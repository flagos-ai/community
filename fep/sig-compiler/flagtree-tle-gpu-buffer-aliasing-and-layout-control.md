# FEP-NNNN: FlagTree TLE GPU Buffer Aliasing and Layout Control

**Status:** `Under developement`

**Created:** 2026-07-24

**Owner:** @sunnycase

**SIG:** sig-compiler

**Target Version:** FlagOS 2.2

---

## Summary

FlagTree TLE GPU Buffer Aliasing and Layout Control introduces two complementary, opt-in interfaces. `tle.gpu.alloc(..., alias=..., alias_offset_bytes=...)` creates a statically validated typed shared-memory view backed by an existing buffer, while `tle.gpu.set_layout(value, layout)` assigns an explicit GPU distributed layout to a block tensor. Together, they let performance-oriented kernels reuse shared-memory storage across non-overlapping execution phases and control register-tensor distribution across GPU execution resources.

Repository: https://github.com/flagos-ai/FlagTree

## Motivation

Shared-memory consumption and layout conversions are common performance bottlenecks in pipelined and warp-specialized GPU kernels.

Logical buffers used by different execution phases often have disjoint lifetimes but require different shapes, element types, or shared-memory layouts. Allocating each logical buffer independently increases the shared-memory footprint, which can reduce occupancy or prevent a kernel from launching. Reusing storage through raw pointers hides bounds, type, layout, liveness, and memory effects from the compiler.

The compiler's automatic tensor-layout selection is a good default, but kernels built around a deliberate warp topology, MMA instruction shape, or memory-access pattern sometimes require a particular distributed layout. Without an explicit language-level contract, the chosen layout may differ from the kernel design and introduce redundant layout conversions.

The proposal provides typed, analyzable controls for these two separate layout domains: shared-memory descriptor views and distributed register tensors.

### Goals

- Add a zero-allocation alias mode to `tle.gpu.alloc` for typed views into existing shared-memory buffers.
- Validate alias offsets, alignment, byte bounds, storage class, and mutability at compile time.
- Add `tle.gpu.set_layout` as the public API for assigning an explicit distributed layout to a block tensor.
- Propagate explicit distributed layouts through compatible producers, consumers, control flow, dot operations, and memory accesses.
- Preserve explicit layout boundaries and diagnose incompatible explicit requirements.
- Keep alias views visible to shared-memory allocation, alias, memory-effect, and lowering analyses.
- Keep explicit distributed layouts visible to layout propagation, coalescing, and lowering.
- Preserve the behavior of ordinary allocations and automatic layout inference when the new interfaces are not used.

### Non-Goals

- Generalize alias views to global memory, tensor memory, or arbitrary address spaces.
- Support dynamic alias offsets or dynamically sized alias byte ranges.
- Infer when two overlapping aliases are safe to access concurrently.
- Make `tle.gpu.set_layout` a data transpose, an in-place mutation, or a shared-memory descriptor operation.
- Replace automatic layout selection for kernels that do not request an explicit layout.
- Guarantee that every explicit layout is legal or optimal on every GPU target.
- Guarantee a latency improvement for every workload; the design guarantees explicit storage and layout semantics.

## Proposal

### Shared-memory alias views

`tle.gpu.alloc` accepts two additional keyword arguments:

```python
def alloc(
    shape,
    dtype,
    layout=None,
    scope=tle.gpu.smem,
    init_value=None,
    nv_mma_shared_layout=True,
    *,
    alias: tle.gpu.buffered_tensor | None = None,
    alias_offset_bytes: int = 0,
) -> tle.gpu.buffered_tensor:
    ...
```

When `alias` is `None`, `tle.gpu.alloc` retains its ordinary allocation semantics. When `alias` is provided, the call returns a `buffered_tensor` view backed by the source buffer instead of creating a new allocation:

```python
v_smem = tle.gpu.alloc(
    (PIPELINE_STAGES, 1, 1, BLOCK_N, BLOCK_D),
    dtype=tl.bfloat16,
    scope=tle.gpu.smem,
)

tl.static_assert(PIPELINE_STAGES * BLOCK_N >= BLOCK_H)

o_smem = tle.gpu.alloc(
    (BLOCK_H, BLOCK_D),
    dtype=tl.bfloat16,
    scope=tle.gpu.smem,
    alias=v_smem,
    alias_offset_bytes=0,
)

# Complete the mainloop lifecycle and synchronize all participants before the
# first conflicting access through o_smem.
```

The aliasing call defines the result shape, dtype, shared-memory layout, and scope. The source determines the backing storage, current-view base and bounds, and maximum permitted mutability. This allows, for example, an attention mainloop value buffer to become an epilogue output buffer after the mainloop has released it.

### Explicit distributed layouts

TLE exposes the following API:

```python
def set_layout(
    value: tl.tensor,
    layout: tle.gpu.distributed_encoding,
) -> tl.tensor:
    ...
```

The returned tensor has the same logical contents, shape, and element type as `value`, with the requested GPU distribution attached to the returned SSA value.

An MMA kernel can declare compatible accumulator and operand layouts as compile-time launch parameters:

```python
mma_layout = tle.gpu.MmaEncoding(
    version=[2, 0],
    warps_per_cta=[4, 1],
    instr_shape=[16, 8],
)
lhs_layout = tle.gpu.DotOperandEncoding(0, mma_layout, k_width=2)
rhs_layout = tle.gpu.DotOperandEncoding(1, mma_layout, k_width=2)


@triton.jit
def mma_kernel(
    MMA_LAYOUT: tl.constexpr,
    LHS_LAYOUT: tl.constexpr,
    RHS_LAYOUT: tl.constexpr,
):
    lhs = tle.gpu.set_layout(
        tl.zeros((32, 32), tl.bfloat16),
        LHS_LAYOUT,
    )
    rhs = tle.gpu.set_layout(
        tl.zeros((32, 8), tl.bfloat16),
        RHS_LAYOUT,
    )
    acc = tle.gpu.set_layout(
        tl.zeros((32, 8), tl.float32),
        MMA_LAYOUT,
    )

    acc = tl.dot(lhs, rhs, acc=acc, out_dtype=tl.float32)
    acc = tl.dot(lhs, rhs, acc=acc, out_dtype=tl.float32)


mma_kernel[(1,)](
    mma_layout,
    lhs_layout,
    rhs_layout,
    num_warps=4,
)
```

## Design Details

### Alias API contract

In alias mode, the result base address is:

```text
base(result) = base(source_view) + alias_offset_bytes
```

The byte offset is relative to the source descriptor's current view base, not necessarily the root allocation. Aliasing a subslice or another alias therefore cannot reach an address outside the physical address set of that immediate source view.

The result shape, rank, element type, and shared-memory layout may differ from those of the source. This is a byte-level reinterpretation of existing storage: it performs no element conversion, initialization, copy, or physical layout transformation. If `layout=None`, normal layout selection uses the result shape and dtype; the source layout is not implicitly inherited.

Bounds and alignment are defined over the physical, per-CTA shared-memory address sets described by the source and result descriptors. The compiler derives these sets from shape, dtype, shared layout, CTA partitioning, padding, and the source view's accumulated offset. For a dense contiguous view, this reduces to checking that the result's physical byte span, shifted by `alias_offset_bytes`, is contained in the source view's physical byte span. For a non-contiguous or layout-dependent view, the compiler must prove address-set containment; it rejects the alias when it cannot do so.

An alias is valid only when all of the following conditions hold:

- `alias` is a `tle.gpu.buffered_tensor` backed by shared memory.
- Both the source and result use `tle.gpu.smem`.
- Source and result physical address sets and byte spans are statically known without integer overflow.
- `alias_offset_bytes` is a compile-time integer, excluding `bool`, in `[0, INT32_MAX]`.
- `base(source_view) + alias_offset_bytes` satisfies the alignment required by the result dtype and shared layout. Consumers may impose additional alignment requirements.
- Every physical byte address reachable through the result is within the source view's address set.
- The result does not strengthen the mutability of the source.
- `init_value` is `None` whenever `alias` is non-`None`.

A violation produces a compile-time error.

`alias_offset_bytes` is interpreted only when `alias` is non-`None`.

Creating a view performs no synchronization. Overlapping views refer to the same storage, so the program must establish a happens-before relationship between the final conflicting access through the old view and the first conflicting access through the new view.

### Distributed layout descriptors

`set_layout` accepts a compile-time `tle.gpu.distributed_encoding` whose rank and target-specific properties are compatible with the block tensor and launch configuration.

| Descriptor | Meaning | Core validation |
|---|---|---|
| `BlockEncoding(size_per_thread, threads_per_warp, warps_per_cta, order, cga_layout=None)` | Blocked distribution across threads and warps | Per-dimension fields have the same rank; `order` is a dimension permutation; each CGA basis matches the rank |
| `MmaEncoding(version, warps_per_cta, instr_shape, cga_layout=None)` | NVIDIA MMA accumulator or result distribution | `version` contains major and minor values; instruction shape and optional CGA bases match the rank |
| `DotOperandEncoding(operand_index, parent, k_width)` | Dot operand A or B relative to an MMA parent | `operand_index` is 0 or 1; parent is distributed; `k_width` is positive |
| `SlicedEncoding(dim, parent)` | A parent distribution with one dimension removed | `dim` is within the parent rank |

`MmaEncoding` and its dot-operand layouts are target-specific. The backend validates supported MMA versions, instruction shapes, warp topology, and cluster topology, and rejects these descriptors on unsupported targets.

`value` must be a block `tl.tensor`. Scalars and `tle.gpu.buffered_tensor` values are outside the API domain. Malformed descriptors, rank mismatches, incompatible launch configurations, and target-unsupported layouts produce compilation errors.

### Layout propagation and conversion

The layout on the result of `set_layout` is a hard layout anchor rather than an ignorable optimization hint.

The compiler propagates it backward into producers and forward into consumers when operation-specific layout inference preserves program semantics. Propagation covers structured control-flow arguments and yields. Rank- or dimension-changing operations such as reshape, transpose, join, split, and concatenation derive compatible source or destination layouts instead of copying an encoding blindly.

For dot operations, A and B use their respective `DotOperandEncoding` descriptors, while accumulator C and result D use the parent `MmaEncoding`. The accumulator layout propagates across chained dots.

If a producer can be retargeted to the requested layout, `set_layout` is eliminated without an execution-time conversion. Otherwise, the boundary becomes an explicit layout conversion. Optimization and rematerialization passes preserve that boundary rather than replacing it with a heuristic layout. When an explicit layout reaches a supported tensor-pointer load, store, or atomic operation, coalescing preserves the requested access layout. Multiple incompatible explicit layouts reaching the same layout-equivalence class or supported memory operation produce a diagnostic.

### Separate layout domains

The two APIs control different representations:

| API | Value domain | Layout domain |
|---|---|---|
| `tle.gpu.alloc(..., layout=..., alias=...)` | Shared-memory `buffered_tensor` descriptor | `tle.gpu.shared_layout` |
| `tle.gpu.set_layout(value, layout)` | Distributed block `tl.tensor` | `tle.gpu.distributed_encoding` |

`set_layout` does not apply directly to an aliased buffer. A program loads a block tensor from a shared-memory view and then applies a distributed layout:

```python
smem_view = tle.gpu.alloc(
    shape,
    dtype,
    layout=shared_layout,
    alias=workspace,
)

values = tl.load(tle.gpu.local_ptr(smem_view, indices))
values = tle.gpu.set_layout(values, distributed_layout)
```

Local-memory lowering consumes the shared-memory descriptor layout and the distributed layout of the loaded or stored tensor as separate contracts. If surrounding SSA values require another distributed layout, the compiler may materialize an explicit distributed-layout conversion.

### IR and lowering

- The frontend represents an alias as a typed `tle.memdesc_alias` view with a static byte offset.
- Shared-memory alias analysis resolves `tle.memdesc_alias` through recognized memdesc-view chains.
- Allocation analysis associates the view with its backing allocation, does not reserve additional shared memory for the view, and extends the backing allocation's liveness through alias uses.
- Memory-effect analysis resolves recognized alias views to the same shared-memory root.
- LLVM lowering derives the source view's shared-memory base, adds `alias_offset_bytes`, and constructs a descriptor with the result element type, rank, and layout.
- The frontend represents an explicit distributed-layout anchor as the pure, shape- and element-type-preserving `tle.gpu.set_layout` operation.
- TritonGPU conversion propagates the requested layout, annotates affected memory accesses, removes satisfied anchors, and emits explicit conversions at unsatisfied boundaries.

Both interfaces are opt-in. Allocations without `alias` and tensors without `set_layout` retain their existing user-visible semantics and results.

## Packaging

The feature is distributed as part of the FlagTree Python package and does not add a separate runtime library or package.

- Repository: https://github.com/flagos-ai/FlagTree
- Build command: `MAX_JOBS=32 python3 -m pip install . --no-build-isolation`
- Packaging format: installable Python package and Python wheel
- Build requirements: Python 3, CMake, Ninja, a compatible LLVM toolchain, and the dependencies declared by FlagTree
- Runtime requirements: a supported GPU backend for the selected layout descriptors; NVIDIA SM90 is used for MMA, shared-memory lowering, and integration validation
- NVIDIA CI: https://github.com/flagos-ai/FlagTree/actions/workflows/nv3.6-build-and-test.yml
- Containerized NVIDIA CI and image source: https://github.com/flagos-ai/FlagTree/actions/workflows/flagcicd-nv3.6-build-and-test.yml

## Test Plan

### Image acquisition

Use the NVIDIA CI base image declared by FlagTree:

```bash
docker pull harbor.baai.ac.cn/flagtree/flagtree-py312-torch2.8.0a0_5228986c39.nv25.05-ubuntu24.04:202605-3.6-base
```

The image source is the FlagTree NVIDIA CI workflow:
https://github.com/flagos-ai/FlagTree/actions/workflows/flagcicd-nv3.6-build-and-test.yml

Access to `harbor.baai.ac.cn` is required. The self-hosted NVIDIA CI environment may be used when registry access is unavailable.

### Package installation

From the FlagTree repository root:

```bash
pip uninstall -y triton
MAX_JOBS=32 python3 -m pip install . --no-build-isolation
```

### Component setup and running

```bash
export PYTHONPATH="$PWD/python:${PYTHONPATH}"
export TRITON_CACHE_DIR=/tmp/flagtree_tle_gpu_layout_cache
```

Run on an NVIDIA SM90 GPU for the MMA and shared-memory integration cases.

### Test commands

Run the Python frontend and integration suites:

```bash
python3 -m pytest -s python/test/tle/unit/test_tle.py
python3 -m pytest -s python/test/tle/integration
```

Build and run the TLE compiler regression suite:

```bash
cmake --build build/cmake.linux-x86_64-cpython-3.12 \
  --target triton-opt triton check-triton-tle-lit-tests -j32
```

Run the focused alias and layout regressions:

```bash
lit -v \
  --filter='GPU/test_tle_(memdesc_alias.*|set_layout.*|explicit_(dot_encoding_propagation|memory_encoding_coalesce))\.mlir$' \
  build/cmake.linux-x86_64-cpython-3.12/third_party/tle/test
```

### Expected results

- `python/test/tle/unit/test_tle.py` accepts valid alias views and distributed descriptors. It rejects invalid storage classes; `alias` with a non-`None` initializer; invalid offset types, alignment, bounds, or mutability; scalar, buffered, or rank-incompatible `set_layout` inputs; malformed descriptors; layout/launch mismatches; and unsupported target layouts.
- `python/test/tle/integration` covers alias-to-`local_ptr` load/store composition with `set_layout`, structured-control-flow and reshape/transpose propagation, a required conversion boundary, and conflicting explicit anchors. Numerical kernels match their references across repeated executions.
- `check-triton-tle-lit-tests` passes the complete compiler regression suite, including kernels that use neither interface and retain their existing semantics and numerical results.
- The focused lit run proves physical-span containment and alignment checks, including dynamic or unprovable views; verifies that aliases add no shared-memory allocation; matches the requested constant byte offset in LLVM lowering; preserves compatible blocked, sliced, MMA, dot-operand, and tensor-pointer access layouts without redundant conversions; keeps required conversion boundaries; and diagnoses conflicting explicit layouts.

## Related PRs

- [FlagTree](https://github.com/flagos-ai/FlagTree) — API, compiler, and validation work governed by this FEP

## Implementation History

- 2026-07-24: FEP created

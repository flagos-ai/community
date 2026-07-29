# FEP-0083: vllm-plugin-FL Support for Arm64 CPU Local Inference

**Status:** `Implementable`

**Created:** 2026-07-29

**Owner:** @kevinzs2048

**SIG:** sig-edge

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP enables
[`vllm-plugin-FL`](https://github.com/flagos-ai/vllm-plugin-FL) to run local model inference
on Linux Arm64 CPUs. It reuses vLLM's existing Arm64 CPU platform, worker, model runner,
attention, KV-cache, scheduling, and multiprocessing support. This FEP does not add another
Arm64 platform implementation to vLLM or duplicate its CPU runtime.

The plugin-side work is to provide the Arm CPU quantized inference paths directly in the
`vllm-plugin-FL` main repository. The plugin will support both W4A8 and W8A8 local inference
and select the requested mode at runtime.

The initial baseline is vLLM `0.20.2` with its corresponding PyTorch `2.11` environment. The
acceptance platform is Linux AArch64 with `asimddp` (dot-product), `i8mm`, and BF16 CPU
features.

## Motivation

vLLM already supports Arm64 CPU inference. Therefore, the missing capability is not another
CPU platform abstraction, CPU worker, distributed backend, or memory-management
implementation. The required work is confined to `vllm-plugin-FL`: connect its model
registration and optimized Arm operators to vLLM's native CPU execution path, and make W4A8
and W8A8 available from the main plugin package.

Without this integration, installing the main plugin does not provide a complete, selectable
Arm64 quantized inference path. W8A8 also depends on native assets, compiler symbols, cache
identity, and packaging rules that must be managed by the same repository as its Python model
integration.

The adaptation therefore provides both quantized linear implementations behind one model
registration entry point. W4A8 and W8A8 share one Triton CPU compiler build while retaining
independent operator namespaces, packing rules, native symbols, cache ABI values, and runtime
selection.

### Goals

**(Required)**

- Run vLLM local model inference on Linux Arm64 with `vllm-plugin-FL` enabled, reusing
  upstream vLLM's existing CPU runtime.
- Provide W4A8 and W8A8 implementations in the `vllm-plugin-FL` main repository.
- Allow one installed plugin to select W4A8 or W8A8 through explicit environment variables.
- Make W8A8 take precedence when both W4A8 and W8A8 are requested, avoiding double model
  patching.
- Keep the W4A8 and W8A8 Triton operator namespaces and Inductor patches independent so both
  implementations can coexist in one Python process.
- Use one KleidiAI-enabled `libtriton.so` and the existing shared compiler builder operation
  for both paths.
- Package all W8A8 native assets and provide a reproducible Arm64 asset build script.
- Validate decode and prefill correctness, strict/fallback behavior, wheel completeness, and
  end-to-end local inference on the Arm64 reference platform.

### Non-Goals

- Reimplementing or replacing vLLM's Arm64 CPU platform, worker, model runner, CPU attention,
  KV-cache management, scheduler, multiprocessing, or Gloo support.
- Adding an `ArmCpuPlatformFL`, `ArmCPUWorkerFL`, or other parallel CPU runtime hierarchy.
- OpenAI-compatible serving, multi-node execution, tensor parallelism greater than 1, or
  pipeline parallelism in the initial acceptance scope.
- x86_64 CPU, GPU, NPU, macOS, or Windows support.
- New quantization formats other than the existing W4A8 and W8A8 paths.
- Adding a new Triton compiler operation solely for W8A8.
- Changing upstream vLLM APIs or its Arm64 installation procedure.

## Proposal

Keep vLLM responsible for the complete Arm CPU runtime and limit the plugin changes to model
registration and optimized quantized linear operators:

```text
vLLM local inference on Arm64
        |
        +-- upstream vLLM CPU platform / worker / model runner
        |
        +-- vllm-plugin-FL register_model()
                |
                +-- FL_CPU_INT8=1 --> W8A8 backend --> return
                |
                +-- otherwise, FL_CPU_INT4=1 --> existing W4A8 backend
                |
                +-- neither enabled --> existing non-quantized vLLM CPU path
```

The main repository contains the W4A8 and W8A8 operator files, native assets, backend
selection, and model-enable logic. They are released, versioned, and tested as one plugin.

### Model Registration

`vllm_fl/__init__.py::register_model()` is the single selection point. The required order is:

```python
if FL_CPU_INT8:
    validate FL_CPU_INT8_BACKEND
    enable the selected W8A8 backend
    return

if FL_CPU_INT4:
    validate FL_CPU_INT4_BACKEND
    enable the existing W4A8 backend
```

`FL_CPU_INT8` has higher priority than `FL_CPU_INT4`. The early return is required so the same
model is not patched by both paths when both variables are set. The existing W4A8 behavior
must remain unchanged when `FL_CPU_INT8` is unset or `0`.

## Design Details

### Arm64 Operator Integration

The W4A8 implementation remains in place. The following W8A8 implementation files and native
assets are added to the main repository:

| File | Purpose |
|---|---|
| `vllm_fl/ops/cpu_int8_tleraw.py` | Primary W8A8 TLE path; mirrors the role of `cpu_int4_tleraw.py`. |
| `vllm_fl/ops/cpu_int8_tle_wrapper.c` | W8A8 TLE native implementation with dot-product GEMV and i8mm GEMM. |
| `vllm_fl/ops/cpu_int8_kai.py` | Optional eager KleidiAI W8A8 backend. |
| `vllm_fl/ops/cpu_int8_kai_wrapper.c` | Native wrapper for the eager KleidiAI backend. |
| `vllm_fl/ops/cpu_int8_pack.py` | Optional PyTorch `_weight_int8pack_mm` W8A16 compatibility backend. |
| `vllm_fl/ops/libkai_w8a8.so` | Prebuilt W8A8 packing library loaded at runtime. |
| `vllm_fl/ops/libkai_w8a8_ukernels.o` | W8A8 microkernel object linked by the TLE path. |

`cpu_int8_pack.py` is retained as an alternative compatibility path, but it computes W8A16
through PyTorch's native INT8 pack operation and is not the primary W8A8 acceptance backend.
The recommended and default W8A8 backend is `tleraw`.

### Runtime Configuration

The merged plugin supports the following Arm CPU variables:

| Variable | Values | Meaning |
|---|---|---|
| `FL_CPU_INT8` | `0` / `1` | Enable the W8A8 model path. It takes priority over W4A8. |
| `FL_CPU_INT8_BACKEND` | `tleraw`, `kleidiai`, `torchpack` | Select the W8A8 implementation; default is `tleraw`. |
| `FL_CPU_INT4` | `0` / `1` | Enable the existing W4A8 model path. |
| `FL_CPU_INT4_BACKEND` | `tleraw` | Select the W4A8 implementation; no other value is accepted. |
| `FL_INT4_LMHEAD` | `0` / `1` | Include `lm_head` in W4A8 quantization. |
| `FL_INT8_LMHEAD` | `0` / `1` | Include `lm_head` in W8A8 quantization. |
| `FL_CPU_INT4_STRICT` | `0` / `1` | Raise on W4A8 conversion failure instead of falling back to BF16. |
| `FL_CPU_INT8_STRICT` | `0` / `1` | Raise on W8A8 conversion failure instead of falling back to BF16. |
| `FL_KAI_W4A8_DIR` | path | W4A8 pack-library source/build directory. |
| `KLEIDIAI_ROOT` | path | KleidiAI source root used by the W4A8 online pack build. |

`FL_KAI_W4A8_DIR` and `KLEIDIAI_ROOT` apply only to W4A8. W8A8 loads the packaged
`libkai_w8a8.so` and does not require KleidiAI headers to be compiled during inference.

Typical selections are:

```bash
# W4A8
export FL_CPU_INT4=1
export FL_CPU_INT4_BACKEND=tleraw
export FL_CPU_INT8=0

# W8A8
export FL_CPU_INT8=1
export FL_CPU_INT8_BACKEND=tleraw
```

### W4A8 and W8A8 Coexistence

The two paths share the model-integration pattern but keep their quantization and runtime
identities separate:

| Area | W4A8 | W8A8 |
|---|---|---|
| Weight quantization | Signed INT4, per block with `BL=32` | Symmetric INT8, per row with `scale=amax/127` |
| Primary operator | `fltleraw::linear_w4a8` | `flint8tle::linear_w8a8` |
| Primary backend | `tleraw` | `tleraw` |
| Packing dependency | Online build using KleidiAI sources | Packaged `libkai_w8a8.so` |
| Inductor import | `gemm_w4a8_i8mm` | `gemm_w8a8_tle` |
| Patch marker | `_fl_w4a8_builtin_patched` | `_fl_w8a8_builtin_patched` |
| Cache ABI | Independently maintained W4A8 value | Independently maintained W8A8 value |

The `torch.library.triton_op` namespaces must remain different. Likewise, each path
monkey-patches `AsyncCompile.triton` only with its own builtin import and uses its own
idempotence marker. Reusing one namespace or patch marker would make import order determine
which implementation survives.

### Shared Compiler Integration

W4A8 and W8A8 intentionally reuse the compiler builder operation
`create_cpu_gemm_q4_0_v2_smmla_bf16`, defined under
`third_party/cpu/language/cpu/tle_ops.py`. The W8A8 Python builtin
`gemm_w8a8_tle` still emits this existing operation. Its
`neon.register_c_function` binding points to the W8A8 external implementation, while W4A8
binds its own external symbol.

Despite the historical `q4_0` name, no new compiler operation is needed for W8A8. The
quantization-specific behavior is supplied by the registered native function behind the
shared builder operation.

The known-good compiler source containing the required KleidiAI integration is
`arm64-dev/backend/main`. A `libtriton.so` built only from the checked-out INT8 V2 branch is
insufficient because that branch does not contain the KleidiAI changes. The implementation
must:

1. use `arm64-dev/backend/main` as the compiler source baseline;
2. record the exact commit used;
3. rebuild `libtriton.so` after checkout; and
4. use that single rebuilt library for both W4A8 and W8A8.

When the Triton 3.7 CPU line described by
[FEP-0082](./0082-flagtree-cpu-bump-to-triton-3_7.md) becomes the FlagTree baseline, the
shared builder operation and KleidiAI integration above must be present in its matching
`flagtree-cpu` line.

### Torch Inductor and Native Dispatch Constraints

The merged implementation must preserve the following constraints from the working Arm64
paths:

- Operators must use `triton_op` together with `wrap_triton`. Reverting to the older
  `custom_op` launch wrapper introduces a large decode-performance regression.
- Prefill (`M > 1`) versus decode (`M = 1`) dispatch must occur in the backing C function.
  vLLM CPU uses `DYNAMO_TRACE_ONCE`; a Python shape branch observed during warmup cannot be
  relied upon to retain the correct guard for later decode shapes.
- W4A8 and W8A8 keep independent `TLE_CACHE_ABI` values. The current values are `20260717`
  for W4A8 and `20260720` for W8A8. Any change to external C source, linked object content, or
  native calling convention must bump the corresponding value because Inductor does not hash
  those native inputs.
- Python startup ordering must not pre-populate an incorrect `has_triton_package` result.
  The `.pth`/`sitecustomize` order must ensure the intended Triton package is discoverable
  before Inductor caches Triton availability; otherwise the observed failure is an
  `AttrsDescriptor` `NameError`.

### Version and Platform Constraints

| Component | Required baseline |
|---|---|
| Operating system | Linux AArch64 |
| CPU features | `asimddp`/dot-product, `i8mm`, and BF16 |
| vLLM | `0.20.2` |
| PyTorch | `2.11`, matching the vLLM environment |
| vllm-plugin-FL | Main repository with both W4A8 and W8A8 paths |
| Triton CPU compiler | KleidiAI-enabled build from `arm64-dev/backend/main`, exact commit pinned |

Both quantized paths call `_validate_cpu_features()` and must fail early with a clear message
when the required Arm instructions are unavailable. They must not silently execute an
incompatible native kernel.

## Packaging

**(Required)** The `vllm-plugin-FL` wheel must contain the Python implementations and the W8A8
native assets:

- `vllm_fl/ops/libkai_w8a8.so`;
- `vllm_fl/ops/libkai_w8a8_ukernels.o`; and
- the W8A8 Python and C wrapper sources required by the runtime/JIT path.

These files must be listed in the package configuration and source manifest. Asset presence is
part of wheel validation because the W8A8 loader otherwise fails with
`FileNotFoundError`.

The main repository must also include `tools/build_arm_int8_assets.sh` and connect it to the
Arm64 package build flow. The script is the reproducible way to rebuild the W8A8 pack library
and microkernel object. A missing asset error should direct developers to this script.

Both W4A8 and W8A8 use the same KleidiAI-enabled `libtriton.so`.

## Test Plan

**(Required)** All acceptance testing is performed on Linux AArch64 with `asimddp`, `i8mm`,
and BF16. This FEP validates local inference only; serving is outside the initial scope.

### 1. Repository and Packaging Validation

- Build the main `vllm-plugin-FL` wheel on Arm64.
- Inspect the wheel and verify that every W8A8 Python file, wrapper source,
  `libkai_w8a8.so`, and `libkai_w8a8_ukernels.o` is present.
- Install the wheel in a clean environment containing vLLM `0.20.2`, PyTorch `2.11`, and the
  rebuilt KleidiAI-enabled `libtriton.so`.
- Import the W4A8 and W8A8 modules in either order and verify that both Triton operator
  namespaces and both Inductor patch markers remain registered.

### 2. Selection and Fallback Validation

Exercise the model registration matrix:

| `FL_CPU_INT4` | `FL_CPU_INT8` | Expected result |
|---|---|---|
| `0` | `0` | Normal upstream vLLM CPU inference; no quantized model patch. |
| `1` | `0` | Existing W4A8 `tleraw` path. |
| `0` | `1` | Selected W8A8 backend; `tleraw` by default. |
| `1` | `1` | W8A8 only; W4A8 is not also applied. |

Additional checks:

- invalid `FL_CPU_INT4_BACKEND` and `FL_CPU_INT8_BACKEND` values fail with actionable errors;
- strict mode raises when the requested conversion cannot be applied; and
- non-strict mode falls back to BF16 without leaving a partially converted model.

### 3. Operator Correctness

For W4A8 and W8A8, compare the optimized linear result with the corresponding dequantized BF16
reference across:

- decode shapes with `M=1`;
- prefill shapes with `M>1`;
- aligned and boundary K/N sizes used by the supported models; and
- `lm_head` disabled and enabled.

The W8A8 matrix covers `tleraw` and `kleidiai`; `torchpack` is checked separately as W8A16.
Tests must prove that decode uses dot-product GEMV and prefill uses i8mm GEMM through the C-side
shape dispatch. Strict tests must also prove that the selected optimized operator ran rather
than silently falling back.

### 4. End-to-End Local Inference

Run the same supported model checkpoint and deterministic prompt set through:

1. upstream vLLM BF16 CPU inference;
2. `vllm-plugin-FL` W4A8 `tleraw`; and
3. `vllm-plugin-FL` W8A8 `tleraw`.

Pass criteria:

- the model loads and generates non-empty output in all three modes;
- W4A8 and W8A8 complete both prompt processing and multi-token decode;
- no CUDA/NPU platform is required;
- both quantized paths use the same rebuilt `libtriton.so`; and
- output quality is checked against the fixed BF16 reference prompts and tolerances recorded
  by the implementation PR.

The implementation PR must pin the model, revision, prompt set, maximum sequence length,
thread affinity, and numerical tolerances so the result is reproducible.

### 5. Cache and Performance Regression

- Run W4A8, then W8A8, then W4A8 again in clean processes and verify that no cache entry or
  import patch from one path corrupts the other.
- Modify or rebuild each native asset in a development test and verify that bumping its own
  `TLE_CACHE_ABI` invalidates the corresponding cache.
- Record prefill throughput and decode tokens per second for BF16, W4A8 `tleraw`, W8A8
  `tleraw`, and W8A8 `kleidiai` on the same pinned host.
- Confirm that the primary paths use `triton_op` plus `wrap_triton` and do not regress to the
  legacy `custom_op` launch path.

The initial performance numbers are recorded as characterization rather than a cross-machine
absolute threshold. Any regression against the existing W4A8 main-repository result or the
known W8A8 prototype result on the same host blocks the FEP from moving to `Implemented`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Both quantization paths patch the same model | Enforce W8A8 priority and return immediately after `enable_int8()`. |
| Triton operator or import names collide | Keep separate namespaces, imports, and idempotence markers. |
| Native asset changes reuse stale Inductor output | Maintain and bump independent W4A8/W8A8 cache ABI values. |
| Python shape dispatch selects the warmup path permanently | Dispatch on `M` inside the backing C function. |
| Wheel works from source but fails after installation | Validate native asset contents from an installed wheel in a clean environment. |
| Wrong Triton checkout lacks KleidiAI support | Build and pin `libtriton.so` from `arm64-dev/backend/main`. |

## Related PRs

No implementation PRs exist at the time of this draft.

## References

- [vllm-plugin-FL](https://github.com/flagos-ai/vllm-plugin-FL)
- [vLLM 0.20.2 CPU installation](https://docs.vllm.ai/en/v0.20.2/getting_started/installation/cpu/)
- [FEP-0015: Arm64 CPU Backend for FlagOS (TLE + Triton-CPU)](./0015-arm64-cpu-backend-flagtree-tle.md)
- [FEP-0082: FlagTree CPU Backend Upgrade to Triton 3.7](./0082-flagtree-cpu-bump-to-triton-3_7.md)

## Implementation History

- 2026-07-29: Reworked the draft around the verified implementation scope: reuse upstream
  vLLM Arm64 CPU support and provide W4A8/W8A8 local inference in the `vllm-plugin-FL` main
  repository.

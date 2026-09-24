# FEP-0065: FlagTree TLE GPU Buffer Aliasing and Layout Control

**Status:** `Implemented`

**Updated:** 2026-09-24

**Created:** 2026-07-24

**Owner:** @sunnycase

**SIG:** sig-compiler

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| flagtree-triton3.6 | [`0.7.0-rc2-triton3.6` @ `4819c190476c`](https://github.com/flagos-ai/FlagTree/tree/4819c190476cebb66057493e41379c1406c615ac) | [`0.7.0rc2.post2+triton3.6` @ `d9e65f4df7fe`](https://github.com/flagos-ai/FlagTree/tree/d9e65f4df7fe881281abd9e834ab3f37f4d0642c) |

## Summary

Add shared-memory alias views through `tle.gpu.alloc` and explicit tensor
layouts through `tle.gpu.set_layout`. Both APIs are present in the Triton 3.6
RC2 branch.

## Delivered Scope

| Goal | RC2 implementation | Acceptance |
|---|---|---|
| Typed shared-memory aliases | `gpu/core.py`, `gpu/semantic.py`, `tle.memdesc_alias` and allocation/LLVM lowering | Implemented; NVIDIA feature CI passed |
| Explicit distributed layouts | `tle.gpu.set_layout`, encoding propagation and memory coalescing rules | Implemented; NVIDIA and MUSA feature CI passed |
| Preserve ordinary allocation and inferred layouts | Both APIs are opt-in | Covered by the existing TLE suite |

Source: `python/triton/experimental/tle/language/gpu/` and `third_party/tle/`.

## API and Design

`tle.gpu.alloc(shape, dtype, alias=buffer, alias_offset_bytes=0)` creates a
view without allocating storage. The offset is relative to the source view.
The result may use a different shape, dtype or shared-memory layout.

Alias validation requires shared-memory storage, a static non-negative byte
offset, compatible alignment, containment within the source view and no
stronger mutability. An alias cannot have an initializer. Creating an alias
neither copies data nor synchronizes accesses; the kernel must order
conflicting uses of overlapping views.

The compiler tracks the backing allocation through aliases, extends its
lifetime to cover alias uses and lowers the view to the source address plus
the byte offset.

`tle.gpu.set_layout(value, layout)` returns the same logical block tensor with
an explicit distributed encoding. Supported descriptors include
`BlockEncoding`, `MmaEncoding`, `DotOperandEncoding` and `SlicedEncoding`.
The encoding must match the tensor rank, launch configuration and backend.
Scalars and shared-memory descriptors are outside this API.

Layout anchors propagate through compatible operations and control flow.
Satisfied anchors disappear; other boundaries become explicit layout
conversions. Conflicting hard encodings produce a compilation error.
Shared-memory descriptor layouts and distributed register layouts remain
separate contracts.

## Non-Goals

Dynamic alias ranges, global-memory aliases, automatic synchronization of
overlapping views and a universal performance gain are outside this FEP.

## Packaging

Included in the FlagTree wheel. Build on the target backend with its matching
LLVM and device SDK:

```bash
python -m pip wheel . --no-build-isolation --no-deps -w dist
```

NVIDIA SM90 is the reference target for the shared-memory and MMA tests.
Moore Threads has a separate `set_layout` backend test.

## Test Commands

From the FlagTree source root on the matching accelerator:

```bash
python -m pytest -q python/test/tle/unit/test_tle_alloc_alias.py
python -m pytest -q python/test/tle/unit/test_tle.py
python -m pytest -q python/test/tle/integration/test_tle_alias_e2e.py
```

Run the configured CMake build's `check-triton-tle-lit-tests` target. Required
regressions under `third_party/tle/test/GPU/` include:

- `test_tle_memdesc_alias.mlir`
- `test_tle_memdesc_alias_allocation.mlir`
- `test_tle_memdesc_alias_to_llvm.mlir`
- `test_tle_explicit_dot_encoding_propagation.mlir`
- `test_tle_explicit_memory_encoding_coalesce.mlir`

Valid views must preserve reference results without extra shared-memory
allocation. Invalid bounds, offsets, layouts and conflicting anchors must
fail compilation. Required conversions must remain; redundant conversions
must disappear.

## Validation

NVIDIA build and test jobs passed for [alias allocation](https://github.com/flagos-ai/FlagTree/actions/runs/32091166625/job/95573500265)
and [layout integration](https://github.com/flagos-ai/FlagTree/actions/runs/32687963733/job/97316379054).
The logs include the alias unit cases, TLE frontend tests and numerical
integration suite. PR #1037 also passed the MUSA unit and Qwen jobs.
The tested feature revisions are included in RC2.

## Related PRs

- [x] [FlagTree#826](https://github.com/flagos-ai/FlagTree/pull/826) — Shared-memory alias allocation. Merged.
- [x] [FlagTree#908](https://github.com/flagos-ai/FlagTree/pull/908) — Explicit distributed layout API. Merged.
- [x] [FlagTree#946](https://github.com/flagos-ai/FlagTree/pull/946) — Layout anchors for tile extraction and insertion. Merged.
- [x] [FlagTree#1037](https://github.com/flagos-ai/FlagTree/pull/1037) — Moore Threads set_layout support. Merged.

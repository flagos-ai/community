# FEP-0014: TLERaw - CUDA Backend Integration

**Status:** `Implemented`

**Created:** 2026-05-27

**Owner:** (TBD)

**SIG:** sig-compiler

**Target Version:** FlagOS 2.1

---

## Summary

TLERaw is a low-level programming path in FlagTree TLE (Triton Language Extensions) that allows calling external device code from Triton kernels. This proposal documents the CUDA backend integration of TLERaw, including the runtime import flow from CUDA device code to LLVM IR, the IR wrapping mechanism (`DSLRegionOp`), and the compiler passes that enable efficient shared-memory buffer interaction.

Repository: https://github.com/flagos-ai/FlagTree

## Motivation

Triton users sometimes need to integrate hand-tuned CUDA device functions (e.g., inline PTX, warp-level primitives, vendor-specific codegen patterns) while still benefiting from Triton’s Python frontend and scheduling model. TLERaw provides a controlled bridge to bring CUDA device code into the Triton compilation pipeline.

### Goals

- Provide a documented TLERaw CUDA backend flow that imports CUDA device code into the compilation pipeline and invokes it from Triton kernels.
- Enable interop between TLERaw calls and TLE GPU shared-memory buffers allocated by `tle_gpu.alloc` (via `tle_raw.call_smem`).
- Reduce unnecessary local load/store traffic around TLERaw calls through dedicated compiler passes.

### Non-Goals

- Replace CUDA toolchain dependencies (e.g., `clang`) with a fully in-process compiler pipeline.
- Provide performance guarantees for all TLERaw workloads; performance remains workload- and hardware-dependent.

## Proposal

- Users write CUDA device functions and compile them to LLVM IR at runtime.
- The imported LLVM function is wrapped into a `DSLRegionOp` so it can be called inside Triton kernels.
- For shared-memory interaction, users allocate buffers via `tle_gpu.alloc` and pass those buffers into TLERaw calls (e.g., `tle_raw.call_smem`) so external code can read/write local memory buffers directly.
- Add compilation passes that (1) convert tensor operands/results to memdesc around `DSLRegionOp` and (2) eliminate redundant copies in loop-carried patterns.

## Design Details

- **Runtime import (CUDA → LLVM IR)**: the CUDA backend uses `clang` to compile CUDA device code to LLVM IR and parses it into MLIR for downstream compilation.
- **IR wrapping (`DSLRegionOp`)**: the imported LLVM function is embedded into the current module and invoked via an always-inline `LLVM::CallOp`, with arguments/results converted using protocol-based patterns.
- **Optimization passes**:
  - `tle-convert-arg-to-memdesc`: converts tensor operands/results around `DSLRegionOp` into memdesc form, inserting barriers when needed.
  - `tle-remove-redundant-copy`: rewrites specific loop-carried patterns to avoid redundant local loads/stores across iterations.

## Packaging

The TLERaw CUDA backend is shipped as part of FlagTree’s TLE components. Users should refer to FlagTree installation guides and ensure `clang` is available in the build/runtime environment when using TLERaw CUDA imports.

## Test Plan

CI runs TLERaw examples through existing workflow scripts:
- nvidia: https://github.com/flagos-ai/FlagTree/blob/triton_v3.6.x/.github/workflows/hopper-build-and-test.yml
- nvidia (flagcicd): https://github.com/flagos-ai/FlagTree/blob/triton_v3.6.x/.github/workflows/flagcicd-hopper-build-and-test.yml

Key example entrypoints:
- MLIR path: https://github.com/flagos-ai/FlagTree/tree/triton_v3.6.x/python/tutorials/tle/raw/mlir
- CUDA path: https://github.com/flagos-ai/FlagTree/tree/triton_v3.6.x/python/tutorials/tle/raw/cuda

## Related PRs

- [ ] flagos-ai/FlagTree#471 - Enable fp16 for TLERaw CUDA
- [ ] flagos-ai/FlagTree#479 - Support `buffered_tensor` with TLERaw calls and remove redundant copy
- [ ] flagos-ai/FlagTree#516 - TLERaw: delete legacy INOUT identifier
- [ ] flagos-ai/FlagTree#585 - TLERaw: improve MLIR hello-world test robustness

## Implementation History

- 2026-05-27: FEP created


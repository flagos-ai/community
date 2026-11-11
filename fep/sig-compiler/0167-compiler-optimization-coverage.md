# FEP-0167: FlagTree Compiler Optimization Across Twenty Operator-Device Combinations

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** @Vincent-Xiao

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Extend [FlagTree](https://github.com/flagos-ai/FlagTree) optimization coverage through FlagOSTune, layout optimization, task and instruction scheduling, mixed precision and synchronization optimization. Apply these techniques to a cumulative twenty operator/device combinations across NVIDIA, T-Head PPU, Hygon, MetaX and Moore Threads, focusing on key operators used by Qwen and DeepSeek.

## Goals

| Goal | Deliverable |
|---|---|
| G1 — FlagOSTune | Extend machine-learning-guided Triton autotuning to more key operators, reducing search cost while selecting efficient configurations. |
| G2 — Layout | Reduce layout-conversion overhead and improve layout encoding and data movement on selected operators. |
| G3 — Scheduling | Extend explicit barrier control for warp-specialized tasks; apply instruction reordering and fusion to improve parallelism and hide memory-access latency. |
| G4 — Mixed precision | Support low-precision floating-point and integer formats on the selected backends, and reuse accumulators across operand precisions to reduce register usage. |
| G5 — Synchronization | Remove redundant synchronization in warp-specialized and TMA-store paths while preserving required memory ordering. |

Count each operator/device pair once, regardless of the number of shapes or optimizations. Separate existing coverage from additions in 2.3. The Owner will provide the twenty-pair list, per-feature backend coverage and performance criteria.

## Packaging

**Target vendors:** NVIDIA, T-Head PPU, Hygon, MetaX and Moore Threads.

Compiler passes and the FlagTune runtime ship in the FlagTree wheel. Build from the repository root using the backend's documented SDK environment. Set `FLAGTREE_BACKEND` to `ppu`, `hcu`, `metax` or `mthreads` for those backends; leave it unset for NVIDIA.

```bash
python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist
```

FlagTune's optional Python dependencies are declared in the `flagtune` extra. Predictor packages are loaded separately through its manifest and model-cache mechanism; record the matching manifest and model-package versions.

## Test Plan

Run the tests from the matching FlagTree checkout and backend installation. Record the device model, SDK/driver, PyTorch, FlagTree and operator-source revisions. Each operator case records its shape, input/output and accumulation dtypes, reference and accuracy tolerance. Report compiler-only checks, device results, failures and skips separately. The IR commands require matching `triton-opt` and LLVM `FileCheck` binaries on `PATH`.

### G1: FlagOSTune

Run the runtime and configuration-contract regressions:

```bash
python3 -m pytest -q python/test/flagtune/test_autotuner.py \
  python/test/flagtune/test_config_registry.py
```

**Check:** Verify dtype identity, candidate-configuration constraints, model-version compatibility and error reporting. These tests do not measure device tuning speed.

For each selected operator/backend, compare model-guided tuning with the agreed autotuning baseline using the same candidate space, inputs and timing method. Record search time, configurations measured, the selected configuration and its latency. Check the selected configuration's numerical output using the operator's reference.

### G2: layout optimization

Run the enhanced layout-conversion regressions from [#1333](https://github.com/flagos-ai/FlagTree/pull/1333):

```bash
triton-opt test/TritonGPU/remove-layout-conversions-enhance.mlir \
  -split-input-file -tritongpu-remove-layout-conversions="enable-rlc-enhance=true" \
  | FileCheck test/TritonGPU/remove-layout-conversions-enhance.mlir --check-prefixes=COMMON,ON
triton-opt third_party/tle/test/GPU/test_tle_set_layout_remove_layout_conversions.mlir \
  -split-input-file -tritongpu-remove-layout-conversions="enable-rlc-enhance=true" \
  | FileCheck third_party/tle/test/GPU/test_tle_set_layout_remove_layout_conversions.mlir
```

**Check:** Verify the expected conversion placement and preservation of explicit layouts. These are IR checks; the enhancement is currently enabled by default on NVIDIA. Validate other selected backend/operator combinations with their own correctness and performance cases.

### G3: task and instruction scheduling

On NVIDIA Hopper, run the warp-specialized helper regression:

```bash
python3 -m pytest -q python/test/tle/integration/test_tle_warp_specialize_helpers.py
```

**Check:** Verify output values and the barrier IDs and thread counts generated for default/worker partitions and nested helper calls.

Run the existing instruction-reordering regression:

```bash
triton-opt test/TritonGPU/reorder-instructions.mlir \
  -split-input-file -tritongpu-reorder-instructions \
  | FileCheck test/TritonGPU/reorder-instructions.mlir
```

**Check:** Verify the expected instruction order and operand dependencies.

For the Moore Threads scheduling and fusion changes in [#1612](https://github.com/flagos-ai/FlagTree/pull/1612), run the compiler regressions with that PR's matching backend build:

```bash
# Requires FlagTree PR #1612 (not yet merged).
python3 -m pytest -q \
  third_party/mthreads/python/test/unit/tle/test_fp8_pack_pair_sums.py \
  third_party/mthreads/python/test/unit/tle/test_sqmma_overlap_add_order.py
```

**Check:** Verify FP8 packing/add fusion and ADD placement around SQMMA, preserving required waits. These are compiler checks; device correctness and performance cases remain to be supplied before acceptance.

### G4: mixed precision

On the PPU and Moore Threads builds containing [#1116](https://github.com/flagos-ai/FlagTree/pull/1116) and [#1189](https://github.com/flagos-ai/FlagTree/pull/1189), run:

```bash
python3 python/tutorials/mixed_precision/01-fp8.py
python3 python/tutorials/mixed_precision/02-fp4.py
python3 python/tutorials/mixed_precision/03-int8.py
python3 python/tutorials/mixed_precision/04-int4.py
```

**Check:** Verify the supported floating-point conversions and matrix products using the scripts' assertions. Check integer matrix products and INT4 packing/unpacking for exact results. Record native, emulated and unsupported paths separately.

On Moore Threads, run the cross-precision accumulator tests from [#1401](https://github.com/flagos-ai/FlagTree/pull/1401):

```bash
python3 -m pytest -q python/test/tle/integration/test_tle_wgmma_accumulator.py --device musa
python3 -m pytest -q third_party/mthreads/python/test/unit/tle/test_tle_sqmma_acc_reuse.py --device musa
```

**Check:** Verify FP32 accumulator reuse across FP8/FP16/BF16 operands, loop-boundary correctness and required waits. Hygon and MetaX low-precision coverage depends on the integration and device tests for [#1587](https://github.com/flagos-ai/FlagTree/pull/1587) and [#1493](https://github.com/flagos-ai/FlagTree/pull/1493), both under review.

### G5: synchronization optimization

On NVIDIA Hopper, use an integration build containing [#1166](https://github.com/flagos-ai/FlagTree/pull/1166), which is still under review:

```bash
# Requires FlagTree PR #1166 (not yet merged).
python3 -m pytest -q python/test/tle/integration/test_tle_tma_store_dataflow.py
```

**Check:** Verify TMA-store results across branches, nested loops and source-buffer reuse, including the test's pending-store wait checks. Add device cases for the selected warp-specialized barrier-removal paths and compare operator latency using the criteria below.

### Operator performance and coverage

For every selected pair, identify the optimization and whether the operator source changes. Use the operator's correctness and benchmark commands:

- **Compiler-only changes:** Keep operator sources and other dependencies fixed; compare the agreed compiler baseline with the 2.3 candidate.
- **New or rewritten operators:** Compare with the vendor-native implementation or another agreed reference using equivalent inputs, precision and accuracy requirements.

Use the same device and timing method, and record both latencies and speedup as `reference latency / candidate latency`. Report regressions alongside gains. For mixed precision, specify operand and accumulation formats so that a format change is not reported as compiler-only speedup.

Complete correctness and performance records for twenty distinct operator/device pairs. Record the model use, device, optimization, reference, source revisions and commands for each pair, separating existing coverage from 2.3 additions. The Owner confirms the pair list, performance thresholds and aggregation before acceptance.

## Related PRs

- Baseline: [FEP-0097](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0097-flagtree-compiler-optimization.md).
- [x] [FlagTree #1236](https://github.com/flagos-ai/FlagTree/pull/1236) and [#1478](https://github.com/flagos-ai/FlagTree/pull/1478) — FlagTune configuration contracts, model-package versions and benchmark integration.
- [x] [FlagTree #1333](https://github.com/flagos-ai/FlagTree/pull/1333) — Enhanced layout-conversion removal.
- [x] [FlagTree #1278](https://github.com/flagos-ai/FlagTree/pull/1278) — Warp-specialized barriers across outlined helper calls.
- [x] [FlagTree #1116](https://github.com/flagos-ai/FlagTree/pull/1116) and [#1189](https://github.com/flagos-ai/FlagTree/pull/1189) — PPU and Moore Threads low-precision floating-point and integer support.
- [x] [FlagTree #1401](https://github.com/flagos-ai/FlagTree/pull/1401) — Moore Threads cross-precision accumulator reuse.
- [ ] [FlagTree #1493](https://github.com/flagos-ai/FlagTree/pull/1493) and [#1587](https://github.com/flagos-ai/FlagTree/pull/1587) — MetaX and Hygon low-precision support.
- [ ] [FlagTree #1612](https://github.com/flagos-ai/FlagTree/pull/1612) — Moore Threads instruction scheduling and fusion transforms; device validation pending.
- [ ] [FlagTree #1166](https://github.com/flagos-ai/FlagTree/pull/1166) — NVIDIA barrier and TMA-store synchronization optimization.

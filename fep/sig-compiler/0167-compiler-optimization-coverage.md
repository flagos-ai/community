# FEP-0167: FlagTree Compiler Optimization Across Twenty Operator-Device Combinations

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** @Vincent-Xiao

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Optimize key Qwen and DeepSeek operators in [FlagTree](https://github.com/flagos-ai/FlagTree) through FlagOSTune, layout optimization, task and instruction scheduling, mixed precision and synchronization optimization. Cover a cumulative twenty operator/device combinations across NVIDIA, T-Head PPU, Hygon, MetaX and Moore Threads.

## Goals

| Goal | Deliverable |
|---|---|
| G1 — FlagOSTune | Extend machine-learning-guided Triton autotuning to more key operators, reducing search cost while selecting efficient configurations. |
| G2 — Layout | Reduce layout-conversion overhead and improve layout encoding and data movement on selected operators. |
| G3 — Scheduling | Extend explicit barrier control for warp-specialized tasks; apply instruction reordering and fusion to improve parallelism and hide memory-access latency. |
| G4 — Mixed precision | Support low-precision floating-point and integer formats on the selected backends, and reuse accumulators across operand precisions to reduce register usage. |
| G5 — Synchronization | Remove redundant synchronization in warp-specialized and TMA-store paths while preserving required memory ordering. |

Count each operator/device pair once, regardless of the number of shapes or optimizations. Separate existing coverage from additions in 2.3. The twenty-pair list and per-feature backend coverage remain for the Owner to confirm.

## Packaging

**Target vendors:** NVIDIA, T-Head PPU, Hygon, MetaX and Moore Threads.

Compiler passes and the FlagTune runtime ship in the FlagTree wheel. Build from the repository root using the backend's documented SDK environment. Set `FLAGTREE_BACKEND` to `ppu`, `hcu`, `metax` or `mthreads` for those backends; leave it unset for NVIDIA.

```bash
python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist
```

FlagTune's optional Python dependencies are declared in the `flagtune` extra. Predictor packages are distributed separately; record the matching manifest and model-package versions.

## Test Plan

Run from the matching FlagTree checkout and backend installation. Record the device model, SDK/driver, PyTorch, FlagTree and operator-source revisions. Each operator case records its shape, input/output and accumulation dtypes, reference and accuracy tolerance. Report compiler checks, device results, failures and skips separately. IR checks use matching `triton-opt` and LLVM `FileCheck` binaries.

### G1: FlagOSTune

Run the runtime, configuration and benchmark-protocol regressions:

```bash
python3 -m pytest -q python/test/flagtune/test_autotuner.py \
  python/test/flagtune/test_config_registry.py \
  python/test/flagtune/test_benchmark_protocol.py
```

**Check:** Verify dtype identity, candidate constraints, model-version compatibility, error reporting and event/replay timing settings.

For operators using `triton.flagtune.flagtune`, run their correctness and benchmark commands in separate processes with `FLAGTUNE_ENABLE=0` and `FLAGTUNE_ENABLE=1`. Use matching predictor packages, the same candidate space, inputs and timing mode, and fresh tuning caches. Confirm that the enabled run uses model predictions. Record search time, configurations measured, the selected configuration and its latency; verify its numerical output. Supply the operator commands with the coverage list.

### G2: layout optimization

**NVIDIA layout conversion:** Run the IR regressions from [#1333](https://github.com/flagos-ai/FlagTree/pull/1333):

```bash
triton-opt test/TritonGPU/remove-layout-conversions-enhance.mlir \
  -split-input-file -tritongpu-remove-layout-conversions="enable-rlc-enhance=true" \
  | FileCheck test/TritonGPU/remove-layout-conversions-enhance.mlir --check-prefixes=COMMON,ON
triton-opt third_party/tle/test/GPU/test_tle_set_layout_remove_layout_conversions.mlir \
  -split-input-file -tritongpu-remove-layout-conversions="enable-rlc-enhance=true" \
  | FileCheck third_party/tle/test/GPU/test_tle_set_layout_remove_layout_conversions.mlir
```

**Check:** Verify conversion placement and preservation of explicit layouts.

**Moore Threads shared KV layouts:** Run the compiler and device regressions from [#1450](https://github.com/flagos-ai/FlagTree/pull/1450):

```bash
python3 -m pytest -q third_party/mthreads/python/test/unit/tle/test_tle_sqmma_kv_root.py --device musa
```

**Check:** Compatible K/V consumers share one physical allocation and produce the reference QK/PV results. Incompatible physical layouts are rejected.

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

For Moore Threads [#1612](https://github.com/flagos-ai/FlagTree/pull/1612), run the compiler regressions with the matching backend build:

```bash
# Requires FlagTree PR #1612 (not yet merged).
python3 -m pytest -q \
  third_party/mthreads/python/test/unit/tle/test_fp8_pack_pair_sums.py \
  third_party/mthreads/python/test/unit/tle/test_sqmma_overlap_add_order.py
```

**Check:** Verify FP8 packing/add fusion and ADD placement around SQMMA, preserving required waits. The transforms are disabled by default. Operator tests must record the enabled scheduling options and provide device correctness and performance results.

### G4: mixed precision

On the PPU and Moore Threads builds containing [#1116](https://github.com/flagos-ai/FlagTree/pull/1116) and [#1189](https://github.com/flagos-ai/FlagTree/pull/1189), run:

```bash
python3 python/tutorials/mixed_precision/01-fp8.py
python3 python/tutorials/mixed_precision/02-fp4.py
python3 python/tutorials/mixed_precision/03-int8.py
python3 python/tutorials/mixed_precision/04-int4.py
```

**Check:** Verify supported floating-point conversions and matrix products using the scripts' assertions. Check integer matrix products and INT4 packing/unpacking for exact results. Record native, emulated and unsupported paths separately; unsupported paths do not count as validated coverage.

On Moore Threads, run the cross-precision accumulator tests from [#1401](https://github.com/flagos-ai/FlagTree/pull/1401):

```bash
python3 -m pytest -q python/test/tle/integration/test_tle_wgmma_accumulator.py --device musa
python3 -m pytest -q third_party/mthreads/python/test/unit/tle/test_tle_sqmma_acc_reuse.py --device musa
```

**Check:** Verify FP32 accumulator reuse across FP8/FP16/BF16 operands, loop-boundary correctness and required waits. Hygon and MetaX low-precision coverage depends on the integration and device tests for [#1587](https://github.com/flagos-ai/FlagTree/pull/1587) and [#1493](https://github.com/flagos-ai/FlagTree/pull/1493), both under review.

### G5: synchronization optimization

On NVIDIA Hopper, use an integration build containing [#1166](https://github.com/flagos-ai/FlagTree/pull/1166):

```bash
# Requires FlagTree PR #1166 (not yet merged).
triton-opt third_party/tle/test/Analysis/test-membar-static-views.mlir \
  -split-input-file --allocate-shared-memory -test-print-membar \
  | FileCheck third_party/tle/test/Analysis/test-membar-static-views.mlir
python3 -m pytest -q python/test/tle/integration/test_tle_tma_store_dataflow.py
```

**Check:** The IR tests preserve barriers for conflicting shared-memory accesses and avoid barriers between disjoint slots. Device tests verify TMA-store results across branches, nested loops and source-buffer reuse, including pending-store waits. Supply device cases for the selected warp-specialized barrier-removal paths.

### Operator performance and coverage

For each selected pair, record its model use, optimization, source revisions, correctness and benchmark commands, and whether the operator source changes. Verify that the case exercises the stated optimization through its runtime configuration or generated IR/instructions.

Compare with the vendor-native implementation or an agreed reference on the same device, inputs, precision and timing method. When operator sources are unchanged, also compare the baseline and 2.3 compiler builds with other dependencies fixed.

Report both latencies and speedup as `reference latency / candidate latency`, including regressions. For mixed precision, record operand and accumulation formats. Confirm per-case thresholds and aggregation with the Owner before testing, and retain correctness and performance results for all twenty pairs.

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

# FEP-0167: FlagTree Compiler Optimization Across Twenty Operator-Device Combinations

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** @Vincent-Xiao

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

[FlagTree](https://github.com/flagos-ai/FlagTree) compiles Triton and TLE operators for target accelerators. This FEP extends its compiler optimizations and FlagTune runtime for key Qwen and DeepSeek operators, targeting configuration-search cost, layout-conversion overhead, instruction scheduling, register usage and synchronization overhead.

For FlagOS 2.3, apply these capabilities to a cumulative twenty operator/device combinations across NVIDIA, T-Head PPU, Hygon, MetaX and Moore Threads.

## Goals

| Goal | Function | Expected outcome |
|---|---|---|
| G1 — FlagOSTune | Extend machine-learning-guided Triton autotuning to more key operators, using predictions to select candidate configurations for measurement. | Reduce configuration-search cost while selecting efficient configurations. |
| G2 — Layout | Remove unnecessary layout conversions and improve instruction layout encodings and data movement on selected operators. | Reduce layout-conversion and data-movement overhead. |
| G3 — Scheduling | Extend explicit barrier control for warp-specialized tasks; reorder and fuse instructions. | Improve task-scheduling flexibility and instruction parallelism, and hide memory-access latency. |
| G4 — Mixed precision | Support selected low-precision floating-point and integer formats; reuse accumulators across operations with different operand precisions. | Enable the selected low-precision operators and reduce register usage through accumulator reuse. |
| G5 — Synchronization | Remove redundant barriers and waits in warp-specialized and TMA-store paths. | Reduce synchronization overhead while preserving required memory ordering and numerical correctness. |

Count each operator/device pair once, regardless of the number of shapes or optimizations. Separate existing coverage from additions in 2.3. The twenty-pair list and per-feature backend coverage remain for the Owner to confirm.

## Packaging

**Target vendors:** NVIDIA, T-Head PPU, Hygon, MetaX and Moore Threads.

Compiler passes and the FlagTune runtime ship in the FlagTree wheel. Build from the repository root using the backend's documented SDK environment. Set `FLAGTREE_BACKEND` to `ppu`, `hcu`, `metax` or `mthreads` for those backends; leave it unset for NVIDIA.

```bash
python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist
```

FlagTune's optional Python dependencies are declared in the `flagtune` extra. Predictor packages are distributed separately; record the matching manifest and model-package versions.

## Test Plan

Test the installed FlagTree wheel on each selected device. Record the device model, SDK/driver, PyTorch, FlagTree and operator-source revisions, compiler options and predictor-package versions.

For each of the twenty operator/device pairs, supply a runnable case from its Qwen or DeepSeek workload: model and operator, applicable prefill/decode stage, shapes, strides, operand/output/accumulation dtypes, optimization exercised, reference, accuracy tolerance and test commands. Use the model's actual batch and sequence configurations. Add missing model shapes to the operator's correctness tests and benchmarks. Each command must identify the case and produce numerical assertions or a benchmark record.

### 1. Upgrade FlagTree and rerun existing operators

Run the selected existing operators through their normal invocation path. Hold their source and other dependencies fixed while comparing the baseline and 2.3 compiler builds.

Exercise the layouts used by the model, including transposed weights or shared K/V views where applicable. Repeat calls with changed inputs and reused buffers.

**Check:** Outputs satisfy the reference tolerance on every selected shape, repeated calls complete without stale results or hangs, and steady-state latency is recorded after warmup. Confirm that the intended kernel and optimization execute.

An existing FlagGems regression reproduces a vLLM-style matrix multiplication with a transposed BF16 weight and an explicit output buffer. From the matching FlagGems checkout, run:

```bash
python3 -m pytest -q tests/test_mm.py::test_mm_out_vllm_tma_column_major_weight
```

For selected FlagGems matrix multiplications, use `benchmark/test_mm.py::test_mm` with a versioned `--shape_file` containing the model dimensions. Enumerate workloads with `--list-cases`, select the required dimensions and weight layout with `--case-id`, and save that case manifest. Keep the FlagGems revision, shape file, dtype, level and timing options identical across runs; case IDs depend on enumeration order. Record benchmark results with `--record json` and a named `--output` file.

### 2. Enable tuning and process subsequent inputs

Run the same adapted operator with prediction disabled and enabled in separate processes, using matching predictor packages, inputs and timing modes. Match the legal candidate space when measuring the effect of prediction. Record the operator identity, variant and effective tuning policy; confirm that the enabled run uses predictions rather than fallback.

For `triton.flagtune.flagtune`, the switch is `FLAGTUNE_ENABLE=0/1`. Adapted FlagGems LibTuner paths use `USE_FLAGTUNE=1` with `USE_FLAGTUNE_COST_MODEL=0/1`; verify their effective candidate spaces before comparing them.

1. Start each run with isolated, empty compilation and tuning caches. Record first-call elapsed time through device completion, the reported tuning time, configurations measured and selected configuration.
2. Repeat the same shape/dtype/layout with new data, then run an input with a different tuning key and return to the original workload. Check configuration reuse and numerical outputs throughout.
3. Measure steady-state operator latency after warmup. For integrations with persistent tuning caches, also check reuse after a process restart.

**Check:** Report tuning cost and the selected configuration's execution latency separately, with correctness results. The cold-start and cache-reuse runner is still to be supplied with the selected operator cases; the runtime/unit tests below do not execute this workflow.

### 3. Use low-precision or optimized fused operators

Run the selected operators through their actual integration paths. For operators introduced with a new compiler feature, compare with the vendor-native implementation or agreed reference. Record the enabled compiler options. Moore Threads scheduling transforms in [#1612](https://github.com/flagos-ai/FlagTree/pull/1612) are disabled by default; supply their operator/device cases with the implementation.

Run the selected low-precision operator on the model's actual dimensions and supported formats. Use identical quantized inputs, packing, scales and accumulation semantics for candidate and reference. Compare numerical outputs with the corresponding decoded or higher-precision reference; compare performance with the vendor-native or agreed implementation using the same precision.

For cross-precision accumulator reuse, exercise the operand-precision sequence and loop counts used by the selected fused operator. Check the final accumulated output, including repeated execution with new inputs. For asynchronous producer/consumer paths, preserve the operator's normal synchronization while checking the final consumer output after buffer reuse.

**Check:** Confirm that the enabled optimizations are exercised. Floating-point results meet the case's tolerance; integer results meet the operator's exactness requirements. Repeated calls complete without stale results or hangs. Record steady-state latency after warmup, and distinguish native, emulated and unsupported paths. Report changes in precision or quantization separately from compiler-only speedups.

### 4. Run an integrated model

For selected operators already integrated into a runnable Qwen or DeepSeek deployment, rerun its existing model regression with fixed weights, inputs and framework configuration.

**Check:** Confirm that the optimized operators are invoked, check outputs against the existing acceptance criteria, and record model latency or throughput separately from operator timings.

### Supporting regressions

Run the relevant existing tests from the matching FlagTree checkout in addition to the selected operator cases:

| Scenario | Entry point | Device or dependency | Check |
|---|---|---|---|
| Tune operators | `python3 -m pytest -q python/test/flagtune/test_autotuner.py python/test/flagtune/test_config_registry.py python/test/flagtune/test_benchmark_protocol.py` | Installed FlagTree and PyTorch; CUDA timing cases require a compatible device | Configuration contracts and timing protocol. |
| Use shared K/V views | `python3 -m pytest -q third_party/mthreads/python/test/unit/tle/test_tle_sqmma_kv_root.py --device musa` | Moore Threads | QK/PV reference results with shared KV layouts and repeated stage reuse. |
| Run warp-specialized tasks | `python3 -m pytest -q python/test/tle/integration/test_tle_warp_specialize_helpers.py` | NVIDIA Hopper | Outputs from worker/default partitions and nested helper calls. |
| Accumulate across precisions | `python3 -m pytest -q python/test/tle/integration/test_tle_wgmma_accumulator.py --device musa` | Moore Threads | Cross-precision accumulation across loop boundaries. |
| Reuse accumulators | `python3 -m pytest -q third_party/mthreads/python/test/unit/tle/test_tle_sqmma_acc_reuse.py --device musa` | Moore Threads | Accumulator reuse and required waits. |
| Reuse TMA-store buffers | `python3 -m pytest -q python/test/tle/integration/test_tle_tma_store_dataflow.py` | NVIDIA Hopper integration build containing [#1166](https://github.com/flagos-ai/FlagTree/pull/1166), not yet merged | TMA-store outputs across branches, loops and source-buffer reuse. |

On PPU and Moore Threads builds containing #1116/#1189, run the low-precision examples and check their conversion, packing and matrix-product assertions:

```bash
python3 python/tutorials/mixed_precision/01-fp8.py
python3 python/tutorials/mixed_precision/02-fp4.py
python3 python/tutorials/mixed_precision/03-int8.py
python3 python/tutorials/mixed_precision/04-int4.py
```

Hygon and MetaX low-precision tests depend on [#1587](https://github.com/flagos-ai/FlagTree/pull/1587) and [#1493](https://github.com/flagos-ai/FlagTree/pull/1493), both under review. Add the selected warp-specialized barrier-removal device cases with their implementation. Retain the affected layout, instruction-order and barrier IR regressions as compiler checks. Report failures and skips separately; a successful exit from an unsupported example is not a device pass.

### Results and coverage

For every selected pair, retain the commands, numerical results, first-use/tuning measurements where applicable, and steady-state latencies. Compare with the vendor-native or agreed reference; add compiler-version comparisons when operator sources are unchanged. Before calculating speedups, check that the saved records match in device, shapes/strides, input/output/accumulation dtypes, quantization settings and timing method. Exclude mismatched, missing, failed or skipped results from speedup calculations. Report both latencies and speedup as `reference latency / candidate latency`, including regressions. Confirm per-case thresholds and aggregation with the Owner before testing. Count only pairs with completed device correctness and performance results toward the twenty-pair coverage.

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

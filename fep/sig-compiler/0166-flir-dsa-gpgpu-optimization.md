# FEP-0166: FLIR Optimization for Ascend and MetaX

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Extend [FlagTree](https://github.com/flagos-ai/FlagTree) and [FLIR](https://github.com/flagos-ai/flir) with Tensor View, L1 reuse and vectorization on Ascend, and layout optimization and Warp lowering on MetaX. Improve key-operator performance and publish optimization templates, Skills and instruction benchmarks for AI for FlagOS.

## Goals

| Goal | Deliverable |
|---|---|
| G1 — Ascend | Support Tensor View for irregular memory access, L1 data reuse and on-chip memory management, and instruction vectorization. Target at least 30% improvement on selected key operators over the current FlagGems implementation, with CANN 9.1 as the planned environment. Prioritize Ascend 950 performance and GLM5.3 key operators. |
| G2 — MetaX | Adapt the CommonIR path to MetaX, improve layout inference and optimization, evaluate layouts using swizzling, layout-conversion and memory-coalescing costs, and complete Tile Op → Warp Op → TTGIR lowering. Target at least 30% improvement on selected key operators; the comparison baseline remains to be confirmed. Layout evaluation and Warp integration remain to be completed. |
| G3 — Optimization knowledge | Publish performance optimization templates and Skills for Ascend and MetaX, and an instruction-level benchmark knowledge base for MetaX. |

The key-operator lists, test shapes/dtypes and MetaX device model remain to be confirmed with the developers.

## Packaging

Ship the compiler changes in the corresponding FlagTree wheel, with matching FLIR dependencies. Publish examples, instruction benchmarks, templates and Skills with their source and environment requirements.

Build from the FlagTree repository root in the backend's documented SDK environment. Ascend uses `triton_v3.5.x`; MetaX uses `main` with the CommonIR integration changes:

```bash
# Ascend
FLAGTREE_BACKEND=ascend python3 -m pip wheel . \
  --no-deps --no-build-isolation --wheel-dir dist

# MetaX
FLAGTREE_BACKEND=metax FLAGTREE_COMMON_IR=1 python3 -m pip wheel . \
  --no-deps --no-build-isolation --wheel-dir dist
```

## Test Plan

Record the device model, SDK/driver, PyTorch, FlagTree and FLIR revisions. Run the following commands from the corresponding FlagTree checkout. Use each test's numerical reference and tolerances, and record failures and skips.

### G1: Ascend

Confirm the device model and matching CANN/driver versions before testing. The #1483 report covers Ascend 910C; Ascend 950 validation is pending.

**Tensor View:** Use the integration branch containing [FlagTree #1483](https://github.com/flagos-ai/FlagTree/pull/1483), its dependencies #1480/#1482 and FLIR #87. These changes are still under review.

```bash
for case in test/CommonIR/Ascend/success_case/tensor_view/*.py; do
  python3 "$case" || exit 1
done
```

Check the directory examples against their numerical references. The cases added in #1483 cover partial tail blocks, non-power-of-two widths, partition/strided views, gather/scatter and ragged/paged layouts.

**Vectorization:** Run the existing MHC case and benchmark on the Ascend build containing [FlagTree #1306](https://github.com/flagos-ai/FlagTree/pull/1306) and FLIR #76:

```bash
TRITON_ALWAYS_COMPILE=1 MLIR_ENABLE_DUMP=1 \
  python3 test/CommonIR/Ascend/mhc/test_mhc_pre_clamp_sinkhorn.py \
  --device npu --check 2> lane-vectorize.mlir.log
python3 test/CommonIR/Ascend/performance_case/bench_mhc_pre_lane_vectorize.py \
  --kernel mhc_pre_clamp_sinkhorn --sweep --check --mode wall
```

Check outputs and inspect the lane-vectorization pass output in `lane-vectorize.mlir.log`. Record wall-clock latency with synchronization and host overhead included.

**L1 reuse:** Validate an operator that reuses data in L1, checking its output and L1 buffer usage. The operator case and command remain to be supplied with the implementation.

### G2: MetaX

**Layout optimization:** Use the integration branch containing [FlagTree #1471](https://github.com/flagos-ai/FlagTree/pull/1471) and FLIR #79, with `FLAGTREE_COMMON_IR=1` at build time and SciPy >= 1.12. Both PRs are under review.

```bash
python3 -m pytest -q test/CommonIR/tle/09-maca-matmul_tn_1.py
python3 test/CommonIR/tle/09-maca-matmul_tn_1.py --benchmark
```

Check FP16 matrix multiplication against PyTorch on the script's supported shapes and record both latencies. The example exercises `@triton.layout_tune()` and requires dimensions divisible by 128. The explicit-layout example uses `tle.gpu.set_layout` in its recurrent kernel:

```bash
python3 test/CommonIR/tle/11-kda_sigmoid_gate_update.py
```

Check every reported accuracy result against the script's reference. Any `False` or `ERR` result is a failure; the script does not propagate these failures through its exit status. The current autotuner benchmarks layout candidates; coverage of the layout-evaluation model remains to be completed with its implementation.

**Warp lowering:** Complete an operator test that passes through Tile Op → Warp Op → TTGIR and checks the device output against a reference. [FLIR #81](https://github.com/flagos-ai/flir/pull/81) provides work in progress on Warp IR; the integrated MetaX test and command are pending.

### G1–G2: key-operator performance

Use the confirmed operator lists to compare implementations on the same device, inputs, dtype and runtime environment. For Ascend, pin the current FlagGems baseline revision and record the implementation actually executed, including any fallback; for MetaX, confirm and pin the reference implementation. Use the same timing method for both implementations. Record correctness and both latencies per case, with speedup calculated as reference latency / optimized latency. The target is at least 1.30x.

### G3: optimization knowledge

Run the delivered instruction benchmarks and optimization examples using their documented commands and hardware. Check example outputs and record measurements with the source and environment versions. The benchmark and Skill artifacts remain to be supplied.

## Related PRs

- Baseline: [FEP-0095](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0095-flagtree-common-ir.md), [FlagTree #974](https://github.com/flagos-ai/FlagTree/pull/974).
- [x] [FlagTree #1426](https://github.com/flagos-ai/FlagTree/pull/1426) and [FLIR #83](https://github.com/flagos-ai/flir/pull/83) — Ascend Tensor View access and lowering.
- [x] [FlagTree #1306](https://github.com/flagos-ai/FlagTree/pull/1306) and [FLIR #76](https://github.com/flagos-ai/flir/pull/76) — Lane vectorization.
- [ ] [FlagTree #1483](https://github.com/flagos-ai/FlagTree/pull/1483) — Tensor View examples; dependencies [#1480](https://github.com/flagos-ai/FlagTree/pull/1480), [#1482](https://github.com/flagos-ai/FlagTree/pull/1482) and [FLIR #87](https://github.com/flagos-ai/flir/pull/87).
- [ ] [FlagTree #1471](https://github.com/flagos-ai/FlagTree/pull/1471) and [FLIR #79](https://github.com/flagos-ai/flir/pull/79) — MetaX layouts and layout autotuning.
- [ ] [FLIR #81](https://github.com/flagos-ai/flir/pull/81) — Warp IR infrastructure and conversion work.

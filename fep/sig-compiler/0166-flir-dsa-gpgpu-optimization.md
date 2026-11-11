# FEP-0166: FLIR Optimization for Ascend and MetaX

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** @kateyijian

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Extend [FlagTree](https://github.com/flagos-ai/FlagTree) and [FLIR](https://github.com/flagos-ai/flir) with Tensor View, L1 reuse and vectorization on Ascend, and layout optimization and Warp lowering on MetaX. Improve key-operator performance and publish optimization templates, Skills and instruction benchmarks for AI for FlagOS.

## Goals

| Goal | Deliverable |
|---|---|
| G1 — Ascend | Support Tensor View for irregular memory access; add L1 data reuse and on-chip memory management; improve instruction vectorization. |
| G2 — MetaX | Adapt the CommonIR path to MetaX; improve layout inference and optimization, including layout evaluation using swizzling, layout-conversion and memory-coalescing costs; complete Tile Op → Warp Op → TTGIR lowering. Layout evaluation and Warp integration remain to be completed. |
| G3 — Optimization knowledge | Publish performance optimization templates and Skills for Ascend and MetaX, and an instruction-level benchmark knowledge base for MetaX. |

Target at least 30% performance improvement on selected key operators on Ascend and MetaX. Use the current FlagGems implementation as the Ascend baseline; the MetaX baseline remains to be confirmed. Prioritize Ascend 950 performance and GLM5.3 key operators, with CANN 9.1 as the planned environment.

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

Run the tests from the matching FlagTree checkout with its backend-specific installation. Record the device model, SDK/driver, PyTorch version and FlagTree/FLIR revisions. Each case records its shape, dtype, numerical reference and tolerance. Report failures and skips separately.

### G1: Ascend

**Tensor View:** In the integration checkout for [#1483](https://github.com/flagos-ai/FlagTree/pull/1483) (not yet merged), with its listed FlagTree/FLIR dependencies, run:

```bash
python3 test/CommonIR/Ascend/success_case/tensor_view/index_select.py
python3 test/CommonIR/Ascend/success_case/tensor_view/paged_kv_block_gather.py
```

**Check:** Compare index selection and paged-KV block gathering with the scripts' PyTorch references. The index-selection cases include partial tail blocks and non-power-of-two row widths.

**Instruction vectorization:** Run the MHC regression included in [#1306](https://github.com/flagos-ai/FlagTree/pull/1306) on the Ascend build:

```bash
python3 test/CommonIR/Ascend/mhc/test_mhc_pre_clamp_sinkhorn.py \
  --device npu --check
```

**Check:** Verify `y`, `post_out` and `comb_frag` against the script's reference using its numerical tolerances.

**L1 reuse and on-chip memory management:** Supply the missing operator case and command with the implementation. Identify the L1 reuse path exercised by the case and compare the operator output with its reference.

### G2: MetaX

**CommonIR and layout optimization:** Use an integration build containing [#1471](https://github.com/flagos-ai/FlagTree/pull/1471) and [FLIR #79](https://github.com/flagos-ai/flir/pull/79), both under review. Build with `FLAGTREE_COMMON_IR=1` and install SciPy >= 1.12, then run:

```bash
python3 -m pytest -q test/CommonIR/tle/09-maca-matmul_tn_1.py
python3 test/CommonIR/tle/11-kda_sigmoid_gate_update.py
```

**Check:** Compare the FP16 matrix-multiplication cases using layout autotuning with PyTorch. Check the explicit-layout KDA example against its reference; any reported `False` or `ERR` is a failure even if the process exits successfully. Add cases covering the layout-evaluation model and resulting operator outputs with that implementation.

**Warp lowering:** Complete the MetaX integration case and command for [FLIR #81](https://github.com/flagos-ai/flir/pull/81). Verify that the case compiles through Tile Op → Warp Op → TTGIR and that its device output matches the reference. The integrated case is still pending.

### G1–G2: key-operator performance

Confirm the operator lists, shapes/dtypes, device configurations and performance assessment criteria with the Owner before testing. Pin the current FlagGems baseline for Ascend and the agreed reference for MetaX, recording the implementations actually executed.

Run correctness and benchmark commands supplied with the selected operators. Match the device, inputs, dtype, runtime environment and timing method. Report both latencies and speedup as `reference latency / optimized latency` per case. Assess the 30% target using the agreed criteria across cases.

### G3: optimization knowledge

Run the examples accompanying the Ascend and MetaX optimization templates and Skills, and the MetaX instruction benchmarks, using their documented commands and environments. Supply these artifacts and commands before acceptance.

**Check:** Verify example outputs against their supplied references. Record instruction-benchmark measurements with the source revision and hardware/software versions for the knowledge base.

## Related PRs

- Baseline: [FEP-0095](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0095-flagtree-common-ir.md), [FlagTree #974](https://github.com/flagos-ai/FlagTree/pull/974).
- [x] [FlagTree #1426](https://github.com/flagos-ai/FlagTree/pull/1426) and [FLIR #83](https://github.com/flagos-ai/flir/pull/83) — Ascend Tensor View access and lowering.
- [x] [FlagTree #1306](https://github.com/flagos-ai/FlagTree/pull/1306) and [FLIR #76](https://github.com/flagos-ai/flir/pull/76) — Lane vectorization.
- [ ] [FlagTree #1483](https://github.com/flagos-ai/FlagTree/pull/1483) — Tensor View examples; dependencies [#1480](https://github.com/flagos-ai/FlagTree/pull/1480), [#1482](https://github.com/flagos-ai/FlagTree/pull/1482) and [FLIR #87](https://github.com/flagos-ai/flir/pull/87).
- [ ] [FlagTree #1471](https://github.com/flagos-ai/FlagTree/pull/1471) and [FLIR #79](https://github.com/flagos-ai/flir/pull/79) — MetaX layouts and layout autotuning.
- [ ] [FLIR #81](https://github.com/flagos-ai/flir/pull/81) — Warp IR infrastructure and conversion work.

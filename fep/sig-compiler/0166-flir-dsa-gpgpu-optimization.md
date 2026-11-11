# FEP-0166: FLIR Optimization for Ascend and MetaX

**Status:** `Provisional`

**Implementation Status:** `In Progress`

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

The Owner supplies cases and commands for each feature, including numerical references and tolerances where applicable. Record the device model, SDK/driver and software revisions, and report failures and skips.

| Goal | Feature | Validation |
|---|---|---|
| G1 | Tensor View | Compile and run irregular-memory-access cases on Ascend; compare outputs with their references. |
| G1 | L1 reuse and on-chip memory management | Run cases that use L1 data reuse and on-chip buffers; compare outputs with their references. |
| G1 | Instruction vectorization | Run vectorized operator cases on Ascend; compare outputs with their references. |
| G2 | CommonIR adaptation and layout optimization | Compile and run CommonIR cases covering layout inference, optimization and evaluation on MetaX; compare operator outputs with their references. |
| G2 | Warp lowering | Compile and run MetaX cases through Tile Op → Warp Op → TTGIR; compare outputs with their references. |
| G3 | Optimization templates and Skills | Run the accompanying Ascend and MetaX examples and check their outputs. |
| G3 | Instruction-level benchmark knowledge base | Run the MetaX instruction benchmarks and record their results with the hardware and software versions. |

For key-operator performance, compare the baseline and optimized implementations on the same device, inputs, dtype, runtime environment and timing method. Record the actual implementations and both latencies. Assess the 30% target using the operator list and evaluation criteria confirmed by the Owner.

Before acceptance, the Owner confirms the key-operator lists, shapes/dtypes, device configurations, MetaX baseline and how the performance target is assessed across cases, and supplies missing feature tests.

## Related PRs

- Baseline: [FEP-0095](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0095-flagtree-common-ir.md), [FlagTree #974](https://github.com/flagos-ai/FlagTree/pull/974).
- [x] [FlagTree #1426](https://github.com/flagos-ai/FlagTree/pull/1426) and [FLIR #83](https://github.com/flagos-ai/flir/pull/83) — Ascend Tensor View access and lowering.
- [x] [FlagTree #1306](https://github.com/flagos-ai/FlagTree/pull/1306) and [FLIR #76](https://github.com/flagos-ai/flir/pull/76) — Lane vectorization.
- [ ] [FlagTree #1483](https://github.com/flagos-ai/FlagTree/pull/1483) — Tensor View examples; dependencies [#1480](https://github.com/flagos-ai/FlagTree/pull/1480), [#1482](https://github.com/flagos-ai/FlagTree/pull/1482) and [FLIR #87](https://github.com/flagos-ai/flir/pull/87).
- [ ] [FlagTree #1471](https://github.com/flagos-ai/FlagTree/pull/1471) and [FLIR #79](https://github.com/flagos-ai/flir/pull/79) — MetaX layouts and layout autotuning.
- [ ] [FLIR #81](https://github.com/flagos-ai/flir/pull/81) — Warp IR infrastructure and conversion work.

# FEP-0097: FlagTree FlagTune, Layout and Instruction Optimization

**Status:** `Implemented`

**Updated:** 2026-09-24

**Created:** 2026-08-01

**Owner:** Unassigned

**SIG:** sig-compiler

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| flagtree-triton3.6 | [`0.7.0-rc2-triton3.6` @ `4819c190476c`](https://github.com/flagos-ai/FlagTree/tree/4819c190476cebb66057493e41379c1406c615ac) | [`0.7.0rc2.post2+triton3.6` @ `d9e65f4df7fe`](https://github.com/flagos-ai/FlagTree/tree/d9e65f4df7fe881281abd9e834ab3f37f4d0642c) |

## Summary

FlagTree adds model-guided autotuning, phased layout-conversion
removal, load reordering during loop unrolling and ordered dot-operand
fusion. These transformations are included in the Triton 3.6 RC2 line.

## Delivered Scope

| Feature | Implementation | Validation |
|---|---|---|
| FlagTune | Model loading, XGBoost ranking and optional genetic search | Unit coverage and mul/mm tuning results |
| Layout optimization | Phased conversion removal and explicit layout anchors | Compiler/FlagGems CI and per-shape timings |
| Load reordering | `tle.range(..., reorder=True)` and `ReorderLoopLoads` | Fused quantization benchmarks |
| Dot fusion | `ConcatDotOperand` | Core tests, bit-identical outputs and MoE timings |

## Design

`triton.flagtune` is enabled with `FLAGTUNE_ENABLE=1`. Model identity uses
`(platform_key, op_id, variant, dtype_key)`. Bundles contain the feature
schema, legal parameter space, version and digests. XGBoost ranks candidates;
optional genetic search refines them through measurement. Disabled or unnamed
tuners use ordinary Triton pruning. Enabled named tuners reject missing or
incompatible model bundles.

Layout passes propagate explicit anchors and remove redundant conversions.
`tle.range(..., loop_unroll_factor=..., reorder=True)` clusters loads during
unrolling. `ConcatDotOperand` combines ordered K-axis fragments before a dot.
The same-warp shuffle change from PR #1047 was reverted by #1139 and is not
an active RC2 optimization.

## Packaging

Compiler passes and `triton.flagtune` ship in the FlagTree wheel. PyYAML is a
package dependency; XGBoost is loaded when a model is used.

```bash
python -m pip wheel . --no-build-isolation --no-deps -w dist
```

## Test Commands

```bash
python -m pytest -q python/test/flagtune
python -m pytest -q python/test/tle/unit/test_tle.py
python -m pytest -q python/test/tle/integration
```

Run the configured build's `check-triton-tle-lit-tests` target for compiler
regressions. FlagTune tests must cover model identity, archive validation,
disabled-mode fallback, model-contract errors, backend timing and stream
ordering. Numerical tests must match reference outputs with tuning enabled
and disabled.

## Validation

| Feature | Recorded result |
|---|---|
| FlagTune | [Compiler delivery](https://jwolpxeehx.feishu.cn/docx/HwHNdMsfCoAXoRxmeNzcNZZQnMe): 12× faster mul tuning on NVIDIA/MetaX/Hygon/PPU/MUSA; 298× faster mm tuning on NVIDIA/MetaX/PPU |
| Layout | [PR #763](https://github.com/flagos-ai/FlagTree/pull/763): roughly 68–79% aggregate conversion elimination; NVIDIA unit and FlagGems CI passed |
| Load reordering | [PR #775](https://github.com/flagos-ai/FlagTree/pull/775): 12.49–18.02% improvement on the listed inverse-RoPE/FP8 quantization shapes |
| Dot fusion | [PR #892](https://github.com/flagos-ai/FlagTree/pull/892): 2,592 core tests passed; bit-identical outputs on 53 MoE shapes; 4.74% lower weighted total latency on H20-3e |

Performance results apply to the hardware, shapes and baselines in each
linked record. Model bundles are distributed separately from the compiler wheel.

## Related PRs

- [x] [FlagTree#850](https://github.com/flagos-ai/FlagTree/pull/850) — FlagTune model-guided autotuning. Merged.
- [x] [FlagTree#1055](https://github.com/flagos-ai/FlagTree/pull/1055) — Additional FlagTune accelerator backends. Merged.
- [x] [FlagTree#1103](https://github.com/flagos-ai/FlagTree/pull/1103) — Remote manifest defaults and runtime compatibility; ported into RC2. Merged.
- [x] [FlagTree#1129](https://github.com/flagos-ai/FlagTree/pull/1129) — Caller-stream ordering during graph benchmarks. Merged.
- [x] [FlagTree#763](https://github.com/flagos-ai/FlagTree/pull/763) — Phased layout conversion removal. Merged.
- [x] [FlagTree#908](https://github.com/flagos-ai/FlagTree/pull/908) — Explicit layout API. Merged.
- [x] [FlagTree#946](https://github.com/flagos-ai/FlagTree/pull/946) — TLE tile layout anchors. Merged.
- [x] [FlagTree#1139](https://github.com/flagos-ai/FlagTree/pull/1139) — Revert the same-warp shuffle conversion change. Merged.
- [x] [FlagTree#775](https://github.com/flagos-ai/FlagTree/pull/775) — Load reordering during loop unrolling; included in RC2. Merged.
- [x] [FlagTree#892](https://github.com/flagos-ai/FlagTree/pull/892) — Ordered K concatenation into one dot operand; included in RC2. Merged.

## Deferred to FlagOS 2.3

Additional barrier elimination and TMA-store synchronization optimization: [FlagTree#1166](https://github.com/flagos-ai/FlagTree/pull/1166).

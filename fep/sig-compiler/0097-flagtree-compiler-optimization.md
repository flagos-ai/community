# FEP-0097: FlagTree Compiler Optimization — FlagTune, Layout, Synchronization, and Instruction Scheduling

**Status:** `Implementable`

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

Add model-guided autotuning and improve layout conversion, synchronization
and instruction scheduling. RC2 contains FlagTune, layout conversion
optimization, explicit synchronization and load/dot reordering. Feature PRs record
correctness and performance results. Later barrier optimization is still open.

## Goals and Completion

| Goal | RC2 implementation | Validation and remaining work |
|---|---|---|
| G1: Reduce autotuning cost with a performance predictor | `python/triton/flagtune/`, model loading, XGBoost ranking and optional genetic search | Reported mul/mm tuning speedups; exact model/workload bundles need release attribution |
| G2: Reduce layout conversion cost | Phased layout conversion removal, explicit layouts and tile anchors | PR #763 records conversion counts and per-operator timings |
| G3: Improve synchronization | Signal/wait and distributed barrier primitives present | Existing warp-specialized operators have results; later barrier elimination in #1166 is open |
| G4: Instruction reordering and fusion | Load clustering in LoopUnroll (#775) and dot-operand concatenation (#892) | Feature correctness and performance results recorded |

## Design

### FlagTune

`triton.flagtune` is an opt-in autotuning extension. Set `FLAGTUNE_ENABLE=1`
before importing the runtime. Model identity uses
`(platform_key, op_id, variant, dtype_key)`. Model bundles carry the feature
schema, legal parameter space, version and digests. XGBoost ranks candidates;
optional genetic search refines them through measurement. Disabled or unnamed
tuners use ordinary Triton pruning. When enabled with
a model identity, missing or incompatible model bundles raise an error.

RC2 includes remote manifest defaults, runtime compatibility handling and
caller-stream ordering fixes. Model assets remain separate from the compiler
wheel. Record model version and digest with performance results.

### Compiler passes

Layout work modifies `RemoveLayoutConversions`, TLE layout anchors and
coalescing. Synchronization changes add explicit communication primitives.
The same-warp shuffle conversion change from PR #1047 was reverted by #1139
and is not an active RC2 optimization.

`tle.range(..., loop_unroll_factor=..., reorder=True)` clusters loads during
unrolling through `ReorderLoopLoads`. `ConcatDotOperand` folds ordered
K-axis fragments into a single dot operand. Both implementations are present
in RC2. The later barrier and TMA-store scheduling changes in PR #1166
remain open and are not part of these merged transformations.

## Packaging

Compiler passes and `triton.flagtune` ship in the FlagTree wheel. PyYAML is a
package dependency; XGBoost is loaded when a model is used.

```bash
python -m pip wheel . --no-build-isolation --no-deps -w dist
```

## Test Plan

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

For each optimization, record the operator, shape, dtype, hardware, compiler
revision, baseline and measurement protocol. G1 additionally requires tuning
wall time and the selected configuration's gap from exhaustive search. G2–G4
require before/after latency and numerical results. Preserve the tested model
assets, workloads and compiler revisions with each result.

## Recorded Validation

| Track | Recorded result |
|---|---|
| FlagTune | The [compiler delivery record](https://jwolpxeehx.feishu.cn/docx/HwHNdMsfCoAXoRxmeNzcNZZQnMe) reports 12× faster tuning for mul across NVIDIA, MetaX, Hygon, PPU and MUSA, and 298× for mm across NVIDIA, MetaX and PPU |
| Layout | [PR #763](https://github.com/flagos-ai/FlagTree/pull/763) records roughly 68–79% aggregate conversion elimination and per-shape timings; its NVIDIA unit and FlagGems CI passed |
| Synchronization | The delivery record lists validated warp-specialized mm, FP8 matmul and attention kernels; the additional barrier-elimination benchmark belongs to open PR #1166 |
| Load reordering | [PR #775](https://github.com/flagos-ai/FlagTree/pull/775) records 12.49–18.02% improvements for the listed fused inverse-RoPE/FP8 quantization shapes |
| Dot fusion | [PR #892](https://github.com/flagos-ai/FlagTree/pull/892) records 2,592 relevant core tests passed, bit-identical outputs on 53 MoE shapes and 4.74% lower call-weighted total latency on H20-3e |

The remaining items are the model/workload revision mapping and the open
barrier optimization, including its separate synchronization measurements.

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
- [ ] [FlagTree#1166](https://github.com/flagos-ai/FlagTree/pull/1166) — Additional barrier and TMA-store synchronization optimization. Open.

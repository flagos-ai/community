# FEP-0097: FlagTree Compiler Optimization — FlagTune, Layout, Synchronization, and Instruction Scheduling

**Status:** `Provisional`

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
and instruction scheduling. RC2 contains FlagTune and layout changes;
quantified performance acceptance for all four tracks remains incomplete.

## Goals and Completion

| Goal | RC2 implementation | Remaining work |
|---|---|---|
| G1: Reduce autotuning cost with a performance predictor | `python/triton/flagtune/`, model loading, XGBoost ranking and optional genetic search | Fixed workloads, exhaustive-search comparison and accepted search-time/quality thresholds |
| G2: Reduce layout conversion cost | Phased layout conversion removal, explicit layouts and tile anchors | Per-operator conversion counts and latency comparison |
| G3: Improve synchronization | Signal/wait and distributed barrier primitives present | Isolated warp-specialized kernel performance results |
| G4: Instruction reordering and fusion | Existing Triton scheduler infrastructure present | Identify the new 2.2 transformation and its acceptance benchmark |

## Design

### FlagTune

`triton.flagtune` is an opt-in autotuning extension. Set `FLAGTUNE_ENABLE=1`
before importing the runtime. Model identity uses
`(platform_key, op_id, variant, dtype_key)`. Model bundles carry the feature
schema, legal parameter space, version and digests. XGBoost ranks candidates;
optional genetic search refines them through measurement. Disabled or unnamed tuners use ordinary Triton pruning. When enabled with
a model identity, missing or incompatible model bundles raise an error.

RC2 includes remote manifest defaults, runtime compatibility handling and
caller-stream ordering fixes. Model assets remain separate from the compiler
wheel. Record model version and digest with performance results.

### Compiler passes

Layout work modifies `RemoveLayoutConversions`, TLE layout anchors and
coalescing. Synchronization changes add explicit communication primitives.
The same-warp shuffle conversion change from PR #1047 was reverted by #1139
and is not an active RC2 optimization.

A separate new instruction-fusion implementation is not identified in RC2;
the existing pipeliner and reordering passes remain the starting point.

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
ordering. Numerical tests
must match reference outputs with tuning enabled and disabled.

For each optimization, record the operator, shape, dtype, hardware, compiler
revision, baseline and measurement protocol. G1 additionally requires tuning
wall time and the selected configuration's gap from exhaustive search. G2–G4
require before/after latency and numerical results. Those acceptance reports
and thresholds remain outstanding.

## Related PRs

- [x] [FlagTree#850](https://github.com/flagos-ai/FlagTree/pull/850) — FlagTune model-guided autotuning. Merged.
- [x] [FlagTree#1055](https://github.com/flagos-ai/FlagTree/pull/1055) — Additional FlagTune accelerator backends. Merged.
- [x] [FlagTree#1103](https://github.com/flagos-ai/FlagTree/pull/1103) — Remote manifest defaults and runtime compatibility; ported into RC2. Merged.
- [x] [FlagTree#1129](https://github.com/flagos-ai/FlagTree/pull/1129) — Caller-stream ordering during graph benchmarks. Merged.
- [x] [FlagTree#763](https://github.com/flagos-ai/FlagTree/pull/763) — Phased layout conversion removal. Merged.
- [x] [FlagTree#908](https://github.com/flagos-ai/FlagTree/pull/908) — Explicit layout API. Merged.
- [x] [FlagTree#946](https://github.com/flagos-ai/FlagTree/pull/946) — TLE tile layout anchors. Merged.
- [x] [FlagTree#1139](https://github.com/flagos-ai/FlagTree/pull/1139) — Revert the same-warp shuffle conversion change. Merged.

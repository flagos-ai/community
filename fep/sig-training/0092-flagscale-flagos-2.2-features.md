# FEP-0092: FlagScale Features for FlagOS 2.2

**Status:** `Implementable`

**Updated:** 2026-09-24

**Created:** 2026-07-30

**Owner:** Unassigned

**SIG:** sig-training

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| flagscale | [`2.1.0-rc2` @ `333964d5937e`](https://github.com/flagos-ai/FlagScale/tree/333964d5937ec2401d4324b92569158c663154de) | [`v2.1.0-rc2.post2` @ `333964d5937e`](https://github.com/flagos-ai/FlagScale/tree/333964d5937ec2401d4324b92569158c663154de) |

## Summary

FlagScale 2.1 adds training observability, model/checkpoint updates,
function-level overrides, native Ascend integration and a shared VLA serving
entry point. The RC2 source contains these changes and the Megatron Core
0.18.2 integration. Training and checkpoint validation is recorded below; other model and
serving goals retain separate acceptance items.

DeepSeek-V4 base support and initial Qwen3.5 support belong to the FlagOS 2.1
baseline. The 2.2 changes extend their training and checkpoint paths.

## Goals and Completion

| Goal | RC2 implementation | Remaining acceptance |
|---|---|---|
| G1: Observability | Straggler detector, performance monitor and progress heartbeat | Distributed training reports and monitoring overhead |
| G2: Models | Qwen3.5 conversion, Qwen3-VL, Qwen-GR00T Orca, GLM5 and Qwen3.6 paths | Per-model training and checkpoint results |
| G3: Multi-platform integration | Function overrides, device dispatch and in-tree Ascend adaptor | Platform dispatch and training regression |
| G4: Checkpoints | GR00T portability and Qwen3.5 uneven-PP/Qwen3.6 conversion | Cross-node reload and numerical round trips |
| G5: Performance | DeepSeek-V4 FLOPs accounting, DualPipeV fix and PI0.5 loading changes | Scheduling regression and measured memory/throughput |
| G6: VLA serving | Shared `run_serve_vla.py` entry point | PI0, PI0.5, Qwen-GR00T and GR00T N1.5 serving results |
| G7: Engineering | Vendor training CI, golden updates and license headers | Completed RC2 platform matrix |

## Design

`flagscale/runner/straggler/` collects rank-level progress and reports slow
workers. `flagscale/train/perf_monitor/` records step performance, estimated
FLOPs and memory. Both have unit tests and standalone distributed smoke
programs.

The override plugin replaces selected Megatron functions through registered
device-specific implementations. Its dispatch tests are in
`flagscale/train/megatron/plugin_flagscale/test_override.py`. Ascend's
MegatronAdaptor is integrated in-tree; the vendor runtime remains an external
dependency.

Checkpoint tools extend the existing model workflow. VLA serving selects
PI0/PI0.5/Qwen-GR00T/GR00T N1.5 from one entry point under
`flagscale/serve/`. PI0.5 loading uses empty-weight initialization and assigned
state to reduce peak allocation.

RC2 includes the Megatron 0.18.2 update and Enflame/Kunlunxin CI work. PR
#1283 removes inference/serving CI and focuses the unified workflow on
training; the presence of VLA test files does not establish an active VLA CI
lane.

## Packaging

Use the pinned FlagScale source with the platform-specific training image
and matching Megatron-LM-FL/TransformerEngine-FL versions. The module version
is 2.1.0 within FlagOS 2.2. The YAML runner remains the user entry point.
Debian/RPM integration is still open in PR #1205 and tracked by
[FEP-0019](../sig-os/0019-unified-package-integration.md).

## Test Plan

From the RC2 checkout in the configured training environment:

```bash
python -m pytest -q tests/unit_tests/runner/straggler \
  tests/unit_tests/runner/test_runner_train_straggler.py \
  tests/unit_tests/train/test_perf_monitor.py
python -m pytest -q tests/unit_tests/checkpoint/test_qwen35_converter.py
python -m pytest -q flagscale/train/megatron/plugin_flagscale/test_override.py
```

Standalone observability checks on two configured workers:

```bash
torchrun --standalone --nproc_per_node=2 tools/straggler/straggler_smoke.py \
  --output-dir /tmp/flagscale-straggler
torchrun --standalone --nproc_per_node=2 tools/perf_monitor/perf_smoke.py \
  --output-dir /tmp/flagscale-perf
```

Require valid rank reports and performance records. Run the model's checked-in
training configuration and checkpoint conversion on each claimed platform;
verify loss against its reference, reload correctness and uneven-PP handling.
For GR00T, reload on another node. For PI0.5, compare peak loading memory
against the previous implementation. For DualPipeV, verify completion and
reference-compatible gradients under the affected schedule.

Run all four VLA families through the shared serving entry and validate
responses against the corresponding model reference. Record these runs
separately from training CI. Preserve source/dependency revisions, model
configuration, hardware, logs and measurements for the release matrix.

## Recorded Validation

The [September 24 execution matrix](https://jwolpxeehx.feishu.cn/wiki/Kg47wjKm1if8eOk1GfscLiIcnDe) records Qwen3-0.6B training,
checkpoint save/load and converted-weight continuation across PPU, Hygon,
Ascend and MetaX. Qwen3.5-4B also passed the vendor and FlagOS TE routes
with FlagCX disabled, including 2TP-to-4TP checkpoint conversion.

The full-stack paths have narrower coverage: selected FlagGems operators
are disabled on PPU/MetaX, and the matrix records failing Qwen3.5 cases on
Hygon/Ascend with FlagGems enabled. FlagCX training is a separate unresolved
path, tracked in [Megatron-LM-FL#172](https://github.com/flagos-ai/Megatron-LM-FL/issues/172).

These results cover real training and checkpoint paths. They do not cover
all four VLA serving families, GR00T cross-node reload or the monitoring
overhead targets in this FEP. Those remaining cases need their own results.

## Related PRs

- [x] [FlagScale#1215](https://github.com/flagos-ai/FlagScale/pull/1215) — Straggler detection. Merged.
- [x] [FlagScale#1216](https://github.com/flagos-ai/FlagScale/pull/1216) — Performance monitor. Merged.
- [x] [FlagScale#1243](https://github.com/flagos-ai/FlagScale/pull/1243) — Low-overhead progress heartbeat. Merged.
- [x] [FlagScale#1214](https://github.com/flagos-ai/FlagScale/pull/1214) — Function-level override plugin. Merged.
- [x] [FlagScale#1226](https://github.com/flagos-ai/FlagScale/pull/1226) — Native Ascend adaptor. Merged.
- [x] [FlagScale#1233](https://github.com/flagos-ai/FlagScale/pull/1233) — Qwen3.5 MoE conversion and uneven pipeline parallelism. Merged.
- [x] [FlagScale#1235](https://github.com/flagos-ai/FlagScale/pull/1235) — Qwen3-VL update. Merged.
- [x] [FlagScale#1228](https://github.com/flagos-ai/FlagScale/pull/1228) — Qwen-GR00T Orca features. Merged.
- [x] [FlagScale#1219](https://github.com/flagos-ai/FlagScale/pull/1219) — GR00T checkpoint portability. Merged.
- [x] [FlagScale#1230](https://github.com/flagos-ai/FlagScale/pull/1230) — DeepSeek-V4 FLOPs accounting. Merged.
- [x] [FlagScale#1207](https://github.com/flagos-ai/FlagScale/pull/1207) — DualPipeV scheduling fix. Merged.
- [x] [FlagScale#1221](https://github.com/flagos-ai/FlagScale/pull/1221) — PI0.5 loading memory reduction. Merged.
- [x] [FlagScale#1225](https://github.com/flagos-ai/FlagScale/pull/1225) — Unified VLA serving entry point. Merged.
- [x] [FlagScale#1227](https://github.com/flagos-ai/FlagScale/pull/1227) — GLM5 training. Merged.
- [x] [FlagScale#1273](https://github.com/flagos-ai/FlagScale/pull/1273) — Qwen3.6 model and checkpoint support. Merged.
- [x] [FlagScale#1284](https://github.com/flagos-ai/FlagScale/pull/1284) — Megatron Core 0.18.2 update. Merged.
- [x] [FlagScale#1275](https://github.com/flagos-ai/FlagScale/pull/1275) — Enflame CI. Merged.
- [x] [FlagScale#1282](https://github.com/flagos-ai/FlagScale/pull/1282) — Kunlunxin CI. Merged.
- [x] [FlagScale#1283](https://github.com/flagos-ai/FlagScale/pull/1283) — Training-only CI scope. Merged.
- [x] [FlagScale#1301](https://github.com/flagos-ai/FlagScale/pull/1301) — RC2 source update. Merged.

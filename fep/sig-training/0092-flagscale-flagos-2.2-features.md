# FEP-0092: FlagScale Features for FlagOS 2.2

**Status:** `Provisional`

**Created:** 2026-07-30

**Owner:** [TODO: @github-username]

**SIG:** sig-training

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP covers the FlagScale work delivered in the FlagOS 2.2
release cycle, relative to **v2.0.0-rc2.post1**, across seven areas:

1. **Training observability & stability** — Straggler Detection and Perf
   Monitor integration.
2. **Model support expansion** — Qwen3.5 checkpoint conversion, Qwen3-VL,
   Qwen-GR00T Orca, GLM5 and Qwen3.6 work. DeepSeek-V4 and the initial
   Qwen3.5 model support are already in the 2.1 baseline.
3. **Plugin & multi-platform architecture** — Override plugin upgrade
   (function-level Megatron-LM-FL overrides with cross-platform device
   dispatch) and native Ascend NPU MegatronAdaptor integration.
4. **Checkpoint tooling** — GR00T cross-node portability and Qwen3.5/Qwen3.6
   conversion, including uneven pipeline parallelism for Qwen3.5 MoE.
5. **Training performance** — DeepSeek-V4 TFLOPs accounting, DualPipeV
   scheduling fix, PI0.5 pretrained-loading memory-peak reduction.
6. **VLA serving unification** — single `run_serve_vla.py` entrypoint for
   PI0 / PI0.5 / Qwen-GR00T / GR00T N1.5.
7. **CI/CD & engineering** — expanded Ascend, MetaX, Moore Threads and Hygon
   validation, Apache 2.0 headers, and functional-test golden-value refresh.

All items are implemented on `main` (per-PR references below).

Repository: https://github.com/flagos-ai/FlagScale

## Release Boundary and Evidence

- **FlagOS 2.1 baseline:** `v2.0.0-rc2.post1` / `v2.0.0`. DeepSeek-V4
  (#1195), initial Qwen3.5 support (#1196), DeepSeek-V3 `--skip-mtp` export
  (#1202), and the initial unified multi-chip CI (#1209) are already present
  there and are not FlagOS 2.2 deliverables.
- **FlagOS 2.2 release candidate reviewed:** `v2.1.0-rc2.post1`, as pinned by
  the FlagOS 2.2 RC2 manifest.
- **Development window:** 2026-06-01 through 2026-08-31. Stabilization changes
  included in RC1/RC2 are recorded, but work is not reassigned to 2.2 merely
  because it was documented during this cycle.

The release delta includes the observability work, override upgrade, GR00T and
PI0.5 changes, VLA serve entrypoint, Ascend MegatronAdaptor, Orca features,
Qwen3.5 conversion fixes, Qwen3-VL update, GLM5, Qwen3.6, platform CI, and
release stabilization. RC2 additionally incorporates the Megatron v0.18.2
integration line and Kunlunxin/Enflame validation work. Per-PR implementation
does not replace the release-level model/platform acceptance matrix.

## Motivation

The 2.2 cycle advances FlagScale on three fronts: current model increments
(Qwen3.5 conversion, Qwen3-VL, GLM5, Qwen3.6 and VLA models), reliability of large
distributed runs (straggler detection, performance monitoring, checkpoint
portability), and the multi-platform architecture direction of FlagOS
(function-level override plugin, native NPU integration, unified multi-chip
CI), while keeping the established Megatron-LM-FL-based training stack
unchanged.

### Goals

**(Required)**

- **G1 (Observability):** Distributed training runs automatically identify
  lagging nodes and produce health reports (Straggler Detection, #1215,
  `flagscale/runner/straggler/`); training performance metrics (FLOPs,
  throughput) are collected and logged via the Perf Monitor integration
  (#1216), with a low-overhead GPU progress heartbeat added in #1243.
- **G2 (Models):** Extend Qwen3.5 MoE checkpoint conversion and uneven
  pipeline parallelism (#1231/#1233), update Qwen3-VL on current
  Megatron-LM-FL (#1235), add Qwen-GR00T Orca features (#1228), GLM5
  training (#1227), and Qwen3.6 LLM/checkpoint support (#1273).
- **G3 (Multi-platform):** Function-level Megatron-LM-FL override framework
  with cross-platform device dispatch (Override plugin upgrade, #1214);
  Ascend NPU trains via natively integrated MegatronAdaptor (FlagScale
  Module) without external adaptation dependencies (#1226).
- **G4 (Checkpoint):** GR00T checkpoints are portable across nodes (#1219);
  Qwen3.5 MoE conversion supports non-uniform pipeline parallelism (#1233);
  Qwen3.6 includes checkpoint conversion support (#1273).
- **G5 (Performance):** DeepSeek-V4 TFLOPs accounting with Engram
  IdentityOp optimization (#1230); DualPipeV bidirectional pipeline
  scheduling fixed (#1207); PI0.5 pretrained-weight loading memory peak
  reduced via `init_empty_weights()` + `assign=True` (#1221).
- **G6 (VLA serving):** One `run_serve_vla.py` entrypoint
  (`flagscale/serve/`) serves PI0, PI0.5, Qwen-GR00T, and GR00T N1.5,
  replacing per-model scripts (#1225).
- **G7 (Engineering):** Build/test workflows for Ascend and MetaX (#1250),
  S5000 end-to-end validation (#1260), and Hygon BW1000 CI (#1272); Apache
  2.0 headers on all source files (#1240); functional-test golden values
  updated to current training results (#1244).

### Non-Goals

- FlagScale-Agent (the autonomous training/inference agent system) — to be
  proposed in its own FEP.
- New inference-serving features beyond the VLA entrypoint unification
  (inference serving otherwise follows the existing FlagScale serve stack).
- Upstream Megatron-LM-FL / TransformerEngine-FL feature work (covered by
  their own FEPs in sig-framework).

## Proposal

The work is delivered as incremental features on the existing FlagScale
architecture (runner / train / serve / models layers), each independently
usable through the standard FlagScale YAML-config workflow:

- **Straggler Detection** (`flagscale/runner/straggler/`): enabled per run
  config; monitors rank-level progress during distributed training, flags
  lagging nodes, and emits a health report.
- **Perf Monitor**: collects FLOPs and training performance metrics into
  the run logs.
- **Model additions** plug into the existing model zoo + checkpoint
  conversion tool flow (`flagscale/models/`, ckpt convert tools), so
  training a new family is a config choice.
- **Override plugin**: a function-level override framework over Megatron-LM-FL —
  per-platform implementations register overrides that are dispatched by
  device type, replacing ad-hoc patching as the multi-platform mechanism.
- **Ascend MegatronAdaptor**: integrated as a FlagScale Module so NPU
  training needs no external adaptor package.
- **VLA serve**: `flagscale/serve/run_serve_vla.py` selects the model
  family by config.

## Design Details

Details per feature are in the merged PRs referenced above; the two
architecturally significant pieces:

- **Override plugin (#1214):** establishes the function-level override
  registry over Megatron-LM-FL with cross-platform device dispatch —
  platforms provide overrides without forking training code.
- **Native NPU MegatronAdaptor (#1226):** moves Ascend adaptation in-tree
  as a FlagScale Module, aligning with the same-direction change in
  TransformerEngine-FL (flagos-ai/TransformerEngine-FL#79).

<!-- TODO: if the Override framework is intended as the standard vendor
     integration path going forward, document the override API surface and
     registration contract here before Implementable. -->

## Packaging

Unchanged from the v2.0.0 line: FlagScale is used from source with its
YAML-config runner (`flagscale/run.py`); per-platform container images and
the unified CI (`all_tests`) validate CUDA / Ascend / MetaX.

<!-- TODO: confirm the 2.2 release tag scheme (v2.1.0 vs v2.0.x) and
     whether images are published per platform. -->

## Test Plan

**(Required)** Validation runs on the repository's unified CI plus targeted
functional tests:

| Goal | Verification | Status |
|---|---|---|
| G1 | Straggler detection unit/integration tests; perf-monitor metrics present in run logs | Implemented (#1215, #1216) |
| G2 | Per-model functional tests (train + ckpt convert) for Qwen3.5 MoE, Qwen3-VL, Qwen-GR00T Orca, GLM5 and Qwen3.6 | Implemented in linked PRs; release acceptance pending |
| G3 | Override dispatch tests; Ascend NPU training via native MegatronAdaptor on the Ascend CI lane | Implemented (#1214, #1226) |
| G4 | Checkpoint convert regression tests (GR00T portability, Qwen3.5 uneven PP, Qwen3.6) | Implemented (#1219, #1233, #1273) |
| G5 | DualPipeV scheduling test; PI0.5 loading memory measurement; TFLOPs accounting check | Implemented (#1207, #1221, #1230) |
| G6 | `run_serve_vla.py` serves each of the four VLA model families | Implemented (#1225) |
| G7 | Platform CI lanes green; license check; golden values current | Implemented in #1240/#1244/#1250/#1260/#1272; release matrix pending |

<!-- TODO: the table reflects per-PR CI validation on main; define the
     release-level acceptance (which platforms × which models run in the
     2.2 rc test window) with the Release Manager. -->

## Related PRs

- [x] flagos-ai/FlagScale#1215 — Straggler detection
- [x] flagos-ai/FlagScale#1216 — Perf monitor integration
- [x] flagos-ai/FlagScale#1243 — Low-overhead GPU progress heartbeat
- [x] flagos-ai/FlagScale#1231 — Qwen3.5 ckpt convert fix
- [x] flagos-ai/FlagScale#1233 — Qwen3.5 MoE ckpt convert + uneven PP
- [x] flagos-ai/FlagScale#1235 — Qwen3-VL update for current Megatron-LM-FL
- [x] flagos-ai/FlagScale#1228 — Qwen-GR00T Orca training features
- [x] flagos-ai/FlagScale#1214 — Override plugin upgrade
- [x] flagos-ai/FlagScale#1226 — Native Ascend MegatronAdaptor integration
- [x] flagos-ai/FlagScale#1219 — GR00T checkpoint portability
- [x] flagos-ai/FlagScale#1230 — DeepSeek-V4 TFLOPs
- [x] flagos-ai/FlagScale#1207 — DualPipeV fix
- [x] flagos-ai/FlagScale#1221 — PI0.5 pretrained loading memory peak
- [x] flagos-ai/FlagScale#1225 — VLA serve entrypoint unification
- [x] flagos-ai/FlagScale#1227 — GLM5 training support
- [x] flagos-ai/FlagScale#1232 — DeepSeek-V4 fixes beyond the 2.1 baseline
- [x] flagos-ai/FlagScale#1240 — Apache 2.0 headers
- [x] flagos-ai/FlagScale#1244 — Functional-test golden value update
- [x] flagos-ai/FlagScale#1250 — Ascend and MetaX build/test CI
- [x] flagos-ai/FlagScale#1254 — Tsingmicro TXDA platform
- [x] flagos-ai/FlagScale#1260 — S5000 image and end-to-end validation
- [x] flagos-ai/FlagScale#1272 — Hygon BW1000 CI
- [x] flagos-ai/FlagScale#1273 — Qwen3.6 LLM and checkpoint conversion

## Implementation History

- 2026-07-30: FEP created as `Provisional` for the FlagOS 2.2 cycle; all
  listed items already merged on `main`, pending release-level acceptance
  definition.
- 2026-09-17: Reconciled `v2.0.0-rc2.post1` with
  `v2.1.0-rc2.post1`. Removed DeepSeek-V4 base support, initial Qwen3.5,
  DeepSeek-V3 export and unified CI from the 2.2 increment because they were
  already in 2.1; added the actual model, checkpoint and platform-CI delta.

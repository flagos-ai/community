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
2. **Model support expansion** — DeepSeek-V4, Qwen3.5 MoE, Qwen3-VL update,
   Qwen-GR00T Orca training features.
3. **Plugin & multi-platform architecture** — Override plugin upgrade
   (function-level Megatron-LM-FL overrides with cross-platform device
   dispatch) and native Ascend NPU MegatronAdaptor integration.
4. **Checkpoint tooling** — DeepSeek-V3 export compatibility, GR00T
   cross-node portability, Qwen3.5 MoE conversion with uneven pipeline
   parallelism.
5. **Training performance** — DeepSeek-V4 TFLOPs accounting, DualPipeV
   scheduling fix, PI0.5 pretrained-loading memory-peak reduction.
6. **VLA serving unification** — single `run_serve_vla.py` entrypoint for
   PI0 / PI0.5 / Qwen-GR00T / GR00T N1.5.
7. **CI/CD & engineering** — unified multi-chip CI workflow, Apache 2.0
   headers across all source files, functional-test golden-value refresh.

All items are implemented on `main` (per-PR references below).

Repository: https://github.com/flagos-ai/FlagScale

## Motivation

The 2.2 cycle advances FlagScale on three fronts: current model families
(DeepSeek-V4, Qwen3.5, multimodal and VLA models), reliability of large
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
  (#1216).
- **G2 (Models):** Train DeepSeek-V4 (CSA/HCA, Hash Router, mHC, #1195),
  Qwen3.5 MoE (with checkpoint conversion and uneven pipeline parallelism,
  #1196/#1231/#1233), updated Qwen3-VL on current Megatron-LM-FL (#1235),
  and Qwen-GR00T Orca features (Data Mixture, Chunked Cross Entropy,
  Stateful DataLoader, Recompute, #1228).
- **G3 (Multi-platform):** Function-level Megatron-LM-FL override framework
  with cross-platform device dispatch (Override plugin upgrade, #1214);
  Ascend NPU trains via natively integrated MegatronAdaptor (FlagScale
  Module) without external adaptation dependencies (#1226).
- **G4 (Checkpoint):** DeepSeek-V3 HF export works with `--skip-mtp`
  (#1202); GR00T checkpoints are portable across nodes (#1219); Qwen3.5 MoE
  conversion supports non-uniform pipeline parallelism (#1233).
- **G5 (Performance):** DeepSeek-V4 TFLOPs accounting with Engram
  IdentityOp optimization (#1230); DualPipeV bidirectional pipeline
  scheduling fixed (#1207); PI0.5 pretrained-weight loading memory peak
  reduced via `init_empty_weights()` + `assign=True` (#1221).
- **G6 (VLA serving):** One `run_serve_vla.py` entrypoint
  (`flagscale/serve/`) serves PI0, PI0.5, Qwen-GR00T, and GR00T N1.5,
  replacing per-model scripts (#1225).
- **G7 (Engineering):** Multi-chip (CUDA / Ascend / MetaX) CI merged into a
  unified `all_tests` workflow with centralized environment initialization
  (#1209); Apache 2.0 headers on all 703 source files (#1240);
  functional-test golden values updated to current training results
  (#1244).

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
| G2 | Per-model functional tests (train + ckpt convert) for DeepSeek-V4, Qwen3.5 MoE, Qwen3-VL, Qwen-GR00T Orca | Implemented (#1195, #1196, #1231, #1233, #1235, #1228) |
| G3 | Override dispatch tests; Ascend NPU training via native MegatronAdaptor on the Ascend CI lane | Implemented (#1214, #1226) |
| G4 | Checkpoint export/convert regression tests (DeepSeek-V3 `--skip-mtp`, GR00T portability, Qwen3.5 uneven PP) | Implemented (#1202, #1219, #1233) |
| G5 | DualPipeV scheduling test; PI0.5 loading memory measurement; TFLOPs accounting check | Implemented (#1207, #1221, #1230) |
| G6 | `run_serve_vla.py` serves each of the four VLA model families | Implemented (#1225) |
| G7 | Unified `all_tests` workflow green on CUDA/Ascend/MetaX; license check; golden values current | Implemented (#1209, #1240, #1244) |

<!-- TODO: the table reflects per-PR CI validation on main; define the
     release-level acceptance (which platforms × which models run in the
     2.2 rc test window) with the Release Manager. -->

## Related PRs

- [x] flagos-ai/FlagScale#1215 — Straggler detection
- [x] flagos-ai/FlagScale#1216 — Perf monitor integration
- [x] flagos-ai/FlagScale#1195 — DeepSeek-V4 support
- [x] flagos-ai/FlagScale#1196 — Qwen3.5 model
- [x] flagos-ai/FlagScale#1231 — Qwen3.5 ckpt convert fix
- [x] flagos-ai/FlagScale#1233 — Qwen3.5 MoE ckpt convert + uneven PP
- [x] flagos-ai/FlagScale#1235 — Qwen3-VL update for current Megatron-LM-FL
- [x] flagos-ai/FlagScale#1228 — Qwen-GR00T Orca training features
- [x] flagos-ai/FlagScale#1214 — Override plugin upgrade
- [x] flagos-ai/FlagScale#1226 — Native Ascend MegatronAdaptor integration
- [x] flagos-ai/FlagScale#1202 — DeepSeek-V3 checkpoint export compatibility
- [x] flagos-ai/FlagScale#1219 — GR00T checkpoint portability
- [x] flagos-ai/FlagScale#1230 — DeepSeek-V4 TFLOPs
- [x] flagos-ai/FlagScale#1207 — DualPipeV fix
- [x] flagos-ai/FlagScale#1221 — PI0.5 pretrained loading memory peak
- [x] flagos-ai/FlagScale#1225 — VLA serve entrypoint unification
- [x] flagos-ai/FlagScale#1209 — Unified multi-chip CI pipeline
- [x] flagos-ai/FlagScale#1240 — Apache 2.0 headers
- [x] flagos-ai/FlagScale#1244 — Functional-test golden value update

## Implementation History

- 2026-07-30: FEP created as `Provisional` for the FlagOS 2.2 cycle; all
  listed items already merged on `main`, pending release-level acceptance
  definition.

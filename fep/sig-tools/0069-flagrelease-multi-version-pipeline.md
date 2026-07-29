# FEP-0069: FlagRelease Multi-Version Automated Migration & Release Pipeline

**Status:** `Implementable`

**Created:** 2026-07-27

**Owner:** @Lxiparer

**SIG:** sig-tools

**Target Version:** FlagOS 2.2

> Supersedes [FEP-0012](0012-flagrelease-automated-migration.md) (FlagRelease Automated Migration). This proposal reworks the single linear pipeline into a **dual-branch, multi-version release** architecture with hard/soft qualification gates.

---

## Summary

FlagRelease is a Claude Code-driven automated migration and release framework that takes a container or image plus a model name and, with zero human interaction, produces validated, published artifacts for FlagOS across multiple chip backends (NVIDIA, Ascend, MUSA, Moore Threads, Hygon).

Repository: https://github.com/flagos-ai/flagrelease

This revision replaces the original flat 13-step pipeline with a design that:

- **Routes deterministically into one of two pipelines** (Branch A / Branch B) based on the admitted image type, so orchestration no longer depends on the model deciding what to do.
- **Produces up to four release versions** (V1 base, V2 Pro, V3 Max, V4 Flag-express) from a single run, each with its own image tag suffix.
- **Separates accuracy (hard gate) from performance (non-blocking signal)**: accuracy relative degradation ≤ 5% is the only condition that blocks a qualified public release; performance only affects the `qualified` label, never halts the flow.
- **Adds anti-drift gates** (`v1_gate.py`, `step7_gate.py`, accuracy final-check) so the pipeline cannot "self-declare success" when a version has not actually met its bar.

## Motivation

Migrating each model to each backend by hand does not scale — new models ship weekly and FlagOS supports 5+ chip backends. FEP-0012 automated the linear happy path, but real deployments surfaced three structural gaps:

1. **One pipeline shape did not fit all admitted images.** Images arrive in different compositions (flaggems+flagtree, or flaggems+flagtree+plugin, or plain native). Forcing a single step order onto all of them pushed branching decisions onto the model at runtime, which was non-deterministic and hard to reproduce.
2. **A single "pass/fail" verdict was too coarse.** A model may pass accuracy under one operator scheduling path (code injection) but not another (plugin whitelist), and performance tuning may plateau below target without that being a release blocker. The framework needed to emit multiple graded versions rather than one binary result.
3. **Nothing prevented optimistic self-judgement.** Without explicit gates, an interrupted or truncated run could silently skip a stage and still mark the workflow qualified.

### Goals

- **Zero-interaction pipeline**: a single command drives container input → published, validated artifact with no prompts.
- **Deterministic branch routing**: `inspect_env.py` classifies the admitted image (`gems_tree` / `gems_tree_plugin` / `native`) and the orchestrator (`run_pipeline.sh`) picks the pipeline — the model never decides the branch.
- **Multi-version release**: emit V1/V2/V3/V4 images from one run, each tagged and gated independently.
- **Automated operator fault isolation**: locate accuracy-regressing and startup-crashing operators by group bisection and disable them cumulatively across stages.
- **Accuracy as the sole hard gate**: relative degradation ≤ 5% (vs. local V1 baseline, or NV reference when V1 is unavailable) governs public release; performance is reported and tuned best-effort but never blocks.
- **Reproducible artifacts**: every run snapshots its config, traces each step, and produces a single authoritative report.

### Non-Goals

- FlagRelease is **not** a training framework, a benchmarking tool, or a serving platform.
- It does **not** implement operators, compilers, or plugins — it orchestrates and validates existing L0–L2 components (see Cross-Module Dependencies) and never modifies them.
- It does not make accuracy/performance *policy* — thresholds are fixed inputs, not decisions the model is free to relax.

## Proposal

### User-Facing Workflow

A single trigger runs the whole flow:

```bash
# Single model, container or image target
bash prompts/run_pipeline.sh --target <container-or-image> --model <model-name>

# Batch execution over a task list
bash prompts/run_batch.sh
```

The target is auto-classified: a value containing `:` or `/` is treated as an image address, otherwise `docker inspect --type=container` decides. Model weights are auto-searched on the host and in the container; missing weights are downloaded. No port, GPU, repo, or credential prompts — all are resolved by fixed default rules.

### Pipeline Steps

| Step | Name | Description |
|------|------|-------------|
| 1 | Container Preparation | Auto-detect container vs. image, search/download weights, deploy tools via `setup_workspace.sh` |
| 2 | Environment Inspection | Classify into `native` / `vllm_flaggems` / `vllm_plugin_flaggems`; emit `entry_image_type` for branch routing |
| 3 | Service Startup | Validate V1 (base) and V2 (FlagOS) startup; crash → operator isolation (disabling operators is the first-line fix) |
| 4 | Accuracy Evaluation | V1 vs. V2 on GPQA Diamond; **hard gate** at 5% relative degradation |
| 5 | Accuracy Operator Tuning | *(conditional)* group-bisect to isolate accuracy-regressing operators, max 3 rounds |
| 6 | Performance Benchmark | V1 vs. V2 throughput/latency (4k-in/1k-out); target 80% ratio per concurrency level |
| 7 | Performance Operator Tuning | *(conditional)* disable operators one at a time until target met; unbounded rounds, quick mode |
| 8 | V2 Publish (Pro) | Always package to Harbor private; public weights/README only if V2 accuracy qualified; tag suffix `-v2` |
| 9 | Plugin Install | Install `vllm-plugin-FL`; failure → issue + stop |
| 10 | Plugin Service Startup | Start with qualified operator set in plugin mode; crash → issue + stop |
| 11 | Plugin Accuracy | Compare vs. V1 baseline; three-tier escalation on miss (issue → tune in plugin mode → framework-fault verdict) |
| 12 | Plugin Performance | Compare vs. V1 baseline; miss → degraded-issue + `performance_ok=false`, continue anyway |
| 13 | V3 Publish (Max) | Tag suffix `-v3`; publishes to `flagrelease-project` for SVT acceptance |
| 13.5 | V4 Reduction (Flag-express) | Two-phase operator reduction on the V3 set to maximize absolute throughput; tag suffix `-v4` |

Execution order: `1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → [plugin_entry] → 9 → 10 → 11 → 12 → 13 → [V3 accuracy qualified] → 13.5`.

### Qualification Logic

```
qualified        = service_ok AND accuracy_ok AND performance_ok   # label only, not a release blocker
plugin_entry     = service_ok                                       # V2 accuracy does NOT block V3 attempt
v4_entry         = service_ok AND v3_accuracy_ok                    # not gated on V2 accuracy

accuracy_ok      = rel_drop <= 5%   where rel_drop = (baseline - current) / baseline
performance_ok   = min_ratio >= 0.80   (per data point, V*/V1)
```

Public-release gating (ModelScope / HuggingFace):

- V2 accuracy qualified → Step 8 creates repo + uploads weights + README.
- V2 accuracy not qualified → Step 8 stays Harbor-private; if V3 later qualifies, Step 13 back-fills the public release.
- Neither V2 nor V3 qualified → private image only, nothing public.

Performance is **never** a release blocker — a sub-80% ratio only drops the `qualified` label and files a `performance-degraded` issue.

## Design Details

### Architecture: Skill-Based Orchestration

Each pipeline step is a **Skill** — a directory with a `SKILL.md` specification and a `tools/` folder of deterministic scripts. The orchestrator routes trigger phrases to skills through a routing table in `CLAUDE.md`. The core principle: **anything that can be made deterministic lives in a script; the model only orchestrates and analyzes complex failures.** Tools include `inspect_env.py`, `toggle_flaggems.py`, `benchmark_runner.py`, `operator_search.py`, `accuracy_compare.py`, `install_plugin.py`, `generate_report.py`, and the release tool under `flagos-release/tools/`.

### Dual-Pipeline Routing

`inspect_env.py` emits `entry_image_type`, and `run_pipeline.sh` routes deterministically:

| entry_image_type | Branch | Admitted image composition | Version path |
|------------------|--------|----------------------------|--------------|
| `gems_tree` | A (simple) | flaggems + flagtree, no plugin | V1 (bare) → V2 (full code injection) → V3 (switch to plugin whitelist) → V4 |
| `gems_tree_plugin` | B (complex) | flaggems + flagtree + plugin | V1 (three-way selector) → V2 (2.1/2.2) → V3 (3.1/3.2) → V4 |
| `native` | native | no flaggems | accuracy/performance eval only; no tuning, no multi-version |

Branch B's V1 uses a **three-way state machine** (`baseline_selector.py`): `v1.1` clean baseline (`VLLM_PLUGINS=''`) → `v1.2` vendor platform plugin → `v1.3` FL plugin without flaggems; all failing → `none` (hard flaggems dependency), in which case the accuracy baseline falls back to `nv_baseline.yaml`.

### Version Definitions

| Version | Definition | Tag suffix |
|---------|-----------|-----------|
| V1 (base) | FlagTree only, flaggems disabled — accuracy & performance baseline | `-v1` |
| V0 (transient) | flaggems fully enabled initial state — tuning start point, not published | — |
| V2 (Pro) | flaggems + flagtree, accuracy rel-drop ≤ 5%, perf ≥ 80% of V1 | `-v2` |
| V3 (Max) | V2 + plugin, accuracy rel-drop ≤ 5%, perf ≥ 80% of V1 | `-v3` |
| V4 (Flag-express) | Operator reduction on V3 to maximize throughput; bar is **beating V3** (not V1); accuracy rel-drop ≤ 5% is a precondition; keep ≥ 1 operator | `-v4` |

When no local V1 baseline exists, the performance baseline is **synthesized**: the first successful V2 startup is quick-benchmarked (`v2_initial_performance`) and scaled by `synthesize_perf_baseline.py` (throughput ×1.2, latency ÷1.2) into a standard `native_performance.json` marked `_meta.synthetic=true`.

### State Management: context.yaml

Shared cross-skill state lives in `/flagos-workspace/shared/context.yaml` — **one file per container** so parallel migrations never collide. It tracks container/model metadata, environment classification, workflow gate fields (`service_ok`, `accuracy_ok`, `performance_ok`, `qualified`), the disabled-operator list, timing, and a `workflow_ledger`. The template (`shared/context.template.yaml`) is init-only and never written at runtime. Host-side snapshots are archived read-only.

A key data-integrity constraint: `accuracy_ok` / `performance_ok` **cannot be set true by hand** — `update_context.py` re-validates the latest result files on write and rejects unsupported values; only `operator_search.py` sets them on genuine qualification.

### Operator Control Flow

Disabled operators accumulate and propagate across the whole run (Step 3 crash → Step 5 accuracy → Step 7 performance → Steps 10–12 plugin), each stage adding to the prior set. Control differs by scenario:

- **Non-plugin (`vllm_flaggems`)**: a whitelist control file `/root/flaggems_ops_control.json` (`{"include": [...]}`); `start_service.sh` infers `FLAGGEMS_CONTROL_MODE=only_enable`.
- **Plugin (`vllm_plugin_flaggems`)**: config is persisted to `/etc/environment` via `persist_op_config.py` (`USE_FLAGGEMS`, `VLLM_FL_PREFER_ENABLED`, `VLLM_FL_FLAGOS_WHITELIST`); `start_service.sh --mode flagos` loads it.

The runtime txt (`flaggems_enable_oplist.txt` / `gems.txt`) is the single source of truth — anything not listed there must be explicitly disabled. Every startup clears Triton/FlagGems compile caches so each attempt exposes all problem operators cleanly.

### Cross-Module Dependencies

```
L3  FlagRelease            (this framework — orchestration only)
      │ consumes
L2  vllm-plugin-FL         (plugin operator scheduling path)
      │
L1  FlagGems               (operator library)
      │
L0  FlagTree, FlagCX       (compiler / comms)
```

FlagRelease **does not modify any L0–L2 component**; it installs, configures, and validates them. Recommended NV combination: `vllm>=0.7.3 + flaggems>=5.1.0 + flagtree>=0.5.0`.

### Failure Handling

The pipeline **never terminates on failure** except when the Claude API itself is unavailable. A failing accuracy or performance check is not a stop condition — the corresponding `*_ok` field is set false, an issue is filed locally via `issue_reporter.py`, and the flow continues to Step 8 (private release). The one bounded exception: if Step 3 flaggems crashes and operator diagnosis confirms two consecutive rounds with no attributable new operator, `service_ok=false` is set and Steps 4–7 are skipped to Step 8.

Startup-crash first principle: **disabling operators is the highest-priority fix.** `enforce-eager` / switching to native is a last resort only after every operator-localization avenue is exhausted.

Issues are written as local markdown only (GitHub auto-submission is disabled at the code level). Plugin-stage issues (Steps 9–13) route to `flagos-ai/vllm-plugin-FL`.

### Recovery

On a new session the orchestrator reads container `context.yaml`; if `workflow.all_done != true` and a container is bound, it runs `diagnose_failure.py --json`, summarizes the interruption point and cause, and resumes from that point rather than restarting. Each step writes a trace JSON, updates the workflow ledger, and regenerates the report, so the four records (ledger, trace, timing, report) stay consistent.

## Packaging

Each run produces, under the host workspace `/mnt/data/flagos-workspace/<model>/`:

- `results/` — final deliverables (report, benchmark JSON, accuracy JSON)
- `traces/` — per-step trace JSON
- `logs/` — pipeline and issue logs
- `config/` — config snapshots and final context

Images publish to Harbor with version tag suffixes (`-v1/-v2/-v3/-v4`). V1/V2/V4 go to `harbor.baai.ac.cn/flagrelease-public`; **V3 (Max, the final delivery version) goes to `harbor.baai.ac.cn/flagrelease-project`** for SVT acceptance. Public model repos follow `FlagRelease/{Model}-{vendor}-FlagOS`, gated by the accuracy rules above.

## Test Plan

| Goal | Verification Method | Status |
|------|--------------------|--------|
| Branch routing is deterministic | Run `inspect_env.py` across all three image types, assert `entry_image_type` and selected pipeline | Pending |
| Accuracy hard gate blocks public release | Inject a >5% degradation model, assert V2 stays private | Pending |
| Performance never blocks the flow | Inject a sub-80% ratio, assert flow reaches Step 8 with `performance_ok=false` | Pending |
| Operator isolation locates bad operators | Group-bisection unit tests on `operator_search.py` | Pending |
| Gates prevent self-declared success | `v1_gate.py` / `step7_gate.py` reject incomplete stages | Pending |
| Recovery resumes from interruption | Kill mid-run, restart, assert resume from `context.yaml` | Pending |
| V4 reduction beats V3 or reverts safely | Two-phase reduction with accuracy final-check | Pending |

All rows are verified in [flagos-ai/FlagRelease#20](https://github.com/flagos-ai/FlagRelease/pull/20) and flip to Implemented when it merges.

## Related PRs

- [ ] https://github.com/flagos-ai/FlagRelease/pull/20 — rework FlagOS migration pipeline: dual-branch, multi-version release, gates

## Implementation History

- 2026-07: Dual-pipeline (Branch A/B) routing, V1–V4 multi-version release, accuracy hard gate / performance non-blocking policy, synthetic performance baseline, anti-drift gates (`v1_gate`, `step7_gate`, accuracy final-check). Consolidated in `flagos-ai/FlagRelease#20`.
- 2026-05: Initial automated migration framework — flat 13-step pipeline, skill-based orchestration, `context.yaml` state, operator fault isolation ([FEP-0012](0012-flagrelease-automated-migration.md)).

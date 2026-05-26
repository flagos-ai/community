# FEP: FlagRelease — Automated Multi-Chip Model Migration and Release

**Status:** `Implemented`

**Created:** 2026-05-26

**Owner:** @shh2000

**SIG:** sig-tools

**Target Version:** FlagOS 2.1

---

## Summary

FlagRelease is a Claude Code-driven automated migration and release framework for deploying LLMs across multiple AI chip platforms (NVIDIA, Huawei Ascend, MUSA, Moore Threads, Hygon). It provides a 13-step zero-interaction pipeline that takes a model container/image as input and produces a validated, published release artifact — including accuracy evaluation, performance benchmarking, operator-level fault isolation, and multi-registry publishing.

Repository: https://github.com/flagos-ai/flagrelease

## Motivation

FlagOS aims to run mainstream LLMs on diverse chip backends. Before FlagRelease, migrating each new model to each backend required manual effort: starting services, running evaluations, diagnosing operator failures, tuning performance, and packaging results. This per-model-per-chip manual process does not scale — new models are released weekly, and FlagOS supports 5+ chip backends.

FlagRelease solves this by automating the entire migration lifecycle. When a new model appears, a single command triggers the full pipeline. Failures are automatically diagnosed, problematic operators are isolated and disabled, and results are published regardless of pass/fail status (public for qualified, private for unqualified).

### Goals

- **Zero-interaction pipeline**: From container preparation to image publishing in one command, no human intervention required
- **Multi-chip support**: Automatically detect chip vendor (NVIDIA/Ascend/MUSA/Moore Threads/Hygon) and adapt execution accordingly
- **Automated operator fault isolation**: When FlagGems operators cause crashes or accuracy/performance degradation, automatically identify and disable problematic operators through binary search
- **Cross-module orchestration**: Coordinate FlagGems (compute operators), FlagCX (communication), FlagTree (compiler), and vllm-plugin-FL (inference framework plugin) in a unified workflow
- **Automated issue reporting**: File GitHub issues against the responsible component repository when failures are detected
- **Batch execution**: Process multiple models sequentially with checkpoint/resume support
- **Reproducible artifacts**: Every pipeline run produces structured traces, logs, and comparison reports

### Non-Goals

- Not a training framework (FlagScale handles distributed training)
- Not a general-purpose benchmarking tool (FlagPerf handles multi-chip evaluation)
- Not a model serving platform (vLLM/sglang handle serving; FlagRelease validates and publishes)
- Does not implement operators or compilers (delegates to FlagGems/FlagTree)

## Proposal

### User-Facing Workflow

```bash
# Single model pipeline (container mode)
bash prompts/run_pipeline.sh <container_name> <model_name> \
  <MODELSCOPE_TOKEN> <HF_TOKEN> <GITHUB_TOKEN> <HARBOR_USER> <HARBOR_PASSWORD>

# Single model pipeline (image mode)
bash prompts/run_pipeline.sh <image:tag> <model_name> \
  <MODELSCOPE_TOKEN> <HF_TOKEN> <GITHUB_TOKEN> <HARBOR_USER> <HARBOR_PASSWORD>

# Batch execution
bash prompts/run_batch.sh tasks.txt <tokens...>
```

### Pipeline Steps

| Step | Name | Description |
|------|------|-------------|
| 1 | Container Preparation | Auto-detect container/image + model weight search/download + tool deployment |
| 2 | Environment Inspection | Classify scenario (native / vllm_flaggems / vllm_plugin_flaggems) |
| 3 | Service Startup | V1 (native) + V2 (FlagOS) startup validation |
| 4 | Accuracy Evaluation | V1/V2 GPQA Diamond comparison (threshold: 5% degradation) |
| 5 | Accuracy Operator Tuning | Conditional: isolate problematic operators via group bisection (max 3 rounds) |
| 6 | Performance Benchmark | V1/V2 throughput comparison (threshold: 80% ratio per concurrency level) |
| 7 | Performance Operator Tuning | Conditional: disable operators one-by-one until target met |
| 8 | Auto Publish | Package + upload (qualified=public, unqualified=private) |
| 9-13 | Plugin Validation | Install vllm-plugin-FL → startup → accuracy → performance → publish |

### Qualification Logic

```
qualified = service_ok AND accuracy_ok AND performance_ok
```
- Qualified → public release to Harbor + ModelScope + HuggingFace
- Unqualified → private release with report noting failures

## Design Details

### Architecture: Skill-Based Orchestration

FlagRelease uses a skill-based architecture where each pipeline step is an independent skill with:
- `SKILL.md` — execution specification (read by Claude Code as instructions)
- `tools/` — Python/Bash scripts invoked during execution

```
skills/
├── flagos-container-preparation/    # Step 1
├── flagos-pre-service-inspection/   # Step 2
├── flagos-service-startup/          # Step 3
├── flagos-eval-comprehensive/       # Steps 4-5
├── flagos-performance-testing/      # Steps 6-7
├── flagos-operator-replacement/     # Steps 5, 7 (operator tuning)
├── flagos-plugin-install/           # Step 9
├── flagos-release/                  # Steps 8, 13
├── flagos-issue-reporter/           # Cross-cutting
├── flagos-log-analyzer/             # Cross-cutting
└── shared/                          # Pipeline log spec
```

### State Management: context.yaml

A YAML state file (`/flagos-workspace/shared/context.yaml`) tracks workflow progress across steps:
- Container metadata (name, image, GPU info)
- Model metadata (name, path, architecture)
- Environment classification
- Workflow state (which steps completed, pass/fail status)
- Operator control state (disabled operators list)

Each container has its own independent context.yaml, enabling parallel execution on different models.

### Operator Control Flow

Operator disabling accumulates across the pipeline:

```
Step 3 (crash diagnosis) → Step 5 (accuracy tuning) → Step 7 (performance tuning) → Steps 10-12 (plugin)
```

Two control mechanisms depending on scenario:
- **vllm_flaggems**: Whitelist control file (`/root/flaggems_ops_control.json`)
- **vllm_plugin_flaggems**: Environment variables persisted to `/etc/environment` (`USE_FLAGGEMS`, `VLLM_FL_PREFER_ENABLED`, `VLLM_FL_FLAGOS_WHITELIST`)

### Cross-Module Dependencies

| FlagOS Component | Role in FlagRelease |
|-----------------|---------------------|
| FlagGems | Compute operators — FlagRelease validates and tunes which operators are safe to enable |
| FlagTree | Compiler — compiles FlagGems operators to target backend binary |
| FlagCX | Communication — validated during multi-GPU service startup |
| vllm-plugin-FL | Inference plugin — Steps 9-13 validate plugin-mode deployment |
| sglang-plugin-FL | Alternative inference plugin (same validation flow) |

### Fault Recovery

- `diagnose_failure.py` — automatic diagnosis on session resume
- `run_pipeline.sh` post-exit hooks — data sync, missing file generation, fallback publish
- Checkpoint/resume via context.yaml state

## Packaging

- **Build**: No build step required. Clone the repository and ensure Claude Code CLI is installed.
- **Runtime dependencies**: Claude Code CLI, Docker, Python 3.8+
- **Execution environment**: Host machine with Docker access to target containers
- **Credentials**: Environment variables (`HARBOR_USER`, `HARBOR_PASSWORD`, `MODELSCOPE_TOKEN`, `HF_TOKEN`, `GITHUB_TOKEN`)
- **Platform**: Linux (tested on Ubuntu 20.04/22.04)

```bash
git clone https://github.com/flagos-ai/flagrelease.git
cd flagrelease
# Ensure Claude Code CLI is available
bash prompts/run_pipeline.sh <container> <model> <tokens...>
```

## Test Plan

| Goal | Verification Method | Status |
|------|-------------------|--------|
| Zero-interaction pipeline | Run `run_pipeline.sh` end-to-end on a model without any manual input | Verified (Qwen3-8B, MiniMax-M2.5) |
| Multi-chip support | Execute on NVIDIA GPU and Huawei Ascend NPU containers | Verified |
| Operator fault isolation | Inject a known-bad operator, confirm pipeline isolates and disables it | Verified |
| Cross-module orchestration | Pipeline correctly invokes FlagGems/FlagTree/vllm-plugin-FL in sequence | Verified |
| Auto issue reporting | Confirm GitHub issues are filed against correct repos on failure | Verified |
| Batch execution | Run `run_batch.sh` with 3+ models, confirm checkpoint/resume works | Verified |
| Reproducible artifacts | Check traces/, results/, logs/ directories contain complete structured output | Verified |

## Related PRs

- [x] https://github.com/flagos-ai/flagrelease — Initial repository with full pipeline implementation

## Implementation History

- 2026-05: FlagRelease v0.1.0-rc0 included in FlagOS 2.1 RC0 release manifest
- 2026-05: 13-step pipeline with plugin validation flow completed
- 2026-04: Batch execution mode (`run_batch.sh`) added
- 2026-04: Operator fault isolation (binary search + elimination) implemented
- 2026-03: Initial skill-based architecture and V1/V2 comparison pipeline

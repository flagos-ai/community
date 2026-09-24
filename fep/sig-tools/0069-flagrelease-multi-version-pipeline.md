# FEP-0069: FlagRelease Multi-Version Automated Migration & Release Pipeline

**Status:** `Implementable`

**Updated:** 2026-09-24

**Created:** 2026-07-27

**Owner:** @Lxiparer

**SIG:** sig-tools

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| flagrelease | [`0.3.0-rc2` @ `c1a5956a2264`](https://github.com/flagos-ai/flagrelease/tree/c1a5956a22641e4d16ce6d1320dcb215851b4b3a) | [`v0.3.0-rc2.post1` @ `c1a5956a2264`](https://github.com/flagos-ai/flagrelease/tree/c1a5956a22641e4d16ce6d1320dcb215851b4b3a) |

## Summary

Extend [FEP-0012](0012-flagrelease-automated-migration.md) with deterministic
pipeline routing, V1–V4 artifacts and accuracy/performance gates. The design
is tracked in PR #20, which remains open. RC2 contains the earlier migration
framework; the proposed multi-version pipeline is not included.

## Goals and Completion

| Goal | RC2 status |
|---|---|
| Container preparation, evaluation and operator diagnosis | Earlier framework and tools present |
| Deterministic two-branch routing | Proposed in open PR #20 |
| V1 baseline selector and stage gates | Proposed scripts absent from RC2 |
| V1–V4 artifact generation | Multi-version implementation absent from RC2 |
| Synthetic baseline and V4 reduction | Proposed scripts absent from RC2 |
| Qualified publication and interruption recovery | New gate semantics and acceptance remain pending |

RC2 includes `prompts/run_pipeline.sh`, `prompts/run_batch.sh`, step tools
under `skills/` and `shared/context.template.yaml`. Its environment labels
are `native`, `vllm_flaggems` and `vllm_plugin_flaggems`. The proposed
`baseline_selector.py`, `v1_gate.py`, `step7_gate.py` and
`synthesize_perf_baseline.py` are absent from this snapshot.

## Proposed Design

The orchestrator selects the pipeline from the inspected image composition:

| Image type | Version path |
|---|---|
| `gems_tree` | Native baseline, FlagGems injection, plugin whitelist, operator reduction |
| `gems_tree_plugin` | Three-way baseline selection, injection/plugin variants, operator reduction |
| `native` | Accuracy and performance evaluation |

For an image containing the plugin, baseline selection tries the clean
framework, the vendor platform plugin, then the FL plugin with FlagGems
disabled. If all fail, accuracy uses the recorded NVIDIA reference.

| Version | Artifact |
|---|---|
| V1 | Local baseline with FlagGems disabled |
| V2 | FlagGems/FlagTree injection path |
| V3 | Plugin path with the selected operator set |
| V4 | Reduced V3 operator set, retaining at least one operator |

Public release requires a working service and accuracy relative degradation
of at most 5% against the selected baseline. A performance ratio below 80%
changes the qualification label but does not block an accuracy-qualified
release. V4 must preserve the accuracy bound and improve on V3; otherwise
the pipeline retains V3.

If a local performance baseline is unavailable, the proposed fallback scales
the initial successful V2 measurement by 1.2 for throughput and 1/1.2 for
latency. The result must carry `_meta.synthetic=true` and must not be
reported as measured native performance.

Per-container state records source/configuration snapshots, baseline choice,
operator exclusions, result files and a workflow ledger. Gates derive their
verdicts from those results. Operator exclusions accumulate across crash
diagnosis, accuracy tuning and performance tuning. Recovery resumes from the
last valid stage and preserves prior traces.

## Artifacts

The proposed output contains versioned images, accuracy/performance JSON,
reports, traces, logs and configuration snapshots. V3 is the SVT delivery
artifact. Versions without accuracy qualification remain private. Each
published version records its exact module revisions, operator configuration,
baseline source and gate results.

## Test Plan

PR #20 must provide executable checks for:

| Check | Required result |
|---|---|
| Image classification | Repeatable branch selection for all three image types |
| Baseline fallback | Ordered local attempts and explicit NVIDIA/synthetic provenance |
| Accuracy gate | Degradation above 5% prevents public publication |
| Performance signal | Ratio below 80% records a failure without blocking an accuracy-qualified artifact |
| Operator isolation | Injected faulty operators are identified and exclusions persist |
| Stage validation | Missing or inconsistent result files cannot mark a stage complete |
| Recovery | An interrupted run resumes without skipping required stages |
| V4 reduction | Accuracy is retained and throughput exceeds V3, or V3 is retained |

The current RC2 scripts do not execute this acceptance matrix. Merging the
implementation and recording the gate tests and representative backend runs
are required for completion.

## Recorded Validation

The [September 24 delivery report](https://jwolpxeehx.feishu.cn/docx/BOSRdLTIDoK64bxXLVIcviKXnV6)
records production migration runs, including 39 tasks on the improved
workflow across PPU and Iluvatar. The deployed workflow has been exercised.
Its release-to-source mapping and the V1–V4 gate matrix are not established
by those task totals. PR #20 remains open, and its new scripts are absent
from the inspected RC2 tree.

## Related PRs

- [x] [FlagRelease#14](https://github.com/flagos-ai/FlagRelease/pull/14) — Earlier migration framework in RC2. Merged.
- [ ] [FlagRelease#20](https://github.com/flagos-ai/FlagRelease/pull/20) — Proposed multi-version pipeline and qualification gates. Open.

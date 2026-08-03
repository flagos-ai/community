# FEP — FlagOS Enhancement Proposal

[English](README.md) | [中文](README_CN.md)

## What is a FEP

A FEP (FlagOS Enhancement Proposal) is the mechanism for managing features in FlagOS.
Each cross-module or significant feature gets a FEP — a markdown design document,
stored under `fep/sig-*/`, submitted and reviewed via PR.

**Toolchain**: GitHub PR + Markdown file + [SIG OWNERS](../sigs/) approval

> **New here?** Start with the [FEP Authoring Guide](../contributors/fep-guide.md). **Approver?** See the [FEP Review Guide](REVIEW_GUIDE.md). Governance rules are in [GOVERNANCE.md](../GOVERNANCE.md).

## 🚩 Release Tracker

Live FEP progress per FlagOS release. Badges read from the GitHub Milestones API and update automatically. Board: [**FlagOS FEP Tracker**](https://github.com/orgs/flagos-ai/projects/6) (views explained in [Labels, Milestone & Board](#labels-milestone--board)).

[![FlagOS 2.1](https://img.shields.io/github/milestones/progress-percent/flagos-ai/community/1?label=FlagOS%202.1&color=brightgreen)](https://github.com/flagos-ai/community/milestone/1)
[![FlagOS 2.2](https://img.shields.io/github/milestones/progress-percent/flagos-ai/community/2?label=FlagOS%202.2&color=blue)](https://github.com/flagos-ai/community/milestone/2)

| Release | Due | Status | FEP Milestone |
|---------|-----|--------|---------------|
| **FlagOS 2.1** | 2026-06-11 | ✅ Released — all FEPs merged | [milestone/1](https://github.com/flagos-ai/community/milestone/1) |
| **FlagOS 2.2** | 2026-09-28 | 🔵 Open — accepting FEPs | [milestone/2](https://github.com/flagos-ai/community/milestone/2) |

> **FlagOS 2.2 key dates** — Feature Freeze: **2026-08-31** · Testing: 09-01 → 09-24. Full schedule and freeze rules: [release/2.2/schedule.md](../release/2.2/schedule.md).

## SIG Groups

### Active SIGs (7)

| SIG | Modules |
|-----|---------|
| `sig-operator` | FlagGems, FlagAttention, FlagFFT, FlagSparse, FlagDNN, FlagBLAS, FlagTensor, FlagAudio |
| `sig-compiler` | FlagTree |
| `sig-network` | FlagCX |
| `sig-framework` | PyTorch-Plugin-FL, vllm-plugin-FL, sglang-plugin-FL, TransformerEngine-FL, Megatron-LM-FL, verl-FL |
| `sig-training` | FlagScale |
| `sig-kernelgen` | KernelGen, KernelGenBench |
| `sig-chip` | Datacenter chip adaptation |

### Planned / Incubating

The following areas have been identified but lack Approvers; FEPs are reviewed directly by the TSC. See [SIG Overview](../sigs/README.md).

| Area | Type | Modules |
|------|------|------|
| `sig-benchmark` | Planned SIG | FlagPerf |
| `sig-agent` | Planned SIG | Skills |
| `sig-tools` | Planned SIG | FlagRelease |
| `sig-edge` | Planned SIG | Edge Hardware and Edge side SDK for FlagOS |
| `sig-architecture` | Planned SIG | Cross-module features, process changes |
| `sig-os` | Planned SIG | OS-level packaging, distribution integration (openKylin, openEuler) |
| `sig-riscv` | Planned SIG | Experimental RISC-V support — compile adaptation, dependency analysis |
| `wg-embodied` | Incubating WG | FlagOS-Robo |
| `wg-ai4s` | Incubating WG | FlagQuantum |

## When to Write a FEP

| Scenario | FEP Required? |
|----------|---------------|
| Cross-module feature | **Required** |
| New chip support | **Required** |
| New module / repository | **Required** |
| Major module-level feature | **Recommended** |
| Single-repo minor feature / bugfix | No |
| Documentation improvements | No |

## FEP Lifecycle

```
Provisional ──→ Implementable ──→ Implemented
     │                                ↑
     ├──→ Deferred ──────────────────┘
     └──→ Rejected
```

| Status | Meaning | Action |
|--------|---------|--------|
| **Provisional** | Draft, under SIG discussion | Iterate in PR. A FEP may merge at `Provisional` — merging accepts the direction, not the final design |
| **Implementable** | Design complete, Test Plan executable | Raise via follow-up PR once design gaps (TODO markers) are filled |
| **Implemented** | Code merged, acceptance criteria met | Raise via follow-up PR; close the tracking issue |
| **Deferred** | Postponed to a later release | Move the tracking issue to the next Milestone; swap `target/X.Y` for the next release's label |
| **Rejected** | Not moving forward | Merge the PR with Status `Rejected` to preserve the decision record |

> Status is marked in the FEP doc as `**Status:** <value>` and updated via follow-up PRs at each state transition.

A FEP is **in a release** once its PR merges carrying that release's `target/X.Y` label. Whether it **graduates** in that release is a separate question, decided at the release's Feature Freeze: implementation code submitted by the freeze date, acceptance passed during the testing window. A merged FEP that misses the freeze is `Deferred` to the next release, not dropped.

## Workflow

Each step lists the bookkeeping it triggers. Labels, milestone and board mechanics are defined once in [Labels, Milestone & Board](#labels-milestone--board).

### 0. Socialize with SIG

Before writing a FEP, discuss the idea with the relevant SIG. Make sure there is interest
in the problem space and willingness to review.

> **Bootstrap note:** If the relevant SIG has no Chair, Approver, or meeting yet, open an Issue
> in the target module repository or post in [GitHub Discussions](https://github.com/FlagOS-AI/community/discussions).
> The TSC (or the ZhongZhi FlagOS Community (众智FlagOS社区) before TSC is formed) will route and review. See [GOVERNANCE.md](../GOVERNANCE.md).

### 1. Create the FEP Document

Copy the [FEP template](fep-template/README.md) to `fep/sig-xxx/title-slug.md`.

- `title-slug` is a short hyphenated English description
- Minimum content to start: the template's **(Required)** sections — Summary, Goals, Packaging, Test Plan. Everything else can follow later.
- Set initial Status to `Provisional`

### 2. Open a PR

Open a PR with the FEP file.

- PR title should describe the feature
- PR description can be brief — the FEP doc carries the details
- Use a **Draft PR** for early-stage ideas that need more discussion

**Bookkeeping:** label the PR `FEP` + `sig/*` (or `wg/*`). To target a release, set `Target Version: FlagOS X.Y` in the FEP header and add the `target/X.Y` label — the PR then shows in that release's *Features Pending* board view.

### 3. Review and Merge

Review, discussion and iteration happen on the PR.

- SIG approvers (listed in OWNERS) approve the PR
- **Bootstrap note:** If the relevant SIG has no Approver yet, the TSC reviews directly. Post in [GitHub Discussions](https://github.com/FlagOS-AI/community/discussions) if you need help routing.
- The bar for merging: **(Required)** sections in place and SIG agreement on direction. `Provisional` FEPs merge routinely; `Implementable` comes later via follow-up PR
- Rename the file to `NNNN-title-slug.md` (NNNN = PR number) before merge

Merging a `target/X.Y`-labeled FEP **puts it into that release**: it moves from the *Features Pending* view to the *SIG Roadmap* view.

**Bookkeeping (merger):** create the tracking issue — `[FEP-XXXX] <title> tracking`, labeled `FEP` + `sig/*`, assigned to the FEP Owner, attached to the release Milestone. No `target/*` label on the issue; its release is the milestone.

**Cross-SIG FEPs**: Pick a home SIG whose directory the file lives in. SIGs
impacted by the feature should also review. If no existing SIG fits, use `sig-architecture` (during bootstrap) or ask TSC for routing.

### 4. Implement

- Implementation happens across the relevant repos; implementation code must be submitted by the release's **Feature Freeze** (date in `release/X.Y/schedule.md`)
- Track related PRs in the `Related PRs` section of the FEP doc
- Check off progress and attach acceptance evidence (environment, logs, metrics) in the tracking issue
- Update the FEP doc via follow-up PRs: fill design TODOs, then raise Status to `Implementable`
- After Feature Freeze: acceptance testing, bug fixes, tuning, and FEP doc updates only — no new feature code for that release; feature work for later releases continues on `main`

### 5. Wrap Up

- When all acceptance criteria are met, update Status to `Implemented` via a final PR
- Close the tracking issue — this marks the FEP delivered in the Milestone view
- Acceptance partially unmet at release: keep Status `Implementable` and open a follow-up acceptance issue on the milestone for the failing part
- Not delivered: mark `Deferred`, move the tracking issue to the next Milestone, swap the `target/*` label on the FEP PR

## File Naming

| Convention | When |
|------------|------|
| `title-slug.md` | Before PR is created, or during early draft |
| `NNNN-title-slug.md` | After PR is created, where NNNN is the PR number |

> Rename the file to include the PR number before merge. The PR number serves as the FEP identifier.

## Roles

| Role | Responsibilities |
|------|-----------------|
| **FEP Owner** | Write the FEP, declare `Target Version`, fill `Related PRs`, drive implementation, update status, ensure acceptance |
| **SIG Approver** | Review and approve FEP documents (listed in [SIG OWNERS](../sigs/)); create the tracking issue on merge |
| **Release Manager** | Track overall FEP progress per version, Go/No-Go decisions; set up each release cycle (see [Starting a new release cycle](#starting-a-new-release-cycle)) |

> `Target Version` and `Related PRs` are the Owner's declarations — reviewers comment on them but do not fill them in.
> For complete role definitions and promotion paths, see [contributors/roles.md](../contributors/roles.md).

## Labels, Milestone & Board

A FEP's path through a release is carried by two artifacts — the FEP **PR** (design) and its **tracking issue** (delivery) — wired together by labels and the milestone.

### Labels

| Label | Goes on | Set by | When |
|-------|---------|--------|------|
| `FEP` | FEP PR and tracking issue | Author / merger | On creation |
| `sig/*`, `wg/*` | FEP PR and tracking issue | Author / merger | On creation |
| `target/X.Y` | **FEP PR only** | Owner (before merge) / Release Manager (after merge) | On declaring the target release; post-merge changes only per the rules below |

Release identity is carried once per artifact: the `target/*` label on the PR, the milestone on the tracking issue. Do not add version labels to tracking issues, and do not attach FEP PRs to milestones.

**`target/*` changes on a merged PR go through the Release Manager only**, in one of two cases: retargeting on `Deferred`, or entering a release after merge when the Owner declares a `Target Version` via follow-up PR — the latter only before that release's Feature Freeze; after the freeze the only way in is the `[URGENT]` channel ([Review Guide](REVIEW_GUIDE.md#7-urgent-fep-channel)). In both cases the tracking issue's milestone is updated in the same step — the follow-up PR and the milestone change are the audit record. Adding a `target/*` label to a merged PR by itself does not put the FEP into a release.

### Milestone

- Each FlagOS version has a Milestone (e.g., `FlagOS 2.2`) with a deadline set
- Every FEP in the release has **one tracking issue** (`[FEP-XXXX] <title> tracking`), created when the FEP merges, assigned to the FEP Owner, and closed when the FEP reaches `Implemented`
- **The Milestone holds tracking issues (plus the release tracking issue), not FEP PRs** — so milestone open/closed counts reflect real delivery progress
- Deferring a FEP moves its tracking issue to the next Milestone; the issue is not closed

### Board views

The [FlagOS FEP Tracker](https://github.com/orgs/flagos-ai/projects/6) board has one permanent view plus three per release. All views are filter-driven — items flow between them as PRs merge and issues close; nothing is moved by hand.

| View | Filter | What it shows |
|------|--------|---------------|
| **All FEPs** | `is:pr label:FEP` | Every FEP, across releases |
| **X.Y Features Pending** | `is:pr is:open label:FEP label:target/X.Y` | Proposed for the release, not yet merged |
| **X.Y SIG Roadmap** | `is:pr is:merged label:FEP label:target/X.Y` | In the release, grouped by SIG |
| **X.Y Release Track** | `is:issue milestone:"FlagOS X.Y"` | Delivery progress, one card per tracking issue |

### Starting a new release cycle

The Release Manager creates: the `FlagOS X.Y` milestone, the `target/X.Y` label, the three per-release board views per the table above, the release tracking issue, and `release/X.Y/schedule.md` with the cycle's dates.

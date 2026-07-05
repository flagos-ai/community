# FEP — FlagOS Enhancement Proposal

[English](README.md) | [中文](README_CN.md)

## What is a FEP

A FEP (FlagOS Enhancement Proposal) is the mechanism for managing features in FlagOS.
Each cross-module or significant feature gets a FEP — a markdown design document,
stored under `fep/sig-*/`, submitted and reviewed via PR.

**Toolchain**: GitHub PR + Markdown file + [SIG OWNERS](../sigs/) approval

> **New here?** Start with the [FEP Authoring Guide](../contributors/fep-guide.md). **Approver?** See the [FEP Review Guide](REVIEW_GUIDE.md). Governance rules are in [GOVERNANCE.md](../GOVERNANCE.md).

## 🚩 Release Tracker

Live FEP progress per FlagOS release. Badges read from the GitHub Milestones API and update automatically. Board view: [**FlagOS FEP Tracker** — grouped by FEP Status](https://github.com/orgs/flagos-ai/projects/6/views/1?layout=board&groupedBy%5BcolumnId%5D=365272770).

[![FlagOS 2.1](https://img.shields.io/github/milestones/progress-percent/flagos-ai/community/1?label=FlagOS%202.1&color=brightgreen)](https://github.com/flagos-ai/community/milestone/1)
[![FlagOS 2.2](https://img.shields.io/github/milestones/progress-percent/flagos-ai/community/2?label=FlagOS%202.2&color=blue)](https://github.com/flagos-ai/community/milestone/2)

| Release | Due | Status | FEP Milestone |
|---------|-----|--------|---------------|
| **FlagOS 2.1** | 2026-06-11 | ✅ Released — all FEPs merged | [milestone/1](https://github.com/flagos-ai/community/milestone/1) |
| **FlagOS 2.2** | 2026-09-28 | 🔵 Open — accepting FEPs | [milestone/2](https://github.com/flagos-ai/community/milestone/2) |

> **FlagOS 2.2 key dates** — FEP Freeze: **2026-08-15** · Code Freeze: **2026-08-31** · Testing: 09-01 → 09-26. Full schedule and freeze rules: [release/2.2/schedule.md](../release/2.2/schedule.md).

> A FEP is attached to a release milestone once its Owner sets `Target Version` to that release (see [Milestone Usage](#milestone-usage)).

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
| `sig-edge` | Planned SIG | Edge hardware |
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
| **Provisional** | Draft, under SIG discussion | Iterate in PR |
| **Implementable** | Design approved, ready to implement | SIG approvers approve PR, then merge |
| **Implemented** | Code merged, acceptance criteria met | Update doc via PR |
| **Deferred** | Postponed to a later release | Move to next Milestone |
| **Rejected** | Not moving forward | Close PR; rejected FEPs should still be merged to preserve the decision record |

> Status is marked in the FEP doc as `**Status:** <value>` and updated via follow-up PRs at each state transition.

## Workflow

### 0. Socialize with SIG

Before writing a FEP, discuss the idea with the relevant SIG. Make sure there is interest
in the problem space and willingness to review.

> **Bootstrap note:** If the relevant SIG has no Chair, Approver, or meeting yet, open an Issue
> in the target module repository or post in [GitHub Discussions](https://github.com/FlagOS-AI/community/discussions).
> The TSC (or the ZhongZhi FlagOS Community (众智FlagOS社区) before TSC is formed) will route and review. See [GOVERNANCE.md](../GOVERNANCE.md).

### 1. Create the FEP Document

Copy the [FEP template](fep-template/README.md) to `fep/sig-xxx/title-slug.md`.

- `title-slug` is a short hyphenated English description
- Minimum content to start: Summary + Motivation. Everything else can follow later.
- Set initial Status to `Provisional`

### 2. Open a PR

Open a PR with the FEP file.

- PR title should describe the feature
- PR description can be brief — the FEP doc carries the details
- Use a **Draft PR** for early-stage ideas that need more discussion

### 3. Review and Approve

Review, discussion and iteration happen on the PR.

- SIG approvers (listed in OWNERS) approve the PR
- **Bootstrap note:** If the relevant SIG has no Approver yet, the TSC reviews directly. Post in [GitHub Discussions](https://github.com/FlagOS-AI/community/discussions) if you need help routing.
- Once approved, update Status to `Implementable`
- Merge the PR

**Cross-SIG FEPs**: Pick a home SIG whose directory the file lives in. SIGs
impacted by the feature should also review. If no existing SIG fits, use `sig-architecture` (during bootstrap) or ask TSC for routing.

### 4. Implement

- Implementation happens across the relevant repos
- Track related PRs in the `Related PRs` section of the FEP doc
- Update the FEP doc via follow-up PRs when scope or design changes

### 5. Wrap Up

- When all acceptance criteria are met, update Status to `Implemented`
- This is done via a final PR to update the FEP doc

## File Naming

| Convention | When |
|------------|------|
| `title-slug.md` | Before PR is created, or during early draft |
| `NNNN-title-slug.md` | After PR is created, where NNNN is the PR number |

> Rename the file to include the PR number before merge. The PR number serves as the FEP identifier.

## Roles

| Role | Responsibilities |
|------|-----------------|
| **FEP Owner** | Write the FEP, drive implementation, update status, ensure acceptance |
| **SIG Approver** | Review and approve FEP documents (listed in [SIG OWNERS](../sigs/)) |
| **Release Manager** | Track overall FEP progress per version, Go/No-Go decisions |

> For complete role definitions and promotion paths, see [contributors/roles.md](../contributors/roles.md).

## Milestone Usage

- Each FlagOS version has a corresponding Milestone (e.g., `FlagOS 2.1`)
- Milestones have a deadline set
- FEPs targeting a version are associated with the corresponding Milestone
- Release Manager tracks progress via the Milestone view
- Live status for every release is surfaced at the top of this page under [🚩 Release Tracker](#-release-tracker)

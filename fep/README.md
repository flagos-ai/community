# FEP — FlagOS Enhancement Proposal

## What is a FEP

A FEP (FlagOS Enhancement Proposal) is the mechanism for managing features in FlagOS.
Each cross-module or significant feature gets a FEP — a markdown design document,
stored under `fep/sig-*/`, submitted and reviewed via PR.

**Toolchain**: GitHub PR + Markdown file + OWNERS approval

## SIG Groups

| SIG | Modules |
|-----|---------|
| `sig-operator` | FlagGems, FlagAttention, FlagFFT, FlagSparse, FlagDNN, FlagBLAS, FlagTensor, FlagAudio |
| `sig-compiler` | FlagTree |
| `sig-network` | FlagCX |
| `sig-framework` | PyTorch-Plugin-FL, vllm-plugin-FL, sglang-plugin-FL, TransformerEngine-FL, Megatron-LM-FL, verl-FL |
| `sig-training` | FlagScale |
| `sig-kernelgen` | KernelGen |
| `sig-embodied` | FlagOS-Robo |
| `sig-ai4s` | FlagQuantum |
| `sig-benchmark` | FlagPerf |
| `sig-agent` | Skills |
| `sig-tools` | FlagRelease |
| `sig-edge` | Edge-side hardware — Arm CPU, mobile NPU, IoT devices |
| `sig-architecture` | Cross-cutting features, process changes |

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
- Once approved, update Status to `Implementable`
- Merge the PR

**Cross-SIG FEPs**: Pick a home SIG whose directory the file lives in. SIGs
impacted by the feature should also review. If no existing SIG fits, use `sig-architecture`.

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
| **SIG Approver** (OWNERS) | Review and approve FEP documents |
| **Release Manager** | Track overall FEP progress per version, Go/No-Go decisions |

## Milestone Usage

- Each FlagOS version has a corresponding Milestone (e.g., `FlagOS 2.1`)
- Milestones have a deadline set
- FEPs targeting a version are associated with the corresponding Milestone
- Release Manager tracks progress via the Milestone view

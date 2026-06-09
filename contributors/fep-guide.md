# FEP Writing Guide

This document is for contributors who want to propose a FlagOS Enhancement Proposal. For the full FEP process, see [fep/README.md](../fep/README.md).

## When to Write a FEP

| Scenario | Need a FEP? |
|----------|-------------|
| Cross-module feature (involving ≥2 repos) | **Required** |
| New chip support | **Required** |
| New module / new repository | **Required** |
| Major module-level feature | **Recommended** |
| Small feature or bugfix in a single repo | **Not needed** |
| Documentation improvement | **Not needed** |

## Step 1: Find Your SIG

Locate the SIG that corresponds to the module(s) involved in your proposal:

| Module(s) Involved | Corresponding SIG | Status |
|--------------------|-------------------|--------|
| FlagGems, FlagAttention, FlagFFT, FlagSparse, FlagDNN, FlagBLAS, FlagTensor, FlagAudio | [sig-operator](../sigs/sig-operator/) | Active |
| FlagTree | [sig-compiler](../sigs/sig-compiler/) | Active |
| FlagCX | [sig-network](../sigs/sig-network/) | Active |
| PyTorch-Plugin-FL, vllm-plugin-FL, sglang-plugin-FL, TransformerEngine-FL, Megatron-LM-FL, verl-FL | [sig-framework](../sigs/sig-framework/) | Active |
| FlagScale | [sig-training](../sigs/sig-training/) | Active |
| KernelGen, KernelGenBench | [sig-kernelgen](../sigs/sig-kernelgen/) | Active |
| Chip porting | [sig-chip](../sigs/sig-chip/) | Active |
| FlagPerf | [sig-benchmark](../sigs/_planned/sig-benchmark.md) | Planned |
| FlagRelease | [sig-tools](../sigs/_planned/sig-tools.md) | Planned |
| Skills | [sig-agent](../sigs/_planned/sig-agent.md) | Planned |
| FlagQuantum | [wg-ai4s](../wg/wg-ai4s/) | Incubating |
| FlagOS-Robo | [wg-embodied](../wg/wg-embodied/) | Incubating |
| Crosses multiple SIGs or none of the above | Home SIG assigned by TSC | — |

> SIGs/WGs marked "Planned" or "Incubating" have no Approver yet. FEPs for these modules are approved directly by the TSC.

## Step 2: Socialize Within Your SIG

**Discuss your idea within the SIG before writing the FEP document.**

Ways to do this:
- Briefly describe your idea in a GitHub Issue or Discussion for the relevant module
- If the SIG already holds regular meetings, attend and give a short introduction
- Confirm the SIG is interested in the direction and that someone is willing to review

> **Bootstrap phase note**: If the SIG has not officially started operating (no Chair, no chat group, no meetings), you may directly open an Issue or PR in the relevant module repo. The TSC will route it directly. See [GOVERNANCE.md](../GOVERNANCE.md) for bootstrap phase transition procedures.

## Step 3: Write the FEP Document

1. Copy the [FEP template](../fep/fep-template/README.md) to `fep/sig-xxx/title-slug.md`
2. Fill in at minimum: Summary + Motivation + Goals + Test Plan
3. Set the initial Status to `Provisional`
4. Title format: `NNNN-title-slug.md` (NNNN = PR number)

## Step 4: Open a PR

1. Open a Draft PR (if further discussion is needed) or a regular PR (if already well-discussed)
2. The PR title should describe the feature; the PR description can be brief — the FEP document itself carries the details
3. Link the PR to the corresponding Milestone

## Step 5: Drive the Approval

- The SIG Approver (or the TSC during the bootstrap phase) will provide initial feedback within 2 weeks
- Actively respond to review comments and update the document
- If multiple SIGs are involved, an Approver from each relevant SIG must approve
- Once approved, update Status to `Implementable` and merge the PR

## Step 6: Implement & Wrap Up

- Implement the feature in the relevant repos
- Track implementation PRs in the FEP document's Related PRs section
- Once everything is complete, update Status to `Implemented`

## FEP Status Transitions

```
Provisional ──→ Implementable ──→ Implemented
     │                                ↑
     ├──→ Deferred ──────────────────┘
     └──→ Rejected
```

| Status | Meaning |
|--------|---------|
| Provisional | Draft, under discussion within the SIG |
| Implementable | Design approved, ready to begin implementation |
| Implemented | Code merged, acceptance complete |
| Deferred | Postponed to a later release |
| Rejected | Will not proceed (PR must still be merged to preserve the decision record) |

## FAQ

**Q: Not sure which SIG your proposal belongs to?**
Ask in a GitHub Discussion, or open a PR directly in the relevant module repo. During the bootstrap phase, the TSC handles routing and review directly.

**Q: What if the SIG doesn't respond within two weeks?**
Note this in a PR comment and post in [GitHub Discussions](https://github.com/FlagOS-AI/community/discussions) for help. See [MAINTAINERS.md](../MAINTAINERS.md) for bootstrap phase contacts.

**Q: What if my FEP is rejected?**
Rejected FEPs must still be merged as a PR — preserving decision records is an important open-source governance practice.

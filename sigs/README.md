# FlagOS SIG Overview

## Active SIGs (8)

| SIG | Modules | Layer | Meetings |
|-----|---------|-------|----------|
| [sig-operator](sig-operator/) | FlagGems, FlagAttention, FlagFFT, FlagSparse, FlagDNN, FlagBLAS, FlagTensor, FlagAudio | L1 | TBD |
| [sig-compiler](sig-compiler/) | FlagTree | L0 | TBD |
| [sig-network](sig-network/) | FlagCX | L0 | TBD |
| [sig-framework](sig-framework/) | PyTorch-Plugin-FL, vllm-plugin-FL, sglang-plugin-FL, TransformerEngine-FL, Megatron-LM-FL, verl-FL | L2 | TBD |
| [sig-training](sig-training/) | FlagScale | L3 | TBD |
| [sig-kernelgen](sig-kernelgen/) | KernelGen, KernelGenBench | L3 | TBD |
| [sig-chip](sig-chip/) | Datacenter chip adaptation (NVIDIA, Hygon, Iluvatar, MetaX, and 9 others — 13 total) | — | TBD |
| [sig-edge](sig-edge/) | Edge hardware and edge-side SDK | — | TBD |

## Incubating Working Groups (2)

| WG | Focus Area | Promotion Criteria |
|----|-----------|--------------------|
| [wg-embodied](../wg/wg-embodied/) | Robotics | ≥3 active Contributors + ≥1 demonstrable scenario |
| [wg-ai4s](../wg/wg-ai4s/) | AI for Science / Quantum Computing | ≥3 active Contributors + paper or demo |

## Planned SIGs

The following areas have been identified as important but no Chair candidate has been found yet. They will be activated when conditions are met.

| Area | Charter Draft | Activation Criteria |
|------|---------------|---------------------|
| sig-benchmark | [_planned/sig-benchmark.md](_planned/sig-benchmark.md) | ≥2 people dedicated full-time to benchmark output |
| sig-documentation | [_planned/sig-documentation.md](_planned/sig-documentation.md) | Docs virtual team delivers Getting Started + API Ref |
| sig-user-ecosystem | [_planned/sig-user-ecosystem.md](_planned/sig-user-ecosystem.md) | GitHub Discussions MAU ≥50, external contributors ≥10 |
| sig-release | [_planned/sig-release.md](_planned/sig-release.md) | Release cadence increases, requiring a standing body |
| sig-agent | [_planned/sig-agent.md](_planned/sig-agent.md) | Skills module attracts active external contributors |
| sig-tools | [_planned/sig-tools.md](_planned/sig-tools.md) | FlagRelease has external contributors |
| sig-architecture | [_planned/sig-architecture.md](_planned/sig-architecture.md) | Held by TSC members concurrently; no standalone SIG for now |
| sig-os | [_planned/sig-os.md](_planned/sig-os.md) | Wave 1 unified packaging (FEP-19) lands and a Chair candidate emerges |
| sig-riscv | [_planned/sig-riscv.md](_planned/sig-riscv.md) | `riscv64` build experiments (FEP-34) land and a Chair candidate emerges |

## SIG Creation Process

1. Proposer submits a Charter draft + initial member list to TSC (PR to community repo)
2. TSC votes within 2 weeks
3. Upon approval, create directory structure and add to this index page
4. Chair executes the [SIG Launch Checklist](#sig-launch-checklist)

### SIG Launch Checklist

After TSC approves a new SIG, the Chair must complete the following within **2 weeks**.

**GitHub**
- [ ] Create `sigs/sig-xxx/` directory: `README.md` (Charter), `meetings/`
- [ ] Request a SIG-specific GitHub label (`sig/xxx`) for tagging Issues and PRs
- [ ] Update this page (`sigs/README.md`) with the SIG list and meeting calendar

**Communication Channels**
- [ ] Create SIG WeChat group and set group notice (SIG name, meeting time, GitHub link)
- [ ] If a mailing list is needed, contact TSC to create one (planned)
- [ ] Post a SIG launch announcement in GitHub Discussions

**Meetings & Recordings**
- [ ] Set a biweekly meeting time (staggered from TSC meetings), update the [Meeting Calendar](#meeting-calendar)
- [ ] Create a Bilibili / YouTube playlist for uploading meeting recordings
- [ ] Publish the agenda before the first meeting (per the [Meeting Operations Guide](../contributors/meeting-guide.md))

**Community Participation**
- [ ] Chair and tech leads read the [Moderation Guidelines](../contributors/communication-guidelines.md#viii-moderation)
- [ ] Give a SIG introduction at the next community all-hands (5-minute lightning talk)
- [ ] Submit the first monthly brief to TSC (1 page, including meeting notes link and key progress)

**Bootstrap Phase Simplification**: Before the TSC is formed, the ZhongZhi FlagOS Community will assist the Chair with the checklist items involving WeChat groups, GitHub labels, Bilibili playlists, etc. GitHub label requests will be filed by TSC members on behalf of the SIG.

## SIG Roles

A SIG has exactly two roles — **Chair** and **Tech Lead** — recorded centrally in
[data/sigs.yaml](../data/sigs.yaml). Code merge and PR approval authority belongs
to the subproject (per [data/projects.yaml](../data/projects.yaml)); a SIG has no
Approver/Reviewer roles, and there is no per-SIG `OWNERS` file. FEPs are approved
by the Chair + Tech Lead.

**Do NOT fill roles with TBD, placeholder, or unconfirmed individuals.** Leave
fields empty if no one is assigned.

## Meeting Calendar

| Time (UTC+8) | Meeting | Link |
|-------------|---------|------|
| TBD | TSC Meeting | — |
| TBD | SIG Meetings | See individual SIG Charters |

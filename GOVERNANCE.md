# FlagOS Governance

[English](GOVERNANCE.md) | [中文](GOVERNANCE_CN.md)

FlagOS community governance follows the principle of **people first, structure later**. This document defines the decision-making mechanism and role system. For individual SIG charters, see [sigs/](sigs/).

## Project Principles

### Vendor Neutrality

FlagOS is a multi-chip AI system software project that maintains neutrality across chip vendors, cloud providers, and organizations. Community decisions are based on technical merit — the soundness and maintainability of the approach and its value to the community — not on the commercial influence of a contributor's organization.

- All contributors are treated equally in community roles and decision-making, regardless of organizational affiliation
- Code contributions from chip vendors must meet the same technical standards and CI requirements
- TSC members and SIG Chairs act as individuals when performing community duties, not as representatives of their employers

### Public Decision Records

All technical and governance decisions must be recorded publicly on GitHub. Substantive governance decisions must not be made through private channels (WeChat, phone, email, etc.).

## Bootstrap Phase Transition

### Decision-Making Entity

Before the first TSC meeting, the project is governed by the **ZhongZhi FlagOS Community** (众智FlagOS社区), the founding team of the FlagOS project, consisting of core engineers and community organizers from the project's initiators.

**Decision-Making**: All decisions by the ZhongZhi FlagOS Community are made publicly on GitHub. Routine decisions follow lazy consensus (a proposal passes if no objection is raised within 72 hours on the PR/Issue). Major decisions (SIG creation, version releases, governance changes) are decided by vote (2/3 majority) on GitHub Discussions or the corresponding PR/Issue. All decisions must have a GitHub record.

**Bootstrap Exception**: The initial cohort of roles (TSC members, SIG Chairs, SIG Approvers) are directly appointed by the ZhongZhi FlagOS Community without going through the standard promotion process. They are confirmed in MAINTAINERS.md and the corresponding OWNERS files. Once the initial roles are in place, all subsequent promotions follow the standard process defined in [Role Definitions & Promotion](contributors/roles.md).

### Initial Role Appointment Sequence

```
ZhongZhi FlagOS Community
  │
  ├→ Step 1: Appoint TSC members (3–5) → record in MAINTAINERS.md
  │
  ├→ Step 2: TSC confirms SIG Chairs + Tech Leads from community contributors → record in MAINTAINERS.md
  │
  ├→ Step 3: Chair + TSC confirm SIG Approvers → record in OWNERS files
  │
  └→ Transition ends: standard promotion process takes effect
```

### First TSC Meeting

**Trigger**: TSC membership reaches ≥ 3 confirmed members (listed in MAINTAINERS.md with their informed consent).

**Convener**: The ZhongZhi FlagOS Community designates one of the TSC members as interim TSC Chair, responsible for convening the first meeting. The formal TSC Chair is elected by TSC members from among themselves at the first meeting.

**First Meeting Agenda**:
1. Elect the TSC Chair (mutual election)
2. Confirm the list of SIG Chairs and Tech Leads
3. Confirm the plan for handling backlog PRs/FEPs from the transition period
4. Set the bi-weekly meeting schedule

After the first meeting, day-to-day decisions are handled by the TSC. Transitional rules phase out gradually.

### Transitional Rules

| Matter | Before First TSC Meeting | After First TSC Meeting |
|--------|--------------------------|-------------------------|
| All decisions | ZhongZhi FlagOS Community handles directly | TSC takes over |
| SIG meetings | Not required | TSC bi-weekly meeting is the only mandatory meeting |
| Contributor can't find a SIG | File a PR directly, comment on the PR + post in GitHub Discussions; ZhongZhi FlagOS Community responds | Same; TSC members handle routing |
| FEP ownership | FEPs with no SIG home go under `fep/sig-architecture/`; reviewed by ZhongZhi FlagOS Community | Same; reviewed by TSC |
| Chip vendor onboarding | If sig-chip has no Chair, vendors contact ZhongZhi FlagOS Community (see MAINTAINERS.md) | TSC handles |
| Release Manager | Appointed by ZhongZhi FlagOS Community | Appointed by TSC |

### Transition Completion

The transition period ends when OWNERS files are first populated (roles confirmed with informed consent) and the TSC has held its first meeting. The target is to complete Chair and Approver confirmation within **3 months**.

### Bootstrap SIG Notes

The directories and charters for the current 7 SIGs have been pre-created as placeholders for bootstrap-phase technical directions. These SIGs are in a **"pre-created, awaiting activation"** state — directories exist, but OWNERS are empty and decision-making authority rests with the TSC.

Future SIGs must strictly follow the [SIG Creation Conditions](#creation-conditions): **a SIG without a Chair is not created**. Directory structure is created only after ≥ 1 Chair is confirmed.

At the first TSC meeting, each of the 7 pre-created SIGs is reviewed: those with a confirmed Chair are formally activated; those without remain in pre-created status, with the TSC continuing to directly manage the corresponding modules.

## Technical Steering Committee (TSC)

The TSC is the highest technical decision-making body of the FlagOS project.

### Responsibilities

- Establish and revise the project's technical direction and governance rules
- Approve the creation, dissolution, or merger of SIGs
- Resolve cross-SIG disputes (escalated when a SIG cannot reach internal consensus)
- Approve major version releases (Go/No-Go decisions)
- Maintain GOVERNANCE.md and CODE_OF_CONDUCT.md

### Composition

- **Bootstrap phase**: 3–5 members, appointed by the ZhongZhi FlagOS Community
- **Mature phase**: 5–7 members, elected by SIG Chair mutual election + community election, 2-year term

### Decision Rules

| Type | Rule |
|------|------|
| **Routine decisions** | Lazy consensus — a proposal passes if no objection is raised on GitHub within 72 hours |
| **Major decisions** | New SIG creation/dissolution, version Go/No-Go, TSC membership changes — requires 2/3 majority vote |
| **Emergency decisions** | The TSC Chair may make a provisional decision (must be co-signed by ≥ 1 other TSC member), retroactively confirmed within 72 hours |
| **Meeting quorum** | ≥ 50% of TSC members present |

### Conflict of Interest (CoI)

TSC members exercise independent technical judgment in community decisions.

**Disclosure Requirement**: TSC members must proactively declare conflicts of interest when:
- A vote directly involves the commercial interests of their employer or affiliated organization (e.g., chip tier promotion/demotion, CI resource allocation, vendor-related FEPs)
- A vote involves an entity in which they have a direct financial interest

**Declaration Method**: Clearly state in the voting Issue/PR comment: "CoI declaration: I am employed by / affiliated with <organization name>." After declaration, the member may still vote — FlagOS assumes community members are capable of independent technical judgment. Recusal is at the individual's discretion.

**Record-Keeping**: All CoI declarations must be recorded in the corresponding decision document.

**Violations**: Deliberately concealing a significant conflict that affects decision fairness may result in recusal on that matter by a 2/3 vote of other TSC members. Serious cases may trigger an investigation under the [Code of Conduct](CODE_OF_CONDUCT.md).

### TSC Chair

Elected by TSC members from among themselves. 1-year term, renewable. Responsibilities:
- Chair TSC meetings; publish agendas and meeting notes
- Make provisional decisions in emergencies (co-signed by ≥ 1 other TSC member)
- Represent the project's technical direction externally

---

## SIG (Special Interest Group)

A SIG is a standing group organized around a specific technical domain or ecosystem area.

### Creation Conditions

**A SIG must simultaneously meet all of:**
1. At least 1 Chair confirmed (target ≥ 2)
2. At least 1 Tech Lead confirmed
3. At least 3 initial members (excluding Chair and TL)
4. A clear Charter (scope, responsibility boundaries)

**A SIG without a Chair is not created.** The TSC directly manages the corresponding modules and decisions for that domain.

### Roles

| Role | Responsibilities | Term |
|------|-----------------|------|
| **Chair** (≥1) | Run SIG meetings, represent the SIG externally, report annually to TSC | 1 year, renewable |
| **Tech Lead** (≥1) | SIG-level technical direction decisions, architecture review | No fixed term |
| **Approver** | Approve FEPs and PRs (binding), merge code | Ongoing activity |
| **Reviewer** | Provide LGTM on PRs (non-binding) | Ongoing activity |
| **Member** | Attend meetings, file Issues and PRs | — |

Promotion path: Member → Reviewer (≥ 5 merged PRs) → Approver (sustained contribution ≥ 3 months + 2/3 Approver vote) → Tech Lead (Chair nomination + TSC approval) → Chair (elected from Tech Leads + TSC approval)

### Creation Process

1. Proposer submits a SIG Proposal to the TSC (PR to community repo, including draft Charter + initial member list)
2. TSC votes within 2 weeks
3. Upon approval, create the `sigs/sig-xxx/` directory (Charter + OWNERS + meetings/)

### Dissolution Process

1. Chair or TSC initiates a dissolution proposal
2. 2-week public comment period
3. TSC votes (2/3 majority)
4. Upon dissolution, archive the SIG and reassign its modules

### Subprojects

Concrete work within a SIG is organized into **subprojects**. Each module repository in FlagOS is a subproject belonging to its corresponding SIG.

**Subproject OWNERS**

Each subproject has its own OWNERS file defining the module's technical leads:

```yaml
# Module repo root OWNERS
approvers:
  - sig-xxx-approvers   # References the alias in community OWNERS_ALIASES

reviewers:
  - sig-xxx-reviewers
```

> **OWNERS_ALIASES**: The community root [OWNERS_ALIASES](OWNERS_ALIASES) centrally defines the Reviewer and Approver aliases for each SIG. Module OWNERS files reference aliases rather than individual GitHub IDs. When personnel change, only OWNERS_ALIASES needs updating — no need to update each module's OWNERS file individually.

Subproject Approvers have binding approval authority over code changes within their module. Cross-subproject changes (e.g., modifying public APIs) require approval from Approvers of all affected subprojects.

**Subproject vs. SIG**

| Level | Decision Scope | Roles |
|-------|---------------|-------|
| **SIG** | Cross-module FEPs within the SIG's domain, architecture direction, personnel promotion | Chair + Tech Lead + Approvers |
| **Subproject** | PR approval within a single module repo, module-level technical decisions | Subproject Approvers + Reviewers |

SIG Approvers automatically have approval authority across all subprojects under their SIG (cross-module approval). Subproject Approvers only have approval authority within their assigned module scope.

**Subproject Creation**

1. The SIG Chair or an existing subproject Approver submits a PR adding an OWNERS file to the new module repository
2. At least 1 subproject Approver is designated (may initially be the SIG Chair or Tech Lead)
3. The subproject is registered in the "Subprojects" table of the SIG Charter

**Subproject Retirement**

- When a module is archived/deprecated, the SIG Chair submits a PR to update the SIG Charter
- The archived module's OWNERS file is preserved, marked `archived: true`
- Related GitHub labels and CI resources are recycled under TSC coordination

### Working Group (WG)

A WG is a precursor to a SIG. It may graduate to SIG status when conditions are met.

| Graduation Condition | ≥ 3 active Contributors + ≥ 1 demonstrable scenario/output |

---

## FEP (FlagOS Enhancement Proposal)

The FEP is the proposal mechanism for managing cross-module or significant features. See [fep/README.md](fep/README.md) for details.

Abbreviated workflow:
1. Socialize the idea in the relevant SIG
2. Copy the FEP template and draft the proposal
3. Open a PR for SIG Approver review
4. Cross-SIG review (if applicable)
5. Merge; set status to Implementable
6. Update status to Implemented once implementation is complete

> **Bootstrap note**: When a SIG is not yet formally operational, "SIG Approver review" in the above workflow is performed directly by the TSC. See [Bootstrap Phase Transition](#bootstrap-phase-transition) above.

---

## Version Releases

- Each major version appoints 1 **Release Manager** (designated by the TSC)
- The Release Manager is responsible for: release calendar, FEP progress tracking, Go/No-Go meeting facilitation, release notes
- See [release/README.md](release/README.md) for the major release process (including patch releases and backport policy)
- Release tooling: [release/](release/)

---

## Meeting System

| Meeting | Frequency | Duration |
|---------|-----------|----------|
| TSC Meeting | Bi-weekly | 60 min |
| SIG Meeting | Bi-weekly (staggered with TSC) | 45 min |
| Community Town Hall | Quarterly | 90 min |

- All meeting agendas are published publicly ≥ 24 hours in advance
- Meeting notes are published to GitHub within 48 hours

---

## Code of Conduct

All participants must abide by the [Code of Conduct](CODE_OF_CONDUCT.md).

---

## Related Documents

- [SIG Overview](sigs/README.md) — Index of all active SIGs and meeting calendar
- [MAINTAINERS.md](MAINTAINERS.md) — TSC + Chair roster
- [Contributor Guide](contributors/) — How to contribute
- [FEP Process](fep/README.md) — FlagOS Enhancement Proposal details
- [Role Definitions & Promotion](contributors/roles.md) — Community roles, promotion path, and offboarding
- [TSC Election Process](contributors/election.md) — Mature-phase TSC election procedures
- [SIG Annual Report](contributors/sig-annual-report.md) — Template and health assessment
- [Communication Channels](contributors/communication-guidelines.md) — Channel operations and moderation
- [Code Review Guide](contributors/review-guide.md) — PR review standards and workflow
- [Issue Triage Guide](contributors/issue-triage.md) — Issue classification, priority, and response SLAs
- [OWNERS_ALIASES](OWNERS_ALIASES) — Reviewer/Approver alias definitions for each SIG

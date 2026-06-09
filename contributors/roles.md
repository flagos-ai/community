# Role Definitions & Promotion Paths

[English](roles.md) | [中文](roles_CN.md)

## Role Hierarchy

```
Member
  │  Participate in SIG meetings, file Issues, contribute PRs
  │  Requirements: Follow Code of Conduct + ≥1 merged PR
  │
  ▼
Reviewer
  │  Can give LGTM on PRs (non-binding)
  │  Requirements: ≥5 merged PRs in SIG scope, ≥1 Approver sponsor, Chair approval
  │
  ▼
Approver / Maintainer
  │  Can approve FEPs and PRs (binding), can merge code
  │  Requirements: ≥3 months continuous contribution, ≥2 months as Reviewer, significant contributions in module
  │        ≥2 existing Approvers co-nominate, 2/3 Approver vote
  │
  ▼
Tech Lead
  │  SIG technical direction decisions, architecture review
  │  Requirements: Deep technical influence within SIG scope, Chair nomination + TSC approval
  │
  ▼
Chair
  │  SIG external representative, chairs regular meetings, annual report, TSC liaison
  │  Requirements: Selected from Tech Leads, TSC approval, 1-year term (renewable)
  │
  ▼
TSC Member
     Cross-SIG governance, overall project direction
     Requirements: Appointed by ZhongZhi FlagOS Community (众智FlagOS社区) during bootstrap;
                   elected by Chair mutual selection + community election in mature phase, 2-year term
```

## Permission Matrix

| Permission | Member | Reviewer | Approver | Tech Lead | Chair | TSC |
|------|--------|----------|----------|-----------|-------|-----|
| Submit Issue / PR | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Participate in SIG informal polls (directional feedback) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Give LGTM | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Approve & Merge PR | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Approve FEP | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| SIG technical direction decisions | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| Merge / sunset SIG | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Version Go/No-Go | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## How to Become a Member

Member is the foundational role in the community. No formal application is required — anyone who meets the following criteria is considered a community Member:

1. Have ≥1 merged PR in any FlagOS module repository (code, docs, or tests)
2. Have read and agree to abide by the [Code of Conduct](../CODE_OF_CONDUCT.md)
3. Have read [GOVERNANCE.md](../GOVERNANCE.md)

Once the criteria are met, add your GitHub ID to the relevant SIG's OWNERS file and submit a PR. Any Approver can review and merge it.

> **Bootstrap note:** When OWNERS is empty, PR to the community repo is reviewed directly by the TSC. Also announce in GitHub Discussions.

### Member Rights & Responsibilities

- May be assigned Issues and PRs
- May vote in SIG meetings and community discussions (directional feedback)
- Must respond to assigned Issues and PRs
- Must take responsibility for contributed code (passing tests, responding to bugs)

---

## Promotion Process

### Sponsorship

FlagOS role promotion requires a **sponsor** who holds an existing role. The sponsor must have directly collaborated with the candidate (code review, design discussion, issue collaboration, etc.) and have confidence in the candidate's ability and judgment.

| Promotion | Sponsor Requirement | Notes |
|------|-----------|------|
| Member → Reviewer | ≥1 Approver in the same SIG | Approver vouches for the candidate's review quality |
| Reviewer → Approver | ≥2 Approvers in the same SIG co-nominate | Ensures multiple Approvers endorse the candidate's technical judgment |
| Approver → Tech Lead | ≥1 Chair in the same SIG nominates | Chair assesses suitability from SIG-wide perspective |
| Tech Lead → Chair | Self-nomination or existing Chair nomination | — |

Sponsors must confirm sponsorship by replying `+1` in the promotion PR. Sponsors from different organizations/companies are preferred.

> **Bootstrap Exception:** The initial TSC members, SIG Chairs, and SIG Approvers are appointed directly by the ZhongZhi FlagOS Community (众智FlagOS社区) without going through the standard promotion process and sponsorship. Once the initial roles are in place (first population of OWNERS files), subsequent promotions strictly follow this document. See [GOVERNANCE.md](../GOVERNANCE.md) for bootstrap transition.

### Member → Reviewer

1. Accumulate ≥5 merged PRs within the SIG scope (including at least 3 code PRs)
2. Participated in ≥5 PR reviews within the SIG scope (comment or LGTM)
3. ≥1 Approver in the same SIG as sponsor
4. Submit a PR updating the OWNERS file (reviewers list); sponsor replies `+1` in the PR
5. SIG Chair approval (lazy consensus, passes if no Approver objects within 72h)

**Promotion criteria**: Primarily evaluates code quality and review participation; no specific time duration required.

### Reviewer → Approver

1. Held Reviewer role for ≥2 months
2. Significant technical contributions within the module (described by sponsor in nomination)
3. **≥2 existing Approvers co-nominate** (from different organizations/companies preferred)
4. Submit a PR updating the OWNERS file (approvers list); nominating Approvers reply `+1`
5. 2/3 vote by existing SIG Approvers (≥72h voting period)

> **When voter count is insufficient:** If a SIG has fewer than 3 existing Approvers, the decision automatically escalates to TSC review (lazy consensus, 72h). The TSC must consider the nominating Approvers' opinions during review.

**Promotion criteria**: Core evaluation is technical judgment and sense of responsibility. Approvers decide what code enters the project — this is the most critical permission gate.

### Approver → Tech Lead

1. Deep technical influence within the SIG scope (has guided technical direction of multiple sub-projects)
2. Chair nomination (must describe the candidate's demonstrated technical leadership)
3. TSC approval (lazy consensus, 72h)
4. Update SIG Charter

### Tech Lead → Chair

1. Existing Chair nomination or self-nomination
2. TSC approval
3. 1-year term, renewable

### TSC Member

Appointed by the ZhongZhi FlagOS Community (众智FlagOS社区) during bootstrap, 2-year term.

For mature-phase election process, see [TSC Election Process](election.md).

---

## TSC Election Process

For mature-phase election process, see [TSC Election Process](election.md).

### Election Timing

- Regular elections held every 2 years
- Election timing aligned with the end month of the previous term
- By-elections held within 2 months when a vacancy occurs (member resignation / departure)

### Voter Eligibility

- Community Members with ≥1 merged PR in the 12 months prior to the election announcement
- Voter list published by TSC 2 weeks before the election, open to objections

### Candidate Eligibility

- Current or former SIG Chair or Tech Lead
- Or former Approver for ≥12 months
- Self-nomination or nomination by ≥2 existing TSC members

### Voting Process

1. **Nomination period** (2 weeks): Candidates declare candidacy in a GitHub Issue with a platform statement
2. **Review period** (1 week): Candidate list published; community may ask questions
3. **Voting period** (1 week): Anonymous ranked-choice voting using [Elekto](https://elekto.dev/) or similar tooling
4. **Results announcement**: TSC Chair announces the elected members

### Seat Allocation

- 5-7 seats, filled in descending order of votes received
- No more than 2 seats from the same organization/company (prevents single-employer control)
- Ties decided by vote of the current TSC

### Terms & Staggering

- 2-year term, renewable
- At the first election, half of the seats have a 1-year term (determined by lot) to achieve staggered terms
- Thereafter, roughly half of the seats are up for election each cycle

---

## Role Exit

### Voluntary Exit

Submit a PR updating the OWNERS file or MAINTAINERS.md. It is recommended to state the reason and handover items in the exit statement.

### Inactivity Exit

| Role | Inactivity Definition | Handling |
|------|-----------|----------|
| **Member** | No contributions of any kind (PR, review, issue, community discussion) for 12 months | TSC may propose removal from OWNERS |
| **Reviewer** | No review activity for 6 months | Chair reminds; auto-removal after 12 consecutive months of inactivity |
| **Approver** | No activity for 3 consecutive months (no PR review, no issue participation) | SIG Chair may propose removal; lazy consensus by other Approvers |
| **Tech Lead** | Unable to perform duties for 2 consecutive months | Chair consults with TSC on replacement |
| **Chair** | — | See "Chair Vacancy" below |
| **TSC** | Missed 3 consecutive TSC meetings without notice; or no community activity of any kind for 6 consecutive months (no PR review, no issue participation, no community discussion, no email/WeChat group participation) | TSC vote (2/3) may remove |

### Chair Vacancy

- If the Chair steps down early, TSC appoints an interim Chair within 1 month
- Simultaneously open recruitment for a formal Chair (SIG internal nomination + TSC approval)
- Interim Chair serves until a formal Chair is elected, maximum 3 months

### Forced Removal

Any role may be forcibly removed for violation of the [Code of Conduct](../CODE_OF_CONDUCT.md), after TSC investigation and confirmation. Requires 2/3 TSC vote.

### Reinstatement After Exit

- Those removed for inactivity may reapply for their original role after 2 months of active contribution. **Active contribution** means ≥2 merged PRs or ≥5 valid PR reviews during this period.
- Those removed for CoC violations require unanimous TSC vote for reinstatement.

---

## Other Forms of Contribution

Writing code is not the only form of contribution. The following contributions are equally counted in promotion evaluation:

- Documentation writing and translation
- Issue triage and community support
- Benchmark testing and data maintenance
- FEP review and technical discussion
- Community event organization
- Meeting minutes and agenda preparation

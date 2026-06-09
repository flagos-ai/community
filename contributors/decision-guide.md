# Decision-Making Manual

[English](decision-guide.md) | [中文](decision-guide_CN.md)

This document is the operational guide for [GOVERNANCE.md](../GOVERNANCE.md), providing the **specific execution steps** for each decision type.

---

## 1. Lazy Consensus (Default Decision Method)

**Applicable scenarios**: Routine PR approval, FEP advancement, SIG internal regular decisions.

### Procedure

**Initiator:**

1. Annotate `**Decision**: <decision content>` in the GitHub PR description
2. @mention relevant Approvers and SIG Chair in a PR comment
3. Wait **72 hours** (counting from PR creation or last substantive modification)
4. If no Approver objection and no blocking review comment within 72h → **Decision passed**
5. Before merging the PR, the initiator confirms in a comment: `Decision passed (lazy consensus, 72h no objection)`

**Approver:**

1. After receiving @mention, state your position within 72 hours
2. Agree → LGTM or approve
3. Changes needed → leave a review comment, **clearly mark whether it is blocking**: `Non-blocking: suggest xxx` vs `Blocking: must resolve xxx first`
4. Object → clearly write `Object: <reason>` in a PR comment and provide an alternative proposal

**Chair:**

1. Ensure relevant Approvers have noticed the proposal within 72 hours
2. If an Approver has not responded, the Chair is responsible for reminding them
3. Still no response 48h after reminder → that Approver is considered abstaining, does not affect the clock
4. If all Approvers are unresponsive → Chair may decide independently or escalate to TSC
5. If an objection is raised, Chair organizes discussion and attempts to reach consensus
6. If consensus cannot be reached within 48 hours → escalate to voting

### Time Calculation

```
Start: PR creation time or time of last substantive modification
End: Start + 72h
Excluded: Weekends and statutory holidays are not counted (in practice calculated by calendar days,
          but Approvers may request extension to the next business day)
```

### Status Labels

Use labels on PRs to aid tracking:

| Label | Meaning |
|-------|------|
| `needs-decision` | Proposal requires Approver decision |
| `lazy-consensus` | Waiting for 72h to expire |
| `under-discussion` | Under discussion, clock paused |
| `decision-reached` | Decision reached |

---

## 2. Voting

**Applicable scenarios**: New SIG creation / sunset, version Go/No-Go, TSC member changes, role promotions, and escalation when lazy consensus fails to reach consensus.

### Procedure

**Initiator:**

1. Initiate a vote in the corresponding GitHub Issue or PR
2. Clearly state the voting options (typically "Approve / Reject / Abstain")
3. Set a voting deadline (recommended ≥72h)
4. @mention all members with voting rights
5. Tally votes after the deadline and announce the result

> **Conflict of Interest Declaration:** Voters with a conflict of interest (see [GOVERNANCE.md](../GOVERNANCE.md) conflict of interest provisions) should voluntarily declare it in their voting comment. After declaration, they may still vote normally; recusal is not mandatory.

**Voting Template:**

```markdown
## Vote: <Topic>

**Initiator**: @github-id
**Deadline**: YYYY-MM-DD HH:MM (UTC+8)
**Quorum**: ≥50% (N/N)
**Pass Condition**: 2/3 majority

**Options**:
- [ ] Approve
- [ ] Reject
- [ ] Abstain

**Background**: (link to proposal doc / PR)

Members with voting rights, please vote by commenting on this Issue.
```

### Tallying Rules

| Rule | Description |
|------|------|
| **Quorum** | Number of participants must be ≥50% of total eligible voters; otherwise the vote is invalid |
| **Pass Condition** | Approve votes / (Approve votes + Reject votes) ≥ 2/3. Abstentions are not counted in the denominator |
| **Tie** | If approve and reject votes are equal, the Chair has one additional deciding vote |
| **Non-vote** | Not voting before the deadline is treated as abstention |
| **Invalid Vote** | Participation below quorum → vote invalid. Chair re-initiates within one week, may adjust voter scope or extend voting period. Two consecutive invalid votes → Chair or TSC decides directly |

### Recording Voting Results

Voting results must be recorded in the Issue/PR, in this format:

```markdown
## Voting Result

**Approve**: @a, @b, @c (3)
**Reject**: @d (1)
**Abstain**: @e (1)
**Non-vote**: @f (1)

**Result**: Passed (3/4 = 75%, meets 2/3)

**Next Steps**: <resolution execution steps>
```

---

## 3. Objection Handling Process

When an objection arises during lazy consensus or voting:

```
Objection Raised
  │
  ├→ Objector must provide: 1) Reason for objection 2) Alternative proposal
  │
  ├→ Chair organizes discussion (within 48h)
  │     │
  │     ├→ Consensus reached → Revise proposal, re-initiate decision
  │     │
  │     ├→ Objector withdraws → Continue original process
  │     │
  │     └→ Cannot reach consensus → Escalate to vote
  │           │
  │           └→ Still fails → Escalate to next level (SIG → TSC)
  │                 │
  │                 └→ TSC still fails → Proposal shelved, may be re-submitted after 60-day cooling-off period
  │                       │
  │                       └→ Urgent matter → TSC Chair makes interim decision (requires ≥1 other TSC member co-signature),
  │                           retrospective vote within 72h; if still fails, decision is revoked
  │
  └→ Objection reasons and alternatives must be recorded in the decision document
```

---

## 4. Emergency Decisions

**Applicable scenarios**: Security incidents, CI fully blocked, release blocking situations requiring immediate action.

### Procedure

1. **TSC Chair + ≥1 other TSC member co-signature** required for an interim decision. If the Chair is absent, any 2 TSC members co-sign.
2. Within **24 hours** of execution, create a GitHub Issue recording:
   - What happened
   - What decision was made
   - Why normal process could not be followed
   - Co-signers
3. TSC retrospective vote for confirmation within **72 hours**
4. If retrospective vote fails → Roll back the emergency decision, remediate impact, review process gaps

---

## 5. Meeting Decisions

### Decisions in TSC Regular Meetings

1. Agenda clearly marks which items require decisions (`[Decision] Item Title`)
2. After discussion in the meeting, the Chair initiates a vote or confirms lazy consensus
3. Resolutions are recorded in meeting minutes with a `[Resolution]` prefix
4. TSC members who did not attend may raise objections within 72 hours after minutes are published
5. No objection → Resolution takes effect

### Decisions in SIG Regular Meetings

Follow the TSC process, but only affecting the SIG's own scope. Decisions involving cross-SIG matters must be escalated to TSC.

---

## 6. Decision Type Quick Reference

| Decision | Method | Voters | Pass Condition |
|----------|------|--------|----------|
| Merge regular PR | Lazy consensus | SIG Approvers | 72h no objection |
| Merge FEP (Provisional → Implementable) | Lazy consensus | SIG Approvers | 72h no objection |
| Create new SIG | Vote | TSC | 2/3 |
| Sunset / merge SIG | Vote | TSC | 2/3 |
| Version Go/No-Go | Vote | TSC | 2/3 |
| TSC member change | Vote | TSC (community election in mature phase) | 2/3 |
| Reviewer → Approver promotion | Vote | Relevant SIG Approvers | 2/3 |
| Approver → Tech Lead promotion | TSC approval | TSC | Lazy consensus |
| Tech Lead → Chair promotion | TSC approval | TSC | Lazy consensus |
| Emergency decision | Chair + ≥1 TSC member co-sign → retrospective | TSC | Retrospectively passed within 72h |
| GOVERNANCE.md amendment | Vote | TSC | 2/3 |
| CODE_OF_CONDUCT amendment | Vote | TSC | 2/3 |

---

## 7. Decision Record Standards

Every formal decision must include the following elements:

```markdown
### Decision Record: #NNN

- **Date**: YYYY-MM-DD
- **Decision Method**: Lazy consensus / Vote (x/x passed)
- **Decision**: <one-line description>
- **Decision Makers**: @github-id, @github-id
- **Objections**: (if any, record objection reasons and alternatives)
- **Follow-up Actions**: [ ] @someone: xxx
```

Decision records are stored in the same PR as the related document, or in meeting minutes.

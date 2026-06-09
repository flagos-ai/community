# FEP Review Guide

This document is for **SIG Approvers**. It explains when to approve a FEP, when to block it, and how to provide useful reviews.

---

## 1. Review Process Overview

```
FEP PR submitted
  │
  ├→ Within 72h: SIG Chair designates a lead Approver (at least 1)
  │
  ├→ Within 2 weeks: Lead Approver provides initial feedback (approve / request changes / block)
  │
  ├→ Involving other SIGs: Lead Approver @mentions the relevant SIG's Approvers to participate
  │
  ├→ All discussions resolved → all relevant Approvers approve → merged
  │
  └→ No Approver feedback within 2 weeks → SIG Chair escalates to TSC
```

> **Bootstrap phase note**: When the SIG Chair and Approvers have not yet been confirmed, the actions "SIG Chair designates" and "SIG Approver approval" in the above process are performed directly by the TSC. Before the TSC is established, the ZhongZhi FlagOS Community acts on its behalf. See [GOVERNANCE.md](../GOVERNANCE.md) for details.

---

## 2. Review Checklist

Approvers reviewing a FEP should check each item against the following checklist:

### A. Motivation & Scope

- [ ] **Is the problem real?** Is the pain point the proposal addresses sufficiently described? Is there data or user feedback to back it up?
- [ ] **Is the scope reasonable?** Do Non-Goals clearly define boundaries? Is there scope creep?
- [ ] **Is it appropriate for FlagOS?** Is this feature suitable as part of FlagOS, or better suited as an external tool/plugin?

### B. Design Proposal

- [ ] **Is the design simple?** Is the simplest workable solution used? Is there over-engineering?
- [ ] **Are there precedents?** Are there similar designs that can be referenced? If there are significant differences, what is the rationale?
- [ ] **Are the API/interfaces stable?** Does the user-facing API account for forward compatibility?
- [ ] **What is the impact on existing modules?** Are there any breaking changes? If so, what is the migration path?

### C. Cross-SIG Impact

- [ ] **Which SIGs are involved?** Which SIG owns the modules in the proposal? Are there cross-SIG dependencies?
- [ ] **Are relevant SIGs aware?** Have relevant SIG Approvers been @mentioned?
- [ ] **Are dependencies reasonable?** If the FEP depends on work from other SIGs, has communication already occurred?

### D. Implementation Feasibility

- [ ] **Is there an owner?** Does the FEP Owner have the ability or resources to drive implementation?
- [ ] **Is the timeline reasonable?** Is the target release realistic? Does it need to be split across multiple releases?
- [ ] **Is the test plan sufficient?** Does the Test Plan cover all Goals? Are multi-chip scenarios considered?

### E. Documentation & Compliance

- [ ] **Is the documentation plan clear?** Does the Packaging section specify build and distribution methods?
- [ ] **Is the license compatible?** If new dependencies are introduced, are the licenses compatible?

---

## 3. Review Opinion Types

| Opinion Type | Meaning | When to Use |
|--------------|---------|-------------|
| **Approve** | Unconditional approval | All checklist items pass |
| **Comment / LGTM** | Agree with minor suggestions | Non-blocking suggestions; can be merged without changes |
| **Request Changes** | Modifications required before re-review | Issues exist but are fixable |
| **Block / Objection** | Fundamental, irreparable objection | The design direction is wrong, scope is severely inappropriate, or core FlagOS principles are violated. **Must clearly state reasons and alternatives** |

---

## 4. Common Rejection Reasons

Below are the most common reasons a FEP is rejected or requires significant revision. Approvers should clearly call these out in their review when encountered:

| Issue | Description | Recommendation |
|-------|-------------|----------------|
| **Scope too large** | The FEP attempts to solve too many problems at once | Suggest splitting into multiple independent FEPs |
| **Over-engineered design** | Complex abstractions designed for simple requirements | Suggest starting with the simplest approach and evolving incrementally |
| **No user demand** | Designs a feature no one asked for | Suggest gathering user feedback before submitting |
| **Insufficient cross-SIG coordination** | Involves other SIGs but no communication has occurred | Suggest communicating with relevant SIG Chairs first |
| **Inadequate test plan** | Especially: multi-chip scenarios not covered | Supplement the test matrix |
| **Backward incompatible** | Breaking change with no migration path | Provide a migration guide or compatibility layer design |

---

## 5. Special Process for Cross-SIG FEPs

When a FEP involves ≥2 SIGs:

1. **Home SIG designation**: The FEP author selects one SIG as home; the file is placed under that SIG's directory
2. **Lead Approver**: The home SIG's Approver serves as lead and is responsible for coordination
3. **Relevant SIG approval**: The lead Approver @mentions the relevant SIGs' Approvers in the PR
4. **All Approvers pass**: Each relevant SIG needs at least 1 Approver's approve
5. **Unable to reach consensus**: Escalate to the TSC. If the TSC still cannot pass → the proposal is tabled, with a 60-day cooling-off period before resubmission; urgent matters → the TSC Chair makes a temporary decision (requires co-signature by ≥1 other TSC member), with a retroactive vote within 72h

### Cross-SIG Review Template

The lead Approver uses the following template in the PR to initiate a cross-SIG review:

```markdown
## Cross-SIG Review Request

**FEP**: [link]
**Home SIG**: sig-xxx
**Involved SIGs**: sig-yyy, sig-zzz

Requesting review from the following Approvers:

@sig-yyy-approver-1
@sig-zzz-approver-2

Please complete your review by YYYY-MM-DD. If you have objections, please state them in a PR comment.
```

---

## 6. Urgent FEP Channel

Emergency situations such as security patches, critical bug fixes, or CI blockers may use the fast-track channel:

1. The FEP Owner marks the PR title with `[URGENT]`
2. The SIG Chair assigns an Approver within 24h
3. The Approver delivers an approval decision within 48h
4. Missing documentation sections may be supplemented within 1 week after merging

---

## 7. Approver Code of Conduct

- **Response time**: Initial feedback must be provided within 2 weeks of receiving a review request. If no feedback is given beyond 2 weeks, the Chair may reassign
- **Constructiveness**: When rejecting, you must provide reasons and alternatives. A review that only says "no" provides no value
- **Respect the Owner**: The FEP Owner has invested significant time. Reviews should help improve the proposal, not discourage the contributor
- **Transparency**: All review opinions are expressed publicly in the PR. Do not communicate privately
- **Critique the process, not the person**: Distinguish between "this design has an issue" and "you did it wrong." The former is constructive; the latter is unacceptable

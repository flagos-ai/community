# Code Review Guide

This document defines the review standards and operating procedures for FlagOS community code PRs. For FEP review, see [FEP Review Guide](../fep/REVIEW_GUIDE.md).

---

## I. Review Roles

| Role | Review Authority | Description |
|------|-----------------|-------------|
| **Reviewer** | May give LGTM (non-binding) | See [Role Definitions](roles.md) |
| **Approver** | May approve PR (binding), merge code | See [Role Definitions](roles.md) |

---

## II. Review Checklist

### A. Correctness and Functionality

- [ ] Is the issue being fixed accurately resolved? Are the scenarios described in the Issue covered?
- [ ] Are there corresponding tests? (new features require tests; bug fixes should include regression tests)
- [ ] Is behavior correct for all supported chips? (at minimum, Tier 1 chips pass)
- [ ] Are edge cases handled? (empty input, extreme dimensions, error input)

### B. Performance and Efficiency

- [ ] Does it introduce unnecessary performance regression? (Benchmark-sensitive modules must provide performance comparison data)
- [ ] Is memory usage reasonable? (memory-sensitive in large-model scenarios)
- [ ] Is the kernel implementation efficient? (PRs involving GPU/NPU kernels)

### C. Code Quality

- [ ] Does code style match the project conventions? (follow each repo's pre-commit configuration)
- [ ] Are names clear and semantically accurate?
- [ ] Is there duplicated code that can be extracted?
- [ ] Are comments necessary and accurate? (write WHY comments, not WHAT comments)

### D. API and Compatibility

- [ ] Is this a breaking change? If so, is a migration path provided?
- [ ] Is the newly introduced public API stable? Is it marked experimental?
- [ ] Does it affect other modules' interfaces? (cross-module changes require confirmation from the relevant module's Approver)

### E. Multi-Chip

- [ ] Does it depend on chip-specific behavior? (if so, is there an equivalent implementation or skip logic on other chips?)
- [ ] Does CI pass on all Tier 1 chips?

### F. Documentation and DCO

- [ ] Is the DCO sign-off present? (automatically checked by the DCO bot)
- [ ] Is relevant documentation updated? (API changes must sync documentation)
- [ ] Is the related Issue linked in the PR description?

---

## III. Types of Review Feedback

| Feedback Type | Meaning | When to Use |
|---------------|---------|-------------|
| **Approve** | Unconditional approval, ready to merge | All checklist items pass |
| **Comment / LGTM** | Agreement with minor suggestions | Non-blocking suggestions; can merge without changes |
| **Request Changes** | Needs revision before re-review | Issues exist but are fixable |
| **Block / Objection** | Fundamental objection, not fixable | Wrong approach direction, introduces security vulnerabilities, severe performance issues. **Must clearly state rationale and alternatives** |

---

## IV. Review Process

```
PR Submitted
  │
  ├→ Automated Checks (DCO bot, lint, CI)
  │     │
  │     ├→ Automated checks fail → PR author fixes
  │     └→ Pass → Await human review
  │
  ├→ Within 72h: SIG Approver or Reviewer provides initial feedback
  │     │
  │     ├→ No response: PR author @mentions SIG Approver in a PR comment
  │     │   └→ Still no response after 72h → post in GitHub Discussions for help (see MAINTAINERS.md for bootstrap-phase contacts)
  │     │
  │     └→ Feedback received → Discussion and revision
  │
  ├→ All review comments resolved → Approver approves
  │
  └→ Merge (squash merge executed by Approver)
```

---

## V. Review Time Expectations

| Type | Initial Feedback | Subsequent Rounds |
|------|-----------------|-------------------|
| Regular PR | 72h | 48h |
| P0 Fix | 24h | 24h |
| Documentation PR | 1 week | 72h |

No Approver feedback for more than 2 weeks → PR author posts in GitHub Discussions, or contacts the SIG Chair.

---

## VI. Reviewer Code of Conduct

- **Respond promptly**: aim to provide initial feedback within 72h
- **Be constructive**: when rejecting, provide rationale and alternatives
- **Distinguish severity**: mark feedback as blocking (Request Changes) or non-blocking (Comment)
- **Respect contributors**: PR authors are contributors who have invested time; the goal of review is to improve quality, not to demonstrate the reviewer's technical prowess
- **Open and transparent**: all review feedback is discussed publicly in the PR
- **Do not block progress for perfection**: code can be improved but need not be perfect. Core standard: correct, maintainable, and will not cause rework later
- **Critique the code, not the person**: "This loop has O(n²) risk" is better than "Your code performs poorly"

---

## VII. Cross-Module PR Review

When a PR touches ≥2 modules:

1. The PR author lists all affected modules in the description
2. The primary reviewing Approver @mentions the relevant module Approvers in the PR
3. Each affected module requires approval from at least 1 Approver
4. Merge only after all Approvers have approved

---

## VIII. Related Documents

- [Role Definitions and Promotion Path](roles.md) — Reviewer / Approver role descriptions
- [FEP Review Guide](../fep/REVIEW_GUIDE.md) — FEP document review standards
- [Decision Playbook](decision-guide.md) — objection handling and escalation process
- [CONTRIBUTING.md](CONTRIBUTING.md) — PR submission process

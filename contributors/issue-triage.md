# Issue Triage Guide

This document defines the classification, prioritization, and response norms for FlagOS community GitHub Issues.

---

## I. Roles and Responsibilities

| Role | Responsibility |
|------|----------------|
| **SIG Triage Lead** | Each SIG designates 1 Triage Lead (may be fulfilled by the Chair or an Approver), responsible for initial classification and routing of Issues within that SIG's scope |
| **SIG Approver** | Confirms priority determination, closes invalid Issues, associates Issues with Milestones |
| **Contributor** | Submits using Issue templates, responds to triage questions, marks resolved Issues |

> **Bootstrap phase:** When a SIG Triage Lead has not been designated, TSC members rotate to handle triage. After the first TSC meeting, each SIG Chair designates the SIG's Triage Lead in the first monthly report.

---

## II. Issue Classification

### Type Labels (kind/*)

| Label | Meaning | Example |
|-------|---------|---------|
| `kind/bug` | Functional anomaly with reproduction steps | "FlagGems produces incorrect computation results on a certain chip" |
| `kind/feature` | New feature request | "Want to support a new attention variant" |
| `kind/cleanup` | Code cleanup, refactoring (no functional change) | "Remove deprecated API" |
| `kind/documentation` | Documentation issue | "Incorrect installation steps in README" |
| `kind/fep` | FEP-related tracking Issue | "FEP-0042 implementation tracking" |
| `kind/support` | Usage question, help request | "How to configure xx in vllm-plugin" |
| `kind/flake` | CI flaky test report | "test_attention.py occasionally times out" |

### Priority Labels (priority/*)

| Label | Meaning | Initial Response | Target Fix |
|-------|---------|-----------------|------------|
| `priority/P0` | Blocks release, security vulnerability, CI completely blocked | 24h | Current version / patch version |
| `priority/P1` | Core functionality unavailable, Tier 1 chip build/test failure | 1 week | Current or next version |
| `priority/P2` | Non-core functionality anomaly, Tier 2 chip issue | 2 weeks | Next version |
| `priority/P3` | Edge case, optimization suggestion, low-impact issue | 4 weeks | Backlog |

### Status Labels

| Label | Meaning |
|-------|---------|
| `triage/needs-information` | Submitter needs to provide more information |
| `triage/accepted` | Confirmed, awaiting assignment |
| `triage/duplicate` | Duplicate Issue; link to the original Issue |
| `triage/wont-fix` | Will not fix; reason must be stated |
| `help-wanted` | Suitable for external contributors to pick up |
| `good-first-issue` | Suitable for newcomers |

---

## III. Triage Process

```
New Issue Submitted
  │
  ├→ Within 24h: Triage Lead performs initial classification (kind/* + priority/*)
  │     │
  │     ├→ Insufficient information → add triage/needs-information, request more details
  │     │     └→ No response within 14 days → close (with closing note)
  │     │
  │     ├→ Duplicate → add triage/duplicate, link to original Issue, close
  │     │
  │     ├→ Won't fix → add triage/wont-fix, state reason, close
  │     │
  │     └→ Confirmed → add triage/accepted, route to corresponding SIG
  │           │
  │           ├→ SIG Approver confirms priority
  │           ├→ Associate with Milestone (if target version is determined)
  │           └→ Add help-wanted / good-first-issue (if suitable for external contributors)
  │
  └→ P0/P1: Triage Lead alerts in the SIG WeChat group or TSC working group
```

---

## IV. Response SLA

| Priority | Initial Classification | Status Update | Escalation |
|----------|----------------------|---------------|------------|
| P0 | 24h | Every 48h | Triage Lead escalates to SIG Chair + TSC |
| P1 | 1 week | Every 2 weeks | Triage Lead reminds SIG Approver |
| P2 | 2 weeks | Per Milestone | — |
| P3 | 4 weeks | Per Milestone | Inactive >6 months → auto-close |

---

## V. Closing Norms

When closing an Issue, you must:
- State the closing reason (fixed / duplicate / wont-fix / stale)
- If fixed, link the fixing PR
- If duplicate, link the original Issue
- If wont-fix, state the rationale

---

## VI. Issue Template Requirements

Each module repository should configure Issue templates (`.github/ISSUE_TEMPLATE/`), at a minimum including:
- Bug Report template (reproduction steps, environment info, logs)
- Feature Request template (use case, proposed approach)

> See [CONTRIBUTING.md](CONTRIBUTING.md) Bug Reports and Feature Requests sections for template details.

---

## VII. Related Documents

- [CONTRIBUTING.md](CONTRIBUTING.md) — Bug Report and Feature Request templates
- [Communication Channel Operations Guide](communication-guidelines.md) — GitHub Issues management
- [SIG Overview](../sigs/README.md) — each SIG's scope and OWNERS
- [Decision Playbook](decision-guide.md) — decision approach for closing/rejecting

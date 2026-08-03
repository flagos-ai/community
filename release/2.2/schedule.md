# FlagOS 2.2 Release Schedule

[English](schedule.md) | [中文](schedule_CN.md)

> Authoritative schedule for the FlagOS 2.2 release cycle. Date changes are made via PR to this file.
> Milestone: [FlagOS 2.2](https://github.com/flagos-ai/community/milestone/2) · Live FEP progress: [🚩 Release Tracker](../../fep/README.md#-release-tracker)

## Timeline

| Date | Event | What it means |
|------|-------|---------------|
| **2026-08-31** | **Feature Freeze** | FEPs targeting 2.2 must be merged, and their implementation code submitted in the module repositories. After this date: acceptance testing, bug fixes, tuning, and FEP doc updates only — no new FEPs into 2.2, no new feature code. |
| 2026-09-01 → 09-24 | **Testing & stabilization** | Testing runs against each FEP's Test Plan (multi-chip matrix). Only bug fixes land; no new features. |
| **2026-09-28** | **Release** | FlagOS 2.2 GA. FEPs with acceptance criteria met flip Status to `Implemented`. |

> **Recommended submission cutoff: 2026-08-17.** Approver initial feedback takes up to 2 weeks ([Review Guide](../../fep/REVIEW_GUIDE.md#8-approver-code-of-conduct)); FEP PRs opened later may not complete review before the freeze.

## Freeze rules

- **In or out**: a FEP is in 2.2 once its PR is merged with the `target/2.2` label ([FEP lifecycle](../../fep/README.md#fep-lifecycle)). The freeze closes both doors at once — FEP merge and feature code.
- **Missed the freeze?** The FEP retargets the next release: `Deferred`, tracking issue re-milestoned, `target/2.2` label swapped.
- **Exception**: security patches, critical bug fixes, and CI blockers may use the `[URGENT]` fast-track channel defined in the [FEP Review Guide](../../fep/REVIEW_GUIDE.md#7-urgent-fep-channel), subject to TSC approval.
- **Graduation**: `Implemented` requires an executable Test Plan (commands + environment + expected results, multi-chip scenarios covered) passed during the testing window. A merged FEP whose acceptance fails partially keeps Status `Implementable`, with a follow-up acceptance issue on the milestone.

## Roles

- **FEP Owners**: get your FEP merged and implementation code submitted before Feature Freeze; drive acceptance during the testing window.
- **Release Manager**: maintains the 2.2 test matrix in [tracking issue #47](https://github.com/flagos-ai/community/issues/47) — a row added per FEP as its tracking issue is created, final snapshot at Feature Freeze; tracks progress via the milestone view; runs Go/No-Go per the [release process](../README.md).
- **SIG Approvers / TSC**: complete FEP reviews in time for authors to meet the freeze (initial feedback within 2 weeks per the Review Guide).

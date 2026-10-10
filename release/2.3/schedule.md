# FlagOS 2.3 Release Schedule

[English](schedule.md) | [中文](schedule_CN.md)

> Authoritative schedule for the FlagOS 2.3 release cycle. Date changes are made via PR to this file.
> Milestone: [FlagOS 2.3](https://github.com/flagos-ai/community/milestone/3) · Live FEP progress: [🚩 Release Tracker](../../fep/README.md#-release-tracker)

## Timeline

| Date | Event | What it means |
|------|-------|---------------|
| **2026-11-13** | **FEP Merge Deadline** | Hard cutoff: FEPs targeting 2.3 must be **merged** by this date. FEPs not merged are `Deferred` to the next release — no retroactive admission. (Submit at least 2 weeks earlier; Approver initial feedback takes up to 2 weeks per the [Review Guide](../../fep/REVIEW_GUIDE.md#8-approver-code-of-conduct).) |
| **2026-11-27** | **Feature Freeze — rc0 cut** | Implementation code submitted in module repositories, **rc0 branch and rc0 tag created, and version identifiers consistent** (tag = manifest = package metadata). After this date: acceptance testing, bug fixes, tuning, and FEP doc updates only — no new 2.3 feature code. Feature work for later releases continues on `main`. |
| 2026-12-01 | **Integration smoke** | `vcs import` from the rc0 manifest + full-module build on the reference environment. Source/tag mismatches surface here, not at GA. |
| **2026-12-04** | **rc1 cut** | First full integration round (1 week). Each FEP tracking issue must carry an executable Test Plan (commands + environment + expected results) by rc1. |
| **2026-12-11** | **rc2 cut** | Second validation round (2 weeks). Bugfixes land on the active rc branch and merge back to `main`. |
| 2026-12-25 | **rc2 stabilization ends** | `Hotfix` only past this point. |
| **2026-12-29** | **Go/No-Go** | RM publishes the written Go/No-Go report (issue on the milestone) 48h before GA; TSC votes in the issue. Release-scope changes happen here, not on release day. |
| **2026-12-31** | **Release (GA)** 🚀 | FlagOS 2.3 GA. The GA manifest accepts `existing-tag` sources only — every entry's official tag must exist. FEPs with acceptance passed flip Status to `Implemented`; the rest keep `Implementable` with a follow-up acceptance issue. |

## Freeze rules

- **In or out**: a FEP is in 2.3 once its PR is merged with the `target/2.3` label by the **FEP Merge Deadline** ([FEP lifecycle](../../fep/README.md#fep-lifecycle)). The Feature Freeze then closes the 2.3 feature-code door.
- **Missed a gate?** The FEP retargets the next release: `Deferred`, tracking issue re-milestoned, `target/2.3` label swapped by the Release Manager.
- **Tag gate**: at Feature Freeze every participating module must have its rc0 tag, and version identifiers must agree across tag, manifest, and package metadata. The GA manifest allows `existing-tag` release sources only — the 2.2 primary-branch-cutoff fallback was a one-time exception.
- **Exception**: security patches, critical bug fixes, and CI blockers may use the `[URGENT]` fast-track channel defined in the [FEP Review Guide](../../fep/REVIEW_GUIDE.md#7-urgent-fep-channel), subject to TSC approval.
- **Graduation**: `Implemented` requires an executable Test Plan (commands + environment + expected results, multi-chip scenarios covered) passed during the testing window, checked off on the FEP's tracking issue. A merged FEP whose acceptance fails partially keeps Status `Implementable`, with a follow-up acceptance issue on the milestone. At GA the Release Manager records an acceptance verdict on every tracking issue and closes the milestone.

## Roles

- **FEP Owners**: get your FEP merged by the FEP Merge Deadline and implementation code submitted before Feature Freeze; attach the executable Test Plan to your tracking issue by rc1; drive acceptance during the testing window.
- **Release Manager**: maintains the 2.3 test matrix in the release tracking issue — a row added per FEP as its tracking issue is created, final snapshot at Feature Freeze; enforces the tag gate on manifest PRs; publishes the Go/No-Go report 48h before GA; records acceptance verdicts and closes the milestone at GA.
- **SIG Approvers / TSC**: complete FEP reviews in time for authors to meet the FEP Merge Deadline (initial feedback within 2 weeks per the Review Guide); vote Go/No-Go in the report issue.

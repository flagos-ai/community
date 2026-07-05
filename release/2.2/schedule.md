# FlagOS 2.2 Release Schedule

[English](schedule.md) | [中文](schedule_CN.md)

> Authoritative schedule for the FlagOS 2.2 release cycle. Date changes are made via PR to this file.
> Milestone: [FlagOS 2.2](https://github.com/flagos-ai/community/milestone/2) · Live FEP progress: [🚩 Release Tracker](../../fep/README.md#-release-tracker)

## Timeline

| Date | Event | What it means |
|------|-------|---------------|
| **2026-08-15** | **FEP Freeze** | FEPs targeting 2.2 must be approved (`Implementable`) and merged, with a complete Test Plan. After this date, no new FEPs are attached to the 2.2 milestone — late FEPs move to the next release. |
| **2026-08-31** | **Code Freeze** | All implementation PRs tracked by 2.2 FEPs must be merged in their module repositories. |
| 2026-09-01 → 09-26 | **Testing & stabilization** | Testing runs against each FEP's Test Plan (multi-chip matrix). Only bug fixes land; no new features. |
| **2026-09-28** | **Release** | FlagOS 2.2 GA. FEPs with acceptance criteria met flip Status to `Implemented`. |

## Freeze rules

- **Gate**: attachment to the [2.2 milestone](https://github.com/flagos-ai/community/milestone/2) is the tracking mechanism. The Release Manager stops attaching new FEPs after FEP Freeze.
- **Missed the freeze?** The FEP retargets the next release (`Deferred` if previously targeted 2.2), per the [FEP lifecycle](../../fep/README.md#fep-lifecycle).
- **Exception**: security patches, critical bug fixes, and CI blockers may use the `[URGENT]` fast-track channel defined in the [FEP Review Guide](../../fep/REVIEW_GUIDE.md#6-urgent-fep-channel), subject to TSC approval.
- **Test Plan requirement**: a FEP is not `Implementable` without an executable Test Plan (commands + environment + expected results, multi-chip scenarios covered) — this is what the testing window runs against.

## Roles

- **FEP Owners**: set `Target Version: FlagOS 2.2` in your FEP before FEP Freeze and drive implementation before Code Freeze.
- **Release Manager**: enforces milestone attachment cut-off, tracks progress via the milestone view, runs Go/No-Go per the [release process](../README.md).
- **SIG Approvers / TSC**: complete FEP reviews in time for authors to meet the freeze (initial feedback within 2 weeks per the Review Guide).

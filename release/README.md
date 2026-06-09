# FlagOS Release Management Process

[English](README.md) | [中文](README_CN.md)

This document defines the complete process and operational standards for FlagOS version releases.

> **Bootstrap note:** The following process assumes SIG Chairs and Approvers are already in place. When SIGs are not yet formally operational during bootstrap:
> - The SIG release liaison role is coordinated directly by the TSC
> - In Go/No-Go meetings, SIG Chairs that are in place report normally; SIGs without a Chair are reported by a TSC member on their behalf
> - Before TSC formation, the Release Manager is designated by the ZhongZhi FlagOS Community (众智FlagOS社区)
>
> See [GOVERNANCE.md](../GOVERNANCE.md) for bootstrap transition.

---

## 1. Version Naming

### Version Number Format

```
v<MAJOR>.<MINOR>.<PATCH>[-rc<N>][.post<N>]
```

| Component | Meaning | Example |
|----------|------|------|
| MAJOR | Major architecture change, no backward compatibility guaranteed | `v3.0.0` |
| MINOR | New features, backward compatible | `v2.1.0` |
| PATCH | Bug fixes, backward compatible | `v2.1.1` |
| -rcN | Release Candidate (pre-release) | `v2.1.0-rc2` |
| .postN | Validation iteration (incremental within an RC) | `v2.1.0-rc2.post3` |

### Branch and Tag Naming

| Type | Format | Example |
|------|------|------|
| **Branch** | Without `v` prefix, without `release/` prefix | `2.1.0-rc2` |
| **Tag** | With `v` prefix | `v2.1.0-rc2.post1` |

### Exception Modules

| Module | Default Branch | Notes |
|------|----------|------|
| FlagGems | `master` | Not `main` |
| FlagDNN | `master` | Not `main` |
| FlagBLAS | `master` | Not `main` |

---

## 2. Roles

| Role | Responsibilities | Appointment |
|------|------|----------|
| **Release Manager (RM)** | Overall release coordinator. Responsible for release calendar, FEP progress tracking, Go/No-Go meeting organization, Release Notes | 1 person designated by TSC per major version |
| **SIG Release Liaison** | 1 person designated per SIG, responsible for confirming that SIG's release readiness | Designated by SIG Chair |
| **CI Signal Lead** | Track multi-chip CI status, maintain CI summary dashboard, report blocking issues daily during RC | Designated by RM (recommended from sig-chip or contributors familiar with CI) |
| **Docs Lead** | Coordinate Release Notes draft, Getting Started updates, API Reference updates, documentation translation | Designated by RM (recommended from the docs virtual group) |
| **QA Lead** (optional) | Coordinate multi-chip manual testing and issue tracking | Designated by RM |

During FlagOS bootstrap, RM may be held by a TSC member concurrently; CI Signal / Docs Lead may be vacant.

---

## 3. Release Cycle

### RC Phase

```
Feature Freeze
  │
  ├→ RC1: First integration validation
  │     │
  │     ├→ Bug fixes
  │     ├→ Tag .post1, .post2, ...
  │     │
  │     └→ RC2: Second validation round (if needed)
  │
  └→ Official Release
```

### Timeline

| Phase | Duration | Description |
|------|------|------|
| Development | 8-12 weeks | Module development and FEP implementation |
| Feature Freeze | 1 day | Cutoff date; only bug fixes accepted thereafter |
| RC1 | Week 1 | First full integration, identify blocking issues |
| RC Fix Period | 2-4 weeks | Fix blocking issues, tag post.N for each fix round |
| Go/No-Go | Last week of RC | TSC decides whether to release |
| Official Release | 1 day | Tag official version, publish Release Notes, announcement |

### Release Calendar Template

```
FlagOS vX.Y Release Calendar

| Date | Milestone |
|------|--------|
| YYYY-MM-DD | Feature Freeze |
| YYYY-MM-DD | RC1 |
| YYYY-MM-DD | RC1.post1 (if applicable) |
| YYYY-MM-DD | Go/No-Go Meeting |
| YYYY-MM-DD | Official Release |
```

---

## 4. Feature Freeze

### Before Freeze

1. RM confirms status of all targeted FEPs in the Milestone
2. All targeted FEPs must reach `Implementable` status
3. Each SIG Release Liaison confirms that SIG's readiness

### Freeze Day

1. RM creates `release-vX.Y-freeze.yaml` under `release/`, freezing all module versions
2. Announce to all modules; only bug fixes accepted thereafter

### Changes Allowed After Freeze

- Bug fixes (determined by SIG Approver)
- Documentation updates
- CI/CD configuration fixes
- Chip compatibility fixes

**Not allowed**: New features, API changes, refactoring.

---

## 5. RC Validation

### Per Validation Iteration (.postN)

1. RM tags all modules with `.postN` using [manage-release.py](manage-release.py)
2. Update the `version` field in `release-2.1-rc2.yaml`
3. Run full multi-chip CI test suite
4. Record blocking issues in the RC tracking Issue

### RC Validation Checklist

> **CI Gate Definition:** Among the following checks, Tier 1 chip compilation + unit tests are **Required** (must pass, blocks merge), Tier 2 chips are **Recommended** (must run but non-blocking). See [CONTRIBUTING.md](../contributors/CONTRIBUTING.md) for detailed CI gate policy.

| Check | Owner | Pass Criteria | Type |
|--------|------|----------|------|
| All modules compile (all chips) | sig-chip (coordinated by TSC during bootstrap) + vendors | Tier 1 100% pass | Required |
| Unit tests pass (all chips) | Each SIG + vendors | Tier 1 100% pass, Tier 2 95%+ | Required (Tier 1) / Recommended (Tier 2) |
| Basic operator tests pass | sig-operator | All chips pass | Required |
| Framework adapter integration tests | sig-framework | At least 1 chip per framework passes | Required |
| End-to-end training / inference | sig-training | At least NVIDIA + 1 domestic chip passes | Required |
| No significant benchmark regression | sig-benchmark (planned, currently coordinated by TSC) | Performance regression <5% | Recommended |
| Lint / format checks | Each SIG | All modules pass | Required |
| DCO check | DCO bot | All PRs pass | Required |
| Documentation readiness | Docs virtual group | Getting Started and Release Notes draft complete | Required |

> **Transitional Arrangements for Planned SIGs:** sig-benchmark and the docs virtual group are coordinated by the TSC before formal SIG formation. Once sig-benchmark is activated, benchmark checks and performance regression detection are transferred to sig-benchmark. After the docs virtual group delivers Getting Started + API Reference, it may apply to upgrade to sig-documentation. See [SIG Overview](../sigs/README.md) for activation criteria of planned SIGs.

---

## 6. Go/No-Go Decision

### Meeting Flow

1. RM prepares Go/No-Go report (published 48h before meeting)
2. TSC holds Go/No-Go meeting (60 min)
3. Each SIG Chair verbally reports that SIG's readiness status
4. List all known blocking issues, discuss one by one
5. TSC votes: Go / No-Go / Go with caveats

### Go/No-Go Report Template

```markdown
# FlagOS vX.Y Go/No-Go Report

**Date**: YYYY-MM-DD
**Release Manager**: @github-id

## FEP Status

| FEP | Status | Notes |
|-----|------|------|
| FEP-NNNN | Implemented | Complete |
| FEP-NNNN | Deferred | Deferred to next version |

## Blocking Issues

| # | Description | Affected Module | Severity | Owner |
|----|------|----------|----------|--------|
| 1 | xxx | FlagGems | P0 - Blocks release | @xxx |

## SIG Readiness Status

| SIG | Chair Confirmed | Notes |
|-----|-----------|------|
| sig-operator | ✅ Ready | |
| sig-compiler | ✅ Ready | |
| ... | | |

## CI Summary

| Chip | Compile | Unit Tests | Integration Tests | Status |
|------|------|----------|----------|------|
| NVIDIA | ✅ | ✅ | ✅ | ✅ |
| Hygon | ✅ | ✅ | ⚠️ (1 flaky) | ✅ |
| ... | | | | |

## Recommendation

- [ ] Go — All conditions met
- [ ] No-Go — P0 blocking issues exist
- [ ] Go with caveats — Non-P0 known issues exist, note in Release Notes
```

### Decision Criteria

| Outcome | Condition |
|------|------|
| **Go** | No P0 blocking issues, all CI gates passing, all SIG Chairs confirm readiness |
| **No-Go** | P0 blocking issues exist, CI Tier 1 not passing |
| **Go with caveats** | Known non-blocking issues exist, noted in Release Notes |

---

## 7. Official Release

### Release Steps

1. Tag all modules' release branches with the official version tag (remove `.postN` suffix)
2. Update the `version` field in `release-*.yaml` to the official version
3. Merge Release Notes PR
4. Publish Release Announcement on GitHub Discussions
5. Update Milestone status to Closed
6. Publish on WeChat official account / community newsletter

### Release Notes Template

```markdown
# FlagOS vX.Y Release Notes

## Release Date

YYYY-MM-DD

## Highlights

- Support for XX chip
- New XX feature
- Performance improved by XX%

## New Features (FEP)

- FEP-NNNN: Feature description
- FEP-NNNN: Feature description

## Supported Chips

| Chip | SDK Version | Status |
|------|----------|------|
| NVIDIA | CUDA 13.0 | ✅ Tier 1 |
| Hygon | DTK 26.04 | ✅ Tier 2 |
| ... | | |

## Known Issues

- Issue description (scope of impact, expected fix version)
- ...

## Acknowledgments

Thanks to the following contributors (in alphabetical order):
@contributor1, @contributor2, ...

## Upgrade Guide

Notes for upgrading from vX.(Y-1) to vX.Y:
1. ...
2. ...
```

---

## 8. Post-Release

### Post-Release Checklist

- [ ] Official tags for all modules pushed successfully
- [ ] Release Notes published
- [ ] Announcements sent (GitHub Discussion + WeChat + Email)
- [ ] Milestone closed, incomplete FEPs migrated to next version
- [ ] RM publishes Post-mortem (if issues occurred during release)

### Post-mortem (optional, for significant issues)

```markdown
# FlagOS vX.Y Release Post-mortem

## Timeline

| Time | Event |
|------|------|
| YYYY-MM-DD | Blocking issue discovered |
| YYYY-MM-DD | Fix merged |
| YYYY-MM-DD | Re-validation passed |
| YYYY-MM-DD | Release completed |

## Root Cause

...

## Improvement Actions

- [ ] Improvement item 1
- [ ] Improvement item 2
```

---

## 9. Patch Versions & Backport

### When to Release a Patch Version

| Situation | Example | Patch Version |
|------|------|----------|
| Security vulnerability fix | CVE-level vulnerability | Must release |
| P0 bug (critical feature unavailable) | Tier 1 chip compilation failure, training accuracy error | Must release |
| CI fix | Release branch CI unable to run | Must release |
| P1 bug | Non-critical but high-impact issue | Recommended, RM decides |
| Documentation correction | Incorrect information fix | Do not release separately; bundled in next patch |

### Backport Process

```
Confirm need to backport
  │
  ├→ 1. Fix and merge on main branch
  │
  ├→ 2. Submit cherry-pick PR to release branch (e.g., 2.1.x)
  │     Title: [backport-2.1] fix: xxx
  │     Description: Link original PR + cherry-pick notes
  │
  ├→ 3. Approval: RM + ≥1 relevant SIG Approver approve
  │     (Simplified vs. original PR: only confirm cherry-pick correctness, no re-review of approach)
  │
  └→ 4. After merge, tag patch version (e.g., v2.1.1)
```

### Release Branch Maintenance Window

| Version | Maintenance Window | Notes |
|------|------|------|
| Latest MAJOR.MINOR | **9 months** after official release | Accepts backports (security fixes + P0/P1 bugs) |
| Previous MAJOR.MINOR | **6 months** after official release | Security fixes only |
| Earlier versions | No maintenance | — |

After the maintenance window ends, the release branch is marked EOL (end-of-life) and no longer accepts any PRs.

### Patch Version Go/No-Go (Simplified)

The Go/No-Go process for patch versions is simplified:

1. RM confirms all cherry-picks merged, CI passing
2. RM proposes release in the TSC work group or corresponding Issue
3. **72h lazy consensus**, no formal Go/No-Go meeting required
4. No TSC member objection → Release
5. Objection → RM negotiates with objector; escalate to TSC vote if necessary

### Patch Version Release Notes

For patch versions, append to the official version Release Notes:

```markdown
## v2.1.1 (YYYY-MM-DD)

### Fixes
- fix: Fix precision issue in FlagGems on certain chip (#1234)
- fix: Fix CI pipeline timeout (#1235)

### Acknowledgments
Thanks to the following contributors who submitted these fixes:
@contributor1, @contributor2
```

### Version Number Rules

- Patch versions only increment the PATCH position: `v2.1.0` → `v2.1.1` → `v2.1.2`
- The first patch after official release is `.1` (not `.0`)
- Do not use `.postN` — that is the RC phase iteration marker

---

## 10. Toolchain

| Tool | Purpose | Path |
|------|------|------|
| `manage-release.py` | Automated branch creation and tagging | [manage-release.py](manage-release.py) |
| `release-2.1-rc2.yaml` | Module manifest and version pinning example (vcstool format) | [release-2.1-rc2.yaml](release-2.1-rc2.yaml) |
| `chip-targets-2.1-rc2.toml` | Chip SDK version and Docker base image example | [chip-targets-2.1-rc2.toml](chip-targets-2.1-rc2.toml) |

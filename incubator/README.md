# FlagOS Incubator

[English](README.md) | [中文](README_CN.md)

This directory is the single entry point for **external project donations** to the FlagOS community. It defines the full lifecycle from donation proposal through incubation, graduation, and archiving. Design principle: **take IP in cleanly, let projects exit gracefully** — keep everything else simple.

## Project Lifecycle

```
Donation Proposal → Incubating → Graduated
                        └─────→ Archived
```

Only two levels: **Incubating** / **Graduated**. Archiving is the exit path from either stage.

## Project List

| Project | Status | Donor | Mentors | Proposal |
|---------|--------|-------|---------|----------|
| _None yet_ | | | | |

## 1. Decision Body

- Donation acceptance, graduation, and archiving are decided by **TSC vote** (simple majority). Before the first TSC meeting, the FlagOS founding community acts on its behalf during the bootstrap period (see [GOVERNANCE.md](../GOVERNANCE.md)).
- Routine matters follow lazy consensus: proposals posted on GitHub pass after 72 hours without objection.
- **Conflict of interest recusal**: TSC members affiliated with the donor organization recuse themselves from acceptance, graduation, and archiving votes for that project.
- All decisions are recorded publicly on GitHub, consistent with community governance principles.

## 2. Donation Process

```
① Proposal PR → ② 2-week public review → ③ TSC presentation & vote → ④ SGA + IP clearance → ⑤ Repo transfer, incubation begins
```

1. **Proposal PR**: The donor fills out [proposal-template.md](proposal-template.md) and submits it as a PR to `incubator/projects/<project-name>/proposal.md`. Questions before submitting can go to <contact@flagos.io>.
2. **2-week public review**: The PR stays open for at least 14 days to collect community feedback. Meanwhile the TSC identifies 1–2 Mentors for the project.
3. **TSC presentation & vote**: The donor presents at a TSC meeting (~30 minutes); the TSC votes (simple majority, conflicted members recuse). On approval, the proposal PR is merged.
   - **If rejected**: The TSC provides written reasons in the PR; the project may resubmit after 6 months.
4. **SGA + IP clearance**: Sign the [Software Grant Agreement](sga-outline.md) and complete every item on the [IP clearance checklist](ip-checklist.md). **No acceptance until the checklist is complete.**
5. **Incubation begins**: The repository is transferred into the `flagos-ai` org (preserving fork relationships and stars), the README is marked `(incubating)`, the project list on this page is updated, and an announcement is published.

## 3. Incubation

- Each project is assigned **1–2 Mentors** by the TSC, who coach governance adoption, answer process questions, and provide the recommendation at graduation time.
- **Annual review**: Once a year, the project answers a short set of questions via an issue in the community repo: releases shipped, new maintainers added, community challenges, support needed. The Mentor confirms and the review is archived.
- Project governance and code of conduct follow the community's existing [GOVERNANCE.md](../GOVERNANCE.md) and [CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md) — no separate rulebook.
- Day-to-day contributions use the **DCO** (`Signed-off-by`), checked automatically by a CI bot; no CLA signing required.

## 4. Graduation

Once an incubating project demonstrates **sustainable cross-organization maintenance** (maintainers not concentrated in a single organization, a steady release cadence, and real users), it graduates to a formal project by Mentor recommendation and TSC vote, dropping the `(incubating)` label.

> Quantitative criteria (number of organizations, releases, production users, etc.) will be defined by the TSC as the first project approaches graduation, and added to this section.

## 5. Archiving

- If a project shows **no substantive activity for 12 consecutive months** (no commits, no releases, unreachable maintainers), any community member may propose archiving. After a TSC vote, the project moves to archived status and its repository becomes read-only but remains available.
- **Commitment to donors**: The code license granted under the SGA is **irrevocable**; archiving does not affect anyone's right to fork and use the code. Project trademarks may be returned to the donor by negotiation.

## 6. License Policy

- **Default outbound license**: Apache-2.0.
- **Allowed dependency licenses**: Apache-2.0, MIT, BSD, MulanPSL-2.0.
- **Prohibited in the source tree**: GPL, AGPL, SSPL, Commons Clause, and any "non-commercial use only" terms.

License scanning in CI blocks non-compliant dependencies at the PR level. Special cases (e.g., weak-copyleft dependencies used only in tests) are decided by the TSC case by case.

## 7. Security Vulnerability Response

Please report security vulnerabilities in incubating and graduated projects **privately** to <security@flagos.io> — do not open public issues. We will acknowledge within 3 business days and coordinate a disclosure timeline with the reporter.

## Files in This Directory

| File | Purpose |
|------|---------|
| [proposal-template.md](proposal-template.md) | Donation proposal template |
| [ip-checklist.md](ip-checklist.md) | IP clearance checklist (hard gate for acceptance) |
| [sga-outline.md](sga-outline.md) | Software Grant Agreement term sheet (pending legal counsel) |
| `projects/` | Proposals and status records for each project |

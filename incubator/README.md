# FlagOS Incubator

[English](README.md) | [中文](README_CN.md)

## 1. Purpose & Scope

This directory is the single entry point for **external project donations** to the FlagOS community. It defines the full lifecycle from donation proposal through incubation, graduation, and archiving. Design principle: **take IP in cleanly, let projects exit gracefully** — keep everything else simple.

This process applies to externally donated projects; governance of existing FlagOS subprojects is not affected by this directory.

**Language.** English is the working language of this directory. Policy and runbook documents are authoritative in English — the `_CN` translations are provided for convenience, and if the versions differ, the English version prevails. Canonical project records (proposals, IP checklists, graduation proposals, annual reviews) are written in English. Legally executed documents such as the SGA define their own governing-language rule. Changes to any policy or runbook must update the English and `_CN` files in the same PR.

## 2. Quick Start for Donors

If you plan to donate a project to FlagOS:

1. **Confirm the fit**: Read the acceptance principles in Section 4 and confirm the project fits the FlagOS technical scope, has a maintainer team, and its code and assets can in principle pass IP clearance.
2. **Prepare and submit the proposal**: Copy the [donation proposal template](proposal-template.md) to `incubator/projects/<project-name>/proposal.md`, fill in the project, maintainer team, donation scope, IP status, and post-donation plan, then submit a PR to the community repo. The proposal and all subsequent project records are written in English.
3. **Public review and TSC presentation**: The proposal is publicly reviewed for at least 14 days; we will then contact you to arrange a ~30-minute TSC presentation. On approval the project is conditionally approved and enters the SGA and IP due-diligence stage.
4. **Complete the SGA and IP clearance**: With help from the Mentors, the TSC-designated verifier, and the legal receiving entity, complete the [IP clearance checklist](ip-checklist.md) and sign the SGA. Conditional approval is valid for 12 months.
5. **Formal acceptance and asset migration**: Once the SGA is effective and IP clearance is complete, the community records Final Acceptance in the proposal, and **the project enters incubation as of that date**; both sides then migrate repositories, release channels, domains, and other agreed assets per the [acceptance runbook](acceptance-runbook.md).

Status progression at a glance:

```
Draft → Public Review → Conditional Approved → SGA / IP Clearance → Final Accepted → Incubating
```

Questions before submitting: <contact@flagos.io>. **Do not submit contract scans, identity documents, account credentials, or other sensitive material in the public PR**; your Mentor or legal contact will provide a private submission channel for such material.

## 3. Project Lifecycle

```
Donation Proposal → Incubating → Graduated
                        └─────→ Archived
```

Only two levels: **Incubating** / **Graduated**. Archiving is the neutral exit path from either stage.

### Project List

| Project | Status | Donor | Mentors | Proposal |
|---------|--------|-------|---------|----------|
| _None yet_ | | | | |

## 4. Acceptance Principles

The TSC reviews donation proposals against the following principles, and the reasons for acceptance or rejection are recorded publicly. A candidate project must at minimum:

- Fit the FlagOS mission and technical scope (the multi-chip AI system software stack and its ecosystem);
- Use an open source license compliant with the license policy in Section 9;
- Have an IP status that is clearable in principle (known issues are not automatically disqualifying, but a feasible clearance path must exist);
- Have a committed initial maintainer team — not code parked after maintenance has stopped;
- Be willing to adopt open, neutral community governance, including this community's [GOVERNANCE.md](../GOVERNANCE.md) and [CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md);
- Be complementary to, or clearly differentiated from, existing FlagOS projects, without creating duplicated competition within the community.

## 5. Decision Body

- Donation acceptance, graduation, and archiving are **major decisions** of the community, decided by **TSC vote under the major-decision rules defined in [GOVERNANCE.md](../GOVERNANCE.md)**. Before the first TSC meeting, the FlagOS founding community acts on its behalf under the same rules.
- Routine matters follow the lazy consensus rules in GOVERNANCE.
- **Conflict of interest**: Directly interested parties in a donation matter (TSC members from the donor or its affiliated organizations) **must recuse** from the vote. This is a special rule for donation matters on top of the GOVERNANCE conflict-of-interest policy; see [GOVERNANCE.md](../GOVERNANCE.md#conflict-of-interest-coi).
- All decisions are recorded publicly on GitHub.

## 6. Donation & Formal Acceptance Process

```
① Proposal PR → ② 2-week public review → ③ TSC conditional approval → ④ SGA + IP clearance → ⑤ Formal acceptance, incubation begins
```

1. **Proposal PR**: The donor fills out [proposal-template.md](proposal-template.md) and submits it as a PR to `incubator/projects/<project-name>/proposal.md`. Questions before submitting can go to <contact@flagos.io>.
2. **2-week public review**: The PR stays open for at least 14 days to collect community feedback. Meanwhile the TSC identifies 1–2 Mentors for the project.
3. **TSC conditional approval**: The donor presents at a TSC meeting (~30 minutes); the TSC votes under the rules in Section 5. On approval, the proposal PR is merged.
   - **Conditional approval only authorizes proceeding to IP due diligence; it does not constitute formal acceptance.**
   - **Validity**: Conditional approval is valid for **12 months** from the vote, extendable by TSC resolution. If the SGA and IP clearance are not completed in time, the proposal is closed (closed/withdrawn) and the project **enters no lifecycle state**; it may be resubmitted later.
   - **If rejected**: The TSC provides written reasons in the PR; the project may resubmit after 6 months.
4. **SGA + IP clearance**: Sign the [Software Grant Agreement](sga-outline.md) and complete every item on the [IP clearance checklist](ip-checklist.md). **No acceptance until the checklist is complete.**
5. **Formal acceptance**: Once the SGA is effective and the IP clearance checklist is fully complete, the TSC (or its authorized delegate) records **Final Acceptance** in the proposal document (with date and verification basis); **formal acceptance takes effect as of that record**. Transferring the repository into the `flagos-ai` org (preserving forks and stars), marking the README `(incubating)`, updating the project list on this page, and publishing the announcement are execution steps that follow formal acceptance, carried out per the [acceptance runbook](acceptance-runbook.md).

## 7. Incubation, Annual Review & Graduation

### Incubation

- Each project is assigned **1–2 Mentors** by the TSC, who coach governance adoption, answer process questions, and provide the recommendation at graduation time. See the [Mentor guide](mentor-guide.md) for appointment, responsibilities, and rotation.
- **Annual review**: Once a year, the project submits an issue in the community repo following the [annual review template](annual-review-template.md): releases, community changes, adoption, compliance and security, challenges and support needed. The Mentor confirms and the review is archived.
- Project governance and code of conduct follow the community's existing [GOVERNANCE.md](../GOVERNANCE.md) and [CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md) — no separate rulebook.
- Day-to-day contributions require signing the **CLA** (Contributor License Agreement), consistent with current practice across FlagOS repositories; the CLA bot checks this automatically on PRs, and a one-time signature remains valid thereafter.

### Graduation

Graduation is assessed against the following **six fixed dimensions**, which projects can prepare for from day one of incubation:

1. **Governance**: community governance operates openly and independently (committer nominations, decision records visible on GitHub);
2. **Maintainer sustainability**: an active maintainer team with a working path for onboarding new maintainers;
3. **Releases & security**: a steady release cadence and basic security-response capability;
4. **Real adoption**: real users or production usage exists;
5. **Compliance**: IP and licensing remain continuously compliant, with no unresolved violating dependencies;
6. **Reduced single-party dependence**: dependence on the original donor is clearly reduced (maintainers not concentrated in a single organization).

Graduation is initiated by project maintainers or the Mentor using the [graduation proposal template](graduation-template.md) (evidence per dimension + written Mentor recommendation), takes effect after a TSC vote under the rules in Section 5, and drops the `(incubating)` label.

> Quantitative reference indicators for each dimension (number of organizations, releases, etc.) will be added by the TSC later; such additions only refine reference lines and do not change the dimensions themselves.

## 8. Exit & Archiving

Archiving is the neutral exit mechanism for a **formally accepted project** (Incubating or Graduated) that no longer meets the conditions of its stage; proposals that never reached formal acceptance are handled under the conditional-approval validity rules in Section 6 and are not archived. **Discovery**: incubating projects are checked via the annual review; graduated projects undergo a lightweight health check **every 2 years** (reusing the [annual review template](annual-review-template.md)), and any community member may also propose archiving at any time based on the conditions below. Upon any of the following, the TSC decides by vote under the rules in Section 5:

- No substantive activity for 12 consecutive months (no commits, no releases, unreachable maintainers);
- IP or compliance issues discovered after formal acceptance that remain unfixed long-term;
- Loss of the maintainer team with no successor; for incubating projects, no Mentor available long-term;
- Sustained violation of community governance or the code of conduct without remedy;
- Inability to sustain basic release and security-response capability;
- The project's maintainer team voluntarily requests to exit.

After archiving, the repository becomes **read-only and remains available**; execution details (notice period, channel disposition, trademarks, reactivation) are in the [archiving runbook](archiving-runbook.md). **Commitment to donors**: the code license granted under the SGA is **irrevocable**; archiving does not affect anyone's right to fork and use the code. Project trademarks may be returned to the donor by negotiation.

## 9. Licensing, Security & Supporting Files

### License Policy

- **Default outbound license**: Apache-2.0.
- **Allowed dependency licenses**: Apache-2.0, MIT, BSD, MulanPSL-2.0.
- **Prohibited in the source tree**: GPL, AGPL, SSPL, Commons Clause, and any "non-commercial use only" terms.

License scanning in CI blocks non-compliant dependencies at the PR level. See the [license policy details](license-policy.md) for the full classification (including case-by-case categories), CI scanning requirements, and licensing rules for model weights and datasets.

### Security Vulnerability Response

Please report security vulnerabilities in incubating and graduated projects **privately** to <security@flagos.io> — do not open public issues. We will acknowledge within 3 business days and coordinate a disclosure timeline with the reporter. See the [security response policy](security-policy.md) for the full process (timelines, disclosure coordination, project obligations).

### Files in This Directory

| File | Purpose |
|------|---------|
| [proposal-template.md](proposal-template.md) | Donation proposal template |
| [ip-checklist.md](ip-checklist.md) | IP clearance checklist (hard gate for acceptance) |
| [sga-outline.md](sga-outline.md) | Software Grant Agreement term sheet (pending legal counsel) |
| [license-policy.md](license-policy.md) | License policy details (classification, CI scanning, AI artifacts) |
| [security-policy.md](security-policy.md) | Security response policy (timelines, process, obligations) |
| [mentor-guide.md](mentor-guide.md) | Mentor guide (appointment, responsibilities, rotation) |
| [acceptance-runbook.md](acceptance-runbook.md) | Formal acceptance runbook (migration & announcement steps) |
| [annual-review-template.md](annual-review-template.md) | Annual review template |
| [graduation-template.md](graduation-template.md) | Graduation proposal template (six-dimension evidence + Mentor recommendation) |
| [archiving-runbook.md](archiving-runbook.md) | Archiving runbook (notice period, disposition, reactivation) |
| `projects/` | Proposals and process records for each project |

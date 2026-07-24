# Formal Acceptance Runbook

[English](acceptance-runbook.md) | [中文](acceptance-runbook_CN.md)

> The English version is authoritative. The Chinese translation is provided for convenience; if the versions differ, the English version prevails.

> Operational runbook for step ⑤ of the donation process in Section 6 of the [README](README.md): after Final Acceptance is recorded, the execution team completes asset migration and announcements per this document.

## 0. Preconditions

- [ ] The SGA is signed and effective, with a signing-confirmation record archived under `projects/<project-name>/` (the legal text itself stays in the alliance's records, not the public repository)
- [ ] The [IP clearance checklist](ip-checklist.md) is fully complete, with the verified copy archived as `projects/<project-name>/ip-checklist.md`
- [ ] The TSC (or its authorized delegate) has recorded **Final Acceptance** at the end of `projects/<project-name>/proposal.md` (date + verification basis + recorder)

## 1. Repository Transfer

1. The donor hands over repository owner rights or uses GitHub **Transfer ownership** to move the repository into the `flagos-ai` org (stars, forks, issue and PR history are preserved; GitHub auto-redirects the old URL).
2. Multi-repository projects migrate one by one; once all are done, append a migration-completion confirmation under the Final Acceptance record in proposal.md.
3. Post-transfer setup:
   - Branch protection (main: no force pushes, PR review required);
   - Repository Settings → Security: enable Private Vulnerability Reporting and Dependabot alerts;
   - Hook up the org-wide CLA bot and license-scanning CI;
   - Team permissions: create a GitHub team for the project maintainers with maintain permission; admin stays with org administrators.

## 2. Project Labeling

- Add an incubating badge at the top of the project README: `FlagOS Incubating Project`;
- Append `(incubating)` to the repository About description;
- Add `SECURITY.md` (pointing to the [security response policy](security-policy.md)); confirm `LICENSE`/`NOTICE` comply with the [license policy](license-policy.md);
- **Per-project security readiness** ([security response policy](security-policy.md) Section 6, completed **before announcement or opening contributions, whichever comes first**): enable GitHub Private Vulnerability Reporting and register the project security contact in the `projects/<project-name>/` records.

## 3. Release Channels & Accounts

Execute the actual handover item by item, following the asset inventory and migration plan confirmed in the "Asset Verification & Migration Readiness" section of the IP clearance checklist:

- PyPI / npm / Docker Hub etc.: add the alliance machine account as owner; downgrade the donor's personal accounts to maintainer or remove them;
- Domains: complete the transfer or hand over DNS control;
- Social media / community channels: complete the handover or update ownership in the channel profile.

## 4. Community Onboarding

- Update the project list in the incubator [README](README.md) / [README_CN.md](README_CN.md) (status Incubating, donor, Mentors, proposal link);
- Assign the project to the appropriate SIG (where none fits, the TSC manages it directly per the GOVERNANCE transition rules);
- Register the maintainer roster in MAINTAINERS.md or the project OWNERS file;
- Invite the project maintainers to the open agenda of TSC meetings.

## 5. Announcement

- Publish the acceptance announcement in the community repo's GitHub Discussions (project intro, donor, incubating-status note);
- Syndicate to official channels such as the WeChat official account;
- Wording: refer to the project as a "FlagOS incubating project"; avoid phrasing that could be read as final endorsement.

## 6. Completion

Once everything is executed, the execution owner appends an execution-completion record to `projects/<project-name>/proposal.md` (date + executor + links per item). The incubation period runs from the date of the Final Acceptance record.

# Security Response Policy

[English](security-policy.md) | [中文](security-policy_CN.md)

> The English version is authoritative. The Chinese translation is provided for convenience; if the versions differ, the English version prevails.

> This document details the security-response policy in Section 9 of the [README](README.md), applying to all incubating and graduated projects.

## 1. Reporting Channel

- **Private reporting mailbox**: <security@flagos.io> (do not open public issues or discuss unfixed vulnerabilities in public channels)
- GitHub private channel: once a project repository enables **GitHub Private Vulnerability Reporting** (Settings → Security), reports can be submitted privately via the repository's Security page.
- Reports should include where possible: affected versions, reproduction steps or PoC, impact assessment, and suggested remediation direction (if any).

## 2. Response Timeline

| Stage | Target |
|-------|--------|
| Acknowledge receipt | Within 3 business days |
| Initial assessment (validity, severity) | Within 10 business days |
| Fix target | Critical: within 30 days; High: within 60 days; Medium/Low: within 90 days or the next regular release |
| Coordinated disclosure | Advisory published after the fix ships; timeline negotiated with the reporter, defaulting to no more than 90 days |

Timelines are targets, not hard commitments; where genuinely difficult, the security-response owners negotiate an extension with the reporter.

## 3. Handling Process

1. **Intake & triage**: The security@ mailbox is staffed by TSC-designated security-response owners (at least 2); reports are moved into the affected project's private remediation channel (a GitHub Security Advisory draft).
2. **Assessment**: Project maintainers and the reporter confirm validity and severity (CVSS as reference).
3. **Fix**: Patches are developed on a private branch; remediation discussions stay out of public issues/PRs.
4. **Release**: The patch ships in a new release together with a GitHub Security Advisory; a CVE ID is requested where warranted (GitHub can assign one).
5. **Credit**: The reporter is credited in the advisory with their consent.

## 4. Project Obligations

Every incubating and graduated project must:

- Place a `SECURITY.md` at the repository root pointing to this policy and the security@ mailbox;
- Enable GitHub Private Vulnerability Reporting;
- Designate at least 1 maintainer as the security contact (recorded in the `projects/<project-name>/` records);
- Report the year's security-incident handling in the annual review (state "none" if none).

## 5. Embargo

Before a fix is released, vulnerability details are limited to: the reporter, the project's security contact and maintainers working on the fix, and the security-response owners. Where important downstream users must be notified early (e.g., active exploitation), the TSC decides the notification scope.

## 6. Readiness Gate

Two layers:

**Institutional (must be in place before the first project's Final Acceptance)**:

- [ ] The <security@flagos.io> mailbox is operational;
- [ ] The TSC has designated and published at least **2** security-response owners.

**Per-project (completed after each repository migration, before announcement or opening contributions — a completion gate in the [acceptance runbook](acceptance-runbook.md), not a precondition of Final Acceptance)**:

- [ ] GitHub Private Vulnerability Reporting enabled on the repository;
- [ ] `SECURITY.md` added (pointing to this policy);
- [ ] Project security contact registered (in the `projects/<project-name>/` records).

The response timelines in this policy take effect once the institutional items are in place; per-project items are completed per repository after migration.

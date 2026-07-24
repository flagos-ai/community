# Archiving Runbook

[English](archiving-runbook.md) | [中文](archiving-runbook_CN.md)

> Runbook for executing an archiving decision under Section 8 of the [README](README.md). Archiving is a neutral exit; keep all wording non-punitive.

## 1. Notice Period

- Before an archiving proposal goes to a TSC vote, it is publicized in the project repository and the community repository for **≥30 days**, with best-effort direct contact to the project maintainers and the donor contact;
- During the notice period the project may present an improvement plan; the TSC decides whether to halt the archiving process;
- After the vote passes, downstream users get a **≥30-day** migration notice before the repository goes read-only.

## 2. Repository Disposition

- The repository is set to **archived (read-only)**, preserving all code, issue, and PR history — nothing is deleted;
- The incubating/graduated badge at the top of the README is replaced with an archive notice: the project is archived, the archive date, and that the code license remains valid (under the project's actual outbound license — anyone may fork and continue);
- CI spend beyond branch protection is removed (scheduled jobs, release pipelines).

## 3. Release Channels & Domains

- PyPI / npm / Docker Hub etc.: **published versions are kept** (deletion breaks downstream); the package description gets an archive note, and new releases stop;
- Domains: the website is replaced with an archive notice page or redirected to the GitHub repository; whether to renew after expiry is decided by the TSC;
- Social media channels: post the archive announcement, then stop updating.

## 4. Post-Archive Security Reports

- Vulnerability reports for archived projects are still received via <security@flagos.io>, but **no fix timeline is promised**;
- For severe, widely impactful vulnerabilities, the security-response owners may, after assessment, publish an informational advisory (risk and mitigations for users) without committing to a patch.

## 5. Trademark Disposition

- Negotiated with the donor per the SGA trademark terms: return to the donor, retain under the alliance, or let registration lapse;
- The outcome is recorded in the process records of `projects/<project-name>/proposal.md`.

## 6. Announcement

- Publish the archive announcement in the community repo Discussions: the reason (neutral wording), the date, a note that the code remains usable, and thanks to contributors;
- Update the incubator README project list, setting the status to Archived.

## 7. Reactivation

Archived projects may be reactivated: a new maintainer team submits a **simplified proposal** to the TSC (team and plan). On approval, the repository is un-archived and the project returns to Incubating status (formerly graduated projects also return to Incubating and are re-assessed against the graduation dimensions). Reactivation **does not repeat full IP clearance but requires incremental verification**: the code license is unchanged, trademark/domain status is usable, dependency compliance scans pass, and no security risks remain unhandled.

## 8. Completion Record

The execution owner appends an archiving-execution record (date, executor, links per item) to the process records of `projects/<project-name>/proposal.md`.

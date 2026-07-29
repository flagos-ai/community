# Contribution Proposal: <Project Name>

<!--
HOW TO USE THIS TEMPLATE

1. Copy this file to incubator/projects/<project-name>/proposal.md and submit as a PR
   (process: /incubator/README.md Section 6; questions: contact@flagos.io).
2. Every field has a short hint in <angle brackets> and most have an example in the
   HTML comment above it. Replace hints with your content; comments may be kept
   (they do not render) or deleted.
3. Write "N/A" where a field does not apply; do not delete sections.
4. Fill in all fields truthfully — especially "IP Status Disclosure". Issues disclosed
   early can be worked out; issues concealed will block acceptance at IP clearance.
5. Do NOT put contract scans, identity documents, or account credentials in this
   public file; your Mentor or legal contact will provide a private channel.
-->

## Basic Information

<!-- Example:
- Project name: FooKit
- Website: https://fookit.io
- Current license: MIT
- Contributing party & signing entity: Foo Technology Co., Ltd. (北京富科技术有限公司)
- Contact: Zhang San <zhangsan@footech.com>
-->

- **Project name**:
- **Website (if any)**:
- **Current license**: <the license the project ships under today, e.g. MIT / Apache-2.0>
- **Contributing party & signing entity**: <full registered legal name of the organization, or the individual's name — this is who will sign the SGA>
- **Contact**: <name + email>

**Contribution scope (repository list)**:

<!-- List EVERY repository transferred in this contribution; multi-repo projects list all.
     Repositories not listed are out of scope of the SGA. Example:
     | https://github.com/footech/fookit      | Core library    |
     | https://github.com/footech/fookit-docs | Documentation   |
-->

| Repository | Description |
|------------|-------------|
| | |

## Project Description

<!-- Start with a single sentence — it will be reused verbatim in the acceptance
     announcement and the incubator project list. Then one paragraph: what the project
     does, what problem it solves, who the target users are. Example opening:
     "FooKit is a kernel autotuning toolkit for heterogeneous AI accelerators." -->

**Relationship to existing FlagOS projects**:
<!-- Complementary or overlapping with FlagGems / FlagTree / FlagScale / FlagCX / FlagPerf?
     If overlapping, how is it positioned? (Acceptance principle #6) Example:
     "Complements FlagGems: FooKit tunes the kernels FlagGems provides; no overlap with
     the other subprojects." -->

**Fit with the FlagOS mission**:
<!-- How does the project serve the multi-chip AI system software stack and its
     ecosystem? (Acceptance principle #1) -->

## Community Status

- **Core developers & affiliations**: <fill in the table below, or link an equivalent MAINTAINERS file pinned to a commit SHA (a mutable branch link does not preserve the roster the TSC evaluated); the live roster may be linked separately>

<!-- GitHub ID and organization are what the review relies on: the ID to verify
     contribution activity, the organization to assess concentration. A display name
     is optional — legal identity, where clearance requires it, is verified through the
     private channel, not this public file. Example row:
     | Zhang San | @zhangsan | Foo Technology | Maintainer, Release Manager |
     | | @lisi-dev | Independent | Committer | -->

| Name (optional) | GitHub ID | Organization / Independent | Role |
|-----------------|-----------|---------------------------|------|
| | | | |

- **Developer independence**: <organizational contributing party only — how many core developers are salaried by it vs. independent, and what is its commitment if business priorities shift? N/A for an individual contributing party>
- **Users & adoption**: <known users or production deployments; note which can be cited publicly, e.g. "3 companies in production, 2 citable">
- **Release history**: <number of releases and the most recent, e.g. "12 releases since 2023-05, latest v2.3.1 on 2026-06-10">

## IP Status Disclosure

<!-- Verified item by item against /incubator/ip-checklist.md after conditional
     approval. Disclose known issues here. Issues found later during clearance are
     documented and resolved then (compatible relicensing, retroactive authorization,
     rewrite, or removal); material omissions or issues left unresolved may block
     acceptance. -->

- **Code ownership**: <Is ownership clear? Any outsourced code, prior-employer code, or copied code of unclear origin? e.g. "All code written by employees; one module (src/vendor/) adapted from BSD-licensed upstream, headers retained">
- **Software copyright registration**: <registered or not; under whose name, e.g. "Registered in 2024 under Foo Technology Co., Ltd.">
- **Trademarks & domains**: <name/logo registered? by whom? willing to transfer or exclusively license? e.g. "'FooKit' word mark registered by Foo Technology; willing to transfer">
- **Release channels & account assets**: <current state of PyPI / npm / Docker Hub / social accounts; handover happens after acceptance per the [acceptance runbook](/incubator/acceptance-runbook.md)>
- **Known risks**: <GPL-family dependencies, cryptographic functionality (export compliance), patent issues, ongoing disputes; write "none" if none>

**AI artifacts (if applicable)**:

<!-- A repository license covers code, not necessarily third-party data or weights
     inside it — state the license of the artifact itself, verified at its source. -->

- **Model weights**: <contributed along with code? license of the weights themselves, and the base model's terms if fine-tuned? e.g. "Yes, weights under Apache-2.0, trained from scratch" or "N/A">
- **Datasets**: <provenance and license of the dataset content itself; redistributable? e.g. "Eval set created by Foo Technology, contributed under CC BY 4.0, redistribution rights confirmed" or "N/A">

## Post-Contribution Plan

- **Initial maintainers**: <who will maintain after acceptance — names or "same as core developers table">
- **6–12 month roadmap**: <a few sentences, e.g. "H2 2026: v3.0 with X; H1 2027: support for Y">
- **Support requested**: <what you need from the community — CI resources, promotion, mentoring focus, etc.>

## Commitments

Check to confirm:

- [ ] Agree to open, neutral community governance under the FlagOS [GOVERNANCE](/GOVERNANCE.md) and [CODE_OF_CONDUCT](/CODE_OF_CONDUCT.md)
- [ ] Agree to relicense outbound under Apache-2.0 (or an exception justified above for TSC approval) and to follow the [license policy](/incubator/license-policy.md)
- [ ] Agree that subsequent contributions follow the current FlagOS CLA mechanism
- [ ] Aware of the 12-month conditional-approval validity, the archiving mechanism, and the irrevocable-license terms (README Sections 6 & 8)
- [ ] Confirm this proposal is truthful with no material omissions

## Proposed Mentors

<!-- Optional; leave empty and the TSC will assign. Mentors must not be from the
     contributing party or its affiliates. -->

-

---

<!-- ==================== Sections below are completed by the community. ====================
     ==================== Contributing parties: please do not edit. ========================= -->

## Process Records

### Conditional Approval

- **TSC vote result & link**:
- **Date**:
- **Assigned Mentors**:
- **Valid until**: <approval date + 12 months>

### Final Acceptance

<!-- Completed by the TSC or its authorized delegate once the SGA is effective and the
     IP clearance checklist is fully complete; formal acceptance takes effect as of this record. -->

- **Date**:
- **Verification basis**: <SGA confirmation + link to archived ip-checklist.md>
- **Recorded by**:

### Execution Completed

- **Date**:
- **Executed by**:
- **Completion**: <links per [acceptance runbook](/incubator/acceptance-runbook.md) sections>

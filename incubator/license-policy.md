# License Policy

[English](license-policy.md) | [中文](license-policy_CN.md)

> The English version is authoritative. The Chinese translation is provided for convenience; if the versions differ, the English version prevails.

> This document details the license policy in Section 9 of the [README](README.md), applying to all incubating and graduated projects.

## 1. Outbound License

All projects release under **Apache-2.0**. Donated projects under other licenses must switch during IP clearance. **The SGA covers only what the donor itself has the right to license**; whether the project can switch its outbound license as a whole is determined by the "Contribution Rights Chain" verification in the [IP clearance checklist](ip-checklist.md) — copyright retained by historical external contributors must be resolved item by item via original-license compatibility, retroactive authorization, or rewrite/removal. Exceptions (e.g., MulanPSL-2.0) must be justified in the proposal and approved by the TSC.

## 2. Dependency License Categories

### Allowed (may be introduced directly)

| License | Notes |
|---------|-------|
| Apache-2.0 | Includes a patent grant |
| MIT / ISC | |
| BSD-2-Clause / BSD-3-Clause | |
| MulanPSL-2.0 | Both the Chinese and English texts are legally effective |
| Zlib / Python-2.0 | |
| CC0-1.0 / Unlicense | Public-domain class |

### Case-by-Case (requires TSC approval, recorded)

| License | Typical permitted scenario |
|---------|---------------------------|
| MPL-2.0 / EPL-2.0 | Used as standalone files/binaries without modifying the source files |
| LGPL-2.1 / LGPL-3.0 | Dynamic linking only, as a replaceable system-level dependency |
| CDDL | Treated the same as MPL |
| Weak-copyleft licenses used only in test/build toolchains | Not part of distributed artifacts |

How to apply: open an issue in the affected repository stating the dependency name, license, usage mode (source inclusion / dynamic linking / build-time only), whether it enters distributed artifacts, and available alternatives. The TSC handles it by lazy consensus and records the conclusion in the issue.

### Prohibited (must not enter the source tree or distributed artifacts)

- GPL-2.0 / GPL-3.0 / AGPL-3.0
- SSPL, BUSL, Elastic License 2.0
- Commons Clause and any text with added "non-commercial only" or "no competition" terms
- JSON License ("shall be used for Good, not Evil") and other non-free terms with usage restrictions
- Third-party code with no license

## 3. CI Scanning Requirements

- Every project repository must run license scanning in CI (ScanCode Toolkit or OSS Review Toolkit recommended), incrementally checking new dependencies introduced by PRs and blocking merges on prohibited licenses.
- Scan configuration follows the categories in this document; case-by-case approved dependencies go into a project-level allowlist annotated with the approval issue link.
- A full scan runs at least once before every release, with the report archived alongside the release records.

## 4. Licensing of AI Artifacts

For projects donating or distributing model weights or datasets:

- **Model weights**: Whether weights are donated with the code must be stated in the proposal. Weight licenses are independent of code licenses; Apache-2.0 or a clearly defined open-weights license is recommended. Licenses with usage restrictions (e.g., research-only) must be declared prominently in the README and must not be conflated with "open source" claims.
- **Datasets**: Provenance must be lawful and licenses must permit redistribution; datasets that cannot be redistributed may only be provided as a download script plus source citation, and must not enter the repository.
- **Fine-tuned derivatives of third-party models**: Must comply with the base model's license terms (derivative naming, use-policy pass-through, etc.), verified item by item in the IP clearance checklist.

## 5. File & Notice Requirements

- Repository root: `LICENSE` (full Apache-2.0 text) + `NOTICE` (copyright statements and third-party attributions).
- **Project-owned source files** carry a uniform SPDX header: `SPDX-License-Identifier: Apache-2.0`; third-party files **keep their original license and copyright headers unmodified**.
- Introduced third-party code retains its original copyright notices and is registered in `NOTICE` or a `third_party/` directory.

# FEP-NNNN: Title

<!--
Copy this template into the target sig-* directory, naming it NNNN-title.md.
NNNN = PR number, title = short hyphenated description.

**All content must be written in English.**

Status is marked at the top of the document:
  **Status:** `Provisional` | `Implementable` | `Implemented` | `Deferred` | `Rejected`

Merge early and iterate — fill the required sections before the first PR; others can follow later.
-->

**Status:** `Provisional`

**Created:** YYYY-MM-DD

**Owner:** @github-username

**SIG:** sig-xxx

**Target Version:** FlagOS X.Y

---

## Summary

**(Required)** A short paragraph explaining what this feature does, its scope, and a link to the relevant GitHub repository.

<!-- One paragraph describing what this feature does and linking to the repo. -->

## Motivation

Why we need this feature and the problem it solves.

<!-- Why should we do this? What problem does it solve? -->

### Goals

**(Required)** What this feature aims to achieve.

<!-- Concrete goals. -->

-

### Non-Goals

What is explicitly out of scope.

<!-- Explicitly out of scope, to set boundaries. -->

-

## Proposal

The high-level approach: how the feature works from a user perspective.

<!-- What is the user-visible change? How will it be used? -->

## Design Details

Implementation-level details such as API changes, data flow, or architecture diagrams. Optional for simple features.

<!-- (Optional) Implementation details, API changes, architecture diagrams. -->

## Packaging

**(Required)** How to build and package the feature. This section is about **building/packaging only** — do NOT describe how to install or run the feature here (that belongs in the Test Plan).

**Supported vendors:** e.g. Metax, Nvidia, Hygon

**Can this feature be packaged as a wheel (`.whl`)?**
- If **yes**: provide detailed instructions for building the wheel, **or** provide the pre-built `.whl` file directly (with a download link).
- If **no**: state why, and note that it will be built from source instead.

<!--
If yes:
- Packaging format: pip wheel (.whl) / deb / rpm / Docker ...
- Build command (to produce the wheel), e.g.:
    python -m build            # produces dist/*.whl
    # or
    pip wheel . -w dist/
- Pre-built artifact: [link to the .whl file], or
- [Link to packaging script or CI workflow]

Platform requirements: supported vendors, CUDA/toolkit version, Python version, PyTorch version, etc.
-->

## Test Plan

**(Required)** How to verify the feature works correctly. Verify against each Goal listed above. Include functional, performance, and compatibility checks where relevant.

This section focuses on **verifying the new feature** — do NOT describe installation or environment setup here (packaging is covered in the Packaging section).

The test plan MUST explicitly describe, for each new feature in this release:
- **Test commands** — the exact command(s) that exercise the new feature added in this release. Clearly mark which feature each command targets.
- **Expected results** — the expected output/behavior for each test command.

<!--
For each new feature in this release:

Feature: e.g. <name of the new feature>
- Test command: e.g. <exact command>
- Expected result: e.g. <expected output / behavior>
-->

## Related PRs

All implementation PRs tracked as a checklist.

<!-- Track implementation PRs here as a checklist. -->

<!--
- [ ] flagos-ai/FlagGems#xxx — description
- [ ] flagos-ai/FlagTree#xxx — description
-->

## Implementation History

Key milestones and dates recorded after merge.

<!-- Record key milestones and dates after merge. -->

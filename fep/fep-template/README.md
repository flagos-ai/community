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

**(Required)** How to build and package the feature. Include build commands, packaging format, and platform requirements.

<!-- How to build and package this feature? Provide build commands or script. -->

<!--
- Build command: pip install . / make / cmake ...
- Packaging format: pip wheel / deb / rpm / Docker ...
- Platform requirements: CUDA version, Python version, etc.
- [Link to packaging script or CI workflow]
-->

## Test Plan

**(Required)** How to verify the feature works correctly. Verify against each Goal listed above. Include functional, performance, and compatibility checks where relevant.

<!-- How will this feature be verified? -->
The test plan MUST explicitly describe:
- **Image acquisition** (base image and source)
- **Package installation** (commands)
- **Component setup/running** (startup commands)
- **Test commands** (exact commands for each verification scenario)
- **Expected results** (per test command)

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

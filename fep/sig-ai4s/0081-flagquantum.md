# FEP-0081: FlagQuantum Development Direction

**Status:** `Provisional`

**Created:** 2026-07-29

**Owner:** @FlagQuantum

**SIG:** sig-ai4s

**Target Version:** FlagOS 2.2

---

## Summary

This FEP proposes the next-stage development direction for FlagQuantum.

FlagQuantum will continue improving its overall product experience and
ecosystem compatibility.

## Release Boundary and Evidence

- **FlagOS 2.1 baseline:** FlagQuantum `v0.1.0`.
- **FlagOS 2.2 release candidate reviewed:** the FlagOS 2.2 RC2 manifest still
  pins FlagQuantum to `v0.1.0`; no new 2.2 release artifact is identified.
- **Development window:** 2026-06-01 through 2026-08-31.

Public repository evidence in the 2.2 window is limited to documentation of
multi-chip backend support (flagos-ai/FlagQuantum#12) and Apache 2.0 source
headers (flagos-ai/FlagQuantum#14). Later vNext implementation activity first
appears after the 2026-08-31 feature freeze and is not treated as FlagOS 2.2
delivery evidence.

Because this FEP intentionally withholds technical design pending
intellectual-property review, it cannot yet define an implementable interface,
package delta or acceptance test. `Provisional` records the direction without
claiming that undisclosed capabilities are included in the FlagOS 2.2
artifact.

## Motivation

FlagQuantum requires a clear and consistent direction for future development,
collaboration, and delivery.

## Principles

- Maintain a coherent product identity.
- Improve usability and compatibility.
- Introduce capabilities progressively.
- Define support boundaries clearly.
- Validate maturity before making public claims.

## Scope

This FEP records product direction only. It does not define or disclose any
specific architecture, method, implementation, performance technique, or
platform capability.

All technical designs and supporting materials are maintained separately and
are subject to intellectual-property review before disclosure.

## Packaging

No packaging change beyond the existing `v0.1.0` artifact is claimed for
FlagOS 2.2 by this FEP.

## Test Plan

No new public 2.2 capability is specified for acceptance. Any future status
change requires a reviewable public scope, release artifact and test boundary,
or an explicitly approved confidential acceptance process documented by the
release owner.

## Related PRs

- [x] flagos-ai/FlagQuantum#12 — document multi-chip backend support
- [x] flagos-ai/FlagQuantum#14 — add Apache 2.0 source headers

## Implementation History

- 2026-07-29: FEP created as a product-direction proposal.
- 2026-09-17: Reconciled the FEP with the FlagOS 2.1 and 2.2 manifests. Status
  changed to `Provisional` because both manifests pin `v0.1.0` and the public
  evidence does not define a new testable 2.2 capability.

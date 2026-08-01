# FEP-0099: Operator Library for FlagOS 2.2

**Status:** `Provisional`

**Created:** 2026-08-01

**Owner:** [TODO: @github-username]

**SIG:** sig-operator

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP covers the operator-library work planned for the
FlagOS 2.2 release cycle, across four directions:

1. **Operator scale** — grow the total operator set to 635, combining manually
   implemented operators with operators produced by KernelGen
   (flagos-ai/community#93).
2. **Attention operators** — high-performance Attention-class operators
   matching NVIDIA state-of-the-art, running on 5+ domestic chips.
3. **TLE key operators** — key operators built on the Triton Language Extension
   (TLE), using the compiler-side TLE work (flagos-ai/community#96) as the
   underlying capability.
4. **General optimization techniques** — low-bit, MegaKernel fusion, reduction
   layout, and shape-aware multi-path dispatch, applied to named operators.

Repositories: https://github.com/flagos-ai/FlagGems,
https://github.com/flagos-ai/FlagBLAS, https://github.com/flagos-ai/FlagDNN,
https://github.com/flagos-ai/FlagSparse, https://github.com/flagos-ai/FlagFFT,
https://github.com/flagos-ai/FlagAttention

## Motivation

FlagOS 2.2 advances the operator library along three axes: scale (more
operators covered), performance (Attention and key operators at NVIDIA
state-of-the-art on domestic chips), and generality (shared optimization
techniques reused across operators). Manual implementation and KernelGen
generation are counted together as one operator set so that coverage is
tracked against a single target rather than split across two workflows.

### Goals

**(Required)**

- **G1 (Operator scale):** Reach 635 total operators, composed of 334 manually
  implemented and 301 KernelGen-generated (flagos-ai/community#93). Includes
  the sub-targets in the [Operator Count](#operator-count) table.
- **G2 (Attention operators):** Deliver high-performance Attention-class
  operators matching NVIDIA state-of-the-art, running on 5+ domestic chips.
  <!-- TODO: list the specific Attention operators in scope; name the target
       chips; define the NVIDIA SOTA baseline (hardware, version) and the
       parity tolerance per operator. -->
- **G3 (TLE key operators):** Deliver key operators built on TLE, using the
  compiler-side TLE capability (flagos-ai/community#96).
  <!-- TODO: name the key operators built on TLE and the acceptance metric per
       operator. -->
- **G4 (General optimization techniques):** Apply low-bit, MegaKernel fusion,
  reduction layout, and shape-aware multi-path dispatch to named operators.
  <!-- TODO: for each technique, name the operators it is applied to and the
       measured effect. -->

### Non-Goals

- The KernelGen tooling, knowledge base, and multi-chip generation mechanism
  itself, tracked in flagos-ai/community#93. This FEP counts the operators
  KernelGen produces but does not cover how KernelGen works.
- The compiler-side TLE capability (MegaKernel, distributed primitives,
  buffer aliasing), tracked in flagos-ai/community#96. This FEP consumes TLE
  but does not define it.

## Proposal

### Feature 1: Operator Scale

Grow the operator set to 635 total operators. Manually implemented operators
span FlagBLAS, FlagDNN, FlagSparse, FlagFFT and FlagGems; generated operators
are produced by KernelGen (flagos-ai/community#93) and counted in the same
total. The per-library and per-target breakdown is in the
[Operator Count](#operator-count) table.

### Feature 2: Attention Operators

Deliver high-performance Attention-class operators targeting NVIDIA
state-of-the-art, running on 5+ domestic chips.

<!-- TODO (design): list the Attention operators in scope (e.g. the
     Flash-family variants), the target chips, and the optimization approach
     per operator. -->

### Feature 3: TLE Key Operators

Deliver key operators built on the Triton Language Extension. The TLE
capability itself (MegaKernel, distributed primitives, buffer aliasing) is
provided by the compiler side (flagos-ai/community#96); this feature is the
operator-side adoption of it.

<!-- TODO (design): name the key operators built on TLE and how each uses the
     TLE capability. -->

### Feature 4: General Optimization Techniques

Apply reusable optimization techniques across operators:

- **Low-bit** — [TODO: operators and bit widths]
- **MegaKernel fusion** — [TODO: fused operator groups]
- **Reduction layout** — [TODO: operators]
- **Shape-aware multi-path dispatch** — [TODO: operators]

<!-- TODO (design): for each technique, the named operators it applies to and
     the measured effect. -->

## Design Details

<!-- TODO: implementation-level details for Features 2/3/4, to be filled before
     Status moves to `Implementable`. -->

## Operator Count

Total: **635** = **334** manually implemented + **301** KernelGen-generated
(flagos-ai/community#93).

### Manually implemented (334)

| Library | Count |
|---|---|
| FlagBLAS | 21 |
| FlagDNN | 20 |
| FlagSparse | 12 |
| FlagFFT | 14 |
| FlagGems (family) | 267 |
| **Total** | **334** |

### KernelGen-generated (301)

Generated via KernelGen (flagos-ai/community#93). Named sub-targets:

| Sub-target | Count |
|---|---|
| gems-SGLang | ≥35 |
| gems-vLLM | 3 |
| [TODO: telecom operators] | 4 |
| [TODO: named party] | 3 |
| [TODO: remaining generated operators] | [TODO] |
| **Total** | **301** |

<!-- TODO: label the two [TODO] sub-targets with their actual scope, and
     itemize the remaining generated operators so the sub-target counts sum to
     301. -->

## Performance Targets

Representative operator speedups (vs. [TODO: baseline — NVIDIA SOTA hardware
and version]). Status is Pending until measured on the release hardware.

| Operator | Target | Status |
|---|---|---|
| Flash MLA | 0.916–1.213× | Pending |
| reshape_and_cache | 185.874× | Pending |
| [TODO: remaining named operators] | [TODO] | Pending |

<!-- TODO: define the baseline precisely (hardware, version, workload) and add
     the remaining operators with performance targets from the roadmap. -->

## Packaging

Installed from source per library.

```bash
# FlagGems
git clone https://github.com/flagos-ai/FlagGems.git
cd FlagGems && pip install .
```

<!-- TODO: build/install commands for FlagBLAS, FlagDNN, FlagSparse, FlagFFT
     and FlagAttention; packaging format (wheel vs. source); platform and
     toolkit version requirements per target chip. -->

## Test Plan

**(Required)** Each goal is verified independently. Acceptance runs on vendor
hardware; results (environment, logs, metrics) are attached to the tracking
issue by the testing party.

### G1: Operator scale

<!-- TODO: how the 635 count is verified — the operator inventory / test suite
     that enumerates implemented + generated operators, and the command that
     produces the count. -->

### G2: Attention operators

<!-- TODO: per Attention operator — correctness test command, performance
     benchmark command, target chips, NVIDIA SOTA baseline and parity
     tolerance. -->

### G3: TLE key operators

<!-- TODO: per key operator — test command and acceptance metric. -->

### G4: General optimization techniques

<!-- TODO: per technique/operator — test command and the measured effect
     that counts as passing. -->

## Related PRs

<!-- TODO: link the implementation PRs across FlagGems, FlagBLAS, FlagDNN,
     FlagSparse, FlagFFT and FlagAttention. -->

- [ ] flagos-ai/community#93 — KernelGen Knowledge and Tool Hub (source of the
  301 generated operators; cross-reference, not owned by this FEP)
- [ ] flagos-ai/community#96 — FlagTree TLE MegaKernel + distributed primitives
  (TLE capability consumed by G3/G4; cross-reference, not owned by this FEP)

## Implementation History

- 2026-08-01: FEP created as `Provisional` for the FlagOS 2.2 cycle.

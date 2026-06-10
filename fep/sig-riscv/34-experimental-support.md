# FEP-34: Experimental RISC-V Support for FlagOS

**Status:** `Provisional`

**Created:** 2026-06-05

**Owner:** @shiptux

**SIG:** sig-riscv

**Target Version:** FlagOS TBD

---

## Summary

This FEP scopes an **experimental** track of RISC-V architecture support for the FlagOS software stack: compile-adapt the FlagOS software stack on `riscv64`, document what builds, what breaks, and what is not yet supported, and analyze the dependency graph for RISC-V availability. Distribution-level packaging and publishing decisions belong to `sig-os` ([flagos-ai/community#19](https://github.com/flagos-ai/community/pull/19)); this FEP hands compile evidence and build artifacts to that workflow.

This work runs in parallel with per-vendor RISC-V backend FEPs such as SpacemiT's FlagGems backend ([flagos-ai/community#33](https://github.com/flagos-ai/community/pull/33)); this FEP covers architecture-level enablement across the whole stack, while per-vendor FEPs cover specific operator/runtime backends.

## Motivation

RISC-V is becoming a viable target for AI system software, with chip vendors such as SpacemiT shipping platforms suitable for FlagOS workloads. Today FlagOS's published packages target `amd64` only (see [unified-package-integration](../sig-os/19-unified-package-integration.md)), and `riscv64` is unverified across most of the stack. We need a structured experimental track to:

- Discover and document what builds, what breaks, and what is fundamentally unsupported on RISC-V today.
- Inform whether and when RISC-V deserves a place in the baseline matrix.
- Reduce duplicated effort across vendor-specific RISC-V backend FEPs by centralizing the architecture-level findings.

### Goals

- Compile-adapt the FlagOS software stack for `riscv64`, landing build helpers, CI matrix entries, and capability documentation directly in the originating Flag* repositories.
- Analyze the FlagOS dependency graph for RISC-V availability and land dependency-trimming PRs in the originating repositories where deps are unavailable, broken, or unnecessary.
- Surface the capability boundary per repository in that repository's own documentation — what builds, what's limited, what is not yet supported on `riscv64`.

### Non-Goals

- **Distribution-level packaging and publishing.** Distribution package formats (`.deb`/`.rpm`/wheel), the supported distribution matrix, publishing channels, and per-distribution install/runtime validation belong to `sig-os` ([#19](https://github.com/flagos-ai/community/pull/19)). This FEP hands compile evidence and build artifacts to that workflow.
- Production-grade RISC-V support across all FlagOS modules. The work here is explicitly experimental.
- Guaranteeing every FlagOS module compiles or runs on RISC-V in this wave. Some modules will be documented as not-yet-supported; that is a valid outcome.
- Adding `riscv` to the canonical backend suffix list in [unified-package-integration](../sig-os/19-unified-package-integration.md) before experiment data justifies it. That is a follow-up decision under `sig-os` once compatibility data is in hand.
- Replacing per-vendor RISC-V backend FEPs (for example SpacemiT, [community#33](https://github.com/flagos-ai/community/pull/33)); this FEP coordinates above them, not under them.

## Proposal

Stand up an experimental RISC-V track owned by `sig-riscv`, executing two phases that may run in parallel:

1. **Compile adaptation.** For each FlagOS repository in scope, attempt a `riscv64` build and submit the adaptation back to the originating repository — either a working build helper + CI matrix entry, or a documented "not yet supported" status (README note, an `ARCH_SUPPORT`-style file, or a CI skip).
2. **Dependency analysis.** Identify deps that are unavailable, broken, or unnecessary on `riscv64`, and land trimming / relaxation PRs in the originating repositories.

This FEP does not produce any standalone document; the experiment's outcome is the state of the in-scope Flag* repositories after the merged work.

Build helpers and CI matrix entries landed by Phase 1 feed into sig-os's distribution packaging workflow; this FEP does not specify package format, distribution matrix, or publishing channels.

Coordination with vendor-specific RISC-V backend SIGs (for example sig-operator for SpacemiT) happens through this FEP's tracking issue and the related PR list.

## Design Details

### Modules in scope

Initial scope mirrors Wave 1 of [unified-package-integration](../sig-os/19-unified-package-integration.md): FlagCX, FlagTree, FlagGems, FlagScale, FlagQuantum, FlagTensor, FlagAudio, FlagBLAS, FlagDNN, FlagAttention, FlagSparse. Within this wave, **FlagCX, FlagTree, FlagGems, and FlagScale are the initial priority** for the build matrix; the remaining seven modules join as the matrix progresses. Each module enters with one of three statuses:

- **Compile-adapted** — builds on `riscv64`; build helpers and CI matrix entry merged into the originating repository.
- **Partially adapted** — builds with limitations (subset of operators, particular configuration). Limitations recorded in the repository's own documentation.
- **Not yet supported** — documented in the originating repository as out of scope for this experimental wave, with a brief justification (for example missing upstream Triton support).

The status per module is tracked in [Related PRs](#related-prs).

### Coordination boundaries

- **sig-operator** and other module-owning SIGs own the vendor-specific RISC-V backends — operator implementations, runtime backends. Example: SpacemiT's FlagGems backend under [community#33](https://github.com/flagos-ai/community/pull/33). This FEP consumes those backends; it does not duplicate operator-level work.
- **sig-os** owns distribution-level integration — package format selection, distribution matrix, publishing channels, per-distribution install/runtime validation. Build helpers and compile evidence from this FEP feed into sig-os's workflow.

### Dependency policy

The dependency analysis phase classifies each dependency relative to RISC-V:

- **Hard runtime dep, RISC-V available** — keep.
- **Hard runtime dep, RISC-V unavailable** — block; surface as a capability boundary in the originating repository's documentation.
- **Optional dep** — should be marked optional and excluded from default install paths.
- **Build-only dep** — should not appear in runtime metadata.
- **Unused dep** — remove via a PR to the originating repository.

Dependency-trimming PRs land in the originating Flag* repositories. This FEP tracks the analysis output and the list of submitted trimming PRs.

## Test Plan

The deliverables for this FEP live in the in-scope Flag* repositories; "test plan" maps to how each merged piece is validated.

- **Build matrix:** for each in-scope module, attempt a `riscv64` build (host or QEMU user-mode emulation). The result is reflected in the originating repo as either a merged build helper / CI matrix entry (pass / partial) or a documented not-yet-supported status (fail).
- **Smoke test:** for any module whose `riscv64` build succeeds (fully or partially), run a minimal install-layout-level check on `riscv64` (`importlib.util.find_spec` for Python, `ldconfig` / link test for native libraries). Functional and accelerator tests are delegated to per-vendor backend FEPs.
- **Dependency analysis:** produced from `pip show` / dep tree tools and import/link usage; results land as merged trimming PRs in the originating repositories.

Status transition: this FEP moves to `Implemented` when the merged PRs tracked in [Related PRs](#related-prs) collectively cover the in-scope modules — either with `riscv64` enablement merged or with the not-yet-supported status documented in each originating repository. Every module succeeding is **not** a requirement; documented limitations are an acceptable outcome.

### Deliverables

This FEP does not produce any standalone document. The experimental track lands as merged PRs in the in-scope Flag* repositories:

| Phase | Evidence in repository |
|-------|------------------------|
| Compile adaptation | Merged build helpers / Dockerfiles / CI matrix entries in each Flag* repo, or a documented not-yet-supported status (README note, `ARCH_SUPPORT`-style file, or CI skip) |
| Dependency analysis | Merged dependency-trimming PRs in originating Flag* repositories |

Progress is tracked in [Related PRs](#related-prs); the capability boundary per module is whatever the repository's own documentation says after the experiment lands.

## Related PRs

This list is a snapshot; the authoritative tracking lives in the FEP tracking issue.

**Related FEPs:**

- [flagos-ai/community#33](https://github.com/flagos-ai/community/pull/33) — `fep(sig-operator)`: SpacemiT backend for FlagGems (per-vendor RISC-V backend; consumed by this FEP).
- [flagos-ai/community#19](https://github.com/flagos-ai/community/pull/19) — `fep(sig-os)`: unified package integration FEP; receives build helpers and compile evidence from this FEP for distribution packaging.

**Related upstream work:**

- [flagos-ai/FlagGems#3793](https://github.com/flagos-ai/FlagGems/pull/3793) — SpacemiT operator implementations and Triton dependency update (merged).

**Implementation tracking (priority subset of Wave 1, TBD):**

- [ ] flagos-ai/FlagCX#TBD — `riscv64` build experiment
- [ ] flagos-ai/FlagTree#TBD — `riscv64` build experiment
- [ ] flagos-ai/FlagGems#TBD — `riscv64` build experiment (architecture-level; vendor backends tracked under #33)
- [ ] flagos-ai/FlagScale#TBD — `riscv64` build experiment
- [ ] Remaining Wave 1 modules (FlagQuantum, FlagTensor, FlagAudio, FlagBLAS, FlagDNN, FlagAttention, FlagSparse) — joined as the build matrix progresses.
- [ ] Dependency-trimming PRs (per repository) — populated as analysis lands.

## Implementation History

- 2026-06-05: Initial draft for the experimental RISC-V architecture-level track. SIG registration lives in [flagos-ai/community#35](https://github.com/flagos-ai/community/pull/35); this PR contains only the FEP document. Scope is intentionally narrow — compile adaptation + dependency analysis; distribution-level packaging, the supported distribution matrix, and publishing channels belong to `sig-os` ([#19](https://github.com/flagos-ai/community/pull/19)). Deliverables land as merged PRs in originating Flag* repositories rather than standalone PDF reports. Assigned `FEP-34` and renamed the file. Adopted the SpacemiT brand notation consistently. Smoke test scope updated to apply to any module whose build succeeds (fully or partially). Implementation tracking explicitly calls out the initial 4-module priority within Wave 1; relative links to the OS FEP updated for its `19-` prefix.

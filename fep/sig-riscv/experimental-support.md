# FEP-NNNN: Experimental RISC-V Support for FlagOS

**Status:** `Provisional`

**Created:** 2026-06-05

**Owner:** @shiptux

**SIG:** sig-riscv

**Target Version:** FlagOS TBD

---

## Summary

This FEP scopes an **experimental** track of RISC-V architecture support for the FlagOS software stack: compile-adapt the FlagOS software stack on `riscv64`, document what builds, what breaks, and what is not yet supported, and analyze the dependency graph for RISC-V availability. Distribution-level packaging and publishing decisions belong to `sig-os` ([flagos-ai/community#19](https://github.com/flagos-ai/community/pull/19)); this FEP hands compile evidence and build artifacts to that workflow.

This work runs in parallel with per-vendor RISC-V backend FEPs such as Spacemit's FlagGems backend ([flagos-ai/community#33](https://github.com/flagos-ai/community/pull/33)); this FEP covers architecture-level enablement across the whole stack, while per-vendor FEPs cover specific operator/runtime backends.

## Motivation

RISC-V is becoming a viable target for AI system software, with chip vendors such as Spacemit shipping platforms suitable for FlagOS workloads. Today FlagOS's published packages target `amd64` only (see [unified-package-integration](../sig-os/unified-package-integration.md)), and `riscv64` is unverified across most of the stack. We need a structured experimental track to:

- Discover and document what builds, what breaks, and what is fundamentally unsupported on RISC-V today.
- Inform whether and when RISC-V deserves a place in the baseline matrix.
- Reduce duplicated effort across vendor-specific RISC-V backend FEPs by centralizing the architecture-level findings.

### Goals

- Compile-adapt the FlagOS software stack for `riscv64`, recording problems encountered, workarounds applied, and performance observations.
- Analyze the FlagOS dependency graph for RISC-V availability, identifying deps that are unavailable, broken, or trimmable on `riscv64`.
- Deliver a RISC-V experiment report covering environment, build process, test results, and capability boundaries.
- Deliver a dependency analysis report — full dependency graph + RISC-V availability assessment + trimming suggestions.

### Non-Goals

- **Distribution-level packaging and publishing.** Distribution package formats (`.deb`/`.rpm`/wheel), the supported distribution matrix, publishing channels, and per-distribution install/runtime validation belong to `sig-os` ([#19](https://github.com/flagos-ai/community/pull/19)). This FEP hands compile evidence and build artifacts to that workflow.
- Production-grade RISC-V support across all FlagOS modules. The work here is explicitly experimental.
- Guaranteeing every FlagOS module compiles or runs on RISC-V in this wave. Some modules will be documented as not-yet-supported; that is a valid outcome.
- Adding `riscv` to the canonical backend suffix list in [unified-package-integration](../sig-os/unified-package-integration.md) before experiment data justifies it. That is a follow-up decision under `sig-os` once compatibility data is in hand.
- Replacing per-vendor RISC-V backend FEPs (for example Spacemit, [community#33](https://github.com/flagos-ai/community/pull/33)); this FEP coordinates above them, not under them.

## Proposal

Stand up an experimental RISC-V track owned by `sig-riscv`, executing two phases that may run in parallel:

1. **Compile adaptation.** For each FlagOS repository in scope, attempt a `riscv64` build and record the result, the issues encountered, and any workaround. Output: per-repository build matrix + RISC-V experiment report.
2. **Dependency analysis.** Produce a full dependency graph of the FlagOS stack and assess each dep's RISC-V availability. Submit removal/relaxation PRs to originating repositories where deps are not actually required. Output: dependency analysis report.

Build artifacts produced in Phase 1 are handed to `sig-os` for distribution packaging decisions; this FEP does not specify package format, distribution matrix, or publishing channels.

Coordination with vendor-specific RISC-V backend SIGs (for example sig-operator for Spacemit) happens through this FEP's tracking issue and the related PR list.

## Design Details

### Modules in scope

Initial scope mirrors Wave 1 of [unified-package-integration](../sig-os/unified-package-integration.md): FlagCX, FlagTree, FlagGems, FlagScale, FlagQuantum, FlagTensor, FlagAudio, FlagBLAS, FlagDNN, FlagAttention, FlagSparse. Each module enters with one of three statuses:

- **Compile-adapted** — builds on `riscv64`; build artifact handed to `sig-os`.
- **Partially adapted** — builds with limitations (subset of operators, particular configuration). Limitations recorded in the experiment report.
- **Not yet supported** — documented as out of scope for this experimental wave, with a brief justification (for example missing upstream Triton support).

The status per module is tracked in [Related PRs](#related-prs).

### Coordination boundaries

- **sig-operator** and other module-owning SIGs own the vendor-specific RISC-V backends — operator implementations, runtime backends. Example: Spacemit's FlagGems backend under [community#33](https://github.com/flagos-ai/community/pull/33). This FEP consumes those backends; it does not duplicate operator-level work.
- **sig-os** owns distribution-level integration — package format selection, distribution matrix, publishing channels, per-distribution install/runtime validation. Build artifacts and compile evidence from this FEP feed into sig-os's workflow.

### Dependency policy

The dependency analysis phase classifies each dependency relative to RISC-V:

- **Hard runtime dep, RISC-V available** — keep.
- **Hard runtime dep, RISC-V unavailable** — block; report as a capability boundary in the experiment report.
- **Optional dep** — should be marked optional and excluded from default install paths.
- **Build-only dep** — should not appear in runtime metadata.
- **Unused dep** — remove via a PR to the originating repository.

Dependency-trimming PRs land in the originating Flag* repositories. This FEP tracks the analysis output and the list of submitted trimming PRs.

## Test Plan

The deliverables for this FEP are two reports plus build evidence; "test plan" maps to the validation behind each deliverable.

- **Build matrix:** for each in-scope module, attempt a `riscv64` build (host or QEMU user-mode emulation). Output: pass / partial / fail in the experiment report.
- **Smoke test:** for build-adapted modules, run a minimal install-layout-level check on `riscv64` (`importlib.util.find_spec` for Python, `ldconfig` / link test for native libraries). Functional and accelerator tests are delegated to per-vendor backend FEPs.
- **Dependency analysis:** produced from `pip show` / dep tree tools and import/link usage, cross-referenced against `riscv64` availability for each transitive dep.

Status transition: this FEP moves to `Implemented` when both deliverable reports are published. Every module succeeding is **not** a requirement; documented limitations are an acceptable outcome.

### Deliverables

| Deliverable | Description | Form |
|-------------|-------------|------|
| RISC-V experiment report | Environment, build process, test results, capability boundaries on `riscv64` | PDF technical report |
| Dependency analysis report | Full dependency graph + RISC-V availability + trimming suggestions | PDF report |

## Related PRs

This list is a snapshot; the authoritative tracking lives in the FEP tracking issue.

**Related FEPs:**

- [flagos-ai/community#33](https://github.com/flagos-ai/community/pull/33) — `fep(sig-operator)`: Spacemit backend for FlagGems (per-vendor RISC-V backend; consumed by this FEP).
- [flagos-ai/community#19](https://github.com/flagos-ai/community/pull/19) — `fep(sig-os)`: unified package integration FEP; receives build artifacts from this FEP for distribution packaging.

**Related upstream work:**

- [flagos-ai/FlagGems#3793](https://github.com/flagos-ai/FlagGems/pull/3793) — Spacemit operator implementations and Triton dependency update (merged).

**Implementation tracking (TBD):**

- [ ] flagos-ai/FlagCX#TBD — `riscv64` build experiment
- [ ] flagos-ai/FlagTree#TBD — `riscv64` build experiment
- [ ] flagos-ai/FlagGems#TBD — `riscv64` build experiment (architecture-level; vendor backends tracked under #33)
- [ ] flagos-ai/FlagScale#TBD — `riscv64` build experiment
- [ ] (additional modules added as the build matrix progresses)
- [ ] Dependency-trimming PRs (per repository) — populated as analysis lands.

## Implementation History

- 2026-06-05: Initial draft after `sig-riscv` was registered in [flagos-ai/community#34](https://github.com/flagos-ai/community/pull/34). Scope is intentionally narrow — architecture-level (compile adaptation + dependency analysis); distribution-level packaging, the supported distribution matrix, and publishing channels belong to `sig-os` ([#19](https://github.com/flagos-ai/community/pull/19)).

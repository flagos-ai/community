# FEP-NNNN: Experimental RISC-V Support for FlagOS

**Status:** `Provisional`

**Created:** 2026-06-05

**Owner:** @shiptux

**SIG:** sig-riscv

**Target Version:** FlagOS TBD

---

## Summary

This FEP scopes an **experimental** track of RISC-V architecture support for the FlagOS software stack: compile-adapt the FlagOS software stack on `riscv64`, deliver experimental `.deb`/`.rpm` packages for components that build successfully, validate installation across five mainstream Linux distributions, and produce a set of technical reports (RISC-V experiment, dependency analysis, cross-distribution compatibility). The deliverables are explicitly experimental — the goal is to chart the capability boundary on RISC-V today, not to ship production-grade artifacts.

This work runs in parallel with per-vendor RISC-V backend FEPs such as Spacemit's FlagGems backend ([flagos-ai/community#33](https://github.com/flagos-ai/community/pull/33)); this FEP covers the architecture-level enablement and distribution-level packaging across the whole stack, while per-vendor FEPs cover specific operator/runtime backends.

## Motivation

RISC-V is becoming a viable target for AI system software, with chip vendors such as Spacemit shipping platforms suitable for FlagOS workloads. Today, FlagOS's published Wave 1 packages target `amd64` only (see [unified-package-integration](../sig-os/unified-package-integration.md)), and `riscv64` on the broader distribution matrix is unverified. We need a structured experimental track to:

- Discover and document what builds, what breaks, and what is fundamentally unsupported on RISC-V today.
- Inform whether and when RISC-V deserves a place in the baseline package matrix.
- Give downstream RISC-V distributions (openKylin RISC-V, openEuler RISC-V, OpenAnolis RISC-V, …) a concrete reference for FlagOS adoption.
- Reduce duplicated effort across vendor-specific RISC-V backend FEPs by centralizing the architecture- and distribution-level findings.

### Goals

- Compile-adapt the FlagOS software stack for `riscv64`, recording problems encountered, workarounds applied, and performance observations.
- Produce experimental `.deb` and `.rpm` packages for `riscv64` for FlagOS components that compile successfully.
- Verify package installation on five mainstream Linux distributions: **Ubuntu, Debian, Fedora, openEuler, OpenAnolis**.
- Profile runtime dependencies of the FlagOS stack and trim deps where they are not actually required.
- Deliver a RISC-V experiment report covering environment, build process, test results, and capability boundaries.
- Deliver a dependency analysis report with a full dependency graph and optimization suggestions.
- Deliver an initial cross-distribution compatibility verification report.

### Non-Goals

- Production-grade RISC-V support across all FlagOS modules. The deliverables here are explicitly experimental.
- Guaranteeing every FlagOS module compiles or runs on RISC-V in this wave. Some modules will be documented as not-yet-supported; that is a valid outcome.
- Adding `riscv` to the canonical backend suffix list in [unified-package-integration](../sig-os/unified-package-integration.md) before the experiment results justify it. This is a follow-up decision once compatibility data is in hand.
- Replacing per-vendor RISC-V backend FEPs (for example Spacemit, [community#33](https://github.com/flagos-ai/community/pull/33)); this FEP coordinates above them.
- Verifying every Linux distribution shipping a `riscv64` port. The matrix is the five distributions listed above.

## Proposal

Stand up an experimental RISC-V track owned by `sig-riscv`, executing the work in three phases that may run in parallel:

1. **Compile adaptation.** For each FlagOS repository in scope, attempt a `riscv64` build on each target distribution and record the result, the issues encountered, and any workaround. Output: per-repository build matrix + the RISC-V experiment report.
2. **Packaging and runtime validation.** For components that build successfully, produce experimental `.deb`/`.rpm` packages and validate install + a minimal runtime smoke test on the five target distributions. Output: experimental package set + the cross-distribution compatibility validation report.
3. **Dependency analysis and trimming.** Produce a full dependency graph of the FlagOS stack on RISC-V, identify unnecessary dependencies, and submit removal/relaxation PRs to the originating repositories. Output: the dependency analysis report.

Coordination with vendor-specific RISC-V backend SIGs (for example sig-operator for Spacemit) happens through this FEP's tracking issue and the related PR list.

## Design Details

### Target distribution matrix

| Distribution | RISC-V edition | Package format |
|--------------|----------------|----------------|
| Ubuntu | Ubuntu `riscv64` port | `.deb` |
| Debian | Debian `riscv64` port | `.deb` |
| Fedora | Fedora `riscv64` port | `.rpm` |
| openEuler | openEuler RISC-V edition | `.rpm` |
| OpenAnolis | OpenAnolis RISC-V edition | `.rpm` |

Specific point releases (for example "Ubuntu 24.04 riscv64", "Fedora 43 riscv64") are pinned in the FEP tracking issue and the experiment report once selected; this section captures the matrix shape.

### Modules in scope

Initial scope mirrors Wave 1 of [unified-package-integration](../sig-os/unified-package-integration.md): FlagCX, FlagTree, FlagGems, FlagScale, FlagQuantum, FlagTensor, FlagAudio, FlagBLAS, FlagDNN, FlagAttention, FlagSparse. Each module enters the experiment with one of three statuses:

- **Compile-adapted** — builds on `riscv64`; experimental package produced.
- **Partially adapted** — builds with limitations (subset of operators, particular configuration). Limitations recorded in the experiment report.
- **Not yet supported** — documented as out of scope for this experimental wave, with a brief justification (for example missing upstream Triton support).

The status per module is tracked in [Related PRs](#related-prs).

### Coordination with vendor backend FEPs

Vendor-specific RISC-V backend FEPs continue to own their backend (for example Spacemit's FlagGems backend under [flagos-ai/community#33](https://github.com/flagos-ai/community/pull/33)). This FEP does **not** duplicate operator-level work; it consumes vendor backends as they land and reports cross-distribution and packaging results for them.

### Dependency policy

The dependency analysis phase classifies each dependency as one of:

- **Hard runtime dep** — required for execution; must appear in package metadata.
- **Optional dep** — required only for a feature subset; should be marked optional and not pulled by default install.
- **Build-only dep** — should not appear in runtime package metadata.
- **Unused dep** — to be removed via a PR to the originating repository.

Dependency-trimming PRs land in the originating Flag* repositories. This FEP tracks the analysis output and the list of submitted trimming PRs.

## Packaging

Where a module compiles on `riscv64`, the experimental package follows the same structure as [unified-package-integration](../sig-os/unified-package-integration.md), narrowed to:

- Naming follows the same `python3-<slug>` / `lib<name>-<backend>` rules; the architecture field carries `riscv64` (Debian `Architecture` / RPM `BuildArch`) rather than a backend suffix in the package name. Accelerator-specific backend suffixes remain on the package name only when applicable.
- Build entry points live under `packaging/debian/build-helpers/build-<slug>.sh` and `packaging/rpm/build-helpers/build-<slug>.sh`; on RISC-V the helpers run on a `riscv64` host or via QEMU user-mode emulation, per repository decision.
- Experimental packages publish to an **experimental** namespace in FlagOS Nexus (for example `flagos-apt-hosted-experimental`), separate from the production `flagos-apt-hosted` repository, so users cannot accidentally install them alongside baseline packages.
- Experimental packages carry a metadata flag (changelog note + package description prefix `[experimental]`) so downstream tooling can detect them.

Container images and a PyPI `riscv64` wheel are out of scope for this experimental wave; once a module is upgraded from experimental to baseline, those channels follow the parent FEP.

## Test Plan

The deliverables for this FEP are reports plus experimental packages; "test plan" maps to the validation behind each deliverable.

- **Build matrix:** for each in-scope module × `{Ubuntu, Debian, Fedora, openEuler, OpenAnolis}`, attempt a `riscv64` build. Output: pass / fail / limited matrix in the RISC-V experiment report.
- **Install verification:** for every successfully built experimental package, install on the corresponding distribution from a clean image (or QEMU `riscv64` VM) and confirm the install layout is correct.
- **Smoke test (packaging CI):** install-layout-level only (`importlib.util.find_spec` for Python; `ldconfig` / `dpkg -L` for native), matching the baseline FEP — no full `import` of heavy runtime deps.
- **Functionality check (vendor hardware):** delegated to per-vendor backend FEPs (for example Spacemit). This FEP does not run accelerator tests on the packaging side.
- **Dependency analysis:** produced from `apt-cache depends`, `dnf repoquery --requires`, plus Python `pip show` / dependency tree tools, cross-referenced against actual import/link usage. Output: dependency analysis report.
- **Cross-distribution compatibility:** the install + smoke result on each distribution × module is the input to the cross-distribution compatibility validation report.

Status transition: this FEP moves to `Implemented` when the four deliverable documents are published and the experimental package set is available on Nexus' experimental namespace. It does **not** require every module to succeed — documented limitations are an acceptable outcome.

### Deliverables

| Deliverable | Description | Form |
|-------------|-------------|------|
| RISC-V experiment report | Environment, build process, test results, capability boundaries on `riscv64` | PDF technical report |
| RISC-V experimental packages | Where compilation succeeded, `riscv64` packages for in-scope modules | `.deb` / `.rpm` (experimental) |
| Dependency analysis report | Full dependency graph for the FlagOS stack + optimization suggestions | PDF report |
| Cross-distribution compatibility report | Initial multi-distribution install + runtime verification on the 5-distribution matrix | PDF report |

## Related PRs

This list is a snapshot; the authoritative tracking lives in the FEP tracking issue.

**Related FEPs:**

- [flagos-ai/community#33](https://github.com/flagos-ai/community/pull/33) — `fep(sig-operator)`: Spacemit backend for FlagGems (per-vendor RISC-V backend; consumed by this FEP).
- [flagos-ai/community#19](https://github.com/flagos-ai/community/pull/19) — unified package integration FEP (`sig-os`); this FEP follows its packaging shape, narrowed to `riscv64` and the 5-distribution matrix.

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

- 2026-06-05: Initial draft prepared after `sig-riscv` was registered in [flagos-ai/community#34](https://github.com/flagos-ai/community/pull/34).

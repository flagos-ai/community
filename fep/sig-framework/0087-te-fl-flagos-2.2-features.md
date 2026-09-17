# FEP-0087: TransformerEngine-FL Features for FlagOS 2.2

**Status:** `Provisional`

**Created:** 2026-07-30

**Owner:** [TODO: @github-username]

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP covers the TransformerEngine-FL work planned for the
FlagOS 2.2 release cycle, on top of the v0.2.0 line delivered in FlagOS 2.1
([FEP-0026](0026-te-fl-v0.2.0-rc0-features.md), upstream base TE v2.14):

1. **Vendor adaptation matrix** — complete adaptation for **10** vendor
   platforms and publish an adaptation matrix documenting per-vendor feature
   coverage.
2. **Upstream synchronization with TE v2.17** — upgrade the upstream NVIDIA
   TransformerEngine base from v2.14 to v2.17 while preserving the FlagOS
   plugin system.
3. **Deferred: FSA sparse attention backend** — design and business-logic
   validation continued, but FSA was explicitly left out of the 2.2 release
   test scope and is not a 2.2 acceptance item.

Repository: https://github.com/flagos-ai/TransformerEngine-FL

## Release Boundary and Evidence

- **FlagOS 2.1 baseline:** TransformerEngine-FL `v0.2.0`, based on upstream
  TE v2.14.
- **FlagOS 2.2 release candidate reviewed:** `v0.3.0-rc2.post1`, as pinned by
  the FlagOS 2.2 RC2 manifest.
- **Development window:** 2026-06-01 through 2026-08-31.

The RC2 delta verifies the vendor backend and CI work listed below and the
upstream v2.17 synchronization in #105. The release evidence does not verify a
published ten-vendor acceptance matrix. The development review also states
that FSA was not entering 2.2 testing; this FEP therefore records it as
deferred, not delivered.

## Motivation

FlagOS 2.1 established TransformerEngine-FL as a multi-backend TE distribution
with a plugin system dispatching to vendor operator implementations. The 2.2
cycle works toward a 10-vendor adaptation matrix (replacing ad-hoc per-vendor
status) and upgrades the upstream base to v2.17. FSA sparse attention remained
under business-logic evaluation and was removed from the 2.2 test scope.

### Goals

**(Required)**

- **G1 (Vendor matrix):** Complete adaptation for 10 vendor platforms and
  publish an adaptation matrix. The in-tree vendor backend directory
  (`transformer_engine/plugin/core/backends/vendor/`) currently covers 9
  platforms: NVIDIA (cuda), Enflame, Hygon, Iluvatar, KunlunXin, MetaX,
  Moore Threads (musa), Ascend (npu), Tsingmicro.
  <!-- TODO: name the 10th platform, and define the per-vendor bar for
       "adapted" (which ops / which unit-test suites must pass) that the
       matrix will document. -->
- **G2 (upstream v2.17):** Synchronize the upstream base from v2.14 to v2.17,
  preserving the FlagOS plugin system (plugin OP API signatures,
  `te_device_type()` multi-backend dispatch). The code landed in #105 and is
  present in the RC2 snapshot; end-to-end Megatron regression remains part of
  release acceptance.
- **G3 (deferred — FSA sparse attention):** Continue design and validation of
  Triton and CUDA implementations outside the 2.2 acceptance scope.
  <!-- TODO: the performance benefit is still under evaluation; define
       the target workloads, the expected gain over the dense fused
       attention path, and the acceptance criterion before this moves to
       Implementable. No FSA code is on main yet. -->

### Non-Goals

- Vendor platforms beyond the 10 named in the adaptation matrix for this
  cycle.
- Fused/sparse attention support on vendor backends beyond the Triton and
  CUDA implementations named in G3.
- Inference-serving optimization (out of scope for TE-FL, unchanged from
  previous cycles).
- FSA release acceptance in FlagOS 2.2; it was not included in the final test
  scope.

## Proposal

### Feature 1: Vendor Adaptation Matrix (10 platforms)

Per-vendor backend implementations under
`transformer_engine/plugin/core/backends/vendor/<vendor>/` (device management,
flash attention, operator registration). Landed or in flight on main:

- Tsingmicro TXDA backend (flagos-ai/TransformerEngine-FL#88).
- Ascend: `transformer_engine_npu` integration and reference-backend GEMM fix
  (#89); native MegatronAdaptor integration (#79); Ascend NPU unit-test CI
  (#91, open).
- Hygon: `multi_tensor_scale_tensor` via transformer_engine_hygon 2.13 (#85);
  library path resolution fallback (#82).
- KunlunXin: TE-FL backend patch integration (#84).
- FlagOS backend operators: Triton fused RoPE kernels (#83), layernorm (#72),
  bias support for generic GEMM (#70).

Deliverable: an **adaptation matrix** (published in the repository docs)
documenting per-vendor × per-capability support across all 10 platforms.

<!-- TODO: matrix location (docs/ page vs README), row/column definition, and
     whether CI enforces it per vendor. -->

### Feature 2: Upstream v2.17 Synchronization

PR #105 used the same tree-replacement strategy as the v2.9 → v2.14 sync in
2.1 (FEP-0026): integrate upstream changes, then re-apply the plugin-system
patches (plugin OP API signature sync, `te_device_type()` patching of new
upstream CUDA hardcoding, renamed-symbol fixes). It is included in RC2.

<!-- TODO: after a v2.16 diff review — list the upstream features pulled in
     and any plugin API breaks requiring vendor-backend changes. -->

### Feature 3: FSA Sparse Attention Backend (Deferred)

The following remained the design direction, but was not included in 2.2
release testing or acceptance:

- **Triton implementation** — vendor-neutral, using FlagOS backend Triton
  operators.
- **CUDA implementation** — NVIDIA-native.

<!-- TODO (design, before Implementable):
     1. FSA algorithm reference and sparsity pattern support.
     2. Integration point in the attention backend dispatch (alongside
        flash/fused attention selection).
     3. Which vendor backends can reuse the Triton implementation.
     4. Benefit evaluation results and go/no-go decision. -->

## Design Details

<!-- TODO: to be filled as Features 1–3 designs land, before Status moves to
     `Implementable`. -->

## Packaging

Unchanged from the 2.1 cycle: built from source per platform following the
repository build documentation; CI builds and wheel attachment via the
existing workflows (`build.yml`, `attach-wheels-to-release.yml`).

<!-- TODO: confirm per-vendor distribution channels for the 10-platform
     matrix (which vendors get prebuilt wheels vs source-only). -->

## Test Plan

**(Required)** Reuses the repository's CI matrix (`all_tests_cuda.yml`,
`all_tests_ascend.yml`, `all_tests_metax.yml`, `unit_tests_common.yml`,
`integration_tests_common.yml`).

| Goal | Verification | Status |
|---|---|---|
| G1: 10-vendor matrix | Per-vendor unit/integration tests green; adaptation matrix published and consistent with CI results <!-- TODO: per-vendor test entry points and hardware --> | Pending |
| G2: v2.17 sync | Existing plugin unit tests pass on the synced tree; per-vendor backends unaffected <!-- TODO: regression scope --> | Code merged in #105; acceptance pending |
| G3: FSA backend | Correctness vs dense attention reference; benefit evaluation on target workloads <!-- TODO: workloads, tolerance, perf criterion --> | Deferred from 2.2 testing |

## Related PRs

- [x] flagos-ai/TransformerEngine-FL#88 — feat(backend): support tsingmicro txda backend
- [x] flagos-ai/TransformerEngine-FL#89 — [Ascend] Integrate transformer_engine_npu && fix reference-backend GEMM
- [x] flagos-ai/TransformerEngine-FL#85 — hcu: multi_tensor_scale_tensor via transformer_engine_hygon 2.13
- [x] flagos-ai/TransformerEngine-FL#83 — Add FlagOS Triton fused RoPE kernels
- [x] flagos-ai/TransformerEngine-FL#79 — [ascend] Native MegatronAdaptor integration
- [x] flagos-ai/TransformerEngine-FL#84 — Integrate KunLunXin TE-FL backend patches
- [x] flagos-ai/TransformerEngine-FL#91 — [CICD] Add Ascend NPU unit test support
- [x] flagos-ai/TransformerEngine-FL#92 — Add BW1000 CI baseline and standardize plugin tests
- [x] flagos-ai/TransformerEngine-FL#93 — Add MUSA test workflow
- [x] flagos-ai/TransformerEngine-FL#94 — Add KunlunXin unit and MCore integration tests
- [x] flagos-ai/TransformerEngine-FL#95 — Expose backend ops required by TP communication overlap
- [x] flagos-ai/TransformerEngine-FL#98 — Add Enflame S60 CI baseline
- [x] flagos-ai/TransformerEngine-FL#105 — Sync TransformerEngine-FL to upstream v2.17

## Implementation History

- 2026-07-30: FEP created as `Provisional` for the FlagOS 2.2 cycle; FSA
  benefit evaluation outstanding.
- 2026-09-17: Reconciled `v0.2.0` with `v0.3.0-rc2.post1`; recorded the
  completed v2.17 code synchronization and vendor CI PRs, and moved FSA out of
  the 2.2 acceptance scope in line with the development review.

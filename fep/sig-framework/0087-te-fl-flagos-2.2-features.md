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
2. **[Stretch] Upstream synchronization with TE v2.16** — upgrade the upstream
   NVIDIA TransformerEngine base from v2.14 to v2.16 while preserving the
   FlagOS plugin system.
3. **FSA sparse attention backend** — add a new FSA sparse attention backend
   with both Triton and CUDA implementations. The performance benefit is still
   under evaluation and gates the final scope of this feature.

Repository: https://github.com/flagos-ai/TransformerEngine-FL

## Motivation

FlagOS 2.1 established TransformerEngine-FL as a multi-backend TE distribution
with a plugin system dispatching to vendor operator implementations. The 2.2
cycle continues along both established axes — vendor breadth (a complete
10-vendor matrix instead of ad-hoc per-vendor status) and upstream currency
(v2.16) — and begins extending the attention operator space with a sparse
attention (FSA) backend.

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
- **G2 (Stretch — upstream v2.16):** Synchronize the upstream base from v2.14
  to v2.16, preserving the FlagOS plugin system (plugin OP API signatures,
  `te_device_type()` multi-backend dispatch) as in previous upstream syncs.
  Marked stretch; slipping it does not block the release.
- **G3 (FSA sparse attention):** Provide an FSA sparse attention backend with
  a Triton implementation and a CUDA implementation.
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

## Proposal

### Feature 1: Vendor Adaptation Matrix (10 platforms)

Work in this cycle continues the per-vendor backend pattern under
`transformer_engine/plugin/core/backends/vendor/<vendor>/` (device management,
flash attention, operator registration). Landed or in flight on main this
cycle:

- Tsingmicro TXDA backend (flagos-ai/TransformerEngine-FL#88).
- Ascend: `transformer_engine_npu` integration and reference-backend GEMM fix
  (#89); native MegatronAdaptor integration (#79); Ascend NPU unit-test CI
  (#91, open).
- Hygon: `multi_tensor_scale_tensor` via transformer_engine_hygon 2.13 (#85);
  library path resolution fallback (#82).
- KunlunXin: TE-FL backend patch integration (#84).
- FlagOS backend operators: Triton fused RoPE kernels (#83), layernorm (#72),
  bias support for generic GEMM (#70).

The deliverable beyond the code is the **adaptation matrix**: a per-vendor ×
per-capability table (published in the repository docs) recording what each of
the 10 platforms supports.

<!-- TODO: matrix location (docs/ page vs README), row/column definition, and
     whether CI enforces it per vendor. -->

### Feature 2 (Stretch): Upstream v2.16 Synchronization

Same tree-replacement strategy as the v2.9 → v2.14 sync delivered in 2.1
(FEP-0026): integrate upstream changes, then re-apply the plugin-system
preservation patches (plugin OP API signature sync, `te_device_type()`
patching of new upstream CUDA hardcoding, renamed-symbol fixes).

<!-- TODO: after a v2.16 diff review — list the upstream features pulled in
     and any plugin API breaks requiring vendor-backend changes. -->

### Feature 3: FSA Sparse Attention Backend

Add FSA as a new sparse attention backend selectable through the existing
attention backend dispatch, with two implementations:

- **Triton implementation** — vendor-neutral path aligned with the FlagOS
  backend's Triton operator direction.
- **CUDA implementation** — NVIDIA-native path.

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
| G2: v2.16 sync | Existing plugin unit tests pass on the synced tree; per-vendor backends unaffected <!-- TODO: regression scope --> | Pending (stretch) |
| G3: FSA backend | Correctness vs dense attention reference; benefit evaluation on target workloads <!-- TODO: workloads, tolerance, perf criterion --> | Pending |

## Related PRs

- [x] flagos-ai/TransformerEngine-FL#88 — feat(backend): support tsingmicro txda backend
- [x] flagos-ai/TransformerEngine-FL#89 — [Ascend] Integrate transformer_engine_npu && fix reference-backend GEMM
- [x] flagos-ai/TransformerEngine-FL#85 — hcu: multi_tensor_scale_tensor via transformer_engine_hygon 2.13
- [x] flagos-ai/TransformerEngine-FL#83 — Add FlagOS Triton fused RoPE kernels
- [x] flagos-ai/TransformerEngine-FL#79 — [ascend] Native MegatronAdaptor integration
- [x] flagos-ai/TransformerEngine-FL#84 — Integrate KunLunXin TE-FL backend patches
- [ ] flagos-ai/TransformerEngine-FL#91 — [CICD] Add Ascend NPU unit test support

## Implementation History

- 2026-07-30: FEP created as `Provisional` for the FlagOS 2.2 cycle; FSA
  benefit evaluation outstanding.

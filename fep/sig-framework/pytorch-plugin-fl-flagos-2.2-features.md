# FEP: PyTorch-Plugin-FL Features for FlagOS 2.2

**Status:** `Provisional`

**Created:** 2026-07-30

**Owner:** [TODO: @github-username]

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP covers the PyTorch-Plugin-FL (`torch_fl`) work planned
for the FlagOS 2.2 release cycle, on top of the v0.1.0 CUDA/Ascend dispatch
foundation delivered in FlagOS 2.1
([FEP-0025](0025-pytorch-plugin-fl-v0.1.0-cuda-dispatch.md)):

1. **Vendor adaptation for 5 chips** — Hygon, MetaX, Huawei Ascend, T-Head,
   Moore Threads — validated on 3 model classes: LLM + VLM + Omni
   (tentatively the Qwen series, possibly extended to MiniCPM).
2. **FlagGems operator coverage 90%+** — an estimated **380+** FlagGems
   operators dispatched through the `flagos` device, with vendor operator
   libraries as the fallback path: CUDA-compatible vendors reuse PyTorch's
   libtorch kernels (100% operator coverage via the boxing approach);
   non-CUDA-compatible vendors integrate the vendor C++ operator library
   covering the operator range used by `transformers` and `diffusers`.
3. **torch-fl package release** — publish installable `torch_fl` wheels
   against PyTorch **2.8–2.10** (2.11 dropped: no vendor has shipped official
   support for it), split per vendor (e.g. `torch-fl-ascend`, `torch-fl-mx`)
   because the bundled libtorch makes a single wheel impractically large.
4. **Initial FlagCX integration** — `torch.distributed` basic capability on
   the `flagos` device: standard communication operators and DDP support,
   with an FSDP feasibility spike (not committed for this release).

Repository: https://github.com/flagos-ai/PyTorch-Plugin-FL

## Motivation

v0.1.0 proved the PrivateUse1 `flagos` device with per-operator backend
routing on CUDA and Ascend. The 2.2 cycle turns that foundation into a
releasable multi-vendor product: a defined 5-chip support matrix validated on
real models, a quantified FlagGems coverage bar with a deterministic fallback
story per vendor class, actual installable wheels on PyTorch versions vendors
ship against, and the first step from single-device execution to distributed
training via FlagCX.

### Goals

**(Required)**

- **G1 (5-chip adaptation):** Hygon, MetaX, Huawei Ascend, T-Head, and
  Moore Threads platforms run the 3 target model classes (LLM + VLM + Omni,
  tentatively Qwen series) through the `flagos` device.
  <!-- TODO: name the exact model list and per-model acceptance (inference
       only, or training too — v0.1.0 validated Qwen3-0.6B both ways). -->
- **G2 (FlagGems 90%+ coverage):** 90%+ of dispatched operators route to
  FlagGems (≈380+ operators), with fallback to vendor operator libraries:
  - CUDA-compatible vendors: libtorch kernel-reuse ("boxing") path, 100%
    operator coverage.
  - Non-CUDA-compatible vendors: vendor C++ operator library integration
    covering the `transformers` / `diffusers` usage range.
- **G3 (torch-fl release):** Publish `torch_fl` wheels for PyTorch 2.8–2.10,
  packaged per vendor (`torch-fl-ascend`, `torch-fl-mx`, ...) to keep the
  bundled libtorch size manageable.
  <!-- TODO: confirm the per-vendor torch-version matrix once vendor official
       support statements are collected. -->
- **G4 (FlagCX / distributed):** `torch.distributed` on the `flagos` device
  backed by FlagCX: standard collectives and DDP working; FSDP investigated
  as a spike, explicitly not committed.

### Non-Goals

- Vendor platforms beyond the 5 named in G1 for this cycle (backends for
  Enflame GCU and Tsingmicro exist in-tree but are not part of the 2.2
  acceptance).
- FSDP support as a deliverable (spike only, per G4).
- Graph-level compilation (`torch.compile`) integration (unchanged from
  v0.1.0 non-goals).
- Operator performance benchmarking as an acceptance gate (correctness-first,
  unchanged from v0.1.0; benchmarks exist in-tree for engineering use).

## Proposal

### Feature 1: 5-Chip Adaptation with Model Validation

Per-vendor accelerator integrations continue the v0.1.0 architecture
(PrivateUse1 dispatch + per-operator backend routing via
`torch_fl/configs/backends_*.conf`). State on main relevant to the five
target chips:

- **Hygon (DCU):** supported via the DTK CUDA-compatibility layer
  (flagos-ai/PyTorch-Plugin-FL#22), FlagGems enabled on DCU (#29).
- **MetaX:** hybrid backend config and platform-aware ops (#13), boxing-mode
  wheel bundling the forked libtorch (README-documented flow), FlagCX
  distributed path fix (#34).
- **Ascend:** native ACL NN dispatch from v0.1.0; triton-ascend patch flow
  for FlagGems (#12).
- **T-Head (PPU):** FlagGems enablement (#28).
- **Moore Threads:** dispatcher enum slot exists (`Backend::kMusa`);
  <!-- TODO: no MUSA backend/config is on main yet — this is net-new work
       this cycle; describe the planned integration path (CUDA-compatible
       boxing vs native). -->

Model validation covers three model classes — LLM, VLM, Omni — tentatively
from the Qwen series, possibly extended to MiniCPM.

### Feature 2: FlagGems Coverage and Vendor Fallback

Two-tier dispatch policy per vendor class:

- **FlagGems first (90%+, ≈380+ ops):** operators route to FlagGems Triton
  kernels via the `flagos` / `flagos_python` backends. The FlagGems C++
  dispatch path (Stage A, #31) reduces Python dispatch overhead.
- **Fallback:**
  - *CUDA-compatible vendors* (Hygon DTK, MetaX MACA, T-Head): reuse
    PyTorch's generated CUDA boxing kernels against the vendor's forked
    libtorch — 100% operator coverage without per-op porting.
  - *Non-CUDA-compatible vendors* (Ascend, ...): integrate the vendor C++
    operator library, scoped to the operator set exercised by
    `transformers` and `diffusers` workloads.

<!-- TODO: how the 90% / 380+ numbers are counted (dispatch-table entries vs
     ops hit by the target models) and where the per-op routing tables are
     published. -->

### Feature 3: torch-fl Package Release

Publish `torch_fl` as installable wheels:

- **PyTorch version range 2.8–2.10.** The earlier 2.11 target is dropped
  because no vendor has shipped an official release supporting it; the final
  per-vendor pin follows vendor support statements.
- **Per-vendor wheels** (`torch-fl-ascend`, `torch-fl-mx`, ...): the bundled
  forked libtorch is large (the MetaX boxing wheel is ~1.1 GB, above the
  PyPI 100 MB limit), so wheels are split by vendor and distributed via
  channels that admit that size.
  <!-- TODO: distribution channel per vendor (private index / release
       assets), and naming/versioning convention (local version segment vs
       package-name suffix). -->

### Feature 4: FlagCX Integration for torch.distributed

Build out `torch_fl/comm/` (process group + `_nccl_ext`) so the `flagos`
device participates in `torch.distributed` with FlagCX as the communication
backend:

- Standard collectives (the base collective set; missing base collectives and
  a FlagCX plain-signature fallback landed in #30).
- DDP training support.
- FSDP: feasibility spike only; findings recorded, support not promised.

<!-- TODO: collective coverage list, process-group registration mechanism,
     and which of the 5 chips are in scope for distributed acceptance
     (FlagCX path validated on MetaX in #34; others TBD). -->

## Design Details

The v0.1.0 architecture (FEP-0025) is unchanged at the core: PrivateUse1
ATen dispatch, `Dispatcher<FnPtr>` per-operator routing, per-platform
accelerator layer. This cycle adds vendor breadth (Feature 1), the boxing /
vendor-library fallback tiers (Feature 2), packaging (Feature 3), and the
distributed layer (Feature 4).

<!-- TODO: design notes per feature before Status moves to `Implementable`,
     including the MUSA integration design and the FSDP spike plan. -->

## Packaging

Feature 3 **is** the packaging deliverable for this cycle: per-vendor wheels
against PyTorch 2.8–2.10 built from the existing `setup.py` flow
(`ACCELERATOR=<vendor>` + per-vendor env flags, `FLAGOS_WHEEL_LOCAL` version
tagging, libtorch bundling via `scripts/bundle_maca_libtorch.sh`-style
scripts where applicable).

Runtime prerequisites per platform follow the repository README (vendor SDK /
toolkit, FlagGems ≥ 5.0.x where the FlagGems path is used).

## Test Plan

**(Required)** Reuses the repository test suites (`tests/`, FlagGems routing
consistency tests #24, CI workflows including the CUDA platform general
workflow #32).

| Goal | Verification | Status |
|---|---|---|
| G1: 5-chip × 3-model | Run the target model list on each of the 5 platforms through the `flagos` device <!-- TODO: model list, inference/training scope, per-platform hardware --> | Pending |
| G2: FlagGems 90%+ | FlagGems routing consistency tests + per-op routing table audit showing ≥90% FlagGems, fallback conf per vendor class | Pending |
| G3: wheels | Install each per-vendor wheel on a clean target machine against torch 2.8/2.9/2.10 and run the smoke path <!-- TODO: exact smoke test --> | Pending |
| G4: FlagCX distributed | Collectives unit tests + DDP training run on FlagCX-backed process group <!-- TODO: platforms, model, node count --> | Pending |

## Related PRs

- [x] flagos-ai/PyTorch-Plugin-FL#22 — Hygon DCU support via DTK CUDA compatibility layer
- [x] flagos-ai/PyTorch-Plugin-FL#29 — Enable FlagGems on Hygon DCU
- [x] flagos-ai/PyTorch-Plugin-FL#28 — PPU FlagGems enablement (+ mul.Tensor recursion fix)
- [x] flagos-ai/PyTorch-Plugin-FL#31 — FlagGems C++ dispatch (kFlagOs) Stage A + 3-way dispatch benchmark
- [x] flagos-ai/PyTorch-Plugin-FL#30 — Missing base collectives + FlagCX plain-signature fallback
- [x] flagos-ai/PyTorch-Plugin-FL#34 — FlagCX distributed path on MetaX
- [x] flagos-ai/PyTorch-Plugin-FL#24 — Full FlagGems routing consistency tests + main_ops CI subset
- [ ] flagos-ai/PyTorch-Plugin-FL#36 — FlagGems factory device index (all backends) + DCU comm vendor routing
- [ ] flagos-ai/PyTorch-Plugin-FL#37 — feat(metax): real device Event + pin_memory in `_to_copy`

## Implementation History

- 2026-07-30: FEP created as `Provisional` for the FlagOS 2.2 cycle, from the
  framework-group 2.2 release plan.

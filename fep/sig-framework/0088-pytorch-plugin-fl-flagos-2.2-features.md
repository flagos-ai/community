# FEP-0088: Torch-FL Features for FlagOS 2.2

**Status:** `Provisional`

**Created:** 2026-07-30

**Owner:** [TODO: @github-username]

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP covers the Torch-FL (`torch_fl`) work planned
for the FlagOS 2.2 release cycle, on top of the v0.1.0 CUDA/Ascend dispatch
foundation delivered in FlagOS 2.1
([FEP-0025](0025-pytorch-plugin-fl-v0.1.0-cuda-dispatch.md)):

1. **Vendor adaptation for 7 chips** — the PyTorch 2.10 line covers Hygon,
   MetaX, Huawei Ascend, T-Head, Moore Threads and Enflame; the PyTorch 2.9
   line covers Kunlunxin. Validation focuses on `transformers` and `diffusers`
   inference and simple fine-tuning workloads.
2. **FlagGems operator-coverage target** — a planned **90%+ / 380+** FlagGems
   operators dispatched through the `flagos` device, with vendor operator
   libraries as the fallback path: CUDA-compatible vendors reuse PyTorch's
   libtorch kernels (100% operator coverage via the boxing approach);
   non-CUDA-compatible vendors integrate the vendor C++ operator library
   covering the operator range used by `transformers` and `diffusers`.
3. **torch-fl package release** — publish installable, per-vendor `torch_fl`
   wheels for the validated PyTorch line. The RC evidence uses PyTorch 2.10
   for six vendors and PyTorch 2.9 for Kunlunxin; it does not establish one
   common 2.8–2.10 matrix for every vendor.
4. **FlagCX integration** — `torch.distributed` on the `flagos` device:
   standard collectives and DDP support, with an FSDP spike (not committed
   for this release).

Repository: https://github.com/flagos-ai/Torch-FL

## Release Boundary and Evidence

- **FlagOS 2.1 baseline:** Torch-FL `v0.1.0`.
- **FlagOS 2.2 release candidate reviewed:** `v0.2.0-rc2.post1`, as pinned by
  the FlagOS 2.2 RC2 manifest.
- **Development window:** 2026-06-01 through 2026-08-31.

The release delta contains vendor backends for Ascend, MetaX, Hygon,
Tsingmicro, Enflame, MUSA and BPU, FlagGems routing/dispatch work, wheel
packaging, FlagCX distributed integration, profiler/AMP work and initial
`torch.compile`/TileOPs support. The development acceptance scope was narrower:
six PyTorch 2.10 vendors plus Kunlunxin on PyTorch 2.9. The internal KT count
is intentionally not used as a public compatibility claim; model support is
described by workload and model architecture instead.

## Motivation

v0.1.0 validated the PrivateUse1 `flagos` device with per-operator backend
routing on CUDA and Ascend. The 2.2 cycle expands the validated scope to seven
chips across the PyTorch 2.10 and 2.9 lines, adds a FlagGems coverage target
with per-vendor-class fallback, per-vendor wheels, and `torch.distributed` via
FlagCX.

### Goals

**(Required)**

- **G1 (7-chip adaptation):** Hygon, MetaX, Huawei Ascend, T-Head, Moore
  Threads and Enflame on PyTorch 2.10, plus Kunlunxin on PyTorch 2.9, run the
  agreed `transformers` / `diffusers` inference and simple fine-tuning set
  through the `flagos` device.
  <!-- TODO: name the exact model list and per-model acceptance (inference
       only, or training too — v0.1.0 validated Qwen3-0.6B both ways). -->
- **G2 (FlagGems coverage target):** The development plan targets 90%+ of
  dispatched operators / approximately 380+ operators routed to FlagGems,
  with fallback to vendor operator libraries. The repository contains routing
  tables and consistency tests, but this FEP does not claim an independently
  reproduced 90% / 380+ release count:
  - CUDA-compatible vendors: libtorch kernel-reuse ("boxing") path, 100%
    operator coverage.
  - Non-CUDA-compatible vendors: vendor C++ operator library integration
    covering the `transformers` / `diffusers` usage range.
- **G3 (torch-fl release):** Publish `torch_fl` wheels for the validated
  PyTorch/vendor pairs, packaged per vendor (`torch-fl-ascend`,
  `torch-fl-mx`, ...) to keep the bundled libtorch size manageable.
  <!-- TODO: confirm the per-vendor torch-version matrix once vendor official
       support statements are collected. -->
- **G4 (FlagCX / distributed):** `torch.distributed` on the `flagos` device
  backed by FlagCX: standard collectives and DDP working; FSDP investigated
  as a spike, explicitly not committed.

### Non-Goals

- Vendor platforms beyond the seven named in G1 for this cycle. Other in-tree
  backends do not automatically become release-accepted platforms.
- FSDP support as a deliverable (spike only, per G4).
- Broad `torch.compile` compatibility as a release gate. Initial support is
  present in the RC delta, but a cross-vendor model matrix is not established.
- Operator performance benchmarking as an acceptance gate (correctness-first,
  unchanged from v0.1.0; benchmarks exist in-tree for engineering use).

## Proposal

### Feature 1: 7-Chip Adaptation with Model Validation

Per-vendor accelerator integrations use the v0.1.0 architecture (PrivateUse1
dispatch + per-operator backend routing via
`torch_fl/configs/backends_*.conf`). The 2.2 acceptance set is:

- **Hygon (DCU):** supported via the DTK CUDA-compatibility layer
(flagos-ai/Torch-FL#22), FlagGems enabled on DCU (#29).
- **MetaX:** hybrid backend config and platform-aware ops (#13), boxing-mode
  wheel bundling the forked libtorch (README-documented flow), FlagCX
  distributed path fix (#34).
- **Ascend:** native ACL NN dispatch from v0.1.0; triton-ascend patch flow
  for FlagGems (#12).
- **T-Head (PPU):** FlagGems enablement (#28).
- **Moore Threads:** PyTorch 2.10 line; the RC delta contains the MUSA backend.
- **Enflame:** PyTorch 2.10 line.
- **Kunlunxin:** PyTorch 2.9 line.

Model validation is reported in terms of Hugging Face model architectures and
the supported workload: `transformers` and `diffusers` inference plus simple
fine-tuning. The development-side KT count is not a public acceptance metric.

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

- **Validated version lines.** PyTorch 2.10 for Hygon, MetaX, Ascend, T-Head,
  Moore Threads and Enflame; PyTorch 2.9 for Kunlunxin. Additional version
  pairs require their own build and acceptance evidence.
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
- FSDP: spike only; findings recorded, support not committed.

<!-- TODO: collective coverage list, process-group registration mechanism,
     and which of the 5 chips are in scope for distributed acceptance
     (FlagCX path validated on MetaX in #34; others TBD). -->

## Design Details

The v0.1.0 core (FEP-0025) is unchanged: PrivateUse1 ATen dispatch,
`Dispatcher<FnPtr>` per-operator routing, per-platform accelerator layer.
This cycle adds the remaining vendor backends (Feature 1), the boxing /
vendor-library fallback tiers (Feature 2), packaging (Feature 3), and the
distributed layer (Feature 4).

<!-- TODO: design notes per feature before Status moves to `Implementable`,
     including the MUSA integration design and the FSDP spike plan. -->

## Packaging

Feature 3 **is** the packaging deliverable for this cycle: per-vendor wheels
for the validated PyTorch/vendor pairs built from the existing `setup.py` flow
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
| G1: 7-chip workload matrix | Run the target `transformers` / `diffusers` inference and simple fine-tuning list on each named PyTorch/vendor pair <!-- TODO: publish exact architecture list and hardware --> | Development validation reported; release matrix pending |
| G2: FlagGems 90%+ | FlagGems routing consistency tests + per-op routing table audit showing ≥90% FlagGems, fallback conf per vendor class | Pending |
| G3: wheels | Install each per-vendor wheel on a clean target machine against its declared PyTorch line and run the smoke path <!-- TODO: exact smoke test --> | Pending |
| G4: FlagCX distributed | Collectives unit tests + DDP training run on FlagCX-backed process group <!-- TODO: platforms, model, node count --> | Pending |

## Related PRs

- [x] flagos-ai/Torch-FL#22 — Hygon DCU support via DTK CUDA compatibility layer
- [x] flagos-ai/Torch-FL#29 — Enable FlagGems on Hygon DCU
- [x] flagos-ai/Torch-FL#28 — PPU FlagGems enablement (+ mul.Tensor recursion fix)
- [x] flagos-ai/Torch-FL#31 — FlagGems C++ dispatch (kFlagOs) Stage A + 3-way dispatch benchmark
- [x] flagos-ai/Torch-FL#30 — Missing base collectives + FlagCX plain-signature fallback
- [x] flagos-ai/Torch-FL#34 — FlagCX distributed path on MetaX
- [x] flagos-ai/Torch-FL#24 — Full FlagGems routing consistency tests + main_ops CI subset
- [x] flagos-ai/Torch-FL#36 — FlagGems factory device index (all backends) + DCU comm vendor routing
- [x] flagos-ai/Torch-FL#37 — feat(metax): real device Event + pin_memory in `_to_copy`

## Implementation History

- 2026-07-30: FEP created as `Provisional` for the FlagOS 2.2 cycle.
- 2026-09-17: Reconciled the FEP with `v0.1.0` and
  `v0.2.0-rc2.post1`. Updated the repository name and seven-chip/version
  scope, replaced the internal KT count with a workload/architecture scope,
  and retained the 90% / 380+ figures as development targets pending a
  reproducible public inventory.

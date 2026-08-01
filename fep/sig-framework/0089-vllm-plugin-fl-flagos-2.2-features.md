# FEP-0089: vLLM-Plugin-FL Features for FlagOS 2.2

**Status:** `Provisional`

**Created:** 2026-07-30

**Owner:** [TODO: @github-username]

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP covers the vllm-plugin-FL work planned for the FlagOS
2.2 release cycle, on top of the v0.2.0 line delivered in FlagOS 2.1
([FEP-0023](0023-vllm-plugin-FL-0.2.0-new-features-nvidia.md)):

1. **Vendor adaptation** — complete adaptation of **10** vendor platforms on
   **vllm-plugin-fl + vLLM 0.20.2**, and upgrade **5** of them to
   **vllm-plugin-fl + vLLM 0.24.0** (Empty mode).
2. **Empty mode** — support vLLM's Empty (device-less build) mode so a single
   vLLM version can serve all platforms, unifying deployment and usage across
   chips.
3. **Operator auto-tuning** — operator-granularity automatic tuning that
   selects the best-performing operator implementation for the hardware
   platform, improving inference performance and reducing manual tuning cost.

Repository: https://github.com/flagos-ai/vllm-plugin-FL

## Motivation

vllm-plugin-FL 0.2.0 established the plugin as a multi-chip vLLM backend on a
single pinned vLLM version. The 2.2 cycle addresses two deployment
needs: a defined adaptation matrix across the vendor platforms (instead of
ad-hoc per-chip status), and a path off per-vendor vLLM forks — vLLM's Empty
build makes the framework itself device-neutral so every platform can share
one vLLM release, with the plugin (FlagGems operators + FlagCX communication
+ vendor dispatch backends) supplying the hardware layer. In addition, with
multiple operator implementations available per op (FlagGems / vendor-native
/ reference), selecting the fastest one per platform manually is costly, so
this cycle adds operator-granularity auto-tuning.

### Goals

**(Required)**

- **G1 (10 vendors on vLLM 0.20.2):** Complete adaptation of 10 vendor
  platforms against vLLM v0.20.2. The repository README currently lists 10
  supported chips: NVIDIA, Ascend, MetaX, T-Head, Iluvatar, Tsingmicro,
  Moore Threads, Hygon, Sunrise, Enflame; in-tree dispatch vendor backends
  exist for ascend / cuda / gcu (Enflame) / hygon / iluvatar / metax / musa /
  sunrise / txda (Tsingmicro), with CUDA-compatible chips (e.g. T-Head)
  reusing the cuda path.
  <!-- TODO: define the per-vendor acceptance bar (which models × which test
       suites must pass on 0.20.2) that "adapted" means for the matrix. -->
- **G2 (5 vendors upgraded to vLLM 0.24.0, Empty mode):** Upgrade 5 vendor
  platforms to vLLM v0.24.0 using the Empty build. In-flight adaptations on
  this track include Moore Threads MTT S5000 (#308) and Iluvatar BI-V150
  (#310).
  <!-- TODO: name the 5 committed vendors. -->
- **G3 (Empty mode support):** The plugin runs against a device-less vLLM
  build ("empty" platform), providing the missing device pieces itself —
  e.g. avoiding `vllm._C` dependencies (#325) and falling back to Triton
  cache ops when vLLM C extensions are absent (#319).
- **G4 (Operator auto-tuning):** Operator-granularity automatic selection of
  the best implementation per hardware platform through the dispatch layer's
  policy mechanism.
  <!-- TODO (design): tuning trigger (offline profiling vs first-run
       autotune), persistence of tuning results, and relationship to the
       existing dispatch policy/config system (vllm_fl/dispatch/policy.py,
       config/). The benchmarks/benchmark_throughput_autotune.py harness
       exists; the runtime selection mechanism is the deliverable. -->

### Non-Goals

- Upgrading all 10 platforms to vLLM 0.24.0 in this cycle (only the 5 named
  in G2; the rest stay on 0.20.2).
- New model enablement beyond what the vendor adaptations require (model
  day-0 support continues as ordinary repository work, not gated by this
  FEP).
- Kernel-level performance work inside FlagGems itself (owned by
  sig-operator; this FEP only selects among existing implementations).

## Proposal

### Feature 1: Vendor Adaptation Matrix (10 on 0.20.2, 5 on 0.24.0)

Adaptation continues the established per-vendor pattern under
`vllm_fl/dispatch/backends/vendor/<vendor>/` (backend class, op
implementations, optional patches), with platform CI validating each vendor.
Representative work already on main or in flight this cycle:

- Ascend: vLLM upgraded to 0.20.2 (#307); Qwen3.6 baseline optimization
  (#301, open).
- MetaX: CI workflow (#304); MoE optimizations and contiguous prefill (#320,
  open); Empty-build fixes (#325, #319, open).
- Moore Threads: MTT S5000 adaptation for vLLM 0.24.0 (#308, open) + S5000 CI
  (#314, open).
- Iluvatar: BI-V150 adaptation for vLLM 0.24.0 (#310, open).
- T-Head: PPU-native DeepGEMM BF16 unquantized MoE (#322, open).
- Hygon: CI image workflow (#311).

The deliverable beyond per-vendor code is the adaptation matrix itself —
which platform is validated on which vLLM version with which model set.

### Feature 2: Empty Mode

vLLM's Empty build compiles the framework without a device backend; the
plugin then supplies platform detection, operators (FlagGems / vendor), and
communication (FlagCX) — so all vendors consume the same vLLM wheel instead
of per-vendor forks. Work involves removing the plugin's residual
assumptions that vLLM's compiled C extensions exist (#325, #319) and
validating the empty path per vendor on the 0.24.0 track.

<!-- TODO (design): how the empty platform is registered/selected, the
     definitive list of vLLM C-extension call sites the plugin must replace,
     and per-vendor empty-mode validation status. -->

### Feature 3: Operator Auto-Tuning

Build on the dispatch system (`vllm_fl/dispatch/`: registry, policy, config)
to select, per operator and per platform, the best implementation among
FlagGems / vendor-native / reference. The existing
`benchmarks/benchmark_throughput_autotune.py` provides the measurement
harness.

<!-- TODO (design): selection granularity (op vs op+shape), where tuning
     results live (config file per platform vs runtime cache), and how a
     tuned config is shipped/reproduced. -->

## Design Details

<!-- TODO: to be filled before Status moves to `Implementable` — Empty-mode
     platform registration design, auto-tuning architecture, and the
     per-vendor 0.24.0 upgrade plan. -->

## Packaging

Unchanged installation model from 0.2.0: `pip install --no-build-isolation .`
on top of an official vLLM release (v0.20.2 track), or on top of the vLLM
Empty build (0.24.0 track, Feature 2). Per-platform container images are
built via the repository `docker/` tooling and platform CI workflows.

<!-- TODO: confirm whether 2.2 ships per-vendor images, a PyPI wheel, or
     both; and the version scheme for the dual 0.20.2/0.24.0 tracks. -->

## Test Plan

**(Required)** Reuses the repository test infrastructure (`tests/unit_tests`,
`tests/functional_tests`, platform YAMLs under `tests/platforms/`, and the
per-vendor CI workflows).

| Goal | Verification | Status |
|---|---|---|
| G1: 10 vendors on 0.20.2 | Per-vendor CI green on the agreed model × test matrix <!-- TODO: matrix definition --> | Pending |
| G2: 5 vendors on 0.24.0 | Same matrix re-run against vLLM 0.24.0 Empty build on the 5 vendors | Pending |
| G3: Empty mode | Plugin installs and serves on a vLLM Empty build with no vllm._C present; smoke inference passes <!-- TODO: reference platform for the empty smoke test --> | Pending |
| G4: Auto-tuning | Tuned config outperforms or matches the default dispatch config on target platforms <!-- TODO: benchmark set, platforms, improvement threshold --> | Pending |

## Related PRs

- [x] flagos-ai/vllm-plugin-FL#307 — upgrade vllm to 0.20.2 on ascend platform
- [x] flagos-ai/vllm-plugin-FL#304 — [CICD] Add MetaX CI workflow
- [x] flagos-ai/vllm-plugin-FL#311 — [CICD] Add Hygon CI image workflow
- [ ] flagos-ai/vllm-plugin-FL#308 — adapt(musa): MTT S5000 backend adaptation for vLLM 0.24.0
- [ ] flagos-ai/vllm-plugin-FL#310 — adapt(iluvatar): BI-V150 backend adaptation for vLLM 0.24.0
- [ ] flagos-ai/vllm-plugin-FL#325 — fix(metax): avoid vllm._C dependency in activation ops for empty builds
- [ ] flagos-ai/vllm-plugin-FL#319 — fix(metax): fall back to Triton cache ops when vllm C extensions are missing
- [ ] flagos-ai/vllm-plugin-FL#322 — WIP: Add PPU-native DeepGEMM BF16 unquantized MoE

## Implementation History

- 2026-07-30: FEP created as `Provisional` for the FlagOS 2.2 cycle.

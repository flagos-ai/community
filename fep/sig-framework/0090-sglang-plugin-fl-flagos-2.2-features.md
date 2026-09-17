# FEP-0090: SGLang-Plugin-FL Features for FlagOS 2.2

**Status:** `Provisional`

**Created:** 2026-07-30

**Owner:** [TODO: @github-username]

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP covers the sglang-plugin-FL work planned for the
FlagOS 2.2 release cycle, on top of v0.1.0 delivered in FlagOS 2.1
([FEP-0024](0024-sglang-plugin-FL-0.1.0-multi-chip-inference-nvidia.md) and
the Ascend/MUSA companions [FEP-0029](0029-sglang-plugin-FL-0.1.0-multi-chip-inference-ascend.md),
[FEP-0030](0030-sglang-plugin-FL-0.1.0-multi-chip-inference-musa.md)):

1. **Vendor adaptation** — complete adaptation of **10** vendor platforms,
   including NVIDIA, Huawei 910C, Moore Threads, T-Head, and MetaX. The
   plugin's SGLang base is **v0.5.11**; Moore Threads builds on **v0.5.12**,
   whose plugin platform API matches v0.5.11 exactly.
2. **Empty mode** — Empty-build adaptation for **3+** vendors (NVIDIA
   included), decoupling the SGLang layer from vendor-specific dependencies.
3. **Testing** — a first full round of plugin-side **unittest,
   function_tests, and e2e tests**, as the foundation for subsequent CI/CD
   pipeline work.

Repository: https://github.com/flagos-ai/sglang-plugin-FL

## Release Boundary and Evidence

- **FlagOS 2.1 baseline:** sglang-plugin-FL `v0.1.0`.
- **FlagOS 2.2 release candidate reviewed:** `v0.2.0-rc2.post1`, as pinned by
  the FlagOS 2.2 RC2 manifest. RC0, RC1 and RC2 are cut from the same release
  snapshot; a later PR merge is therefore not automatically present in RC2.
- **Development window:** 2026-06-01 through 2026-08-31. PRs opened before
  freeze and merged during stabilization are distinguished from work first
  proposed afterward.

The pinned release tree has vendor paths for Ascend, CUDA, Enflame, Hygon,
Iluvatar, Kunlunxin, Moore Threads and Tsingmicro; T-Head uses the
CUDA-compatible route. MetaX #50 remains open. The 2026-08-28 development
review reported vendor adaptation accepted except MetaX, with Empty mode
working on NVIDIA and substantially progressed on Ascend while Moore Threads
continued. This is narrower than claiming every one of ten vendors or three
Empty-mode vendors passed one final release matrix.

## Motivation

v0.1.0 validated the three-layer out-of-tree adaptation architecture (ATen
ops via FlagGems dispatch, SGLang fused kernels via HookRegistry AROUND
hooks, communication via CommunicatorFL on FlagCX) on NVIDIA, Ascend, and
MUSA. The 2.2 cycle extends that architecture to a 10-platform adaptation
matrix, starts the same device-decoupling (Empty) direction as
vllm-plugin-FL so SGLang deployments stop depending on vendor-specific
builds, and establishes the plugin's own test suites — v0.1.0 shipped with
manual verification only — as the foundation for CI/CD.

### Goals

**(Required)**

- **G1 (10-vendor adaptation):** Complete adaptation of 10 vendor platforms
  on SGLang v0.5.11 (Moore Threads on v0.5.12), including NVIDIA, Huawei
  910C, Moore Threads, T-Head, and MetaX. In-tree dispatch vendor backends
  now cover **ascend / cuda / enflame / iluvatar / kunlunxin / mthreads /
  tsingmicro** (7 merged), with T-Head routed through the CUDA-compatible
  path (#27) rather than its own backend directory, and a `template/` vendor
  skeleton for new integrations. Hygon HCU (#35) is merged; MetaX (#50)
  remains open.
  <!-- TODO: per-vendor acceptance bar (models × TP configs × test suites). -->
- **G2 (Empty mode, 3+ vendors):** Adapt the Empty (device-decoupled) build
  path for 3+ vendors including NVIDIA, removing the underlying dependence
  on vendor-specific stacks. PR #43, opened during the development window and
  merged during stabilization, adds
  reference/Triton fallbacks for all fused ops so the plugin runs without
  `sgl_kernel` / `flashinfer` (depends on upstream sgl-project/sglang#31300,
  which adds the `srt_empty` extra for device-agnostic install); #74 enables
  `srt_empty` on Ascend by stubbing absent `sgl_kernel_npu` imports through a
  `sys.meta_path` finder and vendoring the Ascend-only kernels with no
  upstream replacement.
  <!-- TODO: name the 3+ committed vendors and the per-vendor validation
       plan. -->
- **G3 (Test suite):** Deliver a first complete round of plugin-side
  unittest, function_tests, and e2e tests, supporting the subsequent CI/CD
  pipeline. All four tiers are populated —
  `tests/unit_tests` (182 test functions across 23 files: dispatch registry /
  policy / manager, per-op bridge tests, distributed, platform loading),
  `tests/functional_tests` (39, ops correctness + graph capture + collective
  ops), `tests/e2e_tests` (8, inference / serving / concurrent smoke), and
  `tests/benchmarks` (3, latency / throughput / serve). CI runs cuda, ascend,
  musa and T-Head PPU (`.github/configs/platforms.yml`). Hygon DCU #75 was
  opened before freeze and merged during stabilization.
  <!-- TODO: coverage targets per suite and which platforms run per-PR vs
       on-demand. -->

### Non-Goals

- Feature parity with vllm-plugin-FL's operator auto-tuning (not in scope
  for the SGLang plugin this cycle).
- Upstreaming changes into SGLang itself (the plugin remains strictly
  out-of-tree). The one exception is the upstream `srt_empty` extra
  (sgl-project/sglang#31300) that G2 depends on.
- Implementing serving-layer features (router, PD disaggregation) that SGLang
  does not already provide. Making SGLang's existing serving features work on
  FlagOS hardware is in scope — #59 registers a FlagCX KV transfer backend so
  `--disaggregation-transfer-backend flagcx` works without SGLang source
  changes — but the serving logic itself stays upstream's.

## Proposal

### Feature 1: 10-Vendor Adaptation

Vendors integrate through the established pattern — a backend class plus
`register_ops.py` under `sglang_fl/dispatch/backends/vendor/<vendor>/`, with
auto-discovery handling registration; the dispatch system is aligned with
vllm-plugin-FL so vendor op implementations are shared across both plugins.
Base-version policy: SGLang v0.5.11 for the fleet, v0.5.12 for Moore Threads.

Merged this cycle: T-Head CUDA-compatible routing (#27), multi-platform
attention backend support (#28), FlagCX full communication replacement for PP
(#26), FlagCX comm on Ascend/MUSA with platform-aware multinode examples
(#32), CUDA graph on Ascend/MUSA (#31), MUSA PP multi-request hang fix (#36),
Tsingmicro TXDA backend (#33), Kunlunxin backend (#41), Iluvatar backend
(#34), Enflame GCU backend (#42), Ascend PP comm + qwen3-vl vendor patch
(#49), multi-accelerator functional tests (#66), MTP support for Qwen3.6-27B
(#58), CUDA/Ascend/MUSA e2e tests (#37, #57, #54), engine overrides (#62),
FlagGems blacklist YAML configs (#55, #56), and Feishu CI notification (#60).
Merged since the earlier draft: Hygon HCU (#35), the throughput benchmark
(#40), Empty reference fallbacks (#43), FlagCX PD-disaggregation transfer
(#59), T-Head PPU CI (#64), DeviceInfo/early patches (#73), and Hygon DCU CI
(#75). MetaX (#50) and Ascend Empty mode (#74) remain open. PRs merged after
the release snapshot are progress evidence, not automatically part of the
pinned RC2 artifact.

### Feature 2: Empty Mode

Mirror the vllm-plugin-FL direction on the SGLang side: run against a
device-decoupled SGLang install (upstream `srt_empty` extra) where the plugin
supplies the hardware layer (FlagGems ATen ops, dispatch-routed fused
kernels, CommunicatorFL), so one SGLang version serves all platforms. Two
tracks define the work:

- **Reference fallbacks (#43, merged)** — reference/Triton implementations for all
  fused ops (`fused_moe` via SGLang's native Triton MoE Runner,
  `chunk_gated_delta_rule` and the FLA family via SGLang's native Triton FLA
  kernels), so the plugin runs without `vendor.cuda`, i.e. without
  `sgl_kernel` or `flashinfer`, on FlagGems plus SGLang's Triton attention
  backend.
- **Ascend empty (#74, open)** — a `sys.meta_path` stub finder installed from a
  `patch_early.py` hook, so SGLang boots on NPU without `sgl_kernel_npu`:
  the handful of Ascend-only kernels with no upstream replacement
  (`mem_cache.allocator`, `mamba.causal_conv1d`, `fla.fused_gdn_gating`,
  `fla.layernorm_gated`, `fla.fused_sigmoid_gating_recurrent`) are vendored
  into the plugin, and every other submodule resolves to a None-stub so core
  imports succeed.

<!-- TODO (design): name the 3+ committed vendors and the per-vendor
     validation plan; upstream sgl-project/sglang#31300 must land for the
     `srt_empty` install path. -->

### Feature 3: Test Suite for CI/CD

Fill out the three test tiers so CI/CD pipelines have stable signals:

- **unittest** — dispatch registry / policy / manager / call-op / fork-safety
  and per-op bridge tests, plus distributed (communicator, FlagCX), FlagGems
  setup, and platform loading (`tests/unit_tests`, 182 test functions).
- **function_tests** — feature-level tests: op correctness, CUDA graph
  capture, collective ops (`tests/functional_tests`, 39), driven per platform
  by `tests/platforms/*.yaml` with multi-accelerator support from #66 and
  per-platform engine overrides from #62.
- **e2e** — inference / serving / concurrent smoke plus precision alignment
  (`tests/e2e_tests`, 8; `tests/test_precision_align.py`), with benchmarks
  (`tests/benchmarks`, 3) for latency / throughput / serve.

CI is a reusable-workflow pipeline (`_lint`, `_build_wheel`, `_unit_test`,
`_functional_test`, `_e2e_test`, `_benchmark_test`, `_platform_test`) with
per-platform runner configs and Feishu notification (#60). Enabled platforms:
cuda (#37), ascend (#57), musa (#54). The earlier multi-platform attempt (#38)
was closed in favor of this per-platform config model; T-Head PPU (#64) and
Hygon DCU (#75) pipelines now follow the same pattern, and the Enflame GCU
pipeline (#76) was closed.

## Design Details

The three-layer architecture (ATen / fused-kernel hooks / communication) is
unchanged from v0.1.0; this cycle adds vendor breadth, the empty-build
track, and test depth on top of it. Two mechanisms were generalized while
integrating the new vendors:

- **CUDA-compatible vendor routing (#27)** — `CudaBackend.is_available()` no
  longer hardcodes `vendor_name == "nvidia"`; a `_CUDA_COMPATIBLE_VENDORS` set
  lets fully CUDA-compatible chips (T-Head/PPU) resolve to the CUDA op
  implementations without a vendor backend directory of their own.
- **Vendor patch layer** — beyond `register_ops.py`, vendors carry a
  `patch.py` / `patches/` tree for the platform fixes that dispatch cannot
  express (attention-backend selection, PP scheduler behavior, processor and
  model-class shims). #73 consolidates this into a `DeviceInfo` service class
  plus an early-patches mechanism, which the Ascend empty-mode work (#74)
  builds on.

<!-- TODO: to be filled before Status moves to `Implementable` — the final
     10-vendor list and the 3+ empty-mode vendors. -->

## Packaging

Unchanged from v0.1.0: `pip install` of the plugin on top of the pinned
SGLang release (v0.5.11 for most vendors, v0.5.12 for Moore Threads), plus
FlagGems and the vendor runtime stack per platform. Docker images for CI are
built per-platform (`.github/workflows/_build_wheel.yml` publishes wheels;
`docker/{cuda,ascend,mthreads}/containerfile` define per-vendor images with
pinned dependencies). Empty mode work (#43, #74) reduces vendor dependencies,
but a unified install and three-vendor acceptance remain pending upstream and
per-platform validation.

<!-- TODO: whether 2.2 publishes a unified wheel or per-vendor wheels, and
     how the 0.5.11/0.5.12 split is expressed in versioning. -->

## Test Plan

**(Required)** Feature 3 *is* the test-infrastructure deliverable; goals are
verified through it.

| Goal | Verification | Status |
|---|---|---|
| G1: 10-vendor adaptation | Per-vendor function_tests + e2e green on the agreed model set <!-- TODO: model set, TP configs, hardware --> | Development acceptance reported except MetaX; uniform public matrix pending |
| G2: Empty mode 3+ vendors | Plugin serves on the device-decoupled build on each named vendor; smoke inference passes | Reference fallback #43 merged; Ascend #74 open; three-vendor acceptance pending |
| G3: Test suite | unittest / function_tests / e2e suites run green in CI and are wired for additional platforms <!-- TODO: coverage numbers --> | Suites and CUDA/Ascend/MUSA/T-Head pipelines present; Hygon #75 merged during stabilization |

## Related PRs

Vendor adaptation (G1):

- [x] flagos-ai/sglang-plugin-FL#26 — feat: complete FlagCX full communication replacement for PP support
- [x] flagos-ai/sglang-plugin-FL#27 — feat: add thead (T-Head/PPU) CUDA-compatible vendor routing
- [x] flagos-ai/sglang-plugin-FL#28 — feat: multi-platform attention backend support
- [x] flagos-ai/sglang-plugin-FL#31 — feat: enable cuda graph for ascend and musa platforms
- [x] flagos-ai/sglang-plugin-FL#32 — feat: enable FlagCX comm on Ascend / MUSA + platform-aware multinode examples
- [x] flagos-ai/sglang-plugin-FL#33 — feat: add TXDA vendor backend with op implementations and platform support
- [x] flagos-ai/sglang-plugin-FL#34 — feat: add Iluvatar backend for SGLang-FL op dispatch
- [x] flagos-ai/sglang-plugin-FL#36 — [MUSA] Fix/pp multi req hang
- [x] flagos-ai/sglang-plugin-FL#41 — feat: add Kunlunxin (KLX) out-of-tree vendor backend
- [x] flagos-ai/sglang-plugin-FL#42 — feat: add enflame gcu
- [x] flagos-ai/sglang-plugin-FL#49 — [NPU] Add ascend vendor patch for PP comm and qwen3-vl
- [x] flagos-ai/sglang-plugin-FL#55 — [NPU] Maintaining the FlagGems blacklist using YAML configuration
- [x] flagos-ai/sglang-plugin-FL#56 — [MUSA] Maintaining the FlagGems blacklist using YAML configuration
- [x] flagos-ai/sglang-plugin-FL#58 — feat: add MTP (Multi-Token Prediction) support for Qwen3.6-27B
- [x] flagos-ai/sglang-plugin-FL#35 — feat: add hcu vendor
- [ ] flagos-ai/sglang-plugin-FL#50 — Add Metax support
- [ ] flagos-ai/sglang-plugin-FL#51 — fix(flagcx): simplify stream management and fix resource leaks
- [x] flagos-ai/sglang-plugin-FL#73 — refactor: DeviceInfo service class + vendor early-patches mechanism

Hardware enablement for upstream serving features:

- [x] flagos-ai/sglang-plugin-FL#59 — feat(disagg): add FlagCX KV transfer backend for PD disaggregation

Empty mode (G2):

- [x] flagos-ai/sglang-plugin-FL#43 — feat: add empty device support for national platform deployment
- [ ] flagos-ai/sglang-plugin-FL#74 — [NPU] ascend empty support

Test suite and CI (G3):

- [x] flagos-ai/sglang-plugin-FL#37 — ci: add CUDA CI pipeline with lint, build, and test stages
- [x] flagos-ai/sglang-plugin-FL#45 — [CICD] Add cuda CICD test
- [x] flagos-ai/sglang-plugin-FL#54 — [e2e] Feat/musa sglang0516
- [x] flagos-ai/sglang-plugin-FL#57 — [e2e] Feat/ascend npu e2e
- [x] flagos-ai/sglang-plugin-FL#60 — ci(feishu): align Feishu notification with vllm-plugin-FL
- [x] flagos-ai/sglang-plugin-FL#62 — Engine overrides
- [x] flagos-ai/sglang-plugin-FL#66 — support multi-accelerator functional tests
- [x] flagos-ai/sglang-plugin-FL#40 — feat: add end-to-end throughput benchmark script for sglang server
- [x] flagos-ai/sglang-plugin-FL#64 — [e2e] feat(thead): add T-Head PPU (PPU-ZW810E) CI platform
- [x] flagos-ai/sglang-plugin-FL#75 — [e2e] feat(hygon): Hygon DCU (BW1000) CI pipeline

## Implementation History

- 2026-07-30: FEP created as `Provisional` for the FlagOS 2.2 cycle.
- 2026-08-25: Refreshed against the repository — 7 vendor backends merged,
  Ascend/MUSA e2e CI landed, empty-mode split into #43 and #74; base-version
  policy corrected (v0.5.12 is Moore Threads, not T-Head/Kunlunxin).
- 2026-09-17: Reconciled the FEP with `v0.1.0` and
  `v0.2.0-rc2.post1`; updated merged/open PR states, recorded the release-tree
  vendor paths, and kept MetaX plus full three-vendor Empty acceptance open.

# FEP: SGLang-Plugin-FL Features for FlagOS 2.2

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
   plugin's SGLang base is **v0.5.11** (T-Head and Kunlunxin on **v0.5.12**).
2. **Empty mode** — Empty-build adaptation for **3+** vendors (NVIDIA
   included), decoupling the SGLang layer from vendor-specific dependencies.
3. **Testing** — a first full round of plugin-side **unittest,
   function_tests, and e2e tests**, as the foundation for subsequent CI/CD
   pipeline work.

Repository: https://github.com/flagos-ai/sglang-plugin-FL

## Motivation

v0.1.0 proved the three-layer out-of-tree adaptation architecture (ATen ops
via FlagGems dispatch, SGLang fused kernels via HookRegistry AROUND hooks,
communication via CommunicatorFL on FlagCX) on NVIDIA, Ascend, and MUSA. The
2.2 cycle scales that architecture across the vendor fleet to a 10-platform
matrix, starts the same device-decoupling (Empty) direction as
vllm-plugin-FL so SGLang deployments stop depending on vendor-specific
builds, and pays down the testing debt — v0.1.0 shipped with manual
verification; CI/CD needs a real test pyramid to build on.

### Goals

**(Required)**

- **G1 (10-vendor adaptation):** Complete adaptation of 10 vendor platforms
  on SGLang v0.5.11 (T-Head and Kunlunxin based on v0.5.12), including
  NVIDIA, Huawei 910C, Moore Threads, T-Head, and MetaX. In-tree dispatch
  vendor backends currently cover ascend / cuda / mthreads / tsingmicro
  (with T-Head routed CUDA-compatible, #27); Iluvatar (#34), Kunlunxin
  (#41), Enflame GCU (#42), Hygon HCU (#35), and MetaX (#50) are open PRs.
  <!-- TODO: name all 10 committed vendors and the per-vendor acceptance bar
       (models × TP configs × test suites). -->
- **G2 (Empty mode, 3+ vendors):** Adapt the Empty (device-decoupled) build
  path for 3+ vendors including NVIDIA, removing the underlying dependence
  on vendor-specific stacks (#43 starts this: empty device support for
  national platform deployment).
  <!-- TODO: define what the SGLang-side Empty build consists of (which
       sgl_kernel / flashinfer dependencies are replaced by what), and name
       the 3+ vendors. -->
- **G3 (Test suite):** Deliver a first complete round of plugin-side
  unittest, function_tests, and e2e tests, supporting the subsequent CI/CD
  pipeline. The repository test skeleton exists
  (`tests/{unit_tests,functional_tests,e2e_tests,benchmarks}`, precision
  alignment, platform YAMLs); CUDA CI landed in #45.
  <!-- TODO: coverage targets per suite and which platforms run in CI vs
       on-demand. -->

### Non-Goals

- Feature parity with vllm-plugin-FL's operator auto-tuning (not in the 2.2
  plan for the SGLang plugin).
- Upstreaming changes into SGLang itself (the plugin remains strictly
  out-of-tree).
- Serving-layer features (router, disaggregation) beyond what SGLang v0.5.11
  provides natively.

## Proposal

### Feature 1: 10-Vendor Adaptation

Vendors integrate through the established pattern — a backend class plus
`register_ops.py` under `sglang_fl/dispatch/backends/vendor/<vendor>/`, with
auto-discovery handling registration; the dispatch system is aligned with
vllm-plugin-FL so vendor op implementations are shared across both plugins.
Base-version policy: SGLang v0.5.11 for the fleet, v0.5.12 for T-Head and
Kunlunxin.

Landed this cycle: Tsingmicro TXDA backend (#33), T-Head CUDA-compatible
routing (#27), multi-platform attention backend support (#28), CUDA graph on
Ascend/MUSA (#31), FlagCX full communication replacement for PP (#26) and
FlagCX comm on Ascend/MUSA (#32), MUSA PP multi-request hang fix (#36).
In review: Iluvatar (#34), Hygon HCU (#35), Kunlunxin (#41), Enflame GCU
(#42), MetaX (#50), Ascend PP comm + qwen3-vl vendor patch (#49).

### Feature 2: Empty Mode

Mirror the vllm-plugin-FL direction on the SGLang side: run against a
device-decoupled SGLang install where the plugin supplies the hardware layer
(FlagGems ATen ops, dispatch-routed fused kernels, CommunicatorFL), so one
SGLang version serves all platforms. #43 (empty device support for national
platform deployment) is the opening PR on this track.

<!-- TODO (design): dependency inventory (sgl_kernel, flashinfer, NCCL) and
     the replacement for each in empty mode; per-vendor validation plan. -->

### Feature 3: Test Suite for CI/CD

Fill out the three test tiers so CI/CD pipelines have stable signals:

- **unittest** — dispatch/registry/policy and op-level tests
  (`tests/unit_tests`).
- **function_tests** — feature-level tests (attention backends, CUDA graph,
  PP/TP communication) per platform (`tests/functional_tests`,
  `tests/platforms/*.yaml`).
- **e2e** — model serving smoke and precision alignment
  (`tests/e2e_tests`, `tests/test_precision_align.py`), extending the CUDA
  CI (#45) to more platforms (multi-platform pipeline attempt: #38, closed;
  successor TBD).

## Design Details

The three-layer architecture (ATen / fused-kernel hooks / communication) is
unchanged from v0.1.0; this cycle adds vendor breadth, the empty-build
track, and test depth on top of it.

<!-- TODO: to be filled before Status moves to `Implementable` — empty-mode
     dependency replacement design and the final vendor list. -->

## Packaging

Unchanged from v0.1.0: `pip install` of the plugin on top of the pinned
SGLang release (v0.5.11 / v0.5.12 per G1), plus FlagGems and the vendor
runtime stack per platform.

<!-- TODO: whether 2.2 publishes a wheel / per-vendor images, and how the
     dual 0.5.11/0.5.12 base is expressed in versioning. -->

## Test Plan

**(Required)** Feature 3 *is* the test-infrastructure deliverable; goals are
verified through it.

| Goal | Verification | Status |
|---|---|---|
| G1: 10-vendor adaptation | Per-vendor function_tests + e2e green on the agreed model set <!-- TODO: model set, TP configs, hardware --> | Pending |
| G2: Empty mode 3+ vendors | Plugin serves on the device-decoupled build on each named vendor; smoke inference passes | Pending |
| G3: Test suite | unittest / function_tests / e2e suites exist, run green on CUDA CI, and are wired for additional platforms <!-- TODO: coverage numbers --> | Pending |

## Related PRs

- [x] flagos-ai/sglang-plugin-FL#33 — feat: add TXDA vendor backend with op implementations and platform support
- [x] flagos-ai/sglang-plugin-FL#27 — feat: add thead (Thead/PPU) CUDA-compatible vendor routing
- [x] flagos-ai/sglang-plugin-FL#28 — feat: multi-platform attention backend support
- [x] flagos-ai/sglang-plugin-FL#31 — feat: enable cuda graph for ascend and musa platforms
- [x] flagos-ai/sglang-plugin-FL#26 — feat: complete FlagCX full communication replacement for PP support
- [x] flagos-ai/sglang-plugin-FL#32 — feat: enable FlagCX comm on Ascend / MUSA + platform-aware multinode examples
- [x] flagos-ai/sglang-plugin-FL#45 — [CICD] Add cuda CICD test
- [ ] flagos-ai/sglang-plugin-FL#34 — feat: add Iluvatar backend for SGLang-FL op dispatch
- [ ] flagos-ai/sglang-plugin-FL#35 — feat: add hcu vendor
- [ ] flagos-ai/sglang-plugin-FL#41 — feat: add Kunlunxin (KLX) out-of-tree vendor backend
- [ ] flagos-ai/sglang-plugin-FL#42 — feat: add enflame gcu
- [ ] flagos-ai/sglang-plugin-FL#43 — feat: add empty device support for national platform deployment
- [ ] flagos-ai/sglang-plugin-FL#49 — [NPU] Add ascend vendor patch for PP comm and qwen3-vl
- [ ] flagos-ai/sglang-plugin-FL#50 — Add Metax support

## Implementation History

- 2026-07-30: FEP created as `Provisional` for the FlagOS 2.2 cycle, from the
  framework-group 2.2 release plan.

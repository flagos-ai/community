# FEP-0086: Megatron-LM-FL New Features for FlagOS 2.2

**Status:** `Provisional`

**Created:** 2026-07-30

**Owner:** [TODO: @github-username]

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP covers the Megatron-LM-FL features planned for the
FlagOS 2.2 release cycle, on top of v0.2.0:

1. **Vendor adaptation** — complete platform adaptation for 10 chip vendors
   with a published adaptation matrix; push the platform abstraction layer
   toward upstream Megatron-LM adoption.
2. **[Stretch] Upstream upgrade** — synchronize with Megatron-LM core v0.18.2
   (current: 0.17.1).
3. **New model support** — Qwen3.5/3.6 and DeepSeek-V4 next-generation model
   support, including the related colocated training and CSA/HCA/DSA core
   modules and optimization strategies.

Repository: https://github.com/flagos-ai/Megatron-LM-FL

## Motivation

Megatron-LM-FL is the multi-vendor training backend of FlagOS. The 2.2 cycle
extends the platform plugin system established in v0.2.0 (FEP-0026: NPU, TXDA
backends and multi-vendor dispatch) toward full 10-vendor coverage with a
verifiable adaptation matrix, and keeps model coverage current with the
next-generation MoE/sparse-attention architectures (Qwen3.5/3.6,
DeepSeek-V4-family) that FlagOS users train.

### Goals

**(Required)**

- **G1 (Vendor adaptation):** Complete platform adaptation for 10 chip
  vendors on the `megatron/plugin/platform/` plugin system, and publish an
  adaptation matrix documenting per-vendor supported features and test status.
  In-tree platform backends today: CUDA, MUSA, NPU (Ascend), TXDA
  (Tsingmicro), Kunlunxin, Enflame.
  <!-- TODO: name the remaining vendors to reach 10; define the matrix
       dimensions (models × parallelism modes × precision?) and where it is
       published. -->
- **G2 (Upstream platform abstraction):** Drive the platform abstraction
  merge into upstream NVIDIA Megatron-LM.
  <!-- TODO: define the acceptance form — upstream PR(s) opened? merged?
       RFC accepted? -->
- **G3 (Stretch — core upgrade):** Upgrade the Megatron-LM core base from
  0.17.1 to v0.18.2, preserving all FL patches (platform plugin, overrides,
  dualpipev, hetero, engram).
- **G4 (New models):** Support Qwen3.5/3.6 and DeepSeek-V4 model training,
  including the related colocated training capability and CSA/HCA/DSA core
  modules and optimization strategies.
  <!-- TODO: DeepSeek-V4 base support (CSA/HCA, Hash Router, mHC, Engram,
       MTP) shipped in v0.2.0 (FEP-0026) — specify the 2.2 increment: DSA
       attention variant and fused kernels? context parallelism for sparse
       attention? colocated training? GLM5.x-family DSA models? -->

### Non-Goals

<!-- TODO: confirm/extend. -->

- Low-precision (FP8/INT8) training for the new model families.
- Inference optimization for the new models (FlagScale / inference-plugin
  scope).

## Proposal

### Feature 1: Vendor Adaptation to 10 Platforms

Extend the platform plugin system (`platform_base.py` / `platform_register.py`
/ `platform_manager.py`, one `platform_<vendor>.py` per backend) from the
current six chip backends (CUDA, MUSA, NPU, TXDA, Kunlunxin, Enflame) to 10
vendors, and publish an adaptation matrix.

Related work already on main: KunLunXin platform support
(flagos-ai/Megatron-LM-FL#63) with core patches migrating to the override
mechanism (#74), Enflame backend (#45), TXDA platform upgraded to core 0.17.0
(#87), Ascend native MegatronAdaptor integration (#68).

<!-- TODO (design): list the 4+ new vendors and for each — platform plugin
     vs. override-based adaptation; vendor operator library dependencies;
     CI coverage (cf. #92 MUSA CI, #93 Hygon BW1000 CI). -->

### Feature 2: Platform Abstraction Upstreaming

Push the platform abstraction (vendor-neutral device/platform dispatch layer)
into upstream NVIDIA Megatron-LM, so that FL platform plugins can attach to
upstream releases without carrying a fork-wide patch set.

<!-- TODO (design): which abstraction interfaces are proposed upstream; link
     to the upstream RFC/PR once opened. -->

### Feature 3: Megatron-LM Core v0.18.2 Upgrade [Stretch]

Synchronize the core with upstream v0.18.2 following the established sync
process (cf. #34 for the 0.17.0 sync, #42 upgrade skills), preserving FL
patches: platform plugin, override registry, dualpipev, hetero pipeline,
engram, and the experimental attention variants.

### Feature 4: New Model Support (Qwen3.5/3.6, DeepSeek-V4 family)

Add training support for Qwen3.5/3.6 and the DeepSeek-V4 model family,
covering the colocated training capability and the CSA/HCA/DSA attention
modules with their optimization strategies. Related in-flight work: DSA
attention variant and fused kernels (`experimental_attention_variant/dsa.py`,
#86 fused DSA kernel for sm90, #88 FlashSparseAttention, #81 flash sparse
attn patch), context parallel support for DSV4 sparse attention (#57),
GLM5/5.1/5.2 DSA-structure models (#69).

<!-- TODO (design):
     1. Qwen3.5/3.6 — architecture deltas vs. Qwen3 (MoE config, attention),
        checkpoint conversion path, target parallelism configs.
     2. Colocated — what is colocated with what (training+inference for RL?),
        and which scheduler/memory changes it needs.
     3. DSA/FSA — which variants land in this cycle and on which platforms
        (fused kernels are sm90-specific today). -->

## Design Details

<!-- TODO: to be filled before Status moves to `Implementable`. -->

## Packaging

Installed from source; no wheel is published for Megatron-LM-FL.

```bash
git clone https://github.com/flagos-ai/Megatron-LM-FL.git
cd Megatron-LM-FL
git checkout <release branch for FlagOS 2.2>
pip install -e .
```

**Supported vendors:** [TODO: final 10-vendor list with per-vendor
toolkit/driver requirements — this is the adaptation matrix from G1.]

Base image: FlagOS 2.2 training image (per-vendor variant).

## Test Plan

**(Required)** Reuses the in-repo test infrastructure: `tests/unit_tests`
(torchrun + pytest), `tests/functional_tests` (per-model test cases with
golden values), and the multi-platform CI workflows.

### G1: Vendor adaptation matrix

| Test | Command | Expected result |
|---|---|---|
| Per-vendor unit tests | `torchrun --nproc_per_node=8 -m pytest tests/unit_tests -v` on each vendor platform <!-- TODO: per-vendor subset/markers if full suite is not applicable --> | Pass on all 10 platforms per the matrix |
| Per-vendor functional tests | `tests/functional_tests` model cases per vendor <!-- TODO: which model cases gate which vendor --> | Loss curves match golden values within tolerance |

### G2: Upstream platform abstraction

| Test | Command | Expected result |
|---|---|---|
| Upstream milestone | — | [TODO: upstream PR link and its acceptance state] |

### G3: Core v0.18.2 upgrade [stretch]

| Test | Command | Expected result |
|---|---|---|
| Full unit suite post-sync | `torchrun --nproc_per_node=8 -m pytest tests/unit_tests -v` | Pass; no FL-patch regressions |
| Benchmark gate | Qwen3 TP2/PP2 functional benchmark (CI gate) | Throughput/elapsed within regression thresholds |

### G4: New model support

| Test | Command | Expected result |
|---|---|---|
| DSA attention unit tests | `torchrun --nproc_per_node=8 -m pytest tests/unit_tests/transformer/experimental_attention_variant -v` | All pass |
| Qwen3.5/3.6 training | <!-- TODO: functional test case / pretrain command with target parallelism config --> | Training runs; loss matches golden values |
| DeepSeek-V4-family training (incl. colocated) | <!-- TODO: functional test case / command --> | Training runs; loss matches golden values |

## Related PRs

- [x] flagos-ai/Megatron-LM-FL#63 — Add KunLunXin platform support
- [x] flagos-ai/Megatron-LM-FL#74 — Migrate remaining XME core patches to KunLunXin overrides
- [x] flagos-ai/Megatron-LM-FL#45 — Add the Enflame backend
- [x] flagos-ai/Megatron-LM-FL#87 — Upgrade TXDA Platform to v0.17.0
- [x] flagos-ai/Megatron-LM-FL#68 — Native Integration of MegatronAdaptor (Ascend)
- [ ] flagos-ai/Megatron-LM-FL#57 — Add context parallel support for dsv4 sparse attention
- [ ] flagos-ai/Megatron-LM-FL#69 — Support models with DSA structure (GLM5/5.1/5.2)
- [x] flagos-ai/Megatron-LM-FL#86 — Add fused DSA kernel for sm90
- [ ] flagos-ai/Megatron-LM-FL#88 — Add support for FlashSparseAttention

## Implementation History

- 2026-07-30: FEP created as `Provisional` for the FlagOS 2.2 cycle.

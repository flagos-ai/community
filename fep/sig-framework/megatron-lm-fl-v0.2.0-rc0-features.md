# FEP-NNNN: Megatron-LM-FL v0.2.0-rc0 Features

**Status:** `Provisional`

**Created:** 2026-05-26

**Owner:** @zhaoyinglia, @lxd-cumt, @Darryl233, @xmhubj

**SIG:** sig-framework

**Target Version:** FlagOS 2.1

---

## Summary

**(Required)** This FEP covers the features and improvements delivered in Megatron-LM-FL between commits `e6afd8e7` and `77a74339`, including:

1. **DeepSeek V4 model support** — full training support for DeepSeek V4 architecture (CSA/HCA, Hash Router, mHC, Engram, MTP).
2. **TXDA platform adaptation** — new hardware backend for Tsingmicro chips.
3. **NPU platform adaptation** — new hardware backend for Ascend NPU.
4. **Multi-vendor plugin dispatch** — runtime vendor selection via `MG_FL_PREFER` environment variable.
5. **Core upgrade to Megatron-LM Core 0.17.0** — upstream synchronization with FlagScale patches preserved.
6. **CI/CD enhancements** — multi-platform unit/functional tests, lint gate, benchmark gate (Qwen3), coverage reporting.
7. **Bug fixes** — Engram loss/param-norm fixes, FlagScale annotation completeness, DDP gradient scaling.

Repository: [Megatron-LM-FL](https://github.com/flagos-ai/Megatron-LM-FL)

## Motivation

FlagOS 2.1 requires Megatron-LM-FL to support next-generation model architectures (DeepSeek V4), broaden hardware coverage (TXDA, NPU), and improve multi-vendor extensibility for domestic chip ecosystems. The CI/CD and code-quality improvements ensure these features are continuously validated across CUDA, MetaX, TXDA, and NPU platforms.

### Goals

**(Required)**

- Enable end-to-end training of DeepSeek V4 models with CSA, HCA, Hash Router, Multi-Head Hyper-Connection (mHC), and Engram support.
- Add NPU (Ascend) and TXDA (Tsingmicro) as first-class platform backends alongside CUDA and MetaX (MUSA).
- Provide runtime multi-vendor dispatch so different chip vendors can register and select their own operator implementations.
- Upgrade Megatron core to 0.17.0 while preserving all FlagScale-specific patches (engram, hetero pipeline, platform plugin, etc.).
- Establish CI benchmark gates (Qwen3 TP2/PP2) with throughput and elapsed-time regression checks.
- Achieve pylint score >= 9.0 via automated lint gate.

### Non-Goals

- DeepSeek V4 inference optimization (out of scope for this cycle).
- Low-precision (FP8/INT8) training for DeepSeek V4 (resource-limited, deferred).
- Context parallelism for sparse attention (future work).
- Muon optimizer with Zero-1 adaptation (in progress, tracked separately).

## Proposal

### 1. DeepSeek V4 Support

Port DeepSeek V4 architecture modules from the Megatron-LM dev branch into Megatron-LM-FL:
- **CSA (Compressed Sparse Attention)** and **HCA** attention variants.
- **Hash Router** for MoE token routing.
- **Multi-Head Hyper-Connection (mHC)** for residual connections.
- **Engram** auxiliary memory module (optional).
- **Multi-Token Prediction (MTP)** enhancements.
- New fused kernels: `fused_mhc_kernels`, extended `fused_mla_yarn_rope_apply`.

Related PRs: #38, #47.

### 2. TXDA Platform Backend (Tsingmicro)

Add `platform_txda.py` to `megatron/plugin/platform/`, providing Tsingmicro chip support. Includes optimizer and pipeline schedule adaptations for the TXDA hardware. Registered via `platform_register.py` and managed by `platform_manager.py`.

Related PR: #22.

### 3. NPU Platform Backend

Add `platform_npu.py` to `megatron/plugin/platform/`, following the existing CUDA/MUSA pattern. Registered via `platform_register.py` and managed by `platform_manager.py`.

Related PR: #44.

### 4. Multi-Vendor Plugin Dispatch

Extend the `@override` decorator system:
- Refactor `_plugin_registry` to `dict[str, dict[str, Callable]]` (method -> vendor -> impl).
- Four-level fallback: preferred vendor -> default vendor -> sole vendor -> None.
- Runtime selection via `MG_FL_PREFER` env var (integrates with FlagScale YAML config `mg_fl_prefer`).

Related PR: #27.

### 5. Core 0.17.0 Upgrade

Merge upstream Megatron-LM Core 0.17.0 (`fa4908745`), restoring FlagScale-specific patches:
- Engram DDP buffer separation.
- Hetero pipeline support.
- `qk_layernorm_hidden_dim` support.
- `cur_platform` abstraction replacing `torch.cuda` in 22+ core files.
- 15 FlagScale-specific fields added to `TransformerConfig`.

Related PR: #34.

### 6. CI/CD Enhancements

- **Unit tests**: dual-backend (CUDA + MetaX) execution with coverage upload to FlagCICD.
- **Functional tests**: GPT inference, GRPO, mock-data cases; Qwen3 benchmark gate with A100 golden values.
- **Lint gate**: pylint >= 9.0 via `lint_common.yml`.
- **Workflow simplification**: consolidated from 20+ workflows; BAAI runner support for MetaX.

Related PRs: #23, #28, #29, #37.

### 7. Bug Fixes

- Engram: fix param buffer assignment for independent optimizer, fix incorrect param norm calculation (#24).
- Engram: add `engram_embedding_gradient_scaling_factor` initialization for `per_token_loss` mode (#39).
- FlagScale annotations: add missing `FlagScale Begin/End` markers across 81 files in `megatron/core` (#40).

## Design Details

See individual PR descriptions for implementation-level details:
- DeepSeek V4: 40 files changed, ~8300 lines added. Key modules: `csa.py`, `deepseek_v4_hybrid_attention.py`, `hyper_connection.py`, `engram.py`, `fused_mhc_kernels.py`.
- NPU: 3 files, 316 lines. Self-contained platform plugin.
- Multi-vendor dispatch: 3 files, 398 lines. Backwards-compatible decorator extension.

## Packaging

**(Required)**

- **Base image**: FlagOS 2.1 官方训练镜像（CUDA / MetaX / NPU 对应变体，具体地址待确认）
- **Build & install**:
  ```bash
  git clone https://github.com/flagos-ai/Megatron-LM-FL.git
  cd Megatron-LM-FL
  git checkout release/v0.2.0-rc0
  pip install -e .
  ```
- **Packaging format**: Python pip editable install（或 `pip wheel . --no-deps -w dist/` 产出 `.whl`）
- **Platform requirements**:
  - Python >= 3.10
  - PyTorch >= 2.3
  - CUDA >= 12.1 (NVIDIA GPU), or MUSA SDK (MetaX), or CANN 8.0+ (NPU)
  - TransformerEngine (optional, for TE-accelerated layers)

## Test Plan

**(Required)**

### Image Acquisition

- **Base image**: FlagOS 2.1 training image (CUDA variant or MetaX variant as applicable).
- **Source**: Internal container registry or `docker pull` from FlagOS CI.

### Package Installation

```bash
git clone https://github.com/flagos-ai/Megatron-LM-FL.git
cd Megatron-LM-FL
git checkout release/v0.2.0-rc0
pip install -e .
```

### Functional Verification

#### DeepSeek V4 Training

- **Modules**: `megatron/core/transformer/` (CSA, HCA, mHC, Engram, MTP), `megatron/core/transformer/moe/` (Hash Router)
- **Test commands**:
  ```bash
  # Unit tests for CSA attention variant
  torchrun --nproc_per_node=8 -m pytest tests/unit_tests/transformer/experimental_attention_variant/test_attention_variant_csa.py -v

  # Unit tests for DSV4 hybrid attention
  torchrun --nproc_per_node=8 -m pytest tests/unit_tests/transformer/experimental_attention_variant/test_dsv4_hybrid_attention.py -v

  # Unit tests for MTP
  torchrun --nproc_per_node=8 -m pytest tests/unit_tests/transformer/test_multi_token_prediction.py -v -k "not TestMultiTokenPredictionMamba"

  # Unit tests for MoE routers (hash router)
  torchrun --nproc_per_node=8 -m pytest tests/unit_tests/transformer/moe/test_routers.py -v

  # Unit tests for fused kernels
  torchrun --nproc_per_node=8 -m pytest tests/unit_tests/fusions/test_mla_yarn_rope_apply.py -v
  torchrun --nproc_per_node=8 -m pytest tests/unit_tests/fusions/test_swiglu_fusion.py -v

  # Unit tests for dualpipev
  torchrun --nproc_per_node=8 -m tests/unit_tests/a2a_overlap/test_schedule_dualpipev.py -v
  ```
- **Expected results**: All tests pass with exit code 0.

#### NPU Platform/TXDA Platform (Tsingmicro)/...

- **Modules**: `megatron/plugin/platform/platform_npu.py`
- **Modules**: `megatron/plugin/platform/platform_txda.py`
- **Test commands**:
  ```bash
  python -m pytest megatron/plugin/tests/test_platform.py -v
  ```
- **Expected results**: NPU platform is detected and registered on Ascend hardware.
- **Compatibility**: Ascend 910B / CANN 8.0+

#### Multi-Vendor Plugin Dispatch

- **Modules**: `megatron/plugin/decorators.py`
- **Test commands**:
  ```bash
  python -m pytest megatron/plugin/tests/test_override_manager.py -v
  ```
- **Expected results**: All 15+ test cases pass, covering registration, selection, fallback, and case-insensitive matching.

#### E2E benchmark Test
.megatron-lm-fl+te-fl-e2e-test.md

### Existing CI Validation

```bash
# Full unit test suite (CUDA)
python -m pytest tests/unit_tests/ -v

# Lint check
pylint megatron/ --score=y  # must be >= 9.0
```

## Related PRs

- [x] flagos-ai/Megatron-LM-FL#22 — Add TXDA platform (Tsingmicro)
- [x] flagos-ai/Megatron-LM-FL#23 — Enable CUDA & MetaX unit tests; Sync upstream core updates
- [x] flagos-ai/Megatron-LM-FL#24 — Fix engram loss and log param norm bugs
- [x] flagos-ai/Megatron-LM-FL#27 — Add multi-vendor dispatch support to plugin override system
- [x] flagos-ai/Megatron-LM-FL#28 — Upload unittest coverage report to FlagCICD platform
- [x] flagos-ai/Megatron-LM-FL#29 — Simplified workflows, add lint_check & functional_tests
- [x] flagos-ai/Megatron-LM-FL#34 — Synchronization with Megatron-LM Core 0.17.0
- [x] flagos-ai/Megatron-LM-FL#37 — Add Qwen3 benchmark gate for functional tests
- [x] flagos-ai/Megatron-LM-FL#38 — DeepSeek V4 Support
- [x] flagos-ai/Megatron-LM-FL#39 — Add engram_embedding_gradient_scaling_factor
- [x] flagos-ai/Megatron-LM-FL#40 — Fix missing FlagScale annotations
- [x] flagos-ai/Megatron-LM-FL#44 — Add NPU platform
- [x] flagos-ai/Megatron-LM-FL#47 — Fix bug of DeepSeek V4 support

## Implementation History

- 2026-03-25: TXDA platform (Tsingmicro) added (#22)
- 2026-04-02: CUDA & MetaX unit tests enabled (#23)
- 2026-04-03: Multi-vendor plugin dispatch merged (#27)
- 2026-04-13: Engram bug fixes merged (#24); Coverage reporting added (#28)
- 2026-04-24: CI workflow simplification and functional tests (#29)
- 2026-04-30: Core 0.17.0 upgrade merged (#34)
- 2026-05-11: Qwen3 benchmark gate added (#37)
- 2026-05-12: FlagScale annotations fixed (#40)
- 2026-05-18: Engram gradient scaling factor fix (#39)
- 2026-05-20: NPU platform added (#44)
- 2026-05-24: DeepSeek V4 support merged (#38)
- 2026-05-25: DeepSeek V4 bug fix (#47)

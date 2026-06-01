# FEP-NNNN: verl-FL v0.2.0 Features

**Status:** `Provisional`

**Created:** 2026-06-01

**Owner:** @heavyrain-lzy,@physics31415926

**SIG:** sig-framework

**Target Version:** FlagOS 2.1

---

## Summary

**(Required)** This FEP covers the features and improvements delivered in verl-FL v0.2.0, including:

1. **Unified platform abstraction layer** — Strategy Pattern platform abstraction under `verl/plugin/platform/` to decouple the codebase from hard-coded `torch.cuda` calls, enabling support for CUDA, Ascend NPU, MetaX (MACA), Moore Threads (MUSA), CPU, and future accelerators (XPU, ROCm, MLU, etc.).
2. **FlagOS training engine integration** — Use `vllm-plugin-FL` and `TransformerEngine-FL` / `Megatron-LM-FL` as backends to support multi-chip GRPO training.
3. **Megatron-LM-FL version compatibility fix** — Fix mcore version checking for `Megatron-LM-FL` versioning format (`xxx+megatronxxx`).
4. **MetaX platform support** — Training validation on MetaX hardware via MACA software stack.
5. **Moore Threads MUSA platform support** — Heterogeneous CUDA+MUSA distributed training via FlagCX communication backend.

Repository: [verl-FL](https://github.com/flagos-ai/verl-FL)

## Motivation

FlagOS 2.1 requires verl-FL to support multi-chip RLHF/GRPO training across domestic hardware ecosystems. The upstream verl project is tightly coupled to CUDA, making it difficult to run on Ascend NPU, MetaX (MACA), Moore Threads (MUSA), or other accelerators. verl-FL introduces a platform abstraction layer and integrates FlagOS ecosystem components (vllm-plugin-FL, TransformerEngine-FL, Megatron-LM-FL, FlagCX) to enable heterogeneous distributed training without modifying upstream business logic.

### Goals

**(Required)**

- Introduce a unified platform abstraction layer (`PlatformBase` ABC) with concrete implementations for CUDA, NPU, MetaX (MACA), MUSA, and CPU.
- Integrate `vllm-plugin-FL` and `Megatron-LM-FL`/`TransformerEngine-FL` as pluggable backends for rollout and training engines.
- Enable end-to-end GRPO training of Qwen3 models on FlagOS-supported hardware.
- Support heterogeneous distributed training across NVIDIA GPU and Moore Threads MUSA nodes using FlagCX as the unified communication backend.
- Fix compatibility issues with Megatron-LM-FL versioning format.
- Validate on MetaX hardware with MACA software stack.

### Non-Goals

- Full inference optimization on non-CUDA platforms (handled by vllm-plugin-FL).
- Support for all verl training recipes on all platforms (incremental rollout).
- Upstream contribution of platform abstraction to verl-project (planned for next phase).

## Proposal

### 1. Unified Platform Abstraction Layer

Introduce a Strategy Pattern platform abstraction under `verl/plugin/platform/`:

- **`platform_base.py`** — `PlatformBase` ABC defining 16 device-agnostic methods (device allocation, memory management, stream operations, distributed init, etc.).
- **`platform_cuda.py`** — CUDA platform with FlagCX auto-detection.
- **`platform_npu.py`** — Ascend NPU platform implementation.
- **`platform_musa.py`** — Moore Threads MUSA platform with FlagCX auto-detection.
- **`platform_cpu.py`** — CPU fallback platform for testing.
- **`platform_manager.py`** — Singleton manager with `VERL_PLATFORM` env var override for runtime platform selection.

Replace all scattered `torch.cuda.*` calls in business logic with the platform API.

Related PR: #8 (commits from PR #2 in the repo).

### 2. FlagOS Training Engine Integration

Add a training engine based on FlagOS to support multiple chips:

- **`verl/plugin/engine/fsdp_fl/`** — FSDP training engine using TransformerEngine-FL.
- **`verl/plugin/engine/megatron_fl/`** — Megatron training engine using Megatron-LM-FL.
- **`verl/plugin/configs/vllm_plugin_fl_dispatch.yaml`** — vllm-plugin-FL dispatch configuration.
- **`examples/grpo_trainer/run_qwen3-0.6b_fl.sh`** — Example script for Qwen3-0.6B GRPO training on FlagOS.

Related PR: #8 (commits from PR #1 in the repo).

### 3. Megatron-LM-FL Version Compatibility

Fix the error when checking mcore version because the version of `Megatron-LM-FL` uses the format `xxx+megatronxxx` (e.g., `0.1.0+megatron0.15.rc7`). Add a utility function in `verl/models/mcore/util.py` to parse this format correctly.

Related PR: #9.

### 4. MetaX Platform Support

Validate verl-FL training on MetaX hardware via MACA software stack. The platform abstraction layer enables MetaX devices to be used as training accelerators through the existing plugin system, leveraging FlagOS ecosystem components (TransformerEngine-FL, vllm-plugin-FL) that already support MetaX MACA.

### 5. Moore Threads MUSA Platform Support with FlagCX

Enable heterogeneous distributed training across NVIDIA GPU and Moore Threads MUSA nodes:

```
┌─────────────────────────┐              ┌─────────────────────────┐
│  NVIDIA Nodes           │              │  MUSA Nodes             │
│  (Actor / Critic)       │◄── FlagCX ──►│  (Rollout / vLLM)       │
│  FSDP + NCCL            │              │  torch_musa             │
└─────────────────────────┘              └─────────────────────────┘
```

Key components:
- **FlagCX communication backend** — Unified cross-vendor collective communication replacing NCCL for heterogeneous setups.
- **Weight synchronization** — Cross-device weight transfer between CUDA and MUSA nodes.
- **Device isolation** — Proper device index management via Ray runtime context.
- **Recipe adaptation** — `one_step_off_policy` recipe updated for heterogeneous distributed training.

Related PR: #10.

## Design Details

### Platform Abstraction Architecture

```
verl/plugin/platform/
├── __init__.py
├── platform_base.py        # PlatformBase ABC (16 methods)
├── platform_cuda.py        # CUDA + FlagCX auto-detection
├── platform_metax.py       # MetaX MACA
├── platform_npu.py         # Ascend NPU
├── platform_musa.py        # Moore Threads MUSA + FlagCX
├── platform_cpu.py         # CPU fallback
├── platform_manager.py     # Singleton, VERL_PLATFORM env var
└── README.md               # Guide for adding new backends
```

### Engine Plugin Architecture

```
verl/plugin/engine/
├── __init__.py             # Engine registry
├── fsdp_fl/
│   ├── __init__.py
│   └── transformer_impl.py # TE-FL based FSDP engine
└── megatron_fl/
    └── __init__.py         # Megatron-LM-FL based engine
```

## Packaging

**(Required)**

- **Build command:** `pip install -e .` (editable install from verl-FL repo)
- **Packaging format:** pip wheel
- **Platform requirements:**
  - Python >= 3.10
  - PyTorch >= 2.4
  - For CUDA: CUDA >= 12.1
  - For MetaX MUSA: torch_musa, MACA toolkit
  - For NPU: torch_npu, CANN toolkit
  - FlagOS dependencies: vllm-plugin-FL, TransformerEngine-FL, Megatron-LM-FL, FlagCX (for heterogeneous communication)

## Test Plan

**(Required)**

### Platform Abstraction Unit Tests

```bash
# Run platform abstraction tests (CPU mode, no GPU required)
python -m pytest tests/plugin/test_platform_abstraction.py -v

# Run device API tests
python -m pytest tests/plugin/test_device_on_cpu.py -v

# Run engine registry tests
python -m pytest tests/plugin/test_engine_registry_on_cpu.py -v

# Run FL environment manager tests
python -m pytest tests/plugin/test_fl_env_manager_on_cpu.py -v
```

### Device API Usage Sanity Check

```bash
# Verify no direct torch.cuda.* calls remain in business logic
python tests/special_sanity/check_device_api_usage.py
```


### Expected Results

| Platform | Test Scope | Expected Result |
|----------|-----------|-----------------|
| CPU | Unit tests (platform abstraction, engine registry, env manager) | All pass |
| CUDA (NVIDIA GPU) | Unit tests + E2E GRPO training | All pass, training converges |

## Related PRs

- [x] flagos-ai/verl-FL#8 — [hardware] feat: Add unified platform abstraction layer and FlagOS training engine integration
- [x] flagos-ai/verl-FL#9 — [megatron] fix: fix the error when checking mcore version
- [x] flagos-ai/verl-FL#10 — [hardware, fsdp, rollout, recipe] feat: add MUSA platform support with FlagCX heterogeneous communication

## Future Plans

- Migrate multi-hardware adaptation to the [verl-project](https://github.com/volcengine/verl) upstream, co-maintained by FlagOS and verl communities.
- Expand platform support to additional domestic chips (KunlunXin, ENFLAME, etc.).
- Add more training recipes (DPO, PPO) for non-CUDA platforms.

## Implementation History

- 2026-03-19: Unified platform abstraction layer merged (#8, commit from PR #2)
- 2026-03-20: FlagOS training engine with vllm-plugin-FL and TE-FL backends merged (#8, commit from PR #1)
- 2026-04-16: Megatron-LM-FL version compatibility fix merged (#9)
- 2026-05-15: Moore Threads MUSA platform support with FlagCX heterogeneous communication merged (#10)

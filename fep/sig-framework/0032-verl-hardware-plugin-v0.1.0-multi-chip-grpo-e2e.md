# FEP-NNNN: verl-hardware-plugin v0.1.0 — Multi-Chip GRPO E2E Tests (MetaX, Iluvatar, Cambricon MLU)

<!-- Rename NNNN to the PR number before merge. -->

**Status:** `Implementable`

**Created:** 2026-07-23

**Owner:** @heavyrain-lzy

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP covers `verl-hardware-plugin` v0.1.0, a pip-installable plugin package that extends [verl](https://github.com/verl-project/verl) with platform abstraction and training-engine implementations for non-NVIDIA accelerators. The plugin is discovered automatically through verl's `verl.plugins` entry-point group; no source modification of verl is required.

This FEP scopes the v0.1.0 acceptance to three end-to-end GRPO training runs — one per chip — using the same Qwen3-0.6B / GSM8K baseline across:

1. **MetaX** (CUDA-compatible, MACA stack, `mx-smi` detection)
2. **Iluvatar** (CUDA-compatible, Corex stack, `ixsmi` detection)
3. **Cambricon MLU** (native `torch.mlu` + CNCL backend)

Repository: [verl-hardware-plugin](https://github.com/verl-project/verl-hardware-plugin)

## Motivation

The upstream verl framework is tightly coupled to `torch.cuda`, which makes it hard to run RLHF/GRPO training on domestic accelerators. `verl-hardware-plugin` provides reference platform and engine implementations that vendors can adapt to their own hardware through a stable plugin interface, decoupling hardware support from the verl release cycle.

For v0.1.0 we need to prove that the plugin mechanism works end-to-end on real hardware. The chosen proof point is a full GRPO training run on GSM8K with Qwen3-0.6B, reproduced independently on MetaX, Iluvatar, and Cambricon MLU, each validated against the NVIDIA reference reward curve.

### Goals

**(Required)**

- Package platform + engine implementations as a standalone pip-installable plugin (`verl-hardware-plugin`) discovered via the `verl.plugins` entry point, with no changes to verl source.
- Register three hardware platforms through `@PlatformRegistry.register(...)`:
  - `metax` — `device="cuda"`, `vendor="metax"`, NCCL/MCCL communication, `mx-smi` hardware detection.
  - `iluvatar` — `device="cuda"`, `vendor="iluvatar"`, NCCL/IXCCL communication, `ixsmi` hardware detection.
  - `cambricon` — `device="mlu"`, `vendor="cambricon"`, CNCL communication, custom Ray `MLU` resource.
- Register matching FSDP and Megatron engines for each platform via `@EngineRegistry.register(device=..., vendor=...)`.
- An end-to-end GRPO training run (Qwen3-0.6B, GSM8K, FSDP, vLLM rollout) example on each of the three chips, with the reward curve tracking the NVIDIA baseline.

### Non-Goals

- Production-grade performance tuning or full operator coverage on any of the three platforms (reference implementations only; production support requires vendor collaboration).
- Support for every verl recipe (PPO, DPO, etc.) — v0.1.0 validates GRPO only.
- Upstreaming the plugin interface into the verl core (tracked separately).

## Proposal

`verl-hardware-plugin` is installed alongside verl. At import time it registers its platforms and engines into verl's registries. Users select a platform either explicitly via `export VERL_PLATFORM=<name>` or through SMI-based auto-detection, then launch any standard verl training script unchanged.

```
verl (main framework)
    └── entry_points: verl.plugins → verl_hardware_plugin
            │
            ├── PlatformRegistry.register("metax")      → PlatformMetaX   (device=cuda, vendor=metax)
            ├── PlatformRegistry.register("iluvatar")   → PlatformIluvatar(device=cuda, vendor=iluvatar)
            ├── PlatformRegistry.register("cambricon")  → PlatformMLU     (device=mlu,  vendor=cambricon)
            │
            ├── EngineRegistry.register(device="cuda", vendor="metax")
            ├── EngineRegistry.register(device="cuda", vendor="iluvatar")
            └── EngineRegistry.register(device="mlu",  vendor="cambricon")
```

Engine lookup uses a two-level `(device, vendor)` key: an exact vendor match is preferred, falling back to the device-only base engine, and for CUDA-compatible devices to the base CUDA engine. This is what lets MetaX and Iluvatar reuse the CUDA path while still selecting vendor-specific engines when registered.

## Design Details

### Platform registration

Each platform subclasses `verl.plugin.platform.platform_base.PlatformBase` and is registered by decorator. Key per-chip properties:

| Platform | `device_name` | `vendor_name` | Comm backend | Ray resource | Detection | IPC |
|----------|---------------|---------------|--------------|--------------|-----------|-----|
| MetaX    | `cuda` | `metax`     | nccl / mccl | `GPU` | `mx-smi` | yes |
| Iluvatar | `cuda` | `iluvatar`  | nccl / ixccl | `GPU` | `ixsmi` | yes |
| Cambricon MLU | `mlu` | `cambricon` | cncl | `MLU` | `torch.mlu` | no |

For the two CUDA-compatible chips, `torch.cuda.is_available()` returns `True` on both them and NVIDIA hardware. `is_platform_available(use_smi_check=True)` runs the vendor SMI command (`mx-smi` / `ixsmi`) during first-time auto-detection to disambiguate. `is_available()` (no args) calls the native `torch.<device>.is_available()` for runtime checks.

Cambricon MLU uses the native `torch.mlu.*` API (via `import torch_mlu`) and a custom Ray `MLU` resource, so Ray workers must advertise it (`ray start --resources='{"MLU": 8}'`) to keep device assignment separate from CUDA GPU scheduling.

### Engine registration

Each platform ships FSDP (`fsdp_metax.py`, `fsdp_iluvatar.py`, `fsdp_mlu.py`) and Megatron (`megatron_metax.py`, `megatron_iluvatar.py`, `megatron_mlu.py`) engines, registered with the matching `(device, vendor)` key. The v0.1.0 acceptance runs exercise the FSDP path with a vLLM rollout backend.

## Packaging

**(Required)**

- **Format:** Python package (`pip`), editable or wheel install.
- **Build/install:**
  ```bash
  git clone https://github.com/verl-project/verl-hardware-plugin.git
  cd verl-hardware-plugin
  pip install --no-build-isolation -v -e .
  ```
- **Discovery:** exposes the `verl.plugins` entry point (`hardware = "verl_hardware_plugin"` in `pyproject.toml`); loaded automatically once verl imports.
- **Requirements:** Python ≥ 3.10, `verl >= 0.7.0`, plus the vendor torch/runtime stack (MACA / Corex / Cambricon) provided by each chip's base container image.
- **Version:** `0.1.0` (see `pyproject.toml`).

## Test Plan

**(Required)** Acceptance is one end-to-end GRPO run per chip (MetaX, Iluvatar, Cambricon MLU). Every run uses the same baseline (`scripts/baseline_grpo_gsm8k.sh` — Qwen3-0.6B, GSM8K, FSDP, vLLM rollout, `adv_estimator=grpo`) with an identical hyperparameter configuration; only the base image, install steps, and platform selection differ per chip.

All setup and launch details (image pull, container flags, verl + plugin install, data/model download, platform selection, and the exact training command) live in each chip's user guide and must be followed end-to-end:

| Platform | Detection | User Guide |
|----------|-----------|------------|
| MetaX | `mx-smi` | [`docs/user_guide_metax/README.md`](https://github.com/verl-project/verl-hardware-plugin/blob/main/docs/user_guide_metax/README.md) |
| Iluvatar | `ixsmi` | [`docs/user_guide_iluvatar/README.md`](https://github.com/verl-project/verl-hardware-plugin/blob/main/docs/user_guide_iluvatar/README.md) |
| Cambricon MLU | `torch.mlu` | [`docs/user_guide_mlu/README.md`](https://github.com/verl-project/verl-hardware-plugin/blob/main/docs/user_guide_mlu/README.md) |

### Expected Results

The acceptance criterion is the same for all three chips: the platform initialises to the expected vendor and the GRPO reward curve (`critic/rewards/mean`) **shows a clear upward trend within the first 100 training steps**. Absolute convergence and performance are out of scope for v0.1.0.

## Related PRs

<!-- Fill in with actual PR numbers as they land. -->

- [ ] flagos-ai/verl-hardware-plugin#xxx — feat: MetaX platform + FSDP/Megatron engines and GRPO E2E validation
- [ ] flagos-ai/verl-hardware-plugin#xxx — feat: Iluvatar platform + FSDP/Megatron engines and GRPO E2E validation
- [ ] flagos-ai/verl-hardware-plugin#xxx — feat: Cambricon MLU platform (CNCL) + FSDP/Megatron engines and GRPO E2E validation

## Future Plans

- Add PPO/DPO recipes and expand operator/engine coverage per chip.
- Extend to multi-node and heterogeneous cross-vendor training.
- Add remaining reference platforms (Intel XPU, etc.) to the acceptance matrix.
- Propose the plugin interface for upstream inclusion in verl, co-maintained with hardware vendors.

## Implementation History

- 2026-07-23: FEP drafted for verl-hardware-plugin v0.1.0 multi-chip GRPO E2E acceptance.

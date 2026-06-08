# FEP: sglang-plugin-FL 0.1.0 Multi-Chip Inference Plugin for SGLang (NVIDIA)

**Status:** `Provisional`

**Created:** 2026-05-27

**Owner:** @yixiaodapeng

**SIG:** sig-framework

**Target Version:** FlagOS 2.1

---

## Summary

[sglang-plugin-FL](https://github.com/flagos-ai/sglang-plugin-FL) is an out-of-tree (OOT) plugin for [SGLang](https://github.com/sgl-project/sglang), built on FlagOS's unified multi-chip backend — including the unified operator library [FlagGems](https://github.com/flagos-ai/FlagGems) and the unified communication library [FlagCX](https://github.com/flagos-ai/FlagCX). It extends SGLang's inference capabilities across diverse hardware platforms. Without changing SGLang's original interfaces or usage patterns, the same command can run model inference on different chips.

## Motivation

SGLang's inference engine relies on NVIDIA-specific components: flashinfer for attention, sgl_kernel for fused CUDA kernels, and NCCL for distributed communication. Running on alternative hardware (Huawei Ascend, Iluvatar, etc.) would otherwise require invasive source modifications.

This plugin provides a non-intrusive adaptation layer that enables SGLang to run on multiple chip platforms without modifying SGLang's source code, bridging the gap between SGLang's NVIDIA-centric design and the diverse hardware ecosystem.

### Goals

- Provide a three-layer non-intrusive adaptation for SGLang covering ATen operators, fused kernels, and distributed communication.
- Support verified end-to-end inference on NVIDIA for models including Qwen3.6-27B and Qwen3.6-35B-A3B, covering both text and multimodal (VL) modalities.
- Validate concurrent inference (16-way parallel requests) for text, VL, and mixed workloads.
- Validate the full plugin pipeline on NVIDIA CUDA platform with comprehensive dispatch unit tests.
- Share the dispatch system and vendor backend implementations with vllm-plugin-FL for cross-framework code reuse.

## Proposal

From a user perspective, sglang-plugin-FL is installed as a standard Python package via `pip install`. Once installed, SGLang automatically discovers and loads the plugin at startup via setuptools entry_points. Users launch SGLang servers and run inference with the same commands as before — no code changes required.

The plugin provides three layers of replacement:

- **Layer 1 — ATen Operators**: Replaces PyTorch's low-level ops (matmul, softmax, embedding, etc.) with FlagGems Triton kernels via PyTorch's dispatch mechanism.
- **Layer 2 — SGLang Fused Kernels**: Intercepts SGLang's custom fused ops (SiluAndMul, RMSNorm, RotaryEmbedding) via HookRegistry AROUND hooks, routing through a standardized dispatch system to FlagGems, vendor-native, or PyTorch reference implementations.
- **Layer 3 — Distributed Communication**: Replaces NCCL-based collectives with CommunicatorFL (backed by FlagCX or torch.distributed), enabling multi-card inference on any hardware.

## Design Details

### Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                       SGLang Runtime                         │
├──────────────────────────────────────────────────────────────┤
│  Layer 1: ATen Ops (flag_gems.enable → PyTorch dispatch)     │
│    torch.mm / torch.add / torch.softmax / ...                │
│      → FlagGems Triton kernels                               │
├──────────────────────────────────────────────────────────────┤
│  Layer 2: SGLang Fused Ops (AROUND hook on dispatch_forward) │
│    SiluAndMul / RMSNorm / RotaryEmbedding                    │
│      → flagos (FlagGems Triton) | vendor (chip-native) | ref │
├──────────────────────────────────────────────────────────────┤
│  Layer 3: Communication (AROUND hooks on GroupCoordinator)   │
│    all_reduce / all_gather / reduce_scatter / send / recv    │
│      → CommunicatorFL (FlagCX / torch.distributed)           │
├──────────────────────────────────────────────────────────────┤
│  Triton JIT / Vendor Native → GPU / NPU Kernels              │
└──────────────────────────────────────────────────────────────┘
```

### Dispatch System

The dispatch system is shared with vllm-plugin-FL. It uses a priority-based backend resolution:

| Backend | Priority | Description |
|---------|----------|-------------|
| FlagGems (DEFAULT) | 150 | FlagGems Triton kernels |
| Vendor | 100 | Chip-native implementations (CUDA, Ascend) |
| Reference | 50 | Pure PyTorch, always available |

Users can configure backend selection via YAML config files or `SGLANG_FL_*` environment variables with per-op granularity.

### Vendor Integration

Chip vendors integrate by implementing a backend class and `register_ops.py` under `dispatch/backends/vendor/`. The plugin auto-discovers vendor backends at startup. The same vendor implementations work across both sglang-plugin-FL and vllm-plugin-FL.

Currently supported vendor backend for this FEP:

| Vendor | Hardware Detection |
|--------|-------------------|
| NVIDIA CUDA | `sgl_kernel` importable |

### Verified Models (NVIDIA)

| Model | TP | Modality | Status |
|-------|-----|----------|--------|
| Qwen3.6-27B (Hybrid Attention + FLA + MoE) | TP=1 (single-node), TP=2 PP=2 (multi-node) | Text + VL | Verified |
| Qwen3.6-35B-A3B (MoE, 256 experts) | TP=1 (single-node), TP=2 PP=2 (multi-node) | Text + VL | Verified |

All models support 16-way concurrent inference (text, VL, and mixed modes).

## Packaging

### Build and Package

1. Install SGLang v0.5.11:

```bash
pip install "sglang[all]==0.5.11"
```

2. Install FlagGems:

```bash
git clone https://github.com/flagos-ai/FlagGems
cd FlagGems && pip install --no-build-isolation .
```

3. Install sglang-plugin-FL:

```bash
git clone https://github.com/flagos-ai/sglang-plugin-FL
cd sglang-plugin-FL && pip install --no-build-isolation .
```

4. (Optional) Install FlagCX for multi-chip distributed communication:

```bash
git clone https://github.com/flagos-ai/FlagCX.git
cd FlagCX && make USE_NVIDIA=1
export FLAGCX_PATH="$PWD"
```

### Environment Requirements

| Package | Version |
|---------|---------|
| SGLang | 0.5.11 |
| sglang-kernel | 0.4.2 |
| PyTorch | 2.11.0+cu130 |
| Triton | 3.6.0 |
| FlagGems | 5.3.0-rc2.post1 |
| flashinfer | 0.6.8.post1 |
| Python | 3.12 |
| CUDA | 13.0 |

## Test Plan

The test plan below is required for NVIDIA.

### Environment Matrix

- Platform: NVIDIA H20
- Single-node tests (1–4, 7–9): 1 node, 8x NVIDIA H20
- Multi-node tests (5–6): 2 nodes, 2x NVIDIA H20 per node (4 GPUs total, TP=2, PP=2)

### Model Acquisition

Models are pre-loaded in the Docker image at `/models/`. Alternatively, download from ModelScope:

```bash
# Qwen3.6-27B
modelscope download --model Qwen/Qwen3.6-27B --local_dir /models/Qwen3.6-27B

# Qwen3.6-35B-A3B
modelscope download --model Qwen/Qwen3.6-35B-A3B --local_dir /models/Qwen3.6-35B-A3B
```

### Image Acquisition

NVIDIA platform image (pre-installed with PyTorch, Triton, FlagGems, SGLang, and Qwen3.6 models):

```bash
docker pull harbor.baai.ac.cn/flagos-inner-models-release/flagrelease-qwen3.6-nvidia-tree_none-gems_5.3.0-rc2.post1-vllm_none-plugin_none-cx_none-python_3.12.3-torch_2.11.0-pcp_cuda13.0-gpu_nvidia003-arc_amd64-driver_580.105.08:202606072035
```

### Package Installation

```bash
# Inside container (SGLang, FlagGems, PyTorch, Triton are pre-installed in the image)
git clone https://github.com/flagos-ai/sglang-plugin-FL && cd sglang-plugin-FL && pip install --no-build-isolation . && cd ..
```

### Component Setup

Start the SGLang server with the plugin:

```bash
python -m sglang.launch_server \
    --model-path /models/Qwen3.6-27B \
    --port 30000 \
    --disable-piecewise-cuda-graph
```

### Test Commands and Expected Results

**1. Text + VL offline inference (Qwen3.6-27B)**

```bash
MODEL_PATH=/models/Qwen3.6-27B python examples/qwen3_6_27b_offline_inference.py
```

Expected: Text prompts return correct answers (e.g., "50" for US states, "Paris" for France capital). VL prompts correctly identify image content (e.g., "red" for red_square.jpg, "cat" for cat.jpg, "7" for digit_seven.png).

**2. Text + VL offline inference (Qwen3.6-35B-A3B)**

```bash
MODEL_PATH=/models/Qwen3.6-35B-A3B python examples/qwen3_6_35b_a3b_offline_inference.py
```

Expected: Same as test 1 — text and VL outputs are correct.

**3. 16-way concurrent inference (Qwen3.6-27B)**

```bash
MODEL_PATH=/models/Qwen3.6-27B python examples/qwen3_6_27b_concurrent.py --mode all
```

Expected: All 16 concurrent requests complete successfully in text, VL, and mixed modes. Per-request latency statistics are printed. All responses pass correctness checks.

**4. 16-way concurrent inference (Qwen3.6-35B-A3B)**

```bash
MODEL_PATH=/models/Qwen3.6-35B-A3B python examples/qwen3_6_35b_a3b_concurrent.py --mode all
```

Expected: Same as test 3 — all concurrent modes pass on the MoE model.

**5. Multi-node text + concurrent + VL inference (Qwen3.6-27B)**

```bash
# [Node 0 / Master / 192.168.0.66]
CUDA_VISIBLE_DEVICES=0,1 \
SGLANG_FL_FLAGOS_BLACKLIST=count_nonzero \
SGLANG_ENABLE_TP_MEMORY_INBALANCE_CHECK=0 \
GLOO_SOCKET_IFNAME=eth0 NCCL_SOCKET_IFNAME=eth0 \
    python examples/qwen3_6_27b_multinode.py --role master --master-addr 192.168.0.66 --tp 2 --pp 2

# [Node 1 / Worker / 192.168.0.65]
CUDA_VISIBLE_DEVICES=0,1 \
SGLANG_FL_FLAGOS_BLACKLIST=count_nonzero \
SGLANG_ENABLE_TP_MEMORY_INBALANCE_CHECK=0 \
GLOO_SOCKET_IFNAME=eth0 NCCL_SOCKET_IFNAME=eth0 \
    python examples/qwen3_6_27b_multinode.py --role worker --master-addr 192.168.0.66 --tp 2 --pp 2
```

Expected: All requests complete successfully in text, concurrent, and multimodal (VL) inference tests.

**6. Multi-node text + concurrent + VL inference (Qwen3.6-35B-A3B)**

```bash
# [Node 0 / Master / 192.168.0.66]
CUDA_VISIBLE_DEVICES=0,1 \
SGLANG_FL_FLAGOS_BLACKLIST=count_nonzero \
SGLANG_ENABLE_TP_MEMORY_INBALANCE_CHECK=0 \
GLOO_SOCKET_IFNAME=eth0 NCCL_SOCKET_IFNAME=eth0 \
    python examples/qwen3_6_35b_a3b_multinode.py --role master --master-addr 192.168.0.66 --tp 2 --pp 2

# [Node 1 / Worker / 192.168.0.65]
CUDA_VISIBLE_DEVICES=0,1 \
SGLANG_FL_FLAGOS_BLACKLIST=count_nonzero \
SGLANG_ENABLE_TP_MEMORY_INBALANCE_CHECK=0 \
GLOO_SOCKET_IFNAME=eth0 NCCL_SOCKET_IFNAME=eth0 \
    python examples/qwen3_6_35b_a3b_multinode.py --role worker --master-addr 192.168.0.66 --tp 2 --pp 2
```

Expected: Same as test 5 — all text, concurrent, and VL tests pass on the MoE model.

**7. Dispatch unit tests**

```bash
cd sglang-plugin-FL
pytest tests/unit_tests/dispatch/ -v
```

Expected: All dispatch unit tests pass, covering:
- `test_types`: OpImpl, BackendImplKind, BackendPriority, match_token
- `test_registry`: register/get/dedup/clear/snapshot/thread safety
- `test_policy`: SelectionPolicy, PolicyManager, context managers, YAML config
- `test_manager`: resolve/cache/call fallback/fork reset/singleton
- `test_call_op`: call_op/resolve_op API, builtin_ops registration
- `test_fork_safety`: real os.fork() cache/reinit/parent/epoch
- `test_env_policy`: SGLANG_FL_PREFER/STRICT/DENY_VENDORS/ALLOW_VENDORS/PER_OP/CONFIG

**8. Dispatch log verification**

```bash
SGLANG_FL_DISPATCH_LOG=/tmp/dispatch.log \
  python -m sglang.launch_server \
    --model-path /models/Qwen3.6-27B \
    --port 30000 --disable-piecewise-cuda-graph
# After first request:
sort -u /tmp/dispatch.log
```

Expected: Log shows all three fused ops dispatched to the flagos backend:

```
[OOT-DISPATCH] SiluAndMul → flagos(flagos)
[OOT-DISPATCH] RMSNorm → flagos(flagos)
[OOT-DISPATCH] RotaryEmbedding → flagos(flagos)
```

**9. Plugin disabled baseline**

```bash
SGLANG_PLUGINS="__none__" python -m sglang.launch_server \
    --model-path /models/Qwen3.6-27B \
    --port 30000 --disable-piecewise-cuda-graph
```

Expected: Server starts using vanilla SGLang CUDA path without the plugin; confirms no regressions in the baseline.

## Related PRs

- [x] [flagos-ai/sglang-plugin-FL#1](https://github.com/flagos-ai/sglang-plugin-FL/pull/1) — Initial implementation of sglang-plugin-FL (three-layer OOT plugin)
- [x] [flagos-ai/sglang-plugin-FL#9](https://github.com/flagos-ai/sglang-plugin-FL/pull/9) — Add concurrent inference examples with text/VL/mixed modes
- [x] [flagos-ai/sglang-plugin-FL#11](https://github.com/flagos-ai/sglang-plugin-FL/pull/11) — Add dispatch unit tests
- [x] [flagos-ai/sglang-plugin-FL#23](https://github.com/flagos-ai/sglang-plugin-FL/pull/23) — Add pipeline parallelism support to multi-node examples

## Implementation History

- 2026-05-27: FEP created
- 2026-05-29: Added multimodal (VL) inference, 16-way concurrent inference tests (PR #9), and dispatch unit tests (PR #11)


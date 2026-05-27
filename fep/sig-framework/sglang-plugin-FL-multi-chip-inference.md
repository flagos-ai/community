# FEP: sglang-plugin-FL — Multi-Chip Inference Plugin for SGLang

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
- Support verified end-to-end inference for models including Qwen3.6-27B, Qwen3.6-35B-A3B, and Qwen2.5-14B-Instruct.
- Enable multi-chip deployment on NVIDIA CUDA and Huawei Ascend with a unified vendor integration interface.
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

Currently supported vendor backends:

| Vendor | Hardware Detection |
|--------|-------------------|
| NVIDIA CUDA | `sgl_kernel` importable |
| Huawei Ascend | `torch_npu` importable |

### Verified Models

| Model | TP | Status |
|-------|-----|--------|
| Qwen3.6-27B (Hybrid Attention + FLA + MoE) | tp=1 | Verified |
| Qwen3.6-35B-A3B (MoE, 256 experts) | tp=1 | Verified |
| Qwen2.5-14B-Instruct | tp=8 | Verified |

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
| FlagGems | 4.2.1rc0 |
| flashinfer | 0.6.8.post1 |
| Python | 3.12 |
| CUDA | 13.0 |

## Test Plan

### Image Acquisition

Use the official vLLM CUDA base image (or equivalent SGLang-compatible image):

```bash
docker pull vllm/vllm-openai:v0.20.0-cu130-ubuntu
```

### Package Installation

```bash
# Inside container
pip install "sglang[all]==0.5.11"
git clone https://github.com/flagos-ai/FlagGems && cd FlagGems && pip install --no-build-isolation . && cd ..
git clone https://github.com/flagos-ai/sglang-plugin-FL && cd sglang-plugin-FL && pip install --no-build-isolation . && cd ..
```

### Component Setup

Start the SGLang server with the plugin:

```bash
python -m sglang.launch_server \
    --model-path Qwen/Qwen2.5-0.5B-Instruct \
    --port 30000 \
    --disable-piecewise-cuda-graph
```

### Test Commands and Expected Results

**1. Single-GPU inference (Qwen2.5-0.5B-Instruct)**

```bash
python -m sglang.launch_server \
    --model-path Qwen/Qwen2.5-0.5B-Instruct \
    --port 30000 \
    --disable-piecewise-cuda-graph
```

Send a request after server is ready:

```bash
curl -s http://localhost:30000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "default",
    "messages": [{"role": "user", "content": "List the first 5 prime numbers."}],
    "temperature": 0
  }' | python -m json.tool
```

Expected: Server starts successfully; API returns a valid JSON response with coherent generated text listing prime numbers (2, 3, 5, 7, 11).

**2. Multi-GPU inference (Qwen2.5-14B-Instruct, tp=8)**

```bash
python -m sglang.launch_server \
    --model-path Qwen/Qwen2.5-14B-Instruct \
    --tp 8 --port 30000 \
    --disable-piecewise-cuda-graph
```

Expected: Server starts with 8 GPUs; inference produces correct results with tensor-parallel communication via CommunicatorFL.

**3. Dispatch log verification**

```bash
SGLANG_FL_DISPATCH_LOG=/tmp/dispatch.log \
  python -m sglang.launch_server \
    --model-path Qwen/Qwen2.5-0.5B-Instruct \
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

**4. Plugin disabled baseline**

```bash
SGLANG_PLUGINS="__none__" python -m sglang.launch_server \
    --model-path Qwen/Qwen2.5-0.5B-Instruct \
    --port 30000 --disable-piecewise-cuda-graph
```

Expected: Server starts using vanilla SGLang CUDA path without the plugin; confirms no regressions in the baseline.

## Related PRs

- [ ] flagos-ai/sglang-plugin-FL — initial plugin implementation

## Implementation History

- 2026-05-27: FEP created

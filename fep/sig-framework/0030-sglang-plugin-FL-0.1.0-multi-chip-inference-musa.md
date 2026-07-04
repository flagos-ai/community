# FEP: sglang-plugin-FL 0.1.0 Multi-Chip Inference Plugin for SGLang (MUSA)

**Status:** `Implemented`

**Created:** 2026-05-29

**Owner:** @huangxu0914

**SIG:** sig-framework

**Target Version:** FlagOS 2.1

---

## Summary

This proposal adds a vendor dispatch backend for Moore Threads MUSA to [sglang-plugin-FL](https://github.com/flagos-ai/sglang-plugin-FL), enabling end-to-end inference for `Qwen3.6-27B` and `Qwen3.6-35B-A3B` on MUSA without modifying SGLang's source code. The work ports SGLang's MUSA operator implementations into the plugin's vendor dispatch backend and adds MUSA platform detection and configuration.

## Motivation

Running `Qwen3.6-27B` (hybrid attention + FLA + MoE) and `Qwen3.6-35B-A3B` (256-expert MoE) on Moore Threads MUSA requires fused ops covering normalization, attention, MoE routing, and linear attention — and a mechanism to restore SGLang's dispatch bridge after MUSA's `RotaryEmbedding.__init__` overwrites it. Without the vendor.musa backend these ops would either fail or fall through to incompatible CUDA paths.

### Goals

- Add a vendor.musa backend with 10 op registrations covering the full op set needed by both models.
- Add MUSA platform detection and a per-platform dispatch config (`musa.yaml`).
- Patch `RotaryEmbedding.__init__` to restore the dispatch bridge after the MUSA override.
- Validate end-to-end inference of `Qwen3.6-27B` and `Qwen3.6-35B-A3B` on MUSA.

## Proposal

From a user perspective, usage is unchanged. On a MUSA host, the same `pip install sglang-plugin-FL` is sufficient; the plugin auto-detects MUSA via `flag_gems` `DeviceDetector`, loads the MUSA dispatch config, registers the vendor.musa backend, and applies the `rotary_patch` at startup.

## Verified Models (MUSA)

| Model | TP | Status |
|-------|-----|--------|
| Qwen3.6-27B (Hybrid Attention + FLA + MoE) | tp=1 | Verified |
| Qwen3.6-35B-A3B (MoE, 256 experts) | tp=1 | Verified |

## Packaging

### Build and Package

1. Install SGLang v0.5.11:

```bash
# Use the default branch
git clone https://github.com/sgl-project/sglang.git
cd sglang

# Compile sgl-kernel
pip install --upgrade pip
cd sgl-kernel
python setup_musa.py install

# Install sglang python package along with diffusion support
cd ..
rm -f python/pyproject.toml && mv python/pyproject_other.toml python/pyproject.toml
pip install -e "python[all_musa]"
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

### Environment Requirements

| Package | Version |
|---------|---------|
| SGLang | 0.5.11 |
| PyTorch | 2.9.0 |
| torch_musa | 2.9.0 |
| sgl_kernel (MUSA build) | 0.4.2 |
| FlagGems | 5.0.2 |
| Python | 3.10 |

## Test Plan

The test plan below is required for MUSA.

### Environment Matrix

- Platform: Moore Threads MTT S5000

### Image Acquisition

MUSA platform image:

```bash
docker pull harbor.baai.ac.cn/flagos-inner-models-release/flagrelease-qwen3.6-mthreads-tree_none-gems_none-vllm_none-plugin_none-cx_none-python_3.10.12-torch_2.9.0-pcp_musa4.3.5-gpu_mthreads001-arc_amd64-driver_3.3.5-server:202605291523
```

### Container Setup

```bash
docker run -dit \
  --name sglang-plugin-fl-musa \
  --privileged \
  --ipc host \
  --network host \
  --shm-size 64g \
  --env MTHREADS_VISIBLE_DEVICES=all \
  harbor.baai.ac.cn/flagos-inner-models-release/flagrelease-qwen3.6-mthreads-tree_none-gems_none-vllm_none-plugin_none-cx_none-python_3.10.12-torch_2.9.0-pcp_musa4.3.5-gpu_mthreads001-arc_amd64-driver_3.3.5-server:202605291523 \
  sleep infinity
```

### Package Installation

```bash
# Inside container
git clone https://github.com/flagos-ai/FlagGems && cd FlagGems && pip install --no-build-isolation . && cd ..
git clone https://github.com/flagos-ai/sglang-plugin-FL && cd sglang-plugin-FL && pip install --no-build-isolation . && cd ..
```

### Test Commands and Expected Results

**1. Qwen3.6-27B offline inference (tp=1)**

```bash
MODEL_PATH=/models/Qwen3.6-27B TP_SIZE=1 \
SGLANG_FL_FLAGOS_BLACKLIST=count_nonzero,index_put_,_index_put_impl_,cumsum \
  python sglang-plugin-FL/examples/qwen3_6_27b_offline_inference.py
```

Expected: text testing outputs contain `"50"` and `"Paris"`; vl testing outputs contain `"red"`, `"cat"`, `"stop"` and `"7"`; prints `All validations passed.`

**2. Qwen3.6-27B concurrent inference (tp=1)**

```bash
MODEL_PATH=/models/Qwen3.6-27B TP_SIZE=1 \
SGLANG_FL_FLAGOS_BLACKLIST=count_nonzero,index_put_,_index_put_impl_,cumsum \
  python sglang-plugin-FL/examples/qwen3_6_27b_concurrent.py
```

Expected: all modes (text, text-concurrent, vl, vl-concurrent, mixed-concurrent) pass; latency stats printed; no scheduling or dispatch errors.


**3. Qwen3.6-35B-A3B offline inference (tp=1)**

```bash
MODEL_PATH=/models/Qwen3.6-35B-A3B TP_SIZE=1 \
SGLANG_FL_FLAGOS_BLACKLIST=count_nonzero,index_put_,_index_put_impl_,cumsum \
  python sglang-plugin-FL/examples/qwen3_6_35b_a3b_offline_inference.py
```

Expected: text testing outputs contain `"50"` and `"Paris"`; vl testing outputs contain `"red"`, `"cat"`, `"stop"` and `"7"`; prints `All validations passed.`


**4. Qwen3.6-35B-A3B concurrent inference (tp=1)**

```bash
MODEL_PATH=/models/Qwen3.6-35B-A3B TP_SIZE=1 \
SGLANG_FL_FLAGOS_BLACKLIST=count_nonzero,index_put_,_index_put_impl_,cumsum \
  python sglang-plugin-FL/examples/qwen3_6_35b_a3b_concurrent.py
```

Expected: all modes (text, text-concurrent, vl, vl-concurrent, mixed-concurrent) pass; latency stats printed; no scheduling or dispatch errors.

**5. Qwen3.6-27B Dispatch log verification**

```bash
SGLANG_FL_DISPATCH_DEBUG=1 SGLANG_FL_DISPATCH_LOG=/tmp/dispatch.log \
MODEL_PATH=/models/Qwen3.6-27B TP_SIZE=1 \
SGLANG_FL_FLAGOS_BLACKLIST=count_nonzero,index_put_,_index_put_impl_,cumsum \
  python sglang-plugin-FL/examples/qwen3_6_27b_offline_inference.py
sort -u /tmp/dispatch.log
```

Expected:

```
[OOT-DISPATCH] gemma_rms_norm → vendor.musa
[OOT-DISPATCH] chunk_gated_delta_rule → vendor.musa
[OOT-DISPATCH] silu_and_mul → default.flagos
[OOT-DISPATCH] mrotary_embedding → vendor.musa
[OOT-DISPATCH] fused_recurrent_gated_delta_rule_packed_decode → vendor.musa
```

**6. Qwen3.6-35B-A3B Dispatch log verification**

```bash
SGLANG_FL_DISPATCH_DEBUG=1 SGLANG_FL_DISPATCH_LOG=/tmp/dispatch.log \
SGLANG_FL_FLAGOS_BLACKLIST=count_nonzero,index_put_,_index_put_impl_,cumsum \
MODEL_PATH=/models/Qwen3.6-35B-A3B TP_SIZE=4 \
  python sglang-plugin-FL/examples/qwen3_6_35b_a3b_offline_inference.py
sort -u /tmp/dispatch.log
```

Expected:

```
[OOT-DISPATCH] gemma_rms_norm → vendor.musa
[OOT-DISPATCH] chunk_gated_delta_rule → vendor.musa
[OOT-DISPATCH] silu_and_mul → default.flagos
[OOT-DISPATCH] topk → default.flagos
[OOT-DISPATCH] fused_moe → vendor.musa
[OOT-DISPATCH] mrotary_embedding → vendor.musa
[OOT-DISPATCH] fused_recurrent_gated_delta_rule_packed_decode → vendor.musa
```

## Related PRs

- [ ] flagos-ai/sglang-plugin-FL — feat: add MUSA out-of-tree vendor backend with op implementations

## Implementation History

- 2026-05-29: FEP created

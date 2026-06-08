# FEP: sglang-plugin-FL 0.1.0 Multi-Chip Inference Plugin for SGLang (Ascend)

**Status:** `Provisional`

**Created:** 2026-05-29

**Owner:** @huangxu0914

**SIG:** sig-framework

**Target Version:** FlagOS 2.1

---

## Summary

This proposal adapts [sglang-plugin-FL](https://github.com/flagos-ai/sglang-plugin-FL) to run on Huawei Ascend NPU, enabling end-to-end inference for `Qwen3.6-27B` and `Qwen3.6-35B-A3B` on Ascend without modifying SGLang's source code. The work ports the SGLang upstream Ascend operator implementations into the plugin's vendor dispatch backend and wires NPU-specific KV pool and paged allocator routing through `PlatformFL`.

## Motivation

Running `Qwen3.6-27B` (hybrid attention + FLA + MoE) and `Qwen3.6-35B-A3B` (256-expert MoE) on Ascend NPU requires a set of fused ops beyond the basic attention primitives — specifically `gemma_rms_norm`, `mrotary_embedding`, `topk`, `fused_moe`, and `chunk_gated_delta_rule` — as well as NPU-specific KV pool and paged allocator classes that the generic CUDA-based pools cannot serve.

### Goals

- Port five ops from SGLang's NPU backend into the Ascend vendor dispatch backend.
- Route NPU-native KV pool and paged allocator classes through `PlatformFL` when `device_type == "npu"`.
- Validate end-to-end inference of `Qwen3.6-27B` and `Qwen3.6-35B-A3B` on Ascend NPU.

## Proposal

From a user perspective, usage is unchanged. On an Ascend NPU host, the same `pip install sglang-plugin-FL` is sufficient; the plugin auto-detects NPU via `flag_gems` `DeviceDetector`, registers the Ascend vendor backend, and dispatches the new ops to the ported NPU implementations.

## Verified Models (Ascend NPU)

| Model | TP | Status |
|-------|-----|--------|
| Qwen3.6-27B (Hybrid Attention + FLA + MoE) | tp=4 | Verified |
| Qwen3.6-35B-A3B (MoE, 256 experts; text + VL) | tp=4 | Verified |

## Packaging

### Build and Package

1. Install SGLang from source:

```bash
git clone https://github.com/sgl-project/sglang.git
cd sglang
mv python/pyproject_npu.toml python/pyproject.toml
pip install -e python[all_npu]
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

4. (Optional) Install FlagCX for multi-card distributed communication:

```bash
git clone https://github.com/flagos-ai/FlagCX.git
cd FlagCX && make USE_ASCEND=1
export FLAGCX_PATH="$PWD"
```

### Environment Requirements

| Package | Version |
|---------|---------|
| SGLang | 0.5.11 |
| PyTorch | 2.8.0+cpu |
| torch_npu | 2.8.0.post2 |
| sgl_kernel_npu | 2026.5.1|
| triton | 3.5.0 |
| triton_ascend | 3.2.1 |
| FlagGems | 5.3.0-rc2.post1 |
| Python | 3.10 |
| CANN | 8.5.0 |

## Test Plan

The test plan below is required for Ascend.

### Environment Matrix

- Platform: Huawei Ascend NPU 910B4-1

### Image Acquisition

Ascend platform image:

```bash
docker pull harbor.baai.ac.cn/flagos-inner-models-release/flagrelease-qwen3.6-ascend-tree_none-gems_5.3.0-rc2.post1-vllm_none-plugin_none-cx_none-python_3.11.14-torch_npu_2.8.0.post2-pcp_cann8.5.0-gpu_ascend001-arc_arm64-driver_25.2.0:202606081729
```

### Container Setup

```bash
docker run -dit \
    --name sglang-plugin-fl-ascend \
    --privileged \
    --network=host --ipc=host --shm-size=64g \
    --device=/dev/davinci0 --device=/dev/davinci1 --device=/dev/davinci2 --device=/dev/davinci3 \
    --device=/dev/davinci4 --device=/dev/davinci5 --device=/dev/davinci6 --device=/dev/davinci7 \
    --device=/dev/davinci_manager \
    --device=/dev/hisi_hdc \
    --volume /usr/local/sbin:/usr/local/sbin \
    --volume /usr/local/Ascend/driver:/usr/local/Ascend/driver \
    --volume /usr/local/Ascend/firmware:/usr/local/Ascend/firmware \
    --volume /etc/ascend_install.info:/etc/ascend_install.info \
    --volume /var/queue_schedule:/var/queue_schedule \
    --entrypoint=bash \
    harbor.baai.ac.cn/flagos-inner-models-release/flagrelease-qwen3.6-ascend-tree_none-gems_5.3.0-rc2.post1-vllm_none-plugin_none-cx_none-python_3.11.14-torch_npu_2.8.0.post2-pcp_cann8.5.0-gpu_ascend001-arc_arm64-driver_25.2.0:202606081729
```

### Package Installation

```bash
# Inside container
git clone https://github.com/flagos-ai/FlagGems && cd FlagGems && pip install . && cd ..
git clone https://github.com/flagos-ai/sglang-plugin-FL && cd sglang-plugin-FL && pip install . && cd ..
```

### Test Commands and Expected Results

**1. Qwen3.6-27B offline inference (tp=4)**

```bash
MODEL_PATH=/models/Qwen3.6-27B TP_SIZE=4 \
SGLANG_FL_FLAGOS_BLACKLIST=count_nonzero,index_put_,_index_put_impl_,cumsum,fill_scalar_,argmax,index,add_,conv1d \
  python sglang-plugin-FL/examples/qwen3_6_27b_offline_inference.py
```

Expected: engine starts on NPU with `attention_backend=ascend`, `dtype=bfloat16`; text testing outputs contain `"50"` and `"Paris"`; vl testing outputs contain `"red"`, `"cat"`, `"stop"` and `"7"`; prints `All validations passed.`

**2. Qwen3.6-27B concurrent inference (tp=4)**

```bash
MODEL_PATH=/models/Qwen3.6-27B TP_SIZE=4 \
SGLANG_FL_FLAGOS_BLACKLIST=count_nonzero,index_put_,_index_put_impl_,cumsum,fill_scalar_,argmax,index,add_,conv1d \
  python sglang-plugin-FL/examples/qwen3_6_27b_concurrent.py
```

Expected: all modes (text, text-concurrent, vl, vl-concurrent, mixed-concurrent) pass; latency stats printed; no scheduling or dispatch errors.


**3. Qwen3.6-35B-A3B offline inference (tp=4)**

```bash
MODEL_PATH=/models/Qwen3.6-35B-A3B TP_SIZE=4 \
SGLANG_FL_FLAGOS_BLACKLIST=count_nonzero,index_put_,_index_put_impl_,cumsum,fill_scalar_,argmax,index,add_,conv1d \
  python sglang-plugin-FL/examples/qwen3_6_35b_a3b_offline_inference.py
```

Expected: engine starts on NPU with `attention_backend=ascend`, `dtype=bfloat16`; text testing outputs contain `"50"` and `"Paris"`; vl testing outputs contain `"red"`, `"cat"`, `"stop"` and `"7"`; prints `All validations passed.`


**4. Qwen3.6-35B-A3B concurrent inference (tp=4)**

```bash
MODEL_PATH=/models/Qwen3.6-35B-A3B TP_SIZE=4 \
SGLANG_FL_FLAGOS_BLACKLIST=count_nonzero,index_put_,_index_put_impl_,cumsum,fill_scalar_,argmax,index,add_,conv1d \
  python sglang-plugin-FL/examples/qwen3_6_35b_a3b_concurrent.py
```

Expected: all modes (text, text-concurrent, vl, vl-concurrent, mixed-concurrent) pass; latency stats printed; no scheduling or dispatch errors.

**5. Qwen3.6-27B Dispatch log verification**

```bash
SGLANG_FL_DISPATCH_DEBUG=1 SGLANG_FL_DISPATCH_LOG=/tmp/dispatch.log \
SGLANG_FL_FLAGOS_BLACKLIST=count_nonzero,index_put_,_index_put_impl_,cumsum,fill_scalar_,argmax,index,add_,conv1d \
  MODEL_PATH=/models/Qwen3.6-27B TP_SIZE=4 \
  python sglang-plugin-FL/examples/qwen3_6_27b_offline_inference.py
sort -u /tmp/dispatch.log
```

Expected: the five ops land on `vendor.ascend`:

```
[OOT-DISPATCH] silu_and_mul → default.flagos
[OOT-DISPATCH] gemma_rms_norm → vendor.ascend
[OOT-DISPATCH] mrotary_embedding → vendor.ascend
[OOT-DISPATCH] chunk_gated_delta_rule → vendor.ascend
```

**6. Qwen3.6-35B-A3B Dispatch log verification**

```bash
SGLANG_FL_DISPATCH_DEBUG=1 SGLANG_FL_DISPATCH_LOG=/tmp/dispatch.log \
SGLANG_FL_FLAGOS_BLACKLIST=count_nonzero,index_put_,_index_put_impl_,cumsum,fill_scalar_,argmax,index,add_,conv1d \
  MODEL_PATH=/models/Qwen3.6-35B-A3B TP_SIZE=4 \
  python sglang-plugin-FL/examples/qwen3_6_35b_a3b_offline_inference.py
sort -u /tmp/dispatch.log
```

Expected: the five ops land on `vendor.ascend`:

```
[OOT-DISPATCH] silu_and_mul → default.flagos
[OOT-DISPATCH] gemma_rms_norm → vendor.ascend
[OOT-DISPATCH] mrotary_embedding → vendor.ascend
[OOT-DISPATCH] topk → vendor.ascend
[OOT-DISPATCH] fused_moe → vendor.ascend
[OOT-DISPATCH] chunk_gated_delta_rule → vendor.ascend
```

## Related PRs

- [x] [flagos-ai/sglang-plugin-FL#10](https://github.com/flagos-ai/sglang-plugin-FL/pull/10) — feat: extend Ascend out-of-tree vendor backend with op implementations

## Implementation History

- 2026-05-29: FEP created

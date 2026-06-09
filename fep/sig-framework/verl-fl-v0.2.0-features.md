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
  - For MetaX: torch_maca, MACA toolkit
  - For MUSA: torch_musa, MUSA toolkit
  - For NPU: torch_npu, CANN toolkit
  - FlagOS dependencies:
    - FlagCX (required, unified cross-vendor communication backend)
    - vllm-plugin-FL (optional, for vLLM-based rollout engine)
    - TransformerEngine-FL (optional, for TE-FL based FSDP training engine)
    - Megatron-LM-FL (optional, for Megatron-based training engine)

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

### NVIDIA E2E Test

End-to-end GRPO training test on NVIDIA GPU environment. Model: Qwen3-0.6B, Dataset: GSM8K.

#### Step 1: Pull Image and Create Container

```bash
docker pull harbor.baai.ac.cn/flagscale/flagscale-rl:dev-cu128-py3.12-20260402105433

docker_image=harbor.baai.ac.cn/flagscale/flagscale-rl:dev-cu128-py3.12-20260402105433
docker_name=verl_test
sudo docker run -itd \
                --name ${docker_name} \
                --privileged \
                --network=host \
                --ipc=host \
                --device=/dev/infiniband \
                --pid=host \
                --cap-add=ALL \
                --shm-size 512G \
                --ulimit memlock=-1 \
                --gpus all \
                -v /dev/:/dev/ \
                -v /usr/src/:/usr/src/ \
                -v /lib/modules/:/lib/modules/ \
                -w /workspace \
                ${docker_image} \
                /bin/bash

docker exec -it verl_test bash
```

#### Step 2: Prepare Data and Model

```bash
cd /workspace
conda activate flagscale-RL

# Download model
modelscope download --model Qwen/Qwen3-0.6B --local_dir ./Qwen3-0.6B

# Download dataset
mkdir gsm8k && cd gsm8k
wget "https://baai-flagscale.ks3-cn-beijing.ksyuncs.com/rl/datasets/gsm8k/train.parquet"
wget "https://baai-flagscale.ks3-cn-beijing.ksyuncs.com/rl/datasets/gsm8k/test.parquet"
```

#### Step 3: Install FlagOS Software Stack

> **Note:** FlagCX is required. All other FlagOS components (FlagGems, vllm-plugin-FL, TransformerEngine-FL, Megatron-LM-FL) are optional.

**3.1 Install FlagCX (Required)**

```bash
cd /workspace
git clone https://github.com/flagos-ai/FlagCX.git
cd FlagCX
git submodule update --init --recursive
pip install . -v --no-build-isolation

# Post-install configuration
# export FLAGCX_PATH=/workspace/FlagCX/
```

**3.2 Install FlagGems (Optional)**

```bash
cd /workspace
pip install -U scikit-build-core>=0.11 pybind11 ninja cmake
git clone https://github.com/flagos-ai/FlagGems.git
cd FlagGems
pip install --no-build-isolation -v .
```

**3.3 Install vllm-plugin-FL (Optional)**

```bash
cd /workspace
## Option A: Install from PyPI
pip install vllm-plugin-fl==0.1.0+vllm0.13.0 --extra-index-url https://resource.flagos.net/repository/flagos-pypi-hosted/simple

## Option B: Install from source
git clone --branch v0.1.0+vllm0.13.0 https://github.com/flagos-ai/vllm-plugin-FL.git
cd vllm-plugin-fl
pip install --no-build-isolation -v .
```

**3.4 Install Megatron-LM-FL / TransformerEngine-FL (Optional)**

```bash
cd /workspace
## Option A: Install from PyPI
pip install transformer_engine==0.1.0+te2.9.0 --extra-index-url https://resource.flagos.net/repository/flagos-pypi-hosted/simple

## Option B: Install from source
git clone --branch v0.1.0+te2.9.0 https://github.com/flagos-ai/TransformerEngine-FL.git
cd TransformerEngine-FL
pip install --no-build-isolation -v .

cd /workspace
## Option A: Install from PyPI
pip install megatron_core==0.1.0+megatron0.15.0rc7 --extra-index-url https://resource.flagos.net/repository/flagos-pypi-hosted/simple

## Option B: Install from source
git clone --branch v0.1.0+megatron0.15.0rc7 https://github.com/flagos-ai/Megatron-LM-FL.git
cd Megatron-LM-FL
pip install --no-build-isolation -v .
```

#### Step 4: Install verl-FL

```bash
cd /workspace
git clone --branch v0.2.0-rc2.post1 https://github.com/flagos-ai/verl-FL.git
cd verl-FL
pip install --no-build-isolation -v -e .
```

#### Step 5: Modify Script and Run

Based on `examples/grpo_trainer/run_qwen3-0.6b_fl.sh`, modify model/data/FlagCX paths according to your actual setup (all paths below assume `/workspace` from the steps above):

```bash
#!/bin/bash
# FL Multi-Chip Support Version of run_qwen3-0.6b.sh
# This script demonstrates training with FL (FlagOS) multi-chip support
# including FlagGems operators, Transformer-Engine-FL, and FlagCX communication.
#
# Reference: docs/design/fl_multi_chip_support.md

set -x

# ============ Device Configuration ============
export CUDA_VISIBLE_DEVICES=4,5,6,7
export HYDRA_FULL_ERROR=1

# ============ FlagCX Communication Library ============
# export FLAGCX_PATH=/share/project/lizhiyu/FlagCX
# export PYTHONPATH=/share/project/gzy/FlagCX/plugin/torch:${PYTHONPATH}

# ============ FL Configuration via verl fl_config ============
# Note: Environment variables below are for reference only.
# In verl FL architecture, these are set dynamically by FLEnvManager
# based on fl_config YAML configuration.
export RAY_ACCEL_ENV_VAR_OVERRIDE_ON_ZERO=0
export VERL_ENGINE_DEVICE=flagos
# Training phase environment variables:
export TE_FL_PREFER=flagos  #flagos / vendor / reference    flagos
export TE_FL_PREFER_VENDOR=0    # Prefer vendor (legacy)    1 / 0   0
export TE_FL_STRICT=0   # Strict mode (no fallback) 1 / 0   0
# TE_FL_ALLOW_VENDORS=nvidia,amd    # Allowed vendors (whitelist)   nvidia,amd
# TE_FL_DENY_VENDORS=vendor_a   # Denied vendors (blacklist)    vendor_a
# TE_FL_PER_OP=rmsnorm_fwd=vendor:cuda|default
export VLLM_FL_FLAGOS_BLACKLIST="where_scalar_other,where_scalar_self,where_self,where_self_out,pad"
# Logging
export TEFL_LOG_LEVEL=DEBUG # / INFO / WARNING / ERROR  INF

# Rollout phase environment variables:
# export VLLM_PLUGINS=""
# export VLLM_FL_PREFER_ENABLED=true
# export VLLM_FL_PLATFORM=cuda # will cause error
# export VLLM_FL_PREFER=flagos
export USE_FLAGGEMS=true
export VLLM_FL_OOT_ENABLED=1
export USE_FLAGCX=1
# unset FLAGCX_PATH

export FLAGCX_PATH=/workspace/FlagCX/
export FLAGCX_LOG_LEVEL=DEBUG

## Key modifications below
DATA_DIR=/workspace/gsm8k/
MODEL_DIR=/workspace/Qwen3-0.6B

python3 -m verl.trainer.main_ppo \
    algorithm.adv_estimator=grpo \
    data.train_files=${DATA_DIR}/train.parquet \
    data.val_files=${DATA_DIR}/test.parquet \
    data.train_batch_size=64 \
    data.max_prompt_length=512 \
    data.max_response_length=1024 \
    data.filter_overlong_prompts=True \
    data.truncation='error' \
    actor_rollout_ref.model.path=${MODEL_DIR} \
    actor_rollout_ref.actor.optim.lr=1e-6 \
    actor_rollout_ref.model.use_remove_padding=True \
    actor_rollout_ref.actor.ppo_mini_batch_size=64 \
    actor_rollout_ref.actor.ppo_micro_batch_size_per_gpu=4 \
    actor_rollout_ref.actor.use_kl_loss=True \
    actor_rollout_ref.actor.kl_loss_coef=0.001 \
    actor_rollout_ref.actor.kl_loss_type=low_var_kl \
    actor_rollout_ref.actor.entropy_coeff=0 \
    actor_rollout_ref.model.enable_gradient_checkpointing=True \
    actor_rollout_ref.actor.fsdp_config.param_offload=False \
    actor_rollout_ref.actor.fsdp_config.optimizer_offload=False \
    actor_rollout_ref.rollout.log_prob_micro_batch_size_per_gpu=4 \
    actor_rollout_ref.rollout.tensor_model_parallel_size=1 \
    actor_rollout_ref.rollout.name=vllm \
    actor_rollout_ref.rollout.gpu_memory_utilization=0.4 \
    actor_rollout_ref.rollout.n=5 \
    actor_rollout_ref.ref.log_prob_micro_batch_size_per_gpu=4 \
    actor_rollout_ref.ref.fsdp_config.param_offload=True \
    algorithm.use_kl_in_reward=False \
    trainer.critic_warmup=0 \
    trainer.logger='["console"]' \
    trainer.project_name='verl_grpo_example_gsm8k_fl' \
    trainer.experiment_name='qwen3_0.6b_fl' \
    trainer.n_gpus_per_node=4 \
    trainer.nnodes=1 \
    trainer.save_freq=20 \
    trainer.test_freq=5 \
    trainer.use_legacy_worker_impl='disable' \
    +actor_rollout_ref.rollout.enable_sleep_mode=False \
    actor_rollout_ref.rollout.free_cache_engine=False \
    trainer.total_epochs=15 \
    $@
```

Once the script is modified, run:

```bash
bash examples/grpo_trainer/run_qwen3-0.6b_fl.sh
```

**Validation criteria:** Training outputs step information normally, no errors during the training process, and the reward metric shows a convergence trend.

---

### MetaX E2E Test

End-to-end GRPO training test on MetaX C500 environment. Model: Qwen3-0.6B, Dataset: GSM8K.

#### Step 1: Pull Image and Create Container

Use the MetaX official release image `verl:0.7.0-maca.ai3.3.0.102-torch2.8-py310-ubuntu22.04-amd64`. You need to register a MetaX developer account:
https://developer.metax-tech.com/softnova/docker?chip_name=%E6%9B%A6%E4%BA%91C500%E7%B3%BB%E5%88%97&package_name=verl%3A0.7.0&dimension=docker&deliver_type=%E5%88%86%E5%B1%82%E5%8C%85

```bash
# Create container
docker run -d -t --net=host --uts=host --ipc=host --privileged=true \
  --group-add video --shm-size 100gb --ulimit memlock=-1 \
  --security-opt seccomp=unconfined --security-opt apparmor=unconfined \
  --device=/dev/dri --device=/dev/mxcd --device=/dev/infiniband \
  -v /nfs/dh:/nfs/dh --name verl_fl_test \
  <image_id> bash

docker exec -it verl_fl_test bash
```

#### Step 2: Prepare Data and Model

```bash
cd /workspace
conda activate flagscale-RL

# Download model
modelscope download --model Qwen/Qwen3-0.6B --local_dir ./Qwen3-0.6B

# Download dataset
mkdir gsm8k && cd gsm8k
wget "https://baai-flagscale.ks3-cn-beijing.ksyuncs.com/rl/datasets/gsm8k/train.parquet"
wget "https://baai-flagscale.ks3-cn-beijing.ksyuncs.com/rl/datasets/gsm8k/test.parquet"
```

#### Step 3: Install FlagOS Software Stack

> **Note:** FlagCX is required. All other FlagOS components (FlagGems, vllm-plugin-FL, TransformerEngine-FL, Megatron-LM-FL) are optional.

**3.1 Install FlagCX (Required)**

```bash
cd /workspace
git clone https://github.com/flagos-ai/FlagCX.git
cd FlagCX
git checkout -b v0.9.0
git submodule update --init --recursive
make USE_METAX=1
export FLAGCX_PATH="$PWD"
cd plugin/torch/
FLAGCX_ADAPTOR=metax pip install . --no-build-isolation

# Post-install configuration
# export FLAGCX_PATH=/workspace/FlagCX/
```

**3.2 Install FlagGems (Optional)**

```bash
cd /workspace
pip install -U scikit-build-core>=0.11 pybind11 ninja cmake
git clone https://github.com/flagos-ai/FlagGems.git
cd FlagGems
git checkout v4.2.0
pip install --no-build-isolation -v .
```

**3.3 Install vllm-plugin-FL (Optional)**

```bash
cd /workspace
## Option A: Install from PyPI
pip install vllm-plugin-fl==0.1.0+vllm0.13.0 --extra-index-url https://resource.flagos.net/repository/flagos-pypi-hosted/simple

## Option B: Install from source
git clone --branch v0.1.0+vllm0.13.0 https://github.com/flagos-ai/vllm-plugin-FL.git
cd vllm-plugin-fl
pip install --no-build-isolation -v .

# Uninstall metax plugin to avoid conflicts
pip uninstall vllm-metax
```

**3.4 Install Megatron-LM-FL / TransformerEngine-FL (Optional)**

```bash
cd /workspace
## Install TransformerEngine-FL from source
pip install onnxscript  # Install dependency
wget https://baai-flagscale.ks3-cn-beijing.ksyuncs.com/rl/pkg/metax/transformer_engine_metax-2.9.0%2Bmaca3.3.0-cp310-cp310-linux_x86_64.whl
pip install transformer_engine_metax-2.9.0+maca3.3.0-cp310-cp310-linux_x86_64.whl
git clone --branch v0.1.0+te2.9.0 https://github.com/flagos-ai/TransformerEngine-FL.git
cd TransformerEngine-FL
TE_FL_SKIP_CUDA=1 pip install --no-build-isolation -v .

cd /workspace
## Option A: Install from PyPI
pip install megatron_core==0.1.0+megatron0.15.0rc7 --extra-index-url https://resource.flagos.net/repository/flagos-pypi-hosted/simple

## Option B: Install from source
git clone --branch v0.1.0+megatron0.15.0rc7 https://github.com/flagos-ai/Megatron-LM-FL.git
cd Megatron-LM-FL
pip install --no-build-isolation -v .
```

#### Step 4: Install verl-FL

```bash
cd /workspace
git clone --branch v0.2.0-rc2.post1 https://github.com/flagos-ai/verl-FL.git
cd verl-FL
pip3 install nvtx
pip3 install --no-deps -e .
```

#### Step 5: Modify Script and Run

Based on `examples/grpo_trainer/run_qwen3-0.6b_fl.sh`, modify model/data/FlagCX paths according to your actual setup (all paths below assume `/workspace` from the steps above):

```bash
#!/bin/bash
# FL Multi-Chip Support Version of run_qwen3-0.6b.sh
# This script demonstrates training with FL (FlagOS) multi-chip support
# including FlagGems operators, Transformer-Engine-FL, and FlagCX communication.
#
# Reference: docs/design/fl_multi_chip_support.md

set -x

# ============ MetaX Platform Environment ============
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export RAY_ACCEL_ENV_VAR_OVERRIDE_ON_ZERO=0
export VLLM_FL_FLAGOS_BLACKLIST="where_scalar_other,where_scalar_self,where_self,where_self_out,pad"
export VERL_ENGINE_DEVICE="flagos"
export USE_FLAGCX=1
export VLLM_FL_PREFER="vendor"
export VLLM_FL_PLATFORM="metax"
export LOGLEVEL="INFO"

# MetaX MACA SDK paths
export CUCC_PATH="/opt/maca/tools/cu-bridge"
export CUDA_PATH="/opt/maca/tools/cu-bridge"
export DEVINFO_ROOT="/opt/maca"
export LD_LIBRARY_PATH="/opt/maca/lib:/opt/maca/mxgpu_llvm/lib:/opt/mxdriver/lib:/opt/maca/ompi/lib:/opt/maca/ucx/lib:/opt/mxdriver/lib"
export MACA_CLANG="/opt/maca/mxgpu_llvm"
export MACA_CLANG_PATH="/opt/maca/mxgpu_llvm/bin"
export MACA_PATH="/opt/maca"
export PATH="/opt/conda/bin:/opt/conda/condabin:/opt/maca/tools/cu-bridge:/opt/maca/bin:/opt/maca/mxgpu_llvm/bin:/opt/maca/ompi/bin:/opt/maca/ucx/bin:/opt/mxdriver/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# MetaX performance tuning
export CUDA_DEVICE_MAX_CONNECTIONS=1
export NVTE_FLASH_ATTN=1
export NVTE_FUSED_ATTN=0
export MACA_SMALL_PAGESIZE_ENABLE=1
export MCCL_MAX_NCHANNELS=18
export MCCL_P2P_LEVEL=SYS
export PYTORCH_ENABLE_SAME_RAND_CONF=multiprocessosr_count:114,maxthreads_per_multiprocessor:2048
export NVTE_ALLOW_NONDETERMINISTIC_ALGO=0

# MetaX network configuration
export GLOO_SOCKET_IFNAME=bond0
export MCCL_SOCKET_IFNAME=bond0
export MCCL_IB_HCA=mlx5_101,mlx5_102,mlx5_103,mlx5_104,mlx5_105,mlx5_106,mlx5_107,mlx5_108

# FlagCX configuration for MetaX
export FLAGCX_P2P_LEVEL=SYS
export FLAGCX_GLOO_SOCKET_IFNAME=bond0
export FLAGCX_SOCKET_IFNAME=bond0
export FLAGCX_IB_HCA=mlx5_101,mlx5_102,mlx5_103,mlx5_104,mlx5_105,mlx5_106,mlx5_107,mlx5_108
export FLAGCX_MAX_NCHANNELS=18
export FLAGCX_ENABLE_TOPO_DETECT=TRUE
# ============ End MetaX Platform Environment ============

export HYDRA_FULL_ERROR=1

# ============ FlagCX Communication Library ============
export FLAGCX_PATH=/workspace/FlagCX/
export FLAGCX_LOG_LEVEL=DEBUG

# ============ FL Configuration ============
export TE_FL_PREFER=flagos
export TE_FL_PREFER_VENDOR=0
export TE_FL_STRICT=0
export TEFL_LOG_LEVEL=DEBUG

# Rollout phase environment variables:
export USE_FLAGGEMS=true
export VLLM_FL_OOT_ENABLED=1

## Key modifications below
DATA_DIR=/workspace/gsm8k/
MODEL_DIR=/workspace/Qwen3-0.6B

python3 -m verl.trainer.main_ppo \
    algorithm.adv_estimator=grpo \
    data.train_files=${DATA_DIR}/train.parquet \
    data.val_files=${DATA_DIR}/test.parquet \
    data.train_batch_size=64 \
    data.max_prompt_length=512 \
    data.max_response_length=1024 \
    data.filter_overlong_prompts=True \
    data.truncation='error' \
    actor_rollout_ref.model.path=${MODEL_DIR} \
    actor_rollout_ref.actor.optim.lr=1e-6 \
    actor_rollout_ref.model.use_remove_padding=True \
    actor_rollout_ref.actor.ppo_mini_batch_size=64 \
    actor_rollout_ref.actor.ppo_micro_batch_size_per_gpu=8 \
    actor_rollout_ref.actor.use_kl_loss=True \
    actor_rollout_ref.actor.kl_loss_coef=0.001 \
    actor_rollout_ref.actor.kl_loss_type=low_var_kl \
    actor_rollout_ref.actor.entropy_coeff=0 \
    actor_rollout_ref.model.enable_gradient_checkpointing=True \
    actor_rollout_ref.actor.fsdp_config.param_offload=False \
    actor_rollout_ref.actor.fsdp_config.optimizer_offload=False \
    actor_rollout_ref.rollout.log_prob_micro_batch_size_per_gpu=4 \
    actor_rollout_ref.rollout.tensor_model_parallel_size=1 \
    actor_rollout_ref.rollout.name=vllm \
    actor_rollout_ref.rollout.gpu_memory_utilization=0.4 \
    actor_rollout_ref.rollout.n=5 \
    actor_rollout_ref.ref.log_prob_micro_batch_size_per_gpu=4 \
    actor_rollout_ref.ref.fsdp_config.param_offload=True \
    algorithm.use_kl_in_reward=False \
    trainer.critic_warmup=0 \
    trainer.logger='["console"]' \
    trainer.project_name='verl_grpo_example_gsm8k_fl' \
    trainer.experiment_name='qwen3_0.6b_fl' \
    trainer.n_gpus_per_node=4 \
    trainer.nnodes=1 \
    trainer.save_freq=20 \
    trainer.test_freq=5 \
    trainer.use_legacy_worker_impl='disable' \
    +actor_rollout_ref.rollout.enable_sleep_mode=False \
    actor_rollout_ref.rollout.free_cache_engine=False \
    trainer.total_epochs=15 \
    $@
```

Once the script is modified, run:

```bash
bash examples/grpo_trainer/run_qwen3-0.6b_fl.sh
```

**Validation criteria:** Training outputs step information normally, no errors during the training process, and the reward metric shows a convergence trend.

### CUDA E2E GRPO Training

Environment requirements:
- CUDA >= 12.1, PyTorch >= 2.4
- `vllm-plugin-FL`, `TransformerEngine-FL`, `Megatron-LM-FL` installed
- Model: [Qwen3-0.6B](https://modelscope.cn/models/Qwen/Qwen3-0.6B)
- Dataset: GSM8K ([train.parquet](https://baai-flagscale.ks3-cn-beijing.ksyuncs.com/rl/datasets/gsm8k/train.parquet), [test.parquet](https://baai-flagscale.ks3-cn-beijing.ksyuncs.com/rl/datasets/gsm8k/test.parquet))

```bash
TORCH_COMPILE_DISABLE=1 RAY_DEDUP_LOGS=0 HYDRA_FULL_ERROR=1 \
CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 RAY_ACCEL_ENV_VAR_OVERRIDE_ON_ZERO=0 \
python3 -m recipe.one_step_off_policy.main_ppo \
    --config-path=config \
    --config-name='one_step_off_ppo_trainer.yaml' \
    actor_rollout_ref.model.path=<path/to/Qwen3-0.6B> \
    data.train_files=<path/to/gsm8k/train.parquet> \
    data.val_files=<path/to/gsm8k/test.parquet> \
    actor_rollout_ref.actor.strategy=fsdp2 \
    actor_rollout_ref.actor.ppo_micro_batch_size_per_gpu=4 \
    actor_rollout_ref.actor.ppo_mini_batch_size=64 \
    actor_rollout_ref.rollout.name="vllm" \
    actor_rollout_ref.rollout.log_prob_micro_batch_size_per_gpu=4 \
    actor_rollout_ref.rollout.tensor_model_parallel_size=1 \
    +actor_rollout_ref.rollout.enable_sleep_mode=False \
    actor_rollout_ref.rollout.free_cache_engine=False \
    actor_rollout_ref.rollout.calculate_log_probs=True \
    +actor_rollout_ref.model.override_config.attn_implementation=eager \
    critic.strategy=fsdp2 \
    actor_rollout_ref.hybrid_engine=False \
    trainer.nnodes=1 \
    trainer.logger='["console"]' \
    trainer.n_gpus_per_node=8 \
    rollout.nnodes=1 \
    rollout.n_gpus_per_node=8 \
    2>&1 | tee onestep.log
```

### (Optional) FlagCX Heterogeneous Communication Test

Before running full E2E training, you can verify cross-node FlagCX communication independently using `torchrun`. This step does not require Ray or verl-FL — it only tests whether NVIDIA and MUSA nodes can communicate via FlagCX.

On the MUSA node (rank 0, master):

```bash
export FLAGCX_DEBUG=INFO
export FLAGCX_DEBUG_SUBSYS=ALL
export FLAGCX_SOCKET_IFNAME=<MUSA_IB_IFNAME>   # e.g. bond0; check with `ip a`
export MUSA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export FLAGCX_IB_HCA=mlx5
export FLAGCX_ENABLE_TOPO_DETECT=TRUE

torchrun --nproc_per_node 8 --nnodes=2 --node_rank=0 \
    --master_addr=<MUSA_NODE_IP> --master_port=8122 \
    example.py
```

On the NVIDIA node (rank 1):

```bash
export FLAGCX_DEBUG=INFO
export FLAGCX_DEBUG_SUBSYS=ALL
export FLAGCX_SOCKET_IFNAME=<NVIDIA_IB_IFNAME>   # e.g. ens22f0; check with `ip a`
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export FLAGCX_IB_HCA=mlx5
export FLAGCX_ENABLE_TOPO_DETECT=TRUE

torchrun --nproc_per_node 8 --nnodes=2 --node_rank=1 \
    --master_addr=<MUSA_NODE_IP> --master_port=8122 \
    example.py
```

Expected: `example.py` (from the [FlagCX](https://github.com/FlagOpen/FlagCX) repo) completes without error; allreduce results match on both sides.

### MUSA Heterogeneous Training (NVIDIA + Moore Threads)

This test validates CUDA+MUSA heterogeneous distributed training via FlagCX. One node runs actor/critic (NVIDIA, FSDP), the other runs rollout (Moore Threads MUSA, vLLM).

#### Environment Requirements

- **NVIDIA node:** base image `nvidia/cuda:12.9.1-devel-ubuntu22.04`; **Python 3.10**; manually install: torch 2.9.0+cu129, vllm 0.12.0, `vllm-plugin-FL`, `TransformerEngine-FL`, `Megatron-LM-FL`, `FlagCX`, `Ray`, `verl-FL`
- **MUSA node:** base image `registry.mthreads.com/presale/devtech/vllm_plugin_fix:20260327hg` (includes `torch_musa`, MUSA toolkit, `vllm-plugin-FL`); **Python 3.10**; manually install: `FlagCX`, `Ray`, `verl-FL`
- **Both nodes:** Python 3.10; InfiniBand for cross-node communication
- **Model:** Qwen3-0.6B
- **Dataset:** GSM8K (`train.parquet` / `test.parquet`)

#### Step 1 — Start Ray cluster

On the MUSA node (head, handles rollout):

```bash
export RAY_EXPERIMENTAL_NOSET_MUSA_VISIBLE_DEVICES=1
export MUSA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export MCCL_NET_GDR_LEVEL=2
export MCCL_IB_HCA=mlx5_bond_0
export FLAGCX_PATH=/workspace/FlagCX
export USE_FLAGCX=1
export FLAGCX_IB_HCA=mlx5

# Install RDMA dependencies if not present
apt install -y rdma-core libibverbs1 libibverbs-dev ibverbs-utils

ray start --head --port=6379 --node-ip-address=<MUSA_NODE_IP> --num-gpus=8
```

On the NVIDIA node (worker, handles actor/critic):

```bash
export FLAGCX_PATH=/workspace/FlagCX
export USE_FLAGCX=1
export FLAGCX_LOG_LEVEL=DEBUG

ray start --address='<MUSA_NODE_IP>:6379' --node-ip-address=<NVIDIA_NODE_IP> --num-gpus=8
```

#### Step 2 — Launch heterogeneous GRPO training

Edit `config/one_step_off_ppo_trainer.yaml` to set data and model paths:

```yaml
data:
  train_files: <path/to/gsm8k/train.parquet>
  val_files: <path/to/gsm8k/test.parquet>

actor_rollout_ref:
  model:
    path: <path/to/Qwen3-0.6B>
```

Then run on the NVIDIA (worker) node:

```bash
TORCH_COMPILE_DISABLE=1 RAY_DEDUP_LOGS=0 HYDRA_FULL_ERROR=1 \
FLAGCX_PATH=/workspace/FlagCX USE_FLAGCX=1 FLAGCX_LOG_LEVEL=DEBUG \
CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 RAY_ACCEL_ENV_VAR_OVERRIDE_ON_ZERO=0 \
python3 -m recipe.one_step_off_policy.main_ppo \
    --config-path=config \
    --config-name='one_step_off_ppo_trainer.yaml' \
    actor_rollout_ref.actor.strategy=fsdp2 \
    actor_rollout_ref.actor.ppo_micro_batch_size_per_gpu=4 \
    actor_rollout_ref.actor.ppo_mini_batch_size=64 \
    actor_rollout_ref.rollout.name="vllm" \
    actor_rollout_ref.rollout.log_prob_micro_batch_size_per_gpu=4 \
    actor_rollout_ref.rollout.tensor_model_parallel_size=1 \
    +actor_rollout_ref.rollout.enable_sleep_mode=False \
    actor_rollout_ref.rollout.free_cache_engine=False \
    actor_rollout_ref.rollout.calculate_log_probs=True \
    +actor_rollout_ref.model.override_config.attn_implementation=eager \
    critic.strategy=fsdp2 \
    actor_rollout_ref.hybrid_engine=False \
    trainer.nnodes=1 \
    trainer.logger='["console"]' \
    trainer.n_gpus_per_node=8 \
    rollout.nnodes=1 \
    rollout.n_gpus_per_node=8 \
    2>&1 | tee onestep_hetero.log
```

### Expected Results

| Platform | Test Scope | Expected Result |
|----------|-----------|-----------------|
| CPU | Unit tests (platform abstraction, engine registry, env manager) | All pass |
| CUDA (NVIDIA GPU) | Unit tests + E2E GRPO training | All pass, training converges |
| MetaX (MACA) | E2E GRPO training | All pass, training converges |
| MUSA heterogeneous (NVIDIA actor/critic + MUSA rollout) | E2E GRPO training on GSM8K via FlagCX | FlagCX cross-node communication established; training runs without crash; `critic/score/mean` > 0 throughout; `rollout_corr/log_ppl_diff` < 0.005 (training vs rollout PPL consistent, e.g. `training_log_ppl` ~0.76 and `rollout_log_ppl` ~0.76 at step 1) |

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

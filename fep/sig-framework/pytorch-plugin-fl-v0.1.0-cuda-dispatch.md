# FEP: PyTorch-Plugin-FL Multi-Backend Operator Dispatch

## Summary

This FEP proposes integrating multi-backend operator dispatch support into the PyTorch-Plugin-FL project through the following complementary execution paths:

1. Native CUDA operator dispatch
2. Native Ascend (Huawei) operator dispatch
3. FlagGems Triton operator dispatch (C++ and Python paths)

The goal is to provide a unified and extensible backend dispatch mechanism for PyTorch operators across heterogeneous accelerator platforms, aligning with the broader FlagOS multi-backend ecosystem.

---

## Motivation

FlagOS aims to build a unified AI system software stack that enables "develop once, run anywhere" across heterogeneous accelerators. ([github.com](https://github.com/flagos-ai))

Within this ecosystem, FlagGems provides a backend-neutral operator library and integrates with PyTorch ATen dispatch to accelerate model training and inference on diverse hardware platforms. ([github.com](https://github.com/flagos-ai/FlagGems))

PyTorch-Plugin-FL is designed as a lightweight PyTorch backend plugin framework. This FEP introduces the dispatch architecture that:

* Supports native vendor kernels (CUDA, Ascend)
* Supports FlagGems operators (via C++ linking and Python embedding)
* Provides per-operator backend routing via configuration
* Establishes the foundation for future hardware expansion
* Keeps compatibility with existing PyTorch execution semantics

---

## Goals

### In Scope

* Multi-backend support: CUDA, Ascend (CANN)
* Native vendor kernel dispatch for each platform
* FlagGems Triton operator dispatch (C++ linked and Python embedded)
* Runtime per-operator backend selection via configuration file
* Unified backend abstraction for operator execution
* PyTorch-compatible operator behavior
* End-to-end model inference and training validation (Qwen3-0.6B)

### Out of Scope

* Custom operator authoring APIs
* Graph-level compilation (torch.compile integration)
* Distributed runtime support (DDP/FSDP is in-progress but separate)
* Operator performance benchmarking (correctness-first approach)
* Automatic kernel generation

---

## Background

FlagGems is a Triton-based operator library that supports multiple hardware backends and integrates with the PyTorch ATen backend dispatch mechanism. ([github.com](https://github.com/flagos-ai/FlagGems))

The FlagOS ecosystem has gradually moved hardware-specific implementations into plugin-style repositories and backend abstraction layers. ([github.com](https://github.com/FlagOpen/FlagScale))

This proposal follows the same architectural direction by introducing a multi-backend dispatch layer into PyTorch-Plugin-FL.

The v0.1.0 implementation covers two hardware platforms:

| Platform | Hardware | SDK/Toolkit | Kernel Type |
|----------|----------|-------------|-------------|
| CUDA | NVIDIA A800-SXM4-80GB | CUDA 12.8, Driver 535.x | `.cu` native kernels |
| Ascend | Huawei Atlas 910B | CANN 25.0.rc1.3 | ACL NN API (`.cc`) |

---

## Design Overview

### High-Level Architecture

```text
┌──────────────────────────────────────────────────────────────┐
│  Python: import torch_fl                                     │
│  ┌────────────────┐  ┌────────────────────────────┐          │
│  │ torch_fl.flagos│  │ torch_fl.distributed       │          │
│  │ (device API)   │  │ (DDP/FSDP patch)           │          │
│  └────────────────┘  └────────────────────────────┘          │
├──────────────────────────────────────────────────────────────┤
│  PrivateUse1 Dispatch (ATen)                                 │
│  ┌─────────────┐  ┌──────────┐  ┌───────────┐               │
│  │ FlagGems    │  │ CUDA     │  │  Ascend   │               │
│  │ (Triton)    │  │ (native) │  │ (ACL NN)  │               │
│  └─────────────┘  └──────────┘  └───────────┘               │
│  ┌─────────────────────────────────────────┐  ┌────────┐     │
│  │ FlagGems Python (embed via pybind11)    │  │  CPU   │     │
│  │                                         │  │fallback│     │
│  └─────────────────────────────────────────┘  └────────┘     │
├──────────────────────────────────────────────────────────────┤
│  C++ Runtime (csrc/)                                         │
│  ┌──────────┐ ┌────────┐ ┌───────┐ ┌───────────┐             │
│  │Allocator │ │ Guard  │ │ RNG   │ │ Hooks     │             │
│  └──────────┘ └────────┘ └───────┘ └───────────┘             │
├──────────────────────────────────────────────────────────────┤
│  Hardware Abstraction (accelerator/)                         │
│  ┌──────────────┐  ┌────────────┐                            │
│  │ CUDA Runtime │  │ Ascend ACL │                            │
│  └──────────────┘  └────────────┘                            │
└──────────────────────────────────────────────────────────────┘
```

### Dispatch Mechanism

The `Dispatcher<FnPtr>` template class (defined in `csrc/aten/dispatcher.h`) manages per-operator kernel routing:

```cpp
enum class Backend { kCuda, kFlagOs, kFlagOsPython, kAscend, kMusa, kMetax };

template <typename FnPtr>
class Dispatcher {
  // Per-backend kernel function pointers
  FnPtr cuda_fn_, flagos_fn_, flagos_python_fn_, ascend_fn_, musa_fn_, metax_fn_;
  // Routes to GetBackendForOp(op_name) which reads config file
};
```

Backend selection is controlled by a `.conf` file (defaulting to `torch_fl/backends.conf`):

```ini
# Format: op_name = backend
# backend: flaggems | cuda | ascend | flagos_python
mm = flaggems
add.Tensor = cuda
embedding = ascend
abs = flagos_python
```

Per-operator override is also possible via environment variable:
```bash
FLAGOS_OP_add__Tensor=cuda  # Override add.Tensor to use CUDA backend
```

### Registration Flow

```text
1. DECLARE_DISPATCHER(FnPtr, name)         → header: extern Dispatcher
2. ADD_IMPL_TO_DISPATCHER(FnPtr, name, op) → source: define Dispatcher instance
3. REGISTER_IMPL_TO_DISPATCHER(...)        → per-backend .cu/.cc: register kernel
```

Each backend directory (`csrc/aten/backends/{cuda,ascend}/`) contains kernel implementations that self-register via static initialization.

### FlagGems Integration

Two integration paths are supported:

1. **C++ path** (`FLAGGEMS_KERNEL=1`): Links against `liboperators.so` from FlagGems build, calling Triton kernels via C++ API. Low overhead, requires pre-built FlagGems with C extensions.

2. **Python path** (`FLAGGEMS_PYTHON=1`): Embeds Python interpreter calls to `flag_gems.ops.*` functions via pybind11. Higher overhead but requires only a pip-installed FlagGems. Configured via `backends.conf` with `flagos_python` backend.

---

## Operator Coverage

### First-Phase Supported Operators (32 ops)

All operators below have native kernel implementations on both platforms:

| Category | Operators |
|----------|-----------|
| Elementwise Unary | `abs`, `acos`, `cos`, `sin`, `neg`, `rsqrt`, `silu`, `silu_backward` |
| Elementwise Binary | `add.Tensor`, `mul.Tensor`, `mul.Scalar`, `div.Scalar`, `pow.Tensor_Scalar` |
| Comparison | `le.Tensor`, `bitwise_and.Tensor`, `where.self` |
| Reduction | `all`, `mean.dim`, `sum.dim_IntList`, `_softmax` |
| BLAS | `mm`, `bmm` |
| Memory/Factory | `new_ones`, `scalar_tensor`, `ones_like`, `zeros`, `cat`, `constant_pad_nd`, `slice_backward` |
| Embedding | `embedding`, `embedding_dense_backward` |
| Loss | `nll_loss_forward`, `nll_loss_backward` |
| Indexing | `index.Tensor` |

### Per-Platform Kernel Implementations

| Platform | Directory | File Type | Count |
|----------|-----------|-----------|-------|
| CUDA | `csrc/aten/backends/cuda/` | `.cu`, `.cc` | 33 files |
| Ascend | `csrc/aten/backends/ascend/` | `.cc` (ACL NN) | 35 files |

---

## Testing Strategy

### Test Hierarchy

```
tests/integration/
├── ops/                          # Per-operator dispatch tests (32 test files)
│   ├── test_add_dispatch.py      # Correctness + dispatch routing
│   ├── test_mm_dispatch.py
│   └── ...
├── test_qwen3_infer.py           # End-to-end inference (Qwen3-0.6B)
├── test_qwen3_train.py           # End-to-end training (Qwen3-0.6B)
└── test_factory_ops.py           # Factory/memory ops
```

### Test Categories (pytest markers)

| Marker | Description |
|--------|-------------|
| `@pytest.mark.anyplatform` | Runs on all backends (correctness tests) |
| `@pytest.mark.cuda` | CUDA-specific tests (native comparison) |
| `@pytest.mark.ascend` | Ascend-specific tests |
| `@pytest.mark.flaggems` | Requires FlagGems Triton backend |
| `@pytest.mark.flaggems_python` | Requires FlagGems Python wrapper |

---

## Implementation and Verification Plan

### 1. Verification Environments

#### CUDA Platform

| Item | Value |
|------|-------|
| Host IP | 10.1.15.171 |
| Docker Container | `hcr_torch` |
| Docker Image | `pytorch2.11.0_cuda12.8_triton3.6.0_flaggems5.0.2` |
| GPU | NVIDIA A800-SXM4-80GB |
| Driver | 535.154.05 |
| CUDA Toolkit | 12.8 |
| Conda Env | `pytorch` (Python 3.12.13) |

**Key Dependencies:**
```
torch                    2.11.0+cu128
triton                   3.6.0
flag_gems                5.0.2 (with C extensions, flag DFLAGGEMS_BUILD_C_EXTENSIONS)
transformers             5.5.0
pytest                   9.0.2
cmake                    4.3.2
setuptools               81.0.0
wheel                    0.46.3
torch_fl                 0.1.0 (editable)
```

#### Ascend Platform

| Item | Value |
|------|-------|
| Host IP | 10.1.15.165 |
| Docker Container | `torch_fl` |
| Docker Image | `harbor.baai.ac.cn/flagrelease-public/flagrelease-ascend-release-model_qwen3.5-35b-a3b-tree_none-gems_4.2.1rc0-scale_none-cx_none-python_3.11.14-torch_npu2.8.0.post2-pcp_cann8.5.0-gpu_ascend001-arc_arm64-driver_25.2.3:202603211926` |
| NPU | Huawei Atlas 910B |
| CANN Toolkit | 25.0.rc1.3 |
| Conda Env | `torchfl` (Python 3.11.15) |

**Key Dependencies:**
```
torch                    2.11.0+cpu (host build, NPU via ACL)
flag_gems                5.0.2
transformers             5.7.0
pytest                   9.0.3
setuptools               70.2.0
wheel                    0.46.3
torch_fl                 0.1.0 (editable)
```

### 2. Installation and Configuration Steps

#### CUDA Platform

```bash
# Enter environment
ssh 10.1.15.171
docker exec -it hcr_torch zsh
source /root/miniconda3/etc/profile.d/conda.sh && conda activate pytorch

# Build and install
cd /nfs/hcr/repos/PyTorch-Plugin-FL
export TORCH_CUDA_ARCH_LIST="8.0"
rm -rf build
ACCELERATOR=cuda \
  FLAGGEMS_DIR=/nfs/hcr/repos/FlagGems/build/cpython-312/ \
  FLAGGEMS_KERNEL=1 FLAGGEMS_PYTHON=1 CUDA_KERNEL=1 \
  CMAKE_BUILD_PARALLEL_LEVEL=32 \
  pip install --no-build-isolation -vvv -e .
```

#### Ascend Platform

> **Note:** On domestic accelerator platforms (e.g., Ascend), the vendor-provided PyTorch (torch_npu-bundled torch) must be uninstalled first, then install the official PyTorch 2.11.0 CPU version. This ensures PyTorch-Plugin-FL registers its own backend dispatch without conflicting with vendor-patched torch internals.

```bash
# Enter environment
ssh 10.1.15.165
docker exec -it torch_fl zsh
source /root/miniconda3/etc/profile.d/conda.sh && conda activate torchfl

# Uninstall vendor-provided torch and install official CPU version
pip uninstall -y torch torch_npu
pip install torch==2.11.0 --index-url https://download.pytorch.org/whl/cpu

# Build and install
cd /nfs/hcr/repos/PyTorch-Plugin-FL
rm -rf build
ACCELERATOR=ascend \
  FLAGGEMS_KERNEL=0 FLAGGEMS_PYTHON=1 \
  CUDA_KERNEL=0 ASCEND_KERNEL=1 \
  CMAKE_BUILD_PARALLEL_LEVEL=32 \
  pip install --no-build-isolation -vvv -e .

# Patch triton-ascend to remove torch_npu dependency
python scripts/patch_triton_ascend.py
rm -rf ~/.triton/cache/
```

### 3. Test Procedures and Expected Output

#### 3.1 Operator Correctness Tests

Tests verify each operator produces numerically correct results on the `flagos` device by comparing with CPU reference values.

**CUDA Platform:**
```bash
CUDA_VISIBLE_DEVICES=0 \
  FLAGGEMS_SOURCE_DIR=/nfs/hcr/repos/FlagGems/src/flag_gems \
  pytest -v -s tests/integration/ops -m "anyplatform or cuda"
```

**Ascend Platform:**
```bash
ASCEND_RT_VISIBLE_DEVICES=1 \
  FLAGOS_BACKEND_CONFIG=torch_fl/backends_ascend.conf \
  pytest tests/integration/ops -v -s -m "anyplatform or ascend"
```

**Expected output (both platforms):**
```
tests/integration/ops/test_add_dispatch.py::TestAddTensorCorrectness::test_add_shape[shape0] PASSED
tests/integration/ops/test_add_dispatch.py::TestAddTensorCorrectness::test_add_alpha PASSED
tests/integration/ops/test_add_dispatch.py::TestAddTensorCorrectness::test_add_broadcast PASSED
tests/integration/ops/test_mm_dispatch.py::TestMmCorrectness::test_mm_basic PASSED
...
====== 90+ passed ======
```

Acceptance criteria: All `anyplatform`-marked tests pass on both platforms. Platform-specific tests (`cuda`, `ascend`) pass on their respective hardware.

#### 3.2 Dispatch Routing Verification

Each test file includes a `TestXxxDispatch` class that verifies the dispatch log output:

```bash
# Verify CUDA dispatch routing
FLAGOS_LOG_DISPATCH=1 FLAGOS_OP_add__Tensor=cuda \
  python -c "import torch_fl, torch; a=torch.randn(4,4,device='flagos:0'); b=torch.randn(4,4,device='flagos:0'); torch.add(a,b)"
```

**Expected stderr:**
```
[flagos dispatch] add.Tensor -> cuda
```

```bash
# Verify FlagGems Python dispatch routing
FLAGOS_LOG_DISPATCH=1 FLAGOS_OP_add__Tensor=flaggems_python \
  python -c "import torch_fl, torch; a=torch.randn(4,4,device='flagos:0'); b=torch.randn(4,4,device='flagos:0'); torch.add(a,b)"
```

**Expected stderr:**
```
[flagos dispatch] add.Tensor -> flagos_python
```

#### 3.3 End-to-End Inference Test (Qwen3-0.6B)

Validates full model execution on the `flagos` device using Hugging Face Transformers.

**CUDA Platform:**
```bash
CUDA_VISIBLE_DEVICES=1 \
  FLAGOS_DISABLE_FLAGGEMS_PY=1 \
  FLAGGEMS_SOURCE_DIR=/nfs/hcr/repos/FlagGems/src/flag_gems \
  pytest -v -s tests/integration/test_qwen3_infer.py
```

**Ascend Platform:**
```bash
ASCEND_RT_VISIBLE_DEVICES=2 \
  FLAGOS_BACKEND_CONFIG=torch_fl/backends_ascend.conf \
  pytest tests/integration/test_qwen3_infer.py -v -s
```

**Expected output:**
```
test_qwen3_infer.py::test_generate_output_shape PASSED
test_qwen3_infer.py::test_generate_nontrivial PASSED
test_qwen3_infer.py::test_generate_deterministic PASSED
====== 3 passed ======
```

Acceptance criteria:
- Model loads to `flagos:0` device without error
- Generation produces coherent text (non-empty, non-garbage)
- Deterministic generation with same seed produces identical output

#### 3.4 End-to-End Training Test (Qwen3-0.6B)

Validates forward pass, loss computation, and gradient update on the `flagos` device.

**CUDA Platform:**
```bash
CUDA_VISIBLE_DEVICES=2 \
  FLAGOS_DISABLE_FLAGGEMS_PY=1 \
  FLAGGEMS_SOURCE_DIR=/nfs/hcr/repos/FlagGems/src/flag_gems \
  pytest -v -s tests/integration/test_qwen3_train.py
```

**Ascend Platform:**
```bash
ASCEND_RT_VISIBLE_DEVICES=3 \
  FLAGOS_BACKEND_CONFIG=torch_fl/backends_ascend.conf \
  pytest tests/integration/test_qwen3_train.py -v -s
```

**Expected output:**
```
test_qwen3_train.py::test_training_loss_decreases PASSED
test_qwen3_train.py::test_training_no_nan PASSED
====== 2 passed ======
```

Acceptance criteria:
- Training loss decreases monotonically over 10 steps
- No NaN/Inf values in loss or gradients
- Model parameters update correctly

### 4. Backend Selection Verification Method

The dispatch mechanism is validated through three approaches:

#### 4.1 Configuration File Method

Each platform uses a dedicated config file that routes all ops to its native backend:

| Platform | Config File | Default Backend |
|----------|-------------|-----------------|
| CUDA | `torch_fl/backends.conf` | `cuda` / `flaggems` |
| Ascend | `torch_fl/backends_ascend.conf` | `ascend` |

#### 4.2 Environment Variable Override

Per-operator override for A/B testing between backends:

```bash
# Run add.Tensor on FlagGems instead of native CUDA
FLAGOS_OP_add__Tensor=flaggems_python python my_script.py
```

#### 4.3 Dispatch Log Inspection

Enable dispatch logging to trace all operator routing decisions:

```bash
FLAGOS_LOG_DISPATCH=1 python -c "
import torch_fl, torch
x = torch.randn(4, 4, device='flagos:0')
y = torch.matmul(x, x.T)
print(y.shape)
"
```

**Expected stderr (CUDA platform with default config):**
```
[flagos dispatch] mm -> flaggems
```

### 5. Native Kernel vs FlagGems Comparison Criteria

Correctness comparison between native backend and FlagGems uses the following standard:

| Metric | Threshold | Method |
|--------|-----------|--------|
| Relative tolerance | 1e-4 (fp32), 1e-3 (fp16) | `torch.testing.assert_close()` |
| Absolute tolerance | 1e-4 (fp32), 1e-3 (fp16) | `torch.testing.assert_close()` |
| Shape consistency | Exact match | `assert out.shape == expected.shape` |
| Device placement | Must remain on `flagos` | `assert out.device.type == "flagos"` |
| Dtype preservation | Must match input dtype | `assert out.dtype == input.dtype` |

Example comparison test (from `test_add_dispatch.py`):

```python
def test_add_matches_cuda(self):
    """Compare flagos output with native CUDA reference."""
    a_cuda = torch.randn(64, 64, device="cuda:0")
    b_cuda = torch.randn(64, 64, device="cuda:0")
    ref = torch.add(a_cuda, b_cuda)
    a = a_cuda.to("flagos:0")
    b = b_cuda.to("flagos:0")
    out = torch.add(a, b)
    torch.testing.assert_close(out.cpu(), ref.cpu(), rtol=1e-4, atol=1e-4)
```

### 6. Continuous Integration and Regression Testing

#### 6.1 CI Pipeline Structure

The project uses GitHub Actions for continuous integration:

```yaml
# .github/workflows/ci.yml
Jobs:
  1. lint              → ruff check + ruff format (all platforms)
  2. build-cuda        → build wheel on CUDA self-hosted runner
  3. integration-cuda  → full test suite on CUDA GPU (currently gated)
```

#### 6.2 CI Runners

| Platform | Runner Label | Hardware | Notes |
|----------|-------------|----------|-------|
| CUDA | `[self-hosted, nvidia, gpu-8]` | 8x NVIDIA A800 | Available but workflow currently gated |
| Ascend | Manual testing | Huawei Atlas 910B | Tested manually on 10.1.15.165 |

#### 6.3 CI Test Steps (CUDA example)

```yaml
- name: Check GPU availability
  run: nvidia-smi

- name: Install dependencies
  run: |
    pip install --upgrade pip
    pip install -e . --no-build-isolation
    pip install pytest

- name: Run ops tests
  run: pytest tests/integration/ops/ -v -s --tb=short

- name: Run general tests
  run: pytest tests/integration/test_factory_ops.py -v --device cuda --tb=short

- name: Run inference tests
  run: pytest tests/integration/test_qwen3_infer.py -v -s --device cuda --tb=short

- name: Run training tests
  run: pytest tests/integration/test_qwen3_train.py -v -s --device cuda --tb=short
```

#### 6.4 Regression Test Policy

- All PRs to `main` trigger lint + build checks
- Integration tests run on available self-hosted runners (CUDA auto, Ascend manual)
- New operator additions must include a corresponding `test_<op>_dispatch.py` file with:
  - At least one `@pytest.mark.anyplatform` correctness test
  - At least one dispatch routing verification test
- End-to-end tests (inference + training) serve as integration regression gates

#### 6.5 Acceptance Gate

A PR passes when:
1. `ruff check` and `ruff format --check` produce zero errors
2. All `anyplatform` operator tests pass on at least one platform (CUDA or Ascend)
3. End-to-end inference test generates valid output
4. End-to-end training test shows loss decrease without NaN

---

## Rollout Plan

### Phase 1 (Complete)

* Introduce multi-backend dispatch abstraction (`Dispatcher<FnPtr>`)
* Enable native CUDA and Ascend backends
* Add per-operator runtime backend selection via config file
* Implement 32 operators across both platforms
* End-to-end inference and training on Qwen3-0.6B

### Phase 2 (In Progress)

* Integrate FlagGems C++ dispatch (Triton → `liboperators.so`)
* Integrate FlagGems Python dispatch (pybind11 embed)
* Expand CI coverage to both CUDA and Ascend platforms
* Validate operator correctness across backend switches

### Phase 3 (Planned)

* Add MetaX (Muxi) backend support with FlagGems integration
* Expand operator coverage (conv, attention, norm ops)
* Performance benchmarking infrastructure
* Multi-backend DDP/FSDP integration
* Prepare for additional hardware backends (MUSA, etc.)

---

## References

* [FlagOS Community Repository](https://github.com/flagos-ai/community)
* [FlagGems Repository](https://github.com/flagos-ai/FlagGems)
* [PyTorch-Plugin-FL Repository](https://github.com/flagos-ai/PyTorch-Plugin-FL)
* [FlagTree Repository](https://github.com/flagos-ai/FlagTree)

# FEP-XXXX: FlagGems-sglang High-Performance Operator Library

**Status:** `Provisional`

**Created:** 2026-09-06

**Owner:** @liuhycs

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

---

## Summary

FlagGems-sglang is a high-performance operator library designed for SGLang framework, providing optimized implementations of common deep learning operators using Triton. This library enables efficient inference and deployment for various models on multiple hardware backends. Repository: https://github.com/flagos-ai/FlagGems-sglang

## Motivation

SGLang (Structured Generation Language) is a fast serving framework for large language models and vision language models. To achieve optimal performance across different hardware backends, there is a need for highly optimized operator implementations that can leverage hardware-specific features while maintaining portability through Triton.

### Goals

- Provide high-performance Triton-based implementations for common SGLang operators
- Support multiple hardware backends through a flexible vendor-agnostic architecture
- Achieve performance parity or improvements over reference implementations
- Enable seamless integration with SGLang framework
- Support critical operators including flashinfer-related operations, fused MoE, and specialized convolution kernels

### Non-Goals

- Replace the entire SGLang operator stack (only focus on performance-critical operators)
- Provide training-specific optimizations (focus on inference workloads)
- Support non-Triton backends in this initial release

## Proposal

FlagGems-sglang provides a three-level operator registration system that allows runtime selection of optimal implementations:

```
generic ops < vendor ops < arch ops
```

Users can import and use operators through a unified interface:

```python
import torch
import flaggems_sglang

x = torch.randn(1024, device='cuda')
y = flaggems_sglang.silu_and_mul(x)
```

The library automatically selects the best implementation based on the detected hardware.

## Design Details

### Architecture

The library follows a layered architecture:

1. **Runtime Layer** (`flaggems_sglang.runtime`):
   - `OpRegistrar`: Three-level operator registration and resolution
   - Device detection and vendor identification
   - Common utilities and error handling

2. **Operator Layer** (`flaggems_sglang.ops`):
   - Triton kernel implementations
   - Vendor-specific optimizations
   - Generic fallback implementations

3. **Reference Layer** (`flaggems_sglang.reference`):
   - PyTorch-based reference implementations for validation
   - Used in correctness testing

4. **Testing Layer** (`flaggems_sglang.testing`):
   - Accuracy validation utilities
   - Performance benchmarking framework

### Supported Operators

Currently implemented operators (v0.1.0):

- `silu_and_mul`: Fused SiLU activation and multiplication
- `fused_moe_gemm`: Fused mixture-of-experts GEMM operations
- `mrope_fused`: Fused multi-resolution RoPE (Rotary Position Embedding)
- `merge_state`: State merging for attention mechanisms
- `per_group_transpose`: Group-wise tensor transposition
- `causal_conv1d_fn`: Causal 1D convolution for sequence modeling
- `chunk_local_cumsum_scalar`: Chunked local cumulative sum with scalar output

### Multi-Backend Support

The library supports multiple hardware vendors through runtime detection:

- **NVIDIA GPUs**: CUDA backend with Triton
- **Huawei Ascend**: Ascend backend optimizations
- **Hygon DCU**: DCU-specific implementations
- **Tianshu**: Tianshu chip support
- **MetaX (Metax)**: MetaX accelerator optimizations
- **Kunlunxin**: Kunlun chip backend
- **Enflame**: `_enflame` backend with custom optimizations
- **Generic fallback**: CPU and other devices

Backend selection is automatic based on the device where tensors are allocated.

## Packaging

**Supported vendors:** NVIDIA, Huawei Ascend, Hygon DCU, Tianshu, MetaX, Kunlunxin, Enflame, and other hardware with Triton support

**Can this feature be packaged as a wheel (`.whl`)?** Yes

### Build Instructions

#### Prerequisites
```bash
pip install -U scikit-build-core>=0.11 pybind11 ninja cmake
```

#### Building from source
```bash
git clone https://github.com/flagos-ai/FlagGems-sglang.git
cd FlagGems-sglang
pip install .
```

This will produce a wheel in the `dist/` directory that can be distributed.

#### Platform Requirements
- Python >= 3.8.0
- PyTorch >= 2.6.0
- CUDA-capable GPU (for GPU execution)
- Triton (installed automatically with PyTorch)

## Test Plan

### Functional Testing

**Feature: Core operator correctness**
- Test command: 
  ```bash
  cd FlagGems-sglang
  pytest -q tests --quick
  ```
- Expected result: All tests pass with accuracy within tolerance (default: 1e-5 for float32)

**Feature: Individual operator validation**
- Test command (example for silu_and_mul):
  ```bash
  pytest -q tests/test_silu_and_mul.py --quick
  ```
- Expected result: Operator output matches PyTorch reference implementation within tolerance

**Feature: Multi-backend support**
- Test command:
  ```bash
  python -c "import flaggems_sglang; print(f'Device: {flaggems_sglang.device}, Vendor: {flaggems_sglang.vendor_name}')"
  ```
- Expected result: Correctly identifies the hardware backend (e.g., "cuda" and "nvidia" on NVIDIA GPUs)

### Performance Testing

**Feature: Operator performance benchmarking**
- Test command:
  ```bash
  pytest -q benchmark/test_silu_and_mul.py::test_silu_and_mul --level core --iter 10 --warmup 5
  ```
- Expected result: Performance metrics (latency, throughput) are logged, showing competitive or improved performance vs reference

**Feature: Full benchmark suite**
- Test command:
  ```bash
  cd benchmark
  python run_all_tests_perf.py --level core --iter 10 --warmup 5
  ```
- Expected result: Comprehensive performance report for all operators

### Compatibility Testing

**Feature: PyTorch integration**
- Test command:
  ```bash
  python -c "import torch; import flaggems_sglang; x=torch.randn(1024, device='cuda'); y=flaggems_sglang.silu_and_mul(x); print('Success')"
  ```
- Expected result: Operators work seamlessly with PyTorch tensors

## Related PRs

Implementation PRs will be tracked here:

- [ ] flagos-ai/FlagGems-sglang#1 — Initial operator implementations (silu_and_mul, fused_moe_gemm)
- [ ] flagos-ai/FlagGems-sglang#2 — Add mrope_fused and merge_state operators
- [ ] flagos-ai/FlagGems-sglang#3 — Enflame backend support
- [ ] flagos-ai/FlagGems-sglang#4 — Performance optimizations and benchmarking framework

## Implementation History

- 2026-08-17: Initial repository setup and core operators implemented
- 2026-08-31: Enflame backend support added
- 2026-09-06: FEP created and submitted for review

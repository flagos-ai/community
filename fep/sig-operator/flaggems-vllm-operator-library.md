# FEP: FlagGems-vllm - High-Performance Fused Operator Library for vLLM

**Status:** `Provisional`

**Created:** 2026-05-27

**Owner:** @flagos-ai

**SIG:** sig-operator

**Target Version:** FlagOS 2.1

---

## Summary

FlagGems-vllm is a high-performance fused operator library for vLLM inference workloads in the FlagOS ecosystem. It provides Triton-based fused kernels and vLLM-facing operator implementations for performance-critical paths such as MoE routing, cache update, rotary embedding, FP8 quantization, sequence packing, and DeepSeek V4 attention helpers. The repository maintains these fused operators together with multi-backend adaptation hooks, accuracy tests, and benchmark coverage. Repository: https://github.com/flagos-ai/FlagGems-vllm

## Motivation

The primary motivation of FlagGems-vllm is to improve vLLM inference performance by providing fused operator implementations for performance-critical execution paths. vLLM workloads frequently execute short operator sequences for MoE routing, KV cache update, rotary embedding, FP8 quantization, sequence layout conversion, and DeepSeek-style attention metadata preparation. Fusing these operations reduces kernel launch overhead, lowers memory traffic, and improves end-to-end inference throughput.

Another motivation is to prepare a unified operator layer for future multi-chip backend support. FlagOS targets diverse accelerator platforms, and vLLM-facing fused operators should be maintained with a consistent API, test suite, benchmark methodology, and backend adaptation mechanism. FlagGems-vllm keeps the implementation style and runtime conventions inherited from FlagGems while organizing the operator surface around fused kernels that can evolve from CUDA-first implementations to multiple chip backends over time.

### Goals

- Provide a dedicated home for high-performance vLLM fused operators under `flagos-ai/FlagGems-vllm`.
- Maintain Triton fused kernels for performance-critical vLLM paths, including MoE, cache update, rotary embedding, FP8 quantization, sequence pack/unpack, and DeepSeek V4 attention helper kernels.
- Reduce launch overhead and memory traffic by combining adjacent vLLM inference operations where practical.
- Keep API compatibility with the FlagGems operator style where practical, while exposing a `flaggems_vllm` Python package for direct use.
- Provide accuracy tests for each fused operator against PyTorch, vLLM, or equivalent reference implementations.
- Provide benchmark coverage following the FlagGems-vllm benchmark conventions for kernel-level and operator-level performance checks.
- Support future multi-backend adaptation using the same runtime specialization model as the FlagOS operator stack.

### Non-Goals

- It is not a replacement for vLLM itself or for `vllm-plugin-FL`.
- It does not implement model serving, scheduling, request routing, or distributed inference orchestration.
- It does not own general-purpose FlagGems operators that are unrelated to vLLM workloads or fused inference paths.
- It does not define new model architectures; it only provides operator implementations used by framework integrations.
- It does not guarantee that every upstream vLLM custom op is immediately reimplemented; coverage is expanded according to FlagOS inference requirements.

## Proposal

FlagGems-vllm provides a standalone Python package named `flaggems_vllm`. Users and framework integrations can install it and call high-performance fused operators directly from `flaggems_vllm.ops` or from the package top level.

Example direct use:

```python
import torch
import flaggems_vllm

num_tokens = 128
topk = 2
num_experts = 16
block_size = 32

topk_ids = torch.randint(
    low=0,
    high=num_experts,
    size=(num_tokens, topk),
    device="cuda",
    dtype=torch.int32,
)

sorted_ids, expert_ids, num_tokens_post_pad = flaggems_vllm.ops.moe_align_block_size(
    topk_ids=topk_ids,
    block_size=block_size,
    num_experts=num_experts,
)
```

The repository should track the vLLM-facing fused operator subset from FlagGems. When new vLLM-related fused kernels are merged into FlagGems, they should be mirrored into FlagGems-vllm together with:

1. the operator implementation under `src/flaggems_vllm/ops/`,
2. package exports in `src/flaggems_vllm/ops/__init__.py`,
3. accuracy tests under `tests/`, and
4. benchmark cases under `benchmark/`.

This keeps FlagGems as the main operator development repository while allowing FlagGems-vllm to serve as the smaller, performance-focused fused operator package for vLLM-related integration work.

## Design Details

### Repository Layout

The repository follows a lightweight Python package layout:

```text
FlagGems-vllm/
|-- src/flaggems_vllm/
|   |-- __init__.py
|   |-- config.py
|   |-- ops/
|   |   |-- __init__.py
|   |   |-- fused_moe.py
|   |   |-- moe_align_block_size.py
|   |   |-- reshape_and_cache.py
|   |   |-- rotary_embedding.py
|   |   |-- fused_inv_rope_fp8_quant.py
|   |   `-- ...
|   |-- runtime/
|   |-- testing/
|   `-- utils/
|-- tests/
|-- benchmark/
|-- tools/
`-- pyproject.toml
```

### Fused Operator Scope

The initial and ongoing fused operator scope includes:

- MoE routing and execution fusion, such as `moe_align_block_size`, `moe_sum`, `grouped_topk`, and fused expert kernels.
- Cache update and layout fusion, such as `reshape_and_cache`, `reshape_and_cache_flash`, `concat_and_cache_mla`, and vLLM MLA cache kernels.
- Activation and normalization fusion used by inference models, such as `silu_and_mul`, `gelu_and_mul`, `fused_add_rms_norm`, and `skip_layer_norm`.
- Attention-related fusion, including sparse attention, FlashMLA helpers, rotary embedding, sequence pack/unpack, and DeepSeek V4 attention helper kernels.
- Quantization-related fusion used by vLLM inference paths, including FP8 quantization helpers and FP8-oriented fused kernels.

### Runtime and Backend Adaptation

FlagGems-vllm keeps the runtime structure from FlagGems:

- `runtime/` selects the active device and backend.
- `utils/` provides Triton helper functions, device information, code cache utilities, and dynamic pointwise wrappers.
- Backend-specific behavior can be introduced through runtime specialization without changing the public operator API.

This design allows the same operator API to be used across supported hardware backends as implementations become available.

### Multi-Chip Backend Support

FlagGems-vllm is organized around a vendor-neutral Python operator API and a runtime backend layer. The public operator entry points, such as `grouped_topk`, `fused_experts_impl`, `moe_align_block_size`, cache update kernels, rotary embedding helpers, and DeepSeek V4 helper kernels, should remain stable across accelerator vendors. Backend differences are handled by runtime device detection, vendor metadata, backend-specific configuration files, and optional vendor-specialized operator overrides.

The current backend structure follows the FlagGems model:

- NVIDIA/CUDA is the primary bring-up and performance validation backend for Triton fused kernels.
- Iluvatar is represented as a backend specialization directory and can provide vendor-specific tuning data or operator overrides.
- The runtime vendor registry reserves names for additional accelerator families used in the FlagOS operator stack, including Cambricon, MThreads, Kunlunxin, Hygon, AMD, AIPU, Ascend, Tsingmicro, and Sunrise.

For each backend, the intended extension pattern is:

1. add or update vendor metadata under `src/flaggems_vllm/runtime/backend/_<vendor>/`,
2. provide vendor tune and heuristic configs when the generic Triton config is not sufficient,
3. add backend-specific fused operator implementations only when the generic implementation is unavailable or underperforms,
4. keep the top-level `flaggems_vllm` operator API unchanged, and
5. add backend-aware skip conditions, accuracy tests, and benchmark coverage for the supported operator subset.

This means backend support can be staged. A backend may first support import, runtime detection, collection, and a small smoke-test subset; it can then expand to full accuracy coverage and finally to tuned performance coverage for vLLM inference workloads.

### Testing and Benchmarking

Each migrated fused operator should include:

- an accuracy test under `tests/` using PyTorch, vLLM, or a local reference implementation,
- a benchmark under `benchmark/` following the existing `GenericBenchmark` conventions where applicable,
- skip conditions for unavailable hardware, unavailable vLLM reference ops, or unsupported dtype features, and
- coverage for edge cases that are important to the vLLM calling convention.

## Packaging

FlagGems-vllm is packaged as a Python project using `pyproject.toml`.

Build and install from source:

```bash
git clone https://github.com/flagos-ai/FlagGems-vllm.git
cd FlagGems-vllm
pip install .
```

Editable install for development:

```bash
pip install -e .
```

Package metadata:

- Python package name: `flaggems_vllm`
- Packaging format: Python wheel / source install through `pip`
- Build backend: `setuptools`
- Runtime dependencies: PyTorch, packaging utilities, PyYAML, SQLAlchemy, and backend-specific Triton/runtime dependencies
- Optional test dependencies: pytest, numpy, scipy, and CUDA-specific array/runtime packages where needed
- Platform requirements: Linux with a supported accelerator runtime; most tests and benchmarks require CUDA or a compatible backend runtime

## Test Plan

| Goal | Verification Method |
|------|---------------------|
| Dedicated package import | Install the package, import `flaggems_vllm` and `flaggems_vllm.ops`, and print the detected device and selected operator availability. |
| Fused operator API availability | Check that exported package symbols include representative vLLM-facing operators such as `grouped_topk`, `moe_align_block_size`, `reshape_and_cache`, and `fused_inv_rope_fp8_quant`. |
| Test discovery | Run `pytest -q tests --collect-only` before functional execution to catch import, marker, and skip-condition regressions. |
| Accuracy coverage | Run `pytest -q tests --quick` plus targeted operator tests for MoE, cache update, rotary embedding, FP8 quantization, and DeepSeek V4 helpers. |
| vLLM reference compatibility | Run tests that compare against vLLM custom ops when vLLM is installed; otherwise verify that they skip cleanly. |
| Benchmark collection | Run `pytest -q benchmark --collect-only` to validate benchmark imports and parameterization. |
| Benchmark smoke runs | Run representative benchmarks with `--level core --iter 1 --warmup 1` for fast kernel-level performance validation. |
| Multi-backend readiness | Run collection and import smoke tests on each available backend, using backend/vendor environment selection where needed, and verify unsupported operators skip rather than fail. |
| Packaging validation | Build and install from a clean checkout using `pip install .`, then run import, collection, selected accuracy tests, and selected benchmark smoke tests. |

Representative setup and import smoke test:

```bash
cd FlagGems-vllm
pip install .
PYTHONPATH=$PWD/src python - <<'PY'
import torch
import flaggems_vllm
import flaggems_vllm.ops as ops

print("torch:", torch.__version__)
print("device:", flaggems_vllm.device)
print("grouped_topk:", callable(flaggems_vllm.grouped_topk))
print("moe_align_block_size:", hasattr(ops, "moe_align_block_size"))
PY
```

Collection and quick accuracy checks:

```bash
cd FlagGems-vllm
PYTHONPATH=$PWD/src pytest -q tests --collect-only
PYTHONPATH=$PWD/src pytest -q tests --quick
PYTHONPATH=$PWD/src pytest -q tests/test_moe_align_block_size.py --quick
PYTHONPATH=$PWD/src pytest -q tests/test_grouped_topk.py
PYTHONPATH=$PWD/src pytest -q tests/test_reshape_and_cache.py
PYTHONPATH=$PWD/src pytest -q tests/test_fused_inv_rope_fp8_quant.py --quick
```

DeepSeek V4 and cache helper checks, when the required CUDA/vLLM reference environment is available:

```bash
cd FlagGems-vllm
PYTHONPATH=$PWD/src pytest -q tests/test_deepseek_v4_attention_fused_q_kv_rmsnorm.py
PYTHONPATH=$PWD/src pytest -q tests/test_deepseek_v4_attention_dequantize_and_gather_k_cache.py
PYTHONPATH=$PWD/src pytest -q tests/test_cp_gather_indexer_k_quant_cache.py
PYTHONPATH=$PWD/src pytest -q tests/test_concat_and_cache_mla.py
```

Benchmark collection and smoke runs:

```bash
cd FlagGems-vllm
PYTHONPATH=$PWD/src pytest -q benchmark --collect-only
PYTHONPATH=$PWD/src pytest -q benchmark/test_moe_align_block_size_triton.py::test_moe_align_block_size_triton --level core --iter 1 --warmup 1
PYTHONPATH=$PWD/src pytest -q benchmark/test_grouped_topk.py --level core --iter 1 --warmup 1
PYTHONPATH=$PWD/src pytest -q benchmark/test_fused_inv_rope_fp8_quant.py --level core --iter 1 --warmup 1
PYTHONPATH=$PWD/src pytest -q benchmark/test_fused_moe_w8a16.py --level core --iter 1 --warmup 1
```

Multi-backend validation should be run on each available accelerator platform. The exact environment variable may be provided by the runtime integration, but the validation pattern is:

```bash
cd FlagGems-vllm
export FLAGGEMS_VENDOR=<vendor-name>
PYTHONPATH=$PWD/src python -c "import flaggems_vllm; print(flaggems_vllm.vendor_name, flaggems_vllm.device)"
PYTHONPATH=$PWD/src pytest -q tests --collect-only
PYTHONPATH=$PWD/src pytest -q tests --quick
PYTHONPATH=$PWD/src pytest -q benchmark --collect-only
```

For backend bring-up, a passing result may include backend-specific skips for unsupported operators or unsupported dtype features. A failure is expected only when an operator is advertised as supported on that backend but cannot pass import, accuracy, or benchmark smoke validation.

## Related PRs

- [ ] flagos-ai/FlagGems-vllm - Initial repository and package setup
- [ ] flagos-ai/FlagGems-vllm - Mirror latest vLLM-facing operators from FlagGems with tests and benchmarks
- [ ] flagos-ai/FlagGems - Source operator implementations used as the upstream reference for migration

## Implementation History

- 2026-05-27: FEP created for FlagGems-vllm under `sig-operator`.

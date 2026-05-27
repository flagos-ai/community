# FEP: FlagGems-vllm - vLLM-Oriented Operator Library for FlagOS

**Status:** `Provisional`

**Created:** 2026-05-27

**Owner:** @flagos-ai

**SIG:** sig-operator

**Target Version:** FlagOS 2.1

---

## Summary

FlagGems-vllm is a high-performance operator library for vLLM-oriented inference workloads in the FlagOS ecosystem. It extracts and maintains the vLLM-relevant fused and non-fused operators from FlagGems in a dedicated repository, providing Triton-based implementations, multi-backend adaptation hooks, accuracy tests, and benchmark coverage for operators used by vLLM and related FlagOS inference integrations. Repository: https://github.com/flagos-ai/FlagGems-vllm

## Motivation

FlagGems contains a broad collection of general-purpose PyTorch and fused operators, while vLLM inference workloads require a narrower and faster-moving operator subset such as MoE routing, cache update, rotary embedding, FP8 quantization, MLA/DeepSeek-specific kernels, and sequence pack/unpack helpers. Keeping all vLLM-facing kernels only in the main FlagGems repository makes it harder to align with vLLM release cadence, test against vLLM-specific reference implementations, and maintain a lightweight dependency boundary for framework integration.

FlagGems-vllm addresses this by providing a dedicated operator repository for the vLLM path. The repository keeps the implementation style and runtime conventions inherited from FlagGems, while organizing the operator surface, tests, and benchmarks around vLLM usage.

### Goals

- Provide a dedicated home for vLLM-oriented FlagGems operators under `flagos-ai/FlagGems-vllm`.
- Maintain Triton implementations for commonly used vLLM fused and non-fused operators, including MoE, cache, rotary embedding, FP8 quantization, and DeepSeek V4 attention helper kernels.
- Keep API compatibility with the FlagGems operator style where practical, while exposing a `flaggems_vllm` Python package for direct use.
- Provide accuracy tests for each migrated operator against PyTorch, vLLM, or equivalent reference implementations.
- Provide benchmark coverage following the FlagGems-vllm benchmark conventions for kernel-level and operator-level performance checks.
- Support future multi-backend adaptation using the same runtime specialization model as the FlagOS operator stack.

### Non-Goals

- It is not a replacement for vLLM itself or for `vllm-plugin-FL`.
- It does not implement model serving, scheduling, request routing, or distributed inference orchestration.
- It does not own general-purpose FlagGems operators that are unrelated to vLLM workloads.
- It does not define new model architectures; it only provides operator implementations used by framework integrations.
- It does not guarantee that every upstream vLLM custom op is immediately reimplemented; coverage is expanded according to FlagOS inference requirements.

## Proposal

FlagGems-vllm provides a standalone Python package named `flaggems_vllm`. Users and framework integrations can install it and call operators directly from `flaggems_vllm.ops` or from the package top level.

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

The repository should track the vLLM-facing operator subset from FlagGems. When new vLLM-related kernels are merged into FlagGems, they should be mirrored into FlagGems-vllm together with:

1. the operator implementation under `src/flaggems_vllm/ops/`,
2. package exports in `src/flaggems_vllm/ops/__init__.py`,
3. accuracy tests under `tests/`, and
4. benchmark cases under `benchmark/`.

This keeps FlagGems as the main operator development repository while allowing FlagGems-vllm to serve as the smaller framework-facing package for vLLM-related integration work.

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

### Operator Scope

The initial and ongoing operator scope includes:

- MoE routing and execution helpers, such as `moe_align_block_size`, `moe_sum`, `grouped_topk`, and fused expert kernels.
- Cache update and layout helpers, such as `reshape_and_cache`, `reshape_and_cache_flash`, `concat_and_cache_mla`, and vLLM MLA cache kernels.
- Activation and normalization fused kernels used by inference models, such as `silu_and_mul`, `gelu_and_mul`, `fused_add_rms_norm`, and `skip_layer_norm`.
- Attention-related kernels, including sparse attention, FlashMLA helpers, rotary embedding, sequence pack/unpack, and DeepSeek V4 attention helper kernels.
- Quantization-related kernels used by vLLM inference paths, including FP8 quantization helpers and FP8-oriented fused kernels.

### Runtime and Backend Adaptation

FlagGems-vllm keeps the runtime structure from FlagGems:

- `runtime/` selects the active device and backend.
- `utils/` provides Triton helper functions, device information, code cache utilities, and dynamic pointwise wrappers.
- Backend-specific behavior can be introduced through runtime specialization without changing the public operator API.

This design allows the same operator API to be used across supported hardware backends as implementations become available.

### Testing and Benchmarking

Each migrated operator should include:

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
| Dedicated package import | Run `python -c "import flaggems_vllm; import flaggems_vllm.ops"` after installation. |
| Operator API availability | Verify exported symbols from `flaggems_vllm.ops.__all__` include the migrated vLLM-facing operators. |
| Accuracy coverage | Run `pytest -q tests --collect-only` and targeted tests such as `pytest -q tests/test_moe_align_block_size.py --quick`. |
| DeepSeek V4 helper coverage | Run the DeepSeek V4 attention helper tests when the matching CUDA/vLLM reference environment is available. |
| Benchmark coverage | Run benchmark collection with `pytest -q benchmark --collect-only` and targeted benchmarks with `--level core --iter 1 --warmup 1`. |
| Multi-backend readiness | Verify that backend-specific skip conditions and runtime device detection do not break collection on unsupported platforms. |
| Packaging validation | Build and install from a clean checkout using `pip install .`, then run import and selected smoke tests. |

Representative commands:

```bash
cd FlagGems-vllm
pip install .
pytest -q tests --collect-only
pytest -q benchmark --collect-only
pytest -q tests/test_moe_align_block_size.py --quick
pytest -q benchmark/test_moe_align_block_size_triton.py::test_moe_align_block_size_triton --level core --iter 1 --warmup 1
```

## Related PRs

- [ ] flagos-ai/FlagGems-vllm - Initial repository and package setup
- [ ] flagos-ai/FlagGems-vllm - Mirror latest vLLM-facing operators from FlagGems with tests and benchmarks
- [ ] flagos-ai/FlagGems - Source operator implementations used as the upstream reference for migration

## Implementation History

- 2026-05-27: FEP created for FlagGems-vllm under `sig-operator`.

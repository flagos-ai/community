# FEP-0004: KernelGenBench - Multi-Chip Triton Kernel Generation Benchmark

**Status:** `Implementable`

**Created:** 2025-05-25

**Owner:** @factnn

**SIG:** sig-kernelgen

**Target Version:** FlagOS 2.1

---

## Summary

KernelGenBench is an end-to-end Triton kernel generation and verification benchmark framework. It supports LLM-driven Triton kernel generation, correctness validation, and performance benchmarking. This is its initial release as a new component in FlagOS 2.1, supporting 6 chip platforms.

## Motivation

There is currently no unified cross-platform evaluation standard for Triton kernel generation. Different chip vendors have varying levels of Triton support, and an automated framework is needed to assess the correctness and performance of LLM-generated kernels, providing quantifiable benchmarks for operator development.

### Goals

- Provide a standardized Triton kernel generation evaluation pipeline (generation → verification → performance testing)
- Support 3 sub-datasets: aten (110 ops), vllm (50 ops), cublas (50 ops)
- Cover 6 chip platforms: NVIDIA, Ascend, MUSA, Hygon, Iluvatar, MetaX
- Support Pass@K iterative verification workflow
- Integrate 3 SOTA agent methods: AutoKernel, AKO4ALL, cuda-optimized-skill

### Non-Goals

- Not responsible for Triton compiler adaptation
- Not providing chip driver-level support

## Proposal

After installing via `pip install kernelgenbench`, users can:
1. Select the target chip platform and sub-dataset
2. Configure the LLM backend to generate Triton kernels
3. Automatically run correctness validation (compared against PyTorch reference)
4. Output pass rate and performance reports

## Design Details

### Architecture

Three-layer structure:
1. **Generator Layer** — LLM generates Triton kernel code
2. **Sandbox/Verifier Layer** — Isolated execution and correctness verification
3. **Benchmark Layer** — Performance benchmarking and result collection

### Multi-Chip Support

The `device_manager.py` module automatically detects the current hardware platform, loads the corresponding prompt templates and compilation constraints, enabling a single codebase to work across multiple platforms.

## Test Plan

### Functional Verification

| Module | Test Case | Description |
|--------|-----------|-------------|
| Agent benchmark | `bash agent_bench/test_ops.sh add` | Single-operator end-to-end: generate prompt → agent generates kernel → verify |
| Full benchmark | `bash agent_bench/test_ops.sh -d KernelGenBench` | Full dataset agent benchmark |
| Single-op generation | `python scripts/generate_kernel_and_verify.py --op-name add` | Single-operator Pass@K generation and verification |
| Full generation | `python scripts/generate_kernel_and_verify.py --dataset KernelGenBench` | Full dataset Pass@K generation and verification |
| Sub-dataset coverage | Run aten/vllm/cublas datasets separately | All dataset operator lists are complete and loadable |
| SOTA Agent | `bash agent_bench/test_autokernel.sh` / `test_ako4all.sh` / `test_cuda_optimized_skill.sh` | All three agent methods run successfully and produce results |
| Device detection | `agent_bench/device_manager.py` | All platforms auto-detected, correct templates loaded |

### Compatibility Verification

| Platform | Verification |
|----------|--------------|
| NVIDIA | Device detection, template loading, kernel compilation and execution, correctness validation passed |
| Ascend | Device detection, template loading, kernel compilation and execution, correctness validation passed |
| MUSA | Device detection, template loading, kernel compilation and execution, correctness validation passed |
| Hygon | Device detection, template loading, kernel compilation and execution, correctness validation passed |
| Iluvatar | Device detection, template loading, kernel compilation and execution, correctness validation passed |
| MetaX | Device detection, template loading, kernel compilation and execution, correctness validation passed |

## Related PRs

- [ ] flagos-ai/KernelGenBench — Initial release

## Implementation History

- 2025-05-25: FEP created

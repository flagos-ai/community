# FEP-0004: KernelGenBench - Multi-Chip Triton Kernel Generation Benchmark

**Status:** `Implemented`

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
- Integrate 3 kernel-specialized methods: AutoKernel, AKO4ALL, cuda-optimized-skill

### Non-Goals

- Not responsible for Triton compiler adaptation
- Not providing chip driver-level support

## Proposal

After installing via `pip install kernelgenbench`, users can:
1. Select the target chip platform and sub-dataset
2. Configure the LLM backend to generate Triton kernels
3. Automatically run correctness validation (compared against PyTorch reference)
4. Output pass rate and performance reports

### Distribution

- Provide wheel (.whl) packages for easy installation
- Build command: `python setup.py bdist_wheel` or `pip wheel .`
- Per-platform requirements files under `requirements/` (following FlagGems convention)

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
| Kernel-specialized methods | `bash agent_bench/test_autokernel.sh` / `test_ako4all.sh` / `test_cuda_optimized_skill.sh` | All three kernel-specialized methods run successfully and produce results |
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

### Test Environment (Docker)

NVIDIA / Hygon / Iluvatar / MetaX use the default FlagTree vendor images.
Ascend and MUSA require the following specific images:

#### Ascend NPU (910b)

```bash
docker run -dit --name svt-ascend \
  --privileged --network=host --ipc=host --shm-size=64g \
  --device=/dev/davinci0 --device=/dev/davinci1 \
  --device=/dev/davinci2 --device=/dev/davinci3 \
  --device=/dev/davinci4 --device=/dev/davinci5 \
  --device=/dev/davinci6 --device=/dev/davinci7 \
  --device=/dev/davinci_manager --device=/dev/hisi_hdc \
  --volume /usr/local/sbin:/usr/local/sbin \
  --volume /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  --volume /public-flash:/public-flash \
  --volume /etc/ascend_install.info:/etc/ascend_install.info \
  harbor.baai.ac.cn/flagtree/flagtree-ascend-910c-py311-torch2.6.0-cann8.5.0-ubuntu22.04-aarch64:202603 \
  bash
```

#### MUSA (S5000)

```bash
IMAGE=harbor.baai.ac.cn/flagtree/flagtree-mthreads3.6-py310-torch2.7.1-musa5.1.0-ubuntu22.04:202605-base
CONTAINER=flagtree-dev-xxx
docker run -dit \
    --network=host --pid=host --privileged \
    --cap-add=SYS_PTRACE \
    --shm-size 16gb \
    --security-opt seccomp=unconfined \
    -e MTHREADS_VISIBLE_DEVICES=all -e MTHREADS_DRIVER_CAPABILITIES=all \
    -v /usr/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu \
    -v /lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu \
    -v /etc/alternatives:/etc/alternatives \
    -v /etc/localtime:/etc/localtime:ro \
    -v /data:/data -v /home:/home -v /tmp:/tmp \
    -w /root --name ${CONTAINER} ${IMAGE} bash
```

## Related PRs

- [ ] flagos-ai/KernelGenBench — Initial release

## Implementation History

- 2025-05-25: FEP created

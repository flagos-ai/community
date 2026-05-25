# FEP-0004: KernelGenBench - Multi-Chip Triton Kernel Generation Benchmark

**Status:** `Implementable`

**Created:** 2025-05-25

**Owner:** @factnn

**SIG:** sig-kernelgen

**Target Version:** FlagOS 2.1

---

## Summary

KernelGenBench 是一个端到端的 Triton kernel 生成与验证基准测试框架，支持 LLM 自动生成 Triton kernel、正确性验证和性能评测。本次作为 FlagOS 2.1 新组件首次发布，支持 6 款芯片平台。

## Motivation

当前缺乏统一的跨平台 Triton kernel 生成评估标准。各芯片厂商的 Triton 支持程度不一，需要一个自动化框架来评估 LLM 生成 kernel 的正确性和性能，为算子开发提供可量化的基准。

### Goals

- 提供标准化的 Triton kernel 生成评测流程（生成 → 验证 → 性能测试）
- 支持 3 个子数据集：aten (110 ops)、vllm (50 ops)、cublas (50 ops)
- 覆盖 6 款芯片平台：NVIDIA、Ascend、MUSA、Hygon、Iluvatar、MetaX
- 支持 Pass@K 迭代验证流程
- 集成 3 种 SOTA agent 方法：AutoKernel、AKO4ALL、cuda-optimized-skill

### Non-Goals

- 不负责 Triton 编译器本身的适配工作
- 不提供芯片驱动层面的支持

## Proposal

用户通过 `pip install kernelgenbench` 安装后，可以：
1. 选择目标芯片平台和子数据集
2. 配置 LLM 后端生成 Triton kernel
3. 自动运行正确性验证（与 PyTorch 参考实现对比）
4. 输出 pass rate 和性能报告

## Design Details

### 架构

三层结构：
1. **Generator Layer** — LLM 生成 Triton kernel 代码
2. **Sandbox/Verifier Layer** — 隔离执行与正确性验证
3. **Benchmark Layer** — 性能评测与结果收集

### 多芯片支持

通过 `device_manager.py` 自动检测当前硬件平台，加载对应的 prompt 模板和编译约束，实现一套代码适配多平台。

## Test Plan

### 功能验证

| 模块 | 验证 Case | 说明 |
|------|-----------|------|
| Agent 评测 | `bash agent_bench/test_ops.sh add` | 单算子端到端：生成 prompt → agent 生成 kernel → 验证 |
| 全量评测 | `bash agent_bench/test_ops.sh -d KernelGenBench` | 全数据集 agent 评测 |
| 单算子生成与验证 | `python scripts/generate_kernel_and_verify.py --op-name add` | 单算子 Pass@K 生成与验证 |
| 全量生成与验证 | `python scripts/generate_kernel_and_verify.py --dataset KernelGenBench` | 全数据集 Pass@K 生成与验证 |
| 子数据集覆盖 | 分别运行 aten/vllm/cublas 数据集 | 各数据集算子列表完整、可加载 |
| SOTA Agent | `bash agent_bench/test_autokernel.sh` / `test_ako4all.sh` / `test_cuda_optimized_skill.sh` | 三种 agent 方法可正常运行并输出结果 |
| 设备检测 | `agent_bench/device_manager.py` | 各平台设备自动检测、模板正确加载 |

### 性能验证

| 指标 | 要求 |
|------|------|
| Pass@1 通过率 | aten 数据集 ≥ 60% |
| Pass@10 通过率 | aten 数据集 ≥ 80% |
| 生成 kernel Speedup | 与 PyTorch eager 对比，平均 speedup ≥ 1.0x |

### 兼容性验证

| 平台 | 验证内容 |
|------|----------|
| NVIDIA | 设备检测、模板加载、kernel 编译运行、正确性验证通过 |
| Ascend | 设备检测、模板加载、kernel 编译运行、正确性验证通过 |
| MUSA | 设备检测、模板加载、kernel 编译运行、正确性验证通过 |
| Hygon | 设备检测、模板加载、kernel 编译运行、正确性验证通过 |
| Iluvatar | 设备检测、模板加载、kernel 编译运行、正确性验证通过 |
| MetaX | 设备检测、模板加载、kernel 编译运行、正确性验证通过 |

## Related PRs

- [ ] flagos-ai/KernelGenBench — 主仓库首次发布

## Implementation History

- 2025-05-25: FEP 创建

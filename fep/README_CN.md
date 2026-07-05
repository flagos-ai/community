# FEP — FlagOS Enhancement Proposal

[English](README.md) | [中文](README_CN.md)

## 什么是 FEP

FEP (FlagOS Enhancement Proposal) 是 FlagOS 的特性管理机制。每个跨模块或重大特性对应一个 FEP——一份 Markdown 设计文档，存放在 `fep/sig-*/` 目录下，通过 PR 提交和评审。

**工具链**: GitHub PR + Markdown 文件 + [SIG OWNERS](../sigs/) 审批

> **新手?** 先看 [FEP 编写指引](../contributors/fep-guide.md)。**Approver?** 看 [FEP 评审指南](REVIEW_GUIDE.md)。治理规则见 [GOVERNANCE.md](../GOVERNANCE.md)。

## 🚩 版本追踪 (Release Tracker)

按 FlagOS 版本实时展示 FEP 进度。徽章直接读取 GitHub Milestones API,自动更新。看板视图:[**FlagOS FEP Tracker** — 按 FEP Status 分组](https://github.com/orgs/flagos-ai/projects/6/views/1?layout=board&groupedBy%5BcolumnId%5D=365272770)。

[![FlagOS 2.1](https://img.shields.io/github/milestones/progress-percent/flagos-ai/community/1?label=FlagOS%202.1&color=brightgreen)](https://github.com/flagos-ai/community/milestone/1)
[![FlagOS 2.2](https://img.shields.io/github/milestones/progress-percent/flagos-ai/community/2?label=FlagOS%202.2&color=blue)](https://github.com/flagos-ai/community/milestone/2)

| 版本 | 截止 | 状态 | FEP Milestone |
|------|------|------|---------------|
| **FlagOS 2.1** | 2026-06-11 | ✅ 已发布 — FEP 全部合入 | [milestone/1](https://github.com/flagos-ai/community/milestone/1) |
| **FlagOS 2.2** | 2026-09-28 | 🔵 进行中 — 接受 FEP | [milestone/2](https://github.com/flagos-ai/community/milestone/2) |

> FEP 的 Owner 将 `Target Version` 设为某版本后,该 FEP 即挂入对应的 release milestone(详见 [Milestone 使用](#milestone-使用))。

## SIG 分组

### 活跃 SIG (7 个)

| SIG | 模块 |
|-----|---------|
| `sig-operator` | FlagGems, FlagAttention, FlagFFT, FlagSparse, FlagDNN, FlagBLAS, FlagTensor, FlagAudio |
| `sig-compiler` | FlagTree |
| `sig-network` | FlagCX |
| `sig-framework` | PyTorch-Plugin-FL, vllm-plugin-FL, sglang-plugin-FL, TransformerEngine-FL, Megatron-LM-FL, verl-FL |
| `sig-training` | FlagScale |
| `sig-kernelgen` | KernelGen, KernelGenBench |
| `sig-chip` | 数据中心芯片适配 |

### 规划中 / 孵化中

以下方向已识别但尚无 Approver，FEP 由 TSC 直接审批。详见 [SIG 总览](../sigs/README.md)。

| 方向 | 类型 | 模块 |
|------|------|------|
| `sig-benchmark` | 规划中 SIG | FlagPerf |
| `sig-agent` | 规划中 SIG | Skills |
| `sig-tools` | 规划中 SIG | FlagRelease |
| `sig-edge` | 规划中 SIG | 端侧硬件 |
| `sig-architecture` | 规划中 SIG | 跨模块功能、流程变更 |
| `sig-os` | 规划中 SIG | 操作系统打包、发行版集成（openKylin、openEuler） |
| `sig-riscv` | 规划中 SIG | RISC-V 实验性支持 — 编译适配、依赖分析 |
| `wg-embodied` | 孵化 WG | FlagOS-Robo |
| `wg-ai4s` | 孵化 WG | FlagQuantum |

## 何时需要编写 FEP

| 场景 | 是否需要 FEP |
|----------|---------------|
| 跨模块特性 | **必须** |
| 新芯片支持 | **必须** |
| 新模块 / 仓库 | **必须** |
| 模块级重大特性 | **建议** |
| 单仓库小功能 / bug 修复 | 不需要 |
| 文档改进 | 不需要 |

## FEP 生命周期

```
Provisional ──→ Implementable ──→ Implemented
     │                                ↑
     ├──→ Deferred ──────────────────┘
     └──→ Rejected
```

| 状态 | 含义 | 操作 |
|--------|---------|--------|
| **Provisional** | 草案，SIG 讨论中 | 在 PR 中迭代 |
| **Implementable** | 设计已批准，可开始实现 | SIG Approver 批准 PR 后合入 |
| **Implemented** | 代码已合入，验收标准已满足 | 通过 PR 更新文档 |
| **Deferred** | 推迟到后续版本 | 移至下一 Milestone |
| **Rejected** | 不再推进 | 关闭 PR；被拒绝的 FEP 仍应合入以保留决策记录 |

> 状态在 FEP 文档中标注为 `**Status:** <value>`，每次状态变更通过后续 PR 更新。

## 工作流程

### 0. 与 SIG 沟通

在编写 FEP 之前，先与相关 SIG 讨论想法。确保该 SIG 对问题领域有兴趣并愿意评审。

> **启动期**：如果相关 SIG 尚无 Chair、Approver 或例会，在目标模块仓库提 Issue 或在 [GitHub Discussions](https://github.com/FlagOS-AI/community/discussions) 发帖。TSC（或 TSC 成立前的众智FlagOS社区）将负责流转和评审。详见 [GOVERNANCE.md](../GOVERNANCE.md)。

### 1. 创建 FEP 文档

将 [FEP 模板](fep-template/README.md) 复制到 `fep/sig-xxx/title-slug.md`。

- `title-slug` 是一个简短的英文连字符描述
- 起步最小内容：Summary + Motivation，其余后续补充
- 初始 Status 设为 `Provisional`

### 2. 提交 PR

提交包含 FEP 文件的 PR。

- PR 标题应描述该特性
- PR 描述可以简略——FEP 文档承载详细内容
- 早期需要更多讨论的想法请使用 **Draft PR**

### 3. 评审与批准

评审、讨论和迭代在 PR 上进行。

- SIG Approver（列在 OWNERS 中）批准 PR
- **启动期**：如果相关 SIG 尚无 Approver，TSC 直接评审。如需帮助流转，在 [GitHub Discussions](https://github.com/FlagOS-AI/community/discussions) 发帖。
- 批准后，将 Status 更新为 `Implementable`
- 合入 PR

**跨 SIG FEP**：选择一个归属 SIG 作为文件存放目录。受影响的 SIG 也应参与评审。如果没有现有 SIG 适用，使用 `sig-architecture`（启动期）或咨询 TSC 获取流转建议。

### 4. 实现

- 在相关仓库中进行实现
- 在 FEP 文档的 `Related PRs` 章节中追踪相关 PR
- 当范围或设计变更时，通过后续 PR 更新 FEP 文档

### 5. 收尾

- 所有验收标准满足后，将 Status 更新为 `Implemented`
- 通过最终 PR 更新 FEP 文档

## 文件命名

| 约定 | 适用时机 |
|------------|------|
| `title-slug.md` | PR 创建前或早期草稿阶段 |
| `NNNN-title-slug.md` | PR 创建后，NNNN 为 PR 编号 |

> 合入前将文件重命名为包含 PR 编号。PR 编号作为 FEP 标识符。

## 角色

| 角色 | 职责 |
|------|-----------------|
| **FEP Owner** | 编写 FEP、推动实现、更新状态、确保验收 |
| **SIG Approver** | 评审和批准 FEP 文档（列在 [SIG OWNERS](../sigs/) 中） |
| **Release Manager** | 追踪各版本 FEP 整体进度，Go/No-Go 决策 |

> 完整角色定义和晋升路径见 [contributors/roles.md](../contributors/roles.md)。

## Milestone 使用

- 每个 FlagOS 版本对应一个 Milestone（如 `FlagOS 2.1`）
- Milestone 设有截止日期
- 目标版本的 FEP 关联到对应的 Milestone
- Release Manager 通过 Milestone 视图追踪进度
- 各版本实时进度展示在本页顶部的 [🚩 版本追踪](#-版本追踪-release-tracker)

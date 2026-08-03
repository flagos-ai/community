# FEP — FlagOS Enhancement Proposal

[English](README.md) | [中文](README_CN.md)

## 什么是 FEP

FEP (FlagOS Enhancement Proposal) 是 FlagOS 的特性管理机制。每个跨模块或重大特性对应一个 FEP——一份 Markdown 设计文档，存放在 `fep/sig-*/` 目录下，通过 PR 提交和评审。

**工具链**: GitHub PR + Markdown 文件 + [SIG OWNERS](../sigs/) 审批

> **新手?** 先看 [FEP 编写指引](../contributors/fep-guide.md)。**Approver?** 看 [FEP 评审指南](REVIEW_GUIDE.md)。治理规则见 [GOVERNANCE.md](../GOVERNANCE.md)。

## 🚩 版本追踪 (Release Tracker)

按 FlagOS 版本实时展示 FEP 进度。徽章直接读取 GitHub Milestones API,自动更新。看板:[**FlagOS FEP Tracker**](https://github.com/orgs/flagos-ai/projects/6)(视图说明见[标签、Milestone 与看板](#标签milestone-与看板))。

[![FlagOS 2.1](https://img.shields.io/github/milestones/progress-percent/flagos-ai/community/1?label=FlagOS%202.1&color=brightgreen)](https://github.com/flagos-ai/community/milestone/1)
[![FlagOS 2.2](https://img.shields.io/github/milestones/progress-percent/flagos-ai/community/2?label=FlagOS%202.2&color=blue)](https://github.com/flagos-ai/community/milestone/2)

| 版本 | 截止 | 状态 | FEP Milestone |
|------|------|------|---------------|
| **FlagOS 2.1** | 2026-06-11 | ✅ 已发布 — FEP 全部合入 | [milestone/1](https://github.com/flagos-ai/community/milestone/1) |
| **FlagOS 2.2** | 2026-09-28 | 🔵 进行中 — 接受 FEP | [milestone/2](https://github.com/flagos-ai/community/milestone/2) |

> **FlagOS 2.2 关键日期** — 特性冻结(Feature Freeze):**2026-08-31** · 测试期:09-01 → 09-24。完整时间表与冻结规则:[release/2.2/schedule_CN.md](../release/2.2/schedule_CN.md)。

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
| `sig-edge` | 规划中 SIG | 端侧硬件与 FlagOS 端侧 SDK |
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
| **Provisional** | 草案，SIG 讨论中 | 在 PR 中迭代。FEP 可以在 `Provisional` 状态合入——合入代表方向获认可，不代表设计已定稿 |
| **Implementable** | 设计完整，Test Plan 可执行 | 设计缺口（TODO 标记）补齐后通过后续 PR 升级 |
| **Implemented** | 代码已合入，验收标准已满足 | 通过后续 PR 升级；同时关闭 tracking issue |
| **Deferred** | 推迟到后续版本 | tracking issue 移至下一 Milestone；`target/X.Y` 标签换为下一版本 |
| **Rejected** | 不再推进 | 将 Status 标为 `Rejected` 后合入 PR,以保留决策记录 |

> 状态在 FEP 文档中标注为 `**Status:** <value>`，每次状态变更通过后续 PR 更新。

FEP PR 带着某版本的 `target/X.Y` 标签合入，即**进入该版本**。能否在该版本**毕业**是另一件事，由该版本的特性冻结（Feature Freeze）决定:冻结日前实现代码提交完毕，测试期内验收通过。合入后未赶上冻结的 FEP 转为 `Deferred` 顺延，不会被丢弃。

## 工作流程

每一步末尾列出它触发的登记操作。标签、milestone、看板的定义统一放在[标签、Milestone 与看板](#标签milestone-与看板)。

### 0. 与 SIG 沟通

在编写 FEP 之前，先与相关 SIG 讨论想法。确保该 SIG 对问题领域有兴趣并愿意评审。

> **启动期**：如果相关 SIG 尚无 Chair、Approver 或例会，在目标模块仓库提 Issue 或在 [GitHub Discussions](https://github.com/FlagOS-AI/community/discussions) 发帖。TSC（或 TSC 成立前的众智FlagOS社区）将负责流转和评审。详见 [GOVERNANCE.md](../GOVERNANCE.md)。

### 1. 创建 FEP 文档

将 [FEP 模板](fep-template/README.md) 复制到 `fep/sig-xxx/title-slug.md`。

- `title-slug` 是一个简短的英文连字符描述
- 起步最小内容：模板中标注 **(Required)** 的章节——Summary、Goals、Packaging、Test Plan，其余后续补充
- 初始 Status 设为 `Provisional`

### 2. 提交 PR

提交包含 FEP 文件的 PR。

- PR 标题应描述该特性
- PR 描述可以简略——FEP 文档承载详细内容
- 早期需要更多讨论的想法请使用 **Draft PR**

**登记操作**：给 PR 打 `FEP` + `sig/*`（或 `wg/*`）标签。若目标某个版本，在 FEP 头部写 `Target Version: FlagOS X.Y` 并打 `target/X.Y` 标签——PR 随即出现在该版本的 *Features Pending* 看板视图中。

### 3. 评审与合入

评审、讨论和迭代在 PR 上进行。

- SIG Approver（列在 OWNERS 中）批准 PR
- **启动期**：如果相关 SIG 尚无 Approver，TSC 直接评审。如需帮助流转，在 [GitHub Discussions](https://github.com/FlagOS-AI/community/discussions) 发帖。
- 合入门槛：**(Required)** 章节成型 + SIG 认可方向。`Provisional` 状态合入是常态；`Implementable` 由后续 PR 升级
- 合入前将文件重命名为 `NNNN-title-slug.md`（NNNN = PR 编号）

带 `target/X.Y` 标签的 FEP 合入即**进入该版本**：从 *Features Pending* 视图自动流转到 *SIG Roadmap* 视图。

**登记操作（由合入者执行）**：创建 tracking issue——`[FEP-XXXX] <标题> tracking`，打 `FEP` + `sig/*` 标签，assign 给 FEP Owner，挂对应版本 Milestone。issue 不打 `target/*` 标签，其版本归属由 milestone 承载。

**跨 SIG FEP**：选择一个归属 SIG 作为文件存放目录。受影响的 SIG 也应参与评审。如果没有现有 SIG 适用，使用 `sig-architecture`（启动期）或咨询 TSC 获取流转建议。

### 4. 实现

- 在相关仓库中进行实现；实现代码须在该版本的**特性冻结**日前提交完毕（日期见 `release/X.Y/schedule.md`）
- 在 FEP 文档的 `Related PRs` 章节中追踪相关 PR
- 在 tracking issue 中勾选进度、附验收凭据（环境、日志、指标）
- 通过后续 PR 更新 FEP 文档：补齐设计 TODO，然后将 Status 升为 `Implementable`
- 特性冻结后：只做验收测试、bug 修复、调优和 FEP 文档更新，不再进新特性代码

### 5. 收尾

- 所有验收标准满足后，通过最终 PR 将 Status 更新为 `Implemented`
- 关闭 tracking issue —— Milestone 视图中即标记为已交付
- 发布时验收部分未过：Status 保持 `Implementable`，为未过部分单独开验收 issue 挂在 milestone 上
- 完全未交付：标为 `Deferred`，tracking issue 移至下一 Milestone，FEP PR 的 `target/*` 标签换为下一版本

## 文件命名

| 约定 | 适用时机 |
|------------|------|
| `title-slug.md` | PR 创建前或早期草稿阶段 |
| `NNNN-title-slug.md` | PR 创建后，NNNN 为 PR 编号 |

> 合入前将文件重命名为包含 PR 编号。PR 编号作为 FEP 标识符。

## 角色

| 角色 | 职责 |
|------|-----------------|
| **FEP Owner** | 编写 FEP、申报 `Target Version`、填写 `Related PRs`、推动实现、更新状态、确保验收 |
| **SIG Approver** | 评审和批准 FEP 文档（列在 [SIG OWNERS](../sigs/) 中）；合入时创建 tracking issue |
| **Release Manager** | 追踪各版本 FEP 整体进度，Go/No-Go 决策；搭建各版本周期的基础设施（见[开启新版本周期](#开启新版本周期)） |

> `Target Version` 和 `Related PRs` 是 Owner 的申报项——评审者可以对其提意见，但不代填。
> 完整角色定义和晋升路径见 [contributors/roles.md](../contributors/roles.md)。

## 标签、Milestone 与看板

一个 FEP 在版本中的推进由两个载体承载——FEP **PR**（设计）和它的 **tracking issue**（交付）——通过标签和 milestone 串联。

### 标签

| 标签 | 打在哪 | 谁打 | 何时 |
|------|--------|------|------|
| `FEP` | FEP PR 和 tracking issue | 作者 / 合入者 | 创建时 |
| `sig/*`, `wg/*` | FEP PR 和 tracking issue | 作者 / 合入者 | 创建时 |
| `target/X.Y` | **仅 FEP PR** | FEP Owner | 申报目标版本时；`Deferred` 时更换 |

每个载体的版本归属只记一处：PR 用 `target/*` 标签，tracking issue 用 milestone。不要给 tracking issue 打版本标签，也不要把 FEP PR 挂到 milestone。

**已合入 PR 的 `target/*` 变更只能由 Release Manager 执行**，且仅限两种情形：`Deferred` 顺延换标，或合入后 Owner 通过后续 PR 申报 `Target Version` 补充进入某版本。两种情形都必须在同一步同步 tracking issue 的 milestone——后续 PR 和 milestone 变更即审计记录。单独给已合入 PR 补打 `target/*` 标签不构成进入版本。

### Milestone

- 每个 FlagOS 版本对应一个 Milestone（如 `FlagOS 2.2`），设有截止日期
- 每个进入版本的 FEP 都有**一个 tracking issue**（`[FEP-XXXX] <标题> tracking`）：FEP 合入时创建，assign 给 FEP Owner，FEP 达到 `Implemented` 时关闭
- **Milestone 只挂 tracking issue（以及版本发布追踪 issue），不挂 FEP PR** —— 这样 milestone 的 open/closed 数量反映真实交付进度
- FEP 推迟时，将其 tracking issue 移至下一 Milestone，issue 不关闭

### 看板视图

[FlagOS FEP Tracker](https://github.com/orgs/flagos-ai/projects/6) 看板包含一个常驻视图和每版本三个视图。所有视图由 filter 驱动——PR 合入、issue 关闭时条目自动流转，无需手工挪动。

| 视图 | Filter | 展示内容 |
|------|--------|----------|
| **All FEPs** | `is:pr label:FEP` | 全部 FEP，跨版本 |
| **X.Y Features Pending** | `is:pr is:open label:FEP label:target/X.Y` | 已申报该版本、尚未合入 |
| **X.Y SIG Roadmap** | `is:pr is:merged label:FEP label:target/X.Y` | 已进入该版本，按 SIG 分组 |
| **X.Y Release Track** | `is:issue milestone:"FlagOS X.Y"` | 交付进度，每个 tracking issue 一张卡 |

### 开启新版本周期

Release Manager 创建：`FlagOS X.Y` milestone、`target/X.Y` 标签、按上表建三个版本视图、版本发布追踪 issue、以及记录本周期日期的 `release/X.Y/schedule.md`。

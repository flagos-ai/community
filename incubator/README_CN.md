# FlagOS 孵化器（Incubator）

[English](README.md) | [中文](README_CN.md)

## 1. 目标与适用范围

本目录是 FlagOS 社区接收**外部项目捐赠**的统一入口，定义从捐赠提案到孵化、转正、归档的完整生命周期。制度设计原则：**IP 拿得干净、项目死了能体面退出**，其余从简。

本制度适用于外部捐赠项目；FlagOS 现有子项目的治理不受本目录约束。

## 2. 捐赠方快速开始 / Quick Start for Donors

如果您计划向 FlagOS 捐赠项目：

1. **确认适合捐赠**：阅读第 4 节准入原则，初步确认项目符合 FlagOS 技术范围、具备维护团队，且代码和相关资产原则上可以完成 IP 清理。
2. **准备并提交提案**：复制[项目捐赠提案模板](proposal-template.md)至 `incubator/projects/<项目名>/proposal.md`，填写项目、维护团队、捐赠范围、IP 状况及捐赠后计划，向 community 仓库提交 PR。
3. **参与公开评审和 TSC 答辩**：提案公开评审至少 14 天，之后我们会联系您安排约 30 分钟的 TSC 答辩。通过后项目获得条件批准，进入 SGA 与 IP 尽调阶段。
4. **完成 SGA 与 IP 清理**：在 Mentor、TSC 指定核验人与法律接收主体协助下，完成 [IP 清理清单](ip-checklist.md)并签署 SGA。条件批准有效期为 12 个月。
5. **正式接收和资产迁移**：SGA 生效且 IP 清理完成后，社区在提案中记录 Final Acceptance，**项目自该日起正式进入孵化**；随后双方按[正式接收执行手册](acceptance-runbook_CN.md)迁移仓库、发布渠道、域名及其他约定资产。

状态进度一览：

```
Draft → Public Review → Conditional Approved → SGA / IP Clearance → Final Accepted → Incubating
```

提交前如有疑问，请联系 <contact@flagos.io>。**请勿在公开 PR 中提交合同扫描件、身份证明、账号密码或其他敏感材料**；此类材料的私密提交方式由 Mentor 或法律对接人另行提供。

## 3. 项目生命周期

```
捐赠提案 → 孵化中 (Incubating) → 正式项目 (Graduated)
                    └────────→ 已归档 (Archived)
```

只设两级：**孵化中** / **正式项目**。归档是任一阶段的中性退出通道。

### 项目列表

| 项目 | 状态 | 捐赠方 | Mentor | 提案 |
|------|------|--------|--------|------|
| _暂无_ | | | | |

## 4. 准入原则

TSC 依据以下原则评审捐赠提案，接收与否的理由公开记录。候选项目至少应：

- 符合 FlagOS 的使命与技术范围（多芯片 AI 系统软件栈及其生态）；
- 采用符合本文件第 9 节许可证政策的开源许可证；
- IP 状况原则上可清理（存在已知问题不必然否决，但须有可行的清理路径）；
- 有明确的初始维护团队，而非停止维护后的代码托管；
- 愿意接受开放、中立的社区治理，包括本社区的 [GOVERNANCE_CN.md](../GOVERNANCE_CN.md) 与 [CODE_OF_CONDUCT_CN.md](../CODE_OF_CONDUCT_CN.md)；
- 与 FlagOS 现有项目定位互补或有清晰的差异化，不造成社区内的重复竞争。

## 5. 决策机构

- 捐赠接收、转正、归档属于社区**重大决策**，由 **TSC 按 [GOVERNANCE_CN.md](../GOVERNANCE_CN.md) 规定的重大决策规则投票决定**；TSC 首次会议召开前的过渡期内，由众智FlagOS社区按同一规则代行。
- 一般事项遵循 GOVERNANCE 的 lazy consensus 规则。
- **利益冲突**：项目捐赠事项中的直接利益相关者（来自捐赠方或其关联机构的 TSC 成员）**必须回避**表决。此为 GOVERNANCE 利益冲突规则中针对捐赠事项的特别规定，见 [GOVERNANCE_CN.md](../GOVERNANCE_CN.md#利益冲突-conflict-of-interest)。
- 所有决策在 GitHub 公开记录。

## 6. 捐赠与正式接收流程

```
① 提案 PR → ② 公示 2 周 → ③ TSC 条件批准 → ④ SGA + IP 清理 → ⑤ 正式接收，进入孵化
```

1. **提案 PR**：捐赠方按 [proposal-template.md](proposal-template.md) 填写提案，以 PR 形式提交至 `incubator/projects/<项目名>/proposal.md`。提交前有疑问可先联系 <contact@flagos.io>。
2. **公示 2 周**：PR 保持开放至少 14 天，收集社区意见。期间 TSC 为项目物色 1~2 名 Mentor。
3. **TSC 条件批准**：捐赠方在 TSC 例会上答辩（约 30 分钟），TSC 按第 5 节规则投票。通过则合并提案 PR。
   - **条件批准仅表示同意进入 IP 尽调，不构成正式接收。**
   - **有效期**：条件批准自投票通过之日起有效 **12 个月**，可由 TSC 决议延长。逾期未完成 SGA 签署与 IP 清理的，提案关闭（closed/withdrawn），项目**不进入任何生命周期状态**，后续可重新提交。
   - **未通过**：TSC 在 PR 中给出书面理由，项目方可在 6 个月后再次提交。
4. **签署 SGA + IP 清理**：签署[软件捐赠协议](sga-outline.md)，逐项完成 [IP 清理清单](ip-checklist.md)。**清单走不完不接收。**
5. **正式接收**：SGA 生效且 IP 清理清单全部完成后，由 TSC（或其授权负责人）在提案文档中记录 **Final Acceptance**（含日期与核验依据），**正式接收自该记录之日生效**。仓库迁入 `flagos-ai` org（保留 fork 关系与 star）、README 标注 `(incubating)`、更新本页项目列表、发布公告，均为正式接收后的执行动作，按[正式接收执行手册](acceptance-runbook_CN.md)完成。

## 7. 孵化、年度 review 与转正

### 孵化期

- 每个项目由 TSC 指派 **1~2 名 Mentor**，负责辅导治理落地、解答流程问题、在转正时出具推荐意见。Mentor 的产生、职责与更换见 [Mentor 指南](mentor-guide_CN.md)。
- **年度 review**：每年一次，项目在 community 仓库以 issue 形式按[年度 review 模板](annual-review-template.md)提交：发布情况、社区变化、采用情况、合规与安全、遇到的困难与需要的支持。Mentor 确认后归档。
- 项目治理与行为准则沿用社区现有的 [GOVERNANCE_CN.md](../GOVERNANCE_CN.md) 与 [CODE_OF_CONDUCT_CN.md](../CODE_OF_CONDUCT_CN.md)，不另立一套。
- 日常贡献需签署 **CLA**（贡献者许可协议），与 FlagOS 各仓库现行做法一致，由 CLA bot 在 PR 上自动检查，首次签署后长期有效。

### 转正（Graduation）

转正评估固定考察以下**六个维度**，项目自进入孵化之日起即可对照准备：

1. **治理**：社区治理公开、独立运转（Committer 提名、决策记录等在 GitHub 可查）；
2. **维护可持续性**：维护团队活跃且有新人加入机制；
3. **发布与安全**：有稳定的发布节奏，具备基本的安全漏洞响应能力；
4. **真实采用**：存在真实用户或生产使用；
5. **合规**：IP 与许可证持续合规，无未处理的违规依赖；
6. **去单点依赖**：对原始捐赠方的单点依赖已明显降低（maintainer 不集中于单一机构）。

转正由项目 maintainer 或 Mentor 按[转正提案模板](graduation-template.md)发起（逐维度附证据 + Mentor 书面推荐），TSC 按第 5 节规则投票通过后生效，去掉 `(incubating)` 标识。

> 各维度的量化参考指标（机构数量、发布次数等）由 TSC 后续补充，补充仅细化参考线，不改变上述维度本身。

## 8. 退出与归档

归档是**已正式接收的项目**（孵化中或正式项目）不再满足相应条件时的中性退出机制；未完成正式接收的提案按第 6 节的条件批准有效期处理，不进入归档。**发现机制**：孵化项目经年度 review 发现；正式项目**每 2 年**做一次轻量健康检查（复用[年度 review 模板](annual-review-template.md)），任何社区成员亦可随时依据下列情形发起提议。出现以下任一情形，由 TSC 按第 5 节规则投票决定：

- 连续 12 个月无实质活动（无代码提交、无发布、maintainer 失联）；
- 正式接收后新发现的 IP 或合规问题长期无法修复；
- 失去维护团队且无人接手；孵化项目长期无 Mentor 可指派；
- 持续违反社区治理或行为准则且无改善；
- 无法维持基本的发布与安全响应能力；
- 项目维护团队主动申请退出。

归档后仓库设为**只读并保留**，具体执行（通知期、渠道处置、商标、复活机制）见[归档执行手册](archiving-runbook_CN.md)。**对捐赠方的承诺**：SGA 授予的代码许可**不可撤销**，归档不影响任何人继续 fork 和使用；项目商标可与捐赠方协商返还。

## 9. 许可证、安全与配套文件

### 许可证政策

- **默认出口许可证**：Apache-2.0。
- **允许的依赖许可证**：Apache-2.0、MIT、BSD、MulanPSL-2.0（木兰）。
- **禁止进入源码树**：GPL、AGPL、SSPL、Commons Clause 及任何"仅限非商用"类条款。

CI 中的许可证扫描会在 PR 级别阻断违规依赖。完整分类（含个案裁定类）、CI 扫描要求及模型权重/数据集的许可规则见[许可证政策细则](license-policy_CN.md)。

### 安全漏洞响应

孵化及正式项目的安全漏洞请**私密报告**至 <security@flagos.io>，请勿公开提 issue。我们会在 3 个工作日内确认，并与报告者协调披露时间线。完整流程（响应时限、披露协调、项目义务）见[安全响应政策](security-policy_CN.md)。

### 目录文件

| 文件 | 用途 |
|------|------|
| [proposal-template.md](proposal-template.md) | 捐赠提案模板 |
| [ip-checklist.md](ip-checklist.md) | IP 清理清单（接收硬门槛） |
| [sga-outline.md](sga-outline.md) | 软件捐赠协议条款框架（待法务定稿） |
| [license-policy_CN.md](license-policy_CN.md) | 许可证政策细则（分类、CI 扫描、AI 制品许可） |
| [security-policy_CN.md](security-policy_CN.md) | 安全响应政策（时限、流程、项目义务） |
| [mentor-guide_CN.md](mentor-guide_CN.md) | Mentor 指南（产生、职责、更换） |
| [acceptance-runbook_CN.md](acceptance-runbook_CN.md) | 正式接收执行手册（迁移与发布操作） |
| [annual-review-template.md](annual-review-template.md) | 年度 review 模板 |
| [graduation-template.md](graduation-template.md) | 转正提案模板（六维度证据 + Mentor 推荐） |
| [archiving-runbook_CN.md](archiving-runbook_CN.md) | 归档执行手册（通知期、处置、复活） |
| `projects/` | 各项目的提案与流程档案存档 |

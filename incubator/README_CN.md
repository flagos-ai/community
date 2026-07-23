# FlagOS 孵化器（Incubator）

[English](README.md) | [中文](README_CN.md)

本目录是 FlagOS 社区接收**外部项目捐赠**的统一入口，定义从捐赠提案到孵化、转正、归档的完整生命周期。制度设计原则：**IP 拿得干净、项目死了能体面退出**，其余从简。

## 项目生命周期

```
捐赠提案 → 孵化中 (Incubating) → 正式项目 (Graduated)
                    └────────→ 已归档 (Archived)
```

只设两级：**孵化中** / **正式项目**。归档是任一阶段的退出通道。

## 项目列表

| 项目 | 状态 | 捐赠方 | Mentor | 提案 |
|------|------|--------|--------|------|
| _暂无_ | | | | |

## 1. 决策机构

- 捐赠接收、转正、归档由 **TSC** 投票决定（简单多数）；TSC 首次会议召开前的过渡期内，由众智FlagOS社区代行（见 [GOVERNANCE_CN.md](../GOVERNANCE_CN.md) 启动期过渡章节）。
- 一般事项遵循 lazy consensus：GitHub 上发出后 72 小时无反对即通过。
- **利益冲突回避**：来自捐赠方所属机构的 TSC 成员，在该项目的接收、转正、归档投票中回避。
- 所有决策在 GitHub 公开记录，与社区治理原则一致。

## 2. 捐赠流程

```
① 提案 PR → ② 公示 2 周 → ③ TSC 答辩与投票 → ④ 签署 SGA + IP 清理 → ⑤ 仓库迁入，进入孵化
```

1. **提案 PR**：捐赠方按 [proposal-template.md](proposal-template.md) 填写提案，以 PR 形式提交至 `incubator/projects/<项目名>/proposal.md`。提交前有疑问可先联系 <contact@flagos.io>。
2. **公示 2 周**：PR 保持开放至少 14 天，收集社区意见。期间 TSC 为项目物色 1~2 名 Mentor。
3. **TSC 答辩与投票**：捐赠方在 TSC 例会上答辩（约 30 分钟），TSC 投票（简单多数，冲突方回避）。通过则合并提案 PR。
   - **未通过**：TSC 在 PR 中给出书面理由，项目方可在 6 个月后再次提交。
4. **签署 SGA + IP 清理**：签署[软件捐赠协议](sga-outline.md)，逐项完成 [IP 清理清单](ip-checklist.md)。**清单走不完不接收。**
5. **进入孵化**：仓库迁入 `flagos-ai` org（保留 fork 关系与 star），README 顶部标注 `(incubating)`，更新本页项目列表，发布公告。

## 3. 孵化期

- 每个项目由 TSC 指派 **1~2 名 Mentor**，负责辅导治理落地、解答流程问题、在转正时出具推荐意见。
- **年度 review**：每年一次，项目在 community 仓库以 issue 形式回答：发布了几个版本、新增了几名 maintainer、社区遇到什么困难、需要什么支持。Mentor 确认后归档。
- 项目治理与行为准则沿用社区现有的 [GOVERNANCE_CN.md](../GOVERNANCE_CN.md) 与 [CODE_OF_CONDUCT_CN.md](../CODE_OF_CONDUCT_CN.md)，不另立一套。
- 日常贡献采用 **DCO**（`Signed-off-by`）确认，由 CI bot 自动检查，无需签署 CLA。

## 4. 转正（Graduation）

孵化项目展示出**跨机构的可持续维护能力**（maintainer 不集中于单一机构、有稳定的发布节奏与真实用户）后，由 Mentor 推荐、TSC 投票转为正式项目，去掉 `(incubating)` 标识。

> 量化标准（机构数量、发布次数、生产用户数等）将在首个项目临近转正时由 TSC 制定并补充至本节。

## 5. 归档（Archiving）

- 项目**连续 12 个月无实质活动**（无代码提交、无发布、maintainer 失联），任何社区成员可发起归档提议，TSC 投票后项目转入 archived 状态，仓库设为只读并保留。
- **对捐赠方的承诺**：SGA 授予的代码许可**不可撤销**，归档不影响任何人继续 fork 和使用；项目商标可与捐赠方协商返还。

## 6. 许可证政策

- **默认出口许可证**：Apache-2.0。
- **允许的依赖许可证**：Apache-2.0、MIT、BSD、MulanPSL-2.0（木兰）。
- **禁止进入源码树**：GPL、AGPL、SSPL、Commons Clause 及任何"仅限非商用"类条款。

CI 中的许可证扫描会在 PR 级别阻断违规依赖。特殊情况（如仅测试期使用的弱互惠许可依赖）由 TSC 个案裁定。

## 7. 安全漏洞响应

孵化及正式项目的安全漏洞请**私密报告**至 <security@flagos.io>，请勿公开提 issue。我们会在 3 个工作日内确认，并与报告者协调披露时间线。

## 目录文件

| 文件 | 用途 |
|------|------|
| [proposal-template.md](proposal-template.md) | 捐赠提案模板 |
| [ip-checklist.md](ip-checklist.md) | IP 清理清单（接收硬门槛） |
| [sga-outline.md](sga-outline.md) | 软件捐赠协议条款框架（待法务定稿） |
| `projects/` | 各项目的提案与状态存档 |

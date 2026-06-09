# FlagOS 社区治理

[English](GOVERNANCE.md) | [中文](GOVERNANCE_CN.md)

FlagOS 社区治理遵循 **先有人后有结构** 的原则。本文档定义决策机制和角色体系，具体 SIG 章程见 [sigs/](sigs/)。

## 项目原则

### 供应商中立

FlagOS 是一个多芯片 AI 系统软件项目，对不同芯片厂商、云厂商和组织保持中立。社区决策基于技术 merit（技术方案的合理性、可维护性、对社区的价值），不基于贡献者所属组织的商业影响力。

- 所有贡献者不论所属组织，在社区角色和决策权上一视同仁
- 芯片厂商的代码贡献需满足同等的技术标准和 CI 要求
- TSC 成员和 SIG Chair 在执行社区职责时以个人身份行事，不代表雇主

### 决策记录公开

所有技术决策、治理决策必须在 GitHub 上公开记录。不得通过私下沟通（微信、电话、邮件等）达成实质性治理决策。

## 启动期过渡

### 决策实体

TSC 首次会议召开之前，项目由 **众智FlagOS社区** 代行最高决策。众智FlagOS社区是 FlagOS 项目的创始团队，由项目发起方的核心工程师和社区组织者组成。

**决策方式**：众智FlagOS社区的决策在 GitHub 上公开进行。日常决策遵循 lazy consensus（PR/Issue 发出后 72h 无反对即通过），重大决策（SIG 创建、版本发布、治理规则变更）在 GitHub Discussions 或对应 PR/Issue 中以投票方式决定（2/3 多数）。所有决策必须有 GitHub 记录。

**Bootstrap 例外**：启动期的首批角色（TSC 成员、SIG Chair、SIG Approver）无需经过标准晋升流程。由众智FlagOS社区直接任命，在 MAINTAINERS.md 和对应 OWNERS 文件中确认。一旦首批角色就位，后续晋升严格按 [角色定义与晋升路径](contributors/roles.md) 执行。

### 首批角色任命顺序

```
众智FlagOS社区
  │
  ├→ Step 1: 任命 TSC 成员（3-5 人）→ 填入 MAINTAINERS.md
  │
  ├→ Step 2: TSC 从社区贡献者中确认各 SIG Chair + Tech Lead → 填入 MAINTAINERS.md
  │
  ├→ Step 3: Chair + TSC 确认各 SIG Approver → 填入 OWNERS 文件
  │
  └→ 过渡状态结束：标准晋升流程生效
```

### TSC 首次会议

**触发条件**：TSC 成员 ≥3 人已确认（填入 MAINTAINERS.md 且本人知情同意）。

**召集人**：TSC 成员中由众智FlagOS社区指定一人担任临时 TSC Chair，负责召集首次会议。TSC Chair 正式人选在首次会议上由 TSC 成员互选产生。

**首次会议议程**：
1. 选举 TSC Chair（互选）
2. 确认各 SIG Chair 和 Tech Lead 名单
3. 确认过渡期积压的 PR/FEP 处理方案
4. 确定双周例会时间

首次会议后，日常决策由 TSC 接管。过渡规则逐步退出。

### 过渡规则

| 事项 | TSC 首次会议前 | TSC 首次会议后 |
|------|---------------|---------------|
| 所有决策 | 众智FlagOS社区直接处理 | TSC 接管 |
| SIG 例会 | 不要求 | TSC 双周例会是唯一必开会议 |
| 贡献者找不到 SIG | 直接提 PR，PR comment 说明 + GitHub Discussions 发帖，众智FlagOS社区响应 | 同左，TSC 成员负责路由 |
| FEP 归属 | 无 SIG 可归属的 FEP 放 `fep/sig-architecture/`，众智FlagOS社区审批 | 同左，TSC 审批 |
| 芯片厂商接入 | sig-chip 暂无 Chair 时，厂商联系众智FlagOS社区（见 MAINTAINERS.md） | TSC 处理 |
| Release Manager | 众智FlagOS社区指定 | TSC 指定 |

### 过渡结束

OWNERS 文件首次填充（对应角色已确认且本人知情同意），并且 TSC 已召开首次会议后，过渡状态结束。目标是 **3 个月内**完成首批 Chair 和 Approver 确认。

### 启动期 SIG 说明

当前 7 个 SIG 的目录和 Charter 已预创建，作为启动期技术方向的占位。这些 SIG 属于 **"预创建等待激活"** 状态——目录存在，但 OWNERS 为空，决策权在 TSC。

未来新增 SIG 严格遵循 [SIG 创建条件](#创建条件)：**找不到 Chair 的 SIG 不创建**。只有在 ≥1 名 Chair 确认后才创建目录结构。

TSC 首次会议时，对 7 个预创建 SIG 逐项确认：找到 Chair 的正式激活，暂时找不到的保持预创建状态，TSC 继续直管对应模块。

## Technical Steering Committee (TSC)

TSC 是 FlagOS 项目的最高技术决策体。

### 职责

- 制定和修订项目技术方向与治理规则
- 批准新 SIG 的创建、已有 SIG 的关停或合并
- 解决跨 SIG 争议（SIG 内部无法达成共识时升级到 TSC）
- 批准大版本发布（Go/No-Go 决策）
- 维护 GOVERNANCE.md 和 CODE_OF_CONDUCT.md

### 组成

- **启动期**: 3-5 人，由众智FlagOS社区任命
- **成熟期**: 5-7 人，由 SIG Chair 互选 + 社区选举产生，任期 2 年

### 决策规则

| 类型 | 规则 |
|------|------|
| **日常决策** | Lazy consensus — 提案在 GitHub 发出后 72 小时内无人反对即通过 |
| **重大决策** | 新 SIG 创建/关停、版本 Go/No-Go、TSC 成员变更 — 需 2/3 多数投票 |
| **紧急决策** | TSC Chair 可临时决定（需 ≥1 名其他 TSC 成员联署），72 小时内追溯确认 |
| **会议法定人数** | ≥ 50% TSC 成员出席 |

### 利益冲突 (Conflict of Interest)

TSC 成员在社区决策中以个人技术判断行事。

**披露要求**：TSC 成员在以下情况下需主动声明利益关系：
- 投票事项直接涉及本人雇主或关联公司的商业利益（如芯片 Tier 升降、CI 资源分配、供应商相关的 FEP）
- 投票事项涉及本人有直接财务利益的实体

**声明方式**：在投票 Issue/PR comment 中明确写出 "利益声明：本人受雇于 / 关联于 <组织名称>"。声明后该成员仍可正常投票——FlagOS 假设社区成员能做出独立技术判断。是否回避由本人决定。

**记录要求**：所有利益声明必须记录在对应决策文档中。

**违规处理**：故意隐瞒重大利益关系且影响决策公正性的，经其他 TSC 成员 2/3 投票可要求其在该事项上回避。情节严重者可依据 [Code of Conduct](CODE_OF_CONDUCT.md) 启动违规调查。

### TSC Chair

TSC 成员互选产生，任期 1 年可连任。职责：
- 主持 TSC 例会，发布议程和纪要
- 在紧急情况下做临时决策（需 ≥1 名其他 TSC 成员联署）
- 对外代表项目技术方向

---

## SIG (Special Interest Group)

SIG 是围绕特定技术领域或生态方向组织的常设小组。

### 创建条件

**一个 SIG 必须同时满足：**
1. 至少 1 名 Chair 已确认（目标 ≥2）
2. 至少 1 名 Tech Lead 已确认
3. 至少 3 名初始成员（不含 Chair 和 TL）
4. 有明确的 Charter（范围、职责边界）

**找不到 Chair 的 SIG 不创建。** TSC 直接管理该方向的模块和决策。

### 角色

| 角色 | 职责 | 任期 |
|------|------|------|
| **Chair** (≥1) | 主持 SIG 例会、对外代表 SIG、向 TSC 年度汇报 | 1 年，可连任 |
| **Tech Lead** (≥1) | SIG 技术方向决策、架构评审 | 无固定任期 |
| **Approver** | 审批 FEP 和 PR（绑定）、合入代码 | 持续活跃 |
| **Reviewer** | 对 PR 给出 LGTM（非绑定） | 持续活跃 |
| **Member** | 参与例会、提交 Issue 和 PR | — |

晋升路径：Member → Reviewer (≥5 个合入 PR) → Approver (持续贡献 ≥3 月 + 2/3 Approver 投票) → Tech Lead (Chair 提名 + TSC 批准) → Chair (Tech Lead 中选出 + TSC 批准)

### 创建流程

1. 发起人向 TSC 提交 SIG Proposal（PR 到 community repo，含 Charter 草稿 + 初始成员名单）
2. TSC 在 2 周内投票决定
3. 批准后创建 `sigs/sig-xxx/` 目录（Charter + OWNERS + meetings/）

### 关停流程

1. Chair 或 TSC 发起关停提案
2. 公示 2 周征集意见
3. TSC 投票 (2/3) 决定
4. 关停后归档，相关模块重新分配归属

### 子项目 (Subproject)

SIG 范围内的具体工作由 **子项目** 组织。FlagOS 的每个模块仓库为一个子项目，归属于对应的 SIG。

**子项目 OWNERS**

每个子项目有自己的 OWNERS 文件，定义该模块的技术负责人：

```yaml
# 模块仓库根目录 OWNERS
approvers:
  - sig-xxx-approvers   # 引用社区 OWNERS_ALIASES 中的别名

reviewers:
  - sig-xxx-reviewers
```

> **OWNERS_ALIASES**：社区根目录的 [OWNERS_ALIASES](OWNERS_ALIASES) 集中定义各 SIG 的 Reviewer 和 Approver 别名。各模块 OWNERS 文件引用别名而非具体 GitHub ID。人员变动时只需更新 OWNERS_ALIASES，无需逐个修改模块 OWNERS 文件。

子项目 Approver 对该模块内的代码变更有绑定审批权。跨子项目的变更（如修改公共 API）需相关子项目的 Approver 均 approve。

**子项目与 SIG 的关系**

| 层级 | 决策范围 | 角色 |
|------|----------|------|
| **SIG** | SIG 范围内跨模块的 FEP、架构方向、人员晋升 | Chair + Tech Lead + Approver |
| **子项目** | 单个模块仓库内的 PR 审批、模块级技术决策 | 子项目 Approver + Reviewer |

SIG Approver 自动拥有下属各子项目的审批权（可跨模块 approve）。子项目 Approver 仅在其负责的模块范围内有审批权。

**子项目创建**

1. SIG Chair 或已有子项目的 Approver 提交 PR，在新模块仓库添加 OWNERS 文件
2. 指定至少 1 名子项目 Approver（初始可由 SIG Chair 或 Tech Lead 兼任）
3. 在 SIG Charter 的 "Subprojects" 表格中登记

**子项目退役**

- 模块归档/弃用时，SIG Chair 提交 PR 更新 SIG Charter
- 归档模块的 OWNERS 文件保留，标注 `archived: true`
- 相关 GitHub label 和 CI 资源由 TSC 协调回收

### 孵化工作组 (Working Group)

WG 是 SIG 的前身。条件成熟后可升级为 SIG。

| 升级条件 | ≥3 名活跃 Contributor + ≥1 个可演示场景/产出 |

---

## FEP (FlagOS Enhancement Proposal)

FEP 是管理跨模块或重大功能的提案机制。详见 [fep/README.md](fep/README.md)。

简版流程：
1. 在相关 SIG 中 socialize 想法
2. 复制 fep 模板，撰写提案
3. 开 PR，SIG Approver 审批
4. 跨 SIG 评审（如涉及）
5. 合入，状态设为 Implementable
6. 实现完成后更新状态为 Implemented

> **启动期注意**：SIG 尚未正式运转时，上述流程中的"SIG Approver 审批"由 TSC 直接执行。详见上方 [启动期过渡](#启动期过渡)。

---

## 版本发布

- 每个大版本任命 1 名 **Release Manager**（由 TSC 指定）
- Release Manager 负责：发布日历、FEP 进度追踪、Go/No-Go 会议组织、Release Note
- 大版本发布流程见 [release/README.md](release/README.md)（含补丁版本和 Backport 策略）
- 版本发布工具链：[release/](release/)

---

## 会议体系

| 会议 | 频率 | 时长 |
|------|------|------|
| TSC 例会 | 双周 | 60min |
| SIG 例会 | 双周（与 TSC 错开） | 45min |
| 社区全员会 | 季度 | 90min |

- 所有会议议程提前 ≥24h 公开发布
- 会议纪要会后 48h 内发布到 GitHub

---

## 行为准则

所有参与者必须遵守 [Code of Conduct](CODE_OF_CONDUCT.md)。

---

## 相关文档

- [SIG 总览](sigs/README.md) — 所有活跃 SIG 的索引和会议日历
- [MAINTAINERS.md](MAINTAINERS.md) — TSC + Chair 名单
- [贡献者指南](contributors/) — 如何参与贡献
- [FEP 流程](fep/README.md) — FlagOS Enhancement Proposal 详细说明
- [角色定义与晋升](contributors/roles.md) — 社区角色、晋升路径与退出机制
- [TSC 选举流程](contributors/election.md) — 成熟期 TSC 选举规范
- [SIG 年度报告](contributors/sig-annual-report.md) — SIG 年度报告模板与健康度评估
- [通信渠道运营](contributors/communication-guidelines.md) — 各渠道创建、运营与 Moderation 规范
- [代码审查指南](contributors/review-guide.md) — PR 审查标准和操作流程
- [Issue Triage 指南](contributors/issue-triage.md) — Issue 分类、优先级和响应规范
- [OWNERS_ALIASES](OWNERS_ALIASES) — 各 SIG 的 Reviewer/Approver 别名定义

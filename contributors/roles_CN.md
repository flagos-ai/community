# 角色定义与晋升路径

[English](roles.md) | [中文](roles_CN.md)

## 角色层级

```
Member (社区成员)
  │  参与 SIG 例会、提 Issue、PR 贡献
  │  要求: 遵守 Code of Conduct + ≥1 个合入 PR
  │
  ▼
Reviewer (评审者)
  │  可对 PR 给出 LGTM (非绑定)
  │  要求: 在 SIG 范围内有 ≥5 个合入的 PR, ≥1 名 Approver 担保, Chair 批准
  │
  ▼
Approver / Maintainer (审批者/维护者)
  │  可 approve FEP 和 PR (绑定), 可合入代码
  │  要求: 持续贡献 ≥3 个月, Reviewer 身份 ≥2 个月, 在模块内有显著贡献
  │        ≥2 名现有 Approver 联合提名, 2/3 Approver 投票通过
  │
  ▼
Tech Lead (技术负责人)
  │  SIG 技术方向决策, 架构评审
  │  要求: 在 SIG 范围内有深入技术影响力, Chair 提名 + TSC 批准
  │
  ▼
Chair (组长)
  │  SIG 对外代表, 主持例会, 年度报告, TSC 联络人
  │  要求: Tech Lead 中选出, TSC 批准, 任期 1 年可连任
  │
  ▼
TSC Member
    跨 SIG 治理, 项目整体方向
    要求: 启动期由众智FlagOS社区任命; 成熟期由 Chair 互选 + 社区选举产生, 任期 2 年
```

## 权限矩阵

| 权限 | Member | Reviewer | Approver | Tech Lead | Chair | TSC |
|------|--------|----------|----------|-----------|-------|-----|
| 提交 Issue / PR | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 参与 SIG 非正式投票（方向性意见征集） | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 给出 LGTM | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Approve & Merge PR | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Approve FEP | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| SIG 技术方向决策 | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| 合并/关停 SIG | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| 版本 Go/No-Go | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## 如何成为 Member

Member 是社区的基础身份。成为 Member 无需正式申请，满足以下条件即视为社区 Member：

1. 在任意 FlagOS 模块仓库有 ≥1 个合入的 PR（代码、文档、测试均可）
2. 已阅读并同意遵守 [Code of Conduct](../CODE_OF_CONDUCT.md)
3. 已阅读 [GOVERNANCE.md](../GOVERNANCE.md)

达到条件后，在对应 SIG 的 OWNERS 文件中添加自己的 GitHub ID 并提 PR，由任一 Approver 审核合入即可。

> **启动期注意**：OWNERS 为空时，PR 到 community repo 由 TSC 直接审核。同时在 GitHub Discussions 发帖告知社区。

### Member 的权利与责任

- 可被分配 Issue 和 PR
- 可在 SIG 例会和社区讨论中投票（方向性意见征集）
- 需响应被分配的 Issue 和 PR
- 需对自己贡献的代码负责（测试通过、响应 bug）

---

## 晋升流程

### 担保机制 (Sponsorship)

FlagOS 角色晋升须有现有角色的**担保 (sponsor)**。担保人需与候选人有过直接协作（代码 review、设计讨论、issue 协作等），对候选人的能力和判断力有信心。

| 晋升 | 担保人要求 | 说明 |
|------|-----------|------|
| Member → Reviewer | ≥1 名同 SIG Approver | Approver 担保候选人的 review 质量 |
| Reviewer → Approver | ≥2 名同 SIG Approver 联合提名 | 确保多位 Approver 认可候选人的技术判断 |
| Approver → Tech Lead | ≥1 名同 SIG Chair 提名 | Chair 对 SIG 全局视角判断候选人是否适合 |
| Tech Lead → Chair | 自荐或现有 Chair 提名 | — |

担保人需在晋升 PR 中回复 `+1` 确认担保。担保人来自不同组织/公司者优先。

> **启动期 Bootstrap 例外**：首批 TSC 成员、SIG Chair、SIG Approver 由众智FlagOS社区直接任命，无需经过标准晋升流程和担保。一旦首批角色就位（OWNERS 文件首次填充），后续晋升严格按本表执行。详见 [GOVERNANCE.md](../GOVERNANCE.md) 启动期过渡。

### Member → Reviewer

1. 在 SIG 范围内累计 ≥5 个 PR 被合入（含至少 3 个代码 PR）
2. 在 SIG 范围内参与过 ≥5 次 PR review（comment 或 LGTM）
3. ≥1 名同 SIG Approver 作为 sponsor
4. 提交 PR 更新 OWNERS 文件 (reviewers 列表)，sponsor 在 PR 中回复 `+1`
5. SIG Chair 批准（lazy consensus, 72h 无 Approver 反对即通过）

**晋升标准**: 主要考察代码质量和 review 参与度，不要求特定时间长度。

### Reviewer → Approver

1. Reviewer 身份持续 ≥2 个月
2. 在模块内有显著技术贡献（由 sponsor 在提名中说明）
3. **≥2 名现有 Approver 联合提名**（来自不同组织/公司者优先）
4. 提交 PR 更新 OWNERS 文件 (approvers 列表)，提名 Approver 回复 `+1`
5. SIG 现有 Approver 2/3 投票通过（≥72h 投票期）

> **投票人数不足时**：SIG 现有 Approver 少于 3 人时，自动升级到 TSC 审批（lazy consensus, 72h）。TSC 在审批时需参考提名 Approver 的意见。

**晋升标准**: 核心考察技术判断力和责任感。Approver 可以决定什么代码进入项目，这是最关键的权限关口。

### Approver → Tech Lead

1. 在 SIG 范围内有深入技术影响力（指导过多个子项目的技术方向）
2. Chair 提名（需说明候选人的技术领导力体现）
3. TSC 批准（lazy consensus, 72h）
4. 更新 SIG Charter

### Tech Lead → Chair

1. 现有 Chair 提名或自荐
2. TSC 批准
3. 任期 1 年，可连任

### TSC 成员

启动期由众智FlagOS社区任命，任期 2 年。

成熟期选举流程见 [TSC 选举流程](election.md)。

---

## TSC 选举流程

成熟期选举流程见 [TSC 选举流程](election.md)。

### 选举时间

- 每 2 年举行一次常规选举
- 选举时间与上一届任期结束月对齐
- 出现空缺（成员辞职/退出）时 2 个月内举行补选

### 选民资格

- 在选举公告发布前 12 个月内有 ≥1 个合入 PR 的社区 Member
- 选民名单由 TSC 在选举前 2 周公示，接受异议

### 候选人资格

- 当前或曾任 SIG Chair 或 Tech Lead
- 或曾任 Approver ≥12 个月
- 自荐或由 ≥2 名现有 TSC 成员提名

### 投票流程

1. **提名期**（2 周）: 候选人在 GitHub Issue 中声明参选，附竞选陈述
2. **公示期**（1 周）: 候选人名单公示，社区可提问
3. **投票期**（1 周）: 使用 [Elekto](https://elekto.dev/) 或类似工具进行匿名排名投票 (ranked-choice voting)
4. **结果公布**: TSC Chair 公布当选者

### 席位分配

- 5-7 席，按得票数从高到低
- 同一组织/公司的成员不超过 2 席（防止单一雇主控制）
- 得票相同者由现任 TSC 投票决定

### 任期与交错

- 任期 2 年，可连任
- 首次选举时半数席位任期 1 年（抽签决定），以实现任期交错
- 此后每次选举约半数席位改选

---

## 角色退出

### 主动退出

提交 PR 更新 OWNERS 文件或 MAINTAINERS.md 即可。退出声明中建议说明原因和交接事项。

### 不活跃退出

| 角色 | 不活跃定义 | 处理方式 |
|------|-----------|----------|
| **Member** | 12 个月内无任何贡献（PR、review、issue、社区讨论） | TSC 可提议从 OWNERS 中移除 |
| **Reviewer** | 6 个月内无 review 活动 | Chair 提醒；连续 12 个月无活动则自动移除 |
| **Approver** | 连续 3 个月无活动（无 PR review、无 issue 参与） | SIG Chair 可提议移除，其他 Approver lazy consensus |
| **Tech Lead** | 连续 2 个月无法履行职责 | Chair 与 TSC 协商替换 |
| **Chair** | — | 见下文"Chair 空缺" |
| **TSC** | 连续 3 次未参加 TSC 例会且未请假；或连续 6 个月无任何社区活动（无 PR review、无 issue 参与、无社区讨论、无邮件/微信群参与） | TSC 投票 (2/3) 可移除 |

### Chair 空缺

- Chair 提前退出的，TSC 在 1 个月内指派临时 Chair
- 同时公开招募正式 Chair（SIG 内部提名 + TSC 批准）
- 临时 Chair 任期至正式 Chair 选出为止，最长 3 个月

### 强制移除

违反 [Code of Conduct](../CODE_OF_CONDUCT.md) 经 TSC 调查确认后，可强制移除任何角色。需 TSC 2/3 投票通过。

### 退出后恢复

- 因不活跃退出的，重新活跃贡献 2 个月后可重新申请原角色。**活跃贡献**指在此期间有 ≥2 个合入 PR 或 ≥5 次有效 PR review。
- 因 CoC 违规被移除的，恢复需 TSC 全票通过

---

## 其他贡献方式

不是只有写代码才算贡献。以下贡献同样计入晋升评审：

- 文档编写与翻译
- Issue triage 和社区支持
- Benchmark 测试与数据维护
- FEP 评审和技术讨论
- 社区活动组织
- 会议记录和议程准备

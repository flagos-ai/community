# FlagOS 2.3 发布时间表

[English](schedule.md) | [中文](schedule_CN.md)

> FlagOS 2.3 发布周期的权威时间表。日期变更须通过 PR 修改本文件。
> Milestone:[FlagOS 2.3](https://github.com/flagos-ai/community/milestone/3) · FEP 实时进度:[🚩 版本追踪](../../fep/README_CN.md#-版本追踪-release-tracker)

## 时间线

| 日期 | 节点 | 含义 |
|------|------|------|
| **2026-11-13** | **FEP 合入截止(FEP Merge Deadline)** | 硬截止:目标 2.3 的 FEP 须在此日期前**完成合入**。未合入的 FEP 标为 `Deferred` 顺延下一版本,不做追认。建议至少提前 2 周提交;Approver 初审意见最长 2 周,见[评审指南](../../fep/REVIEW_GUIDE.md#8-approver-code-of-conduct)。 |
| **2026-11-30** | **特性冻结(Feature Freeze)— 拉 rc0** | 实现代码已提交至各模块仓库;**rc0 分支与 tag 已创建,版本号三处一致**(tag = manifest = 包元数据)。RM 当周用 rc0 manifest 执行 `vcs import` + 全模块构建,源码/tag 不一致问题在此暴露,不留到 GA。此日期后:只做验收测试、bug 修复、调优和 FEP 文档更新——不再进 2.3 特性代码。 |
| **2026-12-07** | **拉 rc1** | 第一轮完整集成验证(1 周)。每个 FEP 的 tracking issue 须在 rc1 前挂上可执行的 Test Plan(命令 + 环境 + 期望结果)。 |
| **2026-12-14** | **拉 rc2** | 第二轮验证(2 周,至 12-28)。bug 修复进当前 rc 分支并合回 `main`。 |
| **2026-12-30** | **发布(GA)** 🚀 | FlagOS 2.3 GA。Go/No-Go:GA 前 48 小时 RM 发布书面报告(issue 形式,挂 milestone),TSC 在 issue 中投票;发布范围变更只能发生在这道门,不能发生在发布日。GA manifest 只接受 `existing-tag` 发布源。验收通过的 FEP 将 Status 更新为 `Implemented`;未通过的保持 `Implementable` 并单独开验收 issue。 |

rc 统一在周一切分支。bug 修复进当前 rc 分支并合回 `main`。

## 冻结规则

- **进入即算数**:FEP PR 带 `target/2.3` 标签在 **FEP 合入截止日**前合入即进入 2.3([FEP 生命周期](../../fep/README_CN.md#fep-生命周期))。特性冻结随后关上 2.3 特性代码的门。
- **错过节点?** FEP 顺延至下一版本:标为 `Deferred`,tracking issue 移至下一 milestone,`target/2.3` 标签由 Release Manager 更换。
- **Tag 门禁**:特性冻结日,每个参与模块须完成 rc0 tag,且 tag、manifest、包元数据三处版本号一致。GA manifest 只允许 `existing-tag` 发布源——2.2 的"主干截止时间"兜底口径是一次性特例,不再沿用。
- **例外通道**:安全补丁、严重 bug 修复、CI 阻塞可走 [FEP 评审指南](../../fep/REVIEW_GUIDE.md#7-urgent-fep-channel) 定义的 `[URGENT]` 快速通道,需 TSC 批准。
- **毕业标准**:`Implemented` 要求可执行的 Test Plan(命令 + 环境 + 期望结果,覆盖多芯片场景)在测试期内验收通过,并在该 FEP 的 tracking issue 上逐项打钩。已合入但验收部分未过的 FEP,Status 保持 `Implementable`,未过部分单独开验收 issue 挂在 milestone 上。GA 日 RM 在每个 tracking issue 上给出验收结论并关闭 milestone。

## 角色分工

- **FEP Owner**:在 FEP 合入截止日前完成合入,特性冻结前提交实现代码;rc1 前在 tracking issue 挂上可执行 Test Plan;测试期内推动验收。
- **Release Manager**:在发布追踪 issue 中维护 2.3 测试矩阵——每个 FEP 的 tracking issue 创建时增加一行,特性冻结日定稿;在 manifest PR 上执行 tag 门禁;GA 前 48 小时发布 Go/No-Go 报告;GA 日逐 tracking issue 记录验收结论并关闭 milestone。
- **SIG Approver / TSC**:及时完成 FEP 评审(按评审指南 2 周内给出初审意见),让作者来得及赶上合入截止日;在 Go/No-Go 报告 issue 中投票。

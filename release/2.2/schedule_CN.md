# FlagOS 2.2 发布时间表

[English](schedule.md) | [中文](schedule_CN.md)

> FlagOS 2.2 发布周期的权威时间表。日期变更须通过 PR 修改本文件。
> Milestone:[FlagOS 2.2](https://github.com/flagos-ai/community/milestone/2) · FEP 实时进度:[🚩 版本追踪](../../fep/README_CN.md#-版本追踪-release-tracker)

## 时间线

| 日期 | 节点 | 含义 |
|------|------|------|
| **2026-08-31** | **特性冻结(Feature Freeze)** | 目标 2.2 的 FEP 须已合入,且实现代码已提交至各模块仓库。此日期后:只做验收测试、bug 修复、调优和 FEP 文档更新——不再有新 FEP 进入 2.2,不再进新特性代码。 |
| 2026-09-01 → 09-24 | **测试与稳定期** | 依据各 FEP 的 Test Plan(多芯片矩阵)开展测试。只收 bug 修复,不进新特性。 |
| **2026-09-28** | **发布** | FlagOS 2.2 GA。验收标准满足的 FEP 将 Status 更新为 `Implemented`。 |

> **建议提交截止:2026-08-17。** Approver 初审意见最长 2 周([评审指南](../../fep/REVIEW_GUIDE.md#8-approver-code-of-conduct));晚于此日提交的 FEP PR 可能来不及在冻结前完成评审。

## 冻结规则

- **进入即算数**:FEP PR 带 `target/2.2` 标签合入即进入 2.2([FEP 生命周期](../../fep/README_CN.md#fep-生命周期))。特性冻结同时关上两扇门——FEP 合入与特性代码。
- **错过冻结?** FEP 顺延至下一版本:标为 `Deferred`,tracking issue 移至下一 milestone,`target/2.2` 标签更换。
- **例外通道**:安全补丁、严重 bug 修复、CI 阻塞可走 [FEP 评审指南](../../fep/REVIEW_GUIDE.md#7-urgent-fep-channel) 定义的 `[URGENT]` 快速通道,需 TSC 批准。
- **毕业标准**:`Implemented` 要求可执行的 Test Plan(命令 + 环境 + 期望结果,覆盖多芯片场景)在测试期内验收通过。已合入但验收部分未过的 FEP,Status 保持 `Implementable`,未过部分单独开验收 issue 挂在 milestone 上。

## 角色分工

- **FEP Owner**:在特性冻结前完成 FEP 合入和实现代码提交,在测试期内推动验收。
- **Release Manager**:在[追踪 issue #47](https://github.com/flagos-ai/community/issues/47) 中维护 2.2 测试矩阵——每个 FEP 的 tracking issue 创建时增加一行,特性冻结日定稿;通过 milestone 视图追踪进度;按[发布流程](../README_CN.md)组织 Go/No-Go。
- **SIG Approver / TSC**:及时完成 FEP 评审(按评审指南 2 周内给出初审意见),让作者来得及赶上冻结点。

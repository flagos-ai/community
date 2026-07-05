# FlagOS 2.2 发布时间表

[English](schedule.md) | [中文](schedule_CN.md)

> FlagOS 2.2 发布周期的权威时间表。日期变更须通过 PR 修改本文件。
> Milestone:[FlagOS 2.2](https://github.com/flagos-ai/community/milestone/2) · FEP 实时进度:[🚩 版本追踪](../../fep/README_CN.md#-版本追踪-release-tracker)

## 时间线

| 日期 | 节点 | 含义 |
|------|------|------|
| **2026-08-15** | **FEP 冻结(FEP Freeze)** | 目标 2.2 的 FEP 必须已批准为 `Implementable` 并合入,且 Test Plan 完整。此日期后不再有新 FEP 挂入 2.2 milestone——逾期 FEP 顺延至下一版本。 |
| **2026-08-31** | **代码冻结(Code Freeze)** | 2.2 各 FEP 追踪的实现 PR 必须全部合入各模块仓库。 |
| 2026-09-01 → 09-26 | **测试与稳定期** | 依据各 FEP 的 Test Plan(多芯片矩阵)开展测试。只收 bug 修复,不进新特性。 |
| **2026-09-28** | **发布** | FlagOS 2.2 GA。验收标准满足的 FEP 将 Status 更新为 `Implemented`。 |

## 冻结规则

- **准入闸门**:挂入 [2.2 milestone](https://github.com/flagos-ai/community/milestone/2) 即纳入追踪。FEP Freeze 后 Release Manager 不再挂入新 FEP。
- **错过冻结?** FEP 顺延至下一版本(原目标 2.2 的转为 `Deferred`),见 [FEP 生命周期](../../fep/README_CN.md#fep-生命周期)。
- **例外通道**:安全补丁、严重 bug 修复、CI 阻塞可走 [FEP 评审指南](../../fep/REVIEW_GUIDE.md#6-urgent-fep-channel) 定义的 `[URGENT]` 快速通道,需 TSC 批准。
- **Test Plan 要求**:没有可执行的 Test Plan(命令 + 环境 + 期望结果,覆盖多芯片场景)的 FEP 不能进入 `Implementable`——测试期的工作就依据它展开。

## 角色分工

- **FEP Owner**:在 FEP Freeze 前将 `Target Version` 设为 `FlagOS 2.2`,在 Code Freeze 前推动实现完成。
- **Release Manager**:执行 milestone 准入截止,通过 milestone 视图追踪进度,按[发布流程](../README_CN.md)组织 Go/No-Go。
- **SIG Approver / TSC**:及时完成 FEP 评审(按评审指南 2 周内给出初审意见),让作者来得及赶上冻结点。

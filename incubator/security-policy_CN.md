# 安全响应政策

[English](security-policy.md) | [中文](security-policy_CN.md)

> 本文档以英文版本为准，中文版本供阅读便利；如两者存在不一致，以英文版本为准。

> 本文件是 [README_CN.md](README_CN.md) 第 9 节安全响应的实施细则，适用于所有孵化中与正式项目。

## 1. 报告渠道

- **私密报告邮箱**：<security@flagos.io>（请勿公开提 issue 或在公开渠道讨论未修复漏洞）
- 支持 GitHub 私密渠道：各项目仓库启用 **GitHub Private Vulnerability Reporting**（Settings → Security）后，可经仓库 Security 页直接私密提交。
- 报告请尽量包含：受影响版本、复现步骤或 PoC、影响评估、建议的修复方向（如有）。

## 2. 响应时限

| 阶段 | 时限 |
|------|------|
| 确认收到报告 | 3 个工作日内 |
| 初步评估（是否为有效漏洞、严重程度） | 10 个工作日内 |
| 修复目标 | 严重（Critical）：30 天内；高危：60 天内；中低危：90 天内或下一常规版本 |
| 协调披露 | 修复发布后公开 advisory；与报告者协商时间线，默认不超过 90 天 |

时限为目标而非硬承诺；确有困难时由安全响应负责人与报告者沟通延期。

## 3. 处理流程

1. **接收与分诊**：security@ 邮箱由 TSC 指定的安全响应负责人（至少 2 人）值守，收到报告后转入对应项目的私密修复通道（GitHub Security Advisory 草稿）。
2. **评估**：项目 maintainer 与报告者确认漏洞有效性与严重程度（参考 CVSS 评分）。
3. **修复**：在私有分支开发补丁；修复涉及的讨论不进入公开 issue/PR。
4. **发布**：补丁随新版本发布，同时发布 GitHub Security Advisory；需要时申请 CVE 编号（GitHub 可代为分配）。
5. **致谢**：经报告者同意后在 advisory 中致谢。

## 4. 项目义务

每个孵化中与正式项目须：

- 在仓库根目录放置 `SECURITY.md`，内容指向本政策与 security@ 邮箱；
- 启用 GitHub Private Vulnerability Reporting；
- 指定至少 1 名 maintainer 作为安全联系人（记录于 `projects/<项目名>/` 档案）；
- 在年度 review 中报告本年度安全事件处理情况（无事件则声明"无"）。

## 5. 嵌入式披露

在修复发布前，漏洞细节仅限以下人员知悉：报告者、该项目安全联系人与参与修复的 maintainer、安全响应负责人。确需提前通知重要下游用户的（如漏洞已被利用），由 TSC 决定通知范围。

## 6. 启用前置条件

分两层：

**制度级（首个项目 Final Acceptance 前必须就绪）**：

- [ ] <security@flagos.io> 邮箱开通并可收信；
- [ ] TSC 已指定至少 **2 名**安全响应负责人并公示。

**项目级（每个项目仓库迁入后、对外公告或正式开放贡献前完成，属[执行手册](acceptance-runbook_CN.md)的完成门槛，不是 Final Acceptance 的前置条件）**：

- [ ] 仓库启用 GitHub Private Vulnerability Reporting；
- [ ] 添加 `SECURITY.md`（指向本政策）；
- [ ] 登记项目安全联系人（记录于 `projects/<项目名>/` 档案）。

本政策承诺的响应时限自制度级条件就绪之日起生效；项目级条件按仓库在迁移后逐个完成。

# 安全响应政策 / Security Response Policy

> 本文件是 [README_CN.md](README_CN.md) 第 8 节安全响应的实施细则，适用于所有孵化中与正式项目。
> This document details the security-response policy in Section 8 of the [README](README.md), applying to all incubating and graduated projects.

## 1. 报告渠道 / Reporting Channel

- **私密报告邮箱**：<security@flagos.io>（请勿公开提 issue 或在公开渠道讨论未修复漏洞）
- 支持 GitHub 私密渠道：各项目仓库启用 **GitHub Private Vulnerability Reporting**（Settings → Security）后，可经仓库 Security 页直接私密提交。
- 报告请尽量包含：受影响版本、复现步骤或 PoC、影响评估、建议的修复方向（如有）。

## 2. 响应时限 / Response Timeline

| 阶段 | 时限 |
|------|------|
| 确认收到报告 | 3 个工作日内 |
| 初步评估（是否为有效漏洞、严重程度） | 10 个工作日内 |
| 修复目标 | 严重（Critical）：30 天内；高危：60 天内；中低危：90 天内或下一常规版本 |
| 协调披露 | 修复发布后公开 advisory；与报告者协商时间线，默认不超过 90 天 |

时限为目标而非硬承诺；确有困难时由安全响应负责人与报告者沟通延期。

## 3. 处理流程 / Handling Process

1. **接收与分诊**：security@ 邮箱由 TSC 指定的安全响应负责人（至少 2 人）值守，收到报告后转入对应项目的私密修复通道（GitHub Security Advisory 草稿）。
2. **评估**：项目 maintainer 与报告者确认漏洞有效性与严重程度（参考 CVSS 评分）。
3. **修复**：在私有分支开发补丁；修复涉及的讨论不进入公开 issue/PR。
4. **发布**：补丁随新版本发布，同时发布 GitHub Security Advisory；需要时申请 CVE 编号（GitHub 可代为分配）。
5. **致谢**：经报告者同意后在 advisory 中致谢。

## 4. 项目义务 / Project Obligations

每个孵化中与正式项目须：

- 在仓库根目录放置 `SECURITY.md`，内容指向本政策与 security@ 邮箱；
- 启用 GitHub Private Vulnerability Reporting；
- 指定至少 1 名 maintainer 作为安全联系人（记录于 `projects/<项目名>/` 档案）；
- 在年度 review 中报告本年度安全事件处理情况（无事件则声明"无"）。

## 5. 嵌入式披露 / Embargo

在修复发布前，漏洞细节仅限以下人员知悉：报告者、该项目安全联系人与参与修复的 maintainer、安全响应负责人。确需提前通知重要下游用户的（如漏洞已被利用），由 TSC 决定通知范围。

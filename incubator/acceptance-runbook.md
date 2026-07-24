# 正式接收执行手册 / Formal Acceptance Runbook

> 本文件是 [README_CN.md](README_CN.md) 第 6 节流程第 ⑤ 步的操作手册：Final Acceptance 记录生效后，执行团队按此完成资产迁移与对外发布。
> Operational runbook for step ⑤ of the donation process: after Final Acceptance is recorded, the execution team completes asset migration and announcements per this document.

## 0. 前置条件 / Preconditions

- [ ] SGA 已签署生效，扫描件归档至 `projects/<项目名>/`（法律文本本体不入公开仓库，存联盟档案；此处存签署确认记录）
- [ ] [IP 清理清单](ip-checklist.md)全部完成，核验副本已存 `projects/<项目名>/ip-checklist.md`
- [ ] TSC（或授权负责人）已在 `projects/<项目名>/proposal.md` 末尾记录 **Final Acceptance**（日期 + 核验依据 + 记录人）

## 1. 仓库迁移 / Repository Transfer

1. 捐赠方将仓库 owner 权限移交或使用 GitHub **Transfer ownership** 功能迁入 `flagos-ai` org（保留 star、fork、issue、PR 历史；GitHub 自动为旧地址建立跳转）。
2. 多仓库项目逐个迁移，全部完成后在 proposal.md 的 Final Acceptance 记录下追加迁移完成确认。
3. 迁移后设置：
   - 分支保护规则（main 分支：禁止 force push、要求 PR review）；
   - 仓库 Settings → Security：启用 Private Vulnerability Reporting、Dependabot alerts；
   - 接入 org 统一的 CLA bot 与许可证扫描 CI；
   - 团队权限：为项目 maintainer 建立 GitHub team，授予 maintain 权限；admin 权限保留在 org 管理员。

## 2. 项目标识 / Project Labeling

- 项目 README 顶部添加孵化标识（建议 badge 形式）：`FlagOS Incubating Project`；
- 仓库 About 描述追加 `(incubating)`；
- 添加 `SECURITY.md`（指向[安全响应政策](security-policy.md)）、确认 `LICENSE`/`NOTICE` 符合[许可证政策](license-policy.md)；
- **项目级安全就绪**（[安全响应政策](security-policy.md)第 6 节，**对外公告或开放贡献前（以先到者为准）**完成）：启用 GitHub Private Vulnerability Reporting、登记项目安全联系人至 `projects/<项目名>/` 档案。

## 3. 发布渠道与账号 / Release Channels & Accounts

按 IP 清理清单"资产核验与迁移准备"节确认的资产清单与迁移方案，逐项执行实际移交：

- PyPI / npm / Docker Hub 等：将联盟机器账号加为 owner，捐赠方个人账号降为 maintainer 或移除；
- 域名：完成转移或 DNS 控制权移交；
- 社交媒体/社区渠道：完成交接或在渠道简介中更新归属。

## 4. 社区接入 / Community Onboarding

- 更新 incubator [README_CN.md](README_CN.md) / [README.md](README.md) 项目列表（状态 Incubating、捐赠方、Mentor、提案链接）；
- 项目归入对应 SIG（无合适 SIG 时按 GOVERNANCE 过渡规则由 TSC 直管）；
- maintainer 名单登记进 MAINTAINERS.md 或项目 OWNERS 文件；
- 邀请项目 maintainer 加入 TSC 例会的开放议程。

## 5. 对外公告 / Announcement

- community 仓库 GitHub Discussions 发布接收公告（项目简介、捐赠方、孵化状态说明）；
- 同步至微信公众号等官方渠道；
- 公告措辞注意：孵化中项目表述为 "FlagOS 孵化项目"，不使用可能被理解为最终背书的表述。

## 6. 完成确认 / Completion

全部执行完毕后，执行负责人在 `projects/<项目名>/proposal.md` 追加执行完成记录（日期 + 执行人 + 各项完成情况链接），孵化期自 Final Acceptance 记录之日起算。

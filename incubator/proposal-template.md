# 项目捐赠提案：<项目名>

> 复制本模板至 `incubator/projects/<项目名>/proposal.md`，填写后以 PR 提交（流程见 [README_CN.md](/incubator/README_CN.md) 第 5 节；提交前有疑问可联系 <contact@flagos.io>）。所有字段务必如实填写——特别是"IP 状况自述"部分，早期披露的问题都有办法处理，隐瞒的问题会在 IP 清理阶段阻断接收。
>
> Copy this template to `incubator/projects/<project-name>/proposal.md` and submit as a PR (process in [README.md](/incubator/README.md) Section 5; questions to <contact@flagos.io>). Fill in all fields truthfully — especially the "IP Status Disclosure" section. Issues disclosed early can be worked out; issues concealed will block acceptance at IP clearance.

## 基本信息 / Basic Information

- **项目名称 / Project name**：
- **官网（如有）/ Website (if any)**：
- **当前许可证 / Current license**：
- **捐赠方及签约主体 / Donor & signing entity**：<机构全称或个人姓名 / full legal name of organization or individual>
- **捐赠方联系人 / Donor contact**：<姓名 + 邮箱 / name + email>

**捐赠范围（仓库清单）/ Donation scope (repository list)**：

<!-- 逐个列出随本次捐赠移交的仓库；多仓库项目全部列出。不在此列表中的仓库不属于捐赠范围。 -->
<!-- List every repository transferred in this donation; multi-repo projects list all. Repositories not listed are out of scope. -->

| 仓库地址 / Repository | 说明 / Description |
|----------------------|--------------------|
| | |

## 项目介绍 / Project Description

<!-- 一段话：项目做什么、解决什么问题、目标用户是谁 -->
<!-- One paragraph: what the project does, what problem it solves, who the target users are -->

**与 FlagOS 现有项目的关系 / Relationship to existing FlagOS projects**：
<!-- 与 FlagGems / FlagTree / FlagScale / FlagCX / FlagPerf 等是互补还是重叠？重叠处如何定位？（对应准入原则第 6 条） -->
<!-- Complementary or overlapping with FlagGems / FlagTree / FlagScale / FlagCX / FlagPerf? If overlapping, how is it positioned? (Acceptance principle #6) -->

**与 FlagOS 使命的契合 / Fit with the FlagOS mission**：
<!-- 项目如何服务于多芯片 AI 系统软件栈及其生态？（对应准入原则第 1 条） -->
<!-- How does the project serve the multi-chip AI system software stack and its ecosystem? (Acceptance principle #1) -->

## 社区现状 / Community Status

- **核心开发者及所属机构 / Core developers & affiliations**：

| 姓名/ID | 机构 / Org | 角色 / Role |
|---------|-----------|-------------|
| | | |

- **用户与使用情况 / Users & adoption**：<有无生产环境使用？可否公开引用？ / any production usage? citable publicly?>
- **发布历史 / Release history**：<发布过几个版本，最近一次是什么时候 / number of releases, most recent date>

## IP 状况自述 / IP Status Disclosure

> 本节内容将在条件批准后按 [IP 清理清单](/incubator/ip-checklist.md) 逐项核实。
> This section will be verified item by item against the [IP clearance checklist](/incubator/ip-checklist.md) after conditional approval.

- **代码权属 / Code ownership**：<权属是否清晰？是否包含外包代码、前雇主代码、来源不明的拷贝代码？ / Is ownership clear? Any outsourced code, prior-employer code, or copied code of unclear origin?>
- **软件著作权登记 / Software copyright registration**：<是否登记？登记在谁名下？ / registered? under whose name?>
- **商标与域名 / Trademarks & domains**：<项目名/Logo 是否注册商标？注册主体？是否同意移交或独占许可？ / registered? by whom? willing to transfer or exclusively license?>
- **发布渠道与账号资产 / Release channels & account assets**：<PyPI / npm / Docker Hub / 社交媒体等账号现状，正式接收后须按[执行手册](/incubator/acceptance-runbook.md)交接 / current state of PyPI / npm / Docker Hub / social accounts, to be handed over per the acceptance runbook>
- **已知风险 / Known risks**：<GPL 类依赖、专利问题、进行中的纠纷等，如无填"无" / GPL-family dependencies, patent issues, ongoing disputes; write "none" if none>

**AI 制品（如适用）/ AI artifacts (if applicable)**：

- **模型权重 / Model weights**：<是否随代码一并捐赠？拟采用的权重许可证？ / donated along with code? intended license?>
- **数据集 / Datasets**：<涉及的训练/评测数据集来源与许可，是否可再分发？ / provenance and licenses of training/eval datasets; redistributable?>

## 捐赠后计划 / Post-Donation Plan

- **初始 maintainer 名单 / Initial maintainers**：
- **未来 6~12 个月路线图 / 6–12 month roadmap**：<几句话即可 / a few sentences>
- **希望联盟提供的支持 / Support requested**：<CI 资源、推广、导师方向等 / CI resources, promotion, mentoring focus, etc.>

## 捐赠方承诺 / Donor Commitments

勾选确认 / Check to confirm:

- [ ] 同意采用开放、中立的社区治理，遵循 FlagOS 社区的 [GOVERNANCE](/GOVERNANCE_CN.md) 与 [CODE_OF_CONDUCT](/CODE_OF_CONDUCT_CN.md) / Agree to open, neutral community governance under FlagOS GOVERNANCE and CODE_OF_CONDUCT
- [ ] 同意项目出口许可证切换为 Apache-2.0（或已在提案中说明例外并申请 TSC 批准），并遵守[许可证政策](/incubator/license-policy.md) / Agree to relicense outbound under Apache-2.0 (or an exception justified above for TSC approval) and to follow the license policy
- [ ] 同意后续贡献遵循 FlagOS 现行 CLA 机制 / Agree that subsequent contributions follow the current FlagOS CLA mechanism
- [ ] 已知悉条件批准有效期 12 个月、归档机制及许可不可撤销条款（README 第 5、7 节）/ Aware of the 12-month conditional-approval validity, the archiving mechanism, and the irrevocable-license terms (README Sections 5 & 7)
- [ ] 确认本提案所述内容真实、无重大遗漏 / Confirm this proposal is truthful with no material omissions

## 意向 Mentor（可留空，由 TSC 指派）/ Proposed Mentors (optional; TSC will assign)

-

---

<!-- ==================== 以下由社区填写，捐赠方请勿改动 ==================== -->
<!-- ============ Sections below are completed by the community ============ -->

## 流程记录 / Process Records

### 条件批准 / Conditional Approval

- **TSC 投票结果与链接 / TSC vote result & link**：
- **日期 / Date**：
- **指派 Mentor / Assigned Mentors**：
- **有效期至 / Valid until**：<批准日 + 12 个月 / approval date + 12 months>

### Final Acceptance（正式接收）

> 由 TSC 或其授权负责人在 SGA 生效且 IP 清理清单全部完成后填写；正式接收自本记录之日生效。
> Completed by the TSC or its authorized delegate once the SGA is effective and the IP clearance checklist is fully complete; formal acceptance takes effect as of this record.

- **日期 / Date**：
- **核验依据 / Verification basis**：<SGA 签署确认 + ip-checklist.md 存档链接 / SGA confirmation + link to archived ip-checklist.md>
- **记录人 / Recorded by**：

### 执行完成 / Execution Completed

- **日期 / Date**：
- **执行人 / Executed by**：
- **完成情况 / Completion**：<按[执行手册](/incubator/acceptance-runbook.md)各节列出完成链接 / links per acceptance-runbook sections>

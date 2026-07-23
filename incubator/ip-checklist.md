# IP 清理清单 / IP Clearance Checklist

> 本清单是项目进入孵化的**硬门槛**：全部勾选完成前不执行仓库迁移。由项目 Mentor 与 TSC 指定成员共同核验，完成后将本清单副本存档至 `incubator/projects/<项目名>/`。
>
> This checklist is a **hard gate** for entering incubation: the repository is not transferred until every item is checked. Verified jointly by the project Mentors and a TSC designee; the completed copy is archived under `incubator/projects/<project-name>/`.

## 法律文件 / Legal Documents

- [ ] 软件捐赠协议（SGA）已由捐赠方签约主体签署 / Software Grant Agreement signed by the donor's legal entity
- [ ] 捐赠方已出具代码权属声明，确认无外包代码、前雇主代码或来源不明代码的权属风险；如有，已逐项说明处理方式 / Donor has provided a code ownership declaration covering outsourced / prior-employer / unclear-origin code risks, with resolution for each item if any
- [ ] SGA 约定的软件著作权权利安排（转让 / 独占许可 / 非独占可再许可的永久授权，以正式 SGA 为准）已生效，或相应登记/备案手续已启动且有明确完成时点 / The software-copyright arrangement agreed in the SGA (assignment / exclusive license / non-exclusive perpetual sublicensable license, as the executed SGA specifies) is effective, or the corresponding registration/recording has been initiated with a defined completion date

## 贡献权利链 / Contribution Rights Chain

> SGA 仅能覆盖捐赠方自身有权授权的部分；历史外部贡献者保留的版权不因捐赠方签署 SGA 而获得再许可。本节核验整体切换出口许可证的权利基础。
> The SGA covers only what the donor has the right to license; copyright retained by historical external contributors is not relicensed by the donor's signature. This section verifies the rights basis for switching the outbound license as a whole.

- [ ] 历史 contributor / commit 来源清单已生成并存档 / Historical contributor / commit provenance list generated and archived
- [ ] 历史外部贡献进入项目的授权依据已核验（CLA / DCO / 项目原许可证条款）/ The authorization basis for historical external contributions verified (CLA / DCO / original project license terms)
- [ ] 已确认捐赠方及贡献授权链合计覆盖全部拟捐赠代码按目标出口许可证对外授权的权利 / Confirmed that the donor plus the contribution authorization chain together cover the right to license all donated code under the target outbound license
- [ ] 无法取得授权的历史贡献已逐项处理：保留兼容的原许可证 / 补签授权 / 重写或移除 / Contributions whose authorization cannot be obtained handled item by item: kept under a compatible original license / authorization obtained retroactively / rewritten or removed

## 许可证合规 / License Compliance

- [ ] 全量依赖许可证扫描完成（ScanCode / ORT 等），扫描报告已存档 / Full dependency license scan completed (ScanCode / ORT, etc.), report archived
- [ ] 无禁止类许可证依赖（GPL / AGPL / SSPL / Commons Clause / 非商用条款）；例外项已获 TSC 个案批准 / No prohibited licenses in dependencies; any exceptions approved by TSC case by case
- [ ] **项目自有源码**文件头统一添加许可证声明；第三方源码保留其原许可证与版权头 / License headers added consistently to **project-owned** source files; third-party sources keep their original license and copyright headers
- [ ] 仓库根目录包含 LICENSE 与 NOTICE 文件 / LICENSE and NOTICE present at the repository root

## 资产核验与迁移准备 / Asset Verification & Migration Readiness

> 本节在正式接收前完成的是**核验与准备**；域名、发布渠道、CI、社媒等运营资产的**实际移交**在 Final Acceptance 后按[执行手册](acceptance-runbook.md)执行。仅商标等法律权利安排须在接收前启动。
> Before formal acceptance this section covers **verification and preparation** only; the **actual transfer** of operational assets (domains, release channels, CI, social accounts) is executed after Final Acceptance per the [acceptance runbook](acceptance-runbook.md). Only legal arrangements such as trademarks must be initiated before acceptance.

- [ ] （法律项）项目名称与 Logo 的商标检索完成；SGA 约定的商标权利安排（转让或独占许可）已启动 / (Legal) Trademark search completed; the trademark arrangement agreed in the SGA (assignment or exclusive license) initiated
- [ ] 资产清单已编制并作为 SGA 附件 C 存档：域名、发布渠道（PyPI / npm / Docker Hub 等）、CI 与基础设施账号、社交媒体与社区渠道 / Asset inventory compiled and archived as SGA Schedule C: domains, release channels (PyPI / npm / Docker Hub, etc.), CI and infrastructure accounts, social media and community channels
- [ ] 清单内各资产的现持有人已核实，可迁移性已验证，迁移方案与双方授权已书面确认 / Current holder of each inventoried asset verified, transferability validated, migration plan and both parties' authorization confirmed in writing
- [ ] GitHub 仓库迁移方案确认（迁入 flagos-ai org，保留 fork 关系与 star）/ GitHub repository migration plan confirmed (into flagos-ai org, preserving forks and stars)

## AI 项目附加项（如适用）/ AI-Specific Items (if applicable)

- [ ] 模型权重是否随代码一并捐赠已明确，及其许可证已确定 / Whether model weights are donated along with code is settled, and their license determined
- [ ] 训练/评测数据集的来源、许可及实际使用/分发方式已确认合法：随项目**再分发**的数据集须具备再分发权；不具备再分发权的**不得入库**，仅以合规获取方式（下载脚本 + 来源引用）提供 / Provenance, licenses, and actual usage/distribution mode of training/eval datasets confirmed lawful: datasets **redistributed** with the project must carry redistribution rights; those without must **not enter the repository** and may only be provided via compliant acquisition (download script + source citation)

## 合规排查 / Compliance Review

- [ ] 加密功能出口合规排查（如含加密算法实现）/ Export compliance review for cryptographic functionality (if any)
- [ ] 无进行中的知识产权纠纷，或已向 TSC 书面披露 / No ongoing IP disputes, or disclosed to the TSC in writing

---

**核验人 / Verified by**：

| 角色 | 姓名 | 日期 |
|------|------|------|
| Mentor | | |
| TSC 指定成员 / TSC designee | | |

# IP 清理清单 / IP Clearance Checklist

> 本清单是项目进入孵化的**硬门槛**：全部勾选完成前不执行仓库迁移。由项目 Mentor 与 TSC 指定成员共同核验，完成后将本清单副本存档至 `incubator/projects/<项目名>/`。
>
> This checklist is a **hard gate** for entering incubation: the repository is not transferred until every item is checked. Verified jointly by the project Mentors and a TSC designee; the completed copy is archived under `incubator/projects/<project-name>/`.

## 法律文件 / Legal Documents

- [ ] 软件捐赠协议（SGA）已由捐赠方签约主体签署 / Software Grant Agreement signed by the donor's legal entity
- [ ] 捐赠方已出具代码权属声明，确认无外包代码、前雇主代码或来源不明代码的权属风险；如有，已逐项说明处理方式 / Donor has provided a code ownership declaration covering outsourced / prior-employer / unclear-origin code risks, with resolution for each item if any
- [ ] 软件著作权转让或独占许可手续已启动（以登记变更完成为最终确认）/ Software copyright registration transfer or exclusive license initiated (registration change as final confirmation)

## 许可证合规 / License Compliance

- [ ] 全量依赖许可证扫描完成（ScanCode / ORT 等），扫描报告已存档 / Full dependency license scan completed (ScanCode / ORT, etc.), report archived
- [ ] 无禁止类许可证依赖（GPL / AGPL / SSPL / Commons Clause / 非商用条款）；例外项已获 TSC 个案批准 / No prohibited licenses in dependencies; any exceptions approved by TSC case by case
- [ ] 源码文件头统一添加许可证声明 / License headers added consistently to source files
- [ ] 仓库根目录包含 LICENSE 与 NOTICE 文件 / LICENSE and NOTICE present at the repository root

## 商标与资产移交 / Trademark & Asset Transfer

- [ ] 项目名称与 Logo 的商标检索完成；已注册商标的转让或独占许可已启动 / Trademark search completed; transfer or exclusive license of registered marks initiated
- [ ] 域名移交或 DNS 控制权移交完成 / Domain names or DNS control transferred
- [ ] GitHub 仓库迁移方案确认（迁入 flagos-ai org，保留 fork 关系与 star）/ GitHub repository migration confirmed (into flagos-ai org, preserving forks and stars)
- [ ] 发布渠道账号权限移交（PyPI / npm / Docker Hub 等的 owner 权限）/ Release channel ownership transferred (PyPI / npm / Docker Hub, etc.)
- [ ] CI 与基础设施账号清点并移交 / CI and infrastructure accounts inventoried and transferred
- [ ] 社交媒体与社区渠道账号清点（公众号、Slack/Discord、邮件列表等）/ Social media and community channels inventoried

## AI 项目附加项（如适用）/ AI-Specific Items (if applicable)

- [ ] 模型权重是否随代码一并捐赠已明确，及其许可证已确定 / Whether model weights are donated along with code is settled, and their license determined
- [ ] 训练/评测数据集的来源与许可已确认可再分发 / Training/eval dataset provenance and licenses confirmed redistributable

## 合规排查 / Compliance Review

- [ ] 加密功能出口合规排查（如含加密算法实现）/ Export compliance review for cryptographic functionality (if any)
- [ ] 无进行中的知识产权纠纷，或已向 TSC 书面披露 / No ongoing IP disputes, or disclosed to the TSC in writing

---

**核验人 / Verified by**：

| 角色 | 姓名 | 日期 |
|------|------|------|
| Mentor | | |
| TSC 指定成员 / TSC designee | | |

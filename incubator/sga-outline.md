# 软件捐赠协议（SGA）条款框架 / Software Grant Agreement Term Sheet

> **状态：条款框架，非最终法律文本。** 正式协议须由法律顾问基于本框架起草，并适配中国法律语境（特别是软件著作权登记转让与商标转让部分），以满足国内司法实践中的权属认定要求。
>
> **Status: term sheet, not final legal text.** The formal agreement must be drafted by legal counsel based on this outline and adapted to the PRC legal context (especially software copyright registration transfer and trademark assignment) to satisfy domestic ownership-evidence requirements.

## 待定事项 / Open Question

- **接收主体 / Receiving entity**：协议乙方（受赠方）的法律实体待确定——联盟自身法人 / 依托单位代持。**此项确定前法律文本无法定稿。**
  The legal entity acting as recipient is TBD — the alliance's own legal entity or a host organization. **Legal drafting cannot be finalized before this is settled.**

## 核心条款 / Core Terms

1. **代码版权权利安排 / Code copyright arrangement**
   具体权利模型——**转让、独占许可、或非独占且可再许可的永久授权**——由正式 SGA 针对每个项目确定（默认推荐：捐赠方保留版权，授予受赠方**永久、全球、非独占、免费、不可撤销、可再许可**的版权及专利许可）。无论采用何种模型，均须允许受赠方以 Apache-2.0（或 TSC 批准的其他出口许可证）对外分发。本条仅覆盖捐赠方自身有权处分的权利；历史外部贡献者保留的权利按 [IP 清理清单](ip-checklist.md)"贡献权利链"一节处理。
   The specific rights model — **assignment, exclusive license, or a non-exclusive perpetual sublicensable license** — is determined per project in the executed SGA (recommended default: the donor retains copyright and grants the recipient a **perpetual, worldwide, non-exclusive, royalty-free, irrevocable, sublicensable** copyright and patent license). Whichever model applies, it must permit outbound distribution under Apache-2.0 (or another TSC-approved license). This clause covers only rights the donor itself may dispose of; rights retained by historical external contributors are handled per the "Contribution Rights Chain" section of the [IP clearance checklist](ip-checklist.md).

2. **不可撤销承诺 / Irrevocability**
   上述许可不因项目归档、捐赠方退出社区或双方合作终止而撤销或终止。
   The license granted survives project archiving, the donor's departure from the community, and termination of cooperation.

3. **软件著作权登记 / Software copyright registration**
   如项目已进行软著登记，捐赠方配合办理**与第 1 条约定的权利模型相对应**的登记或备案手续（转让登记 / 独占许可备案 / 许可备案），以满足国内司法实践中的权属证据要求。
   Where software copyright is registered, the donor cooperates in the registration or recording procedure **corresponding to the rights model agreed under Clause 1** (assignment registration / exclusive-license recording / license recording) to meet domestic ownership-evidence requirements.

4. **商标 / Trademarks**
   项目名称与 Logo 的已注册商标**转让**至受赠方，或授予独占许可；未注册的，捐赠方承诺不另行注册并配合受赠方注册。项目归档时商标可协商返还捐赠方。
   Registered trademarks for the project name and logo are **assigned** to the recipient, or exclusively licensed; for unregistered marks, the donor agrees not to register them separately and to assist the recipient's registration. Upon archiving, trademarks may be returned to the donor by negotiation.

5. **权属声明与保证 / Ownership representations & warranties**
   捐赠方声明：其有权作出本捐赠；所捐代码不侵犯第三方权利；已披露全部已知的第三方代码、专利与许可证义务；对外包代码与雇员职务作品已完成权属确认。
   The donor represents: it has the right to make this grant; the code does not infringe third-party rights; all known third-party code, patents, and license obligations are disclosed; ownership of outsourced code and employee works-for-hire has been confirmed.

6. **专利防御性终止 / Defensive patent termination**
   若捐赠方对受赠方或项目用户发起针对本项目的专利诉讼，其依据本协议获得的专利许可自动终止。
   If the donor initiates patent litigation over the project against the recipient or its users, patent licenses granted to the donor terminate automatically.

7. **无附加义务 / No further obligations**
   受赠方不承担继续开发、维护或推广项目的义务；捐赠不构成任何形式的商业对价或背书承诺。
   The recipient assumes no obligation to continue developing, maintaining, or promoting the project; the donation constitutes no commercial consideration or endorsement.

8. **附件 / Schedules**
   - 附件 A：捐赠代码范围（仓库列表、commit 哈希基线）/ Schedule A: donated code scope (repository list, baseline commit hashes)
   - 附件 B：已披露的第三方组件与许可证清单 / Schedule B: disclosed third-party components and licenses
   - 附件 C：商标、域名及账号资产清单 / Schedule C: trademarks, domains, and account assets

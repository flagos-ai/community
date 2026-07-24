# 软件捐赠协议（SGA）条款框架 / Software Grant Agreement Term Sheet

> **语言说明 / Language note**：本文件为法律条款框架，有意保持中英对照单文件（双语合同惯例），不适用政策文档"以英文版为准"的规则；正式签署的 SGA 在协议中自行约定语言效力条款。
> This is a legal term sheet kept deliberately as a single bilingual file (bilingual-contract practice); the English-authoritative rule for policy documents does not apply here. The executed SGA defines its own governing-language clause.

> **状态：条款框架，非最终法律文本。** 正式协议须由法律顾问基于本框架起草，并适配中国法律语境（特别是软件著作权登记转让与商标转让部分），以满足国内司法实践中的权属认定要求。
>
> **Status: term sheet, not final legal text.** The formal agreement must be drafted by legal counsel based on this outline and adapted to the PRC legal context (especially software copyright registration transfer and trademark assignment) to satisfy domestic ownership-evidence requirements.

## 接收主体 / Receiving Entity

- 协议乙方（受赠方）为**中关村人工智能开源联盟**（拟接收主体）。正式协议定稿前，法务须核验并固化：工商/登记注册全称及统一社会信用代码；主体类型及独立签约、持有版权许可与商标/域名等资产的能力；法定代表人或授权签署人、授权文件与有效盖章流程；TSC 接收决定与该法律主体签约/持有资产之间的内部授权关系。中英文名称不一致时，以注册中文名称及正式协议约定为准。核验完成情况见 [IP 清理清单](ip-checklist.md)法律文件部分。
  The recipient (Party B) is the **Zhongguancun Artificial Intelligence Open Source Alliance** (designated recipient). Before the formal agreement is finalized, legal counsel must verify and fix: the registered name and unified social credit code; the entity type and its capacity to contract independently and hold copyright licenses, trademarks, and domains; the legal representative or authorized signatory, authorization documents, and valid sealing procedure; and the internal authorization linking TSC acceptance decisions to this legal entity's contracting and asset holding. Where the Chinese and English names diverge, the registered Chinese name and the executed agreement prevail. Verification is tracked in the Legal Documents section of the [IP clearance checklist](ip-checklist.md).

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
   任何一方（含捐赠方）就本项目对受赠方、贡献者或用户提起专利诉讼的，**该方基于本项目所获得的全部专利许可**（含依出口许可证 Apache-2.0 第 3 条获得的专利授权）自诉讼提起之日终止。具体机制由法务定稿时确定：直接依赖出口许可证 Apache-2.0 第 3 条，或在 SGA 中另行设计双向专利许可及其终止条款——若选后者，须先明确授予对象与范围。
   If any party (including the donor) initiates patent litigation over the project against the recipient, contributors, or users, **all patent licenses that party has received for the project** (including those under Apache-2.0 §3 of the outbound license) terminate as of the filing date. Legal counsel will settle the exact mechanism at drafting: rely directly on Apache-2.0 §3 of the outbound license, or design a reciprocal patent grant with its own termination clause in the SGA — in the latter case, the grantees and scope must be defined first.

7. **无附加义务 / No further obligations**
   受赠方不承担继续开发、维护或推广项目的义务；捐赠不构成任何形式的商业对价或背书承诺。
   The recipient assumes no obligation to continue developing, maintaining, or promoting the project; the donation constitutes no commercial consideration or endorsement.

8. **附件 / Schedules**
   - 附件 A：捐赠代码范围（仓库列表、commit 哈希基线）/ Schedule A: donated code scope (repository list, baseline commit hashes)
   - 附件 B：已披露的第三方组件与许可证清单 / Schedule B: disclosed third-party components and licenses
   - 附件 C：商标、域名及账号资产清单 / Schedule C: trademarks, domains, and account assets

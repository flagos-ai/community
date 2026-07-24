# IP Clearance Checklist

> **Language requirement:** All submitted content must be written in English.

<!--
This checklist is a hard gate for entering incubation: the repository is not
transferred until every item is checked. Verified jointly by the project Mentors
and a TSC designee; the completed copy is archived under
incubator/projects/<project-name>/.

-->

## Legal Documents

- [ ] Recipient entity information and signing authorization verified by legal counsel: registered name and unified social credit code, capacity to contract independently and to hold copyright licenses / trademarks / domains, authorized signatory and sealing procedure
- [ ] Software Grant Agreement (SGA) signed by the contributing organization's legal entity
- [ ] The contributing organization has provided a code ownership declaration covering outsourced / prior-employer / unclear-origin code risks, with a resolution for each item if any
- [ ] The software-copyright arrangement agreed in the SGA (assignment / exclusive license / non-exclusive perpetual sublicensable license, as the executed SGA specifies) is effective, or the corresponding registration/recording has been initiated with a defined completion date

## Contribution Rights Chain

<!-- The SGA covers only what the contributing organization has the right to license; copyright retained by
     historical external contributors is not relicensed by the contributing organization's signature.
     This section verifies the rights basis for switching the outbound license as a whole. -->

- [ ] Historical contributor / commit provenance list generated and archived
- [ ] The authorization basis for historical external contributions verified (CLA / DCO / original project license terms)
- [ ] Confirmed that the contributing organization plus the historical authorization chain together cover the right to license all contributed code under the target outbound license
- [ ] Contributions whose authorization cannot be obtained handled item by item: kept under a compatible original license / authorization obtained retroactively / rewritten or removed

## License Compliance

- [ ] Full dependency license scan completed (ScanCode / ORT, etc.), report archived
- [ ] No prohibited licenses in dependencies (GPL / AGPL / SSPL / Commons Clause / non-commercial terms); any exceptions approved by the TSC case by case
- [ ] License headers added consistently to **project-owned** source files; third-party sources keep their original license and copyright headers
- [ ] LICENSE and NOTICE present at the repository root

## Asset Verification & Migration Readiness

<!-- Before formal acceptance this section covers verification and preparation only;
     the actual transfer of operational assets (domains, release channels, CI, social
     accounts) is executed after Final Acceptance per /incubator/acceptance-runbook.md.
     Only legal arrangements such as trademarks must be initiated before acceptance. -->

- [ ] (Legal) Trademark search completed; the trademark arrangement agreed in the SGA (assignment or exclusive license) initiated
- [ ] Asset inventory compiled and archived as SGA Schedule C: domains, release channels (PyPI / npm / Docker Hub, etc.), CI and infrastructure accounts, social media and community channels
- [ ] Current holder of each inventoried asset verified, transferability validated, migration plan and both parties' authorization confirmed in writing
- [ ] GitHub repository migration plan confirmed (into the flagos-ai org, preserving forks and stars)

## AI-Specific Items (if applicable)

- [ ] Whether model weights are contributed along with the code is settled, and their license determined
- [ ] Provenance, licenses, and actual usage/distribution mode of training/eval datasets confirmed lawful: datasets **redistributed** with the project must carry redistribution rights; those without must **not enter the repository** and may only be provided via compliant acquisition (download script + source citation)

## Compliance Review

- [ ] Export compliance review for cryptographic functionality (if any)
- [ ] No ongoing IP disputes, or disclosed to the TSC in writing

---

**Verified by**:

| Role | Name | Date |
|------|------|------|
| Mentor | | |
| TSC designee | | |

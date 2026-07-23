# 许可证政策 / License Policy

> 本文件是 [README_CN.md](README_CN.md) 第 8 节许可证政策的实施细则，适用于所有孵化中与正式项目。
> This document details the license policy in Section 8 of the [README](README.md), applying to all incubating and graduated projects.

## 1. 出口许可证 / Outbound License

项目对外发布统一采用 **Apache-2.0**。捐赠项目若原采用其他许可证，须在 IP 清理阶段完成切换（SGA 中的授权条款保证了切换的合法性）。个别项目确有理由采用其他许可证的（如 MulanPSL-2.0），须在捐赠提案中说明并经 TSC 批准。

All projects release under **Apache-2.0**. Donated projects under other licenses must switch during IP clearance (the SGA grant makes this lawful). Exceptions (e.g., MulanPSL-2.0) must be justified in the proposal and approved by the TSC.

## 2. 依赖许可证分类 / Dependency License Categories

### 允许 / Allowed（可直接引入）

| 许可证 | 说明 |
|--------|------|
| Apache-2.0 | 含专利授权 |
| MIT / ISC | |
| BSD-2-Clause / BSD-3-Clause | |
| MulanPSL-2.0（木兰宽松） | 中英双语文本均有法律效力 |
| Zlib / Python-2.0 | |
| CC0-1.0 / Unlicense | 公有领域类 |

### 个案裁定 / Case-by-Case（须经 TSC 批准并记录）

| 许可证 | 典型允许场景 |
|--------|-------------|
| MPL-2.0 / EPL-2.0 | 以独立文件/二进制形式使用，不修改源文件 |
| LGPL-2.1 / LGPL-3.0 | 仅动态链接，且为可替换的系统级依赖 |
| CDDL | 同 MPL 处理 |
| 弱互惠许可证仅用于测试/构建工具链 | 不进入分发产物 |

申请方式：在对应仓库提 issue，说明依赖名称、许可证、使用方式（源码引入/动态链接/仅构建期）、是否进入分发产物、有无替代方案。TSC 按 lazy consensus 处理，结论记录在 issue 中。

### 禁止 / Prohibited（不得进入源码树或分发产物）

- GPL-2.0 / GPL-3.0 / AGPL-3.0
- SSPL、BUSL、Elastic License 2.0
- Commons Clause 及任何附加"仅限非商用""禁止竞争"条款的文本
- JSON License（"shall be used for Good, not Evil"）及其他含使用限制的非自由条款
- 无许可证（no license）的第三方代码

## 3. CI 扫描要求 / CI Scanning Requirements

- 每个项目仓库须在 CI 中启用许可证扫描（推荐 ScanCode Toolkit 或 OSS Review Toolkit），对 PR 引入的新依赖做增量检查，命中禁止类许可证即阻断合并。
- 扫描配置以本文件的分类为准；个案批准的依赖加入项目级 allowlist，并注明批准 issue 链接。
- 全量扫描至少每次发布前执行一次，报告随发布记录存档。

## 4. AI 制品的许可 / Licensing of AI Artifacts

适用于捐赠或分发模型权重、数据集的项目：

- **模型权重**：是否随代码捐赠须在提案中明确。权重的许可证独立于代码，推荐采用 Apache-2.0 或明确的开放权重许可；含使用限制的许可（如仅研究用途）须在 README 显著位置声明，且不得与"开源项目"表述混同。
- **数据集**：须确认来源合法、许可允许再分发；不能再分发的数据集只能以"下载脚本 + 来源引用"方式提供，不得直接入库。
- **第三方模型微调产物**：须遵守基座模型的许可条款（如衍生模型命名、使用政策传递等），在 IP 清理清单中逐项核对。

## 5. 文件与声明要求 / File & Notice Requirements

- 仓库根目录：`LICENSE`（Apache-2.0 全文）+ `NOTICE`（版权声明与第三方组件致谢）。
- 源码文件头统一添加 SPDX 标识：`SPDX-License-Identifier: Apache-2.0`。
- 引入的第三方代码保留其原始版权声明，并在 `NOTICE` 或 `third_party/` 目录中登记。

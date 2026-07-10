# FlagOS 发布管理流程

[English](README.md) | [中文](README_CN.md)

本文档定义 FlagOS 版本发布的完整流程和操作规范。

> **启动期注意**：以下流程假设 SIG Chair 和 Approver 已就位。启动期 SIG 未正式运转时：
> - SIG 发布联络人角色由 TSC 直接协调
> - Go/No-Go 会议中，已就位的 SIG Chair 正常汇报；未就位的 SIG 由 TSC 成员代行汇报
> - TSC 成立前，Release Manager 由众智FlagOS社区指定
>
> 详见 [GOVERNANCE.md](../GOVERNANCE.md) 启动期过渡。

---

## 一、版本命名

### 版本号格式

```
v<MAJOR>.<MINOR>.<PATCH>[-rc<N>][.post<N>]
```

| 组成部分 | 含义 | 示例 |
|----------|------|------|
| MAJOR | 重大架构变更，不保证向后兼容 | `v3.0.0` |
| MINOR | 新功能，向后兼容 | `v2.1.0` |
| PATCH | Bug 修复，向后兼容 | `v2.1.1` |
| -rcN | Release Candidate（预发布） | `v2.1.0-rc2` |
| .postN | 验证轮次（RC 内的递增迭代） | `v2.1.0-rc2.post3` |

### 分支与 Tag 命名

| 类型 | 格式 | 示例 |
|------|------|------|
| **分支** | 不带 `v` 前缀，不带 `release/` 前缀 | `2.1.0-rc2` |
| **Tag** | 带 `v` 前缀 | `v2.1.0-rc2.post1` |

### 例外模块

| 模块 | 默认分支 | 说明 |
|------|----------|------|
| FlagGems | `master` | 非 `main` |
| FlagDNN | `master` | 非 `main` |
| FlagBLAS | `master` | 非 `main` |

---

## 二、角色

| 角色 | 职责 | 任命方式 |
|------|------|----------|
| **Release Manager (RM)** | 发布总协调人。负责发布日历、FEP 进度追踪、Go/No-Go 会议组织、Release Notes | 每个大版本由 TSC 指定 1 人 |
| **SIG 发布联络人** | 每个 SIG 指定 1 人，负责该 SIG 的发布就绪确认 | SIG Chair 指定 |
| **CI Signal Lead** | 追踪多芯片 CI 状态，维护 CI 汇总看板，在 RC 期间每日汇报阻塞问题 | RM 指定（建议从 sig-chip 或对 CI 熟悉的贡献者中选出） |
| **Docs Lead** | 协调 Release Notes 草稿、Getting Started 更新、API Reference 更新、文档翻译 | RM 指定（建议从文档虚拟小组中选出） |
| **QA Lead** (可选) | 协调多芯片手动测试和问题追踪 | RM 指定 |

FlagOS 启动期 RM 可由 TSC 成员兼任，CI Signal / Docs Lead 可空缺。

---

## 三、发布周期

### RC 阶段

```
Feature Freeze (功能冻结)
  │
  ├→ RC1: 首次集成验证
  │     │
  │     ├→ 问题修复
  │     ├→ 打 .post1, .post2, ... tag
  │     │
  │     └→ RC2: 第二轮验证 (如有)
  │
  └→ 正式发布
```

### 时间节奏

| 阶段 | 时长 | 说明 |
|------|------|------|
| 开发期 | 8-12 周 | 各模块开发和 FEP 实现 |
| Feature Freeze | 1 天 | 截止日，此后只合入 bug 修复 |
| RC1 | 第 1 周 | 首次全量集成，识别阻塞问题 |
| RC 修复期 | 2-4 周 | 修复阻塞问题，每个修复轮次打 post.N tag |
| Go/No-Go | RC 最后 1 周 | TSC 决策是否发布 |
| 正式发布 | 1 天 | 打正式 tag、发布 Release Notes、公告 |

### 发布日历模板

```
FlagOS vX.Y 发布日历

| 日期 | 里程碑 |
|------|--------|
| YYYY-MM-DD | Feature Freeze |
| YYYY-MM-DD | RC1 |
| YYYY-MM-DD | RC1.post1 (如有) |
| YYYY-MM-DD | Go/No-Go 会议 |
| YYYY-MM-DD | 正式发布 |
```

---

## 四、Feature Freeze

### Freeze 前

1. RM 在 Milestone 中确认所有目标 FEP 的状态
2. 所有目标 FEP 必须达到 `Implementable` 状态
3. 每个 SIG 发布联络人确认该 SIG 的就绪状态

### Freeze 日

1. RM 在 `release/` 下创建 `release-vX.Y-freeze.yaml`，冻结所有模块的版本
2. 发布公告通知所有模块，此后只合入 bug 修复

### Freeze 后可以合入的变更

- Bug 修复（由 SIG Approver 判定）
- 文档更新
- CI/CD 配置修复
- 芯片兼容性修复

**不可以合入**：新功能、API 变更、重构。

---

## 五、RC 验证

### 每个验证轮次 (.postN)

1. RM 按 [manage-release.py](tools/manage-release.py) 为所有模块打 `.postN` tag
2. 更新 `release-2.1-rc2.yaml` 中的 `version` 字段
3. 多芯片 CI 跑全量测试
4. 记录阻塞问题到 RC 追踪 Issue

### RC 验证检查项

> **CI 门禁定义**：以下检查项中，Tier 1 芯片的编译 + 单元测试为 **Required**（必须通过，阻塞合入），Tier 2 芯片为 **Recommended**（必须运行但不阻塞）。CI 详细策略见 [CONTRIBUTING.md](../contributors/CONTRIBUTING.md) 的 CI 门禁要求。

| 检查项 | 负责 | 通过标准 | 类型 |
|--------|------|----------|------|
| 所有模块编译通过（所有芯片） | sig-chip (启动期由 TSC 协调) + 厂商 | Tier 1 100% 通过 | Required |
| 单元测试通过（所有芯片） | 各 SIG + 厂商 | Tier 1 100% 通过, Tier 2 95%+ | Required (Tier 1) / Recommended (Tier 2) |
| 基础算子测试通过 | sig-operator | 所有芯片通过 | Required |
| 框架适配器集成测试 | sig-framework | 每个框架至少 1 个芯片通过 | Required |
| 端到端训练/推理 | sig-training | 至少 NVIDIA + 1 家国产芯片通过 | Required |
| Benchmark 无严重回退 | sig-benchmark (规划中，目前由 TSC 协调) | 性能回退 <5% | Recommended |
| Lint / 格式检查 | 各 SIG | 所有模块通过 | Required |
| DCO 检查 | DCO bot | 所有 PR 通过 | Required |
| 文档就绪 | 文档虚拟小组 | Getting Started 和 Release Notes 草稿完成 | Required |

> **规划中 SIG 的过渡安排**：sig-benchmark 和文档虚拟小组在正式 SIG 成立前由 TSC 协调。sig-benchmark 激活后，Benchmark 检查项和性能回归检测移交给 sig-benchmark。文档虚拟小组产出 Getting Started + API Reference 后，可申请升级为 sig-documentation。详见 [SIG 总览](../sigs/README.md) 规划中 SIG 的激活条件。

---

## 六、Go/No-Go 决策

### 会议流程

1. RM 准备 Go/No-Go 报告（会议前 48h 发布）
2. TSC 召开 Go/No-Go 会议（60min）
3. 每个 SIG Chair 口头汇报该 SIG 就绪状态
4. 列出所有已知阻塞问题，逐条讨论
5. TSC 投票决定：Go / No-Go / Go with caveats

### Go/No-Go 报告模板

```markdown
# FlagOS vX.Y Go/No-Go 报告

**日期**: YYYY-MM-DD
**Release Manager**: @github-id

## FEP 状态

| FEP | 状态 | 备注 |
|-----|------|------|
| FEP-NNNN | Implemented | 已完成 |
| FEP-NNNN | Deferred | 推迟到下个版本 |

## 阻塞问题

| # | 描述 | 影响模块 | 严重程度 | 负责人 |
|----|------|----------|----------|--------|
| 1 | xxx | FlagGems | P0 - 阻塞发布 | @xxx |

## 各 SIG 就绪状态

| SIG | Chair 确认 | 备注 |
|-----|-----------|------|
| sig-operator | ✅ Ready | |
| sig-compiler | ✅ Ready | |
| ... | | |

## CI 汇总

| 芯片 | 编译 | 单元测试 | 集成测试 | 状态 |
|------|------|----------|----------|------|
| NVIDIA | ✅ | ✅ | ✅ | ✅ |
| Hygon | ✅ | ✅ | ⚠️ (1 flaky) | ✅ |
| ... | | | | |

## 建议

- [ ] Go — 所有条件满足
- [ ] No-Go — 存在 P0 阻塞问题
- [ ] Go with caveats — 存在非 P0 已知问题，发布时注明
```

### 决策标准

| 结果 | 条件 |
|------|------|
| **Go** | 无 P0 阻塞问题，所有 CI 门禁通过，所有 SIG Chair 确认就绪 |
| **No-Go** | 存在 P0 阻塞问题，CI Tier 1 不通过 |
| **Go with caveats** | 存在已知非阻塞问题，在 Release Notes 中注明即可 |

---

## 七、正式发布

### 发布步骤

1. 为所有模块的发布分支打正式版本 tag（去掉 `.postN` 后缀）
2. 更新 `release-*.yaml` 的 `version` 字段为正式版本
3. 合并 Release Notes PR
4. 在 GitHub Discussions 发布 Release Announcement
5. 更新 Milestone 状态为 Closed
6. 发布微信公众号/社区通讯

### Release Notes 模板

```markdown
# FlagOS vX.Y Release Notes

## 发布日期

YYYY-MM-DD

## 亮点

- 支持 XX 芯片
- 新增 XX 功能
- 性能提升 XX%

## 新增功能 (FEP)

- FEP-NNNN: 功能描述
- FEP-NNNN: 功能描述

## 支持的芯片

| 芯片 | SDK 版本 | 状态 |
|------|----------|------|
| NVIDIA | CUDA 13.0 | ✅ Tier 1 |
| Hygon | DTK 26.04 | ✅ Tier 2 |
| ... | | |

## 已知问题

- 问题描述 (影响范围，预计修复版本)
- ...

## 致谢

感谢以下贡献者（按字母排序）：
@contributor1, @contributor2, ...

## 升级指南

从 vX.(Y-1) 升级到 vX.Y 的注意事项：
1. ...
2. ...
```

---

## 八、发布后

### 发布后 Checklist

- [ ] 所有模块的正式 tag 推送成功
- [ ] Release Notes 已发布
- [ ] 公告已发送（GitHub Discussion + 微信 + 邮件）
- [ ] Milestone 已关闭，未完成 FEP 已迁移到下一版本
- [ ] RM 发布 Post-mortem（如果发布中出现了问题）

### Post-mortem（可选，出现严重问题时）

```markdown
# FlagOS vX.Y 发布复盘

## 时间线

| 时间 | 事件 |
|------|------|
| YYYY-MM-DD | 发现阻塞问题 |
| YYYY-MM-DD | 修复合入 |
| YYYY-MM-DD | 重新验证通过 |
| YYYY-MM-DD | 发布完成 |

## 根本原因

...

## 改进措施

- [ ] 改进项 1
- [ ] 改进项 2
```

---

## 九、补丁版本与 Backport

### 什么情况发补丁版本

| 情况 | 示例 | 补丁版本 |
|------|------|----------|
| 安全漏洞修复 | CVE 级别的漏洞 | 必须发 |
| P0 bug（关键功能不可用） | Tier 1 芯片编译失败、训练精度错误 | 必须发 |
| CI 修复 | 发布分支 CI 无法运行 | 必须发 |
| P1 bug | 非关键但影响较大的问题 | 建议发，RM 判断 |
| 文档修正 | 错误信息更正 | 不单独发，合并在下次补丁中 |

### Backport 流程

```
确认需要 backport
  │
  ├→ 1. 在 main 分支修复并合入
  │
  ├→ 2. 提交 cherry-pick PR 到 release 分支 (如 2.1.x)
  │     标题: [backport-2.1] fix: xxx
  │     描述: 链接原 PR + cherry-pick 说明
  │
  ├→ 3. 审批: RM + ≥1 名对应 SIG Approver approve
  │     (与原 PR 相比简化: 只确认 cherry-pick 正确性，不重新 review 方案)
  │
  └→ 4. 合入后打 patch tag (如 v2.1.1)
```

### Release 分支维护周期

| 版本 | 维护周期 | 说明 |
|------|------|------|
| 最新 MAJOR.MINOR | 正式发布后 **9 个月** | 接受 backport（安全修复 + P0/P1 bug） |
| 上一 MAJOR.MINOR | 正式发布后 **6 个月** | 仅接受安全修复 |
| 更早版本 | 不维护 | — |

维护期结束后，release 分支标记为 EOL (end-of-life)，不再接受任何 PR。

### 补丁版本 Go/No-Go (简化)

补丁版本的 Go/No-Go 流程简化：

1. RM 确认所有 cherry-pick 已合入，CI 通过
2. RM 在 TSC 工作群或对应 Issue 中提出发布请求
3. **72h lazy consensus**，无需召开正式 Go/No-Go 会议
4. 无 TSC 成员反对 → 发布
5. 有反对 → RM 与反对者协商解决，必要时升级到 TSC 投票

### 补丁版本 Release Note

补丁版本在正式版本的 Release Notes 基础上追加：

```markdown
## v2.1.1 (YYYY-MM-DD)

### 修复
- fix: 修复 FlagGems 在某芯片上的精度问题 (#1234)
- fix: 修复 CI pipeline 超时 (#1235)

### 致谢
感谢以下贡献者提交了本次修复：
@contributor1, @contributor2
```

### 版本号规则

- 补丁版本只增加 PATCH 位：`v2.1.0` → `v2.1.1` → `v2.1.2`
- 正式发布后的第一个补丁为 `.1`（不是 `.0`）
- 不用 `.postN`——那是 RC 阶段的迭代标记

---

## 十、工具链

| 工具 | 用途 | 路径 |
|------|------|------|
| `manage-release.py` | 自动化分支创建与打 tag | [manage-release.py](tools/manage-release.py) |
| `release-2.1-rc2.yaml` | 模块清单与版本锁定示例（vcstool 格式） | [release-2.1-rc2.yaml](2.1/release-2.1-rc2.yaml) |
| `chip-targets-2.1-rc2.toml` | 芯片 SDK 版本与 Docker 基础镜像示例 | [chip-targets-2.1-rc2.toml](2.1/chip-targets-2.1-rc2.toml) |

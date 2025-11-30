<div align="center">

**语言** | **Language**

[中文](CONTRIBUTING_CN.md) | [English](CONTRIBUTING.md)

</div>

---

# 为 FlagOS 做贡献

欢迎！我们很高兴您有兴趣为 FlagOS 做出贡献。本文档为所有类型的贡献提供指南和说明。

## 目录

- [贡献方式](#贡献方式)
- [快速开始](#快速开始)
- [代码贡献工作流](#代码贡献工作流)
- [文档贡献](#文档贡献)
- [Bug 报告](#bug-报告)
- [功能请求](#功能请求)
- [社区参与](#社区参与)
- [行为准则](#行为准则)
- [有疑问？](#有疑问)

## 贡献方式

有很多方式可以为 FlagOS 做贡献：

### 💻 代码贡献
- **修复 Bug**: 帮助我们消除 bug
- **新功能**: 实现请求的功能或您自己的想法
- **性能优化**: 优化现有代码以提高性能
- **测试**: 改进测试覆盖率和可靠性
- **代码审查**: 审查其他贡献者的 Pull Request

### 📖 文档贡献
- **README 和指南**: 改进项目文档
- **示例**: 创建示例和教程
- **API 文档**: 记录 API 和函数
- **翻译**: 帮助将文档翻译成其他语言
- **Wiki**: 为 FlagOS Wiki 做贡献

### 🐛 Issue 管理
- **Bug 报告**: 报告您发现的问题
- **功能请求**: 建议改进
- **Issue 分类**: 帮助组织和优先化 issue
- **Issue 讨论**: 对现有 issue 提供见解

### 🤝 社区支持
- **帮助他人**: 回答您知道答案的问题
- **指导**: 指导新贡献者
- **讨论**: 参与技术讨论
- **反馈**: 对提案提供建设性反馈

## 快速开始

### 前提条件
- Git 知识（fork、clone、branch、commit）
- GitHub 账户
- 熟悉您想为之贡献的项目

### 理解 FlagOS 结构

FlagOS 是一个多仓库项目。在贡献前，请确定您的贡献属于哪个仓库：

| 仓库 | 范围 |
|------|------|
| **community** | 社区治理、指南和协作中心 |
| **FlagGems** | 高性能 AI 算子实现 |
| **FlagTree** | AI 编译器基础设施 |
| **FlagScale** | 分布式训练和推理 |
| **FlagCX** | 通信库 |
| **FlagPerf** | 性能评测工具 |
| **FlagAttention** | 注意力算子优化 |
| [更多...](https://github.com/flagos-ai) | 其他专业项目 |

### 设置开发环境

对于每个 FlagOS 仓库，请按照其 `README.md` 中的特定设置说明操作：

```bash
# 一般工作流（具体步骤可能因仓库而异）
1. Fork 代码仓到您的 GitHub 账户
2. 本地克隆您的 fork：
   git clone https://github.com/YOUR_USERNAME/REPO_NAME.git
3. 添加 upstream 远程：
   git remote add upstream https://github.com/flagos-ai/REPO_NAME.git
4. 为您的工作创建分支
5. 按照该仓库 README 中的设置说明操作
```

## 代码贡献工作流

### 1. Fork 和创建分支

```bash
# 在 GitHub 上 Fork 仓库（通过 GitHub 网页）
# 克隆您的 fork
git clone https://github.com/YOUR_USERNAME/REPO_NAME.git
cd REPO_NAME

# 添加 upstream 远程
git remote add upstream https://github.com/flagos-ai/REPO_NAME.git

# 创建特性分支
git checkout -b fix/your-fix-name
# 或
git checkout -b feature/your-feature-name
```

### 2. 进行更改

- 遵循仓库的代码风格和约定
- 编写清晰的描述性提交信息
- 为新功能添加测试
- 确保现有测试仍然通过

### 3. 提交指南

使用清晰描述性的提交信息：

```
# 好的例子：
fix: 解决算子缓存中的内存泄漏
feat: 添加多头注意力优化支持
docs: 更新 CONTRIBUTING.md 中的新工作流
test: 为 FlagGems 算子添加单元测试

# 格式: <类型>: <描述>
# 类型: feat, fix, docs, style, refactor, test, chore, perf
```

### 4. 代码格式化和质量

许多 FlagOS 仓库使用 pre-commit 钩子进行代码格式化。提交前：

```bash
# 如果使用 pre-commit（检查仓库的 README）
pip install pre-commit
pre-commit install
# 然后提交 - 钩子会自动运行

# 或手动格式化
black .          # Python 格式化
flake8 .         # 代码检查
# 等等
```

### 5. 运行测试

推送前，运行测试：

```bash
# Python 项目示例（具体命令因仓库而异）
pytest tests/           # 运行所有测试
pytest tests/unit/      # 运行特定测试套件

# 检查失败的测试
pytest -v               # 详细输出
```

### 6. 推送和创建 Pull Request

```bash
# 从 upstream 更新您的分支
git fetch upstream
git rebase upstream/main

# 推送您的分支
git push origin your-branch-name

# 在 GitHub 上创建 PR：
# 1. 转到您的 fork 页面
# 2. 点击"Compare & pull request"
# 3. 填写 PR 模板
# 4. 提交
```

### 7. Pull Request 指南

**PR 标题**：应该清晰描述
```
fix: 解决 FlagScale 分布式训练中的崩溃问题
feat: 为 FlagAttention 实现新的注意力算子
```

**PR 描述**：包括
- 这解决了什么问题？
- 它如何解决的？
- 是否有破坏性变化？
- 进行的测试
- 相关 issue 的链接

**PR 审查流程**：
- 至少需要一名 FlagOS 维护者审查
- 及时处理审查意见
- 进行更改后重新请求审查
- 对反馈和建议保持开放态度

## 文档贡献

### 改进现有文档

1. Fork 和克隆仓库
2. 进行文档更新
3. 如果可能，本地预览更改
4. 提交 PR 并清晰描述更改内容

### 编写新文档

- 遵循现有文档风格
- 在适当位置包含代码示例
- 测试示例是否正确运行
- 链接到相关文档

### 翻译

帮助使 FlagOS 对全球用户可访问：
- 翻译文档
- 保持与现有翻译的一致性
- 如有可用，使用翻译工具
- 将翻译标记为社区贡献

## Bug 报告

### 报告前

1. 检查[现有 issue](https://github.com/flagos-ai) 以避免重复
2. 尝试最新版本 - bug 可能已被修复
3. 搜索已关闭的 issue - 您的问题可能已被解决

### 编写良好的 Bug 报告

```markdown
## 描述
清晰描述 bug 及其影响

## 复现步骤
1. 第一步
2. 第二步
3. 第三步

## 预期行为
应该发生什么

## 实际行为
实际发生了什么

## 环境
- 操作系统: [例如 Linux]
- Python 版本: [例如 3.10]
- 相关依赖版本
- 复现环境的差异

## 日志/错误信息
```
粘贴相关日志或错误信息
```

## 额外上下文
可能有帮助的任何其他信息
```

### 报告安全问题

**不要**为安全漏洞开设公开 issue。而是：
1. 发送邮件至 contact@flagos.io 提供详情
2. 如可能，包括复现步骤
3. 给我们时间回应和创建修复
4. 协调披露有助于保护所有用户

## 功能请求

### 建议功能

1. 检查现有 issue 和讨论
2. 描述使用场景和收益
3. 如适用，提供示例
4. 解释它如何符合 FlagOS 目标

### 功能请求模板

```markdown
## 描述
清晰描述请求的功能

## 使用场景
为什么需要此功能？它解决了什么问题？

## 建议解决方案
这个功能应该如何工作？

## 替代解决方案
您考虑过的其他方法？

## 额外上下文
任何草图、模型或相关 issue
```

## 社区参与

### 交流渠道

- **邮箱**: contact@flagos.io
- **微信公众号**: FlagOpen
- **微信视频号**: FlagOpen
- **GitHub Discussions**: [即将推出]
- **GitHub Issues**: 用于 bug 和功能请求

### 参与讨论

- 尊重和建设性
- 保持主题相关
- 避免垃圾信息或自我推广
- 先搜索现有讨论
- 提供背景和相关信息

### 帮助其他贡献者

- 回答您知道答案的问题
- 为新贡献者指出相关文档
- 分享知识和专业知识
- 对新手保持欢迎态度

## 行为准则

我们致力于提供热情和包容的社区。所有贡献者必须遵守我们的行为准则：

- **[Code of Conduct (English)](CODE_OF_CONDUCT.MD)**
- **[行为准则 (中文)](CODE_OF_CONDUCT_CN.MD)**

不可接受的行为包括骚扰、歧视和违反这些标准。

## 致谢

我们重视所有贡献！贡献者将通过以下方式获得认可：
- 在发布说明中被提及
- 添加到贡献者列表
- 在社区更新中获得认可
- 对重要贡献的特殊认可

## 有疑问？

不要犹豫提问！您可以：

1. **阅读文档**: 查看 [FlagOS Wiki](https://flagos-wiki.baai.ac.cn/)
2. **检查现有 issue**: 搜索类似问题
3. **在讨论中提问**: 当可用时使用 GitHub Discussions
4. **联系**: 邮件 contact@flagos.io
5. **加入社区**: 通过微信或其他渠道联系

## 其他资源

- [FlagOS 组织](https://github.com/flagos-ai)
- [FlagOS Wiki](https://flagos-wiki.baai.ac.cn/)
- [行为准则](CODE_OF_CONDUCT_CN.MD)
- [社区 README](README_CN.md)

---

**感谢您为 FlagOS 做出贡献！** 您的努力有助于构建一个更好、更具包容性的 AI 软件生态。

<div align="center">

英文版本：[English Version](CONTRIBUTING.md)

</div>

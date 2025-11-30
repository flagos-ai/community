<div align="center">

**Language** | **语言**

[English](CONTRIBUTING.md) | [中文](CONTRIBUTING_CN.md)

</div>

---

# Contributing to FlagOS

Welcome! We're excited to have you interested in contributing to FlagOS. This document provides guidelines and instructions for all types of contributions.

## Table of Contents

- [Ways to Contribute](#ways-to-contribute)
- [Getting Started](#getting-started)
- [Code Contribution Workflow](#code-contribution-workflow)
- [Documentation Contributions](#documentation-contributions)
- [Bug Reports](#bug-reports)
- [Feature Requests](#feature-requests)
- [Community Participation](#community-participation)
- [Code of Conduct](#code-of-conduct)
- [Questions?](#questions)

## Ways to Contribute

There are many ways to contribute to FlagOS:

### 💻 Code Contributions
- **Bug Fixes**: Help us squash bugs
- **New Features**: Implement requested features or your own ideas
- **Performance**: Optimize existing code for better performance
- **Tests**: Improve test coverage and reliability
- **Code Review**: Review other contributors' pull requests

### 📖 Documentation
- **README & Guides**: Improve project documentation
- **Examples**: Create examples and tutorials
- **API Docs**: Document APIs and functions
- **Translations**: Help translate documentation into other languages
- **Wiki**: Contribute to the FlagOS Wiki

### 🐛 Issue Management
- **Bug Reports**: Report issues you find
- **Feature Requests**: Suggest improvements
- **Issue Triage**: Help organize and prioritize issues
- **Issue Discussions**: Provide insights on existing issues

### 🤝 Community Support
- **Help Others**: Answer questions on communication channels
- **Mentoring**: Guide new contributors
- **Discussions**: Participate in technical discussions
- **Feedback**: Provide constructive feedback on proposals

## Getting Started

### Prerequisites
- Git knowledge (fork, clone, branch, commit)
- GitHub account
- Familiarity with the project you want to contribute to

### Understanding FlagOS Structure

FlagOS is a multi-repository project. Before contributing, identify which repository your contribution belongs to:

| Repository | Scope |
|------------|-------|
| **community** | Community governance, guidelines, and collaboration hub |
| **FlagGems** | High-performance AI operator implementations |
| **FlagTree** | AI compiler infrastructure |
| **FlagScale** | Distributed training and inference |
| **FlagCX** | Communication libraries |
| **FlagPerf** | Performance evaluation tools |
| **FlagAttention** | Attention operator optimizations |
| [More...](https://github.com/flagos-ai) | Other specialized projects |

### Setting Up Development Environment

For each FlagOS repository, follow its specific setup instructions found in its `README.md`:

```bash
# General workflow (specific steps may vary per repo)
1. Fork the repository to your GitHub account
2. Clone your fork locally:
   git clone https://github.com/YOUR_USERNAME/REPO_NAME.git
3. Add upstream remote:
   git remote add upstream https://github.com/flagos-ai/REPO_NAME.git
4. Create a branch for your work
5. Follow the setup instructions in that repo's README
```

## Code Contribution Workflow

### 1. Fork and Branch

```bash
# Fork the repository on GitHub (via GitHub web interface)
# Clone your fork
git clone https://github.com/YOUR_USERNAME/REPO_NAME.git
cd REPO_NAME

# Add upstream remote
git remote add upstream https://github.com/flagos-ai/REPO_NAME.git

# Create a feature branch
git checkout -b fix/your-fix-name
# or
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes

- Follow the code style and conventions of the repository
- Write clear, descriptive commit messages
- Add tests for new functionality
- Ensure existing tests still pass

### 3. Commit Guidelines

Use clear and descriptive commit messages:

```
# Good examples:
fix: resolve memory leak in operator cache
feat: add support for multi-head attention optimization
docs: update CONTRIBUTING.md with new workflow
test: add unit tests for FlagGems operators

# Format: <type>: <description>
# Types: feat, fix, docs, style, refactor, test, chore, perf
```

### 4. Code Formatting and Quality

Many FlagOS repositories use pre-commit hooks for code formatting. Before committing:

```bash
# If using pre-commit (check repo's README)
pip install pre-commit
pre-commit install
# Then commit - hooks will run automatically

# Or manually format
black .          # Python formatting
flake8 .         # Linting
# etc.
```

### 5. Running Tests

Before pushing, run tests:

```bash
# Example for Python projects (specific commands vary by repo)
pytest tests/           # Run all tests
pytest tests/unit/      # Run specific test suite

# Check for failing tests
pytest -v               # Verbose output
```

### 6. Pushing and Creating a Pull Request

```bash
# Update your branch from upstream
git fetch upstream
git rebase upstream/main

# Push your branch
git push origin your-branch-name

# Create PR on GitHub:
# 1. Go to your fork on GitHub
# 2. Click "Compare & pull request"
# 3. Fill in the PR template
# 4. Submit
```

### 7. Pull Request Guidelines

**PR Title**: Should be clear and descriptive
```
fix: resolve crash in FlagScale distributed training
feat: implement new attention operator for FlagAttention
```

**PR Description**: Include
- What problem does this solve?
- How does it solve it?
- Any breaking changes?
- Testing done
- Links to related issues

**PR Review Process**:
- At least one FlagOS maintainer review required
- Address review comments promptly
- Re-request review after making changes
- Be open to feedback and suggestions

## Documentation Contributions

### Improving Existing Documentation

1. Fork and clone the repository
2. Make documentation updates
3. Preview changes locally if possible
4. Submit PR with clear description of changes

### Writing New Documentation

- Follow existing documentation style
- Include code examples where appropriate
- Test that examples work correctly
- Link to related documentation

### Translations

Help make FlagOS accessible globally:
- Translate documentation
- Maintain consistency with existing translations
- Use translation tools if available
- Mark translations as community-contributed

## Bug Reports

### Before Reporting

1. Check [existing issues](https://github.com/flagos-ai) to avoid duplicates
2. Try the latest version - the bug might already be fixed
3. Search closed issues - your issue might have been resolved

### Writing a Good Bug Report

```markdown
## Description
Clear description of the bug and its impact

## Reproduction Steps
1. Step one
2. Step two
3. Step three

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: [e.g., Linux]
- Python version: [e.g., 3.10]
- Relevant dependency versions
- How reproduction environment differs

## Logs/Error Messages
```
Paste relevant logs or error messages here
```

## Additional Context
Any other information that might be helpful
```

### Reporting Security Issues

**DO NOT** open public issues for security vulnerabilities. Instead:
1. Email us at contact@flagos.io with details
2. Include steps to reproduce if possible
3. Allow time for us to respond and create a fix
4. Coordinated disclosure helps protect all users

## Feature Requests

### Suggesting a Feature

1. Check existing issues and discussions
2. Describe the use case and benefits
3. Provide examples if applicable
4. Explain how it fits with FlagOS goals

### Feature Request Template

```markdown
## Description
Clear description of the requested feature

## Use Case
Why is this feature needed? What problem does it solve?

## Proposed Solution
How should this feature work?

## Alternative Solutions
Any other approaches you've considered?

## Additional Context
Any sketches, mockups, or related issues
```

## Community Participation

### Communication Channels

- **Email**: contact@flagos.io
- **WeChat Official Account**: FlagOpen
- **WeChat Channels**: FlagOpen
- **GitHub Discussions**: [Coming Soon]
- **GitHub Issues**: Use for bugs and feature requests

### Participating in Discussions

- Be respectful and constructive
- Stay on topic
- Avoid spam or self-promotion
- Search existing discussions first
- Provide context and relevant information

### Helping Other Contributors

- Answer questions you know the answer to
- Point new contributors to relevant documentation
- Share knowledge and expertise
- Be welcoming to newcomers

## Code of Conduct

We are committed to providing a welcoming and inclusive community. All contributors must adhere to our Code of Conduct:

- **[Code of Conduct (English)](CODE_OF_CONDUCT.MD)**
- **[行为准则 (中文)](CODE_OF_CONDUCT_CN.MD)**

Unacceptable behavior includes harassment, discrimination, and violations of these standards.

## Recognition

We value all contributions! Contributors will be recognized through:
- Mentions in release notes
- Addition to contributors list
- Recognition in community updates
- Special recognition for significant contributions

## Questions?

Don't hesitate to ask for help! You can:

1. **Read the docs**: Check the [FlagOS Wiki](https://flagos-wiki.baai.ac.cn/)
2. **Check existing issues**: Search for similar questions
3. **Ask in discussions**: Use GitHub Discussions when available
4. **Contact**: Email contact@flagos.io
5. **Join community**: Connect via WeChat or other channels

## Additional Resources

- [FlagOS Organization](https://github.com/flagos-ai)
- [FlagOS Wiki](https://flagos-wiki.baai.ac.cn/)
- [Code of Conduct](CODE_OF_CONDUCT.MD)
- [Community README](README.md)

---

**Thank you for contributing to FlagOS!** Your efforts help build a better, more inclusive AI software ecosystem.

<div align="center">

Chinese version: [中文版本](CONTRIBUTING_CN.md)

</div>

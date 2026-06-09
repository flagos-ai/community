# Documentation Style Guide

## Language

- All user-facing documentation must be available in both Chinese and English
- Technical documentation (API Reference, code comments) should be primarily in English
- Governance documents (GOVERNANCE, Charter, etc.) must be available in both Chinese and English

## File Naming

- Markdown files use lowercase-hyphenated English naming: `how-to-contribute.md`
- Chinese versions use a suffix: `how-to-contribute_CN.md` or `how-to-contribute.md` + `CONTRIBUTING_CN.md`
- Directories use lowercase-hyphenated naming: `sig-operator/`

## Markdown Conventions

- Use `#` for headings, up to 4 levels maximum
- Align tables, annotate code blocks with language
- Use relative paths for links (do not use absolute paths or external URLs for internal file references)

## Minimum README Requirements per Module

Each FlagOS module's README.md should include at minimum:

```markdown
# Module Name

## Introduction
(1 paragraph in Chinese + 1 paragraph in English, briefly explaining what the module is)

## Quick Start
(A minimal example that can be run in under 30 minutes)

## Installation
(Supported chips, Python version, dependencies)

## API Documentation
(Or link to docs.flagos.io)

## Contributing
(Link to contributor/ guides)

## License
```

## PR Documentation Requirements

- New features must include documentation updates (README, API docs, or a separate doc)
- Breaking changes must be noted in the PR description
- Documentation PRs also require review

## Translation

- Technical terms should remain in English or use widely-accepted translations
- Mark uncertain translations with "to be verified"
- Use a glossary for consistency (to be established by sig-documentation)

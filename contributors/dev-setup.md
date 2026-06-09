# Development Environment Setup

## Common Prerequisites

- Python 3.10+
- Git
- pip / conda

## By Module

Refer to each module's repository README for environment setup instructions:

| Module | Repository | Entry Point |
|--------|------------|-------------|
| FlagGems | [flagos-ai/FlagGems](https://github.com/flagos-ai/FlagGems) | README.md |
| FlagTree | [flagos-ai/FlagTree](https://github.com/flagos-ai/FlagTree) | README.md |
| FlagCX | [flagos-ai/flagcx](https://github.com/flagos-ai/flagcx) | README.md |
| FlagScale | [flagos-ai/FlagScale](https://github.com/flagos-ai/FlagScale) | README.md |
| PyTorch-Plugin-FL | [flagos-ai/PyTorch-Plugin-FL](https://github.com/flagos-ai/PyTorch-Plugin-FL) | README.md |
| vllm-plugin-FL | [flagos-ai/vllm-plugin-FL](https://github.com/flagos-ai/vllm-plugin-FL) | README.md |
| Other modules | [flagos-ai](https://github.com/flagos-ai) | Corresponding repo README |

## Developing in the community Repository

The community repository is primarily documentation and governance processes. To preview locally:

```bash
git clone git@github.com:FlagOS-AI/community.git
cd community
# Preview using any Markdown editor
```

## Multi-Chip Development

If you are developing on a specific chip, please confirm:

1. The chip SDK is installed per [chip-targets.toml](../release/chip-targets-2.1-rc2.toml)
2. The Docker base image is available (see `harbor.baai.ac.cn/flagbase/`)
3. The chip CI runner is configured (contact sig-chip)

## FAQ

See [faq.md](faq.md)

# sig-training: Training Orchestration

> **The ML engineer's daily tool SIG.** FlagScale is the entry point for users running large-scale training and inference.

## Scope

**Responsible Modules:**
- [FlagScale](https://github.com/flagos-ai/FlagScale) — Distributed training and inference framework

**In Scope:**
- Distributed training/inference orchestration
- Training recipes (pre-training, fine-tuning, SFT, RLHF)
- Model parallelism strategies and auto-configuration
- Integration with ecosystems such as Hugging Face
- Multi-chip training support

**Out of Scope:**
- Framework adapters → sig-framework
- Communication library → sig-network
- Benchmarking and performance evaluation → sig-benchmark (planned)

## Members

### Chairs
| Name | GitHub | Affiliation | Status |
|------|--------|-------------|--------|
| (TBD) | — | — | Pending TSC confirmation |

### Tech Leads
| Name | GitHub | Affiliation | Status |
|------|--------|-------------|--------|
| (TBD) | — | — | Pending TSC confirmation |

## Communication

- **Meetings**: TBD (biweekly)
- **WeChat Group**: To be created
- **Meeting Notes**: [meetings/](meetings/)

## Decision Making

- Routine PR approval: Subproject Maintainers (see [data/projects.yaml](../../data/projects.yaml))
- FEP approval: Chair + Tech Lead
- Major SIG internal decisions: 2/3 majority vote
- Unresolved disputes escalate to TSC

## Key Deliverables

- **Training Recipes**: Training configurations for mainstream models (Llama, Qwen, DeepSeek, etc.)
- **Hugging Face Integration**: One-click migration from HF models to FlagScale
- **Performance Tuning Guide**: Training performance tuning checklist and best practices

## Subprojects

(None at this time)

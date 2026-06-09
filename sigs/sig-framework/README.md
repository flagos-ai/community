# sig-framework: Framework Adapter Layer

> **The primary user-facing SIG.** Most users enter FlagOS through PyTorch/vLLM/SGLang — the adapter experience determines whether users stay.

## Scope

**Responsible Modules:**
- [PyTorch-Plugin-FL](https://github.com/flagos-ai/PyTorch-Plugin-FL) — PyTorch adaptation
- [vllm-plugin-FL](https://github.com/flagos-ai/vllm-plugin-FL) — vLLM adaptation
- [sglang-plugin-FL](https://github.com/flagos-ai/sglang-plugin-FL) — SGLang adaptation
- [TransformerEngine-FL](https://github.com/flagos-ai/TransformerEngine-FL) — TransformerEngine adaptation
- [Megatron-LM-FL](https://github.com/flagos-ai/Megatron-LM-FL) — Megatron-LM adaptation
- [verl-FL](https://github.com/flagos-ai/verl-FL) — veRL adaptation

**In Scope:**
- Framework adapter development and maintenance
- Upstream framework version tracking and compatibility testing
- Migration guides and compatibility matrix maintenance
- Framework-level performance optimization
- User troubleshooting support

**Out of Scope:**
- Operator implementation → sig-operator
- Distributed training orchestration → sig-training
- Communication → sig-network

## Members

### Chairs
| Name | GitHub | Affiliation | Status |
|------|--------|-------------|--------|
| (TBD) | — | — | Pending TSC confirmation |

### Tech Leads
| Name | GitHub | Affiliation | Status |
|------|--------|-------------|--------|
| (TBD) | — | — | Pending TSC confirmation |

### Approvers
See [OWNERS](./OWNERS)

## Communication

- **Meetings**: TBD (biweekly)
- **WeChat Group**: To be created
- **Meeting Notes**: [meetings/](meetings/)

## Decision Making

- Routine PR/FEP approval: Any Approver in OWNERS may approve
- Major SIG internal decisions: 2/3 majority vote
- Unresolved disputes escalate to TSC

## Key Deliverables

- **Compatibility Matrix**: Compatibility table for each FlagOS version × each framework version
- **Migration Guide**: Minimal-change migration steps from native frameworks to FlagOS
- **Troubleshooting FAQ**: Common issues and solutions
- **Example Directory**: Standalone examples for each framework adapter

## Subprojects

| Subproject | Responsible Framework | Owner |
|------------|----------------------|-------|
| pytorch-plugin | PyTorch | (TBD) |
| vllm-plugin | vLLM | (TBD) |
| sglang-plugin | SGLang | (TBD) |
| te-plugin | TransformerEngine | (TBD) |
| megatron-plugin | Megatron-LM | (TBD) |
| verl-plugin | veRL | (TBD) |

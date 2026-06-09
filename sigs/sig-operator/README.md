# sig-operator: Operator Libraries

## Scope

**Responsible Modules:**
- [FlagGems](https://github.com/flagos-ai/FlagGems) — High-performance AI operators
- [FlagAttention](https://github.com/flagos-ai/FlagAttention) — Attention operator optimization
- [FlagFFT](https://github.com/flagos-ai/FlagFFT) — FFT operators
- [FlagSparse](https://github.com/flagos-ai/FlagSparse) — Sparse computation operators
- [FlagDNN](https://github.com/flagos-ai/FlagDNN) — DNN operator library
- [FlagBLAS](https://github.com/flagos-ai/FlagBLAS) — BLAS operator library
- [FlagTensor](https://github.com/flagos-ai/FlagTensor) — Tensor operation library
- [FlagAudio](https://github.com/flagos-ai/FlagAudio) — Audio processing operators

**In Scope:**
- Operator implementation, performance optimization, multi-chip adaptation
- Operator API design and iteration
- Operator correctness testing and accuracy validation
- Operator documentation and usage examples

**Out of Scope:**
- Compiler backend optimization → sig-compiler
- Framework-level adaptation (PyTorch/vLLM plugins) → sig-framework
- Communication operators → sig-network

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

## Subprojects

(None at this time; may be split by operator category in the future)

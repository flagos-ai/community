# sig-chip: Datacenter Chip Adaptation

> **Multi-chip support is FlagOS's core differentiating capability.** This SIG is responsible for datacenter AI chip SDK integration, performance optimization, and vendor collaboration.
>
> Note the distinction from sig-edge: sig-chip covers datacenter training/inference accelerators, while sig-edge covers edge/IoT inference devices.

## Scope

**Covered Chips:**
| Chip | Vendor | SDK | Status |
|------|--------|-----|--------|
| NVIDIA CUDA | NVIDIA | CUDA 13.0 | Active |
| Hygon DTK | Hygon | DTK 26.04 | Active |
| Iluvatar CoreX | Iluvatar | CoreX 4.4.0 | Active |
| MetaX MACA | MetaX | MACA 3.5.3.9 | Active |
| TsingMicro TXDA | TsingMicro | TXDA SDK 3.3 | Active |
| T-Head XuanTie | T-Head | — | Active |
| Ascend CANN | Huawei | CANN 3.2 | Adapting |
| Kunlunxin XPU | Kunlunxin | XPU SDK 3.0 | Adapting |
| MThreads MUSA | Moore Threads | MUSA 4.0.0 | Adapting |
| Enflame GCU | Enflame | GCU 3.7.1 | Planned |
| SpacemiT | SpacemiT | — | Planned |
| Sunrise TPU | Sophgo | — | Planned |
| AMD ROCm | AMD | — | Planned |

**In Scope:**
- Chip bring-up process management
- Vendor SDK version tracking (aligned with chip-targets.toml)
- Multi-chip CI infrastructure
- Chip-specific performance optimization coordination
- Vendor contributor onboarding

**Out of Scope:**
- Operator implementation → sig-operator (but chip-specific optimization proposals require sig-chip review)
- Framework adaptation → sig-framework
- Edge hardware → sig-edge (planned)
- Benchmark data collection → sig-benchmark (planned)

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
- New chip access approval: sig-chip internal 2/3 vote + TSC approval
- Unresolved disputes escalate to TSC

## Chip Vendor Participation

Vendor participation follows a 4-tier model: Contributor → Approver → Chair → TSC. For detailed promotion criteria, see [contributors/roles.md](../../contributors/roles.md).

**New Vendor Onboarding Process:**
1. Submit a [Chip Support Request](chip-support-request.md)
2. sig-chip evaluation (SDK version, CI resources, compliance)
3. TSC approval
4. Create chip-specific directory and CI pipeline

## Key Deliverables

- **chip-targets.toml**: Inventory of all chip SDK versions and Docker base images
- **Multi-chip CI Dashboard**: Visualization of build/test status across chips
- **Chip Integration Guide**: Onboarding documentation for chip vendors

## Subprojects

| Subproject | Chip | Owner |
|------------|------|-------|
| nvidia-cuda | NVIDIA CUDA | (TBD) |
| hygon-dtk | Hygon DTK | (TBD) |
| (others added per chip) | | |

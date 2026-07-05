# Chip Vendor Onboarding Guide

## Overview

FlagOS supports multi-chip AI acceleration. Chip vendors (including but not limited to GPU, NPU, and TPU vendors) may add their chips to the FlagOS support matrix through a standardized process.

> **Vendor neutrality**: FlagOS maintains neutrality toward all chip vendors. Chip onboarding evaluation is based on technical merit and CI delivery capability; no special treatment is given based on a vendor's commercial influence. See [GOVERNANCE.md](../GOVERNANCE.md) for project principles.

> **Bootstrap note:** sig-chip currently has no Chair or Approver; evaluation and approval are handled directly by the TSC. Before the TSC is established, the ZhongZhi FlagOS Community acts in its stead. See [GOVERNANCE.md](../GOVERNANCE.md) for bootstrap phase transition.

## Onboarding Process

```
Submit Application ──→ sig-chip Evaluation ──→ TSC Approval ──→ CI Delivery ──→ Bring-up ──→ Official Support
```

## Step 1: Submit Chip Support Request

Complete the [Chip Support Request](../sigs/sig-chip/chip-support-request.md) form and submit it as a PR to the community repo.

The application must include:
- Basic chip and SDK information
- CI resource commitment (self-hosted runner or hardware provision)
- At least 2 initial contributors
- SDK License compatibility confirmation

## Step 2: sig-chip Evaluation

sig-chip evaluates and provides feedback within 2 weeks on:
- Whether the SDK License is compatible with FlagOS open-source licensing
- Whether CI resources meet requirements (see CI Tiers)
- Whether the initial contributors have the requisite capability

## Step 3: TSC Approval

After sig-chip evaluation passes, the TSC votes to approve within 2 weeks.

## Step 4: CI Delivery

The vendor deploys CI runners or provides remote hardware access. sig-chip verifies that the CI pipeline is operational.

> **CI delivery deadline**: The estimated delivery date committed in the application is a hard deadline. If delivery is over 4 weeks late and no extension reason has been communicated to sig-chip (or the TSC during the bootstrap phase), the approval automatically lapses and a new application must be submitted.

### Handling Failed Evaluation

If sig-chip evaluation or TSC approval does not pass, the reviewer must clearly state the reason for rejection in the feedback. The vendor may resubmit the application after resolving the rejection reasons (no cooling-off period). When resubmitting, the PR description must reference the original application and describe the issues that have been resolved.

## Step 5: Bring-up

Vendor engineers implement chip adaptation code in FlagOS. Once completed, validation passes through CI.

## Step 6: Official Support

After bring-up is complete, the chip is added to `chip-targets.toml` and is officially supported in FlagOS releases.

## CI Tiers

| Tier | Requirement | Privilege |
|------|-------------|-----------|
| **Tier 1** (e.g., NVIDIA) | CI runs on every PR, blocks merge | Highest-priority support |
| **Tier 2** (e.g., Hygon, Iluvatar, MetaX) | CI runs on every PR, non-blocking (alerts on failure, does not block merge) | Standard support |
| **Tier 3** (bring-up in progress) | CI in daily/weekly report form | Incubating |

Tier promotions and demotions are decided by sig-chip in quarterly evaluations.

## Vendor Participation Path

The growth path for chip vendor engineers in FlagOS is the same as for other contributors:

```
Chip Contributor → Reviewer → Approver → (sig-chip) Tech Lead → Chair → TSC
```

See [roles.md](roles.md) for detailed promotion criteria.

## Related Resources

- [sig-chip Charter](../sigs/sig-chip/README.md)
- [chip-targets-2.1-rc2.toml](../release/2.1/chip-targets-2.1-rc2.toml)
- [Chip Support Request Form](../sigs/sig-chip/chip-support-request.md)

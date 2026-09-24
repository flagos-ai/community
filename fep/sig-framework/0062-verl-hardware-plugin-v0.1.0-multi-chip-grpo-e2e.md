# FEP-0062: verl-hardware-plugin v0.1.0 — Multi-Chip GRPO E2E Tests (MetaX, Iluvatar, Cambricon MLU)

**Status:** `Implementable`

**Updated:** 2026-09-24

**Created:** 2026-07-23

**Owner:** @heavyrain-lzy

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

## Summary

Validate Qwen3-0.6B GRPO training on GSM8K through `verl-hardware-plugin`
0.1.0 on MetaX, Iluvatar and Cambricon MLU. Platform and engine integrations
are merged. The recorded MetaX and Iluvatar runs passed; the MLU acceptance
issue remains open.

## Source and Acceptance Status

The plugin is maintained in
[verl-project/verl-hardware-plugin](https://github.com/verl-project/verl-hardware-plugin).
The inspected `main` revision is
[`d437ff13633e`](https://github.com/verl-project/verl-hardware-plugin/tree/d437ff13633e50f3e3eeb7e167758943c13754e9).
There is no corresponding RC2 branch or entry in the FlagOS 2.2 RC2 manifest.
Later main-branch changes require a release revision before inclusion.

| Platform | Implementation | Recorded GRPO acceptance |
|---|---|---|
| MetaX | Platform and FSDP/Megatron engines, PR #7 | Passed on 2026-07-29 |
| Iluvatar | Platform and FSDP/Megatron engines, PR #3 | Passed on 2026-07-29 |
| Cambricon MLU | Platform and engines, PR #1; later runtime/checkpoint fixes | Failed; no passing rerun in community#73 |

[community#73](https://github.com/flagos-ai/community/issues/73) records the
three-platform acceptance status. The current README's MLU support label
does not resolve that specific GRPO failure.

## Design

The `verl.plugins` entry point loads `verl_hardware_plugin` and registers
platforms and engines. Engine lookup first uses the exact device/vendor pair,
then the supported device-level fallback. The acceptance recipe uses FSDP
with vLLM rollout; the presence of Megatron engines does not extend this
test scope.

| Platform | Device | Runtime communication | Detection / Ray resource |
|---|---|---|---|
| MetaX | `cuda` | NCCL API / MCCL | `mx-smi` / `GPU` |
| Iluvatar | `cuda` | NCCL API / IXCCL | `ixsmi` / `GPU` |
| Cambricon | `mlu` | CNCL | `torch.mlu` / `MLU` |

CUDA-compatible platform detection uses vendor SMI commands to distinguish
devices. MLU uses `torch_mlu` and requires Ray workers to advertise the
`MLU` resource. Hardware runtimes and compatible framework packages come
from each platform's environment.

## Packaging

`pyproject.toml` declares version `0.1.0`, Python >=3.10 and `verl>=0.7.0`.
Install from the selected source revision:

```bash
python -m pip install --no-build-isolation -e '.[dev]'
python -m pytest tests/test_plugin_registration.py -v
```

The broad dependency lower bound is not a tested version matrix. Acceptance
records must include the exact verl, plugin, PyTorch, rollout and SDK versions.

## Test Plan

Follow the hardware-specific setup guide and run
`scripts/baseline_grpo_gsm8k.sh` with Qwen3-0.6B, GSM8K, FSDP, vLLM rollout
and `adv_estimator=grpo`:

- [MetaX guide](https://github.com/verl-project/verl-hardware-plugin/blob/d437ff13633e50f3e3eeb7e167758943c13754e9/docs/user_guide_metax/README.md)
- [Iluvatar guide](https://github.com/verl-project/verl-hardware-plugin/blob/d437ff13633e50f3e3eeb7e167758943c13754e9/docs/user_guide_iluvatar/README.md)
- [MLU guide](https://github.com/verl-project/verl-hardware-plugin/blob/d437ff13633e50f3e3eeb7e167758943c13754e9/docs/user_guide_mlu/README.md)

Use identical hyperparameters and the NVIDIA reference configuration.
Require the expected platform/engine selection and a clear upward trend in
`critic/rewards/mean` within the first 100 steps. Preserve configuration,
environment, logs and reward curves. Absolute convergence and performance
tuning remain outside this acceptance scope.

Completion requires a passing MLU rerun and a pinned release revision.

## Recorded Validation

[The FEP review](https://github.com/flagos-ai/community/pull/62) records
passing MetaX and Iluvatar GRPO runs. The unresolved item is the MLU rerun in
[community#73](https://github.com/flagos-ai/community/issues/73).
No later passing MLU result was located in the reviewed release records;
this does not invalidate the other two platforms' completed tests.

## Related PRs

- [x] [verl-hardware-plugin#1](https://github.com/verl-project/verl-hardware-plugin/pull/1) — Cambricon MLU integration. Merged.
- [x] [verl-hardware-plugin#3](https://github.com/verl-project/verl-hardware-plugin/pull/3) — Iluvatar integration. Merged.
- [x] [verl-hardware-plugin#7](https://github.com/verl-project/verl-hardware-plugin/pull/7) — MetaX integration. Merged.
- [x] [verl-hardware-plugin#5](https://github.com/verl-project/verl-hardware-plugin/pull/5) — End-to-end and formatting checks. Merged.
- [x] [verl-hardware-plugin#14](https://github.com/verl-project/verl-hardware-plugin/pull/14) — Plugin registration CI. Merged.
- [x] [verl-hardware-plugin#16](https://github.com/verl-project/verl-hardware-plugin/pull/16) — MLU checkpoint buffer reuse on main. Merged.
- [x] [verl-hardware-plugin#19](https://github.com/verl-project/verl-hardware-plugin/pull/19) — MLU runtime dependency checks on main. Merged.

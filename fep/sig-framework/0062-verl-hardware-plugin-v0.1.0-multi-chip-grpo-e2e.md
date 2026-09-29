# FEP-0062: GRPO Validation on MetaX and Iluvatar

**Status:** `Implemented`

**Updated:** 2026-09-24

**Created:** 2026-07-23

**Owner:** @heavyrain-lzy

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

## Summary

Validate Qwen3-0.6B GRPO training on GSM8K through
`verl-hardware-plugin` 0.1.0, FSDP and vLLM rollout on MetaX and Iluvatar.

## Source

[verl-hardware-plugin](https://github.com/verl-project/verl-hardware-plugin/tree/d437ff13633e50f3e3eeb7e167758943c13754e9)
at `d437ff13633e50f3e3eeb7e167758943c13754e9` contains the accepted platform
integrations. The plugin has no separate RC2 entry in the FlagOS manifest.

## Implementation

The `verl.plugins` entry point loads `verl_hardware_plugin`. Engine lookup
uses the device/vendor pair, followed by the supported device-level fallback.

| Platform | Device | Communication | Detection / Ray resource |
|---|---|---|---|
| MetaX | `cuda` | NCCL API / MCCL | `mx-smi` / `GPU` |
| Iluvatar | `cuda` | NCCL API / IXCCL | `ixsmi` / `GPU` |

The accepted recipe uses FSDP with vLLM rollout. Megatron-engine validation
is outside this recipe.

## Packaging

`pyproject.toml` declares version `0.1.0`, Python >=3.10 and `verl>=0.7.0`.
Install from the selected source revision:

```bash
python -m pip install --no-build-isolation -e '.[dev]'
python -m pytest tests/test_plugin_registration.py -v
```

## Validation

| Platform | Qwen3-0.6B / GSM8K GRPO | Record |
|---|---|---|
| MetaX | Passed, 2026-07-29 | [FEP review](https://github.com/flagos-ai/community/pull/62) |
| Iluvatar | Passed, 2026-07-29 | [Acceptance record](https://github.com/flagos-ai/community/issues/73) |

Use `scripts/baseline_grpo_gsm8k.sh` with `adv_estimator=grpo` in the
[MetaX](https://github.com/verl-project/verl-hardware-plugin/blob/d437ff13633e50f3e3eeb7e167758943c13754e9/docs/user_guide_metax/README.md)
or [Iluvatar](https://github.com/verl-project/verl-hardware-plugin/blob/d437ff13633e50f3e3eeb7e167758943c13754e9/docs/user_guide_iluvatar/README.md)
environment. The acceptance check is correct platform/engine selection and
an upward reward trend within the first 100 steps.

## Related PRs

- [x] [verl-hardware-plugin#3](https://github.com/verl-project/verl-hardware-plugin/pull/3) — Iluvatar integration. Merged.
- [x] [verl-hardware-plugin#7](https://github.com/verl-project/verl-hardware-plugin/pull/7) — MetaX integration. Merged.
- [x] [verl-hardware-plugin#5](https://github.com/verl-project/verl-hardware-plugin/pull/5) — End-to-end and formatting checks. Merged.
- [x] [verl-hardware-plugin#14](https://github.com/verl-project/verl-hardware-plugin/pull/14) — Plugin registration CI. Merged.

## Deferred to FlagOS 2.3

Cambricon MLU GRPO acceptance and runtime/checkpoint validation: [community#73](https://github.com/flagos-ai/community/issues/73), [plugin#16](https://github.com/verl-project/verl-hardware-plugin/pull/16), [plugin#19](https://github.com/verl-project/verl-hardware-plugin/pull/19).

# FEP-0092: FlagScale Qwen Training and Checkpoint Portability

**Status:** `Implemented`

**Updated:** 2026-09-24

**Created:** 2026-07-30

**Owner:** Unassigned

**SIG:** sig-training

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| flagscale | [`2.1.0-rc2` @ `333964d5937e`](https://github.com/flagos-ai/FlagScale/tree/333964d5937ec2401d4324b92569158c663154de) | [`v2.1.0-rc2.post2` @ `333964d5937e`](https://github.com/flagos-ai/FlagScale/tree/333964d5937ec2401d4324b92569158c663154de) |

## Summary

FlagScale 2.1 integrates Megatron Core 0.18.2, Qwen training/checkpoint
updates and native Ascend adaptation. The 2.2 scope includes the validated
four-platform Qwen configurations and GR00T N1.5 checkpoint portability.

## Delivered Scope

| Feature | Implementation | Validation |
|---|---|---|
| Qwen training | Device overrides, native Ascend adaptor and Core 0.18.2 | PPU/Hygon/Ascend/MetaX training |
| Qwen checkpoints | Save/load and conversion tools | 2TP-to-4TP continuation |
| GR00T portability | Runtime device override and saved base-model path | Ascend training, reload and action inference |

## Design

The override plugin selects device-specific Megatron functions. Ascend's
MegatronAdaptor is integrated in-tree. Qwen checkpoint tools convert model
weights for the destination tensor-parallel configuration.

GR00T saves an absolute local base-model path or a HuggingFace identifier.
Serving replaces the processor's saved device with the runtime device.
The shared serving entry point is `flagscale/serve/run_serve_vla.py`.

## Packaging

Use the pinned FlagScale source with the platform-specific training image
and matching Megatron-LM-FL/TransformerEngine-FL versions. The module version
is 2.1.0 within FlagOS 2.2. The YAML runner remains the user entry point.
Debian/RPM integration is still open in PR #1205 and tracked by
[FEP-0019](../sig-os/0019-unified-package-integration.md).

## Test Commands

```bash
python -m pytest -q tests/unit_tests/checkpoint/test_qwen35_converter.py
python -m pytest -q flagscale/train/megatron/plugin_flagscale/test_override.py
```

Run the model's training configuration, save a checkpoint, convert it and
resume training. GR00T validation also checks the saved base-model path,
runtime device override, `/healthz` and action output.

## Validation

The [September 24 execution matrix](https://jwolpxeehx.feishu.cn/wiki/Kg47wjKm1if8eOk1GfscLiIcnDe) records Qwen3-0.6B training,
checkpoint save/load and converted-weight continuation on PPU, Hygon,
Ascend and MetaX. Qwen3.5-4B passed the vendor and FlagOS TE routes with
FlagCX disabled, including 2TP-to-4TP checkpoint conversion.

[PR #1219](https://github.com/flagos-ai/FlagScale/pull/1219) records five-step
GR00T N1.5 training on Ascend 910B, checkpoint save, a simulated saved MUSA
device, and successful reload on NPU. `/healthz` returned `OK`; WebSocket
inference returned actions of shape `(16, 7)`.

## Known Limitations

FlagCX-enabled training remains affected by
[Megatron-LM-FL#172](https://github.com/flagos-ai/Megatron-LM-FL/issues/172).
Full FlagGems enablement is not part of the accepted Qwen3.5 configuration:
PPU/MetaX runs exclude selected operators, and Hygon/Ascend have recorded
failures with FlagGems enabled.

## Related PRs

- [x] [FlagScale#1214](https://github.com/flagos-ai/FlagScale/pull/1214) — Function-level override plugin. Merged.
- [x] [FlagScale#1226](https://github.com/flagos-ai/FlagScale/pull/1226) — Native Ascend adaptor. Merged.
- [x] [FlagScale#1233](https://github.com/flagos-ai/FlagScale/pull/1233) — Qwen3.5 MoE conversion and uneven pipeline parallelism. Merged.
- [x] [FlagScale#1219](https://github.com/flagos-ai/FlagScale/pull/1219) — GR00T checkpoint portability. Merged.
- [x] [FlagScale#1225](https://github.com/flagos-ai/FlagScale/pull/1225) — Unified VLA serving entry point. Merged.
- [x] [FlagScale#1284](https://github.com/flagos-ai/FlagScale/pull/1284) — Megatron Core 0.18.2 update. Merged.
- [x] [FlagScale#1283](https://github.com/flagos-ai/FlagScale/pull/1283) — Training-only CI scope. Merged.
- [x] [FlagScale#1301](https://github.com/flagos-ai/FlagScale/pull/1301) — RC2 source update. Merged.

## Deferred to FlagOS 2.3

- Monitoring overhead and distributed straggler/performance acceptance for [#1215](https://github.com/flagos-ai/FlagScale/pull/1215), [#1216](https://github.com/flagos-ai/FlagScale/pull/1216) and heartbeat [#1243](https://github.com/flagos-ai/FlagScale/pull/1243).
- Model acceptance for Qwen3.6 [#1273](https://github.com/flagos-ai/FlagScale/pull/1273), GLM5 [#1227](https://github.com/flagos-ai/FlagScale/pull/1227), Qwen3-VL [#1235](https://github.com/flagos-ai/FlagScale/pull/1235) and Qwen-GR00T [#1228](https://github.com/flagos-ai/FlagScale/pull/1228).
- The complete PI0/PI0.5/Qwen-GR00T/GR00T serving matrix and physical cross-node checkpoint reload.
- DualPipeV scheduling regression for [#1207](https://github.com/flagos-ai/FlagScale/pull/1207) and PI0.5 loading-memory measurements for [#1221](https://github.com/flagos-ai/FlagScale/pull/1221).

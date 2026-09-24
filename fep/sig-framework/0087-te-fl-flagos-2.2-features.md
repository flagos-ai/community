# FEP-0087: TransformerEngine 2.17 and Four-Platform Training Integration

**Status:** `Implemented`

**Updated:** 2026-09-24

**Created:** 2026-07-30

**Owner:** Unassigned

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| transformerengine-fl | [`0.3.0-rc2` @ `255a6bfd28b2`](https://github.com/flagos-ai/TransformerEngine-FL/tree/255a6bfd28b295bb2b35e111fdfeeba63bbac1d7) | [`v0.3.0-rc2.post2` @ `255a6bfd28b2`](https://github.com/flagos-ai/TransformerEngine-FL/tree/255a6bfd28b295bb2b35e111fdfeeba63bbac1d7) |

## Summary

TransformerEngine-FL 0.3 integrates upstream TransformerEngine 2.17.0.
The 2.2 acceptance scope covers Qwen training through the vendor and FlagOS
TE routes on PPU, Hygon, Ascend and MetaX.

## Delivered Scope

| Feature | Implementation | Validation |
|---|---|---|
| Upstream synchronization | TE 2.17.0 and FL plugin interfaces | Four-platform Megatron regression |
| Vendor/FlagOS dispatch | Backend registry and reference/FlagOS operator paths | Qwen3-0.6B and Qwen3.5-4B training |
| Training integration | Optimizer and checkpoint interfaces | Save/load and converted-checkpoint continuation |

## Design

Vendor dispatch lives under `transformer_engine/plugin/core/backends/vendor/`.
Reference and FlagOS implementations provide shared operator paths. RC2 adds
fused RoPE, optimizer completion, compute-scale fixes and communication-overlap
factory compatibility.

Ascend uses the in-tree integration with vendor runtime components. RC2 also
contains MetaX TE package-layout compatibility through PR #130.

## Packaging

Build with the selected vendor's PyTorch and TE runtime following its
repository build guide. Python packaging and native libraries use the
upstream TE build system; dependencies and ABI differ by vendor.

```bash
python -m pip wheel . --no-build-isolation --no-deps -w dist
```

## Test Commands

Shared plugin tests:

```bash
python -m pytest -q tests/plugin/plugin
python -m pytest -q tests/plugin/backend/reference
python -m pytest -q tests/plugin/backend/flagos
```

NVIDIA test entry:

```bash
bash tests/plugin/backend/cuda/run_unit_tests.sh unittest distributed
```

## Validation

The [September 24 execution matrix](https://jwolpxeehx.feishu.cn/wiki/Kg47wjKm1if8eOk1GfscLiIcnDe) records Qwen3-0.6B training,
checkpoint save/load and converted-weight continuation on PPU, Hygon,
Ascend and MetaX. Qwen3.5-4B passed the vendor and FlagOS TE routes with
FlagCX disabled, including 2TP-to-4TP checkpoint conversion.

## Known Limitations

FlagCX-enabled training remains affected by
[Megatron-LM-FL#172](https://github.com/flagos-ai/Megatron-LM-FL/issues/172).
Full FlagGems enablement is not part of the accepted Qwen3.5 configuration:
PPU/MetaX runs exclude selected operators, and Hygon/Ascend have recorded
failures with FlagGems enabled.

## Related PRs

- [x] [TransformerEngine-FL#79](https://github.com/flagos-ai/TransformerEngine-FL/pull/79) — Ascend MegatronAdaptor integration. Merged.
- [x] [TransformerEngine-FL#83](https://github.com/flagos-ai/TransformerEngine-FL/pull/83) — FlagOS fused RoPE kernels. Merged.
- [x] [TransformerEngine-FL#84](https://github.com/flagos-ai/TransformerEngine-FL/pull/84) — Kunlunxin backend integration. Merged.
- [x] [TransformerEngine-FL#88](https://github.com/flagos-ai/TransformerEngine-FL/pull/88) — Tsingmicro backend. Merged.
- [x] [TransformerEngine-FL#91](https://github.com/flagos-ai/TransformerEngine-FL/pull/91) — Ascend unit-test CI. Merged.
- [x] [TransformerEngine-FL#94](https://github.com/flagos-ai/TransformerEngine-FL/pull/94) — Kunlunxin unit and MCore integration tests. Merged.
- [x] [TransformerEngine-FL#95](https://github.com/flagos-ai/TransformerEngine-FL/pull/95) — TP communication-overlap operator interfaces. Merged.
- [x] [TransformerEngine-FL#105](https://github.com/flagos-ai/TransformerEngine-FL/pull/105) — Upstream TE 2.17 synchronization. Merged.
- [x] [TransformerEngine-FL#108](https://github.com/flagos-ai/TransformerEngine-FL/pull/108) — FlagOS Adam interface completion. Merged.
- [x] [TransformerEngine-FL#109](https://github.com/flagos-ai/TransformerEngine-FL/pull/109) — Reference Adam interface completion. Merged.
- [x] [TransformerEngine-FL#110](https://github.com/flagos-ai/TransformerEngine-FL/pull/110) — Reference compute-scale semantics. Merged.
- [x] [TransformerEngine-FL#115](https://github.com/flagos-ai/TransformerEngine-FL/pull/115) — Vendor communication-overlap factory arguments. Merged.
- [x] [TransformerEngine-FL#125](https://github.com/flagos-ai/TransformerEngine-FL/pull/125) — RC2 backports. Merged.
- [x] [TransformerEngine-FL#127](https://github.com/flagos-ai/TransformerEngine-FL/pull/127) — Additional RC2 backports. Merged.
- [x] [TransformerEngine-FL#130](https://github.com/flagos-ai/TransformerEngine-FL/pull/130) — MetaX TE package-layout compatibility in RC2. Merged.

## Deferred to FlagOS 2.3

Complete the ten-vendor operator and communication-overlap matrix; validate FSA sparse attention.

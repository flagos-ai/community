# FEP-0086: Megatron Core 0.18.2 and Qwen Training on Four Platforms

**Status:** `Implemented`

**Updated:** 2026-09-24

**Created:** 2026-07-30

**Owner:** Unassigned

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| megatron-lm-fl | [`0.3.0-rc2` @ `066fd5edf541`](https://github.com/flagos-ai/Megatron-LM-FL/tree/066fd5edf5413839172c5a65785ea381f75febf1) | [`v0.3.0-rc2.post1` @ `c8fa61f2e403`](https://github.com/flagos-ai/Megatron-LM-FL/tree/c8fa61f2e403f490baf4cf43fbad24a122f7225a) |

## Summary

Megatron-LM-FL 0.3 integrates Megatron Core 0.18.2 and supports the
validated Qwen training and checkpoint configurations on PPU, Hygon, Ascend
and MetaX.

## Delivered Scope

| Feature | Implementation | Validation |
|---|---|---|
| Core update | Megatron Core 0.18.2 with FL platform hooks | Qwen training regression |
| Platform integration | Device discovery, vendor dispatch and runtime compatibility | Four-platform Qwen3/Qwen3.5 runs |
| Checkpoints | Save/load and tensor-parallel conversion | 2TP-to-4TP continuation |

`megatron/plugin/platform/` provides registration, device operations and
dispatch. CUDA-compatible vendors reuse the CUDA route. RC2 includes
non-CUDA runtime fixes and MetaX JIT-fuser compatibility.

## Packaging

Build from the RC2 source with the matching vendor PyTorch, communication
libraries and TransformerEngine-FL:

```bash
python -m pip wheel . --no-build-isolation --no-deps -w dist
```

PR #189 restores the full Megatron package scope in the RC2 wheel.

## Test Commands

```bash
torchrun --nproc_per_node=8 -m pytest tests/unit_tests -v
```

Run the Qwen model configuration with the vendor-specific PyTorch and TE-FL
environment. Preserve the loss curve, checkpoint conversion and restart logs.

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

- [x] [Megatron-LM-FL#68](https://github.com/flagos-ai/Megatron-LM-FL/pull/68) — Ascend MegatronAdaptor integration. Merged.
- [x] [Megatron-LM-FL#109](https://github.com/flagos-ai/Megatron-LM-FL/pull/109) — Megatron Core 0.18.2 synchronization. Merged.
- [x] [Megatron-LM-FL#126](https://github.com/flagos-ai/Megatron-LM-FL/pull/126) — Chunked cross entropy. Merged.
- [x] [Megatron-LM-FL#156](https://github.com/flagos-ai/Megatron-LM-FL/pull/156) — Non-CUDA accelerator runtimes. Merged.
- [x] [Megatron-LM-FL#179](https://github.com/flagos-ai/Megatron-LM-FL/pull/179) — Vendor compatibility and CI fixes in RC2. Merged.
- [x] [Megatron-LM-FL#186](https://github.com/flagos-ai/Megatron-LM-FL/pull/186) — MetaX JIT-fuser fix in RC2. Merged.
- [x] [Megatron-LM-FL#189](https://github.com/flagos-ai/Megatron-LM-FL/pull/189) — Restore full-scope RC2 wheel packaging. Merged.

## Deferred to FlagOS 2.3

- Complete the ten-vendor matrix and upstream platform proposal, including Kunlunxin [#63](https://github.com/flagos-ai/Megatron-LM-FL/pull/63) and Enflame [#45](https://github.com/flagos-ai/Megatron-LM-FL/pull/45) hardware acceptance.
- Additional Qwen3.6/GLM5 model and parallelism acceptance, including GLM5 DSA [#69](https://github.com/flagos-ai/Megatron-LM-FL/pull/69) and the SM90 fused DSA kernel [#86](https://github.com/flagos-ai/Megatron-LM-FL/pull/86).
- Sparse-attention context parallelism: [Megatron-LM-FL#57](https://github.com/flagos-ai/Megatron-LM-FL/pull/57).
- FlashSparseAttention and recursive transformer: [Megatron-LM-FL#88](https://github.com/flagos-ai/Megatron-LM-FL/pull/88).

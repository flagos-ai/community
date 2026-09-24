# FEP-0086: Megatron-LM-FL New Features for FlagOS 2.2

**Status:** `Implementable`

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

Megatron-LM-FL 0.3 updates the upstream base to Megatron Core 0.18.2 and adds
vendor integration, GLM5-family DSA attention and training fixes. The
10-vendor acceptance matrix and upstream platform proposal are incomplete.

## Goals and Completion

| Goal | RC2 implementation | Remaining work |
|---|---|---|
| G1: Ten vendor platforms | CUDA, MUSA, NPU, TXDA, Kunlunxin and Enflame platform classes; CUDA-compatible vendors reuse shared paths | Publish the ten-vendor model/precision/parallelism matrix and results |
| G2: Upstream platform abstraction | Local platform and override interfaces present | Link an upstream RFC or PR |
| G3: Megatron Core 0.18.2 | Version and source synchronization present | Four-platform Qwen3.5 validation recorded; full ten-vendor matrix remains open |
| G4: Qwen3.5/3.6 and GLM5-family model work | DSA module and SM90 kernel present; Qwen integrations also depend on FlagScale | Qwen3.5 results recorded; remaining models, context parallelism and FlashSparseAttention need completion |

DeepSeek-V4 base architecture support is part of the 2.1 baseline.

## Design

`megatron/plugin/platform/` provides platform registration, detection, device
operations and vendor dispatch. CUDA-compatible vendors can reuse the CUDA
class; the number of platform files is not a vendor acceptance count.

The core update retains FL platform hooks, overrides, heterogeneous pipeline
support and experimental attention. GLM5-family DSA implementation and tests
are under `megatron/core/transformer/experimental_attention_variant/` and
`tests/unit_tests/transformer/experimental_attention_variant/`.

RC2 stabilization includes native accelerator detection, non-CUDA runtime
support, vendor compatibility fixes and a MetaX JIT-fuser change. These fixes
and PR #189 packaging restoration are ahead of the manifest tag shown above.
PR #189 restores the full Megatron package scope in the wheel.

## Packaging

Build from the RC2 source with the matching vendor PyTorch, communication
libraries and TransformerEngine-FL:

```bash
python -m pip wheel . --no-build-isolation --no-deps -w dist
```

Platform test environments are defined by the repository's per-vendor CI
workflows. A common wheel or container for all vendors is not established.

## Test Plan

On the target training platform:

```bash
torchrun --nproc_per_node=8 -m pytest tests/unit_tests -v
torchrun --nproc_per_node=8 -m pytest \
  tests/unit_tests/transformer/experimental_attention_variant -v
```

Run the matching `tests/functional_tests` model configuration for each claimed
platform and parallelism mode. Require reference-compatible loss, successful
checkpoint handling and no regression after the 0.18.2 upgrade. Report
throughput separately from correctness.

Qwen3.5 validation is recorded below. The remaining model/vendor matrix
and upstream proposal are outstanding. FlagCX-enabled training has an open report in
[Megatron-LM-FL#172](https://github.com/flagos-ai/Megatron-LM-FL/issues/172).

## Recorded Validation

The [September 24 execution matrix](https://jwolpxeehx.feishu.cn/wiki/Kg47wjKm1if8eOk1GfscLiIcnDe) records Qwen3-0.6B training,
checkpoint save/load and converted-weight continuation across PPU, Hygon,
Ascend and MetaX. Qwen3.5-4B also passed the vendor and FlagOS TE routes
with FlagCX disabled, including 2TP-to-4TP checkpoint conversion.

The full-stack paths have narrower coverage: selected FlagGems operators
are disabled on PPU/MetaX, and the matrix records failing Qwen3.5 cases on
Hygon/Ascend with FlagGems enabled. FlagCX training is a separate unresolved
path, tracked in [Megatron-LM-FL#172](https://github.com/flagos-ai/Megatron-LM-FL/issues/172).

## Related PRs

- [x] [Megatron-LM-FL#63](https://github.com/flagos-ai/Megatron-LM-FL/pull/63) — Kunlunxin platform. Merged.
- [x] [Megatron-LM-FL#45](https://github.com/flagos-ai/Megatron-LM-FL/pull/45) — Enflame platform. Merged.
- [x] [Megatron-LM-FL#68](https://github.com/flagos-ai/Megatron-LM-FL/pull/68) — Ascend MegatronAdaptor integration. Merged.
- [x] [Megatron-LM-FL#69](https://github.com/flagos-ai/Megatron-LM-FL/pull/69) — GLM5-family DSA models. Merged.
- [x] [Megatron-LM-FL#86](https://github.com/flagos-ai/Megatron-LM-FL/pull/86) — SM90 fused DSA kernel. Merged.
- [x] [Megatron-LM-FL#109](https://github.com/flagos-ai/Megatron-LM-FL/pull/109) — Megatron Core 0.18.2 synchronization. Merged.
- [x] [Megatron-LM-FL#126](https://github.com/flagos-ai/Megatron-LM-FL/pull/126) — Chunked cross entropy. Merged.
- [x] [Megatron-LM-FL#156](https://github.com/flagos-ai/Megatron-LM-FL/pull/156) — Non-CUDA accelerator runtimes. Merged.
- [x] [Megatron-LM-FL#179](https://github.com/flagos-ai/Megatron-LM-FL/pull/179) — Vendor compatibility and CI fixes in RC2. Merged.
- [x] [Megatron-LM-FL#186](https://github.com/flagos-ai/Megatron-LM-FL/pull/186) — MetaX JIT-fuser fix in RC2. Merged.
- [ ] [Megatron-LM-FL#57](https://github.com/flagos-ai/Megatron-LM-FL/pull/57) — DeepSeek-V4 sparse-attention context parallelism. Open.
- [ ] [Megatron-LM-FL#88](https://github.com/flagos-ai/Megatron-LM-FL/pull/88) — FlashSparseAttention and recursive transformer. Open.
- [x] [Megatron-LM-FL#189](https://github.com/flagos-ai/Megatron-LM-FL/pull/189) — Restore full-scope RC2 wheel packaging. Merged.

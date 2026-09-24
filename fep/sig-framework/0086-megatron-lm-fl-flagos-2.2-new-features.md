# FEP-0086: Megatron-LM-FL New Features for FlagOS 2.2

**Status:** `Provisional`

**Updated:** 2026-09-24

**Created:** 2026-07-30

**Owner:** Unassigned

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| megatron-lm-fl | [`0.3.0-rc2` @ `f376a47d3d93`](https://github.com/flagos-ai/Megatron-LM-FL/tree/f376a47d3d93e59eb408fdcbd065bd2b6a11ba47) | [`v0.3.0-rc2.post1` @ `c8fa61f2e403`](https://github.com/flagos-ai/Megatron-LM-FL/tree/c8fa61f2e403f490baf4cf43fbad24a122f7225a) |

## Summary

Megatron-LM-FL 0.3 updates the upstream base to Megatron Core 0.18.2 and adds
vendor integration, GLM5-family DSA attention and training fixes. The
10-vendor acceptance matrix and upstream platform proposal are incomplete.

## Goals and Completion

| Goal | RC2 implementation | Remaining work |
|---|---|---|
| G1: Ten vendor platforms | CUDA, MUSA, NPU, TXDA, Kunlunxin and Enflame platform classes; CUDA-compatible vendors reuse shared paths | Publish the ten-vendor model/precision/parallelism matrix and results |
| G2: Upstream platform abstraction | Local platform and override interfaces present | Link an upstream RFC or PR |
| G3: Megatron Core 0.18.2 | Version and source synchronization present | Complete release regression on each declared platform |
| G4: Qwen3.5/3.6 and GLM5-family model work | DSA module and SM90 kernel present; Qwen integrations also depend on FlagScale | Release model results; context-parallel and FlashSparseAttention work remains open |

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
support, vendor compatibility fixes and a MetaX JIT-fuser change. The last
two changes are ahead of the manifest tag shown above.

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

The cross-vendor matrix, Qwen3.5/3.6 release runs and upstream proposal remain
outstanding. FlagCX-enabled training has an open report in
[Megatron-LM-FL#172](https://github.com/flagos-ai/Megatron-LM-FL/issues/172).

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

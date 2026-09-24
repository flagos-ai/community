# FEP-0099: FlagGems Operator and TLE Kernel Optimization

**Status:** `Implemented`

**Updated:** 2026-09-24

**Created:** 2026-08-01

**Owner:** Unassigned

**SIG:** sig-operator

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| flaggems | [`5.4.0-rc2` @ `6ed2f39071ef`](https://github.com/flagos-ai/FlagGems/tree/6ed2f39071ef85db26b7e64f0652a162f434959c) | [`v5.4.0-rc2.post4` @ `6ed2f39071ef`](https://github.com/flagos-ai/FlagGems/tree/6ed2f39071ef85db26b7e64f0652a162f434959c) |
| flaggems-vllm | [`0.2.0-rc2` @ `b61c244b0cce`](https://github.com/flagos-ai/FlagGems-vllm/tree/b61c244b0cce2d3762d2a6a47c35efe2207bc7a3) | [`v0.2.0-rc2.post1` @ `b61c244b0cce`](https://github.com/flagos-ai/FlagGems-vllm/tree/b61c244b0cce2d3762d2a6a47c35efe2207bc7a3) |

## Summary

FlagGems 5.4 and FlagGems-vLLM add low-bit MoE, reduction and
shape-dependent kernel paths, plus TLE optimizations for KV cache, MHC,
indexer fusion and TopK.

## Delivered Scope

| Feature | Implementations | Validation |
|---|---|---|
| Low-bit and fused MoE | FP8/FP4 storage, dequantization, matrix operations and fused routing | Numerical suites and development benchmarks |
| Reduction and dispatch | Axis-specific reduction; shape/layout-dependent paths | FlagGems QA |
| TLE kernels | `reshape_and_cache`, `reshape_and_cache_flash`, `mhc_bwd`, `fused_indexer_q_rope_quant`, TopK | Kernel tests and H800 development results |

## Implementation

Low-bit paths include `per_token_group_quant_fp8`, `fp8_fp4_mega_moe`,
`fused_marlin_moe` and block-FP8 matrix multiplication. Reduction kernels
select paths by axis and layout. Sparse attention, `mul` and `index` select
paths by shape and layout.

TLE kernels use FlagTree's explicit memory and scheduling primitives.
Tests record the selected implementation, dtype and shape so alternate
kernel paths remain distinguishable.

## Packaging

Build the pinned library revisions with the matching FlagTree and vendor
runtime. Debian/RPM publication is tracked separately in
[FEP-0019](../sig-os/0019-unified-package-integration.md).

## Test Commands

FlagGems:

```bash
python -m pytest -q tests/test_fp8_fp4_mega_moe.py \
  tests/test_fused_marlin_moe.py tests/test_per_token_group_quant_fp8.py \
  tests/test_w8a8_block_fp8_matmul.py tests/test_topk.py
```

FlagGems-vLLM:

```bash
python -m pytest -q tests/test_persistent_topk.py tests/test_mhc_ops.py \
  tests/test_reshape_and_cache.py tests/test_reshape_and_cache_flash.py \
  tests/test_fused_indexer_q_rope_quant.py
```

## Validation

The [release QA record](https://jwolpxeehx.feishu.cn/wiki/MuxCwz4q3iV8BzkwmJtcfJZwnah) marks FlagGems testing complete.
The [operator delivery record](https://jwolpxeehx.feishu.cn/docx/HwHNdMsfCoAXoRxmeNzcNZZQnMe) contains the named TLE kernel
benchmarks and low-bit, fusion, reduction and dispatch results.

The [backend test matrix](https://jwolpxeehx.feishu.cn/docx/NozxdnxSooZVqmxPynLcJyuXnVg)
retains skips and platform-specific failures. Support and performance are
limited to the tested operator/dtype/shape/backend combinations.

## Related PRs

- [x] [FlagGems-vllm#12](https://github.com/flagos-ai/FlagGems-vllm/pull/12) — MLA TLE split-KV path. Merged.
- [x] [FlagGems-vllm#20](https://github.com/flagos-ai/FlagGems-vllm/pull/20) — NSA compression. Merged.
- [x] [FlagGems-vllm#29](https://github.com/flagos-ai/FlagGems-vllm/pull/29) — Parallel NSA. Merged.
- [x] [FlagGems-vllm#21](https://github.com/flagos-ai/FlagGems-vllm/pull/21) — KDA operators. Merged.
- [x] [FlagGems-vllm#23](https://github.com/flagos-ai/FlagGems-vllm/pull/23) — KDA optimization. Merged.
- [x] [FlagGems-vllm#55](https://github.com/flagos-ai/FlagGems-vllm/pull/55) — KDA fast path. Merged.
- [x] [FlagGems-vllm#22](https://github.com/flagos-ai/FlagGems-vllm/pull/22) — GLA operator. Merged.
- [x] [FlagGems-vllm#26](https://github.com/flagos-ai/FlagGems-vllm/pull/26) — Indexer RoPE/quantization fusion. Merged.
- [x] [FlagGems-vllm#37](https://github.com/flagos-ai/FlagGems-vllm/pull/37) — GDN operators. Merged.
- [x] [FlagGems-vllm#38](https://github.com/flagos-ai/FlagGems-vllm/pull/38) — GDN2 operators. Merged.
- [x] [FlagGems-vllm#56](https://github.com/flagos-ai/FlagGems-vllm/pull/56) — Persistent TopK. Merged.
- [x] [FlagGems#4081](https://github.com/flagos-ai/FlagGems/pull/4081) — Indexer RoPE/quantization fusion. Merged.
- [x] [FlagGems#4572](https://github.com/flagos-ai/FlagGems/pull/4572) — Triton/TLE TopK paths. Merged.
- [x] [FlagGems#4322](https://github.com/flagos-ai/FlagGems/pull/4322) — FP8/FP4 fused MoE. Merged.
- [x] [FlagGems#5437](https://github.com/flagos-ai/FlagGems/pull/5437) — Marlin MoE optimization. Merged.
- [x] [FlagGems#4794](https://github.com/flagos-ai/FlagGems/pull/4794) — Block-FP8 matrix multiplication. Merged.

## Deferred to FlagOS 2.3

- The complete six-family attention matrix and five-domestic-chip performance targets, including FlagAttention GDN [#34](https://github.com/flagos-ai/FlagAttention/pull/34)/[#40](https://github.com/flagos-ai/FlagAttention/pull/40), KDA [#41](https://github.com/flagos-ai/FlagAttention/pull/41) and sparse attention/GLA [#42](https://github.com/flagos-ai/FlagAttention/pull/42).
- FlagAttention SageAttention and GDN2 TLE release integration: [#43](https://github.com/flagos-ai/FlagAttention/pull/43), [#44](https://github.com/flagos-ai/FlagAttention/pull/44), merged on main outside RC2.
- Domain-library acceptance and a deduplicated 635-operator inventory: 334 manual and 301 generated operators. The manual targets are FlagBLAS 21, FlagDNN 20, FlagSparse 12, FlagFFT 14 and the FlagGems family 267. Each entry records source revision, implementation provenance and per-platform results.

# FEP-0099: Operator Library for FlagOS 2.2

**Status:** `Implementable`

**Updated:** 2026-09-24

**Created:** 2026-08-01

**Owner:** Unassigned

**SIG:** sig-operator

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| flaggems | [`5.4.0-rc2` @ `6ed2f39071ef`](https://github.com/flagos-ai/FlagGems/tree/6ed2f39071ef85db26b7e64f0652a162f434959c) | [`v5.4.0-rc2.post4` @ `6ed2f39071ef`](https://github.com/flagos-ai/FlagGems/tree/6ed2f39071ef85db26b7e64f0652a162f434959c) |
| flagblas | [`0.3.0-rc2` @ `824b256fe4c5`](https://github.com/flagos-ai/FlagBLAS/tree/824b256fe4c5a0e5a8645f4752248bcdfcb61d6f) | [`v0.3.0-rc2.post2` @ `a1897220dd06`](https://github.com/flagos-ai/FlagBLAS/tree/a1897220dd06596e44e8add94cfb084b41cbb98a) |
| flagdnn | [`0.3.0-rc2` @ `42bcbcc23beb`](https://github.com/flagos-ai/FlagDNN/tree/42bcbcc23beb8d6af287485c0df55935f38f92e9) | [`v0.3.0-rc2.post2` @ `42bcbcc23beb`](https://github.com/flagos-ai/FlagDNN/tree/42bcbcc23beb8d6af287485c0df55935f38f92e9) |
| flagsparse | [`0.3.0-rc2` @ `b15bbcc509d3`](https://github.com/flagos-ai/FlagSparse/tree/b15bbcc509d388c27bff7e8b180017aefc7ed1f4) | [`v0.3.0-rc2.post1` @ `2d4eee7ff0a6`](https://github.com/flagos-ai/FlagSparse/tree/2d4eee7ff0a6095dc8daf28a0dd2c4e0d76e0ad5) |
| flagfft | [`0.2.0-rc2` @ `5eecfd409b65`](https://github.com/flagos-ai/FlagFFT/tree/5eecfd409b655458a7b0d4aaad53f802660bc66f) | [`v0.2.0-rc2.post2` @ `5eecfd409b65`](https://github.com/flagos-ai/FlagFFT/tree/5eecfd409b655458a7b0d4aaad53f802660bc66f) |
| flagattention | [`0.4.0-rc2` @ `ff6a63543741`](https://github.com/flagos-ai/FlagAttention/tree/ff6a63543741953c7c48a478211794b113064429) | [`v0.4.0-rc2.post1` @ `2dd3a7408c3f`](https://github.com/flagos-ai/FlagAttention/tree/2dd3a7408c3ff1b11baccb8758392c5da5f3aef6) |
| flaggems-vllm | [`0.2.0-rc2` @ `b61c244b0cce`](https://github.com/flagos-ai/FlagGems-vllm/tree/b61c244b0cce2d3762d2a6a47c35efe2207bc7a3) | [`v0.2.0-rc2.post1` @ `b61c244b0cce`](https://github.com/flagos-ai/FlagGems-vllm/tree/b61c244b0cce2d3762d2a6a47c35efe2207bc7a3) |
| flaggems-sglang | [`0.1.0-rc2` @ `e72037ad1909`](https://github.com/flagos-ai/FlagGems-sglang/tree/e72037ad19095ecbe40368c2fa45e6b3070e979a) | [`v0.1.0-rc2.post1` @ `e72037ad1909`](https://github.com/flagos-ai/FlagGems-sglang/tree/e72037ad19095ecbe40368c2fa45e6b3070e979a) |

## Summary

Expand FlagOS operator coverage, attention kernels, TLE-based operators and
shared optimization techniques. RC2 contains many named implementations and
tests. Release QA records completed FlagGems testing, and development reports
record operator counts and multi-chip performance. The complete attention
set and the mapping of that inventory to RC2 still have gaps.

## Goals and Completion

| Goal | RC2 status | Remaining work |
|---|---|---|
| G1: 635 operators | Multiple library and model-specific implementations present | Development counts reported; map deduplicated entries to RC2 revisions |
| G2: Six attention families | MLA, KDA, GDN/GLA and sparse-attention code present | SageAttention in RC2, exact family mapping and five-chip acceptance |
| G3: Five TLE operators | KV-cache, MHC, indexer fusion and TopK paths/tests present | Per-path TLE attribution and performance matrix |
| G4: Shared optimizations | Low-bit MoE, fusion, reduction and shape dispatch changes present | Results reported; retain per-workload baselines and release revisions |

FlagAttention PRs #43 (SageAttention) and #44 (GDN2 TLE) are merged on main
but absent from the inspected RC2 source. FlagGems-vLLM has a separate GDN2
implementation in RC2; its presence does not include those FlagAttention PRs.

## Operator Inventory Target

| Manual library target | Count |
|---|---|
| FlagBLAS | 21 |
| FlagDNN | 20 |
| FlagSparse | 12 |
| FlagFFT | 14 |
| FlagGems family | 267 |
| Total manual | 334 |
| Generated | 301 |
| Combined | 635 |

These are planning counts. The generated subset names at least 35 SGLang,
3 vLLM, 4 telecom-model and 3 Mianbi operators, but does not enumerate the
full 301. Acceptance needs stable operator identifiers, repository/revision,
manual/generated provenance, test cases and supported chips. Count operators
once across shared libraries and vendor specializations.

## Implementation

Attention implementations span FlagAttention and FlagGems-vLLM:

| Family | RC2 implementation/test evidence |
|---|---|
| MLA | FlagGems-vLLM `tests/test_flash_mla.py` and related MLA paths |
| KDA | FlagAttention `src/fla/chunk_kda.py`; FlagGems-vLLM KDA tests |
| GDN/GDN2 | FlagAttention gated-delta-rule paths; FlagGems-vLLM `tests/test_FLA/test_chunk_gdn2.py` |
| GLA | FlagAttention `src/flag_attn/FLA/gated_linear_attention/`; FlagGems-vLLM GLA tests |
| Sparse attention | FlagGems-vLLM NSA paths; FlagAttention Minimax sparse attention is a distinct implementation |
| SageAttention | PR #43 is outside FlagAttention RC2 |

The five TLE targets are `reshape_and_cache`, `reshape_and_cache_flash`,
`mhc_bwd`, `fused_indexer_q_rope_quant` and TopK. Their public tests exist in
FlagGems and/or FlagGems-vLLM. Correctness tests must record the selected
implementation to distinguish TLE paths from alternate kernels.

Shared optimization work covers:

- FP8/FP4 storage, dequantization and accumulation in
  `per_token_group_quant_fp8`, `fp8_fp4_mega_moe`, `fused_marlin_moe` and
  block-FP8 matrix multiplication.
- Fused dequantization, matrix multiplication, activation and routing in
  MoE kernels.
- Reduction-axis-specific paths for `prod`, `std`, `log_softmax` and `any`.
- Shape/layout-dependent dispatch for sparse attention, `mul` and `index`.

Compiler primitives are defined in
[FEP-0096](../sig-compiler/0096-flagtree-tle-megakernel-and-distributed.md).
The [KernelGen Knowledge Hub](../sig-kernelgen/0093-kernelgen-knowledge-and-tool-hub.md)
is a separate proposal and does not establish the generated-operator count.

## Packaging

Use each module's RC2 revision with the matching FlagTree and vendor runtime.
Python libraries provide their repository build/install entry points;
native libraries retain their CMake/toolchain requirements. System-package
status is tracked in [FEP-0019](../sig-os/0019-unified-package-integration.md).

## Test Plan

Run tests from the corresponding repository checkout on supported hardware.
FlagAttention:

```bash
python -m pytest -q tests/flag_attn/test_gated_delta_rule.py \
  tests/flag_attn/test_chunk_gla.py \
  tests/flag_attn/test_minimax_sparse_attention.py \
  tests/test_FLA/test_chunk_kda.py
```

FlagGems-vLLM:

```bash
python -m pytest -q tests/test_flash_mla.py \
  tests/test_FLA/test_chunk_gdn2.py tests/test_FLA/test_chunk_gla.py \
  tests/test_FLA/test_chunk_kda.py tests/test_persistent_topk.py \
  tests/test_mhc_ops.py tests/test_reshape_and_cache.py \
  tests/test_reshape_and_cache_flash.py tests/test_fused_indexer_q_rope_quant.py
```

FlagGems:

```bash
python -m pytest -q tests/test_fp8_fp4_mega_moe.py \
  tests/test_fused_marlin_moe.py tests/test_per_token_group_quant_fp8.py \
  tests/test_w8a8_block_fp8_matmul.py tests/test_topk.py
```

For each claimed operator, retain its reference, dtype/shape matrix,
numerical tolerance, selected kernel and skipped cases. Performance acceptance
requires the following baselines and a fixed workload:

| Target | Baseline requirement |
|---|---|
| MLA | Pinned vLLM CUDA implementation |
| KDA | Pinned official FlashKDA CUDA implementation |
| GDN2, GLA and NSA | Pinned corresponding FLA implementation |
| SageAttention | Named reference implementation and complete RC2 kernel |
| Five TLE operators | Named native/reference kernel on NVIDIA H800 |
| Domestic-chip deployment | Native implementation on each of at least five named chips |

Record warmup, timing method, toolkit, hardware, compiler, source revisions
and per-shape results. The goal is competitive NVIDIA performance and
improvement over each target chip's native implementation. Development performance results are recorded below. Their aggregate counts
and speedups still need per-operator RC2 attribution for the complete
release inventory.

## Recorded Validation

The [release QA record](https://jwolpxeehx.feishu.cn/wiki/MuxCwz4q3iV8BzkwmJtcfJZwnah) marks FlagGems testing complete and
contains results for the domain and framework-specific libraries. The
[operator delivery record](https://jwolpxeehx.feishu.cn/docx/HwHNdMsfCoAXoRxmeNzcNZZQnMe) reports 334 manually implemented
operators, attention benchmarks and five TLE operator results. The
[September 24 development report](https://jwolpxeehx.feishu.cn/wiki/SJc8wh08si8x9vk9ECgcjXtPnJc) records 440 generated operators
meeting its five-chip performance threshold. These counts use different
inventories and cannot be added without deduplication and source mapping.

The QA detail retains platform skips, domain-library failures and incomplete
attention coverage. FlagAttention #43/#44 remain outside the inspected RC2
tree. Completed FlagGems QA and development performance results therefore
coexist with the remaining full-FEP release gaps.

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
- [x] [FlagAttention#34](https://github.com/flagos-ai/FlagAttention/pull/34) — GDN optimization. Merged.
- [x] [FlagAttention#40](https://github.com/flagos-ai/FlagAttention/pull/40) — Additional GDN paths. Merged.
- [x] [FlagAttention#41](https://github.com/flagos-ai/FlagAttention/pull/41) — TLE chunk KDA. Merged.
- [x] [FlagAttention#42](https://github.com/flagos-ai/FlagAttention/pull/42) — Minimax sparse attention and GLA. Merged.
- [x] [FlagAttention#43](https://github.com/flagos-ai/FlagAttention/pull/43) — SageAttention; merged on main but absent from RC2. Merged.
- [x] [FlagAttention#44](https://github.com/flagos-ai/FlagAttention/pull/44) — GDN2 TLE; merged on main but absent from RC2. Merged.
- [x] [FlagGems#4081](https://github.com/flagos-ai/FlagGems/pull/4081) — Indexer RoPE/quantization fusion. Merged.
- [x] [FlagGems#4572](https://github.com/flagos-ai/FlagGems/pull/4572) — Triton/TLE TopK paths. Merged.
- [x] [FlagGems#4322](https://github.com/flagos-ai/FlagGems/pull/4322) — FP8/FP4 fused MoE. Merged.
- [x] [FlagGems#5437](https://github.com/flagos-ai/FlagGems/pull/5437) — Marlin MoE optimization. Merged.
- [x] [FlagGems#4794](https://github.com/flagos-ai/FlagGems/pull/4794) — Block-FP8 matrix multiplication. Merged.

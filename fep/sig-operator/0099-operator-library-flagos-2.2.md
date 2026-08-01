# FEP-0099: Operator Library for FlagOS 2.2

**Status:** `Provisional`

**Created:** 2026-08-01

**Owner:** [TODO: @github-username]

**SIG:** sig-operator

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP covers the operator-library work planned for the
FlagOS 2.2 release cycle, across four directions:

1. **Operator scale** — grow the total operator set to 635, combining manually
   implemented operators with operators produced by KernelGen
   (flagos-ai/community#93).
2. **Attention operators** — high-performance Attention-class operators
   matching NVIDIA state-of-the-art, running on 5+ domestic chips.
3. **TLE key operators** — key operators built on the Triton Language Extension
   (TLE), using the compiler-side TLE work (flagos-ai/community#96) as the
   underlying capability.
4. **General optimization techniques** — low-bit, MegaKernel fusion, reduction
   layout, and shape-aware multi-path dispatch, applied to named operators.

Repositories: https://github.com/flagos-ai/FlagGems,
https://github.com/flagos-ai/FlagBLAS, https://github.com/flagos-ai/FlagDNN,
https://github.com/flagos-ai/FlagSparse, https://github.com/flagos-ai/FlagFFT,
https://github.com/flagos-ai/FlagAttention

## Motivation

FlagOS 2.2 advances the operator library along three axes: scale (more
operators covered), performance (Attention and key operators at NVIDIA
state-of-the-art on domestic chips), and generality (shared optimization
techniques reused across operators). Manual implementation and KernelGen
generation are counted together as one operator set so that coverage is
tracked against a single target rather than split across two workflows.

### Goals

**(Required)**

- **G1 (Operator scale):** Reach 635 total operators, composed of 334 manually
  implemented and 301 KernelGen-generated (flagos-ai/community#93). Includes
  the sub-targets in the [Operator Count](#operator-count) table.
- **G2 (Attention operators):** Deliver 6 high-performance Attention-class
  operators — Flash MLA, Flash KDA, GDN2, GLA, NSA and SageAttention — at
  NVIDIA-GPU state-of-the-art, then extend to 5+ domestic chips with
  performance above each vendor's native implementation. Targets in
  [Performance Targets](#performance-targets).
- **G3 (TLE key operators):** Deliver 5 high-value operators on the model core
  compute path, covering KV Cache, MHC, sparse-Attention fusion and FP8
  quantization, built on the compiler-side TLE capability
  (flagos-ai/community#96), at NVIDIA-GPU state-of-the-art, then extend to 5+
  domestic chips with performance above native. Targets in
  [Performance Targets](#performance-targets).
- **G4 (General optimization techniques):** Apply low-bit / mixed precision,
  MegaKernel fusion, reduction-layout optimization, and shape-aware multi-path
  dispatch across the operators named in Feature 4.

### Non-Goals

- The KernelGen tooling, knowledge base, and multi-chip generation mechanism
  itself, tracked in flagos-ai/community#93. This FEP counts the operators
  KernelGen produces but does not cover how KernelGen works.
- The compiler-side TLE capability (MegaKernel, distributed primitives,
  buffer aliasing), tracked in flagos-ai/community#96. This FEP consumes TLE
  but does not define it.

## Proposal

### Feature 1: Operator Scale

Grow the operator set to 635 total operators. Manually implemented operators
span FlagBLAS, FlagDNN, FlagSparse, FlagFFT and FlagGems; generated operators
are produced by KernelGen (flagos-ai/community#93) and counted in the same
total. The per-library and per-target breakdown is in the
[Operator Count](#operator-count) table.

### Feature 2: Attention Operators

Deliver 6 Attention-class operators — Flash MLA, Flash KDA, GDN2, GLA, NSA and
SageAttention (video-generation models) — at NVIDIA-GPU state-of-the-art, then
extend to 5+ domestic chips with performance above each vendor's native
implementation. Per-operator NVIDIA-GPU targets are in
[Performance Targets](#performance-targets).

<!-- TODO (design): per operator, the optimization approach and the target
     domestic chips. -->

### Feature 3: TLE Key Operators

Deliver 5 high-value operators on the model core compute path — covering KV
Cache, MHC, sparse-Attention fusion and FP8 quantization — at NVIDIA-GPU
state-of-the-art, then extend to 5+ domestic chips with performance above
native. The TLE capability itself (MegaKernel, distributed primitives) is
provided by the compiler side (flagos-ai/community#96); this feature is the
operator-side adoption of it.

<!-- TODO (design): map each of the 5 operators to its function
     (reshape_and_cache / reshape_and_cache_flash, mhc_bwd,
     fused_indexer_q_rope_quant, Topk, ...) and how each uses TLE. -->

### Feature 4: General Optimization Techniques

Apply reusable optimization techniques across operators:

- **Low-bit / mixed precision** — FP8/FP4 storage, online dequantization and
  high-precision accumulation, covering `per_token_group_quant_fp8`,
  `fp8_fp4_mega_moe`, `fused_marlin_moe`, `w8a8_block_fp8_bmm`.
- **MegaKernel fusion** — fuse dequantization, matmul, activation and routing
  weighting to cut intermediate memory traffic and kernel launches, mainly
  covering `fp8_fp4_mega_moe`, `fused_marlin_moe`.
- **Reduction-layout optimization** — separate kernels and parallel strategies
  for contiguous vs. non-contiguous reduction dimensions, covering `prod`,
  `std`, `log_softmax`, `any`.
- **Shape-aware multi-path dispatch** — select a plain or linearized execution
  path by shape, data layout and hardware, covering `sparse_attention`, `mul`,
  `index`.

## Design Details

<!-- TODO: implementation-level details for Features 2/3/4, to be filled before
     Status moves to `Implementable`. -->

## Operator Count

Total: **635** = **334** manually implemented + **301** KernelGen-generated
(flagos-ai/community#93).

### Manually implemented (334)

| Library | Count |
|---|---|
| FlagBLAS | 21 |
| FlagDNN | 20 |
| FlagSparse | 12 |
| FlagFFT | 14 |
| FlagGems (family) | 267 |
| **Total** | **334** |

### KernelGen-generated (301)

Generated via KernelGen (flagos-ai/community#93), running on 5+ domestic chips.
Named sub-targets:

| Sub-target | Count |
|---|---|
| gems-SGLang | ≥35 |
| gems-vLLM | 3 |
| Telecom-model operators | 4 |
| Mianbi operators | 3 |
| [TODO: remaining generated operators] | [TODO] |
| **Total** | **301** |

<!-- TODO: itemize the remaining generated operators so the named sub-targets
     sum to 301. The four named sub-targets above are the ones called out in
     the source; the balance is not itemized there. -->

## Performance Targets

Each speedup is against the baseline named in its row. Status is Pending until
re-measured on the release hardware.

### G2: Attention operators (NVIDIA GPU)

| Operator | Target | Baseline | Status |
|---|---|---|---|
| Flash MLA | 0.916–1.213× | vLLM CUDA version | Pending |
| Flash KDA | 1.15× | official FlashKDA CUDA version | Pending |
| GDN2 | 1.5–2× | fla Triton version | Pending |
| GLA | fwd 1.18–1.27× / fwd+bwd 1.03–1.12× | fla Triton version | Pending |
| NSA | 1.01–1.28× | fla Triton version | Pending |
| SageAttention | [TODO] | [TODO] | Pending |

### G3: TLE key operators (NVIDIA H800)

| Operator | Target | Status |
|---|---|---|
| reshape_and_cache | 185.874× | Pending |
| reshape_and_cache_flash | 138.981× | Pending |
| mhc_bwd | 155.972× | Pending |
| fused_indexer_q_rope_quant | 19.592× | Pending |
| Topk (with TLE primitives) | 2.03× | Pending |

<!-- TODO: SageAttention target/baseline; per-operator baselines for the H800
     TLE speedups (workload/shape); domestic-chip "above native" targets for
     both G2 and G3. -->

## Packaging

Installed from source per library.

```bash
# FlagGems
git clone https://github.com/flagos-ai/FlagGems.git
cd FlagGems && pip install .
```

<!-- TODO: build/install commands for FlagBLAS, FlagDNN, FlagSparse, FlagFFT
     and FlagAttention; packaging format (wheel vs. source); platform and
     toolkit version requirements per target chip. -->

## Test Plan

**(Required)** Each goal is verified independently. Acceptance runs on vendor
hardware; results (environment, logs, metrics) are attached to the tracking
issue by the testing party.

### G1: Operator scale

<!-- TODO: how the 635 count is verified — the operator inventory / test suite
     that enumerates implemented + generated operators, and the command that
     produces the count. -->

### G2: Attention operators

<!-- TODO: per Attention operator — correctness test command, performance
     benchmark command, target chips, NVIDIA SOTA baseline and parity
     tolerance. -->

### G3: TLE key operators

<!-- TODO: per key operator — test command and acceptance metric. -->

### G4: General optimization techniques

<!-- TODO: per technique/operator — test command and the measured effect
     that counts as passing. -->

## Related PRs

<!-- TODO: link the implementation PRs across FlagGems, FlagBLAS, FlagDNN,
     FlagSparse, FlagFFT and FlagAttention. -->

- [ ] flagos-ai/community#93 — KernelGen Knowledge and Tool Hub (source of the
  301 generated operators; cross-reference, not owned by this FEP)
- [ ] flagos-ai/community#96 — FlagTree TLE MegaKernel + distributed primitives
  (TLE capability consumed by G3/G4; cross-reference, not owned by this FEP)

## Implementation History

- 2026-08-01: FEP created as `Provisional` for the FlagOS 2.2 cycle.

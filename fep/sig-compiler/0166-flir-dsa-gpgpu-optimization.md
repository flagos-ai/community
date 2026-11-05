# FEP-0166: FLIR Optimization for Ascend and Domestic GPGPU Backends

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Extend [FlagTree](https://github.com/flagos-ai/FlagTree) FLIR/Common IR beyond its Ascend proof of concept. Deliver Tensor View, L1 reuse, vectorization and communication integration on Ascend, and layout optimization plus a Tile Op → Warp Op → TTGIR path on at least one domestic GPGPU backend. Target more than 30% improvement on the selected key operators and publish performance knowledge for AI-assisted optimization.

Repository dependencies: [FlagTree](https://github.com/flagos-ai/FlagTree) and [FLIR](https://github.com/flagos-ai/flir).

## Motivation

FLIR gives operator developers explicit control over memory views, data movement and computation on DSA and GPGPU hardware. This proposal extends the shared programming model and its backend lowering paths.

### Goals

| Goal | Scope | Acceptance |
|---|---|---|
| G1 — Ascend optimization | Tensor View dialect, L1 reuse, on-chip memory management and instruction vectorization | Selected key operators achieve >1.30x speedup over the matched current FlagGems baseline. |
| G2 — Ascend communication | Communication-library integration and tile-granularity compute/communication overlap | Correct fused execution, visible overlap and no synchronization error. Library/API and operator list: TBD. |
| G3 — Domestic GPGPU | At least one backend; layout inference/cost model; Tile Op → Warp Op → TTGIR | Functional coverage and >1.30x speedup on selected key operators. MetaX CommonIR integration is in review (#1471); acceptance SKU and baseline revision: TBD. |
| G4 — Optimization knowledge | Ascend/GPGPU optimization templates and skills; instruction-level benchmark knowledge for one domestic GPGPU | Reproducible measurements, documented applicability and examples usable by AI-for-FlagOS tooling. |

### Non-Goals

Replacing Triton for all operators, universal DSA/GPGPU binary portability and automatic generation of all model operators. General compiler-pass coverage is tracked in FEP-0167; the same operator may be used there with a separate record of the optimization being measured.

## Proposal

Keep the shared frontend and FLIR semantics in one design, with separate Ascend and GPGPU lowering pipelines. Describe buffer views, memory spaces and explicit data dependencies centrally; specialize layout, memory scheduling and instruction selection in the relevant backend. Publish small working operator examples alongside each new capability.

## Design Details

### Ascend

Tensor View represents non-contiguous access without losing shape/stride semantics. L1 reuse and buffer-lifetime analysis reduce repeated data movement and unnecessary on-chip allocation. Vectorization must preserve alignment and tail correctness. Communication integration establishes tile readiness and completion ordering before overlapping communication and computation.

Prioritize GLM5.3 critical operators and Ascend 950 performance enablement. The existing 910B/910C path remains regression coverage. Ascend 950 SDK/hardware readiness and model-specific operator list: TBD.

### GPGPU

Evaluate candidate layouts using swizzle requirements, layout conversions and memory coalescing. Lower tile operations into Warp operations for finer-grained optimization, then produce valid TTGIR for the backend. Check legality before applying a lower-cost layout; retain a valid fallback for unsupported patterns.

### Current implementation paths

Ascend Tensor View examples in PR #1483 cover 17 operators: embedding, index_select, index_copy, index_put, index_add, cp_gather_indexer, concat_and_cache_mla, reshape_and_cache_flash, apply_rotary_pos_emb, fused_add_rms_norm, rms_norm, skip_layernorm, combine_topk_swa_indices, compute_global_topk_indices_and_lens, pack_seq, unpack_seq and paged_kv_block_gather. They depend on bounds checks (#1480, FLIR #87) and statically shaped view stores (#1482). These are implementation examples, not the confirmed release acceptance list. GLM5.3 performance cases and reference revisions: TBD.

MetaX PR #1471 adds explicit `tle.gpu.set_layout` and opt-in `@triton.jit(autolayout=True)` with candidate benchmarking and winner caching. It depends on FLIR #79; statistical pruning uses SciPy >=1.12. Treat these as integration dependencies, not completed release acceptance.

### Knowledge delivery

Each instruction benchmark records the instruction or sequence, shape/dtype, dependency structure, hardware/clock configuration, command and measured latency/throughput. Optimization templates state their preconditions, transformation and validation steps. Coordinate the skill interface with AI-for-FlagOS; packaging schema: TBD.

## Packaging

**Supported vendors:** Huawei Ascend and at least one domestic GPGPU, TBD.

**Wheel:** dialects, passes and backend integration ship in FlagTree. Instruction benchmarks, templates and skills ship as versioned source assets with their dependency manifest.

Build a backend-specific FlagTree wheel from the selected release tag, using its documented SDK/LLVM/Python environment and `FLAGTREE_BACKEND` selector where required:

```bash
python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist
```

Record the source tag, Triton line, Python ABI, toolkit versions and wheel checksum. Release tag and dependency pins: TBD.

## Test Plan

### G1–G3: compiler and operator validation

Run the GPGPU semantic and bridge tests on the matching integration revision:

```bash
python3 -m pytest -q \
  test/CommonIR/test_gpu_semantics.py \
  test/CommonIR/test_gpu_wgmma_bridge.py
```

On the integration revision containing PR #1483 and its dependencies, run the standalone Ascend Tensor View cases:

```bash
for case in test/CommonIR/Ascend/success_case/tensor_view/*.py; do
  python3 "$case" || exit 1
done
```

Expected: all 17 examples pass their default, partial-tail and non-power-of-two-width cases. Preserve per-file logs. This functional coverage does not by itself establish the 30% performance target.

Expected: applicable semantic and lowering checks pass. Supplement these suites with hardware tests for the new Tensor View, reuse, vectorization, Warp and communication paths; commands: TBD.

| Capability | Required cases | Expected result |
|---|---|---|
| Tensor View | Contiguous, strided, masked/tail accesses | Same numerical result as the reference; valid addressing |
| L1 reuse | Multiple consumers and overlapping lifetimes | Correct results; measured L1 allocation/reload changes |
| Vectorization | Aligned and unaligned/tail inputs | Correct fallback where vectorization is illegal |
| Communication | Repeated multi-device tile transfer plus computation | Correct visibility/order and measured compute/communication overlap |
| Layout/Warp lowering | Conversion-heavy, reduction and matrix-compute cases | Legal IR and correct hardware results; cost-model choices compared with alternatives |

Maintain separate Ascend and GPGPU operator tables with model path, operator, shapes, precision, reference revision, command and speedup. Evaluate the >30% target independently for each agreed platform/case group. No cross-platform averaging.

### G4: knowledge validation

Re-run the published instruction benchmarks and optimization examples on their documented hardware. Retain generated code, numerical checks and measurements. Benchmark and skill commands: TBD.

Use the same hardware, inputs, precision and runtime dependencies for each comparison. Record correctness, latency, failed cases and skips. Kernel speedup = reference latency / candidate latency. Tolerances and performance aggregation: TBD.

## Related PRs

- Baseline: [FEP-0095](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0095-flagtree-common-ir.md), [FlagTree #974](https://github.com/flagos-ai/FlagTree/pull/974).
- [ ] [FlagTree #1483](https://github.com/flagos-ai/FlagTree/pull/1483) — Tensor View operator examples; dependencies [#1480](https://github.com/flagos-ai/FlagTree/pull/1480), [#1482](https://github.com/flagos-ai/FlagTree/pull/1482) and [FLIR #87](https://github.com/flagos-ai/flir/pull/87).
- [ ] [FlagTree #1471](https://github.com/flagos-ai/FlagTree/pull/1471) — MetaX layout/autotuning; dependency [FLIR #79](https://github.com/flagos-ai/flir/pull/79).
- [ ] L1/vectorization and communication integration — TBD.
- [ ] GPGPU layout, Warp lowering and backend validation — TBD.
- [ ] Benchmarks and optimization knowledge assets — TBD.

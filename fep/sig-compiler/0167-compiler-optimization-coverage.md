# FEP-0167: FlagTree Compiler Optimization and Twenty Operator-Device Combinations

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Expand [FlagTree](https://github.com/flagos-ai/FlagTree) compiler optimization coverage to a cumulative twenty distinct operator/device combinations. Extend FlagOSTune, layout optimization, warp-specialized scheduling, instruction scheduling, mixed precision, synchronization elimination and software pipelining, with an explicit operator list and reproducible evidence for every combination.

## Motivation

Compiler improvements need to transfer from isolated examples to the critical operators used by models. A coverage ledger links each optimization to the operator, chip, input cases and measured effect, and prevents multiple passes on the same operator/device from inflating coverage.

### Goals

- **G1:** Apply the optimization techniques to at least twenty unique operator/device combinations, distinguishing the existing baseline from the 2.3 increment.
- **G2:** Extend FlagOSTune to more key operators/backends and measure both search cost and selected-configuration quality.
- **G3:** Extend layout, scheduling, mixed-precision, synchronization and pipeline optimization with correctness and pass-specific evidence.

### Non-Goals

Twenty new operators on every chip, a common speedup guarantee for all passes, FLIR's new dialect architecture and distributed-autotune coordination.

## Proposal

Select optimization cases from model/operator profiles and partner work already planned for the release. Use shared compiler passes where possible and keep hardware-dependent legality/cost decisions in backend hooks. For each combination, capture the pre-change compiler/reference and candidate, then measure with identical operator inputs.

## Design Details

| Track | 2.3 work | Evidence |
|---|---|---|
| FlagOSTune | Broaden model-guided search and operator/platform coverage | Search wall time, candidates evaluated, selected latency and bounded-search reference |
| Layout | Reduce `convert_layout` cost and improve layout encoding | IR conversion count/placement and kernel latency |
| Warp specialization | Explicit barrier control for flexible producer/consumer scheduling | Correct synchronization and measured scheduling effect |
| Instruction scheduling | Reorder/fuse instructions to improve overlap | Generated code and latency/resource comparison |
| Mixed precision | Supported low-precision formats and cross-precision accumulation | Error analysis, overflow cases and register usage |
| Synchronization | Remove redundant barriers in supported warp-specialized/TMA-store paths | Ordering tests and barrier count |
| Pipelining | Fine-grained load latency assignment and load/MMA coordination | Pipeline schedule, correctness and performance |

### Coverage ledger

The release ledger records `operator`, `model/use`, `vendor/SKU`, `shape/dtype`, `optimization`, `baseline/candidate`, `command`, `correctness`, `performance` and `baseline-or-new`. Operator/device pairs are counted once even when several passes or shapes apply.

Candidate operators from previous work include `mul`, `mm`, `w8a8_block_fp8_matmul`, `flashmla_with_kvcache`, FlashAttention, `fused_marlin_moe`, `fused_inv_rope_fp8_quant` and GDN. Their inclusion in the twenty-pair release list is TBD; previous results are not automatically counted as new 2.3 work. Publish the full selected list before acceptance.

## Packaging

**Supported vendors:** selected domestic backends plus applicable NVIDIA regression coverage; final per-track matrix TBD.

**Wheel:** compiler passes and the FlagTune runtime ship in FlagTree. Predictor assets require a versioned model manifest and checksum; distribution mode TBD.

Build a backend-specific FlagTree wheel from the selected release tag, using its documented SDK/LLVM/Python environment and `FLAGTREE_BACKEND` selector where required:

```bash
python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist
```

Record the source tag, Triton line, Python ABI, toolkit versions and wheel checksum. Release tag and dependency pins: TBD.

## Test Plan

### G2: tuning regressions

```bash
python3 -m pytest -q python/test/flagtune
python3 -m pytest -q python/test/unit/runtime/test_autotuner.py
```

Expected: runtime, model/config identity, cache and error-handling tests pass. For each new operator/backend, compare selected latency with the same search space's reference and report tuning cost. Missing predictor assets follow the documented fallback or error policy.

### G1/G3: optimization validation

Use each selected operator's existing correctness/benchmark command, plus the affected pass's IR regression tests. Store the exact commands in the twenty-pair ledger; remaining entries TBD.

- Correctness: reference outputs, tail/masked shapes, non-contiguous layouts where supported and dtype-appropriate tolerances.
- Pass effect: retain before/after IR or generated code proving the intended layout, barrier, register or schedule change.
- Performance: same hardware and input cases, warm-up and repeated measurements; report regressions as well as gains.
- Coverage: at least twenty unique operator/device pairs have completed correctness and measurement records. List baseline and new pairs separately.

For mixed precision, freeze accuracy/error criteria before performance comparison. For scheduling/synchronization changes, include repeated execution and producer/consumer stress cases. Per-track performance thresholds and final operator commands: TBD.

Use identical hardware, model/operator inputs, dtype, compiler/runtime dependencies and device topology for baseline and candidate. Warm up, synchronize device work, retain at least three measured runs and report per-case results. Kernel speedup is baseline latency divided by candidate latency; decode speedup is candidate output tokens/s divided by baseline output tokens/s. Record failed and skipped cases separately. Dataset, tolerances and performance-case aggregation: TBD.

## Related PRs

- Baseline: [FEP-0097](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0097-flagtree-compiler-optimization.md).
- [ ] Twenty-pair operator/device ledger — TBD.
- [ ] FlagOSTune coverage and predictor assets — TBD.
- [ ] Pass implementations and regression/benchmark evidence — TBD.

## Implementation History

- 2026-11-05: Initial FlagOS 2.3 proposal.

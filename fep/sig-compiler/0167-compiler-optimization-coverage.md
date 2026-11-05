# FEP-0167: FlagTree Compiler Optimization and Twenty Operator-Device Combinations

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Expand [FlagTree](https://github.com/flagos-ai/FlagTree) compiler optimization coverage to a cumulative twenty distinct operator/device combinations. Extend FlagOSTune, layout optimization, warp-specialized scheduling, instruction scheduling, mixed precision, synchronization elimination and software pipelining, with an explicit operator list and reproducible evidence for every combination.

## Motivation

Compiler improvements need to transfer from isolated examples to the critical operators used by models. An operator/device test list identifies where each optimization is used and how its effect is measured.

### Goals

- **G1:** Apply the optimization techniques to at least twenty unique operator/device combinations, distinguishing the existing baseline from the 2.3 increment.
- **G2:** Extend FlagOSTune to more key operators/backends and measure both search cost and selected-configuration quality.
- **G3:** Extend layout, scheduling, mixed-precision, synchronization and pipeline optimization with correctness and pass-specific evidence.

### Non-Goals

Twenty new operators on every chip, a common speedup guarantee for all passes, FLIR's new dialect architecture and distributed-autotune coordination.

## Proposal

Select optimization cases from model/operator profiles and partner work already planned for the release. Use shared compiler passes where possible and keep hardware-dependent legality/cost decisions in backend hooks. For each combination, identify the affected compiler feature and operator implementation, then select the appropriate reference and measure identical inputs.

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

### Operator/device test list

The test list records `operator`, `model/use`, `vendor/SKU`, `shape/dtype`, `optimization`, `baseline/candidate`, `command`, `correctness`, `performance` and `baseline-or-new`. Operator/device pairs are counted once even when several passes or shapes apply.

The twenty-pair list is TBD. It must identify the operators affected by each compiler change, including whether the operator source changes. Existing coverage counts toward the cumulative target but must be distinguished from new 2.3 work.

## Packaging

**Supported vendors:** selected domestic backends plus applicable NVIDIA regression coverage; final per-track matrix TBD.

**Wheel:** compiler passes and the FlagTune runtime ship in FlagTree. Predictor-asset distribution and dependencies: TBD.

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

Expected: applicable tuning tests pass. For each selected operator/backend, record search time and the latency of the chosen configuration. Use the same search space and device configuration for tuning comparisons.

### G1/G3: optimization validation

Use each selected operator's existing correctness/benchmark command, plus the affected pass's IR regression tests. Store the exact commands in the twenty-pair test list; remaining entries TBD.

| Comparison | Method | Expected result |
|---|---|---|
| Compiler-only upgrade | Hold FlagGems/operator sources and other dependencies fixed; compare the 2.2 compiler with the 2.3 candidate on the same chip | Correctness preserved; measured latency changes, including regressions, attributed to the compiler upgrade |
| New or rewritten TLE operator | Compare with the vendor-native implementation or agreed reference at the same precision and inputs | Correctness and measured relative performance; per-case target TBD |
| Existing equivalent implementation | Add a before/after comparison when both versions support the same operation | Comparable outputs and timing; no new legacy implementation required |

Per-case reference and performance targets: TBD.

- Correctness: reference outputs, tail/masked shapes, non-contiguous layouts where supported and dtype-appropriate tolerances.
- Pass effect: retain before/after IR or generated code proving the intended layout, barrier, register or schedule change.
- Performance: same hardware and input cases, warm-up and repeated measurements; report regressions as well as gains.
- Coverage: at least twenty unique operator/device pairs have completed correctness and measurement records. List baseline and new pairs separately.

For mixed precision, compare equivalent precision and accuracy requirements; FP4 versus FP8 alone cannot establish compiler speedup. Freeze accuracy/error criteria before performance comparison. For scheduling/synchronization changes, include repeated execution and producer/consumer stress cases. Per-track performance thresholds and final operator commands: TBD.

Use the same hardware, inputs, precision and runtime dependencies for each comparison. Record correctness, latency, failed cases and skips. Kernel speedup = reference latency / candidate latency. Tolerances and performance aggregation: TBD.

## Related PRs

- Baseline: [FEP-0097](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0097-flagtree-compiler-optimization.md).
- [ ] Twenty-pair operator/device test list — TBD.
- [ ] FlagOSTune coverage and predictor assets — TBD.
- [ ] Pass implementations and regression/benchmark evidence — TBD.

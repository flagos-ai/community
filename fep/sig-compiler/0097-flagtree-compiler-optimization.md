# FEP-0097: FlagTree Compiler Optimization — FlagOSTune, Layout, Synchronization, and Instruction Scheduling

**Status:** `Provisional`

**Created:** 2026-08-01

**Owner:** [TODO: @github-username]

**SIG:** sig-compiler

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP covers the general compiler-optimization work planned
for FlagTree in the FlagOS 2.2 cycle, along four independent tracks:

1. **FlagOSTune** — add a machine-learning-prediction layer to Triton
   AutoTune so configuration search is both faster and more accurate.
2. **Layout optimization** — reduce `convert_layout` instruction cost and
   improve data-movement efficiency, raising operator performance.
3. **Synchronization optimization** — improve warp-specialization performance
   through explicit barrier control.
4. **Instruction scheduling** — instruction reordering and instruction fusion
   to raise instruction-level parallelism and hide memory-access latency.

These are backend-agnostic optimizations that live in FlagTree's shared
compiler layers and the Python autotuning runtime, benefiting every FlagTree
backend that reuses the trunk pipeline.

Repository: https://github.com/flagos-ai/FlagTree

## Release Boundary and Evidence

- **FlagOS 2.1 baseline:** FlagTree `0.6.0` on the corresponding Triton
  release lines.
- **FlagOS 2.2 release candidates reviewed:** FlagTree `0.7.0rc2.post1` on
  Triton 3.6, 3.5 and 3.3.
- **Development window:** 2026-06-01 through 2026-08-31. FlagTree#1055 was
  opened before feature freeze and merged on 2026-09-01 during stabilization.

FlagTune has direct implementation evidence in #850: an XGBoost ranking
model, top-k pruning, optional genetic search, strict model/bundle identity
validation, and a fallback path. PR #1055 extends backend support to MetaX,
MUSA, T-Head and Hygon. Layout-related evidence includes #763, #908 and #946.
Signal/barrier work is represented by #863 and #1048, but those PRs do not by
themselves prove the G3 warp-specialization performance target. No concrete
2.2 implementation PR and quantified acceptance result was identified for
the instruction-scheduling track. The FEP remains `Provisional` for the
multi-track claim even though FlagTune itself is implemented.

## Motivation

FlagTree provides a single trunk pipeline shared across many chip backends.
Improvements in that shared layer benefit all backends at once,
whereas today several optimizations are either absent or left to each vendor's
downstream fork:

- **Autotuning cost.** The stock Triton autotuner (`python/triton/runtime/autotuner.py`)
  benchmarks every candidate configuration by running it. For large
  configuration spaces this is slow, and it is repeated per shape. A predictive
  layer can prune the space before measurement, making search both faster and
  more reliable.
- **Layout conversions.** `convert_layout` operations inserted to reconcile
  incompatible tensor layouts are a recurring source of shared-memory traffic
  and register pressure; reducing them directly improves throughput.
- **Warp specialization.** Warp-specialized kernels (FEP-0027) depend on
  correct and efficient producer/consumer synchronization; coarse or implicit
  barriers cost performance.
- **Instruction scheduling.** Reordering independent instructions and fusing
  compatible ones increases parallelism and hides load latency; the default
  lowering does not fully exploit either.

### Goals

**(Required)**

- **G1 (FlagOSTune):** Extend the FlagTree autotuner with a machine-learning
  performance-predictor path that prunes candidate configurations before
  measurement, reducing autotuning wall-clock time while keeping the selected
  configuration within a bounded gap of the exhaustively-tuned best.
  <!-- TODO: define the accuracy bar (e.g. selected config within X% of best)
       and the search-time reduction target, and the predictor model type. -->
- **G2 (Layout optimization):** Reduce the number and cost of `convert_layout`
  instructions on representative operators, improving measured operator
  performance without changing results.
  <!-- TODO: name the representative operators and the perf-gain target. -->
- **G3 (Synchronization optimization):** Improve warp-specialization
  performance via explicit barrier control, measured on warp-specialized
  kernels. <!-- TODO: baseline kernels and target gain. -->
- **G4 (Instruction scheduling):** Add instruction reordering and instruction
  fusion passes that raise ILP and hide memory latency, improving measured
  performance on latency-bound operators.
  <!-- TODO: name target operators and gain. -->

### Non-Goals

- Backend-specific scheduling that belongs in a vendor's `third_party/<backend>`
  tree rather than the shared trunk.
- Replacing the stock Triton autotuner interface — FlagOSTune extends it via the
  existing `perf_model` hook, keeping the `@triton.autotune` API unchanged.
- Guaranteeing gains on every operator; performance remains shape- and
  hardware-dependent.

## Proposal

### Track 1: FlagTune / FlagOSTune (ML-predicted AutoTune)

Stock Triton's autotuner already exposes a `perf_model` hook
(`prune_configs_by["perf_model"]`) that predicts a config's running time and
prunes the search space before measurement, but ships no model for it. The
FlagTree autotuner (`python/triton/runtime/autotuner.py`, extended on the
`optimize_autotuner_20260119*` branch family) adds FlagTree-specific
enhancements on top:

- tuned-meta deduplication (`seen_tuned_metas`) so identical metas are not
  re-tuned;
- dependency-analysis-driven auto-pairing of tuning parameters
  (`dep_analyzer.analyze_kernel_dependencies`).

FlagTree#850 implements this path under the code/project name FlagTune. It
uses an XGBoost ranker to order configurations, selects top-k candidates for
measurement, can run an optional genetic search, validates the model identity
and bundle against the kernel, and falls back when a valid model is
unavailable. FlagTree#1055 adds MetaX, MUSA, T-Head and Hygon backend support.

<!-- TODO (design):
     1. Feature set (kernel signature, block sizes, shapes, dtype, target).
     2. Model type and where it is trained/stored/loaded; offline vs. online.
     3. Integration point in autotuner.py (prune vs. rank vs. early-stop).
     4. Fallback when no model is available (must reduce to today's behavior). -->

### Track 2: Layout Optimization

Layout handling lives in the shared trunk:
`lib/Dialect/TritonGPU/Transforms/RemoveLayoutConversions.cpp`,
`lib/Conversion/TritonGPUToLLVM/ConvertLayoutOpToLLVM.cpp`, and `Coalesce.cpp`.
PRs #763, #908 and #946 provide concrete 2.2 layout work: phased
`RemoveLayoutConversions`, the `tle.gpu.set_layout` primitive, and layout
anchors for TLE tile extraction/insertion. Together they reduce or control
layout-conversion placement; this FEP does not claim one quantified gain
across all operators. The broader track reduces the number and cost of `convert_layout` operations —
propagating compatible layouts further, coalescing conversions, and lowering
the remaining ones more efficiently — building on the explicit-layout
infrastructure from FEP-0065 (`tle.gpu.set_layout`,
`feature/gpu_set_layout&gpu_alloc`).

<!-- TODO (design): which conversions are targeted (dot-operand, reduction,
     epilogue), and the propagation/coalescing rules added. -->

### Track 3: Synchronization Optimization

Warp specialization lives under
`lib/Dialect/TritonGPU/Transforms/WarpSpecialization/` (e.g.
`OptimizePartitionWarps.cpp`) with barrier / membar analysis in
`lib/Analysis/Membar.cpp`. Signal/wait and multi-GPU barrier primitives landed
in #863 and #1048. They are relevant synchronization building blocks, but no
reviewed result isolates their effect on warp-specialized kernel performance.
The broader track adds explicit barrier control so
producer/consumer partitions synchronize with the minimum necessary barriers,
improving warp-specialized kernel performance.

<!-- TODO (design): the explicit-barrier mechanism (IR op or attribute), and
     how it interacts with the existing membar analysis and NVWS lowering. -->

### Track 4: Instruction Scheduling

Instruction scheduling and reordering exist in the pipeliner
(`lib/Dialect/TritonGPU/Transforms/Pipeliner/`, `Schedule.cpp`,
`AssignLatencies.cpp`) and as `ReorderInstructions.cpp`. This track proposes
instruction reordering and instruction fusion to raise ILP and hide
memory-access latency. Existing scheduler files establish a design location,
not evidence that a new 2.2 pass and acceptance benchmark landed.

<!-- TODO (design): reordering heuristic (latency model), what "instruction
     fusion" fuses, and whether this is a new pass or an extension of the
     existing pipeliner scheduler. -->

## Design Details

<!-- TODO: per-track pass design and IR-level details, to be filled before
     Status moves to `Implementable` (FEP Freeze 2026-08-14). -->

## Packaging

**(Required)** All four tracks ship inside the FlagTree wheel — three as C++
compiler passes in the shared trunk, FlagOSTune as Python in the autotuning
runtime plus its predictor asset.

**Supported vendors:** shared-trunk optimizations apply to all FlagTree
backends that reuse the trunk pipeline; measured acceptance is on NVIDIA
[TODO: confirm any additional vendors for per-track acceptance].

**Can this feature be packaged as a wheel (`.whl`)?** Yes — no standalone
artifact.

### Build

```bash
git clone https://github.com/flagos-ai/FlagTree.git
cd FlagTree
MAX_JOBS=32 python3 -m pip install . --no-build-isolation
```

<!-- TODO: whether a trained FlagOSTune model ships in the wheel or is fetched
     separately; any build flag to enable/disable each optimization. -->

## Test Plan

**(Required)** Each track is verified independently. Correctness (results
unchanged) is required for all four; performance is measured against the
pre-optimization baseline on the same hardware.

### G1: FlagOSTune

| Test | Command | Expected result |
|---|---|---|
| Autotuner unit | `pytest -s python/test/unit/runtime/test_autotuner.py` | Autotuning with the predictor produces correct results; falls back cleanly when no model present |
| Search cost / accuracy | <!-- TODO: benchmark harness, config space, shapes --> | Search time reduced by [TODO]; selected config within [TODO]% of exhaustive best |

### G2: Layout optimization

| Test | Command | Expected result |
|---|---|---|
| Layout pass regression | `pytest -s python/test/unit` (layout tests) + MLIR `lit` tests | `convert_layout` count reduced on target ops; numerics unchanged |
| Operator perf | <!-- TODO: op list + benchmark --> | ≥ [TODO]% improvement vs. baseline |

### G3: Synchronization optimization

| Test | Command | Expected result |
|---|---|---|
| Warp-specialized correctness | `pytest -s python/test/unit/hopper/test_persistent_warp_specialized_gemm.py` | Results unchanged |
| Warp-specialized perf | <!-- TODO: benchmark --> | ≥ [TODO]% improvement vs. baseline |

### G4: Instruction scheduling

| Test | Command | Expected result |
|---|---|---|
| Scheduling regression | MLIR `lit` tests (reorder-instructions) | Passes verify; numerics unchanged |
| Latency-bound op perf | <!-- TODO: op list + benchmark --> | ≥ [TODO]% improvement vs. baseline |

## Related PRs

- [x] flagos-ai/FlagTree#850 — FlagTune model-driven autotuning on Triton 3.6
- [x] flagos-ai/FlagTree#1055 — additional FlagTune accelerator backends
  (opened before freeze, merged during stabilization)
- [x] flagos-ai/FlagTree#763 — phased `RemoveLayoutConversions`
- [x] flagos-ai/FlagTree#908 — `tle.gpu.set_layout` primitive
- [x] flagos-ai/FlagTree#946 — TLE tile ops as layout anchors
- [x] flagos-ai/FlagTree#863 — signal and signal_wait operators
- [x] flagos-ai/FlagTree#1048 — multi-GPU distributed barrier support
- [ ] Instruction-scheduling implementation and acceptance PR not identified

## Implementation History

- 2026-08-01: FEP created as `Provisional` for the FlagOS 2.2 cycle. Autotuner
  predictor hook, layout passes, warp-specialization passes, and pipeliner
  scheduling infrastructure exist in the trunk / on feature branches; the
  ML-predictor realization (FlagOSTune) and the four measured performance
  targets are the remaining 2.2 work. Owner and quantified gains pending fill-in
  before FEP Freeze.
- 2026-09-17: Reconciled the FEP with the 2.2 RC lines and implementation PRs.
  Recorded FlagTune as implemented, tied layout/synchronization statements to
  concrete PRs, and retained unmeasured cross-track performance and instruction
  scheduling as provisional.

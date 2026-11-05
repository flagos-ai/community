# FEP-0164: TLE Distributed Primitives and Autotuned Communication-Compute Fusion

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Extend [FlagTree](https://github.com/flagos-ai/FlagTree) TLE distributed primitives through [FlagCX](https://github.com/flagos-ai/FlagCX) to at least four domestic backends. Support at least three communication-computation fused operators per backend, targeting more than 20% speedup, and add distributed-kernel autotuning.

## Motivation

Communication-computation fusion needs device-side data transfer, synchronization and scheduling to work together. A set of standalone primitives is insufficient without validated operator use cases, multi-rank correctness and coordinated tuning.

### Goals

- **G1:** Support at least four domestic backends with an agreed chip-priority list and FlagCX dependency matrix. Vendors/SKUs: TBD.
- **G2:** Validate at least three distinct fused operators per backend, selected from critical paths in GLM and other priority models. Target >1.20x speedup over the matched reference. Operator list, reference and case aggregation: TBD.
- **G3:** Add autotuning for TLE distributed kernels and validate the selected configurations across participating ranks.

### Non-Goals

Full-model FlagMega acceptance, TLE Raw native-code integration, arbitrary multi-node topologies and development of vendor communication transports.

## Proposal

Use `tle.remote`, `tle.shard_id`, signal/wait loads/stores and distributed barriers to express fused communication and computation. Lower communication through supported FlagCX device interfaces. Reuse the FlagTree tuning infrastructure, adding distributed candidate validation and coordination.

## Design Details

### Distributed execution

Preserve peer addressing, memory visibility and acquire/release ordering. Specify collective participation and buffer lifetime for each fused operator. Test repeated execution and multiple message sizes, including nonuniform tail shapes where supported.

### Autotuning

Extend the tuning path to distributed kernels. Validate correctness across ranks before benchmarking a candidate. Candidate coordination, search space and cache design: TBD.

### Acceptance matrix

| Backend | Priority | Model path | Three fused operators | FlagCX/runtime | Device count/topology |
|---|---|---|---|---|---|
| Domestic backend 1 | TBD | GLM or another priority model | TBD | TBD | TBD |
| Domestic backend 2 | TBD | TBD | TBD | TBD | TBD |
| Domestic backend 3 | TBD | TBD | TBD | TBD | TBD |
| Domestic backend 4 | TBD | TBD | TBD | TBD | TBD |

Select the final operators from priority-model profiles with the FlagCX maintainers. Count distinct fused operators on each backend; additional shapes do not increase the operator count. Backend names and operators remain TBD.

## Packaging

**Supported vendors:** four domestic backends, TBD; NVIDIA is reference/regression coverage.

**Wheel:** TLE changes ship in FlagTree. FlagCX and vendor communication runtimes are separately pinned dependencies.

Build a backend-specific FlagTree wheel from the selected release tag, using its documented SDK/LLVM/Python environment and `FLAGTREE_BACKEND` selector where required:

```bash
python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist
```

Record the source tag, Triton line, Python ABI, toolkit versions and wheel checksum. Release tag and dependency pins: TBD.

## Test Plan

### G1: primitive regressions

From the matching FlagTree checkout, run the existing primitive and integration suites in their documented multi-device environment:

```bash
python3 -m pytest -q python/test/tle/unit/test_tle_distributed.py
python3 -m pytest -q python/test/tle/integration/test_tle_distributed.py
```

Run applicable backend-specific suites as well. On Iluvatar:

```bash
python3 -m pytest -q \
  third_party/iluvatar/python/test/unit/tle/test_tle_distributed.py \
  third_party/iluvatar/python/test/unit/tle/test_tle_distributed_barrier.py \
  third_party/iluvatar/python/test/unit/tle/test_tle_distributed_barrier_multi_gpu.py
```

Expected: all required ranks participate; results and visibility checks pass; no hang or leaked process occurs. Record test collection, device count and skips. A backend is accepted only after its required tests run on hardware.

### G2: fused operators

For every matrix row, compare outputs with the unfused reference, then benchmark the identical input cases on the same devices. Retain at least twelve backend/operator results and the per-shape measurements supporting the >20% target. Exact benchmark commands and baseline revisions: TBD.

### G3: distributed tuning

Run correctness checks for the selected configuration on all ranks, then compare its kernel latency with the untuned configuration on the same devices and inputs. Record tuning time. Distributed-autotune commands: TBD.

Use the same hardware, inputs, precision and runtime dependencies for each comparison. Record correctness, latency, failed cases and skips. Kernel speedup = reference latency / candidate latency. Tolerances and performance aggregation: TBD.

## Related PRs

- Prior scope: [FEP-0096](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0096-flagtree-tle-megakernel-and-distributed.md).
- [ ] Four-backend matrix and fused-operator implementations — TBD.
- [ ] Distributed autotuning — TBD.

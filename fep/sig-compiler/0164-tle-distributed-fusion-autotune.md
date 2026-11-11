# FEP-0164: TLE Distributed Primitives and Autotuned Communication-Compute Fusion

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** @Galaxy1458

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Extend [FlagTree](https://github.com/flagos-ai/FlagTree) TLE distributed primitives through [FlagCX](https://github.com/flagos-ai/FlagCX) to Iluvatar, Hygon, Kunlunxin and DAMO ACADEMY. Deliver two fused operators per backend from priority models such as GLM, targeting >20% speedup over equivalent PyTorch implementations. Autotuning targets eager and graph execution; graph integration and multi-rank validation are pending.

## Goals

| Goal | Deliverable |
|---|---|
| G1 — Backends | Device communication and synchronization through TLE/FlagCX on Iluvatar, Hygon, Kunlunxin and DAMO ACADEMY. |
| G2 — Fused operators | Deliver two communication-compute fused operators per backend from priority-model workloads by December 7, targeting >20% performance improvement over PyTorch. |
| G3 — Autotuning | Coordinate candidate evaluation, selection and cache reuse across ranks in eager and graph workflows. Graph integration and multi-rank validation are pending. |

| Backend | Integration and test requirements |
|---|---|
| Iluvatar | FlagCX device runtime, peer-memory access and multi-device barrier tests. |
| Hygon | Integrate [FlagTree #1441](https://github.com/flagos-ai/FlagTree/pull/1441): TLE/FlagCX primitives, HCU device-library linking and a two-device test workflow. |
| Kunlunxin | Integrate [FlagTree #1436](https://github.com/flagos-ai/FlagTree/pull/1436) with matching FlagCX host libraries, XPU device bitcode and XSHMEM; complete the remote-write and synchronization paths. |
| DAMO ACADEMY (`third_party/thrive`) | Complete the TLE/FlagCX device path. Awaiting test hardware. |

## Packaging

Ship the TLE changes and `flagtree.tune.autotune` in the FlagTree wheel. Use the selected backend's documented SDK environment and `FLAGTREE_BACKEND` setting. Leave `FLAGTREE_BACKEND` unset for NVIDIA/AMD builds.

```bash
python3 -m pip wheel . \
  --no-deps --no-build-isolation --wheel-dir dist
```

Publish the matching source, distributed-operator tutorials and autotuning documentation. Pin the FlagCX host/device libraries and vendor runtime dependencies for each backend.

## Test Plan

Use identical development and QA images and source revisions per backend. Record device model, card count, interconnect, SDK/driver, Python/PyTorch/FlagTree, FlagCX and vendor communication-library versions. Each case records its model path, shape, input/output and accumulation dtypes, reference revision, accuracy tolerance and execution mode.

Run commands from the matching FlagTree checkout. Before device tests, verify that generated FlagCX calls link against the selected bitcode and vendor device libraries.

### G1: distributed primitives

Front-end mesh/sharding regression; no device kernels or cross-rank communication:

```bash
python3 -m pytest -q python/test/tle/unit/test_tle_distributed.py
```

On NVIDIA and Iluvatar, configure FlagCX and select two visible devices for the peer-memory test:

```bash
torchrun --standalone --nproc-per-node=2 \
  python/test/tle/unit/test_tle_distributed_d2d.py
```

Iluvatar device-barrier test:

```bash
torchrun --standalone --nproc-per-node=2 \
  third_party/iluvatar/python/test/unit/tle/test_tle_distributed_barrier_multi_gpu.py
```

For Hygon, integrate #1441 and run the `TLE-FlagCX Distributed Unit Tests (2 GPUs)` step in `.github/workflows/hcu3.6-dist-test.yml`. It requires HIP PyTorch, two visible HCU devices and a matching FlagCX host/device build with `USE_FLAGCX=ON`.

**Expected:** Each rank reads the expected peer data. Iluvatar barrier, arrive/wait and ordering checks pass across repeated executions. Retain per-rank results and exit codes.

For Kunlunxin, complete #1436's device-init and signal/wait linkage, configure XPU SDK/XCCL/FlagCX dependencies, and run the two-device signal tests:

```bash
# Requires FlagTree PR #1436 (not yet merged).
NPROC_PER_NODE=2 NNODES=1 NODE_RANK=0 \
  bash third_party/xpu/test/test_tle_signal.sh
NPROC_PER_NODE=2 NNODES=1 NODE_RANK=0 \
  bash third_party/xpu/test/test_tle_signal_wait.sh
```

**Expected:** Signal/wait smoke tests complete on both devices. Hygon and Kunlunxin must also pass nonzero waits for signals from another rank and repeated barrier-ordering checks. For Kunlunxin P800, verify remote-write visibility through receiver-side reads. Complete remote-access and synchronization tests for DAMO ACADEMY before acceptance.

### G2: fused-operator correctness and performance

For 2.3, use PyTorch as the performance baseline; FEP-0096 used Triton-distributed.

Single-node eager workloads from [#1599](https://github.com/flagos-ai/FlagTree/pull/1599):

| Fused operator | Required PyTorch performance reference |
|---|---|
| Reduce-scatter + residual add + RMSNorm + all-gather | `torch.distributed.all_reduce` + residual add + RMSNorm, including the same local residual update. |
| Q/KV RMSNorm + all-gather | `torch.distributed.all_gather_into_tensor` + Q/KV RMSNorm. |

After integrating #1599 on a backend with the TLE/FlagCX path, set `FEP_NPROC` to the card count (at least two) and `FEP_RESULTS` to an existing output directory:

```bash
# Requires FlagTree PR #1599 (not yet merged).
PEER=tle NPROC_PER_NODE="$FEP_NPROC" DTYPE=bf16 \
  OUT_JSON="$FEP_RESULTS/fused-operators.json" \
  bash python/tutorials/tle/10-intra-node-rs-norm-ag.sh
```

**Expected:** The run reports `peer=tle`; output and residual checks pass on all ranks, including uneven row counts and repeated calls with changing shapes. Signal waits complete without timeouts.

Validate both timed implementations against the same reference, including residual updates. Reset mutable inputs and residuals between iterations; account for reset costs consistently. Match hardware, shapes, input/output dtypes and execution modes. Measure complete-operation latency, including communication, using the slowest rank. Retain correctness results and per-shape timing samples.

Report speedup as `PyTorch latency / TLE latency` and improvement as `(speedup - 1) × 100%`. Set each backend's operator list, workloads and aggregation before testing. Provide commands and results for each backend/operator pair. Shape variants do not increase the operator count.

### G3: distributed autotuning

Run [#1446](https://github.com/flagos-ai/FlagTree/pull/1446)'s local autotuner regressions, which use mocked device interfaces by default:

```bash
# Requires FlagTree PR #1446 (not yet merged).
python3 -m unittest discover -s python/test/unit -p test_function_autotune.py
```

**Expected:** Candidate selection, pruning, cache reuse and argument checks pass.

Add executable multi-rank eager/graph cases using G2 operators and `autotune_pg` for all participating ranks. Restore inputs and residuals and verify each candidate's correctness before timing:

| Case | Expected result |
|---|---|
| Eager, empty tuning cache | All ranks evaluate the common candidates in the same order, select the same configuration and produce correct outputs. |
| Graph workflow, empty tuning cache | The graph workflow triggers tuning before capture. The selected configuration replays correctly with new inputs; communication signals and buffer state remain correct across repeated replays. |
| Cached execution | All ranks reuse the same selected configuration; repeated calls and a restarted run remain correct. |
| Inconsistent rank settings or no common candidate | All ranks report the error without hanging. |

Compare tuned execution with `autotune=False` on identical workloads, using the maximum latency across ranks. Record the selected configuration, tuning time, per-rank latency and cache state.

## Related PRs

- Prior FEP: [FEP-0096](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0096-flagtree-tle-megakernel-and-distributed.md).
- [x] [FlagCX #667](https://github.com/flagos-ai/FlagCX/pull/667) — Hygon device bitcode and unified Device IR packaging.
- [x] [FlagCX #678](https://github.com/flagos-ai/FlagCX/pull/678) — Six Kunlunxin XPU device-IR entry points for rank queries, peer pointers and barriers.
- [ ] [FlagTree #1436](https://github.com/flagos-ai/FlagTree/pull/1436) — Kunlunxin TLE distributed backend.
- [ ] [FlagTree #1441](https://github.com/flagos-ai/FlagTree/pull/1441) — Hygon TLE/FlagCX backend and two-device test workflow.
- [ ] [FlagTree #1446](https://github.com/flagos-ai/FlagTree/pull/1446) — Function-level local and distributed autotuning.
- [ ] [FlagTree #1599](https://github.com/flagos-ai/FlagTree/pull/1599) — Fused RS/RMSNorm/AG and Q/KV RMSNorm/AG tutorials.

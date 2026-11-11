# FEP-0164: TLE Distributed Primitives and Autotuned Communication-Compute Fusion

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** @Galaxy1458

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Extend [FlagTree](https://github.com/flagos-ai/FlagTree) TLE distributed primitives through [FlagCX](https://github.com/flagos-ai/FlagCX) to Iluvatar, Hygon, Kunlunxin and DAMO ACADEMY. Deliver communication-compute fused operators from priority models such as GLM, targeting more than 20% speedup over equivalent PyTorch implementations. Distributed autotuning targets eager and graph execution; graph integration and multi-rank validation remain to be implemented.

## Goals

| Goal | Deliverable |
|---|---|
| G1 — Backends | Device communication and synchronization through TLE/FlagCX on Iluvatar, Hygon, Kunlunxin and DAMO ACADEMY. |
| G2 — Fused operators | Communication-compute fused operators from priority-model workloads on each backend, with a >20% performance improvement target over PyTorch. |
| G3 — Autotuning | Coordinate candidate evaluation, configuration selection and cache reuse across ranks for eager and graph workflows. Graph integration and multi-rank validation remain to be implemented. |

**Operator count:** The Roadmap specifies at least three per backend; the November 9 comment specifies two per backend by December 7. The owner must reconcile the acceptance count.

| Backend | Integration and test requirements |
|---|---|
| Iluvatar | FlagCX device runtime, peer-memory access and multi-device barrier tests. |
| Hygon | Integrate [FlagTree #1441](https://github.com/flagos-ai/FlagTree/pull/1441): TLE/FlagCX primitives, HCU device-library linking and a two-device test workflow. Complete fused-operator validation. |
| Kunlunxin | Integrate [FlagTree #1436](https://github.com/flagos-ai/FlagTree/pull/1436) with matching FlagCX host libraries, XPU device bitcode and XSHMEM; complete the remote-write and synchronization paths. |
| DAMO ACADEMY (`third_party/thrive`) | Complete the TLE/FlagCX device path. Hardware validation is blocked: no test machine is available. |

## Packaging

Ship the TLE changes and `flagtree.tune.autotune` in the FlagTree wheel. Use the selected backend's documented SDK environment and `FLAGTREE_BACKEND` setting. Leave `FLAGTREE_BACKEND` unset for NVIDIA/AMD builds.

```bash
python3 -m pip wheel . \
  --no-deps --no-build-isolation --wheel-dir dist
```

Publish the matching source, distributed-operator tutorials and autotuning documentation. Pin the FlagCX host/device libraries and vendor runtime dependencies for each backend.

## Test Plan

Use the same candidate images and source revisions for development and QA on each backend. Record device model, card count, interconnect, SDK/driver, Python/PyTorch/FlagTree, FlagCX and vendor communication-library versions. Each operator case records its model path, shape, input/output and accumulation dtypes, reference revision, accuracy tolerance and execution mode.

Run the following commands from the matching FlagTree checkout. Before runtime tests, check that generated FlagCX device calls resolve against the selected bitcode and vendor device libraries. Confirm each backend's operator list and benchmark cases before acceptance, and retain results for every backend/operator pair.

### G1: distributed primitives

Run the common mesh and sharding front-end regressions. These tests do not execute device kernels or cross-rank communication:

```bash
python3 -m pytest -q python/test/tle/unit/test_tle_distributed.py
```

On NVIDIA reference and Iluvatar environments, configure the backend's FlagCX runtime and select two visible devices. Run the peer-memory test:

```bash
torchrun --standalone --nproc-per-node=2 \
  python/test/tle/unit/test_tle_distributed_d2d.py
```

On Iluvatar, also run the device-barrier test:

```bash
torchrun --standalone --nproc-per-node=2 \
  third_party/iluvatar/python/test/unit/tle/test_tle_distributed_barrier_multi_gpu.py
```

For Hygon, integrate #1441 and run the `TLE-FlagCX Distributed Unit Tests (2 GPUs)` step in `.github/workflows/hcu3.6-dist-test.yml`. It requires HIP PyTorch, two visible HCU devices and a matching FlagCX host/device build with `USE_FLAGCX=ON`.

**Expected:** Each rank reads the expected peer data. Iluvatar barrier, arrive/wait and ordering checks pass across repeated executions. Retain per-rank results and exit codes.

For Kunlunxin, complete the device-init and signal/wait linkage required by #1436, and configure its XPU SDK, XCCL and FlagCX device libraries. Then run its two-device signal tests:

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

The single-node eager tutorial in [#1599](https://github.com/flagos-ai/FlagTree/pull/1599) contains two operator families:

| Fused operator | Required PyTorch performance reference |
|---|---|
| Reduce-scatter + residual add + RMSNorm + all-gather | `torch.distributed.all_reduce` + residual add + RMSNorm, including the same local residual update. |
| Q/KV RMSNorm + all-gather | `torch.distributed.all_gather_into_tensor` + Q/KV RMSNorm. |

After integrating #1599, run it on backends with the required TLE/FlagCX path. Set `FEP_NPROC` to the selected card count, at least two, and `FEP_RESULTS` to an existing output directory:

```bash
# Requires FlagTree PR #1599 (not yet merged).
PEER=tle NPROC_PER_NODE="$FEP_NPROC" DTYPE=bf16 \
  OUT_JSON="$FEP_RESULTS/fused-operators.json" \
  bash python/tutorials/tle/10-intra-node-rs-norm-ag.sh
```

**Expected:** The run reports `peer=tle`; output and residual checks pass on all ranks, including uneven row counts and repeated calls with changing shapes. Signal waits complete without timeouts.

For release benchmarks, validate both timed implementations against the same correctness reference, including updated residuals. Reset mutable inputs and residuals between iterations and account for reset costs consistently. Compare equivalent outputs on the same devices, with matching shapes, input/output dtypes and execution modes. Measure the complete fused operation and its PyTorch reference, including communication, and use the slowest rank. Retain the accuracy checks and per-shape latency samples.

Report speedup as `PyTorch latency / TLE latency` and improvement as `(speedup - 1) × 100%`, against the >20% target. Define the acceptance workloads and aggregation before testing. Complete the release operator list and backend-specific commands to cover G2; shape variants of one operator do not increase the operator count.

### G3: distributed autotuning

Integrate [#1446](https://github.com/flagos-ai/FlagTree/pull/1446) for rank coordination and caching. That PR does not provide distributed graph integration or multi-rank tests. Run its local autotuner regressions:

```bash
# Requires FlagTree PR #1446 (not yet merged).
python3 -m unittest discover -s python/test/unit -p test_function_autotune.py
```

**Expected:** Candidate selection, pruning, cache reuse and argument checks pass. This suite uses mocked device interfaces by default.

Add executable multi-rank cases using the G2 operators and `autotune_pg` for all participating ranks. Verify each candidate's correctness with restored inputs and residuals before comparing timings:

| Case | Expected result |
|---|---|
| Eager, empty tuning cache | All ranks evaluate the common candidates in the same order, select the same configuration and produce correct outputs. |
| Graph workflow, empty tuning cache | The graph workflow triggers tuning before capture. The selected configuration replays correctly with new inputs; communication signals and buffer state remain correct across repeated replays. |
| Cached execution | All ranks reuse the same selected configuration; repeated calls and a restarted run remain correct. |
| Inconsistent rank settings or no common candidate | All ranks report the error without hanging. |

Compare tuned execution with `autotune=False` on identical workloads. Record the selected configuration, tuning time, per-rank latency and cache state. The distributed comparison uses the maximum latency across ranks. Complete the multi-rank eager/graph test commands before acceptance.

## Related PRs

- Prior FEP: [FEP-0096](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0096-flagtree-tle-megakernel-and-distributed.md).
- [x] [FlagCX #667](https://github.com/flagos-ai/FlagCX/pull/667) — Hygon device bitcode and unified Device IR packaging.
- [x] [FlagCX #678](https://github.com/flagos-ai/FlagCX/pull/678) — Six Kunlunxin XPU device-IR entry points for rank queries, peer pointers and barriers.
- [ ] [FlagTree #1436](https://github.com/flagos-ai/FlagTree/pull/1436) — Kunlunxin TLE distributed backend.
- [ ] [FlagTree #1441](https://github.com/flagos-ai/FlagTree/pull/1441) — Hygon TLE/FlagCX backend and two-device test workflow.
- [ ] [FlagTree #1446](https://github.com/flagos-ai/FlagTree/pull/1446) — Function-level local and distributed autotuning.
- [ ] [FlagTree #1599](https://github.com/flagos-ai/FlagTree/pull/1599) — Fused RS/RMSNorm/AG and Q/KV RMSNorm/AG tutorials.

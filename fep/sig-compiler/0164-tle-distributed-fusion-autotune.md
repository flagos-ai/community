# FEP-0164: TLE Distributed Primitives and Autotuned Communication-Compute Fusion

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** @Galaxy1458

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Extend [FlagTree](https://github.com/flagos-ai/FlagTree) TLE distributed primitives through [FlagCX](https://github.com/flagos-ai/FlagCX) to Iluvatar, Hygon, Kunlunxin and T-Head. Deliver communication-compute fused operators from priority models such as GLM, targeting more than 20% speedup over equivalent PyTorch implementations. Add distributed autotuning for eager and graph execution.

## Goals

| Goal | Deliverable |
|---|---|
| G1 — Backends | Device communication and synchronization through TLE/FlagCX on Iluvatar, Hygon, Kunlunxin and T-Head. |
| G2 — Fused operators | At least three fused operators per backend, selected from priority-model workloads, with a >20% performance improvement target over PyTorch. |
| G3 — Autotuning | Tune distributed kernels in eager and graph workflows; coordinate candidate evaluation, configuration selection and cache reuse across participating ranks. |

**December 7 milestone:** deliver at least two fused operators on each of the four backends.

| Backend | Integration and test requirements |
|---|---|
| Iluvatar | FlagCX device runtime, peer-memory access and multi-device barrier tests. |
| Hygon | Complete the TLE/FlagCX device path and multi-device operator tests. |
| Kunlunxin | Integrate [FlagTree #1436](https://github.com/flagos-ai/FlagTree/pull/1436) with compatible FlagCX host libraries, XPU device bitcode and vendor communication libraries. |
| T-Head | Complete the TLE/FlagCX device path. Test hardware access is pending. |

## Packaging

Ship the TLE changes and `flagtree.tune.autotune` in the FlagTree wheel. Build in the selected backend's SDK environment, with `FEP_BACKEND` set to its FlagTree backend identifier:

```bash
FLAGTREE_BACKEND="$FEP_BACKEND" python3 -m pip wheel . \
  --no-deps --no-build-isolation --wheel-dir dist
```

Publish the matching source, distributed-operator tutorials and autotuning documentation. Pin the FlagCX host/device libraries and vendor runtime dependencies for each backend.

## Test Plan

Use the same candidate images and source revisions for development and QA on each backend. Record device model, card count, interconnect, SDK/driver, Python/PyTorch/FlagTree, FlagCX and vendor communication-library versions. Each operator case records its model path, shape, input/output and accumulation dtypes, reference revision, accuracy tolerance and execution mode.

Run the following commands from the matching FlagTree checkout. Confirm each backend's operator list and benchmark cases before acceptance, and retain results for every backend/operator pair.

### G1: distributed primitives

Run the common mesh and sharding regressions:

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

**Expected:** Each rank reads the expected peer data. Iluvatar barrier, arrive/wait and ordering checks pass across repeated executions. Retain per-rank results and exit codes.

For Kunlunxin, integrate #1436 and configure its XPU SDK, XCCL and FlagCX device-library dependencies. Run its two-device signal tests:

```bash
NPROC_PER_NODE=2 NNODES=1 NODE_RANK=0 \
  bash third_party/xpu/test/test_tle_signal.sh
NPROC_PER_NODE=2 NNODES=1 NODE_RANK=0 \
  bash third_party/xpu/test/test_tle_signal_wait.sh
```

**Expected:** Signal and wait tests complete on both devices. Complete on-device remote-access and barrier-ordering tests for Kunlunxin, Hygon and T-Head before acceptance.

### G2: fused-operator correctness and performance

The initial workload in [#1599](https://github.com/flagos-ai/FlagTree/pull/1599) contains two operator families:

| Fused operator | PyTorch performance reference |
|---|---|
| Reduce-scatter + residual add + RMSNorm + all-gather | `torch.distributed.all_reduce` + residual add + RMSNorm. |
| Q/KV RMSNorm + all-gather | `torch.distributed.all_gather_into_tensor` + Q/KV RMSNorm. |

After integrating #1599, run it on backends with the required TLE/FlagCX path. Set `FEP_NPROC` to the selected card count, at least two, and `FEP_RESULTS` to an existing output directory:

```bash
PEER=tle NPROC_PER_NODE="$FEP_NPROC" DTYPE=bf16 \
  OUT_JSON="$FEP_RESULTS/fused-operators.json" \
  bash python/tutorials/tle/10-intra-node-rs-norm-ag.sh
```

**Expected:** The run reports `peer=tle`; output and residual checks pass on all ranks, including uneven row counts and repeated calls with changing shapes. Signal waits complete without timeouts.

For release benchmarks, reset mutable inputs and residuals between iterations. Compare equivalent outputs on the same devices, with matching shapes, input/output dtypes and execution modes. Measure the complete fused operation and its PyTorch reference, including communication, and use the slowest rank. Retain the accuracy checks and per-shape latency samples.

Report speedup as `PyTorch latency / TLE latency` and improvement as `(speedup - 1) × 100%`, against the >20% target. Define the acceptance workloads and aggregation before testing. Complete the release operator list and backend-specific commands to cover G2; shape variants of one operator do not increase the operator count.

### G3: distributed autotuning

Integrate [#1446](https://github.com/flagos-ai/FlagTree/pull/1446). Run its local autotuner regressions:

```bash
python3 -m unittest discover -s python/test/unit -p test_function_autotune.py
```

**Expected:** Candidate selection, pruning, cache reuse and argument checks pass. This suite uses mocked device interfaces by default.

Add executable multi-rank cases using the G2 operators and `autotune_pg` for all participating ranks:

| Case | Expected result |
|---|---|
| Eager, empty tuning cache | All ranks evaluate the common candidates in the same order, select the same configuration and produce correct outputs. |
| Graph workflow, empty tuning cache | Tuning is triggered through the graph workflow; the selected configuration captures and replays correctly across all ranks. |
| Cached execution | All ranks reuse the same selected configuration; repeated calls and a restarted run remain correct. |

Compare tuned execution with `autotune=False` on identical workloads. Record the selected configuration, tuning time, per-rank latency and cache state. The distributed comparison uses the maximum latency across ranks. Complete the multi-rank eager/graph test commands before acceptance.

## Related PRs

- Prior FEP: [FEP-0096](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0096-flagtree-tle-megakernel-and-distributed.md).
- [x] [FlagCX #667](https://github.com/flagos-ai/FlagCX/pull/667) — Hygon device bitcode and unified Device IR packaging.
- [x] [FlagCX #678](https://github.com/flagos-ai/FlagCX/pull/678) — Kunlunxin XPU device-IR entry points for FlagTree.
- [ ] [FlagTree #1436](https://github.com/flagos-ai/FlagTree/pull/1436) — Kunlunxin TLE distributed backend.
- [ ] [FlagTree #1446](https://github.com/flagos-ai/FlagTree/pull/1446) — Function-level local and distributed autotuning.
- [ ] [FlagTree #1599](https://github.com/flagos-ai/FlagTree/pull/1599) — Fused RS/RMSNorm/AG and Q/KV RMSNorm/AG tutorials.

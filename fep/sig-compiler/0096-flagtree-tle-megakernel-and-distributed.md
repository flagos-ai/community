# FEP-0096: FlagTree TLE New Features — MegaKernel Compiler and Distributed Primitives

**Status:** `Provisional`

**Created:** 2026-08-01

**Owner:** [TODO: @github-username]

**SIG:** sig-compiler

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP covers the two Triton Language Extensions (TLE) features
planned for FlagTree in the FlagOS 2.2 cycle:

1. **MegaKernel compiler** — a new kernel-authoring paradigm that compiles a
   model (e.g. from a HuggingFace definition) into Triton code executed by a
   single cooperative "mega" kernel, targeting low-latency single-batch decode.
2. **Distributed primitives and communication-computation fusion** — a TLE
   distributed API (`tle.remote`, `tle.distributed_barrier`, `tle.shard_id`,
   `tle.load`/`tle.store` with signal/wait semantics) lowered onto FlagCX so
   that inter-device collectives can be fused with computation inside a Triton
   kernel, on par with Triton-distributed.

Both build on the existing TLE stack in FlagTree (`python/triton/experimental/tle/`
and the `third_party/tle` MLIR dialect).

Repository: https://github.com/flagos-ai/FlagTree

## Motivation

TLE is FlagTree's vehicle for expressing performance-oriented kernel structure
that block-level Triton cannot: warp specialization (FEP-0027 `tle.pipe`),
explicit shared-memory aliasing and layout control (FEP-0065). FlagOS 2.2
extends TLE along two new axes that matter for LLM serving:

- **Latency.** For single-batch decode, per-layer kernel launches and the
  round-trips they imply dominate latency. Compiling an entire decode step into
  one persistent, cooperatively-scheduled kernel removes launch overhead and
  keeps weights and activations resident.
- **Scale.** Multi-device LLM inference needs communication fused with
  computation to hide transfer latency behind compute. Giving TLE first-class
  distributed primitives, lowered onto FlagCX, lets FlagTree express
  compute-communication fused operators (AllGather+GEMM, GEMM+ReduceScatter) at
  the compiler level rather than stitching collectives around kernels.

### Goals

**(Required)**

- **G1 (MegaKernel compiler):** Provide a compiler path that turns a model
  definition into Triton code run by a single cooperative mega-kernel, with a
  pull-based scheduler prototype and at least two demonstration operators.
  <!-- TODO: name the two demonstration operators and their acceptance shape. -->
- **G2 (MegaKernel performance):** On a single H800, Qwen3-32B `bs=1` decode
  throughput exceeds the vLLM baseline by ≥20% (and exceeds Triton-distributed).
  <!-- TODO: pin vLLM baseline version/commit, sequence length, tensor-parallel
       degree, quantization, and the throughput metric (tokens/s) used. -->
- **G3 (Distributed primitives):** Provide the TLE distributed API —
  `tle.remote`, `tle.distributed_barrier`, `tle.shard_id`, and
  `tle.load`/`tle.store` with signal/wait memory-order semantics — with a
  device mesh / sharding model, lowered to device-side communication.
- **G4 (Multi-chip via FlagCX):** Lower the distributed primitives onto FlagCX
  so at least two domestic chips (in addition to NVIDIA) can run the
  distributed operators.
  <!-- TODO: name the two domestic chips committed for 2.2. -->
- **G5 (Comm-compute fusion validation):** Validate on at least two
  communication-computation fused operators (e.g. AllGather / ReduceScatter,
  AllGather+GEMM / GEMM+ReduceScatter) with average cross-device performance on
  par with Triton-distributed.
  <!-- TODO: define "on par" — Triton-distributed baseline version, tolerance,
       message-size range, GPU count and topology, per operator. -->

### Non-Goals

- Replacing Triton's automatic software pipeliner or `tle.pipe` for
  intra-CTA producer/consumer flows (FEP-0027).
- Guaranteeing the ≥20% gain outside the named model/hardware configuration in
  G2; performance remains workload- and hardware-dependent.
- Full model coverage for the MegaKernel path — the deliverable is the compiler
  paradigm plus demonstration operators, not a complete model zoo.
- Inter-node (multi-host) distributed operators beyond the validated intra-node
  scope in this cycle. <!-- TODO: confirm whether inter-node is in or out. -->

## Proposal

### Feature 1: MegaKernel Compiler

A pull-based cooperative scheduler is prototyped on the `feature/tle_mega`
branch: kernels live under `python/tutorials/tle/mega/` (e.g.
`kernels/linear_fused_rmsnorm.py` providing
`linear_fused_add_rms_norm_decode_mega`), driven by a mega scheduler and
covered by `python/test/tle/integration/test_tle_mega_scheduler.py`. The
branch carries the compiler-side changes the paradigm needs — extensions to
`TritonToTritonGPUPass`, WGMMA pipelining (`WGMMAPipeline.cpp`,
`TleWGMMAAnalysis`), shared-memory allocation and membar analysis
(`lib/Analysis/Allocation.cpp`, `lib/Analysis/Membar.cpp`), and layout handling
(`RemoveLayoutConversions.cpp`).

The model-level entry point (HuggingFace definition → Triton mega-kernel) is the
net-new work for 2.2: a front-end that composes the per-operation mega kernels
into a full decode step and schedules them cooperatively on one launch.

<!-- TODO (design):
     1. Front-end scope — which model families / layer types the compiler
        accepts, and how a HuggingFace config maps to mega-kernel fragments.
     2. Scheduler — pull-based cooperative scheduling model, occupancy /
        persistent-CTA strategy, how weights and KV stay resident.
     3. Relationship to FlagOS-RT / TileRT positioning. -->

### Feature 2: Distributed Primitives and Comm-Compute Fusion

The TLE distributed API already exists on feature branches under
`python/triton/experimental/tle/language/distributed.py` and is exported from
`experimental/tle/language/__init__.py`: `remote`, `shard_id`,
`distributed_barrier`, `distributed_dot`, plus a sharding model
(`ShardedTensor`, `ShardingSpec`, `device_mesh`, `reshard`, `make_sharded_tensor`)
and a hierarchical `MeshConfig` (node / device / block_cluster / block).
Device-side helpers include `n_pes` and `_get_local_rank`, and the barrier
carries `BarrierKind {arrive, wait, sync}` and `MemoryOrder {relaxed, acquire,
release, acqrel}`.

Signal/wait `load`/`store` and the FlagCX lowering are in flight across the
`add_signal_primitives_for_tle_dist`, `add_put_value_primitives`, and
`feature/tle_remote_node` branches, which add the MLIR ops and their lowering in
the `third_party/tle` dialect:

- `Tle_PutMemOrValueOp` (`tle.putmem`) — transfer a value to a remote PE, with
  an optional `put_type` attribute selecting signal / counter-update semantics.
- `Tle_DeviceIntraBarrierOp` — device-local synchronization barrier
  (arrive / wait / sync), lowered via `flagcxIntraBarrierWaitS`.
- FlagCX integration under
  `third_party/tle/dialect/lib/Conversion/TleToLLVM/FlagCxOpToLLVM/` and
  `Tools/FlagcxUtils.cpp` — this is the compiler-side linkage to FlagCX
  ([FEP-0021](../sig-network/0021-flagcx-v0.13.0-new-features.md)).

Distributed-operator examples already exist on
`triton_v3.6.x_add_intra_node_test_demo` — `test_tle_intra_node_allgather.py`,
`test_tle_intra_node_reduce_scatter.py` and TMA / atomic-barrier variants —
and NVSHMEM support is prototyped on a separate feature branch.

The 2.2 deliverable is to land these primitives on the release branch, complete
the FlagCX multi-chip lowering, and validate comm-compute fusion parity with
Triton-distributed.

<!-- TODO (design):
     1. Final public API surface and stability level (experimental namespace).
     2. Execution model — device-initiated (NVSHMEM-style) vs. host-scheduled
        chunking; which is used per vendor.
     3. FlagCX version dependency and the per-vendor CCL backends exercised. -->

## Design Details

<!-- TODO: architecture and data-flow details for both features, to be filled
     before Status moves to `Implementable` (FEP Freeze 2026-08-14). -->

## Packaging

**(Required)** Built as part of the FlagTree TLE components; no separate wheel.

**Supported vendors:** NVIDIA (mega-kernel + distributed); distributed
primitives additionally target 2+ domestic chips via FlagCX
[TODO: name vendors].

**Can this feature be packaged as a wheel (`.whl`)?** Yes — it ships inside the
per-backend FlagTree wheel; there is no standalone artifact.

### Build

```bash
git clone https://github.com/flagos-ai/FlagTree.git
cd FlagTree
MAX_JOBS=32 python3 -m pip install . --no-build-isolation
```

FlagCX must be available for the distributed-primitive lowering.
<!-- TODO: FlagCX version pin and build flag / environment variable that
     enables the FlagCX lowering path. -->

## Test Plan

**(Required)** Each goal is verified independently, reusing the existing TLE
test infrastructure under `python/test/tle/` and the tutorials under
`python/tutorials/tle/`.

### G1 / G2: MegaKernel

| Test | Command | Expected result |
|---|---|---|
| Mega scheduler correctness | `pytest -s python/test/tle/integration/test_tle_mega_scheduler.py` | Generated cooperative kernel matches the torch reference within tolerance |
| Qwen3-32B decode perf | <!-- TODO: launch command, bs=1 decode driver, metric collection on H800 --> | Decode throughput ≥ 1.20× vLLM [TODO: version] and > Triton-distributed |

### G3 / G4: Distributed primitives on FlagCX

| Test | Command | Expected result |
|---|---|---|
| Unit (primitives) | `pytest -s python/test/tle/unit/test_tle_distributed.py` | `remote` / `shard_id` / `distributed_barrier` / signal-wait `load`/`store` pass |
| put_mem / signal | `python/test/tle/unit/test_tle_put_mem.sh` | Value/signal transfer to remote PE verified |
| Multi-chip | <!-- TODO: per vendor — build flag, launcher, rank count, hardware --> | Primitives run on 2+ domestic chips via FlagCX |

### G5: Comm-compute fusion vs. Triton-distributed

Baseline: Triton-distributed [TODO: version/commit], same hardware and message
sizes.

| Test | Command | Expected result |
|---|---|---|
| AllGather / ReduceScatter | `python/tutorials/tle/test_tle_intra_node_allgather.sh`, `..._reduce_scatter.sh` | Correct results; within [TODO: tolerance] of baseline |
| AllGather+GEMM / GEMM+ReduceScatter | <!-- TODO: benchmark command, GEMM shapes, topology --> | Within [TODO: tolerance] of baseline, average parity |

## Related PRs

<!-- TODO: fill with the actual FlagTree PR numbers by the FEP Owner. -->
- [ ] FlagTree — MegaKernel compiler (branch `feature/tle_mega`)
- [ ] FlagTree — TLE distributed primitives (branches
  `add_signal_primitives_for_tle_dist`, `add_put_value_primitives`,
  `feature/tle_remote_node`)
- [ ] FlagTree — intra-node distributed operator demos (branch
  `triton_v3.6.x_add_intra_node_test_demo`)

## Implementation History

- 2026-08-01: FEP created as `Provisional` for the FlagOS 2.2 cycle. MegaKernel
  scheduler prototype and TLE distributed API present on feature branches;
  model-level MegaKernel front-end, FlagCX multi-chip lowering, and
  comm-compute fusion parity are the net-new 2.2 work. Owner and quantified
  acceptance targets (G2, G4, G5) pending fill-in before FEP Freeze.

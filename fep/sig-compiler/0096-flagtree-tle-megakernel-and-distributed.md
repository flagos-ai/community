# FEP-0096: FlagTree TLE New Features — MegaKernel Compiler and Distributed Primitives

**Status:** `Implementable`

**Updated:** 2026-09-24

**Created:** 2026-08-01

**Owner:** Unassigned

**SIG:** sig-compiler

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| flagtree-triton3.6 | [`0.7.0-rc2-triton3.6` @ `4819c190476c`](https://github.com/flagos-ai/FlagTree/tree/4819c190476cebb66057493e41379c1406c615ac) | [`0.7.0rc2.post2+triton3.6` @ `d9e65f4df7fe`](https://github.com/flagos-ai/FlagTree/tree/d9e65f4df7fe881281abd9e834ab3f37f4d0642c) |
| flagtree-triton3.5 | [`0.7.0-rc2-triton3.5` @ `15ec1a6cbc8d`](https://github.com/flagos-ai/FlagTree/tree/15ec1a6cbc8d51f597f46459a500e96f3812c58f) | [`0.7.0rc2.post2+triton3.5` @ `15ec1a6cbc8d`](https://github.com/flagos-ai/FlagTree/tree/15ec1a6cbc8d51f597f46459a500e96f3812c58f) |

## Summary

Extend TLE with model-level MegaKernel compilation and distributed
communication primitives. RC2 contains distributed primitives, FlagCX
integration and NVSHMEM fusion examples. MegaKernel model tests are recorded in the development delivery report,
but their implementation artifact is not pinned by this RC2 manifest.
Distributed primitive QA has passed; fused-operator coverage has a separate gap.

## Goals and Completion

| Goal | RC2 implementation | Remaining work |
|---|---|---|
| G1: Model-level MegaKernel compiler and two demonstration operators | Independent MegaKernel workflow and model tests reported; no model compiler in the inspected FlagTree RC2 tree | Link and pin the tested model compiler artifact |
| G2: Qwen3-32B, batch-1 decode on one H800, at least 20% over vLLM | H800 results reported for Qwen3-1.7B and Qwen3.5-32B-A3B | Reconcile the original dense Qwen3-32B target with the tested model set |
| G3: Distributed primitives | Remote access, rank/shard queries, signal/wait and distributed barriers | Primitive QA completed; retain backend/revision attribution |
| G4: FlagCX lowering on two domestic accelerators plus NVIDIA | FlagCX host/device integration is present; Ascend DSA distributed code is on 3.5 | Retain the reported backend results and their source mapping |
| G5: At least two fused operators and Triton-distributed parity | AllGather+GEMM and GEMM+AllReduce examples present | GEMM+ReduceScatter implementation and fixed-baseline performance results |

## Design

TLE device meshes describe block, device and node placement. `tle.remote`
provides remote-memory access; `tle.shard_id`, rank queries, signals and
barriers support coordination. FlagCX integration lives under
`third_party/tle/dialect/` and is built through
`scripts/build-flagcx-project.sh`.

Multi-device and multi-node primitive tests are under `python/test/tle/unit/`.
The fusion examples under `python/tutorials/tle/raw/nvshmem/` use NVSHMEM
through TLE Raw. Their presence does not establish FlagCX-backed execution
of the same fused operators.

The MegaKernel design uses a persistent cooperative scheduler for model
execution. Development reports identify an independent model conversion and execution
workflow. Its source and benchmark artifacts still need a release mapping.

## Packaging

Distributed support ships in the FlagTree wheel with the selected FlagCX
libraries. NVSHMEM examples additionally require CUDA, NVSHMEM and the
matching hardware. NVIDIA fusion validation targets SM90 or later.

```bash
bash scripts/build-flagcx-project.sh
python -m pip wheel . --no-build-isolation --no-deps -w dist
```

The build script fetches FlagCX independently; record its commit and the
loaded `libflagcx.so`/device bitcode with every test result.

## Test Plan

Single-node primitive tests:

```bash
bash python/test/tle/unit/test_tle_distributed_d2d.sh
bash python/test/tle/unit/test_tle_signal.sh
bash python/test/tle/unit/test_tle_signal_wait.sh
bash python/test/tle/unit/test_tle_d2d_barrier.sh
```

For node-space PUT/GET, run on both nodes with the same reachable master
address and port, changing `NODE_RANK` on the second node:

```bash
NNODES=2 NODE_RANK=0 MASTER_ADDR=10.0.0.1 \
  bash python/test/tle/unit/test_tle_distributed_node.sh
```

Every rank must pass reference-value and synchronization checks.

NVSHMEM fusion examples, on at least two supported GPUs:

```bash
cd python/tutorials/tle/raw/nvshmem/02-allgather-gemm
torchrun --nproc_per_node=2 benchmark.py --dump_csv
```

Run `03-gemm-allreduce/gemm-ar.py` with `torchrun` from its example
directory. Compare numerical outputs with the PyTorch reference and record
latency, shape, dtype, topology and backend.

GEMM+ReduceScatter is tracked in
[FlagCX#620](https://github.com/flagos-ai/FlagCX/issues/620). Primitive QA and
fused-operator acceptance are separate rows in the release matrix.

## Recorded Validation

The [compiler delivery record](https://jwolpxeehx.feishu.cn/docx/HwHNdMsfCoAXoRxmeNzcNZZQnMe) reports a working model-to-Triton
MegaKernel workflow. On H800, batch-1 decode improved over the reported vLLM
baseline by 56% for Qwen3-1.7B and 24.6% for Qwen3.5-32B-A3B. These are
different models from the original dense Qwen3-32B target and are not
benchmarks of the FlagTree RC2 wheel alone.

The [September 24 development report](https://jwolpxeehx.feishu.cn/wiki/SJc8wh08si8x9vk9ECgcjXtPnJc) also records H800 multi-GPU
and Iluvatar MegaKernel tests. The implementation is developed and tested;
the missing item here is its versioned release-to-source mapping.

Tree distributed primitives have passed QA. The [NVIDIA fusion report](https://jwolpxeehx.feishu.cn/docx/MuygdfqaNoaOLkxiHqycWkNxnBc)
records passing AllGather, ReduceScatter and AllGather+GEMM. The missing
GEMM+ReduceScatter example in FlagCX #620 is a separate, non-blocking
release follow-up and does not invalidate primitive QA.

## Related PRs

- [x] [FlagTree#701](https://github.com/flagos-ai/FlagTree/pull/701) — Distributed rank primitives. Merged.
- [x] [FlagTree#732](https://github.com/flagos-ai/FlagTree/pull/732) — Remote offset support. Merged.
- [x] [FlagTree#861](https://github.com/flagos-ai/FlagTree/pull/861) — NVSHMEM GEMM+AllReduce example. Merged.
- [x] [FlagTree#863](https://github.com/flagos-ai/FlagTree/pull/863) — Signal and signal_wait primitives. Merged.
- [x] [FlagTree#899](https://github.com/flagos-ai/FlagTree/pull/899) — Remote node support. Merged.
- [x] [FlagTree#918](https://github.com/flagos-ai/FlagTree/pull/918) — Multi-node AllGather+GEMM example. Merged.
- [x] [FlagTree#961](https://github.com/flagos-ai/FlagTree/pull/961) — DSA distributed operations on Triton 3.5. Merged.
- [x] [FlagTree#969](https://github.com/flagos-ai/FlagTree/pull/969) — Node-axis shard_id. Merged.
- [x] [FlagTree#1048](https://github.com/flagos-ai/FlagTree/pull/1048) — Multi-GPU distributed barriers. Merged.
- [x] [FlagTree#1255](https://github.com/flagos-ai/FlagTree/pull/1255) — FlagCX load error handling in RC2. Merged.

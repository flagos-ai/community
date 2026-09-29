# FEP-0096: FlagTree TLE Distributed Primitives and AllGather-GEMM

**Status:** `Implemented`

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

TLE provides remote access, rank/shard queries, signal/wait operations
and distributed barriers. FlagTree includes FlagCX host/device integration
and a validated NVIDIA AllGather+GEMM example using TLE Raw/NVSHMEM.

## Delivered Scope

| Feature | Implementation | Validation |
|---|---|---|
| Distributed primitives | Remote pointers, rank/shard queries, signals and barriers | Primitive QA passed |
| FlagCX integration | Host/device lowering under `third_party/tle/dialect/` | Distributed primitive tests |
| AllGather+GEMM | `python/tutorials/tle/raw/nvshmem/02-allgather-gemm/` | Eight-H800 numerical and timing run |

## Design

Device meshes describe block, device and node placement. `tle.remote`
provides remote-memory access; rank/shard queries, signals and barriers
coordinate execution. Multi-device and multi-node tests are under
`python/test/tle/unit/`.

`scripts/build-flagcx-project.sh` builds the FlagCX dependency. The fused
AllGather+GEMM example uses NVSHMEM through TLE Raw.

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

## Test Commands

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

## Validation

Tree distributed primitives have passed QA. The
[NVIDIA report](https://jwolpxeehx.feishu.cn/docx/MuygdfqaNoaOLkxiHqycWkNxnBc)
records passing AllGather, ReduceScatter and AllGather+GEMM. The fused run
used eight H800s, passed every numerical check and achieved 1.13–1.67× the
PyTorch baseline across seven benchmark rows.

## Related PRs

- [x] [FlagTree#701](https://github.com/flagos-ai/FlagTree/pull/701) — Distributed rank primitives. Merged.
- [x] [FlagTree#732](https://github.com/flagos-ai/FlagTree/pull/732) — Remote offset support. Merged.
- [x] [FlagTree#863](https://github.com/flagos-ai/FlagTree/pull/863) — Signal and signal_wait primitives. Merged.
- [x] [FlagTree#899](https://github.com/flagos-ai/FlagTree/pull/899) — Remote node support. Merged.
- [x] [FlagTree#918](https://github.com/flagos-ai/FlagTree/pull/918) — Multi-node AllGather+GEMM example. Merged.
- [x] [FlagTree#961](https://github.com/flagos-ai/FlagTree/pull/961) — DSA distributed operations on Triton 3.5. Merged.
- [x] [FlagTree#969](https://github.com/flagos-ai/FlagTree/pull/969) — Node-axis shard_id. Merged.
- [x] [FlagTree#1048](https://github.com/flagos-ai/FlagTree/pull/1048) — Multi-GPU distributed barriers. Merged.
- [x] [FlagTree#1255](https://github.com/flagos-ai/FlagTree/pull/1255) — FlagCX load error handling in RC2. Merged.

## Deferred to FlagOS 2.3

- Release integration of the MegaKernel prototype and the model decode benchmark matrix.
- GEMM+AllReduce benchmark acceptance for the NVSHMEM example in [FlagTree#861](https://github.com/flagos-ai/FlagTree/pull/861).
- GEMM+ReduceScatter in FlagTree and the complete Triton-distributed performance comparison: [FlagCX#620](https://github.com/flagos-ai/FlagCX/issues/620).

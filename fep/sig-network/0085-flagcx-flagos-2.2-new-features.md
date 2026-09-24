# FEP-0085: FlagCX Backend, Device API and Distributed Operator Support

**Status:** `Implemented`

**Updated:** 2026-09-24

**Created:** 2026-07-30

**Owner:** [@MC952-arch](https://github.com/MC952-arch)

**SIG:** sig-network

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| flagcx | [`0.14.0-rc2` @ `5154fdbf3327`](https://github.com/flagos-ai/flagcx/tree/5154fdbf3327c1c7c272e8a83684e1508a302206) | [`v0.14.0-rc2.post1` @ `cb8896cacd49`](https://github.com/flagos-ai/flagcx/tree/cb8896cacd49ef9901c39af18df9b89bd6b9f34c) |
| flagtree-triton3.6 | [`0.7.0-rc2-triton3.6` @ `4819c190476c`](https://github.com/flagos-ai/FlagTree/tree/4819c190476cebb66057493e41379c1406c615ac) | [`0.7.0rc2.post2+triton3.6` @ `d9e65f4df7fe`](https://github.com/flagos-ai/FlagTree/tree/d9e65f4df7fe881281abd9e834ab3f37f4d0642c) |

## Summary

FlagCX 0.14 adds the PPU backend and Kunlunxin Device API support.
The distributed operator scope covers NVIDIA AllGather, ReduceScatter and
the FlagTree AllGather+GEMM example.

## Delivered Scope

| Feature | Implementation | Validation |
|---|---|---|
| PPU backend | `ppu_cuda_adaptor.cc`, `ppu_nccl_adaptor.cc`, `USE_PPU=1` | Backend QA and CI passed |
| Kunlunxin Device API | Native platform/communication traits and device kernels | Device API QA passed |
| NVIDIA collectives | Host AllGather and ReduceScatter | Multiprocess tests passed |
| AllGather+GEMM | FlagTree TLE Raw/NVSHMEM example | Eight-H800 numerical and performance run passed |

## Design

The Device API separates platform traits, communication traits and device
kernels. Device IR bindings are under `bindings/ir/`. MUSA and other
platforms use the default compatibility path where native traits are absent.

The AllGather+GEMM example is under FlagTree's
`python/tutorials/tle/raw/nvshmem/02-allgather-gemm/`. It uses NVSHMEM;
its benchmark is not a FlagCX-backed fused-kernel result.

## Packaging

Build from source with the vendor toolchain:

```bash
make USE_PPU=1 -j8
```

For NVIDIA Device API tests:

```bash
make USE_NVIDIA=1 COMPILE_KERNEL=1 -j8
```

MPI is required for multiprocess tests. P2P RDMA paths require libibverbs.
The fused examples additionally require FlagTree and NVSHMEM on NVIDIA SM90+.

## Test Commands

PPU host collectives:

```bash
cd test/perf/host_api
make USE_PPU=1
mpirun -np 2 ./build/bin/perf_allgather
mpirun -np 2 ./build/bin/perf_reducescatter
```

Device API and IR tests are under `test/unittest/device_api/`; intra-node
benchmarks are under `test/perf/device_api/`. Run the matching vendor build
and require correct results on every rank.

AllGather+GEMM, from the FlagTree source root:

```bash
cd python/tutorials/tle/raw/nvshmem/02-allgather-gemm
torchrun --nproc_per_node=2 benchmark.py --dump_csv
```

## Validation

The [release QA record](https://jwolpxeehx.feishu.cn/wiki/MuxCwz4q3iV8BzkwmJtcfJZwnah) records PPU backend, Kunlunxin Device
API and NVIDIA distributed-operator completion, with passing FlagCX CI on
NVIDIA, MetaX, Hygon and PPU.

The [NVIDIA report](https://jwolpxeehx.feishu.cn/docx/MuygdfqaNoaOLkxiHqycWkNxnBc)
records AllGather and ReduceScatter passing, and seven AllGather+GEMM
benchmark rows on eight H800s passing numerical checks with 1.13–1.67×
speedup over the PyTorch baseline.

## Related PRs

- [x] [FlagCX#512](https://github.com/flagos-ai/FlagCX/pull/512) — PPU backend. Merged.
- [x] [FlagCX#539](https://github.com/flagos-ai/FlagCX/pull/539) — Unified IR support. Merged.
- [x] [FlagCX#545](https://github.com/flagos-ai/FlagCX/pull/545) — Unified IR backend fixes. Merged.
- [x] [FlagCX#555](https://github.com/flagos-ai/FlagCX/pull/555) — Kunlunxin Device API. Merged.
- [x] [FlagCX#576](https://github.com/flagos-ai/FlagCX/pull/576) — MUSA default Device API path. Merged.
- [x] [FlagCX#582](https://github.com/flagos-ai/FlagCX/pull/582) — Default Device API on remaining platforms. Merged.
- [x] [FlagTree#918](https://github.com/flagos-ai/FlagTree/pull/918) — Multi-node NVSHMEM AllGather+GEMM example. Merged.

## Deferred to FlagOS 2.3

- A second native Device API backend and its primitive matrix.
- GLM5.2 PD validation on PPU/MetaX and the Mooncake performance comparison.
- GEMM+ReduceScatter in FlagTree and the full intra-/inter-node Triton-distributed comparison: [FlagCX#620](https://github.com/flagos-ai/FlagCX/issues/620).

# FEP-0085: FlagCX New Features for FlagOS 2.2

**Status:** `Implementable`

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

FlagCX 0.14 adds PPU support, extends the Device API and supports development
of distributed fused operators. PPU, Kunlunxin Device API and NVIDIA
collective/fusion tests have passed. PD performance and the remaining
operator/topology combinations have separate acceptance items.

## Goals and Completion

| Goal | RC2 implementation | Validation and remaining work |
|---|---|---|
| G1: T-Head PPU backend | PPU device and CCL adaptors behind `USE_PPU=1`; 13 hardware CCL backends in total | PPU backend QA and CI passed |
| G2: Two additional native Device API vendors | Kunlunxin traits and device kernels present | Identify and validate the second native vendor; default fallback does not supply a native implementation |
| G3: GLM5.2 PD disaggregation on T-Head and MetaX, at least 3% over Mooncake | P2P/KV-transfer infrastructure present; a T-Head functional run was recorded | MetaX model run and fixed-baseline end-to-end performance results |
| G4: AllGather, ReduceScatter, AllGather+GEMM and GEMM+ReduceScatter | Host collectives, Device API/IR bindings and Tree NVSHMEM examples present | GEMM+ReduceScatter and the complete intra-/inter-node comparison with Triton-distributed |

## Design

PPU uses `flagcx/adaptor/device/ppu_cuda_adaptor.cc` and
`flagcx/adaptor/ccl/ppu_nccl_adaptor.cc`.

The Device API separates platform traits, communication traits and device
kernels. Kunlunxin has native traits; MUSA and other platforms can use the
default compatibility path. Device IR bindings are under `bindings/ir/`.

PD disaggregation uses the P2P Engine for KV transfer. The acceptance workload
is GLM5.2 with one prefill and one decode instance, eight cards each. The
Mooncake comparison requires the same model, topology and request workload.
The throughput or latency metric for the 3% target is still unspecified.

## Distributed Operator Coverage

| Operator | RC2 code | Validation and remaining work |
|---|---|---|
| AllGather | FlagCX host collective and `test/perf/host_api/test_allgather.cpp` | NVIDIA tests passed; full topology/Triton-distributed comparison remains separate |
| ReduceScatter | FlagCX host collective and `test/perf/host_api/test_reducescatter.cpp` | NVIDIA tests passed; full topology/Triton-distributed comparison remains separate |
| AllGather+GEMM | FlagTree `python/tutorials/tle/raw/nvshmem/02-allgather-gemm` | Eight-H800 NVSHMEM run passed against PyTorch; full topology/baseline matrix remains separate |
| GEMM+AllReduce | FlagTree `python/tutorials/tle/raw/nvshmem/03-gemm-allreduce` | Additional example; it has different output semantics from ReduceScatter |
| GEMM+ReduceScatter | No runnable implementation in the inspected FlagCX or FlagTree RC2 trees | [FlagCX#620](https://github.com/flagos-ai/FlagCX/issues/620) |

Fused examples and their tests belong in FlagTree. Each result must identify
the communication backend and source revisions. Passing distributed-primitive
tests does not complete fused-operator acceptance.

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

## Test Plan

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

The harness checks per-rank outputs with `atol=1e-3, rtol=1e-3` and exports
shape-specific latency and speedup against torch-native. Triton-distributed
parity requires a separate pinned baseline. G3 and missing G4 forms remain
open until their launch commands and results are available.

## Recorded Validation

The [release QA record](https://jwolpxeehx.feishu.cn/wiki/MuxCwz4q3iV8BzkwmJtcfJZwnah), reviewed September 24, marks PPU backend
support, Kunlunxin Device API and NVIDIA distributed operator testing complete.
It also records successful FlagCX CI on NVIDIA, MetaX, Hygon and PPU.
GLM5.2 PD validation is still unchecked in that record.

The [NVIDIA operator report](https://jwolpxeehx.feishu.cn/docx/MuygdfqaNoaOLkxiHqycWkNxnBc)
records passing AllGather and ReduceScatter, plus an eight-H800
AllGather+GEMM run with seven benchmark rows, all numerically correct and
1.13–1.67× the PyTorch baseline. The fused example uses TLE Raw/NVSHMEM.

[Issue #620](https://github.com/flagos-ai/FlagCX/issues/620) tracks the missing
GEMM+ReduceScatter example and its end-to-end validation. It does not reopen
the completed Tree primitive QA. The release clarification treats this
missing case as non-blocking; communication/compute examples belong in Tree.

## Related PRs

- [x] [FlagCX#512](https://github.com/flagos-ai/FlagCX/pull/512) — PPU backend. Merged.
- [x] [FlagCX#539](https://github.com/flagos-ai/FlagCX/pull/539) — Unified IR support. Merged.
- [x] [FlagCX#545](https://github.com/flagos-ai/FlagCX/pull/545) — Unified IR backend fixes. Merged.
- [x] [FlagCX#555](https://github.com/flagos-ai/FlagCX/pull/555) — Kunlunxin Device API. Merged.
- [x] [FlagCX#576](https://github.com/flagos-ai/FlagCX/pull/576) — MUSA default Device API path. Merged.
- [x] [FlagCX#582](https://github.com/flagos-ai/FlagCX/pull/582) — Default Device API on remaining platforms. Merged.
- [x] [FlagTree#918](https://github.com/flagos-ai/FlagTree/pull/918) — Multi-node NVSHMEM AllGather+GEMM example. Merged.
- [x] [FlagTree#861](https://github.com/flagos-ai/FlagTree/pull/861) — NVSHMEM GEMM+AllReduce example. Merged.

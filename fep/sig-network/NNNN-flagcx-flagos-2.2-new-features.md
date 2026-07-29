# FEP-NNNN: FlagCX New Features for FlagOS 2.2

**Status:** `Provisional`

**Created:** 2026-07-30

**Owner:** [TODO: @github-username]

**SIG:** sig-network

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP covers the FlagCX features planned for the FlagOS 2.2
release cycle, on top of v0.13.0:

1. **Vendor adaptation** — T-Head (PPU) backend support, bringing FlagCX to 13
   supported chip backends; extend the FlagCX Device API adaptor interface to
   2+ additional domestic chips.
2. **PD-disaggregation support and optimization for inference** — run
   prefill-decode disaggregation for GLM5.2 on T-Head and MetaX platforms with
   3+% end-to-end gain, building on the P2P Engine introduced in v0.13.0
   ([FEP-0021](0021-flagcx-v0.13.0-new-features.md)).
3. **Distributed operators** — AllGather / ReduceScatter and the fused
   AllGather+GEMM / GEMM+ReduceScatter operators, with intra-node and
   inter-node performance on par with Triton-distributed.

Repository: https://github.com/flagos-ai/FlagCX

## Motivation

FlagOS 2.2 extends FlagCX along the two axes established in previous cycles:
breadth of domestic chip coverage, and depth of LLM-workload support. The P2P
Engine and Device API foundations shipped in v0.13.0 now need to be carried
into production inference scenarios (PD disaggregation) and into
compute-communication fusion (distributed operators), while the vendor adaptor
matrix grows to include T-Head and more Device API-capable backends.

### Goals

**(Required)**

- **G1 (T-Head adaptation):** Support the T-Head PPU backend (device adaptor
  `ppu_cuda_adaptor` + CCL adaptor `ppu_nccl_adaptor`, build flag `USE_PPU=1`),
  bringing the in-tree chip backend count to 13.
- **G2 (Device API adaptor expansion):** Extend the Device API vendor traits
  interface (`flagcx/adaptor/include/device_api/*_comm_traits.h` /
  `*_platform_traits.h`, currently implemented for NVIDIA, Hygon DU and
  Sunrise) to at least 2 additional domestic chips.
  <!-- TODO: name the target vendors and the Device API primitive subset that
       must pass tests to count as supported. -->
- **G3 (PD disaggregation):** GLM5.2 prefill-decode disaggregation runs
  end-to-end on T-Head and MetaX platforms using the FlagCX P2P Engine as the
  KV transfer substrate, with ≥3% end-to-end gain.
  <!-- TODO: define the ≥3% measurement — metric (throughput/TTFT/goodput),
       baseline, serving framework and workload profile. -->
- **G4 (Distributed operators):** Provide AllGather, ReduceScatter,
  AllGather+GEMM and GEMM+ReduceScatter operators whose intra-node and
  inter-node performance is on par with Triton-distributed.
  <!-- TODO: define "on par" — Triton-distributed baseline version, tolerance,
       message-size range, GPU count and topology, per operator. -->

### Non-Goals

- Device API CustomAllReduce / IR bindings support on vendors beyond the ones
  named in G2 (tracked per-vendor in future cycles).
- PD disaggregation on platforms other than T-Head and MetaX in this cycle.
- Fused operators beyond the four listed in G4 (e.g. AlltoAll+GEMM for MoE).

## Proposal

### Feature 1: Vendor Adaptation

**1a. T-Head (PPU) backend.** Already merged on main
(flagos-ai/FlagCX#512): adds `flagcx/adaptor/device/ppu_cuda_adaptor.cc` and
`flagcx/adaptor/ccl/ppu_nccl_adaptor.cc` behind `USE_PPU=1`, following the
existing per-vendor adaptor pattern. With PPU, the in-tree CCL adaptor matrix
covers 13 chip backends: NVIDIA (nccl), Ascend (hccl), Iluvatar (ixnccl),
Cambricon (cncl), MetaX (mccl), Moore Threads (musa_mccl), Kunlunxin (xccl),
AMD (rccl), Hygon (dunccl), TsingMicro (tccl), Enflame (eccl), Sunrise (pccl),
T-Head (ppu_nccl).

**1b. Device API adaptor interface for 2+ domestic chips.** The Device API
(v0.11–v0.13) dispatches device-side communication primitives through
per-vendor traits (`comm_traits.h` / `platform_traits.h`); today only NVIDIA,
Hygon DU and Sunrise have vendor traits, with a default fallback. This work
adds traits implementations (and, where needed, kernel compilation pipeline
support) for additional domestic chips so they can use Device API-based
features such as CustomAllReduce.

<!-- TODO (design): per target vendor — native primitives vs. default
     fallback; LLVM bitcode path availability; symmetric-window vs. IPC-only
     registration. -->

### Feature 2: PD Disaggregation Support and Optimization

Builds on the v0.13.0 P2P Engine (one-sided RDMA, vectorized read/write,
topology-aware NIC selection) and its NIXL integration
(`plugin/nixl/flagcx_p2p_on_nixl_v1.1.0.patch`). This cycle takes that
substrate to a production inference scenario: GLM5.2 PD disaggregation on
T-Head and MetaX.

<!-- TODO (design):
     1. Integration path — vLLM KV-transfer connector, NIXL backend, or both;
        serving framework versions on T-Head / MetaX.
     2. Gaps on these two platforms (P2P Engine has been validated on
        NVIDIA / Mthreads / MetaX / Hygon; what does T-Head need).
     3. Source of the optimization — transfer overlap, NIC selection,
        noncontiguous KV layout handling, or other. -->

### Feature 3: Distributed Operators

Provide standalone AllGather / ReduceScatter and communication-computation
fused AllGather+GEMM / GEMM+ReduceScatter operators, benchmarked against
Triton-distributed, targeting parity intra-node and inter-node.

<!-- TODO (design):
     1. Execution model — device-initiated kernels on the Device API IR
        bindings, or host-side chunked scheduling overlapping collectives with
        GEMM launches.
     2. API surface — C/C++ host API, torch ops (plugin/torch), or
        Triton-language builtins.
     3. Vendor scope for this cycle.
     4. Relationship to Triton-distributed — reuse of kernels/algorithms, or
        independent implementation with it as benchmark baseline only. -->

## Design Details

<!-- TODO: architecture and data-flow details for Features 1b/2/3, to be
     filled before Status moves to `Implementable`. -->

## Packaging

Built from source per backend; no wheel is published for the core library.

### Obtain Source Code

```bash
git clone https://github.com/flagos-ai/FlagCX.git
cd FlagCX
git submodule update --init --recursive
```

### Build

```bash
# Core library — choose your backend flag
make <backend>=1 -j$(nproc)

# T-Head PPU backend (Feature 1a)
make USE_PPU=1 -j$(nproc)

# Device API kernel support (Features 1b / 3, where applicable)
make USE_NVIDIA=1 COMPILE_KERNEL=1 -j$(nproc)
```

`<backend>` is one of: `USE_NVIDIA`, `USE_ASCEND`, `USE_ILUVATAR_COREX`,
`USE_CAMBRICON`, `USE_METAX`, `USE_MUSA`, `USE_KUNLUNXIN`, `USE_AMD`,
`USE_DU`, `USE_TSM`, `USE_ENFLAME`, `USE_SUNRISE`, `USE_PPU`.

### Dependencies

- MPI (multi-process tests): OpenMPI or mpich
- libibverbs (IBRC P2P adaptor, required for PD disaggregation transfers)
- Vendor toolkit per backend (CUDA toolkit for NVIDIA, etc.)
<!-- TODO: T-Head and MetaX toolchain/driver versions for Feature 2;
     serving-framework version pins. -->

### Multi-Platform Support

| Feature | Platform scope (this cycle) |
|---|---|
| T-Head backend | T-Head PPU |
| Device API adaptor expansion | [TODO: 2+ named vendors] |
| PD disaggregation (GLM5.2) | T-Head, MetaX |
| Distributed operators | [TODO] |

## Test Plan

**(Required)** Each goal is verified independently, reusing the existing test
infrastructure (`test/perf/host_api`, `test/perf/kv_transfer`,
`test/perf/device_api`).

### G1: T-Head backend

| Test | Command | Expected result |
|---|---|---|
| Build | `make USE_PPU=1 -j$(nproc)` | Library builds without errors |
| Collectives correctness/perf | `cd test/perf/host_api && make USE_PPU=1`, run perf binaries via mpirun on a T-Head node <!-- TODO: binary list, rank count, expected bandwidth --> | All collectives pass correctness check |

### G2: Device API adaptor expansion

<!-- TODO: per new vendor — build flag, required Device API test binaries
     (test/device_api unit tests, perf_allreduce_intranode, ...), hardware. -->

### G3: PD disaggregation (GLM5.2 on T-Head / MetaX)

Acceptance runs on vendor hardware; results (environment, logs, metrics) are
attached to the tracking issue by the testing party.

| Test | Command | Expected result |
|---|---|---|
| KV transfer micro-benchmark | `test/perf/kv_transfer/kv_transfer_benchmark.py` on the target platform <!-- TODO: args, expected bandwidth --> | Transfer bandwidth within expected range |
| E2E PD disaggregation | <!-- TODO: prefill/decode instance launch commands, workload driver, metric collection --> | GLM5.2 serves correctly in PD mode on T-Head and MetaX; ≥3% gain in [TODO: metric] vs. [TODO: baseline] |

### G4: Distributed operators vs. Triton-distributed

Baseline: Triton-distributed [TODO: version/commit], same hardware, same
message sizes.

| Test | Command | Expected result |
|---|---|---|
| AllGather / ReduceScatter | <!-- TODO: benchmark command --> | Within [TODO: tolerance] of baseline, intra- and inter-node |
| AllGather+GEMM / GEMM+ReduceScatter | <!-- TODO: benchmark command, GEMM shapes --> | Within [TODO: tolerance] of baseline, intra- and inter-node |

## Related PRs

- [x] flagos-ai/FlagCX#512 — [PAL] Add PPU support (T-Head backend)

## Implementation History

- 2026-07-30: FEP created as `Provisional` for the FlagOS 2.2 cycle; Features
  2 and 3 under design, Feature 1a merged on main.

# FEP(sig-network): Add FlagCX v0.13.0 New Features

**Status:** `Provisional`

**Created:** 2026-05-27

**Owner:** @flagos-ai

**SIG:** sig-network

**Target Version:** FlagOS 2.1

---

## Summary

Comparing v0.13.0 (current main branch) against v0.11.0 (commit `cceb96d`), three significant feature areas have been introduced in FlagCX:

1. **P2P Engine** — a one-sided RDMA engine for point-to-point communication, enabling prefill-decode disaggregation in LLM inference scenarios and NIXL integration.
2. **Device API-based CustomAllReduce** — an intra-node AllReduce collective implemented entirely through FlagCX Device API primitives, allowing custom kernels to perform AllReduce without host-side scheduling overhead.
3. **Device API IR Bindings for Triton** — a set of C IR wrapper functions (compilable via LLVM bitcode) that expose FlagCX device-side communication primitives to Triton-generated kernels.

Repository: https://github.com/flagos-ai/FlagCX

---

## Motivation

### Goals

- **P2P Engine:** Provide a hardware-abstracted, one-sided RDMA engine that supports high-performance P2P communications widely used in LLM inference scenarios, such as prefill-decode disaggregation. Currently, FlagCX P2P engine have been to used as vLLM KV transfer connector and integrated as a NIXL backend.
- **Device API CustomAllReduce:** Achieve low-latency AllReduce using Device API to address intra-node small-to-medium message size communication.
- **Device API IR Bindings:** Enable Triton-compiled kernels to call FlagCX Device API (rank queries, intra-node pointer access, barriers, etc.) via LLVM bitcode.

---

## Proposal

### Feature 1: P2P Engine

A standalone P2P engine (`FlagcxP2pEngine`) is introduced with a C++ API for one-sided RDMA and two-sided send/recv operations. The engine:

- Creates and manages RDMA connections over IBRC (InfiniBand Reliable Connected) QPs.
- Exposes vectorized read/write (`flagcxP2pEngineReadVector`, `flagcxP2pEngineWriteVector`) suitable for scatter-gather KV cache transfers.
- Provides an out-of-band notification channel for completion signaling.
- Integrates with FlagCX's existing topology manager (`flagcxP2pTopoManager`) to select the optimal NIC per GPU.

Users of vLLM, NIXL, Mooncake or custom disaggregation frameworks can use the P2P engine as a low-level RDMA substrate. A patch for NIXL v1.1.0 integration (`plugin/nixl/flagcx_p2p_on_nixl_v1.1.0.patch`) is provided.

### Feature 2: Device API-based CustomAllReduce

`flagcxIntraAllReduce` is a kernel-based AllReduce that operates on a registered shared memory window (`flagcxDevMem_t`) using LSA or Multicast. The host-side setup:

1. Allocate a symmetric buffer (`flagcxMemAlloc` for VMM/window mode, or `cudaMalloc` for IPC mode).
2. Register it: `flagcxCommWindowRegister` (window mode) or `flagcxCommRegister` (IPC mode).
3. Create device handles: `flagcxDevCommCreate` + `flagcxDevMemCreate`.
4. Get device pointers: `flagcxDevCommGetDevicePtr` + `flagcxDevMemGetDevicePtr`.
5. Call `flagcxIntraAllReduce(devMem, count, datatype, devComm, stream)` from the host.

### Feature 3: Device API IR Bindings for Triton

A set of `extern "C"` wrapper functions (declared in `flagcx_device_wrapper.h`, implemented in `flagcx_device_wrapper_impl.h`) expose the following categories of device-side primitives for LLVM bitcode compilation:

| Category | Functions |
|---|---|
| Comm Queries | `flagcxDevCommGetRank`, `flagcxDevCommGetSize`, `flagcxDevCommGetIntraRank`, `flagcxDevCommGetIntraSize` |
| Cooperative Group | `flagcxCoopAnyInitBlock`, `flagcxCoopThreadRankC`, `flagcxCoopSizeC`, `flagcxCoopSyncC` |
| Team Queries | `flagcxGetTeamIntra`, `flagcxTeamRankToWorldC`, `flagcxTeamRankToIntraC` |
| Local Pointer | `flagcxGetLocalPointerC` |
| Intra Pointer (LSA) | `flagcxGetIntraPointerC` |
| Data Type Size | `flagcxDataTypeSizeC` |
| Intra Barrier | `flagcxIntraBarrierSessionInit`, `flagcxIntraBarrierSyncC` |
| Intra Barrier Arrive/Wait | `flagcxIntraBarrierArriveC`, `flagcxIntraBarrierWaitC` |

The `flagcx_kernel.h` umbrella header guards these with `#ifndef __clang_llvm_bitcode_lib__` so that Triton's bitcode path only includes the device-safe subset (`flagcx_kernel_core.h`).

---

## Design Details

### P2P Engine Architecture

```
FlagcxP2pEngine
  ├── IBRC adaptor (flagcxP2pDevCtx, ibv_pd per device)
  ├── Accept thread (TCP handshake → QP setup)
  ├── Notification thread (out-of-band completion signals)
  └── MR registry (base VA → lkey/rkey mapping)

FlagcxP2pConn
  ├── flagcxP2pSendComm / flagcxP2pRecvComm (IB QP + CQ)
  ├── flagcxP2pRequest ring (128 slots)
  └── IPC handle cache (intra-node transfers)

FlagcxP2pRdmaDesc (64 bytes)
  ├── addr    : remote virtual address
  ├── size    : transfer size
  ├── rkey    : remote MR key
  └── padding : reserved for bookkeeping
```

Connection setup follows a TCP-based handshake where both sides exchange QP numbers, GIDs, and MTU via `flagcxP2pConnMeta`. The topology manager (`flagcxP2pTopoInit`) enumerates local GPUs and NICs, builds a node-scoped topology graph, and selects the best NIC for each GPU via `flagcxP2pTopoGetNetDev`.

### Device API CustomAllReduce Data Flow

```
Host Setup:
  flagcxMemAlloc(regBuff)
  flagcxCommWindowRegister(comm, regBuff, size, &win, FLAGCX_WIN_COLL_SYMMETRIC)
  flagcxDevCommCreate(comm, &reqs, &devComm)   // reqs.intraBarrierCount = CTA_COUNT
  flagcxDevMemCreate(comm, regBuff, size, win, &devMem)

Kernel Execution:
  flagcxIntraAllReduce(devMem, count, flagcxFloat, devComm, stream)
    └── Device kernel:
        1. Each CTA reads local data from regBuff
        2. Reads peer data via flagcxGetIntraPointerC(devMem, offset, peer)
        3. Performs reduction (sum)
        4. Writes result back to regBuff
        5. Synchronizes via flagcxIntraBarrier
```

Two registration modes are supported:
- **Window mode** (`-R 2`): Uses `flagcxCommWindowRegister` + VMM-allocated memory. Preferred for NCCL >= 2.28.
- **IPC mode** (`-R 1`): Uses `flagcxCommRegister` + `cudaMalloc` memory. Compatible with all NCCL versions.

### Device API IR Bindings Architecture

```
Triton Kernel (.py)
  → Triton IR → LLVM IR
  → Links flagcx_device_wrapper bitcode (.bc)
  → Final PTX/CUBIN

flagcx_device_wrapper.h   (extern "C" declarations, bitcode-safe)
flagcx_device_wrapper_impl.h  (inline implementations using adaptor)
flagcx_kernel_core.h      (device-side types: flagcxDevComm, flagcxDevMem, etc.)
```

The IR functions operate on opaque `devCommPtr` and `devMemPtr` pointers obtained from the host-side `flagcxDevCommGetDevicePtr` / `flagcxDevMemGetDevicePtr` APIs. This allows Triton kernels to:
- Query communicator topology (rank, size, intra-rank).
- Access peer memory directly via LSA pointers.
- Synchronize across intra-node ranks using barriers.
- Perform cooperative group operations within a CTA.

---

## Packaging

### Obtain Source Code

```bash
git clone https://github.com/flagos-ai/FlagCX.git
cd FlagCX
git submodule update --init --recursive
```

### Build

```bash
# Build FlagCX core library (choose your backend)
make <backend>=1 -j$(nproc)

# Build with Device API kernel support (required for CustomAllReduce)
make USE_NVIDIA=1 COMPILE_KERNEL=1 -j$(nproc)
```

Where `<backend>` is one of: `USE_NVIDIA`, `USE_ASCEND`, `USE_ILUVATAR_COREX`, `USE_CAMBRICON`, `USE_METAX`, `USE_MUSA`, `USE_KUNLUNXIN`, `USE_DU`, `USE_AMD`, `USE_TSM`, `USE_ENFLAME`.

### Dependencies

- MPI (for multi-process tests)
- libibverbs (for IBRC P2P adaptor)
- CUDA toolkit (for NVIDIA backend)
- NCCL >= 2.25 (for Device API vendor path; >= 2.28 for window mode)

---

## Test Plan

### P2P Engine Tests

```bash
cd test/unittest/p2p
make
cd build/bin
```

| Test | Command | Description |
|---|---|---|
| Unit test: P2P engine | `mpirun --allow-run-as-root -np 2 ./p2p_unit_tests` | Verifies P2P engine correctness: one-sided read, RPC, adaptor, batch, and slice task |

### Device API CustomAllReduce Tests

```bash
# FlagCX must be built with COMPILE_KERNEL=1 (from project root)
make USE_NVIDIA=1 COMPILE_KERNEL=1 FORCE_DEFAULT_PATH=1 -j$(nproc)

cd test/perf/device_api
make USE_NVIDIA=1
cd build/bin
```

| Test | Command | Description |
|---|---|---|
| Perf test: AllReduce intranode | `mpirun --allow-run-as-root -np 8 -x FLAGCX_USE_HETERO_COMM=1 -x FLAGCX_MEM_ENABLE=1 -x FLAGCX_VMM_ENABLE=0 -x FLAGCX_P2P_DISABLE=1 ./perf_allreduce_intranode -b 1M -e 64M -f 2 -R 1` | Sweeps message sizes, reports algBW/busBW, verifies AllReduce correctness |

### Device API IR Bindings Tests

```bash
# FlagCX must be built with COMPILE_KERNEL=1 (from project root)
make USE_NVIDIA=1 COMPILE_KERNEL=1 FORCE_DEFAULT_PATH=1 -j$(nproc)

cd test/unittest/device_api
make USE_NVIDIA=1 FORCE_DEFAULT_PATH=1 -j$(nproc)
cd build/bin
```

| Test | Command | Description |
|---|---|---|
| IR bindings correctness | `mpirun --allow-run-as-root -np 8 -x FLAGCX_USE_HETERO_COMM=1 -x FLAGCX_MEM_ENABLE=1 -x FLAGCX_VMM_ENABLE=0 -x FLAGCX_P2P_DISABLE=1 ./test_device_ir -b 1M -e 4M -f 2 -R 2` | Tests 8 kernel categories covering 69 IR wrapper functions (comm queries, cooperative group, team queries, local/intra pointers, barriers) |

---

## Related PRs

- [ ] flagos-ai/FlagCX#450 — [PAL] IBRC P2P adaptor for FlagCX P2P engine
- [ ] flagos-ai/FlagCX#452 — [CRL] Refactor P2P zerocopy
- [ ] flagos-ai/FlagCX#453 — [CRL] P2P topo manager
- [ ] flagos-ai/FlagCX#454 — [CRL] Using Device API for customAllReduce implementation
- [ ] flagos-ai/FlagCX#466 — [CRL] Add & implement P2P interface for integration with NIXL
- [ ] flagos-ai/FlagCX#433 — [PAL] Introduce traits abstraction and DeviceAPI for unified vendor/fallback support
- [ ] flagos-ai/FlagCX#445 — [PAL] Support Device API Transport
- [ ] flagos-ai/FlagCX#442 — [PAL] Add Device API DU support
- [ ] flagos-ai/FlagCX#447 — [CRL] Add Device API multi-FIFO support
- [ ] flagos-ai/FlagCX#471 — [CRL] Add Device API symmem and multicast support
- [ ] flagos-ai/FlagCX#474 — [Others] KV transfer benchmark
- [ ] flagos-ai/FlagCX#475 — [UIL] Support Device API IR Bindings

---

## Implementation History

- 2026-05-27: FEP created for FlagCX v0.13.0 (features under development) under `sig-network`.
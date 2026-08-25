# FEP-0085: FlagCX New Features for FlagOS 2.2

**Status:** `Provisional`

**Created:** 2026-07-30

**Owner:** [@MC952-arch](https://github.com/MC952-arch)

**SIG:** sig-network

**Target Version:** FlagOS 2.2

---

## Summary

This FEP covers the FlagCX features planned for the FlagOS 2.2
release cycle, on top of v0.13.0:

1. **Vendor adaptation** — T-Head (PPU) backend support, bringing FlagCX to 13
   supported chip backends; extend the FlagCX Device API adaptor interface to
   2 additional domestic chips (Kunlunxin plus one more vendor).
2. **PD-disaggregation support and optimization for inference** — run
   prefill-decode disaggregation for GLM5.2 on T-Head and MetaX with ≥3%
   end-to-end gain over the Mooncake TransferEngine baseline, building on the
   P2P Engine introduced in v0.13.0
   ([FEP-0021](0021-flagcx-v0.13.0-new-features.md)).
3. **Distributed operators** — AllGather and ReduceScatter, plus the fused
   AllGather+GEMM and GEMM+ReduceScatter operators, targeting intra-node and
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

- **G1 (T-Head adaptation):** Support the T-Head PPU backend (device adaptor
  `ppu_cuda_adaptor` + CCL adaptor `ppu_nccl_adaptor`, build flag `USE_PPU=1`),
  bringing the in-tree chip backend count to 13. Merged on `main`
  (flagos-ai/FlagCX#512); adaptation complete and ready for testing.
- **G2 (Device API adaptor expansion):** Extend the Device API vendor traits
  interface (`flagcx/adaptor/include/device_api/*_comm_traits.h` /
  `*_platform_traits.h`, currently implemented for NVIDIA, Hygon DU and
  Sunrise) to 2 additional domestic chips. First target is Kunlunxin, whose
  PR is expected around 2026-09-10 with runs on their production line; the
  second vendor is being lined up with the goal of landing within the 2.2
  window and carries schedule risk.
  <!-- TODO: name the second vendor once committed, and the Device API
       primitive subset that must pass tests to count as supported. -->
- **G3 (PD disaggregation):** GLM5.2 prefill-decode disaggregation runs
  end-to-end on T-Head and MetaX using the FlagCX P2P Engine as the KV
  transfer substrate, with ≥3% end-to-end gain over Mooncake TransferEngine
  (its default configuration) on the same setup.
  Status 2026-08-24: runs on T-Head at parity with the baseline, with the
  optimization work for the gain in progress and prioritized there. MetaX
  is gated on the platform's base optimization, which is not done — GLM
  does not yet run normally on MetaX, so its acceptance lands later in the
  cycle.
  <!-- TODO: metric definition for the ≥3% (throughput/TTFT/goodput) and
       workload profile. -->
- **G4 (Distributed operators):** AllGather and ReduceScatter, plus the
  fused AllGather+GEMM and GEMM+ReduceScatter operators, with intra-node
  and inter-node performance on par with Triton-distributed. The operators
  build on the FlagCX Device API + IR bindings and NVSHMEM; vendor scope
  this cycle is NVIDIA (sm90+).
  Status 2026-08-24: adapted on NVIDIA; most scenarios outperform
  torch-native, and the gap to Triton-distributed is being optimized. In
  the FlagTree tree today the fused implementations are
  `python/tutorials/tle/raw/nvshmem/02-allgather-gemm` (with a benchmark
  harness against torch-native) and `03-gemm-allreduce`.
  <!-- TODO: code locations for standalone AllGather / ReduceScatter and
       GEMM+ReduceScatter (not in the FlagTree tree as of 2026-08-25), and
       the Triton-distributed comparison method — add a variant to
       benchmark.py or run their upstream benchmark, and which
       version/commit defines "on par". -->

### Non-Goals

- Device API CustomAllReduce / IR bindings support on vendors beyond the ones
  named in G2 (tracked per-vendor in future cycles).
- PD disaggregation on platforms other than T-Head and MetaX in this cycle.
- Fused operators beyond the four listed in G4 (e.g. AlltoAll+GEMM for MoE).
- Ascend enablement: blocked on a PCI-probe interface issue on the Ascend
  side; not pursued standalone in this cycle, tracked together with the
  sglang-plugin Huawei P0 work, which hits the same problem.

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

**1b. Device API adaptor interface for 2 more domestic chips.** The Device API
(v0.11–v0.13) dispatches device-side communication primitives through
per-vendor traits (`comm_traits.h` / `platform_traits.h`); today only NVIDIA,
Hygon DU and Sunrise have vendor traits, with a default fallback. This work
adds traits implementations (and, where needed, kernel compilation pipeline
support) for Kunlunxin and a second vendor so they can use Device API-based
features such as CustomAllReduce. Vendor-side adaptation is in progress;
Kunlunxin's PR is expected around 2026-09-10.

<!-- TODO (design): per target vendor — native primitives vs. default
     fallback; LLVM bitcode path availability; symmetric-window vs. IPC-only
     registration. -->

### Feature 2: PD Disaggregation Support and Optimization

Builds on the v0.13.0 P2P Engine (one-sided RDMA, vectorized read/write,
topology-aware NIC selection) and its NIXL integration
(`plugin/nixl/flagcx_p2p_on_nixl_v1.1.0.patch`). This cycle takes that
substrate to a production inference scenario: GLM5.2 PD disaggregation on
T-Head and MetaX, with 1 prefill + 1 decode instance (8+8 cards) and
inter-instance KV transfers over the network; the setup runs in containers.
Baseline for the ≥3% gain is Mooncake TransferEngine in its default
configuration on the same topology.

Status 2026-08-24: runs end-to-end on T-Head at roughly baseline
performance; the optimization work targeting the gain is in progress and is
prioritized on T-Head. MetaX waits on the platform's base optimization —
GLM does not yet run normally there — so its PD acceptance comes later in
the cycle.

<!-- TODO (design): source of the optimization — transfer overlap, NIC
     selection, noncontiguous KV layout handling, or other. -->

### Feature 3: Distributed Operators

Standalone AllGather / ReduceScatter and fused AllGather+GEMM /
GEMM+ReduceScatter operators, targeting intra-node and inter-node
performance on par with Triton-distributed. The operators use the FlagCX
Device API + IR bindings and NVSHMEM for intra-node and inter-node
transfers; vendor scope this cycle is NVIDIA (sm90+).

Status 2026-08-24: adapted on NVIDIA, with most scenarios outperforming
torch-native and the gap to Triton-distributed being optimized. What is in
the FlagTree tree today (https://github.com/flagos-ai/FlagTree, under
`python/tutorials/tle/raw/nvshmem/`): `02-allgather-gemm` and
`03-gemm-allreduce`. The AG+GEMM directory carries a benchmark harness:
it sweeps seven layer shapes (LLaMA-7B / 3.1-8B / 3.1-70B / 3.1-405B,
Mistral-7B, Qwen2-72B, GPT-3-175B) at M=8192 (configurable via `--M`),
fp16 or bf16, gates correctness first (`assert_allclose` at
`atol=1e-3, rtol=1e-3` per rank), then times six variants — fused total,
AG-only, GEMM-only, on both the FlagTree and torch sides — and
`--dump_csv` writes `csv/perf_ag_gemm_<world_size>_ranks.csv` with speedup
per shape. Run:
`torchrun --nproc_per_node=<N> benchmark.py --dump_csv` (at least 2 GPUs,
`WORLD_SIZE % LOCAL_WORLD_SIZE == 0`).

<!-- TODO:
     1. Code locations for standalone AllGather / ReduceScatter and for
        GEMM+ReduceScatter — neither is in the FlagTree tree as of
        2026-08-25 (03- is GEMM+AllReduce).
     2. Triton-distributed comparison method — add a third timing variant
        to benchmark.py or run their upstream benchmark, and which
        version/commit defines "on par". -->

## Design Details

<!-- TODO: architecture and data-flow details for Features 1b/2/3, to be
     filled as the per-feature TODOs above are resolved. -->

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
- PD disaggregation runs use the inference stack's images for the target
  platform (the same communication library paths are exercised there), so no
  separate legacy-driver images are required.
<!-- TODO: T-Head toolchain/driver versions and serving-framework pins for
     Feature 2. -->

### Multi-Platform Support

| Feature | Platform scope (this cycle) |
|---|---|
| T-Head backend | T-Head PPU |
| Device API adaptor expansion | Kunlunxin + 1 vendor [TODO: name when committed] |
| PD disaggregation (GLM5.2) | T-Head, MetaX (MetaX gated on its base platform optimization) |
| Distributed operators | NVIDIA |

## Test Plan

Each goal is verified independently, reusing the existing test
infrastructure (`test/perf/host_api`, `test/perf/kv_transfer`,
`test/perf/device_api`).

Test inputs the development side provides before the testing window starts:

- An official test command document per feature (the CI workflows under
  `.github/workflows/` — currently running the full suites on NVIDIA, MetaX
  and Hygon on every code update — serve as the command reference; CI
  coverage for the remaining vendors is being added separately).
- A per-vendor API compatibility list for the existing host-API surface, so
  the test matrix reflects the actual supported set rather than the CI
  subset. Hygon and MetaX coverage in CI is current; vendors last validated
  in earlier cycles are re-listed with the driver versions they were
  validated against.

Scope rule for the 2.2 window: existing features are tested against the 2.1
release scope (more thoroughly than 2.1); new features are tested only within
the support scope stated in this FEP.

### G1: T-Head backend

| Test | Command | Expected result |
|---|---|---|
| Build | `make USE_PPU=1 -j$(nproc)` | Library builds without errors |
| Collectives correctness/perf | `cd test/perf/host_api && make USE_PPU=1`, run the per-collective binaries (`test_allreduce`, `test_allgather`, `test_reducescatter`, `test_alltoall`, `test_sendrecv`, ...) via mpirun on a T-Head node <!-- TODO: rank count, expected bandwidth --> | All collectives pass correctness check |

### G2: Device API adaptor expansion

Kunlunxin first (PR expected ~2026-09-10), second vendor when its adaptation
lands.

<!-- TODO: per new vendor — build flag, required Device API test binaries
     (test/device_api unit tests, test_allreduce_intranode, ...), hardware. -->

### G3: PD disaggregation (GLM5.2 on T-Head / MetaX)

Acceptance runs on vendor hardware; results (environment, logs, metrics) are
attached to the tracking issue by the testing party. Topology: 1P+1D, 8+8
cards, KV transfers over the network, containerized. T-Head is testable now;
MetaX follows once its base platform optimization lands and GLM runs there.

| Test | Command | Expected result |
|---|---|---|
| KV transfer micro-benchmark | `test/perf/kv_transfer/kv_transfer_benchmark.py` on the target platform (connector modes per its README) <!-- TODO: args, expected bandwidth --> | Transfer bandwidth within expected range |
| E2E PD disaggregation | <!-- TODO: prefill/decode instance launch commands, workload driver, metric collection --> | GLM5.2 serves correctly in PD mode; ≥3% gain in [TODO: metric] vs. Mooncake TransferEngine (default) on the same setup |

### G4: Distributed operators

Four operators in scope: AllGather, ReduceScatter, AllGather+GEMM,
GEMM+ReduceScatter; acceptance target is intra-node and inter-node
performance on par with Triton-distributed. NVIDIA sm90+ this cycle.

The command below is the harness that exists in the FlagTree tree today
(`02-allgather-gemm/benchmark.py`): it sweeps seven layer shapes (LLaMA-7B /
3.1-8B / 3.1-70B / 3.1-405B, Mistral-7B, Qwen2-72B, GPT-3-175B) at M=8192
(configurable via `--M`), fp16 or bf16, gates correctness first
(`assert_allclose` at `atol=1e-3, rtol=1e-3` per rank), then times six
variants: fused total, AG-only, GEMM-only, on both FlagTree and torch sides.

| Test | Command | Expected result |
|---|---|---|
| AllGather+GEMM | `cd python/tutorials/tle/raw/nvshmem/02-allgather-gemm && torchrun --nproc_per_node=<N> benchmark.py --dump_csv` (requires ≥2 GPUs, sm90+, `WORLD_SIZE % LOCAL_WORLD_SIZE == 0`) | Correctness passes per rank; fused path outperforms torch-native total latency in the covered shapes; csv written to `csv/perf_ag_gemm_<world_size>_ranks.csv` with speedup column |
| GEMM+AllReduce | `03-gemm-allreduce` — test command TBD | Correctness passes; latency vs. torch-native recorded |
| AllGather / ReduceScatter (standalone) | [TODO: code location and command] | Performance on par with Triton-distributed, intra- and inter-node |
| GEMM+ReduceScatter | [TODO: code location and command] | Performance on par with Triton-distributed, intra- and inter-node |

<!-- TODO: Triton-distributed comparison method — no baseline exists in the
     tree today; either add a third timing variant to benchmark.py or run
     their upstream benchmark, fixing the version/commit and the tolerance
     that counts as "on par". -->

## Related PRs

- [x] flagos-ai/FlagCX#512 — [PAL] Add PPU support (T-Head backend)
- [x] flagos-ai/FlagCX#539 — [UIL] Add Unified IR support (Device API / IR
  groundwork Features 1b and 3 build on)
- [x] flagos-ai/FlagCX#545 — [UIL] Fix multi-backend issues for Unified IR
- [ ] Kunlunxin Device API traits PR (expected ~2026-09-10)
- [ ] Second Device API vendor PR [TODO]

## Implementation History

- 2026-07-30: FEP created as `Provisional` for the FlagOS 2.2 cycle; Features
  2 and 3 under design, Feature 1a merged on main.
- 2026-08-24: Progress sync with development — T-Head adaptation complete and
  testable; distributed operators adapted on NVIDIA; PD disaggregation runs
  on T-Head with optimization in progress (baseline Mooncake); Kunlunxin
  Device API PR expected ~09-10; MetaX PD moved to stretch (base platform
  optimization pending); Ascend deferred behind the sglang-plugin Huawei P0.
- 2026-08-25: FEP updated to the synced scope; Owner set.
- 2026-08-25: Goals restored to the development-side feature list (PD on
  T-Head and MetaX; four distributed operators with the Triton-distributed
  parity target), with the 08-24 status and the open items kept as TODOs.

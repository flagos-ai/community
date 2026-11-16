# FEP-NNNN: FlagCX Device API, Multi-Backend Validation and PD Disaggregation for FlagOS 2.3

**Status:** `Provisional`

**Created:** 2026-11-16

**Owner:** [@MC952-arch](https://github.com/MC952-arch) (proposed; confirmation pending)

**SIG:** sig-network

**Target Version:** FlagOS 2.3 (proposed; not admitted)

## Summary

Extend [FlagCX](https://github.com/flagos-ai/FlagCX) Device API support, validate communication across at least eight accelerator backends, and complete communication-compute fusion and prefill/decode (PD) integration tests. This proposal also tracks GIN and in-network computing (INC) feasibility and the evidence needed to reapply to the PyTorch ecosystem.

This draft separates code already on `main`, open implementation PRs and unverified targets. It does not claim release acceptance. The [2.3 schedule](../../release/2.3/schedule.md) set November 13 as the FEP merge deadline, with no retroactive admission. This proposal missed that gate and must be deferred under the current rules; the Release Manager must record its actual target before release tracking. No exception is assumed.

## Baseline

Code reviewed: [`86e8d9bb9b28b1ec5c5fd371feea305cf183b7a5`](https://github.com/flagos-ai/FlagCX/tree/86e8d9bb9b28b1ec5c5fd371feea305cf183b7a5), November 15, 2026. PR states below were checked on November 16. This is a development snapshot, not a release tag.

| Area | Available on the reviewed main branch | Remaining work |
|---|---|---|
| Device API | Hygon Device API/IR and bitcode; Iluvatar default path; Kunlunxin bitcode and XPU IR entry points | Ascend #705 and PPU #719 are open. Compile success or IR entry points alone do not establish complete Device API support. |
| CI | Six enabled entries in [platforms.yml][platforms]: CUDA, Hygon, Iluvatar, MetaX, PPU and Ascend | Kunlunxin #671, Enflame #672 and MUSA #675 are open. A registered backend is not necessarily fully tested. MetaX Torch jobs still require a working image. |
| Fusion | UniRunner fused collectives and shared CUDA/Hygon kernels, including AllGather+GEMM and GEMM+ReduceScatter (#697, #713) | Per-backend accuracy, performance and physical multi-node acceptance; Hygon FP16/BF16 reductions remain unsupported in the shared kernel path. |
| PD transport | Shared P2P engine, interservice integration, KV-transfer benchmark and PTD profiling; Ascend IPC/GPU registration and VMM/RMA changes (#700, #706) | Model-level launch recipes, reproducible results and the complete five-chip matrix. Transport tests do not establish model-level gains. |
| GIN/INC | DefaultBackend Net-provider dispatch (#694), with Proxy as the active implementation | No accepted GIN hardware test environment; INC implementation and validation are not established. Provider dispatch is not a completed GIN implementation. |

Earlier release proposals: [FEP-0021](0021-flagcx-v0.13.0-new-features.md) and [FEP-0085](0085-flagcx-flagos-2.2-new-features.md). Unaccepted targets from those documents are not treated as completed here.

## Goals

| Goal | Proposed scope | Acceptance requirement |
|---|---|---|
| G1 — Device API | At least three domestic accelerator backends, prioritizing Huawei Ascend, Hygon and T-Head PPU | Publish a per-backend primitive, dtype, topology and runtime-version matrix; validate the declared subset on hardware, including the device execution path. MetaX is not a priority for this goal. |
| G2 — CI and compatibility | At least eight distinct accelerator backends, extending the six registered backends with Kunlunxin, Enflame and MUSA as candidates | Build and regression results for each counted backend; Host API, Device API and Torch coverage reported separately. Validate the planned PyTorch 2.14 target when available and the latest stable CUDA PyTorch at qualification time. |
| G3 — Communication-compute fusion | AllGather+GEMM and GEMM+ReduceScatter; operator-side testing first on Hygon and Iluvatar, retaining CUDA as a reference | Correctness per rank, supported dtypes and intra-/inter-node measurements against equivalent vendor-native operations. The percentage improvement target remains to be agreed. |
| G4 — PD disaggregation | GLM5.2 on T-Head and Hygon, targeting at least 3% end-to-end improvement over Mooncake TransferEngine; Qwen3.6 on five chip platforms | Model-level functional and performance evidence. T-Head, Hygon and MetaX are reported Qwen candidates; two additional platforms and all exact model revisions remain to be confirmed. |
| G5 — GIN/INC feasibility | Device API GIN and Host/Device API INC design, integration boundary and test tooling | Obtain a usable environment and executable test harness before committing implementation scope. INC remains high risk. Neither is a guaranteed 2.3 feature. |

G1, G3 and G4 have different vendor matrices. Device API priority does not imply that every fused operator or model already runs on those backends. G4 platform reports are planning inputs, not verified acceptance results.

## Proposal

### Device API and integration boundaries

Preserve the Host API and Device API interfaces while completing vendor implementations through the existing backend/traits and IR mechanisms. For each platform, document whether communication uses a native vendor path, the default backend or SHMEM, and which operations require kernel compilation, symmetric memory or a network provider. Unsupported combinations must report a documented error rather than silently count as supported.

Deliver matching host libraries, device bitcode where supported, and consumer headers from the same revision. Check downstream linking with FlagTree and operator consumers. Ascend native-operator interoperability (#695) is a separate integration dependency, not evidence of full Device API completion.

[FEP-0164 / community #164](https://github.com/flagos-ai/community/pull/164) owns FlagTree TLE primitives, compiler integration, autotuning and its model-derived fused operators. This FEP owns the FlagCX runtime, communication interfaces, backend validation and PD transport. Share compatible environments and test evidence with SIG Compiler, SIG Operator and SIG Framework; do not substitute #164's PyTorch speedup target for G3's vendor-native comparison.

### Compatibility and PyTorch ecosystem readiness

Maintain the vendor support matrix and executable recipes in the FlagCX repository. Pin accelerator model, driver, SDK, vendor communication library, MPI, Python/PyTorch, image digest and FlagCX revision for every result. Development and QA must use the same qualified image; rerun regressions when drivers or SDKs change. Retest existing functionality separately from new-feature acceptance.

For G2, count distinct backends with passing declared build and regression suites, not configuration files or skipped jobs. Publish remaining Host API, Device API, Torch and multi-node gaps explicitly. The ninth candidate may be included if ready; eight is a minimum, not a claim that all nine are supported today.

[PyTorch ecosystem application #68](https://github.com/pytorch-fdn/ecosystem/issues/68) is closed. Its review identified four gaps: current PyTorch support, CI across declared backends, documented technical governance and verifiable binary installation. Prepare a new application only after addressing all four, linking the previous review and reproducible evidence. Building a wheel locally is not proof that users can obtain a published binary. Ecosystem admission is an external decision, not a release acceptance criterion.

### PD and performance

Use the FlagCX P2P engine and serving-framework integration for KV transfer. Record separate transport correctness, transport performance and model-level results. Keep model revision, precision, serving stack, P/D placement, card count, network, request distribution and concurrency identical between FlagCX and Mooncake runs.

For GLM, the proposed primary metric is request throughput at the same latency SLO: `100 * (FlagCX throughput / Mooncake throughput - 1) >= 3`. The owner and inference team must confirm the metric, SLO and workload before measurement. Report TTFT and inter-token latency alongside throughput. The target is pending, not an achieved gain.

For Qwen, qualify five explicitly named chip platforms. Each requires a reproducible prefill/decode launch and benchmark command, successful model outputs and a recorded transport selection. Do not count a backend from a transfer microbenchmark alone.

### GIN/INC and non-goals

Keep Proxy behavior covered while defining GIN provider capabilities, ordering/completion semantics and required hardware. Request a reproducible test environment or a supplier-runnable harness. INC additionally needs its supported operations, reduction semantics, accuracy and fallback behavior specified before implementation acceptance.

National-standard publication, external collaboration milestones, universal binary packaging RFC #698 and third-party ecosystem approval are outside this FEP's technical acceptance. GIN/INC work that lacks hardware or misses the applicable feature gate moves to a later release.

## Packaging

Build one artifact set per backend and supported architecture. The reviewed source can build a Python wheel containing the Torch extension and `libflagcx.so`; setting `FLAGCX_BITCODE_ARCH` additionally packages device bitcode and matching headers on supported toolchains. NVIDIA, Iluvatar and Hygon bitcode builds are documented in [device_api_bitcode.md][bitcode]. Ascend and PPU default Device API additions remain subject to their open PRs and hardware qualification.

Run from a clean FlagCX checkout with submodules initialized, the selected vendor SDK/communication libraries, MPI, libibverbs, Python build dependencies and a compatible PyTorch environment. The examples below are independent builds; use a fresh checkout/build directory when changing backend or architecture.

```bash
# NVIDIA wheel, including sm_90 Device API bitcode.
FLAGCX_ADAPTOR=nvidia FLAGCX_BITCODE_ARCH=sm_90 \
  python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist

# Hygon wheel, including bitcode for an SDK-supported architecture.
FLAGCX_ADAPTOR=du DEVICE_HOME=/opt/dtk CCL_HOME=/opt/dtk \
  FLAGCX_BITCODE_ARCH=gfx906 \
  python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist

# T-Head Host API library; this alone does not enable the proposed Device API.
make USE_PPU=1 -j8
```

Record the exact supported dependency versions with each artifact. Verify the wheel's library/bitcode/header contents and the installed Torch extension. Publish the download location and supported installation command before ecosystem resubmission. Release tags, manifest entries and package metadata must agree; no new FlagCX version number is assigned by this draft.

## Test Plan

Commands below refer to paths present in the reviewed FlagCX snapshot and have been inspected, not executed for this document. Run them from the repository root in the corresponding qualified hardware CI image. The CI wrappers may build the library/plugin as part of the test. Preserve per-rank results, timeouts and skipped-case reasons. An exit code of zero with all relevant cases skipped is not acceptance.

CI configurations can emulate multiple logical nodes within one server. Those runs must be identified as such; any physical inter-node claim requires separate hosts with recorded rank placement and RDMA topology. Final release qualification must repeat the tests against the selected release tag.

### G1 — Device API

On the Hygon CI environment:

```bash
bash .github/scripts/ci/run_unit_test.sh \
  .github/scripts/set_env/hygon.sh device_api
bash .github/scripts/ci/run_unit_test.sh \
  .github/scripts/set_env/hygon.sh device_api_unified_ir
```

**Expected:** All selected Device API and unified-IR cases execute and pass; transferred data and synchronization results agree across ranks, with no hangs or cleanup errors. Record the primitive/dtype subset and whether each topology was exercised. This is not an all-backend test.

**Pending:** After #705 and #719 are integrated, add the Ascend and PPU device-executing commands, supported primitive lists and expected outputs to this section. Ascend's current `device_api_host` suite proves only host-side behavior. Retain Iluvatar coverage and coordinate Kunlunxin IR/linking tests with #164 without claiming unsupported peer-read primitives.

### G2 — CI, Torch and packaging

Examples using the existing platform runner, on separate corresponding hardware environments:

```bash
bash .github/scripts/ci/run_hardware_workload.sh \
  hygon torch-api .github/scripts/set_env/hygon.sh torch-api
bash .github/scripts/ci/run_hardware_workload.sh \
  ascend torch-api .github/scripts/set_env/ascend.sh torch-api
```

**Expected:** The plugin builds and the selected collective/P2P Torch cases execute successfully, with correct results and no hangs. Record the actual PyTorch version loaded by the script; the current CI image is not automatically a PyTorch 2.14 image.

For every counted backend, run its declared suites through the same runner and attach CI links, environment versions and per-suite results. Repeat against the agreed PyTorch targets where a compatible vendor distribution exists; report unavailable combinations explicitly. Verify the built wheel in a clean matching environment with import, backend registration and the same distributed tests. The published-artifact installation command and new-platform commands must be added when those artifacts/PRs exist.

### G3 — Fused collectives

Run separately on the CUDA and Hygon CI machines:

```bash
bash .github/scripts/ci/run_hardware_workload.sh \
  cuda perf-test-experimental .github/scripts/set_env/cuda.sh perf-test-experimental
bash .github/scripts/ci/run_hardware_workload.sh \
  hygon perf-test-experimental .github/scripts/set_env/hygon.sh perf-test-experimental
```

**Expected:** `FlagCXCollTest.AllGatherGemm*` and `FlagCXCollTest.GemmReduceScatter*` pass on all four ranks. The runner checks require the UniRunner kernel path, local P2P and stream-value support; preserve those checks to detect unintended fallback. Related IPC/group error cases must also pass. These are correctness/regression gates, not a measured speedup claim.

The existing `test/perf/host_api/test_allgather_gemm.cpp` and `test_gemm_reducescatter.cpp` benchmarks use FP32 and require `-p 1` for correctness checking. Do not extrapolate those results to FP16/BF16. Add Iluvatar-specific executable cases, physical multi-node runs, agreed workload shapes/dtypes, accuracy tolerances and the exact vendor-native baseline before G3 acceptance. Publish both baseline and FlagCX timings; the planned improvement percentage is still undecided.

### G4 — KV transport and model-level PD

Existing transfer benchmark on two supported GPU hosts. Set `FEP_SERVER_IP` to the server's reachable address on both hosts; use the matching Python bindings and transport dependencies. Start the server first:

```bash
# Server host.
python3 test/perf/kv_transfer/kv_transfer_benchmark.py \
  --connector=flagcx --role=server --remote-ip="$FEP_SERVER_IP" \
  --device=gpu --sizes=1048576,16777216,104857600 --iters=20

# Client host.
python3 test/perf/kv_transfer/kv_transfer_benchmark.py \
  --connector=flagcx --role=client --remote-ip="$FEP_SERVER_IP" \
  --device=gpu --sizes=1048576,16777216,104857600 --iters=20
```

**Expected:** Every tested size reports successful verification, with completed transfers and latency/bandwidth results. Repeat the paired commands with `--connector=mooncake` for a same-direction transport reference. Both use writes; do not compare against a read-based NIXL run as if the operation were identical. The benchmark's GPU allocation uses `torch.cuda`; non-CUDA backends require a compatible or adapted harness before claiming coverage.

**Pending model gate:** Add exact GLM5.2/Qwen3.6 revisions, P/D service launch commands, FlagCX/Mooncake selection, load-generator command, fixed dataset/seed, warmup and repeated-run settings for each named platform. Use PTD (`tools/PTD/`) to diagnose transfer bottlenecks, not as a substitute for end-to-end measurements. GLM requires the agreed >=3% result; Qwen requires functional PD evidence on all five named platforms. Model-level executable recipes and results are not yet available in this draft.

### G5 — GIN/INC feasibility

Existing host-only provider-dispatch regression in a configured build environment:

```bash
make -C test/unittest/device_api USE_NVIDIA=1 provider_test
```

**Expected:** Provider-dispatch assertions pass. This tests the existing dispatch contract only; it does not exercise GIN network traffic or INC.

**Pending:** Define provider selection, hardware/firmware, host/device launch commands, remote-write visibility, signal/wait ordering, completion/error handling and supported INC reductions. Compare INC results with the host reference at an agreed dtype/tolerance. Without those executable tests and hardware results, record design/tooling progress only and defer implementation acceptance.

## Release Gates and Open Decisions

The dates below are the authoritative 2.3 gates, not an admission or delivery commitment for this late proposal. Component planning dates in mid/late December cannot authorize new feature code after November 30.

| Gate | Required decision or evidence |
|---|---|
| November 13 — FEP merge deadline | Missed. Record deferral and the actual target under the release rules. |
| November 30 — feature freeze / rc0 | For scope admitted through the applicable release process: implementation submitted, release source/tag selected, package and manifest versions consistent. |
| December 7 — rc1 | Executable vendor matrix, model launch recipes, performance references and test environments complete. |
| December 14 — rc2 | Integration/regression evidence; unresolved hardware, dtype and model gaps visible. |
| December 25 — code lock | Acceptance verdict and final artifacts; incomplete scope follows the release rules. |
| December 30 — GA | Publish only supported and accepted capabilities; external ecosystem/standards decisions remain separate. |

Before this proposal becomes `Implementable`, confirm the owner, actual release target, G1 primitive subsets, G2 backend/version matrix, G3 performance threshold, G4 five-chip list and metric, and whether G5 has a usable environment. Replace pending test recipes with reviewed executable commands. Developer review and QA sign-off are required; no hardware tests were performed while preparing this FEP.

## Related PRs

Checked entries mean merged implementation PRs, not completed release acceptance.

- [x] [FlagCX #608](https://github.com/flagos-ai/FlagCX/pull/608) — Iluvatar default Device API path.
- [x] [FlagCX #643](https://github.com/flagos-ai/FlagCX/pull/643), [#667](https://github.com/flagos-ai/FlagCX/pull/667) — Hygon Device API/IR and bitcode packaging.
- [x] [FlagCX #676](https://github.com/flagos-ai/FlagCX/pull/676), [#678](https://github.com/flagos-ai/FlagCX/pull/678) — Kunlunxin bitcode and XPU IR entry points.
- [x] [FlagCX #669](https://github.com/flagos-ai/FlagCX/pull/669), [#670](https://github.com/flagos-ai/FlagCX/pull/670) — Ascend and Iluvatar CI.
- [x] [FlagCX #690](https://github.com/flagos-ai/FlagCX/pull/690), [#709](https://github.com/flagos-ai/FlagCX/pull/709) — Torch Python coverage and Ascend Torch tests.
- [x] [FlagCX #697](https://github.com/flagos-ai/FlagCX/pull/697), [#713](https://github.com/flagos-ai/FlagCX/pull/713) — UniRunner fusion and CUDA/Hygon experimental CI.
- [x] [FlagCX #700](https://github.com/flagos-ai/FlagCX/pull/700), [#706](https://github.com/flagos-ai/FlagCX/pull/706) — Ascend IPC/GPU registration and VMM/RMA validation paths.
- [x] [FlagCX #694](https://github.com/flagos-ai/FlagCX/pull/694) — DefaultBackend provider dispatch foundation.
- [ ] [FlagCX #705](https://github.com/flagos-ai/FlagCX/pull/705) — Ascend default backend and staged device smoke tests.
- [ ] [FlagCX #719](https://github.com/flagos-ai/FlagCX/pull/719) — PPU default Device API.
- [ ] [FlagCX #671](https://github.com/flagos-ai/FlagCX/pull/671), [#672](https://github.com/flagos-ai/FlagCX/pull/672), [#675](https://github.com/flagos-ai/FlagCX/pull/675) — Kunlunxin, Enflame and MUSA CI candidates.
- [ ] [FlagCX #695](https://github.com/flagos-ai/FlagCX/pull/695) — HCCL communicator-name interoperability.
- [ ] [FlagCX #707](https://github.com/flagos-ai/FlagCX/pull/707), [#712](https://github.com/flagos-ai/FlagCX/pull/712), [#720](https://github.com/flagos-ai/FlagCX/pull/720) — DUSHMEM, Enflame and MUSA Device API candidates; not additional guaranteed deliverables.

## Implementation History

No release-acceptance milestone recorded. Update after review and implementation acceptance.

[platforms]: https://github.com/flagos-ai/FlagCX/blob/86e8d9bb9b28b1ec5c5fd371feea305cf183b7a5/.github/configs/platforms.yml
[bitcode]: https://github.com/flagos-ai/FlagCX/blob/86e8d9bb9b28b1ec5c5fd371feea305cf183b7a5/docs/device_api_bitcode.md

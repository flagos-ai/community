# FEP-0165: TLE Raw Integration on Five Domestic Accelerator Backends

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Complete [FlagTree](https://github.com/flagos-ai/FlagTree) TLE Raw support on Enflame S60, Iluvatar 150, Huawei Ascend 910B, Hygon BW1000 and Kunlunxin P800. Keep the operator's main computation in Triton/TLE and use Raw calls for device capabilities that require native code or vendor DSLs. Validate each backend with actual operator scenarios, prioritizing Hygon.

## Motivation

Native device functions can fill gaps in Triton/TLE without rewriting an entire operator or adding a new language primitive for every hardware feature. Cross-backend support requires correct argument conversion, toolchain integration, linking and interaction with TLE buffers.

### Goals

- **G1:** Support the five named backend/SKU pairs, including native-code compilation/import or deferred linking as required by the vendor toolchain.
- **G2:** Verify Raw calls within Triton/TLE operators, covering scalar/pointer arguments, tensor results and supported shared-memory interaction.
- **G3:** Provide a representative operator scenario and reproducible correctness/performance results on each backend. Operator list and performance thresholds: TBD.

### Non-Goals

New layout/pipeline optimization-hint APIs, automatic cross-vendor source translation and a standalone Raw operator library.

## Proposal

Use the existing `tle_raw.call(edsl, [...])` path to embed external device code into a Triton kernel. Register the backend dialect/runtime, compile external code with the supported toolchain and lower the call with the surrounding TLE computation. Use deferred import/linking where early LLVM import loses required target attributes or the vendor toolchain requires a later lowering stage.

## Design Details

The common path comprises dialect registration, external-code compilation, a `DSLRegionOp` boundary, argument/result mapping, and inline or deferred lowering. Preserve address spaces, shapes, strides, alignment, buffer ownership and synchronization. Backend code supplies the compilation/linking adapter and supported ABI; common TLE code retains the surrounding operator logic.

| Backend / SKU | Integration | Required validation |
|---|---|---|
| Enflame S60 | TOPS/vendor DSL and deferred route where needed | Raw call plus an operator using the supported device-code path |
| Iluvatar 150 | CUDA-compatible Raw adapter with CoreX toolchain | Raw call, tensor/FP16 support and operator execution |
| Ascend 910B | Ascend Raw adapter | Native call and supported TLE buffer interaction; communication-library integration tracked separately |
| Hygon BW1000 | Deferred HIP bitcode path | `call`/`call_smem`, target-attribute preservation and representative operator; highest priority |
| Kunlunxin P800 | XPU Raw/deferred integration | Argument handling, deferred linking and supported object-file path |

Hygon PR #1345 is an open prototype without CI/performance evidence; completing its test coverage is part of this proposal. Existing integration PRs are reused, with 2.3 acceptance tied to the named SKU and scenario. Do not count vector-add alone as application-level validation.

## Packaging

**Supported vendors:** Enflame S60, Iluvatar 150, Ascend 910B, Hygon BW1000, Kunlunxin P800.

**Wheel:** frontend, adapters and compiler passes ship with FlagTree. Vendor compilers, device libraries and supported object files remain explicit dependencies.

Build a backend-specific FlagTree wheel from the selected release tag, using its documented SDK/LLVM/Python environment and `FLAGTREE_BACKEND` selector where required:

```bash
python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist
```

Record the source tag, Triton line, Python ABI, toolkit versions and wheel checksum. Release tag and dependency pins: TBD.

## Test Plan

### G1–G2: Raw regression and interoperability

Run the applicable commands from the backend's selected FlagTree checkout:

```bash
# NVIDIA regression
python3 python/tutorials/tle/raw/cuda/01-vector-add.py
python3 python/tutorials/tle/raw/cuda/03-matrix-multiplication-smem.py

# Enflame
python3 -m pytest -q third_party/enflame/python/test/tle/raw/tops/test_tops_scripts.py

# Kunlunxin
python3 -m pytest -q third_party/xpu/test/tle_raw
```

For Iluvatar, run the backend tutorial from the matching release checkout:

```bash
python3 third_party/iluvatar/python/tutorials/tle/raw/cuda/02-fused-softmax.py
```

Ascend/Hygon release test commands: TBD. Expected: numerical checks pass, native functions are included in the final kernel, and memory/address-space handling matches the reference. Validate deferred mode independently; unsupported eager mode must fail clearly.

### G3: operator scenarios

For each backend, record the model/operator, shape/dtype, native function, source revision and test command. Compare Triton/TLE+Raw against the current supported implementation with identical inputs; report correctness, latency and resource use. Prioritize a Hygon workload and vendor-provided Iluvatar/Enflame scenarios. Performance targets and remaining commands: TBD.

Use identical hardware, model/operator inputs, dtype, compiler/runtime dependencies and device topology for baseline and candidate. Warm up, synchronize device work, retain at least three measured runs and report per-case results. Kernel speedup is baseline latency divided by candidate latency; decode speedup is candidate output tokens/s divided by baseline output tokens/s. Record failed and skipped cases separately. Dataset, tolerances and performance-case aggregation: TBD.

## Related PRs

- [x] [FlagTree #602](https://github.com/flagos-ai/FlagTree/pull/602) — Enflame integration.
- [x] [FlagTree #1184](https://github.com/flagos-ai/FlagTree/pull/1184) — Iluvatar integration.
- [x] [FlagTree #1238](https://github.com/flagos-ai/FlagTree/pull/1238) — Ascend Raw call interface.
- [ ] [FlagTree #1345](https://github.com/flagos-ai/FlagTree/pull/1345) — Hygon deferred Raw and DUSHMEM examples.
- Kunlunxin integration: [#1155](https://github.com/flagos-ai/FlagTree/pull/1155), [#1330](https://github.com/flagos-ai/FlagTree/pull/1330).
- [ ] Five-platform release acceptance and operator scenarios — TBD.

## Implementation History

- 2026-11-05: Initial FlagOS 2.3 proposal.

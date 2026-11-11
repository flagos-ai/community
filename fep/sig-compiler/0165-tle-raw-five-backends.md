# FEP-0165: TLE Raw Integration on Five Accelerator Backends

**Status:** `Provisional`

**Implementation Status:** `In Progress`

**Created:** 2026-11-05

**Owner:** @i3wanna2

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Complete [FlagTree](https://github.com/flagos-ai/FlagTree) TLE Raw integration on Enflame S60, Iluvatar BI150, Huawei Ascend 910B, Hygon BW1000 and Kunlunxin P800. Enable Triton/TLE kernels to call vendor device code and exchange data with it. Use these calls to supplement TLE in operator workloads, prioritizing Hygon.

## Goals

| Goal | Deliverable |
|---|---|
| G1 — Backend integration | Compile and link vendor device code into Triton/TLE kernels, pass arguments and return or write results through the backend interfaces below. Run the resulting kernels on all five target SKUs. |
| G2 — Operator use | Validate Raw in operator-team workloads that need it to supplement TLE, prioritizing Hygon. Check correctness and compare performance with a vendor-native or agreed reference. The workload list is pending confirmation with the operator teams. |

| Backend / SKU | Source branch | Raw functionality |
|---|---|---|
| Enflame S60 | `main` | TOPS device functions with pointer/scalar and tensor arguments; deferred compilation targeting GCU300. |
| Iluvatar BI150 | `main` | CoreX device functions through `call`/`call_smem`; tensor results, shared-memory buffers and eager/deferred compilation. |
| Huawei Ascend 910B | `triton_v3.5.x` | AscendC device functions through the `cann` dialect and `tle_raw.call`; UB buffers and explicit output operands. |
| Hygon BW1000 | `main` | HIP/MLIR device code through `call`/`call_smem`; shared-memory buffers and eager/deferred compilation. |
| Kunlunxin P800 | `main` | XPU3 device code with pointer/scalar arguments and deferred linking. |

[TLE Raw vendor integration examples](https://jwolpxeehx.feishu.cn/wiki/Ipvbwa1WYintOwkmNzUchJJun0c)

## Packaging

Include TLE Raw in the corresponding FlagTree wheel and publish its examples with the source. Build in the backend's documented SDK environment with its `FLAGTREE_BACKEND` setting:

```bash
python3 -m pip wheel . \
  --no-deps --no-build-isolation --wheel-dir dist
```

## Test Plan

Run the repository tests below from the listed branch with its backend-specific FlagTree installation. Record the device model, source revision, SDK/driver and PyTorch/FlagTree versions. Each target SKU requires numerical device-test results; report compiler-only checks and skips separately.

### G1: backend integration

**Enflame S60:** Run the TOPS examples with the GCU300 target:

```bash
GCU_ARCH=gcu300 python3 -m pytest -q \
  third_party/enflame/python/test/tle/raw/tops/test_tops_scripts.py
```

**Check:** Compile and execute the TOPS functions. Verify vector addition, tensor-argument addition, softmax and matrix multiplication using the scripts' numerical assertions.

**Iluvatar BI150:** Run IR/ABI regressions and device cases:

```bash
python3 -m pytest -q \
  third_party/iluvatar/python/test/unit/tle/test_tle_raw.py \
  third_party/iluvatar/python/test/unit/tle/test_tle_raw_deferred_tutorial.py
```

**Check:** Verify pointer address spaces, tensor results and shared-buffer lowering. Run the device assertions for vector addition, shared-buffer updates, CoreX SME loads and matrix multiplication under eager/deferred compilation.

**Huawei Ascend 910B:** In the `triton_v3.5.x` checkout, configure CANN, `ccec`, `llvm-link` and `torch_npu`, then run:

```bash
python3 python/tutorials/tle/custom/test_dialect_custom_ops.py
python3 python/tutorials/tle/custom/test_custom_ops.py
```

**Check:** Verify int32/FP16 addition through the CANN source-compilation path, including UB staging and output aliasing. Run the built-in Raw operation checks for gather, sort and reduction.

**Hygon BW1000:** In the DTK/HIP environment, run:

```bash
python3 third_party/hcu/python/tutorials/tle/raw/hip/01-vector-add.py
python3 third_party/hcu/python/tutorials/tle/raw/hip/03-matrix-multiplication-smem-defered.py
python3 third_party/hcu/python/tutorials/tle/raw/mlir/01-vector-add-defered.py
python3 third_party/hcu/python/tutorials/tle/raw/mlir/03-matrix-multiplication-smem.py
```

**Check:** Compare HIP/MLIR vector addition and shared-memory matrix multiplication with the scripts' references. The HIP deferred-matmul and MLIR deferred-vector-add scripts each exercise eager and deferred compilation.

**Kunlunxin P800:** Run compiler regressions and the XPU3 device test separately:

```bash
python3 -m pytest -q \
  third_party/xpu/test/tle_raw/test_tle_raw_deferred.py \
  third_party/xpu/test/tle_raw/test_tle_raw_cluster_ir.py

TRITON_XPU_ARCH=3 python3 -m pytest -q \
  third_party/xpu/test/tle_raw/vector_add/test_tle_raw_vector_add.py
```

**Check:** The first two files check Raw registration, signatures and linking without device execution. Use the vector-add device test to check pointer/scalar arguments and output values against PyTorch CPU and Triton references, including partial tiles.

### G2: operator use

Select workloads with the operator teams, prioritizing Hygon and the vendor-provided Iluvatar/Enflame scenarios. For each selected workload, identify the Raw call site and inputs that exercise it, and provide the existing correctness and benchmark commands.

Check results using the operator tests' reference and accuracy tolerances. Compare operator latency with the vendor-native implementation or an agreed reference on the same device, inputs, dtype and runtime environment. Report both latencies.

## Related PRs

- [x] [FlagTree #602](https://github.com/flagos-ai/FlagTree/pull/602) and [#835](https://github.com/flagos-ai/FlagTree/pull/835) — Enflame Raw integration and deferred TOPS compilation.
- [x] [FlagTree #1184](https://github.com/flagos-ai/FlagTree/pull/1184) — Iluvatar Raw integration.
- [x] [FlagTree #1321](https://github.com/flagos-ai/FlagTree/pull/1321) — Backport the Raw foundation to `triton_v3.5.x`.
- [x] [FlagTree #1238](https://github.com/flagos-ai/FlagTree/pull/1238) — Ascend Raw call interface and CANN dialect on `triton_v3.5.x`.
- [x] [FlagTree #1508](https://github.com/flagos-ai/FlagTree/pull/1508) — Hygon HIP/MLIR Raw support and DUSHMEM examples.
- [x] [FlagTree #1155](https://github.com/flagos-ai/FlagTree/pull/1155) and [#1330](https://github.com/flagos-ai/FlagTree/pull/1330) — Kunlunxin Raw integration.
- [x] [FlagGems #6767](https://github.com/flagos-ai/FlagGems/pull/6767) — Kunlunxin reflection-padding object payload.

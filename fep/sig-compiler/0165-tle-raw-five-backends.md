# FEP-0165: TLE Raw Integration on Five Accelerator Backends

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Complete [FlagTree](https://github.com/flagos-ai/FlagTree) TLE Raw integration on Enflame S60, Iluvatar BI150, Huawei Ascend 910B, Hygon BW1000 and Kunlunxin P800. Allow Triton/TLE operators to call vendor device code for capabilities missing from the language. Validate the integration through Raw-using operator workloads, prioritizing Hygon.

## Goals

| Goal | Deliverable |
|---|---|
| G1 — Backend integration | Compile and link vendor device code into Triton/TLE kernels on all five target SKUs. |
| G2 — Interoperability | Validate argument passing, output aliasing and the buffer interfaces supported by each backend, including eager/deferred compilation where implemented. |
| G3 — Operator workloads | Validate correctness and measure performance of Raw-using operators on each target SKU. The release workload list and performance thresholds remain to be agreed with the operator teams. |

| Backend / SKU | Source branch | Integration and test requirements |
|---|---|---|
| Enflame S60 | `main` | TOPS device code through deferred Raw calls; scalar/pointer and tensor arguments. Select the GCU300 target. |
| Iluvatar BI150 | `main` | CoreX device code; `call`/`call_smem`, tensor results and eager/deferred compilation. |
| Huawei Ascend 910B | `triton_v3.5.x` | AscendC source/bitcode through `@dialect(name="cann")` and `tle_raw.call`; UB buffers and explicit output operands. `call_smem` is unsupported. |
| Hygon BW1000 | `main` | HIP/MLIR through `call`/`call_smem`, eager/deferred compilation and DUSHMEM library calls. |
| Kunlunxin P800 | `main` | XPU3 native source and object payloads; pointer/scalar arguments, deferred linking and device execution. |

## Packaging

Ship Raw frontends, backend adapters and compiler passes in the corresponding FlagTree wheel. Use the backend's documented SDK environment and `FLAGTREE_BACKEND` setting; leave it unset for NVIDIA/AMD builds.

```bash
python3 -m pip wheel . \
  --no-deps --no-build-isolation --wheel-dir dist
```

Publish the matching source and backend examples. Record the source revision, Triton version, Python ABI, vendor compiler/runtime versions and required device libraries or object payloads.

## Test Plan

Use the same image and source revisions for development and QA on each backend. Record the device model, card count, SDK/driver, PyTorch/FlagTree versions and external-code dependencies. Run commands from the branch listed above with its backend-specific FlagTree installation. Record executed cases and skips. Required device cases must execute on the named SKU; skipped or compile-only cases do not establish device support.

### G1–G2: compilation and device interoperability

Run the shared source-cache regression in the Iluvatar environment with MLIR Python bindings:

```bash
python3 -m pytest -q python/test/tle/unit/test_tle_raw_cache_key.py
```

**Expected:** Source and dialect-metadata changes update the cache key. These are host-side checks. For each backend, also verify that changing its native source or payload rebuilds the kernel.

**Enflame S60:** Run the TOPS examples with the GCU300 target:

```bash
GCU_ARCH=gcu300 python3 -m pytest -q \
  third_party/enflame/python/test/tle/raw/tops/test_tops_scripts.py
```

**Expected:** Vector addition, tensor-argument addition, softmax and matrix multiplication pass their numerical checks after deferred TOPS compilation.

**Iluvatar BI150:** Run IR/ABI regressions and device cases:

```bash
python3 -m pytest -q \
  third_party/iluvatar/python/test/unit/tle/test_tle_raw.py \
  third_party/iluvatar/python/test/unit/tle/test_tle_raw_deferred_tutorial.py
```

**Expected:** Pointer address spaces, tensor returns and shared-buffer descriptors lower correctly. Device cases verify vector addition, shared-buffer updates, CoreX-native SME loads and eager/deferred matrix multiplication against their references.

**Huawei Ascend 910B:** In the `triton_v3.5.x` checkout, configure CANN, `ccec`, `llvm-link` and `torch_npu`, then run:

```bash
python3 python/tutorials/tle/custom/test_dialect_custom_ops.py
python3 python/tutorials/tle/custom/test_custom_ops.py
```

**Expected:** Source-JIT addition passes for int32 and FP16, including UB staging and output aliasing. Built-in Raw operations pass the gather, sort, reduction and related checks. Add a corresponding precompiled-bitcode case before accepting that input format.

**Hygon BW1000:** In the DTK/HIP environment, run:

```bash
python3 third_party/hcu/python/tutorials/tle/raw/hip/01-vector-add.py
python3 third_party/hcu/python/tutorials/tle/raw/hip/03-matrix-multiplication-smem-defered.py
python3 third_party/hcu/python/tutorials/tle/raw/mlir/01-vector-add-defered.py
python3 third_party/hcu/python/tutorials/tle/raw/mlir/03-matrix-multiplication-smem.py
```

**Expected:** HIP/MLIR vector addition and shared-memory matrix multiplication match their references. The HIP deferred-matmul and MLIR deferred-vector-add scripts each exercise both eager and deferred compilation.

For DUSHMEM interoperability, provide matching host/device libraries, device bitcode for the target architecture and two visible BW1000 devices:

```bash
source /opt/dtk/env.sh
export LD_LIBRARY_PATH="/opt/dtk/lib/dushmem:${LD_LIBRARY_PATH:-}"
unset DUSHMEM_BOOTSTRAP
torchrun --standalone --nproc-per-node=2 \
  third_party/hcu/python/tutorials/tle/raw/dushmem/01-simple-shift/simple-shift.py
```

**Expected:** Both ranks pass the ring-shift check through a Raw device-library call. The existing distributed CI uses BW1100; BW1000 results are required here.

**Kunlunxin P800:** Run compiler regressions and the XPU3 device test separately:

```bash
python3 -m pytest -q \
  third_party/xpu/test/tle_raw/test_tle_raw_deferred.py \
  third_party/xpu/test/tle_raw/test_tle_raw_cluster_ir.py

TRITON_XPU_ARCH=3 python3 -m pytest -q \
  third_party/xpu/test/tle_raw/vector_add/test_tle_raw_vector_add.py
```

**Expected:** Compiler tests check payload registration, cache keys, signatures and linking. Device vector addition matches a PyTorch CPU reference and the equivalent Triton kernel, including partial tiles. Add device coverage for the object-payload path using a Raw-using operator.

### G3: operator correctness and performance

Agree release workloads and performance thresholds with the operator teams, prioritizing Hygon and vendor-provided Iluvatar/Enflame scenarios. For each backend/operator pair, provide the source revision, Raw call site, external function or payload, shapes/dtypes, reference, accuracy tolerance and test command.

Kunlunxin's FlagGems `reflection_pad1d` is an existing object-payload candidate. Use valid nonzero reflection padding and at least 262,144 output elements; retain a device trace showing `pad1d_raw_edges_kernel` executes. Its fallback paths must not count as Raw coverage. Confirm workload coverage for the other backends before acceptance.

Compare with the vendor-native implementation or an agreed equivalent reference on the same device, inputs, precision and runtime environment. Reuse operator-team correctness and benchmark cases. Where an equivalent pre-Raw implementation exists, also compare against it.

For Hygon, reproduce the deferred-mode HIP SGEMM comparison reported in #1508's review against [#1345](https://github.com/flagos-ai/FlagTree/pull/1345) (closed, unmerged). Obtain and pin the original benchmark script, shapes, dtype and toolchain first; these are not specified in the review.

**Expected:** Numerical checks pass at the agreed tolerances, and the selected Raw path executes. Record warmed-up operator latency for both implementations and report `reference latency / Raw-using operator latency` per workload. Record compilation time separately.

## Related PRs

- [x] [FlagTree #602](https://github.com/flagos-ai/FlagTree/pull/602) and [#835](https://github.com/flagos-ai/FlagTree/pull/835) — Enflame Raw integration and deferred TOPS compilation.
- [x] [FlagTree #1184](https://github.com/flagos-ai/FlagTree/pull/1184) — Iluvatar Raw integration.
- [x] [FlagTree #1321](https://github.com/flagos-ai/FlagTree/pull/1321) — Backport the Raw foundation to `triton_v3.5.x`.
- [x] [FlagTree #1238](https://github.com/flagos-ai/FlagTree/pull/1238) — Ascend Raw call interface and CANN dialect on `triton_v3.5.x`.
- [x] [FlagTree #1508](https://github.com/flagos-ai/FlagTree/pull/1508) — Hygon HIP/MLIR Raw support and DUSHMEM examples.
- [x] [FlagTree #1155](https://github.com/flagos-ai/FlagTree/pull/1155) and [#1330](https://github.com/flagos-ai/FlagTree/pull/1330) — Kunlunxin Raw integration.
- [x] [FlagGems #6767](https://github.com/flagos-ai/FlagGems/pull/6767) — Kunlunxin reflection-padding object payload.

# FEP-0148: Torch-FL Coverage and Execution Capabilities

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** TODO: @github-username

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Extend Torch-FL with HF architecture coverage on seven domestic platforms, FlagGems C++ dispatch, low-bit dtype emulation in Beta and an FSDP2 optimization experiment. Each feature has a separate capability matrix and acceptance criteria.

Repository: [Torch-FL](https://github.com/flagos-ai/Torch-FL).

## Motivation

[FEP-0088](0088-pytorch-plugin-fl-flagos-2.2-features.md) covers earlier Transformers/Diffusers inference and simple fine-tuning. Torch-FL also has C++ routing and FSDP2 support. This release expands tested coverage, specifies the C++ operator subset, adds bounded low-bit emulation and evaluates a selected FSDP2 optimization.

### Goals

- **G1 — HF coverage:** Validate each required architecture/platform row on MetaX, T-Head, Hygon, Ascend, Moore Threads, Enflame and Kunlunxin. Cover transfer, forward, backward/optimizer and generation where applicable.
- **G2 — C++ dispatch:** Deliver the selected operator-overload/platform set and native artifacts. Verify routing, numerical/dtype/aliasing/mutation behavior and fallback; compare end-to-end performance with Python dispatch.
- **G3 — Low-bit Beta:** Define formats and storage/compute semantics, implement the selected conversion/operator subset, and validate rounding, saturation, special values and serialization against independent references.
- **G4 — FSDP2 Experimental:** Implement an opt-in optimization for Qwen3-30B on MetaX and Hygon. Preserve sharding, gradients and checkpoints; publish paired performance results and an adoption decision.

### Non-Goals

Future HF versions outside the pinned inventory, seven-vendor C++ coverage, native low-bit acceleration, new-chip admission and FlagOS-Robo FSDP2 work.

## Proposal

### Feature 1: HF coverage

Users consult a versioned architecture/platform table and run the corresponding tests. Results distinguish missing dependencies, invalid configurations, unsupported capabilities and backend failures.

### Feature 2: C++ dispatch

Users select a C++-enabled wheel and dispatch configuration. The build record lists available routes; diagnostics identify the active route or fallback.

### Feature 3: Low-bit emulation

Users opt into a supported dtype/operation combination. The API specifies storage and compute precision and rejects unsupported combinations.

### Feature 4: FSDP2 optimization

Users run the same training recipe with the optimization enabled or disabled. The baseline path remains available.

## Design Details

### HF inventory and tests

Pin the Transformers revision and architecture inventory. The existing inventory has 511 named Transformers entries; reconcile it with that revision before testing. Fix applicability rules in advance. A failed required case remains in the denominator. Diffusers, if included, requires a separate inventory.

Run architectures in isolated processes. Combine the existing probe with version-matched official tests and full-size reference workloads. Record transfer, forward, backward/update and generation results separately. Tiny-model success does not establish full-size memory capacity.

### C++ dispatch

Define routes at ATen-overload granularity. Pin PyTorch/C++ ABI, compiler and kernel libraries. Preserve existing routes outside the selected subset. Read the wheel's `KERNELS` record and verify runtime routing. Compare Python and C++ wrappers with the same kernels, model and runtime.

### Low-bit emulation

Separate storage representation from compute dtype. Specify scale metadata, operations that materialize higher precision, backward support and serialization version. Disabling emulation preserves ordinary dtype behavior.

### FSDP2 optimization

Profile the baseline before selecting changes to sharding, collective scheduling or memory lifetime. Fix the model revision, data, precision, global batch, topology and communication backend. Compare steady-state step time, tokens/s and peak memory, and verify gradients, loss and checkpoint resume. Set the performance criterion before the paired experiment.

**Dependencies:** FlagGems; FlagTree for required compilation paths; FlagCX if the FSDP2 change affects communication. Existing compile coverage differs by platform and does not establish full HF compile support.

**Open decisions:** HF revisions, inventory and applicability rules; C++ overload/platform list; low-bit formats, API and backward scope; exact Qwen3-30B checkpoint; FSDP2 strategy/topology; per-feature quality and performance limits.

## Packaging

**Supported vendors:** HF: MetaX C550, T-Head ZW810E, Hygon BW1000, Ascend 910C, Moore Threads S5000, Enflame S60 and Kunlunxin P800 are the device candidates. C++ and low-bit subsets are pending. FSDP2 targets MetaX and Hygon; device/topology pending.

**Can this feature be packaged as a wheel (`.whl`)?** Yes.

Build per-platform wheels with `python -m build --wheel --no-isolation`, following `.github/workflows/build-wheel-common.yml` in the prepared vendor environment. For supported C++ platforms, use `FLAGOS_BUILD_FLAGGEMS_CPP=ON python -m build --wheel --no-isolation` and include the matching native library and ABI settings. The generated build record must list the C++ route.

Package HF version locks and the architecture inventory, low-bit format specifications/examples, and paired FSDP2 configurations. Version any changed communication artifact separately.

**Build record:** Pin Python/PyTorch, framework, operator/compiler libraries, SDK/driver and native ABI as applicable. Record source revisions, build configuration and artifact digest.

At Feature Freeze, provide the module rc0 branch and tag with matching tag, manifest and package-metadata versions.

## Test Plan

Tests marked Proposed remain to be implemented. Run each case against the specified artifact and matrix configuration, and retain its command and results. Set `FEP_ARCH` to the Transformers model-type key in the inventory and `FEP_REPORT` to a distinct JSON output path for each architecture/platform run.

### Feature 1 / G1: Existing inventory command

```bash
python tests/manual/transformers_model_probe.py --list-models
```

**Expected result:** The output matches the pinned Transformers revision and is reconciled with the architecture inventory.

### Feature 1 / G1: Existing probe, repeated per approved architecture/platform

```bash
TORCH_DEVICE_BACKEND_AUTOLOAD=0 python tests/manual/transformers_model_probe.py --model "$FEP_ARCH" --device flagos --out "$FEP_REPORT"
```

**Expected result:** Applicable probe stages pass against the CPU reference; reports identify the active device, routes and environment.

### Feature 1 / G1: Proposed acceptance driver wrapping the existing official HF runner

```bash
python tests/acceptance_flagos23/evaluate_hf_architectures.py --matrix acceptance/flagos23/hf-architectures.yaml
```

**Expected result:** Every required architecture/platform row runs version-matched official tests and required workload checks. Missing or skipped required rows prevent a complete-coverage claim.

### Feature 2 / G2: Existing operator tests

```bash
python -m pytest tests/integration/ops/ -m "flaggems_cpp and main_ops" -v
```

**Expected result:** Required C++ cases are collected and pass; a wheel that causes them all to skip fails the C++ acceptance goal.

### Feature 2 / G2: Proposed acceptance test extending coverage beyond the smoke subset

```bash
python -m pytest tests/acceptance_flagos23/test_cpp_route_contract.py -v
```

**Expected result:** All declared overloads, including out/in-place variants where supported, use the intended C++ route and preserve the API contract.

### Feature 2 / G2: Proposed paired benchmark driver

```bash
python tests/acceptance_flagos23/evaluate_cpp_dispatch.py --matrix acceptance/flagos23/cpp-dispatch.yaml
```

**Expected result:** Numerically valid paired runs report model latency/throughput and routing evidence; accepted gains and regression limits use the frozen workload-specific gates.

### Feature 3 / G3: Proposed acceptance test

```bash
python -m pytest tests/acceptance_flagos23/test_low_bit_emulation.py -v
```

**Expected result:** Encode/decode, rounding boundaries, saturation and declared special values match the chosen reference; supported operators satisfy the stated numerical semantics.

### Feature 3 / G3: Proposed acceptance test

```bash
python -m pytest tests/acceptance_flagos23/test_low_bit_serialization.py -v
```

**Expected result:** Metadata and tensor semantics survive round trips; incompatible formats and undeclared operations fail explicitly. Ordinary dtype regression cases still pass.

### Feature 4 / G4: Proposed acceptance test

```bash
python -m pytest tests/acceptance_flagos23/test_fsdp2_optimization_contract.py -v
```

**Expected result:** The declared strategy preserves sharding, gradient and checkpoint semantics; disabling it restores the baseline path.

### Feature 4 / G4: Proposed distributed acceptance driver

```bash
python tests/acceptance_flagos23/evaluate_fsdp2.py --matrix acceptance/flagos23/fsdp2-qwen3-30b.yaml
```

**Expected result:** Both vendor runs report correctness, step time, tokens/s and peak memory against the baseline, with an adoption decision against the agreed criterion.

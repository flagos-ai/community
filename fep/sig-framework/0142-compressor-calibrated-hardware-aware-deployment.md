# FEP-0142: Calibrated Quantization and Hardware-aware Deployment

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** TODO: @github-username

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Bring GPTQ, AWQ and native AutoRound into FlagOS 2.3 release acceptance. Version calibration inputs, qualify module-specific precision policies, and add target hardware profiles. Validate exported models on NVIDIA and selected domestic serving platforms.

Repository: [FlagOS-Compressor](https://github.com/flagos-ai/FlagOS-Compressor).

## Motivation

[FEP-0091](0091-flagos-compressor-first-release.md) limits 2.2 acceptance to `release/v0.1.0` at `eecf2fa` and excludes calibration-dataset-based methods. That baseline already includes module selection, YAML recipes and inspect/quantize/validate commands. This release qualifies the existing calibrated methods and connects their exports to model-quality and serving tests.

### Goals

- **G1 — Calibration:** Validate GPTQ, AWQ and native AutoRound with fixed datasets, settings and seeds. Record the method and precision policy applied to each selected tensor/module and reproduce the export.
- **G2 — Deployment:** Provide profiles for NVIDIA and selected domestic targets, including an NPU. Reject unsupported recipe/layout/kernel combinations and verify model loading and inference for each required model/profile pair.
- **G3 — Model results:** Compare selected Qwen3.5/Qwen3.6 variants with BF16 references. Measure weight-file size, accuracy, memory, throughput and latency. Target weight-size reductions above 40% for INT8 and 60% for INT4, including scales, packing metadata and retained high-precision weights. Proposed accuracy limits are 1 and 3 percentage points respectively, pending confirmation.

### Non-Goals

Quantization-aware training, universal model/backend coverage and NPU calibration support inferred from NPU serving support.

## Proposal

Users inspect a checkpoint, select a recipe and hardware profile, run calibration and quantization, then validate and deploy the exported model. The output records the calibration data, seed, method, tensor precision, retained high-precision weights and target format. Each profile includes a matching serving configuration.

## Design Details

### Calibration and precision policy

Keep model-layout conversion separate from calibration and bit allocation. Validate fused MoE tensors and sensitive-module exclusions before export. Retain existing MSE and conversion tests as regressions.

Compute weight reduction as `1 - exported_weight_bytes / BF16_weight_bytes` over the same tensor set. Count scales, packing metadata and retained weights. Report selected-tensor and whole-model reductions separately. Compare task accuracy with identical evaluation data and inference settings.

### Hardware profiles

A profile specifies serving-stack revision, supported tensor layouts, group sizes, scale formats and required kernels. Validate the recipe against these capabilities and record any permitted fallback. Export validation is followed by loading and inference on the target device.

Record quantization device and inference device separately. CPU/CUDA conversion remains independent of target-specific serving profiles.

**Dependencies:** Serving-plugin maintainers and sig-operator for compatible kernels and formats.

**Open decisions:** Model/checkpoint revisions; calibration and evaluation data; method/format combinations; profile schema; target devices and NPU model; serving versions; quality and performance limits.

## Packaging

**Supported vendors:** Existing CPU/NVIDIA quantization paths; NVIDIA and selected domestic serving devices. The NPU model and serving stack remain pending.

**Can this feature be packaged as a wheel (`.whl`)?** Yes.

Build with `python -m build --wheel`. Package recipes, calibration specifications, tensor policies, hardware profiles, export schemas and deployment examples. Preserve the CLI entry point. Record serving-plugin and kernel artifacts separately from the Compressor wheel.

**Build record:** Pin Python/PyTorch, framework, operator/compiler libraries, SDK/driver and native ABI as applicable. Record source revisions, build configuration and artifact digest.

At Feature Freeze, provide the module rc0 branch and tag with matching tag, manifest and package-metadata versions.

## Test Plan

Tests marked Proposed remain to be implemented. Run each case against the specified artifact and matrix configuration, and retain its command and results.

### G1: Existing calibrated-method tests

```bash
python -m pytest tests/test_gptq_quantization.py tests/test_awq_quantization.py tests/test_autoround.py tests/test_autoround_integration.py -v
```

**Expected result:** All calibrated-method correctness cases pass on the selected release artifact.

### G1: Existing tests

```bash
python -m pytest tests/test_recipe.py tests/test_policy_planner.py tests/test_native_export.py -v
```

**Expected result:** Recipes resolve deterministically, incompatible layouts are rejected and export metadata matches effective policy.

### G1-G3: Proposed acceptance driver

```bash
python tests/acceptance_flagos23/evaluate_calibrated_quantization.py --matrix acceptance/flagos23/calibrated-quantization.yaml
```

**Expected result:** Each model/method/bitwidth row reproduces calibration and export with the pinned dataset, settings and seed. Compare weight size and accuracy with BF16; report INT8 >40% and INT4 >60% size reduction and the proposed accuracy-loss limits separately.

### G2: Proposed acceptance test

```bash
python -m pytest tests/acceptance_flagos23/test_hardware_profiles.py -v
```

**Expected result:** Supported combinations resolve to the expected format; incompatible dtype, scale, group or layout combinations fail with a diagnostic.

### G2-G3: Proposed cross-repository acceptance driver

```bash
python tests/acceptance_flagos23/evaluate_target_deployment.py --matrix acceptance/flagos23/target-deployment.yaml
```

**Expected result:** Every declared model/profile loads and runs on its actual target device; the report includes effective kernel path, accuracy, peak memory, throughput, TTFT and TPOT.

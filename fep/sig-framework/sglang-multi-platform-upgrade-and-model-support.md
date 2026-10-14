# FEP-NNNN: SGLang Multi-platform Upgrade and Model Support

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** TODO: @github-username

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Release three SGLang capabilities: the planned 0.5.18 platform upgrade, Empty-mode support on seven additional vendors using the selected 0.5.11/0.5.12 base, and DeepSeek-V4 W8A8 inference on 0.5.18. Each feature has its own artifacts, dependency versions and test matrix.

Repository: [sglang-plugin-FL](https://github.com/flagos-ai/sglang-plugin-FL).

## Motivation

[FEP-0090](0090-sglang-plugin-fl-flagos-2.2-features.md) provides the 0.5.11/0.5.12 baseline and initial Empty-mode coverage. This release extends platform coverage, updates upstream integration and adds the selected W8A8 model configurations.

### Goals

- **G1 — Platform upgrade:** Validate the 0.5.18 upstream/plugin/SDK combination on ten vendor/device rows including NVIDIA, preserving inference and serving behavior.
- **G2 — Empty mode:** Validate seven additional vendors, including Hygon, Iluvatar and Enflame, with Qwen3.6-27B and Qwen3.6-35B-A3B on the selected 0.5.11/0.5.12 base. Verify operator coverage, accuracy and dispatch.
- **G3 — W8A8:** Validate DeepSeek-V4-Flash and DeepSeek-V4-Pro W8A8 on NVIDIA and at least one domestic platform. Report quality, memory, throughput and latency. A 10% NVIDIA throughput improvement is a stretch target.

### Non-Goals

Reimplementing Empty mode, SGLang 0.5.19 and PD disaggregation.

## Proposal

### Feature 1: Platform upgrade

Users select a 0.5.18 platform package and retain the existing plugin entry point.

### Feature 2: Empty mode

Users run the device-decoupled SGLang build with the FL plugin, vendor runtime and matching operator package. A model/platform row requires all operators needed by that workload.

### Feature 3: W8A8 inference

Users select a supported W8A8 checkpoint and serving configuration. The plugin selects compatible kernels and rejects unsupported checkpoint/kernel combinations.

## Design Details

Keep the three matrices separate. The 0.5.18 upgrade does not rebase the Empty-mode feature, and a vendor in one matrix need not support the other features. Each row records model revision, upstream/plugin versions, SDKs, precision, parallelism and device.

### Feature 1

Update plugin adapters for upstream API changes, run existing regressions and retain the previous validated package for rollback. Freeze upstream patches and SDK versions with FlagGems, FlagTree and SVT/quality. Map each row to a device and execution method; reconcile these rows with FlagCICD coverage.

### Feature 2

Derive the operator list from both model graphs. The operator library supplies implementations; the plugin integrates dispatch. Record the backend for each required operation. Missing operators and forbidden fallbacks fail the case.

### Feature 3

Match checkpoint layout and scales to attention/MoE kernels and tensor parallelism. Compare optimization enabled and disabled with identical weights, prompt/output lengths, precision, batch/concurrency, graph mode and hardware. Measure output tokens/s, TTFT, TPOT, memory and accuracy after warm-up, using repeated runs. Report NVIDIA and domestic results separately.

**Dependencies:** FlagGems/flaggems-sglang, required FlagTree paths, vendor SDKs and checkpoint formats. Coordinate domestic attention kernels with sig-operator.

**Open decisions:** Vendor/device lists for each feature; exact upstream patches; Qwen3.6 and DeepSeek-V4 checkpoint IDs/revisions; Empty-mode operator package; SDK pins; TP settings; quality and regression limits. Reconcile the model identifiers with the training proposal's Qwen3.5 workloads.

## Packaging

**Supported vendors:** Feature 1: ten vendors including NVIDIA. Feature 2: seven additional vendors including Hygon, Iluvatar and Enflame. Feature 3: NVIDIA and at least one domestic vendor. Remaining names and devices are pending.

**Can this feature be packaged as a wheel (`.whl`)?** Yes.

Build with `python -m build --wheel`, following `.github/workflows/_build_wheel.yml`. Publish version-specific plugin wheels and dependency locks. Empty-mode packages use the selected 0.5.11/0.5.12 base; upgrade and W8A8 packages use 0.5.18. Include checkpoint formats, scales and serving-kernel requirements for W8A8.

**Build record:** Pin Python/PyTorch, framework, operator/compiler libraries, SDK/driver and native ABI as applicable. Record source revisions, build configuration and artifact digest.

At Feature Freeze, provide the module rc0 branch and tag with matching tag, manifest and package-metadata versions.

## Test Plan

Tests marked Proposed remain to be implemented. Run each case against the specified artifact and matrix configuration, and retain its command and results. Set `FEP_PLATFORM` and `FEP_DEVICE` from that configuration.

### Feature 1 / G1: Existing runner

```bash
python tests/run.py --platform "$FEP_PLATFORM" --device "$FEP_DEVICE" --scope functional
```

**Expected result:** Every selected operation, compilation and distributed case passes on each declared platform.

### Feature 1 / G1: Existing runner

```bash
python tests/run.py --platform "$FEP_PLATFORM" --device "$FEP_DEVICE" --scope e2e
```

**Expected result:** The frozen regression model list passes inference, serving and applicable concurrency checks with versioned accuracy thresholds.

### Feature 1 / G1: Proposed acceptance test

```bash
python -m pytest tests/acceptance_flagos23/test_sglang_release_manifest.py -v
```

**Expected result:** The ten accepted rows resolve to the frozen release artifacts and their evidence; manifest versions match package metadata.

### Feature 2 / G2: Existing runner; model cases must be bound to both named models

```bash
python tests/run.py --platform "$FEP_PLATFORM" --device "$FEP_DEVICE" --scope e2e
```

**Expected result:** Both models complete the configured inference/serving workloads on every declared new vendor.

### Feature 2 / G2: Proposed acceptance test

```bash
python -m pytest tests/acceptance_flagos23/test_sglang_empty_operator_routes.py -v
```

**Expected result:** All required operators use the permitted implementations; unavailable required operators and forbidden fallback paths fail the case.

### Feature 2 / G2: Proposed acceptance test

```bash
python -m pytest tests/acceptance_flagos23/test_sglang_empty_accuracy.py -v
```

**Expected result:** Outputs and task scores meet the frozen reference/tolerance for each model; skips and unresolved operators remain uncovered.

### Feature 3 / G3: Proposed acceptance test

```bash
python -m pytest tests/acceptance_flagos23/test_deepseek_v4_w8a8.py -v
```

**Expected result:** Both model variants load with the intended W8A8 kernel paths and pass task accuracy and TP consistency gates on each declared platform.

### Feature 3 / G3: Proposed acceptance driver

```bash
python tests/acceptance_flagos23/benchmark_deepseek_v4_w8a8.py --matrix acceptance/flagos23/deepseek-v4-w8a8.yaml
```

**Expected result:** Report paired end-to-end baseline/optimized metrics, variability and throughput ratio. State whether the NVIDIA stretch target of 1.10x is met; report domestic results separately.

Run each feature with its own version, resolved model revision and platform configuration.

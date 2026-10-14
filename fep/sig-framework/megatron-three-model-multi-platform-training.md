# FEP-NNNN: Three-model Multi-platform Training in Megatron-LM-FL

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** TODO: @github-username

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Support Qwen3.5-27B, Qwen3.5-35B-A3B and DeepSeek-V4-Flash-Base training on three vendor platforms. Publish model/platform recipes, correctness and performance results, and matching FlagScale configurations.

Repository: [Megatron-LM-FL](https://github.com/flagos-ai/Megatron-LM-FL).

## Motivation

[FEP-0086](0086-megatron-lm-fl-flagos-2.2-new-features.md) records Qwen3.5/3.6 and GLM5-family DSA work; DeepSeek-V4 base support predates 2.3. This release validates the selected model sizes and platform combinations and exposes them through reproducible training recipes.

### Goals

- **G1:** Complete the three-model by three-platform matrix with fixed checkpoint/configuration, precision and parallelism.
- **G2:** Validate forward/backward computation, optimizer updates, finite loss, numerical agreement and checkpoint save/resume.
- **G3:** Publish comparable throughput, step-time and peak-memory results using fixed data, batch semantics, topology and baseline configurations.
- **G4:** Register the accepted training configurations in FlagScale and verify its invocation.

### Non-Goals

An additional upstream version upgrade, unlisted low-precision training and additional model families.

## Proposal

Users select a model/platform recipe in Megatron-LM-FL or FlagScale and run the documented training workload. Both entry points use the same model configuration and component versions.

## Design Details

Adapt checkpoint conversion and model configuration to the selected Megatron and TE interfaces. Keep model-specific changes separate and preserve supported checkpoint formats.

Each recipe fixes data revision, sequence length, global/micro batch, training steps, TP/PP/DP/EP settings and topology. Compare outputs, gradients and loss against the reference. Test checkpoint resume against uninterrupted training. Measure steady-state throughput, step time and peak memory under matching workload and batch semantics.

Register the new cases in FlagScale's test configuration. Link a TE migration dependency only for rows that require the new plugin architecture.

**Dependencies:** FlagScale integration, TE, required distributed communication and model kernels; coordinate across sig-training, sig-network and sig-operator as applicable.

**Open decisions:** Three vendors/devices; model and data revisions; parallelism and node count; run duration; numerical limits; performance baselines and any required regression thresholds; FlagScale case registration.

## Packaging

**Supported vendors:** Three vendor/device combinations, pending selection.

**Can this feature be packaged as a wheel (`.whl`)?** Yes.

Build with `python -m build`, following `.github/workflows/_build_test_publish_wheel.yml`. Package the training recipes and their source/dependency manifest. Version FlagScale and TE artifacts separately.

**Build record:** Pin Python/PyTorch, framework, operator/compiler libraries, SDK/driver and native ABI as applicable. Record source revisions, build configuration and artifact digest.

At Feature Freeze, provide the module rc0 branch and tag with matching tag, manifest and package-metadata versions.

## Test Plan

Tests marked Proposed remain to be implemented. Run each case against the specified artifact and matrix configuration, and retain its command and results. Set `FEP_PLATFORM` and `FEP_DEVICE` from that configuration.

### G1-G3: Proposed model-matrix acceptance driver

```bash
python tests/acceptance_flagos23/evaluate_training_matrix.py --matrix acceptance/flagos23/three-model-training.yaml
```

**Expected result:** All nine model/platform pairs meet output, gradient, optimizer-update, loss and checkpoint save/resume requirements. Each report includes throughput, step time and peak memory against the fixed baseline, plus any agreed regression limit.

### G4: Existing FlagScale command, run from the FlagScale repository with these new cases registered

```bash
bash tests/test_utils/runners/run_tests.sh --platform "$FEP_PLATFORM" --device "$FEP_DEVICE" --type functional --task train
```

**Expected result:** The registered configurations execute all three target models on their selected platforms and reproduce the Megatron acceptance results.

# FEP-NNNN: First Release of the LightX2V Multi-chip Generation Plugin

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** TODO: @github-username

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Introduce a LightX2V FL plugin for image/video generation on NVIDIA and five domestic vendors, targeting Qwen-Image-2.1, Minimax H3 and Wan 2.1/2.2 T2V. This FEP also proposes admission of the new module and repository.

Repository: TODO.

## Motivation

The plugin needs model adapters, device dispatch and compatible kernels across the selected platforms. Its first release will provide reproducible generation workloads and compare quality and speed with native vendor torch+diffusers implementations.

### Goals

- **G1:** Publish the plugin repository, package and integration interface for the selected LightX2V version.
- **G2:** Validate the target models on the supported model/device matrix.
- **G3:** Measure generation speed against native vendor torch+diffusers while meeting per-model quality requirements.

### Non-Goals

Models or devices outside the matrix and a uniform acceleration factor across platforms.

## Proposal

Users enable the FL plugin through a documented LightX2V generation entry point and select a model/device configuration. The plugin chooses the backend and reports the operator implementations used.

## Design Details

Separate upstream generation orchestration, FL model/backend adapters and operator implementations. Define checkpoint compatibility, attention/quantization settings and unsupported combinations.

For each model, fix prompts, seeds, resolution, inference steps and video frame count/FPS. Compare output quality before evaluating speed. Run the native torch+diffusers reference with the same workload and record latency and peak memory.

**Dependencies:** LightX2V APIs, vendor runtimes and model kernels. Compiler dependencies depend on the selected kernels and build paths.

**Open decisions:** Repository and package name; upstream version; exact checkpoint IDs for the target model names; model/device matrix; quality metrics and limits; performance targets; SDK and wheel requirements.

## Packaging

**Supported vendors:** NVIDIA, T-Head, Hygon, Moore Threads, Huawei Ascend and Kunlunxin. Device models and supported model/device combinations are pending.

**Can this feature be packaged as a wheel (`.whl`)?** Yes; the plugin build is proposed.

Implement a wheel build using `python -m build --wheel`. Build native/kernel dependencies separately. Include model configurations, the upstream version pin and per-vendor build recipes. Repository metadata and build scripts remain to be added.

**Build record:** Pin Python/PyTorch, framework, operator/compiler libraries, SDK/driver and native ABI as applicable. Record source revisions, build configuration and artifact digest.

At Feature Freeze, provide the module rc0 branch and tag with matching tag, manifest and package-metadata versions.

## Test Plan

Tests marked Proposed remain to be implemented. Run each case against the specified artifact and matrix configuration, and retain its command and results.

### G1: Proposed plugin acceptance test

```bash
python -m pytest tests/acceptance_flagos23/test_lightx2v_plugin_contract.py -v
```

**Expected result:** The plugin registers against the pinned upstream, selects the requested backend and rejects incompatible versions.

### G2-G3: Proposed acceptance driver

```bash
python tests/acceptance_flagos23/evaluate_generation.py --matrix acceptance/flagos23/generation.yaml
```

**Expected result:** Each declared model/device case emits the expected image or video shape/frame count, meets frozen quality gates, and reports latency, memory and native-baseline speed ratio.

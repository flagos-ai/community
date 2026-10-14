# FEP-NNNN: Multi-version Platform Compatibility for vLLM-Plugin-FL

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** TODO: @github-username

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Release vLLM-Plugin-FL support for the planned vLLM 0.28 line on ten domestic vendor platforms, and close the remaining 0.24 compatibility and release-acceptance gaps. Each supported combination includes a plugin wheel, dependency versions and inference/serving results.

Repository: [vllm-plugin-FL](https://github.com/flagos-ai/vllm-plugin-FL).

## Motivation

[FEP-0089](0089-vllm-plugin-fl-flagos-2.2-features.md) covers vLLM 0.20.2 and a selected 0.24 Empty-mode subset. Its final vendor list and acceptance results remain incomplete. The 0.24 work in this release is the gap between that released baseline and the selected 2.3 configurations.

### Goals

- **G1:** Close the identified 0.24 compatibility and acceptance gaps against the 2.2 release artifacts and results.
- **G2:** Validate vLLM 0.28 on ten domestic vendor/device combinations, including model inference and serving.
- **G3:** Publish dependency versions, supported model configurations, migration instructions and test results for both version lines.

### Non-Goals

vLLM 0.32, a new Empty-mode architecture, a new autotuning algorithm and additional Day-0 models.

## Proposal

Users select a version/platform combination from the compatibility matrix. Each row specifies the plugin wheel, upstream vLLM version, runtime, operator/compiler libraries and model configuration. Upgrading follows the migration instructions for that row.

## Design Details

Use the 2.2 manifest and acceptance results to identify the 0.24 gaps. Record implementation changes and missing release tests separately. For 0.28, update adapters for upstream API changes and run functional and serving regression tests on each target platform.

The matrix records vendor, device, upstream patch, plugin revision, runtime, FlagGems/FlagTree versions, model revision and precision. Keep a previously validated combination available for rollback.

**Dependencies:** FlagGems operators, applicable FlagTree compilation paths and vendor SDKs. Coordinate dependency versions with their maintainers and the quality team.

**Open decisions:** Ten-vendor roster; 0.24 gap list; upstream patch versions; model/precision configurations; numerical and performance limits.

## Packaging

**Supported vendors:** Ten domestic vendors for 0.28 and the selected 0.24 gap rows; names and devices are pending.

**Can this feature be packaged as a wheel (`.whl`)?** Yes.

Build with `python -m build --wheel`, following `.github/workflows/_build_wheel.yml`. Publish the plugin wheel, dependency lock and vendor image build recipe for each version line. Record upstream vLLM, plugin and runtime versions separately.

**Build record:** Pin Python/PyTorch, framework, operator/compiler libraries, SDK/driver and native ABI as applicable. Record source revisions, build configuration and artifact digest.

At Feature Freeze, provide the module rc0 branch and tag with matching tag, manifest and package-metadata versions.

## Test Plan

Tests marked Proposed remain to be implemented. Run each case against the specified artifact and matrix configuration, and retain its command and results. Set `FEP_PLATFORM` and `FEP_DEVICE` from that configuration.

### G1-G2: Existing runner, repeated in every approved track/platform environment

```bash
python tests/run.py --platform "$FEP_PLATFORM" --device "$FEP_DEVICE" --scope functional
```

**Expected result:** All declared functional cases pass; the report identifies the upstream version and platform. A missing configuration is not a pass.

### G1-G3: Existing runner; approved model cases must be bound in its platform configuration

```bash
python tests/run.py --platform "$FEP_PLATFORM" --device "$FEP_DEVICE" --scope e2e
```

**Expected result:** Each declared inference/serving case completes and meets its frozen accuracy and regression gates.

### G3: Proposed acceptance test

```bash
python -m pytest tests/acceptance_flagos23/test_vllm_version_contract.py -v
```

**Expected result:** Every published matrix row resolves to matching artifacts and test evidence; incompatible dependency combinations are rejected.

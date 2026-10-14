# FEP-0149: Iluvatar Platform Support in Torch-FL

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** TODO: @github-username

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Add Iluvatar support to Torch-FL, covering device runtime, operator dispatch, model execution and platform wheel builds.

Repository: [Torch-FL](https://github.com/flagos-ai/Torch-FL).

## Motivation

The Iluvatar BI-V150 baseline has runtime bring-up recorded, while vendor-operator integration remains pending. Usable framework support requires operator and model tests as well as device initialization.

### Goals

- **G1:** Integrate the device runtime, allocation, streams/events, tensor transfer and selected operator routes through the `flagos` device API.
- **G2:** Validate the model/operation matrix, including training for the selected workloads.
- **G3:** Provide a reproducible wheel build and document supported and unsupported capabilities.

### Non-Goals

Other new chips, full HF architecture coverage and distributed/compile capabilities outside the selected matrix.

## Proposal

Users build or obtain the Iluvatar Torch-FL wheel and use the `flagos` device interface. Unsupported operations fail or use a documented fallback.

## Design Details

Integrate device enumeration, allocation, streams/events and tensor transfers. Record which operator routes use FlagGems and which use vendor libraries. Keep vendor configuration isolated and run existing-platform regressions.

Acceptance covers four layers: runtime behavior; operator routing and numerical/aliasing semantics; model forward/backward/update; and a reproducible wheel build with a capability report. Add multi-device cases only if distributed support enters the matrix.

**Dependencies:** Iluvatar SDK/toolchain, operator libraries and Torch-FL build infrastructure; communication libraries only for selected distributed cases. Chip admission involves sig-chip and operator integration involves sig-operator.

**Open decisions:** Device/SDK version; accelerator selector and setup script; operator/model matrix; numerical limits; library bundling; distributed scope.

## Packaging

**Supported vendors:** Iluvatar; BI-V150 is the device candidate, pending SDK/device confirmation.

**Can this feature be packaged as a wheel (`.whl`)?** Yes; the Iluvatar build is proposed.

Extend the Torch-FL platform build and use `python -m build --wheel --no-isolation`. Add the accelerator selector, SDK setup and library-bundling rules, then document the complete build recipe.

**Build record:** Pin Python/PyTorch, framework, operator/compiler libraries, SDK/driver and native ABI as applicable. Record source revisions, build configuration and artifact digest.

At Feature Freeze, provide the module rc0 branch and tag with matching tag, manifest and package-metadata versions.

## Test Plan

Tests marked Proposed remain to be implemented. Run each case against the specified artifact and matrix configuration, and retain its command and results.

### G1-G2: Existing operator suite in the new vendor environment

```bash
python -m pytest tests/integration/ops/ -v
```

**Expected result:** All declared Iluvatar operator cases execute on the device with correct results; missing required routes are reported as failures.

### G1-G3: Proposed acceptance test

```bash
python -m pytest tests/acceptance_flagos23/test_iluvatar_platform.py -v
```

**Expected result:** Device, memory, stream/event and transfer tests pass on the selected SDK. Rebuild the wheel from the recorded recipe, verify its runtime compatibility, and generate the supported/unsupported capability report.

### G2: Proposed model acceptance driver

```bash
python tests/acceptance_flagos23/evaluate_iluvatar_models.py --matrix acceptance/flagos23/iluvatar-models.yaml
```

**Expected result:** Declared inference/training cases meet correctness and stability gates; unsupported optional capabilities remain explicitly marked.

# FEP-NNNN: Migration from TransformerEngine-FL to the Upstream Plugin Architecture

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** TODO: @github-username

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Migrate TransformerEngine-FL to upstream TransformerEngine plus a separately versioned FL plugin. Validate plugin activation and Megatron-LM-FL/FlagScale training, and provide migration and rollback instructions.

Repository: [TransformerEngine-FL](https://github.com/flagos-ai/TransformerEngine-FL).

## Motivation

Upstream [#3401](https://github.com/NVIDIA/TransformerEngine/pull/3401) merged the plugin entry point at `7c6fa5986d01b8175986ed4d6959c8b8afbee946`. This allows FL-specific code to move out of the broad upstream fork. The release still needs a compatible upstream/plugin pair, vendor build paths and training regression results.

### Goals

- **G1:** Publish the FL plugin with documented upstream versions, package/import names and backend responsibilities.
- **G2:** Verify activation and backend selection on each platform, including initialization failure and supported fallback behavior.
- **G3:** Validate outputs, gradients, loss and checkpoint save/resume against the previous TE-FL package; document migration and rollback.

### Non-Goals

Independent FSA acceptance and platforms outside the migration matrix.

## Proposal

Users replace the TE-FL package with a compatible upstream TE and FL plugin pair. The migration guide maps imports and configurations, verifies plugin activation and identifies the previous package for rollback.

## Design Details

The merged entry point uses `NVTE_PLUGIN=<module_name>` and calls `load_plugins()`. It retains the native extension under an `_nv` alias and rolls back with a warning if plugin initialization fails. A test requiring the plugin must detect that rollback and fail rather than accept the native path.

Separate FL-owned code and define compatibility checks for the upstream/plugin pair. Record native-extension loading, ABI and build requirements per platform.

Device abstraction remains a separate dependency. Upstream [#3513](https://github.com/NVIDIA/TransformerEngine/pull/3513) is open as of 2026-10-15. For each platform, identify whether it needs that change and which upstream revision provides the required functionality.

Compare the new package pair with the last validated TE-FL package on the same Megatron and FlagScale recipes. Include initialization errors, incompatible versions and checkpoint migration.

**Dependencies:** Upstream TE, vendor runtimes, operator interfaces and FlagScale/Megatron integrations. Cross-module changes involve sig-training and sig-operator.

**Open decisions:** Upstream tag; plugin repository/package names; device-specific dependencies; migration matrix; native ABI/build requirements; numerical limits; rollback package.

## Packaging

**Supported vendors:** Selected migration-matrix rows; vendor/device names are pending.

**Can this feature be packaged as a wheel (`.whl`)?** Yes; the extracted plugin build is proposed.

Implement `python -m build --wheel` for the plugin package. Provide its build metadata, native-kernel recipes, upstream TE pin and platform dependency locks. The existing monolithic TE build does not build the extracted plugin.

**Build record:** Pin Python/PyTorch, framework, operator/compiler libraries, SDK/driver and native ABI as applicable. Record source revisions, build configuration and artifact digest.

At Feature Freeze, provide the module rc0 branch and tag with matching tag, manifest and package-metadata versions.

## Test Plan

Tests marked Proposed remain to be implemented. Run each case against the specified artifact and matrix configuration, and retain its command and results.

### G1-G2: Proposed acceptance test in the selected plugin repository

```bash
python -m pytest tests/acceptance_flagos23/test_upstream_te_plugin_contract.py -v
```

**Expected result:** The pinned upstream activates the selected `NVTE_PLUGIN` module through `load_plugins()` and selects the intended backend. Incompatible versions and initialization failures are detected, including native fallback when the plugin is required. Reports identify native-extension and device-abstraction dependencies.

### G3: Proposed integration acceptance driver

```bash
python tests/acceptance_flagos23/evaluate_te_migration.py --matrix acceptance/flagos23/te-migration.yaml
```

**Expected result:** Paired old/new package runs reproduce model outputs, gradients and loss, and verify checkpoint save/resume across the selected Megatron/FlagScale matrix. The documented rollback restores the previous package and training configuration.

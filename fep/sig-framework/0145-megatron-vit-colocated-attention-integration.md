# FEP-0145: ViT Colocated Training and Attention Integration in Megatron-LM-FL

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** TODO: @github-username

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Add ViT Colocated training support to Megatron-LM-FL and validate the applicable CSA/HCA/DSA paths in the selected multimodal workloads. The release covers placement, data exchange, training correctness and efficiency.

Repository: [Megatron-LM-FL](https://github.com/flagos-ai/Megatron-LM-FL).

## Motivation

Megatron-LM-FL already contains a [MIMO colocated communicator](https://github.com/flagos-ai/Megatron-LM-FL/blob/df6fb45deedfae958e1226e49ff2fcbf10404fec/megatron/core/models/mimo/comm/colocated_communicator.py) and gradient-correctness tests. The communicator connects modules on the same rank set with different TP/DP layouts. [FEP-0086](0086-megatron-lm-fl-flagos-2.2-new-features.md) records earlier attention work and leaves colocated training acceptance unresolved.

The 2.3 ViT workload needs an explicit placement configuration and model/platform acceptance matrix.

### Goals

- **G1:** Implement the selected Colocated configuration, including module placement, parallel groups, data exchange and memory behavior.
- **G2:** Validate applicable CSA/HCA/DSA forward/backward paths under that configuration and identify any required integration changes.
- **G3:** Validate multimodal training and checkpoint save/resume; compare throughput, memory and scaling against the baseline configuration.

### Non-Goals

New attention algorithms and model/attention combinations outside the selected matrix.

## Proposal

Users select a Colocated configuration in a multimodal training recipe. The runtime checks module placement, parallel groups and attention compatibility before training. The baseline configuration remains available.

## Design Details

**Placement definition — pending:** Identify the colocated modules and rank/device mapping, and confirm whether the existing MIMO communicator is the implementation base. Specify each module's TP/DP layout and the baseline used for comparison.

The existing communicator requires matching rank spans and offsets, evenly divisible DP sizes, and PP/CP dimensions of one. Its input is replicated across source TP ranks. These are constraints of the current implementation; any extension needs separate tests.

Define activation transfer, gradient scaling, activation lifetime, recomputation and checkpoint state for the selected configuration. Map each attention implementation to the models that use it. Compare outputs, gradients and optimizer updates before measuring performance.

The minimal acceptance workload must fix one multimodal model, input batch, colocated/baseline layouts and device group. Its model and configuration remain pending.

**Dependencies:** The selected placement/communication implementation, applicable TE/attention kernels and FlagScale integration where required.

**Open decisions:** Placement definition; implementation base; model and minimal workload; public configuration; attention applicability; devices/parallelism; numerical and efficiency limits.

## Packaging

**Supported vendors:** Pending for the selected Colocated configurations.

**Can this feature be packaged as a wheel (`.whl`)?** Yes.

Use the Megatron-LM-FL build entry `python -m build`. Include configuration schemas, example recipes and separately versioned TE/operator dependencies. Package a FlagScale recipe where that integration is required.

**Build record:** Pin Python/PyTorch, framework, operator/compiler libraries, SDK/driver and native ABI as applicable. Record source revisions, build configuration and artifact digest.

At Feature Freeze, provide the module rc0 branch and tag with matching tag, manifest and package-metadata versions.

## Test Plan

Tests marked Proposed remain to be implemented. Run each case against the specified artifact and matrix configuration, and retain its command and results.

### G1: Proposed acceptance test

```bash
python -m pytest tests/acceptance_flagos23/test_vit_colocated_placement.py -v
```

**Expected result:** Valid placement/group configurations execute; invalid device or attention combinations fail before training.

### G2: Proposed mode-specific regression test

```bash
python -m pytest tests/acceptance_flagos23/test_colocated_attention.py -v
```

**Expected result:** Every applicable CSA/HCA/DSA row passes forward and backward comparisons at the approved tolerances.

### G3: Proposed acceptance driver

```bash
python tests/acceptance_flagos23/evaluate_colocated_training.py --matrix acceptance/flagos23/colocated-training.yaml
```

**Expected result:** Paired runs meet numerical limits, verify checkpoint save/resume against uninterrupted training, and report throughput, memory and scaling under fixed model/data/batch/topology.

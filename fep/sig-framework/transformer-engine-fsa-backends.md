# FEP-NNNN: Triton and CUDA FSA Backends for TransformerEngine

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** TODO: @github-username

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Provide Triton and CUDA FSA backends and integrate backend selection with TransformerEngine training. Validate sparse-attention outputs and gradients and measure kernel and model-level performance.

Repository: [TransformerEngine-FL](https://github.com/flagos-ai/TransformerEngine-FL).

## Motivation

[FEP-0087](0087-te-fl-flagos-2.2-features.md) excluded FSA from 2.2 acceptance. [Megatron-LM-FL #88](https://github.com/flagos-ai/Megatron-LM-FL/pull/88) contains Flash Sparse Attention integration through `flash_sparse_attn` Triton and CuTe interfaces; it remains unmerged as of 2026-10-15. Its relationship to the proposed TE backends needs confirmation.

### Goals

- **G1:** Define FSA semantics, supported sparsity configurations, layouts and dtypes, and provide Triton and CUDA implementations.
- **G2:** Add capability-checked TE selection and validate outputs and gradients against an independent reference.
- **G3:** Measure kernel latency and end-to-end training performance for the selected workloads.

### Non-Goals

Additional sparse-attention algorithms, automatic coverage of every Triton-capable device and acceptance of the separate TE plugin migration.

## Proposal

Users select FSA in a supported training recipe. TE checks device, backend, dtype and sparsity compatibility. Unsupported combinations fail or use an explicitly configured fallback; the executed backend is recorded.

## Design Details

**Algorithm definition — pending:** Confirm whether TE uses the Flash Sparse Attention interface referenced by Megatron #88, then pin its repository/revision and mathematical reference. Define sparsity selection, masking, padding, accumulation precision and backward semantics.

Use the same fixed Q/K/V inputs and sparsity configuration for the independent reference, Triton backend and CUDA backend. Compare outputs and dQ/dK/dV. Include boundary shapes and unsupported inputs. Exact shapes, dtypes and sparsity settings remain pending with the algorithm definition.

Partition kernel implementation and TE dispatch changes between the operator and framework components. Keep FSA acceptance separate from TE migration. For each model, compare FSA enabled and disabled under matching data, batch, precision and topology; report correctness before performance.

**Dependencies:** The selected FSA implementation, TE dispatch and required Triton/FlagTree compilation paths. CUDA architecture requirements depend on the selected kernel implementation.

**Open decisions:** Algorithm/reference revision; relationship to Megatron #88; sparsity settings; model/device/dtype matrix; build flow; numerical limits; performance workloads and targets.

## Packaging

**Supported vendors:** CUDA: NVIDIA, architecture pending. Triton: selected devices, pending validation.

**Can this feature be packaged as a wheel (`.whl`)?** Yes; TE integration and kernel packaging are proposed.

Add the integration to the selected TE-FL/plugin wheel build using `python -m build --wheel`. Record CUDA or CuTe build requirements and Triton/FlagTree pins according to the chosen implementation. Kernel package layout and build flags remain pending.

**Build record:** Pin Python/PyTorch, framework, operator/compiler libraries, SDK/driver and native ABI as applicable. Record source revisions, build configuration and artifact digest.

At Feature Freeze, provide the module rc0 branch and tag with matching tag, manifest and package-metadata versions.

## Test Plan

Tests marked Proposed remain to be implemented. Run each case against the specified artifact and matrix configuration, and retain its command and results.

### G1-G2: Proposed acceptance test

```bash
python -m pytest tests/acceptance_flagos23/test_fsa_forward_backward.py -v
```

**Expected result:** Both backends match the approved algorithmic reference over the declared shape/dtype/sparsity matrix; unsupported inputs produce the documented error/fallback.

### G3: Proposed acceptance driver

```bash
python tests/acceptance_flagos23/evaluate_fsa_training.py --matrix acceptance/flagos23/fsa-training.yaml
```

**Expected result:** Report kernel latency and paired model step-time/throughput/memory results, with loss/gradient correctness passing before performance is assessed.

# FEP: PyTorch-Plugin-FL CUDA Backend Operator Dispatch

## Summary

This FEP proposes integrating CUDA backend operator dispatch support into the PyTorch-Plugin-FL project through two complementary execution paths:

1. Native CUDA operator dispatch
2. FlagGems operator dispatch

The goal is to provide a unified and extensible backend dispatch mechanism for PyTorch operators on CUDA platforms while aligning with the broader FlagOS multi-backend ecosystem.

---

## Motivation

FlagOS aims to build a unified AI system software stack that enables "develop once, run anywhere" across heterogeneous accelerators. ([github.com](https://github.com/flagos-ai?utm_source=chatgpt.com))

Within this ecosystem, FlagGems provides a backend-neutral operator library and integrates with PyTorch ATen dispatch to accelerate model training and inference on diverse hardware platforms. ([github.com](https://github.com/flagos-ai/FlagGems?utm_source=chatgpt.com))

PyTorch-Plugin-FL is designed as a lightweight PyTorch backend plugin framework. However, the project currently lacks:

* A unified CUDA dispatch layer
* Runtime dispatch between native and FlagGems operators
* A clean abstraction for integrating alternative operator implementations
* A backend registration mechanism compatible with the FlagOS architecture

This FEP introduces an initial CUDA-focused dispatch architecture that:

* Supports native CUDA operators
* Supports FlagGems operators
* Establishes the foundation for future multi-backend expansion
* Keeps compatibility with existing PyTorch execution semantics

---

## Goals

### In Scope

* CUDA backend support in PyTorch-Plugin-FL
* Native CUDA operator dispatch
* FlagGems operator dispatch
* Runtime operator selection mechanism
* Unified backend abstraction for operator execution
* PyTorch-compatible operator behavior

### Out of Scope

* Non-CUDA backend support
* Custom operator authoring APIs
* Graph-level compilation
* Distributed runtime support
* Operator performance benchmarking
* Automatic kernel generation
* Full FlagTree integration

---

## Background

FlagGems is a Triton-based operator library that supports multiple hardware backends and integrates with the PyTorch ATen backend dispatch mechanism. ([github.com](https://github.com/flagos-ai/FlagGems?utm_source=chatgpt.com))

The FlagOS ecosystem has gradually moved hardware-specific implementations into plugin-style repositories and backend abstraction layers. ([github.com](https://github.com/FlagOpen/FlagScale?utm_source=chatgpt.com))

This proposal follows the same architectural direction by introducing a dispatch layer into PyTorch-Plugin-FL.

The initial implementation focuses on CUDA because:

* CUDA provides the most mature validation environment
* Native CUDA operators can serve as correctness references
* FlagGems already supports CUDA execution paths
* The architecture can later generalize to additional backends

---

## Design Overview

### High-Level Architecture

```text
PyTorch Frontend
        |
        v
PyTorch-Plugin-FL Dispatch Layer
        |
        +-------------------+
        |                   |
        v                   v
 Native CUDA          FlagGems CUDA
 Operator Path        Operator Path
```

The dispatch layer acts as a runtime selection mechanism between:

* Native CUDA implementations
* FlagGems implementations

Operator execution remains transparent to PyTorch users.

---

## Operator Dispatch Model

### Dispatch Flow

```text
PyTorch Op
    |
    v
PyTorch-Plugin-FL Dispatcher
    |
    +--> Native CUDA Backend
    |
    +--> FlagGems Backend
```

The dispatcher:

* Receives operator execution requests
* Resolves backend selection
* Invokes the corresponding implementation
* Returns standard PyTorch tensors

---

## Backend Selection

### Native CUDA Path

The native CUDA path directly invokes PyTorch CUDA implementations.

This path provides:

* Baseline correctness
* Stable fallback behavior
* Compatibility with existing PyTorch semantics

### FlagGems Path

The FlagGems path dispatches supported operators to FlagGems kernels.

This path enables:

* Triton-based operator acceleration
* Backend-neutral kernel abstraction
* Future portability to additional accelerators

FlagGems integration follows its existing ATen registration and backend dispatch model. ([github.com](https://github.com/flagos-ai/FlagGems?utm_source=chatgpt.com))

---

## Runtime Configuration

The implementation may support runtime backend selection through:

* Environment variables
* Configuration flags
* Internal backend registration APIs

Example:

```bash
export PT_PLUGIN_FL_BACKEND=native
export PT_PLUGIN_FL_BACKEND=flaggems
```

The exact configuration interface may evolve during implementation.

---

## Compatibility

The proposal is designed to maintain compatibility with:

* Existing PyTorch operator semantics
* Existing CUDA tensor behavior
* Standard ATen dispatch patterns

No frontend API changes are required for PyTorch users.

---

## Future Extensions

This FEP establishes the architectural foundation for:

* Additional accelerator backends
* Dynamic backend capability detection
* Hybrid backend dispatch strategies
* Operator-level fallback policies
* Future FlagTree integration
* Backend-specific optimization pipelines

Potential future backends include:

* Ascend
* Cambricon
* Hygon
* Iluvatar
* Kunlunxin
* Additional FlagOS-supported accelerators

---

## Alternatives Considered

### Direct Native CUDA Only

A native CUDA-only implementation was considered.

However, this approach:

* Does not align with the FlagOS multi-backend direction
* Limits future portability
* Prevents integration with FlagGems operator acceleration

### Full Backend Rewrite

A complete backend rewrite was also considered.

However, this would:

* Increase implementation complexity
* Delay incremental integration
* Make validation more difficult

The proposed dispatch-layer approach provides a more incremental and extensible path.

---

## Risks

Potential risks include:

* Dispatch overhead
* Operator semantic mismatches
* Backend capability inconsistencies
* Increased testing complexity

These risks are mitigated through:

* Native CUDA fallback paths
* Incremental operator enablement
* PyTorch semantic compatibility requirements
* Backend-isolated validation

---

## Testing Plan

The implementation will include:

* Operator correctness validation
* Native CUDA vs FlagGems result comparison
* Tensor layout compatibility testing
* Runtime dispatch validation
* Backend fallback validation

Initial testing scope focuses on CUDA execution.

---

## Rollout Plan

### Phase 1

* Introduce dispatch abstraction
* Enable native CUDA backend
* Add runtime backend selection

### Phase 2

* Integrate FlagGems dispatch
* Validate operator correctness
* Expand operator coverage

### Phase 3

* Improve backend extensibility
* Prepare multi-backend integration

---

## References

* [FlagOS Community Repository](https://github.com/flagos-ai/community?utm_source=chatgpt.com)
* [FlagGems Repository](https://github.com/flagos-ai/FlagGems?utm_source=chatgpt.com)
* [PyTorch-Plugin-FL Repository](https://github.com/Hchnr/PyTorch-Plugin-FL?utm_source=chatgpt.com)
* [FlagTree Repository](https://github.com/flagos-ai/FlagTree?utm_source=chatgpt.com)

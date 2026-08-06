# FEP-0095: Introduce CommonIR to FlagTree

**Status:** `Implemented`

**Created:** 2026-07-30

**Owner:** kateyijian

**SIG:** sig-compiler

**Target Version:** FlagOS 2.2

---

## Summary

Common IR serves as a unified input reception layer that enhances TLE's data representation and pipeline control abstractions, enabling operator developers to achieve fine-grained pipeline orchestration when developing operators with TLE. As an intermediate representation layer connecting Triton Dialect to hardware-specific Dialects, Common IR introduces tile-granularity `tile.buf` that carries richer semantics and optimization information, providing hardware-specific Dialects with more comprehensive optimization context. This enables more precise performance optimization and code generation, achieving near-hardware-peak performance while maintaining portability.

Repository: https://github.com/flagos-ai/FlagTree

## Motivation

Triton's block-granularity programming paradigm cannot meet high-performance requirements. Community projects like Gluon and TLX focus their high-performance abstractions primarily on GPGPU characteristics without considering DSA hardware features. An increasing number of non-GPGPU vendors extend Triton DSL for fine-grained programming to achieve better performance, causing Triton's extended DSLs to face a non-convergent state across GPGPU/DSA. Common IR abstracts computation, expresses semantics, and carries optimization information while accommodating both GPGPU and DSA hardware characteristics, providing operator developers with a unified programming model when using TLE for operator development across GPGPU/DSA. Additionally, as LLM-generated operators become increasingly mature, a unified high-performance TLE programming model (compatible with DSA/GPGPU) provides the necessary foundation for LLM-generated TLE operators.

### Goals

- Enable operator developers to program with a unified DSL across DSA/GPGPU hardware architectures with different characteristics.
- Provide tile-op granularity pipeline orchestration, achieving vendor C-like pipeline scheduling expressiveness.
- Enhance buffer discrete memory access representation, enabling Triton to describe buffer views.
- Carry additional information (buffer view, memory hierarchy) to facilitate performance optimization in downstream dialects.

### Non-Goals

- Replace Triton's existing block-granularity programming model or break compatibility for current Triton users.
- Achieve complete adaptation for all DSA hardware backends in this FEP.
- Guarantee performance for every workload; performance remains dependent on specific operator shapes, hardware, and backend lowering strategies.

## Proposal

Operator developers specify the compute unit type through `tle.scope`, use `tile.buf` to describe tile-granularity buffers with rich semantics, and perform fine-grained pipeline control through pipeline orchestration APIs:

```python
with tle.scope(core_mode="cube"):
    buf = tle.tile.buf(shape=[BLOCK_M, BLOCK_N], dtype=tl.float16, memory="L1")
    # Tile-granularity pipeline orchestration
    ...
```

## Design Details

- **Frontend API**: `with tle.scope(core_mode="cube"):` declares the current compute unit as a cube/vector compute unit. The scope context manager declares the hardware compute unit type, providing target information for subsequent lowering.
- **tile.buf abstraction**: `tle.tile.buf` introduces a tile-granularity buffer description carrying shape, dtype, memory hierarchy, and other semantic information, providing optimization context for hardware-specific Dialects.
- **IR construction**: The Python frontend generates Common IR operations through the semantic builder, preserving tile.buf semantic information, memory hierarchy annotations, and pipeline orchestration metadata as the intermediate representation connecting Triton Dialect to hardware-specific Dialects.
- **Pipeline orchestration**: Provides tile-op granularity pipeline orchestration capabilities, supporting fine-grained data transfer and compute overlap, achieving expressiveness comparable to hardware vendor C-like pipeline scheduling.
- **Buffer View**: Supports description of discrete memory access patterns for buffers, enabling Triton to express buffer views and facilitating memory access optimization in downstream dialects.

## Packaging

CommonIR is shipped as part of FlagTree's TLE components.

- Source branch: https://github.com/flagos-ai/FlagTree/tree/triton_v3.6.x
- Build command: `MAX_JOBS=32 python3 -m pip install . --no-build-isolation`
- Packaging format: Python wheel/installable Python package built by `pip install .`

## Test Plan

Package installation:

```bash
pip uninstall -y triton
MAX_JOBS=32 python3 -m pip install . --no-build-isolation
```

Component setup:

```bash
export PYTHONPATH=/path/to/FlagTree/python:${PYTHONPATH}
```

Test commands:

```bash
python3 -m pytest -s python/test/tle/unit
python3 -m pytest -s python/test/tle/integration
```

Expected results:
- Unit tests validate the Common IR frontend API contract, including scope declarations, tile.buf creation, and memory hierarchy annotations.
- Integration tests validate the correctness of Common IR lowering to hardware-specific Dialects.

## Related PRs

<!-- Add related PRs here -->

## Implementation History

- 2026-07-30: FEP created

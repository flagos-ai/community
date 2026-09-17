# FEP-0095: Introduce CommonIR to FlagTree

**Status:** `Implemented`

**Created:** 2026-07-30

**Owner:** kateyijian

**SIG:** sig-compiler

**Target Version:** FlagOS 2.2

---

## Summary

Common IR is introduced as a lower-level complement to TTIR for TLE operator
authors. The FlagOS 2.2 implementation is specifically an **Ascend 910B/910C
proof of concept on the Triton 3.5 release line**: it connects
`tle.dsa → Common IR → linalg IR → npubin`. It does not yet establish a
production-quality unified DSA/GPGPU path or near-peak performance across
hardware families.

Repository: https://github.com/flagos-ai/FlagTree

## Release Boundary and Evidence

- **FlagOS 2.1 baseline:** FlagTree `0.6.0+triton3.5` for the relevant Triton
  3.5 line.
- **FlagOS 2.2 release candidate reviewed:**
  `0.7.0rc2.post1+triton3.5`, as pinned by the FlagOS 2.2 RC2 manifest.
- **Implementation PR:** flagos-ai/FlagTree#974, opened 2026-08-13 and merged
  2026-08-27 into `triton_v3.5.x`.

PR #974 describes and implements an Ascend PoC, not the entire architecture
described as the long-term motivation below. It records CANN 9.1.0,
Ascend 910B/910C, `python/test/CommonIR`, and a linked FlagGems precision run.
`Implemented` in this FEP therefore means that this bounded PoC is present in
the 2.2 Triton 3.5 release line; the broader multi-backend goals remain future
work.

## Motivation

Triton's block-granularity programming paradigm cannot meet high-performance requirements. Community projects like Gluon and TLX focus their high-performance abstractions primarily on GPGPU characteristics without considering DSA hardware features. An increasing number of non-GPGPU vendors extend Triton DSL for fine-grained programming to achieve better performance, causing Triton's extended DSLs to face a non-convergent state across GPGPU/DSA. Common IR abstracts computation, expresses semantics, and carries optimization information while accommodating both GPGPU and DSA hardware characteristics, providing operator developers with a unified programming model when using TLE for operator development across GPGPU/DSA. Additionally, as LLM-generated operators become increasingly mature, a unified high-performance TLE programming model (compatible with DSA/GPGPU) provides the necessary foundation for LLM-generated TLE operators.

### Goals

- Validate a Common IR route on Ascend 910B/910C from `tle.dsa` through
  linalg IR to NPU binary generation.
- Expose lower-level operator abstractions that can carry buffer, memory and
  scheduling semantics beyond the normal TTIR path.
- Run the Common IR test directory and the linked FlagGems precision suite on
  the stated CANN/hardware environment.
- Use the PoC to inform, rather than claim completion of, a future unified DSL
  across DSA and GPGPU architectures.

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

The Common IR PoC is shipped as part of FlagTree's Triton 3.5 TLE components.

- Source branch: https://github.com/flagos-ai/FlagTree/tree/triton_v3.5.x
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

Primary Common IR test location from PR #974:

```bash
python3 -m pytest -s python/test/CommonIR
```

Expected results:
- Common IR frontend and lowering tests pass on the stated Ascend environment.
- FlagGems precision results are checked against the result linked from PR
  #974; this FEP does not convert that result into a cross-backend performance
  claim.

Tested environment recorded by the implementation PR:

- CANN 9.1.0 (the PR notes that some samples do not run on earlier versions)
- Ascend 910B / 910C

## Related PRs

- [x] flagos-ai/FlagTree#974 — Common IR PoC on `triton_v3.5.x`, covering
  `tle.dsa → Common IR → linalg IR → npubin` on Ascend 910B/910C

## Implementation History

- 2026-07-30: FEP created
- 2026-08-27: FlagTree#974 merged into `triton_v3.5.x`.
- 2026-09-17: Reconciled the FEP with the 2.2 RC2 manifest and PR #974;
  limited `Implemented` to the Triton 3.5 Ascend PoC and removed the invalid
  Triton 3.6 source-branch claim.

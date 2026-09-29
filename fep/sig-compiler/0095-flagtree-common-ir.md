# FEP-0095: Introduce CommonIR to FlagTree

**Status:** `Implemented`

**Updated:** 2026-09-24

**Created:** 2026-07-30

**Owner:** kateyijian

**SIG:** sig-compiler

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| flagtree-triton3.5 | [`0.7.0-rc2-triton3.5` @ `15ec1a6cbc8d`](https://github.com/flagos-ai/FlagTree/tree/15ec1a6cbc8d51f597f46459a500e96f3812c58f) | [`0.7.0rc2.post2+triton3.5` @ `15ec1a6cbc8d`](https://github.com/flagos-ai/FlagTree/tree/15ec1a6cbc8d51f597f46459a500e96f3812c58f) |

## Summary

Common IR provides a lower-level route from TLE DSA operations to Ascend
code generation. The implemented scope is an Ascend 910B/910C proof of
concept on FlagTree's Triton 3.5 line.

## Delivered Scope

| Goal | Result |
|---|---|
| TLE DSA to Common IR lowering | Present in RC2 |
| Common IR to Ascend code generation | Present under `third_party/ascend/` |
| Compiler and operator validation | PR #974 records CANN 9.1.0 results on Ascend 910B/910C and a linked FlagGems precision run |

Cross-backend unification and general performance parity remain outside this
implemented PoC.

## Design

The TLE frontend preserves buffer, memory-space and scheduling semantics in
Common IR before Ascend lowering. Compute scopes distinguish cube and vector
work. Buffer views and explicit transfer/compute ordering expose operations
that the backend can schedule across the NPU memory hierarchy.

RC2 also selects its AscendNPU-IR dependency by CANN version through PR #1149.
The original PoC validation used CANN 9.1.0; other toolkit combinations need
their own run.

## Packaging

Build the Triton 3.5 RC2 branch with the Ascend toolchain:

```bash
python -m pip wheel . --no-build-isolation --no-deps -w dist
```

The feature is part of FlagTree; there is no separate Common IR package.

## Test Commands

The RC2 test root is `test/CommonIR`, with unit tests and separate successful,
performance and known-failing Ascend samples.

```bash
python -m pytest -q test/CommonIR/unittest/test_common_ir.py
bash test/CommonIR/Ascend/success_case/run_all_tests.sh
```

Unit tests and the successful sample set must pass on Ascend 910B/910C with
the matching CANN build. Known-failing samples remain under
`test/CommonIR/Ascend/failed_case` and are not a passing regression suite.
The precision result and original source revisions are linked from
[FlagTree#974](https://github.com/flagos-ai/FlagTree/pull/974).

## Related PRs

- [x] [FlagTree#974](https://github.com/flagos-ai/FlagTree/pull/974) — Common IR Ascend PoC. Merged.
- [x] [FlagTree#1149](https://github.com/flagos-ai/FlagTree/pull/1149) — CANN-dependent AscendNPU-IR selection. Merged.

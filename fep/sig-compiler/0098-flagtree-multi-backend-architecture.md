# FEP-0098: FlagTree Backend Integration, Specialization and CI

**Status:** `Implemented`

**Updated:** 2026-09-24

**Created:** 2026-08-01

**Owner:** Unassigned

**SIG:** sig-compiler

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| flagtree-triton3.6 | [`0.7.0-rc2-triton3.6` @ `4819c190476c`](https://github.com/flagos-ai/FlagTree/tree/4819c190476cebb66057493e41379c1406c615ac) | [`0.7.0rc2.post2+triton3.6` @ `d9e65f4df7fe`](https://github.com/flagos-ai/FlagTree/tree/d9e65f4df7fe881281abd9e834ab3f37f4d0642c) |
| flagtree-triton3.5 | [`0.7.0-rc2-triton3.5` @ `15ec1a6cbc8d`](https://github.com/flagos-ai/FlagTree/tree/15ec1a6cbc8d51f597f46459a500e96f3812c58f) | [`0.7.0rc2.post2+triton3.5` @ `15ec1a6cbc8d`](https://github.com/flagos-ai/FlagTree/tree/15ec1a6cbc8d51f597f46459a500e96f3812c58f) |
| flagtree-triton3.3 | [`0.7.0-rc2-triton3.3` @ `0abc361ee426`](https://github.com/flagos-ai/FlagTree/tree/0abc361ee426e4a8c9d39d8af90c37120bbd8f4a) | [`0.7.0rc2.post2+triton3.3` @ `0abc361ee426`](https://github.com/flagos-ai/FlagTree/tree/0abc361ee426e4a8c9d39d8af90c37120bbd8f4a) |

## Summary

FlagTree 0.7 provides Triton 3.6, 3.5 and 3.3 backend lines for FlagOS 2.2,
with backend-local specialization and compiler, operator and model CI.

## Delivered Scope

| Feature | Implementation | Validation |
|---|---|---|
| Backend integration | TileIR, PPU, SpacemiT, Tsingmicro and vendor source lines | Backend build/test jobs |
| Python specialization | Shared extension mechanism; Iluvatar/MetaX migrations | Feature CI |
| C++ specialization | Backend-local sources and Enflame integration | Backend CI |
| Integration workflows | FlagGems actions and selected model benchmarks | Recorded operator/model CI runs |

## Design

`python/triton/_flagtree_spec.py` resolves backend-specific Python modules at
package extension points and retains shared fallback modules. Backend code
lives under `third_party/<backend>/`.

C++ specialization uses backend-local sources and build configuration.
Moore Threads retains its own backend. CI executes compiler tests, FlagGems
operator checks and selected NVIDIA/PPU/Hygon/Iluvatar model benchmarks.

## Packaging

Build a wheel from the matching RC2 source line with the backend SDK and
FlagTree build configuration. The supported backend/version combinations are
those in the branch's build-and-test and delivery workflows.

```bash
python -m pip wheel . --no-build-isolation --no-deps -w dist
```

## Test Plan

For each supported backend, build through its checked-in workflow, run the
compiler and numerical suites, and check specialization loading and shared
fallbacks. Run the configured FlagGems and model jobs with the matching SDK,
image and source revisions.

## Validation

The Triton 3.3 RC2 head passed NVIDIA, Enflame, Tsingmicro and AIPU
build/test lanes. The 3.5 head passed NVIDIA, Ascend 910B/910C unit and TLE
tests, Ascend Qwen, and Enflame GCU300/GCU400 tests.

Triton 3.6 feature PRs [#1037](https://github.com/flagos-ai/FlagTree/pull/1037)
and [#1103](https://github.com/flagos-ai/FlagTree/pull/1103) have passing
multi-backend build/test jobs. Each backend uses its checked-in workflow,
SDK and compiler line.

## Known Limitations

A separate Ascend CANN 9.1.0 lane failed. Compiler/numerical defects remain
tracked in [FlagTree#1248](https://github.com/flagos-ai/FlagTree/issues/1248)
and [#1249](https://github.com/flagos-ai/FlagTree/issues/1249). Passing backend
lanes do not establish support for every SDK combination.

## Related PRs

- [x] [FlagTree#843](https://github.com/flagos-ai/FlagTree/pull/843) — PPU backend. Merged.
- [x] [FlagTree#862](https://github.com/flagos-ai/FlagTree/pull/862) — Iluvatar Python specialization. Merged.
- [x] [FlagTree#933](https://github.com/flagos-ai/FlagTree/pull/933) — SpacemiT backend. Merged.
- [x] [FlagTree#940](https://github.com/flagos-ai/FlagTree/pull/940) — Enflame C++ specialization. Merged.
- [x] [FlagTree#962](https://github.com/flagos-ai/FlagTree/pull/962) — MetaX Python specialization. Merged.
- [x] [FlagTree#1070](https://github.com/flagos-ai/FlagTree/pull/1070) — FlagGems CI integration. Merged.
- [x] [FlagTree#1071](https://github.com/flagos-ai/FlagTree/pull/1071) — Tsingmicro Triton 3.6 backend. Merged.
- [x] [FlagTree#1148](https://github.com/flagos-ai/FlagTree/pull/1148) — FlagGems CI action refactor. Merged.
- [x] [FlagTree#1254](https://github.com/flagos-ai/FlagTree/pull/1254) — Enflame toolkit option compatibility in RC2. Merged.
- [x] [FlagTree#1276](https://github.com/flagos-ai/FlagTree/pull/1276) — XPU current-device selection in RC2. Merged.
- [x] [FlagTree#1277](https://github.com/flagos-ai/FlagTree/pull/1277) — XPU backend-string selection in RC2. Merged.

## Deferred to FlagOS 2.3

- Complete C++ specialization across all backends: [FlagTree#985](https://github.com/flagos-ai/FlagTree/pull/985), [#1038](https://github.com/flagos-ai/FlagTree/pull/1038).
- Triton 3.7 accelerator-backend release integration and additional TileIR routing.
- Required-check configuration and regression-blocking acceptance for every backend.

# FEP-0098: FlagTree Multi-Backend Architecture — New Backends, Unified Specialization, and CI/CD Integration

**Status:** `Provisional`

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

Extend backend support, move backend specializations out of shared compiler
code and add operator/model validation to CI. The FlagOS 2.2 RC2 matrix covers
Triton 3.6, 3.5 and 3.3. It contains no Triton 3.7 artifact.

## Goals and Completion

| Goal | RC2 implementation | Remaining work |
|---|---|---|
| G1: Backend additions | TileIR, PPU, SpacemiT and Tsingmicro paths on 3.6; vendor-specific paths on 3.5/3.3 | Enflame 3.7 is outside the RC2 manifest; per-backend acceptance remains separate |
| G2: Unified specialization | Python specialization and backend-local compiler/build code present | Complete C++ specialization migration |
| G3: Migrate all backends | Iluvatar and MetaX Python migrations and Enflame C++ specialization present | Moore Threads and MetaX C++ migration PRs remain open; no complete all-backend rollout |
| G4: Earlier integration tests | FlagGems test actions and selected vLLM benchmark workflows present | Verify required-check configuration and passing results per platform |

Moore Threads uses its own backend in this RC2 tree; a Moore Threads-through-
TileIR delivery is not established by the source.

## Design

Python specialization is implemented in `python/triton/_flagtree_spec.py`.
Backend-specific modules take precedence at defined package extension points;
shared modules remain the fallback. Backend code lives under
`third_party/<backend>/`.

C++ migration moves specializations into backend-local sources and build
configuration. Open PRs #985 and #1038 are not completed RC2 migrations.

CI contains FlagGems operator testing and NVIDIA, PPU, Hygon and Iluvatar
model benchmark lanes. A workflow file alone does not configure a required
branch-protection check; that configuration remains part of integration
acceptance.

## Packaging

Build a wheel from the matching RC2 source line with the backend SDK and
FlagTree build configuration. The supported backend/version combinations are
those in the branch's build-and-test and delivery workflows.

```bash
python -m pip wheel . --no-build-isolation --no-deps -w dist
```

Triton 3.7 development is tracked separately from these RC2 artifacts.

## Test Plan

For every declared backend:

1. Build through its checked-in build-and-test workflow.
2. Run compiler and backend numerical tests, including the FlagGems action
   where configured.
3. Check that backend specializations load and shared fallback modules remain
   available.
4. Run the checked-in model benchmark configuration and record the image,
   model, source revisions and result.
5. Confirm that required checks fail on a regression and block integration.

RC2 includes fixes for Enflame toolkit option compatibility and XPU runtime
backend/device selection. Backend completion still requires the remaining
compiler and numerical failures to be resolved, including
[FlagTree#1248](https://github.com/flagos-ai/FlagTree/issues/1248) and
[FlagTree#1249](https://github.com/flagos-ai/FlagTree/issues/1249).

## Related PRs

- [x] [FlagTree#843](https://github.com/flagos-ai/FlagTree/pull/843) — PPU backend. Merged.
- [x] [FlagTree#862](https://github.com/flagos-ai/FlagTree/pull/862) — Iluvatar Python specialization. Merged.
- [x] [FlagTree#933](https://github.com/flagos-ai/FlagTree/pull/933) — SpacemiT backend. Merged.
- [x] [FlagTree#940](https://github.com/flagos-ai/FlagTree/pull/940) — Enflame C++ specialization. Merged.
- [x] [FlagTree#962](https://github.com/flagos-ai/FlagTree/pull/962) — MetaX Python specialization. Merged.
- [ ] [FlagTree#985](https://github.com/flagos-ai/FlagTree/pull/985) — Moore Threads C++ specialization. Open.
- [ ] [FlagTree#1038](https://github.com/flagos-ai/FlagTree/pull/1038) — MetaX C++ specialization. Open.
- [x] [FlagTree#1070](https://github.com/flagos-ai/FlagTree/pull/1070) — FlagGems CI integration. Merged.
- [x] [FlagTree#1071](https://github.com/flagos-ai/FlagTree/pull/1071) — Tsingmicro Triton 3.6 backend. Merged.
- [x] [FlagTree#1148](https://github.com/flagos-ai/FlagTree/pull/1148) — FlagGems CI action refactor. Merged.
- [x] [FlagTree#1254](https://github.com/flagos-ai/FlagTree/pull/1254) — Enflame toolkit option compatibility in RC2. Merged.
- [x] [FlagTree#1276](https://github.com/flagos-ai/FlagTree/pull/1276) — XPU current-device selection in RC2. Merged.
- [x] [FlagTree#1277](https://github.com/flagos-ai/FlagTree/pull/1277) — XPU backend-string selection in RC2. Merged.

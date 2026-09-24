# FEP-0088: Torch-FL Runtime, Operator Dispatch and Distributed Support

**Status:** `Implemented`

**Updated:** 2026-09-24

**Created:** 2026-07-30

**Owner:** Unassigned

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| torch-fl | [`0.2.0-rc2` @ `400cf8652ae2`](https://github.com/flagos-ai/Torch-FL/tree/400cf8652ae2744e0e6bc6f621ff6e45cbb07b9a) | [`v0.2.0-rc2.post1` @ `400cf8652ae2`](https://github.com/flagos-ai/Torch-FL/tree/400cf8652ae2744e0e6bc6f621ff6e45cbb07b9a) |

## Summary

Torch-FL exposes the `flagos` device through PyTorch PrivateUse1 and
routes operators to FlagGems, vendor kernels or compatibility boxing. The
2.2 scope covers CUDA, MetaX, Ascend, MUSA, Hygon, PPU and Enflame.

## Delivered Scope

| Feature | Implementation | Validation |
|---|---|---|
| Runtime and dispatch | PrivateUse1 registration, platform configuration and operator routing | Seven-platform RC2 build/test CI |
| FlagGems integration | Python/C++ dispatch and routing consistency checks | Integration suites and hardware adaptation records |
| Distributed execution | FlagCX-backed `ProcessGroupFlagOS` and collectives | Basic distributed and DDP validation |

PyTorch compatibility is `>=2.10,<2.11` in this RC2 source. Supported model
operations depend on each platform's routing configuration and vendor runtime.

## Design

Configuration under `torch_fl/configs/` selects FlagGems, native kernels,
boxing or supported CPU fallback per ATen operation. CUDA-compatible boxing
reuses vendor libtorch. `torch_fl/comm/` provides FlagCX collectives and the
distributed process group. Profiler and compilation coverage vary by platform.

## Packaging

Use the vendor's PyTorch 2.10 build and SDK. Select the accelerator using the
repository's installation guide; for a CUDA build:

```bash
ACCELERATOR=cuda python -m pip wheel . --no-build-isolation --no-deps -w dist
```

The distribution name is `torch_fl`. `FLAGOS_WHEEL_LOCAL` supplies a vendor or
SDK suffix; separate package names such as `torch-fl-mx` are not the RC2
packaging contract. `setup.py` still sets the base wheel version to `0.1.0`,
while the release tag is `v0.2.0-rc2.post1`. This mismatch remains unresolved.

## Test Commands

```bash
python -m pytest -q tests/integration/ops/test_flaggems_conf_consistency.py
python -m pytest -q tests/integration/ops/test_flaggems_cpp_dispatch.py
python -m pytest -q tests/integration/ops/test_full_cuda_coverage.py
```

Live collective and DDP scripts are under `tests/manual/`. Model cases use
the repository's transformers test automation.

## Validation

[RC2 workflow 34449750253](https://github.com/flagos-ai/Torch-FL/actions/runs/34449750253)
passed all 16 checks at `400cf8652ae2`, including build/test lanes for CUDA,
MetaX, Ascend, MUSA, Hygon/DCU, PPU and Enflame/GCU.

The [hardware inventory](https://jwolpxeehx.feishu.cn/wiki/EnckwVHbfixDcAkllaZcRlMgnMf)
records runtime, FlagCX, basic distributed and DDP support. Its model and
operator counts are platform-specific; they are not a universal routing ratio.

## Related PRs

- [x] [Torch-FL#22](https://github.com/flagos-ai/Torch-FL/pull/22) — Hygon CUDA-compatible runtime. Merged.
- [x] [Torch-FL#28](https://github.com/flagos-ai/Torch-FL/pull/28) — PPU FlagGems enablement. Merged.
- [x] [Torch-FL#29](https://github.com/flagos-ai/Torch-FL/pull/29) — Hygon FlagGems enablement. Merged.
- [x] [Torch-FL#24](https://github.com/flagos-ai/Torch-FL/pull/24) — FlagGems routing consistency tests. Merged.
- [x] [Torch-FL#31](https://github.com/flagos-ai/Torch-FL/pull/31) — FlagGems C++ dispatch. Merged.
- [x] [Torch-FL#30](https://github.com/flagos-ai/Torch-FL/pull/30) — Base collectives and FlagCX signature compatibility. Merged.
- [x] [Torch-FL#34](https://github.com/flagos-ai/Torch-FL/pull/34) — MetaX FlagCX execution path. Merged.
- [x] [Torch-FL#239](https://github.com/flagos-ai/Torch-FL/pull/239) — MUSA wrapped-scalar binary operations. Merged.
- [x] [Torch-FL#242](https://github.com/flagos-ai/Torch-FL/pull/242) — MUSA size-one stride compatibility. Merged.
- [x] [Torch-FL#247](https://github.com/flagos-ai/Torch-FL/pull/247) — Transformers test triage and workflow integration. Merged.
- [x] [Torch-FL#258](https://github.com/flagos-ai/Torch-FL/pull/258) — Unsigned dtype cast support. Merged.
- [x] [Torch-FL#270](https://github.com/flagos-ai/Torch-FL/pull/270) — Fused SDPA on the boxing route. Merged.

## Deferred to FlagOS 2.3

- Kunlunxin's released-source and PyTorch-version integration.
- A measured 90% FlagGems routing target with a fixed operator denominator.
- Expanded transformers/diffusers and fine-tuning coverage.

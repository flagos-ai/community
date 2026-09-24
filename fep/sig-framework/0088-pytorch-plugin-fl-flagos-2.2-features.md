# FEP-0088: Torch-FL Features for FlagOS 2.2

**Status:** `Implementable`

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

Torch-FL exposes the `flagos` device through PyTorch PrivateUse1, with
per-operator routing to FlagGems, vendor kernels and compatibility boxing.
RC2 includes distributed, profiler and compilation integration, with
capabilities varying by platform.

## Goals and Completion

| Goal | RC2 implementation | Remaining work |
|---|---|---|
| G1: Seven-chip workload support | Routes for Hygon, MetaX, Ascend, PPU, MUSA and Enflame; additional BPU/Tsingmicro runtime code | Kunlunxin implementation and a validated seven-chip workload matrix |
| G2: At least 90% / about 380 FlagGems operators | Routing tables, C++ dispatch and consistency tests present | Reproducible operator inventory and model-route coverage |
| G3: Per-vendor release packages | `setup.py` builds `torch_fl` with vendor-specific contents and local version suffixes | Package version alignment and published artifact matrix |
| G4: FlagCX collectives and DDP | `torch_fl/comm/` and platform-specific live tests present | Per-vendor collective and DDP acceptance |

The RC2 README pins PyTorch to `>=2.10,<2.11`. The former Kunlunxin/PyTorch
2.9 claim is not supported by this RC2 tree. FSDP remains outside the
committed scope.

## Design

Backend configuration under `torch_fl/configs/` selects FlagGems, native
kernels, boxing or supported CPU fallback per ATen operation. CUDA-compatible
boxing reuses the matching vendor libtorch. Native backend coverage depends
on the vendor operator library.

The RC2 compatibility table lists NVIDIA/MetaX support, Ascend/Hygon beta
routes, experimental PPU/GCU/MUSA routes, BPU graph compilation and
Tsingmicro runtime setup. Eager and training coverage vary by platform.

FlagCX-backed `ProcessGroupFlagOS` supplies collectives and DDP integration.
Profiler and `torch.compile` paths have separate platform limits. Model
validation must record the route exercised and any fallback.

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

## Test Plan

```bash
python -m pytest -q tests/integration/ops/test_flaggems_conf_consistency.py
python -m pytest -q tests/integration/ops/test_flaggems_cpp_dispatch.py
python -m pytest -q tests/integration/ops/test_full_cuda_coverage.py
```

Run live distributed cases from `tests/manual/`, including the Ascend and
MUSA DDP scripts, on the corresponding hardware. Use the checked-in
transformers test automation for model validation. Require successful
forward/backward execution and reference-compatible results for each claimed
workload; record unsupported operations and CPU/vendor fallback separately.

The 90% target needs an explicit operator denominator and observed dispatch
coverage. Wheel acceptance requires installation from the built artifact in a
clean vendor environment with matching package and source versions.

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

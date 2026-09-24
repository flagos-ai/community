# FEP-0090: SGLang Vendor Dispatch, Empty Fallbacks and Test Suites

**Status:** `Implemented`

**Updated:** 2026-09-24

**Created:** 2026-07-30

**Owner:** Unassigned

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| sglang-plugin-fl | [`0.2.0-rc2` @ `1c84db70fc33`](https://github.com/flagos-ai/sglang-plugin-FL/tree/1c84db70fc337569029edb7fce75285c8024e608) | [`v0.2.0-rc2.post1` @ `0f6305218ac7`](https://github.com/flagos-ai/sglang-plugin-FL/tree/0f6305218ac714ee98ff9e6ace679ecc1aa44c49) |

## Summary

SGLang-Plugin-FL 0.2 provides vendor dispatch, FlagCX communication,
Empty-mode kernel fallbacks and unit, functional and end-to-end suites.
CUDA, Ascend and MUSA passed the complete RC2 CI sequence; PPU passed
through inference and concurrency testing.

## Delivered Scope

| Feature | Implementation | Validation |
|---|---|---|
| Vendor dispatch | Platform detection, early patches and backend overrides | CUDA/Ascend/MUSA CI and additional hardware QA |
| PPU route | CUDA-compatible device and operator paths | Unit, functional, inference and concurrency CI passed |
| Empty fallbacks | Reference/Triton paths for selected fused operations | Hygon and MUSA Empty-mode runs recorded |
| Test infrastructure | Unit, functional, inference, concurrency and serving suites | RC2 workflow execution |

## Design

Backend overrides live under `sglang_fl/dispatch/backends/vendor/`.
`DeviceInfo` and early patches handle runtime initialization. The plugin
provides operator hooks and FlagCX communication.

Empty-mode reference and Triton paths replace selected `sgl_kernel` and
`flashinfer` dependencies. They still require the matching vendor runtime.

## Packaging

The RC2 README specifies SGLang 0.5.11; the existing MUSA integration uses a
separate vendor-compatible SGLang line. Record the exact framework commit or
wheel per platform. Later 0.5.18 adaptation PRs are outside this RC2 snapshot.

```bash
python -m pip wheel . --no-build-isolation --no-deps -w dist
```

The branch now declares plugin version `0.2.0`; the manifest tag predates the
version fix. Device-less framework builds still require the vendor runtime
and the corresponding plugin backend.

## Test Commands

```bash
python -m pytest -q tests/unit_tests
python -m pytest -q tests/functional_tests
```

Model cases use `tests/platforms/` and the end-to-end runner. Empty-mode
tests run without `sgl_kernel` and `flashinfer` and record the fallback route.

## Validation

[Workflow 34845525965](https://github.com/flagos-ai/sglang-plugin-FL/actions/runs/34845525965)
at `1c84db70` passed CUDA, Ascend and MUSA unit, functional, inference,
concurrency, serving and benchmark jobs. PPU passed unit, functional,
inference and concurrency jobs.

The [hardware QA matrix](https://jwolpxeehx.feishu.cn/wiki/Kg47wjKm1if8eOk1GfscLiIcnDe) records additional backend and Empty-mode
tests with their operator exclusions and model configurations.

## Known Limitations

PPU's serving CI job failed and its benchmark was skipped. Extended testing
recorded Ascend vendor GroupedMatmul crashes, a 43-operation exclusion list
on Kunlunxin, and memory-growth observations in MUSA Empty and Iluvatar
runs. These configurations do not have unconditional stability acceptance.

## Related PRs

- [x] [sglang-plugin-FL#26](https://github.com/flagos-ai/sglang-plugin-FL/pull/26) — FlagCX communication replacement for pipeline parallelism. Merged.
- [x] [sglang-plugin-FL#27](https://github.com/flagos-ai/sglang-plugin-FL/pull/27) — PPU CUDA-compatible routing. Merged.
- [x] [sglang-plugin-FL#32](https://github.com/flagos-ai/sglang-plugin-FL/pull/32) — FlagCX on Ascend and MUSA. Merged.
- [x] [sglang-plugin-FL#33](https://github.com/flagos-ai/sglang-plugin-FL/pull/33) — Tsingmicro backend. Merged.
- [x] [sglang-plugin-FL#34](https://github.com/flagos-ai/sglang-plugin-FL/pull/34) — Iluvatar backend. Merged.
- [x] [sglang-plugin-FL#35](https://github.com/flagos-ai/sglang-plugin-FL/pull/35) — Hygon backend. Merged.
- [x] [sglang-plugin-FL#41](https://github.com/flagos-ai/sglang-plugin-FL/pull/41) — Kunlunxin backend. Merged.
- [x] [sglang-plugin-FL#42](https://github.com/flagos-ai/sglang-plugin-FL/pull/42) — Enflame backend. Merged.
- [x] [sglang-plugin-FL#43](https://github.com/flagos-ai/sglang-plugin-FL/pull/43) — Empty-device reference fallbacks. Merged.
- [x] [sglang-plugin-FL#64](https://github.com/flagos-ai/sglang-plugin-FL/pull/64) — PPU CI. Merged.
- [x] [sglang-plugin-FL#66](https://github.com/flagos-ai/sglang-plugin-FL/pull/66) — Multi-accelerator functional tests. Merged.
- [x] [sglang-plugin-FL#73](https://github.com/flagos-ai/sglang-plugin-FL/pull/73) — DeviceInfo and early vendor patches. Merged.
- [x] [sglang-plugin-FL#119](https://github.com/flagos-ai/sglang-plugin-FL/pull/119) — RC2 package version update. Merged.

## Deferred to FlagOS 2.3

- MetaX integration: [sglang-plugin-FL#50](https://github.com/flagos-ai/sglang-plugin-FL/pull/50).
- Ascend Empty integration and the complete three-vendor Empty matrix: [sglang-plugin-FL#74](https://github.com/flagos-ai/sglang-plugin-FL/pull/74).
- Full ten-vendor coverage, including the Hygon CI integration in [#75](https://github.com/flagos-ai/sglang-plugin-FL/pull/75), merged outside RC2.
- PD-disaggregation model acceptance for the FlagCX KV-transfer path in [#59](https://github.com/flagos-ai/sglang-plugin-FL/pull/59).

# FEP-0090: SGLang-Plugin-FL Features for FlagOS 2.2

**Status:** `Implementable`

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

SGLang-Plugin-FL 0.2 extends vendor dispatch, communication and Empty-build
support, with unit, functional and end-to-end test infrastructure. RC2 still
lacks MetaX integration and a completed three-vendor Empty-mode matrix.

## Goals and Completion

| Goal | RC2 implementation | Remaining work |
|---|---|---|
| G1: Ten vendors | Ascend, CUDA, Enflame, Hygon, Iluvatar, Kunlunxin, MUSA and TXDA directories; PPU uses the CUDA-compatible route | MetaX implementation and complete vendor/model acceptance |
| G2: Empty mode on at least three vendors | Reference/Triton fused-op fallbacks from PR #43 | Ascend Empty PR #74 and three-vendor release results |
| G3: Unit, functional and end-to-end suites | All three suites, benchmarks and CUDA/Ascend/MUSA/PPU platform configurations present | Complete runs on the claimed vendor matrix |

The RC2 source includes PR #43 and the later package-version fix #119.
Hygon CI PR #75 is merged upstream but is absent from this RC2 snapshot.

## Design

The plugin supplies ATen/operator dispatch, fused-kernel hooks and FlagCX
communication. Vendor overrides live under
`sglang_fl/dispatch/backends/vendor/`. `DeviceInfo` and early patches handle
runtime differences that operator dispatch cannot express.

Empty-mode reference and Triton fallbacks remove selected dependencies on
`sgl_kernel` and `flashinfer`. Ascend's separate Empty-mode integration is not
merged into RC2.

The FlagCX KV-transfer backend enables upstream SGLang PD-disaggregation
through `--disaggregation-transfer-backend flagcx`. Its model-level acceptance
is separate from collective unit tests.

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

## Test Plan

```bash
python -m pytest -q tests/unit_tests
python -m pytest -q tests/functional_tests
```

Run model inference and serving cases through the platform configuration under
`tests/platforms/` and the checked-in end-to-end runner. The RC2 CI platform
files cover CUDA, Ascend, MUSA and PPU. Require reference-compatible operator
results, correct collectives, graph capture where supported, and successful
model inference/serving.

For Empty-mode acceptance, run the same workloads without `sgl_kernel` and
`flashinfer`, verify the selected fallback route and report results separately
for each vendor. Three-vendor acceptance and MetaX coverage remain pending.

## Recorded Validation

[RC2 workflow 34845525965](https://github.com/flagos-ai/sglang-plugin-FL/actions/runs/34845525965)
at `1c84db70` passed CUDA, Ascend and MUSA unit, functional, inference,
concurrency, serving and benchmark jobs. PPU passed unit, functional,
inference and concurrency tests; its serving job failed and its benchmark
was skipped.

The [release execution record](https://jwolpxeehx.feishu.cn/wiki/Kg47wjKm1if8eOk1GfscLiIcnDe) contains additional passing hardware
runs. Twelve-hour testing is an extra QA exercise beyond the developer test
plan: several platforms completed it, while Ascend's vendor GroupedMatmul
crashed. Kunlunxin used a 43-operation exclusion list; MUSA Empty and
Iluvatar runs retain memory-growth observations. These runs must be read
with their recorded configurations, rather than as unconditional platform
acceptance. MetaX and the complete three-vendor Empty matrix remain open.

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
- [ ] [sglang-plugin-FL#50](https://github.com/flagos-ai/sglang-plugin-FL/pull/50) — MetaX support. Open.
- [x] [sglang-plugin-FL#59](https://github.com/flagos-ai/sglang-plugin-FL/pull/59) — FlagCX KV transfer for PD disaggregation. Merged.
- [x] [sglang-plugin-FL#64](https://github.com/flagos-ai/sglang-plugin-FL/pull/64) — PPU CI. Merged.
- [x] [sglang-plugin-FL#66](https://github.com/flagos-ai/sglang-plugin-FL/pull/66) — Multi-accelerator functional tests. Merged.
- [x] [sglang-plugin-FL#73](https://github.com/flagos-ai/sglang-plugin-FL/pull/73) — DeviceInfo and early vendor patches. Merged.
- [ ] [sglang-plugin-FL#74](https://github.com/flagos-ai/sglang-plugin-FL/pull/74) — Ascend Empty mode. Open.
- [x] [sglang-plugin-FL#75](https://github.com/flagos-ai/sglang-plugin-FL/pull/75) — Hygon CI; outside the inspected RC2 snapshot. Merged.
- [x] [sglang-plugin-FL#119](https://github.com/flagos-ai/sglang-plugin-FL/pull/119) — RC2 package version update. Merged.

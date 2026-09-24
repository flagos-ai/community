# FEP-0089: vLLM-Plugin-FL Features for FlagOS 2.2

**Status:** `Implementable`

**Updated:** 2026-09-24

**Created:** 2026-07-30

**Owner:** Unassigned

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| vllm-plugin-fl-0.2 | [`0.2.2-rc2` @ `675548ab2ee5`](https://github.com/flagos-ai/vllm-plugin-FL/tree/675548ab2ee52b8124b0b6a82a2f795c0553e1fa) | [`v0.2.2-rc2.post3` @ `675548ab2ee5`](https://github.com/flagos-ai/vllm-plugin-FL/tree/675548ab2ee52b8124b0b6a82a2f795c0553e1fa) |
| vllm-plugin-fl | [`0.3.0-rc2` @ `f1052770d3ff`](https://github.com/flagos-ai/vllm-plugin-FL/tree/f1052770d3ff2666d86f46d1779648dba62b2cbc) | [`v0.3.0-rc2.post3` @ `f1052770d3ff`](https://github.com/flagos-ai/vllm-plugin-FL/tree/f1052770d3ff2666d86f46d1779648dba62b2cbc) |

## Summary

Maintain vLLM 0.20.2 and 0.24.0 plugin lines, expand vendor integration and
support device-less vLLM builds. RC2 contains both version lines and additional
vendor ports. Automatic performance-based operator selection remains
unimplemented in the release policy.

## Goals and Completion

| Goal | RC2 implementation | Remaining work |
|---|---|---|
| G1: Ten vendors on vLLM 0.20.2 | Vendor dispatch, compatibility patches and platform tests in `0.2.2-rc2` | Basic model tests passed on the listed vendor/version rows; retain stress-test exceptions |
| G2: Five vendors on vLLM 0.24.0 | `0.3.0-rc2` contains MUSA, Iluvatar, Ascend, Kunlunxin, MetaX, GCU, MLU, Sunrise, PPU and TXDA paths in addition to CUDA | Basic model tests passed; results and limits recorded below |
| G3: Empty build | Device-less build instructions and plugin-owned device/operator integration present | Empty-build runs recorded; retain each environment's operator exclusions |
| G4: Operator auto-tuning | Configurable dispatch policy and throughput benchmark present | Measured implementation selection, result persistence and performance acceptance |

## Design

Vendor implementations are under `vllm_fl/dispatch/backends/vendor/`.
CUDA-compatible vendors may share a route, so backend directories do not
represent independent acceptance results.

The Empty build keeps the vLLM framework device-neutral. The plugin supplies
platform detection, operator dispatch and FlagCX communication; the target
accelerator runtime is still required.

`vllm_fl/dispatch/policy.py` implements configured preference and per-operator
order among FlagOS, vendor and reference implementations. The existing
`benchmarks/benchmark_throughput_autotune.py` is a measurement harness; RC2
still needs the proposed automatic runtime selection and persistence path.

RC2 fixes include device binding for MUSA workers, symmetric-memory import
compatibility, vendor ports and worker shutdown. Arm64 W4A8 is included in the
0.24.0 line and tracked separately by [FEP-0083](../sig-edge/0083-vllm_plugin_in_support_arm_CPU.md).

## Packaging

Build the plugin on its matching vLLM line:

| Plugin branch | vLLM dependency |
|---|---|
| `0.2.2-rc2` | `0.20.2` |
| `0.3.0-rc2` | `0.24.0` |

```bash
python -m pip wheel . --no-build-isolation --no-deps -w dist
```

Vendor SDKs and framework build options follow the branch's installation
instructions and platform CI configuration. Empty-mode validation must use a
device-less framework build.

## Test Plan

On a configured NVIDIA A100 test environment:

```bash
python tests/run.py --platform cuda --device a100 --scope unit
python tests/run.py --platform cuda --device a100 --scope functional
python tests/run.py --platform cuda --device a100 --scope e2e
```

Use the matching `tests/platforms/*.yaml` entry for each other platform and
run both release lines where claimed. Model cases are under `tests/models/`.
Require operator correctness, collective correctness, inference and HTTP
serving results; record skipped cases, precision and TP settings.

For G3, repeat inference on the Empty build and verify the plugin route is
used. For G4, a future tuning implementation must reproduce its saved
selection and match or exceed the default configuration on a fixed workload.
G4 has no executable RC2 acceptance path yet.

## Recorded Validation

The [September 24 execution matrix](https://jwolpxeehx.feishu.cn/wiki/Kg47wjKm1if8eOk1GfscLiIcnDe) records passing basic inference
for Qwen3.6-35B-A3B and Qwen3.6-27B across 17 vendor/version rows. Hygon,
MetaX, Iluvatar, PPU, MUSA and Kunlunxin have completed functional,
performance and stress tests in the reported configurations.

The same record lists Ascend NaNs, Sunrise image-output errors and a
Tsingmicro environment failure in stress testing; Enflame stress testing
was still running. These limits coexist with the passing basic tests.
Automatic measured operator selection remains a distinct undelivered goal.

## Related PRs

- [x] [vllm-plugin-FL#307](https://github.com/flagos-ai/vllm-plugin-FL/pull/307) — Ascend vLLM 0.20.2 upgrade. Merged.
- [x] [vllm-plugin-FL#308](https://github.com/flagos-ai/vllm-plugin-FL/pull/308) — MUSA vLLM 0.24.0 integration. Merged.
- [x] [vllm-plugin-FL#310](https://github.com/flagos-ai/vllm-plugin-FL/pull/310) — Iluvatar vLLM 0.24.0 integration. Merged.
- [x] [vllm-plugin-FL#333](https://github.com/flagos-ai/vllm-plugin-FL/pull/333) — FlagGems KV-cache routing on the 0.20.2 line. Merged.
- [x] [vllm-plugin-FL#387](https://github.com/flagos-ai/vllm-plugin-FL/pull/387) — Ascend port to the 0.24.0 line. Merged.
- [x] [vllm-plugin-FL#401](https://github.com/flagos-ai/vllm-plugin-FL/pull/401) — Kunlunxin port to the 0.24.0 line. Merged.
- [x] [vllm-plugin-FL#431](https://github.com/flagos-ai/vllm-plugin-FL/pull/431) — Cambricon compatibility on the 0.24.0 line. Merged.
- [x] [vllm-plugin-FL#432](https://github.com/flagos-ai/vllm-plugin-FL/pull/432) — Enflame compatibility on the 0.24.0 line. Merged.
- [x] [vllm-plugin-FL#433](https://github.com/flagos-ai/vllm-plugin-FL/pull/433) — Arm64 packed W4A8 integration. Merged.
- [x] [vllm-plugin-FL#460](https://github.com/flagos-ai/vllm-plugin-FL/pull/460) — TXDA support on the 0.24.0 line. Merged.
- [x] [vllm-plugin-FL#537](https://github.com/flagos-ai/vllm-plugin-FL/pull/537) — MUSA worker device binding. Merged.
- [x] [vllm-plugin-FL#549](https://github.com/flagos-ai/vllm-plugin-FL/pull/549) — Symmetric-memory import fallback. Merged.
- [x] [vllm-plugin-FL#553](https://github.com/flagos-ai/vllm-plugin-FL/pull/553) — Worker shutdown backport to 0.2.2 RC2. Merged.

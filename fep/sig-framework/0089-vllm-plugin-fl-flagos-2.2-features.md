# FEP-0089: vLLM 0.20.2/0.24.0 Vendor Integration and Empty Builds

**Status:** `Implemented`

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

Maintain the vLLM 0.20.2 and 0.24.0 plugin lines, vendor dispatch and
device-less framework builds. The plugin supplies device operations and
configured operator selection.

## Delivered Scope

| Feature | Implementation | Validation |
|---|---|---|
| vLLM 0.20.2 | `0.2.2-rc2` vendor integrations | Basic model inference in the release matrix |
| vLLM 0.24.0 | `0.3.0-rc2` vendor integrations | Basic model inference in the release matrix |
| Empty builds | Plugin-owned platform, operator and communication routes | Device-less framework runs |
| Operator policy | Configured preference among FlagOS, vendor and reference kernels | Dispatch tests and model execution |

## Design

Vendor implementations are under `vllm_fl/dispatch/backends/vendor/`.
CUDA-compatible vendors may share a route. Empty builds retain the
device-neutral vLLM framework and require the target accelerator runtime.

`vllm_fl/dispatch/policy.py` applies configured kernel preferences. It does
not perform automatic performance measurements or persist tuning decisions.
Arm64 W4A8 is covered by [FEP-0083](../sig-edge/0083-vllm_plugin_in_support_arm_CPU.md).

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

## Test Commands

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

## Validation

The [September 24 matrix](https://jwolpxeehx.feishu.cn/wiki/Kg47wjKm1if8eOk1GfscLiIcnDe) records passing basic inference for
Qwen3.6-35B-A3B and Qwen3.6-27B across 17 vendor/version rows. Hygon, MetaX,
Iluvatar, PPU, MUSA and Kunlunxin completed functional, performance and
stress tests in the listed configurations.

## Known Limitations

Stress testing recorded Ascend NaNs
([FlagGems#6446](https://github.com/flagos-ai/FlagGems/issues/6446),
[FlagTree#1220](https://github.com/flagos-ai/FlagTree/issues/1220)), Sunrise
image-output errors ([FlagGems#6123](https://github.com/flagos-ai/FlagGems/issues/6123))
and a Tsingmicro environment failure. Enflame stress testing was still
running in the September 24 record. The accepted basic-inference matrix does
not establish long-running stability for these configurations.

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

## Deferred to FlagOS 2.3

Automatic per-hardware operator selection, persisted tuning results and comparison against the configured default policy.

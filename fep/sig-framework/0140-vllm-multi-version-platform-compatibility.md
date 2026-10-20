# FEP-0140: Multi-version Platform Compatibility for vLLM-Plugin-FL

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** TODO: @github-username

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Extend [vLLM-Plugin-FL](https://github.com/flagos-ai/vllm-plugin-FL) across three upstream versions: complete the remaining 0.24 adaptations, deliver 0.28 as the main release version, and introduce 0.32 on selected domestic platforms. Ship matching wheels, dependency versions, model configurations and usage documentation.

## Motivation

[FEP-0089](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0089-vllm-plugin-fl-flagos-2.2-features.md) covers vLLM 0.20.2 and the initial 0.24 Empty-mode scope. FlagOS 2.3 completes the remaining platform work and follows newer upstream releases to support Day-0 model adaptation.

### Goals

| Goal | Scope | Planned milestone in 2026 |
|---|---|---|
| G1 — Complete 0.24 | Adapt the remaining five domestic vendors. | Mid-October |
| G2 — Release 0.28 | Support ten domestic vendors on the main release version. | November |
| G3 — Introduce 0.32 | Support five domestic vendors selected by Day-0 demand. | Start mid-November; finish before mid-December |

The G3 upstream version may change with the vLLM release schedule. Update usage documentation with each upgrade. NVIDIA and AMD support is tracked separately from the domestic-vendor targets.

## Proposal

Users choose a version and platform from the compatibility matrix, then use its wheel, runtime and model configuration. Each version has migration instructions and a validated rollback package.

Alongside the release work, support Day-0 adaptation including AMD, review new-model PRs, and contribute model adaptations and operator-coverage tooling to FlagRelease and KT phase 2.

## Design Details

Maintain the three version lines separately. Reconcile the remaining 0.24 work with the 2.2 release matrix, update platform adapters for 0.28 and 0.32 API changes, and run regression tests on each target device.

Each compatibility entry records the vendor/device, upstream patch, plugin version, Python/PyTorch, SDK/driver, FlagGems, applicable FlagTree and communication libraries, plus the model revision, precision, TP/PP and graph settings. Agree dependency versions with the component maintainers and quality team.

**To finalize:** Owner; vendor/device lists for all three goals; exact upstream patches and model configurations; accuracy thresholds and performance regression limits. Select G3's five vendors according to Day-0 demand.

## Packaging

**Supported vendors:** Five remaining domestic vendors for 0.24, ten for 0.28 and five for 0.32. Final names and devices will be recorded in the compatibility matrix.

**Can this feature be packaged as a wheel (`.whl`)?** Yes.

Build from the matching version checkout. For platforms whose runtime does not require `vllm_fl._C`:

```bash
VLLM_VENDOR= python -m build --wheel
```

For platforms using the CUDA native-extension build route, with the matching PyTorch, SDK and build dependencies:

```bash
VLLM_VENDOR=cuda python -m build --wheel --no-isolation
```

Publish the wheel, dependency lock and image recipe for each supported combination. Record the source revision, build settings and artifact digest. At Feature Freeze, provide an rc0 branch/tag with matching package and release-manifest versions.

## Test Plan

Run in each target version/platform environment. Set `FEP_PLATFORM`, `FEP_DEVICE`, `FEP_MODEL` and `FEP_CASE` from that checkout's `tests/platforms` and `tests/models` configurations. Add configurations for newly supported combinations.

### G1–G3: platform compatibility

```bash
python tests/run.py --platform "${FEP_PLATFORM:?}" --device "${FEP_DEVICE:?}" --scope functional
```

**Expected:** Required operator, compilation and communication tests pass on every declared device.

### G1–G3: model inference and serving

```bash
for FEP_TASK in inference serving; do
  python tests/run.py --platform "${FEP_PLATFORM:?}" --device "${FEP_DEVICE:?}" \
    --scope e2e --task "$FEP_TASK" --model "${FEP_MODEL:?}" --case "${FEP_CASE:?}" || exit 1
done
```

**Expected:** Each declared model passes inference and serving checks. For example, the 0.28 Iluvatar configuration provides `iluvatar` / `bi-v150` / `qwen2_5` / `7b_tp2` for both tasks.

Compare model outputs and task scores with the agreed reference. Measure throughput and latency with fixed weights, hardware, precision and workload settings; meet the agreed regression limits. Retain results with the tested artifact and configuration.

All required cases must execute and pass. An empty selection, skipped case or missing result does not satisfy acceptance. Publish a combination only after its wheel loads on the target device and its required tests pass.

## Related PRs

### vLLM 0.28

- [x] [#484](https://github.com/flagos-ai/vllm-plugin-FL/pull/484) — NVIDIA upgrade.
- [x] [#487](https://github.com/flagos-ai/vllm-plugin-FL/pull/487) — Ascend upgrade.
- [x] [#566](https://github.com/flagos-ai/vllm-plugin-FL/pull/566) — Iluvatar BI-V150 support.
- [x] [#574](https://github.com/flagos-ai/vllm-plugin-FL/pull/574) — T-Head upgrade.
- [ ] [#554](https://github.com/flagos-ai/vllm-plugin-FL/pull/554) — MetaX C550 support.
- [ ] [#575](https://github.com/flagos-ai/vllm-plugin-FL/pull/575) — MUSA upgrade.
- [ ] [#576](https://github.com/flagos-ai/vllm-plugin-FL/pull/576) — Hygon upgrade.
- [ ] [#582](https://github.com/flagos-ai/vllm-plugin-FL/pull/582) — Enflame S60 support.
- [ ] [#585](https://github.com/flagos-ai/vllm-plugin-FL/pull/585) — Kunlunxin P800 support.
- [ ] [#613](https://github.com/flagos-ai/vllm-plugin-FL/pull/613) — FlagGems-vllm integration.

### vLLM 0.32

- [ ] [#615](https://github.com/flagos-ai/vllm-plugin-FL/pull/615) — NVIDIA Empty runtime and CI adaptation.

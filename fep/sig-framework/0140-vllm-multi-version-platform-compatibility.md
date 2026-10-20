# FEP-0140: Multi-version Platform Compatibility for vLLM-Plugin-FL

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** TODO: @github-username

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Extend [vLLM-Plugin-FL](https://github.com/flagos-ai/vllm-plugin-FL) across three upstream versions: complete the remaining 0.24 adaptations, deliver 0.28 as the main release version, and introduce 0.32 on selected platforms. Ship matching wheels, dependency versions, model configurations and usage documentation.

## Motivation

[FEP-0089](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0089-vllm-plugin-fl-flagos-2.2-features.md) covers vLLM 0.20.2 and the initial 0.24 Empty-mode scope. FlagOS 2.3 completes the remaining platform work and follows newer upstream releases to support Day-0 model adaptation.

### Goals

| Goal | Scope | Planned milestone in 2026 |
|---|---|---|
| G1 — Complete 0.24 | Close the carry-over adaptations for Huawei Ascend, Kunlunxin, Enflame, Tsingmicro and Sunrise. | Mid-October |
| G2 — Release 0.28 | Support the ten vendors in the matrix below on the main release version. | November |
| G3 — Introduce 0.32 | Support five vendors selected by Day-0 demand; the roster is pending. | Start mid-November; finish before mid-December |

The G3 upstream version may change with the vLLM release schedule. Update usage documentation in the plugin repository with each upgrade. NVIDIA regression coverage and AMD Day-0 work are additional to the ten-vendor roster.

## Proposal

Users choose a version and platform from the compatibility matrix, then use its wheel, runtime and model configuration. Each version has migration instructions and a validated rollback package.

Alongside the release work, support Day-0 adaptation including AMD, review new-model PRs, and contribute model adaptations and operator-coverage tooling to FlagRelease and KT phase 2.

## Design Details

Maintain the three version lines separately. Reconcile the remaining 0.24 work with the 2.2 release matrix, update platform adapters for 0.28 and 0.32 API changes, and run regression tests on each target device.

Each compatibility entry records the vendor/device, upstream patch, plugin version, Python/PyTorch, SDK/driver, FlagGems, applicable FlagTree and communication libraries, plus the model revision, precision, TP/PP and graph settings. Agree dependency versions with the component maintainers and quality team.

### Vendor matrix

The 0.24 baseline covers Moore Threads, T-Head, Hygon, MetaX and Iluvatar. G1 completes coverage of the same ten-vendor roster used by G2. The carry-over group records the original release scope; several adaptations have since merged.

| Vendor | 0.24 scope and integration | 0.28 integration | 0.32 selection |
|---|---|---|---|
| Huawei Ascend | Carry-over; Qwen3.6/graph update in review ([#606](https://github.com/flagos-ai/vllm-plugin-FL/pull/606)) | Merged ([#487](https://github.com/flagos-ai/vllm-plugin-FL/pull/487)) | Pending |
| T-Head | 2.2 baseline | Merged ([#574](https://github.com/flagos-ai/vllm-plugin-FL/pull/574)) | Pending |
| Hygon | 2.2 baseline | In review ([#576](https://github.com/flagos-ai/vllm-plugin-FL/pull/576)) | Pending |
| Moore Threads | 2.2 baseline | In review ([#575](https://github.com/flagos-ai/vllm-plugin-FL/pull/575)) | Pending |
| MetaX | 2.2 baseline | In review ([#554](https://github.com/flagos-ai/vllm-plugin-FL/pull/554)) | Pending |
| Kunlunxin | Carry-over; merged ([#516](https://github.com/flagos-ai/vllm-plugin-FL/pull/516), [#561](https://github.com/flagos-ai/vllm-plugin-FL/pull/561)) | In review ([#585](https://github.com/flagos-ai/vllm-plugin-FL/pull/585)) | Pending |
| Iluvatar | 2.2 baseline | Merged ([#566](https://github.com/flagos-ai/vllm-plugin-FL/pull/566)) | Pending |
| Enflame | Carry-over; merged ([#464](https://github.com/flagos-ai/vllm-plugin-FL/pull/464)) | In review ([#582](https://github.com/flagos-ai/vllm-plugin-FL/pull/582)) | Pending |
| Tsingmicro | Carry-over; merged ([#447](https://github.com/flagos-ai/vllm-plugin-FL/pull/447)) | Upgrade pending | Pending |
| Sunrise | Carry-over; merged ([#391](https://github.com/flagos-ai/vllm-plugin-FL/pull/391)) | Upgrade pending | Pending |
| NVIDIA (additional) | Existing support | Merged ([#484](https://github.com/flagos-ai/vllm-plugin-FL/pull/484)) | Adaptation in draft ([#615](https://github.com/flagos-ai/vllm-plugin-FL/pull/615)) |

Integration status tracks repository changes; release support requires the device/model tests below. The five G3 vendors have not been selected. The `0.5.0-dev` base still pins vLLM 0.28; its inherited platform list does not establish 0.32 support.

**To finalize:** Owner; devices and model configurations for the named vendors; G3's five-vendor roster; exact upstream patches; accuracy thresholds and performance regression limits.

## Packaging

**Supported vendors:** The matrix above defines the ten-vendor scope for 0.24 and 0.28, with NVIDIA regression coverage in addition. The 0.32 five-vendor roster remains to be selected.

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

### vLLM 0.24 carry-over work

- [x] [#391](https://github.com/flagos-ai/vllm-plugin-FL/pull/391) — Sunrise attention backend.
- [x] [#447](https://github.com/flagos-ai/vllm-plugin-FL/pull/447) — Tsingmicro TXDA backend.
- [x] [#464](https://github.com/flagos-ai/vllm-plugin-FL/pull/464) — Enflame S60 adaptation.
- [x] [#516](https://github.com/flagos-ai/vllm-plugin-FL/pull/516) — Kunlunxin adaptation.
- [x] [#561](https://github.com/flagos-ai/vllm-plugin-FL/pull/561) — Kunlunxin P800 CI.
- [ ] [#606](https://github.com/flagos-ai/vllm-plugin-FL/pull/606) — Ascend Qwen3.6 and full-decode graphs.

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

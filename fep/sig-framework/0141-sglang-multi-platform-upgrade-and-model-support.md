# FEP-0141: SGLang Multi-platform Upgrade and Model Support

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** TODO: @github-username

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Release three capabilities in [SGLang-Plugin-FL](https://github.com/flagos-ai/sglang-plugin-FL): a ten-vendor upgrade to SGLang 0.5.18, Empty mode on seven remaining vendors using 0.5.11/0.5.12, and DeepSeek-V4 W8A8 inference and optimization on 0.5.18.

## Motivation

[FEP-0090](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0090-sglang-plugin-fl-flagos-2.2-features.md) covers the 0.5.11/0.5.12 platform baseline and initial Empty-mode scope. FlagOS 2.3 expands that coverage, updates upstream integration and adds leading-model support.

### Goals

| Goal | Scope | Planned milestone in 2026 |
|---|---|---|
| G1 — Platform upgrade | SGLang 0.5.18 on ten vendors, including NVIDIA, Huawei Ascend 910C, Moore Threads, T-Head and MetaX. | Before mid-December |
| G2 — Empty mode | Seven remaining vendors, including Hygon, Iluvatar and Enflame; Qwen3.6-27B and Qwen3.6-35B-A3B on 0.5.11/0.5.12. | Integration follows operator coverage and accuracy readiness. |
| G3 — W8A8 models | DeepSeek-V4-Flash and DeepSeek-V4-Pro on 0.5.18; optimize on NVIDIA and extend to at least one domestic platform. | Model adaptation in early/mid-November; optimization by end-December |

G3 targets a 10% overall throughput improvement on NVIDIA. The two DeepSeek variants are the planned models; finalize checkpoints and any model changes before acceptance.

## Proposal

Users select a feature, platform and model from the support matrix. G1 and G3 use 0.5.18; G2 retains 0.5.11/0.5.12. Each combination supplies matching packages, dependencies and launch settings.

Alongside the release work, support Day-0 adaptation and new-model PR review, FlagRelease model adaptation and operator-coverage tooling, and the Zhipu–Ascend project for large-scale prefill/decode disaggregation optimization.

## Design Details

### Platform upgrade

Update upstream adapters and preserve plugin entry points. Agree exact FlagTree, FlagGems, vendor SDK and other runtime versions with their maintainers and quality team. Record the device, model revision, precision, TP/PP and graph settings for each combination, and retain a validated rollback package.

### Empty mode

Integrate FlagGems/flaggems-sglang operators and dispatch on the selected 0.5.11/0.5.12 base. The operator team must supply all operators required by both Qwen models and align their accuracy before framework acceptance.

Derive the coverage list from both workloads and verify successful execution through the supplied operator implementations. Temporary vendor fallbacks may support integration work, but unresolved operator gaps block G2 completion. Keep vendor device runtimes and communication dependencies explicit.

### W8A8 inference and optimization

Match checkpoint layouts and scales to attention/MoE kernels and tensor parallelism. Validate both DeepSeek variants on NVIDIA and the selected domestic platform. Compare the baseline and optimized configurations using identical weights, precision, workload and hardware.

**To finalize:** Owner; complete vendor/device lists; runtime pins; model/checkpoint revisions; Empty operator delivery and integration dates; W8A8 baseline, accuracy thresholds and performance regression limits.

## Packaging

**Supported vendors:** G1 covers ten including NVIDIA; G2 covers seven remaining vendors including Hygon, Iluvatar and Enflame; G3 covers NVIDIA and at least one domestic vendor.

**Can this feature be packaged as a wheel (`.whl`)?** Yes. Build from the matching version checkout:

```bash
python -m build --wheel
```

Publish version-specific wheels, dependency locks and image recipes. Empty packages retain 0.5.11/0.5.12; upgrade and W8A8 packages use 0.5.18. Include W8A8 checkpoint formats, scales and kernel requirements. Record source revisions, build settings and artifact digests; align the rc0 tag, package version and release manifest at Feature Freeze.

## Test Plan

Run each feature in its declared version/platform environment. Set `FEP_PLATFORM`, `FEP_DEVICE`, `FEP_MODEL` and `FEP_CASE` from the corresponding test configurations. All required cases must execute and pass; empty selections, skips and missing results remain incomplete.

### G1: platform and model regression

```bash
python tests/run.py --platform "${FEP_PLATFORM:?}" --device "${FEP_DEVICE:?}" --scope functional || exit 1
for FEP_TASK in inference serving concurrent; do
  python tests/run.py --platform "${FEP_PLATFORM:?}" --device "${FEP_DEVICE:?}" \
    --scope e2e --task "$FEP_TASK" --model "${FEP_MODEL:?}" --case "${FEP_CASE:?}" || exit 1
done
```

**Expected:** Required operator, compilation and communication checks pass. Each declared model completes inference, serving and concurrency tests on all ten vendors, meeting the agreed quality and regression limits.

### G2: Empty mode and operator coverage

Register both Qwen cases on every G2 platform. Existing case definitions use TP4 with graph execution disabled:

```bash
for FEP_TASK in inference serving concurrent; do
  python tests/run.py --platform "${FEP_PLATFORM:?}" --device "${FEP_DEVICE:?}" \
    --scope e2e --task "$FEP_TASK" --model qwen3_6 \
    --cases '[{"model":"qwen3_6","case":"27b_tp4_nograph"},{"model":"qwen3_6","case":"35b_a3b_tp4_nograph"}]' || exit 1
done
```

**Expected:** Both Qwen models pass all three tasks on each of the seven vendors using its declared 0.5.11/0.5.12 runtime.

Planned acceptance tests to implement with the operator integration:

```bash
python -m pytest tests/acceptance_flagos23/test_sglang_empty_operator_routes.py tests/acceptance_flagos23/test_sglang_empty_accuracy.py -v
```

**Expected:** Every required operator has a working implementation in the supplied operator library; dispatch uses those implementations, and both models meet the agreed output and task-score tolerances. Missing coverage or unresolved vendor fallbacks fail acceptance.

### G3: W8A8 correctness and performance

Planned tests and benchmark matrix to implement with the W8A8 adaptation:

```bash
python -m pytest tests/acceptance_flagos23/test_deepseek_v4_w8a8.py -v
python tests/acceptance_flagos23/benchmark_deepseek_v4_w8a8.py --matrix acceptance/flagos23/deepseek-v4-w8a8.yaml
```

**Expected:** Both DeepSeek variants load through the intended W8A8 paths and pass quality and TP consistency checks on NVIDIA and at least one domestic platform. After warm-up, repeat paired runs with real weights and report output tokens/s, TTFT, TPOT, memory and variability. Report progress against the NVIDIA 1.10× throughput target and report domestic-platform results separately.

## Related PRs

### SGLang 0.5.18

- [x] [#89](https://github.com/flagos-ai/sglang-plugin-FL/pull/89) — NVIDIA upgrade.
- [x] [#95](https://github.com/flagos-ai/sglang-plugin-FL/pull/95) — MUSA Empty runtime.
- [x] [#99](https://github.com/flagos-ai/sglang-plugin-FL/pull/99) — NVIDIA CI.
- [x] [#123](https://github.com/flagos-ai/sglang-plugin-FL/pull/123) — CUDA multi-node stability.
- [x] [#132](https://github.com/flagos-ai/sglang-plugin-FL/pull/132) — Iluvatar fused operators.
- [ ] [#131](https://github.com/flagos-ai/sglang-plugin-FL/pull/131) — Ascend upgrade.
- [ ] [#138](https://github.com/flagos-ai/sglang-plugin-FL/pull/138) — Hygon Empty upgrade.
- [ ] [#139](https://github.com/flagos-ai/sglang-plugin-FL/pull/139) — Iluvatar Empty upgrade.

### Empty operators and dispatch on main

- [ ] [#120](https://github.com/flagos-ai/sglang-plugin-FL/pull/120) — FlagGems FLA and fused MoE operators.
- [ ] [#124](https://github.com/flagos-ai/sglang-plugin-FL/pull/124) — Hygon integration with reference fallbacks.
- [ ] [#125](https://github.com/flagos-ai/sglang-plugin-FL/pull/125) — MUSA Qwen3.6 release and performance paths.
- [ ] [#129](https://github.com/flagos-ai/sglang-plugin-FL/pull/129) — Successful dispatch and fallback logging.
- [ ] [#136](https://github.com/flagos-ai/sglang-plugin-FL/pull/136) — Kunlunxin Empty support.
- [ ] [#145](https://github.com/flagos-ai/sglang-plugin-FL/pull/145) — PPU Empty support.

Operator-library scope: [FlagGems-sglang FEP, community #106](https://github.com/flagos-ai/community/pull/106).

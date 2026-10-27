# FEP-0140: Multi-version Platform Compatibility for vLLM-Plugin-FL

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** TODO: @github-username

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Extend [vLLM-Plugin-FL](https://github.com/flagos-ai/vllm-plugin-FL) across upstream versions: complete the remaining 0.24 adaptations and deliver 0.32 as the main release version on all supported chips, adding AMD to the vendor roster. 0.28 is skipped as a release version; its merged adaptations remain in-tree as the upgrade baseline for 0.32. Provide matching deployment instructions, dependency versions and model configurations.

## Motivation

[FEP-0089](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0089-vllm-plugin-fl-flagos-2.2-features.md) covers vLLM 0.20.2 and the initial 0.24 Empty-mode scope. FlagOS 2.3 completes the remaining platform work and follows newer upstream releases to support Day-0 model adaptation.

### Goals

| Goal | Scope | Planned milestone in 2026 |
|---|---|---|
| G1 — Complete 0.24 | Complete the FlagOS 2.3 adaptations for Huawei Ascend, Kunlunxin, Enflame, Tsingmicro and Sunrise. | Mid-October |
| G2 — Release 0.32 on all chips | Support the full vendor matrix below — the ten 2.2-cycle vendors plus NVIDIA and AMD — on 0.32 as the main release version. 0.28 is skipped as a release version; its merged adaptations serve as the upgrade baseline. | Start mid-November; finish before mid-December |

### Non-Goals

- **0.28 as a release version.** The 0.28 line was the planned main release version in earlier drafts; FlagOS 2.3 skips it in favor of 0.32. Merged 0.28 adaptations stay in-tree as the stepping stone for the 0.32 upgrade, but 0.28 receives no further platform work, release testing or deployment documentation.

## Design Details

Maintain the 0.24 and 0.32 version lines separately. Reconcile the remaining 0.24 work with the 2.2 release matrix, carry the merged 0.28 adaptations forward as the upgrade baseline, update platform adapters for 0.32 API changes, and run regression tests on each target device.

Each compatibility entry records the vendor/device, upstream patch, plugin version, Python/PyTorch, SDK/driver, FlagGems, applicable FlagTree and communication libraries, plus the model revision, precision, TP/PP and graph settings. Agree dependency versions with the component maintainers and quality team.

### Vendor matrix

The 0.24 baseline covers Moore Threads, T-Head, Hygon, MetaX and Iluvatar. G1 completes coverage of the same ten-vendor roster. G2 releases 0.32 on the full matrix — the ten vendors plus NVIDIA and AMD. The 0.28 column records merged upgrade work kept as the 0.32 baseline; it is not a release target.

| Vendor | 0.24 scope and integration | 0.28 integration (baseline only) | 0.32 (release version) |
|---|---|---|---|
| Huawei Ascend | 2.3 Adapting; In review ([#606](https://github.com/flagos-ai/vllm-plugin-FL/pull/606)) | Merged ([#487](https://github.com/flagos-ai/vllm-plugin-FL/pull/487)) | Planned |
| T-Head | 2.2 baseline | Merged ([#574](https://github.com/flagos-ai/vllm-plugin-FL/pull/574)) | Planned |
| Hygon | 2.2 baseline | In review ([#576](https://github.com/flagos-ai/vllm-plugin-FL/pull/576)) | Planned |
| Moore Threads | 2.2 baseline | In review ([#575](https://github.com/flagos-ai/vllm-plugin-FL/pull/575)) | Planned |
| MetaX | 2.2 baseline | In review ([#554](https://github.com/flagos-ai/vllm-plugin-FL/pull/554)) | Planned |
| Kunlunxin | 2.3 Adapting; Merged ([#516](https://github.com/flagos-ai/vllm-plugin-FL/pull/516), [#561](https://github.com/flagos-ai/vllm-plugin-FL/pull/561)) | In review ([#585](https://github.com/flagos-ai/vllm-plugin-FL/pull/585)) | Planned |
| Iluvatar | 2.2 baseline | Merged ([#566](https://github.com/flagos-ai/vllm-plugin-FL/pull/566)) | Planned |
| Enflame | 2.3 Adapting; Merged ([#464](https://github.com/flagos-ai/vllm-plugin-FL/pull/464)) | In review ([#582](https://github.com/flagos-ai/vllm-plugin-FL/pull/582)) | Planned |
| Tsingmicro | 2.3 Adapting; Merged ([#447](https://github.com/flagos-ai/vllm-plugin-FL/pull/447)) | Upgrade pending | Planned |
| Sunrise | 2.3 Adapting; Merged ([#391](https://github.com/flagos-ai/vllm-plugin-FL/pull/391)) | Upgrade pending | Planned |
| NVIDIA (additional) | Existing support | Merged ([#484](https://github.com/flagos-ai/vllm-plugin-FL/pull/484)) | Adaptation in draft ([#615](https://github.com/flagos-ai/vllm-plugin-FL/pull/615)) |
| AMD (new in 2.3) | — | — | Planned |

## Test Plan

Use the FlagOS 2.2 release-test workflow for G1–G2. The 2.2 tests documented in the platform manuals use vendor or FlagOS images, with source installation or updates to the plugin and dependencies as needed. Follow this deployment method for each target vLLM version and chip, with matching plugin, driver, SDK, FlagGems and FlagTree versions. Record any component changes made after starting the container.

Keep Qwen3.6-27B (Dense) and Qwen3.6-35B-A3B (MoE) as the baseline models, using real weights. Add model-specific cases for Day-0 adaptations.

| Test | Method | Expected result |
|---|---|---|
| Installation and loading | Start the target image, check the installed vLLM, plugin, FlagGems and FlagTree versions, and install the target plugin revision when needed. | Components load, versions match the test configuration, and the service uses the FL plugin. |
| Basic functionality | Test both models with text, image and mixed requests, including eight concurrent requests. Run eager and graph configurations supported by the target platform. | Answers pass the case checks, without empty, garbled or repetitive output. Graph configurations complete graph capture and inference. |
| Performance | Measure throughput, time to first token (TTFT) and time per output token (TPOT) after warmup. | All requests complete; record mean and P99 latency and compare results with the previous release on the same chip and workload. |
| Load | Vary request concurrency within the target device's workload range and record the settings. | No failed requests, out-of-memory errors or hangs within the configured workload. |
| 24-hour stability and resources | Run sustained requests while sampling device memory and utilization every five seconds. | No service crash, hang, NaN errors or sustained memory growth; retain request results and resource logs. |

### G1–G2: installation and load checks

Use the platform's image and device-mount settings. Inside the container, keep preinstalled components whose versions match the test configuration. To update the plugin, use its target version checkout and follow the [README installation steps](https://github.com/flagos-ai/vllm-plugin-FL#quick-start).

For the Python-only installation:

```bash
VLLM_VENDOR= python -m pip install --no-build-isolation --no-deps -e .
```

For configurations requiring `vllm_fl._C`, use the native-extension installation instead:

```bash
VLLM_VENDOR=cuda python -m pip install --no-build-isolation --no-deps -e .
python -c "import vllm_fl._C"
```

Verify the installed components:

```bash
python - <<'PY'
from importlib.metadata import version
import vllm, vllm_fl, flag_gems, triton
print("vLLM:", vllm.__version__)
print("Plugin:", version("vllm-plugin-fl"), vllm_fl.__file__)
print("FlagGems:", flag_gems.__version__)
print("Triton:", triton.__version__, triton.__file__)
PY
```

**Expected:** Installation and imports succeed; the versions and module paths match the test configuration. Native-extension configurations also import `vllm_fl._C` successfully. Check the service startup log for FL plugin activation and the selected device backend.

### G1–G2: basic functionality

Use the repository's `tools/adaptation-gate-cases` scripts. With the platform's runtime and device settings loaded, start a service from the plugin checkout:

```bash
cd tools/adaptation-gate-cases
MODEL_PATH=/models/Qwen3.6-27B PORT=8000 TENSOR_PARALLEL_SIZE=2 \
  ./run_serve_eager.sh
```

In a second terminal, run the tests from the same checkout:

```bash
cd tools/adaptation-gate-cases
MODEL_PATH=/models/Qwen3.6-27B PORT=8000 ./run_test.sh
```

Repeat for Qwen3.6-35B-A3B, adjusting the model path and tensor-parallel size for the device. For graph coverage, stop the eager service, start `run_serve_graph.sh` on port 8001 and run the same tests against port 8001.

**Expected:** Each model/mode run passes all five scenarios: single text, single image, concurrent text, concurrent image and mixed requests. These send 26 requests in total. Keep the generated JSON results for each model and mode.

### G1–G2: performance, load and stability

Against the running service, use the same benchmark settings as the 2.2 performance tests:

```bash
vllm bench serve --host 127.0.0.1 --port 8000 \
  --backend openai --endpoint /v1/completions \
  --model /models/Qwen3.6-27B --tokenizer /models/Qwen3.6-27B \
  --dataset-name random --random-input-len 4096 --random-output-len 1024 \
  --num-prompts 640 --max-concurrency 64 --seed 0 \
  --ignore-eos --trust-remote-code --save-result --result-dir ./perf-results
```

Run once for warmup and three times for measurement. Repeat with input length 16384, then for the other model and supported execution modes. Keep the input/output lengths, model weights, precision and card count fixed when comparing releases. Repeat with the previous compatible FlagGems/FlagTree versions to check the effect of dependency upgrades.

For load testing, vary `--max-concurrency` within the target device's workload range. For stability testing, repeat the workload continuously for 24 hours and collect device memory and utilization with the vendor's monitoring tool.

**Expected:** Each benchmark round completes all 640 requests. Save throughput, mean/P99 TTFT and TPOT, and the 24-hour service and resource logs. Investigate performance regressions before release.

## Related PRs

### vLLM 0.24 adaptations for FlagOS 2.3

- [x] [#391](https://github.com/flagos-ai/vllm-plugin-FL/pull/391) — Sunrise attention backend.
- [x] [#447](https://github.com/flagos-ai/vllm-plugin-FL/pull/447) — Tsingmicro TXDA backend.
- [x] [#464](https://github.com/flagos-ai/vllm-plugin-FL/pull/464) — Enflame S60 adaptation.
- [x] [#516](https://github.com/flagos-ai/vllm-plugin-FL/pull/516) — Kunlunxin adaptation.
- [x] [#561](https://github.com/flagos-ai/vllm-plugin-FL/pull/561) — Kunlunxin P800 CI.
- [ ] [#606](https://github.com/flagos-ai/vllm-plugin-FL/pull/606) — Ascend Qwen3.6 and full-decode graphs.

### vLLM 0.28 (upgrade baseline for 0.32, not a release version)

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

### vLLM 0.32 (release version)

- [ ] [#615](https://github.com/flagos-ai/vllm-plugin-FL/pull/615) — NVIDIA Empty runtime and CI adaptation.

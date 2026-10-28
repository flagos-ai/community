# FEP-0140: Multi-version Platform Compatibility and Operator Profiling for vLLM-Plugin-FL

**Status:** `Implementable`

**Created:** 2026-10-14

**Owner:** @ceci3

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Extend [vLLM-Plugin-FL](https://github.com/flagos-ai/vllm-plugin-FL) across upstream versions: complete the remaining 0.24 adaptations and deliver 0.32 as the main release version on all supported chips, adding AMD to the vendor roster. The 0.28 version is skipped. Provide matching deployment instructions, dependency versions and model configurations. Include the [operator profiling tool](https://github.com/flagos-ai/vllm-plugin-FL/blob/main/tools/operator_profile/README.md) to identify operators and input shapes exercised during model execution and guide operator adaptation and optimization.

## Motivation

[FEP-0089](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0089-vllm-plugin-fl-flagos-2.2-features.md) covers vLLM 0.20.2 and the initial 0.24 Empty-mode scope. FlagOS 2.3 completes the remaining platform work and follows newer upstream releases to support Day-0 model adaptation.

### Goals

| Goal | Scope | Planned milestone in 2026 |
|---|---|---|
| G1 — Complete 0.24 | Complete the FlagOS 2.3 adaptations for Huawei Ascend, Kunlunxin, Enflame, Tsingmicro and Sunrise. | Mid-October |
| G2 — Release 0.32 on all chips | Support the full vendor matrix below — the ten 2.2-cycle vendors plus NVIDIA and AMD — on 0.32 as the main release version. | Start mid-November; finish before mid-December |
| G3 — Operator profiling | Export operators/kernels, available input shapes and dtypes, call counts and kernel durations for a model-serving workload. | RC validation |

## Design Details

Maintain the 0.24 and 0.32 version lines separately. Reconcile the remaining 0.24 work with the 2.2 release matrix, update platform adapters for 0.32 API changes, and run regression tests on each target device.

Each compatibility entry records the vendor/device, upstream patch, plugin version, Python/PyTorch, SDK/driver, FlagGems, applicable FlagTree and communication libraries, plus the model revision, precision, TP/PP and graph settings. Agree dependency versions with the component maintainers and quality team.

### Vendor matrix

The 0.24 baseline covers Moore Threads, T-Head, Hygon, MetaX and Iluvatar. G1 completes coverage of the same ten-vendor roster. G2 releases 0.32 on the full matrix — the ten vendors plus NVIDIA and AMD.

| Vendor | 0.24 scope and integration | 0.32 (release version) |
|---|---|---|
| Huawei Ascend | 2.3 Adapting; In review ([#606](https://github.com/flagos-ai/vllm-plugin-FL/pull/606)) | Planned |
| T-Head | 2.2 baseline | Planned |
| Hygon | 2.2 baseline | Planned |
| Moore Threads | 2.2 baseline | Planned |
| MetaX | 2.2 baseline | Planned |
| Kunlunxin | 2.3 Adapting; Merged ([#516](https://github.com/flagos-ai/vllm-plugin-FL/pull/516), [#561](https://github.com/flagos-ai/vllm-plugin-FL/pull/561)) | Planned |
| Iluvatar | 2.2 baseline | Planned |
| Enflame | 2.3 Adapting; Merged ([#464](https://github.com/flagos-ai/vllm-plugin-FL/pull/464)) | Planned |
| Tsingmicro | 2.3 Adapting; Merged ([#447](https://github.com/flagos-ai/vllm-plugin-FL/pull/447)) | Planned |
| Sunrise | 2.3 Adapting; Merged ([#391](https://github.com/flagos-ai/vllm-plugin-FL/pull/391)) | Planned |
| NVIDIA (additional) | Existing support | Adaptation in draft ([#615](https://github.com/flagos-ai/vllm-plugin-FL/pull/615)) |
| AMD (new in 2.3) | — | Planned |

### G3: operator profiling

Collect runtime traces through vLLM's native `/start_profile` and `/stop_profile` endpoints, then export operator/kernel inventories, shape/dtype mappings and timing reports. vLLM profiles all ranks normally; the reports default to rank 0. CUDA Graph replay may lack input metadata: preserve missing values as `null` with mapping status, and mark any eager-reference metadata separately.

## Packaging

For G3, deliver `tools/operator_profile/` with the matching plugin source checkout. These scripts are not included in the plugin wheel.

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

### G3: operator profiling tests

Run from the plugin repository root in a Linux test environment with the repository's test dependencies, `curl` and `flock`.

**1. Automated regression tests**

```bash
python -m pytest -q \
  tests/unit_tests/test_operator_profile_rules.py \
  tests/unit_tests/test_operator_profile_tools.py
```

**Expected:** Both suites pass, covering trace parsing, stale-trace rejection, operator mapping, eager-reference handling and preservation of kernel counts and durations.

**2. Model profiling**

Use Qwen3.6-35B-A3B on the [documented NVIDIA/CUDA setup](https://github.com/flagos-ai/vllm-plugin-FL/blob/main/tools/operator_profile/README.md#start-a-server). Record the device, runtime versions and model revision. Start the plugin graph scenario:

```bash
RUN_DIR=/workspace/op_profile/qwen3.6_35b_a3b_plugin_graph_4096_256
VLLM_PLUGINS=fl USE_FLAGTUNE=0 bash tools/operator_profile/serve.sh \
  /models/Qwen3.6-35B-A3B qwen "$RUN_DIR" \
  --tensor-parallel-size 2 --max-model-len 32768 --max-num-seqs 64 \
  --no-enable-prefix-caching --trust-remote-code \
  --compilation-config '{"cudagraph_capture_sizes":[1,2,4,8,16,32,64]}'
```

In another terminal:

```bash
bash tools/operator_profile/profile.sh qwen \
  /workspace/op_profile/qwen3.6_35b_a3b_plugin_graph_4096_256
```

Repeat for native/plugin × eager/graph in separate run directories, keeping the other settings fixed. Use `VLLM_PLUGINS=""` for native vLLM and add `--enforce-eager` for eager mode.

**Acceptance criteria:**

- `warmup_metrics.json` and `profiled_metrics.json` each report 64 completed requests with 4096 input and 256 output tokens per request. Only the second batch is profiled.
- `operator_list.csv`, `kernel_time.csv` and `kernel_shape_dtype.csv` are nonempty. Spot-check mapped operators and shapes/dtypes against the source trace; missing metadata remains explicit.
- `summary.json` records rank 0 and `runtime_only`; every Boolean check under `conservation` is `true`, confirming kernel-count and duration consistency. Save traces, reports and test configuration in the FEP tracking issue as release-validation evidence.

## Related PRs

### vLLM 0.24 adaptations for FlagOS 2.3

- [x] [#391](https://github.com/flagos-ai/vllm-plugin-FL/pull/391) — Sunrise attention backend.
- [x] [#447](https://github.com/flagos-ai/vllm-plugin-FL/pull/447) — Tsingmicro TXDA backend.
- [x] [#464](https://github.com/flagos-ai/vllm-plugin-FL/pull/464) — Enflame S60 adaptation.
- [x] [#516](https://github.com/flagos-ai/vllm-plugin-FL/pull/516) — Kunlunxin adaptation.
- [x] [#561](https://github.com/flagos-ai/vllm-plugin-FL/pull/561) — Kunlunxin P800 CI.
- [ ] [#606](https://github.com/flagos-ai/vllm-plugin-FL/pull/606) — Ascend Qwen3.6 and full-decode graphs.

### vLLM 0.32

- [ ] [#615](https://github.com/flagos-ai/vllm-plugin-FL/pull/615) — NVIDIA Empty runtime and CI adaptation.

### Operator profiling

- [x] [#422](https://github.com/flagos-ai/vllm-plugin-FL/pull/422) — Initial operator profiling workflow.
- [x] [#593](https://github.com/flagos-ai/vllm-plugin-FL/pull/593) — Eager-reference support and regression tests.
- [x] [#617](https://github.com/flagos-ai/vllm-plugin-FL/pull/617) — Operator profiling integration and NVIDIA test commands.

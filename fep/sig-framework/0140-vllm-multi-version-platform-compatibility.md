# FEP-0140: Multi-version Platform Compatibility and Operator Profiling for vLLM-Plugin-FL

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** TODO: @github-username

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Extend [vLLM-Plugin-FL](https://github.com/flagos-ai/vllm-plugin-FL) across upstream versions: complete the remaining 0.24 adaptations and deliver 0.32 as the main release version on all supported chips, adding AMD to the vendor roster. The 0.28 version is skipped. Provide matching deployment instructions, dependency versions and model configurations. Beyond vendor and model adaptation, the functional addition covered by this FEP is the [operator profiling tool](https://github.com/flagos-ai/vllm-plugin-FL/blob/main/tools/operator_profile/README.md): capture the operators and kernels executed during model serving, their observed input shapes and dtypes, and kernel call counts and durations.

## Motivation

[FEP-0089](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0089-vllm-plugin-fl-flagos-2.2-features.md) covers vLLM 0.20.2 and the initial 0.24 Empty-mode scope. FlagOS 2.3 completes the remaining platform work and follows newer upstream releases to support Day-0 model adaptation.

Operator-level evidence helps maintainers identify which kernels and input shapes a model actually exercises when planning adaptation and optimization. Profiling results must distinguish directly observed metadata from missing or reference-derived metadata, especially under CUDA Graph replay.

### Goals

| Goal | Scope | Planned milestone in 2026 |
|---|---|---|
| G1 — Complete 0.24 | Complete the FlagOS 2.3 adaptations for Huawei Ascend, Kunlunxin, Enflame, Tsingmicro and Sunrise. | Mid-October |
| G2 — Release 0.32 on all chips | Support the full vendor matrix below — the ten 2.2-cycle vendors plus NVIDIA and AMD — on 0.32 as the main release version. | Start mid-November; finish before mid-December |
| G3 — Operator profiling | Provide a reproducible serving-profile workflow and export operator/kernel inventories, observed shapes/dtypes, call counts and kernel durations. Qualify native/plugin and eager/graph scenarios within the profiler's supported runtime scope. | Implementation available; validate the release revision during RC testing |

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

Use `tools/operator_profile/serve.sh` and `profile.sh` with vLLM's native torch profiler and `/start_profile` and `/stop_profile` endpoints. The workflow waits for server health, sends one warmup batch, then profiles a second batch using the same prompt token IDs. Each batch sends 64 concurrent requests with 4096 input tokens and 256 output tokens per request. vLLM retains its normal all-rank profiling behavior; the default offline extraction reads rank 0 runtime traces, excluding warmup and graph capture.

The tool produces:

- `operator_list.csv`: normalized operator identities and kernel names, with shares of total rank-0 runtime kernel duration.
- `kernel_time.csv`: operator/kernel call counts, durations and time shares.
- `kernel_shape_dtype.csv`: observed operator/kernel/input-shape/dtype variants and explicit mapping status.
- `summary.json`: trace scope, mapping statistics and event-count/time conservation checks.

Missing attribution, shape or dtype remains `null`; kernels are retained even when metadata is unavailable. CUDA Graph replay does not expose every kernel's inputs, so complete graph shape/dtype coverage is not guaranteed. An optional same-environment eager reference may supply candidate metadata, but it remains marked as reference evidence and does not increase direct graph coverage or contribute calls/time to graph totals. The caller must verify the model, implementation, device, software versions and serving configuration match; the extractor does not verify the full environment automatically.

The same tool can compare native and plugin inventories using `generate_flagos_coverage.py` and the current run's FlagGems evidence. This is an operator-count report under the [documented coverage rules](https://github.com/flagos-ai/vllm-plugin-FL/blob/main/tools/operator_profile/README.md#generate-flagos-coverage), not a performance-speedup or shape-coverage claim. Kernel time shares use summed kernel durations, not end-to-end latency.

## Packaging

### G3: operator profiling tool

Deliver the scripts, Python modules and `rule/` directory under `tools/operator_profile/` with the matching plugin source revision. The current package configuration includes `vllm_fl*`, so a plugin wheel alone does not include these tools; no separate compiled profiler extension is required. Keep the source revision with the release's runtime image or source checkout.

Live collection requires a compatible vLLM/PyTorch profiler runtime, model weights and Linux utilities including Bash, `curl` and `flock`. The documented live examples use NVIDIA/CUDA. Qualify other backend/version combinations separately; the G1–G2 vendor matrix does not by itself establish profiler support. Record the exact image, plugin/vLLM/PyTorch revisions, driver/SDK, model and serving arguments for every accepted configuration.

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

### G3: profiling regression tests

Run the existing tool tests from the plugin repository root in a Linux test environment with the repository's test dependencies and `flock` available:

```bash
python -m pytest -q \
  tests/unit_tests/test_operator_profile_rules.py \
  tests/unit_tests/test_operator_profile_tools.py
```

**Expected:** Both test files pass. They cover trace JSON/gzip parsing, rejection of stale traces, per-run FlagGems evidence handling, operator identity/grouping, coverage rules, eager-reference ambiguity and conflicts, and preservation of runtime counts, durations and CSV mappings. These tests use synthetic inputs and mocked commands; they do not establish live model or device compatibility.

### G3: live model profiling and output validation

Start with the documented Qwen3.6-35B-A3B case on a compatible NVIDIA/CUDA runtime. Validate the target release revision on each vLLM version for which profiling support is claimed. Run native vLLM and the FL plugin, each in eager and graph mode, with the same weights, hardware, precision, tensor-parallel size and other serving settings. Use a fresh run directory for each scenario and preserve the environment manifest and server log.

For the plugin graph scenario, start the service from the repository root:

```bash
RUN_DIR=/workspace/op_profile/qwen3.6_35b_a3b_plugin_graph_4096_256
VLLM_PLUGINS=fl USE_FLAGTUNE=0 bash tools/operator_profile/serve.sh \
  /models/Qwen3.6-35B-A3B qwen "$RUN_DIR" \
  --tensor-parallel-size 2 \
  --max-model-len 32768 \
  --max-num-seqs 64 \
  --no-enable-prefix-caching \
  --trust-remote-code \
  --compilation-config '{"cudagraph_capture_sizes":[1,2,4,8,16,32,64]}'
```

In a second terminal, from the same checkout:

```bash
RUN_DIR=/workspace/op_profile/qwen3.6_35b_a3b_plugin_graph_4096_256
bash tools/operator_profile/profile.sh qwen "$RUN_DIR"
```

Repeat sequentially for the other three scenarios: use `VLLM_PLUGINS=""` for native vLLM; add `--enforce-eager` for eager runs. Name directories with the corresponding `native`/`plugin` and `eager`/`graph` suffixes. Keep vLLM's native graph-selection policy. `USE_FLAGTUNE=0` disables optional remote FlagTune downloads, not FlagGems kernels or local Triton autotuning. Repeat the applicable scenarios for Qwen3.6-27B and model-specific adaptations; the README also provides a DeepSeek-V4-Flash configuration.

Validate each scenario's output, using its own `RUN_DIR`:

```bash
python - "$RUN_DIR" <<'PY'
import csv
import json
import sys
from pathlib import Path

run = Path(sys.argv[1])
for filename in ("warmup_metrics.json", "profiled_metrics.json"):
    metrics = json.loads((run / filename).read_text())
    assert metrics["request_count"] == metrics["concurrency"] == 64
    assert metrics["input_tokens_per_request"] == 4096
    assert metrics["output_tokens_per_request"] == 256
    assert metrics["total_input_tokens"] == 64 * 4096
    assert metrics["total_output_tokens"] == 64 * 256

results = run / "results"
summary = json.loads((results / "summary.json").read_text())
assert summary["scope"]["rank"] == 0
assert summary["scope"]["phase"] == "runtime_only"
assert summary["scope"]["graph_capture_included"] is False
assert summary["kernel_event_count"] > 0
checks = {k: v for k, v in summary["conservation"].items()
          if isinstance(v, bool)}
assert checks and all(checks.values()), checks
for filename in ("operator_list.csv", "kernel_time.csv", "kernel_shape_dtype.csv"):
    with (results / filename).open(newline="") as source:
        assert next(csv.DictReader(source), None) is not None, filename
print("Profile metrics, runtime scope and conservation checks passed")
PY
```

**Expected:** Warmup and measured batches each complete all 64 requests with exact token counts. Only the second batch is profiled. The three CSV reports are nonempty, rank-0 runtime kernel events are present, and every Boolean conservation check is `true` (the same object also contains numeric totals). Inspect directly mapped eager shape/dtype rows against their source trace events. Graph metadata gaps remain explicit; a `null` field is not itself a failed test. Retain raw traces, both metrics files, prompt token IDs, CSVs, `summary.json` and current-run FlagGems evidence. A second collection into a directory already containing a trace must fail rather than mix runs. Profiled durations are diagnostic data, not the unprofiled G1–G2 performance baseline.

For optional eager-reference validation, reparse an existing graph trace into a separate result directory:

```bash
python tools/operator_profile/extract_operator_shapes.py \
  --trace-dir /workspace/op_profile/qwen3.6_35b_a3b_plugin_graph_4096_256/profile \
  --output-dir /workspace/op_profile/qwen3.6_35b_a3b_plugin_graph_4096_256/results_eager_reference \
  --eager-reference /workspace/op_profile/qwen3.6_35b_a3b_plugin_eager_4096_256/results
```

**Expected:** Runtime kernel counts/durations, direct mapping statistics and original input fields remain unchanged. Reference fields retain provenance; ambiguous or conflicting candidates are not promoted to direct observations. All Boolean conservation checks remain `true`. Repeat using matching native eager results for the native graph case.

To check the tool's coverage report, use the original native/plugin graph outputs and current plugin evidence:

```bash
python tools/operator_profile/generate_flagos_coverage.py \
  --baseline /workspace/op_profile/qwen3.6_35b_a3b_native_graph_4096_256/results/operator_list.csv \
  --plugin /workspace/op_profile/qwen3.6_35b_a3b_plugin_graph_4096_256/results/operator_list.csv \
  --flaggems-oplist /workspace/op_profile/qwen3.6_35b_a3b_plugin_graph_4096_256/results/flaggems_enable_oplist.txt \
  --output /workspace/op_profile/qwen3.6_35b_a3b_flagos_coverage/operator_flagos_coverage.csv
```

**Expected:** Detailed and summary coverage CSVs are produced. Counts reconcile by unique operator identity; undetermined operators retain empty coverage fields and remain in the denominator. Recompute coverage if the inventories are later re-extracted with eager references; this is not automatic. Do not require a historical coverage percentage to stay constant across model, dependency or runtime changes.

### G3: existing validation evidence

- [PR #617](https://github.com/flagos-ai/vllm-plugin-FL/pull/617) documents a NVIDIA Qwen3.6-27B graph profiling run. Its [CUDA unit-test log](https://github.com/flagos-ai/vllm-plugin-FL/actions/runs/39433251334/job/118664770310) explicitly includes both operator-profile test files.
- [PR #593](https://github.com/flagos-ai/vllm-plugin-FL/pull/593) reports 54 passing tool tests and re-extraction of four existing Qwen3.6-35B-A3B traces (native/plugin × eager/graph). It explicitly describes trace reuse, not a fresh serving run.
- [Published result snapshots](https://github.com/cyber-pioneer/op_profile/tree/52fe90086f7ab3dd0cc1fa393091cbeec8a3b0d7) contain the four Qwen3.6-35B-A3B scenarios' metrics and reports. Historical results are examples, not acceptance evidence for every 2.3 target version or vendor. Attach fresh release-revision results and the complete environment manifest to this FEP's tracking issue before declaring G3 accepted.

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

- [x] [#422](https://github.com/flagos-ai/vllm-plugin-FL/pull/422) — Initial operator-profile collection, extraction and coverage workflow (existing baseline).
- [x] [#593](https://github.com/flagos-ai/vllm-plugin-FL/pull/593) — Optional eager references with explicit provenance and runtime-conservation regression tests.
- [x] [#617](https://github.com/flagos-ai/vllm-plugin-FL/pull/617) — Operator-profile integration and documented NVIDIA serving scenario.

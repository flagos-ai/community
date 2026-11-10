# FEP-0141: SGLang Multi-platform Upgrade and Model Support

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** @yixiaodapeng

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Upgrade [SGLang-Plugin-FL](https://github.com/flagos-ai/sglang-plugin-FL) to SGLang 0.5.18, complete the remaining Empty-mode adaptations from the 0.5.11 line, and finish basic-functionality validation on MetaX and Tsingmicro. Support and optimize selected W8A8 models on 0.5.18.

## Goals

- **G1 — Platform support:** Support 0.5.18 on NVIDIA, Huawei Ascend, Moore Threads, T-Head, MetaX, Hygon, Iluvatar, Enflame, Kunlunxin and Tsingmicro. Validate MetaX's integrated runtime and complete Tsingmicro's configuration-compatibility and basic-functionality regressions.
- **G2 — Empty mode:** Complete the remaining vendor adaptations for Qwen3.6-27B and Qwen3.6-35B-A3B. Integrate the required FlagGems / FlagGems-sglang operators with verified coverage and accuracy. Use the 0.5.11 baseline, recording any retained 0.5.12 configuration explicitly.
- **G3 — W8A8 models:** Start with DeepSeek-V4-Flash and DeepSeek-V4-Pro as candidate models; confirm the final selection in [issue #152](https://github.com/flagos-ai/community/issues/152). Optimize NVIDIA throughput with a 10% improvement objective and extend the work to at least one additional accelerator vendor.

Complete implementation and cut rc0 by November 30, 2026; complete acceptance by December 25, per the [2.3 release schedule](https://github.com/flagos-ai/community/blob/main/release/2.3/schedule.md).

## Packaging

Build the plugin wheel from the selected source revision with `python -m build --wheel` ([build configuration](https://github.com/flagos-ai/sglang-plugin-FL/blob/main/pyproject.toml)). Include the matching runtime/dependency versions and model launch configuration for each supported vendor.

## Test Plan

Build each vendor/version's candidate application image from the agreed FlagOS Runtime and dependency versions. Use the same image digest and plugin revision for development tests and QA acceptance. CI images may add test tools while retaining the same runtime dependencies.

Record the server and accelerator models, card count and memory, SDK/driver, SGLang build and source revision, plugin, Python/PyTorch, FlagGems, FlagGems-sglang, FlagTree and communication-library versions in [issue #152](https://github.com/flagos-ai/community/issues/152). Include the base Runtime and application-image digests, model revision, precision, TP/PP and eager/graph settings. Bind each report to the tested environment; include container-side changes and validate the final image.

Run G1 on 0.5.18 and G2 on the selected Empty baseline, using the actual Qwen model weights. Before acceptance, record the accuracy datasets, reference results, metrics and tolerances, plus performance baselines and regression limits, in issue #152.

### G1–G2: regression and model tests

From the matching plugin checkout, set `FEP_PLATFORM` and `FEP_DEVICE` from its `tests/platforms` configuration, then run:

```bash
python tests/run.py --platform "$FEP_PLATFORM" --device "$FEP_DEVICE" --scope unit
python tests/run.py --platform "$FEP_PLATFORM" --device "$FEP_DEVICE" --scope functional
python tests/run.py --platform "$FEP_PLATFORM" --device "$FEP_DEVICE" --scope e2e --model qwen3_6
```

Use the [Qwen examples](https://github.com/flagos-ai/sglang-plugin-FL/tree/main/examples) to complete any model/configuration cases not selected by the runner. Both models must pass offline and 16-way text, vision and mixed requests, plus supported eager/graph and TP/PP configurations. Repeat multi-chunk prefill on Tsingmicro to verify that KV-pool availability does not progressively decline or cause OOM. Keep test results and unresolved gaps per platform.

Reproduce any remaining MetaX runtime failures on the integrated 0.5.18 backend and verify fixes with both Qwen models.

### G2: operator coverage and accuracy

For each Qwen model, export `MODEL_PATH` and `TP_SIZE` for the device. For the 27B model:

```bash
SGLANG_FL_DISPATCH_LOG="$PWD/empty-dispatch-27b.log" \
SGLANG_FLAGGEMS_RECORD=1 SGLANG_FLAGGEMS_LOG_PATH="$PWD/empty-aten-27b.log" \
CONCURRENT_N=16 python examples/qwen3_6_27b_concurrent.py --mode all
```

Repeat with `qwen3_6_35b_a3b_concurrent.py` and separate logs. Verify the executed Attention, FLA/GDN and MoE paths and compare accuracy with the same model's standard deployment. Required compute operators must have working FlagOS implementations; record remaining vendor fallbacks and operator gaps as incomplete.

### G1–G3: performance and stability

Start the model with the agreed launch configuration and set `FEP_MODEL_PATH` to its actual checkpoint. Against the service on port 30000:

```bash
python -m sglang.bench_serving --backend sglang \
  --host 127.0.0.1 --port 30000 \
  --model "$FEP_MODEL_PATH" --tokenizer "$FEP_MODEL_PATH" \
  --dataset-name random-ids --random-input-len 4096 --random-output-len 1024 \
  --max-concurrency 64 --num-prompts 64 \
  --output-file perf-results.jsonl --output-details
```

Warm up to stable throughput and retain at least three measurements. Repeat at 1K/16K input lengths. Each round must complete all 64 requests; record throughput, TTFT and TPOT. Run the Qwen workloads continuously for 12 hours, retaining service and memory logs; expect no crash, hang or sustained memory growth.

For G3, verify W8A8 loading and accuracy for the selected models on NVIDIA and the additional vendor. Compare baseline and optimized runs with identical weights, precision, hardware and request settings; report the measured throughput change against the 10% objective.

## Related PRs

- [x] 0.5.18 upgrades: [NVIDIA #89](https://github.com/flagos-ai/sglang-plugin-FL/pull/89), [MUSA #95](https://github.com/flagos-ai/sglang-plugin-FL/pull/95), [Ascend #131](https://github.com/flagos-ai/sglang-plugin-FL/pull/131), [Hygon #138](https://github.com/flagos-ai/sglang-plugin-FL/pull/138), [Iluvatar #139](https://github.com/flagos-ai/sglang-plugin-FL/pull/139).
- [ ] 0.5.18 integrations: [T-Head #160](https://github.com/flagos-ai/sglang-plugin-FL/pull/160) (derived [#170](https://github.com/flagos-ai/sglang-plugin-FL/pull/170)), [Kunlunxin #155](https://github.com/flagos-ai/sglang-plugin-FL/pull/155) (derived [#169](https://github.com/flagos-ai/sglang-plugin-FL/pull/169)), [MetaX #167](https://github.com/flagos-ai/sglang-plugin-FL/pull/167), [Enflame #168](https://github.com/flagos-ai/sglang-plugin-FL/pull/168).
- [x] Basic backends: [MetaX #50](https://github.com/flagos-ai/sglang-plugin-FL/pull/50), [Tsingmicro #33](https://github.com/flagos-ai/sglang-plugin-FL/pull/33).
- [ ] Tsingmicro compatibility and KV-cache fixes: [#133](https://github.com/flagos-ai/sglang-plugin-FL/pull/133).
- [ ] 0.5.11 Empty integration: [Ascend #74](https://github.com/flagos-ai/sglang-plugin-FL/pull/74), [FLA/MoE operators #120](https://github.com/flagos-ai/sglang-plugin-FL/pull/120), [Hygon #124](https://github.com/flagos-ai/sglang-plugin-FL/pull/124), [Kunlunxin #136](https://github.com/flagos-ai/sglang-plugin-FL/pull/136), [T-Head #145](https://github.com/flagos-ai/sglang-plugin-FL/pull/145).

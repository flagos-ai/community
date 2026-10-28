# FEP-0141: SGLang Multi-platform Upgrade and Model Support

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** @yixiaodapeng

**SIG:** sig-framework

**Target Version:** FlagOS 2.3

---

## Summary

Prioritize [SGLang-Plugin-FL](https://github.com/flagos-ai/sglang-plugin-FL) support for SGLang 0.5.18, complete the remaining 0.5.11 Empty-mode integrations, and close the basic-functionality gaps on MetaX and Tsingmicro. The model scope also includes DeepSeek-V4-Flash and DeepSeek-V4-Pro W8A8 inference on 0.5.18.

## Motivation

[FEP-0090](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0090-sglang-plugin-fl-flagos-2.2-features.md) establishes the 0.5.11/0.5.12 platform baseline and initial Empty support. FlagOS 2.3 updates the upstream version, expands FlagOS operator coverage and supports new models.

### Goals

| Goal | Scope | Planned milestone in 2026 |
|---|---|---|
| G1 — Platform upgrade | SGLang 0.5.18 on the ten vendors below; track MetaX and Tsingmicro basic-functionality acceptance explicitly. | Implementation by November 30 Feature Freeze; acceptance during the RC window |
| G2 — Empty mode | Complete the remaining 0.5.11 Empty integrations, including operator coverage and accuracy for Qwen3.6-27B and Qwen3.6-35B-A3B. Track each vendor's remaining work in issue #152. | Integration follows operator delivery and accuracy validation, within the 2.3 release schedule. |
| G3 — W8A8 models | DeepSeek-V4-Flash and DeepSeek-V4-Pro on 0.5.18. Target a 10% throughput improvement on NVIDIA and extend optimization to at least one additional vendor. | Model adaptation in early/mid-November; optimization by end-December |

## Design Details

### Platform upgrade

Update platform detection, attention and fused-operator interfaces, graph execution and TP/PP communication for SGLang 0.5.18. Each platform configuration records the plugin revision, Python/PyTorch, driver/SDK, FlagGems, applicable FlagTree and communication libraries, plus model weights, precision, TP/PP and graph settings. Agree dependency versions with the component maintainers and quality team.

### Vendor matrix

Implementation status checked on 2026-10-28. A merged adaptation still requires the release tests below; record current blockers and acceptance results in [tracking issue #152](https://github.com/flagos-ai/community/issues/152).

| Vendor / device | Earlier baseline and follow-ups | 0.5.18 integration | PR target branch |
|---|---|---|---|
| NVIDIA H100/H800 | 0.5.11 | Merged ([#89](https://github.com/flagos-ai/sglang-plugin-FL/pull/89)) | `dev/0.5.18` |
| Huawei Ascend 910C | 0.5.11 | Merged ([#131](https://github.com/flagos-ai/sglang-plugin-FL/pull/131)); mixed-VL and graph fixes merged ([#153](https://github.com/flagos-ai/sglang-plugin-FL/pull/153)) | `dev/0.5.18` |
| Moore Threads S5000 | 0.5.11 | Merged ([#95](https://github.com/flagos-ai/sglang-plugin-FL/pull/95)) | `dev/0.5.18` |
| T-Head PPU-ZW810E | 0.5.12 | Pending | — |
| MetaX C550 | 0.5.11 backend merged ([#50](https://github.com/flagos-ai/sglang-plugin-FL/pull/50)); functionality acceptance pending | Experimental guards open ([#86](https://github.com/flagos-ai/sglang-plugin-FL/pull/86)); end-to-end validation pending | `exp/0.5.18` |
| Hygon BW1000 | 0.5.11 | Merged ([#138](https://github.com/flagos-ai/sglang-plugin-FL/pull/138)) | `dev/0.5.18` |
| Iluvatar BI-V150 | 0.5.11 | Fused operators: Merged ([#132](https://github.com/flagos-ai/sglang-plugin-FL/pull/132)); Empty runtime: Open ([#139](https://github.com/flagos-ai/sglang-plugin-FL/pull/139)) | `dev/0.5.18` |
| Enflame S60 | 0.5.11 | Open ([#91](https://github.com/flagos-ai/sglang-plugin-FL/pull/91)) | `exp/0.5.18` |
| Kunlunxin P800 | 0.5.12 | Upgrade open ([#155](https://github.com/flagos-ai/sglang-plugin-FL/pull/155)); model tests pending | `dev/0.5.18` |
| Tsingmicro TX8110 | 0.5.11 backend merged ([#33](https://github.com/flagos-ai/sglang-plugin-FL/pull/33)); compatibility/KV-cache fixes open ([#133](https://github.com/flagos-ai/sglang-plugin-FL/pull/133)) | Integration PR to be linked in issue #152 | — |

### Basic functionality: MetaX and Tsingmicro

For MetaX, confirm resolution of the outstanding vendor-runtime blocker and complete the basic model tests with the merged backend. Track the 0.5.18 experimental guards separately. For Tsingmicro, finish the 0.5.11 compatibility and KV-cache fixes, then validate the 0.5.18 integration. Record the affected version, reproducible failure, dependency fix, owner and verification result in issue #152.

### Empty mode

Use SGLang's `srt_empty` installation on 0.5.11, retaining the platform's PyTorch, device runtime and communication libraries. Integrate FlagGems and FlagGems-sglang implementations for the attention, FLA/GDN, MoE and other operators used by both Qwen models.

The 0.5.12 entries above describe the 2.2 baseline; record any retained 0.5.12 configuration explicitly in the tracking issue. Keep 0.5.11 Empty acceptance and 0.5.18 upgrade acceptance separate.

Empty installation avoids pulling in CUDA-specific dependencies. Completing G2 also requires replacing the remaining vendor compute paths and checking accuracy. Vendor and reference fallbacks can support integration while operator coverage is incomplete.

### W8A8 inference and optimization

Adapt checkpoint loading, quantization scales, attention/MoE kernels and tensor parallelism for both DeepSeek variants. Validate W8A8 inference before optimizing throughput. Compare the baseline and optimized runs with identical weights, precision, hardware and workloads.

## Test Plan

Follow the FlagOS 2.2 SGLang test workflow for G1 and G2, changing the upstream version and chip configuration. Use real Qwen3.6-27B and Qwen3.6-35B-A3B weights. Run G1 on 0.5.18 and G2 on each platform's 0.5.11 Empty environment.

| Test | Method | Expected result |
|---|---|---|
| Installation and loading | Start the platform image and check runtime versions and source revisions. Update the plugin and dependencies as needed. | Components load and the service activates the FL plugin on the selected device. |
| Basic functionality | Run text, math, image and mixed requests for both models, including 16 concurrent requests and temperature 0/0.7/1.0 checks. | Correct answers and image recognition; no empty, garbled or repetitive output. |
| Graph and communication | Run the platform's supported eager/graph configurations and single-node TP plus multi-node TP/PP cases. | Graph capture and inference succeed; communication completes without hangs or corrupted output. |
| Performance and load | Test 1K/4K/16K input with 1K output, 64 prompts and concurrency 64; vary concurrency for load testing. | Requests complete; record throughput, TTFT and TPOT and compare with the previous release on the same chip. |
| 12-hour stability | Repeat requests while monitoring service health, host/device memory and device utilization. | No service crash, hang or sustained memory growth; throughput remains stable after warmup. |

For MetaX and Tsingmicro, first establish a passing baseline for both Qwen models: installation, offline text/image inference, 16-way text/vision/mixed requests and supported TP configurations. Retain a regression case for each resolved blocker. For the Tsingmicro KV-cache issue, repeat multi-chunk prefill and verify that KV-pool availability does not progressively decline or lead to OOM. Validate graph support where declared, then complete the performance and stability matrix above.

### G1–G2: installation and load checks

Start the platform's image with its required device mounts. Keep matching preinstalled dependencies. From the target plugin checkout, follow the repository's source-install method:

```bash
python -m pip install --no-deps -e .
export SGLANG_PLUGINS=sglang_fl
python - <<'PY'
from importlib.metadata import version
import sglang, sglang_fl, torch, flag_gems, triton
print("SGLang:", sglang.__version__, sglang.__file__)
print("Plugin:", version("sglang_fl"), sglang_fl.__file__)
print("PyTorch:", torch.__version__)
print("FlagGems:", flag_gems.__version__)
print("Triton:", triton.__version__, triton.__file__)
PY
```

**Expected:** Imports succeed and runtime versions and module paths match the test configuration. Service startup logs confirm FL plugin activation and the selected device backend.

### G1–G2: functionality, graphs and communication

Run the repository's offline and concurrent examples from the matching plugin checkout. Set the model path, TP size and platform-specific attention backend for the device. For example:

```bash
MODEL_PATH=/models/Qwen3.6-27B TP_SIZE=4 \
  python examples/qwen3_6_27b_offline_inference.py
MODEL_PATH=/models/Qwen3.6-27B TP_SIZE=4 CONCURRENT_N=16 \
  python examples/qwen3_6_27b_concurrent.py --mode all
MODEL_PATH=/models/Qwen3.6-35B-A3B TP_SIZE=4 \
  python examples/qwen3_6_35b_a3b_offline_inference.py
MODEL_PATH=/models/Qwen3.6-35B-A3B TP_SIZE=4 CONCURRENT_N=16 \
  python examples/qwen3_6_35b_a3b_concurrent.py --mode all
```

**Expected:** Both models pass the offline checks and all three concurrent modes: text, vision and mixed. The four image cases identify a red square, a cat, a red stop sign and the digit 7. Retain the logs and exit status for every run.

The concurrent examples disable graphs. Test graph capture and decoding separately with the platform's graph-enabled service configuration. Repeat text, math and image requests through `/v1/chat/completions`, including temperature 0.7 and 1.0. For supported multi-node configurations, use `examples/qwen3_6_27b_multinode.py` and `examples/qwen3_6_35b_a3b_multinode.py` with the target network and communication settings.

Also run the configured functional and e2e suites. An existing NVIDIA A100 configuration selects both Qwen models for inference, serving and concurrency:

```bash
python tests/run.py --platform cuda --device a100 --scope functional
python tests/run.py --platform cuda --device a100 --scope e2e --model qwen3_6
```

Use the corresponding `tests/platforms` configuration for other devices. **Expected:** Operator, compilation, collective and model tests pass. Required cases must execute; missing weights, skipped cases or an empty selection do not count as a pass.

### G1–G2: performance, load and stability

Start the model service on port 30000 using the platform's launch configuration, with a context length sufficient for the benchmark. Run the 2.2 workload:

```bash
python -m sglang.bench_serving --backend sglang \
  --host 127.0.0.1 --port 30000 \
  --model /models/Qwen3.6-27B --tokenizer /models/Qwen3.6-27B \
  --dataset-name random-ids --random-input-len 4096 --random-output-len 1024 \
  --max-concurrency 64 --num-prompts 64 \
  --output-file perf-results.jsonl --output-details
```

Run five rounds per workload: discard the first two for warmup and retain at least three stable measurements. Extend warmup if throughput has not stabilized. Repeat with input lengths 1024 and 16384, then for the other model and supported execution modes. Compare releases using the same weights, precision, card count and workload. Use real weights for these measurements; the repository's dummy-weight benchmark suite only checks that benchmark commands run.

For load testing, vary concurrency within the device's workload range. For stability testing, repeat the workload for 12 hours and collect service health, host/device memory and device utilization.

**Expected:** Each benchmark round completes all 64 requests. Save throughput, mean/P99 TTFT and TPOT, and the 12-hour service and resource logs. Investigate performance regressions and sustained memory growth before release.

### G2: operator coverage and accuracy

Repeat both Qwen models in the target Empty environment with operator logging enabled:

```bash
SGLANG_FL_DISPATCH_LOG="$PWD/empty-dispatch-27b.log" \
SGLANG_FLAGGEMS_RECORD=1 SGLANG_FLAGGEMS_LOG_PATH="$PWD/empty-aten-27b.log" \
MODEL_PATH=/models/Qwen3.6-27B TP_SIZE=4 CONCURRENT_N=16 \
  python examples/qwen3_6_27b_concurrent.py --mode all
```

Repeat with `qwen3_6_35b_a3b_concurrent.py`, its model path and separate log files. Check executed attention, FLA/GDN and MoE paths, including runtime fallback messages. Compare outputs and accuracy against the same weights and test cases in the standard environment. `SGLANG_FL_DENY_VENDORS` can isolate remaining vendor dependencies during debugging; it is not required for normal Empty startup.

**Expected:** Both models pass the functionality, performance and stability tests. Every required compute operator has a working FlagOS implementation with aligned accuracy; unresolved vendor compute dependencies or operator gaps leave G2 incomplete. Retain the operator coverage and accuracy results alongside the model test logs.

### G3: W8A8 correctness and performance

After model integration, start each DeepSeek variant with its W8A8 checkpoint and platform configuration. Check the loaded weight format, activation quantization and scale handling, run text and math cases, and compare accuracy with the model's reference results. Repeat on NVIDIA and at least one additional vendor, including the supported TP configurations.

Use the same serving benchmark for baseline and optimized runs. For example, against the Flash service:

```bash
python -m sglang.bench_serving --backend sglang \
  --host 127.0.0.1 --port 30000 \
  --model /models/DeepSeek-V4-Flash-W8A8 --tokenizer /models/DeepSeek-V4-Flash-W8A8 \
  --dataset-name random-ids --random-input-len 4096 --random-output-len 1024 \
  --max-concurrency 64 --num-prompts 64 \
  --output-file deepseek-flash-perf.jsonl --output-details
```

Repeat for Pro and for the baseline and optimized configurations, using the same warmup and measurement procedure as above.

**Expected:** Both models load and run through the intended W8A8 paths with consistent accuracy across supported TP configurations. Report throughput, TTFT, TPOT and memory for each platform and workload. Evaluate the NVIDIA throughput target as optimized/baseline ≥ 1.10; report the additional platform's improvement separately.

## Related PRs

### SGLang 0.5.18

- [x] [#89](https://github.com/flagos-ai/sglang-plugin-FL/pull/89) — NVIDIA upgrade.
- [x] [#95](https://github.com/flagos-ai/sglang-plugin-FL/pull/95) — MUSA Empty runtime.
- [x] [#99](https://github.com/flagos-ai/sglang-plugin-FL/pull/99) — NVIDIA CI.
- [x] [#123](https://github.com/flagos-ai/sglang-plugin-FL/pull/123) — CUDA multi-node stability.
- [x] [#132](https://github.com/flagos-ai/sglang-plugin-FL/pull/132) — Iluvatar fused operators.
- [x] [#131](https://github.com/flagos-ai/sglang-plugin-FL/pull/131) — Ascend upgrade.
- [x] [#153](https://github.com/flagos-ai/sglang-plugin-FL/pull/153) — Ascend mixed-VL batching, vision graphs and reductions.
- [x] [#138](https://github.com/flagos-ai/sglang-plugin-FL/pull/138) — Hygon Empty upgrade.
- [ ] [#139](https://github.com/flagos-ai/sglang-plugin-FL/pull/139) — Iluvatar Empty upgrade.
- [ ] [#155](https://github.com/flagos-ai/sglang-plugin-FL/pull/155) — Kunlunxin upgrade on `dev/0.5.18`.
- [ ] [#86](https://github.com/flagos-ai/sglang-plugin-FL/pull/86), [#91](https://github.com/flagos-ai/sglang-plugin-FL/pull/91) — MetaX and Enflame adaptations on `exp/0.5.18`.
- [ ] [#104](https://github.com/flagos-ai/sglang-plugin-FL/pull/104) — Earlier Kunlunxin experiment on `exp/0.5.18`.

### Basic functionality on main

- [x] [#50](https://github.com/flagos-ai/sglang-plugin-FL/pull/50) — MetaX backend; release functionality acceptance pending.
- [x] [#33](https://github.com/flagos-ai/sglang-plugin-FL/pull/33) — Tsingmicro TXDA backend.
- [ ] [#133](https://github.com/flagos-ai/sglang-plugin-FL/pull/133) — Tsingmicro config compatibility and multi-chunk prefill KV-cache fix.

### Empty operators and dispatch on main

- [ ] [#74](https://github.com/flagos-ai/sglang-plugin-FL/pull/74) — Ascend Empty support.
- [ ] [#120](https://github.com/flagos-ai/sglang-plugin-FL/pull/120) — FlagGems FLA and fused MoE operators.
- [ ] [#124](https://github.com/flagos-ai/sglang-plugin-FL/pull/124) — Hygon integration with reference fallbacks (draft).
- [ ] [#125](https://github.com/flagos-ai/sglang-plugin-FL/pull/125) — MUSA Qwen3.6 release and performance paths.
- [ ] [#129](https://github.com/flagos-ai/sglang-plugin-FL/pull/129) — Successful dispatch and fallback logging.
- [ ] [#136](https://github.com/flagos-ai/sglang-plugin-FL/pull/136) — Kunlunxin Empty support (draft).
- [ ] [#145](https://github.com/flagos-ai/sglang-plugin-FL/pull/145) — T-Head PPU Empty support.

Operator-library scope: [FlagGems-sglang FEP, community #106](https://github.com/flagos-ai/community/pull/106).

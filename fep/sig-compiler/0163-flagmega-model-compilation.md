# FEP-0163: FlagMega v0.1 Model Compilation, vLLM Integration and Multi-GPU Decode

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Release FlagMega v0.1 with end-to-end model-to-MegaKernel compilation for Qwen3.8 and GLM5.3 Flash, batch-size-one decode and vLLM integration. Support NVIDIA, AMD and Iluvatar with CoreX 5.0. Support single-node multi-GPU execution and validate GLM5.3 Flash on four H800 GPUs, targeting more than 5% higher decode throughput than vLLM.

Repository: [FlagTree, feature/flagmega](https://github.com/flagos-ai/FlagTree/tree/feature/flagmega). Package: `triton.flagmega`.

## Motivation

Batch-size-one decode is sensitive to kernel-launch and memory-access costs. FlagMega compiles a supported model into an executable MegaKernel program and allows model-specific optimization before deployment.

### Goals

| Goal | Deliverable | Acceptance |
|---|---|---|
| G1 — Release | FlagMega v0.1 | Versioned compiler package, matching source and usage instructions. Release revision: TBD. |
| G2 — Model compilation | End-to-end model-to-MegaKernel compilation for Qwen3.8 and GLM5.3 Flash | Start from the selected original checkpoint, generate the complete model artifact and validate decode correctness. Model variants, precision and checkpoint revisions recorded per case. |
| G3 — Decode and integration | BS=1 decode; integration into vLLM | Real vLLM requests execute the compiled decode path, with correct prefill-to-decode state transfer and repeated requests. Release model/backend/vLLM matrix: TBD. |
| G4 — Backends | NVIDIA, AMD and Iluvatar CoreX 5.0 | Compile and execute the selected model cases on each backend; record SDK/driver and compiler versions. |
| G5 — Multi-GPU performance | Single-node, four-H800 GLM5.3 Flash | Correct BS=1 decode; FlagMega/vLLM decode-throughput ratio >1.05 on the agreed input cases. |

### Non-Goals

Concurrent multi-user serving, training and multi-node execution. No additional performance threshold is proposed for Qwen3.8 or the other backends.

## Proposal

Import the model into FlagMega IR, apply model/target-specific compilation and optimization, and package generated code with weights and runtime state metadata. Use the [FlagMega developer workflow](https://github.com/flagos-ai/FlagTree/tree/feature/flagmega/skills/flagmega-developer) for supported IR and compiler optimizations.

In the existing vLLM adapters, vLLM retains prefill, scheduling and sampling while FlagMega executes decode and shares the required KV state. Extend and validate this integration for the release matrix. A standalone FlagMega benchmark against native vLLM does not establish vLLM integration.

### Implementation baseline

Code reviewed at FlagTree `45e17f38d68cbd344b668e37c041520f8bcbf3e4`:

| Area | Existing code and evidence | Remaining release work |
|---|---|---|
| Qwen3.8 | [NVIDIA IQ4_XS tutorial](https://github.com/flagos-ai/FlagTree/tree/feature/flagmega/python/tutorials/flagmega/03-qwen3.8-27b-iq4/nvidia-rtx5060ti) compiles all 64 decoder layers from GGUF. [AMD PR #1498](https://github.com/flagos-ai/FlagTree/pull/1498) adds R9700/W7900 support and is open. | Select release model/precision cases; integrate AMD changes and rerun acceptance on the release revision. |
| GLM5.3 Flash | [H800 tutorial](https://github.com/flagos-ai/FlagTree/tree/feature/flagmega/python/tutorials/flagmega/04-glm5.3-flash-fp8/nvidia-h800) implements the full 45-layer FP8 model at TP=4, BS=1. | Complete checkpoint-to-artifact reproduction and performance acceptance on the release revision. |
| vLLM | Qwen3-1.7B has a [NVIDIA adapter](https://github.com/flagos-ai/FlagTree/blob/feature/flagmega/python/tutorials/flagmega/01-qwen3-1.7b-bf16/nvidia-h800/vllm_adapter.py) using a pinned vLLM `nncase` branch, and an [Iluvatar FlagOS adapter](https://github.com/flagos-ai/FlagTree/blob/feature/flagmega/python/tutorials/flagmega/01-qwen3-1.7b-bf16/iluvator-bi-v150/flagos_adapter.py) using the worker-extension API. | Validate the selected Qwen3.8/GLM5.3 integration cases. Existing adapters have single-device/model-specific constraints. |
| AMD | Qwen3-1.7B has `amd-gfx1201` and `amd-gfx1100` targets and decode examples. | Qwen3.8 depends on #1498; final model coverage and vLLM integration cases TBD. |
| Iluvatar | BI-V150 Qwen3-1.7B compilation and vLLM-Plugin-FL integration are documented with CoreX **4.5.0.20260509**, vLLM **0.24.0**. | Validate **CoreX 5.0** and the release model cases; the 4.5 result does not satisfy this target. |

The Qwen3.8 IQ4 examples use llama.cpp as a numerical/performance reference. This does not add llama.cpp integration to the release scope. Model coverage is recorded per backend; existing examples do not establish every model/precision/backend combination.

The GLM [2026-11-03 report](https://github.com/flagos-ai/FlagTree/blob/feature/flagmega/python/tutorials/flagmega/04-glm5.3-flash-fp8/nvidia-h800/main-c8cc-optimization-20261103-zh.md) records TPOT reductions of 6.09%–8.73% against that run's vLLM baseline. It uses explicitly supplied final IR, and notes earlier faster native samples and slower complete requests including prefill. It is evidence for that configuration, not final v0.1 acceptance.

## Packaging

**Target backends:** NVIDIA, AMD and Iluvatar CoreX 5.0.

**Wheel:** `triton.flagmega` and the `flagmega` CLI are included in the FlagTree wheel. `FLAGTREE_FLAGMEGA=0` disables the optional CLI and its extra dependencies. Current dependencies include `ortools==9.10.4067` and `jinja2>=3.1`.

From the selected FlagTree revision, in the backend's documented build environment:

```bash
python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist
```

Publish the v0.1 source revision, wheel, backend dependencies and matching tutorials. The developer skill and tutorial adapters are source assets; their distribution is recorded with the release. Final vLLM versions and CoreX 5.0 dependency pins: TBD.

## Test Plan

### G1: package verification

In an environment containing the candidate wheel:

```bash
python3 -m triton.flagmega --help
python3 - <<'PYTEST'
from importlib.metadata import version
from triton import flagmega
print(version('flagtree'))
print(flagmega.__file__)
PYTEST
```

Expected: the CLI and module load from the intended release package. Check the release record for the corresponding source revision and backend dependencies.

### G2: full-model compilation and correctness

From the selected checkout, run compiler regressions and import the complete model. Set `FEP_MODEL_PATH` to the selected original checkpoint:

```bash
python3 -m pytest -q --import-mode=importlib python/test/flagmega
python3 -m triton.flagmega import --model "$FEP_MODEL_PATH" --full-model \
  --output imported.py
python3 -m triton.flagmega verify imported.py
python3 -m triton.flagmega inspect imported.py --json
```

Expected: the imported IR contains the complete supported decoder, output head and required state. The default import without `--full-model` selects one layer and is insufficient for G2. Record failed/skipped regressions.

Use each model's compilation recipe to generate and run its artifact. For the existing Qwen3.8 NVIDIA baseline, set `FEP_QWEN_CHECKPOINT` to the documented IQ4_XS GGUF, `FEP_QWEN_TRIAL` to a fresh output path and `FEP_QWEN_REFERENCE` to the reference generated by the tutorial's `llama_golden.py`:

```bash
export FEP_QWEN_TUTORIAL="$PWD/python/tutorials/flagmega/03-qwen3.8-27b-iq4/nvidia-rtx5060ti"
python3 "$FEP_QWEN_TUTORIAL/compile.py" --checkpoint "$FEP_QWEN_CHECKPOINT" \
  --trial "$FEP_QWEN_TRIAL"
python3 -m triton.flagmega artifact verify "$FEP_QWEN_TRIAL/artifact"
python3 "$FEP_QWEN_TUTORIAL/benchmark.py" --artifact "$FEP_QWEN_TRIAL/artifact" \
  --llama-reference "$FEP_QWEN_REFERENCE" --independent-generation \
  --golden-token-prefix 8 --steps 64 --repeats 3 --measurement host-token \
  --output "$FEP_QWEN_TRIAL/correctness.json"
```

Expected: a full 64-layer artifact is produced and the tutorial's independent-generation checks pass. Repeat its Synthetic32 case. Record the checked token range and numerical tolerance; do not equate a prefix check with equality of every generated token. The AMD recipe in #1498 also permits a documented near-tie rule; release accuracy criteria must specify whether that rule is accepted.

For GLM, the existing `optimize.py` resumes bundled intermediate IR and checks a saved source/semantic contract. `emit_verified_candidate.py` instead takes an explicit final IR and records `fresh_original_IR_rebuilt=False`. Neither entry alone proves reproduction from the original model checkpoint. Complete the original-checkpoint-to-artifact command sequence for G2: TBD.

### G3: vLLM decode integration

Reuse the existing adapters as integration regressions. On NVIDIA, use the Qwen3-1.7B tutorial environment with vLLM `nncase` commit `493bd8323b64ad778f802b41ddd3109740910bc8`:

```bash
export FEP_VLLM_TUTORIAL="$PWD/python/tutorials/flagmega/01-qwen3-1.7b-bf16/nvidia-h800"
export PYTHONPATH="$PWD/python:$FEP_VLLM_TUTORIAL${PYTHONPATH:+:$PYTHONPATH}"
python3 "$FEP_VLLM_TUTORIAL/reproduce.py" \
  --checkpoint "$FEP_QWEN3_CHECKPOINT" --work-dir "$FEP_VLLM_WORK" --compile \
  --residual-layout sharded-casts --norm-layout replicated-residual \
  --residual-kernel staged --glu-reduction-group 32 \
  --results "$FEP_VLLM_RESULTS" --rounds 3 --repeats 5
```

Expected: native vLLM and integrated FlagMega generate matching complete greedy sequences for the tutorial cases; adapter statistics confirm FlagMega decode calls. Check prefill-to-decode KV sharing, page-boundary transitions and state reset between requests. Use fresh work/results paths.

This is a Qwen3-1.7B regression, not acceptance of Qwen3.8/GLM5.3 integration. Commands and compatible vLLM versions for the release model/backend matrix: TBD. The GLM `benchmark_vllm.py` invokes native vLLM as a reference and does not install a FlagMega adapter.

### G4: backend validation

Run the selected full-model and integration cases on NVIDIA, AMD and Iluvatar; retain separate results and dependency versions. For AMD, use #1498's Qwen3.8 `compile.py`, `run.py` and `benchmark.py` after its integration. Its R9700/W7900 results do not establish GLM support on AMD.

For the existing Iluvatar integration regression, follow the BI-V150 tutorial's pinned environment and use a fresh output path:

```bash
export FEP_ILUVATAR_TUTORIAL="$PWD/python/tutorials/flagmega/01-qwen3-1.7b-bf16/iluvator-bi-v150"
export PYTHONPATH="$FEP_ILUVATAR_TUTORIAL${PYTHONPATH:+:$PYTHONPATH}"
python3 "$FEP_ILUVATAR_TUTORIAL/reproduce_flagos.py" \
  --checkpoint "$FEP_QWEN3_CHECKPOINT" --work-dir "$FEP_ILUVATAR_WORK" \
  --results "$FEP_ILUVATAR_RESULTS" --rounds 3 --repeats 3
```

Expected: complete model compilation and native/FlagMega request correctness pass. Repeat acceptance with CoreX 5.0 and the selected release model cases; required compatibility changes and commands: TBD.

### G5: four-H800 GLM5.3 Flash

Use the GLM tutorial's FP8 checkpoint revision `eb9eb208eb0d988989d07a6a12d0fdeb5f52574a`, four H800 devices on one host, TP=4 and BS=1. The existing comparison uses vLLM 0.31.0, prompt lengths 32/128/1024/2048 and eight generated tokens. Record both software stacks and the exact precision, device and clock settings.

For a candidate built in the tutorial's complete trial format, run its numerical checks and paired benchmark. Set `FEP_GLM_TRIAL`, `FEP_GLM_VALIDATION`, `FEP_GLM_RESULTS`, checkpoint, SDK and native-environment paths to the prepared test inputs and fresh output directories:

```bash
export FEP_GLM_TUTORIAL="$PWD/python/tutorials/flagmega/04-glm5.3-flash-fp8/nvidia-h800"
python3 "$FEP_GLM_TUTORIAL/accuracy.py" --trial "$FEP_GLM_TRIAL" \
  --output "$FEP_GLM_VALIDATION" --sdk "$FLAGCX_MODULE_PATH" \
  --jit-device "$FEP_GLM_JIT_DEVICE"
python3 "$FEP_GLM_TUTORIAL/reproduce.py" --trial "$FEP_GLM_TRIAL" \
  --validation "$FEP_GLM_VALIDATION/numerics" --output "$FEP_GLM_RESULTS" \
  --checkpoint "$FEP_GLM_CHECKPOINT" --sdk "$FLAGCX_MODULE_PATH" \
  --native-python "$FEP_NATIVE_PYTHON" \
  --native-triton-cache "$FEP_NATIVE_TRITON_CACHE" \
  --native-inductor-cache "$FEP_NATIVE_INDUCTOR_CACHE" \
  --prompt-lengths 32 128 1024 2048
```

Expected: full-state and token checks pass; both N/F/F/N and F/N/N/F orders complete on the same four devices and verified artifact. Preserve warmup, all formal samples and per-context results. Report complete-request latency separately.

The existing runner checks a stable win, not the release's >5% threshold. Check that threshold explicitly from its formal samples:

```bash
python3 - "$FEP_GLM_RESULTS/joint-acceptance.json" <<'PYTEST'
import json, statistics, sys
with open(sys.argv[1]) as f:
    report = json.load(f)
assert report['performance_acceptance']
assert {s['prompt_length'] for s in report['scenarios']} == {32, 128, 1024, 2048}
for case in report['scenarios']:
    samples = case['all_formal_samples_ms']
    assert all(len(samples[k]) == 40 for k in ('flagmega', 'vllm'))
    rates = {k: statistics.median(1000 / t for t in samples[k]) for k in samples}
    ratio = rates['flagmega'] / rates['vllm']
    print(case['prompt_length'], ratio)
    assert ratio > 1.05
PYTEST
```

Decode TPOT excludes prefill and the first generated token. FlagMega measurements include state/token handoff and use the slowest rank. Decode throughput is the median per-request `1000 / TPOT`; throughput gain and TPOT reduction are different percentages. The release result must use the candidate produced by the completed G2 build path, not only a historical optimized artifact.

## Related PRs

- Prior proposal: [FEP-0096](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0096-flagtree-tle-megakernel-and-distributed.md).
- [x] [FlagTree #1364](https://github.com/flagos-ai/FlagTree/pull/1364) — AMD targets and Qwen3 decode.
- [x] [FlagTree #1439](https://github.com/flagos-ai/FlagTree/pull/1439) — AMD decode optimization and correctness fixes.
- [ ] [FlagTree #1498](https://github.com/flagos-ai/FlagTree/pull/1498) — AMD Qwen3.8 IQ4_XS support and regression fixes.
- [ ] v0.1 release packaging and checkpoint-to-artifact reproduction — TBD.
- [ ] Qwen3.8/GLM5.3 vLLM integration and CoreX 5.0 validation — TBD.
- [ ] Four-H800 release correctness and >5% decode-throughput acceptance — TBD.

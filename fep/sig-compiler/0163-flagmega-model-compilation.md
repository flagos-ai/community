# FEP-0163: FlagMega v0.1 Model Compilation, vLLM Integration and Multi-GPU Decode

**Status:** `Provisional`

**Implementation Status:** `In Progress`

**Tracking Issue:** [#173](https://github.com/flagos-ai/community/issues/173)

**Created:** 2026-11-05

**Owner:** @sunnycase

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Release [FlagMega v0.1](https://github.com/flagos-ai/FlagTree/tree/feature/flagmega/python/triton/flagmega) for Qwen3.8 and GLM5.3 Flash model-to-MegaKernel compilation, batch-size-one decode and vLLM integration. Target NVIDIA, AMD and Iluvatar CoreX 5.0. Validate single-node multi-GPU decode with GLM5.3 Flash on four H800 GPUs. Ship the compiler and developer skill with FlagTree.

## Goals

| Goal | Deliverable |
|---|---|
| G1 — Release | FlagMega v0.1, matching source, developer skill and reproduction instructions. |
| G2 — Model compilation | Compile Qwen3.8 and GLM5.3 Flash from their original checkpoints into complete executable model artifacts. |
| G3 — vLLM integration | Serve BS=1 requests through vLLM with FlagMega executing decode; validate prefill-to-decode state transfer and repeated requests. |
| G4 — Backends | Validate the selected model and integration cases on NVIDIA, AMD and Iluvatar CoreX 5.0. |
| G5 — Performance | Optimize Qwen3.8 BS=1 decode toward a 20% speedup. For GLM5.3 Flash on four H800 GPUs, achieve more than 5% higher decode throughput than vLLM. |

Merge `feature/flagmega` into FlagTree `main` before the FlagTree release branch for FlagOS 2.3 is cut on **2026-12-07**. The release branch must include the merged FlagMega changes.

Align vLLM integration, SDK and driver versions with the framework team. Multi-user concurrency is outside the 2.3 scope.

## Packaging

Build `triton.flagmega` and the `flagmega` CLI as part of the FlagTree wheel in the target backend's build environment:

```bash
FLAGTREE_FLAGMEGA=1 python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist
```

Build the release wheel from that release branch, and publish its source revision and backend dependencies. Include the matching [developer skill](https://github.com/flagos-ai/FlagTree/tree/feature/flagmega/skills/flagmega-developer) and [tutorials](https://github.com/flagos-ai/FlagTree/tree/feature/flagmega/python/tutorials/flagmega) in the source release.

## Test Plan

Use the same candidate artifacts and source revisions for development and QA on each backend. Record the image digest, machine and device model, card count, SDK/driver, Python/PyTorch/FlagTree, vLLM and applicable plugin/FlagCX versions. Each case also records the model revision, precision, TP, code generation backend and execution settings.

Finalize the model/backend matrix, accuracy criteria and executable recipes by December 7; complete acceptance by December 25, following the [2.3 release schedule](https://github.com/flagos-ai/community/blob/main/release/2.3/schedule.md). Run the commands below from the matching FlagTree checkout, using the tutorial dependencies and fresh output directories.

### G1: package and compiler regressions

```bash
flagmega --help
python3 -m triton.flagmega --help
python3 -c "from importlib.metadata import version; from triton import flagmega; print(version('flagtree'), flagmega.__file__)"
python3 -m pytest -q --import-mode=importlib python/test/flagmega
```

**Expected:** The module and CLI load from the candidate package; compiler regressions pass. Retain the test report, including any skips.

### G2: full-model compilation and correctness

Set `FEP_MODEL_PATH` to the selected original checkpoint. Import and inspect the complete model:

```bash
python3 -m triton.flagmega import --model "$FEP_MODEL_PATH" --full-model \
  --output imported.py
python3 -m triton.flagmega verify imported.py
python3 -m triton.flagmega inspect imported.py --json
```

**Expected:** The IR contains all decoder layers, the output head and required state. Reproduce the executable artifact from the checkpoint using the model's compilation recipe, retaining compiler settings and generated artifacts.

For [Qwen3.8-27B IQ4_XS on NVIDIA](https://github.com/flagos-ai/FlagTree/tree/feature/flagmega/python/tutorials/flagmega/03-qwen3.8-27b-iq4/nvidia-rtx5060ti), set `FEP_QWEN_CHECKPOINT` to the documented GGUF, `FEP_QWEN_TRIAL` to a fresh trial directory and `FEP_QWEN_REFERENCE` to the tutorial's `llama_golden.py` output:

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

**Expected:** All 64 decoder layers compile. The first eight independently generated tokens match the reference. Repeat the tutorial's Synthetic32 workload using its own reference, `--steps 32` and a separate result file. Retain token checks and numerical diagnostics for both workloads.

For GLM5.3 Flash, complete the original-checkpoint-to-artifact reproduction recipe before acceptance. The current tutorial's `optimize.py` starts from saved intermediate IR.

### G3: vLLM decode integration

The commands below cover Qwen3-1.7B integration regressions. Add vLLM integration commands for the selected Qwen3.8 and GLM5.3 Flash release configurations before acceptance, with compatible vLLM/plugin revisions recorded for each case.

For the [NVIDIA H800 regression](https://github.com/flagos-ai/FlagTree/tree/feature/flagmega/python/tutorials/flagmega/01-qwen3-1.7b-bf16/nvidia-h800), use the tutorial's vLLM `nncase` revision `493bd8323b64ad778f802b41ddd3109740910bc8`:

```bash
export FEP_VLLM_TUTORIAL="$PWD/python/tutorials/flagmega/01-qwen3-1.7b-bf16/nvidia-h800"
export PYTHONPATH="$PWD/python:$FEP_VLLM_TUTORIAL${PYTHONPATH:+:$PYTHONPATH}"
python3 "$FEP_VLLM_TUTORIAL/reproduce.py" \
  --checkpoint "$FEP_QWEN3_CHECKPOINT" --work-dir "$FEP_VLLM_WORK" --compile \
  --residual-layout sharded-casts --norm-layout replicated-residual \
  --residual-kernel staged --glu-reduction-group 32 \
  --results "$FEP_VLLM_RESULTS" --rounds 3 --repeats 5
```

For the [Iluvatar BI-V150 regression](https://github.com/flagos-ai/FlagTree/tree/feature/flagmega/python/tutorials/flagmega/01-qwen3-1.7b-bf16/iluvator-bi-v150), use its documented CoreX 4.5.0.20260509, vLLM 0.24.0 and vLLM-Plugin-FL environment:

```bash
export FEP_ILUVATAR_TUTORIAL="$PWD/python/tutorials/flagmega/01-qwen3-1.7b-bf16/iluvator-bi-v150"
export PYTHONPATH="$FEP_ILUVATAR_TUTORIAL${PYTHONPATH:+:$PYTHONPATH}"
python3 "$FEP_ILUVATAR_TUTORIAL/reproduce_flagos.py" \
  --checkpoint "$FEP_QWEN3_CHECKPOINT" --work-dir "$FEP_ILUVATAR_WORK" \
  --results "$FEP_ILUVATAR_RESULTS" --rounds 3 --repeats 3
```

**Expected:** Native vLLM and integrated FlagMega generate matching complete greedy sequences. Adapter statistics confirm FlagMega decode calls. Verify KV/state transfer, page-boundary transitions and state reset between requests.

### G4: backend compatibility

Run G2 and G3 on each backend's selected release configurations. On AMD, integrate [#1498](https://github.com/flagos-ai/FlagTree/pull/1498) and run its Qwen3.8-27B IQ4_XS compilation, correctness and benchmark recipes on the selected R9700/W7900 device. On Iluvatar, repeat full-model and vLLM integration acceptance with **CoreX 5.0**. Retain separate results for each model/device/SDK combination.

### G5: decode performance

For Qwen3.8, compare FlagMega with the reference runtime using the same checkpoint, weight quantization, device and workload. Record intermediate and KV-cache dtypes and the operations included in timing. Report the measured speedup against the 20% optimization objective. For the NVIDIA IQ4_XS case, use the tutorial's paired `llama_performance.py` and `benchmark.py` commands, with matching compiler and benchmark optimization options.

For [GLM5.3 Flash on four H800 GPUs](https://github.com/flagos-ai/FlagTree/tree/feature/flagmega/python/tutorials/flagmega/04-glm5.3-flash-fp8/nvidia-h800), use the full 45-layer FP8 checkpoint at revision `eb9eb208eb0d988989d07a6a12d0fdeb5f52574a`, TP=4, BS=1 and vLLM 0.31.0 as the reference. Use prompt lengths 32/128/1024/2048 and eight generated tokens, with decode CUDA Graph enabled on both runtimes. Keep the devices and clock settings fixed; record both software environments.

Set `FEP_GLM_TRIAL` to a complete GLM tutorial trial directory, including its artifact and `local_optimizations` files. Set the checkpoint, SDK and reference-environment paths, and use fresh validation/result directories:

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
python3 "$FEP_GLM_TUTORIAL/render_results.py" --results "$FEP_GLM_RESULTS"
```

**Expected:** State and token checks pass. Run both N/F/F/N and F/N/N/F orders (N: native vLLM; F: FlagMega), retaining 40 formal requests per runtime and prompt length after warmup. Report throughput and improvement over vLLM for all four prompt lengths. Define the acceptance workload for the >5% target before testing.

Decode TPOT excludes prefill and the first token. FlagMega timing includes state/token handoff and takes the slowest rank. With TPOT in ms/token, report the median of per-request `1000 / TPOT` as throughput in tokens/s. Report complete-request latency separately.

## Related PRs

- Prior FEP: [FEP-0096](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0096-flagtree-tle-megakernel-and-distributed.md).
- [x] [FlagTree #1364](https://github.com/flagos-ai/FlagTree/pull/1364) — AMD targets and Qwen3 decode.
- [x] [FlagTree #1439](https://github.com/flagos-ai/FlagTree/pull/1439) — AMD decode optimization and correctness fixes.
- [ ] [FlagTree #1498](https://github.com/flagos-ai/FlagTree/pull/1498) — AMD Qwen3.8 IQ4_XS support and regression fixes.

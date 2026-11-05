# FEP-0163: FlagMega v0.1 Model Compilation and Multi-GPU Decode

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Deliver FlagMega v0.1 for model-to-MegaKernel compilation of Qwen3.8 and GLM5.3 Flash, with batch-size-one decode and vLLM integration. Support NVIDIA, AMD and Iluvatar CoreX 5.0. On four H800 GPUs, improve GLM5.3 Flash decode throughput by more than 5% over the matched vLLM baseline.

Repository: [FlagTree, feature/flagmega](https://github.com/flagos-ai/FlagTree/tree/feature/flagmega); package: `triton.flagmega`.

## Motivation

Small-batch decode can spend substantial time launching kernels and transferring intermediate results. Compiling compatible operations into a coordinated MegaKernel execution schedule reduces these costs while preserving model, cache and tensor-parallel semantics.

### Goals

| Goal | Deliverable | Acceptance |
|---|---|---|
| G1 — Model compilation | Qwen3.8 and GLM5.3 Flash import, compilation and decode execution | Both model families pass numerical and KV-cache checks. Reference variants: Qwen3.8-27B IQ4_XS and GLM5.3 Flash FP8; final release checkpoint matrix: TBD. |
| G2 — Runtime integration | vLLM bs=1 decode adapter | Real-weight requests complete with correct state reset across requests. vLLM version: TBD. |
| G3 — Backend support | NVIDIA, AMD, Iluvatar with CoreX 5.0 | Compile/run validation on each platform. AMD reference devices: R9700/gfx1201 and W7900/gfx1100; Iluvatar reference: BI-V150. Per-model release matrix: TBD. |
| G4 — Multi-GPU performance | Single-node, four-H800 GLM5.3 Flash | Decode output tokens/s exceeds the equivalent vLLM baseline by more than 5%. |

### Non-Goals

llama.cpp integration, eight-device release acceptance, multi-node serving, training and universal model coverage.

## Proposal

Compile supported model regions into MegaKernel fragments, schedule their data dependencies and execute them through the vLLM adapter. Keep model loading, sampling and request handling integrated with the serving runtime. Identify unsupported operations and fallback paths explicitly. Cache compiled artifacts by model revision, precision, compiler revision, backend and execution configuration.

## Design Details

- **Model frontend:** map supported layers and tensor shapes to kernel fragments; validate weight formats and cache layouts before execution.
- **Execution:** preserve buffer lifetimes, producer/consumer ordering and rank synchronization. Support single-node tensor parallelism for G4.
- **vLLM adapter:** integrate request state and KV-cache ownership with the supported vLLM execution interfaces; coordinate the adapter with the vLLM-Plugin-FL maintainers.
- **Backend lowering:** reuse TLE capabilities supported by each target backend. Device-specific fallbacks must appear in the support matrix.
- **Dependencies:** consume only the required TLE distributed and FlagCX capabilities. The four-H800 milestone does not depend on completion of all domestic backends in the distributed-primitives FEP.

The earlier model-level work is tracked in [FEP-0096](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0096-flagtree-tle-megakernel-and-distributed.md). This release adds the named model/backend scope and the v0.1 deliverable.

## Packaging

**Supported vendors:** NVIDIA, AMD, Iluvatar (CoreX 5.0).

**Wheel:** `triton.flagmega` and its `flagmega` CLI ship in the FlagTree wheel from `feature/flagmega`. `FLAGTREE_FLAGMEGA=0` disables the optional CLI and extra installation dependencies. Core extraction requires `ortools==9.10.4067`; template generation uses Jinja2. Pin a tested feature-branch revision for the 2.3 release. vLLM adapter packaging/version: TBD.

Build a backend-specific FlagTree wheel from the selected release tag, using its documented SDK/LLVM/Python environment and `FLAGTREE_BACKEND` selector where required:

```bash
python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist
```

Record the source tag, Triton line, Python ABI, toolkit versions and wheel checksum. Release tag and dependency pins: TBD.

## Test Plan

### G1: compiler and artifact verification

From the selected `feature/flagmega` checkout in the matching backend environment:

```bash
python3 -m pytest -q --import-mode=importlib python/test/flagmega
python3 -m triton.flagmega --help
python3 -m triton.flagmega import --model "$FEP_MODEL_PATH" --output imported.py
python3 -m triton.flagmega verify imported.py
python3 -m triton.flagmega inspect imported.py --json
python3 -m triton.flagmega compile --input imported.py --checkpoint "$FEP_MODEL_PATH" \
  --target nvidia-sm90 --output ./artifact --emit-executable \
  --work-dir ./compile-dumps --dump-flags all
python3 -m triton.flagmega artifact verify ./artifact
```

Expected: supported imports verify, compilation produces a valid artifact and hashes/source identity validate. Record existing test failures and hardware skips; the release must resolve failures affecting the accepted paths. Use the model-specific recipe below for GLM's specialized multi-GPU compilation.

### G2–G3: runtime and backend validation

Validate real-weight decode, KV/state updates, request reset and repeated execution on each model/backend row. Reuse the [AMD tutorial](https://github.com/flagos-ai/FlagTree/tree/feature/flagmega/python/tutorials/flagmega/01-qwen3-1.7b-bf16/amd-rdna) and [Iluvatar tutorial](https://github.com/flagos-ai/FlagTree/tree/feature/flagmega/python/tutorials/flagmega/01-qwen3-1.7b-bf16/iluvator-bi-v150) for backend regression; Qwen3-1.7B success does not complete the new Qwen3.8/GLM matrix. Qwen3.8 AMD implementation is tracked in PR #1498. vLLM adapter startup/test command: TBD.

### G4: GLM four-H800 correctness and performance

Use the [GLM H800 recipe](https://github.com/flagos-ai/FlagTree/tree/feature/flagmega/python/tutorials/flagmega/04-glm5.3-flash-fp8/nvidia-h800), checkpoint revision `eb9eb208eb0d988989d07a6a12d0fdeb5f52574a`, TP=4, batch=1 and four available H800 devices. The reference artifact needs approximately 324 GB of readonly storage; verify device-memory capacity before launch. From the repository root, set checkpoint/cache paths and use fresh output directories:

```bash
export GLM_TUTORIAL="$PWD/python/tutorials/flagmega/04-glm5.3-flash-fp8/nvidia-h800"
export GLM_CHECKPOINT=/models/GLM-5.3-Flash-FP8
export GLM_OUTPUT="$PWD/artifacts/glm-fep23"
python3 "$GLM_TUTORIAL/local_optimizations/sdk.py" --output "$GLM_OUTPUT-sdk"
export FLAGCX_MODULE_PATH="$GLM_OUTPUT-sdk/runtime"
python3 "$GLM_TUTORIAL/optimize.py" --output "$GLM_OUTPUT" \
  --checkpoint "$GLM_CHECKPOINT" --readonly-cache /models/readonly-cache
python3 "$GLM_TUTORIAL/accuracy.py" --trial "$GLM_OUTPUT" \
  --output "$GLM_OUTPUT-validation" --sdk "$FLAGCX_MODULE_PATH" --jit-device 1
```

Expected: complete artifact generation, reference-token checks and state/cache checks pass. Preserve the recipe's resource and spill checks. Device selection must match the available test configuration.

Then run the paired reference/candidate benchmark; `FEP_NATIVE_PYTHON` points to the pinned vLLM 0.31 reference environment:

```bash
python3 "$GLM_TUTORIAL/reproduce.py" \
  --trial "$GLM_OUTPUT" --validation "$GLM_OUTPUT-validation/numerics" \
  --output "$GLM_OUTPUT-two-orders" --checkpoint "$GLM_CHECKPOINT" \
  --sdk "$FLAGCX_MODULE_PATH" --native-python "$FEP_NATIVE_PYTHON" \
  --native-triton-cache /models/native-triton-cache \
  --native-inductor-cache /models/native-inductor-cache \
  --prompt-lengths 32 128 1024 2048
python3 "$GLM_TUTORIAL/render_results.py" --results "$GLM_OUTPUT-two-orders"
```

The recipe generates eight tokens per request, runs both N/F/F/N and F/N/N/F orders, and retains all formal requests after its fixed warm-up. Decode TPOT excludes prefill and the first generated token; FlagMega uses the slowest rank. Report each context separately. G4 requires candidate decode tokens/s / baseline decode tokens/s >1.05 for the agreed contexts, with identical model precision and hardware. Report full-request throughput separately. Paired runs must use the same source/artifact identities and device UUIDs; old artifact results do not validate a new build.

Additional 20% optimization objective: model/backend configuration and baseline TBD.

## Related PRs

- [x] [FlagTree #1364](https://github.com/flagos-ai/FlagTree/pull/1364) — AMD targets and cooperative Qwen3 decode on `feature/flagmega`.
- [x] [FlagTree #1439](https://github.com/flagos-ai/FlagTree/pull/1439) — AMD decode optimization and correctness fixes.
- [ ] [FlagTree #1498](https://github.com/flagos-ai/FlagTree/pull/1498) — Qwen3.8-27B IQ4_XS AMD tutorial and fixes.
- [ ] v0.1 release packaging/tag — TBD.
- [ ] vLLM adapter — TBD.
- [ ] AMD/Iluvatar support and four-H800 validation — TBD.

## Implementation History

- 2026-11-05: Initial FlagOS 2.3 proposal.

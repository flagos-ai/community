# FEP-0091: FlagOS-Compressor — Model Quantization Framework (First Release)

**Status:** `Implementable`

**Updated:** 2026-09-24

**Created:** 2026-07-30

**Owner:** [@rdzhu225](https://github.com/rdzhu225)

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| flagos-compressor | [`0.1.0-rc2` @ `eecf2faed14d`](https://github.com/flagos-ai/FlagOS-Compressor/tree/eecf2faed14d70831c96f4d45fd02c693df834d6) | [`v0.1.0-rc2.post1` @ `eecf2faed14d`](https://github.com/flagos-ai/FlagOS-Compressor/tree/eecf2faed14d70831c96f4d45fd02c693df834d6) |

## Summary

FlagOS-Compressor 0.1.0 converts local HuggingFace sharded safetensors
checkpoints to BF16 or compressed-tensors INT4/INT8 formats. RC2 contains
PRs #1–#5, the same source as `release/v0.1.0`. Calibrated GPTQ, AWQ and
AutoRound from PR #6 are outside this release snapshot.

## Goals and Completion

| Goal | RC2 implementation | Remaining acceptance |
|---|---|---|
| G1: BF16 dequantization | MXFP4 and block FP8 decoders, format detection and conversion | Model-scale numerical comparison |
| G2: INT4/INT8 export | MSE weight quantization and dynamic-token W8A8 | Full-model accuracy and target-runtime loading |
| G3: Module selection and recipes | Group/regex selection, version-1 recipes and plan validation | Model recipe equivalence and selection records |
| G4: Dense and MoE models | Dense/2D weights and Qwen3.5 fused-expert adapter | Qwen3.5 dense/MoE and DeepSeek checkpoint matrix |
| G5: CPU/CUDA backends | Both conversion backends present | Paired numerical and output-metadata results |

## Format Contract

Input is a local model directory with `model.safetensors.index.json` and
`config.json`. Output must use a different directory.

| Format | Representation |
|---|---|
| MXFP4 input | E2M1 values and E8M0 scales, 32-value groups |
| Block FP8 input | E8M0 scales for padded 128×128 blocks |
| W4A16 output | Symmetric INT4, group size 32 by default; packed int32 and BF16 scales |
| W8A16 output | Symmetric INT8, group size 128 by default or per-output-channel; packed int32 and BF16 scales |
| W8A8 output | Per-output-channel INT8 weights with FP32 scales; dynamic symmetric per-token INT8 activations |

W4A16/W8A16 use `pack-quantized`; W8A8 uses `int-quantized`. MSE search is
the only quantization method accepted by the RC2 recipe schema. Conversion
dequantizes recognized low-precision weights and preserves floating-point
tensors. A conversion request with no supported FP4/FP8 tensors is rejected.

Selectors include `linear`, `attention`, `mlp`, `moe`, `moe.routed` and
`moe.shared`, with name filters and regex exclusions. Unselected quantized
weights convert to BF16. Preserving their original low-precision format is
not supported. Selection must keep fused inference pairs and expert banks
consistent.

The fused 3D adapter covers Qwen3.5-MoE banks ordered as
`[experts, out, in]`. Unsupported layouts are rejected before output is
written. W8A8 export expands banks into per-expert projection tensors.
Auxiliary attention indexer weights may require explicit name exclusions.

Implementation is under `src/flagos_compressor/`: the planner and executor
apply registered format handlers, quantizers, MoE adapters and CPU/CUDA
backend operations. Conversion/quantization reports record tensor decisions
and backend fallback.

## Packaging

The package requires Python >=3.10, PyTorch, safetensors, tqdm and PyYAML.
CUDA execution additionally requires a matching CUDA PyTorch build and driver.

From the RC2 checkout:

```bash
python -m pip install -e .
python -m pip wheel . --no-deps -w dist
```

The CLI entry point is `flagos-compressor`. CPU and CUDA are the only
compression backends. Serving the output on PPU or Hygon uses those runtimes'
inference kernels and requires separate validation.

## Test Plan

Run the checked-in classifier, planner, format, quantization, recipe, MoE and
end-to-end fixtures:

```bash
python -m pytest tests/ -v
```

The numerical fixtures include exact packing recovery, INT4 MSE below 0.02,
INT8 MSE below 1e-4 and W8A8 relative error below 0.02 for their respective
test tensors. These are fixture checks, not full-model accuracy thresholds.

For a supported source checkpoint:

```bash
flagos-compressor inspect --input /data/models/source --json
flagos-compressor convert --input /data/models/source \
  --output /data/models/source-bf16 --backend cpu
flagos-compressor validate --input /data/models/source-bf16
```

For a dense checkpoint, inspect the plan, execute and validate:

```bash
flagos-compressor quantize --input /data/models/dense \
  --output /data/models/dense-w4a16 --select linear \
  --bits 4 --strategy group --group-size 32 --backend cpu --dry-run
flagos-compressor quantize --input /data/models/dense \
  --output /data/models/dense-w4a16 --select linear \
  --bits 4 --strategy group --group-size 32 --backend cpu
flagos-compressor validate --input /data/models/dense-w4a16
```

Repeat with separate output directories for W8A16 group-128, W8A16 channel
and W8A8 channel (`--bits 8 --activation-bits 8 --strategy channel`). Compare
CPU and CUDA results using the same checkpoint and resolved plan.

| Acceptance case | Required result |
|---|---|
| Dense Qwen3.5 | Correct selected tensors, encoding, scales and output config |
| Qwen3.5-MoE | Routed-only and routed-plus-attention selection; valid fused-bank handling |
| DeepSeek | Correct MLA/2D expert classification and selection |
| Recipe vs. CLI | Equivalent plan, encoding and output metadata |
| Invalid selection/layout | Rejected fused-pair split, empty selection, incompatible group size and unknown 3D layout |
| Backend comparison | Matching metadata/shapes and documented numerical agreement |

Each real run follows a successful dry run and `validate`. Require zero
unmatched quantized tensors, nonempty selection and no unexplained fallback.
Keep `quantization_manifest.json`, `quantization_report.json` or the
conversion report with source revisions and model hashes.

For serving acceptance, load each output on NVIDIA, PPU and Hygon using a
named framework/kernel version. Verify the selected quantization route and
compare accuracy against BF16 on the same evaluation set. Record memory,
TTFT, TPOT and throughput separately. The model-scale tolerances, evaluation
set and complete serving matrix remain unresolved. A valid checkpoint alone
does not establish runtime kernel support.

## Related PRs

- [x] [FlagOS-Compressor#1](https://github.com/flagos-ai/FlagOS-Compressor/pull/1) — BF16 conversion and policy-driven INT4 quantization. Merged.
- [x] [FlagOS-Compressor#2](https://github.com/flagos-ai/FlagOS-Compressor/pull/2) — Fused MoE INT4 packing and compressed-tensors output. Merged.
- [x] [FlagOS-Compressor#3](https://github.com/flagos-ai/FlagOS-Compressor/pull/3) — INT8 weight quantization. Merged.
- [x] [FlagOS-Compressor#4](https://github.com/flagos-ai/FlagOS-Compressor/pull/4) — CLI operation summaries. Merged.
- [x] [FlagOS-Compressor#5](https://github.com/flagos-ai/FlagOS-Compressor/pull/5) — Dynamic-token W8A8 MoE export. Merged.
- [x] [FlagOS-Compressor#6](https://github.com/flagos-ai/FlagOS-Compressor/pull/6) — Calibrated methods on main; excluded from RC2. Merged.
- [x] [vllm-plugin-FL#313](https://github.com/flagos-ai/vllm-plugin-FL/pull/313) — Serving-side W4A16 scaffolding; separate from compressor acceptance. Merged.

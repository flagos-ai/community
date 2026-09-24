# FEP-0091: FlagOS-Compressor Checkpoint Conversion and Quantized Export

**Status:** `Implemented`

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

FlagOS-Compressor 0.1.0 converts local sharded safetensors checkpoints
to BF16 and exports MSE-quantized W4A16, W8A16 and W8A8 artifacts. The
2.2 scope is the producer-side format, planning and validation contract.

## Delivered Scope

| Feature | Implementation | Validation |
|---|---|---|
| BF16 conversion | MXFP4/block-FP8 decoding and format detection | Conversion and numerical fixtures |
| W4A16/W8A16 | MSE weight quantization and packed output | Packing, selection and artifact tests |
| W8A8 | INT8 weights, FP32 scales and dynamic-token metadata | Synthetic fused-MoE end-to-end export |
| Recipes and selectors | Group/regex selection, plan checks and version-1 recipes | Planner and rejection tests |
| Distribution | `flagos_compressor` package and `flagos-compressor` CLI | Wheel build and isolated installation |

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

## Test Commands

```bash
python -m pytest tests/ -v
```

The fixtures check exact packing recovery, INT4 MSE below 0.02, INT8 MSE
below 1e-4 and W8A8 relative error below 0.02 on the specified test tensors.
These bounds apply to producer-side fixtures, not model-task accuracy.

```bash
flagos-compressor inspect --input /data/models/source --json
flagos-compressor quantize --input /data/models/source \
  --output /data/models/output --select linear --bits 4 \
  --strategy group --group-size 32 --backend cpu
flagos-compressor validate --input /data/models/output
```

Add `--dry-run` to inspect the quantization plan without writing output.

## Validation

| Revision | Recorded result |
|---|---|
| [PR #2](https://github.com/flagos-ai/FlagOS-Compressor/pull/2) | 40 tests passed; wheel build and isolated installation verified |
| [PR #3](https://github.com/flagos-ai/FlagOS-Compressor/pull/3) | 57 tests passed after INT8 support |
| [PR #5](https://github.com/flagos-ai/FlagOS-Compressor/pull/5) | 65 tests passed, including synthetic Qwen3.5 fused-MoE artifact export, validation and rescan |

The RC2 snapshot contains these changes. Full-size loading, generation and
task accuracy on target accelerators are outside the producer-side acceptance.

## Related PRs

- [x] [FlagOS-Compressor#1](https://github.com/flagos-ai/FlagOS-Compressor/pull/1) — BF16 conversion and policy-driven INT4 quantization. Merged.
- [x] [FlagOS-Compressor#2](https://github.com/flagos-ai/FlagOS-Compressor/pull/2) — Fused MoE INT4 packing and compressed-tensors output. Merged.
- [x] [FlagOS-Compressor#3](https://github.com/flagos-ai/FlagOS-Compressor/pull/3) — INT8 weight quantization. Merged.
- [x] [FlagOS-Compressor#4](https://github.com/flagos-ai/FlagOS-Compressor/pull/4) — CLI operation summaries. Merged.
- [x] [FlagOS-Compressor#5](https://github.com/flagos-ai/FlagOS-Compressor/pull/5) — Dynamic-token W8A8 MoE export. Merged.

## Deferred to FlagOS 2.3

- Full-model Qwen dense/MoE and DeepSeek CPU/CUDA comparisons and NVIDIA/PPU/Hygon serving acceptance, including the W4A16 serving path in [vllm-plugin-FL#313](https://github.com/flagos-ai/vllm-plugin-FL/pull/313).
- Calibrated GPTQ/AWQ/AutoRound integration: [FlagOS-Compressor#6](https://github.com/flagos-ai/FlagOS-Compressor/pull/6), merged on main outside RC2.

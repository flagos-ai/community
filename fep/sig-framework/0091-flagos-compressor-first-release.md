# FEP-0091: FlagOS-Compressor — Model Quantization Framework (First Release)

**Status:** `Provisional`

**Created:** 2026-07-30

**Owner:** [TODO: @github-username]

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

---

## Summary

This FEP proposes the first release (v0.1.0) of
FlagOS-Compressor, the FlagOS weight-format conversion and quantization
tool, in the FlagOS 2.2 cycle. The tool reads a local HuggingFace sharded
`safetensors` model directory and writes a new model directory. It covers
four areas:

1. BF16 dequantization of MXFP4 (E2M1 + E8M0) and block FP8 (128x128 tile +
   E8M0) source weights, with floating-point weights passed through.
2. Weight-only INT4 and INT8 quantization by groupwise or per-channel MSE
   search, exported as compressed-tensors W4A16 / W8A16, plus dynamic
   per-token W8A8.
3. Module selection and YAML recipes, so a run quantizes a chosen set of
   linear layers and converts the rest to BF16.
4. `inspect`, `--dry-run`, and `validate` for planning a run and checking
   the output directory before it reaches an inference stack.

As a new module and repository, this FEP also serves as the module's
admission proposal, which the FEP rules require for a new repository.

Repository: https://github.com/flagos-ai/FlagOS-Compressor

Release branch for 2.2 acceptance:
https://github.com/flagos-ai/FlagOS-Compressor/tree/release/v0.1.0
(cut at commit `eecf2fa`, 2026-08-04). This FEP is scoped to that branch.
`main` has since taken calibrated quantization work (PR #6) that is outside
this release; see Non-Goals.

## Motivation

Open checkpoints increasingly ship in low-precision storage formats such as
MXFP4 and block FP8, and the chips FlagOS targets differ in which of those
formats they can execute. Serving one model across the FlagOS chip fleet
needs a format bridge: dequantize a format the target cannot execute to
BF16, or re-quantize selected weights to INT4/INT8 in a format inference
stacks already read.

Module-level control matters because routed experts, shared experts,
attention projections, and dense MLP weights differ both in sensitivity and
in kernel availability. A run often needs to quantize routed experts while
leaving attention in BF16, or the reverse. One-shot conversion scripts do not
offer that selection and leave no record of what was quantized.

### Goals

- **G1 (BF16 dequantization):** MXFP4 (E2M1 + E8M0, 32-value groups) and
  block FP8 (E8M0 scale per padded 128x128 tile) inputs dequantize to BF16;
  floating-point inputs pass through. Source format is inferred from weight
  dtype and paired scale shape, and an unrecognized byte-width weight with a
  scale is refused rather than guessed. Format handlers in-tree:
  `fp4_e2m1`, `fp8_e8m0`, `bf16`, `floating`.
- **G2 (INT4/INT8 weight quantization):** Symmetric MSE search
  (`quantizers/mse_int4.py`, `mse_int8.py`) over a configurable candidate
  count, exported as compressed-tensors:
  - W4A16 groupwise, default group size 32, `pack-quantized` int32 storage
    with BF16 scales.
  - W8A16 groupwise (default group size 128) and per-output-channel,
    `pack-quantized` int32 storage with BF16 scales.
  - W8A8: per-output-channel INT8 weights with FP32 scales and dynamic
    symmetric per-token INT8 activations, `int-quantized` storage.
  The quantize command writes the inference-ready checkpoint and its
  `config.json` `quantization_config` directly; there is no separate
  post-quantization conversion step.
- **G3 (Selection + Recipe):** Built-in groups `linear`, `attention`,
  `mlp`, `moe`, `moe.routed`, `moe.shared`, combinable across repeated
  `--select`; regex `--select-name` / `--exclude-name` and group
  `--exclude`; unselected source-quantized weights converted to BF16 so one
  run can produce a mixed-precision directory. A versioned YAML recipe
  (`version: 1`) expresses the same run declaratively, merging its
  selectors with CLI selectors and yielding scalar fields to explicit CLI
  values.
- **G4 (Model coverage):** Sharded HuggingFace safetensors input, meaning a
  directory carrying `model.safetensors.index.json`. Structural coverage:
  dense models, 2D routed and shared experts, MLA attention naming
  (`q_a_proj`, `q_b_proj`, `kv_a_proj_with_mqa`, `kv_b_proj`, `wq_a`,
  `wq_b`, `wkv_a`, `wkv_b`), and fused 3D routed-expert banks for the one
  layout with a registered adapter, Qwen3.5-MoE (`[num_experts, out, in]`,
  `gate_up_proj` split along the output axis). A model whose fused-expert
  axis order has no registered adapter is refused. Acceptance targets in
  the Test Plan: a Qwen3.5 dense model, a Qwen3.5-MoE model, and a
  DeepSeek-class MoE model.
- **G5 (Execution backends):** `--backend cpu` and `--backend cuda` for the
  conversion and MSE search work, selected per run, with per-op CPU
  fallback recorded in the run report.

### Non-Goals

- Quantized inference. Executing a W4A16 / W8A16 / W8A8 product is the
  serving stack's job. `compressed-tensors` describes and stores the
  weights; it does not imply a kernel exists on a given chip.
  vllm-plugin-FL#313 landed compressed-tensors W4A16 scaffolding without
  kernels, so an end-to-end serving claim depends on further work there.
- Quantization-aware training.
- Calibration-dataset-based methods. GPTQ, AWQ, and native AutoRound
  (PR #6) merged to `main` after the release branch was cut and are not in
  v0.1.0 or in this FEP's acceptance. `method: mse` is the only value the
  v0.1.0 recipe schema accepts.
- Preserving a source low-precision format for unselected weights.
  `unselected.strategy: preserve` is parsed but rejected; it needs a
  runtime config exporter and a matching inference kernel first. The only
  supported policy is convert-to-BF16.
- Downloading models, and judging whether a quantized model meets a
  downstream accuracy bar. Both are the caller's responsibility.

## Proposal

A command-line tool, `flagos-compressor`, with four subcommands:

- `inspect --input <model> [--json]` — report detected source weight
  formats and the count of selectable weights per group.
- `convert --input <model> --output <dir> [--backend cpu|cuda]` —
  dequantize recognized FP4/FP8 weights to BF16.
- `quantize --input <model> --output <dir> --select <group> ...` —
  quantize the selected weights; convert unselected source-quantized
  weights to BF16.
- `validate --input <dir> [--json]` — check a produced directory.

Input and output must be different directories. A run goes `inspect`,
`quantize --dry-run`, `quantize`, `validate`. The dry run prints the resolved
W/A bit widths, strategy, group size, the per-format tensor counts, and the
count of scaled byte tensors whose layout was not recognized. That count must
be zero before a real run; an unrecognized layout is refused, not guessed.

Selection rules the planner enforces, all of which surface at `--dry-run`
time:

- A regex may not split a fused inference unit, and may not select part of
  a routed-expert bank. Either the whole bank is quantized or none of it is.
- Group quantization requires every selected layer's `in_features` to be
  divisible by the group size; INT4 `pack-quantized` storage additionally
  requires it divisible by 8.
- `--strategy channel` is INT8-only, and is rejected for routed experts in
  W8A16 because the vLLM WNA16 routed-MoE path requires group
  quantization. Per-channel routed experts are reachable only through W8A8.
- W8A8 requires `--bits 8 --activation-bits 8 --strategy channel` and
  rejects `--group-size`.

`validate` checks shard/index agreement, that every manifest-declared
weight and scale exists with the expected dtype and storage shape, that
INT4/INT8 logical shape metadata is self-consistent, and that
`config.json`'s runtime quantization config matches the manifest. It does
not load the model, so `Valid` is a statement about the directory, not
about any inference stack or chip.

## Design Details

Package layout under `src/flagos_compressor/`: `cli` (the four
subcommands and shared argument/recipe helpers), `core` (policy, planner,
plan, executor, MoE layout adapters, reporting, validation), `inspect`
(checkpoint scan, tensor classification, weight/scale pairing), `io`
(sharded safetensors read and write), `formats` (per-format encode and
decode: `bf16`, `floating`, `fp4_e2m1`, `fp8_e8m0`, `int4_pack`,
`int8_pack`, `compressed_tensors`, `compressed_tensors_moe`),
`quantizers` (`mse_int4`, `mse_int8` over a shared `mse_int` core),
`backends` (`cpu`, `cuda`, op registry). Formats and quantizers register
through `register.py` modules, so a new format or method is added without
editing the planner.

Fused 3D routed-expert banks get their axis order from a `MoeLayout`
adapter chosen by `config.json` (`model_type`, nested `text_config`
`model_type`, then `architectures`), not from the tensor name. Qwen3.5-MoE
stores `[num_experts, out, in]` while Qwen3-VL-MoE
stores `[num_experts, in, out]`, and both use the same
`experts.gate_up_proj` / `experts.down_proj` names, so selecting by name would
quantize along the wrong axis for one of them. v0.1.0 registers only the
verified Qwen3.5-MoE layout and raises
`Fused routed-expert quantization is not supported for this model` for
anything else. On quantization the bank is expanded into standard
`experts.<id>.<projection>` weight and scale names.

Peak memory during the MSE search is bounded by a group chunk size
(`--chunk-size`, default 4096 for INT4 and 1024 for INT8) rather than by
holding a whole layer's candidate set.

Each run writes provenance next to the weights:
`quantization_manifest.json` (schema `flagos-compressor.provenance.v1`:
per-tensor format, bit width, strategy, scale name, storage and logical
shape) and `quantization_report.json` (counts, elapsed time, requested
backend, actual backend, and any per-op CPU fallback). `convert` writes
`conversion_report.json`.

<!-- TODO: numerical acceptance criteria for the dequantization and
     quantization paths — tolerance against a reference dequantization, or
     a downstream-eval-based bar. -->

<!-- TODO: documented upper bound on model size per host memory
     configuration, given the shard-wise processing and chunked search. -->

## Packaging

**Supported vendors:** compression runs on CPU or NVIDIA CUDA. v0.1.0's
`--backend` accepts `cpu` and `cuda` only, so other vendors are covered by
generating the product on a CPU or CUDA host and validating the load on the
target chip. Load and accuracy acceptance is planned on NVIDIA GPU, PPU,
and Hygon DCU.

**Can this feature be packaged as a wheel (`.whl`)?** Yes. `pyproject.toml`
uses a setuptools build backend and a `src/` layout, so a wheel builds
with:

```bash
python -m build          # produces dist/flagos_compressor-0.1.0-*.whl
# or
pip wheel . -w dist/
```

Source install for the acceptance runs below:

```bash
git clone https://github.com/flagos-ai/FlagOS-Compressor.git
cd FlagOS-Compressor
git switch release/v0.1.0
python -m pip install -e .
```

Either way the install provides the `flagos-compressor` entry point.

**Platform requirements:** Python >= 3.10. Runtime dependencies: `torch`
(CPU or CUDA build, matching the chosen backend), `safetensors`, `tqdm`,
`PyYAML`. For `--backend cuda`, a CUDA-enabled torch build and a matching
driver.

<!-- TODO: pin dependency lower bounds, and confirm whether 2.2 publishes a
     wheel to an index or stays source-install. -->

## Test Plan

The repository carries a `tests/` suite covering the tensor
classifier, policy and planner, INT4 and INT8 quantization, fused MoE INT4,
FP4 decoding, recipes, compressed-tensors config, and an end-to-end path:

```bash
python -m pytest tests/
```

Expected result: all tests pass on the `release/v0.1.0` branch.

Acceptance for 2.2 is the model-level matrix below. All cases share these
variables and run against a checked-out `release/v0.1.0`; every case records
the output of `git rev-parse HEAD`:

```bash
MODEL_QWEN_DENSE=/data/models/qwen3.5-dense
MODEL_QWEN_MOE=/data/models/qwen3.5-moe
MODEL_DEEPSEEK=/data/models/deepseek
OUT=/data/models/flagos-compressor-tests
```

Every quantization case runs the same command twice, first with `--dry-run`
and then without, followed by `validate`. Shared expected results for all
cases, checked at `--dry-run`:

- The `quantization` line reports the intended W/A bit widths, strategy, and
  group size.
- `unmatched quantized: 0`.
- The selectors match weights; no
  `selectors did not match any supported tensors`.
- No fused-pair, expert-bank-closure, or group-size divisibility error.

And after the real run: `validate` prints `Valid` on the first line, and the
output directory contains `quantization_manifest.json` and
`quantization_report.json` with no unexplained CPU fallback in the report.

### G1 — BF16 dequantization

Feature: MXFP4 / block FP8 → BF16.

```bash
flagos-compressor inspect --input /data/models/source-low-precision
flagos-compressor convert \
  --input /data/models/source-low-precision \
  --output "$OUT/source-bf16" \
  --backend cuda
flagos-compressor validate --input "$OUT/source-bf16"
```

Expected result: `inspect` reports the source weights as `fp4_e2m1_e8m0` or
`fp8_block_e8m0` with `unmatched quantized: 0`; `convert` writes a BF16
directory plus `conversion_report.json`; `validate` prints `Valid`. On a
BF16 or FP16 input, `convert` is expected to fail with
`No supported FP8/FP4 tensors were found`. Numerical check against a
reference dequantization is pending the tolerance TODO above.

### G2 — INT4 / INT8 export

Feature: W4A16, W8A16 group, W8A16 channel, W8A8. Run on
`$MODEL_QWEN_DENSE`, varying only the quantization flags:

```bash
# W8A16 group-128
flagos-compressor quantize --input "$MODEL_QWEN_DENSE" \
  --output "$OUT/dense-w8a16-g128" \
  --select linear --bits 8 --strategy group --group-size 128 --backend cuda

# W4A16 group-32
flagos-compressor quantize --input "$MODEL_QWEN_DENSE" \
  --output "$OUT/dense-w4a16-g32" \
  --select linear --bits 4 --strategy group --group-size 32 --backend cuda

# W8A8 channel + dynamic per-token
flagos-compressor quantize --input "$MODEL_QWEN_DENSE" \
  --output "$OUT/dense-w8a8" \
  --select linear --bits 8 --activation-bits 8 --strategy channel \
  --backend cuda

# W8A16 channel, attention only
flagos-compressor quantize --input "$MODEL_QWEN_DENSE" \
  --output "$OUT/dense-attn-w8a16-channel" \
  --select attention --bits 8 --strategy channel --backend cuda
```

Expected results: the shared checks above, plus each product's
`config.json` declares the expected `compressed-tensors` scheme —
`pack-quantized` for W4A16 and W8A16, `int-quantized` for W8A8 — and the
manifest reports the matching weight encoding. The attention-only case
additionally shows unselected linear weights listed in the config's ignore
set. Directory sizes compare as expected against the source:

```bash
du -sh "$MODEL_QWEN_DENSE" "$OUT/dense-w8a16-g128" \
  "$OUT/dense-w4a16-g32" "$OUT/dense-w8a8"
```

### G3 — Selection and recipe

Feature: group and regex selection, and recipe equivalence.

```bash
# regex exclude on top of a group selection
flagos-compressor quantize --input "$MODEL_QWEN_DENSE" \
  --output "$OUT/dense-attn-skip-layer0" \
  --select attention --exclude-name '.*\.layers\.0\..*' \
  --bits 8 --strategy group --group-size 128 --backend cuda --dry-run

# the same run expressed as a recipe
flagos-compressor quantize --input "$MODEL_QWEN_MOE" \
  --output "$OUT/moe-w8a8-recipe" \
  --recipe /data/recipes/w8a8-linear.yaml --backend cuda
```

with `/data/recipes/w8a8-linear.yaml`:

```yaml
version: 1
bits: 8
activation_bits: 8
strategy: channel
method: mse
n_candidates: 200
chunk_size: 1024
select:
  - linear
unselected:
  strategy: convert
  format: bf16
```

Expected results: the exclude case's dry-run plan shows layer 0's attention
weights absent from the quantized counts and present in the kept counts;
the recipe run produces a plan and a product equivalent to the matching
all-CLI W8A8 run. Negative cases expected to fail with the quoted message:
`--select-name` matching one half of a fused pair gives
`The selection splits fused inference units`; no selector at all gives
`No weights selected`; `--strategy channel --group-size 128` gives
`group_size must be omitted for channel strategy`; a routed-expert
selection with `--strategy channel` and 16-bit activations is rejected with
the W8A16 routed-MoE message.

### G4 — Model coverage

Feature: dense, fused 3D MoE, and MLA / 2D MoE structures.

```bash
flagos-compressor inspect --input "$MODEL_QWEN_MOE" --json > moe-inspect.json

# routed experts only, W4A16
flagos-compressor quantize --input "$MODEL_QWEN_MOE" \
  --output "$OUT/moe-routed-w4a16-g32" \
  --select moe.routed --bits 4 --strategy group --group-size 32 \
  --backend cuda

# routed experts + attention, W8A16
flagos-compressor quantize --input "$MODEL_QWEN_MOE" \
  --output "$OUT/moe-routed-attn-w8a16-g128" \
  --select moe.routed --select attention \
  --bits 8 --strategy group --group-size 128 --backend cuda

# whole-model W8A8, exercising fused-expert expansion
flagos-compressor quantize --input "$MODEL_QWEN_MOE" \
  --output "$OUT/moe-w8a8" \
  --select linear --bits 8 --activation-bits 8 --strategy channel \
  --backend cuda

# DeepSeek-class: MLA + 2D experts
flagos-compressor quantize --input "$MODEL_DEEPSEEK" \
  --output "$OUT/deepseek-w8a16-g128" \
  --select linear --bits 8 --strategy group --group-size 128 --backend cuda

flagos-compressor quantize --input "$MODEL_DEEPSEEK" \
  --output "$OUT/deepseek-routed-w4a16-g32" \
  --select moe.routed --bits 4 --strategy group --group-size 32 \
  --backend cuda
```

Expected results: `inspect` group counts match the model's real structure —
routed-expert counts present on the MoE models and absent on the dense
model, MLA projection counts present on DeepSeek. For the Qwen3.5-MoE W8A8
product, the manifest carries expanded
`experts.<id>.<projection>.weight` and `weight_scale` entries rather than
fused bank names. A model with a fused 3D expert bank and no registered
layout must fail before writing weights, with
`Fused routed-expert quantization is not supported for this model`.

One case applies to any model whose `self_attn` contains an auxiliary
`indexer` submodule. Its inner weights carry attention-like leaf names, so
`--select attention` picks them up. Check whether a candidate model has them,
and exclude them if so:

```bash
grep -o 'self_attn\.indexer' "$INPUT/model.safetensors.index.json" | head -1

flagos-compressor quantize --input "$INPUT" --output "$OUT/attn-moe-w8a8" \
  --select attention --select moe \
  --exclude-name '.*\.self_attn\.indexer\..*\.weight$' \
  --bits 8 --activation-bits 8 --strategy channel --backend cuda --dry-run
```

Expected result: with the exclusion in place the plan resolves and the
indexer weights appear in the kept counts instead of the quantized ones.

### G5 — Backends

Feature: `--backend cpu` and `--backend cuda`.

```bash
flagos-compressor quantize --input "$MODEL_QWEN_DENSE" \
  --output "$OUT/dense-w8a16-g128-cpu" \
  --select linear --bits 8 --strategy group --group-size 128 --backend cpu

flagos-compressor quantize --input "$MODEL_QWEN_DENSE" \
  --output "$OUT/dense-w8a16-g128-cuda" \
  --select linear --bits 8 --strategy group --group-size 128 \
  --backend cuda --device cuda:0
```

Expected result: both runs validate, and the two products agree on manifest
metadata, storage shapes, and scheme. Numerical agreement between the two
backends is bounded by the tolerance TODO above. On a host without CUDA,
`--backend cuda` is expected to fail with `backend 'cuda' is unavailable`.

### Serving-side verification

Every product is checked for load on a compressed-tensors-capable stack,
recording the inference framework, torch, driver, and device runtime
versions, whether the log reports the intended scheme, and whether any
kernel fallback occurred. A BF16 or source-float reference is served on the
same stack for an accuracy A/B, and peak memory, TTFT, TPOT, and throughput
are recorded alongside it. Load and accuracy acceptance is planned on
NVIDIA GPU, PPU, and Hygon DCU, each verified independently, since a valid
product does not imply a kernel exists on a given chip.

A `Valid` product that fails to load is recorded against the stack and chip
rather than against G1–G5.

<!-- TODO: name the serving stack and version used for the load tests, and
     the accuracy datasets for the A/B, once vllm-plugin-FL's
     compressed-tensors kernel support is settled (see #313). -->

| Goal | Verification | Status |
|---|---|---|
| G1: dequantization | MXFP4 / block FP8 → BF16 convert + validate; expected refusal on float input | Pending |
| G2: INT4/INT8 export | W4A16, W8A16 group, W8A16 channel, W8A8 products validate with the declared scheme | Pending |
| G3: selection + recipe | Group/regex selection and recipe equivalence; guard messages on the negative cases | Pending |
| G4: model coverage | Qwen3.5 dense, Qwen3.5-MoE (fused 3D), DeepSeek-class (MLA + 2D experts) | Pending |
| G5: backends | Equivalent products from `--backend cpu` and `--backend cuda` | Pending |
| Serving | Load + accuracy A/B on NVIDIA GPU, PPU, Hygon DCU with versions recorded | Pending |

## Related PRs

- [x] flagos-ai/FlagOS-Compressor#1 — feat: bootstrap FlagCompressor — safetensors weight-format conversion with BF16 dequant and policy-driven INT4 quantization
- [x] flagos-ai/FlagOS-Compressor#2 — feat: support fused MoE INT4 packing and compressed-tensors output
- [x] flagos-ai/FlagOS-Compressor#3 — feat(quantization): add INT8 weight quantization
- [x] flagos-ai/FlagOS-Compressor#4 — refactor(cli): log operational summaries
- [x] flagos-ai/FlagOS-Compressor#5 — feat(quantization): add dynamic-token W8A8 MoE export

PRs #1–#5 are the content of `release/v0.1.0`.
flagos-ai/FlagOS-Compressor#6 (calibrated GPTQ, AWQ, and native AutoRound)
merged to `main` after the branch was cut and is out of scope for 2.2.

Serving side, tracked separately: flagos-ai/vllm-plugin-FL#313 —
feat(quantization): add compressed-tensors W4A16 scaffolding (kernels not
included), merged 2026-07-29.

## Implementation History

- 2026-07-14: repository bootstrapped.
- 2026-07-30: FEP created as `Provisional` for the FlagOS 2.2 cycle.
- 2026-08-04: `release/v0.1.0` cut at commit `eecf2fa`, after PR #5.
- 2026-08-25: FEP scope aligned to the release branch — INT8, per-channel
  INT8, and dynamic-token W8A8 moved from Non-Goals into G2; calibrated
  methods recorded as out of scope; Test Plan rewritten with the acceptance
  commands and expected results.

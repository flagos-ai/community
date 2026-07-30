# FEP-0091: FlagOS-Compressor — Model Quantization Framework (First Release)

**Status:** `Provisional`

**Created:** 2026-07-30

**Owner:** [TODO: @github-username]

**SIG:** sig-framework

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP proposes the first release of **FlagOS-Compressor**
(initially bootstrapped as FlagCompressor, renamed FlagOS-Compressor), the
FlagOS model quantization and weight-format conversion framework, in the
FlagOS 2.2 cycle. It converts and quantizes HuggingFace `safetensors`
checkpoints:

1. **BF16 dequantization** — end-to-end FP4 (E2M1 + E8M0) / FP8 (block +
   E8M0) → BF16 dequantization, with BF16 pass-through.
2. **INT4 weight quantization** — groupwise MSE INT4 with BF16 scales,
   written directly as an inference-ready compressed-tensors
   `pack-quantized` W4A16 checkpoint.
3. **Selector + Recipe** — built-in selection groups (`moe`, `moe.routed`,
   `moe.shared`, `attention`, `mlp`) combinable via `--select`; unselected
   low-precision weights are converted to BF16 or kept, enabling
   mixed-precision outputs.
4. **Dry-run + inspect** — `--dry-run` previews the execution plan;
   `inspect --json` emits a machine-readable model profile.

As a new module and repository, this FEP also serves as the module's
admission proposal per the FEP rules ("New module / new repository:
Required").

Repository: https://github.com/flagos-ai/FlagOS-Compressor

## Motivation

Mainstream open checkpoints increasingly ship in low-precision storage
formats (MXFP4, block FP8), while the chips FlagOS targets differ in which
formats they can execute. Deploying one model across the FlagOS chip fleet
therefore needs a format bridge: dequantize vendor-incompatible formats to
BF16, or re-quantize selected weights to widely-executable INT4 (W4A16) —
with module-level control, because MoE experts, attention, and MLP weights
have different sensitivity and different hardware support. Existing
one-shot conversion scripts do not offer selection, mixed-precision
products, or reproducible recipes; FlagOS-Compressor provides these as a
first-class FlagOS component.

### Goals

**(Required)**

- **G1 (BF16 dequantization):** FP4 (E2M1 + E8M0) and FP8 (block + E8M0)
  inputs dequantize end-to-end to BF16; BF16 inputs pass through. Format
  handlers in-tree: `fp4_e2m1`, `fp8_e8m0`, `bf16`, `floating`.
- **G2 (INT4 quantization):** Groupwise MSE INT4 (`quantizers/mse_int4.py`,
  default group size 32) with BF16 scales, emitting compressed-tensors
  `pack-quantized` W4A16 output (`formats/int4_pack.py`,
  `compressed_tensors.py`, `compressed_tensors_moe.py` — fused-MoE INT4
  packing landed in #2) and updating `config.json`; no post-quantization
  conversion step.
- **G3 (Selector + Recipe):** Built-in groups `moe` / `moe.routed` /
  `moe.shared` / `attention` / `mlp` (plus `linear`), name-pattern
  select/exclude, unselected-weight strategy (convert-to-BF16 or keep), and
  a versioned YAML recipe format capturing method / group size / selection
  for reproducible runs.
- **G4 (Model coverage):** Sharded HuggingFace safetensors input (models
  with a `model.safetensors.index.json`); conversion and quantization paths
  verified on mainstream MoE models (DeepSeek-V3-class, Qwen MoE class) and
  mainstream dense models (Qwen dense class). Supported input storage
  formats: MXFP4 (E2M1 + E8M0), block FP8 + E8M0, BF16.
- **G5 (Hardware backends):** CPU (torch CPU backend) and CUDA (torch CUDA
  backend, with the quantization search path GPU-accelerated), switchable
  via `--backend cpu|cuda` (`backends/cpu.py`, `cuda.py`).

### Non-Goals

- Quantized *inference* — executing the W4A16 product is the serving
  stack's job (e.g. vllm-plugin-FL, which is adding compressed-tensors
  W4A16 support separately in flagos-ai/vllm-plugin-FL#313).
- Quantization-aware training or calibration-dataset-based methods (PTQ
  weight-only in this release; only the MSE method is accepted by the
  recipe schema).
- Activation quantization (W4A16 means activations stay 16-bit).
- INT8 weight quantization — in progress (#3) but not part of the first
  release's acceptance.
  <!-- TODO: confirm whether INT8 lands in 2.2 or the next cycle. -->

## Proposal

A command-line tool (`flagos-compressor`) with three verbs:

- `inspect --input <model> [--json]` — report detected weight formats and
  selectable groups.
- `convert --input <model> --output <dir> --backend cpu|cuda` — dequantize
  everything to BF16.
- `quantize --input <model> --output <dir> --select <group> --method mse
  --group-size 32 --backend cuda` — quantize the selected modules to INT4
  W4A16; unselected source-quantized weights default to BF16.

Selection composes: repeated `--select`, regex `--select-name` /
`--exclude-name`, group `--exclude`. A YAML recipe (version 1) expresses
the same run declaratively. `--dry-run` previews the tensor plan without
writing.

## Design Details

Package layout (`src/flagos_compressor/`): `cli` (verbs), `core`
(pipeline), `inspect` (model profiling), `io` (sharded safetensors
read/write), `formats` (per-format encode/decode: bf16, fp4_e2m1,
fp8_e8m0, floating, int4_pack, compressed_tensors, compressed_tensors_moe),
`quantizers` (mse_int4 + registry), `backends` (cpu, cuda, op registry).
Format and quantizer handlers register through their `register.py`
modules, so new formats/methods extend without core changes.

<!-- TODO: numerical acceptance for dequant/quant (tolerance vs reference,
     or downstream-eval-based), and large-model memory strategy
     (streaming/shard-wise processing limits). -->

## Packaging

- **Format:** Python package, `pip install -e .` from source
  (`pyproject.toml`; `src/` layout).
- **Entry point:** `flagos-compressor` CLI.
- **Dependencies:** torch (CPU or CUDA build per backend), safetensors.
  <!-- TODO: pin versions; confirm whether a PyPI wheel is published for
       2.2 or source-install only. -->

## Test Plan

**(Required)** The repository has a `tests/` suite; acceptance for 2.2:

| Goal | Verification | Status |
|---|---|---|
| G1: dequant paths | FP4/FP8 → BF16 conversion on models in each input format; numerical check vs reference dequant <!-- TODO: tolerance --> | Pending |
| G2: INT4 W4A16 | Quantized output loads as compressed-tensors pack-quantized and serves in a compressed-tensors-capable stack <!-- TODO: serving stack + model for the load test --> | Pending |
| G3: Selector/Recipe | Group/regex selection unit tests; recipe run reproduces the equivalent CLI run; `--dry-run` plan matches actual writes | Pending |
| G4: model coverage | Convert + quantize on a DeepSeek-V3-class MoE, a Qwen MoE, and a Qwen dense checkpoint (sharded) | Pending |
| G5: backends | Same inputs produce equivalent outputs on `--backend cpu` and `--backend cuda` | Pending |

## Related PRs

- [x] flagos-ai/FlagOS-Compressor#1 — feat: bootstrap FlagCompressor — safetensors weight-format conversion with BF16 dequant and policy-driven INT4 quantization
- [x] flagos-ai/FlagOS-Compressor#2 — feat: support fused MoE INT4 packing and compressed-tensors output
- [ ] flagos-ai/FlagOS-Compressor#3 — feat(quantization): add INT8 weight quantization

## Implementation History

- 2026-07-30: FEP created as `Provisional` for the FlagOS 2.2 cycle, from
  the framework-group 2.2 release plan; repository bootstrapped 2026-07-14.

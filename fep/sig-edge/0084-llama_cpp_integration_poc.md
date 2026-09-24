# FEP-0084: llama.cpp Integration PoC for FlagOS on Qualcomm Hexagon

**Status:** `Deferred`

**Updated:** 2026-09-24

**Created:** 2026-07-29

**Owner:** @kevinzs2048

**SIG:** sig-edge

**Target Version:** Deferred from FlagOS 2.2; candidate for FlagOS 2.3

## Scope and Release Decision

Explore a FlagOS GGML dynamic backend for unmodified llama.cpp on Qualcomm
Hexagon. On 2026-08-24, the owner recommended postponing the feature to
FlagOS 2.3 because the framework and code were not ready for release. No
implementation PR or RC2 artifact is assigned to this FEP.

## Proposed Design

The experimental `libggml-flagos.so` backend would register a Hexagon device
and execute FlagTree AOT artifacts through the GGML backend C ABI. llama.cpp
retains model loading, graph scheduling and CPU fallback; the backend owns
tensor adaptation, device buffers and Qualcomm runtime calls.

The initial operator is quantized `MUL_MAT`, prioritizing `Q4_0`. Additional
quantization formats, RMSNorm, RoPE, Softmax and SiLU are optional extensions.
Unsupported dtype, shape and layout combinations remain on CPU. The PoC
does not require full operator coverage or production performance.

## Planned Artifact

The prototype consists of the dynamic library, Hexagon AOT kernels, a build
script and deployment instructions. The implementation must pin llama.cpp,
the GGML ABI, FlagTree, the Qualcomm SDK and the target SoC. No stable binary
or compatibility guarantee is defined yet.

## Acceptance for Reactivation

1. Build the pinned, unmodified llama.cpp with dynamic GGML backend loading.
2. Load the FlagOS library and enumerate the Hexagon device.
3. Run a FlagTree-compiled operator on Hexagon and compare it with the GGML
   CPU reference.
4. Complete a small GGUF model run with observable FlagOS dispatch and CPU
   fallback for unsupported nodes.
5. Record memory use, load/dispatch overhead, prefill throughput and decode
   throughput with the exact model, hardware, SDK and source revisions.

A working operator and model path establish feasibility. Production scope
and performance targets require a separate release decision.

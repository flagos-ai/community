# FEP-0084: llama.cpp Integration PoC for FlagOS on Qualcomm Hexagon

**Status:** `Implementable`

**Created:** 2026-07-29

**Owner:** @kevinzs2048

**SIG:** sig-edge

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP proposes a proof of concept for integrating the FlagOS compiler and
operator stack with [`llama.cpp`](https://github.com/ggml-org/llama.cpp). The initial target
platform is **Qualcomm Hexagon**.

The PoC will keep upstream llama.cpp unchanged and provide an experimental FlagOS GGML dynamic
backend, tentatively named `libggml-flagos.so`. FlagTree compiles selected FlagGems or custom
Triton/TLE operators ahead of time, and the backend loads and dispatches those operator
artifacts through the GGML backend C ABI. Unsupported operations fall back to the existing
llama.cpp CPU backend.

This is a feasibility exploration, not a product-support commitment. Its output is a working
prototype, measured results, and a recommendation on whether to proceed with a production
integration.

## Motivation

llama.cpp provides a widely used local-inference runtime and GGUF model ecosystem for edge
devices. FlagOS already provides reusable compiler and operator capabilities through FlagTree,
FlagGems, and Triton/TLE. Connecting the two could bring FlagOS operators to AI PC and AI Box
scenarios without maintaining a long-lived llama.cpp fork.

The main question is whether FlagOS AOT operator artifacts can be exposed as a regular GGML
backend with low integration cost. Upstream llama.cpp already has an experimental Hexagon
backend, so this PoC does not attempt to prove that llama.cpp can run on Hexagon. It explores
whether the FlagOS stack can add reusable operators and quantized kernels through the standard
backend boundary while preserving upstream compatibility and CPU fallback.

### Goals

**(Required)**

- Load a FlagOS backend dynamically from an unmodified, pinned llama.cpp checkout.
- Register a Qualcomm Hexagon device through the GGML backend interface.
- Compile at least one representative inference operator with FlagTree and execute its AOT
  artifact through the backend.
- Demonstrate GGUF local inference with partial Hexagon offload and automatic CPU fallback.
- Validate basic correctness and characterize integration overhead, memory use, prefill
  throughput, and decode throughput.
- Identify the operator coverage, compiler, runtime, packaging, and maintenance work required
  for a production implementation.

### Non-Goals

- Complete llama.cpp operator or GGUF quantization-format coverage.
- Production-level performance, stability, packaging, or release support.
- Modifying or maintaining a fork of upstream llama.cpp.
- Multi-device scheduling or CPU/GPU/NPU collaborative optimization.
- Multimodal model support in the initial PoC.
- Supporting platforms other than Qualcomm Hexagon.

## Proposal

The PoC uses llama.cpp's dynamic GGML backend mechanism:

```text
Compile time
FlagGems / custom Triton-TLE operator
                |
                v
         FlagTree compiler
                |
                v
      Hexagon AOT kernel artifact
                |
                v
       libggml-flagos.so

Runtime
llama.cpp (unmodified)
        |
        v
GGML backend C ABI
        |
        v
ggml-flagos backend
        |
        v
Qualcomm device runtime -> Hexagon

Unsupported operation -> llama.cpp CPU backend
```

llama.cpp is built with shared libraries and `GGML_BACKEND_DL=ON`. The FlagOS backend
implements only the GGML device, buffer, and graph-compute interfaces needed by the PoC.
Kernel launch, memory management, and synchronization are delegated to the Qualcomm runtime.

The initial operator target is quantized `MUL_MAT`, prioritizing `Q4_0`. If time permits, the
PoC may add `Q4_K` or common graph operations such as RMSNorm, RoPE, Softmax, and SiLU. This
extended coverage is not required for the initial feasibility result.

## Design Details

### Integration Boundary

- **llama.cpp:** model loading, GGUF parsing, graph construction, scheduling, and CPU fallback.
- **`ggml-flagos`:** GGML-to-FlagOS operator dispatch, tensor layout adaptation, device
  buffers, and runtime calls.
- **FlagTree:** AOT compilation from Triton/TLE source to Hexagon-compatible kernel artifacts.
- **FlagGems/custom kernels:** reusable operator implementations and PoC quantized kernels.
- **Qualcomm runtime:** device discovery, memory, command submission, synchronization, and
  kernel loading.

The PoC pins the llama.cpp commit and GGML backend ABI used for the experiment. Any upstream
ABI change may require rebuilding the dynamic backend.

### Fallback

The backend reports support only for validated operator, datatype, shape, and layout
combinations. Other graph nodes remain on the llama.cpp CPU backend. Fallback is a correctness
mechanism for progressive enablement; the PoC will measure transfer and scheduling overhead
rather than assume that partial offload is beneficial.

## Packaging

**(Required)** The PoC artifact consists of:

- `libggml-flagos.so`;
- the required Hexagon AOT kernel artifacts;
- a build script with pinned llama.cpp, FlagTree, and Qualcomm SDK versions; and
- a minimal deployment/readme describing runtime library paths and device requirements.

No stable binary package or compatibility guarantee is proposed at this stage.

## Test Plan

**(Required)** Testing is limited to one pinned Qualcomm Hexagon device and SDK environment.
The exact SoC, Hexagon version, operating system, SDK, model, and commits will be recorded by
the implementation.

1. Build an unmodified llama.cpp checkout with `GGML_BACKEND_DL=ON`.
2. Load `libggml-flagos.so` and verify that the Hexagon device is enumerated.
3. Run GGML backend operator tests for the selected `MUL_MAT` shapes and compare results with
   the CPU reference.
4. Run one small GGUF model through local inference, proving that at least one graph node runs
   on the FlagOS Hexagon backend and unsupported nodes fall back to CPU.
5. Record model-load success, output sanity, memory use, backend load overhead, prefill
   throughput, and decode tokens per second.

The PoC succeeds when the dynamic backend loads without upstream source changes, one AOT
operator passes correctness testing on Hexagon, and a GGUF model completes local inference
with observable FlagOS dispatch. Performance improvement is desirable but is not a PoC exit
criterion.

## Related PRs

No implementation PRs exist at the time of this draft.

## References

- [llama.cpp](https://github.com/ggml-org/llama.cpp)
- [llama.cpp GGML build options](https://github.com/ggml-org/llama.cpp/blob/master/ggml/CMakeLists.txt)
- [llama.cpp Snapdragon/Hexagon backend](https://github.com/ggml-org/llama.cpp/blob/master/docs/backend/snapdragon/README.md)
- [FlagTree](https://github.com/flagos-ai/FlagTree)
- [FlagGems](https://github.com/flagos-ai/FlagGems)

## Implementation History

- 2026-07-29: Initial exploratory draft. Target platform set to Qualcomm Hexagon.

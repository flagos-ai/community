# FEP-0015: Arm64 CPU Backend for FlagOS (TLE + Triton-CPU)

**Status:** `Provisional`

**Created:** 2026-05-27

**Owner:** @kevinzs2048

**SIG:** sig-edge

**Target Version:** FlagOS 2.1

---

## Summary

This feature brings first-class **Arm64 CPU** support to the FlagOS compiler stack, enabling
FlagTree's Triton kernels and FlagGems operators to compile and run efficiently on Arm CPUs,
**entirely based on open-source compiler infrastructure with no dependency on vendor-proprietary
operator libraries**.

- **Compiler layer**: Arm64 TLE (Triton Language Extensions) capabilities are provided as a
  standalone plugin (`third_party/tle_arm64/`) within FlagTree, following the same plugin
  organization as other hardware backends (e.g., DSA's `third_party/tle/`). Triton-CPU serves
  as the underlying compiler substrate.
- **Operator layer**: Key inference operators (GEMV, Fused MLP, Flash-Attention Decode,
  RMSNorm, etc.) are packaged as TLE extended operations and contributed back to FlagTree.

This extends FlagOS's "write once, deploy across backends" capability from cloud-side
accelerators to Arm CPU edge scenarios.

Related repositories:
- FlagTree: https://github.com/flagos-ai/FlagTree
- TLE design document: https://github.com/flagos-ai/FlagTree/wiki/TLE
- Triton-CPU Arm development branch: https://github.com/kevinzs2049/triton-cpu/tree/arm64-dev

## Motivation

AI inference is shifting from the cloud to the edge — smart terminals, intelligent cockpits,
embodied AI. Arm64 is the dominant CPU architecture in the edge domain, but FlagOS currently
targets cloud-side accelerators and lacks a CPU path. Without a CPU path, any Arm deployment
must fall back to hand-written, vendor-specific C kernels — exactly the kind of fragmentation
FlagOS aims to eliminate.

This FEP fills that gap by making Arm64 a supported FlagOS backend through the open-source
compiler stack.

### Goals

1. Enable FlagTree to compile Triton kernels to Arm64 CPU via the Triton-CPU compiler substrate.
2. Provide Arm64 TLE as a standalone plugin (`third_party/tle_arm64/`) within FlagTree.
3. Package key inference operators as TLE extended operations and contribute them to FlagTree.
4. Provide runtime feature detection (CPU topology, ISA capabilities) to automatically
   configure the execution environment.

### Non-Goals

- NPU / GPU backends (Ascend, Hexagon, etc.) — tracked separately.
- Sub-byte (INT4) quantization — the minimum precision in this FEP is INT8; INT4 is a
  follow-up extension.
- Windows-on-Arm / macOS (Apple Silicon) — limited to Linux/AArch64.
- SME2 support — follow-up extension.
- SVE (non-SVE2) specific optimization — insufficient hardware coverage; this FEP covers
  NEON and SVE2 only.

## Proposal

Developers write a kernel once using `@triton.jit` plus TLE extended operations, select the
Arm64 target at compile time, and FlagTree drives the Triton-CPU backend to lower it into
AArch64 machine code. Pre-built TLE extended operations are available from FlagTree, so models
can run end-to-end on Arm CPUs — architecture-specific optimizations are encapsulated in
open-source TLE extended operations, with no hand-written assembly required from the user.

On the engineering side, the tle_arm64 plugin sits alongside other hardware plugins in
FlagTree's `third_party/`, with ownership, build, and maintenance unified within FlagTree.

## Design Details

### Plugin Architecture

`flagtree/third_party/tle_arm64/`, following the plugin pattern of `third_party/tle/` (DSA).

**Phase 1 (current)**: Pybind injection layer migration — extract `create_cpu_*` builder
methods from Triton-CPU's `ir.cc` into a standalone plugin `.cc`, injected into
`TritonOpBuilder` at module initialization. MLIR op definitions and lowering remain in
Triton-CPU.

**Phase 2 (follow-up)**: Standalone Arm64TleDialect — migrate MLIR op definitions and lowering
into the plugin so that the Triton-CPU compiler substrate no longer contains Arm64 TLE-specific
code.

CMake integration: `add_subdirectory(third_party/tle_arm64)` when `FLAGTREE_BACKEND=cpu`.

### TLE Extended Operations (Operator Layer)

| Category | Operation | Description |
|---|---|---|
| GEMV | `sdot_gemv_fused_bf16` | W8A8-dynamic: fused quantization + SDOT GEMV + dequantization |
| Fusion | `fused_mlp` | gate+up GEMV + SiLU + mul in a single OMP region |
| Fusion | `flash_attn_decode` | M=1 Flash Attention with OMP parallelism across heads |
| Normalization | `rms_norm` / `rms_norm_gated` | Single kernel replacing multiple decomposed ATen ops |
| Activation | `swiglu` | Fused SiLU(gate) * up |
| Sequence models | `causal_conv1d_update` / `gated_delta_decode` | GDN single-step decode |

### Runtime

Reads `/proc/cpuinfo` for big.LITTLE core identification and ISA feature detection,
automatically configuring OMP affinity. NEON serves as the universal fallback.

## Packaging

- **Build**: `FLAGTREE_BACKEND=cpu`, native Linux/AArch64 build or cross-build via
  Docker buildx.
- **Toolchain**: LLVM-based AArch64 code generation through the Triton-CPU lowering path.
- **Artifacts**: tle_arm64 plugin + `libTritonCPURuntime.so` (C runtime) + runtime detection
  coordinator.
- **Platform requirements**: Linux/AArch64; NEON as baseline, SVE2/i8mm optional with
  auto-detection.
- **Distribution**: Shipped as part of the FlagTree release.

## Test Plan

### Functional Verification

- Plugin loading: confirm that `tle_arm64`-injected `create_cpu_*` methods are available on
  the Python side.
- Operator-level: each TLE extended operation compared against a reference implementation
  within defined numerical tolerances.
- End-to-end: greedy decode of a small LLM (Qwen / MiniCPM) on Arm64, with per-token output
  matching against a reference.

### Performance Verification

- Performance benchmarks and acceptance thresholds will be defined after functional
  verification, in conjunction with specific hardware platforms.

### Compatibility Verification

- Platform: Cix P1 (CD8180), Armv9.2-A with SVE2 + i8mm. Sole test platform for this cycle.
- Confirm that the NEON fallback also runs correctly on the same hardware.

## Related PRs

- [ ] FlagTree: `third_party/tle_arm64/` pybind plugin + CMake integration
- [ ] FlagTree: (Phase 2) standalone Arm64TleDialect + lowering migration
- [ ] Triton-CPU: expose `ir.h` + Arm ISA selection + threading optimization + TLE op
  definitions + C runtime
- [ ] FlagGems: Arm64 end-to-end inference integration

## Implementation History

- 2026-05-27: FEP created (Provisional).
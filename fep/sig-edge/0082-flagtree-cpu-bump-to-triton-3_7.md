# FEP-0082: FlagTree CPU Backend Upgrade to Triton 3.7 (Arm64)

**Status:** `Implementable`

**Created:** 2026-07-29

**Owner:** @kevinzs2048

**SIG:** sig-edge

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP proposes upgrading the FlagTree CPU backend and
[`flagtree-cpu`](https://github.com/flagos-ai/flagtree-cpu) integration to the Triton 3.7
compiler line. The upgrade covers the CPU backend only. Its supported and acceptance platform
is Linux on Arm64 (`aarch64`); GPU, NPU, x86_64 CPU, Windows, and macOS are outside this FEP's
validation scope.

The work is a compiler-baseline migration, not a new operator or performance feature. It will
forward-port the existing Arm64 CPU backend, TritonCPU dialect and lowering passes, runtime,
and TLE integration while preserving the user-facing FlagTree CPU workflow. The implementation
will pin an exact Triton 3.7.x commit and its matching LLVM revision. At the time of this draft,
the upstream stable reference is
[`v3.7.1`](https://github.com/triton-lang/triton/releases/tag/v3.7.1).

## Motivation

FlagTree's published support matrix currently exposes CPU support on the
[`triton_v3.3.x`](https://github.com/flagos-ai/FlagTree/tree/triton_v3.3.x) line, while
`flagtree-cpu` also has a
[`triton_v3.6.x`](https://github.com/flagos-ai/flagtree-cpu/tree/triton_v3.6.x) development
branch. Upstream Triton has moved to the 3.7 release line, but there is no corresponding
FlagTree CPU line. This leaves the CPU backend behind the compiler version used for current
Triton development and increases the cost of every future update.

FlagTree will also add support for Triton 3.7. Because `flagtree-cpu` supplies the CPU
backend integrated into FlagTree, the two projects must keep corresponding Triton versions.
Aligning both projects on the 3.7 line keeps their frontend semantics, compiler interfaces,
MLIR/LLVM baseline, and extension points compatible. If FlagTree moves to 3.7 while the CPU
backend remains on 3.3 or 3.6, CPU integration would require a cross-version compatibility
layer or repeated backports, increasing maintenance cost and the risk of build-time or JIT
failures.

The CPU backend cannot be upgraded by changing a Python package version alone. It depends on
Triton internals across several layers:

- the Python backend, driver, target, compiler-stage, cache, and launcher interfaces;
- the TritonCPU MLIR dialect, TableGen definitions, pass registration, and TTIR-to-LLVM
  lowering;
- Triton's CMake and pybind extension interfaces;
- the LLVM revision pinned by Triton; and
- the Arm64 runtime and TLE operations linked into the generated CPU module.

These interfaces and the LLVM pin have changed across Triton 3.3, 3.4, 3.5, 3.6, and 3.7.
Continuing to carry the CPU backend on older branches makes fixes harder to share with newer
FlagTree work, increases downstream version skew, and turns a later upgrade into a larger,
riskier rebase.

Triton 3.7 is also a better long-term integration point for backend extensions. It adds
documented hooks for out-of-tree TTIR/TTGIR passes and dialect plugins, alongside compiler,
frontend, build, and LLVM updates. The CPU upgrade should use these supported extension points
where they can replace local patch points without redesigning the backend. This reduces the
amount of CPU-specific code that must be reapplied to each Triton release.

### Goals

**(Required)**

- Establish a Triton 3.7.x CPU development line in `flagtree-cpu` and integrate it with the
  corresponding FlagTree compiler line.
- Forward-port the existing CPU backend registration, compiler pipeline, launcher, runtime,
  TritonCPU dialect, lowering passes, and Arm64 TLE support to Triton 3.7.x.
- Preserve the existing FlagTree CPU selection and Triton-kernel authoring experience; the
  version bump must not require users to rewrite kernels solely because the backend moved to
  Triton 3.7.
- Keep the acceptance scope explicit: Linux Arm64 (`aarch64`) CPU only.
- Pin and record the exact Triton commit, LLVM revision, Python version range, and build
  toolchain used by the implementation.
- Inventory remaining FlagTree/flagtree-cpu patches against upstream Triton 3.7 and use
  upstream plugin hooks where practical, so subsequent Triton upgrades have a smaller
  maintenance surface.
- Preserve correctness and avoid material performance regressions for the existing Arm64 CPU
  operator set. Exact acceptance criteria will be added with the implementation.

### Non-Goals

- Any GPU or NPU backend migration, including NVIDIA, AMD, Ascend, or other accelerator
  backends.
- Support or acceptance claims for x86_64 CPU, Windows, or macOS. Existing code paths may
  remain, but this FEP does not validate them.
- Adding new TLE operators, model integrations, quantization formats, or ISA-specific
  optimizations solely as part of the version bump.
- A full redesign of `flagtree-cpu` as a completely independent out-of-tree backend. Triton
  3.7 extension hooks may be adopted incrementally where they reduce maintenance risk.
- Upgrading FlagGems, PyTorch, or other downstream projects beyond the minimum compatibility
  changes required to exercise the FlagTree CPU path.
- Maintaining binary or compiler-cache compatibility between Triton 3.3/3.6 and Triton 3.7.

## Proposal

Create a coordinated Triton 3.7.x CPU line rather than applying isolated compatibility
patches to the existing 3.3 or 3.6 branches. The implementation starts from a fixed upstream
3.7.x release commit, then forward-ports the CPU-specific changes as reviewable layers:

1. **Compiler baseline:** adopt the Triton 3.7 source baseline and its pinned LLVM toolchain.
2. **CPU backend interface:** migrate CPU target discovery, backend options, compiler stages,
   driver, launcher, and cache integration to the 3.7 interfaces.
3. **Dialect and lowering:** migrate the TritonCPU dialect, TableGen output, pass pipelines,
   pybind bindings, and LLVM lowering.
4. **Arm64 runtime and TLE:** reconnect the existing Arm64 feature detection, runtime
   functions, and TLE operations without expanding the operator scope.
5. **FlagTree integration:** expose the migrated backend through FlagTree's existing CPU
   selection path and document the exact source revisions used together.

From a user perspective, kernels remain regular Triton kernels and the backend remains named
`cpu`. FlagTree builds continue to select the CPU backend through `FLAGTREE_BACKEND=cpu`.
Internal developer-only switches in `flagtree-cpu` may remain, but they must not replace the
FlagTree-facing interface.

The migration will prefer a clean 3.7 baseline plus isolated CPU changes over mixing unrelated
backend commits into the CPU branch. Existing 3.3 and 3.6 branches remain available during the
transition for comparison and rollback; this FEP does not require deleting or rewriting their
history.

## Design Details

The table below identifies the expected migration surfaces. Exact code changes will be
recorded by the implementation PRs.

| Area | Triton 3.7 migration requirement |
|---|---|
| Source and LLVM baseline | Pin a stable Triton 3.7.x commit and the LLVM revision declared by that commit; do not reuse the older LLVM pin implicitly. |
| Python backend | Adapt CPU backend/driver registration, target representation, compiler options, stage construction, module loading, cache keys, and launcher signatures to 3.7 APIs. |
| MLIR dialect and passes | Rebuild TritonCPU TableGen artifacts and update dialect registration, pass APIs, type conversion, and TTIR-to-CPU/LLVM lowering for the 3.7 MLIR interfaces. |
| Extension boundary | Use Triton 3.7 pass/dialect plugin hooks where they cover existing integration needs; document any remaining in-tree patch points. |
| Build system | Update CMake targets, pybind registration, generated headers, and extension enablement to match the 3.7 build layout. |
| Arm64 runtime | Preserve runtime feature detection and safe ISA dispatch for the existing Arm64 code paths; do not make a newer optional ISA an unconditional build or runtime requirement. |
| Version and cache identity | Include the Triton/LLVM/CPU-backend revisions in version reporting and cache identity; stale 3.3/3.6 artifacts must not be reused by 3.7. |

### Arm64 Platform Boundary

Acceptance under this FEP is limited to Linux hosts reporting `aarch64`/`arm64`. The exact
distribution, compiler version, minimum ISA features, and reference machine will be fixed when
development produces a buildable baseline and the Test Plan is written. Until then, this
document makes no package-availability or tested-hardware claim.

### Compatibility Expectations

- Existing supported Triton CPU kernels should continue to compile without changes unless an
  upstream 3.7 language change makes a source update unavoidable.
- Existing Arm64 TLE operations should keep their public names and semantics.
- Compiler caches produced by older Triton lines are incompatible and must be isolated or
  invalidated.
- Performance improvement is not required for acceptance, but material regressions against the
  pre-upgrade Arm64 baseline must be investigated before this FEP can become `Implemented`.

### Main Risks

- **Internal API churn:** the CPU backend uses compiler interfaces that are not all stable
  public APIs. The migration should keep compatibility changes separated by layer.
- **LLVM behavior changes:** a new LLVM pin can change AArch64 code generation, correctness,
  or performance even when the Triton kernel is unchanged. The final test plan must compare
  both correctness and representative performance.
- **Extension-boundary mismatch:** Triton 3.7 plugin hooks may not cover every existing CPU
  customization. Remaining patches must be documented rather than hidden in a broad rebase.
- **Scope expansion:** unrelated operators and accelerator changes make version-bump failures
  harder to diagnose. They should be tracked in separate work.

## Packaging

**(Required)**

TBD. Implementation has not started. Packaging format, supported build environment, exact
build commands, and artifact publication will be added after the Triton 3.7 CPU integration
is buildable.

## Test Plan

**(Required)**

TBD. Implementation has not started. The test plan will be written once the migrated backend
can compile and run on Linux Arm64. No other architecture will be used as an acceptance
platform for this FEP.

## Related PRs

No implementation PRs exist at the time of this draft.

## References

- [FEP-0015: Arm64 CPU Backend for FlagOS (TLE + Triton-CPU)](./0015-arm64-cpu-backend-flagtree-tle.md)
- [FlagTree](https://github.com/flagos-ai/FlagTree)
- [flagtree-cpu](https://github.com/flagos-ai/flagtree-cpu)
- [Triton 3.7.0 release notes](https://github.com/triton-lang/triton/releases/tag/v3.7.0)
- [Triton 3.7.1 release notes](https://github.com/triton-lang/triton/releases/tag/v3.7.1)

## Implementation History

- 2026-07-29: Initial provisional draft. Scope limited to the FlagTree CPU backend with Linux
  Arm64 as the only acceptance platform; Packaging and Test Plan deferred until development
  starts.

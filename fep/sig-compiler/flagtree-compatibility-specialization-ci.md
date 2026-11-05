# FEP-NNNN: FlagTree Triton API Compatibility, Unified Specialization and CI Gates

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Preserve Triton 3.6 APIs while supporting the Triton 3.7 Python interfaces required by the next FL inference plugins. Complete unified backend specialization and expand FlagTree CI/CD coverage. The acceptance boundary is a reproducible multi-backend compiler package that runs the frozen FlagGems operator sources unchanged and detects integration regressions before merge.

Repository: [FlagTree](https://github.com/flagos-ai/FlagTree).

## Motivation

Inference-plugin upgrades expose compiler API and environment incompatibilities. Backend-specific copies and late integration testing make these problems harder to isolate. API compatibility, controlled specialization and representative operator/model CI form one delivery contract for existing supported platforms.

### Goals

- **G1:** Inventory and implement the Triton 3.7 Python APIs required by the next vLLM/SGLang FL plugin versions while retaining the agreed 3.6 API surface.
- **G2:** Run the frozen FlagGems operator implementation unchanged across the accepted API/backend matrix.
- **G3:** Complete 100% of applicable Python/C++ unified-specialization cells in the frozen backend/branch matrix.
- **G4:** Reach at least 90% of applicable CI/CD coverage cells, with explicit exceptions for lower-priority backends or unavailable hardware.

### Non-Goals

Full upstream Triton 3.7 feature parity, silent removal of 3.6 compatibility and acceptance of the separate new-hardware roadmap.

## Design Details

### API compatibility

Derive the required API inventory from the selected plugin dependency requirements and import/call sites. Coordinate with [vLLM FEP-0140](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0140-vllm-multi-version-platform-compatibility.md) and [SGLang FEP-0141](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0141-sglang-multi-platform-upgrade-and-model-support.md). Record each symbol/signature, 3.6 behavior, required 3.7 behavior, consumer and regression test. Compatibility is measured against this inventory, not inferred from a version string.

### Unified specialization

Keep backend differences in backend-owned files, reusing the common implementation. Verify Python module/function selection and C++ include/CMake specialization without adding new vendor-specific branches to shared code. Cover regular wheel installations and editable development mode, including fallback to shared code and isolation between backend builds.

Track the main and relevant 3.7 release lines with backend × language × branch entries. An inapplicable entry needs a reason; a missing implementation is incomplete. Freeze the denominator before reporting 100%.

### CI/CD

Use a backend × validation-layer × release-line matrix: unit/tutorial tests, two-device distributed tests where applicable, wheel delivery, FlagGems correctness, FlagGems benchmarks and model-inference benchmarks. Pin FlagGems revisions and the historically passing operator list. Reuse the release inference environment for model regression.

Coverage = implemented and successfully exercised applicable cells / all applicable cells. Report approved hardware exceptions separately; do not count skipped cells as passed or silently remove them from the denominator. Required correctness jobs block merge. Performance jobs publish comparable results and flag regressions for review.

## Packaging

**Supported vendors:** the frozen existing-backend/branch matrix, TBD. New-device acceptance belongs to the device-enablement FEP.

**Wheel:** API adapters and specialization changes ship in FlagTree; CI workflows and matrix manifests are versioned repository files.

Build a backend-specific FlagTree wheel from the selected release tag, using its documented SDK/LLVM/Python environment and `FLAGTREE_BACKEND` selector where required:

```bash
python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist
```

Record the source tag, Triton line, Python ABI, toolkit versions and wheel checksum. Release tag and dependency pins: TBD.

## Test Plan

### G1–G2: API and consumer regression

Run the supported common runtime suite in each target compiler environment:

```bash
python3 -m pytest -q python/test/unit/runtime
```

Add inventory-driven import/signature/behavior tests for the required 3.7 interfaces. Run the pinned FlagGems correctness list without operator-source modifications and record the source hash. API-inventory and FlagGems selection commands: TBD.

For model integration, reuse the vLLM-Plugin-FL adaptation gate against Qwen3.6-27B and Qwen3.6-35B-A3B. From its matching source checkout:

```bash
cd tools/adaptation-gate-cases
MODEL_PATH=/models/Qwen3.6-27B PORT=8000 TENSOR_PARALLEL_SIZE=2 ./run_serve_eager.sh
```

In a second terminal, from that same directory:

```bash
MODEL_PATH=/models/Qwen3.6-27B PORT=8000 ./run_test.sh
```

Repeat with the second model and supported graph configuration, using platform-appropriate TP and pinned dependencies. Expected: the gate's request checks pass and logs confirm the intended FlagTree/backend. For SGLang, use FEP-0141's unit/functional/e2e runner with the same candidate compiler package.

### G3: specialization

For every applicable cell, verify specialized module/function selection, shared fallback, C++ compilation, wheel packaging and editable import behavior. Compare shared-source diffs and ensure a backend build cannot select another backend's overrides. Test commands: TBD.

### G4: gate effectiveness and coverage

Exercise each declared CI job. Use a controlled failing correctness case on a test branch to verify failure propagation to the required check; remove the test change afterward. Retain one passing and one intentionally failing run. Report coverage with the frozen denominator, exceptions and missing hardware separately. Workflow names and coverage-report command: TBD.

## Related PRs

- Baseline: [FEP-0098](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0098-flagtree-multi-backend-architecture.md).
- [ ] Required 3.7 API inventory and compatibility changes — TBD.
- [ ] Remaining specialization migrations — TBD.
- [ ] CI/CD matrix and consumer regression gates — TBD.

## Implementation History

- 2026-11-05: Initial FlagOS 2.3 proposal.

# FEP-0168: FlagTree Multi-Platform Support and Triton API Compatibility

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Extend [FlagTree](https://github.com/flagos-ai/FlagTree) to the planned new backends and accelerator generations. Preserve native Triton 3.6 operator compatibility on NVIDIA and provide the Triton 3.7 Python interfaces required by the next FL framework releases. Use one platform/dependency matrix for compiler packages, operator regression and applicable framework tests. Backend specialization and CI improvements support this delivery.

## Motivation

A supported platform needs a working compiler package, correct operator execution and compatible framework dependencies. New hardware and API compatibility share this integration work, while each platform needs its own readiness and test results.

### Goals

- **G1:** Add the new backends and device generations listed below, with build and on-device validation for each delivered entry.
- **G2:** Preserve native operators that run with upstream Triton 3.6 on NVIDIA. Validate supported FlagGems operators on each accepted backend without changing their implementation for API compatibility.
- **G3:** Support the Triton 3.7 Python APIs required by the selected vLLM, PyTorch and FL plugin versions on the applicable existing FlagTree lines. API inventory and version matrix: TBD.
- **G4:** Complete the planned unified-specialization work and CI coverage: 100% of the agreed specialization scope and 90% of the agreed CI scope. Scope definitions and exceptions: TBD.

### Non-Goals

Full upstream Triton 3.7 feature parity, migration of every vendor to a new 3.7 branch, model-serving support on backends with compiler/operator-only scope, and a universal performance-gain target.

## Proposal

Track hardware support, compiler API compatibility and release dependencies in one matrix. For each platform, record vendor/SKU, FlagTree revision and branch, SDK/driver, Python/PyTorch, FlagGems, applicable framework/plugin versions, build artifact and test commands. Align SDK/driver versions with the framework release environment.

### Platform scope

| Platform | Planned work | Readiness / acceptance scope |
|---|---|---|
| Yuntian Lifei / DeepVision | New backend | Compiler integration in progress; two remote test cards reported available. CI integration pending. Compiler and supported-operator tests; framework integration TBD. |
| D-Robotics S600 | New backend | High risk; implementation progress and hardware readiness unconfirmed. Inclusion in 2.3 TBD. |
| EVAS Intelligence | New backend | High risk; implementation progress and hardware readiness unconfirmed. Inclusion in 2.3 TBD. |
| NVIDIA B200 | New device generation | Test hardware unavailable at planning review; on-device validation pending. |
| Iluvatar BI300 | New device generation | High risk; dependent on vendor adaptation. SDK/hardware readiness TBD. |
| T-Head 890 | New device generation | SDK/driver and test access TBD. |
| Hygon BW1100 | New device generation | CI hardware reported available; compiler integration and acceptance pending. |
| Huawei Ascend 950 | New device generation | CANN/toolchain and test access TBD. |

Existing supported platforms remain in the regression matrix. The native Triton 3.6 compatibility target on NVIDIA does not imply universal operator support on all vendor backends. New-platform operator coverage is measured from the selected supported list; estimated coverage is not a release result.

Keep platform results separate. A delayed new backend must not obscure the status of API compatibility or another platform. Confirm high-risk entries before release scope is finalized; record any agreed deferral in the FEP and release tracking.

### Triton API compatibility

Identify the symbols, signatures and behavior needed by the selected framework versions. Adapt those interfaces on the applicable existing FlagTree lines, including the 3.6 line, and retain the existing 3.6 interfaces. Do not require a new vendor branch solely because a framework declares Triton 3.7.

Use [vLLM FEP-0140](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0140-vllm-multi-version-platform-compatibility.md) and [SGLang FEP-0141](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0141-sglang-multi-platform-upgrade-and-model-support.md) for the applicable framework release configurations. Compiler-only backends are tested at the compiler/operator level until framework support is defined.

### Specialization and CI

Complete the existing Python/C++ backend-specialization migration and reuse common compiler code. Preserve the existing specialization rules, including documented exceptions in shared code.

Track migration and CI coverage against the agreed backend/branch checklist. Define the denominator before reporting 100% or 90%; record unavailable hardware and other exceptions separately. These percentages describe engineering coverage, not operator pass rates or performance gains.

Reuse the FlagGems CI integration to check a pinned operator revision and its previously passing cases. Use the framework release environment for applicable model tests. The specialization and CI work belongs in this FEP's implementation tasks; it does not need a separate feature proposal.

## Packaging

**Target vendors:** the platform table plus existing supported backends for regression.

**Wheel:** backend-specific FlagTree wheels. API adapters and specialization changes are part of the compiler; CI workflows remain repository files.

From the selected FlagTree checkout, use the backend's documented build environment and selector:

```bash
python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist
```

Record the source revision, backend, Python ABI, SDK/driver and wheel checksum. Release revisions and platform dependency pins: TBD.

## Test Plan

### G1: package and hardware support

In the environment containing the candidate wheel:

```bash
python3 - <<'PYTEST'
from importlib.metadata import version
import triton
print(version('flagtree'))
print(triton.__version__)
print(triton.__file__)
PYTEST
```

Expected: imports succeed and versions/paths identify the intended package. Then run the backend's supported compiler tests and selected operators on the named device. Per-platform commands and operator lists: TBD.

| Check | Expected result |
|---|---|
| Target selection and compilation | Correct device target; selected operators compile |
| Device execution | Reference results within the selected tolerances, including supported tail/masked cases |
| Earlier device generations | Previously supported cases remain passing |
| New-backend CI | Hardware jobs run and publish test results |
| Release record | Source revision, wheel, SDK/driver, test selection and results available per platform |

Package imports and compilation alone do not complete hardware acceptance.

### G2–G3: operator and API compatibility

Run the common runtime tests from the matching FlagTree checkout:

```bash
python3 -m pytest -q python/test/unit/runtime
```

Expected: applicable tests pass. Add tests for the required 3.7 symbols and behavior; inventory-specific commands: TBD.

For the NVIDIA native-operator comparison, run the same selected operator sources first with upstream Triton 3.6 and then with the candidate FlagTree. Hold hardware, inputs and other dependencies fixed. Expected: all previously passing selected cases remain correct. The native-operator list and command are TBD; the runtime suite alone does not establish this coverage.

For FlagGems regression, reuse the existing [FlagTree test action](https://github.com/flagos-ai/FlagTree/tree/main/.github/actions/run-flaggems-test). In a disposable FlagGems test checkout, set `FEP_GEMS_PATH` to its absolute path, `FEP_GEMS_TAG` to the matching CI-assets tag, `FEP_OPERATOR_LIST` to the approved operator-list file and `FEP_DEVICE_IDS` to the test devices. From the FlagTree checkout:

```bash
export FEP_TREE_ROOT="$PWD"
cp ".github/actions/run-flaggems-test/assets/$FEP_GEMS_TAG/conftest.py" \
  "$FEP_GEMS_PATH/tests/conftest.py"
export PYTHONPATH="$FEP_GEMS_PATH/src${PYTHONPATH:+:$PYTHONPATH}"
python3 "$FEP_TREE_ROOT/.github/actions/run-flaggems-test/assets/ci/ci_run_tests.py" \
  --flaggems-path "$FEP_GEMS_PATH" --gpus "$FEP_DEVICE_IDS" \
  --op-list-file "$FEP_OPERATOR_LIST" --output-dir "$FEP_TREE_ROOT/artifacts/gems-compat"
```

Expected: the approved cases are collected and pass; preserve case counts, failures and skips. The CI fixture changes test collection only; FlagGems operator sources stay fixed. Do not treat an empty collection or a skipped case as a pass.

### G3: framework integration

For supported vLLM platforms, reuse FEP-0140's baseline models and adaptation-gate scripts. From the matching vLLM-Plugin-FL checkout:

```bash
cd tools/adaptation-gate-cases
MODEL_PATH=/models/Qwen3.6-27B PORT=8000 TENSOR_PARALLEL_SIZE=2 \
  ./run_serve_eager.sh
```

From the same directory in a second terminal:

```bash
MODEL_PATH=/models/Qwen3.6-27B PORT=8000 ./run_test.sh
```

Repeat for Qwen3.6-35B-A3B and supported graph mode, with platform-appropriate TP. Expected: the gate's request checks pass using the candidate compiler and agreed dependencies. Reuse FEP-0141's tests for supported SGLang configurations. Additional PyTorch API cases: TBD.

### G4: specialization and CI coverage

Use each backend's existing build/import and regression jobs to verify the migration. Check specialization selection and ordinary/editable installations where supported. Record checklist completion, test-run links and exceptions. Remaining job names and coverage-report command: TBD.

For performance comparisons between 2.2 and 2.3, keep FlagGems/operator sources, framework versions, inputs and other dependencies fixed and change only FlagTree. Reuse the CI benchmark workloads and record both gains and regressions. Updating the whole framework environment is a separate integration comparison. There is no agreed platform-wide speedup threshold.

## Related PRs

- Baseline: [FEP-0098](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0098-flagtree-multi-backend-architecture.md).
- [ ] New backends and device-generation support — TBD.
- [ ] Required Triton 3.7 API compatibility — TBD.
- [ ] Remaining specialization and CI integration — TBD.
- [ ] Platform dependency matrix and hardware/operator/framework acceptance — TBD.

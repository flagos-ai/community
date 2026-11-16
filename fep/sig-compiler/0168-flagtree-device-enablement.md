# FEP-0168: FlagTree Multi-Platform Support and Triton API Compatibility

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Extend [FlagTree](https://github.com/flagos-ai/FlagTree) to new backends and accelerator generations, and provide the Triton interfaces required by the target FL framework releases. Support installation and application upgrades without changing supported operator implementations.

## Motivation

Differences in vendor SDKs, compiler interfaces and framework dependencies complicate deployment across AI chips. This proposal brings device support and API compatibility into one release scope, validated through installation, operator execution and model serving.

### Goals

- **G1:** Add the new backends and device generations listed below, with installable artifacts and on-device validation for each delivered entry.
- **G2:** Preserve native operators that run with upstream Triton 3.6 on NVIDIA. Validate supported FlagGems operators on each accepted backend without changing their implementation for API compatibility.
- **G3:** Support the Triton 3.7 Python APIs required by the selected vLLM, PyTorch and FL plugin versions on the applicable existing FlagTree lines. API inventory and version matrix: TBD.
- **G4:** Complete the planned unified-specialization work and CI coverage: 100% of the agreed specialization scope and 90% of the agreed CI scope. Scope definitions and exceptions: TBD.

### Non-Goals

Full upstream Triton 3.7 feature parity, migration of every vendor to a new 3.7 branch, model-serving support on backends with compiler/operator-only scope, and a universal performance-gain target.

## Proposal

### Platform scope

| Platform | Planned work | Status |
|---|---|---|
| Intellifusion / 云天励飞 | New backend | [#1598](https://github.com/flagos-ai/FlagTree/pull/1598) merged into `triton_v3.8.x` for `ifwa:100`, with CModel CI and delivery workflows. Wheel and physical-device acceptance pending; FlagGems/framework scope TBD. |
| D-Robotics S600 | New backend | High risk. Implementation, SDK, hardware and operator scope unconfirmed; inclusion in 2.3 TBD. |
| EVAS Intelligence | New backend | High risk. Implementation, SDK, hardware and operator scope unconfirmed; inclusion in 2.3 TBD. |
| NVIDIA B200 | New device generation | Uses the NVIDIA backend on `main` / Triton 3.6. B200 package and device acceptance pending. |
| Iluvatar BI300 | New device generation | High risk; dependent on vendor adaptation. SDK, package and hardware acceptance TBD. |
| T-Head 890 | New device generation | PPU backend and Qwen benchmark infrastructure available. Exact SKU, SDK/driver and device acceptance pending. |
| Hygon BW1100 | New device generation | Dedicated build, FlagGems and Qwen CI configurations merged in [#1514](https://github.com/flagos-ai/FlagTree/pull/1514)/[#1597](https://github.com/flagos-ai/FlagTree/pull/1597). Release-environment acceptance pending. |
| Huawei Ascend 950 | New device generation | CANN/toolchain, hardware access and device acceptance TBD. The [Ascend 3.6 port (#1637)](https://github.com/flagos-ai/FlagTree/pull/1637) remains open. |

Existing supported platforms remain in regression coverage. Define operator and framework support separately for each platform.

### Triton API compatibility

Identify the Python symbols, signatures and behavior required by the target framework versions. Implement them on the applicable existing FlagTree lines, including 3.6, while retaining the existing 3.6 interfaces.

Use [vLLM FEP-0140](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0140-vllm-multi-version-platform-compatibility.md) and [SGLang FEP-0141](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0141-sglang-multi-platform-upgrade-and-model-support.md) for framework configurations. FEP-0140 selects vLLM 0.32 as the main 2.3 release version. Validate both API imports and their actual framework callers.

### Specialization and CI

Complete Python/C++ backend specialization and reuse common compiler code, preserving documented exceptions. Support normal-wheel and editable installations where offered.

Define the specialization checklist by backend and Python/C++ migration item, and the CI checklist by backend, compiler line and job type. Cover build/install, compiler examples, operator regression, delivery and applicable model tests. Report the 100%/90% goals against these checklists, with successful runs and hardware exceptions.

## Packaging

Deliver backend-specific FlagTree wheels for the platform scope above. The default distribution name is `flagtree`, with a build-time `FLAGTREE_WHEEL_NAME` override; the Python import namespace remains `triton`.

Build in the backend's documented environment with dependencies installed. Set `FLAGTREE_BACKEND` to its build selector; leave it unset for standard NVIDIA builds, following the [installation guide](https://github.com/flagos-ai/FlagTree#environment-setup):

```bash
python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist
```

Release packages and dependency versions: TBD.

## Test Plan

Use the agreed release dependencies for development and acceptance. Fix the device, software versions and required cases for each configuration, and retain test results. Hardware or configuration gaps remain pending.

### T1 — Install and use the correct compiler (G1, G3, G4)

Test both a clean installation and an upgrade from an existing supported FlagOS environment. After installing all application dependencies, run the following outside the source checkout with the application's Python executable. Add any required vendor runtime-extension import before probing the driver:

```bash
python3 - <<'PYTEST'
import os
import sys
from importlib.metadata import version
import triton
from triton.runtime import driver

print("Python:", sys.executable)
print("Distribution:", version(os.environ.get("FEP_DIST_NAME", "flagtree")))
print("Triton:", triton.__version__, triton.__file__)
print("Driver:", type(driver.active).__module__)
print("Target:", driver.active.get_current_target())
PYTEST
```

**Pass:** the installed package and loaded module match the selected release, the backend targets the correct device, and a supported operator executes correctly. Check for dependency conflicts with `python3 -m pip check`. Repeat in a fresh process, and test editable installation separately where offered. Installation must work through the documented steps without manual `site-packages` patches.

### T2 — Run existing Triton operators on the target chip (G1, G2)

On NVIDIA, compare upstream Triton 3.6 and the candidate FlagTree on the same device using identical operator sources and inputs. On other backends, use their supported operator lists and reference implementations. Cover these workloads where supported:

| Workload | Cases | Expected result |
|---|---|---|
| Elementwise computation and data movement | Small/large inputs, partial blocks/masks, supported non-contiguous layouts | Correct values, shape and dtype; masked writes preserve surrounding data. |
| Reductions and normalization | Supported softmax/RMSNorm/reduction workloads with different reduction lengths | Results meet existing dtype-specific tolerances. |
| Matrix multiplication and attention | Supported model-derived shapes/dtypes; low precision only on declared configurations | Compilation and device execution succeed; numerical results meet reference checks. |
| Repeated application use | First compilation, repeated execution and a fresh process with the supported cache configuration | Correct results throughout; record first-use and steady-state behavior separately. |
| Earlier device generation | Previously passing cases on the same vendor's supported earlier device | No correctness regression after the compiler upgrade. |

Keep operator implementations unchanged during compatibility testing.

For Intellifusion, configure the IFWA environment and run from the 3.8 checkout:

```bash
python3 third_party/intellifusion/ci/check_install.py --torch-ifwa
python3 -m pytest -q third_party/intellifusion/examples/test_vector_add.py
```

`check_install.py` checks installation only. Run the operator cases on physical hardware for device acceptance; keep CModel results separate.

### T3 — Keep FlagGems applications correct after the upgrade (G1, G2, G3)

Run a representative application and confirm that it executes the intended FlagGems kernels. Then compare baseline and candidate compilers using the same FlagGems revision and the platform's required operator list.

Reuse the [FlagTree test action](https://github.com/flagos-ai/FlagTree/tree/main/.github/actions/run-flaggems-test). Set absolute paths for `FEP_GEMS_PATH` (a disposable checkout), `FEP_OPERATOR_LIST` (one operator ID per line), `FEP_SKIP_FILE` (reviewed exclusions) and `FEP_RESULT_DIR` (a new directory for this run). Set `FEP_GEMS_TAG` to the matching tag and `FEP_DEVICE_IDS` to comma-separated device IDs. From the pinned FlagTree checkout:

```bash
export FEP_TREE_ROOT="$PWD"
FEP_FIXTURE="$FEP_TREE_ROOT/.github/actions/run-flaggems-test/assets/gems/$FEP_GEMS_TAG/conftest.py"
if [ -f "$FEP_FIXTURE" ]; then
  cp "$FEP_FIXTURE" "$FEP_GEMS_PATH/tests/conftest.py"
fi
export PYTHONPATH="$FEP_GEMS_PATH/src${PYTHONPATH:+:$PYTHONPATH}"
python3 "$FEP_TREE_ROOT/.github/actions/run-flaggems-test/assets/ci/ci_run_tests.py" \
  --repo-kind flaggems --flaggems-path "$FEP_GEMS_PATH" \
  --gpus "$FEP_DEVICE_IDS" --op-list-file "$FEP_OPERATOR_LIST" \
  --skip-file "$FEP_SKIP_FILE" --output-dir "$FEP_RESULT_DIR"
```

If the tag has no fixture override, its own `conftest.py` must support collection and JSON reporting. For FlagGems-vllm, use `--repo-kind flaggems-vllm`, its separate checkout and the required `assets/gems-vllm/<tag>/conftest.py`. Fix the test-runner revision for both baseline and candidate runs.

**Pass criteria:**

- All required operators and parameterized cases execute and pass; exclusions cannot remove required cases. Check raw results against the case list for failures, missing cases, skips, collection errors and timeouts.
- `marks_collection_ok` is true; `failed`, `errors` and `not_found` are zero for required cases. Verify actual passing-case counts: the runner may return zero with failures or label an all-skipped operator `Passed`.
- Run the full agreed parameter set for acceptance. Reserve `--quick` and `--first-parameter-only` for smoke tests.

Compare results with the matching baseline, using `FEP_BASELINE_RESULT_DIR` for its report directory:

```bash
python3 "$FEP_TREE_ROOT/.github/actions/compare-flaggems-test/scripts/compare_test_result.py" \
  --baseline "$FEP_BASELINE_RESULT_DIR/summary.json" \
  --candidate "$FEP_RESULT_DIR/summary.json" --exit-code
```

Use matching hardware, sources and cases for both reports. New backends require all required-case checks even when no historical baseline exists.

### T4 — Upgrade the framework and serve real requests (G3)

Test required APIs through their framework callers in the target release environment, including vLLM 0.32 configurations from FEP-0140. Where PyTorch Inductor is supported, compare a compiled workload with eager execution.

For supported vLLM platforms, use real Qwen3.6-27B and Qwen3.6-35B-A3B weights with platform-appropriate TP/memory settings. From the matching plugin checkout:

```bash
cd tools/adaptation-gate-cases
MODEL_PATH=/models/Qwen3.6-27B PORT=8000 TENSOR_PARALLEL_SIZE=2 \
  ./run_serve_eager.sh
```

In a second terminal, from the same directory, set `FEP_MODEL_RESULT_DIR` to a new absolute results directory and run:

```bash
MODEL_PATH=/models/Qwen3.6-27B PORT=8000 \
  RESULTS_DIR="$FEP_MODEL_RESULT_DIR" ./run_test.sh
```

Repeat for the MoE model. Where graph mode is supported, stop the eager service, start `run_serve_graph.sh` on port 8001 and repeat the requests. Save results separately for each model/mode and confirm graph capture/execution in the logs.

**Pass:** the FL plugin and candidate compiler are active, and all five scenarios pass: single text, single image, concurrent text, concurrent image and mixed requests (26 requests total). No API, JIT, device-launch or graph-capture errors occur. Task accuracy meets the framework's agreed dataset metrics and tolerances.

Reuse FEP-0140/FEP-0141 performance, load and stability tests on the same candidate image, recording throughput, TTFT/TPOT and resource behavior. SGLang uses FEP-0141's applicable cases; these tests apply only to platforms with framework support.

### T5 — Upgrade, regress and reproduce the release (G1–G4)

Rerun applicable T1–T4 workflows on existing platforms, comparing the previous supported compiler with the candidate while keeping other dependencies, inputs and hardware fixed. Record first-use compilation time and steady-state performance separately. Report comparisons requiring dependency changes as full-stack upgrades.

Investigate regressions against the agreed workload baselines. Verify rollback by restoring the previous working image and rerunning a representative workload.

For G4, verify normal/editable installations and the required CI jobs. Count successful executions against the coverage checklist; retain skipped jobs and hardware gaps as exceptions.

Before acceptance, confirm the platform/operator/API scope, release dependencies, reference tolerances and coverage checklists.

## Related PRs

- Baseline: [FEP-0098](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0098-flagtree-multi-backend-architecture.md).
- [ ] New backends and device-generation support — Intellifusion [#1598](https://github.com/flagos-ai/FlagTree/pull/1598) and BW1100 CI [#1514](https://github.com/flagos-ai/FlagTree/pull/1514)/[#1597](https://github.com/flagos-ai/FlagTree/pull/1597) merged; remaining implementation and acceptance TBD.
- [ ] Required Triton 3.7 API compatibility — full inventory/implementation TBD; Ascend [#1507](https://github.com/flagos-ai/FlagTree/pull/1507) is an open compatibility fix to track.
- [ ] Remaining specialization and CI integration — includes open XPU Python [#1422](https://github.com/flagos-ai/FlagTree/pull/1422) and MThreads C++ [#985](https://github.com/flagos-ai/FlagTree/pull/985); final checklist and acceptance TBD.
- [ ] Platform dependency matrix and hardware/operator/framework acceptance — TBD.

# FEP-0168: FlagTree Multi-Platform Support and Triton API Compatibility

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Extend [FlagTree](https://github.com/flagos-ai/FlagTree) to the planned new backends and accelerator generations. Users should be able to install the matching compiler, continue running supported Triton and FlagGems operators, and upgrade to the selected FL framework releases without rewriting operator implementations for API compatibility. Preserve native Triton 3.6 operator compatibility on NVIDIA and provide the Triton 3.7 Python interfaces required by those releases. Backend specialization and CI improvements support this delivery.

## Motivation

A backend being present in the repository does not establish that users can deploy it. The compiler package, vendor SDK, operator library and framework must work together on the named device. Acceptance therefore follows installation, operator execution and applicable model-serving workflows, with separate results for each platform and compiler line.

### Goals

- **G1:** Add the new backends and device generations listed below, with installable artifacts and on-device validation for each delivered entry.
- **G2:** Preserve native operators that run with upstream Triton 3.6 on NVIDIA. Validate supported FlagGems operators on each accepted backend without changing their implementation for API compatibility.
- **G3:** Support the Triton 3.7 Python APIs required by the selected vLLM, PyTorch and FL plugin versions on the applicable existing FlagTree lines. API inventory and version matrix: TBD.
- **G4:** Complete the planned unified-specialization work and CI coverage: 100% of the agreed specialization scope and 90% of the agreed CI scope. Scope definitions and exceptions: TBD.

### Non-Goals

Full upstream Triton 3.7 feature parity, migration of every vendor to a new 3.7 branch, model-serving support on backends with compiler/operator-only scope, and a universal performance-gain target.

## Proposal

### Platform scope

The following is the planned scope, with implementation evidence reviewed on **2026-11-16**. A merged backend, CI definition or simulator result is separate from release acceptance on physical hardware.

| Platform | Planned work | Implementation evidence / remaining acceptance |
|---|---|---|
| Intellifusion / 云天励飞 | New backend | [FlagTree #1598](https://github.com/flagos-ai/FlagTree/pull/1598) merged into `triton_v3.8.x` on November 12, adding the `intellifusion` backend for `ifwa:100` and build/delivery workflows. The build test uses CModel. Published-wheel and physical-device acceptance remain to be supplied; FlagGems and framework scope must be confirmed. |
| D-Robotics S600 | New backend | High-risk roadmap entry. Implementation revision, SDK, hardware and operator scope remain unconfirmed; inclusion in 2.3 TBD. |
| EVAS Intelligence | New backend | High-risk roadmap entry. Implementation revision, SDK, hardware and operator scope remain unconfirmed; inclusion in 2.3 TBD. |
| NVIDIA B200 | New device generation | NVIDIA compiler support exists on `main` / Triton 3.6. B200 artifact, device-specific case selection and acceptance report remain to be supplied; earlier NVIDIA devices do not establish B200 acceptance. |
| Iluvatar BI300 | New device generation | High-risk roadmap entry, dependent on vendor adaptation. Existing Iluvatar support does not establish BI300 support; SDK, artifact and hardware acceptance TBD. |
| T-Head 890 | New device generation | PPU backend and Qwen benchmark infrastructure exist. Confirm the exact 890 SKU, SDK/driver and release configuration, then validate on that device. |
| Hygon BW1100 | New device generation | `main` has BW1100 runners in build, FlagGems regression and Qwen benchmark workflows; [#1514](https://github.com/flagos-ai/FlagTree/pull/1514) and [#1597](https://github.com/flagos-ai/FlagTree/pull/1597) are merged. Candidate artifact, agreed runtime dependencies and per-device acceptance results remain to be supplied. |
| Huawei Ascend 950 | New device generation | Candidate CANN/toolchain, hardware access and acceptance remain unconfirmed. Existing Ascend support and the open [3.6 port (#1637)](https://github.com/flagos-ai/FlagTree/pull/1637) do not establish 950 acceptance. |

Existing supported platforms remain in the regression matrix. The NVIDIA native Triton 3.6 target does not imply universal operator support on all vendor backends. Record compiler/operator-only scope explicitly, and agree any platform deferral before finalizing the release support list.

### Platform and dependency matrix

Freeze one record for every accepted configuration:

- Exact device SKU/card count, FlagTree branch/SHA, wheel name/checksum and build backend.
- Runtime/application image digests, SDK/driver, LLVM/toolchain, Python/PyTorch, FlagGems and applicable FlagGems-vllm, framework/plugin and communication-library revisions.
- Supported operator IDs and test node IDs, shapes/dtypes/layouts, references/tolerances, exclusions and applicable model/mode/TP configurations.
- Test commands, expected case counts, raw results, CI-run links and the person responsible for resolving failures.

Use the same runtime dependencies for development and release acceptance; CI images may add test tools. Recheck the final application image after all dependencies are installed, including whether framework installation replaces the selected compiler or leaves conflicting modules.

### Triton API compatibility

Identify the symbols, signatures and behavior needed by the selected framework versions. Adapt those interfaces on the applicable existing FlagTree lines, including the 3.6 line, and retain the existing 3.6 interfaces. Do not require a new vendor branch solely because a framework declares Triton 3.7.

Distinguish package-version constraints, import compatibility and execution behavior in the API inventory. Changing a version string does not establish compatibility. The open [Ascend fix #1507](https://github.com/flagos-ai/FlagTree/pull/1507), for example, restores `triton.compiler.compiler.triton_key` for callers such as PyTorch Inductor on the 3.5 line. It is one concrete interface gap, not the complete 3.7 inventory. Intellifusion's separate 3.8 implementation is not evidence of compatibility on other compiler lines.

Use [vLLM FEP-0140](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0140-vllm-multi-version-platform-compatibility.md) and [SGLang FEP-0141](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0141-sglang-multi-platform-upgrade-and-model-support.md) for the applicable framework release configurations. FEP-0140 selects vLLM 0.32 as the main 2.3 release version. Older Qwen CI environments are regression baselines, not substitutes for testing the selected release dependencies. Compiler-only backends remain at compiler/operator scope until framework support is defined.

### Specialization and CI

Complete the existing Python/C++ backend-specialization migration and reuse common compiler code. Preserve the existing specialization rules, including documented exceptions in shared code.

Track specialization by backend and Python/C++ migration item. Track CI by backend, compiler line and job type: build/install, compiler examples, operator regression, delivery and applicable model tests. Define the denominators before reporting 100% or 90%; record successful runs and unavailable-hardware/out-of-scope exceptions. These percentages describe engineering coverage, not operator pass rates. Workflow files alone do not count as verified coverage.

Reuse the FlagGems CI integration to check a pinned operator revision and its previously passing cases. Use the framework release environment for applicable model tests. The specialization and CI work belongs in this FEP's implementation tasks; it does not need a separate feature proposal.

## Packaging

**Target vendors:** the platform table plus existing supported backends for regression.

**Wheel:** backend-specific FlagTree wheels. The package provides the `triton` import namespace. Record distribution metadata separately from `triton.__version__`: the default distribution name is `flagtree`, with a build-time `FLAGTREE_WHEEL_NAME` override. API adapters and specialization changes are part of the compiler; CI workflows remain repository files.

From the selected checkout, use the backend's documented build environment with build dependencies already installed. Set `FLAGTREE_BACKEND` to its build selector; for standard NVIDIA builds, leave it unset as documented in the [installation guide](https://github.com/flagos-ai/FlagTree#environment-setup):

```bash
python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist
```

Record the source revision, backend, Python ABI, SDK/driver and wheel checksum. Release revisions and platform dependency pins: TBD.

## Test Plan

Test on the declared hardware in disposable environments. Freeze the matrix and expected case selection first. Missing hardware, API inventories or required framework configurations are **blocked**, not passing results; explicitly excluded configurations remain out of scope. Compiler unit tests support diagnosis, while these user workflows determine acceptance.

### T1 — Install and use the correct compiler (G1, G3, G4)

Follow the published installation instructions in a clean vendor runtime image and install the pinned application dependencies. Repeat with an existing supported FlagOS environment upgraded to the candidate compiler. From outside all source checkouts, use the same Python executable as the application. If a backend requires an explicit runtime-extension import, add that documented import in this Python process before probing the driver:

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

Compare the output and installed-file ownership with the matrix; preserve wheel metadata and `python3 -m pip freeze` / `python3 -m pip check` output. Resolve or document dependency conflicts rather than changing version metadata to make a check pass.

**Pass:** the intended compiler/backend load, target architecture matches the physical device, and a supported operator executes correctly. Repeat in a fresh process after the complete framework installation. A stale upstream/vendor Triton, missing native library, zero/multiple active-driver error or wrong backend blocks acceptance. Test normal wheels outside the build checkout; separately test editable installation where offered. Neither installation may depend on manually copied `site-packages` files or undocumented build-only settings.

### T2 — Run existing Triton operators on the target chip (G1, G2)

On NVIDIA, run identical operator sources and inputs with upstream Triton 3.6 and the candidate FlagTree in separate environments on the same device. On other backends, use the declared supported list and established reference. Select cases from these user workloads where supported; this table does not assert universal backend coverage.

| Workload | Cases | Expected result |
|---|---|---|
| Elementwise computation and data movement | Small/large inputs, partial blocks/masks, supported non-contiguous layouts | Correct values, shape and dtype; masked writes preserve surrounding data. |
| Reductions and normalization | Supported softmax/RMSNorm/reduction workloads with different reduction lengths | Results meet existing dtype-specific tolerances. |
| Matrix multiplication and attention | Supported model-derived shapes/dtypes; low precision only on declared configurations | Compilation and device execution succeed; numerical results meet reference checks. |
| Repeated application use | First compilation, repeated execution and a fresh process with the supported cache configuration | Correct results throughout; record first-use and steady-state behavior separately. |
| Earlier device generation | Previously passing cases on the same vendor's supported earlier device | No correctness regression after the compiler upgrade. |

Do not edit the selected operator implementations to obtain API compatibility. Record source revisions and input cases. The NVIDIA native-operator inventory and each new backend's operator list remain required before acceptance; a few examples cannot establish the full compatibility claim.

For Intellifusion, the 3.8 branch provides these diagnostic entry points after its documented IFWA environment setup:

```bash
python3 third_party/intellifusion/ci/check_install.py --torch-ifwa
python3 -m pytest -q third_party/intellifusion/examples/test_vector_add.py
```

The first script checks installation without launching a kernel. The existing `ifwa3.8-build-and-test.yml` runs examples under CModel. Keep simulator results separate and rerun agreed cases with the physical-device runtime before claiming hardware support.

### T3 — Keep FlagGems applications correct after the upgrade (G1, G2, G3)

First run a representative application with the installed FlagGems package and verify execution of the intended FlagGems kernels. Then regress the frozen operator list at the same FlagGems revision with baseline and candidate compilers. Use per-platform release lists, not a union of operators passing on different chips.

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

The checked assets include `gems/v5.3.5/conftest.py`. If the tag has no override, verify that its own fixture supports collection and JSON reporting. The override is test instrumentation; operator sources stay fixed. For applicable FlagGems-vllm workloads, use `--repo-kind flaggems-vllm`, its separate checkout and the required `assets/gems-vllm/<tag>/conftest.py`. Pin the action/runner revision independently when testing another compiler branch.

**Pass criteria:**

- All required operators and parameterized cases are present and pass. Compare raw pytest results/node IDs against the frozen selection; retain failures, skips, deselections, collection errors and timeouts.
- `marks_collection_ok` is true; required-case `failed`, `errors` and `not_found` counts are zero. Every required operator has executed passing cases. Exclusions cannot remove required cases or shrink the previously passing set.
- Inspect raw logs even if `summary.json` exists: the runner can return zero with failed tests, and its operator `Passed` status can include an all-skipped operator. Missing or partial execution cannot pass.
- Acceptance uses the full agreed parameter set. `--quick` and `--first-parameter-only` provide smoke coverage only.

Use the comparator to help identify baseline regressions, setting `FEP_BASELINE_RESULT_DIR` to the matching baseline report directory:

```bash
python3 "$FEP_TREE_ROOT/.github/actions/compare-flaggems-test/scripts/compare_test_result.py" \
  --baseline "$FEP_BASELINE_RESULT_DIR/summary.json" \
  --candidate "$FEP_RESULT_DIR/summary.json" --exit-code
```

Both reports must use the same operator sources, case selection and hardware. A missing baseline blocks regression acceptance. The comparator does not replace required-case checks, particularly on a new backend without a baseline.

### T4 — Upgrade the framework and serve real requests (G3)

Use the selected release image/dependencies, including vLLM 0.32 configurations from FEP-0140. Check required API imports/signatures, then execute their actual callers. Where PyTorch Inductor is in scope, run a supported compiled workload and compare with eager output; importing `torch` or `triton` alone is insufficient. Maintain a caller-to-test mapping for required APIs, including known gaps such as Ascend's `triton_key` export.

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

Repeat for the MoE model. Where graph mode is supported, stop the eager service, start `run_serve_graph.sh` on port 8001 and run the same requests against it. Keep separate results per model/mode/run. Confirm actual graph capture/execution from platform logs; omitting `--enforce-eager` is not itself graph coverage.

**Pass:** the FL plugin and candidate compiler are active; all five scenarios pass (single text, single image, concurrent text, concurrent image and mixed requests; 26 requests in the checked scripts). Preserve request outputs and service logs. No missing-interface, JIT, device-launch or graph-capture failures are allowed in supported configurations. Also check task accuracy against the framework's agreed datasets/tolerances; request checks alone do not establish model accuracy.

Reuse FEP-0140/FEP-0141 performance, load and stability acceptance on the same candidate image with the framework owners. Record throughput, TTFT/TPOT and resource behavior. SGLang uses FEP-0141's applicable cases. Compiler/operator-only backends do not inherit framework support claims.

### T5 — Upgrade, regress and reproduce the release (G1–G4)

On existing platforms, compare the previous supported compiler with the candidate while holding operator sources, framework, SDK/driver, inputs and device fixed. Rerun applicable T1–T4 workflows. Separate first-use compilation time from steady-state performance. When dependencies cannot be held fixed, label the result a full-stack upgrade comparison rather than attributing it to FlagTree alone.

Investigate correctness and performance regressions against the agreed per-workload baseline; no platform-wide speedup threshold is specified. Restore the previous known-good test image and rerun a representative workload to verify a usable rollback path.

For G4, attach normal/editable installation results and successful CI runs to the specialization/CI checklist. Jobs skipped by path filters, draft status or missing runners are not test passes. Publish one acceptance row per platform/compiler configuration, with separate package, device-operator, API/framework, earlier-device regression and exception results.

### Items required before acceptance

- Named FEP/platform owners, final hardware scope and artifacts, including high-risk entry decisions.
- Required API/caller inventory; frozen operator/parameterized-case lists, references/tolerances and applicable model configurations.
- Final release dependency/image pins, specialization/CI denominators and actual acceptance reports.

This review checks the plan and implementation entry points; it does not provide GPU/NPU or model acceptance results.

## Related PRs

- Baseline: [FEP-0098](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0098-flagtree-multi-backend-architecture.md).
- [ ] New backends and device-generation support — Intellifusion [#1598](https://github.com/flagos-ai/FlagTree/pull/1598) and BW1100 CI [#1514](https://github.com/flagos-ai/FlagTree/pull/1514)/[#1597](https://github.com/flagos-ai/FlagTree/pull/1597) merged; remaining implementation and acceptance TBD.
- [ ] Required Triton 3.7 API compatibility — full inventory/implementation TBD; Ascend [#1507](https://github.com/flagos-ai/FlagTree/pull/1507) is an open compatibility fix to track.
- [ ] Remaining specialization and CI integration — includes open XPU Python [#1422](https://github.com/flagos-ai/FlagTree/pull/1422) and MThreads C++ [#985](https://github.com/flagos-ai/FlagTree/pull/985); final checklist and acceptance TBD.
- [ ] Platform dependency matrix and hardware/operator/framework acceptance — TBD.

Implementation paths reviewed at FlagTree `main` [`20e0d0880`](https://github.com/flagos-ai/FlagTree/tree/20e0d0880518c9c77e445a579446337cdcacf4d7), Intellifusion 3.8 [`b6775869b`](https://github.com/flagos-ai/FlagTree/tree/b6775869b99df358d7afbba3e15d4bf7afdfd1b0), and vLLM-Plugin-FL [`d6d8380`](https://github.com/flagos-ai/vllm-plugin-FL/tree/d6d83803980fb78d84dcc1b3bc5b915b1fddb237). Use actual release candidate revisions for acceptance and update changed paths/options accordingly.

# FEP-0168: FlagTree Multi-Platform Support and Triton API Compatibility

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

For FlagOS 2.3, extend [FlagTree](https://github.com/flagos-ai/FlagTree) to new backends and accelerator generations, complete the planned unified Python/C++ backend specialization, and prioritize the Triton 3.7 Python APIs required by [vLLM-Plugin-FL](https://github.com/flagos-ai/vllm-plugin-FL) for vLLM 0.32.0. Preserve existing Triton 3.6 interfaces so FlagGems operators do not need implementation changes for API compatibility.

## Motivation

Backend adaptations that directly modify shared code or duplicate the source tree make it harder to reuse common functionality and follow Triton upgrades. FlagTree needs a common specialization mechanism that keeps backend-specific implementations in backend directories while reusing shared code, supporting both new backend integration and device-generation upgrades. In parallel, vLLM-Plugin-FL's move to vLLM 0.32.0 requires identifying and providing the Triton Python APIs used by that stack while preserving existing 3.6 interfaces, so API differences do not force changes to FlagGems operator implementations.

### Goals

- **G1 — Add three backends:** Integrate Intellifusion, D-Robotics S600 and EVAS Intelligence. Each delivered backend must provide an installable FlagTree package that compiles and executes its supported Triton operators on the target device.
- **G2 — Support five new-generation chips:** Enable NVIDIA B200, Iluvatar BI300, T-Head 890, Hygon BW1100 and Huawei Ascend 950 through their vendor backends and matching toolchains, with each backend's supported operators compiling and executing on the corresponding delivered device.
- **G3 — Complete unified Python/C++ backend specialization:** Complete 100% of the planned migration items on `main` for `hcu`, `iluvatar`, `metax`, `mthreads`, `ppu`, `xpu`, `enflame`, `rpu`, `spacemit` and `sunrise`. Reuse shared code and keep backend-specific implementations in backend directories, preserving documented exceptions and existing operator behavior.
- **G4 — Provide Triton API compatibility for vLLM-Plugin-FL with vLLM 0.32.0:** Identify and implement the Triton 3.7 Python APIs used by this deployment while retaining existing 3.6 interfaces. The existing native Triton 3.6 operator cases on NVIDIA and supported FlagGems operators must continue to run without implementation changes for API compatibility.

### Non-Goals

Full upstream Triton 3.7 feature parity, migration of every vendor to a new 3.7 branch, model-serving support on backends with compiler/operator-only scope, and a universal performance-gain target.

## Proposal

### User scenarios

#### Use existing operators on an additional device (G1–G2)

When an operator developer needs to use existing Triton operators on an additional device, the first task is to determine which implementations can be reused and which inputs the target backend supports. The developer installs the matching FlagTree package and vendor SDK/driver, compiles and runs the operators within that scope, and checks their behavior against existing inputs and reference results. This establishes the usable operator scope for subsequent application integration. Either a new vendor backend or an additional chip supported by an existing backend can create this need.

#### Upgrade the serving framework while retaining existing operators (G4)

A framework integrator needs to upgrade a vLLM-Plugin-FL deployment that uses FlagGems to vLLM 0.32.0. The upgrade must satisfy the framework's Triton Python API dependencies, while some FlagTree backends remain based on Triton 3.6. The integrator wants to use a matching FlagTree version to complete the upgrade on a supported platform and continue serving supported model requests, without changing existing FlagGems operator implementations solely for API compatibility.

#### Incorporate shared compiler changes while retaining backend adaptations (G3)

When incorporating fixes or upgrades to shared code on `main`, a backend maintainer needs to retain the backend's Python and C++ adaptations. Direct edits to shared files or copies of the entire source tree intertwine those adaptations with shared changes. The maintainer wants to keep the differences in the backend directory and reuse shared code that is not overridden. Changes affecting an overridden component still require reviewing its backend implementation and updating it where necessary. The built and installed package should select the intended backend implementations and preserve existing operator behavior.

### Functional scope

#### G1–G2 — Backend integration and device enablement

- **G1 adds compiler and runtime support for each new backend:** connect device detection and target selection, Triton kernel compilation, and kernel loading/execution through the vendor runtime; integrate these components into an installable FlagTree package. Vendor SDKs and drivers provide the underlying device environment.
- **G2 extends an existing vendor backend to the listed device:** provide the device/compilation-target configuration and matching toolchain/runtime integration needed to compile and execute that backend's supported operators on the new device. Existing supported device generations remain in regression coverage.

| ID | Target platform | Integration path |
|---|---|---|
| G1.1 | Intellifusion / 云天励飞 | New compiler/runtime backend for `ifwa:100` on `triton_v3.8.x`. |
| G1.2 | D-Robotics S600 | Add compiler and runtime integration for S600. |
| G1.3 | EVAS Intelligence | Add compiler and runtime integration for EVAS Intelligence. |
| G2.1 | NVIDIA B200 | Extend the NVIDIA backend on `main` / Triton 3.6 to the target device. |
| G2.2 | Iluvatar BI300 | Enable the target device through the Iluvatar backend and matching vendor toolchain. |
| G2.3 | T-Head 890 | Enable the target device through the PPU backend and matching vendor toolchain. |
| G2.4 | Hygon BW1100 | Enable the target device through the HCU backend and matching vendor toolchain. |
| G2.5 | Huawei Ascend 950 | Enable the target device through the Ascend backend and matching Ascend toolchain. |

Each platform must define its supported operator list, shapes, dtypes and layouts. Model-serving scope depends on the framework support for that platform and configuration. Dependency combinations and pending decisions are described in Design Details.

#### G3 — Unified backend specialization

The migration scope is the planned Python/C++ items for the `main` backends listed in G3.

| ID | Function | Required behavior |
|---|---|---|
| G3.1 | Python specialization | Load backend-specific modules and function overrides through the shared specialization mechanism while reusing common Python code. Installed packages must select the intended backend implementations. |
| G3.2 | C++ specialization | Keep backend source overrides under `spec_cpp/lib`; select those overrides for the corresponding build targets and reuse the remaining shared sources. The resulting package must preserve the backend's existing operator behavior. Documented backend exceptions remain applicable. |

#### G4 — Framework API and operator compatibility

| ID | Function | Required behavior and boundary |
|---|---|---|
| G4.1 | Required Triton 3.7 APIs | Provide the Python symbols, signatures and runtime behavior used by vLLM-Plugin-FL with vLLM 0.32.0 on applicable FlagTree lines, while retaining existing 3.6 interfaces. The concrete API inventory must be identified from framework callers; full upstream 3.7 parity is outside scope. |
| G4.2 | Existing native Triton operators | Existing NVIDIA Triton 3.6 operator cases must compile and execute from unchanged source on FlagTree, preserving their computational behavior. Other backends cover their supported native examples. |
| G4.3 | FlagGems application calls | Within each backend's declared operator scope, existing FlagGems implementations must remain usable through its public PyTorch integration interfaces. Triton API compatibility must not require rewriting those operator implementations. |

## Design Details

### Implementation approach

- **G1–G2:** Connect each backend's compiler and runtime to FlagTree's build and packaging configuration. New device generations use their vendor backend with the corresponding SDK/toolchain. Device-specific changes and acceptance remain separate from the presence of a backend.
- **G3.1:** Use the existing [Python specialization mechanism](https://github.com/flagos-ai/FlagTree/blob/20e0d0880518c9c77e445a579446337cdcacf4d7/python/triton/_flagtree_spec.py) for backend-specific module paths and function overrides while reusing common code.
- **G3.2:** Use the existing [CMake specialization mechanism](https://github.com/flagos-ai/FlagTree/blob/20e0d0880518c9c77e445a579446337cdcacf4d7/cmake/FlagTreeBackendSpec.cmake) to select backend source overrides under `spec_cpp/lib`. Preserve documented backend exceptions and validate both build and execution after migration.
- **G4.1–G4.3:** Keep supported operator implementations unchanged. Identify the framework callers and Python API differences, then provide the required compatibility on the applicable FlagTree lines. Confirm signatures and runtime behavior as well as imports. The API inventory and per-platform version combinations remain TBD.

### Compatibility and dependencies

G4.1 adds the required Triton 3.7 interfaces to applicable existing FlagTree lines, including 3.6. It does not require every backend to move to a new 3.7 branch. G1.1 uses `triton_v3.8.x`; G2.1 uses the NVIDIA backend on `main` / Triton 3.6. Other platform configurations must name the compiler line and matching SDK/driver before acceptance.

Use [vLLM FEP-0140](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0140-vllm-multi-version-platform-compatibility.md) and [SGLang FEP-0141](https://github.com/flagos-ai/community/blob/main/fep/sig-framework/0141-sglang-multi-platform-upgrade-and-model-support.md) for framework configurations. FEP-0140 selects vLLM 0.32 as the main 2.3 release version. Compiler acceptance uses the same release dependencies as the target application; installing the framework must not replace the candidate compiler with another distribution providing `triton`.

### Upgrade and rollback

Upgrade through the documented wheel or application-image path and rerun the applicable operator and model workloads. Keep application and operator sources unchanged. When other dependencies must change, validate the whole deployment and report it as a full-stack upgrade. Roll back by restoring the previous working image and rerunning the same workload.

### Risks and mitigations

- S600, EVAS Intelligence and BI300 depend on unconfirmed vendor adaptation, SDKs or hardware. Confirm the deliverable scope before release acceptance; unavailable hardware leaves device acceptance pending.
- CModel execution, merged CI configuration and API imports provide partial evidence. Require physical-device results, actual test execution and framework/API invocation evidence for the corresponding support claims.

Final release packages, supported operator/API lists, dependency combinations and workload-specific acceptance limits remain TBD.

## Packaging

**Planned vendor scope:** vendors of the G1–G2 entries selected for delivery, plus existing supported backends.

**Format:** backend-specific Python wheels (`.whl`). The default distribution name is `flagtree`, with a build-time `FLAGTREE_WHEEL_NAME` override; the Python import namespace remains `triton`.

Build in the backend's documented environment with dependencies installed. Set `FLAGTREE_BACKEND` to its build selector; leave it unset for standard NVIDIA builds, following the [installation guide](https://github.com/flagos-ai/FlagTree#environment-setup):

```bash
python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist
```

## Test Plan

Use the agreed release dependencies and platform-specific operator/framework scope. Fix the hardware, software versions, inputs and reference checks for each configuration, and retain results. Unconfirmed configurations remain pending.

### User acceptance tests

#### T1 — Install FlagTree and run the first computation (G1–G3)

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

Then run `python3 -m pip check` and the applicable T2 operator example. Test editable installation separately where offered.

**Pass:** dependency checks succeed, the loaded compiler is the selected release after application dependencies are installed, the backend selects the intended device, and the operator's numerical assertions pass. Repeat in a fresh process. The documented installation must work without manual `site-packages` patches.

#### T2 — Run existing Triton operators on the target chip (G1–G2, G4.2)

On NVIDIA, run identical operator sources and inputs in separate upstream Triton 3.6 and candidate FlagTree environments on the same device. Start with the existing [fused-softmax example](https://github.com/flagos-ai/FlagTree/blob/20e0d0880518c9c77e445a579446337cdcacf4d7/python/tutorials/02-fused-softmax.py), which checks an irregular `(1823, 781)` FP32 input against PyTorch with `torch.allclose`. Set `FEP_TREE_ROOT` to the absolute path of the pinned source checkout:

```bash
python3 "$FEP_TREE_ROOT/python/tutorials/02-fused-softmax.py" --only_unit_test
```

For Intellifusion, configure the IFWA environment and run the existing [vector-add and masked load/store cases](https://github.com/flagos-ai/FlagTree/blob/b6775869b99df358d7afbba3e15d4bf7afdfd1b0/third_party/intellifusion/examples/test_vector_add.py) from the 3.8 checkout:

```bash
python3 third_party/intellifusion/ci/check_install.py --torch-ifwa
python3 -m pytest -q third_party/intellifusion/examples/test_vector_add.py
```

**Pass:** the unchanged operators compile and execute on the intended device, and their existing reference assertions pass. Intellifusion's cases check exact vector-add results and that masked stores preserve surrounding data; `check_install.py` alone checks installation only. Physical-device acceptance requires hardware runs, with CModel results recorded separately.

Extend these starting cases to the agreed native-operator inventory for each backend, including supported shapes, dtypes and layouts, reductions, matrix multiplication and attention. Repeat execution in the same process and a fresh process using the documented cache configuration. Do not change operator implementations or relax existing tolerances to pass compatibility testing. Final per-platform case lists remain TBD.

#### T3 — Run a PyTorch application through FlagGems (G4.3)

On configurations declaring FP32 softmax support, run the same application with the baseline and candidate compilers, keeping the FlagGems revision fixed. Use separate working directories to retain both logs. Use the public [`use_gems` interface](https://github.com/flagos-ai/FlagGems/blob/4d584c59fc5cff365473695663c7b0ca64e46868/docs/content/en/usage/selective.md) around ordinary PyTorch calls:

```python
import torch
import flag_gems
from flag_gems.testing import assert_close

torch.manual_seed(0)
host_inputs = [
    torch.randn(shape, dtype=torch.float32, device="cpu")
    for shape in [(1, 256), (4096, 256), (200, 2560, 3)]
]
references = [torch.softmax(x.to(torch.float64), dim=1) for x in host_inputs]
inputs = [x.to(flag_gems.device) for x in host_inputs]

with flag_gems.use_gems(
    include=["softmax"], record=True, path="./flaggems-softmax.log"
):
    outputs = [torch.softmax(x, dim=1) for x in inputs]

for x, output, reference in zip(inputs, outputs, references):
    assert output.device == x.device
    assert_close(output.cpu(), reference, torch.float32)
```

The shapes come from the existing [softmax tests](https://github.com/flagos-ai/FlagGems/blob/4d584c59fc5cff365473695663c7b0ca64e46868/tests/test_softmax.py); numerical checks reuse [FlagGems' dtype-specific tolerances](https://github.com/flagos-ai/FlagGems/blob/4d584c59fc5cff365473695663c7b0ca64e46868/src/flag_gems/testing/__init__.py). Compute CPU references before enabling FlagGems.

**Pass:** ordinary PyTorch calls produce the expected shape, dtype and values on the target device without application or operator changes between compiler versions. Confirm actual FlagGems invocation: the [generic softmax implementation](https://github.com/flagos-ai/FlagGems/blob/4d584c59fc5cff365473695663c7b0ca64e46868/src/flag_gems/ops/softmax.py) logs `GEMS SOFTMAX`; vendor implementations may use their own call markers. Use a device trace if call logging is unavailable. Registration alone is insufficient. Run the full supported operator suite as described below, beyond this application example.

#### T4 — Upgrade the framework and serve real requests (G4.1)

For supported vLLM platforms, use FEP-0140's vLLM 0.32 configuration and real Qwen3.6-27B and Qwen3.6-35B-A3B weights. Run the existing [adaptation gate cases](https://github.com/flagos-ai/vllm-plugin-FL/tree/d6d83803980fb78d84dcc1b3bc5b915b1fddb237/tools/adaptation-gate-cases) from the matching plugin checkout, adjusting TP and `MAX_MODEL_LEN` to the accepted device configuration:

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

| User task | Requests | Existing output checks |
|---|---|---|
| Ask for a detailed text response | 1 | Minimum response length and required terms. |
| Read text from an image | 1 | Expected words appear in the required order. |
| Submit concurrent text questions | 8 | Each response contains its expected answer terms. |
| Submit concurrent image questions | 8 | Expected terms for colors, shapes, counts and visible text, in the required order. |
| Submit text and image questions together | 8 | Each of four text and four image requests passes its checks. |

**Pass:** the FL plugin and candidate compiler are active; all 26 request results have `passed: true`, including the existing checks for empty, malformed or repetitive output. No API, JIT, device-launch or applicable graph-capture errors occur. These basic request checks must be supplemented by the framework's agreed task-accuracy datasets and tolerances; unconfirmed metrics remain TBD.

For each required Triton API, identify a framework caller and a request that exercises it. Add a focused compiled case for APIs not reached by these requests; successful imports or server startup alone do not establish compatibility. Where PyTorch Inductor is supported, compare the compiled workload with eager execution. SGLang uses FEP-0141's applicable cases.

#### T5 — Assess an upgrade and restore the previous environment (G1–G4)

Rerun applicable T1–T4 workflows on existing platforms, including supported earlier device generations. Compare the previous supported compiler with the candidate while keeping other dependencies, inputs and hardware fixed. Report comparisons requiring dependency changes as full-stack upgrades.

Measure first-use compilation and steady-state performance separately, with diagnostic operator logging disabled for performance runs. For supported model deployments, reuse FEP-0140/FEP-0141 performance, load and stability tests on the candidate image, including throughput, TTFT/TPOT and resource behavior. Restore the previous working image and repeat the same representative operator or model workload.

**Pass:** required correctness cases still pass, performance and stability meet the agreed workload-specific acceptance limits, and rollback restores the baseline workload's expected behavior. Investigate regressions before acceptance; limits not yet agreed remain TBD.

### Supporting tests (G3.1–G3.2, G4.2–G4.3)

For G3.1, use the [XPU specialization regression tests proposed in #1422](https://github.com/flagos-ai/FlagTree/blob/f115e60dd5bfc7572b762824e91000e85e909d67/python/test/packaging/test_xpu_specialization.py). From a checkout containing those changes, with pytest, setuptools and wheel available:

```bash
python3 -m pytest python/test/packaging/test_xpu_specialization.py -q
```

**Pass:** package discovery, staged wheel contents and backend-specific Python behavior pass their assertions. These host-only tests supplement the installed-package and device tests. For G3.2, check the build log's `SPEC: <relative source> -> <target>` entries and compilation commands against the required C++ overrides, then run the applicable T2/T3 workloads.

- Use the [FlagTree test action](https://github.com/flagos-ai/FlagTree/tree/20e0d0880518c9c77e445a579446337cdcacf4d7/.github/actions/run-flaggems-test) with the platform's required operator list and full parameter set, setting the action input `first-parameter-only: false`. Pin the same runner and operator-library revisions for baseline and candidate. Apply the matching `assets/gems/<tag>/conftest.py` override where provided; otherwise verify the checkout's collection/reporting support. FlagGems-vllm requires its separate `assets/gems-vllm/<tag>/conftest.py` and the action input `repo-kind: flaggems-vllm` (`--repo-kind flaggems-vllm` when invoking the runner directly).
- Every required case must execute and pass. Check raw results and case counts for failures, skips, missing cases, collection errors and timeouts; exclusions cannot remove required cases. Require `marks_collection_ok: true` and zero `failed`, `errors` and `not_found` for required cases. The runner can return zero with failures or label an all-skipped operator `Passed`.
- Use the [result comparator](https://github.com/flagos-ai/FlagTree/blob/20e0d0880518c9c77e445a579446337cdcacf4d7/.github/actions/compare-flaggems-test/scripts/compare_test_result.py) with `--exit-code` for baseline regressions, alongside the required-case checks. New backends still need complete required-case results without a historical baseline. The test runner's `--quick` and `--first-parameter-only` options are for smoke tests, not release acceptance.
- Verify each planned specialization item through its build and regression results. Skipped tests and unavailable hardware do not establish a pass.

### Release acceptance criteria

- Each delivered G1 backend and G2 device has a usable package and passing physical-device tests for its declared scope. G4.1 API/framework cases and G4.2–G4.3 operator cases pass in the release environment.
- G3.1–G3.2 meet 100% of the planned specialization checklist. Record completed items and documented exceptions, with passing build and regression results.
- Required upgrade/regression checks pass. Any change to the delivered scope is explicit; a pending platform, API or test is not recorded as completed support.

## Related PRs

Baseline: [FEP-0098](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0098-flagtree-multi-backend-architecture.md).

| Function | Implementation / related PRs | Acceptance |
|---|---|---|
| G1.1 | [#1598](https://github.com/flagos-ai/FlagTree/pull/1598), merged: Intellifusion 3.8 backend, CModel CI and wheel-delivery workflow. | T1/T2: wheel and physical-device results pending; FlagGems/framework scope TBD. |
| G1.2–G1.3 | Implementation PRs TBD. | T1/T2: backend, SDK, hardware and operator scope unconfirmed. |
| G2.1 | Existing NVIDIA 3.6 backend; B200-specific implementation PRs, if needed, TBD. | T1/T2: B200 package and device acceptance pending. |
| G2.2 | Vendor adaptation and implementation PRs TBD. | T1/T2: SDK, package and hardware acceptance pending. |
| G2.3 | Existing PPU backend and Qwen benchmark infrastructure; 890-specific PRs TBD. | T1/T2: exact SKU, SDK/driver and device acceptance pending. |
| G2.4 | [#1514](https://github.com/flagos-ai/FlagTree/pull/1514) and [#1597](https://github.com/flagos-ai/FlagTree/pull/1597), merged: BW1100 build, FlagGems and Qwen CI configurations. | T1–T4 where supported: release-environment acceptance pending. |
| G2.5 | [#1637](https://github.com/flagos-ai/FlagTree/pull/1637), merged: Ascend 3.6 backend port; 950-specific implementation scope TBD. | T1/T2: 950 toolchain, hardware and device acceptance pending. |
| G3.1 | [#1422](https://github.com/flagos-ai/FlagTree/pull/1422), open: XPU Python specialization. Remaining backend items TBD. | T1–T3/T5 where applicable and specialization checklist pending. |
| G3.2 | [#985](https://github.com/flagos-ai/FlagTree/pull/985), Draft: MThreads C++ specialization. Remaining backend items TBD. | T1–T3/T5 where applicable and specialization checklist pending. |
| G4.1 | Required API implementation PRs TBD. Related [#1507](https://github.com/flagos-ai/FlagTree/pull/1507) is open and restores `triton_key` on Ascend 3.5 only. | T4: required API inventory and caller coverage pending; #1507 does not establish 3.7 API coverage. |
| G4.2–G4.3 | Existing examples and FlagGems tests linked in T2/T3; additional compatibility-fix PRs TBD. | T2/T3/T5 and full operator regression pending for the agreed release configurations. |

Test infrastructure: [#1443](https://github.com/flagos-ai/FlagTree/pull/1443) and [#1647](https://github.com/flagos-ai/FlagTree/pull/1647), merged, provide the shared FlagGems CI assets and FlagGems-vllm test integration used by the supporting tests.

## Implementation History

- 2026-11-05: Initial proposal opened as [community PR #168](https://github.com/flagos-ai/community/pull/168).

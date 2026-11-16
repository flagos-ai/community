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

Use the agreed release dependencies and platform-specific operator/framework scope. Fix the hardware, software versions, inputs and reference checks for each configuration, and retain results. Unconfirmed configurations remain pending.

### T1 — Install FlagTree and run the first computation (G1, G3, G4)

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

### T2 — Run existing Triton operators on the target chip (G1, G2)

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

### T3 — Run a PyTorch application through FlagGems (G1, G2, G3)

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

**Pass:** ordinary PyTorch calls produce the expected shape, dtype and values on the target device without application or operator changes between compiler versions. Operator-call logs or a device trace must identify the invoked FlagGems kernels; registration alone is insufficient. Run the full supported operator suite as described below, beyond this application example.

### T4 — Upgrade the framework and serve real requests (G3)

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

### T5 — Assess an upgrade and restore the previous environment (G1–G4)

Rerun applicable T1–T4 workflows on existing platforms, including supported earlier device generations. Compare the previous supported compiler with the candidate while keeping other dependencies, inputs and hardware fixed. Report comparisons requiring dependency changes as full-stack upgrades.

Measure first-use compilation and steady-state performance separately, with diagnostic operator logging disabled for performance runs. For supported model deployments, reuse FEP-0140/FEP-0141 performance, load and stability tests on the candidate image, including throughput, TTFT/TPOT and resource behavior. Restore the previous working image and repeat the same representative operator or model workload.

**Pass:** required correctness cases still pass, performance and stability meet the agreed workload-specific acceptance limits, and rollback restores the baseline workload's expected behavior. Investigate regressions before acceptance; limits not yet agreed remain TBD.

### Supporting operator regression and CI checks (G2, G4)

- Use the [FlagTree test action](https://github.com/flagos-ai/FlagTree/tree/20e0d0880518c9c77e445a579446337cdcacf4d7/.github/actions/run-flaggems-test) with the platform's required operator list and full parameter set. Pin the same runner and operator-library revisions for baseline and candidate. Apply the matching `assets/gems/<tag>/conftest.py` override where provided; otherwise verify the checkout's collection/reporting support. FlagGems-vllm requires its separate `assets/gems-vllm/<tag>/conftest.py` and `--repo-kind flaggems-vllm`.
- Every required case must execute and pass. Check raw results and case counts for failures, skips, missing cases, collection errors and timeouts; exclusions cannot remove required cases. Require `marks_collection_ok: true` and zero `failed`, `errors` and `not_found` for required cases. The runner can return zero with failures or label an all-skipped operator `Passed`.
- Use the [result comparator](https://github.com/flagos-ai/FlagTree/blob/20e0d0880518c9c77e445a579446337cdcacf4d7/.github/actions/compare-flaggems-test/scripts/compare_test_result.py) with `--exit-code` for baseline regressions, alongside the required-case checks. New backends still need complete required-case results without a historical baseline. `--quick` and `--first-parameter-only` are smoke-test options, not release acceptance.
- Verify specialization items and count successful CI executions against G4's agreed checklists. Skipped jobs and unavailable hardware remain gaps, not passing coverage.

## Related PRs

- Baseline: [FEP-0098](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0098-flagtree-multi-backend-architecture.md).
- [ ] New backends and device-generation support — Intellifusion [#1598](https://github.com/flagos-ai/FlagTree/pull/1598) and BW1100 CI [#1514](https://github.com/flagos-ai/FlagTree/pull/1514)/[#1597](https://github.com/flagos-ai/FlagTree/pull/1597) merged; remaining implementation and acceptance TBD.
- [ ] Required Triton 3.7 API compatibility — full inventory/implementation TBD; Ascend [#1507](https://github.com/flagos-ai/FlagTree/pull/1507) is an open compatibility fix to track.
- [ ] Remaining specialization and CI integration — includes open XPU Python [#1422](https://github.com/flagos-ai/FlagTree/pull/1422) and MThreads C++ [#985](https://github.com/flagos-ai/FlagTree/pull/985); final checklist and acceptance TBD.
- [ ] Platform dependency matrix and hardware/operator/framework acceptance — TBD.

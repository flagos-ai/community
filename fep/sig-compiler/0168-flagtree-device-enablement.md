# FEP-0168: FlagTree New Backend and Accelerator Generation Support

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Add the planned new accelerator backends and hardware-generation support to [FlagTree](https://github.com/flagos-ai/FlagTree). Track target detection, toolchain compatibility, code generation and hardware validation independently for each platform, including explicit readiness for high-risk entries.

## Motivation

A new device needs a supported compilation target, correct code generation and reproducible runtime tests. Hardware availability and vendor SDK readiness differ by platform; these deliveries must be tracked separately from compiler compatibility and CI infrastructure for existing devices.

### Goals

- **G1:** Add DeepVision/Yuntian Lifei, D-Robotics S600 and EVAS Intelligence backends according to the platform matrix.
- **G2:** Upgrade support for NVIDIA B200, Iluvatar BI300, T-Head 890, Hygon BW1100 and Huawei Ascend 950.
- **G3:** Publish a build/runtime/dependency matrix and hardware correctness report for each accepted platform.

### Non-Goals

Full model-zoo or operator-library coverage, a universal performance target, and treating compilation-only tests as on-device acceptance.

## Design Details

| Platform | Work | Readiness |
|---|---|---|
| Yuntian Lifei / DeepVision | New backend | SDK/device model and test host: TBD |
| D-Robotics S600 | New backend | High risk; SDK and test host: TBD |
| EVAS Intelligence | New backend | High risk; device model, SDK and test host: TBD |
| NVIDIA B200 | Hardware-generation support | Toolchain and test host: TBD |
| Iluvatar BI300 | Hardware-generation support | High risk; SDK and test host: TBD |
| T-Head 890 | Hardware-generation support | Toolchain and test host: TBD |
| Hygon BW1100 | Hardware-generation support | Toolchain and test host: TBD |
| Huawei Ascend 950 | Hardware-generation support | CANN/toolchain and test host: TBD |

Each backend reuses the shared compiler and expresses its specialization at the supported extension points. Implement device identification, target features, code-generation hooks, runtime launch integration and the required compiler/linker configuration. For an existing backend's new generation, retain regression coverage on the earlier supported generation.

The platform manifest includes vendor/SKU, backend selector, Triton line, source tag, SDK/driver, Python/PyTorch, build command, test command and available CI host. Confirm hardware access before marking a row ready. Keep high-risk rows visible as planned; untested rows remain incomplete.

## Packaging

**Supported vendors:** the eight platform entries above.

**Wheel:** per-backend FlagTree artifacts; device-generation features may share a vendor wheel if the target detection/runtime contract supports it.

Build a backend-specific FlagTree wheel from the selected release tag, using its documented SDK/LLVM/Python environment and `FLAGTREE_BACKEND` selector where required:

```bash
python3 -m pip wheel . --no-deps --no-build-isolation --wheel-dir dist
```

Record the source tag, Triton line, Python ABI, toolkit versions and wheel checksum. Release tag and dependency pins: TBD.

## Test Plan

### G1–G3: build, load and hardware execution

In each platform's documented environment, build the wheel and verify the installed modules:

```bash
python3 - <<'PYTEST'
from importlib.metadata import version
import triton
print(version('flagtree'))
print(triton.__version__)
print(triton.__file__)
PYTEST
```

Expected: the selected release package imports and points to the intended backend installation. Then run the backend's supported unit/tutorial suites and a fixed representative FlagGems correctness list. Exact per-platform commands and lists: TBD.

| Check | Expected result |
|---|---|
| Target identification | Requested SKU and architecture features selected correctly |
| Code generation | Representative elementwise, reduction and matrix operations compile |
| Execution | Actual-device outputs meet the reference tolerances, including masked/tail cases |
| Compatibility | Earlier hardware generation's agreed regressions remain passing |
| Reproducibility | Source tag, wheel, SDK/driver, commands and raw results recorded per platform |

Measure representative compile time, kernel latency and memory use for comparison with the vendor/current implementation; no platform-wide speedup threshold is specified. Required hardware unavailable: status TBD, not passed. No supported-device claim until the corresponding row completes validation.

## Related PRs

- Baseline architecture: [FEP-0098](https://github.com/flagos-ai/community/blob/main/fep/sig-compiler/0098-flagtree-multi-backend-architecture.md).
- [ ] New backend integrations — TBD.
- [ ] Existing backend generation upgrades — TBD.
- [ ] Per-platform build and hardware-validation evidence — TBD.

## Implementation History

- 2026-11-05: Initial FlagOS 2.3 proposal.

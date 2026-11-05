# FEP-0170: FlagPrism v0.2 Multi-Backend Debugging and Profiling

**Status:** `Provisional`

**Created:** 2026-11-05

**Owner:** TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.3

## Summary

Extend FlagTree's FlagPrism debugging and profiling tools to Enflame, MetaX, Kunlunxin, T-Head and Hygon for v0.2. Provide source/IR-correlated debugging, profiling reports and machine-readable execution data while retaining a core-only FlagTree build.

Repository: [FlagTree](https://github.com/flagos-ai/FlagTree). Baseline integration: [PR #916](https://github.com/flagos-ai/FlagTree/pull/916).

## Motivation

Cross-chip kernel development needs a consistent way to connect source and IR operations to runtime values, memory behavior and execution cost. The tool should preserve these common semantics while exposing hardware-specific counters only where supported.

### Goals

- **G1:** Deliver the v0.2 capability checklist on the five named backends, distinguishing completed v0.1 support from new work.
- **G2:** Preserve source/operation IDs and collect numerical/memory summaries, optional full values, execution context and timing through the current FlagPrism interfaces.
- **G3:** Build FlagTree with FlagPrism enabled or disabled, preserving ordinary kernel execution in both configurations.
- **G4:** Provide usage documentation and example outputs for the supported debugging/profiling workflows. AI-facing data requirements: TBD.

### Non-Goals

Replacing vendor profiling tools, identical hardware counters on every chip and mandatory instrumentation in a core-only compiler build.

## Design Details

### Interfaces and instrumentation

Use the current public APIs:

```python
import flagtree.debugger as debugger
import flagtree.profiler as profiler
```

The existing integration collects operation-level summaries and optional full values. Extend backend instrumentation and launch adapters while preserving ordinary, uninstrumented kernel execution. The v0.2 per-backend capability checklist remains TBD.

Profiler reports expose execution scopes, timing and available vendor metrics. Document which fields each backend can collect and distinguish host timing from device measurements.

### Backend matrix

| Backend | v0.2 work | Current evidence |
|---|---|---|
| Enflame | Complete and validate the capability checklist | v0.1 roadmap already lists support; v0.2 delta TBD |
| MetaX | Build registration, instrumented launch and report validation | Minimal integration in review: #1496 |
| Kunlunxin | Backend collection, profiling adapter and report validation | Implementation PR TBD |
| T-Head | Backend collection, profiling adapter and report validation | Implementation PR TBD |
| Hygon | Backend collection, profiling adapter and report validation | Implementation PR TBD |

For each backend, freeze the device/SDK and mark each checklist entry supported, unavailable or pending: summary collection, full-value collection, source/IR mapping, timing, hardware counters and export. A pending mandatory entry prevents that backend's acceptance. Counter lists and mandatory per-backend subset: TBD.

### Reports and documentation

Debugger exports numerical/memory summaries, operation logs and optional full-value artifacts. Profiler exports `profile.hatchet`, `profile.timeline.json`, `profile.meta.json` and `profile.vendor.json` on paths supporting these formats. Retain kernel/source identifiers, device identity, collection options, timing units and metric availability. AI-facing schema and consumer validation requirements: TBD.

The implementation extends the optional FlagPrism component. The older separate-wheel/API description in FEP-0068 is historical; this release follows the current build and public module interfaces.

## Packaging

**Supported vendors:** the five-backend target matrix plus the retained v0.1 regression matrix.

**Wheel:** FlagPrism integration is built into the corresponding FlagTree wheel when enabled. Use separate clean build trees for the two variants:

```bash
TRITON_BUILD_FLAGPRISM=ON python3 -m pip wheel . \
  --no-deps --no-build-isolation --wheel-dir dist/flagprism
```

```bash
TRITON_BUILD_FLAGPRISM=OFF python3 -m pip wheel . \
  --no-deps --no-build-isolation --wheel-dir dist/core
```

Pin the compatible source, backend SDK, Python ABI and LLVM/MLIR versions. FlagPrism's component revision and per-backend dependency pins: TBD. Native extensions must match the selected FlagTree ABI.

## Test Plan

### G1–G3: integration regression

Run the existing integration tests from the matching FlagTree checkout:

```bash
python3 -m pytest -q python/test/unit/test_flagprism.py
```

In the enabled build:

```bash
python3 - <<'PYTEST'
from importlib.metadata import version
import flagtree.debugger as debugger
import flagtree.profiler as profiler
print(version('flagtree'))
print(debugger.__file__)
print(profiler.__file__)
PYTEST
```

Expected: integration tests pass; public modules resolve from the intended package. In both enabled and core-only environments, compile/run the same uninstrumented reference kernel and verify identical output.

### G1–G2: real-device collection

Use the existing `abs` and `softmax` workload pattern at summary/full-value levels, plus `tiny_mlp` for profiling. Run on each target backend with collection off and on. Per-backend example commands: TBD.

| Check | Expected result |
|---|---|
| Numerical preservation | Instrumented/uninstrumented results match the reference tolerance |
| Debugger records | Scope/operation IDs map to source/IR; summaries/full-value records match sampled tensors |
| Profiler records | Session scopes, kernel events and timing units are consistent; missing vendor metrics are explicit |
| Lifecycle | Repeated sessions and failed-kernel cleanup restore hooks and release buffers |
| Buffer configuration | Different capacities select distinct instrumentation/cache configurations; overflow is detected |

Retain the established Ascend regression example and the agreed v0.1 device matrix. MetaX build/launch registration alone does not complete real-device collection acceptance.

### G4: documentation and report validation

Follow the published instructions to run a debugging example and a profiling example on each supported backend. Check that the documented output files can be read and match the example's operation identifiers and timing units. Document the supported devices, dependencies, collection limits and how to interpret the reports. Example commands and the AI-facing data requirements: TBD.

Measure instrumentation overhead against the same uninstrumented workload; overhead threshold: TBD.

## Related PRs

- [x] [FlagTree #916](https://github.com/flagos-ai/FlagTree/pull/916) — Ascend FlagPrism integration and build/API baseline.
- [ ] [FlagTree #1496](https://github.com/flagos-ai/FlagTree/pull/1496) — MetaX minimal integration.
- [ ] Remaining backend adapters and capability checklist — TBD.
- [ ] v0.2 user documentation, examples and release-validation evidence — TBD.

# FEP-0100: KernelGen Capability Building and Optimization Exploration for FlagOS 2.2

**Status:** `Provisional`

**Updated:** 2026-09-24

**Created:** 2026-08-01

**Owner:** Unassigned

**SIG:** sig-kernelgen

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| kernelgen | [`2.2.0-rc2` @ `1e3262c2e53e`](https://github.com/flagos-ai/KernelGen/tree/1e3262c2e53ec5cdeec14df8c74691f6adde6b46) | [`v2.2.0-rc2.post1` @ `1e3262c2e53e`](https://github.com/flagos-ai/KernelGen/tree/1e3262c2e53ec5cdeec14df8c74691f6adde6b46) |
| kernelgenbench | [`0.2.0-rc2` @ `e3cad63b93af`](https://github.com/flagos-ai/KernelGenBench/tree/e3cad63b93af155ddaad05795fa39289f89284eb) | [`v0.2.0-rc2.post1` @ `e3cad63b93af`](https://github.com/flagos-ai/KernelGenBench/tree/e3cad63b93af155ddaad05795fa39289f89284eb) |

## Summary

Extend KernelGen with multi-chip generation services, coverage reporting and
optimization prototypes. The RC2 snapshot contains existing documentation,
skills, search maintenance and license updates. It has no corresponding
release implementation or linked implementation PR for the seven goals below.

## Goals and Completion

| Goal | Required deliverable | RC2 status |
|---|---|---|
| G1: Core refactor | Generation-core changes and a chip/tool/knowledge onboarding contract | No matching implementation |
| G2: FlagOS-Coder v1 | A 32B model for operator generation and tuning on at least five chips | No versioned model artifact or per-chip results |
| G3: Operator coverage map | Reproducible operator/chip/status data and published view | No map generator or dataset |
| G4: Operator agent and leaderboard | Generation/optimization workflow and comparable multi-chip rankings | No implementation or ranking artifact |
| G5: Workbuddy operator expert | Defined operator-expert integration and input/output contract | Scope and acceptance undefined |
| G6: vLLM optimization prototype | KernelGen invocation in a measurable end-to-end inference workflow | No prototype or benchmark result |
| G7: Compiler optimization agent | Defined compiler transformations integrated with kernel optimization | No prototype or transformation contract |

## Dependencies

The [Knowledge Hub](0093-kernelgen-knowledge-and-tool-hub.md) remains
provisional. The planned 301 generated operators in
[FEP-0099](../sig-operator/0099-operator-library-flagos-2.2.md) require their
own inventory and cannot establish completion of these tools.

KernelGenBench has a separate RC2 artifact, but its availability does not
provide the G4 leaderboard or the per-chip results for G2. Compiler integration
must identify which interfaces and transformations it uses from
[FEP-0096](../sig-compiler/0096-flagtree-tle-megakernel-and-distributed.md) and
[FEP-0097](../sig-compiler/0097-flagtree-compiler-optimization.md).

## Delivery and Acceptance

Existing KernelGen web, MCP and skill interfaces do not identify a release
artifact for these new capabilities. Each goal needs its own versioned
delivery and executable acceptance:

- G1: onboard a chip using the documented contract and reproduce generation
  and testing from its environment description.
- G2: publish the model revision, license, invocation and evaluation set;
  report correctness and tuning results on at least five named chips.
- G3: generate the map from versioned data with stable operator identifiers
  and links to test results.
- G4: reproduce an operator run and regenerate rankings from raw correctness
  and timing records using a defined metric.
- G5: define supported requests, output contracts and a repeatable evaluation.
- G6: verify generated-kernel dispatch in a fixed vLLM workload, preserve
  model correctness and measure end-to-end performance.
- G7: identify the compiler changes and compare correctness and performance
  with an unchanged compiler baseline.

Implementation scope, target-chip assignments, package/model distribution
and quantitative acceptance thresholds remain open.

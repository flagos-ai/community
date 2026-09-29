# FEP-0100: KernelGen Generation Tools and Optimization Workflows

**Status:** `Deferred`

**Updated:** 2026-09-24

**Created:** 2026-08-01

**Owner:** Unassigned

**SIG:** sig-kernelgen

**Target Version:** FlagOS 2.3

## FlagOS 2.2 RC2 Baseline

| Module | Branch revision | Manifest tag |
|---|---|---|
| kernelgen | [`2.2.0-rc2` @ `1e3262c2e53e`](https://github.com/flagos-ai/KernelGen/tree/1e3262c2e53ec5cdeec14df8c74691f6adde6b46) | [`v2.2.0-rc2.post1` @ `1e3262c2e53e`](https://github.com/flagos-ai/KernelGen/tree/1e3262c2e53ec5cdeec14df8c74691f6adde6b46) |
| kernelgenbench | [`0.2.0-rc2` @ `e3cad63b93af`](https://github.com/flagos-ai/KernelGenBench/tree/e3cad63b93af155ddaad05795fa39289f89284eb) | [`v0.2.0-rc2.post1` @ `e3cad63b93af`](https://github.com/flagos-ai/KernelGenBench/tree/e3cad63b93af155ddaad05795fa39289f89284eb) |

## Summary

Deliver versioned KernelGen generation tools, model assets, coverage
reporting and optimization workflows for FlagOS 2.3.

## Deliverables

| Capability | Deliverable |
|---|---|
| Core refactor | Generation core and chip/tool/knowledge onboarding contract |
| FlagOS-Coder v1 | Versioned 32B model and generation/tuning results on at least five chips |
| Operator map | Reproducible operator/chip/status dataset and published view |
| Operator agent and leaderboard | Executable workflow and rankings from correctness/timing records |
| Workbuddy integration | Defined request/output contract and evaluation cases |
| vLLM optimization | Generated-kernel integration and end-to-end benchmark |
| Compiler optimization agent | Explicit transformations and correctness/performance comparison |

## Dependencies

The [Knowledge and Tool Hub](0093-kernelgen-knowledge-and-tool-hub.md)
provides the resource registry. KernelGenBench supplies benchmark tooling;
model artifacts, generated operators and rankings retain their own versions.

## Service Baseline

[Service QA](https://jwolpxeehx.feishu.cn/docx/ZLthdWsWqoniLVxIScVcktEinVb)
tested generation, autotuning and TLE execution on nine platforms and four
operator families. NVIDIA, MetaX, Enflame, Iluvatar, Ascend and Hygon passed
all three stages: 24 of 36 platform/operator combinations. MUSA autotuning
failed; Kunlunxin and AMD had device/environment failures. Rows with zero
performance tests establish workflow execution only.

## Acceptance

Each capability supplies a source/model revision, executable entry point,
test dataset and result artifact. Onboarding must reproduce generation and
testing from a documented environment. Coverage maps and rankings must be
regenerable from versioned data. The two optimization workflows must preserve
numerical correctness and compare performance against a fixed baseline.

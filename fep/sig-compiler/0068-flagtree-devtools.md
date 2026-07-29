# FEP-0068: FlagTree DevTools — Optional Debugging and Profiling Components

**Status:** `Provisional`

**Created:** 2026-07-24

**Owner:** @TBD

**SIG:** sig-compiler

**Target Version:** FlagOS 2.2

---

## Summary

FlagTree DevTools provides debugging and performance-analysis capabilities for Triton kernels compiled by FlagTree. It includes FlagTree Debugger, which correlates Triton source and compiler IR with runtime values and memory access information, and FlagTree Profiler, which records execution context, timing, and hardware performance metrics. Together, these tools provide a consistent workflow for locating correctness issues and performance bottlenecks across supported accelerator backends.

Repository: TBD

## Motivation

Developing Triton kernels across different AI accelerators requires a consistent way to diagnose correctness and performance problems. Existing workflows often rely on intrusive kernel modifications or vendor-specific tools and do not clearly connect Python context, Triton source, compiler IR, runtime values, memory accesses, and performance metrics. FlagTree DevTools provides a unified debugging and profiling layer for supported FlagTree backends, helping developers locate incorrect results and performance bottlenecks without maintaining separate workflows for each accelerator.

### Goals

- Provide user-friendly debugging and profiling workflows through stable Python APIs and command-line tools.
- Collect operation-level execution information, including intermediate values, numerical summaries, memory access behavior, execution time, and available hardware performance metrics.
- Correlate Triton source and compiler IR with runtime values, memory accesses, and performance data.
- Provide consistent debugging and profiling interfaces across accelerator backends, with an extensible architecture for adding new backends quickly.

### Non-Goals

- Replacing vendor profilers such as Nsight Systems, CUPTI, ROC-tracer, or CANN profiling services.
- Making Debugger or Profiler mandatory dependencies of the FlagTree core wheel.
- Treating the internal `flagtree_debugger` and `flagtree_profiler` packages as stable public APIs.
- Guaranteeing that every diagnostic backend and metric is available on every accelerator.
- Renaming the existing `flagtree-debugger`, `flagtree-profiler`, `triton.debugger`, or `triton.profiler` user interfaces as part of this FEP.

## Proposal

With FlagTree Debugger, users activate debugging through `triton.debugger` and mark regions of a Triton kernel for collection. Running the kernel produces reports that correlate Triton statements and compiler IR operations with intermediate values, numerical summaries, and memory access information, helping users locate correctness issues without manually adding temporary stores or print operations.

With FlagTree Profiler, users profile a function or code region through `triton.profiler` or the `proton` command-line tool. The profiler records execution context, kernel timing, and available hardware or intra-kernel metrics, and presents the results through generated profiles and `proton-viewer`. Both tools provide consistent user interfaces across supported FlagTree backends.

## Design Details

- **Debugger**: compiler passes instrument selected Triton regions and attach source and IR metadata to operations. At runtime, the generated kernel writes debugging records to a device buffer; the host runtime decodes these records and generates statement-level and operation-level reports.
- **Profiler**: profiling sessions track Python or user-defined scopes and kernel launches. Backend adapters collect timing and hardware data, while compiler instrumentation can collect intra-kernel metrics. The collected data is exported as trace or tree profiles for analysis.
- **FlagTree integration**: FlagTree provides the `triton.debugger` and `triton.profiler` facades together with optional-component registration and compiler/runtime hooks. FlagTree DevTools supplies the component implementations and backend adapters, allowing new backends to reuse the public interfaces while implementing their own collection mechanisms.

## Packaging

FlagTree Debugger and FlagTree Profiler are distributed as the optional `flagtree-debugger` and `flagtree-profiler` wheels. Users install either wheel on top of a compatible FlagTree release according to their debugging or profiling needs.

The two wheels are built independently from the corresponding source directories in `FlagTree_DevTools`. FlagTree must provide the public facade modules and compiler/runtime registration hooks used by these wheels, and native extensions must be built against the matching FlagTree LLVM/MLIR and `libtriton` ABI. The initial release requires Python 3.10 or later and `flagtree>=0.6,<0.7`, together with the runtime required by the selected accelerator backend.

## Test Plan

Testing is performed in the backend-specific build and hardware environments used by the matching FlagTree release. It covers the following dimensions:

- **Installation and integration**: verify that both wheels can be installed against a compatible FlagTree package and that their public Python and command-line interfaces are available.
- **Debugger correctness**: verify compiler instrumentation, runtime record collection, source/IR correlation, numerical summaries, memory access information, and report generation without changing kernel results.
- **Profiler correctness**: verify profiling session lifecycle, execution-context tracking, timing and hardware metric collection, profile generation, and result visualization.
- **Multi-backend compatibility**: run representative debugging and profiling workloads on every declared backend and verify that the public interfaces and output semantics remain consistent.
- **Optional-component isolation**: verify that FlagTree compilation and execution continue to work when either or both DevTools wheels are not installed.

## Related PRs

None yet.

## Implementation History

- 2026-07-24: Initial provisional FEP drafted.

# FEP-0082: FlagTree CPU Backend Upgrade to Triton 3.7 (Arm64)

**Status:** `Implementable`

**Created:** 2026-07-29

**Owner:** @kevinzs2048

**SIG:** sig-edge

**Target Version:** FlagOS 2.2

---

## Summary

Move the Linux Arm64 CPU backend to Triton `3.7.2` at
[`flagtree-cpu/triton_v3.7.x`](https://github.com/flagos-ai/flagtree-cpu/tree/triton_v3.7.x),
commit `2c35990a30e96665f8f9b5e158562288b4011048`. The package imports as `triton`;
`TRITON_CPU_BACKEND=1` selects its CPU backend. Enable and validate it through
[one script entry](scripts/flagtree-cpu37/run.sh) in its own virtual environment.

## Motivation

Triton frontend, MLIR/LLVM, launcher and cache interfaces changed from the earlier
3.3/3.6 CPU lines. Acceptance needs a pinned native build, real CPU JIT execution and
a downstream numerical test, beyond successful package import.

### Goals

- Build and import the pinned Triton 3.7.2 Arm64 CPU tree.
- Verify the declared LLVM/SLEEF and CPU target.
- Execute a real Triton kernel and record empty-cache/cached latency.
- Compare the FlagGems W4A8 operator with its PyTorch reference.

### Non-Goals

- GPU/NPU, x86_64, macOS or Windows acceptance.
- Adding model integration or an accelerated ARM W8A8 operator.
- Cache/binary compatibility with the earlier Triton lines.

## Proposal

The branch carries CPU target discovery, runtime, TritonCPU lowering and Arm support
onto the 3.7 line. Use its declared toolchain and initialized submodules. Keep earlier
compiler caches separate; do not install the public GPU-only Triton wheel over this tree.

## Design Details

| Source | Fixed revision |
|---|---|
| FlagTree CPU | `2c35990a30e96665f8f9b5e158562288b4011048` |
| LLVM (`cmake/llvm-hash.txt`) | `87717bf9f81f7b29466c5d9a30a3453bdfc93941` |
| SLEEF submodule | `93f04d869471ce4d007abaebb8c6a7bc62749f61` |
| [FlagGems #5904](https://github.com/flagos-ai/FlagGems/pull/5904) | `1fda4b11ae528c02ae5187cda551af4a61a514c5` |

This tree contains ARM I8MM/dot lowering and CPU `round`/`rint` libdevice support.
The earlier `77433cf...` checkout failed six of seven W4A8 tests on CIX P1 and is
not the acceptance revision. Initializing SLEEF is required for CMake configuration.

## Packaging

Reference: Debian 13 `aarch64`, 32 GiB CIX P1, Python 3.11 and PyTorch `2.11.0+cpu`.
`setup` installs system dependencies with sudo, fetches exact sources, initializes
submodules, uses uv `0.8.24` and builds with four jobs. Reserve about 8 GiB for the LLVM
cache plus build trees. Allow GitHub, PyPI (or a configured mirror), PyTorch's wheel index,
`oaitriton.blob.core.windows.net` and `developer.download.nvidia.com`; the CPU build
also fetches auxiliary NVIDIA tools. Retry with the same work directory/build cache.
Use the test host's working proxy/package-index configuration for the setup account.

**The scripted setup requires Debian 13; Debian 12 is not covered by this procedure.**
Have Git available before checkout. Setup uses sudo for a regular login or apt directly for root.
Setup installs host diagnostics before using them on minimal systems. Budget at least
25 GiB free for this independent environment, or 60 GiB for both PRs and model files.

### Enable and test

Run these commands in order from this PR's checkout:

```bash
git clone --single-branch --branch flagtree-cpu-3.7 https://github.com/kevinzs2048/community.git community-flagtree
cd community-flagtree
RUN=fep/sig-edge/scripts/flagtree-cpu37/run.sh
bash "$RUN" setup
bash "$RUN" test
```

The default `WORK_DIR` is `$HOME/flagtree-cpu-3.7-test`; export it once to change the
location. `BUILD_JOBS` defaults to 4. `SKIP_SYSTEM_PACKAGES=1` skips apt installation
when prerequisites are present. This environment is independent of FEP-0083 and
does not require that PR's scripts or vLLM. Upstream sources must have no tracked edits.
Paths are derived from the current account/script location; relative overrides are
resolved before changing directory. Choose a `WORK_DIR` without whitespace or semicolons.
Keep the full `scripts/flagtree-cpu37` directory when distributing the scripts.
Each PR needs its own `WORK_DIR`; when switching PRs, update a custom value as well.

## Test Plan

`test` checks source/toolchain pins and runs the repository-required incremental `make`,
then performs all checks below. The real JIT kernel lives in a Python file so Triton
can inspect its source. Numerical tests use the FlagGems install in this same environment.

| Check | Required result |
|---|---|
| Import and target | Arm64, Triton `3.7.2`, source import path, target `cpu` |
| Empty-cache vector add | Output matches PyTorch; cold JIT/run and cached time printed |
| FlagGems W4A8-G128 | **7 passed, 0 skipped**, compared with PyTorch |

Keep `$WORK_DIR/logs/setup.log`, `test.log`, package versions and pytest JUnit XML.
The scripts stop on failure, wrong revisions or skipped numerical tests.
Only the seven FlagGems numerical cases overlap with community PR #82. This PR's
CPU-target and empty-cache vector checks are compiler acceptance; model inference
and warm TTFT/TPS are tested through PR #82. Run shared cases in each environment.
The script entries were rerun on 2026-09-17: incremental setup passed; empty-cache
vector add 1.621 s, cached execution below displayed 0.001 s; FlagGems 7/7 in 3.39 s.
Relative-path overrides and delivery of the complete script folder without a Git
checkout were also tested. Minimal Debian 13 system-package/uv/Python bootstrap
passed in the earlier round; this compiler rerun reused its native build and used
a new kernel cache.
The 128-element vector-add example does not alter vLLM's BLOCK_SIZE.

### Model-level limitation

**Passing the compiler smoke does not establish acceptable model cold-start latency.**
Unmodified vLLM MiniCPM5 empty-cache requests previously took 915.78 s (W4A8) and
931.6 s (W8A8) on CIX P1 because wide Triton bookkeeping/sampling launches compile
slowly on CPU. Model inference and persistent-cache prewarming are in
[FEP-0083](https://github.com/flagos-ai/community/pull/82). No vLLM launch-size patch
is required by its enable procedure. Keep matching compiler/runtime identity and
fixed cache paths; new hardware or request specializations can compile again.
Installation, model loading, cold JIT, warm throughput and quality need separate records.

## Related PRs

- [FlagGems #5904](https://github.com/flagos-ai/FlagGems/pull/5904) — downstream ARM numerical suite.
- [vllm-plugin-FL #433](https://github.com/flagos-ai/vllm-plugin-FL/pull/433) — downstream CPU integration.
- [Community #82](https://github.com/flagos-ai/community/pull/82) — model environment and tests.

## Implementation History

- 2026-07-29: Initial migration proposal.
- 2026-09-04/15/16: Identified and pinned the passing source/toolchain; verified CPU
  JIT and FlagGems numerical tests, and documented model-level cold-JIT limitations.
- 2026-09-16: Moved independent setup/compiler/operator checks into scripts and
  reduced the document to two ordered execution commands and acceptance results.
- 2026-09-17: Reran setup/compiler/numerical checks and standalone delivery; fixed
  relative-path overrides.

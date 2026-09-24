# FEP-0082: FlagTree CPU Backend Upgrade to Triton 3.7 (Arm64)

**Status:** `Implemented`

**Updated:** 2026-09-24

**Created:** 2026-07-29

**Owner:** @kevinzs2048

**SIG:** sig-edge

**Target Version:** FlagOS 2.2

## Summary

Build the Linux Arm64 CPU backend on Triton 3.7.2 and validate CPU JIT and
FlagGems W4A8 numerics. The pinned implementation passed the recorded CIX P1
tests. The compiler still has no RC2 branch or entry in the FlagOS 2.2
release manifest.

## Source

| Component | Fixed revision |
|---|---|
| [FlagTree CPU `triton_v3.7.x`](https://github.com/flagos-ai/flagtree-cpu/tree/2c35990a30e96665f8f9b5e158562288b4011048) | `2c35990a30e96665f8f9b5e158562288b4011048` |
| LLVM | `87717bf9f81f7b29466c5d9a30a3453bdfc93941` |
| SLEEF | `93f04d869471ce4d007abaebb8c6a7bc62749f61` |
| FlagGems numerical dependency | `1fda4b11ae528c02ae5187cda551af4a61a514c5` |

The CPU implementation is dated 2026-09-04. FlagGems #5904 is now included
in the FlagGems RC2 branch. That downstream inclusion does not provide a
release artifact for the CPU compiler.

## Design

The compiler imports as `triton`; `TRITON_CPU_BACKEND=1` selects the CPU
backend. The branch provides CPU target discovery, runtime, TritonCPU
lowering, Arm I8MM/dot lowering and CPU `round`/`rint` support.

Use the declared LLVM and initialized SLEEF submodule. Compiler caches and
environments are independent of the earlier Triton lines and of the model
environment in [FEP-0083](0083-vllm_plugin_in_support_arm_CPU.md).

## Build and Test

The reference host is CIX P1 with 32 GiB RAM, Debian 13 `aarch64`, Python
3.11 and PyTorch `2.11.0+cpu`. The scripted procedure requires Debian 13,
network access to the pinned source/package dependencies, and approximately
25 GiB of free space. Setup uses apt through root or sudo, uv `0.8.24` and
four build jobs by default.

From a community repository checkout:

```bash
bash fep/sig-edge/scripts/flagtree-cpu37/run.sh setup
bash fep/sig-edge/scripts/flagtree-cpu37/run.sh test
```

The [script](scripts/flagtree-cpu37/run.sh) defaults to
`WORK_DIR=$HOME/flagtree-cpu-3.7-test`. `BUILD_JOBS` controls build parallelism;
`SKIP_SYSTEM_PACKAGES=1` skips apt when prerequisites are installed. Preserve
the complete script directory and use a separate work directory without
whitespace or semicolons. Logs and JUnit output are under `$WORK_DIR/logs`.

| Check | Required result | Recorded result, 2026-09-17 |
|---|---|---|
| Import and target | Arm64, Triton 3.7.2, target `cpu`, expected source path | Passed |
| Empty-cache vector add | Matches PyTorch; cold and cached timing recorded | Cold 1.621 s; cached below displayed 0.001 s |
| FlagGems W4A8-G128 | Seven tests pass without skips | 7/7 passed in 3.39 s |

The rerun reused the native compiler build and used a fresh kernel cache.
The script verifies source/toolchain pins and runs the required incremental
build before testing.

## Release Packaging and Limits

Model startup, quality and throughput are covered by FEP-0083. Its roughly fifteen-minute
empty-cache model JIT is not represented by the small vector-add timing.
GPU/NPU, x86_64, macOS and Windows are outside this Arm64 acceptance scope.

## Related PRs

- [x] [FlagGems#5904](https://github.com/flagos-ai/FlagGems/pull/5904) — Arm W4A8 operator and numerical tests; included in FlagGems RC2. Merged.
- [x] [vllm-plugin-FL#433](https://github.com/flagos-ai/vllm-plugin-FL/pull/433) — Downstream Arm64 integration; included in the 0.24.0 RC2 line. Merged.

## Deferred to FlagOS 2.3

CPU compiler release-artifact assignment, manifest integration and packaged
dependency regression.

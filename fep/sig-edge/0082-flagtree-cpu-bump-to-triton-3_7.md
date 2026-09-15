# FEP-0082: FlagTree CPU Backend Upgrade to Triton 3.7 (Arm64)

**Status:** `Implementable`

**Created:** 2026-07-29

**Owner:** @kevinzs2048

**SIG:** sig-edge

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP moves the [`flagtree-cpu`](https://github.com/flagos-ai/flagtree-cpu)
Arm64 CPU backend to Triton 3.7.2. The test revision is
[`triton_v3.7.x`](https://github.com/flagos-ai/flagtree-cpu/tree/triton_v3.7.x) at
`2c35990a30e96665f8f9b5e158562288b4011048`. Its Python package imports as `triton`,
and `TRITON_CPU_BACKEND=1` selects the CPU backend. Acceptance is on Linux `aarch64`.

This is a compiler migration. The branch carries the CPU backend, TritonCPU lowering, runtime,
and Arm64 support onto the 3.7 line. It does not itself add a W8A8 model kernel. The downstream
vLLM environment in [FEP-0083](https://github.com/flagos-ai/community/pull/82) uses this compiler
revision with FlagGems and vllm-plugin-FL.

## Motivation

Earlier CPU development used Triton 3.3 and 3.6 interfaces. Frontend, CMake, MLIR, LLVM,
launcher, and cache interfaces changed across releases, so the Arm64 backend needs a coherent
3.7 source and toolchain baseline. The `triton_v3.7.x` line now exists; the test task is to
verify its exact revision builds, selects the CPU target, compiles a real kernel, and runs the
FlagGems ARM operator added by
[FlagGems #5904](https://github.com/flagos-ai/FlagGems/pull/5904).

### Goals

**(Required)**

- Build and import Triton 3.7.2 with its Arm64 CPU backend on Linux `aarch64`.
- Keep the 3.7 CPU source, declared LLVM revision, and SLEEF submodule pinned for reproduction.
- Compile and execute a CPU Triton kernel with the same authoring interface used before the bump.
- Verify a downstream FlagGems quantized kernel against a PyTorch numerical reference.
- Record cold-JIT latency and representative performance on the same host without claiming a
  cross-machine throughput threshold.

### Non-Goals

- GPU, NPU, x86_64, macOS, and Windows acceptance.
- Adding model integration, W8A8 operators, or new quantization formats in this compiler FEP.
- Binary or compiler-cache compatibility with Triton 3.3 or 3.6.

## Proposal

The 3.7 line forward-ports CPU target discovery, driver, launcher, runtime, TritonCPU dialect,
and lowering as one buildable tree. Use its pinned LLVM revision rather than a host LLVM chosen
independently. `TRITON_CPU_BACKEND=1` selects the CPU backend; regular `@triton.jit` kernels
continue to launch through the `cpu` target. Keep caches from older Triton lines separate.

## Design Details

The pinned tree declares LLVM revision
`87717bf9f81f7b29466c5d9a30a3453bdfc93941` in `cmake/llvm-hash.txt` and SLEEF
submodule `93f04d869471ce4d007abaebb8c6a7bc62749f61`. Initialize submodules before
building: a checkout without SLEEF fails during CMake configuration. The test revision also
contains ARM I8MM/dot lowering and CPU `round`/`rint` libdevice support. The earlier
`77433cf0534d0cddf8717da654628f3f9e48cea9` checkout built but failed six of seven
FlagGems W4A8 tests on CIX P1; it is a failure baseline, not the acceptance revision.

The initial reference is CIX P1 (CD8180), Linux `aarch64`, Python 3.11.2, PyTorch
`2.11.0+cpu`, GCC 14.2.0, and CMake 3.31.6. Other Arm64 processors need their own ISA and
correctness checks. This FEP tests the `flagtree-cpu` package directly; a separate FlagTree
repository build is outside this test environment.

## Packaging

**(Required)** Build from source in an isolated directory. On Debian 13, install `git`,
`build-essential`, `ninja-build`, `cmake`, and `pipx` first. Four build jobs are conservative
for a 32 GiB CIX P1.

```bash
pipx install 'uv==0.8.24'
export PATH="$HOME/.local/bin:$PATH"
uv python install 3.11
export WORK_DIR="$HOME/flagtree-cpu-3.7-test"
mkdir -p "$WORK_DIR"
git clone --branch triton_v3.7.x --depth 1 \
  https://github.com/flagos-ai/flagtree-cpu.git "$WORK_DIR/flagtree-cpu"
git -C "$WORK_DIR/flagtree-cpu" checkout --detach \
  2c35990a30e96665f8f9b5e158562288b4011048
git -C "$WORK_DIR/flagtree-cpu" submodule update --init --recursive
cd "$WORK_DIR"
uv venv --python 3.11 .venv
source .venv/bin/activate
uv pip install -r flagtree-cpu/python/requirements.txt
uv pip install --extra-index-url https://download.pytorch.org/whl/cpu \
  --index-strategy unsafe-best-match 'torch==2.11.0+cpu' pytest
TRITON_HOME="$WORK_DIR/.triton-build" TRITON_BUILD_PROTON=OFF MAX_JOBS=4 \
  uv pip install --no-build-isolation --editable "$WORK_DIR/flagtree-cpu"
```

Do not install a public `triton` wheel over this checkout: that wheel does not contain this
CPU backend. `FLAGTREE_BACKEND=cpu` alone is not the verified selector for this package.

## Test Plan

**(Required)** Run these steps from `$WORK_DIR`. An outer directory named `triton` can shadow
the installed Python package.

1. Confirm the source, LLVM pin, import path, and CPU target:

   ```bash
   test "$(git -C "$WORK_DIR/flagtree-cpu" rev-parse HEAD)" = \
     2c35990a30e96665f8f9b5e158562288b4011048
   test "$(cat "$WORK_DIR/flagtree-cpu/cmake/llvm-hash.txt")" = \
     87717bf9f81f7b29466c5d9a30a3453bdfc93941
   TRITON_CPU_BACKEND=1 python - <<'PY'
   import platform
   from pathlib import Path
   import triton

   target = triton.runtime.driver.active.get_current_target()
   print(platform.machine(), triton.__version__, Path(triton.__file__).resolve(), target)
   assert platform.machine().lower() in {"aarch64", "arm64"}
   assert triton.__version__ == "3.7.2"
   assert "flagtree-cpu" in str(Path(triton.__file__).resolve())
   assert target.backend == "cpu"
   PY
   ```

2. Put the kernel in a **Python file**. Triton JIT cannot inspect a function defined on
   standard input:

   ```bash
   cat > "$WORK_DIR/vector_add.py" <<'PY'
   import torch
   import triton
   import triton.language as tl

   @triton.jit
   def add_one(x, y, BLOCK: tl.constexpr):
       offsets = tl.arange(0, BLOCK)
       tl.store(y + offsets, tl.load(x + offsets) + 1)

   x = torch.arange(128, dtype=torch.float32)
   y = torch.empty_like(x)
   add_one[(1,)](x, y, BLOCK=128)
   torch.testing.assert_close(y, x + 1)
   print("CPU vector add PASS", triton.runtime.driver.active.get_current_target())
   PY
   TRITON_CPU_BACKEND=1 python "$WORK_DIR/vector_add.py"
   ```

3. Install the exact FlagGems #5904 head
   `1fda4b11ae528c02ae5187cda551af4a61a514c5` in this environment with
   `FLAGGEMS_VENDOR=arm`, then run its `tests/test_arm_w4a8_g128.py` suite as shown in
   [FEP-0083](https://github.com/flagos-ai/community/pull/82). Require **7 passed, 0 skipped**.
   It executes the Triton W4A8 kernel and compares
   with a PyTorch reference. A model returning HTTP 200 does not replace this compiler check.

Capture source SHA, LLVM pin, host/ISA, compiler version, test output, and cold-JIT time.
Investigate a material slowdown against the older CPU line on the same host before changing
the FEP status to `Implemented`.

The 128-element vector-add and FlagGems W4A8 checks above establish the pinned compiler
and operator path. They do not exercise all vLLM 0.24 CPU launch sizes. On the same CIX P1,
an unpatched vLLM empty-cache MiniCPM5 request spent 915.78 s (W4A8) or 931.6 s (W8A8):
vLLM reused GPU-sized 1024/8192-element Triton bookkeeping/sampling launches on ARM CPU,
and LLVM `make_asm` became pathological. A targeted slot-mapping compile spent 289.617 s
at block 1024 versus 0.663 s at block 128; `perf` sampling pointed to LLVM live-range
and register-allocation work. This is a downstream vLLM launch-parameter problem, while
the FlagTree CPU package and FlagGems operator tests in this FEP passed.

For a **model-level** cold-cache test, follow
[FEP-0083 Steps 1–10](https://github.com/flagos-ai/community/pull/82) and apply its
[CPU-only vLLM 0.24.0 patch](https://github.com/kevinzs2048/community/blob/vllm-arm64/fep/sig-edge/patches/vllm-0.24.0-arm-cold-jit-128.patch)
before the editable vLLM installation. On CIX P1 with that patch and genuinely empty
Triton caches, W4A8 and W8A8 deterministic first requests completed in 11.452/9.552 s
after 22.140/12.773 s model initialization. W4A8 warm HTTP decoding was about
7.6 token/s; this remains a separate performance-acceptance concern. Do not treat the
small vector-add JIT time alone as the end-to-end cold-start latency.

## Related PRs

- [ ] [`flagtree-cpu/triton_v3.7.x`](https://github.com/flagos-ai/flagtree-cpu/tree/triton_v3.7.x) at `2c35990a...` — CPU line under acceptance test.
- [x] [FlagGems #5904](https://github.com/flagos-ai/FlagGems/pull/5904) — downstream ARM W4A8 operator, merged 2026-09-04.
- [ ] [vllm-plugin-FL #433](https://github.com/flagos-ai/vllm-plugin-FL/pull/433) — downstream vLLM 0.24 ARM CPU integration.

## Implementation History

- 2026-07-29: Initial Triton 3.7 CPU migration proposal.
- 2026-09-04: CIX P1 source-build revalidation identified `2c35990a...` as the passing
  revision; the earlier `77433cf...` failed six of seven FlagGems W4A8 tests.
- 2026-09-15: Pinned source/LLVM/SLEEF revisions and added executable enable and test steps.
  On CIX P1, CPU target selection, vector add, and FlagGems W4A8 passed.
- 2026-09-16: Documented the downstream vLLM CPU launch-size cold-JIT issue and the
  reproducible CPU-only patch and two-model cold-cache test in FEP-0083. Compiler and
  operator acceptance remains independent of model throughput acceptance.

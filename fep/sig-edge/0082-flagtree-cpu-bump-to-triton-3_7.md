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
sudo apt-get update
sudo apt-get install -y git build-essential ninja-build cmake pipx
uname -m
free -h
df -h "$HOME"
```

The reference host reports `aarch64` and 32 GiB RAM. Reserve free disk for the
approximately 8 GiB pinned LLVM cache and the native build tree; record host, RAM,
free disk, and the CPU features with `lscpu | grep -E 'Architecture|Flags'`.

```bash
pipx install 'uv==0.8.24'
export PATH="$HOME/.local/bin:$PATH"
uv python install 3.11
export WORK_DIR="$HOME/flagtree-cpu-3.7-test"
mkdir -p "$WORK_DIR"
git init -q "$WORK_DIR/flagtree-cpu"
if ! git -C "$WORK_DIR/flagtree-cpu" remote get-url origin >/dev/null 2>&1; then
  git -C "$WORK_DIR/flagtree-cpu" remote add origin \
    https://github.com/flagos-ai/flagtree-cpu.git
fi
test "$(git -C "$WORK_DIR/flagtree-cpu" remote get-url origin)" = \
  https://github.com/flagos-ai/flagtree-cpu.git
git -C "$WORK_DIR/flagtree-cpu" fetch --depth 1 origin \
  2c35990a30e96665f8f9b5e158562288b4011048
git -C "$WORK_DIR/flagtree-cpu" checkout --detach \
  2c35990a30e96665f8f9b5e158562288b4011048
test "$(git -C "$WORK_DIR/flagtree-cpu" rev-parse HEAD)" = \
  2c35990a30e96665f8f9b5e158562288b4011048
git -C "$WORK_DIR/flagtree-cpu" submodule update --init --recursive
cd "$WORK_DIR"
uv venv --python 3.11 .venv
source .venv/bin/activate
uv pip install -r flagtree-cpu/python/requirements.txt
uv pip install --extra-index-url https://download.pytorch.org/whl/cpu \
  --index-strategy unsafe-best-match 'torch==2.11.0+cpu' 'numpy==2.3.5' pytest
TRITON_HOME="$WORK_DIR/.triton-build" TRITON_BUILD_PROTON=OFF MAX_JOBS=4 \
  uv pip install --no-build-isolation --editable "$WORK_DIR/flagtree-cpu"
```

Do not install a public `triton` wheel over this checkout: that wheel does not contain this
CPU backend. `FLAGTREE_BACKEND=cpu` alone is not the verified selector for this package.
The source build downloads the pinned LLVM archive and auxiliary NVIDIA tool archives
even when the run selects the CPU backend. Permit access to
`oaitriton.blob.core.windows.net` and `developer.download.nvidia.com`; if a transfer
is interrupted, rerun the editable-install command with the same `TRITON_HOME` so its
compatible third-party cache can be reused.

## Test Plan

**(Required)** Restore the environment in a new terminal, run the repository's required
incremental `make` build, then execute the numbered checks from `$WORK_DIR`. An outer
directory named `triton` can shadow the installed Python package.

```bash
export WORK_DIR="$HOME/flagtree-cpu-3.7-test"
source "$WORK_DIR/.venv/bin/activate"
PATH="$WORK_DIR/.venv/bin:$PATH" \
  make -C "$WORK_DIR/flagtree-cpu" PYTHON="$WORK_DIR/.venv/bin/python"
cd "$WORK_DIR"
```

1. Confirm the source, LLVM pin, import path, and CPU target:

   ```bash
   test "$(git -C "$WORK_DIR/flagtree-cpu" rev-parse HEAD)" = \
     2c35990a30e96665f8f9b5e158562288b4011048
   test "$(cat "$WORK_DIR/flagtree-cpu/cmake/llvm-hash.txt")" = \
     87717bf9f81f7b29466c5d9a30a3453bdfc93941
   test "$(git -C "$WORK_DIR/flagtree-cpu/third_party/sleef" rev-parse HEAD)" = \
     93f04d869471ce4d007abaebb8c6a7bc62749f61
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
   import time

   import torch
   import triton
   import triton.language as tl

   @triton.jit
   def add_one(x, y, BLOCK: tl.constexpr):
       offsets = tl.arange(0, BLOCK)
       tl.store(y + offsets, tl.load(x + offsets) + 1)

   x = torch.arange(128, dtype=torch.float32)
   y = torch.empty_like(x)
   started = time.perf_counter()
   add_one[(1,)](x, y, BLOCK=128)
   cold_s = time.perf_counter() - started
   torch.testing.assert_close(y, x + 1)
   started = time.perf_counter()
   add_one[(1,)](x, y, BLOCK=128)
   warm_s = time.perf_counter() - started
   torch.testing.assert_close(y, x + 1)
   print("CPU vector add PASS", triton.runtime.driver.active.get_current_target(),
         "cold_JIT_plus_run_s", round(cold_s, 3), "cached_run_s", round(warm_s, 3))
   PY
   export TRITON_CACHE_DIR
   TRITON_CACHE_DIR=$(mktemp -d "$WORK_DIR/triton-jit-XXXXXX")
   TRITON_CPU_BACKEND=1 python "$WORK_DIR/vector_add.py"
   ```

3. Install the exact FlagGems #5904 head in **this** `$WORK_DIR/.venv`, then run its
   numerical W4A8-G128 suite. Do not switch to FEP-0083's separate test environment.

   ```bash
   git init -q "$WORK_DIR/FlagGems"
   if ! git -C "$WORK_DIR/FlagGems" remote get-url origin >/dev/null 2>&1; then
     git -C "$WORK_DIR/FlagGems" remote add origin \
       https://github.com/flagos-ai/FlagGems.git
   fi
   test "$(git -C "$WORK_DIR/FlagGems" remote get-url origin)" = \
     https://github.com/flagos-ai/FlagGems.git
   git -C "$WORK_DIR/FlagGems" fetch --depth 1 origin \
     1fda4b11ae528c02ae5187cda551af4a61a514c5
   git -C "$WORK_DIR/FlagGems" checkout --detach \
     1fda4b11ae528c02ae5187cda551af4a61a514c5
   test "$(git -C "$WORK_DIR/FlagGems" rev-parse HEAD)" = \
     1fda4b11ae528c02ae5187cda551af4a61a514c5
   FLAGGEMS_VENDOR=arm uv pip install --no-build-isolation \
     --editable "$WORK_DIR/FlagGems"
   cd "$WORK_DIR/FlagGems"
   export TRITON_CACHE_DIR
   TRITON_CACHE_DIR=$(mktemp -d "$WORK_DIR/flaggems-jit-XXXXXX")
   FLAGGEMS_VENDOR=arm TRITON_CPU_BACKEND=1 \
     python -m pytest -ra tests/test_arm_w4a8_g128.py
   ```

   Require **7 passed, 0 skipped**. The suite executes the Triton W4A8 kernel
   and compares it with a PyTorch reference. A model returning HTTP 200 does not
   replace this compiler check.

   On the reference CPU, FlagGems can warn that device properties and capability
   are unavailable and that its replay benchmarker falls back to event timing.
   These warnings do not waive the seven numerical comparisons.

Capture source SHA, LLVM pin, host/ISA, compiler version, test output, and cold-JIT time.
Investigate a material slowdown against the older CPU line on the same host before changing
the FEP status to `Implemented`.

### Fresh CIX P1 test record (2026-09-16)

| Check | Observed result |
|---|---|
| Source and toolchain | Fresh checkout `2c35990a...`, LLVM `87717bf...`, SLEEF `93f04d...`; Python 3.11.13, PyTorch `2.11.0+cpu`, NumPy 2.3.5 |
| Native build and target | Editable source build succeeded; repository `make` reported no work; Triton 3.7.2 selected `cpu/aarch64` |
| Empty-cache vector add | Output matched PyTorch; cold JIT plus execution 1.627 s, cached execution below displayed 0.001 s |
| FlagGems #5904 | Exact `1fda4b11...` installed in this virtual environment; a second run with a newly empty Triton cache gave W4A8-G128 **7 passed, 0 skipped** in 4.01 s, with three CPU fallback warnings |

The 128-element vector-add and FlagGems W4A8 checks above establish the pinned compiler
and operator path. The standalone vector-add example does not change vLLM's launch
parameters. These checks do not exercise all vLLM 0.24 CPU launch sizes.

**Known model-level limitation:** unmodified vLLM empty-cache MiniCPM5 requests
previously took 915.78 seconds for W4A8 and 931.6 seconds for W8A8 on CIX P1.
Its CPU worker reuses 1024/8192-element Triton bookkeeping/sampling launches, and LLVM
code generation can take minutes. A small vector-add JIT result cannot establish
acceptable model cold-start latency. Compiler lowering and application launch sizes
both affect that cost; passing these operator tests does not resolve it.

For model inference, use the four unmodified source revisions in
[FEP-0083](https://github.com/flagos-ai/community/pull/82), including its Step 10
persistent-cache prewarming procedure. **No vLLM BLOCK_SIZE patch is required by
the enable steps.** Prewarming incurs the compilation cost during preparation and
allows matching kernels to be reused across restarts. Keep the cache at the same
absolute path and record CPU/compiler/runtime identity; different hardware, settings
or request specializations can still trigger JIT. Record installation time, model
loading, first-use compilation and warm decoding separately. Throughput and quality
require their own acceptance tests.

## Related PRs

- [ ] [`flagtree-cpu/triton_v3.7.x`](https://github.com/flagos-ai/flagtree-cpu/tree/triton_v3.7.x) at `2c35990a...` — CPU line under acceptance test.
- [x] [FlagGems #5904](https://github.com/flagos-ai/FlagGems/pull/5904) — downstream ARM W4A8 operator, merged 2026-09-04.
- [x] [vllm-plugin-FL #433](https://github.com/flagos-ai/vllm-plugin-FL/pull/433) — downstream vLLM 0.24 ARM CPU integration, merged 2026-09-09.

## Implementation History

- 2026-07-29: Initial Triton 3.7 CPU migration proposal.
- 2026-09-04: CIX P1 source-build revalidation identified `2c35990a...` as the passing
  revision; the earlier `77433cf...` failed six of seven FlagGems W4A8 tests.
- 2026-09-15: Pinned source/LLVM/SLEEF revisions and added executable enable and test steps.
  On CIX P1, CPU target selection, vector add, and FlagGems W4A8 passed.
- 2026-09-16: Highlighted the downstream vLLM model first-use JIT limitation and
  linked the unmodified-source persistent-cache prewarming procedure in FEP-0083.
  Compiler/operator acceptance remains independent of model cold-start and
  warm-throughput acceptance.
- 2026-09-16: Made the FlagGems checkout, editable install, and 7/7 numerical test
  executable inside FEP-0082's own virtual environment. Fetch the exact FlagTree CPU
  commit rather than depending on the branch tip remaining unchanged. The vector-add
  step now uses a new cache and reports cold JIT plus execution and cached execution.

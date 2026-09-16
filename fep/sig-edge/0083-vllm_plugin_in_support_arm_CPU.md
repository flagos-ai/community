# FEP-0083: vllm-plugin-FL Support for Arm64 CPU Local Inference

**Status:** `Implementable`

**Created:** 2026-07-29

**Owner:** @kevinzs2048

**SIG:** sig-edge

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP enables [`vllm-plugin-FL`](https://github.com/flagos-ai/vllm-plugin-FL)
on Linux Arm64 CPUs while reusing vLLM's built-in `CpuPlatform`, worker, attention, KV cache,
and serving API. The pinned implementation is
[vllm-plugin-FL #433](https://github.com/flagos-ai/vllm-plugin-FL/pull/433) at
`0252496764901de4d464ab64c09d995c954be646`, tested with vLLM `0.24.0+cpu`,
[FlagGems #5904](https://github.com/flagos-ai/FlagGems/pull/5904), and
[`flagtree-cpu/triton_v3.7.x`](https://github.com/flagos-ai/flagtree-cpu/tree/triton_v3.7.x).

The plugin's ARM CPU implementation recognizes `compressed-tensors` **packed W4A8-G128**
checkpoints and routes their linear operators to FlagGems. The
[`FlagRelease/MiniCPM5-2B-W8A8-arm-FlagOS`](https://modelscope.cn/models/FlagRelease/MiniCPM5-2B-W8A8-arm-FlagOS)
checkpoint is **`int-quantized` channel-wise W8A8**. In this source environment it uses
vLLM's native CPU INT8 linear kernel. It is a useful end-to-end W8A8 inference and plugin
coexistence test; it does not demonstrate a FlagGems-accelerated W8A8 CPU route. That route
needs separate implementation and acceptance evidence before this FEP can be `Implemented`.

On CIX P1, a **losslessly repacked copy** of the public
[`FlagRelease/MiniCPM5-2B-W4A8-arm-FlagOS`](https://modelscope.cn/models/FlagRelease/MiniCPM5-2B-W4A8-arm-FlagOS)
checkpoint completed offline and HTTP inference through the plugin and FlagGems W4A8 CPU
path. The as-published checkpoint declares `int-quantized`; the packed adapter in PR #433
does not select FlagGems for that format without the storage conversion in Step 8 below.
In the latest fresh CIX P1 environment, the Step 2 CPU JIT patch reduced separate
empty-cache deterministic first requests to **11.610 s W4A8** and **9.614 s W8A8**
after model initialization, versus the previously observed 915.78/931.6-second
unpatched behavior. Five single-user 64-token HTTP requests per model measured warm
short-input decoding at **7.73 token/s W4A8** and **4.69 token/s W8A8**. Both routes
function, but these rates require a separate performance acceptance decision; W8A8
still selects vLLM's native CPU INT8 kernel rather than FlagGems acceleration.

## Motivation

The earlier FEP draft was based on vLLM 0.20.2 and prototype `FL_CPU_INT4`/`FL_CPU_INT8`
flags. Those flags and native-asset assumptions do not describe PR #433. Test colleagues need
instructions that reproduce the current code and distinguish three outcomes: the FlagTree CPU
compiler works, the packed W4A8 adapter and FlagGems operator work, and the published W8A8
checkpoint completes inference through the kernel actually selected at runtime.

### Goals

**(Required)**

- Select vLLM 0.24's stock CPU platform when the host, vLLM build, and FlagGems backend are Arm64 CPU.
- Preserve packed W4A8-G128 weights and scales, then run the FlagGems ARM W4A8 operator.
- Keep the Qwen GDN stride compatibility hook idempotent and isolated from accelerator builds.
- Load the pinned MiniCPM5 W8A8 release checkpoint and return non-empty HTTP inference.
- Losslessly repackage the public MiniCPM5 W4A8-G128 release checkpoint, then verify
  end-to-end generation and the actual FlagGems W4A8 call path.
- Verify from logs whether W8A8 used native vLLM or a future FlagGems path; do not infer it
  from the checkpoint name or from the HTTP response.
- Add an optimized ARM W8A8 plugin path in a follow-up implementation, with a kernel-selection
  and numerical test, if W8A8 acceleration remains an acceptance goal for FlagOS 2.2.

### Non-Goals

- Replacing vLLM's CPU worker, attention, scheduler, or KV-cache implementation.
- Treating W4A8 and W8A8 checkpoints as interchangeable or switching their checkpoint format
  with an environment flag.
- Claiming CIX image-local native/KleidiAI kernels are delivered by PR #433 alone.

## Proposal

Install a vLLM `0.24.0+cpu` build, FlagTree CPU/Triton 3.7.2, FlagGems with its ARM backend,
and the plugin. Before the first vLLM or FlagGems import, set `FLAGGEMS_VENDOR=arm` and
`TRITON_CPU_BACKEND=1`. `VLLM_PLUGINS=fl` isolates the installed `fl` plugin in a test process.
The plugin automatically returns vLLM's `CpuPlatform` on a Linux `aarch64` CPU build. There
is no dedicated `FL_CPU_INT4` or `FL_CPU_INT8` switch for PR #433's ARM CPU path.

The checkpoint metadata chooses the linear scheme:

| Checkpoint contract | Current route in this environment |
|---|---|
| `pack-quantized`, symmetric INT4 group-wise G128 weight, dynamic per-token INT8 activation | Plugin W4A8 adapter -> FlagGems `w4a8_g128_linear()` -> FlagTree CPU JIT |
| `int-quantized`, symmetric INT8 per-channel weight, dynamic per-token INT8 activation | vLLM `CompressedTensorsW8A8Int8` -> `CPUInt8ScaledMMLinearKernel` (oneDNN path) |

The pinned vLLM commit also launches several GPU-sized Triton bookkeeping and sampling
kernels on its CPU worker. With an empty CPU JIT cache, LLVM code generation of these
1024/8192-element vectors can stall for minutes. Apply the CPU-only
[vLLM 0.24.0 cold-JIT patch](patches/vllm-0.24.0-arm-cold-jit-128.patch) in Step 2 before
building vLLM. It sets eight affected CPU launch sizes to 128 and leaves GPU launch sizes
unchanged. This is a test-environment source patch, not part of plugin #433, FlagGems #5904,
or the pinned upstream vLLM commit; record its SHA256 alongside the four source SHAs.

The MiniCPM5 W8A8 release has 42 `LlamaForCausalLM` layers, BF16 embeddings and `lm_head`,
and an INT8 model body. Its configuration declares up to 131072 positions. The smoke procedure
below uses 512 positions to reduce cold-start cost; it is not a long-context acceptance test.

## Design Details

PR #433 owns ARM CPU platform registration, packed W4A8 checkpoint metadata and weight
conversion, kernel lifecycle, and Qwen GDN CPU compatibility. FlagGems #5904 owns the public
W4A8-G128 packer and Triton operator. The ARM CPU hooks are installed only when the selected
platform is CPU, the host is `aarch64`/`arm64`, and FlagGems reports vendor `arm`; otherwise
the existing platform route remains active. Repeated plugin registration must not patch the
same vLLM method twice.

The W8A8 release checkpoint uses `format: int-quantized`, so it does not match the plugin's
packed W4A8 adapter. PR #433's FlagGems W8A8 linear bridge belongs to the accelerator-shaped
OOT platform, not to the stock ARM CPU platform returned by this integration. A W8A8 HTTP
response is therefore a compatibility result until a separate ARM W8A8 operator is selected
and measured. Image-specific `QUANT_MODE=w8`/`FL_CPU_INT8` launchers refer to a different
runtime and are not part of this four-source test environment.

## Packaging

**(Required)** Reproduce on Linux `aarch64` with Python 3.11, PyTorch `2.11.0+cpu`, and
vLLM `0.24.0+cpu`. The example host is CIX P1 with 32 GiB RAM. On Debian 13, install
`git`, `curl`, `build-essential`, `ccache`, `ninja-build`, `cmake`, `gcc-12`, `g++-12`,
`libnuma-dev`, `libtcmalloc-minimal4t64`, and `pipx` first. Do not put a clone called `vllm`
in Python's current import directory during package verification.

### Step 0: Check the Debian 13 ARM host

Run this once on a test host with package-install privileges. The Debian 13 t64 package
name is `libtcmalloc-minimal4t64`; `libtcmalloc-minimal4` is not available from the
reference Debian 13 repository. Keep enough free disk for the approximately 8 GiB LLVM
cache, native build trees, and two approximately 3 GiB public model weights.

```bash
sudo apt-get update
sudo apt-get install -y git curl build-essential ccache ninja-build cmake \
  gcc-12 g++-12 libnuma-dev libtcmalloc-minimal4t64 pipx
uname -m
free -h
df -h "$HOME"
lscpu -e=CPU,CORE,ONLINE,MAXMHZ
lscpu | grep -E 'Architecture|Flags'
```

The reference CIX P1 reports `aarch64`, `asimddp`, `i8mm`, and `bf16` CPU features,
32 GiB RAM, and eight A720 cores `0,1,6,7,8,9,10,11`. Adjust later affinity values
only after identifying the test host's big cores; record host, features, RAM, and free
disk in the test report.

### Step 1: Create a clean Python environment and pin the four sources

```bash
pipx install 'uv==0.8.24'
export PATH="$HOME/.local/bin:$PATH"
uv python install 3.11
export WORK_DIR="$HOME/arm64-vllm024-test"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
uv venv --python 3.11 .venv
source .venv/bin/activate

fetch_commit() {
  repo_url=$1
  repo_dir=$2
  source_sha=$3
  if [ ! -d "$WORK_DIR/$repo_dir/.git" ]; then
    git init -q "$WORK_DIR/$repo_dir"
  fi
  if ! git -C "$WORK_DIR/$repo_dir" remote get-url origin >/dev/null 2>&1; then
    git -C "$WORK_DIR/$repo_dir" remote add origin "$repo_url"
  fi
  test "$(git -C "$WORK_DIR/$repo_dir" remote get-url origin)" = "$repo_url"
  git -C "$WORK_DIR/$repo_dir" fetch --depth 1 origin "$source_sha"
  git -C "$WORK_DIR/$repo_dir" checkout --detach "$source_sha"
  test "$(git -C "$WORK_DIR/$repo_dir" rev-parse HEAD)" = "$source_sha"
}
fetch_commit https://github.com/vllm-project/vllm.git vllm \
  ee0da84ab9e04ac7610e28580af62c365e898389
fetch_commit https://github.com/flagos-ai/flagtree-cpu.git flagtree-cpu \
  2c35990a30e96665f8f9b5e158562288b4011048
fetch_commit https://github.com/flagos-ai/FlagGems.git FlagGems \
  1fda4b11ae528c02ae5187cda551af4a61a514c5
fetch_commit https://github.com/flagos-ai/vllm-plugin-FL.git vllm-plugin-FL \
  0252496764901de4d464ab64c09d995c954be646
git -C "$WORK_DIR/flagtree-cpu" submodule update --init --recursive
```

The FlagGems commit is the merged #5904 head. The plugin commit is the merged #433 PR head;
record all four `git rev-parse HEAD` outputs in the test report.
`flagtree-cpu` revision `2c35990a...` is required: the earlier `77433cf...` checkout fails
six of seven ARM W4A8 numerical tests.

### Step 2: Install the CPU packages

```bash
export PATH="$HOME/.local/bin:$PATH"
export WORK_DIR="$HOME/arm64-vllm024-test"
source "$WORK_DIR/.venv/bin/activate"
curl --fail --location --retry 3 --output "$WORK_DIR/vllm-arm-cold-jit.patch" \
  'https://raw.githubusercontent.com/kevinzs2048/community/363fc1fae1dcbf834c4173765fead67bfd0643ff/fep/sig-edge/patches/vllm-0.24.0-arm-cold-jit-128.patch'
printf '%s  %s\n' \
  'a2f53cae6a5759590c4637378f673b7c4edb23986f8f51ffe811a14058027959' \
  "$WORK_DIR/vllm-arm-cold-jit.patch" | sha256sum -c -
if git -C "$WORK_DIR/vllm" apply --reverse --check \
  "$WORK_DIR/vllm-arm-cold-jit.patch" >/dev/null 2>&1; then
  echo 'vLLM CPU cold-JIT patch already applied'
else
  git -C "$WORK_DIR/vllm" apply --check "$WORK_DIR/vllm-arm-cold-jit.patch"
  git -C "$WORK_DIR/vllm" apply "$WORK_DIR/vllm-arm-cold-jit.patch"
fi
git -C "$WORK_DIR/vllm" diff --check
cat > "$WORK_DIR/constraints.txt" <<'EOF'
torch==2.11.0
torchaudio==2.11.0
torchvision==0.26.0
transformers==5.15.1
tokenizers==0.22.2
compressed-tensors==0.17.0
numpy==2.3.5
numba==0.65.0
llvmlite==0.47.0
safetensors==0.8.0
sqlalchemy==2.0.48
EOF

uv pip install -r "$WORK_DIR/vllm/requirements/cpu.txt" \
  --constraint "$WORK_DIR/constraints.txt" --index-strategy unsafe-best-match
uv pip install 'cmake==4.4.2' 'ninja==1.13.0' 'pybind11==3.0.3' \
  'setuptools==77.0.3' 'setuptools-scm==9.2.0' \
  'setuptools-rust==1.13.0' 'scikit-build-core==0.12.2' \
  pytest --constraint "$WORK_DIR/constraints.txt"

fetch_cpu_build_dependency() {
  repo_dir=$1
  repo_url=$2
  fetch_ref=$3
  source_sha=$4
  if [ ! -d "$WORK_DIR/$repo_dir/.git" ]; then
    git init -q "$WORK_DIR/$repo_dir"
  fi
  if ! git -C "$WORK_DIR/$repo_dir" remote get-url origin >/dev/null 2>&1; then
    git -C "$WORK_DIR/$repo_dir" remote add origin "$repo_url"
  fi
  test "$(git -C "$WORK_DIR/$repo_dir" remote get-url origin)" = "$repo_url"
  git -C "$WORK_DIR/$repo_dir" fetch --depth 1 origin "$fetch_ref"
  git -C "$WORK_DIR/$repo_dir" checkout --detach "$source_sha"
  test "$(git -C "$WORK_DIR/$repo_dir" rev-parse HEAD)" = "$source_sha"
}
fetch_cpu_build_dependency acl-v52.6.0 \
  https://github.com/ARM-software/ComputeLibrary.git refs/tags/v52.6.0 \
  007264fa740de5723ebddef16b7bb3657692c088
fetch_cpu_build_dependency onednn-9c5be1 \
  https://github.com/oneapi-src/oneDNN.git \
  9c5be1cc59e368aebf0909e6cf20f981ea61462a \
  9c5be1cc59e368aebf0909e6cf20f981ea61462a

export BUILD_JOBS=4
TRITON_HOME="$WORK_DIR/.triton-build" TRITON_BUILD_PROTON=OFF MAX_JOBS="$BUILD_JOBS" \
  uv pip install --no-build-isolation --constraint "$WORK_DIR/constraints.txt" \
  --editable "$WORK_DIR/flagtree-cpu"
cmake -G Ninja -S "$WORK_DIR/acl-v52.6.0" -B "$WORK_DIR/acl-v52.6.0/build" \
  -DARM_COMPUTE_BUILD_SHARED_LIB=OFF -DCMAKE_BUILD_TYPE=Release \
  -DARM_COMPUTE_ARCH=armv8.2-a -DARM_COMPUTE_ENABLE_ASSERTS=OFF \
  -DARM_COMPUTE_ENABLE_CPPTHREADS=OFF -DARM_COMPUTE_ENABLE_OPENMP=ON \
  -DARM_COMPUTE_ENABLE_WERROR=OFF -DARM_COMPUTE_BUILD_EXAMPLES=OFF \
  -DARM_COMPUTE_BUILD_TESTING=OFF
cmake --build "$WORK_DIR/acl-v52.6.0/build" --parallel "$BUILD_JOBS"
CMAKE_ARGS="-DFETCHCONTENT_SOURCE_DIR_ONEDNN=$WORK_DIR/onednn-9c5be1" \
ACL_ROOT_DIR="$WORK_DIR/acl-v52.6.0" \
VLLM_TARGET_DEVICE=cpu VLLM_VERSION_OVERRIDE=0.24.0+cpu MAX_JOBS="$BUILD_JOBS" \
  uv pip install --no-build-isolation --constraint "$WORK_DIR/constraints.txt" \
  --editable "$WORK_DIR/vllm"
unset VLLM_VENDOR
FLAGGEMS_VENDOR=arm uv pip install --no-build-isolation \
  --constraint "$WORK_DIR/constraints.txt" --editable "$WORK_DIR/FlagGems"
uv pip install --no-build-isolation --constraint "$WORK_DIR/constraints.txt" \
  --editable "$WORK_DIR/vllm-plugin-FL"
```

The `flagtree-cpu` installation supplies import name `triton`; do not replace it with the
public Triton wheel. On the reference CIX P1, `MAX_JOBS=4` keeps native compilation within
32 GiB. Its source build fetches pinned LLVM and auxiliary NVIDIA tool archives even for
the CPU backend; permit access to `oaitriton.blob.core.windows.net` and
`developer.download.nvidia.com`, and rerun Step 2 if a transfer is interrupted. A compatible
`TRITON_HOME` cache can be reused across attempts. These are source/editable test packages;
release wheel and image publication are separate work. The vLLM CPU build needs Arm
Compute Library tag `v52.6.0` and oneDNN commit
`9c5be1cc59e368aebf0909e6cf20f981ea61462a`. The commands above fetch those
exact sources with shallow Git history, verify their commits, and pass them to CMake;
without the local sources, vLLM's CPU build fetches them itself. Record these two
build-dependency SHAs with the four main source SHAs.
The explicit ACL prebuild uses four jobs and the same CMake settings as vLLM's internal
ACL invocation. vLLM 0.24's internal ACL build otherwise uses the detected processor
count (12 on CIX P1), independent of `MAX_JOBS`; in the fresh reference build, its later
invocation was incremental. Keep the ACL build output in its source checkout
for a Step 2 rerun.
The patch changes Python launch parameters in the editable vLLM source; it does not remove
the initial package/native-extension build. On a Step 2 rerun, the reverse-apply check above
detects an existing patch so the source edit is not duplicated.

## Test Plan

**(Required)** Run all steps, save the commands and logs, and report passed/skipped/failed
counts. The FlagGems and plugin suites verify the W4A8 implementation independently of the
MiniCPM5 W8A8 model test.

### Step 3: Verify the installed CPU platform and run operator tests

```bash
export WORK_DIR="$HOME/arm64-vllm024-test"
cd "$WORK_DIR/vllm-plugin-FL"
source "$WORK_DIR/.venv/bin/activate"
PATH="$WORK_DIR/.venv/bin:$PATH" \
  make -C "$WORK_DIR/flagtree-cpu" PYTHON="$WORK_DIR/.venv/bin/python"
export FLAGGEMS_VENDOR=arm TRITON_CPU_BACKEND=1 VLLM_PLUGINS=fl
python - <<'PY'
from pathlib import Path
import platform
import torch
import triton
import flag_gems
import vllm
import vllm._C
import vllm_fl
from vllm.platforms import current_platform

print(platform.machine(), torch.__version__, triton.__version__, vllm.__version__)
print(Path(triton.__file__).resolve(), Path(vllm_fl.__file__).resolve())
print(flag_gems.vendor_name, type(current_platform).__name__, current_platform.device_type)
assert platform.machine().lower() in {"aarch64", "arm64"}
assert torch.__version__ == "2.11.0+cpu"
assert triton.__version__ == "3.7.2"
assert vllm.__version__ == "0.24.0+cpu"
assert flag_gems.vendor_name == "arm"
assert type(current_platform).__name__ == "CpuPlatform"
assert current_platform.device_type == "cpu"
PY

cd "$WORK_DIR/FlagGems"
python -m pytest -ra tests/test_arm_w4a8_g128.py
cd "$WORK_DIR/vllm-plugin-FL"
python -m pytest -ra \
  tests/unit_tests/test_arm_cpu_registration.py \
  tests/unit_tests/patches/test_arm_cpu_gdn.py \
  tests/unit_tests/quantization/test_arm_cpu_w4a8.py
```

Require **7 passed, 0 skipped** for FlagGems and **16 passed, 0 skipped** for the plugin.
[FEP-0082](https://github.com/flagos-ai/community/pull/83) contains an independent
vector-add check for the FlagTree CPU compiler.

### Step 4: Fetch and verify the release W8A8 checkpoint

Use the exact ModelScope repository commit and its two LFS blob identities. The published
model card mentions `SHA256SUMS`, but that file is absent at the pinned repository revision;
the following explicit checks are executable against the actual repository.

```bash
export WORK_DIR="$HOME/arm64-vllm024-test"
source "$WORK_DIR/.venv/bin/activate"
export MODEL_DIR="$HOME/Models/MiniCPM5-2B-W8A8-arm-FlagOS"
mkdir -p "$MODEL_DIR"
git init -q "$MODEL_DIR"
if ! git -C "$MODEL_DIR" remote get-url origin >/dev/null 2>&1; then
  git -C "$MODEL_DIR" remote add origin \
    https://www.modelscope.cn/FlagRelease/MiniCPM5-2B-W8A8-arm-FlagOS.git
fi
test "$(git -C "$MODEL_DIR" remote get-url origin)" = \
  https://www.modelscope.cn/FlagRelease/MiniCPM5-2B-W8A8-arm-FlagOS.git
GIT_LFS_SKIP_SMUDGE=1 git -C "$MODEL_DIR" fetch --depth 1 origin \
  e53463a1587ac1a3446efc761c50652a1306ef5e
GIT_LFS_SKIP_SMUDGE=1 git -C "$MODEL_DIR" checkout --detach \
  e53463a1587ac1a3446efc761c50652a1306ef5e
download_verified_lfs() {
  expected_sha=$1
  file_name=$2
  file_url=$3
  if (cd "$MODEL_DIR" && printf '%s  %s\n' "$expected_sha" "$file_name" |
      sha256sum -c - >/dev/null 2>&1); then
    echo "$file_name already verified"
    return
  fi
  if head -c 64 "$MODEL_DIR/$file_name" |
      grep -q '^version https://git-lfs.github.com/spec/v1'; then
    truncate -s 0 "$MODEL_DIR/$file_name"
  fi
  curl --fail --location --retry 3 --continue-at - \
    --output "$MODEL_DIR/$file_name" "$file_url"
  (cd "$MODEL_DIR" && printf '%s  %s\n' "$expected_sha" "$file_name" |
    sha256sum -c -)
}
download_verified_lfs \
  ce27c62b10b4e7bbecbf84b7c820d3b293f9f7ff93a5963aecd785009abda905 \
  model-00000-of-00001.safetensors \
  'https://www.modelscope.cn/models/FlagRelease/MiniCPM5-2B-W8A8-arm-FlagOS/resolve/e53463a1587ac1a3446efc761c50652a1306ef5e/model-00000-of-00001.safetensors'
download_verified_lfs \
  3e065a558a034185fe299917b398685c1facd0169a9eea1e629eb30c171fed81 \
  tokenizer.json \
  'https://www.modelscope.cn/models/FlagRelease/MiniCPM5-2B-W8A8-arm-FlagOS/resolve/e53463a1587ac1a3446efc761c50652a1306ef5e/tokenizer.json'
test "$(git -C "$MODEL_DIR" rev-parse HEAD)" = \
  e53463a1587ac1a3446efc761c50652a1306ef5e
python - <<'PY'
import json
import os
from pathlib import Path

config = json.loads((Path(os.environ["MODEL_DIR"]) / "config.json").read_text())
group = next(iter(config["quantization_config"]["config_groups"].values()))
weights = group["weights"]
activations = group["input_activations"]
assert config["architectures"] == ["LlamaForCausalLM"]
assert config["num_hidden_layers"] == 42
assert config["quantization_config"]["format"] == "int-quantized"
assert weights["num_bits"] == 8 and weights["strategy"] == "channel"
assert weights["symmetric"] and not weights["dynamic"]
assert activations["num_bits"] == 8 and activations["strategy"] == "token"
assert activations["symmetric"] and activations["dynamic"]
print("W8A8 checkpoint metadata PASS")
PY
```

The weight is 3,054,963,160 bytes. Keep `config.json`, tokenizer files, and weights from the
same repository. If the release weight checksum changes, stop and request a new pinned model
revision rather than treating another file as the validated checkpoint.
The `download_verified_lfs` function skips already verified files and resumes partial
downloads. It zeros only unresolved Git LFS pointers. If a completed file fails SHA256,
investigate the source revision and download before running inference.
On the reference host, a 1 MiB partial `tokenizer.json` resumed from the pinned
ModelScope URL and reached the expected full-file SHA256.
After replacing Git LFS pointers with their real blobs, `git status` may show the two
files as modified; the pinned SHA256 checks above establish their byte identity.

### Step 5: Start the model service (terminal A)

First check the CIX P1 core layout with `lscpu -e=CPU,CORE,ONLINE,MAXMHZ`. The reference board
uses its eight Cortex-A720 cores `0,1,6,7,8,9,10,11`; adapt affinity on another Arm64 host.
Without the Step 2 vLLM patch, an empty Triton cache can take many minutes even with
`--enforce-eager`. On the reference board a pristine vLLM first request compiled the CPU
slot-mapping kernel in `triton/backends/cpu/compiler.py::make_asm`. With the patch, first-use
JIT remains necessary but the tested eight kernels compile in seconds; Step 10 measures this
separately from package compilation and warm decoding.

```bash
export WORK_DIR="$HOME/arm64-vllm024-test"
export MODEL_DIR="$HOME/Models/MiniCPM5-2B-W8A8-arm-FlagOS"
cd "$WORK_DIR/vllm-plugin-FL"
source "$WORK_DIR/.venv/bin/activate"
export FLAGGEMS_VENDOR=arm TRITON_CPU_BACKEND=1 VLLM_PLUGINS=fl
export A720_CORES=0,1,6,7,8,9,10,11
export OMP_NUM_THREADS=8 MKL_NUM_THREADS=8
export VLLM_CPU_OMP_THREADS_BIND="$A720_CORES"
export VLLM_CPU_KVCACHE_SPACE=1
export VLLM_EXECUTE_MODEL_TIMEOUT_SECONDS=1800
export TRITON_CACHE_DIR="$WORK_DIR/.cache/triton-2c35990"
export TORCHINDUCTOR_CACHE_DIR="$WORK_DIR/.cache/inductor-2c35990"
export VLLM_CACHE_ROOT="$WORK_DIR/.cache/vllm-2c35990"
mkdir -p "$TRITON_CACHE_DIR" "$TORCHINDUCTOR_CACHE_DIR" "$VLLM_CACHE_ROOT"
set -o pipefail
taskset -c "$A720_CORES" vllm serve "$MODEL_DIR" \
  --host 127.0.0.1 --port 18042 --served-model-name minicpm5-w8a8 \
  --dtype bfloat16 --enforce-eager --max-model-len 512 \
  --max-num-seqs 1 --max-num-batched-tokens 512 \
  --generation-config vllm --distributed-executor-backend uni \
  --disable-log-stats --language-model-only 2>&1 | tee "$WORK_DIR/server.log"
```

Expected log evidence: `Platform plugin fl is activated`, `device_config=cpu`,
`Resolved architecture: LlamaForCausalLM`, and
`Selected CPUInt8ScaledMMLinearKernel for CompressedTensorsW8A8Int8`.
That last line proves this checkpoint selected vLLM's CPU INT8 path; it is not evidence for a
FlagGems W8A8 route.

### Step 6: Call the API and check output (terminal B)

```bash
export WORK_DIR="$HOME/arm64-vllm024-test"
source "$WORK_DIR/.venv/bin/activate"
curl --noproxy '*' --fail-with-body --max-time 10 \
  http://127.0.0.1:18042/health
curl --noproxy '*' --fail-with-body --max-time 10 \
  http://127.0.0.1:18042/v1/models
curl --noproxy '*' --fail-with-body --max-time 180 \
  --write-out 'W8A8 first chat HTTP %{http_code}, %{time_total}s\n' \
  --output "$WORK_DIR/chat-response.json" \
  http://127.0.0.1:18042/v1/chat/completions \
  -H 'Content-Type: application/json' \
  --data '{"model":"minicpm5-w8a8","messages":[{"role":"user","content":"请只回答数字：1+1等于几？"}],"chat_template_kwargs":{"enable_thinking":false},"max_tokens":16,"temperature":0}'
python - <<'PY'
import json
import os
from pathlib import Path

work_dir = Path(os.environ["WORK_DIR"])
response = json.loads((work_dir / "chat-response.json").read_text())
assert response["choices"][0]["message"]["content"].strip() == "2"
assert response["usage"]["completion_tokens"] > 0
server_log = (work_dir / "server.log").read_text()
assert "Platform plugin fl is activated" in server_log
assert "Selected CPUInt8ScaledMMLinearKernel for CompressedTensorsW8A8Int8" in server_log
print("HTTP inference PASS", response["usage"], response["choices"][0]["message"]["content"])
PY
```

Keep the complete service log, HTTP response, model checksums, and test-suite output. Stop
terminal A with Ctrl-C after the request. This check is batch-one functional smoke; it does
not establish quality, long-context behavior, W8A8 FlagGems acceleration, or a CIX throughput
number. The 180-second client timeout is a regression guard for this reference test,
not a cross-machine performance target; record the printed first-chat duration.
To accept a future accelerated W8A8 route, require a selected-kernel log/trace,
numerical comparison against dequantized BF16, prefill and decode coverage, and no silent
fallback. Steps 7-9 below supply end-to-end W4A8 generation coverage with a distinct,
public checkpoint; the W8A8 model in Steps 4-6 cannot verify the W4A8 route.

### Step 7: Fetch and verify the public W4A8-G128 checkpoint

Run this after Step 3 to test the FlagGems W4A8 model route. Steps 4-6 are a separate W8A8
compatibility test. The release W4A8 files are at ModelScope revision
`f125bb2aa4c62cfbac922474176ccf705ef94518`. Both the weight and tokenizer are Git LFS
blobs; do not leave their pointer files in the model directory.

```bash
export W4_SOURCE="$HOME/Models/MiniCPM5-2B-W4A8-arm-FlagOS"
mkdir -p "$W4_SOURCE"
git init -q "$W4_SOURCE"
if ! git -C "$W4_SOURCE" remote get-url origin >/dev/null 2>&1; then
  git -C "$W4_SOURCE" remote add origin \
    https://www.modelscope.cn/FlagRelease/MiniCPM5-2B-W4A8-arm-FlagOS.git
fi
test "$(git -C "$W4_SOURCE" remote get-url origin)" = \
  https://www.modelscope.cn/FlagRelease/MiniCPM5-2B-W4A8-arm-FlagOS.git
GIT_LFS_SKIP_SMUDGE=1 git -C "$W4_SOURCE" fetch --depth 1 origin \
  f125bb2aa4c62cfbac922474176ccf705ef94518
GIT_LFS_SKIP_SMUDGE=1 git -C "$W4_SOURCE" checkout --detach \
  f125bb2aa4c62cfbac922474176ccf705ef94518
download_verified_lfs() {
  expected_sha=$1
  file_name=$2
  file_url=$3
  if (cd "$W4_SOURCE" && printf '%s  %s\n' "$expected_sha" "$file_name" |
      sha256sum -c - >/dev/null 2>&1); then
    echo "$file_name already verified"
    return
  fi
  if head -c 64 "$W4_SOURCE/$file_name" |
      grep -q '^version https://git-lfs.github.com/spec/v1'; then
    truncate -s 0 "$W4_SOURCE/$file_name"
  fi
  curl --fail --location --retry 3 --continue-at - \
    --output "$W4_SOURCE/$file_name" "$file_url"
  (cd "$W4_SOURCE" && printf '%s  %s\n' "$expected_sha" "$file_name" |
    sha256sum -c -)
}
download_verified_lfs \
  e6f8bf8cf7d9498f8dc8895f515c52531cdf90f79c0aad274c9e541b6ece79df \
  model-00000-of-00001.safetensors \
  'https://www.modelscope.cn/models/FlagRelease/MiniCPM5-2B-W4A8-arm-FlagOS/resolve/f125bb2aa4c62cfbac922474176ccf705ef94518/model-00000-of-00001.safetensors'
download_verified_lfs \
  3e065a558a034185fe299917b398685c1facd0169a9eea1e629eb30c171fed81 \
  tokenizer.json \
  'https://www.modelscope.cn/models/FlagRelease/MiniCPM5-2B-W4A8-arm-FlagOS/resolve/f125bb2aa4c62cfbac922474176ccf705ef94518/tokenizer.json'
test "$(git -C "$W4_SOURCE" rev-parse HEAD)" = \
  f125bb2aa4c62cfbac922474176ccf705ef94518
```

The public configuration declares `compressed-tensors` `int-quantized`, symmetric INT4 G128
body weights, dynamic symmetric per-token INT8 activations, and BF16 embeddings and
`lm_head`. It is the same MiniCPM5 model family, but a different checkpoint from the W8A8
release in Step 4. Keep the files from one revision together.
The download helper is safe to rerun: verified files are skipped, incomplete files are
resumed, and unresolved pointer files are replaced with the pinned LFS blob.
The resolved blobs can appear modified relative to Git's LFS pointer files; this is
expected when the explicit SHA256 checks pass.

### Step 8: Convert only the W4 storage layout to the plugin's packed format

This does **not** quantize BF16 weights. It packs each already-quantized signed INT4 weight
tensor into compressed-tensors int32 storage, checks exact recovery, keeps the original scales
and BF16 tensors, and changes the `format` labels required by PR #433. The source stays intact.

```bash
export WORK_DIR="$HOME/arm64-vllm024-test"
source "$WORK_DIR/.venv/bin/activate"
export W4_SOURCE="$HOME/Models/MiniCPM5-2B-W4A8-arm-FlagOS"
export W4_PACKED="$HOME/Models/MiniCPM5-2B-W4A8-arm-FlagOS-packed"
python - <<'PY'
import json
import hashlib
import os
import shutil
from pathlib import Path

import torch
from compressed_tensors.compressors.pack_quantized.helpers import pack_to_int32, unpack_from_int32
from safetensors import safe_open
from safetensors.torch import save_file

source = Path(os.environ["W4_SOURCE"])
packed_dir = Path(os.environ["W4_PACKED"])

def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(4 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

if packed_dir.exists() and any(packed_dir.iterdir()):
    weight_file = packed_dir / "model.safetensors"
    config_file = packed_dir / "config.json"
    tokenizer_file = packed_dir / "tokenizer.json"
    if weight_file.exists() and config_file.exists() and tokenizer_file.exists():
        packed_config = json.loads(config_file.read_text())
        packed_quant = packed_config["quantization_config"]
        packed_group = next(iter(packed_quant["config_groups"].values()))
        if (sha256(weight_file) ==
                "0bc220b3da79f4af1b77dc9231bf7dec417d0a0a8e344e41da6f3f502b76ac7e"
                and sha256(tokenizer_file) ==
                "3e065a558a034185fe299917b398685c1facd0169a9eea1e629eb30c171fed81"
                and packed_quant["format"] == packed_group["format"] == "pack-quantized"):
            print("existing lossless W4A8 test copy already verified", packed_dir)
            raise SystemExit(0)
    raise RuntimeError(f"incomplete W4A8 test copy: {packed_dir}; use an empty output directory")
for file in source.iterdir():
    if file.is_file():
        with file.open("rb") as handle:
            assert not handle.read(64).startswith(
                b"version https://git-lfs.github.com/spec/v1"
            ), f"unresolved Git LFS pointer: {file}"

config = json.loads((source / "config.json").read_text())
quant = config["quantization_config"]
group = next(iter(quant["config_groups"].values()))
weights, activations = group["weights"], group["input_activations"]
assert quant["format"] == "int-quantized"
assert group.get("format", quant["format"]) == "int-quantized"
assert weights["num_bits"] == 4 and weights["group_size"] == 128
assert weights["strategy"] == "group" and weights["symmetric"]
assert activations["num_bits"] == 8 and activations["strategy"] == "token"
assert activations["dynamic"]

output = {}
count = 0
with safe_open(source / "model-00000-of-00001.safetensors", framework="pt", device="cpu") as f:
    keys = set(f.keys())
    for name in sorted(keys):
        tensor = f.get_tensor(name)
        if name.endswith(".weight") and tensor.dtype == torch.int8:
            assert tensor.ndim == 2 and tensor.shape[0] % 4 == 0
            assert tensor.shape[1] % 128 == 0 and name + "_scale" in keys
            assert -8 <= int(tensor.min()) and int(tensor.max()) <= 7
            packed = pack_to_int32(tensor, 4)
            assert torch.equal(unpack_from_int32(packed, 4, tensor.shape), tensor), name
            stem = name.removesuffix(".weight")
            output[stem + ".weight_packed"] = packed.contiguous()
            output[stem + ".weight_shape"] = torch.tensor(tensor.shape, dtype=torch.int64)
            count += 1
        else:
            output[name] = tensor.contiguous()
assert count == config["num_hidden_layers"] * 7 == 294, count

packed_dir.mkdir(parents=True, exist_ok=True)
save_file(output, packed_dir / "model.safetensors")
quant["format"] = group["format"] = "pack-quantized"
(packed_dir / "config.json").write_text(json.dumps(config, indent=2) + "\n")
for file in source.iterdir():
    if file.is_file() and file.name not in {
        "model-00000-of-00001.safetensors", "model.safetensors.index.json", "config.json"
    }:
        shutil.copy2(file, packed_dir / file.name)
print("lossless W4A8 packing PASS", count, packed_dir)
PY
(cd "$W4_PACKED" && printf '%s  %s\n' \
  '0bc220b3da79f4af1b77dc9231bf7dec417d0a0a8e344e41da6f3f502b76ac7e' \
  'model.safetensors' | sha256sum -c -)
(cd "$W4_PACKED" && printf '%s  %s\n' \
  '3e065a558a034185fe299917b398685c1facd0169a9eea1e629eb30c171fed81' \
  'tokenizer.json' | sha256sum -c -)
```

If an LFS pointer is detected or the derived checksum differs, stop before starting vLLM.
The converted artifact is a **test copy**, not a new published FlagRelease revision.
Step 8 is safe to rerun against a completed, checksum-verified test copy. If conversion
was interrupted, use a new empty `$W4_PACKED` output directory before rerunning; the
source model remains untouched.

### Step 9: Prove FlagGems W4A8 is used, then test the HTTP service

Use a single-process offline audit so the Python call counters cover the model worker. The
checks require the FlagGems packer at load and the FlagGems W4A8 linear during the actual
request, beyond any warmup calls. On CIX P1 the 168 packed linears are vLLM's fused
projections of the 294 original quantized tensors.

```bash
export WORK_DIR="$HOME/arm64-vllm024-test"
source "$WORK_DIR/.venv/bin/activate"
cd "$WORK_DIR/vllm-plugin-FL"
export W4_PACKED="$HOME/Models/MiniCPM5-2B-W4A8-arm-FlagOS-packed"
export FLAGGEMS_VENDOR=arm TRITON_CPU_BACKEND=1 VLLM_PLUGINS=fl
export VLLM_ENABLE_V1_MULTIPROCESSING=0 VLLM_CPU_KVCACHE_SPACE=1
export VLLM_EXECUTE_MODEL_TIMEOUT_SECONDS=1800
export OMP_NUM_THREADS=8 MKL_NUM_THREADS=8
export A720_CORES=0,1,6,7,8,9,10,11
export VLLM_CPU_OMP_THREADS_BIND="$A720_CORES"
export TRITON_CACHE_DIR="$WORK_DIR/.cache/triton-2c35990"
mkdir -p "$TRITON_CACHE_DIR"
taskset -c "$A720_CORES" python - <<'PY'
import os
import flag_gems.quantized_linear as flag_linear
from vllm import LLM, SamplingParams

calls = {"pack": 0, "linear": 0}
original_pack = flag_linear.pack_rhs_qsi4c128p
original_linear = flag_linear.w4a8_g128_linear

def audited_pack(*args, **kwargs):
    calls["pack"] += 1
    return original_pack(*args, **kwargs)

def audited_linear(*args, **kwargs):
    calls["linear"] += 1
    return original_linear(*args, **kwargs)

flag_linear.pack_rhs_qsi4c128p = audited_pack
flag_linear.w4a8_g128_linear = audited_linear
llm = LLM(model=os.environ["W4_PACKED"], dtype="bfloat16", enforce_eager=True,
          max_model_len=256, max_num_batched_tokens=256, max_num_seqs=1)
assert calls["pack"] == 168, calls
before = calls["linear"]
output = llm.chat(
    messages=[{"role": "user", "content": "请只回答数字：1+1等于几？"}],
    sampling_params=SamplingParams(max_tokens=16, temperature=0.0),
    chat_template_kwargs={"enable_thinking": False},
)[0]
answer = output.outputs[0].text.strip()
assert answer == "2", answer
assert calls["linear"] - before == 336, calls
print("W4A8 FlagGems inference PASS", answer, calls,
      "inference_calls", calls["linear"] - before)
PY
```

For an HTTP smoke test, leave `VLLM_ENABLE_V1_MULTIPROCESSING` at its default and use the
same packed model. Start the service in terminal A; adjust core affinity on another Arm64
host. If an empty Triton cache still takes minutes with the Step 2 patch, save the worker
stack and compiler log rather than accepting it as expected cold-start behavior.

```bash
export WORK_DIR="$HOME/arm64-vllm024-test"
source "$WORK_DIR/.venv/bin/activate"
cd "$WORK_DIR/vllm-plugin-FL"
export W4_PACKED="$HOME/Models/MiniCPM5-2B-W4A8-arm-FlagOS-packed"
export FLAGGEMS_VENDOR=arm TRITON_CPU_BACKEND=1 VLLM_PLUGINS=fl
export OMP_NUM_THREADS=8 MKL_NUM_THREADS=8
export VLLM_CPU_KVCACHE_SPACE=1
export TRITON_CACHE_DIR="$WORK_DIR/.cache/triton-2c35990"
mkdir -p "$TRITON_CACHE_DIR"
unset VLLM_ENABLE_V1_MULTIPROCESSING
export A720_CORES=0,1,6,7,8,9,10,11
export VLLM_CPU_OMP_THREADS_BIND="$A720_CORES"
export VLLM_EXECUTE_MODEL_TIMEOUT_SECONDS=1800
set -o pipefail
taskset -c "$A720_CORES" vllm serve "$W4_PACKED" \
  --host 127.0.0.1 --port 18043 --served-model-name minicpm5-w4a8 \
  --dtype bfloat16 --enforce-eager --max-model-len 256 \
  --max-num-batched-tokens 256 --max-num-seqs 1 \
  --generation-config vllm --distributed-executor-backend uni \
  --disable-log-stats --language-model-only 2>&1 | tee "$WORK_DIR/w4a8-server.log"
```

In terminal B, send the same deterministic request and save its response:

```bash
export WORK_DIR="$HOME/arm64-vllm024-test"
source "$WORK_DIR/.venv/bin/activate"
curl --noproxy '*' --fail-with-body --max-time 10 \
  http://127.0.0.1:18043/health
curl --noproxy '*' --fail-with-body --max-time 10 \
  http://127.0.0.1:18043/v1/models
curl --noproxy '*' --fail-with-body --max-time 180 \
  --write-out 'W4A8 first chat HTTP %{http_code}, %{time_total}s\n' \
  --output "$WORK_DIR/w4a8-chat-response.json" \
  http://127.0.0.1:18043/v1/chat/completions \
  -H 'Content-Type: application/json' \
  --data '{"model":"minicpm5-w4a8","messages":[{"role":"user","content":"请只回答数字：1+1等于几？"}],"chat_template_kwargs":{"enable_thinking":false},"max_tokens":16,"temperature":0}'
python - <<'PY'
import json
import os
from pathlib import Path

response = json.loads((Path(os.environ["WORK_DIR"]) / "w4a8-chat-response.json").read_text())
assert response["choices"][0]["message"]["content"].strip() == "2"
assert response["usage"]["completion_tokens"] > 0
print("W4A8 HTTP inference PASS", response["usage"])
PY
```

On the reference CIX P1, the offline request produced 24 prompt and 2 completion tokens,
with 336 FlagGems W4A8 linear calls after warmup. The warm HTTP request returned 200 in
0.418 seconds in the latest fresh run. Save the source and derived checksums, offline
audit output, response, and service log. This verifies batch-one functional inference
through FlagGems; numerical
agreement with a BF16 reference, model-quality evaluation, long context, and a fully cold
source-dependency download remain separate acceptance checks. The release config declares
symmetric dynamic token activations, while FlagGems #5904's ARM kernels perform asymmetric
dynamic token quantization; quantify any accuracy impact before claiming full model correctness.

### Step 10: Measure a genuinely empty Triton cache for each model

Run this after both model directories exist and the Step 2 vLLM patch is applied. `mktemp -d`
creates a distinct empty Triton cache for each run; do not use the shared cache from Steps
5 and 9. The timer begins after Python package imports, then reports model initialization
and the first deterministic chat request separately. The shell's full process wall time will
also include Python/Torch/plugin imports. Bind the main process as well as OpenMP threads to
the chosen big cores, because LLVM JIT compilation runs on the main process.

```bash
export WORK_DIR="$HOME/arm64-vllm024-test"
source "$WORK_DIR/.venv/bin/activate"
mkdir -p "$WORK_DIR/.cache"
mkdir -p "$WORK_DIR/.test-scripts"
cd "$WORK_DIR/vllm-plugin-FL"
cat > "$WORK_DIR/.test-scripts/cold-model-smoke.py" <<'PY'
import json
import os
import time
from pathlib import Path

kind = os.environ["MODEL_KIND"]
cache = Path(os.environ["TRITON_CACHE_DIR"])
assert kind in {"w4", "w8"}, kind
assert cache.is_dir() and not any(cache.iterdir()), cache

from vllm import LLM, SamplingParams

calls = {"pack": 0, "linear": 0}
if kind == "w4":
    import flag_gems.quantized_linear as flag_linear

    original_pack = flag_linear.pack_rhs_qsi4c128p
    original_linear = flag_linear.w4a8_g128_linear

    def audited_pack(*args, **kwargs):
        calls["pack"] += 1
        return original_pack(*args, **kwargs)

    def audited_linear(*args, **kwargs):
        calls["linear"] += 1
        return original_linear(*args, **kwargs)

    flag_linear.pack_rhs_qsi4c128p = audited_pack
    flag_linear.w4a8_g128_linear = audited_linear

started = time.perf_counter()
llm = LLM(model=os.environ["MODEL_DIR"], dtype="bfloat16", enforce_eager=True,
          max_model_len=256, max_num_batched_tokens=256, max_num_seqs=1)
loaded = time.perf_counter()
if kind == "w4":
    assert calls["pack"] == 168, calls
before = calls["linear"]
output = llm.chat(
    messages=[{"role": "user", "content": "请只回答数字：1+1等于几？"}],
    sampling_params=SamplingParams(max_tokens=16, temperature=0),
    chat_template_kwargs={"enable_thinking": False},
)[0]
ended = time.perf_counter()
answer = output.outputs[0].text.strip()
assert answer == "2", answer
if kind == "w4":
    assert calls["linear"] - before == 336, calls
print(json.dumps({"model": kind, "answer": answer,
                  "model_init_s": round(loaded - started, 3),
                  "first_request_s": round(ended - loaded, 3),
                  "total_s": round(ended - started, 3),
                  "pack_calls": calls["pack"],
                  "request_linear_calls": calls["linear"] - before,
                  "cache": str(cache)}))
PY

export FLAGGEMS_VENDOR=arm TRITON_CPU_BACKEND=1 VLLM_PLUGINS=fl
export VLLM_ENABLE_V1_MULTIPROCESSING=0 VLLM_CPU_KVCACHE_SPACE=1
export VLLM_EXECUTE_MODEL_TIMEOUT_SECONDS=1800
export OMP_NUM_THREADS=8 MKL_NUM_THREADS=8
export A720_CORES=0,1,6,7,8,9,10,11
export VLLM_CPU_OMP_THREADS_BIND="$A720_CORES"
export MODEL_KIND=w8 MODEL_DIR="$HOME/Models/MiniCPM5-2B-W8A8-arm-FlagOS"
export TRITON_CACHE_DIR
set -o pipefail
TRITON_CACHE_DIR=$(mktemp -d "$WORK_DIR/.cache/cold-w8-XXXXXX")
taskset -c "$A720_CORES" python "$WORK_DIR/.test-scripts/cold-model-smoke.py" \
  2>&1 | tee "$WORK_DIR/cold-w8.log"
grep 'Selected CPUInt8ScaledMMLinearKernel for CompressedTensorsW8A8Int8' \
  "$WORK_DIR/cold-w8.log"

export MODEL_KIND=w4 MODEL_DIR="$HOME/Models/MiniCPM5-2B-W4A8-arm-FlagOS-packed"
TRITON_CACHE_DIR=$(mktemp -d "$WORK_DIR/.cache/cold-w4-XXXXXX")
taskset -c "$A720_CORES" python "$WORK_DIR/.test-scripts/cold-model-smoke.py" \
  2>&1 | tee "$WORK_DIR/cold-w4.log"
```

On the reference CIX P1 with the patch, W8A8 answered `2` with **12.773 s** model init
and **9.552 s** first request; W4A8 answered `2` with **22.140 s** model init,
**11.452 s** first request, 168 pack calls, and 336 request linear calls. These runs used
single-process offline inference, batch one and a 256-token context. A multi-minute result
after the patch is a regression to investigate, not an expected property of an empty cache.
Running the exact Step 10 shell block extracted from this FEP again gave W8A8
12.692 s init / **9.772 s** first request and W4A8 22.237 s init /
**11.629 s** first request, with the same answers, W8A8 selected-kernel log, and
W4A8 FlagGems counts.
The 2026-09-16 fresh source and virtual-environment reproduction below repeated the
exact Step 10 script with separate empty caches: W8A8 initialized in 12.826 s and
answered `2` in 9.614 s; W4A8 initialized in 21.867 s and answered `2` in 11.610 s,
with 168 pack calls and 336 request linear calls.

### Step 11: Measure warm 64-token generation speed

Run this after the functional tests, with one model server at a time. Use the same
CIX P1 A720 affinity and a populated Triton cache. The 43-token and 357-token prompt
cases below force 64 output tokens with `ignore_eos=true`; this measures sustained
generation separately from the two-token smoke test. These are single-user measurements,
not a concurrency or model-quality check.

In terminal A, launch the W4A8 server.

```bash
export WORK_DIR="$HOME/arm64-vllm024-test"
source "$WORK_DIR/.venv/bin/activate"
cd "$WORK_DIR/vllm-plugin-FL"
export FLAGGEMS_VENDOR=arm TRITON_CPU_BACKEND=1 VLLM_PLUGINS=fl
export VLLM_CPU_KVCACHE_SPACE=1 VLLM_EXECUTE_MODEL_TIMEOUT_SECONDS=1800
export OMP_NUM_THREADS=8 MKL_NUM_THREADS=8
export A720_CORES=0,1,6,7,8,9,10,11
export VLLM_CPU_OMP_THREADS_BIND="$A720_CORES"
export TRITON_CACHE_DIR="$WORK_DIR/.cache/triton-2c35990"
mkdir -p "$TRITON_CACHE_DIR"
export PERF_MODEL_PATH="$HOME/Models/MiniCPM5-2B-W4A8-arm-FlagOS-packed"
export PERF_MODEL_NAME=minicpm5-w4a8-perf PERF_PORT=18048
set -o pipefail
taskset -c "$A720_CORES" vllm serve "$PERF_MODEL_PATH" \
  --host 127.0.0.1 --port "$PERF_PORT" \
  --served-model-name "$PERF_MODEL_NAME" \
  --dtype bfloat16 --enforce-eager --max-model-len 1024 \
  --max-num-batched-tokens 1024 --max-num-seqs 1 \
  --no-enable-prefix-caching --generation-config vllm \
  --distributed-executor-backend uni --disable-log-stats \
  --language-model-only 2>&1 | tee "$WORK_DIR/$PERF_MODEL_NAME-server.log"
```

After the W4A8 client finishes, stop terminal A with Ctrl-C. Then start the W8A8
server in terminal A with these exact values:

```bash
export WORK_DIR="$HOME/arm64-vllm024-test"
source "$WORK_DIR/.venv/bin/activate"
cd "$WORK_DIR/vllm-plugin-FL"
export FLAGGEMS_VENDOR=arm TRITON_CPU_BACKEND=1 VLLM_PLUGINS=fl
export VLLM_CPU_KVCACHE_SPACE=1 VLLM_EXECUTE_MODEL_TIMEOUT_SECONDS=1800
export OMP_NUM_THREADS=8 MKL_NUM_THREADS=8
export A720_CORES=0,1,6,7,8,9,10,11
export VLLM_CPU_OMP_THREADS_BIND="$A720_CORES"
export TRITON_CACHE_DIR="$WORK_DIR/.cache/triton-2c35990"
export PERF_MODEL_PATH="$HOME/Models/MiniCPM5-2B-W8A8-arm-FlagOS"
export PERF_MODEL_NAME=minicpm5-w8a8-perf PERF_PORT=18049
set -o pipefail
taskset -c "$A720_CORES" vllm serve "$PERF_MODEL_PATH" \
  --host 127.0.0.1 --port "$PERF_PORT" \
  --served-model-name "$PERF_MODEL_NAME" \
  --dtype bfloat16 --enforce-eager --max-model-len 1024 \
  --max-num-batched-tokens 1024 --max-num-seqs 1 \
  --no-enable-prefix-caching --generation-config vllm \
  --distributed-executor-backend uni --disable-log-stats \
  --language-model-only 2>&1 | tee "$WORK_DIR/$PERF_MODEL_NAME-server.log"
```

In terminal B, create the client once and run it against each ready server. Use
`/health` first; the script emits five raw JSONL records plus warm medians. The first
short run is excluded from the warm median because it can still compile a new request
shape. The decode rate uses the 63 inter-token intervals between 64 output tokens.

```bash
export WORK_DIR="$HOME/arm64-vllm024-test"
source "$WORK_DIR/.venv/bin/activate"
mkdir -p "$WORK_DIR/.test-scripts"
cat > "$WORK_DIR/.test-scripts/arm-perf-client.py" <<'PY'
import argparse
import json
import statistics
import time
import urllib.request
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--port", type=int, required=True)
parser.add_argument("--model", required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()

opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
short_base = "请用中文详述在 ARM CPU 上运行量化语言模型的三个主要性能瓶颈，并逐项给出工程处理方法。"
context = "在 ARM CPU 上部署量化语言模型，需要评估加载时间、首 token 延迟、持续生成速度、内存占用和并发能力。"
long_base = context * 12 + "请根据上述背景综合说明如何评估一个量化模型服务的可用性。"
cases = [("short", short_base, 1), ("short", short_base, 2),
         ("short", short_base, 3), ("long", long_base, 1),
         ("long", long_base, 2)]
records = []
for kind, base, run in cases:
    prompt = f"样本编号 {kind}-{run}。" + base
    payload = {
        "model": args.model,
        "messages": [{"role": "user", "content": prompt}],
        "chat_template_kwargs": {"enable_thinking": False},
        "max_tokens": 64,
        "ignore_eos": True,
        "temperature": 0,
        "stream": True,
        "stream_options": {"include_usage": True},
    }
    request = urllib.request.Request(
        f"http://127.0.0.1:{args.port}/v1/chat/completions",
        data=json.dumps(payload, ensure_ascii=False).encode(),
        headers={"Content-Type": "application/json"}, method="POST",
    )
    started = time.perf_counter()
    first_content = last_content = usage = None
    chunks = 0
    with opener.open(request, timeout=180) as response:
        assert response.status == 200, response.status
        for raw in response:
            line = raw.decode("utf-8").strip()
            if not line.startswith("data:"):
                continue
            data = line[5:].strip()
            if data == "[DONE]":
                break
            item = json.loads(data)
            if item.get("usage"):
                usage = item["usage"]
            for choice in item.get("choices", []):
                content = choice.get("delta", {}).get("content")
                if content:
                    now = time.perf_counter()
                    if first_content is None:
                        first_content = now
                    last_content = now
                    chunks += 1
    ended = time.perf_counter()
    assert usage is not None and usage["completion_tokens"] == 64, usage
    assert first_content is not None and last_content is not None
    assert chunks == 64, f"expected one content chunk per output token, got {chunks}"
    elapsed_decode = last_content - first_content
    record = {
        "model": args.model, "case": kind, "run": run,
        "prompt_tokens": usage["prompt_tokens"],
        "completion_tokens": usage["completion_tokens"],
        "ttft_s": round(first_content - started, 3),
        "total_s": round(ended - started, 3),
        "decode_tok_per_s": round(63 / elapsed_decode, 2)
        if elapsed_decode > 0 else None,
        "content_chunks": chunks,
    }
    records.append(record)
    print(json.dumps(record, ensure_ascii=False), flush=True)
args.output.write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in records) + "\n")
for kind in ("short", "long"):
    warm = [r for r in records if r["case"] == kind
            and not (kind == "short" and r["run"] == 1)]
    print(kind, "warm median TTFT",
          round(statistics.median(r["ttft_s"] for r in warm), 3),
          "s, total", round(statistics.median(r["total_s"] for r in warm), 3),
          "s, decode",
          round(statistics.median(r["decode_tok_per_s"] for r in warm), 2),
          "tok/s", flush=True)
PY

curl --noproxy '*' --fail-with-body --max-time 10 \
  http://127.0.0.1:18048/health
python "$WORK_DIR/.test-scripts/arm-perf-client.py" \
  --port 18048 --model minicpm5-w4a8-perf \
  --output "$WORK_DIR/w4a8-perf.jsonl"
```

After the W8A8 server reports ready, run this separate block in terminal B:

```bash
export WORK_DIR="$HOME/arm64-vllm024-test"
source "$WORK_DIR/.venv/bin/activate"
curl --noproxy '*' --fail-with-body --max-time 10 \
  http://127.0.0.1:18049/health
python "$WORK_DIR/.test-scripts/arm-perf-client.py" \
  --port 18049 --model minicpm5-w8a8-perf \
  --output "$WORK_DIR/w8a8-perf.jsonl"
```

In the latest fresh CIX P1 environment, all five requests for each model returned
64 output tokens in 64 streamed content chunks. Warm median decoding for
43-input/64-output and 357-input/64-output requests was **7.73/7.62 token/s W4A8**
and **4.69/4.63 token/s W8A8**. The W8A8 service selected
`CPUInt8ScaledMMLinearKernel`; this is a native CPU INT8 baseline, not an accelerated
FlagGems W8A8 result. Do not use the two-token math smoke timings as throughput.

### Fresh CIX P1 full reproduction (2026-09-16, Python 3.11.13)

| Check | Observed result |
|---|---|
| Test environment and build | All four exact source commits, pinned LLVM/SLEEF, ACL `v52.6.0` and oneDNN `9c5be1...` verified. Fresh FlagTree and vLLM CPU native builds passed; ACL was prebuilt with four jobs and reused incrementally. `vllm._C` imported; `CpuPlatform`, Triton `3.7.2`, and vLLM `0.24.0+cpu` verified. |
| Independent operators | FlagGems #5904 W4A8-G128 **7 passed, 0 skipped**; plugin #433 ARM CPU/GDN/W4A8 **16 passed, 0 skipped**. |
| Public models and W4A8 conversion | Both ModelScope release weight/tokenizer SHA256 checks passed after full downloads; 294 public W4A8 INT4 tensors were packed and exactly recovered; the derived weight SHA256 matched. Repeat downloads and conversion verified the existing outputs. |
| W8A8 HTTP, `max-model-len=512` | Native `CPUInt8ScaledMMLinearKernel` selected; `/health`, `/v1/models`, and math chat HTTP 200; answer `2`, 24 prompt/2 completion tokens. First chat after server readiness took **8.533 s**. |
| W4A8 audited offline and HTTP | 168 FlagGems pack calls at load and 336 `w4a8_g128_linear` calls during the math request; answer `2`. Shared-cache HTTP chat returned 200 and `2` in **0.418 s**. |
| Separate genuinely empty Triton caches, exact Step 10 | W8A8 model init **12.826 s**, first request **9.614 s**; W4A8 init **21.867 s**, first request **11.610 s**. Both answered `2`; the W4A8 FlagGems call counts and W8A8 native-kernel log matched. |
| W4A8 warm HTTP, 43/357 input and 64 output tokens | Median TTFT **0.508/2.362 s**; total **8.660/10.631 s**; decode **7.73/7.62 token/s**. |
| W8A8 warm HTTP, 43/357 input and 64 output tokens | Median TTFT **0.369/1.540 s**; total **13.808/15.136 s**; decode **4.69/4.63 token/s**. |

The four source commits and local patch can be rebuilt into a functional test environment
using Steps 0–11. The approximately 38-minute FlagTree build and 11.5-minute vLLM build
are installation costs, distinct from the model initialization and first-request figures.
On this host, the W8A8 baseline is slower than W4A8 for single-user decoding, and neither
throughput result establishes production performance. The two-token math check does not
validate general model quality or numerical agreement with a BF16 reference.

### CIX P1 source-environment test record (2026-09-15)

| Check | Observed result |
|---|---|
| Source and model SHA pins | All four source commits, ModelScope `e53463a...`, weight and tokenizer SHA256 matched |
| FlagTree CPU target and kernel | Triton `3.7.2`, target `cpu/aarch64`; vector add passed |
| FlagGems #5904 W4A8-G128 | 7 passed, 0 skipped |
| Plugin #433 ARM registration/W4A8/GDN | 16 passed, 0 skipped |
| MiniCPM5 W8A8 load | `LlamaForCausalLM`, `compressed-tensors`, CPU platform; selected `CPUInt8ScaledMMLinearKernel` |
| HTTP service | `/health` and `/v1/models` HTTP 200 |
| First chat request, empty Triton cache, unpatched vLLM | HTTP 200 after 931.6 seconds; 19 prompt and 27 completion tokens, non-empty text |
| Warm deterministic math request | HTTP 200 in 0.396 seconds; 24 prompt and 2 completion tokens, content `2` |
| Public W4A8 model identity | ModelScope `f125bb2...`; release weight and tokenizer SHA256 matched |
| W4A8 storage conversion | All 294 original INT4 tensors packed and exactly recovered; derived weight SHA256 `0bc220b3...` |
| W4A8 audited offline inference | 168 FlagGems packed linears; 336 linear calls during a 24-prompt, 2-completion-token request; answer `2` |
| W4A8 HTTP service | `/health`, `/v1/models`, and math chat HTTP 200; answer `2`; warm request 0.411 seconds |

The first open-ended request asked for a one-sentence FlagOS description. Its answer was
factually wrong, so non-empty generation is recorded as a **functional** pass only. The
deterministic math request above supplies a minimal answer check; no BF16 comparison,
perplexity, or broader model-quality evaluation was run. Live worker sampling during the unpatched
931.6-second request showed `make_asm -> compute_slot_mappings` in vLLM's CPU attention path.
This cold compilation latency is a test-environment observation, not a steady-state model
throughput figure.

### Fresh CIX P1 reproduction (2026-09-15, Python 3.11.13)

| Check | Observed result |
|---|---|
| Fresh source and venv installation | All four exact source commits fetched; FlagTree CPU and vLLM CPU native extensions rebuilt; PyTorch `2.11.0+cpu`, Triton `3.7.2`, vLLM `0.24.0+cpu`, `CpuPlatform` verified. Pinned LLVM/NVIDIA build caches and local Arm ComputeLibrary `v52.6.0`/oneDNN `9c5be1...` sources were reused after transfer failures. |
| FEP-0082 FlagTree check | Fixed source and LLVM hashes, `cpu/aarch64` target, and vector add passed. |
| Operator tests | FlagGems W4A8-G128 **7 passed, 0 skipped**; plugin ARM registration/GDN/W4A8 **16 passed, 0 skipped**. |
| Model artifacts | Both public W8A8 and W4A8 release weight/tokenizer SHA256 checks passed in new model directories; W4A8 294-tensor lossless repack and derived SHA256 passed. |
| W4A8 audited inference, empty request JIT cache, unpatched vLLM | 24 prompt/2 completion tokens, answer `2`; 168 FlagGems pack calls at load, 336 W4A8 linear calls in the actual request; first request **915.78 seconds**. |
| W4A8 HTTP | `/health`, `/v1/models`, and math chat HTTP 200; answer `2`; all three client checks took 0.51 seconds, repeated chat 0.332 seconds. |
| W8A8 HTTP | Selected `CPUInt8ScaledMMLinearKernel`, all three endpoints HTTP 200, math answer `2`; client checks took 0.56 seconds after the W4A8 CPU-attention JIT cache was populated. |

The first unpatched W4A8 request was sampled inside vLLM's CPU attention
`compute_slot_mappings -> triton/backends/cpu/compiler.py::make_asm`. A 915.78-second
cold request is a material performance issue despite functional success. The warm timings
cover a 24-prompt, 2-completion-token smoke request and cannot establish model throughput.
Measure cold startup, time to first token, and decode throughput separately before any
performance acceptance. The Ctrl-C API-server shutdown emitted resource-tracker warnings
about semaphores and shared memory; this did not affect the successful HTTP requests.

### CPU cold-JIT diagnosis and patched reproduction (2026-09-16)

The empty-cache stall was traced to GPU-sized Triton launches reused by vLLM's CPU worker,
not to MiniCPM5 weight loading or the FlagGems W4A8 matrix multiply. A targeted
`_compute_slot_mappings_kernel` compile with block size 1024 spent 289.617 s in FlagTree
CPU's `make_asm` on a Cortex-A720; with block size 128 it spent 0.663 s. The old LLVM IR
included 1024-wide integer division and masked memory operations. A ten-second `perf`
sample of compilation was dominated by LLVM live-range and register-allocation routines.
After fixing slot mapping alone, an empty request next stalled at block-table gather; after
fixing both, a truly empty Triton cache exposed gumbel sampling, staged KV writes, input
preparation, and the nonzero-temperature path. The linked Step 2 patch gives these eight
CPU call sites block size 128 and preserves their original GPU values.

| Check, fully empty Triton cache unless noted | Observed result on CIX P1 |
|---|---|
| Patch identity | `a2f53cae6a5759590c4637378f673b7c4edb23986f8f51ffe811a14058027959`; applies cleanly to vLLM `ee0da84...` |
| W4A8 deterministic chat, patched | Model init 22.140 s; first request **11.452 s**; answer `2`; 168 FlagGems pack and 336 request W4A8 linear calls |
| W8A8 deterministic chat, patched | Model init 12.773 s; first request **9.552 s**; answer `2`; native `CPUInt8ScaledMMLinearKernel` |
| Exact FEP Step 10 rerun, W4A8/W8A8 | Separate empty caches; W4A8 init 22.237 s / request **11.629 s**; W8A8 init 12.692 s / request **9.772 s**; both answered `2` |
| W4A8/W8A8 first HTTP chat after fresh server readiness | Separate empty caches and default vLLM multiprocessing; W4A8 HTTP 200 / answer `2` in **10.086 s**; W8A8 HTTP 200 / answer `2` in **8.406 s** |
| W4A8 temperature 0.7, seeded, isolated new temperature JIT | `_temperature_kernel` ASM 0.298 s; first request 3.847 s; non-empty 16-token answer and 2688 request W4A8 linear calls |
| W4A8 warm HTTP, 43-input/64-output tokens | Median first content token 0.518 s, total 8.759 s, decode **7.64 token/s** |
| W4A8 warm HTTP, 357-input/64-output tokens | Median first content token 2.370 s, total 10.790 s, decode **7.48 token/s** |

The warm HTTP figures used five single-user streamed requests with `ignore_eos=true`,
`--max-model-len 1024`, and the eight A720 cores. They are comparable to the unpatched
7.50/7.40 token/s runs: the cold-JIT patch did not materially change warm throughput.
In the fresh HTTP runs, the service became ready about 58 s (W8A8) or 68 s (W4A8)
after its first vLLM log. That process startup includes multiprocess imports, model
loading, and warmup. Both fresh HTTP runs used a 256-token maximum context; the W8A8
Step 5 smoke uses 512. The 8.406/10.086-second HTTP figures begin **after** `/health`
returned 200 and measure the first chat request only. Keep startup and first-request
limits separate in acceptance.
The tested CPU patch is a local source fix; it still requires upstream review and does not
cover all optional vLLM sampling features, concurrent requests, longer contexts, or model
quality. Keep those items in performance and correctness acceptance rather than calling
the toolchain production-ready from a two-token answer.

## Related PRs

- [x] [vllm-plugin-FL #433](https://github.com/flagos-ai/vllm-plugin-FL/pull/433) — ARM CPU packed W4A8 and GDN integration; merged 2026-09-09.
- [x] [FlagGems #5904](https://github.com/flagos-ai/FlagGems/pull/5904) — ARM W4A8-G128 API; merged.
- [ ] [`flagtree-cpu/triton_v3.7.x`](https://github.com/flagos-ai/flagtree-cpu/tree/triton_v3.7.x) at `2c35990a...` — CPU compiler baseline under FEP-0082 acceptance.
- [ ] Follow-up ARM CPU W8A8 optimized plugin/operator implementation, if this remains a FlagOS 2.2 goal.

## Implementation History

- 2026-07-29: Initial proposal included prototype mode flags and native assets for vLLM 0.20.2.
- 2026-09-15: Updated to the current vLLM 0.24, plugin #433, FlagGems #5904, and FlagTree
  CPU 3.7.2 revisions. On CIX P1, FlagGems W4A8 tests passed 7/7 and plugin ARM tests passed
  16/16. The published W8A8 checkpoint loaded with the native vLLM CPU INT8 kernel and
  completed HTTP inference. The test record above separates cold JIT, warm inference, and
  the remaining W8A8 FlagGems acceleration and quality acceptance work.
- 2026-09-15: Public MiniCPM5 W4A8 release weight and tokenizer were pinned and verified.
  A losslessly repacked test copy completed audited offline inference via FlagGems W4A8 and
  OpenAI-compatible HTTP inference on CIX P1. The published `int-quantized` file itself
  still needs the Step 8 storage conversion for PR #433's packed CPU adapter.
- 2026-09-16: Isolated vLLM CPU Triton launch sizes as the cause of the multi-minute
  empty-cache request. Added a SHA-pinned CPU-only source patch and a two-model cold-cache
  regression step. On CIX P1, patched W4A8/W8A8 first requests completed in 11.452/9.552
  seconds after model initialization. Fresh multiprocess HTTP first requests also returned
  `2` in 10.086/8.406 seconds after readiness; W4A8 warm decoding remained about
  7.6 token/s.

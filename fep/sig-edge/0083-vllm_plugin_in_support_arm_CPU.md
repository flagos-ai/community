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
With the Step 2 CPU JIT patch and an empty Triton cache, the same deterministic W4A8
request finished in 11.452 seconds after model initialization; W8A8 finished in 9.552
seconds. These first-request times replace the previously observed 915.78/931.6-second
unpatched cold-cache behavior for the tested configuration. They do not establish a
production throughput target: warm W4A8 decoding measured about 7.6 token/s on one CIX P1.

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
`libnuma-dev`, `libtcmalloc-minimal4`, and `pipx` first. Do not put a clone called `vllm`
in Python's current import directory during package verification.

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
  git init -q "$WORK_DIR/$repo_dir"
  git -C "$WORK_DIR/$repo_dir" remote add origin "$repo_url"
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
  'https://raw.githubusercontent.com/kevinzs2048/community/vllm-arm64/fep/sig-edge/patches/vllm-0.24.0-arm-cold-jit-128.patch'
printf '%s  %s\n' \
  'a2f53cae6a5759590c4637378f673b7c4edb23986f8f51ffe811a14058027959' \
  "$WORK_DIR/vllm-arm-cold-jit.patch" | sha256sum -c -
if git -C "$WORK_DIR/vllm" apply --reverse --check \
  "$WORK_DIR/vllm-arm-cold-jit.patch"; then
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

export BUILD_JOBS=4
TRITON_HOME="$WORK_DIR/.triton-build" TRITON_BUILD_PROTON=OFF MAX_JOBS="$BUILD_JOBS" \
  uv pip install --no-build-isolation --constraint "$WORK_DIR/constraints.txt" \
  --editable "$WORK_DIR/flagtree-cpu"
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
release wheel and image publication are separate work. The vLLM CPU build also fetches
Arm ComputeLibrary tag `v52.6.0` and oneDNN commit
`9c5be1cc59e368aebf0909e6cf20f981ea61462a` unless compatible local source caches
are supplied through the `ACL_ROOT_DIR` environment variable and CMake's
`FETCHCONTENT_SOURCE_DIR_ONEDNN` variable (via `CMAKE_ARGS`).
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
git -C "$MODEL_DIR" remote add origin \
  https://www.modelscope.cn/FlagRelease/MiniCPM5-2B-W8A8-arm-FlagOS.git
GIT_LFS_SKIP_SMUDGE=1 git -C "$MODEL_DIR" fetch --depth 1 origin \
  e53463a1587ac1a3446efc761c50652a1306ef5e
GIT_LFS_SKIP_SMUDGE=1 git -C "$MODEL_DIR" checkout --detach \
  e53463a1587ac1a3446efc761c50652a1306ef5e
truncate -s 0 "$MODEL_DIR/model-00000-of-00001.safetensors" "$MODEL_DIR/tokenizer.json"
curl --fail --location --retry 3 --continue-at - --output \
  "$MODEL_DIR/model-00000-of-00001.safetensors" \
  'https://www.modelscope.cn/models/FlagRelease/MiniCPM5-2B-W8A8-arm-FlagOS/resolve/e53463a1587ac1a3446efc761c50652a1306ef5e/model-00000-of-00001.safetensors'
curl --fail --location --retry 3 --continue-at - --output "$MODEL_DIR/tokenizer.json" \
  'https://www.modelscope.cn/models/FlagRelease/MiniCPM5-2B-W8A8-arm-FlagOS/resolve/e53463a1587ac1a3446efc761c50652a1306ef5e/tokenizer.json'
(cd "$MODEL_DIR" && printf '%s  %s\n' \
  'ce27c62b10b4e7bbecbf84b7c820d3b293f9f7ff93a5963aecd785009abda905' \
  'model-00000-of-00001.safetensors' | sha256sum -c -)
(cd "$MODEL_DIR" && printf '%s  %s\n' \
  '3e065a558a034185fe299917b398685c1facd0169a9eea1e629eb30c171fed81' \
  'tokenizer.json' | sha256sum -c -)
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
curl --noproxy '*' --fail-with-body --max-time 1800 \
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
number. To accept a future accelerated W8A8 route, require a selected-kernel log/trace,
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
git -C "$W4_SOURCE" remote add origin \
  https://www.modelscope.cn/FlagRelease/MiniCPM5-2B-W4A8-arm-FlagOS.git
GIT_LFS_SKIP_SMUDGE=1 git -C "$W4_SOURCE" fetch --depth 1 origin \
  f125bb2aa4c62cfbac922474176ccf705ef94518
GIT_LFS_SKIP_SMUDGE=1 git -C "$W4_SOURCE" checkout --detach \
  f125bb2aa4c62cfbac922474176ccf705ef94518
truncate -s 0 "$W4_SOURCE/model-00000-of-00001.safetensors" "$W4_SOURCE/tokenizer.json"
curl --fail --location --retry 3 --continue-at - --output \
  "$W4_SOURCE/model-00000-of-00001.safetensors" \
  'https://www.modelscope.cn/models/FlagRelease/MiniCPM5-2B-W4A8-arm-FlagOS/resolve/f125bb2aa4c62cfbac922474176ccf705ef94518/model-00000-of-00001.safetensors'
curl --fail --location --retry 3 --continue-at - --output "$W4_SOURCE/tokenizer.json" \
  'https://www.modelscope.cn/models/FlagRelease/MiniCPM5-2B-W4A8-arm-FlagOS/resolve/f125bb2aa4c62cfbac922474176ccf705ef94518/tokenizer.json'
(cd "$W4_SOURCE" && printf '%s  %s\n' \
  'e6f8bf8cf7d9498f8dc8895f515c52531cdf90f79c0aad274c9e541b6ece79df' \
  'model-00000-of-00001.safetensors' | sha256sum -c -)
(cd "$W4_SOURCE" && printf '%s  %s\n' \
  '3e065a558a034185fe299917b398685c1facd0169a9eea1e629eb30c171fed81' \
  'tokenizer.json' | sha256sum -c -)
test "$(git -C "$W4_SOURCE" rev-parse HEAD)" = \
  f125bb2aa4c62cfbac922474176ccf705ef94518
```

The public configuration declares `compressed-tensors` `int-quantized`, symmetric INT4 G128
body weights, dynamic symmetric per-token INT8 activations, and BF16 embeddings and
`lm_head`. It is the same MiniCPM5 model family, but a different checkpoint from the W8A8
release in Step 4. Keep the files from one revision together.

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
import os
import shutil
from pathlib import Path

import torch
from compressed_tensors.compressors.pack_quantized.helpers import pack_to_int32, unpack_from_int32
from safetensors import safe_open
from safetensors.torch import save_file

source = Path(os.environ["W4_SOURCE"])
packed_dir = Path(os.environ["W4_PACKED"])
assert not packed_dir.exists() or not any(packed_dir.iterdir()), packed_dir
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
```

If an LFS pointer is detected or the derived checksum differs, stop before starting vLLM.
The converted artifact is a **test copy**, not a new published FlagRelease revision.

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
curl --noproxy '*' --fail-with-body --max-time 1800 \
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
0.411 seconds. Save the source and derived checksums, offline audit output, response, and
service log. This verifies batch-one functional inference through FlagGems; numerical
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
| W4A8 temperature 0.7, seeded, isolated new temperature JIT | `_temperature_kernel` ASM 0.298 s; first request 3.847 s; non-empty 16-token answer and 2688 request W4A8 linear calls |
| W4A8 warm HTTP, 43-input/64-output tokens | Median first content token 0.518 s, total 8.759 s, decode **7.64 token/s** |
| W4A8 warm HTTP, 357-input/64-output tokens | Median first content token 2.370 s, total 10.790 s, decode **7.48 token/s** |

The warm HTTP figures used five single-user streamed requests with `ignore_eos=true`,
`--max-model-len 1024`, and the eight A720 cores. They are comparable to the unpatched
7.50/7.40 token/s runs: the cold-JIT patch did not materially change warm throughput.
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
  seconds after model initialization; W4A8 warm decoding remained about 7.6 token/s.

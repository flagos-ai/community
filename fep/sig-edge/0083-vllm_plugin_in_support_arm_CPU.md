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
and serving API. The current implementation candidate is
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

The FlagGems commit is the merged #5904 head. The plugin commit is the current #433 head;
PR #433 is still open. Record all four `git rev-parse HEAD` outputs in the test report.
`flagtree-cpu` revision `2c35990a...` is required: the earlier `77433cf...` checkout fails
six of seven ARM W4A8 numerical tests.

### Step 2: Install the CPU packages

```bash
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
32 GiB. These are source/editable test packages; release wheel and image publication are
separate work.

## Test Plan

**(Required)** Run all steps, save the commands and logs, and report passed/skipped/failed
counts. The FlagGems and plugin suites verify the W4A8 implementation independently of the
MiniCPM5 W8A8 model test.

### Step 3: Verify the installed CPU platform and run operator tests

```bash
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
  'https://www.modelscope.cn/models/FlagRelease/MiniCPM5-2B-W8A8-arm-FlagOS/resolve/master/model-00000-of-00001.safetensors'
curl --fail --location --retry 3 --continue-at - --output "$MODEL_DIR/tokenizer.json" \
  'https://www.modelscope.cn/models/FlagRelease/MiniCPM5-2B-W8A8-arm-FlagOS/resolve/master/tokenizer.json'
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
Cold Triton JIT may take many minutes, including after `--enforce-eager`. On the reference
board the first request compiled vLLM's CPU attention slot-mapping kernel in
`triton/backends/cpu/compiler.py::make_asm`; this was observed from the live worker stack,
not inferred from HTTP latency alone.

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
fallback. A compatible packed W4A8 checkpoint also needs end-to-end generation coverage
before the full FEP is marked `Implemented`.

### CIX P1 source-environment test record (2026-09-15)

| Check | Observed result |
|---|---|
| Source and model SHA pins | All four source commits, ModelScope `e53463a...`, weight and tokenizer SHA256 matched |
| FlagTree CPU target and kernel | Triton `3.7.2`, target `cpu/aarch64`; vector add passed |
| FlagGems #5904 W4A8-G128 | 7 passed, 0 skipped |
| Plugin #433 ARM registration/W4A8/GDN | 16 passed, 0 skipped |
| MiniCPM5 W8A8 load | `LlamaForCausalLM`, `compressed-tensors`, CPU platform; selected `CPUInt8ScaledMMLinearKernel` |
| HTTP service | `/health` and `/v1/models` HTTP 200 |
| First chat request, empty Triton cache | HTTP 200 after 931.6 seconds; 19 prompt and 27 completion tokens, non-empty text |
| Warm deterministic math request | HTTP 200 in 0.396 seconds; 24 prompt and 2 completion tokens, content `2` |

The first open-ended request asked for a one-sentence FlagOS description. Its answer was
factually wrong, so non-empty generation is recorded as a **functional** pass only. The
deterministic math request above supplies a minimal answer check; no BF16 comparison,
perplexity, or broader model-quality evaluation was run. Live worker sampling during the
931.6-second request showed `make_asm -> compute_slot_mappings` in vLLM's CPU attention path.
This cold compilation latency is a test-environment observation, not a steady-state model
throughput figure.

## Related PRs

- [ ] [vllm-plugin-FL #433](https://github.com/flagos-ai/vllm-plugin-FL/pull/433) — ARM CPU packed W4A8 and GDN integration; open.
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

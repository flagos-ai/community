# FEP-0015: Arm64 CPU Backend for FlagOS (TLE + Triton-CPU)

**Status:** `Implemented`

**Created:** 2026-05-27

**Owner:** @kevinzs2048

**SIG:** sig-edge

**Target Version:** FlagOS 2.1

---

## Summary

This feature brings first-class **Arm64 CPU** support to the FlagOS compiler stack, enabling
FlagTree's Triton kernels and FlagGems operators to compile and run efficiently on Arm CPUs,
**entirely based on open-source compiler infrastructure with no dependency on vendor-proprietary
operator libraries**.

- **Compiler layer**: Arm64 TLE (Triton Language Extensions) capabilities are provided as a
  standalone plugin (`third_party/tle_arm64/`) within FlagTree, following the same plugin
  organization as other hardware backends (e.g., DSA's `third_party/tle/`). Triton-CPU serves
  as the underlying compiler substrate.
- **Operator layer**: Key inference operators (GEMV, Fused MLP, Flash-Attention Decode,
  RMSNorm, etc.) are packaged as TLE extended operations and contributed back to FlagTree.

This extends FlagOS's "write once, deploy across backends" capability from cloud-side
accelerators to Arm CPU edge scenarios.

Related repositories:
- FlagTree: https://github.com/flagos-ai/FlagTree
- TLE design document: https://github.com/flagos-ai/FlagTree/wiki/TLE
- flagtree-cpu (C++ extension layer, renamed from triton-cpu): https://github.com/flagos-ai/flagtree-cpu
- FlagGems (`5.3.0-rc2` release branch): https://github.com/flagos-ai/FlagGems/tree/5.3.0-rc2

## Motivation

AI inference is shifting from the cloud to the edge — smart terminals, intelligent cockpits,
embodied AI. Arm64 is the dominant CPU architecture in the edge domain, but FlagOS currently
targets cloud-side accelerators and lacks a CPU path. Without a CPU path, any Arm deployment
must fall back to hand-written, vendor-specific C kernels — exactly the kind of fragmentation
FlagOS aims to eliminate.

This FEP fills that gap by making Arm64 a supported FlagOS backend through the open-source
compiler stack.

### Goals

1. Enable FlagTree to compile Triton kernels to Arm64 CPU via the Triton-CPU compiler substrate.
2. Provide Arm64 TLE as a standalone plugin (`third_party/tle_arm64/`) within FlagTree.
3. Package key inference operators as TLE extended operations and contribute them to FlagTree.
4. Provide runtime feature detection (CPU topology, ISA capabilities) to automatically
   configure the execution environment.

### Non-Goals

- NPU / GPU backends (Ascend, Hexagon, etc.) — tracked separately.
- Sub-byte (INT4) quantization — the minimum precision in this FEP is INT8; INT4 is a
  follow-up extension.
- Windows-on-Arm / macOS (Apple Silicon) — limited to Linux/AArch64.
- SME2 support — follow-up extension.
- SVE (non-SVE2) specific optimization — insufficient hardware coverage; this FEP covers
  NEON and SVE2 only.

## Proposal

Developers write a kernel once using `@triton.jit` plus TLE extended operations, select the
Arm64 target at compile time, and FlagTree drives the Triton-CPU backend to lower it into
AArch64 machine code. Pre-built TLE extended operations are available from FlagTree, so models
can run end-to-end on Arm CPUs — architecture-specific optimizations are encapsulated in
open-source TLE extended operations, with no hand-written assembly required from the user.

On the engineering side, the tle_arm64 plugin sits alongside other hardware plugins in
FlagTree's `third_party/`, with ownership, build, and maintenance unified within FlagTree.

## Design Details

### Plugin Architecture

`flagtree/third_party/tle_arm64/`, following the plugin pattern of `third_party/tle/` (DSA).

**Phase 1 (current)**: Pybind injection layer migration — extract `create_cpu_*` builder
methods from Triton-CPU's `ir.cc` into a standalone plugin `.cc`, injected into
`TritonOpBuilder` at module initialization. MLIR op definitions and lowering remain in
Triton-CPU.

**Phase 2 (follow-up)**: Standalone Arm64TleDialect — migrate MLIR op definitions and lowering
into the plugin so that the Triton-CPU compiler substrate no longer contains Arm64 TLE-specific
code.

CMake integration: `add_subdirectory(third_party/tle_arm64)` when `FLAGTREE_BACKEND=cpu`.

### TLE Extended Operations (Operator Layer)

| Category | Operation | Description |
|---|---|---|
| GEMV | `sdot_gemv_fused_bf16` | W8A8-dynamic: fused quantization + SDOT GEMV + dequantization |
| Fusion | `fused_mlp` | gate+up GEMV + SiLU + mul in a single OMP region |
| Fusion | `flash_attn_decode` | M=1 Flash Attention with OMP parallelism across heads |
| Normalization | `rms_norm` / `rms_norm_gated` | Single kernel replacing multiple decomposed ATen ops |
| Activation | `swiglu` | Fused SiLU(gate) * up |
| Sequence models | `causal_conv1d_update` / `gated_delta_decode` | GDN single-step decode |

### Runtime

Reads `/proc/cpuinfo` for big.LITTLE core identification and ISA feature detection,
automatically configuring OMP affinity. NEON serves as the universal fallback.

## Packaging

This feature is built from source on AArch64 Linux. The full installation guide is in the
FlagTree repository at `documents/install_cpu.md` (see
[FlagTree#633](https://github.com/flagos-ai/FlagTree/pull/633)). The reproducible build
sequence is reproduced below.

> **Merge status.** Everything below uses canonical `flagos-ai/*` URLs:
> FlagTree [#632](https://github.com/flagos-ai/FlagTree/pull/632) is merged on
> `triton_v3.3.x`; the C++ extension repo is merged and has been **renamed
> `flagos-ai/triton-cpu` → `flagos-ai/flagtree-cpu`**; FlagGems is merged on `master`
> ([#3616](https://github.com/flagos-ai/FlagGems/pull/3616)) and on the `5.3.0-rc2`
> release branch ([#3775](https://github.com/flagos-ai/FlagGems/pull/3775)).

### Platform requirements

- AArch64 Linux (Ubuntu 22.04+ recommended)
- ARMv9-A with NEON / SVE2 + i8mm (e.g. Cortex-A720, CIX P1 CD8180)
- Python 3.11
- LLVM a66376b0 — auto-fetched on first build by default; manually stageable for restricted networks

### 1. System dependencies

```bash
sudo apt-get update && sudo apt-get install -y \
    build-essential cmake ninja-build git ccache pkg-config \
    libomp-dev libjemalloc2 zlib1g zlib1g-dev libxml2 libxml2-dev nlohmann-json3-dev \
    ca-certificates curl wget numactl python3-dev python3-pip python3-venv
```

### 2. Python environment

```bash
python3 -m venv ~/venv-flagtree
source ~/venv-flagtree/bin/activate
pip install --upgrade pip setuptools wheel
pip install pybind11   # build dependency; --no-build-isolation does not install it
pip install numpy      # avoids torch's "Failed to initialize NumPy" warning (FlagGems needs it anyway)
pip install torch==2.10.0+cpu --index-url https://download.pytorch.org/whl/cpu
```

### 3. (Optional) Manual LLVM download for restricted networks

By default the LLVM toolchain is fetched automatically on the first build. Only when
`oaitriton.blob.core.windows.net` is unreachable:

```bash
mkdir -p ~/.triton/llvm && cd ~/.triton/llvm
wget https://oaitriton.blob.core.windows.net/public/llvm-builds/llvm-a66376b0-ubuntu-arm64.tar.gz
tar zxvf llvm-a66376b0-ubuntu-arm64.tar.gz
export LLVM_SYSPATH=~/.triton/llvm/llvm-a66376b0-ubuntu-arm64
export LLVM_INCLUDE_DIRS=$LLVM_SYSPATH/include
export LLVM_LIBRARY_DIR=$LLVM_SYSPATH/lib
```

### 4. Clone FlagTree and check out the CPU backend branch

```bash
cd ${YOUR_CODE_DIR}
git clone https://github.com/flagos-ai/FlagTree.git
cd FlagTree
git checkout -b triton_v3.3.x origin/triton_v3.3.x   # FlagTree's 3.3.x branch (carries the CPU backend)
```

### 5. Wire up flagtree-cpu via the helper script

The C++ extension layer (TritonCPU MLIR dialect + NEON/SVE2 C runtime + Python TLE builtins)
lives in `flagos-ai/flagtree-cpu`. One helper script clones it into `third_party/triton-cpu/`
and creates the 12 symlinks the CPU backend build expects (TritonCPU dialect headers,
`third_party/cpu/*`, sleef, the Python TLE builtins, and `python/triton/language/extra/cpu`):

```bash
bash python/scripts/link_flagtree_cpu.sh
```

All resulting symlinks are relative. Re-running the script is safe (existing/correct
symlinks are skipped).

### 6. Build FlagTree (CPU backend)

```bash
FLAGTREE_BACKEND=cpu TRITON_BUILD_PROTON=OFF MAX_JOBS=$(nproc) \
TRITON_APPEND_CMAKE_ARGS="-DCMAKE_INSTALL_PREFIX=$HOME/.flagtree_install" \
    pip install -e python/ --no-build-isolation -v
```

`TRITON_APPEND_CMAKE_ARGS` redirects the `cmake --install` step; without it the sleef
subproject tries to copy `libsleef.so` into `/usr/local/lib`, which fails with
*Permission denied* for non-root users. Use a per-user prefix (`$HOME/.flagtree_install`)
rather than a shared one like `/tmp/flagtree_install`: on a multi-user machine the shared
directory is owned by whoever built first, and a second user's `cmake --install` then fails
with *Permission denied* — the very error this flag is meant to avoid.

If step 3 ran (manual LLVM), the exported `LLVM_SYSPATH` is picked up automatically; you can
also pass `TRITON_OFFLINE_BUILD=1` to assert no network access is used.

### 7. Install FlagGems (ARM64 backend, for end-to-end inference)

```bash
# FlagGems build dependencies — not auto-installed under --no-build-isolation
pip install "scikit-build-core==0.12.2" "cmake>=3.20,<4.0" "ninja==1.13.0"

cd ${YOUR_CODE_DIR}
git clone -b 5.3.0-rc2 https://github.com/flagos-ai/FlagGems.git
cd FlagGems
pip install --no-build-isolation -e .
```

> **Note.** On CPU-only hosts FlagGems no longer auto-detects the `arm` vendor
> (the `device_query_cmd` probe was removed); `FLAGGEMS_VENDOR=arm` must be set
> explicitly whenever `flag_gems` is imported, otherwise it fails with
> `RuntimeError: No device were detected`. The Test Plan commands below include it.

## Test Plan

The test plan below is required for AArch64 Linux on the reference platform.

### Environment Matrix

- Platform: AArch64 Linux, Ubuntu 22.04+
- Reference hardware: CIX P1 (CD8180), ARMv9-A with NEON / SVE2 + i8mm + dotprod
  (8 big Cortex-A720 cores pinned via `taskset`)
- Python: 3.11
- Triton: 3.3.x (commit recorded in CI logs)
- LLVM: a66376b0 (auto-fetched)
- FlagTree: `flagos-ai/FlagTree:triton_v3.3.x` (merged via PR #632)
- flagtree-cpu: `flagos-ai/flagtree-cpu:main` (merged; repo renamed from `triton-cpu`)
- FlagGems: `flagos-ai/FlagGems:5.3.0-rc2` (merged via PR #3616 to `master`, PR #3775 to `5.3.0-rc2`)

### Component Setup and Running

All commands assume the Packaging steps above completed successfully, the venv is active,
and `FLAGTREE_BACKEND=cpu` is exported — at runtime it enables the ARM `-march` flags,
OpenMP linkage and GCC-assembler compatibility handling for JIT-compiled `kernel.s`:

```bash
export FLAGTREE_BACKEND=cpu
```

#### 1. Verify CPU backend registration

Confirm the CPU backend is registered and the `create_cpu_*` TLE builder methods are
injected by the `tle_arm64` plugin:

```python
import triton
from triton.backends import backends
print(f"triton {triton.__version__}, cpu backend: {'cpu' in backends}")

import triton._C.libtriton as lt
b = lt.ir.builder(lt.ir.context())
cpu_ops = sorted(m for m in dir(b) if m.startswith("create_cpu_"))
print(f"TLE ARM64 ops ({len(cpu_ops)}): {cpu_ops}")
```

Expected output:

```
triton 3.3.0, cpu backend: True
TLE ARM64 ops (10): ['create_cpu_flash_attn_decode', 'create_cpu_fused_decode_step',
 'create_cpu_fused_mlp', 'create_cpu_fused_transformer_layer', 'create_cpu_neon_sdot',
 'create_cpu_rms_norm', 'create_cpu_sdot_gemv', 'create_cpu_sdot_gemv_fused_bf16',
 'create_cpu_sdot_pack_weights', 'create_cpu_swiglu']
```

Pass criteria: `cpu backend: True` and 10 `create_cpu_*` methods are listed.

#### 2. Operator-level verification: TLE rms_norm

Run one TLE op end-to-end (`@triton.jit` → `create_cpu_rms_norm` → TritonCPU dialect →
NEON/SVE2 C runtime):

```python
import torch, triton, triton.language as tl
from triton.language.extra.cpu import tle_ops as tle_cpu

@triton.jit
def rms_kernel(x_ptr, w_ptr, out_ptr, D: tl.constexpr, eps: tl.constexpr):
    tle_cpu.rms_norm(x_ptr, w_ptr, out_ptr, D, eps)

D = 128
torch.manual_seed(0)
x = torch.randn(D, dtype=torch.bfloat16)
w = torch.randn(D, dtype=torch.bfloat16)
out = torch.empty(D, dtype=torch.bfloat16)
rms_kernel[(1,)](x, w, out, D, 1e-6)

xf = x.float()
ref = (xf / torch.sqrt((xf * xf).mean() + 1e-6)) * w.float()
err = (out.float() - ref).abs().max().item()
print(f"TLE rms_norm max err (bf16): {err}")
print(f"RESULT: {'OK' if err < 0.1 else 'MISMATCH'}")
```

Expected output:

```
TLE rms_norm max err (bf16): 0.014348745346069336
RESULT: OK
```

Pass criteria: max err within bf16 precision (~0.014); `RESULT: OK`.

#### 3. End-to-end decoder test: MiniCPM5-0.9B INT8 inference

Verify the full TLE INT8 (W8A8-dynamic) stack on a real LLM. Quantize in memory and
greedy-decode 64 new tokens. Requires `pip install transformers accelerate sentencepiece`
in addition to the Packaging steps. Save as `e2e_test.py`:

```python
import time
import sys
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

sys.path.insert(0, "/path/to/FlagGems/src")
from flag_gems.runtime.backend._arm.int8 import quantize_and_replace_linears
from flag_gems.runtime.backend._arm.fused.patch_llama_arch import patch_llama_arch

MODEL_PATH = "/path/to/MiniCPM5-0.9B"

tok = AutoTokenizer.from_pretrained(MODEL_PATH, trust_remote_code=True)
m = AutoModelForCausalLM.from_pretrained(
    MODEL_PATH, dtype=torch.bfloat16, trust_remote_code=True,
).eval()

# INT8 quantization (W8A8-dynamic) + TLE Llama-arch patches (rope / rmsnorm / layer_norm)
n = quantize_and_replace_linears(m)
arch_info = patch_llama_arch()
print(f"[setup] INT8 Linears={n}  patch_llama_arch={arch_info}")

ids = tok("The future of edge AI is", return_tensors="pt").input_ids

# Warmup
with torch.inference_mode():
    m.generate(ids, max_new_tokens=4, do_sample=False, use_cache=True,
               pad_token_id=tok.eos_token_id)

# Measure
t0 = time.perf_counter()
with torch.inference_mode():
    out = m.generate(ids, max_new_tokens=64, do_sample=False, use_cache=True,
                     pad_token_id=tok.eos_token_id)
dt = time.perf_counter() - t0
tps = 64 / dt
print(f"TPS: {tps:.2f}")
print(f"OUTPUT: {tok.decode(out[0], skip_special_tokens=True)}")
```

Run with the optimal OMP environment for the reference platform:

```bash
FLAGTREE_BACKEND=cpu FLAGGEMS_VENDOR=arm \
OMP_NUM_THREADS=8 OMP_PROC_BIND=close OMP_DYNAMIC=false \
GOMP_SPINCOUNT=infinity TORCH_NUM_THREADS=1 \
taskset -c 0,1,6,7,8,9,10,11 \
    python e2e_test.py
```

(`FLAGGEMS_VENDOR=arm` is required — FlagGems does not auto-detect the `arm` vendor on
CPU-only hosts and `import flag_gems` fails without it.)

Expected output (representative; concrete TPS depends on hardware):

```
[setup] INT8 Linears=169  patch_llama_arch={'rope': 1, 'rmsnorm': 1, 'layer_norm': 1}
TPS: 18.66
OUTPUT: The future of edge AI is ...
```

Pass criteria:
- Setup line shows `INT8 Linears=169` and all three Llama patches applied.
- TPS ≥ 17 tok/s on CIX P1 (CD8180).
- Output text is coherent English (no token loops, no degenerate tokens).

### Pass Criteria (summary)

All three verification phases must pass:

1. **Backend registration** (§1) — the CPU backend loads and the 10 `create_cpu_*` TLE
   builder methods are visible.
2. **Operator correctness** (§2) — TLE `rms_norm` matches the float reference within bf16
   precision.
3. **End-to-end correctness + performance** (§3) — INT8 W8A8-dynamic stack runs MiniCPM5-0.9B
   coherently at ≥ 17 tok/s on CIX P1.

## Related PRs

- [ ] FlagTree: `third_party/tle_arm64/` pybind plugin + CMake integration
- [ ] FlagTree: (Phase 2) standalone Arm64TleDialect + lowering migration
- [ ] Triton-CPU: expose `ir.h` + Arm ISA selection + threading optimization + TLE op
  definitions + C runtime
- [ ] FlagGems: Arm64 end-to-end inference integration

## Implementation History

- 2026-05-27: FEP created (Provisional).
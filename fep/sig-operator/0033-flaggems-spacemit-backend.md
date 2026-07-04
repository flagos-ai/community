# FEP: SpacemiT Backend Support for FlagGems

**Status:** `Implemented`

**Created:** 2026-06-05

**Owner:** @alex-spacemit

**SIG:** sig-operator

**Target Version:** FlagOS 2.1

## Summary

This FEP tracks the SpacemiT backend support work in FlagGems for FlagOS 2.1.

The current work mainly includes:

- Adding SpacemiT runtime backend with operator implementations.
- Refactored the import structure and initialization logic for the SpacemiT backend.
Made the SpacemiT Triton configuration optional if triton.backends.spine_triton is unavailable, and added device detection via the spacemit-tcm-smi query command.

Related SpacemiT repositories:
- https://github.com/spacemit-com/spine-FlagGems

Add baseline SpacemiT backend support for FlagGems on FlagOS 2.1 with a set of supported operators covered by verification tests.

## Motivation

FlagGems equipped with the SpacemiT backend will become the first Triton operator library capable of full deployment on RISC-V environments. It currently runs on SpacemiT K1 and K3 chips, leveraging SpacemiT’s proprietary Triton compiler to compile and execute FlagGems operators. We aim to pioneer a homogeneous fused Triton ecosystem within the RISC-V domain that eliminates the traditional host-device boundary separation.

## Goals

- Add SpacemiT runtime backend support in FlagGems.
- Improve SpacemiT backend setup and import logic.
- Avoid import errors when optional `triton.backends.spine_triton` is unavailable.
- Enable SpacemiT device query through `spacemit-tcm-smi`.
- Add setup support for SpacemiT.
- Use Python 3.12 for SpacemiT setup compatibility.
- Record initial validation result from `tests/test_abs.py`、`tests/test_mm.py`.
- 26 operators exposed from `ops/__init__.py` with complete functional and performance tests.

## Non-Goals

- Retain operator implementations without full exports; enable exports after functional tests pass.

## Proposal

### 1. Add SpacemiT Runtime Backend and Operator Implementations

Add a new `spacemit` runtime backend to FlagGems and integrate it into the existing vendor/runtime infrastructure.

Related PR:

- https://github.com/flagos-ai/FlagGems/pull/2527 — Add Spacemit runtime backend with operator implementations
- https://github.com/flagos-ai/FlagGems/pull/3793 — Update Triton to 3.6.0+spacemit.a5 and fix mm, argmax, gelu, bmm

PR #2527 has been merged into `flagos-ai:master` and included in `tag 5.3.0-rc2`.
PR #3793 has been merged into `flagos-ai:master` and cherry-picked onto `flagos-ai:5.3.0-rc2` via https://github.com/flagos-ai/FlagGems/pull/3828.

The backend currently exports the following operators through `ops/__init__.py`:

- `argmax`, `argmin`
- `bmm`, `bmm_out`
- `gelu`, `gelu_`, `gelu_backward`
- `global_avg_pool`, `layer_norm`, `mean_dim`
- `mm`, `mm_out`, `mv`
- `pow_scalar`, `pow_tensor_scalar`, `pow_tensor_scalar_`, `pow_tensor_tensor`, `pow_tensor_tensor_`
- `rsqrt`
- `sigmoid`, `silu`, `softmax`
- `where_scalar_other`, `where_scalar_self`, `where_self`, `where_self_out`

Additionally, `rsqrt_`, `sigmoid_`, and `silu_` are defined in their respective source files but not exported in `__all__`.

### 2. SpacemiT Operator Support Matrix

The current SpacemiT backend operators are grouped by export status and support level based on `ops/__init__.py` and code analysis.

| Category | Operators | Status | Notes |
|---|---|---|---|
| Exported forward-only operators | `argmax`, `argmin`, `bmm`, `bmm_out`, `global_avg_pool`, `mean_dim`, `mm`, `mm_out`, `mv`, `pow_scalar`, `pow_tensor_scalar`, `pow_tensor_scalar_`, `pow_tensor_tensor`, `pow_tensor_tensor_`, `rsqrt`, `where_scalar_other`, `where_scalar_self`, `where_self`, `where_self_out` | Enabled | Forward path is available; no backward/autograd registration |
| Exported operators with `torch.autograd.Function` integration | `layer_norm`, `silu` | Enabled | `layer_norm`: full forward/backward with weight/bias gradient kernels; `silu`: full forward/backward, also has in-place `silu_` (not exported) |
| Exported operators with separate backward function (no autograd.Function) | `gelu`, `softmax`, `sigmoid` | Enabled | `gelu`: supports `none` and `tanh` approximate modes, backward via `gelu_backward`; `softmax`: forward uses SpacemiT custom kernel (`softmax_kernel_spacemit`), backward delegates to `common_softmax_backward`; `sigmoid`: backward via `sigmoid_backward`, also has in-place `sigmoid_` (not exported) |
| Existing but not exported operator files | `addmm`, `conv1d`, `conv2d`, `conv_depthwise2d`, `flash_attention`, `thnn_conv2d` | Not exported | Operator files exist with full implementations, but imports/exports are commented out in `ops/__init__.py`. `conv1d` and `thnn_conv2d` are thin wrappers around `conv2d`; `conv_depthwise2d` delegates to `conv2d` with `groups`; `flash_attention` supports GQA, causal/non-causal modes, and `scaled_dot_product_attention`; `addmm` uses smt.dot with alpha/beta scaling |

Dtype support summary:

- Matrix operators (`mm`, `bmm`, `mv`): `float16`, `float32`; kernel uses input element type generically, tuned configs cover `float32` and `float16`
- `addmm` (not exported): same dtype support as `mm`/`bmm`
- Elementwise operators (`gelu`, `silu`, `sigmoid`, `rsqrt`, `pow`): `float16`, `float32`; `sigmoid` and `rsqrt` additionally support integer inputs via `INT_TO_FLOAT` promotion; `pow` supports bool and numeric inputs via `BOOL_TO_LONG` promotion
- Reduction/normalization operators (`mean_dim`, `global_avg_pool`, `layer_norm`, `softmax`): numeric types supported by implementation; key floating dtypes include `float16`, `float32`; `layer_norm` saves mean/rstd in accumulator dtype for numerical stability
- Selection operators (`where`): dtype inferred from `torch.result_type(self, other)`; condition must be `bool`; all tensors must be on CPU
- Arg reduction operators (`argmax`, `argmin`): numeric input types; output is `int64`

### 3. SpacemiT Backend Integration

The SpacemiT backend initializes through `_spacemit/__init__.py`. The key integration points are:

**1. Optional Dependency Detection & Triton Config Injection**

```python
# _spacemit/__init__.py
import importlib.util

if importlib.util.find_spec("triton.backends.spine_triton") is not None:
    from .utils.config_pre_hook import setup_triton_config
    setup_triton_config()
    import triton
    from triton.backends.spine_triton.driver import CPUDriver
    triton.runtime.driver.set_active(CPUDriver())
```

At import time, `importlib.util.find_spec` checks whether `triton.backends.spine_triton` is available:
- If available: calls `setup_triton_config()` which monkey-patches `TunedConfigLoader.get_tuned_config` to inject GEMM tuning config validation. For operators like `mm` and `bmm`, it validates and auto-corrects MICRO_M/K/N parameters against per-architecture legal configs (chip arch IDs: `0x503C`, `0xA03C`, `0xA064`, `0xF000`). It then sets `CPUDriver` as the active Triton driver.
- If unavailable: skips the above steps, avoiding import errors when the optional dependency is not installed.

**2. Vendor Info Registration**

```python
# _spacemit/__init__.py
from backend_utils import VendorInfoBase

vendor_info = VendorInfoBase(
    vendor_name="spacemit",
    device_name="cpu",
    device_query_cmd="spacemit-tcm-smi",
)
```

Registers the vendor as `spacemit` with device type `cpu`. The `device_query_cmd` is set to `spacemit-tcm-smi` — FlagGems executes this command at runtime to discover available SpacemiT devices.

``` bash
root@k3:~# spacemit-tcm-smi
spacemit-tcm-smi 3.0.0
backend=v2 runtime=available fake=no block_size=393216 block_num=8 available_blocks=8/8
ID   STATE  SIZE       PHYS               CPU_MASK           PID
0    free   393216     -                  0x300              -
1    free   393216     0x60000            0x300              -
2    free   393216     0xc0000            0xc00              -
3    free   393216     0x120000           0xc00              -
4    free   393216     0x2000000          0x3000             -
5    free   393216     0x2060000          0x3000             -
6    free   393216     0x20c0000          0xc000             -
7    free   393216     0x2120000          0xc000             -
```

**3. Device Guard & Wrapper**

```python
class _DeviceGuard:
    def __init__(self, index: int): ...
    def __enter__(self): ...
    def __exit__(self, ...): ...

class _DeviceWrapper:
    @staticmethod
    def current_device():
        return 0  # CPU backend always uses device 0
```

Provides `_DeviceGuard` (device-switching context manager) and `_DeviceWrapper` (device abstraction; `current_device()` always returns 0 for the CPU backend) for use by the FlagGems runtime.

**4. Python Version & Build Support**

- Python version: `setup.sh` sets SpacemiT's `PYTHON_SUPPORTED` to **Python 3.12**.
- CI/CD: experimental setup support for the SpacemiT backend was added via PR #3355.

## Test Plan

### Test Commands

Env Setup with pip

```bash
pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/

pip config set global.extra-index-url https://git.spacemit.com/api/v4/projects/33/packages/pypi/simple

uv venv --python 3.12 .venv

source ./venv/bin/activate

UV_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/ uv pip install pip

python -m pip install ".[spacemit]"
```

Or

```bash
uv venv --python 3.12 .venv

source ./venv/bin/activate

bash ./tools/vendor.sh
```

Basic operator validation:

```bash
pytest tests/test_abs.py
```

Observed result:

```bash
================================================================= test session starts ==================================================================
platform linux -- Python 3.12.13, pytest-9.0.3, pluggy-1.6.0
rootdir: /home/bianbu/FlagGems
configfile: pytest.ini
plugins: md-report-0.8.0
collected 24 items

tests/test_abs.py ........................                                                                                                       [100%]
```

```bash
python -m pytest tests/test_mm.py
```

Observed result:

```bash
python -m pytest tests/test_mm.py
========================================================================= test session starts ==========================================================================
platform linux -- Python 3.12.13, pytest-9.0.3, pluggy-1.6.0
rootdir: /home/bianbu/FlagGems
configfile: pytest.ini
plugins: md-report-0.8.0
collected 42 items

tests/test_mm.py ........................                                                                                                       [100%]
```

### Expected Results
- `tests/test_abs.py`、`tests/test_mm.py` passes in the reported validation environment.
- SpacemiT backend initialization does not fail when `triton.backends.spine_triton` is unavailable.
- SpacemiT device query command is configured as `spacemit-tcm-smi`.

## Related PRs
- https://github.com/flagos-ai/FlagGems/pull/2527 — Add Spacemit runtime backend with operator implementations
- https://github.com/flagos-ai/FlagGems/pull/3112 — Refactor import organization and setup logic for spacemit
- https://github.com/flagos-ai/FlagGems/pull/3275 — Update SpacemiT device_query_cmd to spacemit-tcm-smi
- https://github.com/flagos-ai/FlagGems/pull/3355 — Add setup support for spacemit
- https://github.com/flagos-ai/FlagGems/pull/3385 — Downgrade SpacemiT supported Python version to 3.12
- https://github.com/flagos-ai/FlagGems/pull/3793 — Update Triton to 3.6.0+spacemit.a5 and fix mm, argmax, gelu, bmm
- https://github.com/flagos-ai/FlagGems/pull/3828 — Cherry-pick PR #3793 onto `flagos-ai:5.3.0-rc2`

> PR #2527、PR #3112、PR #3275、PR #3355、PR #3385 are included in `5.3.0-rc2`.

## Implementation History

- 2026-06-05: FEP created.

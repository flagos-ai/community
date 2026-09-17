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

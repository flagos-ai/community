import platform
from pathlib import Path
import triton

target = triton.runtime.driver.active.get_current_target()
print(platform.machine(), triton.__version__, Path(triton.__file__).resolve(), target)
assert platform.machine().lower() in {"aarch64", "arm64"}
assert triton.__version__ == "3.7.2"
assert "flagtree-cpu" in str(Path(triton.__file__).resolve())
assert target.backend == "cpu"

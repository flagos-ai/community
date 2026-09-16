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

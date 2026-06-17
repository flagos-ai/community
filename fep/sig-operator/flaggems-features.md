# FEP-NNNN: FlagGems Features

**Status:** `Provisional`

**Created:** 2026-05-28

**Owner:** @0x45f

**SIG:** sig-operator

**Target Version:** FlagOS 2.1

---

## Summary

This FEP covers the features and improvements delivered in FlagGems, a high-performance generic operator library implemented in Triton language. FlagGems provides 290+ PyTorch-compatible operators with multi-backend support for 10+ hardware platforms including NVIDIA, Ascend, MetaX, Hygon, Iluvatar, Kunlunxin, Mthreads, Cambricon, and more. Key features in this release include:

1. **DeepSeek V4 attention operators** — support for DeepSeekV4 attention ops with vLLM integration.
2. **Expanded operator coverage** — new operators including `reflection_pad1d_backward`, `randint`, `rad2deg`, `repeat_interleave`, `as_strided_copy`, `cauchy`, etc.
3. **Multi-backend enhancements** — improved support for Ascend, Hygon, Kunlunxin, Mthreads, and new Sunrise platform support.
4. **Performance optimizations** — optimized sum reduction kernels with two-stage and persistent kernel strategies, FlagTune API for matmul ops.
5. **C++ Triton function dispatcher** — ongoing work to reduce Python runtime overhead.

Repository: https://github.com/flagos-ai/FlagGems

## Motivation

FlagOS 2.1 requires FlagGems to expand operator coverage for next-generation model architectures (DeepSeek V4), broaden hardware platform support for domestic chip ecosystems, and improve end-to-end performance through kernel optimizations and C++ runtime enhancements. The multi-backend architecture enables a "develop once, run anywhere" workflow across diverse AI accelerators.

### Goals

- Provide DeepSeek V4 attention operators with vLLM accuracy validation.
- Expand operator coverage to 290+ PyTorch-compatible operators.
- Support 10+ hardware backends with comprehensive dtype coverage (float16, float32, bfloat16).
- Optimize reduction operators (sum) with two-stage and persistent kernel strategies.
- Introduce FlagTune API for extensible matmul operator tuning.
- Add CI support for new platforms (Sunrise).
- Maintain backward compatibility with existing PyTorch ATen backend registration.

### Non-Goals

- Full C++ Triton function dispatcher (in progress, tracked separately).
- AMD backend support (under development).
- TsingMicro backend support (under development).

## Proposal

### 1. DeepSeek V4 Attention Operators

Add DeepSeek V4 attention operators to FlagGems with vLLM integration:
- Register operators in operators YAML configuration.
- Implement vLLM accuracy tests for DeepSeekV4 ops.
- Benchmark DeepSeekV4 ops against vLLM APIs.

Related PRs: #3500, #3494, #3505.

### 2. Expanded Operator Coverage

Add new operators to reach 290+ total operators:
- `floor` operator (KernelGen)
- `log1p` operator
- `reflection_pad1d_backward` operator with Triton kernel
- `randint` operator with Triton kernel
- `rad2deg` operator with Triton kernel
- `repeat_interleave` operator (Advanced Compiler)
- `as_strided_copy` operators
- `cauchy` operators

Related PRs: #1736, #1747, #3448, #3446, #3445, #3328, #3501, #3496.

### 3. Multi-Backend Enhancements

Improve hardware platform support:
- **Ascend**: Optimize full op with hand-written multi-core Triton kernel (#2185).
- **Hygon**: Fix adaptation issues (#3477).
- **Kunlunxin**: Solve elu_backward ops (#3484), fix setup typo (#3527).
- **Mthreads**: Add autotune to mm op (#3493), fix safe_softmax device check (#3499).
- **Sunrise**: Add CI support (#3544).

### 4. Performance Optimizations

Optimize reduction operators:
- Add two-stage reduction kernels for non-inner dim sum.
- Add persistent kernel for small M non-inner reduction.
- Add heuristics for two-stage and persistent kernels.
- Wire optimized kernels into dispatch logic.

Add FlagTune API:
- Simple extensible FlagTune API for selected matmul ops (#3462).

### 5. Bug Fixes and Improvements

- Fix flash attn varlen error when key cache non-contiguous (#3410).
- Fix copy fp8 (#3509).
- Fix torch init error (#3551).
- Improve nll_loss test coverage (#3296).
- Fix uv condition check in setup script (#3541).

## Design Details

### Multi-Backend Architecture

FlagGems uses a backend-neutral kernel design with platform-specific adaptations:

```
flag_gems/
├── ops/           # Backend-neutral operator implementations
├── runtime/       # Runtime kernel dispatching (LibEntry)
├── patches/       # Platform-specific patches
└── csrc/          # C++ extensions
```

### LibEntry Kernel Dispatching

`LibEntry` independently manages the kernel cache and bypasses the runtime of `Autotuner`, `Heuristics`, and `JitFunction`, providing function-level kernel dispatching with reduced overhead.


## Packaging

### Build Command

```bash
# Install with pip (pure Python)
pip install flag_gems
```

### Build from Source

```bash
git clone https://github.com/flagos-ai/FlagGems.git
cd FlagGems
pip install -e .
```

### Platform Requirements

- Python >= 3.10
- PyTorch >= 2.7 (version varies by backend)
- Triton or FlagTree (backend-specific)
- CUDA >= 12.8 (for NVIDIA backend)

## Test Plan

### Test Commands

**Accuracy Tests:**
```bash
pytest tests/test_mhc_ops.py -m mhc_bwd --ref cpu -vs
pytest tests/test_mhc_ops.py -m mhc_post --ref cpu -vs
pytest tests/test_rad2deg.py -m rad2deg --ref cpu -vs
pytest tests/test_affine_grid_generator.py -m affine_grid_generator --ref cpu -vs
pytest tests/test_silu_and_mul.py -m silu_and_mul_out --ref cpu -vs
pytest tests/test_log1p.py -m log1p --ref cpu -vs
```

**Performance Benchmarks:**
```bash
pytest benchmark/test_mhc.py -m mhc_bwd --level core -vs
pytest benchmark/test_mhc.py -m mhc_post --level core -vs
pytest benchmark/test_rad2deg.py -m rad2deg --level core -vs
pytest benchmark/test_affine_grid_generator.py -m affine_grid_generator --level core -vs
pytest benchmark/test_silu_and_mul.py -m silu_and_mul_out --level core -vs
pytest benchmark/test_log1p.py -m log1p --level core -vs
```

### Expected Results

- All accuracy tests pass with numerical tolerance within acceptable bounds.
- DeepSeekV4 operators match vLLM reference implementation.
- Performance benchmarks show speedup compared to PyTorch ATen library in eager mode.
- Multi-backend tests pass on supported platforms with correct dtype handling.

## Related PRs

- [ ] flagos-ai/FlagGems#3296 — Improve nll_loss test coverage
- [ ] flagos-ai/FlagGems#3328 — Add repeat_interleave operator (Advanced Compiler)
- [ ] flagos-ai/FlagGems#3410 — Fix flash attn varlen error when key cache non-contiguous
- [ ] flagos-ai/FlagGems#3445 — Add rad2deg operator with Triton kernel (KernelGen)
- [ ] flagos-ai/FlagGems#3446 — Add randint operator with Triton kernel (KernelGen)
- [ ] flagos-ai/FlagGems#3448 — Add reflection_pad1d_backward operator with Triton kernel (KernelGen)
- [ ] flagos-ai/FlagGems#3462 — Add simple extensible FlagTune API for selected matmul ops
- [ ] flagos-ai/FlagGems#3477 — Fix Hygon adaptation
- [ ] flagos-ai/FlagGems#3484 — Solve elu_backward ops for Kunlunxin
- [ ] flagos-ai/FlagGems#3493 — Add autotune to Mthreads mm op
- [ ] flagos-ai/FlagGems#3494 — Benchmark DeepSeekV4 ops against vLLM APIs
- [ ] flagos-ai/FlagGems#3496 — Add cauchy operators
- [ ] flagos-ai/FlagGems#3499 — Fix safe_softmax device check for MUSA compatibility
- [ ] flagos-ai/FlagGems#3500 — Add vLLM accuracy tests for DeepSeekV4 ops
- [ ] flagos-ai/FlagGems#3501 — Add as_strided_copy operators
- [ ] flagos-ai/FlagGems#3505 — Add DeepSeekV4 attention ops to operators yaml
- [ ] flagos-ai/FlagGems#3509 — Fix copy fp8
- [ ] flagos-ai/FlagGems#3527 — Fix typo for Kunlunxin setup
- [ ] flagos-ai/FlagGems#3528 — Add Containerfile for NVIDIA cu128
- [ ] flagos-ai/FlagGems#3541 — Fix uv condition check in setup script
- [ ] flagos-ai/FlagGems#3544 — Add CI support for Sunrise
- [ ] flagos-ai/FlagGems#3551 — Fix torch init error

## Implementation History

- 2026-05-28: FEP created

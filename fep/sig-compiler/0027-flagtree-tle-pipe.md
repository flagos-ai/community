# FEP-0027: FlagTree TLE Pipe

**Status:** `Implemented`

**Created:** 2026-05-28

**Owner:** sunnycase

**SIG:** sig-compiler

**Target Version:** FlagOS 2.1

---

## Summary

FlagTree TLE Pipe introduces `tle.pipe`, a typed producer/consumer dataflow abstraction for Triton Language Extensions (TLE). It lets kernels explicitly describe CTA-local staged shared-memory payloads, writer and reader endpoints, and synchronization between producer and consumer partitions. The feature covers SPSC and SPMC pipes, ring-buffer stage reuse, warp-specialized pipelines, partial-field readers, and mixed payloads whose fields may be produced by different transports such as TMA, cp.async-style copies, or local shared-memory stores.

Repository: https://github.com/flagos-ai/FlagTree

## Motivation

Triton's automatic software pipelining is useful for regular loop-carried loads, but advanced kernels often need the producer/consumer split to be visible in the program. Sparse attention, FlashMLA-style prefill, and warp-specialized kernels need to coordinate shared-memory slots across TMA loaders, WGMMA consumers, epilogue code, and sometimes multiple consumers. Without a typed pipe abstraction, these kernels must encode synchronization through transport-specific barriers and duplicated state, making the algorithm harder to read and harder for the compiler to analyze.

### Goals

- Provide a user-facing `tle.pipe` API for explicit CTA-local producer/consumer dataflow over shared-memory buffered tensors.
- Support SPSC and SPMC pipelines with named reader endpoints, field-subset subscriptions, close-aware flows, and one-shot broadcast-style pipes.
- Lower accepted NVIDIA CTA-scoped pipes to NVWS token/mbarrier synchronization while preserving stage/phase reuse and multi-reader release tracking.
- Integrate pipe endpoints with `tle.gpu.warp_specialize` so producer and consumer partitions can communicate through typed endpoints.
- Support mixed logical pipes whose payload fields can be produced through different transports, with transport inferred from producer-side IR instead of user-visible attributes.
- Provide regression coverage and Sparse MLA / FlashMLA-style examples that validate correctness and performance-oriented use cases.

### Non-Goals

- Replace `tl.range(..., num_stages=...)` or Triton's automatic software pipeliner for regular loops.
- Provide inter-CTA, inter-device, or distributed pipe semantics in this FEP.
- Guarantee performance for every workload; performance remains dependent on kernel shape, hardware, and backend lowering.
- Make unsafe shared-memory pointer escapes or unprovable mixed-payload effects silently compile.

## Proposal

Users allocate one or more shared-memory buffered tensors with a leading `capacity` dimension and create a pipe with those tensors as named payload fields:

```python
smem = tle.gpu.alloc([2, BLOCK], dtype=tl.float32, scope=tle.gpu.smem)
pipe = tle.pipe(capacity=2, scope="cta", name="tile_pipe", tile=smem)
writer = pipe.writer()
reader = pipe.reader()
```

The writer acquires the slot for an iteration, fills one or more fields, then commits the slot. Readers wait for the corresponding iteration, consume the slot fields, and release them when the data is no longer needed:

```python
slot = writer.acquire(k)
tl.store(tle.gpu.local_ptr(slot.tile), values)
writer.commit(k)

ready = reader.wait(k)
tile = tl.load(tle.gpu.local_ptr(ready.slot.tile))
reader.release(k)
```

For SPMC patterns, users declare reader names and optionally subscribe each reader to only the fields it consumes:

```python
pipe = tle.pipe(
    capacity=PIPE_CAPACITY,
    scope="cta",
    name="kv_pipe",
    readers=("qk", "value"),
    kv=kv_smem,
    meta=meta_smem,
)
qk_reader = pipe.reader("qk")
value_reader = pipe.reader("value", fields=("kv",))
```

For mixed pipes, users keep one logical pipe for one logical payload lifecycle. The compiler infers each field's transport from IR, so a TMA-produced field, a cp.async-style field, and a local-store field can share the same slot, phase, reader set, and commit/release protocol.

## Design Details

- **Frontend API**: `tle.pipe(*, capacity, scope="cta", name=None, readers=None, one_shot=False, **fields)` validates compile-time capacity, CTA scope, public field and reader names, shared-memory buffered tensor payloads, and matching leading capacity dimensions.
- **Endpoint model**: `pipe.writer()` returns a typed writer endpoint, and `pipe.reader(name=None, fields=None)` returns a typed reader endpoint. Endpoints expose `writer.acquire(iter)`, `writer.commit(iter)`, `writer.close(iter)`, `reader.wait(iter)`, and `reader.release(iter)`.
- **Stage and phase mapping**: each `iter` maps to `stage = iter % capacity`; a phase value distinguishes ring-buffer reuse rounds.
- **IR construction**: the Python frontend emits TLE pipe create/acquire/commit/wait/release/close operations through the semantic builder, preserving pipe name, fields, readers, and one-shot metadata.
- **NVIDIA lowering**: CTA-scoped pipes lower to NVWS token/mbarrier synchronization. Multi-reader release tracking records which fields a reader releases so WGMMA operand lifetime waits are tied to actual storage reuse.
- **Warp specialization**: pipe endpoints are passed into `tle.gpu.warp_specialize` partitions so producer and consumer JIT functions receive restricted endpoint values rather than raw shared-memory synchronization internals.
- **Mixed-payload analysis**: compiler passes infer field transports from producer-side IR, including TMA, cp.async-style copies, and local stores. Unsafe opaque stores, pointer escapes, or unprovable source-order hazards fail at compile time.
- **WGMMA/TMA scheduling support**: TLE-owned resource analysis places WGMMA commit/wait and lifetime boundaries around pipe releases, handles TMA store commit/wait flows, and keeps accumulator semantics valid across pipelined stages.

## Packaging

`tle.pipe` is shipped as part of FlagTree's TLE components on the `triton_v3.6.x` line.

- Source branch: https://github.com/flagos-ai/FlagTree/tree/triton_v3.6.x
- NVIDIA CI workflow: https://github.com/flagos-ai/FlagTree/blob/triton_v3.6.x/.github/workflows/hopper-build-and-test.yml
- Containerized NVIDIA CI workflow: https://github.com/flagos-ai/FlagTree/blob/triton_v3.6.x/.github/workflows/flagcicd-hopper-build-and-test.yml
- Build command: `MAX_JOBS=32 python3 -m pip install . --no-build-isolation`
- Packaging format: Python wheel/installable Python package built by `pip install .`
- Platform requirements: Triton 3.6.x-compatible FlagTree checkout, Python 3, NVIDIA Hopper-class GPU for the current NVIDIA pipeline tests, CUDA/NVIDIA driver support, and LLVM configured through the CI environment.

## Test Plan

Image acquisition:
- For the containerized NVIDIA CI path, use `harbor.baai.ac.cn/flagtree/flagtree-3.6.x-py312-torch2.8.0a0_5228986c39.nv25.05-ubuntu24.04:202603` from `flagcicd-hopper-build-and-test.yml`.
- For the self-hosted Hopper CI path, use the runner environment configured by `~/env.sh` and `~/env-3.6.sh` in `hopper-build-and-test.yml`.

Package installation:

```bash
pip uninstall -y triton
MAX_JOBS=32 python3 -m pip install . --no-build-isolation
```

Component setup/running:

```bash
export PYTHONPATH=/path/to/FlagTree/python:${PYTHONPATH}
export TRITON_CACHE_DIR=/tmp/flagtree_tle_pipe_cache
```

Test commands:

```bash
python3 -m pytest -s python/test/tle/unit
python3 -m pytest -s python/test/tle/integration
python3 python/tutorials/tle/deepseek_v32/02-sparse-mla.py
ninja -C build/cmake.linux-x86_64-cpython-3.10 triton-opt triton check-triton-tle-lit-tests
```

Focused MLIR regression coverage includes:

```bash
lit -v build/cmake.linux-x86_64-cpython-3.10/third_party/tle/test/GPU/test_tle_pipe_ops.mlir
lit -v build/cmake.linux-x86_64-cpython-3.10/third_party/tle/test/GPU/test_tle_lower_pipe_to_nvws.mlir
lit -v build/cmake.linux-x86_64-cpython-3.10/third_party/tle/test/GPU/test_tle_lower_pipe_to_nvws_warpspec.mlir
lit -v build/cmake.linux-x86_64-cpython-3.10/third_party/tle/test/GPU/test_tle_lower_pipe_to_nvws_errors.mlir
lit -v build/cmake.linux-x86_64-cpython-3.10/third_party/tle/test/GPU/test_tle_pipe_to_mbarrier.mlir
lit -v build/cmake.linux-x86_64-cpython-3.10/third_party/tle/test/GPU/test_tle_pipe_participant_commit.mlir
lit -v build/cmake.linux-x86_64-cpython-3.10/third_party/tle/test/GPU/test_tle_wgmma_stage_predication.mlir
```

Expected results:
- Python unit tests validate the `tle.pipe` frontend contract, including capacity validation, SPSC/SPMC readers, field-subset readers, lifecycle operations, and one-shot metadata.
- Integration tests and Sparse MLA tutorial runs validate compiled TLE kernels and pipe-enabled sparse attention flows.
- MLIR tests validate pipe operations, pipe-to-NVWS/mbarrier lowering, warp-specialized lowering, diagnostics for invalid lowering cases, participant commit handling, WGMMA stage predication, and related synchronization behavior.
- Performance benchmarks are expected to show the TLE pipe path operating as a performance-oriented Sparse MLA / FlashMLA-style implementation, while exact latency depends on hardware and runtime configuration.

## Related PRs

- [x] flagos-ai/FlagTree#592 - Added TLE pipe and warp-specialized pipeline support on `triton_v3.6.x`
- [x] flagos-ai/FlagTree#596 - Fixed TLE WGMMA descriptor localization and async-copy regression on the warp-specialized path

## Implementation History

- 2026-05-28: FEP created

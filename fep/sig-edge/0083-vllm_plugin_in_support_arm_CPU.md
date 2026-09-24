# FEP-0083: vllm-plugin-FL Support for Arm64 CPU Local Inference

**Status:** `Implemented`

**Updated:** 2026-09-24

**Created:** 2026-07-29

**Owner:** @kevinzs2048

**SIG:** sig-edge

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| vllm-plugin-fl | [`0.3.0-rc2` @ `f1052770d3ff`](https://github.com/flagos-ai/vllm-plugin-FL/tree/f1052770d3ff2666d86f46d1779648dba62b2cbc) | [`v0.3.0-rc2.post3` @ `f1052770d3ff`](https://github.com/flagos-ai/vllm-plugin-FL/tree/f1052770d3ff2666d86f46d1779648dba62b2cbc) |
| flaggems | [`5.4.0-rc2` @ `6ed2f39071ef`](https://github.com/flagos-ai/FlagGems/tree/6ed2f39071ef85db26b7e64f0652a162f434959c) | [`v5.4.0-rc2.post4` @ `6ed2f39071ef`](https://github.com/flagos-ai/FlagGems/tree/6ed2f39071ef85db26b7e64f0652a162f434959c) |

## Summary

Enable Linux Arm64 inference through vLLM's CPU platform and the FL plugin.
Packed W4A8 runs through FlagGems and FlagTree CPU; W8A8 uses vLLM's native
CPU INT8 kernel. Plugin PR #433 and FlagGems PR #5904 are now in their RC2
branches. The CPU compiler dependency has no RC2 release-manifest entry.

## Reproducibility Revisions

The existing test scripts pin these revisions rather than the current RC2
branch heads:

| Dependency | Fixed revision |
|---|---|
| vLLM `0.24.0+cpu` | `ee0da84ab9e04ac7610e28580af62c365e898389` |
| vllm-plugin-FL #433 | `0252496764901de4d464ab64c09d995c954be646` |
| FlagGems #5904 | `1fda4b11ae528c02ae5187cda551af4a61a514c5` |
| [FlagTree CPU](https://github.com/flagos-ai/flagtree-cpu/tree/2c35990a30e96665f8f9b5e158562288b4011048) | `2c35990a30e96665f8f9b5e158562288b4011048` |

The plugin change is in the vLLM 0.24.0 release line. The acceptance below
applies to these fixed test revisions; the plugin and operator changes are
included in RC2.

## Design

Set `FLAGGEMS_VENDOR=arm`, `TRITON_CPU_BACKEND=1` and `VLLM_PLUGINS=fl`
before imports. The plugin selects `CpuPlatform` and retains vLLM's CPU
worker, attention, KV cache and HTTP interface.

| Model format | Execution path |
|---|---|
| Packed W4A8-G128 | Plugin adapter → FlagGems `w4a8_g128_linear` → FlagTree CPU |
| Channel-wise `int-quantized` W8A8 | `CompressedTensorsW8A8Int8` → `CPUInt8ScaledMMLinearKernel` |

The W4A8 preparation step losslessly packs 294 already-quantized INT4
tensors, verifies recovery and preserves scales/BF16 tensors. It writes a
separate test checkpoint. Model revisions and checksums are in
[pins.env](scripts/vllm-arm64/pins.env).

W8A8 success establishes native CPU INT8 inference and plugin coexistence.
It does not establish a FlagGems Arm W8A8 acceleration path.

## Build and Test

The reference host is Debian 13 `aarch64` on a 32 GiB CIX P1 with Python
3.11 and PyTorch `2.11.0+cpu`. Setup uses root/sudo for apt, uv `0.8.24`
and four native build jobs. Reserve at least 35 GiB for this environment and
models, or 60 GiB when also building the independent FEP-0082 environment.
Dependencies are pinned in [requirements.lock](scripts/vllm-arm64/requirements.lock).

From a community repository checkout:

```bash
bash fep/sig-edge/scripts/vllm-arm64/run.sh setup
bash fep/sig-edge/scripts/vllm-arm64/run.sh test w4
bash fep/sig-edge/scripts/vllm-arm64/run.sh test w8
bash fep/sig-edge/scripts/vllm-arm64/run.sh bench w4
bash fep/sig-edge/scripts/vllm-arm64/run.sh bench w8
```

The [script](scripts/vllm-arm64/run.sh) manages preparation, prewarming and
local HTTP servers. Defaults are `WORK_DIR=$HOME/arm64-vllm024-test`,
`MODEL_ROOT=$HOME/Models` and CIX P1 big cores `0,1,6,7,8,9,10,11`. On
other hosts, set `A720_CORES`, `OMP_NUM_THREADS` and `MKL_NUM_THREADS` from
the actual CPU topology. `SKIP_SYSTEM_PACKAGES=1` skips apt when prerequisites
exist. Use separate work directories for the two edge FEPs, retain the full
script directory, and run model tests sequentially on P1.

`operators`, `models w4`, `prewarm w4` and `smoke w4` are available for stage
recovery. An incomplete packed output requires a new empty `W4_PACKED`
directory. W4/W8 ports default to 18043/18042 and can be overridden by `PORT`.
Logs, versions, JUnit results, route counters and performance JSONL are saved
under `$WORK_DIR/logs`.

## Recorded Acceptance

On 2026-09-17, the fixed revisions were rebuilt and tested in a minimal
Debian 13 environment on CIX P1:

| Check | Recorded result |
|---|---|
| Platform | Arm64, Triton 3.7.2, vLLM 0.24.0+cpu, `CpuPlatform`, vendor `arm` |
| FlagGems numerical suite | 7 passed, 0 skipped |
| Plugin Arm suites | 16 passed, 0 skipped |
| W4A8 packing | Exact recovery of all 294 INT4 tensors |
| W4A8 offline request | Answer `2`; 168 load-time pack calls and 336 request linear calls |
| W4/W8 HTTP requests | Health/models HTTP 200 and expected math responses |
| W8A8 route | `CPUInt8ScaledMMLinearKernel` |

W4 initialization took 174.915 s and the first request 906.679 s.
Initialization after a retained-cache restart took 17.940 s. Warm medians
for five single-user, 64-output-token requests with eight big cores and
prefix caching disabled were:

| Model | 43-token prompt: TTFT / decode | 357-token prompt: TTFT / decode |
|---|---|---|
| W4A8 | 0.516 s / 7.58 tok/s | 2.348 s / 7.56 tok/s |
| Native W8A8 | 0.379 s / 4.64 tok/s | 1.526 s / 4.59 tok/s |

These measurements are reproducibility references, not release thresholds.
Independent compiler checks are in
[FEP-0082](0082-flagtree-cpu-bump-to-triton-3_7.md).

## Known Limitations

Empty-cache first use can spend roughly fifteen minutes compiling CPU
kernels. Prewarming requires a persistent `TRITON_CACHE_DIR`, matching
hardware/compiler identity and stable absolute paths. Different request
specializations can trigger compilation again; eager mode does not bypass JIT.

The published activation metadata is symmetric while the FlagGems operator
uses asymmetric dynamic activation quantization. Broader quality claims require a BF16
comparison on a defined evaluation set. Long context, concurrency and
production throughput are outside the completed functional PoC acceptance.

## Related PRs

- [x] [vllm-plugin-FL#433](https://github.com/flagos-ai/vllm-plugin-FL/pull/433) — Arm64 packed W4A8 integration in the 0.24.0 RC2 line. Merged.
- [x] [FlagGems#5904](https://github.com/flagos-ai/FlagGems/pull/5904) — Arm W4A8 operator and public packer in RC2. Merged.

## Deferred to FlagOS 2.3

CPU compiler release-artifact integration and assembled dependency regression,
tracked with [FEP-0082](0082-flagtree-cpu-bump-to-triton-3_7.md#deferred-to-flagos-23).

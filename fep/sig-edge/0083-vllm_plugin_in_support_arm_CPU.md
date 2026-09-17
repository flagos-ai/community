# FEP-0083: vllm-plugin-FL Support for Arm64 CPU Local Inference

**Status:** `Implementable`

**Created:** 2026-07-29

**Owner:** @kevinzs2048

**SIG:** sig-edge

**Target Version:** FlagOS 2.2

---

## Summary

Enable `vllm-plugin-FL` on Linux Arm64 using vLLM's stock CPU platform, worker,
attention, KV cache and HTTP API. Reproduce the environment and tests through
[one script entry](scripts/vllm-arm64/run.sh); the upstream sources remain unmodified.

| Dependency | Fixed revision |
|---|---|
| vLLM `0.24.0+cpu` | `ee0da84ab9e04ac7610e28580af62c365e898389` |
| [vllm-plugin-FL #433](https://github.com/flagos-ai/vllm-plugin-FL/pull/433) | `0252496764901de4d464ab64c09d995c954be646` |
| [FlagGems #5904](https://github.com/flagos-ai/FlagGems/pull/5904) | `1fda4b11ae528c02ae5187cda551af4a61a514c5` |
| [FlagTree CPU 3.7 branch](https://github.com/flagos-ai/flagtree-cpu/tree/triton_v3.7.x) | `2c35990a30e96665f8f9b5e158562288b4011048` |

## Release Boundary and Eligibility

- **FlagOS 2.2 development window:** 2026-06-01 through 2026-08-31, followed
  by release stabilization.
- **Implementation timing:** vllm-plugin-FL#433 and FlagGems#5904 were both
  opened on 2026-09-02, after feature freeze. The pinned FlagTree CPU commit
  is dated 2026-09-04. The full reproducibility rerun documented here was
  completed on 2026-09-17.
- **Release evidence:** these dependencies are not part of the normal
  pre-freeze FlagOS 2.2 feature set. Their technical implementation and tests
  can be `Implementable` while their inclusion in the FlagOS 2.2 release still
  requires an explicit release-manager exception and a manifest/tag decision.

This FEP therefore does not claim that the Arm64 path is already contained in
the published 2.2 RC artifact. If no exception is approved, the same pinned
implementation and evidence should be retained for a later release rather
than backdated into the 2.2 scope.

## Motivation

Test colleagues need a repeatable source environment, verified model files and evidence
of the actual operator selected. Earlier prototype `FL_CPU_INT4`/`FL_CPU_INT8` flags
and CIX image-local native/KleidiAI implementations do not describe PR #433.

### Goals

- Build and select the stock Arm64 CPU platform with the four pinned dependencies.
- Verify the plugin and FlagGems W4A8 operator, then complete offline and HTTP inference.
- Complete W8A8 inference and record its actual native vLLM CPU INT8 route.
- Report preparation, cold JIT, model loading and warm performance separately.

### Non-Goals

- Replacing vLLM's CPU worker, scheduler, attention or KV cache.
- Delivering an accelerated FlagGems ARM W8A8 route through PR #433 alone.
- Treating a math response as model-quality, long-context or production acceptance.

## Proposal

Set `FLAGGEMS_VENDOR=arm`, `TRITON_CPU_BACKEND=1` and `VLLM_PLUGINS=fl` before imports.
The plugin chooses `CpuPlatform` on Linux Arm64 CPU builds; there is no dedicated
`FL_CPU_INT4`/`FL_CPU_INT8` switch for this implementation. Scripts set these variables.

| Model contract | Tested route |
|---|---|
| Packed W4A8-G128 | Plugin adapter → FlagGems `w4a8_g128_linear` → FlagTree CPU |
| Channel-wise `int-quantized` W8A8 | vLLM `CompressedTensorsW8A8Int8` → `CPUInt8ScaledMMLinearKernel` |

## Design Details

PR #433 owns CPU platform registration, packed W4A8 integration and the idempotent
Qwen GDN compatibility hook. FlagGems #5904 owns the public ARM packer and W4A8 operator.
The ARM hooks require a CPU platform, Arm64 host and FlagGems vendor `arm`.

The [public W4A8 checkpoint](https://modelscope.cn/models/FlagRelease/MiniCPM5-2B-W4A8-arm-FlagOS)
is `int-quantized`. The `models w4` command losslessly packs its 294 already-quantized
INT4 tensors, checks exact recovery, preserves scales/BF16 tensors and changes the required
format labels. It creates a test copy and does not modify or requantize the source.
Model revisions and blob checksums are in [pins.env](scripts/vllm-arm64/pins.env).

The [W8A8 checkpoint](https://modelscope.cn/models/FlagRelease/MiniCPM5-2B-W8A8-arm-FlagOS)
does not match the packed W4A8 adapter. HTTP success demonstrates native CPU INT8
inference and plugin coexistence. A FlagGems ARM W8A8 acceleration claim requires
separate implementation, numerical and route-coverage acceptance.

## Packaging

The scripted reference is Debian 13 `aarch64`, 32 GiB CIX P1, Python 3.11 and
PyTorch `2.11.0+cpu`. `setup` installs system packages with sudo, uses uv `0.8.24`,
fetches exact sources and builds native packages with four jobs. It pins the declared
LLVM/SLEEF, ACL `v52.6.0` and oneDNN sources; package versions are in
[requirements.lock](scripts/vllm-arm64/requirements.lock).

**The scripted setup requires Debian 13; Debian 12 is not covered by this procedure.**
Have Git available before checkout. Setup uses sudo for a regular login or apt directly for root.
Setup installs `free`/`lscpu`/`taskset` before host diagnostics, including on minimal systems.
Budget at least 35 GiB free for this environment and models, or 60 GiB for both PRs;
the LLVM download alone needs approximately 8 GiB.
The earlier reference builds took about 38 minutes for FlagTree and 11.5 minutes for
vLLM. Network access to GitHub, ModelScope, PyPI (or a configured mirror), PyTorch's wheel index,
`oaitriton.blob.core.windows.net` and `developer.download.nvidia.com` is required.
Use the test host's working proxy/package-index configuration for the setup account.
Rerun with the same work directory to reuse verified downloads and compatible build caches.

### Run the W4A8 toolchain test

Check out this PR's test scripts, then run these commands in order from the checkout:

```bash
git clone --single-branch --branch vllm-arm64 https://github.com/kevinzs2048/community.git community-arm64
cd community-arm64
RUN=fep/sig-edge/scripts/vllm-arm64/run.sh
bash "$RUN" setup
bash "$RUN" test w4
```

`test w4` runs operator checks, model preparation, prewarming and HTTP smoke in order.
The individual `operators`, `models w4`, `prewarm w4` and `smoke w4` commands remain
available for resuming a failed stage. `models` resumes LFS downloads and checks SHA256.
An incomplete packed output is not overwritten; select a new empty `W4_PACKED`
directory before retrying.
`prewarm` starts two offline processes to check retained-cache reuse. `smoke` starts
its own localhost server, checks health/models, sends two math chats and stops the server.
No second terminal or manual background-process cleanup is needed.

Defaults are `WORK_DIR=$HOME/arm64-vllm024-test`, `MODEL_ROOT=$HOME/Models` and
CIX P1 big cores `0,1,6,7,8,9,10,11`. On another Arm64 host, identify its big cores
with `lscpu` and export `A720_CORES`, `OMP_NUM_THREADS` and `MKL_NUM_THREADS` first.
Export `WORK_DIR`/`MODEL_ROOT` once to change paths. `SKIP_SYSTEM_PACKAGES=1` skips
apt installation when prerequisites already exist. Sources must have no tracked edits.
Paths are derived from the current account/script location; relative overrides are
resolved before changing directory. Choose a `WORK_DIR` without whitespace or semicolons.
Keep the full `scripts/vllm-arm64` directory when distributing the scripts.
Each PR needs its own `WORK_DIR`; when switching PRs, update a custom value as well.
Run model tests sequentially on the P1. Ports default to W4 `18043` / W8 `18042`;
export `PORT` to select a free port if either is occupied.

### Optional W8A8 compatibility and performance tests

Use the same environment and script entry:

```bash
bash "$RUN" test w8
bash "$RUN" bench w4
bash "$RUN" bench w8
```

`bench` manages a 1024-token server, prewarms both prompt shapes, then measures five
64-output-token streamed requests. Raw records and warm medians are saved. This is
single-user throughput, not a concurrency test. `serve w4` or `serve w8` optionally
leaves a foreground server running for manual clients; stop it with Ctrl-C.

## Test Plan

Keep `$WORK_DIR/logs`: setup output, source revisions, package versions, pytest JUnit
results, offline counters, server logs, HTTP JSON responses and performance JSONL.
The commands stop on failures and enforce the following checks:

| Check | Required result |
|---|---|
| Platform/import verification | Arm64, Triton `3.7.2`, vLLM `0.24.0+cpu`, `CpuPlatform`, vendor `arm` |
| FlagGems numerical suite | **7 passed, 0 skipped** |
| Plugin ARM suites | **16 passed, 0 skipped** |
| W4A8 preparation | Pinned source/derived hashes; exact packing recovery |
| W4A8 offline math | Answer `2`; 168 pack calls at load; 336 request linear calls |
| HTTP math | Health/models HTTP 200; both chats return `2` with completion tokens |
| W8A8 selection | `CPUInt8ScaledMMLinearKernel` in the service log |

[FEP-0082](https://github.com/flagos-ai/community/pull/83) supplies an independent compiler test.
Only the seven FlagGems numerical cases overlap: PR #83 additionally checks the CPU
target and an empty-cache vector kernel; this PR checks vLLM/plugin/model integration.
Run the shared cases in each environment. `test w4` is functional acceptance; run
`bench w4` separately to collect warm TTFT/TPS, and `test w8` for native INT8 compatibility.
The script entries were rerun on 2026-09-17. A minimal Debian 13 container on CIX P1
rebuilt native packages under another account and downloaded/verified the model files;
only downloaded LLVM/JSON/NVIDIA dependency artifacts were reused. Both operator suites,
W4/W8 offline inference and HTTP math passed; managed servers stopped. W4 initialization
was 174.915 s and the first request 906.679 s; retained-cache restart initialization was
17.940 s. Relative-path overrides and standalone script delivery were also tested.
These two-token correctness checks are not TPS. Warm single-user 64-token measurements
on that host (eight big cores, prefix caching disabled) were:

| Model | 43-token prompt: TTFT / decode | 357-token prompt: TTFT / decode |
|---|---|---|
| W4A8 | 0.516 s / 7.58 tok/s | 2.348 s / 7.56 tok/s |
| W8A8 native CPU INT8 | 0.379 s / 4.64 tok/s | 1.526 s / 4.59 tok/s |

These are reproducibility references, not throughput acceptance thresholds.

### Known limitations

**Empty-cache first-use compilation is slow: previous CIX P1 requests took 915.78 s
for W4A8 and 931.6 s for W8A8. No BLOCK_SIZE patch is required by this procedure.**
vLLM's 1024/8192-element Triton bookkeeping/sampling launches can generate wide LLVM
vectors and spend minutes in CPU code generation. `--enforce-eager` does not bypass JIT.
The console may remain at `Warming up model...` or `Processed prompts: 0%` while compiling.
The default 1800-second startup/request wait budgets permit that cost; they are not
performance targets or guaranteed upper bounds. Readiness does not imply every chat
kernel is compiled. Retain logs and compilation progress if a wait expires.

**Prewarming moves compilation into environment preparation; it does not eliminate it.**
Retain `TRITON_CACHE_DIR` and the matching runtime/compiler at the same absolute path:
group cache indexes store absolute child paths, and a fresh build of the same source
can have a different compiler fingerprint. For image delivery, prewarm in the final
image or fixed persistent volume on matching CPU hardware. Different CPU features,
compiler builds, dtypes, limits or sampling paths can trigger additional JIT.
The math warmup does not cover every temperature/top-k/top-p/speculative or long-context path.

Quality needs separate evaluation: the published activation metadata is symmetric,
while FlagGems #5904 uses asymmetric dynamic activation quantization. Quantify its
accuracy impact against a BF16 reference. Long context, concurrency, prefill/decode
coverage and acceptable warm throughput remain separate acceptance items.

## Related PRs

- [vllm-plugin-FL #433](https://github.com/flagos-ai/vllm-plugin-FL/pull/433) — merged ARM CPU integration.
- [FlagGems #5904](https://github.com/flagos-ai/FlagGems/pull/5904) — merged ARM W4A8 operator.
- [FlagTree CPU 3.7](https://github.com/flagos-ai/community/pull/83) — compiler acceptance.

## Implementation History

- 2026-07-29: Initial proposal.
- 2026-09-15/16: Pinned current sources and model blobs; verified W4A8 offline/HTTP
  inference and native W8A8 compatibility. Diagnosed cold JIT and documented cache limits.
- 2026-09-16: Moved enable/preparation/test commands into scripts, kept upstream
  source unmodified and shortened the document to the ordered test entry points.
- 2026-09-17: Rebuilt/retested in minimal Debian 13 under another account; verified
  portable script delivery, fixed relative-path overrides and corrected the disk budget.
- 2026-09-17: Added the FlagOS 2.2 release-boundary note: all three pinned
  implementation dependencies landed after the 2026-08-31 feature freeze, so
  2.2 inclusion remains subject to a release-manager exception.

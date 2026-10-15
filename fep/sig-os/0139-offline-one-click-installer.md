# FEP: Offline One-Click Installer for FlagOS (Runtime + App)

**Status:** `Provisional`

**Created:** 2026-10-14

**Owner:** @tengqm

**SIG:** sig-os

**Target Version:** FlagOS 2.3

---

## Summary

A self-extracting offline bundle that installs the FlagOS **runtime + app
Python layer** — the `torch` stack, compilers, `flag_gems`, and the application
stack (for vLLM: the repacked `vllm+flagos` wheel, `vllm-plugin-fl`, app deps,
and the `vllm-serve` launcher) — on a host with **no network access**, with one
command. The bundle carries the shared runtime layer once and the app layer for
**every supported vLLM version** (today 0.20.2 and 0.24.0; 0.28.0 when its line
lands), and the installer selects one at install time. It is built from the
same `configs.yaml` pins and internal indexes the runtime and app images use, so
the installed result is a bare-metal equivalent of the chosen app image, minus
the vendor SDK/driver (which the host must preinstall) and the model weights.
The first deliverable targets the vLLM app on the generic/NVIDIA backend; other
apps and domestic vendors follow the same mechanism.

This FEP is the implementation plan for the self-extracting offline bundle that
[FEP-19](0019-unified-package-integration.md) and the build-infra
[packaging-channels](https://github.com/flagos-ai/build-infra/blob/main/docs/content/en/usage/packaging-channels.md)
page already reserve as a future layer. It lives in the
[build-infra](https://github.com/flagos-ai/build-infra) repository.

## Motivation

FlagOS currently reaches non-container users only through the deb/rpm and PyPI
channels ([FEP-19](0019-unified-package-integration.md)), both of which resolve
dependencies from a repository at install time. Datacenter hosts are frequently
air-gapped or restricted to domestic links, so any install that touches
`resource.flagos.net`, a CN mirror, or PyPI.org at runtime is unusable there.

The pieces already exist to fix this:

- `configs.yaml` pins the exact Python layer per backend (`deps`, `flagtree`,
  `triton`, `flag_gems`, `runtime_prereqs`, `deps_app`).
- Those wheels live on FlagOS-internal indexes, so the full closure can be
  gathered at build time.
- The runtime `Containerfile` already embeds a hermetic Python (uv-managed
  standalone CPython from `flagos-filestore`), proving the toolchain for a
  no-host-Python install.
- The app `Containerfile` (vLLM) adds only a fixed, enumerable set on top:
  `vllm==<version>+flagos`, `vllm-plugin-fl`, `flagcx`, and `deps_app`.

What is missing is a build step that freezes the runtime + app closure into a
file and a one-command installer that consumes it without the network.

### Goals

- Produce a self-extracting tarball per (app, vendor, backend) that installs
  the runtime + app Python layer offline with a single command, with the app
  version selectable at install time.
- Guarantee the bundle's wheel set is byte-identical to what the runtime and
  app images install, by reusing `configs.yaml` as the single source of truth.
- Record provenance (every wheel's filename, sha256, source index) in a
  machine-readable `MANIFEST`.
- Verify in CI that the bundle installs and imports with the network disabled.
- Start with vLLM on the generic/NVIDIA backend; the mechanism is app- and
  vendor-agnostic.

### Non-Goals

- The bundle does **not** carry vendor SDKs or drivers (several are not
  redistributable — the FEP-19 constraint). The host preinstalls them.
- No deb/rpm native packages in the first cut; the bundle is pip-layer only.
  Per-suite native mixing stays on the FEP-19 deb/rpm track.
- No automatic SDK/driver probing or installation on the host.
- No model weights or datasets; no app config (served model, port) — the user
  supplies those at serve time.
- Container-format extras (the vendor env baked into `/etc/profile.d` and the
  `vllm-serve` exec wrapper) are reproduced in bare-metal form as sourced env
  files and a shell shim, not as image config.

## Proposal

A user on an air-gapped host does:

```bash
tar xzf flagos-vllm-nvidia-cuda12.8-2.3.0.tar.gz
cd flagos-vllm-nvidia-cuda12.8-2.3.0
sudo ./install.sh --prefix /opt/flagos --vllm-version 0.24.0
```

The same bundle installs any supported vLLM version — `--vllm-version` picks
which `requirements-<version>.txt` the install consumes; the runtime layer is
shared across all of them and stored once.

`install.sh` then, with no network:

1. unpacks the embedded standalone CPython (matching the backend's Python
   version) into `$PREFIX` and creates a venv;
2. installs the runtime wheel closure plus the selected vLLM version's delta
   from the embedded `wheelhouse/` using `pip install --no-index --find-links
   -r requirements-<version>.txt`;
3. installs the compiler (FlagTree, and Triton when configured) to its side
   dir and writes the `compiler` shim, mirroring the runtime image layout;
4. writes the vendor env to `$PREFIX/etc/profile.d/` and a `vllm-serve` shim,
   mirroring the app image's env + launcher;
5. runs a smoke test (`import torch; import flag_gems; import triton; import
   vllm`) and fails loudly with a diagnostic if the preinstalled SDK/driver is
   missing or mismatched.

The result is a bare-metal `/opt/flagos` that behaves like the app image's
Python layer. The tarball is built in CI, never by hand.

## Design Details

### Bundle layout

```
flagos-<app>-<vendor>-<backend>-<version>/
├── install.sh             # the only entry point (self-contained bash)
├── MANIFEST               # wheel list: filename, sha256, source index, version
├── requirements.txt       # the runtime-layer == pins (shared by all app versions)
├── requirements-0.20.2.txt / requirements-0.24.0.txt / ...
│                          # per app version: the version-specific delta pins
├── wheelhouse/            # pip --no-index --find-links source, de-duplicated
│                          # across runtime + every app version
└── python/                # standalone CPython tarball + uv (hermetic, no host Python)
```

`install.sh` doubles as the tarball's self-extraction front: the payload
(`wheelhouse/`, `python/`, `MANIFEST`, the `requirements-*.txt` files) is
appended after a marker line, so the single `.tar.gz` is also the installer.

The wheelhouse is **de-duplicated across versions**: a wheel shared by 0.20.2
and 0.24.0 (and 0.28.0 when it lands) is stored once. vLLM releases share the
bulk of their dependency closure — `torch`, the compiler, `flag_gems`,
`vllm-plugin-fl`, most of vLLM's own deps — and differ mainly in the `vllm`
wheel itself and a handful of version-bumped transitive deps, so packing
several versions does not multiply the bundle size. `pip download`'s
flat directory naturally coalesces identical filenames; the per-version
requirements files then select from the shared pool. One bundle holds several
versions; **one install installs exactly one** — `--vllm-version` chooses which.

### Where the wheels come from

The wheelhouse is gathered at build time by `pip download` against the same
indexes and in the same order the runtime `Containerfile` uses
(`configs.yaml` `pypi_base` → `pypi_daily` → `mirror`), so vendor wheels
(`torch==2.10.0+cu128`, `flagcx==0.14.0rc2.post2+cuda12.8`) are the same files
the image installs. No wheel is fetched from PyPI.org directly.

The closure is the backend's `deps:` plus `flagtree:`/`triton:` plus
`flag_gems` plus `runtime_prereqs` (shared, written once to
`requirements.txt`), plus, per app version, the version-specific delta
(`vllm==<version>+flagos`, `vllm-plugin-fl`, `deps_app` for that version),
written to `requirements-<version>.txt`. All read from `configs.yaml` by the
same resolution logic `scripts/build_runtime.py` and the app `Containerfile`
use. One source of truth, multiple consumers (image builds, bundle build) —
they can only drift if the resolver logic does.

The app wheel (`vllm+flagos`) is the repacked wheel from the vendor PyPI, so it
carries no `torch`/`triton` requirements that would perturb the runtime pin
(the repack's `remove_torch_chain` / `remove_cuda_only` rules). This is what
lets `pip install --no-index --find-links wheelhouse/ -r requirements.txt -r
requirements-<version>.txt` reproduce the chosen app image's Python layer
without pip ever resolving against a live index.

### Hermetic Python

The bundle embeds the uv-managed standalone CPython for the backend's
`python:` version, staged from `flagos-filestore/utils/uv-*` and the
`UV_PYTHON_INSTALL_MIRROR` already used by the runtime build. A host with no
matching system Python (or none at all) still installs cleanly.

### Compiler layout

Compilers install to side dirs (`$PREFIX/opt/flagtree`, `$PREFIX/opt/triton`),
not site-packages, with a `compiler` shim — the same contract as
`runtime/zz-compiler.sh`, so a bare-metal install and a container switch
compilers identically.

### SDK/driver boundary

The bundle declares, per backend, the SDK and driver the host must already
have (for `nvidia-cuda12.8`: the NVIDIA driver only — `torch+cu128` bundles
the CUDA runtime). This is recorded in `MANIFEST` and asserted at install time
by the smoke test, not by installing anything.

### Build & publish

- New script `scripts/build_offline_bundle.py <app> <vendor>-<backend> [--push]`:
  resolve from `configs.yaml` → `pip download` the runtime closure plus every
  supported app version's delta → stage standalone CPython + uv → write
  `MANIFEST` (sha256 per wheel) + `requirements.txt` +
  `requirements-<version>.txt` per version → assemble the self-extracting
  tarball.
- New workflow `offline-bundle.yml` (manual, per app + backend): build, run the
  offline verify, upload to `flagos-filestore/offline/`.
- The published URL is the single distribution point, like the existing
  source-tarball and wheel URLs.

## Packaging

**Supported vendors:** generic (NVIDIA) first; domestic vendors follow the
same mechanism with the SDK preinstalled on the host.

**Can this feature be packaged as a wheel (`.whl`)?** No — the deliverable is a
self-extracting tarball, not a Python package. It is built by
`scripts/build_offline_bundle.py` in build-infra and uploaded to
`flagos-filestore/offline/` as
`flagos-<app>-<vendor>-<backend>-<version>.tar.gz`.

- Platform requirements: Linux x86_64 (aarch64 for Ascend later); Python
  version, torch/triton/flagtree pins all from `configs.yaml`.
- Build command: `python scripts/build_offline_bundle.py vllm nvidia-cuda12.8 --push`.

## Test Plan

For vLLM on the generic/NVIDIA backend, on a clean Ubuntu host (or container)
with the NVIDIA driver preinstalled and the network disabled:

- **Bundle build**: `python scripts/build_offline_bundle.py vllm
  nvidia-cuda12.8` produces a tarball whose `MANIFEST` lists every wheel with a
  sha256 and a source index, and one `requirements-<version>.txt` per supported
  vLLM version (0.20.2 and 0.24.0).
- **Offline install, one version at a time**: in a network-disabled container,
  `./install.sh --prefix /opt/flagos --vllm-version 0.20.2` completes without
  any network attempt (asserted by denying egress, not just by not observing
  it); installing 0.24.0 into a fresh prefix with the same bundle likewise
  succeeds.
- **Closure equality**: `MANIFEST` wheel set equals the runtime + app images'
  installed set for the same backend and version (diffed against
  `scripts/build_runtime.py --dry-run` output and the app `Containerfile`
  args).
- **Smoke test**: `import torch; import flag_gems; import triton; import vllm`
  succeeds; a host with no driver fails with a clear diagnostic.
- **Compiler toggle**: `compiler triton` switches to `/opt/triton` and back,
  matching `runtime/zz-compiler.sh` semantics.
- **Serve**: `vllm-serve --model <path>` starts and serves a request, matching
  the app image's launcher.

## Related PRs

- [ ] flagos-ai/community#139 — this FEP
- [x] flagos-ai/build-infra#1348 — `scripts/build_offline_bundle.py` + `offline-bundle.yml` + offline verify

## Implementation History

- 2026-10-14: Initial draft. Scoped to the runtime + app Python layer (vLLM
  first), one bundle carrying all supported vLLM versions with a single
  version installed per run, generic/NVIDIA backend, SDK preinstalled on the
  host; targeted FlagOS 2.3.

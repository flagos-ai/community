# FEP-NNNN: Unified Package Integration for FlagOS Repositories

**Status:** `Provisional`

**Created:** 2026-05-25

**Owner:** @shiptux

**SIG:** sig-architecture

**Target Version:** FlagOS TBD

---

## Summary

This FEP proposes a unified package integration process for FlagOS repositories, covering build metadata, package naming, CI artifacts, release publishing, and acceptance checks across the FlagOS project family. The baseline deliverable for each repository is a pair of distribution packages — a Debian `.deb` and an RPM `.rpm` — published to the shared FlagOS Nexus repository, with container images reserved for builds that need a vendor SDK. The initial scope includes the public FlagOS repositories under https://github.com/flagos-ai, including FlagGems, FlagTree, FlagScale, FlagCX, FlagPerf, FlagAttention, KernelGen, FlagBLAS, FlagDNN, FlagFFT, FlagSparse, FlagTensor, FlagAudio, FlagQuantum, FlagOS-Robo, and the `*-FL` framework/plugin repositories (the `-FL` suffix marks FlagOS-maintained forks of upstream frameworks and their plugins).

## Motivation

FlagOS is composed of many repositories that target different layers of the AI system software stack: operators, compiler, communication, framework plugins, training/inference, benchmarking, kernel generation, and domain-specific runtimes. As these repositories become user-facing deliverables, ad hoc package integration makes it hard to provide a predictable install experience, verify compatibility across chips and software stacks, and track release readiness across SIGs.

The project needs a common FEP-backed process so that adding or merging packages for each `Flag*` repository follows the same review, CI, release, and validation rules.

### Goals

- Define a common package integration process for FlagOS repositories.
- Standardize package naming, versioning, metadata, and repository ownership for generated packages.
- Support repository-specific package formats while keeping shared acceptance criteria.
- Track packaging implementation across all relevant `Flag*` and FlagOS plugin repositories.
- Provide reproducible CI builds and downloadable artifacts for every integrated package.
- Verify installation, import/linking, basic functionality, and dependency compatibility before marking the FEP implemented.

### Non-Goals

- Redesign the source-level build systems of every FlagOS repository.
- Require all repositories to use the same programming language packaging format.
- Replace upstream project release processes for forked repositories.
- Guarantee package availability for every hardware backend in the first implementation wave.
- Define long-term ABI stability policies for all libraries. Short-term ABI and Python-version compatibility remain the responsibility of each repository's SIG; this FEP only requires that known limitations be documented (for example, FlagTree's `cp310`-only wheel does not install on Python 3.11+).

## Proposal

Create a unified package integration track for FlagOS repositories. Each repository that enters the track adds packaging metadata, repeatable build commands, CI jobs, artifact upload, and a minimal package validation suite. Package readiness is reviewed through this FEP and tracked by repository-specific PRs.

The home SIG for this cross-cutting process is `sig-architecture`. Repository-specific SIGs remain responsible for reviewing package behavior and compatibility for their modules:

| SIG | Repositories |
|-----|--------------|
| `sig-operator` | FlagGems, FlagAttention, FlagBLAS, FlagDNN, FlagFFT, FlagSparse, FlagTensor, FlagAudio |
| `sig-compiler` | FlagTree and related compiler/runtime repositories |
| `sig-network` | FlagCX |
| `sig-framework` | PyTorch-Plugin-FL, vllm-plugin-FL, sglang-plugin-FL, TransformerEngine-FL, Megatron-LM-FL, verl-FL |
| `sig-training` | FlagScale |
| `sig-kernelgen` | KernelGen |
| `sig-ai4s` | FlagQuantum |
| `sig-benchmark` | FlagPerf |
| `sig-embodied` | FlagOS-Robo |

The integration is staged. Wave 1 is anchored by the repositories that already have open packaging PRs (see [Related PRs](#related-prs)); later waves cover repositories that still need build-system cleanup or have no user-facing install target yet.

| Wave | Repositories | Rationale |
|------|--------------|-----------|
| 1 | FlagCX, FlagTree, FlagGems, FlagScale, FlagQuantum, FlagTensor, FlagAudio, FlagBLAS, FlagDNN, FlagAttention, FlagSparse | Packaging PRs already open and following the shared layout. |
| 2 | FlagFFT, KernelGen, FlagPerf | Need backend-matrix definition, build-system cleanup, or a clear install target before packaging. |
| 3 | FlagOS-Robo, PyTorch-Plugin-FL, vllm-plugin-FL, sglang-plugin-FL, TransformerEngine-FL, Megatron-LM-FL, verl-FL | Plugin/fork or experimental repositories where packages are optional and depend on host-framework versioning decisions. |

Wave membership can change as repositories progress; the authoritative status is the checklist in [Related PRs](#related-prs).

## Design Details

Each integrated repository should provide:

- A package ownership record at `packaging/MANIFEST.yaml` that maps the package to its source repository, SIG, maintainers, supported platforms, and supported hardware backends. A minimal schema:

  ```yaml
  source: flagos-ai/FlagCX
  sig: sig-network
  maintainers: [<github-handle>]
  packages:
    - name: libflagcx-nvidia
      format: [deb, rpm]
      backend: nvidia
    - name: libflagcx-metax
      format: [deb, rpm]
      backend: metax
  platforms: [ubuntu-24.04, fedora-43]
  ```

- A canonical build entry point that can run in CI and locally (see [Packaging](#packaging)).
- Package metadata that declares runtime and development dependencies instead of relying on hidden environment state.
- A minimal install validation test that runs from the generated package rather than the source tree.
- CI artifact upload for PR builds and release publishing for tagged builds.
- A release checklist that records package names, versions, supported platforms, and known limitations.

### Versioning

- Package versions derive from the repository's own release version (git tag `vX.Y.Z`), not from an independent packaging counter; the upstream version maps directly to the Debian/RPM upstream-version field (for example tag `v5.0.2` produces `python3-flag-gems_5.0.2-1`).
- The trailing Debian revision / RPM release number (`-1`) is reserved for packaging-only changes that do not change upstream source.
- Each repository declares which of its versions map to a given FlagOS release matrix in its `MANIFEST.yaml` or release checklist; cross-repository version alignment is owned by the release manager, not encoded per package.

Package names should be predictable:

- Python modules packaged as system packages use the distribution Python prefix, not the bare module name. The name after the prefix derives from the upstream import name with underscores converted to hyphens, so module `flag_gems` becomes `python3-flag-gems` while single-word modules keep their form, as in `python3-flagscale` and `python3-flagquantum`.
- Native shared libraries use lower-case names with backend suffixes when the binary is hardware-specific, for example `libflagcx-nvidia` and `libflagcx-metax`.
- Compiled Python packages that are hardware-specific carry the same backend suffix, for example `python3-flagtree-nvidia`.
- Development packages use a `-dev` suffix for headers, CMake files, or static metadata where the platform package format supports it.
- Plugin packages include the host framework in the name when needed to avoid ambiguity.

The canonical backend suffixes are: `nvidia`, `metax`, `ascend`, `rocm` (AMD), `cambricon`, `iluvatar`, `kunlunxin`, `mthreads`, `enflame`, `hygon`, `aipu`, `sunrise`, `tsingmicro`. Repositories reuse these suffixes rather than inventing new ones; new backends extend this list through this FEP.

Two backend-handling patterns are both acceptable:

- **Per-backend packages** for compiled artifacts whose binary content differs by hardware, for example FlagCX (`libflagcx-nvidia`, `libflagcx-metax`) and FlagTree (`python3-flagtree-nvidia`).
- **Single multi-backend package** for pure-Python projects that select the backend at runtime, for example FlagGems ships one `python3-flag-gems` containing all backends and selects via the `GEMS_VENDOR` environment variable or framework auto-detection.

Backend-specific packages must not conflict at the file level unless they are intentionally mutually exclusive. Where multiple backends can coexist, package names, library paths, and library `SONAME`s must be unique per backend so the packages co-install cleanly.

## Packaging

### Repository layout

Packaging lives under a top-level `packaging/` directory, never a top-level `/debian`. This follows the Debian [UpstreamGuide](https://wiki.debian.org/UpstreamGuide) recommendation that upstream projects keep packaging out of `/debian` to avoid conflicting with distribution maintainers, and it lets a single repository carry both Debian and RPM metadata. The shared layout is:

```
packaging/
├── MANIFEST.yaml                       # package ownership record
├── debian/
│   ├── control, rules, changelog, copyright, source/format
│   └── build-helpers/
│       ├── build-<slug>.sh             # containerized build entry point
│       └── Dockerfile.deb
└── rpm/
    ├── specs/<slug>.spec
    └── build-helpers/
        ├── build-<slug>.sh
        └── Dockerfile.rpm
```

### Build interface

Every repository exposes a containerized build entry point per format, so a clean build needs no host build dependencies beyond Docker:

```bash
# Debian package
bash packaging/debian/build-helpers/build-<slug>.sh   # -> debian-packages/*.deb

# RPM package
bash packaging/rpm/build-helpers/build-<slug>.sh       # -> rpm-packages/*.rpm
```

Backend-specific repositories take the backend (and optionally a base-image version) as an argument, for example FlagCX:

```bash
bash packaging/debian/build-helpers/build-flagcx.sh nvidia        # -> debian-packages/nvidia/*.deb
bash packaging/debian/build-helpers/build-flagcx.sh metax v1.2.3
```

Backend builds that need a vendor SDK pull a prebuilt base image from the FlagOS registry rather than installing the SDK in CI, by convention `harbor.baai.ac.cn/flagbase/flagbase-<backend>:<version>`.

### Package formats

- **Debian `.deb` and RPM `.rpm`** are the baseline formats every repository ships, for both pure-Python packages (`python3-<slug>`) and native libraries (`lib<name>-<backend>`).
- **Python wheel via `pip`/PyPI** is a first-class distribution channel in its own right for Python projects: users who prefer `pip install` over the system package manager should be served by a published wheel. Where the wheel is compiled and ABI-specific it is additionally wrapped inside the `.deb`/`.rpm` (for example FlagTree's `cp310` wheel becomes `python3-flagtree-nvidia`).
- **Container image** only when a package requires a vendor SDK or driver stack that cannot be installed in a generic CI runner.

### Platform matrix

Platform requirements are declared per repository in `MANIFEST.yaml`. The baseline matrix that Wave 1 actually pre-builds and validates is **Ubuntu 24.04** (Debian) and **Fedora 43** (RPM), on `amd64`. Other distributions (Ubuntu 22.04, Debian Trixie, RHEL/openEuler, and so on) are out of scope for this baseline; adapting and validating them is owned by the corresponding distribution SIG or downstream packager, not by this FEP's Wave 1. Repositories additionally declare, where relevant:

- Python version (and whether the package is `noarch` or ABI-specific).
- CUDA, ROCm, MACA, Ascend, or other vendor SDK version.
- Host framework version, for example PyTorch, vLLM, SGLang, Megatron-LM, or TransformerEngine.
- Compiler/runtime dependency version.

### Publishing

Tagged builds publish to the shared **FlagOS Nexus** repository at `https://resource.flagos.net`, exposing an APT repository (`flagos-apt-hosted`) and, as RPM support lands, a matching YUM repository. End users install with the platform package manager:

```bash
# Debian/Ubuntu
echo "deb https://resource.flagos.net/repository/flagos-apt-hosted/ flagos-apt-hosted main" | \
  sudo tee /etc/apt/sources.list.d/flagos.list
sudo apt-get update
sudo apt-get install libflagcx-nvidia libflagcx-nvidia-dev
```

### Reference implementation

The FlagCX packaging work ([FlagCX#476](https://github.com/flagos-ai/FlagCX/pull/476)) is the reference for the native-library path: it defines backend-specific `libflagcx-nvidia`/`libflagcx-metax` packages via Debian build profiles, ships both `.deb` and `.rpm`, and publishes to FlagOS Nexus. FlagGems ([FlagGems#3418](https://github.com/flagos-ai/FlagGems/pull/3418)) is the reference for the pure-Python multi-backend path.

## Test Plan

Each repository package integration PR must include checks for the goals above:

- Build: package artifacts are produced in CI from a clean checkout.
- Install: generated packages install in a clean environment without undeclared source-tree dependencies.
- Smoke test (packaging CI): the installed package is verified at the install-layout level only — `find_spec` for Python modules, `ldconfig`/link for native libraries — since generic CI runners have no accelerator. This must not perform a full `import` of code that pulls in `torch`/`triton`/CUDA.
- Functionality check (backend hardware): full `import`, execution, and heavy/functional tests run on machines with the matching backend hardware, owned by the repository's SIG, not in the packaging CI. The FEP requires that such a test exists and is referenced; it does not require it to run on the generic packaging runner.
- Dependency check: package metadata declares required runtime dependencies and does not rely on CI-only state.
- Backend check: hardware-specific packages build and install for each claimed backend, or document the unsupported backend.
- Version check: the package version matches the source release tag and follows the `X.Y.Z-N` scheme defined in [Versioning](#versioning).
- Compatibility check: package versions align with the target FlagOS release matrix.
- Artifact check: PR builds upload artifacts and tagged builds publish release artifacts.
- Uninstall or conflict check: packages either co-install cleanly or declare explicit conflicts.

Examples:

```bash
# Python system-package smoke test (deb/rpm)
# Use find_spec, not `import`, so the check validates the install layout
# without pulling in heavy runtime deps (torch/triton) at packaging time.
sudo apt-get install -y python3-flag-gems   # or: sudo dnf install python3-flag-gems
python3 -c "import importlib.util, sys; sys.exit(importlib.util.find_spec('flag_gems') is None)"

# Native library smoke test (deb/rpm)
sudo dpkg -i ./libflagcx-nvidia_*.deb ./libflagcx-nvidia-dev_*.deb
dpkg -L libflagcx-nvidia
ldconfig -p | grep flagcx

# Native link test from the -dev package
echo 'int main(){return 0;}' > t.c
gcc t.c -lflagcx -o /dev/null   # headers + .so resolved from the installed package
```

The FEP should only move to `Implemented` after all Wave 1 repositories have merged their package integration PRs and the release manager confirms that artifacts are available for the target FlagOS release.

## Related PRs

This list is a snapshot; the authoritative tracking lives in the FEP tracking issue. The FEP still needs an assigned number (`FEP-NNNN`): the PR number becomes the identifier, and the file is renamed to `NNNN-unified-package-integration.md` before merge.

**Wave 1 (open PRs):**

- [ ] flagos-ai/community#NNNN - this FEP
- [ ] [flagos-ai/FlagCX#476](https://github.com/flagos-ai/FlagCX/pull/476) - deb/rpm for backend-specific `libflagcx-{nvidia,metax}` runtime and dev files
- [ ] [flagos-ai/FlagTree#607](https://github.com/flagos-ai/FlagTree/pull/607) - deb/rpm wrapping `python3-flagtree-nvidia` wheel
- [ ] [flagos-ai/FlagGems#3418](https://github.com/flagos-ai/FlagGems/pull/3418) - `python3-flag-gems` (multi-backend, runtime selection)
- [ ] [flagos-ai/FlagScale#1205](https://github.com/flagos-ai/FlagScale/pull/1205) - `python3-flagscale` (noarch CLI)
- [ ] [flagos-ai/FlagQuantum#4](https://github.com/flagos-ai/FlagQuantum/pull/4) - `python3-flagquantum`
- [ ] [flagos-ai/FlagTensor#4](https://github.com/flagos-ai/FlagTensor/pull/4) - `python3-flagtensor`
- [ ] [flagos-ai/FlagAudio#2](https://github.com/flagos-ai/FlagAudio/pull/2) - `python3-flag-audio`
- [ ] [flagos-ai/FlagBLAS#1](https://github.com/flagos-ai/FlagBLAS/pull/1) - `python3-flag-blas`
- [ ] [flagos-ai/FlagDNN#1](https://github.com/flagos-ai/FlagDNN/pull/1) - `python3-flag-dnn`
- [ ] [flagos-ai/FlagAttention#31](https://github.com/flagos-ai/FlagAttention/pull/31) - `python3-flag-attention`
- [ ] [flagos-ai/FlagSparse#12](https://github.com/flagos-ai/FlagSparse/pull/12) - `python3-flagsparse`

**Wave 2 / 3 (not yet started):**

- [ ] flagos-ai/FlagFFT#TBD - package integration
- [ ] flagos-ai/KernelGen#TBD - package integration
- [ ] flagos-ai/FlagPerf#TBD - package integration
- [ ] flagos-ai/FlagOS-Robo#TBD - package integration
- [ ] flagos-ai/PyTorch-Plugin-FL#TBD - package integration
- [ ] flagos-ai/vllm-plugin-FL#TBD - package integration
- [ ] flagos-ai/sglang-plugin-FL#TBD - package integration
- [ ] flagos-ai/TransformerEngine-FL#TBD - package integration
- [ ] flagos-ai/Megatron-LM-FL#TBD - package integration
- [ ] flagos-ai/verl-FL#TBD - package integration

## Implementation History

- 2026-05-25: Initial draft prepared for discussion.
- 2026-05-26: Revised against the eleven open Wave 1 packaging PRs. Added RPM as a baseline format alongside Debian, replaced the proposed `./packaging/build.sh` interface with the actual `packaging/{debian,rpm}/build-helpers/build-<slug>.sh` layout, defined the verified platform matrix (Ubuntu 24.04, Fedora 43), specified FlagOS Nexus as the publish target, added versioning and ownership-record (`MANIFEST.yaml`) rules, listed canonical backend suffixes, populated concrete Wave assignments and PR links, and corrected the Python smoke test to use `importlib.util.find_spec`.

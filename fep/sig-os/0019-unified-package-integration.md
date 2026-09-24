# FEP-19: Unified Package Integration for FlagOS Repositories

**Status:** `Implementable`

**Updated:** 2026-09-24

**Created:** 2026-05-25

**Owner:** @shiptux

**SIG:** sig-os

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| flagcx | [`0.14.0-rc2` @ `5154fdbf3327`](https://github.com/flagos-ai/flagcx/tree/5154fdbf3327c1c7c272e8a83684e1508a302206) | [`v0.14.0-rc2.post1` @ `cb8896cacd49`](https://github.com/flagos-ai/flagcx/tree/cb8896cacd49ef9901c39af18df9b89bd6b9f34c) |
| flagtree-triton3.6 | [`0.7.0-rc2-triton3.6` @ `4819c190476c`](https://github.com/flagos-ai/FlagTree/tree/4819c190476cebb66057493e41379c1406c615ac) | [`0.7.0rc2.post2+triton3.6` @ `d9e65f4df7fe`](https://github.com/flagos-ai/FlagTree/tree/d9e65f4df7fe881281abd9e834ab3f37f4d0642c) |
| flaggems | [`5.4.0-rc2` @ `6ed2f39071ef`](https://github.com/flagos-ai/FlagGems/tree/6ed2f39071ef85db26b7e64f0652a162f434959c) | [`v5.4.0-rc2.post4` @ `6ed2f39071ef`](https://github.com/flagos-ai/FlagGems/tree/6ed2f39071ef85db26b7e64f0652a162f434959c) |
| flagtensor | [`0.3.0-rc2` @ `bcc97844bf17`](https://github.com/flagos-ai/FlagTensor/tree/bcc97844bf17e169705802ac1231e91df470f279) | [`v0.3.0-rc2.post2` @ `bcc97844bf17`](https://github.com/flagos-ai/FlagTensor/tree/bcc97844bf17e169705802ac1231e91df470f279) |
| flagaudio | [`0.3.0-rc2` @ `00b07b261e70`](https://github.com/flagos-ai/FlagAudio/tree/00b07b261e7035d7193113db012fd96a8f9917de) | [`v0.3.0-rc2.post2` @ `00b07b261e70`](https://github.com/flagos-ai/FlagAudio/tree/00b07b261e7035d7193113db012fd96a8f9917de) |
| flagblas | [`0.3.0-rc2` @ `824b256fe4c5`](https://github.com/flagos-ai/FlagBLAS/tree/824b256fe4c5a0e5a8645f4752248bcdfcb61d6f) | [`v0.3.0-rc2.post2` @ `a1897220dd06`](https://github.com/flagos-ai/FlagBLAS/tree/a1897220dd06596e44e8add94cfb084b41cbb98a) |
| flagdnn | [`0.3.0-rc2` @ `42bcbcc23beb`](https://github.com/flagos-ai/FlagDNN/tree/42bcbcc23beb8d6af287485c0df55935f38f92e9) | [`v0.3.0-rc2.post2` @ `42bcbcc23beb`](https://github.com/flagos-ai/FlagDNN/tree/42bcbcc23beb8d6af287485c0df55935f38f92e9) |
| flagattention | [`0.4.0-rc2` @ `ff6a63543741`](https://github.com/flagos-ai/FlagAttention/tree/ff6a63543741953c7c48a478211794b113064429) | [`v0.4.0-rc2.post1` @ `2dd3a7408c3f`](https://github.com/flagos-ai/FlagAttention/tree/2dd3a7408c3ff1b11baccb8758392c5da5f3aef6) |
| flagsparse | [`0.3.0-rc2` @ `b15bbcc509d3`](https://github.com/flagos-ai/FlagSparse/tree/b15bbcc509d388c27bff7e8b180017aefc7ed1f4) | [`v0.3.0-rc2.post1` @ `2d4eee7ff0a6`](https://github.com/flagos-ai/FlagSparse/tree/2d4eee7ff0a6095dc8daf28a0dd2c4e0d76e0ad5) |
| flagscale | [`2.1.0-rc2` @ `333964d5937e`](https://github.com/flagos-ai/FlagScale/tree/333964d5937ec2401d4324b92569158c663154de) | [`v2.1.0-rc2.post2` @ `333964d5937e`](https://github.com/flagos-ai/FlagScale/tree/333964d5937ec2401d4324b92569158c663154de) |
| flagfft | [`0.2.0-rc2` @ `5eecfd409b65`](https://github.com/flagos-ai/FlagFFT/tree/5eecfd409b655458a7b0d4aaad53f802660bc66f) | [`v0.2.0-rc2.post2` @ `5eecfd409b65`](https://github.com/flagos-ai/FlagFFT/tree/5eecfd409b655458a7b0d4aaad53f802660bc66f) |

## Summary

Provide Debian and RPM packages for eleven FlagOS repositories, with Python
wheels for Python projects, reproducible builds and release publication to
FlagOS Nexus. Nine Wave 1 repositories contain Debian and RPM build code in
RC2. FlagScale and FlagQuantum remain incomplete. Artifact publication and
installation acceptance are still required.

## Goals and Completion

| Wave 1 repository | Source status | Remaining work |
|---|---|---|
| FlagCX | Debian/RPM backend packages present | Validate published artifacts and declared backends |
| FlagTree | Debian/RPM wheel packaging present on the 3.6 line | Validate backend, Python ABI and toolkit combinations |
| FlagGems | Packaging port #6394 and Nexus workflow #6401 present | Validate release artifacts |
| FlagTensor | Packaging port #19 and publication workflow #21 present | Validate release artifacts |
| FlagAudio | Packaging port #7 and publication workflow #9 present | Validate release artifacts |
| FlagBLAS | Packaging port #116 and RPM fix #125 present | Validate native runtime/development packages |
| FlagDNN | Native NVIDIA packaging port #13 present | Complete publication and install validation |
| FlagAttention | Packaging #31 and later RPM fix #74 present | Validate release artifacts |
| FlagSparse | Packaging #12 and later RPM fixes present | Validate release artifacts |
| FlagScale | PR #1205 open; no RC2 packaging tree | Merge integration and complete package acceptance |
| FlagQuantum | PR #4 open; no RC2 branch or manifest entry | Complete integration and assign a release artifact |

FlagFFT, originally Wave 2, also has Debian/RPM packaging in its RC2 branch.
It does not replace either missing Wave 1 repository. KernelGen and FlagPerf
remain later-wave targets. Framework plugins, training forks and FlagOS-Robo
retain host-framework-specific packaging decisions.

## Package Contract

Each repository supplies build scripts, runtime/development dependencies,
supported platforms and backends, install checks, CI artifacts and tagged
release publication. Ownership and compatibility metadata belong in
`packaging/MANIFEST.yaml` or the release checklist; the common manifest is
not yet implemented consistently across repositories.

- Source versions follow each module's release tag. Debian revision and RPM
  release fields identify packaging-only changes. RC and local-version
  suffixes must preserve the source revision's identity.
- Python system packages use `python3-` plus the normalized import name;
  `flag_gems` becomes `python3-flag-gems`.
- Native libraries use `lib<name>-<backend>`. Compiled Python packages may
  also use backend suffixes. Development packages follow distribution naming
  conventions and include headers and link metadata.
- Pure-Python projects may ship one package with runtime vendor selection.
  Binary packages declare their backend, SDK and Python ABI.
- Packages either co-install without file/SONAME conflicts or declare an
  explicit conflict. ABI compatibility remains owned by the module.

Backend names include `nvidia`, `metax`, `ascend`, `rocm`, `cambricon`,
`iluvatar`, `kunlunxin`, `mthreads`, `enflame`, `hygon`, `sunrise`,
`tsingmicro` and `ppu`. Build-script identifiers may differ; the package
metadata must record that mapping.

## Build and Publication

Packaging lives under `packaging/debian/` and `packaging/rpm/`. The RC2
scripts use these entry-point forms:

```text
packaging/debian/build-helpers/build-<slug>.sh
packaging/rpm/build-<slug>-rpm.sh
```

For FlagCX's NVIDIA package:

```bash
bash packaging/debian/build-helpers/build-flagcx.sh nvidia
bash packaging/rpm/build-flagcx-rpm.sh nvidia
```

Use each script's declared container and backend arguments. Builds requiring
a vendor SDK use a compatible vendor image. The original baseline is Linux
amd64 on Ubuntu 24.04 and Fedora 43; the FlagTree RC2 branch additionally
contains Ubuntu 22.04 packaging support. Distribution and Python support
must follow the actual artifact matrix.

Tagged Debian/RPM builds target [FlagOS Nexus](https://resource.flagos.net).
Python wheels also target PyPI. A publication workflow in the source tree
does not establish that a particular version is downloadable.

## Test Plan

For every Wave 1 repository:

1. Build both formats from a clean checkout and record the source SHA,
   container, package version, architecture, backend and Python ABI.
2. Install the generated artifacts in clean distribution containers. Check
   declared dependencies, installed paths and package removal/conflicts.
3. On generic CI, resolve Python modules without importing accelerator
   runtimes, or verify native library/header installation and linking.
4. On matching hardware, import and execute the module's functional smoke
   test from the installed package, outside the source checkout.
5. Verify the release artifacts can be downloaded from Nexus and, for
   Python projects, the wheel index. Compare metadata with the release
   manifest and preserve checksums.

Python install-layout check for FlagGems:

```bash
python3 -c "import importlib.util, sys; sys.exit(importlib.util.find_spec('flag_gems') is None)"
```

Completion requires all eleven Wave 1 integrations and their artifact and
installation results. Tracking: [community#59](https://github.com/flagos-ai/community/issues/59).

## Recorded Validation

The inspected RC2 CI runs successfully built Debian and RPM packages for
FlagAudio and FlagGems; FlagFFT's Debian build also passed. Publication jobs
and other package builds include failures. Successful package builds do not
cover download and clean-install acceptance for all eleven repositories.
FlagScale #1205 and FlagQuantum #4 remain open integrations.

## Related PRs

- [x] [FlagCX#476](https://github.com/flagos-ai/FlagCX/pull/476) — Backend-specific Debian and RPM packages. Merged.
- [x] [FlagTree#607](https://github.com/flagos-ai/FlagTree/pull/607) — Initial compiler wheel packaging. Merged.
- [x] [FlagTree#1204](https://github.com/flagos-ai/FlagTree/pull/1204) — RC2 Nexus publication. Merged.
- [x] [FlagTree#1207](https://github.com/flagos-ai/FlagTree/pull/1207) — Ubuntu 22.04 support. Merged.
- [x] [FlagTree#1208](https://github.com/flagos-ai/FlagTree/pull/1208) — Wheel stripping control. Merged.
- [x] [FlagTree#1209](https://github.com/flagos-ai/FlagTree/pull/1209) — Package version handling. Merged.
- [x] [FlagGems#6394](https://github.com/flagos-ai/FlagGems/pull/6394) — RC2 packaging port. Merged.
- [x] [FlagGems#6401](https://github.com/flagos-ai/FlagGems/pull/6401) — RC2 Nexus publication. Merged.
- [x] [FlagTensor#19](https://github.com/flagos-ai/FlagTensor/pull/19) — RC2 packaging port. Merged.
- [x] [FlagTensor#21](https://github.com/flagos-ai/FlagTensor/pull/21) — Nexus publication. Merged.
- [x] [FlagAudio#7](https://github.com/flagos-ai/FlagAudio/pull/7) — RC2 packaging port. Merged.
- [x] [FlagAudio#9](https://github.com/flagos-ai/FlagAudio/pull/9) — Nexus publication. Merged.
- [x] [FlagBLAS#116](https://github.com/flagos-ai/FlagBLAS/pull/116) — RC2 native packaging port. Merged.
- [x] [FlagBLAS#125](https://github.com/flagos-ai/FlagBLAS/pull/125) — RPM source archive fix. Merged.
- [x] [FlagDNN#13](https://github.com/flagos-ai/FlagDNN/pull/13) — RC2 native NVIDIA packaging port. Merged.
- [x] [FlagAttention#31](https://github.com/flagos-ai/FlagAttention/pull/31) — Debian and RPM packaging. Merged.
- [x] [FlagAttention#74](https://github.com/flagos-ai/FlagAttention/pull/74) — RPM source archive fix. Merged.
- [x] [FlagSparse#12](https://github.com/flagos-ai/FlagSparse/pull/12) — Debian and RPM packaging. Merged.
- [ ] [FlagScale#1205](https://github.com/flagos-ai/FlagScale/pull/1205) — Wave 1 package integration. Open.
- [ ] [FlagQuantum#4](https://github.com/flagos-ai/FlagQuantum/pull/4) — Wave 1 package integration. Closed without merge.
- [x] [FlagFFT#12](https://github.com/flagos-ai/FlagFFT/pull/12) — Wave 2 package integration. Merged.

# FEP-NNNN: Introduce Thrive to FlagTree

**Status:** `Implemented`

**Created:** 2026-05-27

**Owner:** @Liam-461-Lee

**SIG:** sig-compiler

**Target Version:** FlagOS 2.1

---·

## Summary

This FEP proposes introducing the Thrive backend into FlagTree as a new AI chip backend under the FlagTree unified compiler framework. FlagTree is an open-source unified compiler project that targets multiple AI accelerators and aims to foster a diverse AI chip compiler ecosystem while strengthening the upstream and downstream Triton communities. In its initial phase, FlagTree preserves compatibility with existing backend adaptation approaches while consolidating multiple backends into a single repository to provide multi-backend support in-tree. This proposal adds the Thrive backend implementation on FlagTree's `triton_v3.6.x` branch, so that Thrive users can write and run kernels using interfaces compatible with Triton 3.6, and so that downstream Thrive adopters obtain a practical reference for integrating with the Triton ecosystem.

- Repository: https://github.com/flagos-ai/FlagTree
- Implementation PR: https://github.com/flagos-ai/FlagTree/pull/625

## Motivation

Introducing Thrive into FlagTree addresses the following needs:

- Providing Thrive users with a unified programming entry point aligned with the Triton 3.6 language interfaces, lowering the cost of cross-chip migration.
- Enabling Thrive to reuse FlagTree's upstream and downstream toolchain capabilities (TLE language extensions are not yet supported and are tracked as a follow-up TODO; see Non-Goals and Implementation History).
- Providing compiler support for FlagOS models and operator libraries (such as FlagGems) that run on Thrive chips.

### Goals

- Integrate the Thrive backend into FlagTree's `triton_v3.6.x` branch so that it can be built in-tree within FlagTree while remaining compatible with the Triton 3.6.x programming language interfaces.
- Organize the Thrive backend code under `third_party/thrive` following FlagTree conventions, with minimally invasive adaptations to the necessary extension points in shared directories.
- Provide Thrive-specific documentation for the `triton_v3.6.x` branch, covering container environment setup, source build commands, binary installation commands, compiler test cases, and test procedures.

### Non-Goals

- Adapting operator libraries (such as FlagGems) on Thrive chips is out of scope for this FEP and will be tracked separately under the corresponding module's FEP.
- This FEP does not modify upstream Triton language semantics; backend specialization is performed only within the extension points defined by FlagTree.
- **At this stage, the Thrive backend does not support FlagTree Language Extensions (TLE).** It only guarantees compatibility with the native Triton 3.6 language interfaces; TLE adaptation is tracked as a follow-up TODO.

## Proposal

- Users can follow the Thrive backend documentation to set up a development environment and either build the Thrive backend from FlagTree's `triton_v3.6.x` branch or install a prebuilt FlagTree wheel for the Thrive backend.
- After installing the compiler, users can write and run Triton kernels compatible with the Triton 3.6 interfaces; FlagTree compiles them through the Thrive backend and executes them on Thrive devices.

## Design Details

This section describes the implementation aligned with [flagos-ai/FlagTree#625](https://github.com/flagos-ai/FlagTree/pull/625), focusing on the Thrive backend addition and its TLE support status:

- **Backend addition**:
  - Code location: the new Thrive backend code resides under `third_party/thrive` and includes the compiler backend, Python bindings, build scripts, and test cases.
  - Backend selection: users enable the Thrive backend in an in-tree build through the `FLAGTREE_BACKEND=thrive` environment variable.
  - Setup registration: in `python/setup_tools/utils/tools.py`, `thrive` is registered into `FlagtreeConfigs.plugin_backends` and the entry `"thrive": "thrive"` is added to `device_mapping`; a new module `python/setup_tools/utils/thrive.py` provides `get_backend_cmake_args`, which points `CMAKE_INSTALL_PREFIX` to the build artifact path.
  - Toolchain / libdevice: the Thrive backend uses the system-installed toolchain and libdevice paths and does not bundle binary dependencies inside the repository.
  - Test cases: a PGAS-based distributed language-extension example, `test_allgather.py`, is introduced together with the backend; the functionality is not yet supported and is kept only as an interface and semantic reference.
- **TLE support status**:
  - The Thrive backend currently **does not enable** FlagTree's Language Extensions (TLE) mechanism (`thrive` is not included in `language_extra_backends` within `tools.py`); it targets only the native Triton 3.6 language interfaces.
  - TLE adaptation is tracked as a follow-up TODO. Subsequent PRs are expected to add TLE specializations under `third_party/thrive` and to include `thrive` in `language_extra_backends` in the configuration above.

## Packaging

Once this FEP lands, dedicated documentation for environment preparation, build, and installation of the Thrive backend on the `triton_v3.6.x` branch will be added:

- thrive: https://github.com/flagos-ai/FlagTree/blob/main/documents/install_thrive.md *(to be added)*

Packaging form:

- Build command: `FLAGTREE_BACKEND=thrive LLVM_SYSPATH=/work/llvm-f6ded0be-ubuntu-x64 python setup.py bdist_wheel`
- Distribution format: pip wheel

## Test Plan

The goals listed above are verified across the following dimensions:

- **Functional**: run the unit tests under [`third_party/thrive/test/unit/runtime`](https://github.com/flagos-ai/FlagTree/tree/d1c0d51ee379bd8ac87db4864742b587ca323982/third_party/thrive/test/unit/runtime) and [`third_party/thrive/test/unit/language`](https://github.com/flagos-ai/FlagTree/tree/d1c0d51ee379bd8ac87db4864742b587ca323982/third_party/thrive/test/unit/language) on Thrive devices, covering:
  - `runtime`: driver/launcher, memory management, compilation caching, and kernel launch behaviors under the Triton 3.6 interfaces.
  - `language`: operator and intrinsic semantics compatible with the native Triton 3.6 language interfaces.
- **Build and install**: verify that both source build and wheel installation under `FLAGTREE_BACKEND=thrive` succeed reproducibly in a clean container environment.
- **Regression**: ensure that the new Thrive backend does not break the build or tests of existing backends.

## Related PRs

- [ ] [flagos-ai/FlagTree#625](https://github.com/flagos-ai/FlagTree/pull/625) — [BACKEND] Introduce thrive backend to FlagTree (integrates the Thrive backend on the `triton_v3.6.x` branch, covering the build system, setup flow, third-party directory, and the distributed all-gather example case).
- [ ] flagos-ai/FlagTree#xxx — Add Thrive backend documentation (`install_thrive.md`) *(to be submitted)*
- [ ] flagos-ai/FlagTree#xxx — **TODO**: Enable FlagTree Language Extensions (TLE) for Thrive backend *(to be submitted)*

## Implementation History

- 2026-05-27: Opened the merge PR [flagos-ai/FlagTree#625](https://github.com/flagos-ai/FlagTree/pull/625) on FlagTree.
- 2026-05-27: FEP created (Provisional).

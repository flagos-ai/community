# FEP-NNNN: FlagTree - Multi-Backend Integration with Triton 3.6

**Status:** `Implementable`

**Created:** 2026-05-26

**Owner:** zhzhcookie

**SIG:** sig-compiler

**Target Version:** FlagOS 2.1

---

## Summary

FlagTree is an open-source unified compiler project for multiple AI accelerator backends. It is designed to foster a diverse AI chip compiler ecosystem and provide related tooling platforms that strengthen both upstream and downstream integration with the Triton ecosystem. In its initial phase, FlagTree aims to preserve compatibility with existing backend adaptation approaches while unifying the codebase to deliver multi-backend support in a single repository. For upstream model users, it provides unified compilation capabilities across multiple backends. For downstream chip vendors, it provides practical examples of integration with the Triton ecosystem.

Repository: https://github.com/flagos-ai/FlagTree

## Motivation

Some FlagTree backends were based on older Triton releases, such as Triton 3.0 and 3.1, which were released in September 2024. Upgrading these backends to Triton 3.6 addresses the following needs:
- Align with the latest Triton language interfaces and the broader Triton ecosystem.
- Adopt new Triton features to improve performance.
- Keep pace with FlagTree language extensions (TLE) and related performance optimizations.

### Goals

- Integrate multiple backends into the FlagTree `triton_v3.6.x` branch. Backends such as enflame, hcu, and mthreads will be upgraded and integrated into the `triton_v3.6.x` branch, enabling FlagTree to build selected backends in-tree while remaining compatible with the Triton 3.6.x programming language interfaces.
- Provide backend-specific documentation for the `triton_v3.6.x` branch, including container environment setup, source build commands, binary installation commands, compiler test cases, and test procedures.

### Non-Goals

- Does not provide model runtime environments, which are delivered by FlagRelease.

## Proposal

- Users can follow the provided documentation to set up a development environment and build selected backends from the FlagTree `triton_v3.6.x` branch, or install backend-specific FlagTree wheels without building from source.
- After installing the compiler, users can compile and run Triton operators that are compatible with the Triton 3.6 interfaces.

## Design Details

- Backend code is integrated into each backend's directory under `third_party` according to the project conventions.
- Shared directories may be updated as needed for compatibility. Following Triton conventions, specializations for newly integrated backends may be added only where the existing code already enumerates backend-specific implementations. Other backend-specific code should remain under `third_party`.
- Build modules implement backend-specific dependencies and backend-specific build flows.
- Eligible backends use a unified specialization mechanism for Python code. This is implemented through `PYTHONPATH` injection so that specialized Python files under `third_party` take precedence.

## Packaging

Backend-specific environment preparation, build, and installation commands for the `triton_v3.6.x` branch are documented here:
- nvidia: https://github.com/flagos-ai/FlagTree/blob/main/documents/install.md
- enflame: https://github.com/flagos-ai/FlagTree/blob/main/documents/install_enflame.md
- hcu: https://github.com/flagos-ai/FlagTree/blob/main/documents/install_hcu.md
- mthreads: https://github.com/flagos-ai/FlagTree/blob/main/documents/install_mthreads.md

## Test Plan

Backend-specific test commands for the `triton_v3.6.x` branch are documented here:
- nvidia: https://github.com/flagos-ai/FlagTree/blob/triton_v3.6.x/.github/workflows/hopper-build-and-test.yml
- enflame: https://github.com/flagos-ai/FlagTree/blob/triton_v3.6.x/.github/workflows/enflame-gcu400-build-and-test.yml
- hcu: https://github.com/flagos-ai/FlagTree/blob/triton_v3.6.x/.github/workflows/hcu-build-and-test.yml
- mthreads: https://github.com/flagos-ai/FlagTree/blob/triton_v3.6.x/.github/workflows/mthreads-build-and-test.yml


## Related PRs

- [ ] flagos-ai/FlagTree#521 - Upgraded the enflame backend to Triton 3.6
- [ ] flagos-ai/FlagTree#563 - Upgraded the hcu backend to Triton 3.6
- [ ] flagos-ai/FlagTree#577 - Upgraded the mthreads backend to Triton 3.6

## Implementation History

- 2026-05-26: FEP created

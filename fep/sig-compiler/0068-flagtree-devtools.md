# FEP-0068: FlagTree DevTools — Optional Debugging and Profiling Components

**Status:** `Implementable`

**Updated:** 2026-09-24

**Created:** 2026-07-24

**Owner:** Unassigned

**SIG:** sig-compiler

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| flagtree-triton3.5 | [`0.7.0-rc2-triton3.5` @ `15ec1a6cbc8d`](https://github.com/flagos-ai/FlagTree/tree/15ec1a6cbc8d51f597f46459a500e96f3812c58f) | [`0.7.0rc2.post2+triton3.5` @ `15ec1a6cbc8d`](https://github.com/flagos-ai/FlagTree/tree/15ec1a6cbc8d51f597f46459a500e96f3812c58f) |
| flagtree-triton3.6 | [`0.7.0-rc2-triton3.6` @ `4819c190476c`](https://github.com/flagos-ai/FlagTree/tree/4819c190476cebb66057493e41379c1406c615ac) | [`0.7.0rc2.post2+triton3.6` @ `d9e65f4df7fe`](https://github.com/flagos-ai/FlagTree/tree/d9e65f4df7fe881281abd9e834ab3f37f4d0642c) |

## Summary

FlagTree debugging and profiling are implemented through
[FlagPrism](https://github.com/flagos-ai/FlagPrism). RC2 contains the compiler,
runtime and build integration for Ascend on Triton 3.5 and Iluvatar on Triton
3.6. The public component namespaces are `flagtree.debugger` and
`flagtree.profiler`.

## Goals and Completion

| Goal | RC2 implementation | Remaining work |
|---|---|---|
| Debugger instrumentation and reports | Host callbacks, statement metadata, launch context and debugger registration | Backend acceptance results |
| Profiler integration | Optional profiler registration and shared build integration | Backend metrics and trace acceptance results |
| Source/IR/runtime correlation | Compiler and statement events in `python/flagtree/_flagprism.py` | End-to-end report checks |
| Optional components | `TRITON_BUILD_FLAGPRISM` build control and compatibility checks | Record the external FlagPrism revision used for each RC2 build |

`python/setup_tools/setup_helper.py` enables FlagPrism for Ascend and
Iluvatar. Other backends are outside this RC2 build policy. The dependency
registry points to the FlagPrism repository without a commit pin.

## Design

`flagtree._flagprism` defines host API version 2.0, component registration,
capability checks, compiler callbacks and launch events. Kernel collection
uses `flagtree.language.debug_collect_start` and `debug_collect_end`.
Missing components and incompatible host/component APIs raise explicit errors.
Core callbacks remain inactive until a component registers.

The build loads FlagPrism from `third_party/FlagPrism`. Its build helper adds
the debugger and profiler packages to the FlagTree build. FlagPrism and the
legacy Proton build cannot both be enabled.

## Packaging

Components are built with FlagTree and its matching LLVM/MLIR ABI; RC2 does
not use the proposed independent `flagtree-debugger` and
`flagtree-profiler` wheel arrangement.

On the Ascend 3.5 or Iluvatar 3.6 source line, with the vendor toolchain:

```bash
TRITON_BUILD_FLAGPRISM=ON TRITON_BUILD_PROTON=OFF \
  python -m pip wheel . --no-build-isolation --no-deps -w dist
```

Record the FlagTree and FlagPrism commits with the wheel. Build with
`TRITON_BUILD_FLAGPRISM=OFF` to verify operation without the components.

## Test Plan

```bash
python -m pytest -q python/test/unit/test_flagprism.py
python -c 'import flagtree.debugger; import flagtree.profiler'
```

Host tests must verify namespace ownership, registration, version/capability
rejection and enabled/disabled build behavior. On each supported accelerator,
run the matching FlagPrism debugger and profiler tests, verify source/IR
correlation and readable profiles, and compare kernel results with collection
disabled. Full backend acceptance remains open in
[community#76](https://github.com/flagos-ai/community/issues/76).

## Related PRs

- [x] [FlagTree#916](https://github.com/flagos-ai/FlagTree/pull/916) — Ascend integration on the Triton 3.5 line. Merged.
- [x] [FlagTree#1035](https://github.com/flagos-ai/FlagTree/pull/1035) — Iluvatar integration on the Triton 3.6 line. Merged.

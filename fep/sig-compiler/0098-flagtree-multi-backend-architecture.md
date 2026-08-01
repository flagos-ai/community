# FEP-0098: FlagTree Multi-Backend Architecture — New Backends, Unified Specialization, and CI/CD Integration

**Status:** `Provisional`

**Created:** 2026-08-01

**Owner:** [TODO: @github-username]

**SIG:** sig-compiler

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP covers the multi-backend architecture work planned for
FlagTree in the FlagOS 2.2 cycle, along three tracks:

1. **New backends** — NVIDIA TileIR (Triton 3.6), T-Head (Triton 3.6), Enflame
   (Triton 3.7), and Moore Threads (via TileIR).
2. **Unified backend specialization** — a standard way for each backend to
   reuse FlagTree trunk code and express only its differences in its backend
   directory, instead of editing trunk code directly or duplicating whole files.
   Python uses `__path__` path hijacking combined with function-call / function
   -definition specialization; C++ uses include-path hijacking combined with
   CMake auto-scan of specialization files and their targets.
3. **CI/CD integration validation** — move the gate for model-adaptation and
   FlagOS-model-release install issues earlier, to the development CI merge
   stage.

Repository: https://github.com/flagos-ai/FlagTree

## Motivation

FlagTree integrates many AI-chip backends into one repository (FEP-0013).
Today's backends already span NVIDIA, AMD, Cambricon, HCU, Iluvatar, MetaX,
Moore Threads, Kunlunxin (XPU), Enflame, Thrive, Sunrise, and RPU (visible under
`third_party/` and in the per-backend CI workflows). Scaling this to more
backends and Triton versions surfaces two structural problems and one process
problem:

- **Specialization sprawl.** Each backend has legitimate specialization needs,
  but historically these were met either by editing trunk code directly (which
  couples the trunk to one vendor and breaks others) or by copying the whole
  code into a backend directory (which loses trunk reuse and makes Triton
  version upgrades error-prone). A standard specialization mechanism is needed.
- **New backends.** TileIR (NVIDIA), T-Head, Enflame, and Moore Threads must be
  brought in on their target Triton branches under the same conventions.
- **Late integration failures.** Model-adaptation and FlagOS-model-release
  install problems are currently found late. Gating them at the dev CI merge
  stage catches them before release.

### Goals

**(Required)**

- **G1 (New backends):** Integrate the new backends on their target branches —
  NVIDIA TileIR on 3.6, T-Head on 3.6, Enflame on 3.7, Moore Threads via TileIR
  — each building in-tree and reusing the trunk pipeline.
  <!-- TODO: confirm the Moore Threads "TileIR" relationship (shared TileIR
       lowering vs. separate backend) and each backend's acceptance scope. -->
- **G2 (Unified specialization mechanism):** Provide the standardized
  specialization mechanism for both Python (`__path__` hijack + function
  specialization) and C++ (include-path hijack + CMake auto-scan), so trunk
  code contains no backend-specific specialization and no backend-selection
  branch that then specializes, unless that trunk file already had
  backend-selection logic.
- **G3 (Rollout):** Migrate all backends on the `main` branch and the 3.7 branch
  to the unified specialization mechanism.
- **G4 (CI/CD gating):** Add CI validation that gates model-adaptation / install
  regressions at merge time, via at least one of: (a) validating the FlagGems
  operator library against a fixed, previously-passing op list; (b) reusing the
  model-release inference image to run inference regression + performance
  reporting.

### Non-Goals

- Adapting operator libraries (e.g. FlagGems) on the new backends — tracked
  under the relevant module's FEP, not here.
- Changing upstream Triton language semantics; specialization happens only at
  FlagTree's defined extension points.
- Backends beyond the four named in G1 for this cycle.

## Proposal

### Track 1: New Backends

FlagTree already carries per-backend delivery and build-and-test CI workflows
for a wide backend set, and the CI scaffolding for the new backends is present
before the backend code lands. On the CI branch
(`add_signal_primitives_for_tle_dist`) the workflow set includes
`tileir3.6-build-and-test.yml` / `tileir3.6-delivery.yml`,
`thrive3.6-*`, `enflame3.6-gcu300/gcu400-*`, `sunrise-*`, `rpu3.6-*`,
`aipu3.3-delivery.yml`, and the `nv3.6`, `metax3.6`, `mthreads3.6`,
`iluvatar3.6`, `hcu3.6` families. Release branches are versioned by Triton line
(`v0.6.0-rc2-triton3.2/3.3/3.5/3.6`), and `third_party/` on the 3.6 release
branch currently holds `amd, enflame, f2reduce, hcu, mthreads, nvidia, proton,
rpu, thrive, tle`.

The net-new backend code for 2.2 — the TileIR lowering (NVIDIA and Moore
Threads), the T-Head 3.6 backend, and the Enflame 3.7 backend — is not yet in
tree; the `tileir3.6` CI workflows exist but no `tileir` backend directory does.
Each new backend is added under `third_party/<backend>/` following the unified
specialization conventions in Track 2.

<!-- TODO (design): per backend — target Triton branch, dependency on TileIR
     lowering, and whether it reuses an existing backend's codegen. -->

### Track 2: Unified Backend Specialization

The mechanism exists on the `feat/spec-path-dynamic-backend-lookup` and
`feat/mthreads-spec-path-third-party.*` branches:

- **Backend selector.** `python/triton/FLAGTREE_BACKEND` (and the internal
  `_flagtree_backend.FLAGTREE_BACKEND`) names the active backend at build/import
  time.
- **Python `__path__` hijack.** `python/triton/flagtree_spec.py` provides
  `spec_path(path_list, exclude=...)`, which — given a trunk package's
  `__path__` — inserts the backend's mirror directory
  (`backends/<backend>/spec/triton/<rel_path>`, and for editable installs
  `third_party/<backend>/python/triton/<rel_path>`) ahead of the trunk path.
  A package that calls `spec_path(__path__)` in its `__init__.py` therefore
  resolves a specialized module from the backend tree when one exists and the
  trunk module otherwise. Backends provide their overrides under
  `third_party/<backend>/backend/spec/triton/...` mirroring the trunk layout
  (e.g. `.../spec/triton/compiler/compiler.py`).
- **C++ include-path hijack + CMake auto-scan.** The C++ side hijacks include
  paths and has CMake auto-scan the backend's specialization files and their
  corresponding targets, so a backend's `.cpp`/`.h` overrides are picked up
  without editing trunk `CMakeLists.txt`.

The governing rule: trunk code must neither contain a specific backend's
specialization nor branch on the backend and then specialize — unless the trunk
file already had backend-selection logic. This FEP standardizes the mechanism
and the rule; the 2.2 work is to complete it and migrate every backend to it.
Ongoing per-backend migrations are visible on
`refactor/iluvatar-python-specialization` and the `feat/mthreads-spec-path-*`
branches.

<!-- TODO (design): the exclude/protect-subpackages semantics, how function-
     definition specialization (not just module replacement) is expressed, and
     the CMake auto-scan glob/target-naming contract. -->

### Track 3: CI/CD Integration Validation

The goal is to bring the FlagOS-model-release gate forward to the dev CI merge
stage, in one or both of two ways the plan names:

- **Option A — FlagGems op-list gate.** CI validates the FlagGems operator
  library against a fixed op list (the historically-passing ops), with the op
  list updated on major-version cadence. Groundwork is on the
  `triton_v3.6_test_flagGems` / `triton_v3.6_test_flagGems_1` branches and the
  `addflaggemstest` branch.
- **Option B — model-release inference gate.** CI reuses the model-release
  inference image so environment dependencies match the real release scenario,
  running inference regression plus a performance display at merge time.

The existing per-backend `*-build-and-test.yml` workflows are the integration
point for adding these gates.

<!-- TODO (design): which option(s) ship in 2.2, on which backends, the fixed
     FlagGems op-list source and update policy, and where the inference image
     comes from. -->

## Design Details

<!-- TODO: mechanism-level details for Tracks 2 and 3, to be filled before
     Status moves to `Implementable` (FEP Freeze 2026-08-14). -->

## Packaging

**(Required)** New backends ship as per-backend FlagTree wheels built from their
target Triton branch. The specialization mechanism is part of the FlagTree build
system (Python packaging + CMake). CI/CD gating is repository infrastructure and
is not packaged.

**Supported vendors:** new backends this cycle — NVIDIA (TileIR), T-Head,
Enflame, Moore Threads; the specialization mechanism applies to all backends.

**Can this feature be packaged as a wheel (`.whl`)?** Yes — per backend, as with
existing FlagTree backends.

### Build

```bash
git clone https://github.com/flagos-ai/FlagTree.git
cd FlagTree
# Build a specific backend (selector drives __path__ hijack + CMake auto-scan)
export FLAGTREE_BACKEND=<backend>
MAX_JOBS=32 python3 -m pip install . --no-build-isolation
```

<!-- TODO: exact selector value and any per-backend build flags for the four
     new backends. -->

## Test Plan

**(Required)** Verified per track.

### G1 / G3: New backends and rollout

| Test | Command | Expected result |
|---|---|---|
| Per-backend build + test | Backend CI workflow (e.g. `tileir3.6-build-and-test.yml`, T-Head, `enflame*` 3.7) | Backend builds in-tree and its compiler test suite passes |
| Specialization migration | Build each `main` / 3.7 backend with the unified mechanism | All backends build without trunk edits; trunk carries no backend specialization |

### G2: Unified specialization mechanism

| Test | Command | Expected result |
|---|---|---|
| Python path hijack | Import a specialized module with `FLAGTREE_BACKEND` set | Backend override resolves when present; trunk module otherwise |
| C++ auto-scan | Build with a backend that has C++ specialization files | Specialization files/targets picked up without editing trunk CMake |

### G4: CI/CD gating

| Test | Command | Expected result |
|---|---|---|
| FlagGems op-list gate | CI job on a PR that regresses an op | Merge blocked; op-list validation reports the regression |
| Model-release inference gate | CI job using the inference image | Inference regression + perf report produced at merge time |

<!-- TODO: concrete commands/hardware once the gating design is fixed. -->

## Related PRs

<!-- TODO: fill with the actual FlagTree PR numbers by the FEP Owner. -->
- [ ] FlagTree — dynamic backend spec-path lookup (branch `feat/spec-path-dynamic-backend-lookup`)
- [ ] FlagTree — Moore Threads spec-path migration (`feat/mthreads-spec-path-third-party.*`)
- [ ] FlagTree — Iluvatar python specialization (`refactor/iluvatar-python-specialization`)
- [ ] FlagTree — FlagGems CI gate (`triton_v3.6_test_flagGems`, `addflaggemstest`)
- [ ] FlagTree — TileIR / T-Head / Enflame 3.7 backends (net-new)

## Implementation History

- 2026-08-01: FEP created as `Provisional` for the FlagOS 2.2 cycle. The
  unified specialization mechanism (`flagtree_spec.py` `__path__` hijack +
  `FLAGTREE_BACKEND`, C++ include-hijack + CMake auto-scan) and CI scaffolding
  for new backends (`tileir3.6-*`, FlagGems-test branches) exist on feature
  branches; the four new backend implementations, the full backend migration on
  `main`/3.7, and the CI gates are the net-new 2.2 work. Owner and per-track
  acceptance scope pending fill-in before FEP Freeze.

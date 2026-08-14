# FEP: KernelGen Knowledge and Tool Hub

**Status:** `Provisional`

**Created:** 2026-07-30

**Owner:** @zacliu

**SIG:** sig-kernelgen

**Target Version:** FlagOS 2.2

---

## Summary

This FEP proposes the creation of a **Knowledge and Tool Hub** inside the [KernelGen](https://github.com/flagos-ai/kernelgen) repository under a new `knowledge/` directory. The hub collects and indexes multi-chip operator knowledge (blogs, websites, open-source code, documentation, books) and profiling/optimization tooling (vendor and open-source profilers, existing optimization skills and agents) into a single, navigable, machine-readable registry. The hub serves as the data substrate for downstream KernelGen capabilities — including the Optimization Skill/Agent Framework (FEP: kernelgen-optimization-skill-agent-framework) and the Operator Coverage Map (FEP: kernelgen-operator-coverage-map).

## Motivation

Kernel generation today is bottlenecked by **fragmented tribal knowledge**. To produce a high-performance Triton kernel for, say, a fused MoE layer on Ascend, an engineer needs to know:

- Which Triton idioms are fastest on Ascend vs NVIDIA (scattered across vendor blogs, conference talks, and GitHub issues).
- Which profiler to invoke (`msprof` on Ascend, `nsys` on NVIDIA, `musa-profiler` on MUSA) and how to read its output.
- Which existing optimization skills (e.g., `cuda-optimized-skill`, `AutoKernel`, `AKO4ALL`) already encode part of this knowledge.

None of this is centrally indexed. Every contributor re-discovers the same references, re-implements the same profiler wrappers, and re-builds the same skill scaffolding. The result is duplicated effort, inconsistent guidance to the LLM, and onboarding friction for new chip vendors entering the FlagOS ecosystem.

The Knowledge and Tool Hub addresses this by providing a **single curated registry** that is:
- **Machine-readable** (YAML/JSON manifests) so agents can query it programmatically.
- **Multi-chip by default** (NVIDIA, Ascend, MUSA, Hygon, Iluvatar, MetaX, Sunrise, KunlunXin, ENFLAME, Cambricon).
- **Tool-aware** (profilers, kernel libraries, optimization skills indexed uniformly).

### Goals

- Establish `kernelgen/knowledge/` as the canonical location for multi-chip operator knowledge and tooling references.
- Index **knowledge resources**: blogs, websites, books, papers, open-source code repos, and vendor documentation, tagged by chip and topic.
- Index **profiling tools**: vendor profilers (Nsight Systems/Compute, ROCm rocprof, Ascend msprof, MUSA profiler, MetaX msys, etc.) and open-source alternatives, with invocation schemas and output formats.
- Index **existing optimization skills and agents**: `cuda-optimized-skill`, `AutoKernel`, `AKO4ALL`, and other community contributions, with their input/output contracts.
- Provide a uniform manifest schema (YAML) so each entry is queryable by chip, topic, tool type, and license.
- Make the hub consumable by both humans (rendered Markdown index) and machines (structured YAML + a Python query API).

### Non-Goals

- **Authoring new optimization skills or agents** — that is the scope of the Optimization Skill/Agent Framework FEP. This FEP only *indexes* existing ones.
- **Generating the operator coverage map** — that is the scope of the Operator Coverage Map FEP. This FEP only provides the underlying resource registry the map is built from.
- **Re-implementing or forking profiling tools** — the hub references and wraps invocation, it does not replace the tools.
- **Hosting copyrighted book content** — only metadata and links; full text is referenced, not copied.
- **Performance benchmarking** — covered by KernelGenBench (FEP-0004).

## Proposal

From a user perspective, the hub is a directory in the KernelGen repo that can be browsed as Markdown or queried programmatically:

```bash
# Browse the rendered index
cat kernelgen/knowledge/README.md

# Query all profiling tools for Ascend
python -m kernelgen.knowledge query --type profiling-tool --chip ascend

# Query all optimization skills covering GEMM
python -m kernelgen.knowledge query --type optimization-skill --topic gemm
```

Each entry is a YAML manifest with a stable schema, rendered into a human-readable Markdown index by a generator script.

## Design Details

### Directory Layout

```
kernelgen/
└── knowledge/
    ├── README.md                          # Rendered index (auto-generated)
    ├── manifest_schema.json              # JSON Schema for entry validation
    ├── entries/
    │   ├── docs/                          # Documentation & books
    │   │   ├── triton-official-docs.yaml
    │   │   ├── cuda-programming-guide.yaml
    │   │   ├── ascend-cann-docs.yaml
    │   │   ├── musa-programming-guide.yaml
    │   │   └── ...
    │   ├── blogs/                         # Blog posts & articles
    │   │   ├── triton-kernel-optimization-blog-xxx.yaml
    │   │   └── ...
    │   ├── papers/                        # Research papers
    │   │   ├── flash-attention.yaml
    │   │   └── ...
    │   ├── code/                          # Open-source code repos
    │   │   ├── flaggems.yaml
    │   │   ├── triton.yaml
    │   │   ├── vendor-sdks/
    │   │   │   ├── ascend-cann.yaml
    │   │   │   ├── musa-toolkit.yaml
    │   │   │   └── ...
    │   │   └── ...
    │   ├── tools/
    │   │   ├── profiling/                 # Profiling tools
    │   │   │   ├── nvidia-nsight-systems.yaml
    │   │   │   ├── nvidia-nsight-compute.yaml
    │   │   │   ├── rocm-rocprof.yaml
    │   │   │   ├── ascend-msprof.yaml
    │   │   │   ├── musa-profiler.yaml
    │   │   │   ├── metax-msys.yaml
    │   │   │   └── open-source/
    │   │   │       ├── torch-profiler.yaml
    │   │   │       └── ...
    │   │   └── optimization-skills/       # Existing optimization skills/agents
    │   │       ├── cuda-optimized-skill.yaml
    │   │       ├── autokernel.yaml
    │   │       ├── ako4all.yaml
    │   │       └── ...
    │   └── websites/                      # Reference websites
    │       └── ...
    ├── scripts/
    │   ├── generate_index.py              # Renders README.md from entries
    │   ├── validate.py                    # Schema validation
    │   └── query.py                        # Programmatic query API
    └── tests/
        └── test_manifests.py              # Ensure all entries validate
```

### Manifest Schema (YAML)

Each entry follows a uniform schema:

```yaml
# Example: profiling tool entry
id: nvidia-nsight-systems
type: profiling-tool
name: Nsight Systems
vendor: nvidia
chips: [nvidia]
homepage: https://developer.nvidia.com/nsight-systems
license: proprietary
description: |
  System-wide performance profiler for NVIDIA GPUs. Captures CPU, GPU, and
  CUDA/Triton kernel timelines.
invocation:
  cli: nsys profile --output=%o %c
  output_format: .nsys-rep / .qdrep
  parsing_tool: nsys stats
output_fields:
  - kernel_name
  - duration_us
  - gpu_id
  - grid_size
  - block_size
  - registers_per_thread
tags: [timeline, kernel-launch, cpu-gpu-correlation]
notes: |
  Use `nsys stats` to extract per-kernel timing tables from the .nsys-rep.
```

```yaml
# Example: optimization skill entry
id: cuda-optimized-skill
type: optimization-skill
name: CUDA Optimized Skill
source_repo: https://github.com/flagos-ai/skills
chips: [nvidia]
input_contract:
  - operator_name
  - reference_pytorch_impl
  - target_chip
output_contract:
  - optimized_triton_kernel
  - optimization_notes
tags: [pointwise, reduction, gemm]
notes: |
  Claude Code Skill; orchestrates profiler + knowledge lookup + generation.
```

### Query API

A small Python module (`kernelgen.knowledge`) exposes the registry:

```python
from kernelgen.knowledge import Hub

hub = Hub.load()
# All profiling tools for Ascend
tools = hub.query(type="profiling-tool", chip="ascend")
# All skills covering MoE
skills = hub.query(type="optimization-skill", topic="moe")
```

This API is consumed by the Optimization Skill/Agent Framework (FEP: kernelgen-optimization-skill-agent-framework).

### Rendering

`scripts/generate_index.py` walks `entries/`, groups by `type` and `chip`, and emits a single `README.md` with tables and links. This keeps the human-readable view in sync with the machine-readable manifests.

## Packaging

**Supported vendors:** NVIDIA, Ascend, MUSA, Hygon, Iluvatar, MetaX, Sunrise, KunlunXin, ENFLAME, Cambricon (coverage varies per entry).

**Can this feature be packaged as a wheel (`.whl`)?** Yes.

- The `knowledge/` directory ships as part of the `kernelgen` Python package.
- Build command:
  ```bash
  python -m build            # produces dist/*.whl
  # or
  pip wheel . -w dist/
  ```
- The wheel bundles:
  - `entries/*.yaml` (manifest data)
  - `scripts/` (generator, validator, query API)
  - `manifest_schema.json`
- Platform requirements: Python >= 3.10; no GPU/toolkit required to *browse or query* the hub (tool invocation requires the corresponding vendor toolkit, documented per entry).

## Test Plan

### Manifest Validation

- **Test command:**
  ```bash
  cd kernelgen && python -m knowledge.scripts.validate
  ```
- **Expected result:** All YAML entries in `entries/` pass JSON Schema validation; zero errors.

### Index Generation

- **Test command:**
  ```bash
  cd kernelgen && python -m knowledge.scripts.generate_index
  ```
- **Expected result:** `knowledge/README.md` is regenerated and reflects all entries; diff is stable across runs.

### Query API

- **Test command:**
  ```bash
  cd kernelgen && python -m pytest knowledge/tests/test_query.py -v
  ```
- **Expected result:** Query by `type`, `chip`, `topic`, and `tags` returns the expected entry sets; edge cases (empty result, unknown chip, malformed manifest) handled gracefully.

### Coverage Spot Checks

- **Test command:**
  ```bash
  python -m knowledge.scripts.query --type profiling-tool --chip ascend
  python -m knowledge.scripts.query --type profiling-tool --chip musa
  python -m knowledge.scripts.query --type optimization-skill --topic moe
  ```
- **Expected result:** Each of the 7+ FlagOS-supported chips has at least one profiling-tool entry; at least 3 optimization-skill entries are indexed.

### Cross-Reference Integrity

- **Test command:**
  ```bash
  python -m knowledge.scripts.validate --check-links
  ```
- **Expected result:** All `homepage` / `source_repo` URLs resolve (HTTP 200); broken links are reported but do not block validation (warning only).

## Related PRs

- [ ] flagos-ai/kernelgen#xxx — Add `knowledge/` directory, manifest schema, and initial entry set
- [ ] flagos-ai/kernelgen#xxx — Add query API and index generator
- [ ] flagos-ai/kernelgen#xxx — Seed entries for 7+ chips (profiling tools, docs, skills)

## Implementation History

- 2026-07-30: FEP created

# FEP-0100: KernelGen Capability Building and Optimization Exploration for FlagOS 2.2

**Status:** `Provisional`

**Created:** 2026-08-01

**Owner:** [TODO: @github-username]

**SIG:** sig-kernelgen

**Target Version:** FlagOS 2.2

---

## Summary

**(Required)** This FEP covers the KernelGen capability-building and
optimization-exploration work planned for the FlagOS 2.2 cycle, built on top of
the Knowledge and Tool Hub ([FEP-0093](0093-kernelgen-knowledge-and-tool-hub.md)).
It has two directions:

1. **Capability building** — KernelGen 2.2 refactor, FlagOS-Coder v1, the
   operator coverage map, the operator agent + multi-chip leaderboard, and the
   Workbuddy operator expert.
2. **Optimization exploration** — a vLLM end-to-end optimization prototype
   calling KernelGen, and an optimization agent combined with compiler
   techniques.

Repository: https://github.com/flagos-ai/kernelgen

## Motivation

The 301 generated operators in the FlagOS 2.2 operator library
([FEP-0099](../sig-operator/0099-operator-library-flagos-2.2.md)) are produced
by KernelGen. Sustaining and scaling that output across 5+ domestic chips needs
more than a one-off generation pass: it needs a refactored generation core,
tooling that makes coverage and quality visible, and agents that turn the
indexed knowledge into working kernels. FEP-0093 provides the knowledge/tool
substrate; this FEP builds the capabilities that consume it and explores using
KernelGen in end-to-end inference optimization.

### Goals

**(Required)**

- **G1 (KernelGen 2.2 refactor):** Refactor the KernelGen core and define the
  multi-chip tool and knowledge-base onboarding standard.
  <!-- TODO: what the refactor changes; what the onboarding standard specifies
       and how a new chip is judged onboarded. -->
- **G2 (FlagOS-Coder v1):** Deliver v1 of FlagOS-Coder, a 32B model that
  supports operator generation and tuning on 5+ chips.
  <!-- TODO: the v1 acceptance bar — inputs, outputs, and how "supports
       generation and tuning" is measured per chip. -->
- **G3 (Operator coverage map):** Deliver the operator coverage map (the
  Operator Coverage Map named as a follow-up in FEP-0093).
  <!-- TODO: what the map covers (operators × chips × status?), how it is
       generated and where it is published. -->
- **G4 (Operator agent + multi-chip leaderboard):** Deliver the operator agent
  and a multi-chip leaderboard (an instance of the Optimization Skill/Agent
  Framework named as a follow-up in FEP-0093).
  <!-- TODO: what the agent does end-to-end; what the leaderboard ranks and its
       metric. -->
- **G5 (Workbuddy operator expert):** Deliver the Workbuddy operator expert.
  <!-- TODO: scope and acceptance bar. -->
- **G6 (vLLM end-to-end optimization prototype):** Prototype vLLM end-to-end
  optimization that calls KernelGen.
  <!-- TODO: what "end-to-end optimization" targets and what the prototype must
       demonstrate to count as done. -->
- **G7 (Compiler-technique optimization agent):** Prototype an optimization
  agent combined with compiler techniques.
  <!-- TODO: which compiler techniques (relation to sig-compiler #96/#97) and
       the prototype's acceptance bar. -->

### Non-Goals

- The Knowledge and Tool Hub itself (the `kernelgen/knowledge/` registry,
  manifest schema, query API), tracked in FEP-0093. This FEP consumes that
  substrate but does not build it.
- The manually implemented and generated operator *counts* and their
  performance acceptance, tracked in
  [FEP-0099](../sig-operator/0099-operator-library-flagos-2.2.md). This FEP
  builds the generation capability, not the operator-count deliverable.
- KernelGenBench performance benchmarking, tracked in
  [FEP-0004](0004-kernelgenbench.md).

## Proposal

### Direction 1: Capability Building

Five capabilities on top of the FEP-0093 knowledge/tool substrate:

- **KernelGen 2.2 refactor** — refactor the generation core and define the
  standard by which a new chip's tooling and knowledge base are onboarded.
- **FlagOS-Coder v1** — first release of FlagOS-Coder, a 32B model for operator
  generation and tuning across 5+ chips.
- **Operator coverage map** — the coverage map FEP-0093 names as a downstream
  consumer of the resource registry.
- **Operator agent + multi-chip leaderboard** — an agent that generates/optimizes
  operators and a leaderboard comparing results across chips; an instance of
  the Optimization Skill/Agent Framework FEP-0093 names as a follow-up.
- **Workbuddy operator expert** — an operator-expert assistant.

<!-- TODO (design): per capability — inputs/outputs, how it uses the FEP-0093
     hub, and the target chips. -->

### Direction 2: Optimization Exploration

- **vLLM end-to-end optimization prototype** — a prototype that invokes
  KernelGen within a vLLM end-to-end optimization flow.
- **Compiler-technique optimization agent** — an optimization agent that
  combines KernelGen with compiler techniques (relation to the sig-compiler
  work in flagos-ai/community#96 / #97 to be defined).

<!-- TODO (design): the integration path for each prototype and what it must
     demonstrate. -->

## Design Details

<!-- TODO: implementation-level details for each capability and prototype, to
     be filled before Status moves to `Implementable`. -->

## Packaging

N/A for now. KernelGen is not a pip-installable package — it is delivered as
the web platform (https://kernelgen.flagos.io), the MCP service, and IDE
skills in the flagos-ai/kernelgen repo.

<!-- TODO: per-deliverable delivery form — how FlagOS-Coder (model weights),
     the coverage map, the agents and Workbuddy ship; platform and toolkit
     requirements per target chip. -->

## Test Plan

**(Required)** Each goal is verified independently. Acceptance runs on vendor
hardware where a target chip is involved; results (environment, logs, metrics)
are attached to the tracking issue by the testing party.

### G1: KernelGen 2.2 refactor

<!-- TODO: how the refactor and the onboarding standard are verified — e.g.
     onboard one new chip end-to-end following the standard. -->

### G2: FlagOS-Coder v1

<!-- TODO: acceptance test — inputs, command, expected output. -->

### G3: Operator coverage map

<!-- TODO: command that generates the map; expected coverage assertions. -->

### G4: Operator agent + multi-chip leaderboard

<!-- TODO: agent run command and expected output; leaderboard generation
     command and expected ranking content. -->

### G5: Workbuddy operator expert

<!-- TODO: acceptance test. -->

### G6: vLLM end-to-end optimization prototype

<!-- TODO: prototype run command, workload, and the demonstrated result. -->

### G7: Compiler-technique optimization agent

<!-- TODO: prototype run command and the demonstrated result. -->

## Related PRs

<!-- TODO: link the implementation PRs in flagos-ai/kernelgen. -->

- [ ] flagos-ai/community#93 — KernelGen Knowledge and Tool Hub (the knowledge/
  tool substrate this FEP builds on; cross-reference, not owned here)

## Implementation History

- 2026-08-01: FEP created as `Provisional` for the FlagOS 2.2 cycle.

# FEP: KernelGen v2.1.0 Release

**Status:** `Implementable`

**Created:** 2026-05-27

**Owner:** @Dongxu-H

**SIG:** sig-kernelgen

**Target Version:** FlagOS 2.1

---

## Summary

KernelGen v2.1.0 introduces two major enhancements to the AI-powered automatic Triton kernel development platform:

1. **New Hardware Backend Support — Sunrise**: Official support for Sunrise AI accelerator platform, expanding hardware coverage from 6 to 7 supported chips.

2. **Experimental Triton Language Extensions (TLE) Support**: Laboratory/experimental TLE support across Web Platform, MCP workflows, and Skills-based development.

Repository: https://github.com/flagos-ai/kernelgen

---

## Motivation

### Goals

- Expand hardware ecosystem support to include Sunrise AI accelerators
- Enable developers to experiment with TLE-powered kernel generation and optimization
- Provide unified AI-native Triton development experience across all supported hardware platforms
- Maintain full feature parity for new hardware backend (Web, MCP, Skills, generation, optimization, testing, benchmarking)

### Non-Goals

- Full production-ready TLE support (TLE remains experimental/laboratory feature in this release)
- Distributed programming support (planned for future releases)
- Changes to existing hardware backend implementations

---

## Proposal

KernelGen v2.1.0 extends the platform capabilities in two key areas:

### 1. Sunrise Hardware Backend

The Sunrise AI accelerator platform is now fully integrated into the KernelGen ecosystem with complete feature support:

- Web Platform support
- MCP automated workflows
- Skills integration
- Kernel generation & optimization
- Auto testing & benchmarking
- Multi-hardware adaptation workflows

Developers targeting Sunrise hardware can now use the same AI-native Triton development experience available across the FlagOS ecosystem.

### 2. TLE Experimental Support

Triton Language Extensions (TLE) addresses limitations in:
- Hardware adaptation
- Memory hierarchy abstraction
- Tile programming
- Parallelism abstraction
- Distributed operator programming

TLE extends Triton across three abstraction layers:

| Layer | Description |
|---|---|
| TLE-Lite | Lightweight Triton-compatible extensions with minimal code changes |
| TLE-Struct | Architecture-clustered abstractions for deeper performance tuning |
| TLE-Raw | Hardware-native programming interfaces for maximum performance |

---

## Design Details

### Hardware Platform Coverage

KernelGen v2.1 now supports 7 hardware platforms. Supported capabilities across all platforms include:

- Triton kernel generation
- Auto optimization
- Auto tuning
- Testing & benchmarking
- Web workflows
- MCP integration
- Skills integration
- TLE experimental workflows

### Integration Points

- **Web Platform**: https://kernelgen.flagos.io
- **MCP Service (ModelScope)**: https://www.modelscope.cn/mcp/servers/flagos-ai/FlagOS_KernelGen
- **Skills Repository**: https://github.com/flagos-ai/skills

---

## Packaging

### Installation

```bash
# Install skill
npx skills add flagos-ai/skills --skill kernelgen
```

### Platform Requirements

- Bearer Token from KernelGen Web Platform
- MCP-compatible agent/IDE (Claude Code, VS Code with Copilot, OpenClaw)

---

## Test Plan

### Sunrise Backend Verification

- [ ] Kernel generation on Sunrise hardware
- [ ] Auto optimization workflows
- [ ] Testing & benchmarking pipelines
- [ ] MCP integration workflows
- [ ] Skills integration workflows

### TLE Experimental Feature Verification

- [ ] TLE-Lite kernel generation
- [ ] TLE-Struct abstractions
- [ ] TLE-Raw interfaces
- [ ] Web platform TLE workflows
- [ ] MCP TLE workflows

### Known Issues Monitoring

- Complex operators may require multiple optimization iterations
- Auto-tuning may incur longer execution time on certain hardware
- MCP workflow stability depends on external agent/IDE integration
- Experimental TLE workflows may produce non-deterministic results

---


## Implementation History

- **2026-05-27**: FEP created, status set to `Implementable`

# sig-riscv: RISC-V Architecture Support (Planned)

## Reason for Deferred Activation

The RISC-V track is explicitly experimental (FEP-34, [community#34](https://github.com/flagos-ai/community/pull/34)); contributors are emerging around vendor backends (for example SpacemiT), but no Chair candidate or standing member roster has been identified yet.

## Planned Responsibilities

- `riscv64` compile adaptation across the FlagOS software stack
- Dependency analysis and trimming for RISC-V availability
- Coordination with vendor-specific RISC-V backends (owned by module SIGs, for example SpacemiT under sig-operator) and with OS-level packaging (sig-os)

## Current Interim Arrangement

The experimental support FEP (FEP-34) is reviewed directly by the TSC per the bootstrap note in [fep/README.md](../../fep/README.md). Experiment results land as merged PRs in the originating Flag* repositories.

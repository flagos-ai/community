# sig-os: OS Integration (Planned)

## Reason for Deferred Activation

The unified package integration work (FEP-19, [community#19](https://github.com/flagos-ai/community/pull/19)) is in its first implementation wave; no Chair candidate or standing member roster has been identified yet.

## Planned Responsibilities

- OS-level packaging for FlagOS repositories: Debian `.deb`, RPM `.rpm`, and PyPI wheel channels
- FlagOS Nexus publishing (APT / YUM repositories at `resource.flagos.net`)
- Distribution integration through the FlagOS SIGs in distribution communities (openKylin, openEuler)
- Per-distribution install and runtime validation beyond the baseline matrix

## Current Interim Arrangement

The unified package integration FEP (FEP-19) is reviewed directly by the TSC per the bootstrap note in [fep/README.md](../../fep/README.md). Per-repository packaging PRs are reviewed by each module-owning SIG.

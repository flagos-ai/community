# sig-benchmark: Performance Benchmarking (Planned)

> **Strategic ecosystem SIG.** The first question a user asks when evaluating FlagOS is "How much faster is it than my current setup?" If this question cannot be answered, the user will not proceed further.

## Reason for Deferred Activation

Benchmarking is critically important, but it is currently recommended to start as a sub-project of sig-training or sig-operator. Once there are ≥2 people dedicated to continuous benchmarking output, it can be upgraded to a standalone SIG.

## Planned Responsibilities

- Maintain a public benchmark dashboard (nightly automated runs)
- Cover mainstream models: Llama, Qwen, DeepSeek, Stable Diffusion, etc.
- Multi-chip performance comparison
- Align with industry benchmarks such as MLPerf
- Publish a benchmark report with each release

## Current Interim Arrangement

The TSC directly oversees benchmark metrics; benchmark data collection operates as a sub-project of sig-training.

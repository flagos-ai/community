# FEP-0093: KernelGen Knowledge and Tool Hub

**Status:** `Provisional`

**Updated:** 2026-09-24

**Created:** 2026-07-30

**Owner:** @zacliu

**SIG:** sig-kernelgen

**Target Version:** FlagOS 2.2

## RC2 Source

| Module | Branch revision | Manifest tag |
|---|---|---|
| kernelgen | [`2.2.0-rc2` @ `1e3262c2e53e`](https://github.com/flagos-ai/KernelGen/tree/1e3262c2e53ec5cdeec14df8c74691f6adde6b46) | [`v2.2.0-rc2.post1` @ `1e3262c2e53e`](https://github.com/flagos-ai/KernelGen/tree/1e3262c2e53ec5cdeec14df8c74691f6adde6b46) |

## Summary

Create a machine-readable registry of multi-chip operator references,
profiling tools and optimization tools. RC2 contains documentation and
existing skills, but no Knowledge Hub directory, schema, query API or index
generator. No implementation PR is linked to this scope.

## Goals and Completion

| Deliverable | RC2 status |
|---|---|
| Resource registry under `knowledge/` | Absent |
| Validated entry schema | Absent |
| Query by resource type, chip, topic and license | Absent |
| Generated Markdown index | Absent |
| Initial multi-chip resource/tool entries | No registry entry set |

Existing TLE and skill documentation is background material; it does not
implement the registry contract below.

## Proposed Design

Each entry has a stable identifier, resource type, name, source URL, license,
supported chips and topic tags. Profiling-tool entries also define invocation,
output format and parsing tools. Optimization-tool entries define input and
output contracts. The registry stores metadata and links rather than copied
third-party content.

A shared schema validates entries. A query API filters them by type, chip,
topic, tags and license. An index generator renders the same data as Markdown.
The initial chip scope includes NVIDIA, Ascend, MUSA, Hygon, Iluvatar, MetaX,
Sunrise, Kunlunxin, Enflame and Cambricon; coverage is recorded per entry.

The registry supplies references to the coverage map and optimization work in
[FEP-0100](0100-kernelgen-capability-flagos-2.2.md). It does not implement
those consumers, replace profilers or generate the operator inventory in
[FEP-0099](../sig-operator/0099-operator-library-flagos-2.2.md).

## Packaging and Acceptance

The proposed Python package bundles the schema, entries, validator, query
API and index generator. Browsing/querying requires no accelerator; invoking
a profiler requires its vendor runtime.

Completion requires an implementation PR and runnable tests that verify:

1. All entries satisfy the schema, with unique identifiers and valid required
   fields.
2. Queries return the expected entries and handle empty results and unknown
   chips consistently.
3. Index generation is deterministic and includes every entry.
4. At least seven chips have profiling-tool entries and at least three
   optimization tools are indexed.
5. An installed package can load its bundled data, and link checking reports
   broken references.

The final API, package integration and executable acceptance commands remain
undefined in RC2.

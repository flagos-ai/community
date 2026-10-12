# FlagOS People & Governance Data

This directory is the **authoritative, machine-readable** source of two things
that the whole FlagOS community needs to agree on:

1. **Affiliation** — which unit (organization) each contributor belongs to, over time.
2. **Governance roles** — who holds which role in a SIG or a project.

Everything else about people is *derived*, not stored here: contribution
statistics are computed from `git` history joined against these tables, and the
`MAINTAINERS.md` / `OWNERS`-style tables in the repo are generated from them.

## Authority model

- `community/data/` is the single source of truth.
- Module repositories may keep a **local copy** (e.g. a generated `OWNERS`
  file), but it is a mirror — changes flow from here outward, never the reverse.
- A change to these tables is a normal PR, reviewed like any other.

## Tables

The schema is relational. Primary keys are shown; foreign keys are `github id`s.

| Table | File | Primary key | Content |
|-------|------|-------------|---------|
| `units` | `people.yaml` | unit `id` | organization names + optional `domains` fallback |
| `people` | `people.yaml` | `id` (= github login) | `name`, `emails[]`, `affiliations[]` |
| `projects` | `projects.yaml` | repository name | `maintainers[]`, `emeritus[]` |
| `sigs` | `sigs.yaml` | sig `id` | `chair`, `tech_leads[]` |

### Foreign keys (two, on purpose)

- **Governance tables → people**: join on `github id`.
- **`git` history → people**: join on `emails[]` (a person can have several).

The same person is therefore reachable by either key; `people.yaml` is the hub.

### Role vocabulary (closed enum)

| Layer | Roles |
|-------|-------|
| SIG | `chair`, `tech-lead` |
| Project | `maintainer`, `emeritus-contributor` |

- SIGs have **no** approver/reviewer roles — code merge authority is per-project.
- `emeritus-contributor` records former maintainership. It is orthogonal to
  affiliation: an emeritus contributor may or may not still be affiliated with
  the unit they worked for.

## Affiliation rules

- An affiliation is `{unit}` by default — open-ended, no dates.
- **Departure is not recorded.** A leaver keeps `{unit: baai}` because they
  usually stop contributing.
- When a leaver later contributes under a **new** organization, add a new
  affiliation `{unit: X, from: <first new-org contribution date>}` and close the
  prior one with `to:` at that same date. Non-overlapping bands keep history
  exact: earlier commits resolve to the old unit, later ones to the new.
- `units[].domains` is a corporate-domain fallback, so people committing from
  `@company.com` need no explicit listing; only personal-email contributors or
  those who changed units require a `people` entry.

## Contribution statistics (consumer of these tables)

- Contribution volume is pure code volume (additions / deletions / files / PR
  count), not person-days.
- Authors matched to a unit are attributed to it by their PR's **merge date**.
- Authors matched to no unit are reported as `independent` (a first-class
  category, not an error).
- The units that happen to be commissioned vendors are a **report-time filter**,
  never a field on the record — all units are peers.

# FEP-0016: FlagGems Operator PR Automation Skill

**Status:** `Provisional`

**Created:** 2026-05-27

**Owner:** @Schopenhauer-loves-Hegel

**SIG:** sig-kernelgen

**Target Version:** FlagOS 2.1

---

## Summary

FlagGems Operator PR Automation Skill is a Claude Code Skill that automates the end-to-end workflow for submitting FlagGems operator PRs. It covers worktree code extraction, 25+ automated compliance checks, and one-click submission (test, benchmark, commit, push, PR creation, and link backfill).

Repository: https://github.com/flagos-ai/FlagGems

## Motivation

Submitting a FlagGems operator PR involves many manual steps: extracting code from worktrees, verifying naming conventions, checking registration consistency, running tests and benchmarks, formatting the PR description, and backfilling tracking spreadsheets. Each submission currently takes ~30–45 minutes of manual work. This process is error-prone and time-consuming, especially across hundreds of operators. Human reviewers repeatedly catch the same categories of issues (e.g., incorrect dtype usage, missing alphabetical ordering, anti-hack violations).

The skill benefits both kernel contributors (faster, less error-prone submissions) and reviewers (fewer mechanical defects to catch).

### Goals

- Automate the full operator PR lifecycle -- code extraction, validation, test, benchmark, submission, and tracking -- executable in 3 commands.
- Enforce 25+ automated checks (AST analysis, naming conventions, registration consistency, anti-hack detection) to catch issues before human review. Target: zero mechanical-defect PRs in pilot batches.
- Ensure code integrity by extracting directly from worktrees, prohibiting manual rewriting of test or benchmark code.
- Support 687 operators across the FlagGems repository with consistent quality standards. Rollout: pilot with 20–50 operators from diverse categories, then expand to all operators.

### Non-Goals

- Replace human code review entirely. The skill ensures mechanical correctness, but domain-specific judgment (e.g., dtype compatibility, algorithm choice) remains with human reviewers.
- Modify the FlagGems kernel implementation or worktree generation process.
- Provide CI/CD pipeline integration. The skill operates solely as a local development tool.
- Support concurrent multi-user execution on the same repository clone.
- Support repositories other than FlagGems.

## Proposal

The skill integrates into the Claude Code environment as a set of Python and shell scripts orchestrated by a SKILL.md definition. The workflow consists of four phases:

1. **Name Lookup** — Query the operator registry to resolve canonical names and check submission status.
2. **Branch Setup** — Create a feature branch (`pr/<op>`) from `upstream/master`.
3. **Code Extraction** — Automatically extract 6 files (kernel, test, benchmark, `ops/__init__.py`, `__init__.py`, `operators.yaml`) from the `.worktrees/gen-<op>` directory, with all registrations inserted in alphabetical order.
4. **Validate & Submit** — Run a 9-step serial pipeline (with a 1.5 sub-step for overload consistency): `check_operator` → overload consistency (1.5) → pre-commit → local test → local benchmark → PR description generation → commit → push → PR creation → link backfill.

Any step failure immediately halts the pipeline with a diagnostic message. The user must fix the reported issue and re-run; there is no resume-from-failure mechanism.

The `--skip-test` and `--skip-benchmark` flags are provided exclusively for environments where GPU hardware is unavailable (e.g., CPU-only dev machines). They do not bypass validation checks. The `--dry-run` flag runs all validation steps without creating commits or PRs, and is intended for pre-submission review.

A `pr_gate_check.sh` PreToolUse hook enforces that `check_operator.py` must pass before `git push` is allowed, preventing submission of unchecked code.

## Design Details

### Automated Check Categories

| Category | Level | Examples |
|----------|-------|---------|
| Kernel compliance | error | File existence, KernelGen header, no `print()`, no recursive fallback |
| Registration consistency | error | `ops/__init__.py` alphabetical order, `_FULL_CONFIG` mapping, `operators.yaml` completeness |
| Test compliance | error | pytest marks, import conventions, `gems_assert_close` usage (no `rtol`), dtype constants |
| Benchmark compliance | error | pytest marks, `op_name` field, dtype constants |
| Anti-hack detection | error | Layer 1 (AST scan) + Layer 2 (dual execution) to verify genuine Triton computation |
| Code quality | warning | Line length, EOF newline, trailing whitespace, naming conventions |

### Key Scripts

- **`extract_from_worktree.py`** — Extracts operator code from `.worktrees/gen-<op>`, generating 6 PR-ready files with correct registration entries.
- **`check_operator.py`** — Runs 25+ checks (22 check methods, many with multiple sub-checks) with `--strict` mode (warnings promoted to errors). Includes AST-based analysis for anti-hack detection. Supports `--list-files` to preview affected files.
- **`check_overload_consistency.py`** — Validates multi-overload operators for three-way consistency across `operators.yaml` entries, pytest marks, and `op_name` fields.
- **`submit_operator.py`** — Orchestrates the 9-step submission pipeline (plus a 1.5 sub-step for overload consistency) with optional `--dry-run`, `--skip-test`, and `--skip-benchmark` flags. Failures are automatically logged to a status tracking file.
- **`gen_pr_description.py`** — Collects NVIDIA benchmark data (from local benchmark runs) and partner-GPU test results (Tianshu, Muxi, Ascend, Hygon) from pre-existing records. Outputs structured JSON mapped to a PR description template. Supports `--skip-run` to query only partner-GPU data without running local benchmarks.
- **`operator_registry.py`** — Canonical name lookup and PR link backfill to tracking spreadsheets.
- **`pr_gate_check.sh`** — PreToolUse hook that blocks `git push` unless `check_operator.py` has passed, enforcing the validation-before-submission invariant.

### Anti-Hack Mechanism

A two-layer defense ensures submitted kernels perform genuine Triton computation:

- **Layer 1 (AST)**: Static analysis scans the kernel source for suspicious patterns (e.g., direct PyTorch calls inside Triton kernels).
- **Layer 2 (Dual Execution)**: Runs the kernel via both the Triton path and a reference PyTorch path, then compares results to detect passthrough implementations. The dual-execution check runs in the same local environment as the test suite; no additional sandboxing is applied.

## Packaging

The skill is distributed as a Claude Code Skill directory:

```
├── SKILL.md              # Skill definition (triggers, rules, workflow)
├── references/           # Documentation (workflow, PR template, naming, checklist, common issues)
└── scripts/              # Python + shell scripts (check, extract, submit, registry, gate hook)
```

Installation: copy the skill directory into the Claude Code skills path (e.g., `~/.claude/skills/` or project-level `.claude/skills/`).

Requirements:
- Python: >= 3.9
- Python packages: `pyyaml`, `openpyxl`, `pandas`
- Toolchain: `gh` (GitHub CLI >= 2.0), `pre-commit`, `pytest`
- Environment variable: `GH_TOKEN` must be set for PR creation (requires `repo` scope only; the skill does not persist or log the token)

## Security Considerations

- **`GH_TOKEN`**: The token is read from the environment variable at runtime and passed to `gh` CLI. It is never logged, written to disk, or included in PR descriptions. Users should scope the token to `repo` access only.
- **Anti-hack dual execution**: Layer 2 runs operator kernels locally in the same Python process as the test suite. No additional sandboxing is applied. Operators are sourced from repository-generated worktrees (produced by a known tool within the repo), not arbitrary user input. The primary threat model is LLM-generated passthrough implementations, not adversarial code injection.
- **Spreadsheet access**: `operator_registry.py backfill` writes to local Excel files on disk. No remote authentication is involved.

## Test Plan

### Functional Verification (maps to Goal 1: automated lifecycle)

- Run `extract_from_worktree.py` with `--dry-run` on a sample operator (e.g., `special_erfcx`) to confirm correct 6-file extraction without side effects.
- Run `submit_operator.py --dry-run` end-to-end to validate the 9-step pipeline completes without submission.
- Confirm `operator_registry.py backfill` correctly writes PR links to tracking spreadsheets.

### Check Coverage (maps to Goal 2: 25+ checks)

- Run `check_operator.py --strict` on a known-good operator to verify all checks pass with zero errors.
- Run `check_operator.py --strict` on deliberately malformed operator code (missing kernel file, incorrect naming, duplicate functions) to verify appropriate error detection.
- Verify anti-hack Layer 2 (dual execution) correctly rejects a known passthrough kernel.

### Scale Testing (maps to Goal 4: 687 operators)

- Run `check_operator.py` across a representative batch of 20–50 operators spanning pointwise, reduction, and linalg categories to validate breadth.
- Run `extract_from_worktree.py --dry-run` on operators with edge-case naming (leading underscores, overloaded variants) to confirm correct handling.

### Compatibility

- Verify the skill runs correctly in a clean environment (fresh clone, no cached state, Python 3.9+).
- Verify `pr_gate_check.sh` correctly blocks `git push` when `check_operator.py` has not been run.

## Related PRs

- [ ] flagos-ai/community#16 — FEP document (this PR)

## Implementation History

- 2026-05-27: FEP created

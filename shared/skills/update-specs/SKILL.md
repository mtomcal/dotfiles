---
name: update-specs
description: Analyze recent code changes against the spec suite, detect coverage gaps, violations, checklist drift, and missing design rationale, then sync specs using available delegation tools or a manual fallback. Use when specs need syncing after code changes, when the user says 'update specs' or 'sync specs', when specs are stale, or when rationale is missing and future agents would have to infer invariants from code.
metadata:
  short-description: Sync specs after code or reasoning changes
allowed-tools:
  - read
  - write
  - edit
  - bash
  - grep
  - ls
  - find
---

# Update Specs

Sync the repo's spec suite to recent implementation changes without inventing behavior.

## Quick Start

Invoke with a git scope boundary:

```bash
update-specs --since <ref>
```

Examples: `--since HEAD~5`, `--since main..feature-branch`.

## Workflow

1. Pre-flight:
   - Require a clean working tree.
   - Require `--since <ref>`.
   - Verify the ref resolves and the diff is non-empty.
2. Detect discrepancies:
   - Read `AGENTS.md`, `specs/README.md`, and the relevant specs.
   - Compare `git diff --stat <ref>..HEAD` and `git diff <ref>..HEAD` against the current spec suite.
   - Classify each finding as `coverage gap`, `violation`, `checklist drift`, `reasoning gap`, or `in-spec change`.
3. Present a discrepancy table and an execution plan before editing specs.
4. Apply updates:
   - Prefer delegation if the active harness exposes subagents or reviewer agents.
   - Otherwise perform the same update sequence manually in the main thread.
5. Review the result with three passes:
   - contract consistency
   - cross-spec integrity
   - mechanical quality
6. If the session hits a guardrail mid-edit, roll back partial spec changes rather than leaving the suite half-synced.

## Reasoning Gaps

A `reasoning gap` exists when the current specs contain most of the facts, but not the invariant or design intent that lets a future agent choose safely between multiple plausible interpretations.

Common triggers:

- a multi-stage lifecycle where source, generated output, runtime, and active pointers are easy to blur together
- a code path whose behavior depends on Git, filesystem, or tool constraints that specs do not state explicitly
- a recent bug fix that required reconstructing intent from tests and code instead of reading it directly from specs

When a reasoning gap is found, update the relevant spec with the missing invariant, decision rule, or lifecycle rationale rather than only syncing path names or command surfaces.

## Review Standard

- Specs stay prescriptive: "MUST", not narrative descriptions of current code.
- Specs stay language-agnostic: use schema tables, decision tables, or pseudocode.
- Version bumps and changelog entries follow `SPEC-OF-SPECS.md`.
- If new shared skill behavior is introduced, run `audit-shared-skills`.

## Reference

See [REFERENCE.md](REFERENCE.md) for the full discrepancy model, delegation pattern, and review-pass checklists.

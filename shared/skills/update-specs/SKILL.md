---
name: update-specs
description: Analyze implementation changes or approved design decisions against a spec suite, detect coverage gaps, violations, checklist drift, and missing rationale, then synchronize the authoritative specs without disturbing unrelated work. Use when specs need syncing, when the user says "update specs" or "sync specs," or when approved behavior needs durable specification.
metadata:
  short-description: Sync specs with evidence
allowed-tools:
  - read
  - write
  - edit
  - bash
---

# Update Specs

## Language Definitions

- **Evidence basis** — the caller-approved source for the update: approved human decisions, a supplied Git comparison, current working-tree changes, implementation and tests, or a named combination.
- **Spec discrepancy** — evidenced mismatch or decision point between the evidence basis and specs.
- **Coverage gap** — approved or implemented behavior lacks spec coverage.
- **Violation** — implementation contradicts a normative clause.
- **Checklist drift** — a spec checklist no longer matches implementation or approved scope.
- **Reasoning gap** — facts exist but the invariant, decision rule, or lifecycle rationale is missing.
- **In-spec change** — implementation remains within allowed behavior and needs no behavioral spec update.
- **Authorized path set** — exact spec, glossary, and tracker paths this run may create or modify.

## Workflow

### 1. Establish the evidence basis without blocking unrelated work

Use the evidence the caller actually supplied:

- For approved design or domain decisions, record the confirmed decision summary and relevant conversation or durable decision artifact. No Git boundary is required.
- For a caller-supplied `<base>` or `<base>..<head>`, reject three-dot or multiple comparisons, normalize a single revision to `<base>..HEAD`, resolve both endpoints with `git rev-parse --verify '<endpoint>^{commit}'`, and use that pinned comparison consistently.
- For an explicit request to inspect current implementation or working-tree changes without a boundary, inspect the relevant working diff, recent history, code, and tests. State exactly what was inspected rather than inventing a caller-supplied boundary.
- When evidence combines approved decisions and implementation, keep desired, specified, and implemented behavior visibly distinct.

Do not require a clean working tree. Record `git status --short`, identify unrelated pre-existing changes, and leave them untouched. If a target artifact already has changes, preserve and account for them; ask only when intent cannot be distinguished or safe integration is impossible.

Completion criterion: one explicit evidence basis is recorded, relevant evidence is inspectable, and unrelated working state is inventoried rather than used as a reason to stop.

### 2. Detect discrepancies and present the plan

Read repository instructions, `specs/README.md`, the applicable `SPEC-OF-SPECS`, the canonical glossary, relevant specs, and the evidence basis. Load [REFERENCE.md](REFERENCE.md) when the update is non-trivial because it contains the discrepancy table, authoring checks, and rollback procedure.

Classify every relevant area using the definitions above. Build a discrepancy table with the spec path, type, evidence, current spec contract, and proposed action. Account explicitly for in-spec changes that require no edit. If terminology work is indicated, load [`ubiquitous-language`](../ubiquitous-language/SKILL.md) and resolve the canonical glossary before finalizing scope.

Present the table and an execution plan before editing. Name the evidence basis, exact authorized path set, versions or new-spec form, terminology route, editing mode, review sequence, and rollback scope. This is a visibility gate, not a request for redundant approval unless the user or repository requires one.

Completion criterion: every relevant area has an evidenced disposition and the complete edit/review plan is visible before artifact changes.

### 3. Produce one reviewable candidate

Record the pre-edit state of every authorized path, including whether it was absent and any pre-existing content or diff. Keep specs prescriptive and language-agnostic. Requirements may be grounded in explicit human-approved decisions, implementation and tests, or another declared evidence source; never present desired behavior as already implemented.

Follow the suite's versioning and changelog rules. When terminology changes, continue the verified `ubiquitous-language` workflow against the resolved canonical glossary. Update `specs/README.md` when versions, reading order, dependencies, checklist state, or suite scope changes.

When delegation is available, an editor must use an isolated checkout only when isolation would not discard or misrepresent relevant working-tree evidence. Otherwise edit in process with exact path ownership. The invoking agent remains scope owner, durable writer, acceptance authority, and final reporter.

Completion criterion: one candidate accounts for every planned action, changes only authorized paths, preserves unrelated work, follows suite form, and records exact version/changelog evidence.

### 4. Run three sequential reviews

Review the same candidate in this order:

1. **Contract consistency** — every changed requirement is supported by the declared evidence basis; desired, specified, and implemented states are not conflated.
2. **Cross-spec integrity** — glossary terms, links, prefixes, required forms, reading order, dependencies, and related contracts remain coherent.
3. **Mechanical quality** — versions, changelogs, section order, links, and language-agnostic form are valid.

Each pass must succeed before proceeding. Fix failures only within the authorized path set and rerun the failed and subsequent passes. If shared-skill behavior changed, run `audit-shared-skills` under the repository's union schema.

Completion criterion: all three pass results identify the reviewed candidate, and any required shared-skill audit has no new target finding.

### 5. Roll back or report

If editing is interrupted or a required gate cannot complete, restore only this run's changes to authorized paths using their recorded pre-edit state. Preserve unrelated and pre-existing edits; never use a blanket restore over `specs/`, the repository, or the working tree.

On success, reread every changed artifact and report the evidence basis, discrepancy dispositions, exact changed paths and versions, review results, shared-skill audit result when applicable, and unresolved concerns.

Completion criterion: failure leaves no partial edit from this run, or success leaves one fully reviewed spec/glossary candidate with complete evidence and path accounting.

## Reference

When the discrepancy set is non-trivial, load [REFERENCE.md](REFERENCE.md) for evidence prompts, plan forms, authoring checks, reviews, and exact-path rollback guidance.

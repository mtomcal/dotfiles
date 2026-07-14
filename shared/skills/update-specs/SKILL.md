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
---

# Update Specs

## Language Definitions

- **Spec discrepancy** — evidenced mismatch or decision point between implementation changes and specs.
- **Coverage gap** — changed behavior or module lacks spec coverage.
- **Violation** — implementation contradicts a normative clause.
- **Checklist drift** — a spec checklist no longer matches implementation.
- **Reasoning gap** — facts exist but the invariant, decision rule, or lifecycle rationale is missing.
- **In-spec change** — implementation remains within allowed behavior and needs no behavioral spec update.

## Workflow

Use this workflow to synchronize a repository's spec suite without inventing behavior.

### 1. Route and pin the Git comparison

Require one caller-supplied Git boundary, either a single `<base>` revision or one complete `<base>..<head>` comparison. This is input to the skill, not an `update-specs` executable or `--since` option.

Require a clean tree with `git status --porcelain`. Normalize a single revision to `<base>..HEAD`; use a complete two-dot comparison unchanged. Reject missing endpoints, three-dot notation, or multiple comparisons. Resolve and pin both endpoints as commits with `git rev-parse --verify '<endpoint>^{commit}'`, then use the resulting object-ID comparison for every implementation diff.

Run `git diff --quiet '<base-oid>..<head-oid>' --`: exit 0 means the comparison is empty and this workflow stops; exit 1 means changes exist; any greater exit means the comparison failed and this workflow stops. Never guess a boundary or continue after a failed gate.

Completion criterion: the tree is clean, both endpoint commits are pinned, and one non-empty two-endpoint comparison is recorded.

### 2. Detect discrepancies and present the plan

Read `AGENTS.md`, `specs/README.md`, the applicable `SPEC-OF-SPECS`, the relevant specs, and the normalized `git diff --stat` and complete `git diff`. If the pinned comparison is non-empty, load [REFERENCE.md](REFERENCE.md) now and keep it available through classification, editing, review, and rollback for its evidence prompts, output forms, and checklists.

Classify every changed area using the authoritative definitions above. Build a discrepancy table with the spec path, type, implementation evidence, current spec evidence, and proposed action. Account explicitly for in-spec changes that require no edit. If terminology work is indicated, load [`ubiquitous-language`](../ubiquitous-language/SKILL.md) and complete its canonical-location routing before finalizing scope, but do not edit the glossary yet.

Present the table and an execution plan before changing any spec or glossary. The plan must name the comparison, exact proposed artifacts including the resolved canonical glossary when applicable, versions or new-spec form, terminology route, editing mode, review sequence, and rollback scope.

Completion criterion: every changed area has an evidenced disposition and the complete edit/review plan is visible before any artifact changes.

### 3. Produce one reviewable candidate

Record the pre-edit commit and exact authorized path set. Keep specs prescriptive and language-agnostic, do not add requirements unsupported by implementation or tests, and follow the applicable `SPEC-OF-SPECS` for structure, version bumps, and changelogs.

When a discrepancy requires new, revised, or disambiguated terminology, continue the verified [`ubiquitous-language`](../ubiquitous-language/SKILL.md) workflow against the resolved repository-authoritative glossary. This workflow retains its discrepancy plan, candidate integration, review gates, and acceptance authority; it does not directly take over terminology ownership.

If delegation is available, select checkout topology before transport. Read-only reviewers may share a checkout. Any delegate authorized to edit must use an isolated worktree or clone from the recorded pre-edit commit with an exact file scope; a separate pane is not isolation. The invoking agent remains the sole plan and scope owner, durable writer/integrator, acceptance authority, and final reporter. The editor returns a commit or patch, exact changed paths, version/changelog evidence, and concerns without mutating the invoking checkout or durable workflow state.

If delegation is unavailable, the invoking agent performs the same authoring sequence in process and retains the same path inventory and evidence. In either mode, update `specs/README.md` when its recorded versions, reading order, dependency graph, checklist, or scope is affected.

Completion criterion: one candidate accounts for every planned action, changes only authorized artifacts, follows suite form and terminology ownership, and has exact diff and version evidence.

### 4. Run three sequential reviews

Review the candidate in this order:

1. **Contract consistency** — every changed requirement is supported by the pinned implementation diff or tests, and no still-implemented requirement was removed without evidence.
2. **Cross-spec integrity** — glossary use, links, prefixes, required forms, reading order, and dependency claims remain coherent across the suite.
3. **Mechanical quality** — required versions, changelogs, section order, Markdown links, and language-agnostic forms are valid.

Each pass must succeed before proceeding. Apply fixes in the same authorized editable checkout and rerun failed passes; no pass may waive or rerank another. In delegated mode, integrate only the exact candidate head that passed all three reviews. If shared-skill behavior changed, run `audit-shared-skills` under the repository's existing union schema.

Completion criterion: all three pass results identify their reviewed candidate, the invoking agent has integrated that exact candidate when delegated, and any required shared-skill audit has completed without a new target finding.

### 5. Roll back or report

If a guardrail interrupts editing or a required gate cannot be completed, restore only this run's tracked and newly created artifact paths to the recorded pre-edit state. Do not integrate an interrupted isolated candidate, do not leave a partially synchronized suite, and do not use a broad restore that can affect unrelated paths. Report the interruption and the smallest corrective next step.

On success, reread every changed artifact and report the original boundary plus pinned comparison, discrepancy dispositions, exact changed paths and versions, three review results, shared-skill audit result when applicable, and unresolved concerns.

Completion criterion: failure leaves no partial artifact edit from this run, or success leaves one fully reviewed spec/glossary result with complete path, version, and review evidence.

## Reference

- When the pinned comparison is non-empty after Git preflight, load [REFERENCE.md](REFERENCE.md) because it contains the evidence prompts, output forms, and detailed checklists.
- When a discrepancy requires terminology work, load [`ubiquitous-language`](../ubiquitous-language/SKILL.md) before glossary edits because that skill owns canonical-location selection and terminology updates while this workflow retains plan, integration, review, and acceptance authority.

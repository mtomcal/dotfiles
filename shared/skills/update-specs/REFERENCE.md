# Update Specs Reference

The authoritative discrepancy definitions and evidence routing are in [SKILL.md](SKILL.md). This reference applies them without requiring a Git comparison.

## Classification Evidence

Read the applicable sources in this order:

1. repository instructions for module boundaries and editing rules;
2. `specs/README.md` for suite order, dependencies, versions, and checklists;
3. the applicable `SPEC-OF-SPECS` and canonical glossary;
4. relevant specs in declared reading order; and
5. the declared evidence basis:
   - confirmed human decision summary or decision artifact;
   - pinned Git diff when supplied;
   - relevant working-tree diff, history, code, and tests when implementation is the basis; or
   - each of those sources separately when desired and implemented behavior must be compared.

For every relevant area, capture:

- owning bounded context and governing spec;
- exact approved or implemented behavior and its source;
- applicable normative clauses and checklist entries;
- the invariant, decision rule, or lifecycle rationale a future agent needs;
- one classification from `SKILL.md`, with separate rows for distinct discrepancies; and
- a concrete edit or explicit no-edit disposition.

Build this table before editing:

```md
| # | Spec File | Type | Evidence | Current Spec Evidence | Action |
|---|-----------|------|----------|-----------------------|--------|
```

## Execution Plan

Present this information before artifact changes:

```md
## Spec Update Plan — <evidence basis>

Evidence:
- <approved decisions, pinned comparison, working changes, implementation/tests, or combination>

Dispositions: <counts by authoritative classification>

Artifacts:
- <exact path> — <edit/create/no-edit action and version/form>

Terminology:
- <none, or exact canonical glossary path resolved through ubiquitous-language>

Editing mode:
- <isolated candidate or in-process>
- Pre-edit state: <commit when useful plus exact per-path snapshots>
- Authorized paths: <exact paths>
- Unrelated working state: <paths that must remain untouched>

Review:
1. contract consistency
2. cross-spec integrity
3. mechanical quality

Rollback:
- restore/remove only this run's changes to authorized paths
```

This is a visibility gate. Do not infer another approval request unless repository guidance or the caller requires one.

## Editing and Delegation

The invoking agent owns the discrepancy table, authorized scope, pre-edit state, integration, acceptance, and final report.

Use an isolated editor only when the complete evidence basis can be represented there. If relevant evidence includes uncommitted target-file changes, edit in process or transport those exact changes deliberately; never silently drop them by starting from `HEAD`.

A delegated editor receives the evidence basis, exact authorized paths, spec and glossary authorities, and return contract. It returns a commit or patch, exact changed paths, version/changelog evidence, and concerns. The invoking agent integrates only the reviewed candidate.

Without delegation, perform the same ordered edits and reviews in process. Preserve the discrepancy table, path inventory, and pass evidence.

## Spec Authoring Rules

For each candidate update:

- Ground every behavioral change in the declared evidence basis.
- Explicitly label desired behavior that is not implemented; specs may prescribe approved future behavior without claiming implementation exists.
- Keep requirements prescriptive and language-agnostic.
- Use schema tables, decision tables, or pseudocode when structure is needed.
- Follow the applicable `SPEC-OF-SPECS` required sections and version policy.
- Bump every modified versioned spec and append its dated changelog entry.
- Register new specs in suite order, dependency relationships, prefixes, and checklists where required.
- Route new or revised vocabulary through [`ubiquitous-language`](../ubiquitous-language/SKILL.md) and include its candidate in the authorized review scope.
- Update `specs/README.md` when versions, order, dependencies, checklist state, or suite scope changes.
- Keep edits inside the authorized path set; revise the visible plan before material scope growth.

## Review Passes

Run each pass against the same candidate and record PASS or FAIL with evidence.

### Pass 1: Contract Consistency

Check each added, changed, and removed clause against the declared evidence basis.

Fail when:

- a requirement lacks approved decision, implementation/test, or other declared support;
- desired behavior is described as already implemented;
- a removed requirement still has contrary evidence;
- a discrepancy-plan action is absent; or
- candidate scope exceeds the authorized plan.

### Pass 2: Cross-Spec Integrity

Check:

1. relative links and section anchors resolve;
2. glossary terms and aliases match the canonical glossary;
3. reading order, prefixes, and dependencies remain coherent;
4. changed specs follow required form;
5. linked design notes and repository artifacts still exist; and
6. planned terminology changes passed through the terminology owner.

### Pass 3: Mechanical Quality

Check:

1. version bumps match contract impact;
2. dated changelog entries exist;
3. Markdown links resolve;
4. required sections remain in prescribed order;
5. language-specific implementation code did not enter language-agnostic specs; and
6. changed paths match the authorized inventory.

## Exact-Path Rollback

Before editing, record for each authorized path:

- whether it exists;
- its exact content or a recoverable copy;
- its pre-existing diff when tracked; and
- whether this run may replace, merge with, or only append to it.

If interrupted:

1. stop editors and preserve failure evidence;
2. discard an unintegrated isolated candidate;
3. in process, restore only bytes changed by this run and remove only files created by this run;
4. verify unrelated `git status --short` entries are unchanged; and
5. report rolled-back paths and the smallest corrective step.

Never use a broad checkout, reset, clean, or stash as a workflow prerequisite or rollback substitute.

## Completion Evidence

On success, report:

- declared evidence basis and any pinned comparison actually used;
- discrepancy dispositions, including no-edit rows;
- exact created/modified paths and resulting versions;
- terminology result and canonical glossary path;
- candidate identity when delegation was used;
- contract, cross-spec, and mechanical review results;
- shared-skill audit result when applicable; and
- unresolved concerns or follow-up work.

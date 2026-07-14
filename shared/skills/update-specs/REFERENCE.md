# Update Specs Reference

The authoritative discrepancy definitions are in [SKILL.md](SKILL.md#language-definitions). This file applies those terms without redefining them.

## Git Boundary Recipe

Accept exactly one non-empty caller value in either `<base>` or `<base>..<head>` form. A single base compares that commit to `HEAD`; a complete two-dot form compares its two supplied endpoints. Do not append another `..HEAD` to a complete comparison, and do not accept omitted endpoints, three-dot merge-base semantics, or multiple comparisons.

A shell implementation may normalize and pin the comparison as follows:

```bash
boundary='<caller-supplied value>'

case "$boundary" in
  ""|..*|*..|*...*|*..*..*)
    printf 'invalid Git boundary: %s\n' "$boundary" >&2
    exit 2
    ;;
  *..*)
    base_ref=${boundary%%..*}
    head_ref=${boundary#*..}
    ;;
  *)
    base_ref=$boundary
    head_ref=HEAD
    ;;
esac

base_oid=$(git rev-parse --verify "${base_ref}^{commit}") || exit $?
head_oid=$(git rev-parse --verify "${head_ref}^{commit}") || exit $?
comparison="${base_oid}..${head_oid}"

git diff --quiet "$comparison" --
case $? in
  0) printf 'comparison is empty: %s\n' "$comparison"; exit 1 ;;
  1) ;; # differences exist
  *) printf 'Git comparison failed: %s\n' "$comparison" >&2; exit 2 ;;
esac
```

Use the pinned `$comparison` for `git diff --stat "$comparison" --` and `git diff "$comparison" --`. Git describes this diff form as comparing two endpoints; do not infer three-dot merge-base behavior or allow a moving branch name to change the evidence after preflight.

## Classification Evidence

Read in this order:

1. `AGENTS.md` for module boundaries and repository rules.
2. `specs/README.md` for suite reading order, dependencies, versions, and checklists.
3. The applicable `SPEC-OF-SPECS` and relevant specs in their declared reading order.
4. `git diff --stat "$comparison" --` for changed paths and magnitude.
5. `git diff "$comparison" --` for complete implementation evidence.

For every changed area, capture:

- the owning module and governing spec, if any;
- exact changed behavior, tests, paths, and command surfaces;
- applicable normative clauses and checklist entries;
- the invariant, decision rule, or lifecycle rationale a future agent needs;
- one classification from the authoritative definitions, plus a separate row when one area has distinct discrepancies; and
- a concrete edit or explicit no-edit disposition.

Reasoning-gap evidence often appears where source, generated output, runtime state, and active pointers form a multi-stage lifecycle; where Git, filesystem, or tool constraints determine safe behavior; or where a bug fix required reconstructing intent from implementation and tests. Use these as investigation prompts, not as replacement definitions.

Build this table before editing:

```md
| # | Spec File | Type | Implementation Evidence | Current Spec Evidence | Action |
|---|-----------|------|-------------------------|-----------------------|--------|
```

## Execution Plan

Present the discrepancy table and this information before artifact changes:

```md
## Spec Update Plan — <original boundary>

Pinned comparison: <base oid>..<head oid>
Dispositions: <counts by authoritative classification>

Artifacts:
- <exact path> — <edit/create/no-edit action and version/form>

Terminology:
- <none, or exact canonical glossary path resolved through ubiquitous-language before edits>

Editing mode:
- <isolated delegated candidate or in-process fallback>
- Pre-edit commit: <oid>
- Authorized paths: <exact paths>

Review:
1. contract consistency
2. cross-spec integrity
3. mechanical quality

Rollback:
- restore/remove only the authorized paths produced by this run
```

Presentation is the pre-edit sequence gate. Do not infer a separate approval requirement unless repository guidance or the user requires one.

## Editing and Delegation

The invoking agent owns the discrepancy table, authorized scope, pre-edit state, integration, acceptance, and final report.

When delegation exists:

1. Pin the implementation comparison and pre-edit commit before transport selection.
2. Give a read-only investigator or reviewer the comparison, artifact scope, and expected evidence; read-only work may share a checkout.
3. Give one editor an isolated worktree or clone from the pre-edit commit, the discrepancy table, exact authorized paths, spec/glossary authorities, and return contract. A separate pane without a separate checkout is insufficient.
4. Require the editor to return a commit or patch, exact changed paths, version and changelog changes, evidence for each plan row, and concerns. The editor does not write the invoking checkout or durable workflow state directly.
5. Run the three reviews against a pinned candidate commit. Return fixes to the same isolated editable checkout and update the candidate identity.
6. After all three passes, integrate only the exact reviewed candidate. The invoking agent remains the durable writer/integrator and acceptance authority.

Without delegation, perform the same ordered edits and reviews in process. Keep the pre-edit commit, exact path inventory, discrepancy table, and pass evidence visible so the fallback is behaviorally equivalent.

## Spec Authoring Rules

For each candidate update:

- Ground every behavioral change in the pinned implementation diff or tests; do not invent requirements.
- Keep requirements prescriptive and follow the target suite's normative conventions.
- Keep specs language-agnostic; use schema tables, decision tables, or pseudocode when structure is needed.
- Follow the applicable `SPEC-OF-SPECS` required sections and version policy.
- Bump every modified versioned spec as required and append its dated changelog entry.
- For a new spec, follow the suite template and register its prefix, reading-order position, dependency relationships, checklist coverage, and README entry where the suite requires them.
- When new or revised vocabulary is needed, use [`ubiquitous-language`](../ubiquitous-language/SKILL.md) to resolve the canonical glossary path before the plan gate, then continue that workflow during editing; preserve the glossary's established preamble and form. Return the glossary candidate to this workflow's review scope.
- Update `specs/README.md` when recorded versions, reading order, dependency graph, implementation checklist, or suite scope changed.
- Keep all edits inside the authorized artifact set. Revise the visible plan before material scope growth.

## Review Passes

Run the passes sequentially against the same pinned candidate. Record PASS or FAIL with evidence and candidate identity. Fix failures in the authorized editable checkout and rerun failed passes; do not let one pass suppress another.

### Pass 1: Contract Consistency

Check each added, changed, and removed normative clause against the pinned implementation diff and tests.

Fail when:

- a new requirement lacks supporting implementation or test evidence;
- a removed requirement still has clear implementation support;
- a changed rationale describes behavior that does not exist;
- a discrepancy-plan action is absent from the candidate; or
- candidate scope exceeds the visible authorized plan.

### Pass 2: Cross-Spec Integrity

Check:

1. internal cross-references and section anchors resolve;
2. glossary terms and aliases match the repository-authoritative glossary;
3. reading order, prefixes, and dependency claims remain coherent;
4. new and changed specs follow the applicable required form;
5. linked design notes and repo-local explainers still exist; and
6. every planned terminology change passed through the terminology owner.

### Pass 3: Mechanical Quality

Check:

1. required version bumps are present and correctly classified;
2. required dated changelog entries are present;
3. Markdown links resolve;
4. required sections occur in the prescribed order;
5. language-specific code did not enter language-agnostic specs; and
6. exact changed paths match the authorized artifact inventory.

## Rollback Procedure

Before editing, record the pre-edit commit, tracked authorized paths, and planned new paths. If a guardrail interrupts editing or a required gate cannot finish:

1. stop all editors and preserve the interruption evidence;
2. in delegated mode, do not integrate the partial candidate and discard or reset only its isolated item worktree/branch;
3. in in-process mode, restore each tracked item-produced path from the recorded pre-edit commit and remove only new paths created by this run;
4. verify `git status --porcelain` contains no artifact edit from this run; and
5. report the interruption, rolled-back paths, retained unrelated state, and smallest corrective next step.

Do not run a blanket restore over `specs/` or a glossary directory. Exact-path rollback preserves the clean preflight contract without expanding authority to unrelated files.

## Completion Evidence

On success, report:

- original boundary and pinned object-ID comparison;
- discrepancy table dispositions, including in-spec no-edit rows;
- exact created/modified paths and resulting versions;
- terminology owner result and canonical glossary path when applicable;
- candidate identity and integration evidence when delegated;
- contract, cross-spec, and mechanical review results;
- `audit-shared-skills` result when shared-skill behavior changed; and
- unresolved concerns or follow-up work.

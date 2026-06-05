# Update Specs Reference

Use this workflow when spec maintenance needs to be explicit, reviewable, and repeatable across agent harnesses.

## Pre-flight

1. Verify the working tree is clean with `git status --porcelain`.
2. Require an explicit git boundary: `--since <ref>`.
3. Verify the ref resolves and that `git diff <ref>..HEAD` is non-empty.

If any gate fails, stop and report the smallest corrective next step.

## Detect Discrepancies

Read these in order:

1. `AGENTS.md` module boundaries
2. `specs/README.md` dependency graph and implementation checklist
3. Relevant spec files in `specs/`
4. `git diff --stat <ref>..HEAD`
5. `git diff <ref>..HEAD`

Classify each changed area with one of these labels:

| Type | Signal |
|------|--------|
| `coverage gap` | Code changed but no current spec covers the behavior or module |
| `violation` | Code contradicts a current "MUST" clause |
| `checklist drift` | Spec checklist claims something that the implementation no longer matches |
| `reasoning gap` | Specs list facts, but omit the invariant or lifecycle rationale needed to make safe decisions |
| `in-spec change` | The code changed inside behavior the spec already allows; no spec update needed |

Build a discrepancy table:

```md
| # | Spec File | Type | What Changed | What Spec Says | Action |
|---|-----------|------|-------------|----------------|--------|
| 1 | ai-agent-config.md | reasoning gap | `pim` fix depended on Git empty-dir behavior | Specs mention `resolved/extensions/` but not the empty-set invariant | Add lifecycle rationale and edge-case rule |
```

## Execution Plan

Present the discrepancy table and proposed execution plan before editing.

Use this format:

```md
## Spec Update Plan — <ref>

[N] discrepancies found: [n1] violations, [n2] coverage gaps, [n3] checklist drift, [n4] reasoning gaps.

Execution:
- update the affected specs
- revise glossary or design-note links if terminology changed
- run review passes

Review:
- contract consistency
- cross-spec integrity
- mechanical quality
```

## Delegation Pattern

If the active harness exposes subagents, reviewer agents, or equivalent delegation tools:

1. Send one worker to update specs using the discrepancy table.
2. Send reviewers through the three review passes sequentially.
3. Re-run only the failed pass after fixes.

If the harness does not expose delegation tools:

1. Perform the same edit sequence manually.
2. Keep the discrepancy table in the thread.
3. Run the review passes yourself as explicit checklists before finishing.

## Spec Authoring Rules

For each spec update:

- Keep the tone prescriptive.
- Do not embed code.
- Use schema tables, decision tables, or pseudocode when behavior needs structure.
- Add new terms to `specs/UBIQUITOUS_LANGUAGE.md` when terminology changed or was ambiguous.
- Update `specs/README.md` if spec versions or reading-order guidance changed materially.
- Bump the version and append a changelog entry for modified spec files that track changelogs.

## Review Passes

### Pass 1: Contract Consistency

Check every new or changed requirement against the code or tests in `<ref>..HEAD`.

Fail if:

- a new "MUST" has no supporting code or test evidence
- a removed requirement still has clear implementation support
- the updated rationale points at behavior that does not exist

### Pass 2: Cross-Spec Integrity

Check:

1. internal cross-references still resolve
2. glossary terms match spec terminology
3. reading order and dependency claims still make sense
4. any linked design notes or repo-local explainers still exist

### Pass 3: Mechanical Quality

Check:

1. version bumps are present where required
2. changelog entries are present where required
3. markdown links are valid
4. no code blocks slipped into language-agnostic specs unless they are pseudocode

## Guardrail Fallback

If a delegated spec update or review is interrupted mid-edit:

1. roll back partial spec edits
2. report the interruption clearly
3. recommend narrowing scope or raising guardrails before retrying

## Shared-Skill Maintenance

Because this skill lives in `shared/skills/`, any frontmatter or structure changes should be followed by `audit-shared-skills`.

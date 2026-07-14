---
name: resolving-merge-conflicts
description: Resolve in-progress Git merge, rebase, cherry-pick, or revert conflicts by tracing both sides to their intent before editing hunks. Use when Git reports unmerged paths or a user asks to resolve conflicts.
metadata:
  short-description: Resolve Git conflicts by intent
allowed-tools: read,write,edit,bash
---

# Resolving Merge Conflicts

## Language Definitions

- **Source intent** — behavior and rationale introduced by one side of a conflict.
- **Authoritative source** — direction or evidence determining precedence when intents conflict.
- **Combined result** — resolution preserving compatible intents and explicitly choosing among incompatible ones.
- **Remaining operation** — Git continuation, commit, or abort still requiring authorization.

`ours` and `theirs` are operation-dependent labels, not stable intent terms.

## Workflow

Resolve intent, not punctuation.

### 1. Establish Git state

Inspect status, the exact active merge, rebase, cherry-pick, or revert and its current step, every unmerged path, available index stage entries, and relevant history. Record unrelated working-tree and index changes before editing so they remain protected.

Map the available base (stage 1), ours (stage 2), and theirs (stage 3) entries to the commits and source sides they represent in this operation. Do not infer intent from the labels: during rebase, ours is the branch being rebased onto and theirs is the work being replayed, so their everyday meaning appears reversed.

Completion criterion: every conflicted path, the operation and current step, available base and both side identities, and all unrelated changes are accounted for.

### 2. Trace both intents

For every hunk, inspect the introducing commits, commit messages, blame/history, linked issues or plans, and relevant specs. Before editing, record both source-intent statements, the evidence or authority behind each, and either the authoritative source deciding precedence or explicit uncertainty.

If the intents are irreconcilable, their compatibility is unclear, or authority is insufficient, stop without editing or changing the operation. Explain the competing intents and consequences, then ask the user whether to choose a side, redesign, or abort. Never abort silently.

Completion criterion: every hunk has two evidenced intent statements and a precedence authority or explicit uncertainty; every uncertainty has stopped for a user decision.

### 3. Resolve each hunk

Preserve both intents where compatible. Where they are incompatible, follow the operation's stated goal and the authoritative spec or explicit user decision. Do not invent unrelated behavior or absorb cleanup.

Remove conflict markers, inspect the complete combined result, and check semantic neighbors affected beyond the textual hunk, such as callers, tests, configuration, or documentation. Each resolution must be explainable against its two source intents before staging.

Completion criterion: conflict markers are gone, every combined result and semantic neighbor has been inspected, and each choice traces to intent and authority.

### 4. Verify and stage selectively

Run the repository's focused checks first, then broader required checks as practical. Fix only failures induced by the merge or active operation; report unrelated failures or cleanup without modifying or staging them.

Stage only verified conflict resolutions while preserving the unrelated-change inventory. Confirm no unmerged index entries remain and inspect the staged diff for the intended resolutions and no unrelated changes.

Completion criterion: focused and applicable broader results are recorded, verified resolutions alone are staged, no unmerged entries remain, and the staged diff leaves unrelated changes untouched.

### 5. Report the remaining operation

Report:

- intents preserved and trade-offs made;
- files staged;
- checks and results, including failures or limitations;
- the active Git operation; and
- the exact remaining action and whether the user authorized it, such as a merge commit, `git rebase --continue`, `git cherry-pick --continue`, `git revert --continue`, or the operation-specific abort.

Do not commit, continue, or abort unless the user explicitly requested that exact action. Without authorization, stop with the verified resolutions staged and the operation active.

Completion criterion: the report contains every field and either leaves the exact action awaiting authorization or records the result of the exact action already authorized by the user.

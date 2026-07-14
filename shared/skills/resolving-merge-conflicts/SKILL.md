---
name: resolving-merge-conflicts
description: Resolve in-progress Git merge, rebase, cherry-pick, or revert conflicts by tracing both sides to their intent before editing hunks. Use when Git reports unmerged paths or a user asks to resolve conflicts.
metadata:
  short-description: Resolve Git conflicts by intent
allowed-tools: read,write,edit,bash
---

# Resolving Merge Conflicts

Resolve intent, not punctuation.

## 1. Establish Git state

Inspect status, the active Git operation, unmerged paths, stage entries, and relevant history. Preserve unrelated working-tree changes. Identify the exact operation and commits represented by ours/base/theirs; remember that labels can reverse meaning during a rebase.

Completion criterion: every conflicted path is listed and both sides' commits are identified.

## 2. Trace both intents

For each conflict, inspect the introducing commits, commit messages, blame/history, linked issues or plans, and relevant specs. State what each side was trying to preserve before editing.

If intent is irreconcilable or its authority is unclear, never abort silently. Stop, explain the competing intents and consequences, and ask the user whether to choose a side, redesign, or abort the Git operation.

Completion criterion: each hunk has two intent statements and an authoritative source or explicit uncertainty.

## 3. Resolve hunks

Preserve both intents where compatible. Where they conflict, follow the operation's stated goal and the authoritative spec or user decision. Do not invent unrelated behavior. Remove all conflict markers and inspect the combined result, including nearby code affected semantically but not textually.

Completion criterion: no unmerged entries or conflict markers remain, and each resolution can be explained against source intent.

## 4. Verify and stage

Run the repository's focused checks first, then broader required checks as practical. Fix merge-introduced failures without absorbing unrelated cleanup. Stage only verified resolutions and inspect the staged diff.

Completion criterion: resolutions are staged, relevant checks pass, and unrelated changes remain untouched.

## 5. Report the remaining operation

Do not commit, continue, or abort automatically unless the user explicitly requested that action. Report:

- intents preserved and trade-offs made
- files staged
- checks and results
- the active Git operation
- the exact remaining user-approved action, such as merge commit, `git rebase --continue`, `git cherry-pick --continue`, or abort

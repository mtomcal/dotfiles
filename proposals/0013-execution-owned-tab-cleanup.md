# 0013 — Execution-owned tab cleanup

**Status:** Superseded by [0014](0014-model-native-agent-environment.md)

**Created:** 2026-08-10

## What shipped

The solo developer can run a long coordinated engineering effort without its Herdr workspace accumulating an unusable trail of finished implementation, correction, and review tabs. Tabs created for execution identify the molecule and work they belong to, making them distinguishable from the developer’s own shells, coordinator tab, long-lived tools, and unrelated terminal work.

As work completes, the coordinator removes execution-owned tabs that no longer have a workflow role. Cleanup follows durable engineering state rather than guessing from terminal appearance: the applicable work must be closed with complete evidence, and no agent in the tab may still be working, blocked, or of unknown status. A final sweep removes any remaining owned tabs after successful molecule completion. Long molecules therefore release finished terminal resources incrementally instead of postponing all cleanup until the end.

Cleanup is conservative when durable and live state disagree. The coordinator leaves the tab in place, reports the contradiction or residual resource, and continues through ordinary reconciliation. Failure to remove a terminal resource does not erase or reopen already evidenced engineering work. A fresh terminal listing verifies what was actually removed rather than treating a close request as proof.

Ownership remains narrow. Tabs created by people, pre-existing workspace tabs, the caller’s tab, and resources without the execution ownership marker are never selected automatically. Herdr continues to provide replaceable live transport while Beads remains authoritative for work status, evidence, and recovery. Terminal cleanup therefore reduces workspace clutter without turning pane state into workflow authority.

## Why it exists

A real coordinated run in the Firepod workspace grew to twenty-one tabs. Thirteen belonged to older implementation and review work while newer work continued, leaving finished corrections and repeated test-quality passes mixed with the active coordinator, a human shell, a context manager, and current workers. Status labels such as `done` and `idle` showed likely clutter but could not prove that evidence had been persisted or that an agent would not be reused.

Waiting for the whole molecule to finish allows this sprawl to compound, while closing tabs based only on apparent inactivity risks destroying useful live context. The developer needs terminal resources to carry explicit execution ownership and to be collected when durable work state proves they are no longer needed. This keeps long-running workspaces navigable without weakening recovery or granting a generic liveness mechanism authority to terminate workers.

## Out of scope

- Closing human-created, pre-existing, caller, coordinator, or otherwise unowned tabs.
- Treating `idle`, `done`, elapsed time, output volume, or terminal focus as sufficient proof that work is disposable.
- Terminating active, blocked, unknown, or evidence-incomplete workers.
- Making Herdr tabs, labels, or pane contents authoritative workflow state.
- Cleaning legacy tabs automatically when they lack the execution ownership marker.
- Deleting branches, worktrees, attempts, decisions, transcripts, or other durable engineering records.

## FAQ

**Why identify execution ownership in the tab label?**

A visible, inspectable marker lets the coordinator rediscover its task tabs from fresh Herdr state without persisting opaque runtime identifiers. Remembering tab IDs in Beads was rejected because terminal identifiers are runtime state, while matching every project-named tab was rejected because human and tool tabs can share project wording.

**Revisit if:** Herdr provides a first-class, queryable resource-ownership field that survives coordinator recovery without becoming workflow authority.

**Why clean tabs after each work item instead of only after the molecule finishes?**

Long coordinated molecules may complete many implementations, corrections, and reviews before their final gate. Final-only cleanup was rejected because it preserves the exact workspace sprawl this feature addresses. Incremental cleanup occurs only after durable closure and complete evidence, with a final sweep as a backstop.

**Revisit if:** Measured coordinated runs remain small enough that incremental cleanup adds lifecycle complexity without materially reducing clutter.

**Why is agent status insufficient to authorize cleanup?**

`done` and `idle` describe live transport state, not whether evidence was recorded or the owning work passed its closure gate. Beads closure with complete evidence establishes workflow eligibility; Herdr status then prevents closure when a worker is active, blocked, or uncertain. Either source alone was rejected because it cannot prove both durable completion and safe live-resource removal.

**Revisit if:** Herdr and Beads gain a transactional lifecycle operation that proves evidence persistence, workflow closure, and terminal release together.

**Why does cleanup failure not reopen completed engineering work?**

A tab is replaceable runtime transport. Reopening verified source work because a local close operation failed would make terminal hygiene another workflow authority. Cleanup instead verifies the remaining topology and reports residual owned tabs for later reconciliation.

**Revisit if:** Residual owned tabs routinely accumulate because best-effort cleanup failures are ignored rather than reconciled.

**Why does this not introduce autonomous worker termination?**

The coordinator does not infer liveness failure or terminate work from time, silence, or context estimates. It collects only explicitly owned resources after durable work closure, complete evidence, and a safe observed agent state. The broader liveness monitor and active-worker termination mechanisms rejected by earlier proposals remain excluded.

**Revisit if:** Cleanup is expanded to make termination decisions for nonterminal work or agents whose evidence and lifecycle state are uncertain.

## Open questions

None

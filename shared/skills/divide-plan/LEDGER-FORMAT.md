# Execution Ledger Format

Directly apply this operational format whenever creating or updating an execution ledger's coordinator-owned `PLAN.md`.

```markdown
# <Objective> — Execution Ledger

## Identity
- Ledger path: <absolute path>
- Status: planning | executing | blocked | complete
- Created: <timestamp>
- Coordinator: current coordinating agent
- Repository root: <canonical absolute path>
- Repository id: <stable id>

## Immutable source
- Implementation plan: <absolute path>
- Source SHA-256: <digest>
- Base commit: <full hash>
- Head / integration baseline: <full hash>
- Spec comparison: <full-base>..<full-head>

## Orchestration configuration
| Role | Command | Exact model id | Thinking level | Rationale |
|---|---|---|---|---|
| Implementation | ... | ... | ... | ... |
| Oversight | ... | ... | ... | ... |
- Observation timeout: <duration>
- Approved exceptional final passes: <pass + risk + approval, or none>

## Git topology
- Integration branch: <branch>
- Integration worktree: <absolute path>
- Current integrated fixed point: <full hash>

## Source coverage
| Implementation-plan gap / criterion | Slice(s) | Coverage rationale |
|---|---|---|

## Dependency DAG
| Slice | Blocked by | Why |
|---|---|---|

## Frontier
- <derived ready slices, or none>

## Slice state
| Slice | State | Branch | Worktree | Implementer reference | Current worker fixed point | Corrections used | Quality verdict | Integrated commit |
|---|---|---|---|---|---|---:|---|---|

## Verification index
| Artifact | Axis | Current fixed point | Verdict | Attempts |
|---|---|---|---|---:|

## Final review state
- Reviewed integration fixed point: <full hash or pending>
- Repository gates: pending | pass | needs-remediation | blocked
- Standards: pending | pass | needs-remediation | blocked
- Spec: pending | pass | needs-remediation | blocked
- Premortem: pending | pass | needs-remediation | blocked
- Security: pending | pass | needs-remediation | blocked
- Exceptional passes: <states or none>
- Final remediation batches used: <0..2>

## Acceptance
| Source-plan criterion | Integrated evidence | Status |
|---|---|---|

## Recovery
1. Resolve `.plan`; stop and request approval if it is stale or points elsewhere.
2. Recompute the implementation plan SHA-256 and compare it with the immutable source record.
3. Reconcile integration and slice worktrees, branches, and full commits with Git before changing state.
4. Recompute the frontier from slices whose blockers are integrated.
5. Rediscover live Herdr resources; no pane id is durable identity.
6. Resume the exact pending transition or record why the ledger is blocked.

## Decisions and history
- <timestamp> — <decision, approval, transition, reconciliation, or recovery event>

## Attempts
- <timestamp> — <slice/final scope, fixed point, attempt, verdict, and artifact>
```

## Invariants

- The coordinator is the sole writer of ledger `PLAN.md`, slice packets, verification artifacts, and integration records.
- The immutable source block never changes. A source SHA mismatch blocks execution.
- Snapshot fields such as status, frontier, slice state, verification index, and final review state are updated in place. Only `Decisions and history`, `Attempts`, and attempt sections in verification artifacts are append-only.
- Use full commit hashes for every fixed point and integration record.
- The dependency graph is acyclic. Frontier is derived from `ready` slices whose blockers are `integrated`.
- States are `ready`, `implementing`, `verifying`, `needs-correction`, `verified`, `integrating`, `integrated`, and `blocked`; `complete` applies to the ledger.
- Corrections used never exceeds two. Final remediation batches used never exceeds two.
- Store a durable agent purpose/reference only when useful; never store a public Herdr ID or display selector as identity.
- No state transition relies only on a worker claim, idle pane, or missing pane.

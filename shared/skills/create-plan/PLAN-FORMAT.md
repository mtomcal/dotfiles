# PLAN.md Format

Load this reference whenever creating or updating a plan workspace's orchestration index. The parent agent owns every field.

## Required structure

```markdown
# <Objective> — Implementation Control Plane

## Identity
- Plan workspace: <absolute path>
- Status: planning | executing | blocked | complete
- Created: <timestamp>
- Parent owner: current orchestrating agent

## Immutable objective
<Behavioral outcome. Amend only by recording explicit user approval and retaining the original.>

## Context sources
| Kind | Fixed point or path | Authority | Relevance |
|---|---|---|---|
| Spec / decision / research / code | ... | ... | ... |

## Git topology
- Repository root: <absolute path>
- Baseline commit: <full hash>
- Integration branch: <branch>
- Integration worktree: <absolute path>

## Execution defaults
| Worker kind | Command | Model | Thinking | Rationale |
|---|---|---|---|---|
| implementation | `pi ...` or `pis ...` | explicit | explicit | ... |
| review | `pi ...` or `pis ...` | explicit | explicit | ... |

## Dependency DAG
| Slice | Blocked by | Why |
|---|---|---|
| 001-... | — | ... |

## Frontier
- <derived ready slices, or `none`>

## Slice state
| Slice | State | Worktree | Branch | Worker commit | Integrated commit | Herdr session note |
|---|---|---|---|---|---|---|

## Verification matrix
| Slice | Standards | Spec | Tests | Premortem | Security | Visual | Risk rationale |
|---|---|---|---|---|---|---|---|

## Global acceptance criteria
1. ...
2. All repository quality gates pass.

## Interruption and recovery
1. Resolve `.plan` and stop if stale.
2. Confirm baseline, integration branch, worktrees, branches, and commits against Git.
3. Reconcile discrepancies before changing state.
4. Recompute the frontier from slices whose blockers are integrated.
5. Re-read live Herdr ids; never trust a recorded pane id.

## Decision and attempt log
- <timestamp> — <scope, transition, correction, or approved objective amendment>
```

## Invariants

- The immutable objective is changed only with explicit user approval; retain an amendment record.
- Use full commit hashes wherever a fixed point matters.
- The DAG is acyclic. The Frontier section is derived state, not an independent priority list.
- Persist a durable Herdr session label or purpose only if useful; never persist compact pane ids as identity.
- Record risk-matrix rationale before launching reviewers.
- State changes and integration records are appended promptly enough for interruption recovery.

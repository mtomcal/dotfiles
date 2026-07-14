---
name: create-plan
description: Create and operate a file-based implementation control plane with dependency-ordered TDD slices, isolated workers, independent verification, and recoverable state. Use when planning a feature, bug fix, migration, or refactor that may span multiple fresh agent contexts or parallel worktrees.
metadata:
  short-description: Orchestrate verified TDD slice plans
allowed-tools: read,write,edit,bash
---

# Create Plan

Create a recoverable **plan workspace**, not a disposable prose answer. `PLAN.md` is the parent-owned orchestration index; each slice is a fresh-agent task packet; each review has a durable verification artifact.

## 1. Open or create the plan workspace

Find the repository root and inspect its text `.plan` file.

- If `.plan` exists, read its one absolute path. If that target or its `PLAN.md` is missing, report **stale active-plan state** and stop. Do not guess, search `/tmp` for a replacement, or silently rebuild it. Replace the pointer only after explicit user direction.
- If `.plan` does not exist, choose a stable repo id (repository basename plus a short hash of its canonical root), choose a descriptive plan id, and create:

```text
/tmp/agent-plans/<repo-id>/<plan-id>/
├── PLAN.md
├── slices/
└── verifications/
```

Write that absolute directory path plus a newline to `.plan`. Add an exact `.plan` line to the repository's local `.git/info/exclude` if absent; do not require a tracked `.gitignore` change. Never place implementation secrets in this temporary state.

Before writing, read specs, the ubiquitous language, user decisions, relevant research, and current code. Classify the context as spec-driven, research-driven, decision-driven, or hybrid. If unresolved uncertainty prevents a safe implementation shape, route to `wayfinder` instead of inventing a plan.

Completion criterion: `.plan` resolves to one workspace, required context sources are named, and no consequential implementation decision remains implicit.

## 2. Build the orchestration index

Read [PLAN-FORMAT.md](PLAN-FORMAT.md) whenever creating or changing `PLAN.md`. Record:

- immutable objective and context sources
- fixed baseline and dedicated integration branch
- execution defaults for `pi` and/or `pis`, including explicit model and thinking settings
- dependency DAG, derived frontier, and slice state table
- worktree, branch, commit, and current Herdr session references
- verification matrix and global acceptance criteria
- interruption and recovery instructions

The parent agent is the sole writer of `PLAN.md`, slice state, and verification artifacts. Worker and reviewer agents return commits or findings; they never mutate control-plane state. Herdr pane ids are live lookup hints only and MUST NOT be persisted as durable identity because ids compact.

Completion criterion: every slice has a DAG node, every blocker exists, the graph is acyclic, and the frontier equals all `ready` slices whose blockers are `integrated`.

## 3. Write fresh-context slices

Read [SLICE-FORMAT.md](SLICE-FORMAT.md) for every `slices/NNN-<vertical-slice>.md`. A packet must fit one fresh agent context and include behavior, acceptance criteria, blockers, agreed test seam, ordered red/green/refactor tracer bullets, focused commands, likely files, constraints, and required completion evidence.

Prefer narrow end-to-end behavior over horizontal layers. One behavior test fails, minimum implementation passes, then the next mini-cycle begins. For a wide mechanical refactor that cannot stay green as a vertical slice, use the exception: **expand → migrate in bounded batches → contract**. Encode every migration dependency and keep the old form until all migration slices integrate.

Present the proposed slice breakdown and blocker edges to the user when granularity or scope was not already approved. Do not start execution while the task packets still exceed one fresh context.

Completion criterion: each packet is independently understandable, verifiable, and authorized to change only its declared slice.

## 4. Derive verification from risk

Read [VERIFICATION-FORMAT.md](VERIFICATION-FORMAT.md). Standards and Spec reviews are mandatory, independent passes for every slice. Enable the remaining passes from the documented risk matrix:

- Tests for behavior or test changes
- Premortem for operational, migration, concurrency, or hard-to-observe failure risk
- Security for trust-boundary, credential, permission, input, dependency, or data-exposure risk
- Visual for user-visible layout, rendering, motion, responsive, or artifact-fidelity risk

Create flat placeholders such as `001-standards.md`, `001-spec.md`, `001-tests.md`, and `001-premortem.md` only for enabled passes. Also reserve `final-integration.md` and `final-acceptance.md`.

Completion criterion: every enabled review has explicit criteria and no risky dimension is disabled without rationale in `PLAN.md`.

## 5. Execute the dependency frontier

State transitions are:

```text
ready -> implementing -> implemented -> verifying
      -> needs-fix -> implementing
      -> verified -> integrated
```

Only launch a slice when all blockers are integrated.

### Editable workers

Give each active editable slice one Git worktree and one branch from the recorded integration baseline. Explicitly authorize the worker to commit **only that slice** and return the commit hash plus completion evidence. Never let two editing agents share a checkout.

When `HERDR_ENV=1`, load the shared `herdr` skill instead of duplicating its command reference. Launch `pi` or `pis` in a new pane, using the exact command recorded in `PLAN.md`; specify an economical model and thinking level where the task allows it. Re-read current pane ids when controlling Herdr and keep ids out of durable plan claims.

Outside Herdr, run one worker at a time in-process or hand the task packet to a fresh agent context. Preserve the same branch, commit, and evidence contract.

The parent moves a returned commit to `implemented`; a worker's claim is never enough to mark it verified.

### Read-only reviewers

After the worker commits, pin that commit as the review fixed point and move the slice to `verifying`. Read-only reviewers may share the relevant checkout. Under Herdr, use separate smarter Pi instances where appropriate and give each reviewer only its axis criteria. Outside Herdr, perform the same passes in-process with explicitly separate checklists.

The parent writes reviewer results to verification artifacts. `PASS` on all enabled passes moves the slice to `verified`. `NEEDS-FIX` returns work to the original slice branch through `needs-fix -> implementing`; append a new attempt to the same artifact after the fix commit. `BLOCKED` records the blocker without pretending the review ran.

Only after verification does the parent cherry-pick the approved commit(s) onto the integration branch, run focused integration checks, record the integrated commit, and mark the slice `integrated`. Resolve cherry-pick conflicts by intent; do not let a worker alter another slice to make integration convenient.

Completion criterion: every integrated slice has an isolated implementation commit, passing enabled verification attempts, parent-run checks, and an integration commit recorded in `PLAN.md`.

## 6. Finish and recover

After all slices are integrated:

1. run the repository-wide quality gates on the integration branch
2. complete `final-integration.md` against cross-slice interactions
3. complete `final-acceptance.md` against the immutable objective and global criteria
4. report remaining worktrees/branches and the integration branch; do not merge or delete them without authorization

On interruption, reopen `.plan`, verify its target, compare recorded branches/commits/worktrees with Git, and recompute the frontier from integrated blockers. Treat mismatches as reconciliation work and record the correction; never infer success from an idle or missing Herdr pane.

Completion criterion: final reviews pass, acceptance criteria have evidence, and another parent agent can resume from `.plan` without conversation history.

## Guardrails

- Planning and control-plane state belong to the parent; workers and reviewers return evidence only.
- Dependency edges gate on **integrated**, not merely implemented or verified.
- A failed review is fixed on the original slice branch and reviewed again before integration.
- Read-only delegation may share a checkout; editing delegation always uses worktree/clone isolation.
- Never reintroduce removed Pi subagent tools, preset reviewer roles, or profile runtimes.

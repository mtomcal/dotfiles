---
name: create-plan
description: Create and operate a file-based implementation control plane with dependency-ordered TDD slices, isolated workers, independent verification, and recoverable state. Use when planning a feature, bug fix, migration, or refactor that may span multiple fresh agent contexts or parallel worktrees.
metadata:
  short-description: Orchestrate verified TDD slice plans
allowed-tools: read,write,edit,bash
---

# Create Plan

## Language Definitions

- **Plan workspace** — temporary file-based implementation control plane.
- **Active-plan pointer** — repository-local `.plan` file identifying it.
- **Orchestration index** — parent-owned `PLAN.md` holding objective, Git topology, dependencies, verification, and recovery.
- **Slice** — fresh-context packet delivering one vertical behavior.
- **Frontier** — ready slices whose blockers are integrated.
- **Fixed point** — immutable commit under review.
- **Verification artifact** — durable record of one review axis and its attempts.
- **Integration baseline** — commit from which integration and slice worktrees originate.
- **Parent owner** — orchestrating agent solely responsible for state, verification records, and integration.

The parent owner is called the parent below. Repository glossary wording is authoritative where it overlaps. Plan workspaces and slices are not Wayfinder decision tickets, spec-extraction plans, Ralph job plans, teaching state, or Herdr workspaces; each has its own owner and lifecycle.

## Workflow

### 1. Route, open, or create the plan workspace

Find the repository root and inspect its text `.plan` file before planning:

- If `.plan` exists, read its one absolute path. If that target or its `PLAN.md` is missing, report **stale active-plan state** and stop. Do not guess, search `/tmp` for a replacement, or silently rebuild it. Replace the pointer only after explicit user direction.
- If `.plan` does not exist, choose a stable repo id (repository basename plus a short hash of its canonical root) and descriptive plan id, then create `/tmp/agent-plans/<repo-id>/<plan-id>/` with `PLAN.md`, `slices/`, and `verifications/`. Write that absolute directory path plus a newline to `.plan`. Add an exact `.plan` line to local `.git/info/exclude` if absent; do not require a tracked `.gitignore` change. Never place implementation secrets in this temporary state.

Before writing, read specs, the ubiquitous language, user decisions, relevant research, and current code. Classify the context as spec-driven, research-driven, decision-driven, or hybrid. If unresolved uncertainty prevents a safe implementation shape, route to `wayfinder` instead of inventing a plan.

Completion criterion: `.plan` resolves to one workspace, required context sources are named, and no consequential implementation decision remains implicit.

### 2. Build the orchestration index

Before creating or changing `PLAN.md`, load [PLAN-FORMAT.md](PLAN-FORMAT.md) because it owns the complete `PLAN.md` schema and invariants. Record the immutable objective and amendment authority, fixed context sources, full baseline, dedicated integration branch and worktree, explicit `pi` and/or `pis` model and thinking defaults, dependency DAG and derived frontier, slice states and Git/Herdr session references, verification matrix, global acceptance criteria, recovery instructions, and decision/attempt log.

The parent is the sole writer of `PLAN.md`, slice state, verification artifacts, and integration records. Workers and reviewers return commits or findings without mutating the control plane or assuming acceptance authority. Herdr pane ids are live lookup hints only; never persist them as durable identity because they compact.

Completion criterion: every slice has a DAG node, every blocker exists, the graph is acyclic, and the frontier is exactly the `ready` slices whose blockers are `integrated`.

### 3. Write fresh-context slices

Before writing any `slices/NNN-<vertical-slice>.md`, load [SLICE-FORMAT.md](SLICE-FORMAT.md) because it owns the packet schema and tracer-bullet evidence. Each packet must fit one fresh agent context and state its vertical behavior, acceptance and failure criteria, blockers, refactor-resilient public test seam, ordered RED/GREEN/REFACTOR tracer bullets, focused commands, likely files, constraints, authorized scope, and required completion evidence.

Prefer narrow end-to-end behavior over horizontal layers. Observe one behavior test fail for the intended reason, implement the minimum passing change, and only then begin the next cycle. For a wide mechanical refactor that cannot stay green as a vertical slice, use **expand → migrate in bounded green batches → contract**; encode every migration dependency, keep the old form until all migration slices integrate, and block contraction on every migration.

Present the slice breakdown and blocker edges to the user when granularity or scope was not already approved. Do not start execution while any task packet exceeds one fresh context.

Completion criterion: each packet is independently understandable, verifiable, and authorized to change only its declared slice.

### 4. Derive verification from risk

Before selecting passes or writing `verifications/*.md`, load [VERIFICATION-FORMAT.md](VERIFICATION-FORMAT.md) because it owns the risk matrix, append-only attempt schema, axis boundaries, and final-review formats. Standards and Spec reviews are mandatory independent passes for every slice. Also enable:

- Tests for behavior, test, public-seam, regression, or migration changes;
- Premortem for operational, migration, concurrency, recovery, human-use, or hard-to-observe failure risk;
- Security for trust-boundary, credential, permission, input, dependency, network, or data-exposure risk; and
- Visual for user-visible layout, rendering, motion, responsive, screenshot, video, or artifact-fidelity risk.

Create flat per-slice placeholders only for enabled passes, such as `001-standards.md`, `001-spec.md`, `001-tests.md`, and `001-premortem.md`. Reserve `final-integration.md` and `final-acceptance.md`.

Completion criterion: every enabled review has explicit criteria, and every disabled risk dimension has a written rationale in `PLAN.md`.

### 5. Execute the dependency frontier

Use only these transitions:

```text
ready -> implementing -> implemented -> verifying
      -> needs-fix -> implementing
      -> verified -> integrated
```

Launch only frontier slices whose blockers are integrated, never merely implemented or verified.

For each editable slice, create one Git worktree and branch from the recorded integration baseline. Authorize the worker to edit and commit only that slice and to return the full commit hash plus required evidence; editable agents never share a checkout. When `HERDR_ENV=1`, load the shared `herdr` skill, launch `pi` or `pis` in a new pane with the exact `PLAN.md` command and an economical explicit model/thinking level where suitable, and refresh live pane ids whenever controlling Herdr. Outside Herdr, run one worker at a time in-process or use a fresh agent context with the same branch, commit, and evidence contract. Never reintroduce removed Pi subagent tools, preset reviewer roles, profiles, or profile runtimes.

A returned commit moves the slice only to `implemented`; worker claims never establish verification. Pin that commit as the review fixed point and move the slice to `verifying`. Read-only reviewers may share the relevant checkout. Under Herdr, use separate smarter Pi instances where appropriate and provide only each axis's criteria; otherwise run explicitly separate in-process checklists.

The parent records every result in its verification artifact. `PASS` on every enabled pass moves the slice to `verified`. `NEEDS-FIX` returns work through `needs-fix -> implementing` to the original slice branch; append the new fixed point and attempt to the same artifact after the fix, never overwrite failed history. `BLOCKED` records the blocker without pretending the review ran.

Only after verification may the parent cherry-pick approved commit(s) onto the integration branch, run focused integration checks, record the integration commit, and mark the slice `integrated`. Resolve cherry-pick conflicts by both source intents; never let a worker alter another slice for integration convenience.

Completion criterion: every integrated slice has isolated implementation commit(s), passing enabled verification attempts, parent-run checks, and an integration commit recorded in `PLAN.md`.

### 6. Finish and recover

After every slice is integrated:

1. run repository-wide quality gates on the integration branch;
2. complete `final-integration.md` against cross-slice interactions, conflicts, migration order, and all repository gates;
3. complete `final-acceptance.md` against the immutable objective, every global criterion, and required human or visual evidence; and
4. report remaining worktrees, branches, and the integration branch. Do not merge branches or delete worktrees or branches without authorization.

On interruption, reopen `.plan` and stop if its target is stale. Compare the recorded baseline, integration branch, worktrees, branches, and commits with Git; treat mismatches as reconciliation work and record corrections before changing state. Recompute the frontier from integrated blockers and rediscover live Herdr ids. Never infer success from an idle or missing pane.

Completion criterion: both final reviews pass, every acceptance criterion has evidence, and another parent can resume from `.plan` without conversation history.

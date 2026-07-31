---
name: herdr-supervise
description: Supervise one bounded delegated worker in Herdr through preflight model and escalation selection, isolated execution, evidence-based acceptance, cost tracking, and an efficiency verdict against a strong-model-only baseline. Use when a user asks to supervise, delegate, or try an economical worker in Herdr without an immutable implementation plan.
metadata:
  short-description: Supervise bounded Herdr workers
allowed-tools: read,bash
---

# Herdr Supervision

## Language Definitions

- **Supervisor** — agent that owns scope, acceptance, integration, escalation, and the final efficiency verdict; it does not delegate those decisions to a worker.
- **Worker** — isolated implementation agent authorized for exactly one bounded packet.
- **Supervision contract** — preflight record of exact model configurations, prices, baseline, correction budget, timeout, acceptance evidence, and efficiency rule.
- **Critical invariant** — requirement whose violation can invalidate safety, provenance, security, persistence, migration, or the central behavior contract.
- **Correction round** — one consolidated batch of supervisor findings returned to the current worker candidate.
- **Escalation configuration** — exact stronger model command, model id, and thinking level selected before worker launch.
- **Strong-only baseline** — estimated cost and elapsed time for completing the same accepted task with one strong implementation model and no economical worker.
- **Actual supervision cost** — incremental model cost of the supervisor, worker, reviewers, and escalations used from preflight through final acceptance.
- **Efficiency verdict** — mandatory binary `EFFICIENT` or `NOT EFFICIENT` comparison against the strong-only baseline under the precommitted rule.

## Workflow

### 1. Route the work and load transport

Require `HERDR_ENV=1`; if absent, stop because this workflow has no non-Herdr fallback. Load [`herdr`](../herdr/SKILL.md) before controlling any pane. Herdr owns terminal transport; this skill owns supervision and acceptance.

Use this workflow only for one bounded delegated task. If an explicit immutable implementation plan needs slicing, recoverable execution state, or multiple dependent implementation workers, route to [`divide-plan`](../divide-plan/SKILL.md). If no editable delegation is needed, use the relevant review or research workflow with base Herdr transport instead.

Completion criterion: Herdr is available, its skill is loaded, and the task is confirmed as one bounded editable delegation rather than plan execution or read-only work.

### 2. Establish the supervision contract

Ask a short preflight Q&A before creating worker resources. Never hardcode provider or model rankings. Obtain and record:

1. the exact supervisor provider/model id and thinking level;
2. the exact initial worker command, provider/model id, and thinking level;
3. the exact escalation command, provider/model id, and thinking level;
4. the observation timeout, maximum correction rounds, and whether any critical-invariant miss triggers immediate escalation; and
5. the task’s acceptance commands, real-fixture checks, critical invariants, authorized files, network/secret boundaries, and required returned evidence.

The actual cost must include incremental supervisor usage as well as workers, reviewers, and escalations. A cost-only run is `EFFICIENT` only when accepted output costs less than the strong-only baseline. A blended run is `EFFICIENT` only when its precommitted weighted score is lower. Equal or higher cost/score is `NOT EFFICIENT`. Do not launch when the information needed for a binary verdict is missing.

Completion criterion: the supervision contract can identify every model configuration, calculate actual and baseline scores, route every critical miss or exhausted correction budget, and decide one binary verdict without inventing values afterward.

### 3. Pin the source and isolate editing

Inspect Git state and classify tracked, untracked, generated, unrelated, and protected work. Pin one full source commit. An editable worker must receive an isolated branch and worktree or clone derived from that fixed point; a sibling pane is not isolation. Do not silently omit uncommitted source that the task needs. Ask for a checkpoint commit or another explicit immutable snapshot decision before launch, and stop editable delegation if no reproducible source can be prepared.

Keep secrets, production data, and unrelated user work out of the worker checkout unless the supervision contract explicitly requires and authorizes them. Record the isolated path and fixed point in session state, never as a durable Herdr pane id.

Completion criterion: the worker checkout contains exactly the authorized reproducible source, protected material is absent or explicitly authorized, and the caller checkout is not the worker’s editing surface.

### 4. Give the worker one acceptance packet

Send one self-contained packet containing the objective, fixed point, allowed paths, required source/spec reading, critical invariants, ordered behavior expectations, TDD or other required method, focused and repository commands, forbidden operations, and returned-evidence contract. Require a full candidate commit hash, changed-file list, RED/GREEN evidence when applicable, command results, risks, and unresolved questions. Workers do not claim acceptance or integrate their own result.

Prefer economical workers only for mechanically bounded work with a strong oracle. Assign cross-cutting security, provenance, persistence, migration, architecture, or recovery ownership to the preselected strong configuration unless the user deliberately accepts that risk in the supervision contract.

Completion criterion: another agent can implement the packet without conversation history, and every critical invariant has an independent acceptance check or explicit human judgment gate.

### 5. Launch and observe through Herdr

Use the loaded Herdr skill to create only the approved resources, launch the exact worker configuration, confirm readiness, submit the packet, and observe with the recorded timeout. Read current output before waiting for future state. Treat timeout, blocked state, premature idle, missing evidence, or worker questions as prompts to inspect and steer—not as proof of success or failure.

Track launch time, completion time, model configuration, reported usage/cost, correction count, critical misses, and discarded work. Do not persist pane ids as workflow identity.

Completion criterion: the worker reaches an observed terminal state or the recorded escalation condition fires, and the measurement ledger accounts for the attempt.

### 6. Enforce correction and escalation gates

Inspect returned evidence against the packet before choosing a correction. A critical-invariant miss follows the precommitted immediate-escalation policy. Otherwise consolidate all current findings into one correction round; do not drip-feed findings that could have been found together. Stop the worker when its correction budget is exhausted, it edits outside scope, it cannot provide a candidate fixed point, or repeated evidence is unreliable.

Escalation uses the exact preselected configuration. Give the escalator the original packet, pinned candidate or fixed point, complete consolidated findings, and remaining acceptance work. Never choose a model from remembered reputation during the run or silently change the efficiency baseline after seeing results.

Completion criterion: every correction or escalation follows the supervision contract, all attempts remain costed, and no worker continues past its approved budget.

### 7. Verify and integrate independently

Pin the candidate commit. The supervisor independently reads the complete diff, accounts for every changed file, runs focused and repository gates, and exercises every real fixture or human judgment gate in the packet. Worker-authored tests and worker claims are evidence, not acceptance. For high-risk behavior, add an independent reviewer when the supervision contract requires it and include that reviewer’s cost.

Integrate only the exact accepted candidate through a mechanical Git operation, then rerun affected gates in the caller-owned integration checkout. Return semantic conflicts or failed gates through the remaining correction/escalation route; the supervisor does not hide delegated defects with untracked ad hoc edits.

Completion criterion: one exact candidate passes independent acceptance, is integrated mechanically, and passes post-integration checks, or the task stops with preserved evidence and no false success claim.

### 8. Decide efficiency and clean up

Calculate actual supervision cost from incremental supervisor, worker, reviewer, and escalation usage. Calculate actual elapsed time from preflight start through accepted integration, including steering and discarded attempts. Apply the precommitted cost-only or blended formula against the strong-only baseline. Emit exactly one bold verdict: **EFFICIENT** or **NOT EFFICIENT**. State the actual and baseline values, assumptions, estimate source, correction rounds, critical misses, discarded work, accepted model path, and confidence; confidence qualifies the comparison but never replaces the binary verdict.

Report evidence so the human can select future configurations during the next preflight Q&A.

Close only Herdr resources created by this workflow. Preserve or remove branches, worktrees, and clones according to the supervision contract, and report anything left behind. Never commit, push, or delete caller work without explicit authorization.

Completion criterion: acceptance status and cleanup are explicit, every participating model and correction is costed, actual and baseline values are shown, and one binary efficiency verdict is reported.

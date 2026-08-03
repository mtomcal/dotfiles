---
name: herdr-watchdog
description: Monitor context rotation and responsiveness for one bounded Herdr worker, requesting checkpoints and safely terminating a nonresponsive worker without taking over execution authority. Use when an orchestrator sets context thresholds, heartbeat deadlines, or a fail-closed worker termination policy.
metadata:
  short-description: Watch bounded Herdr workers and enforce safe rotation
allowed-tools: read,bash
---

# Herdr Watchdog

## Language Definitions

- **Authority envelope** — caller-supplied worker identity, thresholds, deadlines, evidence route, and pane-close permission that bound one Watchdog run.
- **Protocol record** — worker-emitted heartbeat or checkpoint line in the stable format below.
- **Response window** — one bounded interval in which acknowledgment, a protocol record, or inspectable settled state proves responsiveness.

Repository glossary wording is authoritative for **Watchdog**, **context rotation**, **coordinator lease**, and other shared execution terms.

Monitor one worker on behalf of an owning coordinator. This skill owns liveness observation, checkpoint requests, context-rotation escalation, and authorized pane termination. It does not own the worker's task, Beads, Git integration, scope, acceptance, or coordinator lease.

## Workflow

### 1. Bind the authority envelope

Require `HERDR_ENV=1` and load [`herdr`](../herdr/SKILL.md) before controlling panes. Accept an explicit packet containing:

- coordinator identity and worker agent key or pane ID;
- work-bead/attempt identity, if applicable;
- checkpoint and hard-rotation context thresholds;
- heartbeat/checkpoint acknowledgment deadline;
- evidence destination owned by the coordinator;
- governing write-ahead policy: `required` with a coordinator-owned evidence provider, or `not-applicable` for a workflow with no durable side-effect record; and
- explicit authorization to close this worker's pane when the termination rule is met.

Reject nonpositive deadlines, thresholds outside 1–100, a hard-rotation threshold below the checkpoint threshold, or a packet that asks the Watchdog to edit files, mutate Beads or Git, accept work, start replacement work, transfer a lease, or infer authority from coordinator absence. Completion criterion: one worker and one valid authority envelope are unambiguous.

### 2. Establish a responsive baseline

Use Herdr's agent facade to confirm the target exists and read current output before waiting. Confirm that the worker's initial packet already requires context and checkpoints in this stable form; when write-ahead policy is `required`, also verify the coordinator-owned durable reference:

```text
WATCHDOG heartbeat context=<percent|unknown> state=<working|checkpointing|winding-down|blocked> bead=<id|none> commit=<sha|none>
WATCHDOG checkpoint context=<percent|unknown> bead=<id|none> commit=<sha|none> tests=<summary> remaining=<summary>
```

If the protocol was not sent before launch, return the gap to the coordinator; the Watchdog does not expand the worker contract itself. A terminal's ordinary silence, an agent's working state, or a wait timeout alone does not prove nonresponsiveness. A worker is responsive when it acknowledges a Watchdog request, emits a valid protocol record, or reaches a settled state that can be inspected.

### 3. Enforce context rotation

Observe context only from a native signal or the worker's explicit report; never estimate it from elapsed time or output volume.

- Below the checkpoint threshold: continue bounded observation.
- At or above the checkpoint threshold: report the crossing to the coordinator; when write-ahead is required, wait for its durable reference; then atomically request the checkpoint and handoff evidence and assign no new work.
- At or above the hard-rotation threshold: report the crossing, satisfy the same write-ahead policy, then instruct the worker to stop expanding scope, complete only the checkpoint/wind-down operation, emit the final record, and settle.
- Unknown context: continue heartbeat monitoring and report that threshold enforcement is unavailable; do not fabricate a percentage.

Forward checkpoint evidence to the coordinator. The coordinator alone decides whether the evidence is sufficient and whether to launch a replacement worker.

### 4. Determine nonresponsiveness

After a checkpoint or wind-down request, wait only for the packet's configured deadline. On timeout:

1. read fresh output and current agent state;
2. send one explicit final acknowledgment request with a bounded deadline;
3. inspect again when that deadline expires; and
4. classify the worker as nonresponsive only when no acknowledgment, protocol record, or inspectable settled state appeared across both windows.

Blocked, questioning, or failed workers are responsive if they communicate that state. Report them to the coordinator rather than terminating them as nonresponsive.

### 5. Terminate fail closed

When and only when the worker is classified nonresponsive and pane-close authority was explicit, capture the final observable output and agent/pane identity, then close that worker pane with the current Herdr pane facade:

```bash
herdr pane close "$WORKER_PANE_ID"
```

Do not close the coordinator pane, workspace, tab, or any resource not named in the packet. Termination MUST NOT close or transfer the coordinator lease, mutate attempt state, mark work accepted, or launch a replacement. Durable execution remains blocked pending coordinator reconciliation or a separately authorized human-approved takeover.

If pane-close authority is absent, report the termination recommendation and leave the worker running.

### 6. Return evidence

Return a structured result containing:

- worker and coordinator identities;
- threshold and deadline policy;
- observed heartbeat/checkpoint records;
- final output/state evidence;
- classification (`responsive`, `rotation-requested`, `settled`, `nonresponsive`, or `terminated`);
- whether the pane was closed; and
- an explicit statement that no Beads, Git, scope, acceptance, replacement, or lease action was taken.

Completion criterion: the coordinator can reconcile the worker from evidence, and every action remained inside the bound authority envelope.

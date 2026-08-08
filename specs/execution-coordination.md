# Execution Coordination

> **Version**: 2.0.0
> **Last Updated**: 2026-08-03
> **Depends On**: [Parameters](parameters.md), [Ubiquitous Language](../UBIQUITOUS-LANGUAGE.md), [Tool Provisioning](tool-provisioning.md), [Herdr Config](herdr-config.md)
> **Depended By**: [Skill Library](skill-library.md), [Install Orchestrator](install-orchestrator.md)
> **Prefix**: EXEC

---

## Overview

Execution Coordination owns durable planning, agent assignment, dependency ordering, execution attempts, review policy, evidence, synchronization, and crash recovery for agent-driven engineering work. One private external **command repo** contains the Beads database for every source repository. Source repositories remain free of `.beads/` directories and durable workflow Markdown.

This is a solo-developer workflow. A coordinator remains the only role allowed to change molecule structure, acceptance, integration, and recovery state, but no coordinator lease, takeover ceremony, active authority pointer, or authority-before-mutation gate exists. An optional **coordinator run marker** is a non-authoritative duplicate-process warning only. Permanent historical coordinator-session and decision beads MAY remain as provenance from the retired lease contract.

The system MUST ensure that:

1. `create-engineering-plan` creates one execution-ready Beads molecule directly from a human-approved scope snapshot.
2. `execute-engineering-molecule` uses Herdr for live agent transport while Beads remains the complete durable control and recovery authority.
3. A fresh coordinator can derive the next safe action from compact current-state metadata without conversation or transcript history.
4. Every agent side effect has write-ahead intent, exact model assignment, durable instructions, and durable return evidence.
5. Only integrated work closes a blocking slice, so the Beads ready queue is the authoritative frontier.
6. Worker attempt history, fixed-point verification, Git reconciliation, independent per-slice Test Quality, serialized writes, and synchronization safety remain mandatory.
7. No plan, ledger, slice, verification, active-pointer, recovery-brief, or transcript Markdown file is authoritative.

## Dependencies

### Technology Dependencies

| Dependency | Purpose |
|------------|---------|
| Beads `bd` CLI | Durable issue, dependency, metadata, molecule, embedded-Dolt, and synchronization operations |
| Git | Source identity, fixed points, worktrees, branches, and integration |
| Herdr | Ephemeral agent launch, communication, observation, and steering |
| Supported coding agents | Planning, implementation, review, remediation, and coordination |

### Spec Dependencies

| Spec | Relationship |
|------|--------------|
| [Parameters](parameters.md) | Command-repo paths, installer channels, presets, statuses, and correction limits |
| [Ubiquitous Language](../UBIQUITOUS-LANGUAGE.md) | Canonical coordination artifacts, actors, and lifecycle terms |
| [Tool Provisioning](tool-provisioning.md) | Installs Beads and exposes explicit command-repo bootstrap |
| [Herdr Config](herdr-config.md) | Supplies live transport and non-durable runtime identity rules |

## Parameters

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `BEADS_COMMAND_CONFIG_PATH` | `~/.config/beads-command/env` | Machine-local bootstrap may select a different command-repo checkout per host |
| `BEADS_COMMAND_ENV` | `BEADS_DIR` | Native Beads discovery routes all commands to the external command repo |
| `BEADS_STORAGE_MODE` | embedded | Dolt runs in-process inside `bd`; no server process exists |
| `BEADS_WRITER_CONCURRENCY` | one at a time | Durable writes serialize through the embedded single writer |
| `BEADS_SYNC_POLICY` | semantic checkpoints | Bounds recovery loss without committing every liveness action |
| `ORDINARY_COORDINATOR_STARTUP_BUDGET` | less than 20 KB | Prevents broad specification, notes, and frontier reads before ordinary recovery |
| `RECOVERY_PROJECTION_MAX_BYTES` | 1024 serialized bytes per active record | Keeps current state cheap to inspect while notes retain audit history |
| `SLICE_CORRECTION_DEFAULT` | 2 | Preserves a bounded correction loop with approved per-slice overrides |
| `REVIEW_PRESETS` | Lean, Standard, High assurance | Provides concise creation-time review selection with explicit overrides |
| `ATTEMPT_RETENTION` | permanent, compactable | Active recovery requires distinct attempts; completed history may later compact |
| `ATTEMPT_PROGRESS_POLICY` | semantic transitions only | Herdr owns live progress; Beads stores recovery-relevant state |

## Data Structures

### Command Repo

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| local path | absolute path | Selected by explicit bootstrap | Checkout containing the authoritative `.beads/` directory |
| private remote | URL | Required; credentials excluded | Remote used for command-repo Git and Dolt synchronization |
| runtime config | local file | Unversioned; contains resolved Beads path | Source for global `BEADS_DIR` export |
| storage mode | enum | `embedded` | Single-writer in-process Dolt |
| credentials | local secret state | Never tracked or logged | Authentication for private remote operations |

### Repository Identity

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| repository key | string | Stable and required | Normalized canonical Git remote identity or explicit remote-less key |
| normalized remote | string | Optional only for remote-less repositories | Equivalent remote spellings normalize to one identity |
| runtime checkout | absolute path | Replaceable and non-authoritative | Checkout currently bound to the repository key |
| source fixed point | full Git commit | Required | Reproducible implementation baseline |

### Scope Snapshot

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| objective | text | Human-approved; required | Desired outcome |
| acceptance criteria | ordered list | Human-approved; non-empty | Observable success conditions |
| failure criteria | ordered list | Human-approved; non-empty | Incorrect-behavior boundaries |
| exclusions | list | Human-approved; may be `none` | Adjacent work not authorized |
| approval evidence | event reference | Required | Human confirmation freezing the snapshot |

Any later scope mutation requires a linked decision bead and explicit human approval.

### Execution Molecule

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| root | Beads epic/molecule | One per approved scope | Parent coordination record |
| repository identity | record | Required | Source repository and fixed point |
| scope snapshot | record | Frozen after creation | Implementation authority |
| planner provenance | exact model assignment | Required | Configuration that created the graph |
| coordinator assignment | exact model assignment | Required | Expected configuration for coordination; mismatch warns and stops until reconciled |
| review policy | record | Approved before activation | Required final review breadth and depth |
| worker lifecycle policy | record | Approved before activation | Coordinator-owned context checkpoint and hard-rotation thresholds |
| activation gate | work bead id | Blocks initial implementation frontiers | Planner-owned validation barrier |
| work beads | graph | Acyclic blocking edges | Slices, reviews, remediation, and decisions |
| attempt graph | graph | Non-blocking operational edges | Agent attempts and retained provenance |
| recovery projection | record | Required while active; at most 1024 serialized bytes | Canonical current-state cache |
| coordinator run marker | record | Optional; non-authoritative | Local duplicate-process warning and provenance hint |
| sync state | enum | clean, pending, blocked | Durability relative to the private remote |
| status | enum | draft, ready, executing, blocked, complete | Molecule lifecycle |

### Current-State Recovery Projection

Each active root, work bead, and attempt MUST carry one compact `recovery` metadata object. It is the canonical current-state cache; detailed notes remain immutable audit history and MUST NOT be ordinary startup input.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| state | enum or concise string | Required | Current lifecycle state |
| next action | concise string | Required | One safe next transition |
| branch | string | Required when editable Git state exists | Current branch |
| worktree | absolute path | Required when editable Git state exists | Current checkout |
| base fixed point | full Git commit | Required when applicable | Baseline for the current candidate |
| candidate fixed point | full Git commit | Required after implementation evidence returns | Candidate awaiting verification or integration |
| integration fixed point | full Git commit | Required when an integration branch exists | Last verified integrated state |
| attempt | record | Required | Active/latest attempt id, state, and resumable boolean, or explicit `none` |
| correction count | non-negative integer | Required | Corrections consumed for the record's current work |
| review | record | Required | Latest verdict and finding count, or explicit pending/not-applicable values |
| evidence complete | boolean | Required | Whether evidence required for the recorded transition is present |
| sync state | enum | Required on the root | clean, pending, or blocked |

The serialized object MUST be at most 1024 bytes. A transition that changes any projected fact MUST update the projection in the same semantic checkpoint. Notes MAY explain history but MUST NOT override a projection silently. A missing, stale, oversized, or contradictory projection selects detailed recovery inspection.

### Coordinator Run Marker

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| run token | string | Optional and never an authority token | Correlates one local coordinator run |
| model | exact model summary | Optional | Runtime provenance |
| host | string | Optional | Duplicate-process inspection hint |
| started at | timestamp | Optional | Observation aid |

A marker does not grant authority, block mutation, expire, transfer, or require takeover. A stale marker is replaced after Beads and Git reconciliation. A verifiably live duplicate coordinator process triggers a local warning and stop before overlapping side effects; resolving that local duplicate does not create a decision bead.

### Work Bead

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| kind | enum | slice, review, remediation, decision, mechanical gate | Work role |
| behavior | text | One vertical or review outcome | Authorized result |
| dependencies | list of bead ids | Acyclic; genuine blockers only | Determines readiness |
| acceptance and failure | record | Required | Verifiable boundaries |
| public test seam | text | Required for editable slices | Refactor-resilient behavior seam |
| tracer cycles | ordered list | Required for editable slices | RED, GREEN, and optional REFACTOR instructions |
| proposed execution traces | list | Required where order is material | Intended order and allowed variance |
| model assignment | exact configuration | Required for agent work | Runtime binding |
| escalation policy | record | Required for editable work | Approved ladder and triggers |
| worker lifecycle policy | record | Required for editable work | Context checkpoint and hard-rotation thresholds |
| recovery projection | record | Required while active | Compact current state |
| state | enum | open, in_progress, awaiting_review, needs_correction, integrating, closed, blocked | Work lifecycle |

### Review Policy

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| preset | enum | Lean, Standard, High assurance | Creation-time baseline |
| gates | list | Explicit after overrides | Required acceptance conditions |
| depth | map | Reviewer count per gate | Independent pass count |
| independence | map | Fresh context; model/provider rules explicit | Separation per pass |
| approval evidence | decision/event reference | Required | Human-approved topology |

| Preset | Required final gates | Depth |
|--------|----------------------|-------|
| Lean | Repository mechanical gates; Scope fidelity | One independent Scope pass |
| Standard | Lean; integrated Test Quality; Standards; Premortem; Security | One independent pass per non-mechanical gate |
| High assurance | Standard; risk-triggered gates | Standard depth plus approved second passes |

Independent per-slice Test Quality is mandatory before integration under every preset. Post-creation gate additions, removals, or depth changes require explicit approval and a linked decision bead.

### Exact Model Assignment

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| command | string | Required | Agent launch command |
| provider | string | Required | Runtime provider |
| model id | string | Exact and required | Provider model identifier |
| thinking level | string | Exact and required | Runtime reasoning configuration |
| role | enum | planner, coordinator, implementation, review axis, remediation | Assignment purpose |
| independence rule | record | Required for reviewers | Fresh context plus diversity requirement |

An unavailable initial assignment blocks until human-approved reassignment. Runtime reputation never substitutes for an exact assignment.

### Escalation Policy

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| ladder | ordered list | Human-approved exact assignments | Permitted automatic escalation order |
| correction allowance | non-negative integer | Materialized per slice | Corrections allowed before escalation |
| critical-invariant trigger | boolean | Materialized per slice | Whether a critical miss escalates immediately |
| current rung | integer | Attempt-derived | Last assignment used |

### Worker Lifecycle Policy

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| checkpoint threshold | percentage | Human-approved; 1–99 | Worker checkpoints and receives no new work |
| hard-rotation threshold | percentage | At least checkpoint threshold; at most 100 | Worker winds down for recreation |

Context MUST come from a native runtime signal or explicit worker report, never elapsed-time or output-volume estimation. The coordinator persists each checkpoint or wind-down instruction before sending it. No independent liveness monitor or worker-pane-termination authority exists.

### Worker Attempt

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| attempt id | Beads id | Unique and never reused | Durable launch identity and Herdr correlation token |
| owner | work bead id | Required | Slice, review, or remediation attempted |
| relation | enum | tracks, validates | Non-blocking operational edge |
| exact model | exact model assignment | Required | Actual runtime binding |
| durable instructions | ordered list | Write-ahead | Consequential messages |
| state | enum | planned, launched, submitted, working, evidence_returned, verified, rejected, cancelled, lost | Semantic progress |
| evidence | record | Required before successful completion | Fixed point, commands, results, findings, risks, outcome |
| recovery projection | record | Required while active | Compact current state |

Attempts are permanent and auditable but MAY compact after molecule completion. They never enter the executable frontier.

## Behavior

### Command-Repo Bootstrap and Routing

The explicit idempotent bootstrap MUST verify or create the external command repo, initialize embedded Beads outside source repositories, configure the private Dolt remote, write machine-local routing, synchronize recorded remote configuration through ordinary Git, and verify pull/checkpoint/push behavior. Credentials MUST remain local and absent from tracked files and output.

Issue data travels over the Dolt remote while remote configuration travels through ordinary Git. Shell startup exports `BEADS_DIR` when valid; coordination stops with bootstrap guidance when it is absent or invalid.

### Molecule Creation

`create-engineering-plan` MUST resolve repository identity and a full source fixed point; record planner provenance; inspect relevant evidence; obtain human approval of scope, review, assignments, escalation, correction, and worker lifecycle policy; create context-sized vertical TDD slices; probe installed Beads graph support; atomically materialize the complete graph behind an activation gate; read back nodes, metadata, edges, assignments, traces, and readiness; and activate only after exact validation. Unknown or dropped fields are failures.

Creation MUST initialize a compliant root recovery projection and one local semantic checkpoint. It MUST NOT create durable workflow Markdown or source-repository `.beads/` state. A remote push occurs only when configured and authorized.

### Single-Writer Durable Storage

Every durable write MUST be short and serialized. Writer contention is retryable and never skippable. Live agent work MAY overlap, but no agent holds the writer position while implementing or reviewing. Parallel fan-out MUST remain bounded.

### Summary-First Coordinator Startup

Ordinary coordinator startup MUST consume less than 20 KB before resuming active work. The startup path loads only the compact `beads` and `execute-engineering-molecule` skill bodies plus filtered Beads summaries. It MUST NOT load this complete specification, all notes, all attempts, unfiltered frontier output, transcripts, or irrelevant lifecycle branches.

Startup proceeds as follows:

```
VERIFY runtime, routing, exact molecule id, and exact coordinator assignment
PULL issue state when permitted
READ root status, labels, recovery projection, and sync state only
READ active child ids, statuses, labels, and recovery projections only
READ the frontier as compact ids and titles
RECONCILE projected Git paths and fixed points
IF every projection is present, within size, internally consistent, evidence-complete for its state, and matches Git
    RESUME the recorded next action
ELSE
    EXPAND only the active or contradictory records, then repair their projections
END IF
WARN and stop before overlapping side effects only when a live duplicate local coordinator process is actually verified
```

A stale run marker alone never blocks startup. Detailed notes are audit history, not startup input. No helper command, script, skill, generated recovery brief, or durable summary artifact is required.

### Work Ownership and Frontier

The coordinator role mutates graph structure, dependencies, scope, acceptance, integration state, close/reopen state, review policy, and unapproved assignment changes. Workers atomically claim assigned ready slices and append attempt evidence. Reviewers append findings to their assigned attempts.

A blocking slice closes only after implementation evidence at a full commit, independent per-slice Test Quality at that fixed point, focused mechanical checks, mechanical integration, and post-integration checks. Only closed blockers release dependent work into the frontier.

### Write-Ahead Herdr Attempts

Every consequential agent side effect MUST follow write-ahead ordering:

```
CREATE a unique planned attempt
PERSIST its consequential instruction and checkpoint
THEN launch or message through Herdr with the attempt token
OBSERVE the result
RECORD the next semantic state and refresh recovery metadata
```

Consequential instructions include initial packets, scope clarification, consolidated correction, escalation handoff, and evidence requests. Liveness probes, keypress mechanics, public Herdr IDs, pane output, and transcripts remain ephemeral.

### Worker Completion Evidence

Before transport-level completion, workers and reviewers MUST record exact model, full candidate or reviewed fixed point, changed files where applicable, commands and results, acceptance/failure evidence, findings or `none`, risks, and outcome. Missing durable evidence leaves the attempt nonterminal and prevents verification or integration.

### Context Rotation

At the checkpoint threshold the coordinator persists a consequential checkpoint instruction before sending it; the editable worker preserves durable Git state and test/handoff evidence and receives no new work. At the hard threshold the coordinator likewise writes ahead the wind-down instruction; the worker settles and verified remaining work resumes under a new attempt in fresh context.

Unknown context is recorded as unavailable rather than estimated. No independent liveness monitor, heartbeat protocol, or worker-pane-termination authority exists. Historical Watchdog records remain auditable but authorize no current behavior.

### Correction and Escalation

A failed review or mechanical gate creates one consolidated correction instruction on a distinct attempt. Correction allowance and critical-invariant behavior remain fixed per slice unless an approved decision changes them. Escalation selects only the next available exact assignment on the approved ladder; exhaustion blocks the work bead.

### Integration, Final Reviews, and Remediation

The coordinator MAY run mechanical Git and test commands but MUST NOT implement or independently review. Editable work uses isolated branches and worktrees. Integration is mechanical; semantic conflicts return to the implementer through a new write-ahead attempt.

After implementation slices close, final reviews run against one held integrated fixed point according to the approved policy. Reviewers use fresh contexts and report findings without editing. Consolidated remediation uses the exact remediation assignment. Repository gates and affected reviews rerun after remediation; unaffected passing reviews retain explicit non-rerun rationale.

### Synchronization

A local Beads write and local Dolt commit do not imply remote durability. Correlated writes form semantic checkpoints at molecule activation, work claim/attempt launch, verified integration/closure, approved decisions, review/remediation routing, and completion.

Only the coordinator process performs a push, and only at an authorized recovery boundary. Push failure leaves local state durable and sets `sync:pending`. Work MAY continue locally after reconciliation, but final completion remains blocked until synchronization succeeds. A fresh coordinator reconciles pull results, local checkpoints, and Git before continuing; no lease or takeover decision is involved.

### Crash Recovery and Herdr Loss

A fresh coordinator starts from recovery projections and Git, not conversation or Herdr history. Only active, missing, stale, oversized, evidence-incomplete, or contradictory records are expanded. For each nonterminal attempt, search live transport by durable token; resume a certain match; otherwise mark it lost after Git/evidence reconciliation and create a new id if work remains. Never reuse uncertain attempt identity or persist pane ids.

Historical coordinator-session, lease, rotation, decision, Watchdog, and attempt beads MUST remain. Migration removes obsolete authoritative fields from current metadata without rewriting historical notes or pretending past events did not occur.

### Completion and Retention

Close a molecule only when scope acceptance, all configured review gates, Git integration evidence, and private-remote synchronization pass. Never automatically merge into an unapproved target or delete source branches, worktrees, molecule records, attempts, or decisions. Closed attempts MAY compact through supported Beads operations after completion.

### Legacy Transition

No filesystem plan, ledger, slice packet, verification file, repository-local `.plan`, generated recovery brief, or source-repository `.beads/` state may be created. Legacy cleanup remains a separate explicit operation that archives untracked research before deleting approved legacy locations; normal installation never performs destructive cleanup.

## Error Handling

| Error | Trigger | Response | Recovery |
|-------|---------|----------|----------|
| Missing command repo | `BEADS_DIR` absent or invalid | Stop; never initialize source repo | Run explicit bootstrap |
| Repository identity ambiguity | Identity cannot normalize | Stop creation | Supply explicit key or resolve remote |
| Unapproved scope | Scope lacks confirmation | Keep draft | Obtain approval |
| Partial molecule | Creation/readback mismatch | Keep activation gate open | Reconcile or discard draft explicitly |
| Model unavailable or mismatched | Exact assignment cannot run | Stop; do not substitute | Approve reassignment |
| Escalation exhausted | No higher rung | Block owning work | Approve policy change or decision |
| Verified duplicate coordinator | Another local process is performing side effects | Warn and stop overlapping side effects | Resolve the local duplicate; then reconcile Beads/Git |
| Stale run marker | Marker has no verified live process | Do not treat as authority | Replace after reconciliation |
| Herdr unavailable | Live agent action required | Preserve graph and block transport | Start Herdr and resume from Beads |
| Uncertain launch | Observation lost after write-ahead | Reconcile by token; never duplicate id | Resume or mark lost and create new id |
| Missing evidence | Completion notification lacks durable evidence | Do not verify or integrate | Request evidence or reject attempt |
| Missing/stale recovery projection | Projection absent, oversized, or contradicts notes/Git | Expand only target record; do not trust cache | Reconcile and rewrite projection |
| Writer contention | Embedded writer busy | Retry; never skip | Reduce fan-out if persistent |
| Remote outage | Pull/push fails | Record `sync:pending`; block completion | Reconcile and synchronize later |
| Dependency cycle | Graph validation finds cycle | Keep blocked | Correct graph before activation |
| Review-policy drift | Topology changes without approval | Reject transition | Record approved decision |
| Retired Watchdog activity | A live Watchdog attempt/resource appears after unshipping | Stop and remove the live resource without deleting history | Reconcile current metadata; preserve historical beads and notes |
| Legacy cleanup archive failure | Research archive cannot verify | Delete nothing | Correct archive and rerun explicit cleanup |

## Implementation Notes

1. Beads metadata SHOULD use a project-owned namespace and avoid reserved prefixes.
2. Attempt state changes SHOULD use durable history plus queryable labels and recovery projections as current-state caches.
3. Operational attempt links MUST be non-blocking.
4. Every fixed point uses a full commit hash.
5. Recovery projections SHOULD use concise keys while remaining self-describing and MUST be measured after serialization.
6. Projection writes MUST be read back after mutation; notes remain append-only audit history.
7. Planner and execution behavior belongs to shared skills; command-repo mutable state does not belong in dotfiles.
8. Runtime configuration and credentials remain local even though command-repo history is privately synchronized.
9. Existing historical lease, coordinator-session, rotation, and Watchdog records are provenance, not current authority.

## Test Scenarios

### TS-EXEC-001: External Command-Repo Routing
Category: Integration
Priority: Critical
Preconditions: Bootstrap configured a private command repo.
Input: Run Beads from unrelated source repositories.
Expected Output: Both use the external database; neither gains `.beads/` state.

### TS-EXEC-002: Atomic Molecule Creation
Category: End-to-End
Priority: Critical
Preconditions: Approved engineering scope and installed Beads exist.
Input: Materialize and validate the graph.
Expected Output: One activation gate blocks all implementation work until exact readback passes; no workflow Markdown is created.

### TS-EXEC-003: Integrated Closure Controls Frontier
Category: Integration
Priority: Critical
Preconditions: Slice B depends on Slice A.
Input: Query readiness before and after verified integration of A.
Expected Output: B appears only after A closes with integration evidence.

### TS-EXEC-004: Write-Ahead Launch Recovery
Category: End-to-End
Priority: Critical
Preconditions: A planned attempt is checkpointed and launch observation is lost.
Input: Start a fresh coordinator.
Expected Output: It resumes a token match or marks the attempt lost and creates a new id; no duplicate launch reuses the id.

### TS-EXEC-005: Summary-First Recovery Budget
Category: Integration
Priority: Critical
Preconditions: An active molecule has compliant recovery projections.
Input: Start ordinary coordination and measure loaded skill prose plus filtered Beads output before resume.
Expected Output: Startup reads less than 20 KB, does not load this full spec or notes, reconciles Git fixed points, and resumes the projected next action.

### TS-EXEC-006: Selective Recovery Expansion
Category: Integration
Priority: Critical
Preconditions: One active projection contradicts Git while all others are valid.
Input: Start recovery.
Expected Output: Only the contradictory record and necessary evidence expand; its projection is repaired without scanning unrelated notes or attempts.

### TS-EXEC-007: Recovery Projection Completeness
Category: Unit
Priority: High
Preconditions: Active root, slice, and attempt records exist.
Input: Validate each serialized projection.
Expected Output: Each is at most 1024 bytes and records state, next action, applicable Git paths/fixed points, attempt resumability, correction count, review result/count, and evidence completeness.

### TS-EXEC-008: Coordinator Run Marker Is Non-Authoritative
Category: End-to-End
Priority: Critical
Preconditions: A stale marker and historical nonterminal coordinator-session bead exist but no duplicate process is live.
Input: Start a fresh coordinator after Beads/Git reconciliation.
Expected Output: No takeover approval or decision bead is required; the stale marker does not block mutation and historical records remain.

### TS-EXEC-009: Live Duplicate Warning
Category: Integration
Priority: High
Preconditions: Two local coordinator processes are verifiably live.
Input: The second process reaches its first side effect.
Expected Output: It warns and stops overlapping side effects without creating a lease or authority transfer record.

### TS-EXEC-010: Worker Evidence Before Notification
Category: Integration
Priority: Critical
Preconditions: Worker finishes a slice.
Input: Notify before and after durable evidence.
Expected Output: Only complete fixed-point evidence permits verification.

### TS-EXEC-011: Exact Assignment and Escalation
Category: Integration
Priority: High
Preconditions: Exact assignments and ladder exist.
Input: Exercise initial unavailability, correction exhaustion, and critical miss.
Expected Output: Initial unavailability blocks; triggers select only the next approved rung.

### TS-EXEC-012: Review Presets and Per-Slice Test Quality
Category: Integration
Priority: Critical
Preconditions: Each preset is selectable.
Input: Execute one slice and final review topology per preset.
Expected Output: Every slice receives independent Test Quality; final gates match the approved preset and overrides.

### TS-EXEC-013: Attempt Graph Does Not Pollute Frontier
Category: Unit
Priority: High
Preconditions: Multiple attempts track one slice.
Input: Query ready work.
Expected Output: Attempts are absent; only work dependencies determine readiness.

### TS-EXEC-014: Durable Writes Serialize
Category: Integration
Priority: Critical
Preconditions: Two writes contend.
Input: Submit both writes.
Expected Output: Both eventually land; contention is retried rather than skipped.

### TS-EXEC-015: Coordinator-Owned Context Rotation
Category: End-to-End
Priority: Critical
Preconditions: An editable worker has approved checkpoint and hard-rotation thresholds.
Input: Cross both thresholds, then exercise unknown context and worker nonresponse.
Expected Output: Write-ahead checkpoint/wind-down instructions preserve evidence and recreate remaining work under a new attempt; unknown context is not estimated; no independent liveness monitor or pane termination is launched.

### TS-EXEC-016: Semantic Checkpoint Batching
Category: Integration
Priority: High
Preconditions: One transition needs correlated writes.
Input: Materialize and inspect local/remote durability.
Expected Output: One local checkpoint records the transition; push occurs at most once when authorized; pending state remains explicit otherwise.

### TS-EXEC-017: Current-Metadata Migration Preserves History
Category: Integration
Priority: Critical
Preconditions: An active molecule contains historical lease, rotation, coordinator-session, decision, Watchdog, and attempt records.
Input: Migrate current metadata to recovery projections.
Expected Output: Authoritative lease/rotation pointers disappear, projections match Beads/Git truth, historical records and notes remain, the Watchdog-removal decision stays in force with no live resource, and unsynchronized local writes set `sync:pending`.

### TS-EXEC-018: Explicit Legacy Cleanup
Category: Integration
Priority: Critical
Preconditions: Legacy data and untracked research exist.
Input: Run normal install, then explicit cleanup with valid archive destination.
Expected Output: Normal install deletes nothing; explicit cleanup verifies the archive before approved deletion.

## Changelog

| Version | Date | Change |
|---------|------|--------|
| 2.0.0 | 2026-08-03 | Replaced distributed coordinator leases and takeover ceremony with solo coordination, a non-authoritative run marker, summary-first recovery under 20 KB, and compact current-state recovery projections; unshipped Watchdog while retaining coordinator-owned context rotation and historical audit records. |
| 1.4.0 | 2026-08-03 | Added version-aware atomic graph ingestion with an activation gate, explicit worker context rotation and bounded Watchdog termination, fail-closed lease handling, and local-versus-remote semantic checkpoint rules. |
| 1.3.0 | 2026-08-02 | Renamed the planning and execution entries to `create-engineering-plan` and `execute-engineering-molecule`, scoping both to engineering work. |
| 1.2.0 | 2026-08-02 | Removed the filesystem ledger contract after migration. |
| 1.1.0 | 2026-08-02 | Adopted single-writer embedded storage and two-half synchronization. |
| 1.0.0 | 2026-08-01 | Established command-repo execution molecules, exact assignments, attempts, review policy, synchronization, and recovery. |

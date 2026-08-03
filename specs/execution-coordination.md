# Execution Coordination

> **Version**: 1.4.0
> **Last Updated**: 2026-08-03
> **Depends On**: [Parameters](parameters.md), [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md), [Tool Provisioning](tool-provisioning.md), [Herdr Config](herdr-config.md)
> **Depended By**: [Skill Library](skill-library.md), [Install Orchestrator](install-orchestrator.md)
> **Prefix**: EXEC

---

## Overview

Execution Coordination owns durable planning, agent assignment, dependency ordering, execution attempts, review policy, evidence, synchronization, and crash recovery for agent-driven implementation work. One private external **command repo** contains the Beads database for every source repository. Source repositories remain free of `.beads/` directories and durable workflow Markdown.

The approved behavior in this specification is desired. The `beads`, `create-engineering-plan`, and `execute-engineering-molecule` shared skills encode this contract, but no molecule has yet been created or executed against it, so the runtime behavior remains unproven. All work MUST use an **execution molecule**; no legacy filesystem ledger remains.

The system MUST ensure that:

1. `create-engineering-plan` creates one execution-ready Beads molecule directly from a human-approved scope snapshot.
2. `execute-engineering-molecule` uses Herdr for live agent transport while Beads remains the complete durable control and recovery authority.
3. A coordinator may be killed after any durable transition and a fresh coordinator can derive the next safe action from Beads.
4. Every agent side effect has write-ahead intent, exact model assignment, durable instructions, and durable return evidence.
5. Only integrated work closes a blocking slice, so the Beads ready queue is the authoritative frontier.
6. No plan, ledger, slice, verification, active-pointer, or transcript Markdown file is authoritative.

---

## Dependencies

### Technology Dependencies

| Dependency              | Purpose                                                                                                                                |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| Beads `bd` CLI          | Durable issue, dependency, event, and molecule operations, plus embedded single-writer Dolt storage and private-remote synchronization |
| Git                     | Source identity, fixed points, worktrees, branches, and integration                                                                    |
| Herdr                   | Ephemeral agent launch, communication, observation, and steering                                                                       |
| Supported coding agents | Planning, implementation, review, remediation, and coordination                                                                        |

### Spec Dependencies

| Spec                                          | Relationship                                                                     |
| --------------------------------------------- | -------------------------------------------------------------------------------- |
| [Parameters](parameters.md)                   | Command-repo paths, installer channels, presets, statuses, and correction limits |
| [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md) | Canonical coordination artifacts, actors, and lifecycle terms                    |
| [Tool Provisioning](tool-provisioning.md)     | Installs Beads and exposes explicit command-repo bootstrap                       |
| [Herdr Config](herdr-config.md)               | Supplies live transport and non-durable session identity rules                   |

---

## Parameters

| Parameter                   | Value                          | Rationale                                                                                                          |
| --------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| `BEADS_COMMAND_CONFIG_PATH` | `~/.config/beads-command/env`  | Machine-local bootstrap result can select a different command-repo checkout on each host                           |
| `BEADS_COMMAND_ENV`         | `BEADS_DIR`                    | Native Beads discovery override routes all commands to the external command repo                                   |
| `BEADS_STORAGE_MODE`        | embedded                       | Dolt runs in-process inside `bd`; one command repo serves every source repository without a server process         |
| `BEADS_WRITER_CONCURRENCY`  | one at a time                  | Embedded storage is single-writer, so durable writes serialize rather than overlap                                 |
| `BEADS_SYNC_POLICY`         | semantic checkpoints           | Bounds recovery loss without committing every liveness action                                                      |
| `COORDINATOR_LEASE_EXPIRY`  | none                           | Long reviews and blocked workers make time-based takeover unsafe                                                   |
| `SLICE_CORRECTION_DEFAULT`  | 2                              | Preserves a bounded correction loop while allowing approved per-slice overrides                                    |
| `REVIEW_PRESETS`            | Lean, Standard, High assurance | Provides concise creation-time review selection with explicit overrides                                            |
| `ATTEMPT_RETENTION`         | permanent, compactable         | Active recovery requires distinct durable attempts; completed history may later decay through supported compaction |
| `ATTEMPT_PROGRESS_POLICY`   | semantic transitions only      | Herdr owns live progress; Beads stores only recovery-relevant state                                                |

---

## Data Structures

### Command Repo

| Field          | Type               | Constraints                                                                      | Description                                                               |
| -------------- | ------------------ | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| local path     | absolute path      | Selected by explicit bootstrap                                                   | Checkout containing the authoritative `.beads/` directory                 |
| private remote | URL                | Required; credentials excluded; `git+ssh://` against a private GitHub repository | Remote used for command-repo Git and Dolt synchronization                 |
| runtime config | local file         | Unversioned; contains resolved Beads path                                        | Source for global `BEADS_DIR` export                                      |
| storage mode   | enum               | `embedded`                                                                       | Single-writer in-process Dolt; no server process or separate Dolt install |
| credentials    | local secret state | Never tracked or logged                                                          | Authentication for private remote operations                              |

### Repository Identity

| Field              | Type            | Constraints                                | Description                                                                           |
| ------------------ | --------------- | ------------------------------------------ | ------------------------------------------------------------------------------------- |
| repository key     | string          | Stable and required                        | Normalized canonical Git remote identity or explicit key for a remote-less repository |
| normalized remote  | string          | Optional only for remote-less repositories | SSH and HTTPS spellings of the same remote normalize to one identity                  |
| runtime checkout   | absolute path   | Replaceable and non-authoritative          | Checkout currently bound to the repository key                                        |
| source fixed point | full Git commit | Required                                   | Reproducible implementation baseline pinned at molecule creation                      |

### Scope Snapshot

| Field               | Type            | Constraints                   | Description                                    |
| ------------------- | --------------- | ----------------------------- | ---------------------------------------------- |
| objective           | text            | Human-approved; required      | Desired outcome                                |
| acceptance criteria | ordered list    | Human-approved; non-empty     | Observable success conditions                  |
| failure criteria    | ordered list    | Human-approved; non-empty     | Boundaries that distinguish incorrect behavior |
| exclusions          | list            | Human-approved; may be `none` | Adjacent work not authorized                   |
| approval evidence   | event reference | Required                      | Human confirmation that freezes the snapshot   |

A scope snapshot does not require a specification diff. Any later scope mutation requires a linked decision bead and explicit human approval.

### Execution Molecule

| Field                  | Type                   | Constraints                                | Description                                            |
| ---------------------- | ---------------------- | ------------------------------------------ | ------------------------------------------------------ |
| root                   | Beads epic/molecule    | One per approved scope                     | Parent coordination record                             |
| repository identity    | record                 | Required                                   | Source repository and fixed point                      |
| scope snapshot         | record                 | Frozen after creation                      | Implementation authority                               |
| planner provenance     | exact model assignment | Required                                   | Configuration that created the graph                   |
| coordinator assignment | exact model assignment | Required                                   | Configuration allowed to acquire the coordinator lease |
| review policy          | record                 | Approved before activation                 | Required final review breadth and depth                |
| worker lifecycle policy | record                | Approved before activation                 | Context thresholds, deadlines, and watchdog authority  |
| activation gate        | work bead id           | Blocks all initial implementation frontiers | Planner-owned validation barrier                      |
| work beads             | graph                  | Acyclic blocking edges                     | Slices, reviews, remediation, and decisions            |
| attempt graph          | graph                  | Non-blocking operational edges             | Coordinator sessions and agent attempts                |
| sync state             | enum                   | clean, pending, blocked                    | Durability relative to the private remote              |
| status                 | enum                   | draft, ready, executing, blocked, complete | Molecule lifecycle                                     |

### Work Bead

| Field                     | Type                | Constraints                                                                        | Description                                           |
| ------------------------- | ------------------- | ---------------------------------------------------------------------------------- | ----------------------------------------------------- |
| kind                      | enum                | slice, review, remediation, decision, mechanical gate                              | Work role                                             |
| behavior                  | text                | One vertical or review outcome                                                     | Authorized result                                     |
| dependencies              | list of bead ids    | Acyclic; genuine blockers only                                                     | Determines readiness                                  |
| acceptance and failure    | record              | Required                                                                           | Machine- or human-verifiable boundaries               |
| public test seam          | text                | Required for editable slices                                                       | Refactor-resilient behavior seam                      |
| tracer cycles             | ordered list        | Required for editable slices                                                       | RED, GREEN, and optional REFACTOR instructions        |
| proposed execution traces | list                | Required where runtime or operational order is material                            | Evidence-grounded intended order and allowed variance |
| model assignment          | exact configuration | Required for agent-executed work                                                   | Runtime binding                                       |
| escalation policy         | record              | Required for editable work                                                         | Approved ladder and triggers                          |
| worker lifecycle policy   | record              | Required for editable work                                                         | Context rotation and watchdog envelope                |
| state                     | enum                | open, in_progress, awaiting_review, needs_correction, integrating, closed, blocked | Work lifecycle                                        |

### Review Policy

| Field             | Type                     | Constraints                                         | Description                       |
| ----------------- | ------------------------ | --------------------------------------------------- | --------------------------------- |
| preset            | enum                     | Lean, Standard, High assurance                      | Creation-time baseline            |
| gates             | list                     | Explicit after overrides                            | Required acceptance conditions    |
| depth             | map                      | Reviewer count per gate                             | Number of independent passes      |
| independence      | map                      | Fresh context always; model/provider rules explicit | Separation required for each pass |
| approval evidence | decision/event reference | Required                                            | Human-approved review topology    |

| Preset         | Required final gates                                          | Depth                                                                                  |
| -------------- | ------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Lean           | Repository mechanical gates; Scope fidelity                   | One independent Scope pass                                                             |
| Standard       | Lean; integrated Test Quality; Standards; Premortem; Security | One independent pass per non-mechanical gate                                           |
| High assurance | Standard; risk-triggered gates                                | Standard depth plus approved second independent passes for selected risk-bearing gates |

Independent per-slice Test Quality is mandatory before integration under every preset. Post-creation additions, removals, or depth changes require explicit approval and a linked decision bead.

### Exact Model Assignment

| Field             | Type   | Constraints                                                    | Description                                                 |
| ----------------- | ------ | -------------------------------------------------------------- | ----------------------------------------------------------- |
| command           | string | Required                                                       | Agent launch command                                        |
| provider          | string | Required                                                       | Runtime provider identity                                   |
| model id          | string | Exact and required                                             | Provider model identifier                                   |
| thinking level    | string | Exact and required                                             | Runtime reasoning configuration                             |
| role              | enum   | planner, coordinator, implementation, review axis, remediation | Assignment purpose                                          |
| independence rule | record | Required for reviewers                                         | Fresh context plus any model/provider diversity requirement |

Role defaults are approved for implementation, Test Quality, Standards/Scope, Premortem/Security, and remediation. Per-bead overrides MAY replace a default, but the resolved exact assignment MUST be materialized onto every executable bead. An unavailable initial assignment blocks until a human approves reassignment.

### Escalation Policy

| Field                      | Type                                    | Constraints                | Description                                   |
| -------------------------- | --------------------------------------- | -------------------------- | --------------------------------------------- |
| ladder                     | ordered list of exact model assignments | Human-approved at creation | Permitted automatic escalation order          |
| correction allowance       | non-negative integer                    | Materialized per slice     | Corrections allowed before escalation         |
| critical-invariant trigger | boolean                                 | Materialized per slice     | Whether a critical miss escalates immediately |
| current rung               | integer                                 | Attempt-derived            | Last assignment used                          |

Automatic escalation may select only the next available higher approved rung. If no higher rung is available, the work bead becomes blocked. Runtime reputation or an unapproved model MUST NOT determine escalation.

### Worker Lifecycle Policy

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| checkpoint threshold | percentage | Human-approved; 1–99 | Point at which the worker checkpoints and receives no new work |
| hard-rotation threshold | percentage | Greater than or equal to checkpoint threshold; at most 100 | Point at which the worker winds down for recreation |
| acknowledgment deadline | duration | Positive; human-approved | Bound for each Watchdog response window |
| termination authority | boolean | Explicit | Whether the Watchdog may close the named worker pane after two failed windows |
| lease effect | enum | `none` | Worker or coordinator termination never transfers the coordinator lease |

Context MUST come from a native runtime signal or explicit worker report; it MUST NOT be estimated from elapsed time or output volume.

### Coordinator Lease and Session

| Field             | Type                        | Constraints                                     | Description                                 |
| ----------------- | --------------------------- | ----------------------------------------------- | ------------------------------------------- |
| active session    | coordinator-session bead id | At most one per molecule                        | Current structural and acceptance authority |
| assigned model    | exact model assignment      | Must match root assignment                      | Coordinator capability                      |
| host              | string                      | Required                                        | Host currently coordinating                 |
| acquired at       | timestamp                   | Required                                        | Lease start                                 |
| expiry            | none                        | Non-expiring                                    | Prevents unsafe timeout takeover            |
| takeover evidence | decision/event reference    | Required for replacement of nonterminal session | Human-approved reconciliation               |

Each coordinator boot creates a permanent coordinator-session bead recording its model, host, lease event, checkpoints, decisions, and terminal outcome. The root points to the active session without deleting prior sessions.

### Worker Attempt

| Field                | Type                   | Constraints                                                                                   | Description                                                  |
| -------------------- | ---------------------- | --------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| attempt id           | Beads id               | Unique and never reused                                                                       | Durable launch identity and Herdr correlation token          |
| owner                | work bead id           | Required                                                                                      | Slice, review, or remediation being attempted                |
| relation             | enum                   | tracks, validates                                                                             | Non-blocking operational edge                                |
| exact model          | exact model assignment | Required                                                                                      | Actual runtime binding                                       |
| durable instructions | ordered list           | Write-ahead                                                                                   | Consequential messages sent to the agent                     |
| state                | enum                   | planned, launched, submitted, working, evidence_returned, verified, rejected, cancelled, lost | Semantic progress                                            |
| evidence             | record                 | Required before successful completion                                                         | Fixed point, commands, results, findings, risks, and outcome |

Worker attempts are permanent and auditable but MAY be compacted after their molecule completes. They never enter the executable frontier or block downstream work directly.

---

## Behavior

### Command-Repo Bootstrap and Routing

The bootstrap operation MUST be explicit and idempotent:

```
REQUIRE chosen absolute local path and private remote URL
IF command repo exists
    VERIFY identity, remote, Beads database, storage mode, and runtime config
ELSE
    CLONE or initialize the private command repo
    INITIALIZE Beads in embedded mode without modifying a source repository
    CONFIGURE the private Dolt remote
END IF
WRITE machine-local runtime config with the absolute .beads path
COMMIT and PUSH the recorded remote configuration with ordinary Git
VERIFY bd version, resolved workspace, pull, checkpoint, and push
NEVER persist credentials in dotfiles, command output, or tracked config
```

Synchronization has two halves that MUST both succeed: issue data travels over the Dolt remote to `refs/dolt/data`, while the recorded remote configuration reaches other machines only through ordinary Git. A machine whose database is missing or stale recovers from that committed configuration rather than from a manual database copy.

Shell startup MUST source valid local runtime configuration and globally export `BEADS_DIR`. If bootstrap has not configured a valid path, ordinary shell startup remains usable, but coordination workflows MUST stop with bootstrap guidance.

### Molecule Creation

`create-engineering-plan` MUST:

1. Resolve canonical source checkout, normalized repository identity, and one full source fixed point.
2. Use the caller's current exact model configuration and record it as planner provenance.
3. Inspect relevant code, tests, documentation, risks, and any available specifications without requiring a changed specification.
4. Obtain explicit human approval of the scope snapshot.
5. Design context-sized vertical TDD slices with genuine blocking dependencies and evidence-grounded proposed execution traces.
6. Propose Lean, Standard, or High-assurance review topology with any risk-driven gates and overrides.
7. Propose exact role defaults, per-bead overrides, reviewer independence, exact coordinator assignment, escalation ladders, correction allowances, critical-invariant triggers, and worker lifecycle policy.
8. Obtain human approval of the complete scope, review, model-assignment, context-rotation, and Watchdog map.
9. Probe the installed Beads graph schema with a disposable dry run; warnings about unknown or dropped fields are validation failures.
10. Atomically create the complete graph with a planner-owned activation gate blocking every initial implementation frontier; materialize required unsupported fields while that gate remains open.
11. Read back nodes, fields, metadata, edges, assignments, traces, acceptance, and readiness; validate exact counts/directions, coverage, acyclicity, and review topology.
12. Record validation evidence, transition the root to executable state, close the activation gate, verify the expected first frontier, and create one initial semantic checkpoint. Push once at activation when configured and authorized.

A partial, lossy, cyclic, or mismatched graph MUST remain blocked by the activation gate and MUST NOT expose implementation slices as ready. The planner MUST NOT fall back to a partially runnable sequential graph. `create-engineering-plan` MUST NOT create durable Markdown artifacts or source-repository `.beads/` state.

### Single-Writer Durable Storage

The command repo uses embedded single-writer storage. Every durable write — coordinator checkpoints, write-ahead attempt creation, worker evidence, and reviewer findings — MUST hold the writer position exclusively for the duration of that write.

This constrains execution rather than the graph:

1. Durable writes MUST be short and serialized. Concurrent write attempts contend for a file lock and one of them fails.
2. A writer MUST treat a contention failure as a retryable condition and MUST NOT report success, skip the write, or continue past it. Losing a write-ahead record would break the recovery guarantees this specification depends on.
3. Live agent work MAY overlap; only the durable write MUST serialize. Agents doing long implementation or review work hold no writer position while working.
4. Parallel fan-out MUST be bounded so that evidence submission does not become a sustained contention point.

Read-only inspection is unconstrained. If sustained concurrent writing later becomes necessary, moving to server-mode storage is an approved migration rather than a change to the coordination contract.

### Work Ownership and Frontier

Only the active coordinator MAY mutate graph structure, dependencies, scope, acceptance criteria, integration state, close/reopen state, review policy, or unapproved assignment changes.

Workers MAY atomically claim assigned ready slices and append attempt evidence. Reviewers MAY append findings to their assigned attempts. A blocking slice closes only after:

1. implementation evidence exists at a full candidate commit;
2. independent per-slice Test Quality passes at that fixed point;
3. focused mechanical commands pass at that fixed point;
4. the candidate integrates mechanically into the integration branch; and
5. post-integration checks pass.

Only closed blockers release dependent work into `bd ready` for the molecule.

### Coordinator Lease

Before structural mutation or Herdr control, `execute-engineering-molecule` MUST verify the exact coordinator assignment and acquire the non-expiring coordinator lease. If another nonterminal session holds it, execution stops.

Takeover requires:

1. inspection of molecule, sync, Git, attempt, and prior coordinator-session state;
2. explicit human approval;
3. a linked decision/event recording rationale; and
4. a new coordinator-session bead before the root pointer changes.

No timeout, heartbeat, worker termination, Watchdog action, or coordinator process termination may transfer authority automatically.

### Write-Ahead Herdr Attempts

Herdr is required for agent launch, communication, observation, and steering. It is not required to inspect or reconcile Beads state.

Every agent side effect MUST follow this ordering:

```
CREATE unique attempt bead in planned state
PERSIST and checkpoint the consequential instruction
THEN launch or message through Herdr with the attempt token
OBSERVE Herdr result
RECORD the next semantic attempt state
```

Consequential instructions include the initial packet, scope clarification, consolidated correction batch, escalation handoff, and evidence request. Liveness probes, keypress mechanics, public Herdr IDs, pane output, and full transcripts remain ephemeral.

### Worker Completion Evidence

Before reporting completion through Herdr, a worker or reviewer MUST write to its attempt:

- exact model used;
- full candidate commit or reviewed fixed point;
- changed-file list when applicable;
- commands and observed results;
- acceptance and failure-criteria evidence;
- findings, risks, or `none`; and
- terminal outcome.

Herdr completion is notification only. Missing durable evidence leaves the attempt nonterminal and prevents verification or integration.

### Context Rotation and Watchdog

Every editable worker follows the lifecycle policy materialized on its bead. At the checkpoint threshold it MUST preserve durable Git state, including a commit when changes exist, record test and handoff evidence, and receive no new work. At the hard-rotation threshold it MUST wind down; verified remaining work resumes only in a fresh context under a new write-ahead attempt.

`herdr-watchdog` composes generic Herdr transport and owns bounded liveness observation. It classifies nonresponsiveness only after an initial request and a final acknowledgment request both expire without acknowledgment, protocol evidence, or an inspectable settled state. A blocked or questioning worker is responsive.

When explicitly authorized, the Watchdog MAY capture final evidence and close only the named nonresponsive worker pane. It MUST NOT edit source, mutate Beads or Git, accept work, create replacement attempts, change scope, or transfer a coordinator lease. The coordinator reconciles durable and Git state before recording the attempt outcome. Coordinator loss fails closed pending evidence inspection and human-approved takeover.

### Correction and Escalation

A failed review or mechanical gate creates one consolidated correction instruction on a new or resumed attempt according to the recorded policy. Each new attempt has a distinct id. Correction allowance and critical-invariant behavior are fixed per slice unless changed through an approved decision bead.

When an escalation trigger fires, the coordinator selects the next available higher exact configuration from the approved molecule ladder and records the rung and reason. Initial-assignment unavailability is not an escalation trigger; it blocks pending human-approved reassignment. No cost budget or efficiency verdict is part of this workflow.

### Final Reviews and Remediation

After all implementation slices close, final review beads run against one held integrated fixed point according to the approved review policy. Every independent pass uses a fresh context and its bead's exact model/provider diversity rule.

Findings are consolidated without collapsing review-axis ownership. Final remediation uses the exact remediation role assignment and its escalation ladder. After remediation, repository gates and every affected review rerun; unaffected passing reviews retain an explicit non-rerun rationale. Final completion requires all configured gates and a successful private-remote checkpoint.

### Synchronization

The coordinator pulls before acquiring a lease or beginning mutation. A successful local Beads write and local Dolt commit do not imply remote durability. Correlated writes MUST be grouped into one local semantic checkpoint at recovery-relevant transitions, including:

- initial molecule activation;
- work claim plus write-ahead attempt launch;
- verified integration and slice closure;
- approved scope, review, assignment, or takeover decisions;
- final-review or remediation routing; and
- molecule completion.

Only the active sync authority may push. It pushes once per required recovery boundary when a remote is configured and caller authority permits, never after every field, edge, heartbeat, or evidence write. A successful push creates the remote checkpoint. If push fails, the local checkpoint remains durable but the molecule becomes `sync:pending`; only the leased coordinator host may continue. Lease transfer and final closure are blocked until pull/reconciliation and push succeed.

### Crash Recovery and Herdr Loss

A fresh coordinator MUST be able to derive the next safe action from Beads without conversation history or Herdr state. It inspects the molecule, Git fixed points, work frontier, coordinator sessions, attempts, instructions, evidence, and sync state before mutation.

For each nonterminal attempt:

1. Search the current Herdr instance by durable attempt token.
2. If found, inspect and resume communication.
3. If Herdr state is gone or no match exists, mark the attempt `lost` after reconciliation.
4. Create a new write-ahead attempt with a new id if work must resume.
5. Never reuse uncertain attempt identity or persist a Herdr pane id.

A new Herdr instance may therefore be empty: the graph tells the coordinator which sessions and instructions must be recreated.

### Completion and Retention

The coordinator closes the molecule only when scope acceptance, all configured review gates, Git integration evidence, and private-remote synchronization pass. The system MUST NOT automatically merge into an unapproved target branch or delete source branches, worktrees, molecule records, attempts, or decisions.

Closed attempts MAY undergo supported Beads compaction after molecule completion. Full workflow Markdown snapshots are never generated as authoritative recovery state.

### Legacy Transition

The migration is complete. No legacy execution ledger remains active, and the filesystem plan and ledger contract has been removed from the skill catalog. No filesystem plan, ledger, slice packet, verification file, or repository-local `.plan` pointer may be created.

Legacy cleanup is a separate explicit migration operation. It MUST archive untracked `~/code/beads/research/` outside the clone before deleting the old Beads binaries, symlink, global and project databases, and source clone. Normal installation MUST NEVER repeat destructive cleanup.

---

## Error Handling

| Error                          | Trigger                                                                   | Response                                                   | Recovery                                                              |
| ------------------------------ | ------------------------------------------------------------------------- | ---------------------------------------------------------- | --------------------------------------------------------------------- |
| Missing command repo           | `BEADS_DIR` absent or invalid                                             | Stop coordination; do not initialize a source repo         | Run explicit bootstrap                                                |
| Repository identity ambiguity  | Remote aliases cannot normalize or no remote/key exists                   | Stop molecule creation                                     | Supply explicit repository key or resolve remote                      |
| Unapproved scope               | Objective or criteria lack human confirmation                             | Keep draft; create no ready work                           | Obtain approval                                                       |
| Partial molecule               | Batch creation or validation fails                                        | Keep root draft/blocked; push no ready state               | Reconcile or explicitly discard draft                                 |
| Model unavailable              | Exact initial binding cannot launch                                       | Block work; do not substitute                              | Approve reassignment with decision bead                               |
| Escalation exhausted           | No higher approved available rung                                         | Block owning work bead                                     | Approve ladder change or new decision                                 |
| Lease conflict                 | Nonterminal coordinator session owns lease                                | Stop mutation and launch                                   | Resume owner or approve takeover                                      |
| Herdr unavailable              | Launch, resume, or steering required                                      | Preserve graph and block live execution                    | Start fresh Herdr and boot assigned coordinator                       |
| Uncertain launch               | Attempt is planned/submitted but observation was lost                     | Reconcile by token; never relaunch same id blindly         | Resume match or mark lost and create new attempt                      |
| Missing evidence               | Agent reports completion without durable return record                    | Do not verify, integrate, or close                         | Request evidence through a durable instruction or mark attempt failed |
| Writer contention              | A durable write fails because another writer holds the single-writer lock | Treat as retryable; never report success or skip the write | Retry the write; reduce parallel fan-out if contention persists       |
| Remote outage                  | Pull/push fails after lease                                               | Mark `sync:pending`; prevent takeover/completion           | Continue locally on lease host, then reconcile and push               |
| Dependency cycle               | Graph validation finds cycle                                              | Keep molecule draft/blocked                                | Correct graph before activation                                       |
| Review-policy drift            | Gate topology changes without decision approval                           | Reject transition                                          | Record approved decision and regenerated graph                        |
| Legacy cleanup archive failure | Untracked research cannot be archived and verified                        | Delete nothing                                             | Correct archive destination and rerun explicit cleanup                |

---

## Implementation Notes

1. Beads metadata SHOULD use a project-owned namespace and MUST avoid Beads-reserved prefixes.
2. Attempt state changes SHOULD use durable events plus queryable state labels; events are history and labels are a current-state cache.
3. Operational attempt links MUST be non-blocking so retries and lost attempts do not pollute `bd ready`.
4. The coordinator MAY run mechanical Git and test commands but MUST NOT implement or perform independent review.
5. Editable agents use isolated branches and worktrees before Herdr launch. Separate panes are not checkout isolation.
6. The source fixed point and every candidate/review/integration fixed point use full commit hashes.
7. Generated human-readable reports MAY be temporary, but Beads remains authoritative and reports MUST be labelled non-authoritative.
8. Planner and execution behavior belongs to shared skills; command-repo mutable state does not belong in dotfiles. The `beads` shared skill owns the canonical `bd` contract, and planner and coordinator skills compose it rather than restating command-repo mechanics.
9. Runtime configuration and credentials remain local even though command-repo operational history is privately synchronized.

---

## Test Scenarios

### TS-EXEC-001: External Command-Repo Routing
Category: Integration
Priority: Critical
Preconditions: Bootstrap configured a private command repo.
Input: Run `bd` from two unrelated source repositories.
Expected Output: Both use the configured external Beads database; neither source repository gains `.beads/` files.

### TS-EXEC-002: Molecule Creation Without Spec Diff
Category: End-to-End
Priority: Critical
Preconditions: Source repository has a fixed commit and no changed specification.
Input: Approve objective, acceptance, failure, exclusions, review policy, and exact model map.
Expected Output: One ready execution molecule covers the approved scope with context-sized TDD slices, traces, dependencies, and review graph; no Markdown workflow artifact is created.

### TS-EXEC-003: Integrated Closure Controls Frontier
Category: Integration
Priority: Critical
Preconditions: Slice B depends on Slice A; A implementation has returned but is not integrated.
Input: Query molecule ready work before and after verification and integration of A.
Expected Output: B remains blocked until A closes after integration, then appears ready.

### TS-EXEC-004: Write-Ahead Launch Recovery
Category: End-to-End
Priority: Critical
Preconditions: Attempt is checkpointed as planned; coordinator dies around launch.
Input: Boot a replacement coordinator.
Expected Output: It searches Herdr by attempt token, resumes a match or marks the old attempt lost and creates a new id; it never blindly duplicates the same attempt.

### TS-EXEC-005: Complete Herdr Loss
Category: End-to-End
Priority: Critical
Preconditions: Active workers existed, then Herdr and all session state disappear.
Input: Start fresh Herdr and boot the assigned coordinator.
Expected Output: Beads alone identifies every pending work and attempt transition; lost attempts are reconciled and required sessions are recreated from durable instructions.

### TS-EXEC-006: Worker Evidence Before Notification
Category: Integration
Priority: Critical
Preconditions: Worker finishes a slice.
Input: Worker reports Herdr completion without writing attempt evidence, then with complete evidence.
Expected Output: First report cannot advance verification; second report supplies the fixed point and evidence needed for review.

### TS-EXEC-007: Exact Model Assignment and Escalation
Category: Integration
Priority: High
Preconditions: Slice has exact primary assignment, correction policy, and approved ladder.
Input: Exercise unavailable primary, normal correction exhaustion, and critical-invariant miss.
Expected Output: Unavailable primary blocks for reassignment; configured triggers move only to the next available approved rung; no runtime reputation choice occurs.

### TS-EXEC-008: Review Presets and Overrides
Category: Integration
Priority: High
Preconditions: Creation can select each preset.
Input: Create Lean, Standard, and High-assurance molecules with an approved override.
Expected Output: Lean retains mandatory floor, Standard creates the complete standard gate set, High assurance creates approved risk gates/redundant passes, and the override is materialized on review beads.

### TS-EXEC-009: Coordinator Takeover
Category: End-to-End
Priority: Critical
Preconditions: A nonterminal coordinator session owns the lease but is gone.
Input: Attempt takeover without and then with evidence inspection and human approval.
Expected Output: First attempt stops; approved takeover creates a new coordinator-session bead, preserves the old session, and updates the root pointer.

### TS-EXEC-010: Controlled Offline Mode
Category: Integration
Priority: Critical
Preconditions: Coordinator holds lease and remote becomes unavailable.
Input: Continue one slice, attempt lease transfer, and attempt completion.
Expected Output: Local semantic checkpoints continue with `sync:pending`; transfer and completion remain blocked until synchronization succeeds.

### TS-EXEC-011: Attempt Graph Does Not Pollute Frontier
Category: Unit
Priority: High
Preconditions: A slice has multiple correction, review, and lost attempt beads.
Input: Query ready work for the molecule.
Expected Output: Attempt beads are absent from executable readiness; only owning work-bead dependencies determine the frontier.

### TS-EXEC-011a: Durable Writes Serialize Under Contention
Category: Integration
Priority: Critical
Preconditions: Two agents attempt durable writes to the command repo at the same moment.
Input: Submit two attempt-evidence writes concurrently.
Expected Output: Both writes eventually land; the contending writer retries rather than reporting success, skipping the record, or continuing past the failure.

### TS-EXEC-012: Atomic Graph Activation
Category: End-to-End
Priority: Critical
Preconditions: Installed Beads graph support may reject or silently drop fields.
Input: Probe the installed schema, ingest a complete molecule, materialize unsupported required fields, and inspect readiness before and after activation.
Expected Output: Unknown-field warnings fail the probe; one activation gate blocks every implementation frontier until exact graph readback, acyclicity, lint, assignment, and trace checks pass; gate closure exposes only the expected first frontier.

### TS-EXEC-013: Context Rotation and Nonresponsive Worker
Category: End-to-End
Priority: Critical
Preconditions: An editable worker has approved checkpoint/hard-rotation thresholds, deadlines, and Watchdog pane-close authority.
Input: Cross both thresholds with a responsive worker, then exercise two missed acknowledgment windows with another worker.
Expected Output: The responsive worker checkpoints, winds down, and resumes under a fresh attempt; the nonresponsive worker pane is closed only after final evidence capture; neither path transfers the coordinator lease or lets the Watchdog mutate Beads, Git, scope, acceptance, or replacement work.

### TS-EXEC-014: Semantic Checkpoint Batching
Category: Integration
Priority: High
Preconditions: One transition requires several correlated Beads writes and a configured Dolt remote.
Input: Materialize the transition and inspect local commits and pushes.
Expected Output: Related writes form one local semantic checkpoint and one authorized push at the recovery boundary; no per-field or per-edge push occurs; local and remote durability states are distinguishable.

### TS-EXEC-015: Explicit Legacy Cleanup
Category: Integration
Priority: Critical
Preconditions: Legacy binaries, databases, source clone, and untracked research exist.
Input: Run normal install, then explicit cleanup with a valid archive destination.
Expected Output: Normal install deletes no legacy data; explicit cleanup verifies the research archive before deleting every approved legacy location.

---

## Changelog

| Version | Date       | Change                                                                                                                                                                                                                 |
| ------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.4.0   | 2026-08-03 | Added version-aware atomic graph ingestion with an activation gate, explicit worker context rotation and bounded Watchdog termination, fail-closed lease handling, and local-versus-remote semantic checkpoint rules. |
| 1.3.0   | 2026-08-02 | Renamed the planning and execution entries to `create-engineering-plan` and `execute-engineering-molecule`, scoping both to the engineering work domain.                                                                |
| 1.2.0   | 2026-08-02 | Closed the legacy transition after the filesystem ledger contract was removed from the skill catalog, and recorded that the encoding skills exist while runtime execution remains unproven.                             |
| 1.1.0   | 2026-08-02 | Adopted single-writer embedded storage, added the durable-write serialization constraint, and specified two-half synchronization against a private git+ssh remote.                                                     |
| 1.0.0   | 2026-08-01 | Established private command-repo execution molecules, exact model and review policy, write-ahead attempt graphs, Herdr transport boundaries, semantic synchronization, crash recovery, and legacy transition behavior. |

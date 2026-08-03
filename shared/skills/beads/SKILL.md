---
name: beads
description: Operate the external Beads command repo as durable execution authority — issue and dependency mechanics, compact current-state recovery, graph ingestion, work frontiers, write-ahead attempts, and serialized synchronization. Use when creating or executing a molecule, claiming or closing work, recording attempt evidence, recovering after a crash, or when another skill needs the canonical bd contract.
metadata:
  short-description: Canonical bd and recovery contract
allowed-tools: read,bash
---

# Beads

## Language Definitions

- **Command repo** — private external checkout holding the authoritative `.beads/` database for all source repositories.
- **Execution molecule** — one root epic and work-bead graph from an approved scope; not a `bd mol` template.
- **Frontier** — ready work beads whose blockers are closed.
- **Attempt** — permanent non-blocking bead recording one agent launch, instruction, and evidence.
- **Fixed point** — full Git commit under implementation, review, or integration.
- **Recovery projection** — canonical compact `metadata.recovery` current-state cache; notes remain audit history.
- **Semantic checkpoint** — one locally durable recovery-relevant transition.
- **Remote checkpoint** — a semantic checkpoint successfully pushed to the Dolt remote.

Beads owns `bd` mechanics. Callers retain scope, review policy, workflow state, and acceptance. Source repositories never gain `.beads/` state.

## Workflow

### 1. Verify routing before writes

```bash
bd --version
echo "${BEADS_DIR:?run install.sh --beads-bootstrap PATH REMOTE}"
bd where
bd dolt pull
```

Require the external command repo. If routing is invalid, stop; never run `bd init` in a source repository. Use `bd prime` when installed CLI context is stale. Reconcile pull failure before mutation unless the root already records accepted local `sync:pending`.

Completion: version, routing, and pull state are known; source checkouts remain Beads-free.

### 2. Read compact current state first

Require an explicit root id; never infer the latest. Ordinary startup runs only filtered reads:

```bash
bd show <root> --long --json |
  jq '.[0] | {id,status,labels,recovery:.metadata.recovery}'
bd list --parent <root> --status in_progress,blocked --json |
  jq '[.[] | {id,status,labels,recovery:.metadata.recovery}]'
bd ready --mol <root> --json |
  jq '[.steps[] | select(.parallel_info.is_ready == true) |
       .issue | {id,title,status,labels}]'
```

`bd ready --json` returns one object, not an array: `ready_steps` is a numeric count and the frontier records are under `.steps[]`; readiness is `.parallel_info.is_ready`, and each issue is nested under `.issue`. Do not pipe the whole response through `.[]` or index its scalar `ready_steps` value as an object.

Reconcile projected branches, worktrees, and hashes with Git. Do not read all notes/attempts, transcripts, the complete coordination spec, or unfiltered frontier output. Expand `bd show <id> --long --json` only when an active projection is missing, over 1024 serialized bytes, contradictory, evidence-incomplete for its state, or inconsistent with Git. Notes never silently override current metadata.

Completion: root, active records, frontier, and next action are known; only contradictions were expanded.

### 3. Serialize and verify writes

Embedded Dolt has one writer. Keep writes short. Retry lock contention; never skip or continue past a lost write. Live agent work may overlap, durable writes may not.

Use `bd update <id> --metadata '<complete-json>' --json` to remove obsolete keys; `--set-metadata` cannot prove deletion. Preserve notes and historical beads unless appending approved audit evidence. Read back status, labels, metadata, and projection size after each write.

Completion: every write landed exactly once, obsolete current keys are absent, and readback matches intent.

### 4. Maintain recovery projections

Every active root, work bead, and attempt has a projection at most 1024 serialized bytes containing, as applicable:

- state and one next action;
- branch, worktree, and base/candidate/integration fixed points;
- latest attempt id, state, and resumability;
- correction count;
- latest review verdict and finding count; and
- evidence completeness, plus root sync state.

Refresh it in the transition's semantic checkpoint. Use explicit `none`, `pending`, or `not_applicable` where omission could resemble missing evidence. Notes remain audit history, not startup input.

Completion: each changed active projection is within limit and agrees with Git and evidence.

### 5. Create, claim, and close work

Create work with observable acceptance and genuine blockers; keep partial graphs behind an activation gate and validate cycles. Claim ready work atomically. Attempts use non-blocking `tracks` or `validates` relations and never affect the frontier.

Close a slice only after candidate evidence, independent per-slice Test Quality, focused checks, mechanical integration, and post-integration checks.

Completion: readiness derives only from work edges, writes survive readback, and no slice closes before verified integration.

### 6. Checkpoint without push churn

Inspect `bd config get dolt.auto-commit` and installed help. Verify local commits; use supported batch mode for correlated writes when useful. Push only with caller authority and only at semantic boundaries, never per field, edge, heartbeat, or evidence write.

Without an authorized successful push, set root `sync_state: pending`. Pending sync blocks completion but creates no coordinator lease or takeover gate. A fresh process reconciles pull results, local commits, projections, and Git.

Completion: local durability is verified; remote durability is verified once or explicitly pending; no push is claimed without evidence.

## Activities

### Write ahead an agent side effect

Before a consequential launch or message: create a unique planned attempt with a non-blocking owner relation; persist its exact instruction and projection; checkpoint; then perform the Herdr side effect with the attempt id; finally record the observed semantic state and refresh affected projections.

Initial packets, clarifications, consolidated corrections, escalation handoffs, and evidence requests are consequential. Keypresses, liveness probes, pane output, public Herdr ids, and transcripts are ephemeral.

Completion: no side effect preceded durable intent and no uncertain id was reused.

### Record completion evidence

Before transport completion, record exact model, full candidate/review fixed point, changed files when applicable, commands/results, acceptance/failure evidence, findings or `none`, risks, and outcome. Set `evidence_returned`, mark evidence completeness accurately, and refresh the owner projection. Missing evidence blocks verification and integration.

Completion: readback contains the fixed point, results, outcome, and matching projection.

### Recover after a crash

Run summary-first startup. If projections and Git agree, resume without notes. For each contradictory or nonterminal attempt only, inspect its full record and search live transport by token. Resume a certain match; otherwise reconcile Git/evidence, mark it `lost`, and create a new id if work remains. Never persist pane identity.

Historical coordinator-session, lease, rotation, decision, Watchdog, and attempt beads remain provenance; old metadata never overrides projections.

Completion: contradictions are reconciled, uncertain attempts are resumed or lost, and the next action follows Beads plus Git rather than conversation.

## Reference

- When a reviewed graph is large enough that sequential creation risks partial or runnable state, load [`GRAPH-INGESTION.md`](GRAPH-INGESTION.md) before materialization for version probing, atomic apply, readback, and activation. Ordinary issue, attempt, projection, and recovery operations do not load it.

---
name: beads
description: Operate the external Beads command repo as durable execution authority — issue and dependency mechanics, execution molecules, work-bead frontiers, write-ahead attempts, and single-writer synchronization. Use when creating or executing an execution molecule, claiming or closing work beads, recording attempt evidence, recovering coordination state after a crash, or when another skill needs the canonical bd contract.
metadata:
  short-description: Canonical bd and execution-molecule contract
allowed-tools: read,bash
---

# Beads

Beads is the durable source of truth for coordination work. This skill owns the canonical `bd` contract for this repository; other skills compose it rather than restating `bd` mechanics.

Every source repository routes to **one private external command repo** through `BEADS_DIR`. A source repository never gains a `.beads/` directory.

## Language Definitions

- **Command repo** — the private external checkout holding the authoritative `.beads/` database for every source repository.
- **Execution molecule** — one root epic plus its work-bead graph, created from one human-approved scope snapshot. Not a `bd mol` template proto.
- **Work bead** — one slice, review, remediation, decision, or mechanical gate. Blocking dependencies between work beads derive the frontier.
- **Frontier** — ready work beads whose blockers are closed, as reported by `bd ready --mol <root>`.
- **Attempt** — a durable non-blocking bead recording one agent launch, its instructions, and its returned evidence.
- **Fixed point** — a full Git commit hash under implementation or review.
- **Semantic checkpoint** — a durable commit plus push at a recovery-relevant transition.

`bd mol` in the upstream CLI means template instantiation (`pour`, `wisp`, `bond`, `distill`). An execution molecule is a root epic and its graph; do not spawn one from a proto.

## Workflow

### 1. Verify routing before any durable operation

```bash
bd --version
echo "${BEADS_DIR:?run install.sh --beads-bootstrap PATH REMOTE}"
bd where
```

`BEADS_DIR` must resolve to the command repo's `.beads` directory. If it is unset or invalid, stop and report bootstrap guidance; never run `bd init` in a source repository to recover. Run `bd prime` when Beads context is missing or stale — it is the upstream-maintained CLI reference and stays current across `bd` releases.

Pull before mutating, so a stale local database cannot fork authority:

```bash
bd dolt pull
```

Completion criterion: `bd` runs, `BEADS_DIR` resolves to the command repo, the working database is current, and no source repository gained `.beads/` state.

### 2. Read state before writing

Inspect before mutating anything:

```bash
bd ready --mol <root-id> --json   # frontier for one molecule
bd show <id> --long --json        # full bead context
bd list --status in_progress --json
bd dep tree <root-id>
```

Use `--json` whenever output is parsed. Read-only inspection is unconstrained and never contends for the writer position.

Completion criterion: current graph state, frontier, and the target bead's context are known from `bd` output rather than from conversation history.

### 3. Serialize every durable write

The command repo uses embedded single-writer storage. Each durable write holds the writer position exclusively and must be short.

A write that fails because another writer holds the lock is **retryable, never skippable**. Retry it. Do not report success, do not skip the record, and do not continue past it — a lost write-ahead record breaks recovery. If contention persists, reduce parallel fan-out rather than dropping writes.

Live agent work may overlap freely; only the durable write serializes. Agents hold no writer position while implementing or reviewing.

Completion criterion: every attempted durable write either landed and was verified by reading it back, or was retried to completion; none were skipped.

### 4. Create and close work

Create work beads with explicit dependencies, then validate the graph:

```bash
bd create "<behavior>" --type=task --parent=<root-id> \
  --description="<scope>" --acceptance="<observable criteria>" --json
bd dep <blocker-id> --blocks <blocked-id>
bd dep cycles                      # must report none before activation
```

Claim atomically, record evidence as you go, and close only completed work:

```bash
bd update <id> --claim --json
bd update <id> --append-notes "<evidence>" --json
bd close <id> --reason "<what was verified>" --json
```

Notes are how work survives compaction and handoff — append evidence during the work, not only at the end. A partial graph stays draft or blocked and must not expose ready work.

Completion criterion: created beads carry acceptance criteria and genuine blocking edges, `bd dep cycles` reports none, and no bead was closed without verified completion evidence.

### 5. Checkpoint at semantic transitions

Commit and push at recovery-relevant transitions — molecule activation, durable evidence submission, verified integration and closure, approved decisions, review and remediation transitions, and completion:

```bash
bd dolt commit -m "<transition>"
bd dolt push
```

Issue data travels over the Dolt remote to `refs/dolt/data`; recorded remote *configuration* reaches other machines only through ordinary Git. Both halves must succeed for another machine to recover.

If the remote is unavailable, only the leased coordinator host may continue: local checkpoints proceed with the molecule marked `sync:pending`, while lease transfer and final closure stay blocked until pull and push succeed.

Completion criterion: every semantic transition has a durable commit, and each is pushed or explicitly recorded as `sync:pending` on the leased host.

## Activities

Select these outside the ordinary sequence.

### Write-ahead an agent side effect

Every consequential agent instruction is persisted **before** the agent is launched or messaged, so a coordinator that dies mid-launch can reconcile:

1. `bd create` the attempt bead in `planned` state, linked to its owning work bead with a non-blocking edge.
2. Persist the consequential instruction on that attempt and checkpoint it.
3. Only then launch or message through Herdr, carrying the attempt id as the correlation token.
4. Record the next semantic attempt state after observing the result.

Consequential instructions are the initial packet, scope clarification, consolidated correction batch, escalation handoff, and evidence request. Liveness probes, keypresses, pane output, and transcripts stay ephemeral. Attempt beads use non-blocking edges so retries and lost attempts never pollute `bd ready`.

Completion criterion: no agent side effect preceded its durable attempt record, and each attempt carries a unique never-reused id.

### Record completion evidence

Before an agent reports completion, write to its attempt: exact model used, full candidate commit or reviewed fixed point, changed-file list where applicable, commands and observed results, acceptance and failure evidence, findings or `none`, and terminal outcome.

Transport-level completion is notification only. Missing durable evidence leaves the attempt nonterminal and blocks verification, integration, and closure.

Completion criterion: the attempt holds a full fixed-point hash and command results, verified by reading the bead back.

### Recover coordination state after a crash

Derive the next safe action from Beads alone, without conversation history:

```bash
bd dolt pull
bd show <root-id> --long --json
bd ready --mol <root-id> --json
bd list --status in_progress --json
```

Inspect the molecule, Git fixed points, frontier, coordinator sessions, attempts, instructions, evidence, and sync state before any mutation. For each nonterminal attempt: search the live transport by durable attempt token; resume a match; otherwise mark it `lost` after reconciliation and create a **new** attempt id for resumed work. Never reuse an uncertain attempt identity and never persist a pane id.

Completion criterion: every nonterminal attempt is resumed or explicitly marked lost, and the next action is justified by `bd` state rather than recalled context.

## Reference

- When execution requires the full coordination contract — coordinator lease acquisition and takeover, review presets and independence rules, exact model assignment, escalation ladders, or correction allowances — read `~/dotfiles/specs/execution-coordination.md`. It is authoritative where this skill and it overlap. Ordinary bead creation, claiming, evidence recording, and closing do not need it.

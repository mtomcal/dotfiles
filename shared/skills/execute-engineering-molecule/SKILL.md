---
name: execute-engineering-molecule
description: Coordinate one explicit Beads engineering molecule through Herdr — acquiring the coordinator lease, launching write-ahead attempts, verifying evidence, integrating slices, running configured reviews, and recovering after a crash. Use when a create-engineering-plan molecule is ready for implementation, verification, integration, remediation, or interrupted-execution recovery inside Herdr. Coordinates engineering molecules only; its loop assumes Git commits, isolated worktrees, and testable slices.
metadata:
  short-description: Execute a Beads molecule in Herdr
allowed-tools: read,bash
---

# Execute Engineering Molecule

## Language Definitions

- **Coordinator** — the leased authority that mutates graph structure, verifies evidence, and integrates approved commits without implementing or reviewing.
- **Coordinator lease** — the non-expiring claim on a molecule; at most one nonterminal coordinator session holds it.
- **Frontier** — ready work beads whose blockers are closed, from `bd ready --mol <root>`.
- **Fixed point** — full immutable commit hash under verification.
- **Observation timeout** — maximum wait for the next expected Herdr evidence before the coordinator inspects and steers.

Beads is durable authority; Herdr is ephemeral transport. Herdr state is never a durable record.

This skill coordinates **engineering molecules only**. Its loop is Git- and test-shaped throughout: fixed points are commit hashes, slices are implemented in isolated worktrees and integrated by cherry-pick, and every slice requires an independent test-quality audit. A molecule whose work has no commits to integrate and no tests to audit cannot be executed here. Coordinating another kind of Beads work would need its own skill; none exists yet.

## Workflow

Load the shared [`beads`](../beads/SKILL.md) skill for all `bd` operations — routing, durable-write serialization, write-ahead attempts, evidence recording, and recovery.

### 1. Gate Herdr and validate the molecule

Require `HERDR_ENV=1`; if absent, stop. There is no non-Herdr execution fallback. After the gate passes, load the shared [`herdr`](../herdr/SKILL.md) skill before controlling panes or agents. Herdr owns terminal transport only; the coordinator retains task briefs, checkout isolation, evidence contracts, and acceptance.

Require **one explicit execution-molecule id**. Do not infer a latest molecule or search for one. Verify command-repo routing, pull, then validate:

- repository identity and source fixed point match the current canonical checkout;
- the scope snapshot carries explicit human approval;
- review policy and exact model assignments are materialized on executable beads;
- the graph is acyclic and complete — `bd dep cycles` reports none; and
- sync state is clean or an explicitly accepted `sync:pending` on this host.

Stop on any mismatch, missing fixed point, unapproved scope, partial graph, or contradiction. The scope snapshot is frozen; changing it requires a linked decision bead and human approval.

If the molecule's slices describe authoring work — skills, specs, glossaries, documentation, or agent instructions — rather than engineering work with observable failing tests, stop and report it. Such a molecule should not have been created; route the work to its owning skill instead of executing tracer cycles against prose.

Completion criterion: Herdr is available, its skill is loaded, and the explicit molecule id, repository identity, fixed point, approved scope, assignments, graph integrity, and sync state are verified.

### 2. Acquire the coordinator lease

Verify this session's exact model matches the molecule's recorded coordinator assignment. A mismatched model MUST NOT coordinate. Then create a coordinator-session bead and acquire the non-expiring lease before any structural mutation or Herdr launch.

If another nonterminal session holds the lease, **stop**. No timeout or heartbeat transfers authority. Takeover requires all four: inspection of molecule, sync, Git, attempt, and prior-session state; explicit human approval; a linked decision bead recording rationale; and a new coordinator-session bead created before the root pointer changes. Prior sessions are preserved, never deleted.

If either the implementation or oversight assignment selects Claude Code, load [`herdr-claude-code`](../herdr-claude-code/SKILL.md) before launching it; it owns Claude's launch arguments, readiness interpretation, atomic prompt submission, and blocked-agent steering. Other assignments use base Herdr transport. Record one observation timeout. Keep secrets out of bead state.

Completion criterion: this session's model matches the coordinator assignment, exactly one nonterminal session holds the lease, the transport route per role is known, and any takeover has approval plus a decision bead.

If the molecule's bead kinds, edge semantics, or state transitions are unfamiliar — or a recovery decision turns on which attempt states are terminal — read [WORKFLOW-SHAPES.md](../create-engineering-plan/WORKFLOW-SHAPES.md) for the bead taxonomy, the per-slice execution sequence, and the work-bead, attempt, and molecule state machines. Routine execution of a familiar graph does not need it.

### 3. Prepare integration and derive the frontier

Create a dedicated integration branch and isolated integration worktree from the molecule's source fixed point. Derive the frontier from Beads, never from memory:

```bash
bd ready --mol <root-id> --json
```

Attempt beads use non-blocking edges and never appear in the frontier; only work-bead dependencies determine readiness.

Completion criterion: the integration branch and isolated worktree exist at the source fixed point, and the frontier equals ready work beads whose blockers are closed.

### 4. Implement, verify, and integrate each frontier slice

For each frontier slice, create an isolated editable branch and worktree from the current recorded integration fixed point **before** using Herdr transport. Separate panes are not checkout isolation.

Follow the write-ahead ordering from the `beads` skill: create the planned attempt bead and persist its instruction, checkpoint, and only then launch through Herdr carrying the attempt id. Launch one implementation agent with the slice's exact assignment and authorize only that slice's scope.

Observe through the composed Herdr skill using the recorded observation timeout. Read current evidence before waiting for future evidence. Steer immediately on blocked, premature-idle, error, missing-evidence, or input-needed states. A timeout triggers state and output inspection, not a conclusion — it is not proof of a stall or failure. Never infer success from idle, missing, or compacted panes. Workers never mutate graph structure or claim acceptance.

The worker writes evidence to its attempt before reporting completion. Herdr completion is notification only; missing durable evidence leaves the attempt nonterminal and blocks progress.

Pin the returned commit as a fixed point. In a separate read-only agent using the oversight assignment, compose [`test-quality-verifier`](../test-quality-verifier/SKILL.md) in audit-only mode against that slice scope and fixed point. This independent per-slice pass is mandatory under every review preset. The verifier must be independent of implementation and returns findings without editing.

On findings or missing evidence, record the attempt and relay one **consolidated** correction batch to the same implementer on the same slice branch, as a new attempt with a new id. If that implementer cannot be resumed, block rather than silently substituting another agent. After a new commit, pin the new fixed point and rerun the verifier. When the slice's approved correction allowance is exhausted or a critical-invariant trigger fires, escalate to the next available higher rung on the approved ladder and record the rung and reason; if no higher rung is available, block the work bead. Unavailable initial assignments block for reassignment and are not escalation triggers.

After the verifier passes, run the slice's focused commands and applicable mechanical repository gates at that exact fixed point. Failures return through the same correction loop and require reverification at the new fixed point.

Only after both independent test-quality verification and coordinator mechanical gates pass may integration proceed. Use mechanical cherry-pick or merge commands and record the resulting full integration commit. If integration conflicts or checks require semantic changes, abort the mechanical operation and return evidence to the same implementer through the correction loop — the coordinator does not resolve behavior by editing. Close the slice only after post-integration checks pass, then recompute the frontier.

Completion criterion: every closed slice has isolated implementation commits, durable attempt evidence at a full fixed point, a passing independent test-quality audit, passing coordinator gates, and a recorded integration commit — and only closed blockers released dependent work.

### 5. Run configured final reviews and remediate

After all implementation slices close, pin the integration branch head, run all repository gates, and hold that one unchanged integrated candidate for every review. Run the molecule's approved review policy against that single held fixed point, concurrently where supported.

Repository mechanical gates and independent Scope fidelity are always required. Standard adds integrated Test Quality, Standards, Premortem, and Security; High assurance adds approved risk-triggered gates and second passes. Compose [`test-quality-verifier`](../test-quality-verifier/SKILL.md) for the integrated Test Quality pass — in addition to, never replacing, the per-slice audits in step 4 — and [`code-review`](../code-review/SKILL.md) for independent Standards and Spec axes.

Every independent pass uses a fresh context and its bead's exact model and provider-diversity rule. Each pass is a write-ahead attempt with durable findings. Reviewers report findings and never edit.

Consolidate all gate and review findings without collapsing review-axis ownership. If findings remain, launch one isolated editable remediation agent using the exact remediation assignment — never an original slice worker — with the complete consolidated batch, exact fixed point, authorized scope, and evidence contract. Integrate its returned commit mechanically and pin the new fixed point. After any remediation, always rerun repository gates, rerun every failed review, and rerun each passing review the change invalidates; record explicit rationale for any review not rerun. Remediation follows its own escalation ladder and correction allowance; exhaustion blocks.

Completion criterion: every configured gate passes against the same integrated fixed point with recorded rerun rationale, or the molecule is explicitly blocked with all fixed points, findings, and attempts preserved.

### 6. Complete or recover

Before closing the molecule, verify every acceptance criterion against integrated evidence, confirm all configured gates passed, and complete a successful private-remote checkpoint. Record the final fixed point, remaining worktrees and branches, and any limitations.

Never automatically merge the integration branch into an unapproved target, and never delete source branches, worktrees, molecule records, attempts, or decisions. Completion is blocked while sync is pending.

On interruption, recover from Beads alone using the `beads` skill's recovery activity: pull, inspect the molecule, frontier, sessions, attempts, and sync state; reconcile recorded branches, worktrees, and commits against Git before any transition. Rediscover live Herdr resources by durable attempt token; mark unmatched nonterminal attempts `lost` and create new ids for resumed work. Never trust persisted pane identity. A fresh Herdr instance may be empty — the graph says which sessions and instructions to recreate.

Completion criterion: either the molecule is closed at one fully passing fixed point with a successful checkpoint and another coordinator could audit it without conversation history, or it is blocked with the exact recovery action and every prior attempt intact.

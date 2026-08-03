---
name: execute-engineering-molecule
description: Coordinate one explicit Beads engineering molecule through Herdr — summary-first startup, write-ahead attempts, fixed-point verification, isolated integration, configured reviews, compact recovery, and crash reconciliation. Use when a create-engineering-plan molecule is ready for implementation, verification, integration, remediation, or interrupted recovery inside Herdr. Coordinates engineering molecules only; its loop assumes Git commits, isolated worktrees, and testable slices.
metadata:
  short-description: Execute a Beads molecule in Herdr
allowed-tools: read,bash
---

# Execute Engineering Molecule

## Language Definitions

- **Coordinator** — solo actor responsible for structure, evidence verification, integration, and recovery without implementing or independently reviewing.
- **Recovery projection** — compact Beads current-state cache read before notes or historical attempts.
- **Coordinator run marker** — optional non-authoritative duplicate-process hint; never a lease or mutation gate.
- **Frontier** — ready work beads whose blockers are closed.
- **Fixed point** — full immutable Git commit under verification.
- **Context rotation** — checkpoint-and-recreate lifecycle at approved worker thresholds.
- **Continuation driver** — opt-in, bounded, transport-only polling sidecar that reads one explicit root, waits for one exact coordinator to settle, and re-prompts it; an enabled context-rotation branch may recreate only that coordinator from root configuration, and it has no Beads or worker authority.
- **Continuity Profile** — the root's approved generic continuation contract; disabled by default, and never a durable Herdr identity or coordinator lease.

Beads is durable authority; Herdr is ephemeral transport. This skill executes engineering molecules only. Work without testable behavior and commits to integrate stops and routes to its authoring owner or reports that none exists.

## Workflow

Load [`beads`](../beads/SKILL.md) for every `bd` operation and recovery mechanic.

### 1. Gate and start from summaries

Require `HERDR_ENV=1` and one explicit molecule id; never infer the latest. Load [`herdr`](../herdr/SKILL.md) only before live control. There is no non-Herdr fallback.

Match provider, model, and thinking to the coordinator assignment. Validate repository identity, source fixed point, approved scope, review/model/lifecycle policy, graph acyclicity, and sync state. If the root carries a Continuity Profile, validate its complete generic contract and linked approved decision before enabling transport; a disabled profile is a valid no-op. When enabled, require the exact coordinator target ephemerally at launch and never read a Herdr identity from Beads. The coordinator itself invokes the normal sidecar launcher before its first recovery read, Beads mutation, worker route, or wait; no external bootstrap substitutes for that startup action. Stop on mismatch; never substitute models silently.

Run the `beads` compact startup: root and active-child projections, filtered frontier, then projected Git paths and hashes. Do not load the complete coordination spec, all notes/attempts, transcripts, or irrelevant branches. Expand only missing, oversized, contradictory, or evidence-incomplete records. Invoked skill prose plus filtered startup output must remain below 20 KB before work resumes.

Completion: runtime, molecule, policies, compact state, frontier, sync, and Git agree; only contradictions expanded; no live duplicate is performing side effects.

### 2. Reconcile integration and frontier

Create or reconcile the integration branch and isolated worktree at the recorded full fixed point. Derive readiness from `bd ready --mol <root> --json`; attempts remain non-blocking.

Completion: integration path/branch/head match the root projection and the frontier matches closed blockers.

### 3. Implement with write-ahead evidence

Before transport, create an isolated slice branch/worktree from the integration fixed point. Separate panes are not isolation. Use the exact assignment and `beads` write-ahead ordering for launch, correction, escalation, and evidence requests. Claude assignments additionally compose [`herdr-claude-code`](../herdr-claude-code/SKILL.md); others use base Herdr.

Run every active-worker cycle as **observe → persist → route/steer → wait → repeat**:

1. **Observe** the current root/attempt projections and worker evidence before waiting.
2. **Persist** the observed transition and the exact next instruction or evidence request using the Beads write-ahead ordering.
3. **Route/steer** only after that durable intent exists; blocked, premature idle, error, missing evidence, and input-needed states require inspection and steering.
4. **Wait** with the recorded timeout, then inspect the returned state and evidence.
5. **Repeat** while active attempts remain, or advance the molecule only after the projections and evidence satisfy the next gate.

A strict return gate forbids a status-only return while any active attempt exists. Before returning control, the coordinator must either record a durable transition and route/steer, or observe complete evidence and advance the attempt/slice projection; timeout is not failure. Workers never mutate graph, integration, or acceptance.

Use native/reported context, never estimates. At checkpoint threshold, persist the instruction before sending it, require Git/test/handoff evidence, and assign no new work. At hard threshold, persist wind-down, verify evidence, end the attempt, and resume under a new id in fresh context. A nonresponsive worker is handled by ordinary Herdr state/output inspection and coordinator reconciliation; do not launch a separate monitor or close its pane automatically.

The worker records exact completion evidence before Herdr notification; refresh attempt and slice projections in the same transition.

Completion: each return has an isolated full commit, complete evidence, matching projections, and no transport state treated as authority.

### 4. Verify Test Quality and corrections

Pin the candidate. Launch a fresh read-only reviewer with the oversight assignment and compose [`test-quality-verifier`](../test-quality-verifier/SKILL.md) in audit-only mode. Independent per-slice Test Quality is mandatory under every preset; reviewers never edit.

For findings or missing evidence, persist one consolidated correction under a new attempt id. Resume the same implementer when policy requires; otherwise block rather than substitute. Increment correction count and rerun Test Quality at each new commit.

Correction allowance and critical triggers are fixed. Escalate only to the next available exact approved rung; initial unavailability is not escalation, and exhaustion blocks. After Test Quality passes, run focused and applicable repository commands at that exact commit; failures re-enter correction and reverification.

Completion: candidate Test Quality has no unresolved findings, commands pass, and projections record verdict/count, corrections, fixed point, and evidence completeness.

### 5. Integrate and release blockers

Only after step 4 passes, integrate mechanically and record the full integration commit. On conflict or semantic change, abort and route evidence to the implementer; the coordinator does not edit behavior.

Run post-integration checks, refresh root/slice projections, close only after success, checkpoint locally, and recompute the frontier. Push only when authorized; otherwise set root sync pending.

Completion: each closed slice has implementation evidence, independent Test Quality, coordinator gates, integration commit, and post-integration checks before releasing dependents.

### 6. Run final reviews and remediation

After implementation closes, hold one integrated fixed point for repository gates and the approved review graph. Repository gates and independent Scope fidelity are always required. Standard adds integrated Test Quality, Standards, Premortem, and Security; High assurance adds approved risk gates and redundant passes.

Use fresh contexts and exact independence rules. Compose `test-quality-verifier` for integrated Test Quality and [`code-review`](../code-review/SKILL.md) for Standards/Spec. Every review is a write-ahead attempt with findings and no edits.

Consolidate without collapsing axes. One isolated remediation agent uses the exact assignment and complete batch. Integrate mechanically, rerun repository gates and affected reviews, and record rationale for unaffected non-reruns. Remediation exhaustion blocks.

Completion: every configured gate passes at one current fixed point with rerun evidence, or the molecule records exact blockers and next action.

### 7. Complete or recover

Before closure, verify scope acceptance, all gates, final Git state, and a successful remote checkpoint. Record final fixed point and retained branches/worktrees. Never auto-merge an unapproved target or delete branches, worktrees, molecule records, attempts, decisions, or historical coordinator/Watchdog records. Pending sync blocks completion.

After interruption, run summary-first startup. Continue directly when projections agree with Git; expand contradictions only. Search nonterminal attempts by durable token; resume a certain match or reconcile and mark it lost before creating a new id. Never trust pane ids.

When explicitly enabled by a root policy and linked approved decision, the adjacent `coordinator-continuation.sh` is the only continuation route. The generic policy's `sidecar_layout` must require `target: exact_coordinator_pane`, `direction: down`, and `duplicate_cleanup: close_only_new_sidecar_pane`. A normal coordinator invocation must resolve the exact coordinator pane, split a no-focus horizontal sidecar pane beneath it, and launch the same script there with explicit `--sidecar`; `--sidecar` is the recursion guard and the normal path must not run the polling loop in the coordinator pane. The sidecar acquires one local ephemeral lock derived from the explicit root and holds it for its lifetime, including context rotation. A duplicate launch must never prompt or restart the coordinator; after creating its own sidecar pane, it closes only that new pane and exits, never the shared coordinator tab. The sidecar must read-only verify the explicit root's compact `metadata.coordinator_continuity` contract, derive its decision id, retry bound, polling interval, mode, and requires/stops/prohibits fields, then read-only verify that the referenced decision is closed, approved, and generically matches that contract before any coordinator prompt. Invoke `./coordinator-continuation.sh --root <root-id> --coordinator <exact-agent-or-pane>` and use `--max-retries <value>` only for an override within the root bound. It must continuously log root/coordinator state and retry count, wait while the coordinator is working, and re-prompt only `idle` or `done` coordinator states while the root is executing with active attempts. If `context_rotation.enabled` is true, parse only the final rendered Pi context footer, not quoted scrollback; missing or ambiguous context stops safely. At or above the root threshold, consume the same retry budget, send `ctrl+c` and then `ctrl+d` only to the exact coordinator target, wait until its pane reports no agent, release that exact prior lifecycle registration, start fresh Pi in that exact pane with the root-configured provider/model/thinking, and prompt it to load this skill and resume the explicit root id. It stops on missing or ambiguous state, a disabled or invalid contract/decision, a blocked or closed root, no active attempts, transport failure, or maximum retries. It cannot mutate Beads, route workers, touch workers, integration, or acceptance; this remains the narrow bounded coordinator-only transport exception and never replaces the coordinator.

Stale run markers or historical active-session labels have no authority. Reconcile and replace current metadata without takeover approval; keep notes immutable. Active projections remain at most 1024 bytes; local-only transitions set sync pending.

Before the final completion decision, perform a mandatory active-worker pre-final check: read the root recovery projection and every active attempt/slice projection, then verify no active attempt is left without complete evidence or an explicit durable next action. For example, if the root is executing and one worker has settled but its evidence is absent, the coordinator must persist the evidence request, steer that exact worker, and wait; returning only “worker is idle” fails the gate. If any active attempt remains, keep the root executing and repeat the coordination cycle. Only zero active attempts plus all configured gates and synchronized Git/Beads state may pass final closure.

Completion: close at one synchronized fully passing fixed point, or remain explicitly blocked/executing with compact state sufficient for fresh recovery without conversation.

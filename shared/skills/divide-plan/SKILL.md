---
name: divide-plan
description: Divide an explicit immutable implementation plan into context-sized TDD slices and operate a recoverable Herdr execution ledger through independent test-quality and final reviews. Use when a create-plan artifact is ready for isolated implementation, verification, integration, remediation, or interrupted execution recovery inside Herdr.
metadata:
  short-description: Divide and execute plans in Herdr
allowed-tools: read,write,edit,bash
---

# Divide Plan

## Language Definitions

- **Execution ledger** — coordinator-owned recoverable directory containing execution state, divided slices, verification attempts, commits, integration records, decisions, and recovery data.
- **Coordinator** — sole execution-ledger writer and state owner; it divides work, controls agents and transitions, verifies evidence, and integrates approved commits without implementing or reviewing.
- **Slice** — fresh-context packet for one vertical behavior through explicit RED/GREEN/REFACTOR cycles.
- **Frontier** — ready slices whose blockers are integrated.
- **Fixed point** — full immutable commit hash under verification.
- **Implementation configuration** — exact command, model id, and thinking level used for slice implementation.
- **Oversight configuration** — exact command, model id, and thinking level used for test-quality review, final review, and final remediation.
- **Observation timeout** — maximum wait for the next expected Herdr evidence before the coordinator inspects and steers.

Repository glossary wording is authoritative where it overlaps. Execution ledgers, implementation plans, spec-extraction plans, teaching workspaces, and Herdr workspaces are non-interchangeable.

## Workflow

### 1. Gate Herdr and validate the source

Require `HERDR_ENV=1`; if absent, stop. No non-Herdr fallback is supported. After the gate passes, load the shared [`herdr`](../herdr/SKILL.md) skill before controlling panes or agents. Herdr owns terminal transport only; the coordinator retains task briefs, checkout isolation, execution state, evidence contracts, and acceptance.

Require one explicit absolute implementation-plan path. Do not infer a latest plan or search `/tmp`. Resolve it without mutating it, require a regular `PLAN.md` beneath `/tmp/agent-plans/<repo-id>/plans/<plan-id>/`, and compute its SHA-256. Read its identity and verify:

- the current canonical repository root and stable repository id match the plan;
- its full base and head commits exist;
- its recorded comparison and changed-spec sources are coherent;
- its absolute source path matches the supplied path; and
- it has the immutable single-agent implementation-plan structure.

Stop on any mismatch, missing fixed point, malformed source, ambiguity, or contradiction. Never automatically modify, replace, move, or delete the source plan.

Completion criterion: Herdr is available, its skill is loaded, and the explicit source path, SHA-256, repository identity, and Git fixed points are verified.

### 2. Inspect active state and settle orchestration choices

Inspect the repository-local text `.plan` before creating state. It may point only to an active execution ledger:

- If its target and ledger `PLAN.md` exist, validate their repository identity and status. Do not replace an incomplete ledger without explicit approval.
- If the target is missing, malformed, outside the expected ledger root, or not an execution ledger, report stale active-ledger state and require explicit approval before replacing the pointer. Do not search for or reconstruct a replacement.
- A complete valid ledger may be superseded without mutation; report its path before replacement.

Before writing a new ledger, inspect the source plan's steps, dependencies, test seams, commands, and concrete risks. Ask only context-relevant orchestration questions, one at a time. Record decisions for:

1. exact implementation command, model id, and thinking level;
2. exact oversight command, model id, and thinking level;
3. one observation timeout; and
4. any concrete exceptional final pass the risk evidence justifies.

Propose an exceptional pass, such as Visual, only for a specific risk and add it only after explicit user approval. Do not invent stalled-worker thresholds or other timing policies. Ask about slice granularity or dependency shape only when the source permits consequential alternatives; otherwise derive them.

If either exact configuration selects Claude Code, record that role's transport route and load [`herdr-claude-code`](../herdr-claude-code/SKILL.md) before launching it. The specialization composes base Herdr mechanics and owns Claude launch, readiness, prompt submission, and blocked-agent steering; the coordinator retains ledger state and acceptance. Non-Claude configurations continue through the base Herdr skill only.

Completion criterion: active/stale pointer handling is approved where required, both exact configurations and their base-or-Claude transport routes plus the observation timeout are known, and every exceptional pass is either approved with evidence or absent.

### 3. Create the execution ledger and divided slices

Choose an unused descriptive ledger id and create `/tmp/agent-plans/<repo-id>/ledgers/<ledger-id>/` containing `PLAN.md`, `slices/`, and `verifications/`. Before writing ledger `PLAN.md`, load and directly apply [`LEDGER-FORMAT.md`](LEDGER-FORMAT.md). The coordinator is its sole writer. Record the immutable source path and SHA-256, fixed Git points, exact configurations, observation timeout, integration topology, dependency DAG, derived frontier, slice state, acceptance, recovery, decisions, and attempts.

Divide every remaining implementation-plan step into vertical slices that each fit one fresh agent context. Before writing packets, load and directly apply [`SLICE-FORMAT.md`](SLICE-FORMAT.md). Every source-plan gap and acceptance criterion must map to at least one slice. Encode only genuine dependencies; a slice becomes frontier-ready only when every blocker is integrated. Preserve expand → bounded green migration → contract ordering for wide changes. Put explicit RED/GREEN/REFACTOR instructions in each packet because implementation agents may use an economical model.

Create a dedicated integration branch and isolated integration worktree from the source plan's head commit. Write the ledger's absolute directory path plus one newline to `.plan`, and add an exact `.plan` line to `.git/info/exclude` if absent. Do not put secrets in ledger state. Never overwrite an existing ledger id or mutate the source implementation plan.

Completion criterion: `.plan` resolves to one new execution ledger, the ledger validates against its operational format, every source-plan gap is covered by a context-sized slice, the DAG is acyclic, and the frontier equals ready slices whose blockers are integrated.

### 4. Implement and verify each frontier slice

For each frontier slice, create an isolated editable branch and worktree from the current recorded integration fixed point before using Herdr transport. Launch one implementation agent with the exact implementation configuration and authorize only the packet's scope. The agent must return a full commit hash, changed-file list, observed RED failures, GREEN/REFACTOR passes, acceptance evidence, command output, and risks. Workers never edit the execution ledger or claim acceptance.

Observe through the composed Herdr skill using the recorded observation timeout. Read current evidence before waiting for future evidence. On blocked, premature-idle, error, missing-evidence, or input-needed evidence, steer immediately. A timeout triggers immediate state/output inspection and steering; it is not proof of a stall or failure. Never infer success from idle, missing, or compacted panes.

Pin the returned commit as a fixed point. In a separate read-only agent using the oversight configuration, compose [`test-quality-verifier`](../test-quality-verifier/SKILL.md) in audit-only mode against the slice scope and fixed point. Before recording its result, load and directly apply [`VERIFICATION-FORMAT.md`](VERIFICATION-FORMAT.md). The verifier must be independent of implementation and return its structured evidence to the coordinator.

If the verifier reports findings or required evidence is missing, the coordinator records the attempt and relays the complete findings to the same implementer on the same slice branch. If that implementer cannot be resumed, set the ledger to `blocked` rather than silently substituting another agent. After a new commit, pin the new fixed point and have the verifier rerun. The coordinator may run mechanical commands and compare returned evidence, but must not implement or review. A maximum of two correction attempts is allowed after the initial implementation; then set the ledger to `blocked` with the unresolved evidence.

After a verifier pass, the coordinator runs the packet's focused commands and applicable mechanical repository gates against that exact fixed point. A failure returns through the same correction loop and requires test-quality verification at the new fixed point. Only after both independent test-quality verification and coordinator evidence gates pass may the coordinator integrate the approved commit(s).

Use mechanical cherry-pick/integration commands and record the resulting full integration commit. If integration conflicts or checks require semantic changes, abort the mechanical operation and return evidence to the same implementer through the correction loop; the coordinator does not resolve behavior by editing. Mark a slice `integrated` only after integration checks pass, then recompute the frontier from integrated blockers.

Completion criterion: every integrated slice has isolated implementation commits, append-preserved verification attempts, passing test-quality and coordinator evidence gates at the approved fixed point, and a recorded integration commit.

### 5. Review and remediate the integrated fixed point

After all slices integrate, pin the integration branch head and run all repository gates. Then launch independent oversight work, parallel where possible, against that fixed point:

- compose [`code-review`](../code-review/SKILL.md) for independent Standards and Spec axes against the source plan's fixed head and requirements;
- run a Premortem pass for cross-slice, operational, migration, recovery, concurrency, and human-use failure modes; and
- run a Security pass for trust boundaries, credentials, permissions, inputs, dependencies, network paths, and data exposure.

Use the exact oversight configuration for every pass. Run any explicitly approved exceptional pass beside these four. Record each pass and fixed point using `VERIFICATION-FORMAT.md`. Findings are evidence only; reviewers do not mutate the ledger or decide acceptance.

The coordinator collects and deduplicates all repository-gate and review findings without collapsing axis ownership. If findings remain, launch one isolated editable remediation agent using the oversight configuration, not an original slice worker. Give it the complete batch, exact fixed point, authorized scope, and evidence contract. Integrate its returned commit mechanically, pin the new fixed point, rerun repository gates, and rerun all four mandatory passes; rerun approved exceptional passes while their risk remains applicable.

Allow at most two final remediation batches. If findings remain after the second rerun, set the ledger to `blocked` and preserve all fixed points, findings, and attempts. The coordinator never performs remediation edits itself.

Completion criterion: repository gates and all four mandatory final passes, plus approved exceptional passes, pass against the same integrated fixed point, or the ledger is explicitly blocked with append-preserved evidence after two remediation batches.

### 6. Complete or recover

Before marking complete, verify every implementation-plan gap and global acceptance criterion against integrated evidence. Record the final fixed point, complete status, remaining worktrees and branches, and any limitations. Never automatically merge the integration branch into another branch, mutate or delete the source plan, or clean plans, ledgers, branches, or worktrees.

On interruption, resolve `.plan`; stop on stale state unless pointer replacement was explicitly approved. Recompute and verify the source SHA-256, reconcile recorded integration/slice branches, worktrees, and commits with Git, and record corrections before transitions. Recompute the frontier from integrated blockers and rediscover live Herdr resources through the composed skill; never trust persisted pane identity.

Completion criterion: either the ledger is complete at one fully passing fixed point and another coordinator can audit it without conversation history, or it is blocked with the exact recovery action and all prior attempts intact.

# 0004 — Recoverable agent engineering

**Status:** Accepted

**Created:** 2026-08-08

## What shipped

A solo developer can coordinate a multi-agent engineering effort without depending on one conversation, terminal pane, or coordinator process to remain alive. A human-approved objective becomes one durable execution molecule containing dependency-ordered implementation, review, remediation, and decision work. The molecule records what success and failure mean, what is excluded, which agents may perform each role, and what review depth is required.

Beads retains the durable control state in one private command repo shared across source repositories. Source repositories keep only product code and Git history; they do not acquire coordination databases or authoritative workflow documents. Herdr supplies live agent launch, communication, observation, and steering, but losing Herdr does not erase intent, progress, evidence, or the next safe action.

Each consequential agent launch or instruction is recorded before the live side effect occurs. Attempts retain their exact model assignment, durable instructions, candidate identity, checks, findings, risks, and outcome. A transport completion notification alone cannot make work complete. An implementation slice releases dependent work only after its evidence is verified, it receives independent test-quality review, and the candidate is mechanically integrated and checked again.

A fresh coordinator starts from compact current state and reconciles it with Git. It expands detailed history only when active state is missing, stale, contradictory, or incomplete. Uncertain agent launches are resumed only when they can be identified reliably; otherwise their attempt identity is retired and remaining work receives a new attempt. Historical decisions and attempts remain auditable without acting as current authority.

The developer chooses review breadth, exact model assignments, escalation options, and worker context-rotation policy before execution begins. Agent work may overlap, while durable control writes remain serialized. Local checkpoints protect recovery when the private remote is unavailable, but final completion waits for synchronization. Scope or policy changes remain explicit human decisions rather than silent coordinator adaptations.

## Why it exists

Agent-driven implementation spans planning, coding, tests, reviews, corrections, integration, and recovery. When those activities live only in prompts, panes, or Markdown notes, a crash can make it unclear whether an agent launched, which commit was reviewed, whether a finding was corrected, or what work is actually ready. Parallel activity also makes informal coordination vulnerable to duplicate launches, stale reviews, and premature dependency release.

The solo developer needs durable orchestration without introducing a distributed authority protocol. One coordinator owns structure and integration, while Beads records recoverable state and Herdr remains replaceable transport. Write-ahead attempts make uncertain side effects reconcilable, exact assignments prevent silent model changes, and fixed review policy keeps execution from weakening its own acceptance standard. Compact recovery allows a fresh coordinator to continue safely without replaying the entire project history.

## Out of scope

- Supporting multiple concurrent coordinators with distributed leases or takeover authority.
- Treating Herdr panes, agent transcripts, or conversation history as durable workflow state.
- Creating authoritative plans, ledgers, slice packets, or recovery briefs in source repositories.
- Allowing the coordinator to implement work or serve as an independent reviewer.
- Automatically changing approved scope, review breadth, model assignments, or escalation policy.
- Automatically merging into an unapproved target or deleting branches, worktrees, attempts, decisions, or historical records.
- Shipping an independent liveness monitor or autonomous worker-pane termination mechanism.

## FAQ

**Why does coordination live in one external command repo?**

One private command repo gives engineering efforts across source repositories a durable coordination authority without mixing operational state into product code. Per-repository databases and workflow Markdown were rejected because they fragment recovery and pollute source repositories with execution state.

**Revisit if:** Beads provides an equally recoverable cross-repository federation that keeps source repositories free of operational state.

**Why are Beads and Herdr assigned different responsibilities?**

Beads owns durable intent, dependencies, attempts, evidence, and recovery state. Herdr owns replaceable live transport. Treating terminal state as authoritative was rejected because panes and sessions can disappear without a trustworthy completion record.

**Revisit if:** Herdr provides durable, transactional workflow records with equivalent dependency, evidence, audit, and synchronization guarantees.

**Why is there one coordinator without a lease?**

This is a solo-developer workflow, so one coordinator process owns structure, acceptance, integration, and recovery. Distributed leases and takeover ceremonies were rejected because they add authority state without a real multi-coordinator requirement. A verified duplicate local process stops before overlapping side effects, but stale provenance does not block recovery.

**Revisit if:** Multiple coordinators must intentionally operate on the same molecule at the same time.

**Why is scope frozen before execution?**

The objective, success conditions, failure boundaries, and exclusions receive human approval before work activates. Silent scope mutation was rejected because an agent could otherwise redefine success after implementation begins. Later changes remain possible through an explicit approved decision.

**Revisit if:** The workflow adopts a different human-visible change-control mechanism that preserves both the prior contract and the approved replacement.

**Why are agent actions recorded before they happen?**

A durable attempt and consequential instruction precede each launch or material message. Post-hoc recording was rejected because coordinator failure between launch and record creation makes duplicate work and missing intent impossible to reconcile safely.

**Revisit if:** The transport and durable store support one atomic transaction covering both intent persistence and agent side effects.

**Why does only integrated work release dependencies?**

A worker’s completion claim is not enough. Candidate evidence, independent test-quality review, focused checks, integration, and post-integration checks must succeed before a blocking slice closes. Earlier release was rejected because dependent agents could build on unverified or unintegrated work.

**Revisit if:** The source-control system provides an equivalent atomic candidate-verification and integration boundary.

**Why are exact model assignments approved in advance?**

Each agent role is bound to an explicit runtime configuration, with only approved escalation alternatives. Silent substitution based on model reputation was rejected because it changes cost, capability, independence, and review assumptions without human consent.

**Revisit if:** Providers expose a stable capability contract that makes named models interchangeable for the approved role and review-independence requirements.

**Why does recovery start from compact current state rather than full history?**

The coordinator first reads the current state, next action, relevant candidate identity, review outcome, and synchronization condition, then reconciles Git. Loading all notes, attempts, transcripts, and lifecycle guidance was rejected because it increases startup cost and makes historical detail compete with current truth.

**Revisit if:** Measured recovery failures show that compact state cannot identify contradictions or select the next safe inspection reliably.

**Why is independent test-quality review required for every implementation slice?**

Tests can pass while asserting the wrong behavior or coupling themselves to implementation details. Deferring all test scrutiny until the end was rejected because weak tests can permit later slices to build on false confidence.

**Revisit if:** Automated repository gates demonstrate equivalent detection of vague, missing, or refactor-fragile behavioral assertions.

**Why are local and remote durability distinguished?**

A local checkpoint protects recovery on the current machine, while synchronization protects recovery from machine loss and enables another host. Treating a local write as remotely durable was rejected because outages can leave valid local progress absent from the private remote. Work may continue after reconciliation, but completion waits for synchronization.

**Revisit if:** The durable store provides confirmed synchronous replication for every accepted transition without harming bounded execution.

**Why is worker context rotation coordinator-owned?**

Workers report or expose context state, and the coordinator records checkpoint or wind-down intent before asking them to hand off. An independent liveness monitor with pane-termination authority was rejected because elapsed time and output volume do not prove context exhaustion or safe termination.

**Revisit if:** Agent runtimes provide a reliable transactional lifecycle API that can checkpoint, transfer, and terminate work without losing evidence.

## Open questions

None

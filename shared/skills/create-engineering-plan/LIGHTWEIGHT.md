# Lightweight Planning

Use this branch only after lightweight execution mode and shippable or exploratory delivery intent are human-approved.

## 1. Design the minimal serial graph

Create one root and at least one executable implementation work bead. Keep one bead when the effort fits one coherent direct-executor pass; add more only when separate observable outcomes or genuine ordering make recovery clearer. Encode only real blockers and keep execution serial. If the work no longer fits a bounded direct executor, stop and recommend coordinated mode rather than hiding coordination inside a large lightweight graph.

Each implementation bead records:

- one observable behavior or learning question;
- dependencies;
- completion and material failure conditions;
- likely files and focused commands;
- the approved delivery intent; and
- verification: repository-required TDD and checks for shippable work, or an exact run command and observable demonstration for exploratory work.

Do not add proposed execution traces, review or remediation beads, exact model assignments, escalation ladders, worker-attempt policy, worktrees, or continuity contracts. Record planner provenance only as actual provenance, not a future assignment.

Completion criterion: every approved completion condition maps to at least one bounded work bead, and no coordination-only topology exists.

## 2. Create and validate with ordinary Beads operations

Use the installed `bd` help and the `beads` serialization rules. Create the root and its implementation work beads with ordinary issue creation, attach them to the root, add genuine dependency edges, and record execution mode, delivery intent, scope snapshot, repository identity, source fixed point, dirty-work disposition, and direct-execution next action in current metadata.

A small lightweight graph does not use disposable schema probing, graph ingestion, an activation gate, or partial coordinated policy. Keep writes short and read each record back. Verify:

- exactly one root and the expected child count exist;
- every approved completion condition is represented;
- edge count and direction match the reviewed plan;
- `bd dep cycles` reports none;
- only the intended first serial work bead is ready; and
- the source repository contains no `.beads/` state or durable plan artifact.

If readback is lossy or readiness differs, reconcile before declaring activation. Create one semantic checkpoint after the complete graph passes readback. Push once when configured and authorized; otherwise record pending synchronization without blocking activation.

Completion criterion: the minimal graph is read-back, acyclic, locally checkpointed, and exposes exactly the expected first work bead.

## 3. Return the direct-execution handoff

Record that the caller's current agent may become the direct executor after plan approval. The handoff names the root id, source checkout, starting full commit, first work bead, verification contract, and actual planner provenance. It does not require Herdr or a fresh model assignment.

Completion criterion: `execute-engineering-molecule <root-id>` can start without reconstructing scope from conversation history.

---
name: execute-engineering-molecule
description: Execute one explicit Beads engineering molecule through its approved mode—lightweight direct execution in the caller's session or coordinated multi-agent execution through Herdr. Use when a create-engineering-plan molecule is ready for implementation, verification, integration, remediation, recovery, or exploratory learning.
metadata:
  short-description: Execute a right-sized Beads molecule
allowed-tools: read,write,bash
---

# Execute Engineering Molecule

## Language Definitions

Repository glossary wording is authoritative. Beads is durable workflow authority; Git commits identify source results; a molecule map is disposable visibility only.

## Workflow

### 1. Start from one explicit molecule

Require one root id and load [`beads`](../beads/SKILL.md) before any `bd` operation. Never infer the latest molecule. Read the compact root, active-child, frontier, repository, source fixed point, execution mode, delivery intent, and synchronization state. Reconcile those projections with Git and expand only missing, contradictory, or evidence-incomplete records.

Stop when mode is absent, scope is unapproved, graph cycles exist, repository identity differs, or another process is verifiably performing side effects for the same role. Stale provenance never blocks recovery.

Completion criterion: the explicit molecule, current Git state, frontier, approved scope, execution mode, and next action agree.

### 2. Execute the approved branch

- When the root says **lightweight**, load [LIGHTWEIGHT.md](LIGHTWEIGHT.md) because it defines direct execution, self-verification, exploration dispositions, local completion, and promotion.
- When the root says **coordinated**, require `HERDR_ENV=1`, load [COORDINATED.md](COORDINATED.md), and compose [`herdr`](../herdr/SKILL.md) only before live control; the branch defines isolated workers, write-ahead attempts, independent review, integration, and recovery.

Never emulate coordinated behavior inside lightweight mode or silently downgrade coordinated work. A mode change follows the approved promotion contract.

Completion criterion: the selected branch reaches a recorded completed, blocked, awaiting-human, or executing state with one exact next action.

### 3. Report authoritative state

Report the root id, mode, delivery intent, current/full final commit when applicable, checks or demonstration evidence, exploration disposition when applicable, frontier or blocker, local/remote sync state, and coordinated tab-cleanup result when applicable. Do not treat terminal status, an ownership label, or a generated visual as evidence.

Completion criterion: a fresh executor can identify the next safe action from Beads and Git without conversation history.

## Activities

### Refresh the molecule map

When the human requests current graph visibility, read the explicit root, its work beads, dependencies, frontier, mode, delivery intent, gates, and statuses. Compose [`visual-explainer`](../visual-explainer/SKILL.md) and write a new self-contained HTML page to its temporary default outside the repository. Label it disposable, timestamped, and non-authoritative; never parse an older map as workflow input.

Completion criterion: the map matches a single Beads read point and its absolute temporary path is reported.

## Reference

- [LIGHTWEIGHT.md](LIGHTWEIGHT.md) — load only when the explicit root's approved execution mode is lightweight; it is required for direct implementation and exploratory lifecycle handling.
- [COORDINATED.md](COORDINATED.md) — load only when the explicit root's approved execution mode is coordinated; it is required for Herdr coordination, independent verification, integration, and recovery.

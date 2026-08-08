---
name: create-engineering-plan
description: Create one human-approved Beads execution molecule, recommending lightweight direct execution for bounded or exploratory work and coordinated execution for multi-agent or policy-sensitive engineering. Use when a feature, fix, migration, refactor, or runnable exploration needs a durable implementation plan before execution.
metadata:
  short-description: Create a right-sized execution molecule
allowed-tools: read,write,bash
---

# Create Engineering Plan

## Language Definitions

Repository glossary wording is authoritative. This skill creates no durable Markdown plan and never writes `.beads/` state into a source repository.

## Workflow

### 1. Establish the planning boundary

Load [`beads`](../beads/SKILL.md) before any `bd` operation. Classify the requested delivery intent:

- **Shippable** work produces maintained behavior in code, configuration, or scripts with repository verification.
- **Exploratory** work produces a runnable learning surface with demonstration evidence and an eventual exploration disposition.

Route authoring instead of inventing implementation beads:

| Requested outcome | Owner |
|---|---|
| Write, revise, split, or semantically audit a skill | `write-a-skill` |
| Verify shared-skill frontmatter | `audit-shared-skills` |
| Capture durable intent, contracts, or requirements | `proposal-first` |
| Define or reconcile domain vocabulary | `ubiquitous-language` |
| Produce an `AGENTS.md` codebase map | `create-agents-md` |

Other prose or operational work without executable behavior has no owner here; stop and say so. For mixed work, keep only executable engineering or exploration in the molecule and name each authoring exclusion and owner.

Completion criterion: delivery intent and authoring boundaries are explicit.

### 2. Recommend and approve the execution mode

Inspect relevant code, tests, repository guidance, risks, and the likely work shape. Recommend **lightweight** by default for a bounded serial effort one direct executor can complete. Recommend **coordinated** when parallelism, broad migration, multiple integration boundaries, high risk, long-running recovery, or independent review justifies its cost.

Lightweight mode is ineligible when repository or approved-scope policy requires an independent actor, the requested execution requires concurrent agents, or repository rules require incompatible isolation or review. Other signals are advisory: explain them and allow human override. Carry the recommendation into the scope approval packet rather than forcing a separate lightweight ceremony.

Completion criterion: the recommendation, rationale, and hard-policy checks are ready for human decision.

### 3. Pin evidence and approve scope

Verify command-repo routing through `beads`, resolve the canonical source checkout and full Git `HEAD`, and inspect current changes. Unrelated dirty work must receive explicit handling before execution; never silently include it. Account for desired behavior as already satisfied, absent, or ambiguous from code and test evidence.

Present one human approval packet containing the recommended execution mode, delivery intent, rationale, and scope. Lightweight mode uses a compact scope snapshot: objective, observable completion conditions, and only material failure boundaries, exclusions, or risks. Coordinated mode uses the complete objective, acceptance criteria, failure criteria, and exclusions contract. Record any human override. Any later scope mutation requires a linked approved decision.

Completion criterion: repository identity and fixed point are recorded, every desired behavior has an evidenced disposition, and the human approved mode, delivery intent, and scope in one packet.

### 4. Materialize the selected branch

- When **lightweight** mode is approved, load [LIGHTWEIGHT.md](LIGHTWEIGHT.md) because it defines the minimal serial graph, verification contract, ordinary Beads writes, and readback gate.
- When **coordinated** mode is approved, load [COORDINATED.md](COORDINATED.md) because it defines slices, traces, review and model policy, recovery contracts, atomic ingestion, and activation.
- During coordinated planning, when dependency shape is non-obvious because work is parallel, migratory, or review fan-out is unclear, also load [WORKFLOW-SHAPES.md](WORKFLOW-SHAPES.md) for the applicable graph patterns.

Do not mix branch mechanics. A lightweight molecule does not materialize dormant coordinator, reviewer, attempt, continuity, or escalation topology.

Completion criterion: one activated, read-back execution molecule exists under exactly one approved mode.

### 5. Render visibility and report

After activation, compose [`visual-explainer`](../visual-explainer/SKILL.md) to render a **molecule map** from read-only Beads data. Write it to the visual skill's temporary default outside the source repository. Show the root, work beads, dependency direction, frontier, execution mode, delivery intent, and gates; label the page disposable and Beads authoritative.

Report the root id, mode, delivery intent, activated frontier, local/remote checkpoint state, and absolute molecule-map path.

Completion criterion: the temporary map reflects the activated readback, and the execution handoff names one explicit root id.

## Reference

- [LIGHTWEIGHT.md](LIGHTWEIGHT.md) — load only after lightweight mode is approved; it is required to compile and activate the minimal direct-execution molecule.
- [COORDINATED.md](COORDINATED.md) — load only after coordinated mode is approved; it is required to compile and activate the recoverable multi-agent graph.
- [WORKFLOW-SHAPES.md](WORKFLOW-SHAPES.md) — load only when an approved coordinated graph has non-obvious parallel, migration, or review topology; it prevents false dependency edges.

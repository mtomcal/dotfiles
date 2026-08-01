# Skill Library Specification

> **Version**: 6.0.0
> **Last Updated**: 2026-08-01
> **Depends On**: [Parameters](parameters.md), [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md), [Herdr Config](herdr-config.md), [Execution Coordination](execution-coordination.md)
> **Depended By**: AI Agent Configuration (AIAGT)
> **Prefix**: SKILL

---

## Overview

The Skill Library is the canonical collection of reusable workflows shared by supported AI coding agents. It owns skill discovery metadata, skill-body semantics, progressive disclosure, composition boundaries, workflow-state ownership, provenance, and semantic quality. It does not own agent installation, runtime configuration, or catalog deployment.

The system MUST ensure that:

1. Every shared skill has portable discovery metadata and one canonical source.
2. A skill body presents the smallest complete set of universally required instructions.
3. Additional context is disclosed only after a concrete branch outcome makes it necessary.
4. Workflow composition imports another skill's process without silently transferring caller ownership.
5. Material revisions preserve required behavior or identify an approved replacement owner.
6. Semantic YAGNI removes unnecessary content rather than hiding it in auxiliary files.

---

## Dependencies

| Dependency | Required For |
|------------|--------------|
| [Parameters](parameters.md) | Catalog paths, naming, discovery limits, Reference depth, and canonical section order |
| [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md) | Canonical Skill Library, Reference, workflow-artifact, and ownership terminology |
| [Herdr Config](herdr-config.md) | Herdr delegation terminology, runtime identity, and integration boundaries |
| [Execution Coordination](execution-coordination.md) | Command-repo execution molecules, Beads ownership, model/review policy, attempts, synchronization, and recovery |
| Repository provenance notice | Source, revision, license, and attribution for imported skill material |

The Skill Library supplies canonical skill definitions to [AI Agent Configuration](ai-agent-config.md), which exposes them to supported agents. [Symlink Manager](symlink-manager.md) owns the deployment mechanism.

---

## Parameters

All Skill Library parameters are authoritative in [Parameters > Skill Library](parameters.md#skill-library).

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `SKILL_CATALOG_ROOT` | `~/dotfiles/shared/skills` | One repository-owned source for cross-agent skill definitions |
| `SKILL_ENTRY_FILE` | `SKILL.md` | Portable discovery and invoked skill body |
| `SKILL_DIRECTORY_PATTERN` | lowercase-hyphenated | Stable cross-agent naming |
| `SKILL_DESCRIPTION_MAX_CHARS` | 1024 | Maximum supported portable discovery description |
| `SKILL_DESCRIPTION_TRIGGER_PHRASE` | `Use when` | Makes invocation triggers explicit |
| `SKILL_REFERENCE_MAX_DEPTH` | 1 | Prevents nested context chains and avoidable hill climbing |
| `SKILL_BODY_SECTION_ORDER` | Language Definitions, Workflow, Activities, Reference | Gives each section one stable semantic role |

---

## Data Structures

### Shared Skill

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| directory | path | Required; lowercase and hyphenated | Canonical directory beneath the catalog root |
| entry file | Markdown | Required; named `SKILL.md` | Frontmatter and invoked skill body |
| auxiliary files | list | Optional; local to the skill | Branch-specific Reference files or operational assets |
| provenance | record | Required for imported material | Source, revision, license, and attribution location |

### Union Frontmatter

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| name | string | Required; non-empty | Portable skill identifier |
| description | string | Required; at most 1024 characters; contains `Use when` | Behavior and concrete invocation triggers |
| metadata.short-description | string | Required; non-empty | Short human-facing label |
| allowed-tools | list or string | Required; least privilege | Tools needed by the workflow |
| agent-specific fields | value | Optional | Additional supported-harness metadata that does not replace required fields |

### Skill Body Section

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| name | enum | Language Definitions, Workflow, Activities, Reference | Semantic section identity |
| required | boolean | Language Definitions only | Whether every applicable skill body includes the section |
| cardinality | integer | At most one of each section | Prevents competing primary processes or duplicate indexes |
| content | Markdown | Must satisfy section semantics | Executable instructions or conditional pointers |

### Reference Pointer

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| target | context document location | Required; a local Reference file resolves one level from the skill body | Branch-specific additional context |
| branch condition | statement | Required; concrete and observable | Outcome that makes the target necessary |
| purpose | statement | Required | Why the selected branch needs the target |
| obligation | enum | Required when selected | Loading is mandatory after the branch condition becomes true |
| no-load route | supported route | At least one successful route | Successful execution that does not load the target |

### Behavior-Preservation Ledger

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| behavior | statement | Required | Trigger, branch, gate, failure, guardrail, output, ownership rule, or completion condition |
| previous owner | location | Required | Pre-restructure source of the behavior |
| retained owner | location | Required unless replacement approved | Resulting source of truth |
| replacement approval | evidence | Required when ownership changes | Human-approved replacement owner |

### Execution Workflow Skill Contract

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| creation entry | skill | `create-plan` | Creates one execution-ready Beads molecule directly from approved scope |
| execution entry | skill | `execute-molecule` | Coordinates one explicit molecule through Herdr and Beads |
| durable authority | bounded context | Execution Coordination | Owns command-repo graph, assignments, attempts, evidence, synchronization, and recovery |
| source | repository identity | Normalized remote or explicit key plus full fixed commit | Reproducible source baseline without a mandatory spec diff |
| scope | scope snapshot | Explicit human approval | Objective, acceptance, failure, and exclusions are frozen after creation |
| work | Beads graph | Context-sized slices and review/remediation beads | Blocking dependencies derive the frontier |
| traces | evidence-grounded call trees | Applicable trace lives on each slice bead | Intended order, not captured runtime evidence |
| live transport | composed skill | Herdr required for agent operations | Herdr state is ephemeral and never durable authority |
| compatibility | existing legacy execution ledger only | No new filesystem artifacts | Grandfathered work may reach a terminal state before retired support is removed |

---

## Behavior

### Catalog and Discovery

1. Shared skills MUST have one canonical definition beneath the catalog root.
2. Every shared skill MUST satisfy the Union Frontmatter schema.
3. Descriptions MUST state concrete invocation triggers without duplicate synonyms that increase catalog context load.
4. `allowed-tools` MUST grant only tools used by reachable behavior.
5. Agent-specific metadata MAY refine behavior for a supported harness but MUST NOT replace portable discovery fields.

### Skill-Body Contract

A newly added or materially modified skill body MUST use these sections in canonical order:

1. `Language Definitions` is mandatory and contains only execution-relevant skill-local terms, or the exact statement “No skill-specific terms.”
2. `Workflow` is optional and contains at most one primary end-to-end process, with routing or mode selection before dependent steps.
3. `Activities` is optional and contains independently reusable commands, actions, or recipes selected outside the primary sequence; it MUST NOT restate ordinary Workflow steps.
4. `Reference` is optional and contains only Reference pointers.

A skill MUST omit optional sections it does not need. Guardrails, failure handling, approvals, compact output contracts, and completion criteria MUST remain beside the Workflow step or Activity they govern.

### Core Instructions and Semantic YAGNI

1. Universally required behavior MUST remain as compact core instructions in `SKILL.md`.
2. Mandatory detail MUST be as concise and direct as possible without weakening behavior, safety, ownership, or completion evidence.
3. Content MUST be retained when it changes invocation, routing, workflow correctness, reusable Activity execution, guardrails, failure handling, output contracts, ownership, or required repository behavior.
4. Duplication, stale sediment, speculative detail, and instructions that do not change likely behavior MUST be removed rather than relocated.
5. Fixed line limits MUST NOT be used as the YAGNI standard; size is evidence, not the decision rule.
6. A Reference file MUST satisfy the same semantic YAGNI standard as the skill body.

When universally required material remains too bulky, apply this order:

1. compact the behavioral contract in the skill body;
2. represent deterministic repeated operations as an executable script or operational template when interpretation is unnecessary;
3. create or compose another skill only when the workflow has an independently useful invocation and ownership boundary; or
4. remove detail that does not earn retention.

### Branch-Based Progressive Disclosure

A Reference pointer is valid only when all conditions below hold:

1. A concrete branch outcome selects it, such as a chosen mode, requested detail, detected failure, missing evidence, need for an example, or applicable external integration.
2. At least one successful, supported execution route does not load its target.
3. Once the branch condition becomes true, the target MUST be loaded.
4. The skill body contains enough compact information to select the branch correctly before loading the target.
5. The target contains only detail necessary for the selected branch.

A workflow stage reached by every successful route is not a branch outcome. Cancellation, denied approval, missing prerequisites, and premature failure do not count as successful no-load routes.

The Reference section MUST NOT act as a miscellaneous link collection:

| Target | Required Placement |
|--------|--------------------|
| Branch-specific supporting Markdown | Reference section |
| Script that is executed or installed | Governing Workflow step or Activity |
| Template that is copied or directly applied | Governing Workflow step or Activity |
| Another skill whose process is invoked | Governing routing branch, Workflow step, or Activity |
| External documentation | Reference section only when a concrete branch requires it as additional context |
| Universally required behavioral detail | Compact core instruction in the skill body |

A Reference file MAY support multiple branch outcomes when every pointer satisfies the contract. Reference files MUST NOT require a second Reference traversal to reconstruct their instructions.

### Revision and Behavior Preservation

Before materially restructuring a skill body, the author MUST create a behavior-preservation ledger. Every recorded behavior MUST remain in the candidate or name an explicitly approved replacement owner.

A revision is complete only when:

1. all branches remain reachable;
2. each Workflow step and Activity has an observable finish;
3. all modified files are accounted for;
4. Reference pointers satisfy branch-based progressive disclosure;
5. provenance remains valid; and
6. frontmatter and semantic reviews pass under their distinct owners.

### Catalog Ownership and Composition

1. `write-a-skill` owns skill-body authoring, progressive disclosure, split decisions, Reference semantics, and semantic YAGNI review.
2. `audit-shared-skills` owns executable validation of Union Frontmatter only; it MUST NOT claim semantic review.
3. A composed skill imports a process, not ownership. The caller retains artifact location, user gates, workflow state, acceptance authority, and return criteria unless an approved contract names a replacement owner.
4. Terminal transport skills own terminal mechanics. Their callers retain task briefs, checkout decisions, workflow state, returned-evidence contracts, in-process fallbacks, and acceptance.
5. Checkout isolation MUST be selected before terminal transport. Read-only delegates MAY share a checkout; editable delegates MUST use isolated checkouts; separate panes alone are not isolation.
6. Generic Standards and Spec review remain owned by `code-review`.
7. Visual work MUST preserve capture, optional recording conversion, evidence limitations, and caller or human acceptance. Capture and conversion workflows MUST return evidence directly without claiming final acceptance.
8. Templates, output contracts, ranking models, and checklists remain owned by their domain producer rather than a universal schema.
9. When a workflow delegates through Herdr, it MUST compose the shared Herdr skill instead of duplicating terminal commands. It MUST retain an in-process fallback outside Herdr unless its protected contract declares Herdr a hard precondition; a hard-precondition workflow MUST stop outside Herdr rather than provide a reduced fallback.
10. Public Herdr IDs MUST be refreshed after topology changes; neither public IDs nor legacy display selectors may become durable workflow identity.
11. An agent-specific Herdr skill MUST compose the generic Herdr skill for CLI transport, current IDs, validated agent primitives, output inspection, server-owned settled-state waiting, and cleanup. It MAY own only agent-specific launch arguments, readiness interpretation, task contract, interaction, and steering behavior.

### Workflow Artifact and State Ownership

Execution molecules, slice beads, worker attempts, spec-extraction plans, teaching state, and generated artifacts are non-interchangeable. Each workflow MUST use qualified artifact names and preserve its own writer, lifecycle, approval gates, and state transitions.

Reciprocal routing MAY compose workflows but MUST NOT transfer state or artifact ownership implicitly.

### Protected Workflow Contracts

| Skill | Required Behavior |
|-------|-------------------|
| `codebase-design` | Owns deep-module vocabulary and conditionally disclosed deepening and alternative-interface guidance |
| `diagnosing-bugs` | Establishes a tight red-capable command, minimizes reproduction, tests ranked hypotheses, and routes fixes through TDD |
| `code-review` | Keeps Standards and Spec reviews independent, with available delegation or an in-process fallback |
| `resolving-merge-conflicts` | Traces both intents, stages verified resolutions, and leaves commit or continue operations to explicit approval |
| `handoff` | Writes redacted timestamped Markdown under the operating system's temporary handoff directory and reports its absolute path |
| `research` | Produces durable primary-source-backed notes using the repository convention or an approved location |
| `improve-codebase-architecture` | Produces a temporary visual HTML report with before-and-after diagrams and candidate comparison |
| `herdr` | Owns current generic Herdr CLI mechanics, including validated agent startup, atomic prompt submission, logical keys, output inspection, server-owned settled-state waiting, and failure inspection |
| `herdr-claude-code` | Composes `herdr` and owns Claude's required native launch argument, task contract, settled-result interpretation, and blocked-agent steering without duplicating generic transport |
| `create-plan` | Pins a source fixed point, obtains a human-approved scope snapshot, proposes review/model policy, and creates one execution-ready command-repo molecule with context-sized TDD slices and traces |
| `execute-molecule` | Requires one explicit execution-molecule id and Herdr, then coordinates Beads-backed leases, write-ahead attempts, isolated implementation, evidence-gated integration, configured reviews, synchronization, and crash recovery |
| `teach` | Requires an approved teaching workspace and preserves mission, resources, learning records, lessons, references, assets, and notes |
| `grill-me` | Grounds terminology and evidence, probes consequential branches one question at a time, and defers durable edits until shared understanding |

### Specialized State Contracts

`create-plan` MUST resolve one normalized repository identity and full source fixed point, but MUST NOT require a specification diff. It reads available specs, code, tests, documentation, and risks as evidence, then obtains explicit human approval of objective, acceptance criteria, failure criteria, and exclusions. That scope snapshot becomes frozen; later changes require an approved decision bead.

The caller's current exact model configuration is planner provenance. Before activation, `create-plan` MUST propose and obtain human approval for one review preset with overrides, exact role defaults and per-bead overrides, reviewer independence, exact coordinator assignment, escalation ladders, correction allowances, and critical-invariant triggers. Initial model assignments are exact and unavailable assignments block rather than silently substitute.

Its only durable result is one execution-ready molecule in the external command repo. It directly creates context-sized vertical slices with explicit RED/GREEN/REFACTOR cycles, genuine dependency edges, public test seams, acceptance/failure criteria, focused commands, and applicable proposed execution traces. A trace remains an evidence-grounded intended call tree with binding order distinguished from permitted internal variance; it is not captured runtime evidence or an exhaustive graph.

Creation MUST leave a partial graph draft/blocked, validate complete scope coverage, acyclicity, assignments, traces, and review topology before exposing ready work, then commit and push a semantic checkpoint. It MUST NOT write `PLAN.md`, `.plan`, slice files, verification files, or any `.beads/` state into a source repository.

The generic `herdr` skill MUST use Herdr's current agent facade for validated startup, atomic prompt submission, logical key input, agent reads, and settled-state waiting. Prompt-and-wait MUST use one server-owned operation when submitting new work. Waiting on an already-running agent MUST use the server-owned default settled-state set of `done`, `idle`, and `blocked`, including an already-reported matching state. `done` and `idle` are completion candidates; `blocked` is an immediate steering state. Any failed wait, timeout, stalled prompt, or `unknown` result MUST lead to current agent state and output inspection before retry or failure reporting. Ordinary command output waiting MUST use the pane facade.

`herdr-claude-code` MUST compose `herdr` and launch Claude through validated agent startup with the native `--dangerously-skip-permissions` argument. Task submission and waiting MUST use the base atomic prompt operation, which owns bracketed-paste handling and encoded Enter. Blind prompt resends or manual repeated Enter presses after a failed submission are prohibited until current agent state and output have been inspected. Blocked Claude agents MUST be inspected and steered through a new atomic prompt before observation resumes.

`execute-molecule` MUST require one explicit execution-molecule id, valid global command-repo routing, and `HERDR_ENV=1`; there is no non-Herdr execution fallback. It validates repository identity, source fixed point, scope approval, review/model policy, graph integrity, and synchronization before mutation. The exact assigned coordinator model must acquire the non-expiring coordinator lease; conflicting authority stops unless evidence inspection and human-approved takeover create a new coordinator-session bead.

The skill composes shared `herdr` for every launch, message, observation, and steering action while Beads remains durable authority. Claude Code assignments route through `herdr-claude-code`; other assignments use generic Herdr transport. Every consequential side effect first creates/checkpoints a unique planned worker attempt and durable instruction. Workers and reviewers write fixed-point evidence to that attempt before Herdr completion notification. Attempts are permanent non-blocking operational nodes and never pollute `bd ready`.

The coordinator MAY run mechanical commands but MUST NOT implement or independently review. Editable slices and remediation use isolated worktrees and branches. A slice closes only after an implementation commit, independent `test-quality-verifier` audit, coordinator mechanical gates, mechanical integration, and post-integration checks. Correction behavior and automatic model escalation follow the slice's approved allowance, critical trigger, and molecule-specific exact escalation ladder; unavailable initial assignments and exhausted ladders block.

Final work follows the approved Lean, Standard, or High-assurance review graph. Repository gates and independent Scope fidelity are always final requirements; integrated Test Quality, Standards, Premortem, Security, risk gates, redundant passes, exact reviewer models, and provider diversity follow the approved policy. Reviewers report findings without editing. Consolidated remediation uses its exact role assignment and ladder; affected gates rerun after changes and unaffected passing gates retain rationale.

A fresh coordinator MUST recover from Beads without conversation or Herdr history, then use Herdr to rediscover sessions by durable attempt token. Unmatched uncertain attempts become lost and replacement work receives a new attempt id. Remote outages permit only leased-host work with `sync:pending`; takeover and completion wait for successful synchronization. Neither command-repo records, branches, worktrees, nor attempts are cleaned automatically.

The retired `divide-plan` contract MAY remain temporarily available only to finish the single legacy execution ledger already active at adoption. It MUST create no new filesystem plan or ledger, and it is removed after that ledger becomes terminal.

The teaching workflow MUST obtain approval for a dedicated workspace before scaffolding. It MUST ground lessons in an agreed mission, use primary-source research, maintain durable resources and demonstrated-learning records, prefer reusable lesson assets, and distinguish knowledge acquisition, skill practice, and wisdom from real-world interaction. Interactive codebase lessons SHOULD compose `create-explainer` without weakening teaching-workspace ownership or citation requirements.

### Provenance

Imported skill material MUST be treated as a locally maintained fork. Before imported material is moved or rewritten, its source, revision, and license MUST be identified. Required attribution and license notices MUST live in the repository-level provenance notice. Automatic upstream synchronization is outside the Skill Library contract.

---

## Error Handling

| Error Case | Trigger | Detection | Response | Recovery |
|------------|---------|-----------|----------|----------|
| Invalid frontmatter | A required field is missing, empty, or malformed | Union-frontmatter audit | Report an error for the exact skill and field; do not claim catalog compatibility | Correct the field and rerun the complete audit |
| Discovery portability risk | Description exceeds 1024 characters or omits the exact `Use when` phrase | Union-frontmatter audit | Report a warning for the exact skill and condition | Compact the description or add concrete triggers, then rerun the complete audit |
| Unused tool grant | `allowed-tools` includes a tool with no reachable use | Frontmatter audit plus workflow inspection | Report a least-privilege warning | Remove the grant or document reachable use |
| Universal Reference | Every successful route loads the same Reference target | Semantic branch review | Reject the pointer as progressive disclosure | Inline and compact the behavior, use an operational asset, split an independent workflow, or prune it |
| Optional selected Reference | A true branch condition leaves required context optional | Compare pointer wording with branch contract | Reject the pointer | Make loading mandatory after selection |
| False no-load route | Only cancellation, failure, or denied approval avoids loading | Route analysis | Reject the claimed branch split | Identify a successful no-load route or remove the Reference split |
| Misplaced link | Reference section points to an executable asset or composed workflow | Target classification | Reject the section placement | Move the pointer beside its governing Workflow step or Activity |
| Nested Reference chain | A Reference file requires another support traversal | Link-depth review | Reject the chain | Flatten selected detail into one branch file or deepen the owning module elsewhere |
| Behavior loss | Material revision lacks retained or approved replacement ownership | Behavior-preservation review | Stop the restructure | Restore behavior or obtain replacement-owner approval |
| Provenance gap | Imported material lacks source, revision, license, or attribution | Provenance review | Stop movement or rewriting | Complete the repository provenance record |
| Composition ownership leak | Callee implicitly takes caller state, gates, or acceptance | Contract review | Reject the composition | Restore caller ownership or approve an explicit replacement contract |
| Invalid molecule source | Repository identity, fixed point, approved scope, graph, or assignment map does not match | Execution preflight | Stop before lease mutation or agent launch | Reconcile the explicit molecule and source checkout |
| Coordinator-lease conflict | A nonterminal coordinator session owns the lease | Beads lease inspection | Stop and preserve current authority | Resume it or perform evidence-based human-approved takeover |
| Correction or escalation exhausted | Slice exceeds its approved allowance or has no higher available ladder rung | Attempt graph inspection | Block the owning work bead | Approve a decision changing policy or assignment |
| Remote synchronization pending | Private remote cannot reconcile/push | Semantic checkpoint | Permit leased-host local work but block takeover and completion | Restore remote, reconcile, and push |
| Missing durable worker evidence | Herdr reports completion but attempt evidence is incomplete | Attempt validation | Do not verify, integrate, or close | Request evidence through a write-ahead instruction or mark attempt failed |
| Agent settled-state wait fails | The server-owned agent wait times out, returns `unknown`, or otherwise fails | Base Herdr wait result plus current agent inspection | Inspect current agent state and output; do not infer completion or failure | Retry only from inspected evidence or report the limitation |
| Agent prompt stalls | Atomic prompt submission observes no lifecycle change within the startup window | Herdr returns the stalled-prompt error | Inspect agent state and output; do not resend or add manual Enter blindly | Retry only when inspection shows a safe, non-duplicating submission path |

---

## Implementation Notes

- Keep the catalog discoverable from one entry file per skill.
- Prefer semantic review for Reference validity; textual checks alone cannot prove a successful no-load route.
- Keep frontmatter validation and semantic body review as separate passes with separate owners.
- Avoid duplicating deployment topology here; agent exposure belongs to AI Agent Configuration and symlink behavior belongs to Symlink Manager.
- Avoid a hardcoded catalog count because skills may be added or removed while the catalog contract remains stable.
- Use qualified workflow-artifact names in skill bodies, specs, and reviews.

---

## Test Scenarios

### TS-SKILL-001: Union Frontmatter Compatibility

Category: Integration
Priority: High
Preconditions: The shared catalog contains one or more skills.
Input: Parse every skill entry file and validate the Union Frontmatter schema.
Expected Output: Every skill is accounted for; missing required fields are errors, and portability or least-privilege risks are warnings.

### TS-SKILL-002: Canonical Skill Body

Category: Integration
Priority: High
Preconditions: A new or materially modified skill body is available.
Input: Inspect its section order, section cardinality, local guardrails, outputs, and completion criteria.
Expected Output: Language Definitions is present; optional sections occur once in canonical order; universally required behavior remains compact and local.

### TS-SKILL-003: Valid Reference Branch

Category: Integration
Priority: Critical
Preconditions: A skill contains a Reference pointer.
Input: Trace the pointer's branch condition, selected obligation, target content, and all successful supported routes.
Expected Output: The target is mandatory after selection, at least one successful route avoids loading it, and the target contains only necessary branch-specific detail.

### TS-SKILL-004: Universal Reference Rejection

Category: Integration
Priority: Critical
Preconditions: An auxiliary context file is loaded by every successful execution route.
Input: Evaluate the file as a proposed Reference file.
Expected Output: The split is rejected; reaching a universal stage, cancellation, failure, or denied approval does not satisfy progressive disclosure.

### TS-SKILL-005: Reference Target Placement

Category: Integration
Priority: High
Preconditions: A skill links supporting Markdown, a script, a directly applied template, another skill, or external documentation.
Input: Classify each target and inspect pointer placement.
Expected Output: Only conditionally selected supporting context appears in Reference; executable assets and composed skills appear beside their governing behavior.

### TS-SKILL-006: Behavior Preservation

Category: Integration
Priority: Critical
Preconditions: A skill body is proposed for material restructuring.
Input: Compare the previous behavior with the behavior-preservation ledger and candidate.
Expected Output: Every trigger, branch, gate, failure, guardrail, output, ownership rule, and completion condition remains or has an approved replacement owner.

### TS-SKILL-007: Composition and State Ownership

Category: Integration
Priority: Critical
Preconditions: A skill composes another workflow or delegates through terminal transport.
Input: Inspect artifact names, writers, gates, checkout topology, returned evidence, and acceptance ownership.
Expected Output: The caller retains ownership unless explicitly replaced; editable delegates use isolated checkouts; workflow artifacts remain qualified and non-interchangeable.

### TS-SKILL-008: Imported Skill Provenance

Category: Integration
Priority: High
Preconditions: Imported skill material is proposed for movement or revision.
Input: Inspect source, revision, license, and repository-level attribution.
Expected Output: Provenance is complete before the material changes, and the catalog treats the import as a locally maintained fork.

### TS-SKILL-009: Semantic YAGNI

Category: Integration
Priority: High
Preconditions: A new or revised skill and all auxiliary files are available.
Input: Review each instruction for behavioral value, duplication, sediment, speculation, and unnecessary navigation.
Expected Output: Required behavior remains concise; unnecessary content is removed rather than displaced; no fixed line limit substitutes for semantic review.

### TS-SKILL-010: Execution-Molecule Creation

Category: Integration
Priority: Critical
Preconditions: A source fixed point exists and command-repo routing is valid.
Input: Run `create-plan`, approve scope, review preset/overrides, exact assignments, and escalation ladders.
Expected Output: One ready Beads molecule contains context-sized TDD slices, dependencies, traces, review/remediation topology, and exact per-bead assignments; no spec diff or durable Markdown workflow artifact is required.

### TS-SKILL-011: Recoverable Herdr Molecule Execution

Category: End-to-End
Priority: Critical
Preconditions: A valid molecule exists and execution runs inside Herdr.
Input: Run `execute-molecule`, kill the coordinator after a write-ahead attempt, destroy Herdr state, start fresh Herdr, and boot the assigned coordinator.
Expected Output: The coordinator reconstructs the safe next transition from Beads, reconciles the lost attempt, creates a new attempt id, and resumes through integration and configured reviews without a persisted pane id.

### TS-SKILL-012: Lease, Model, and Synchronization Gates

Category: Integration
Priority: Critical
Preconditions: Molecule execution and failure paths can be exercised.
Input: Attempt execution outside Herdr, use an unassigned coordinator model, take over without approval, exhaust a ladder, and complete with `sync:pending`.
Expected Output: Every attempt stops at its owning gate; no model is silently substituted, no lease expires automatically, and evidence remains in Beads.

### TS-SKILL-013: Server-Owned Herdr Settled-State Wait

Category: Integration
Priority: Critical
Preconditions: A detected agent can transition to `done`, `idle`, or `blocked`.
Input: Invoke the base Herdr coordination Activity from working state and separately from each already-settled state.
Expected Output: One server-owned wait observes the first matching settled state or returns an existing match immediately; output is inspected after the result; timeout, failure, or `unknown` triggers current state and output inspection.

### TS-SKILL-014: Claude Code Herdr Orchestration

Category: End-to-End
Priority: High
Preconditions: Claude Code and Herdr are available and an authorized checkout is selected.
Input: Launch the Claude Code Herdr workflow, atomically submit a prompt, and exercise completion, blocking, and stalled-submission states.
Expected Output: Validated startup runs Claude with `--dangerously-skip-permissions`; atomic prompt submission handles text and Enter; settled-state waiting observes completion or blocking; blocked output is inspected and steered; stalled submission is inspected without blind resubmission.

### TS-SKILL-015: Slice Traces and Configurable Review Graph

Category: Integration
Priority: Critical
Preconditions: A non-empty execution molecule is available.
Input: Inspect slice traces and create Lean, Standard, and High-assurance review policies with an override.
Expected Output: Every applicable slice carries an evidence-grounded intended trace that distinguishes binding order and permitted variance; Lean preserves the mandatory floor, Standard adds the full standard set, High assurance adds approved risk gates/redundant passes, and exact independent assignments are materialized on review beads.

---

## Changelog

| Version | Date | Change |
|---------|------|--------|
| 6.0.0 | 2026-08-01 | Replaced filesystem create/divide execution with command-repo execution molecules, exact per-bead model and review policy, `execute-molecule`, write-ahead attempts, coordinator leases, and Beads-first crash recovery. |
| 5.0.0 | 2026-08-01 | Replaced client-owned Herdr status races and manual Claude submission with Herdr 0.7.5's validated startup, atomic prompt, and server-owned settled-state facade. |
| 4.0.0 | 2026-07-15 | Required a proposed execution trace per ordered step and binding final review gates in every non-empty implementation plan (mode-neutral, results excluded); required slices to retain source traces with a slice-scope frame mapping; added a final integrated Test Quality pass, risk-triggered gates, and impact-scoped review reruns to divide-plan. |
| 3.1.0 | 2026-07-15 | Added executable concurrent Herdr terminal-state waiting and a composing Claude Code orchestration specialization with divide-plan routing. |
| 3.0.0 | 2026-07-15 | Split immutable single-agent implementation planning from Herdr-only execution ledgers, established coordinator ownership, test-quality integration gates, and bounded final review remediation. |
| 2.0.0 | 2026-07-15 | Removed retired workflow contracts and made surviving visual evidence return directly to the caller or human. |
| 1.0.0 | 2026-07-14 | Established the Skill Library bounded context, including portable discovery, canonical skill bodies, branch-based Reference semantics, semantic YAGNI, composition, state ownership, provenance, and verification contracts. |

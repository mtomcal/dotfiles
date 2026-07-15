# Skill Library Specification

> **Version**: 3.1.0
> **Last Updated**: 2026-07-15
> **Depends On**: [Parameters](parameters.md), [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md), [Herdr Config](herdr-config.md)
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

### Implementation Plan

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| path | absolute path | `/tmp/agent-plans/<repo-id>/plans/<plan-id>/PLAN.md` | Sole artifact produced by `create-plan` |
| source comparison | fixed Git comparison | Two full commit hashes | Changed specs establish scope; desired behavior and current code/tests are read at the fixed head |
| contents | technical plan | Immutable; sequential; single-agent | Objective, sources, gaps, vertical steps, dependencies, criteria, test seams, files, commands, risks, assumptions, and exclusions |
| source digest | SHA-256 | Required | Pins the exact immutable artifact for execution |

### Execution Ledger

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| path | absolute directory | `/tmp/agent-plans/<repo-id>/ledgers/<ledger-id>/` | Recoverable execution state owned by `divide-plan` |
| source | implementation-plan identity | Absolute path, SHA-256, repository identity, and full Git points | Blocks execution when any identity check fails |
| contents | file set | `PLAN.md`, `slices/`, `verifications/` | State, dependencies, attempts, commits, integration, decisions, and recovery evidence |
| writer | actor | Exactly one coordinator | Agents return commits, findings, or evidence without mutating ledger state |
| active pointer | repository-local text file | `.plan` contains one absolute ledger path | Incomplete active state is not replaced without explicit approval |

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
11. An agent-specific Herdr skill MUST compose the generic Herdr skill for CLI transport, current IDs, input primitives, output inspection, status races, and cleanup. It MAY own only agent-specific launch, readiness, submission, interaction, and steering behavior.

### Workflow Artifact and State Ownership

Implementation plans, execution-ledger slices, spec-extraction plans, teaching state, and generated artifacts are non-interchangeable. Each workflow MUST use qualified artifact names and preserve its own writer, lifecycle, approval gates, and state transitions.

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
| `herdr` | Owns generic Herdr CLI mechanics, including a safe executable race that prechecks and concurrently observes `done`, `idle`, and `blocked`, cancels remaining waits, and inspects output |
| `herdr-claude-code` | Composes `herdr` and owns exact Claude launch, readiness, explicit prompt submission, completion observation, and blocked-agent steering without duplicating generic transport |
| `create-plan` | Pins a fixed spec diff and writes one immutable single-agent implementation plan containing only remaining current-state gaps and no execution state |
| `divide-plan` | Requires an explicit implementation-plan path and Herdr, then owns coordinator-controlled execution ledgers, context-sized TDD slices, isolated implementation, evidence-gated integration, final review, and recovery |
| `teach` | Requires an approved teaching workspace and preserves mission, resources, learning records, lessons, references, assets, and notes |
| `grill-me` | Grounds terminology and evidence, probes consequential branches one question at a time, and defers durable edits until shared understanding |

### Specialized State Contracts

`create-plan` MUST require one fixed two-endpoint spec comparison. “Last X commits” MUST mean `HEAD~X..HEAD`, and both endpoints MUST be resolved to full hashes. Changed specs establish scope; specs at the fixed head define desired behavior; code and tests at that same head establish current-state gaps. Already-satisfied requirements MUST be retained as evidence and excluded from implementation work. Ambiguity or contradiction MUST stop planning.

Its only artifact MUST be `/tmp/agent-plans/<repo-id>/plans/<plan-id>/PLAN.md`. The implementation plan MUST be immutable and sequentially executable by one agent. It MUST include objective, sources, current-state gaps, ordered vertical steps, dependencies, acceptance and failure criteria, public test seams, likely files, commands, risks, assumptions, and exclusions. It MUST NOT contain RED/GREEN/REFACTOR instructions, `.plan`, worker or model configuration, worktrees, branches, slices, verification artifacts, or execution state.

The generic `herdr` skill MUST precheck current agent state before waiting. When no terminal state is already present, it MUST start `done`, `idle`, and `blocked` waits concurrently, continue after the first successful wait, cancel and reap the remaining waiters, and read current output. `done` and `idle` are completion states; `blocked` is an immediate steering state. If every wait fails or times out, current state and output MUST be inspected before retry or failure reporting.

`herdr-claude-code` MUST compose `herdr`, launch exactly `claude --dangerously-skip-permissions`, and verify Claude readiness before task submission. Prompt delivery MUST distinguish pasted text from submission: `[Pasted text #1]` is not sufficient evidence, an explicit Enter and output/state inspection are required, and blind prompt resends or repeated Enter presses are prohibited. Completion and blocking MUST use the base concurrent status Activity; blocked Claude agents MUST be inspected and steered before observation resumes.

`divide-plan` MUST require an explicit implementation-plan path and `HERDR_ENV=1`; no non-Herdr fallback is required or permitted. It MUST validate repository identity, source path and SHA-256, and full Git points before creating or resuming state. It MUST compose the shared Herdr skill for terminal mechanics while retaining all task, checkout, ledger, evidence, transition, and acceptance ownership. When an implementation or oversight configuration selects Claude Code, it MUST route that role through `herdr-claude-code`; non-Claude roles MUST continue through the generic Herdr skill.

An execution ledger MUST be stored beneath `/tmp/agent-plans/<repo-id>/ledgers/<ledger-id>/` with `PLAN.md`, `slices/`, and `verifications/`. Repository-local `.plan` MUST point only to the active execution ledger and be locally excluded from Git. A stale target MUST NOT be guessed or reconstructed, and an incomplete active ledger MUST NOT be replaced without explicit approval. The source implementation plan and all plans, ledgers, branches, and worktrees MUST NOT be automatically mutated, deleted, or cleaned.

Before writing a new ledger, `divide-plan` MUST inspect source-plan risk and ask only relevant orchestration questions one at a time. It MUST record exact implementation and oversight model ids and thinking levels plus one observation timeout. Exceptional final passes MAY be proposed only for concrete risk and MUST require user approval. No stalled-worker threshold is part of the timing policy.

The coordinator MUST be the sole ledger writer and state owner. It MAY run mechanical commands but MUST NOT implement or review. Every editable slice and final remediation batch MUST use an isolated worktree and branch before Herdr transport. Each slice MUST fit one fresh context, own explicit RED/GREEN/REFACTOR guidance, and become ready only after all blockers are integrated. Recoverability, full fixed-point evidence, integration-gated dependencies, append-preserved failed attempts, and stale-state reconciliation MUST be maintained.

For each slice, implementation MUST produce a commit and required evidence. An independent oversight agent MUST compose `test-quality-verifier` in audit-only mode at that fixed point. Findings MUST return to the same implementer, and verification MUST rerun at every new fixed point. The coordinator MUST run mechanical evidence gates before integration. At most two correction attempts are allowed; unresolved work then blocks the ledger. Standards, Spec, Premortem, Security, Visual, and general code review MUST NOT be default per-slice passes.

After all slices integrate, repository gates and independent Standards, Spec, Premortem, and Security passes MUST run against one integrated fixed point, in parallel where possible. Standards and Spec MUST compose `code-review`. Findings MUST be collected and deduplicated, then batch-remediated by an editable agent using the oversight configuration rather than original slice workers. All four final passes MUST rerun at every new fixed point. At most two remediation batches are allowed; unresolved findings then block the ledger.

A Herdr observation timeout MUST lead to immediate state and output inspection. Blocked, premature-idle, error, missing-evidence, or input-needed evidence MUST be steered immediately; idle or missing panes MUST NOT establish success. Recovery MUST reconcile source SHA-256, Git topology and commits, recompute the frontier from integrated blockers, and rediscover live Herdr resources without persisting pane identity.

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
| Invalid implementation-plan source | Source path, repository id, SHA-256, or fixed Git point does not match | Divide-plan preflight | Stop before ledger mutation or agent launch | Supply the exact immutable plan or restore the missing Git evidence |
| Active-ledger conflict | `.plan` is stale, incompatible, or points to an incomplete ledger that would be replaced | Active-state inspection | Stop and report the exact active state | Obtain explicit replacement approval or resume/reconcile the existing ledger |
| Correction limit reached | A slice still fails verification or mechanical gates after two correction attempts | Ledger attempt count | Set ledger status to blocked | Preserve evidence and request an explicit new decision |
| Remediation limit reached | Final findings remain after two remediation batches and full review reruns | Ledger remediation count | Set ledger status to blocked | Preserve every fixed point and finding for explicit recovery |
| Agent status race exhausted | All concurrent `done`, `idle`, and `blocked` waits fail or time out | Base Herdr wait results | Inspect current pane state and output; do not infer completion or failure | Retry only from inspected evidence or report the limitation |
| Claude prompt not submitted | Claude displays `[Pasted text #1]` or remains idle after prompt delivery | Claude composer plus pane state/output inspection | Send an explicit Enter and inspect once; do not resend the prompt blindly | Report exact composer/state evidence if processing still does not begin |

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

### TS-SKILL-010: Immutable Implementation Plan

Category: Integration
Priority: Critical
Preconditions: A fixed comparison changes authoritative specs.
Input: Run `create-plan` against the comparison and inspect the resulting artifact.
Expected Output: Exactly one immutable implementation-plan file records full Git points, all requirement dispositions, and only remaining sequential work; no `.plan`, slice, worker, review, or execution state is created.

### TS-SKILL-011: Recoverable Herdr Execution Ledger

Category: End-to-End
Priority: Critical
Preconditions: A valid implementation plan exists and execution runs inside Herdr.
Input: Run `divide-plan`, interrupt after at least one verification attempt, and resume through `.plan`.
Expected Output: Repository and source identities validate; isolated slices resume from integration-gated state; failed attempts remain; test-quality and mechanical gates precede integration; final mandatory passes share a fixed point.

### TS-SKILL-012: Execution Limits and Hard Preconditions

Category: Integration
Priority: Critical
Preconditions: Divide-plan preflight or verification can be exercised.
Input: Attempt execution outside Herdr, replace an incomplete active ledger without approval, exceed slice corrections, and exceed final remediation batches.
Expected Output: Non-Herdr execution and unapproved replacement stop; the third required slice correction and third final remediation batch are not launched; ledger state is blocked with preserved evidence.

### TS-SKILL-013: Concurrent Herdr Terminal-State Wait

Category: Integration
Priority: Critical
Preconditions: A detected agent pane can transition to `done`, `idle`, or `blocked`.
Input: Invoke the base Herdr coordination Activity from working state and separately from each already-terminal state.
Expected Output: Current terminal state returns immediately; otherwise all three waits start concurrently, the first success wins, remaining waiters are cancelled and reaped, output is read, and complete exhaustion triggers state/output inspection.

### TS-SKILL-014: Claude Code Herdr Orchestration

Category: End-to-End
Priority: High
Preconditions: Claude Code and Herdr are available and an authorized checkout is selected.
Input: Launch the Claude Code Herdr workflow, submit a prompt that renders as `[Pasted text #1]`, and exercise completion and blocked states.
Expected Output: Claude launches with `--dangerously-skip-permissions`; readiness is inspected; explicit Enter produces submission evidence without prompt duplication; base concurrent waiting observes completion or blocking; blocked output is inspected and steered.

---

## Changelog

| Version | Date | Change |
|---------|------|--------|
| 3.1.0 | 2026-07-15 | Added executable concurrent Herdr terminal-state waiting and a composing Claude Code orchestration specialization with divide-plan routing. |
| 3.0.0 | 2026-07-15 | Split immutable single-agent implementation planning from Herdr-only execution ledgers, established coordinator ownership, test-quality integration gates, and bounded final review remediation. |
| 2.0.0 | 2026-07-15 | Removed retired workflow contracts and made surviving visual evidence return directly to the caller or human. |
| 1.0.0 | 2026-07-14 | Established the Skill Library bounded context, including portable discovery, canonical skill bodies, branch-based Reference semantics, semantic YAGNI, composition, state ownership, provenance, and verification contracts. |

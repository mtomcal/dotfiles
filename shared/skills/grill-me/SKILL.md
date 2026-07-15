---
name: grill-me
description: Interview the user relentlessly about a plan or design until shared understanding resolves every consequential branch, using project terminology and evidence. Use when stress-testing a plan, probing a domain model, resolving design decisions, or when the user says "grill me."
metadata:
  short-description: Stress-test decisions with evidence
allowed-tools: read,bash
---

# Grill Me

## Language Definitions

- **Decision branch** — consequential choice changing design, scope, or implementation route.
- **Shared understanding** — human-confirmed agreement covering decisions, edge cases, evidence discrepancies, terminology, and scope.
- **Term candidate** — proposed term not yet accepted into the applicable ubiquitous language.
- **Definition drift** — materially changed use or boundary of an existing canonical term.
- **Desired behavior** — intended future behavior distinguished from implemented and specified behavior.

## Workflow

Interview the user one question at a time. For each question, provide a recommended answer and an approximate progress percentage based on resolved versus remaining decision branches. Revise the estimate when answers expose new branches.

Do not edit project files or durable artifacts during this workflow. First reach shared understanding; after confirmation, route accepted changes to the skills that own durable artifacts rather than making those edits.

### 1. Ground the language and evidence

Before the first question:

1. Find the repository root when one exists.
2. Read both `specs/UBIQUITOUS_LANGUAGE.md` and root `UBIQUITOUS_LANGUAGE.md` when present. A spec-suite glossary governs its bounded context; a root glossary governs uncovered contexts. Flag conflicting definitions rather than silently choosing one.
3. Read relevant specs, plans, research, code, and tests for the proposal.
4. If no glossary exists, mention that `ubiquitous-language` can establish one, then continue with precise provisional language.

If a question can be answered by code, tests, or relevant specs, investigate it instead of asking the user to recall it. Cross-check factual user claims against those sources and surface mismatches neutrally: distinguish implemented behavior, specified behavior, and desired behavior.

Completion criterion: the first question uses the best available canonical terms and does not ask for an already discoverable fact.

### 2. Build and walk the decision tree

Start with destination, actors, invariants, and scope. Walk dependencies one at a time: resolve prerequisite choices before asking downstream questions. Ask concrete questions, not broad requests for thoughts.

For every important relationship, probe with edge cases:

- cardinality: zero, one, many, duplicates
- lifecycle: creation, transition, cancellation, retry, deletion, recovery
- ownership: who may mutate it, who observes it, who is authoritative
- boundaries: stale state, partial failure, concurrency, invalid input, permissions
- scope: what looks adjacent but must remain out

Challenge overloaded or conflicting terms directly. When the user uses a known alias, restate the question with the canonical term. When two sources use one term differently, ask which bounded-context meaning applies and what observable distinction separates them.

Track:

- resolved decisions and rationale
- tensions between code, specs, and desired behavior
- new term candidates and definition drift
- unresolved branches and what blocks them

Completion criterion: each answer either resolves a branch, produces a sharper dependent question, or identifies concrete evidence needed; no branch is waved away with vague agreement.

### 3. Handle new and drifting terms

For a new domain term, say:

> ⚠️ Term candidate: **New term** is not in the applicable ubiquitous language. I am tracking it for a later `ubiquitous-language` update.

For changed meaning, quote the existing definition and the proposed difference. Probe with at least one concrete edge case to establish whether this is a true definition change, a separate concept, or context-specific language.

Do not opportunistically update the glossary mid-interview. Completion criterion: every accepted term has one proposed definition and boundary from neighboring terms.

### 4. Close only at shared understanding

When no consequential branches remain, summarize:

- resolved decisions with rationale and evidence
- resolved relationship edge cases
- code/spec/desired-behavior discrepancies
- new term candidates and definition updates
- explicit out-of-scope decisions
- remaining uncertainty, or `none`

Ask the user to confirm or correct the summary. Only after confirmation:

- route accepted terminology to `ubiquitous-language`
- route durable behavioral or design decisions to `update-specs`
- route approved spec changes that need a single-agent implementation plan to `create-plan`
- route an explicit immutable implementation plan that is ready for Herdr execution to `divide-plan`
- return unresolved, multi-session uncertainty and its evidence directly to the caller, then stop

Completion criterion: the user confirms the shared-understanding summary before any durable files are changed.

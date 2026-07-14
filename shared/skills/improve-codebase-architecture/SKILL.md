---
name: improve-codebase-architecture
description: Find deepening opportunities in a codebase and always present a visual HTML review with before/after diagrams and candidate comparison. Use when improving architecture, consolidating shallow modules, reducing coupling, or making a codebase more testable and AI-navigable.
metadata:
  short-description: Visual architecture deepening review
allowed-tools: read,write,edit,bash
---

# Improve Codebase Architecture

## Language Definitions

- **Hotspot evidence** — user-reported pain or repeated change history indicating where deeper structure may repay investigation.
- **Architecture candidate** — evidenced opportunity naming files, friction, constraints, direction, and expected gain.
- **Spec tension** — conflict or tradeoff between a candidate and an existing contract.

General architecture vocabulary remains owned by `codebase-design`.

## Workflow

### 1. Scope from intent and change

Load `codebase-design` once as the source of truth for Module, Interface, Implementation, Depth, Seam, Adapter, Leverage, and Locality. If the user names an area or pain point, prioritize it. Otherwise inspect a meaningful stretch of Git history and rank repeatedly changing files or subsystems before widening the scan. State the chosen scope and why it is likely to repay deepening work.

Read `specs/README.md`, `specs/SPEC-OF-SPECS.md`, `specs/UBIQUITOUS_LANGUAGE.md`, and relevant specs when present. Use their domain terms and preserve their invariants. Read repository-native design records linked from those specs; do not require a separate context or ADR convention.

Completion criterion: the scope is tied to user intent or Hotspot evidence, and relevant constraints are cited.

### 2. Explore friction

Look for understanding spread across many shallow modules, leaking seams, duplicated orchestration, pass-through modules, tests coupled to internals, and concepts that require scattered edits. Apply the `codebase-design` deletion test. Check whether a proposed seam has justified adapters and whether tests can use the same interface as callers.

When `HERDR_ENV=1`, load the `herdr` skill and prefer parallel read-only explorers for independent areas or hypotheses; they may share the checkout. Outside Herdr, explore directly in-process. Any delegated agent that edits files must use an isolated clone or worktree.

Completion criterion: every Architecture candidate is grounded in files, observed friction, spec constraints, and a plausible gain in depth, leverage, locality, or test surface.

### 3. Create the mandatory HTML report

Load the report schema in `Reference`, then write a fresh report to `${TMPDIR:-/tmp}/architecture-review-<timestamp>.html`. Include:

- the reviewed scope and Hotspot evidence
- a comparison summary across all candidates
- one card per candidate with files, problem, deepening direction, benefits, recommendation strength, and Spec tension
- side-by-side **Before and After diagrams** for every candidate
- a top recommendation with rationale

Use Mermaid where relationships are graph-shaped and hand-built HTML/SVG where module depth is the point. Attempt to open the report with the platform opener when available; always report its absolute path even if opening fails. Nothing from the report belongs in the repository.

Completion criterion: the HTML exists outside the repository, every candidate has a readable Before/After visual, all candidates are compared, and the absolute path is reported.

### 4. Explore the selected candidate

Ask which candidate the user wants to explore. For the selected candidate, clarify constraints, dependencies, preserved invariants, migration, and tests. If alternative interfaces are useful, follow the already-loaded `codebase-design` Design It Twice branch. Record durable domain or design decisions in the relevant spec; offer to record a rejection only when its rationale would prevent future rediscovery.

Completion criterion: the selected candidate's constraints, invariants, migration, tests, and durable decisions are clear. Stop before implementation until the user chooses a candidate and approves its interface or implementation plan.

## Reference

- Before producing the mandatory visual review, load [HTML-REPORT.md](HTML-REPORT.md) for its static HTML skeleton, candidate-card and comparison fields, badges, diagram patterns, and visual conventions.

---
name: improve-codebase-architecture
description: Find deepening opportunities in a codebase and always present a visual HTML review with before/after diagrams and candidate comparison. Use when improving architecture, consolidating shallow modules, reducing coupling, or making a codebase more testable and AI-navigable.
metadata:
  short-description: Visual architecture deepening review
allowed-tools: read,write,edit,bash
---

# Improve Codebase Architecture

Find architectural friction, then present evidence before designing an interface. Load `codebase-design` as the source of truth for module, interface, implementation, depth, seam, adapter, leverage, and locality.

## 1. Scope from intent and change

If the user names an area or pain point, prioritize it. Otherwise inspect a meaningful stretch of Git history and rank repeatedly changing files or subsystems before widening the scan. State the chosen scope and why it is likely to repay deepening work.

Read `specs/README.md`, `specs/SPEC-OF-SPECS.md`, `specs/UBIQUITOUS_LANGUAGE.md`, and relevant specs when present. Use their domain terms and preserve their invariants. Read any repository-native design records linked from those specs; do not require a separate context or ADR convention.

Completion criterion: scope is tied to user intent or evidenced Git hotspots, and relevant constraints are cited.

## 2. Explore friction

Look for understanding spread across many shallow modules, leaking seams, duplicated orchestration, pass-through modules, tests coupled to internals, and concepts that require scattered edits. Apply the `codebase-design` deletion test. Check whether a proposed seam has justified adapters and whether tests can use the same interface as callers.

When `HERDR_ENV=1`, load the `herdr` skill and prefer parallel read-only explorers for independent areas or hypotheses. They may share the checkout. Outside Herdr, perform the exploration directly in-process. Any delegated agent that edits files must use an isolated clone or worktree.

Completion criterion: every candidate is grounded in files, observed friction, spec constraints, and a plausible gain in depth, leverage, locality, or test surface.

## 3. Always create the HTML report

Read [HTML-REPORT.md](HTML-REPORT.md), then write a fresh report to `${TMPDIR:-/tmp}/architecture-review-<timestamp>.html`. The report must include:

- the reviewed scope and hotspot evidence
- a comparison summary across all candidates
- one card per candidate with files, problem, deepening direction, benefits, recommendation strength, and spec tension
- side-by-side **before and after diagrams** for every candidate
- a top recommendation with rationale

Use Mermaid where relationships are graph-shaped and hand-built HTML/SVG where module depth is the point. Attempt to open the report with the platform opener when available; always report its absolute path even if opening fails. Nothing from the report belongs in the repository.

Completion criterion: the HTML exists outside the repo, every candidate has a readable before/after visual, candidates are compared, and the absolute path is reported.

## 4. Explore the selected candidate

Ask which candidate the user wants to explore. For the selected candidate, clarify constraints, dependencies, preserved invariants, migration, and tests. If alternative interfaces are useful, load `codebase-design` and follow its Design It Twice branch. Record durable domain or design decisions in the relevant spec; offer to record a rejection only when its rationale would prevent future rediscovery.

Do not implement a refactor until the user chooses a candidate and approves an interface or implementation plan.

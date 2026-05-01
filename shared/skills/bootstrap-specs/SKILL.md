---
name: bootstrap-specs
description: Bootstrap a specs/ folder with a language-agnostic specification suite for defining business rules, logic, and requirements. Conducts a grill-style interview to discover systems, bounded contexts, and terminology, then generates SPEC-OF-SPECS, README, ubiquitous language, design language, skeleton specs, and a progress tracker. Use when starting a new project, onboarding AI agents, creating a specification suite from scratch, or initializing specs/ for any project. Supports greenfield (generate directly) and brownfield (generate PLAN.md for agent-driven spec extraction from code).
metadata:
  short-description: Bootstrap language-agnostic spec suites
---

# Bootstrap Specs

Conduct an interactive interview to discover a project's domain, systems, and terminology, then generate a complete `specs/` suite that any AI agent can implement from.

## Quick start

1. Invoke the skill in a project directory
2. Answer the interview questions (one at a time, resolving each branch)
3. Confirm the proposed structure (system list, dependencies, reading order)
4. Receive a complete `specs/` folder ready for authoring

## Two modes

### Greenfield (default)

No code exists yet. The interview produces spec files with headings, guidance prompts, and pre-filled metadata. Specs start at version `0.1.0` — the shape is there, the content needs authoring.

### Brownfield

Code already exists. The interview produces a `PLAN.md` for a long-running agent that reads the codebase and writes fully-authored specs. The agent extracts requirements, behavior, rules, and acceptance criteria — never code or file references.

Detect brownfield when the project already has source files. Ask the user to confirm.

## Process

### Step 1: Interview

Ask these questions **one at a time**, resolving each before moving to the next. Each answer may prompt follow-up questions. Use the grill-me technique: one question, wait for answer, probe for completeness, then move on.

1. **"What is this project?"** — Domain, purpose, target user. One paragraph.
2. **"What languages and frameworks are in the stack?"** — Build the technology dependencies table.
3. **"Greenfield or brownfield?"** — Determines output mode. Brownfield if code exists.
4. **"What are the major systems or modules?"** — Initial system list. Propose additions from domain heuristics.
5. **"Where are the boundaries between these systems?"** — Surface bounded contexts. Ask: "Where does one part not need to know about another part's internals?" and "Are there terms that mean different things in different parts?"
6. **"Are there terms that mean different things in different contexts?"** — Terminology collisions feed the ubiquitous language. Flag context-dependent definitions.
7. **"Does this project have user-facing surfaces?"** — UI, CLI, API endpoints, etc. If yes, generate a design language preamble.
8. **"What depends on what?"** — Build the dependency graph. "Which systems need to understand which other systems to function?"
9. **"Which system should an implementing agent read first?"** — Establish reading order. Foundation systems first, leaf systems last.

After all questions: propose the complete system list, dependency graph, and reading order. **Wait for user confirmation before generating.**

### Step 2: Generate structure

Produce all files in `specs/` (see [REFERENCE.md](REFERENCE.md) for full templates):

| File | Content |
|------|---------|
| `SPEC-OF-SPECS.md` | Template constitution, conventions, required sections |
| `README.md` | Reading order, dependency graph (Mermaid), quick reference, checklist |
| `UBIQUITOUS_LANGUAGE.md` | Domain glossary preamble (populated from interview) |
| `DESIGN_LANGUAGE.md` | Interface vocabulary + visual tokens (only if user-facing surfaces) |
| `parameters.md` | Centralized tuning values with "why" column |
| `{system}.md` per system | Skeleton spec with headings, guidance prompts, pre-filled metadata |
| `SPEC-OF-SPECS-PLAN.md` | Progress tracker |

For **brownfield**: skip individual specs. Produce `PLAN.md` with system-to-code mapping, extraction strategies, and authoring order.

### Step 3: Confirm and iterate

Show the generated file list and dependency graph. User can add/remove/rename systems before final generation.

## Key conventions

- **No code in specs.** Pseudocode, schema tables, and decision tables only. Specs are language-agnostic behavior contracts.
- **Specs are prescriptive**, not descriptive. "The system MUST…" not "the system currently…"
- **Every constant has a WHY.** The parameters spec requires rationale for every value.
- **Test scenarios use `TS-{PREFIX}-{NUMBER}` format.** The SPEC-OF-SPECS defines the format; the actual index gets created when specs have content.

## Re-running

Re-running on an existing `specs/` folder regenerates **meta-files only** (SPEC-OF-SPECS, README, ubiquitous language, design language, progress tracker). Individual spec files — which contain authored content — are never overwritten.

## Relationship to other skills

- **ubiquitous-language** — Bootstrap produces the initial glossary. Ubiquitous-language refines it as the project evolves.
- **create-plan** — Specs feed create-plan's spec-driven mode. The two skills compose but have no hard dependency.

## Advanced features

See [REFERENCE.md](REFERENCE.md) for: spec template, SPEC-OF-SPECS template, README template, brownfield PLAN template, skeleton spec format, design language format, ubiquitous language format.
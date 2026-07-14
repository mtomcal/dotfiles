---
name: bootstrap-specs
description: Bootstrap a specs/ folder with a language-agnostic specification suite for defining business rules, logic, and requirements. Conducts a grill-style interview to discover systems, bounded contexts, and terminology, then generates SPEC-OF-SPECS, README, ubiquitous language, design language, skeleton specs, and a progress tracker. Use when starting a new project, onboarding AI agents, creating a specification suite from scratch, or initializing specs/ for any project. Supports greenfield (generate directly) and brownfield (generate PLAN.md for agent-driven spec extraction from code).
metadata:
  short-description: Bootstrap language-agnostic spec suites
allowed-tools: read,write,edit,bash
---

# Bootstrap Specs

## Language Definitions

- **Greenfield** — mode for a project without implementation source code, producing meta-files and skeleton specs.
- **Brownfield** — human-confirmed mode proposed when implementation source exists, producing a spec-extraction plan rather than individual system specs.
- **Skeleton spec** — unauthored system-spec scaffold with required headings, prompts, and initial metadata.
- **Meta-file** — suite-level governance, navigation, language, design, parameter, or progress artifact that may be regenerated without overwriting authored system specs.

## Workflow

Use this workflow to interview the user, obtain one approval before writing, and generate or safely refresh a language-agnostic `specs/` suite.

### 1. Route the mode and inspect existing state

Inspect the project for project-owned implementation source and for an existing `specs/` folder. Propose **Brownfield** when implementation source exists; otherwise propose **Greenfield**. The proposal is evidence for question 3, not an automatic choice: the user confirms the mode.

If `specs/` already exists, inventory its meta-files and individual system specs before the interview. Treat the run as a rerun and retain that inventory for overwrite review.

Completion criterion: the proposed mode cites the source evidence, the user will make the final mode decision, and every existing spec-suite file is classified before any write.

### 2. Conduct the interview

Ask these eight questions one at a time. Wait for each answer, investigate facts available from current project evidence, probe consequential branches, and resolve the answer before continuing.

1. **"What is this project?"** — Establish domain, purpose, target user, and a one-paragraph summary.
2. **"What languages and frameworks are in the stack?"** — Build the technology-dependencies table.
3. **"Greenfield or Brownfield?"** — Present the evidence-based proposal from step 1 and ask the user to confirm or change it. Brownfield is selected only by this confirmation.
4. **"What are the major systems or modules?"** — Start with the user's list, then propose additions from domain heuristics (for example, a game may need a game loop, a SaaS may need auth, and a CLI may need config). The user confirms or adjusts them.
5. **"Any terms you suspect might be overloaded, or is it too early to tell?"** — Propose likely collisions from the domain and system list. Accept “not sure yet”; Bootstrap seeds initial terms, while `ubiquitous-language` owns later refinement.
6. **"Does this project have user-facing surfaces?"** — Include UI, CLI, and API surfaces. Generate a design-language preamble only when a surface exists.
7. **"Any clear dependencies you already know about?"** — Propose a dependency graph from common domain patterns. The user confirms, adds, or removes edges. Accept “not sure”; later spec authoring may refine it.
8. **"Which system should an implementing agent read first?"** — Propose a reading order derived from the graph, with foundations before leaves. The user confirms or adjusts it.

Completion criterion: all eight answers and follow-up decisions are resolved, provisional terminology is identified, and the selected mode is human-confirmed.

### 3. Propose the complete generation scope and obtain approval

Present one complete proposal containing:

- selected mode and project summary;
- final system list;
- dependency graph and derived reading order;
- exact mode-specific file list; and
- on a rerun, every existing meta-file proposed for overwrite, with a summary or diff of the candidate replacement.

Allow the user to add, remove, or rename systems and adjust dependencies or reading order. Revise and re-present the complete proposal until the user explicitly approves it. **Do not write generated files before this approval.** The approval covers only the displayed structure and exact overwrite set.

Completion criterion: one explicit pre-generation approval covers every file to create or overwrite; no structural choice or overwrite remains implicit.

### 4. Generate the approved suite

Load the exact templates identified in the Reference section, then generate only the approved files.

For **Greenfield**, generate:

- `SPEC-OF-SPECS.md` for conventions and required sections;
- `README.md` for reading order, Mermaid dependency graph, quick reference, and checklist;
- `UBIQUITOUS_LANGUAGE.md` as the initial domain-glossary seed;
- `DESIGN_LANGUAGE.md` only for user-facing surfaces;
- `parameters.md` with a rationale/WHY column;
- one `{system}.md` skeleton spec per confirmed system; and
- `SPEC-OF-SPECS-PLAN.md` as the spec-authoring progress tracker.

For **Brownfield**, generate the same meta-files and progress tracker but no individual system specs. Also generate `PLAN.md` as the Bootstrap-owned **spec-extraction plan**, with system-to-code evidence mapping, discovery strategies, extraction focus, and authoring order. It directs an extracting agent to turn implementation evidence into fully authored prescriptive requirements, behavior rules, error handling, parameters, and acceptance/test scenarios; it is not a `create-plan` plan workspace, implementation plan, slice graph, or `.plan` control plane. Code locations may appear in this extraction artifact, but not in the resulting system specs.

Apply these rules while generating and validating:

- Specs are prescriptive behavior contracts: use “The system MUST…”, not descriptions of what code currently does.
- Specs contain no implementation code, snippets, implementation-source file paths, or other implementation references. Use language-agnostic pseudocode, schema tables, and decision tables. Brownfield code mappings remain in the spec-extraction plan only.
- Every constant or parameter has a rationale explaining WHY the value exists.
- Test scenarios use `TS-{PREFIX}-{NUMBER}`; the SPEC-OF-SPECS defines the format, and content authoring creates the actual index.
- Skeleton specs start at version `0.1.0`.

On a rerun, regenerate only meta-files explicitly approved in step 3. Never create, replace, rename, or delete an individual system spec. Treat the existing suite glossary as live authority: preserve its definitions and route approved term additions or refinements through `ubiquitous-language` at the applicable suite location rather than replacing it from the initial seed template. Other meta-file changes remain limited to the exact approved overwrite set.

Completion criterion: every write is approved, mode-correct, template-conformant, and within rerun boundaries; before/after hashes or diffs prove that individual system specs were not overwritten.

### 5. Validate and report the generated result

Validate the actual file list, required headings, relative links, dependency graph, reading order, mode-specific inclusions and exclusions, and approved overwrite scope. For Brownfield, verify that `PLAN.md` is qualified as a spec-extraction plan and that no individual skeleton specs were generated. For reruns, verify the existing glossary and every individual system spec were preserved except for approved owner-routed glossary merges.

Show the actual generated file list and dependency graph, report validation failures and preserved files, and identify `ubiquitous-language` for later glossary evolution. The resulting specs may feed `create-plan` after they are authored, but Bootstrap has no hard dependency on that workflow.

If the user requests a structural correction after this report, return to step 3, present the revised file and overwrite scope, and obtain a new approval before additional writes. Do not describe already-written output as awaiting “final generation.”

Completion criterion: reported files and graph match disk, all validation checks pass or failures are explicit, and any further structural write is behind a renewed pre-generation approval.

## Reference

- Load [REFERENCE.md](REFERENCE.md) when generating or validating files because it contains the exact suite, system-spec, progress-tracker, and spec-extraction-plan templates.
- Load [EXAMPLES.md](EXAMPLES.md) only when a concrete Greenfield/Brownfield interview or game, API, or CLI output example would clarify the user's choices; examples are illustrative, while this Workflow and `REFERENCE.md` remain authoritative.

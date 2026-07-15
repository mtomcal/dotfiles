# Bootstrap Specs Reference

Detailed templates and formats for all generated files.

---

## Spec Template

Every system spec follows this structure. Skeleton specs include all headings with guidance prompts and pre-filled metadata.

```markdown
# {System Name}

> **Spec Version**: 0.1.0
> **Last Updated**: {DATE}
> **Depends On**: [{spec1.md}]({spec1.md}), [{spec2.md}]({spec2.md})
> **Depended By**: [{spec3.md}]({spec3.md})

---

## Overview

{Guidance: Describe what this system does and why it exists. One to three paragraphs. Start with the core responsibility, then explain the design motivation. Use prescriptive language: "The system MUST…"}

---

## Dependencies

### Technology Dependencies

| Technology | Version | Purpose |
|------------|---------|---------|
| {name} | {version} | {why needed} |

### Spec Dependencies

- [{Spec Name}]({spec-file.md}) - {what is used from this spec}

---

## Parameters

{Guidance: List all tuning values, thresholds, limits, timeouts, and rates that affect this system's behavior. Every parameter MUST have a rationale explaining WHY that specific value was chosen. Also note: authoritative parameters live in [parameters.md](parameters.md).}

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| {NAME} | {value} | {unit} | {why this value} |

---

## Data Structures

{Guidance: Define all data types, entities, and their fields using the schema table format below. Each structure gets its own subsection. For complex systems, group related structures together.}

### {StructureName}

{Guidance: One-sentence description of what this structure represents and its lifecycle.}

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| {fieldName} | {type} | {constraints} | {description} |

---

## Behavior

{Guidance: The core of the spec. Describe every behavioral rule the system MUST enforce. Use pseudocode for algorithms and decision tables for conditional logic. Each behavior gets its own subsection.}

### {Behavior Name}

{Guidance: Describe the rule, then provide pseudocode or a decision table.}

**Pseudocode:**
```
{algorithm steps in language-agnostic pseudocode}
```

**Decision table:**

| Condition | Action |
|-----------|--------|
| {condition} | {action} |

---

## Error Handling

{Guidance: For every error case, define the trigger, detection method, system response, and recovery path. Use the format below for each error.}

### {Error Case Name}

- **Trigger**: {what causes this error}
- **Detection**: {how the system detects it}
- **Response**: {what the system does}
- **Recovery**: {how to recover, if applicable}

---

## Implementation Notes

{Guidance: Language-agnostic guidance for implementers. Describe patterns, constraints, and gotchas without writing code. Examples: concurrency concerns, ordering requirements, edge cases that aren't errors but need careful handling.}

---

## Test Scenarios

{Guidance: Define test scenarios using the TS-{PREFIX}-{NUMBER} format. Each scenario has a category, priority, preconditions, inputs, and expected outputs. Skeleton specs list the scenario IDs and names with a note that scenarios need authoring.}

### TS-{PREFIX}-{NUMBER}: {Test Name}

- **Category**: Unit | Integration | Visual | End-to-End
- **Priority**: Critical | High | Medium | Low
- **Preconditions**: {required state}
- **Input**: {exact input values}
- **Expected Output**: {exact expected results}

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | {DATE} | Initial skeleton |
```

---

## SPEC-OF-SPECS Template

The constitution for the entire spec suite. Defines conventions, required sections, and document standards.

```markdown
# Spec-of-Specs: {Project Name} Documentation Blueprint

> **Version**: 1.0.0
> **Last Updated**: {DATE}
> **Purpose**: Define the structure, content requirements, and templates for all specification files in `specs/`.
> **Target Audience**: AI agents implementing the project from scratch with zero existing code.

---

## Document Conventions

### Formatting Standards

- **All specs use Markdown** with GitHub-flavored extensions
- **Headers**: `#` for title, `##` for major sections, `###` for subsections
- **Tables**: Use for structured data (parameters, schemas, decision tables)
- **Pseudocode**: Use fenced code blocks without a language identifier for algorithms
- **Cross-references**: Use `[Link Text](filename.md#section-anchor)` format

### Required Sections

Every system spec MUST include these sections in order:

1. **Overview** — What the system does and why
2. **Dependencies** — Technology and spec dependencies
3. **Parameters** — Tuning values with rationale
4. **Data Structures** — Entity definitions using schema tables
5. **Behavior** — Rules using pseudocode and decision tables
6. **Error Handling** — Every error case with trigger, detection, response, recovery
7. **Implementation Notes** — Language-agnostic guidance
8. **Test Scenarios** — Using `TS-{PREFIX}-{NUMBER}` format
9. **Changelog** — Version history

### Language-Agnostic Policy

**No code in specs.** This spec suite is language-agnostic. Use:

- **Pseudocode** for algorithms — plain-language steps, not any programming language
- **Schema tables** for data structures — field, type, constraints, description columns
- **Decision tables** for conditional logic — condition, action columns

Implementation examples in specific languages belong in code comments, internal documentation, or separate implementation guides — never in specs.

### Schema Table Format

```
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | string | UUID, required | Unique identifier |
```

Types use plain-language: string, integer, float, boolean, timestamp, enum, map, list.

### Decision Table Format

```
| Condition | Action |
|-----------|--------|
| health ≤ 0 AND NOT isInvulnerable | Trigger death |
| damage received AND isInvulnerable | Ignore damage |
```

### Test Scenario Format

```
TS-{PREFIX}-{NUMBER}: {Test Name}
Category: Unit | Integration | Visual | End-to-End
Priority: Critical | High | Medium | Low
Preconditions: {required state}
Input: {exact values}
Expected Output: {exact expected results}
```

The `PREFIX` should be a 2-6 character abbreviation of the spec name (e.g., PLAYER, MATCH, AUTH).

### Cross-Reference Conventions

When referencing other specs:
```
See [Player > Health System](player.md#health-system) for details.
```

### Versioning Policy

- **Specs start at 0.1.0** when scaffolded (content is not yet authoritative)
- **Bump to 1.0.0** when first fully authored and reviewed
- **Patch (0.0.x)**: Clarifications, typo fixes, non-breaking additions
- **Minor (0.x.0)**: New sections, new test scenarios, new parameters
- **Major (x.0.0)**: Breaking changes to behavior, data structures, or contracts
- Every spec's changelog MUST record every version bump with date and summary

---

## Preamble Files

Two special files live in `specs/` but do NOT follow the spec template:

- `UBIQUITOUS_LANGUAGE.md` — Domain glossary (terms, definitions, aliases, relationships)
- `DESIGN_LANGUAGE.md` — Interface vocabulary and visual tokens (only if project has user-facing surfaces)

These are vocabulary contracts, not behavior contracts. They define shared meaning that all specs reference.

---

## Reading Order Convention

The `README.md` reading order follows dependency depth:

1. **Foundation** — specs with no spec dependencies (parameters, ubiquitous language, core entities)
2. **Core** — specs that depend on foundation specs
3. **Supporting** — specs that depend on core specs
4. **Leaf** — specs that depend on many others but nothing depends on them

An implementing agent MUST read specs in reading order to avoid forward references to undefined terms.
```

---

## README Template

```markdown
# {Project Name} Specification Suite

> **Version**: 0.1.0
> **Last Updated**: {DATE}
> **Purpose**: Complete specification for implementing {Project Name} from scratch

---

## Project Summary

{One paragraph describing the project, its purpose, and its target users.}

---

## Technology Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| {component} | {technology} | {version} | {purpose} |

---

## Reading Order

For an AI agent implementing {Project Name} from scratch, read specs in this order:

### Phase 1: Foundation

1. **[ubiquitous-language.md](UBIQUITOUS_LANGUAGE.md)** — Shared domain vocabulary
{IF user-facing: }2. **[design-language.md](DESIGN_LANGUAGE.md)** — Interface vocabulary and tokens
3. **[parameters.md](parameters.md)** — All tuning values with rationale

### Phase 2: {Phase Name}

4. **[{spec}.md]({spec}.md)** — {description}

{Continue for each phase...}

---

## Dependency Graph

```mermaid
graph TD
    {spec1}[{spec1}.md] --> {spec2}[{spec2}.md]
    {spec1}[{spec1}.md] --> {spec3}[{spec3}.md]
    {spec2}[{spec2}.md] --> {spec4}[{spec4}.md]
```

---

## Key Dependencies

| Spec | Depends On | Depended By |
|------|------------|-------------|
| {spec1}.md | — | {spec2}.md, {spec3}.md |
| {spec2}.md | {spec1}.md | {spec4}.md |

---

## Quick Reference

| Spec | Description | Version |
|------|-------------|---------|
| [parameters.md](parameters.md) | All tuning values with rationale | 0.1.0 |
| [{spec}.md]({spec}.md) | {description} | 0.1.0 |

---

## Implementation Checklist

### {Phase 1: Foundation}

- [ ] Define all parameters with values and rationale
- [ ] Review ubiquitous language for term consistency

### {Phase 2: {Name}}

- [ ] Implement {system}
- [ ] Write tests for {system}

{Continue for each system...}
```

---

## Ubiquitous Language Template

```markdown
# Ubiquitous Language

> **Version**: 0.1.0
> **Last Updated**: {DATE}
> **Purpose**: Shared vocabulary for all specs. Every term used in multiple specs MUST be defined here. Read this before any other spec.

---

## {Context Group 1}

| Term | Definition | Aliases to avoid | Context notes |
|------|-----------|-------------------|---------------|
| **{Term}** | {One-sentence definition} | {aliases} | {context if meaning varies} |

## {Context Group 2}

{Same table format...}

---

## Relationships

- A **{Term}** belongs to exactly one **{Term}** |
- A **{Term}** can contain multiple **{Term}s**

---

## Flagged Ambiguities

- "{ambiguous_term}" was used to mean both **{Term A}** and **{Term B}** — these are distinct concepts: {explanation}.

---

## Example Dialogue

> **Dev**: "When a **{Term}** {action}, does the **{Term}** {consequence}?"
> **Domain Expert**: "{answer demonstrating precise term usage}."
> **Dev**: "So if {scenario}, then {follow-up question using terms}?"
> **Domain Expert**: "{answer clarifying boundary between related terms}."
```

---

## Design Language Template

Only generated when the project has user-facing surfaces (UI, CLI, API).

```markdown
# Design Language

> **Version**: 0.1.0
> **Last Updated**: {DATE}
> **Purpose**: Shared interface vocabulary and visual tokens for all user-facing specs. Read this before authoring any UI, CLI, or API spec.

---

## Interface Vocabulary

### {Interface Type: UI / CLI / API}

| Element | Definition | When to use | When NOT to use |
|---------|-----------|-------------|-----------------|
| **{Element}** | {One-sentence definition of this interface element} | {appropriate contexts} | {inappropriate contexts} |

{Repeat for each interface type present in the project...}

---

## Visual Tokens

### Colors

| Token | Value | Usage |
|-------|-------|-------|
| {color-primary} | {hex value} | Primary actions, key highlights |
| {color-danger} | {hex value} | Destructive actions, error states |

### Spacing

| Token | Value | Usage |
|-------|-------|-------|
| {spacing-xs} | {value} | Inline gaps |
| {spacing-md} | {value} | Section gaps |

### Typography

| Token | Value | Usage |
|-------|-------|-------|
| {font-heading} | {value} | Page and section titles |
| {font-body} | {value} | Body text, descriptions |

{Only include token categories relevant to the project. A CLI project won't have colors or typography. An API project might only have naming conventions.}

---

## Naming Conventions

| Context | Convention | Example |
|---------|-----------|---------|
| {context} | {rule} | {demonstration} |
```

---

## Parameters Template

```markdown
# Parameters

> **Spec Version**: 0.1.0
> **Last Updated**: {DATE}
> **Depends On**: None (foundational spec)
> **Depended By**: {All other specs that reference these values}

---

## Overview

This specification is the **single source of truth** for all tuning values, configuration parameters, and thresholds in {Project Name}. Every parameter MUST include a rationale explaining WHY that specific value was chosen.

Parameters serve three purposes:
1. **Consistency**: All implementations use identical values
2. **Tuning**: Values are centralized for easy adjustment
3. **Rationale**: Future implementers understand the intent behind each value

**Critical Rule**: Parameters defined here take precedence over any hardcoded values in implementation. If a conflict exists, this document is authoritative.

---

## {Category 1: e.g., World, Network, Business Logic}

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| {PARAMETER_NAME} | {value} | {unit} | {Why this specific value? What would break if it were different?} |

{Group parameters by domain. Each group gets its own section.}
```

---

## Skeleton Spec Guidance Prompts

When generating skeleton specs, each section gets a tailored guidance prompt based on the system's domain and dependencies. Examples:

**For a "Billing" system:**
- Overview: "Describe the billing lifecycle: invoice creation, payment attempts, failure handling, retries, and finalization. Explain why this system exists separate from the payment processing system."
- Behavior: "Define every state transition in the billing lifecycle using decision tables. Include: what triggers each transition, what happens on success, what happens on failure, and what recovery paths exist."
- Error Handling: "Cover: payment processor timeout, duplicate charge detection, partial refund scenarios, and currency rounding edge cases."

**For an "Auth" system:**
- Overview: "Describe the authentication and authorization model. Explain the threat model this system defends against and why the chosen approach (session tokens, JWT, etc.) was selected."
- Data Structures: "Define the user identity, session, role, and permission entities. Include field-level constraints (max lengths, valid characters, expiry rules)."
- Test Scenarios: "Cover: valid login, invalid password, expired session, permission check for each role, and concurrent session limits."

**For a "Movement" system (game):**
- Overview: "Describe how entities move through the world, including acceleration, deceleration, and boundary handling. Explain why simulation-based movement was chosen over teleportation."
- Behavior: "Provide pseudocode for the velocity calculation including all speed modifiers (sprint, slow, stun). Use decision tables for state transitions (idle → moving → sprinting → idle)."

The guidance prompt replaces the generic section description with a system-specific brief that tells the author exactly what this section needs for THIS system.

---

## Brownfield PLAN.md Template

For brownfield projects, generate a PLAN.md instead of skeleton specs. This plan guides a long-running agent through extracting specifications from existing code.

```markdown
# {Project Name} Spec Extraction Plan

> **Created**: {DATE}
> **Artifact**: Spec-extraction plan — not an implementation plan, execution ledger, slice graph, or `.plan` state
> **Mode**: Brownfield — extracting specs from existing codebase
> **Approach**: Convert implementation evidence into prescriptive, language-agnostic behavior contracts
> **Ownership**: Bootstrap Specs generates this plan; the extracting agent follows it to author the spec suite

---

## Project Context

{One paragraph from the interview.}

---

## Systems to Specify

| System | Spec File | Primary Code Locations | Discovery Strategy |
|--------|-----------|----------------------|-------------------|
| {name} | {name}.md | {paths if known} | {search strategy if paths unknown} |

---

## Extraction Approach

For each system, the extracting agent MUST:

1. **Read the code** to understand current behavior; code paths and search terms stay in this extraction plan as evidence mappings
2. **Write prescriptive specs** — define what the system MUST do, phrased as requirements and rules, not as a description of what the code currently does
3. **Include no implementation references in resulting specs** — no file paths, code snippets, or implementation references. The authored specs are behavior contracts.
4. **Extract parameters** — any magic numbers, thresholds, or configuration values belong in parameters.md with rationale
5. **Identify error cases** — look for error handling, edge cases, and failure modes in the code
6. **Derive test scenarios** — from existing tests, from documented behavior, and from error paths discovered

---

## Authoring Order

Follow the reading order defined by the dependency graph. Foundation specs first.

1. **[ubiquitous-language.md](UBIQUITOUS_LANGUAGE.md)** — Extract from code comments, variable names, and function names
2. **[parameters.md](parameters.md)** — Extract magic numbers and configuration
3. **[{foundation spec}.md]** — {description}
4. **Continue in dependency order...**

---

## Code Mapping

### {System Name}

**Known paths**: {paths from interview, if provided}

**Discovery strategy**: {search strategy for finding related code}

**Extraction focus**:
- {Key behavior to extract}
- {Key data structures to document}
- {Key error cases to identify}

{Repeat for each system...}

---

## Quality Gates

After each spec is authored:

- [ ] All required sections are present (Overview through Changelog)
- [ ] No code or file path references appear in the spec
- [ ] Every parameter has a rationale
- [ ] Every behavior has at least one test scenario
- [ ] All cross-references link to existing specs
- [ ] The ubiquitous language is consistent with terms used in the spec
- [ ] Version is bumped to 1.0.0 (spec is now authoritative)
```

---

## SPEC-OF-SPECS-PLAN Template (Progress Tracker)

```markdown
# Spec-of-Specs Implementation Plan

> **Created**: {DATE}
> **Mode**: {Greenfield | Brownfield}
> **Purpose**: Track progress on authoring all specification files

---

## Implementation Status

### Phase 1: Foundation

| Spec File | Status | Lines | Notes |
|-----------|--------|-------|-------|
| [UBIQUITOUS_LANGUAGE.md](UBIQUITOUS_LANGUAGE.md) | **Draft** | — | Preambled during bootstrap |
| [DESIGN_LANGUAGE.md](DESIGN_LANGUAGE.md) | **Draft** | — | Preambled during bootstrap (if applicable) |
| [parameters.md](parameters.md) | **Skeleton** | — | Needs values and rationale |
| [{spec}.md]({spec}.md) | **Skeleton** | — | Needs authoring |

{Continue for each phase...}

---

## Progress Summary

- **Total Specs**: {count}
- **Authored (1.0.0+)**: 0
- **Skeleton (0.1.0)**: {count}
- **Draft/Empty**: {count}

---

## Authoring Log

| Date | Spec | What was done |
|------|------|---------------|
| {DATE} | — | Initial bootstrap |
```
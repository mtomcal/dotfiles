# Spec-of-Specs: Personal Dotfiles Manager Documentation Blueprint

> **Version**: 1.4.0
> **Last Updated**: 2026-08-01
> **Purpose**: Define the structure, content requirements, and templates for all specification files in `specs/`.
> **Target Audience**: AI agents extracting specifications from an existing codebase with zero prior context.

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

The `PREFIX` should be a 2-6 character abbreviation of the spec name:

| Spec | Prefix |
|------|--------|
| Symlink Manager | SYMLK |
| Tool Provisioning | TOOL |
| Shell Config | SHELL |
| Tmux Config | TMUX |
| Herdr Config | HERDR |
| Neovim Config | NVIM |
| VS Code Config | VSCODE |
| AI Agent Config | AIAGT |
| Skill Library | SKILL |
| Execution Coordination | EXEC |
| Install Orchestrator | INSTL |

### Cross-Reference Conventions

When referencing other specs:
```
See [Symlink Manager > Backup Strategy](symlink-manager.md#backup-strategy) for details.
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
- `DESIGN_LANGUAGE.md` — Interface vocabulary and visual tokens (CLI + config UI surfaces)

These are vocabulary contracts, not behavior contracts. They define shared meaning that all specs reference.

---

## Reading Order Convention

The `README.md` reading order follows dependency depth:

1. **Foundation** — specs with no spec dependencies (parameters, ubiquitous language, core entities)
2. **Core** — specs that depend on foundation specs
3. **Supporting** — specs that depend on core specs
4. **Leaf** — specs that depend on many others but nothing depends on them

An extracting agent MUST read specs in reading order to avoid forward references to undefined terms.

---

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 1.4.0 | 2026-08-01 | Registered the Execution Coordination system and `EXEC` test prefix. |
| 1.3.0 | 2026-07-31 | Registered the VS Code Configuration system and `VSCODE` test prefix. |
| 1.2.0 | 2026-07-14 | Registered the Skill Library system and `SKILL` test prefix. |

# AGENTS.md

<!-- TREE-HASH: <sha256> -->

## Map

<!-- TREE-START -->
```
<tree --dirsfirst -d output>
```
<!-- TREE-END -->

## Modules

### `<module-name>`

- **Purpose**: [description of what this module owns and is responsible for]
- **Owns**: [key subdirectories]
- **Depends on**: [modules it imports from]
- **Rules**: [conventions and constraints — what to never do here]
- **Entry points**: [build targets, main files, or key entry points]

<!-- Repeat for each module -->

## Dependency Rules

Architectural boundaries and forbidden imports:

- **[rule]**: [rationale — what it protects and what breaks when violated]

## Anti-patterns

Mistakes that have occurred more than once in this codebase:

- **Pattern**: [what was done]
  - **Why wrong**: [what broke]
  - **Right way**: [what should be done instead]

## Coding Principles

Practices and methodologies the team follows:

- **<category>**: [confirmed practices or "not practiced"]

### Test Methodology
[Practices]

### Design Principles
[Practices]

### Code Organization
[Practices]

### Error Handling
[Practices]

### Mutation Rules
[Practices]

### Naming Conventions
[Practices]

### Review Gates
[Practices]

---

## Appendix (optional)

### Quality Invariants

[Linked or referenced from CI config, linter configs, etc. — not duplicated here]

### Ubiquitous Language

[Linked or referenced from root UBIQUITOUS-LANGUAGE.md if it exists]

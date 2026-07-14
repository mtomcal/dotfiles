# AGENTS.md Deep-Pass Briefing

Use this briefing only when the main workflow reaches its mandatory `grill-me` deep pass. Fill it from the current parent-owned draft and the loaded `PRINCIPLES_CATALOG.md`; do not treat placeholders as evidence.

```markdown
## AGENTS.md Draft Review

Below is an auto-generated AGENTS.md draft for <project-name>. Sections marked with a Confidence marker need human confirmation. Interview the user one question at a time until the in-scope sections are complete.

### Section 1: Codebase Area Rules

For each in-scope Codebase area, ask:
- "What rules govern work in <area>?"
- "What has broken when these rules were violated?"
- "What should every developer know before touching this area?"

<list full-generation areas or update-affected areas from the draft>

### Section 2: Dependency Rules

Ask:
- "What architectural boundaries exist in this codebase?"
- "What imports or cross-area calls are forbidden?"
- "Are there layering rules, such as handlers never calling the database directly?"

### Section 3: Anti-patterns

Ask:
- "What mistakes have been made more than once in this codebase?"
- "What patterns keep causing bugs or rework?"
- "What should a new developer be warned about?"

For each anti-pattern, capture the pattern, why it was wrong, and the right approach.

### Section 4: Coding Principles

Walk through all categories in `PRINCIPLES_CATALOG.md`. For each category:
- Confirm whether the team follows it.
- If yes, capture the specific practices.
- If no, record "not practiced" without arguing.

The categories are Test Methodology, Design Principles, Code Organization, Error Handling, Mutation Rules, Naming Conventions, and Review Gates.

### Output Format

Return findings as:

## Interview Results

### Codebase Area Rules
- **<area>**: <rules from interview>

### Dependency Rules
- <rule>: <rationale>

### Anti-patterns
- **Pattern**: <description>
  **Why wrong**: <explanation>
  **Right way**: <guidance>

### Coding Principles
- **<category>**: <confirmed practices or "not practiced">

## Unresolved
- <area the user could not confirm, or "none">
```

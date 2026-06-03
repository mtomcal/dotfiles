---
name: create-subagent-skill
description: Create new subagent skills that define effective ad-hoc subagent configurations. Specializes write-a-skill for Pi coding agent subagents.
metadata:
  short-description: Create subagent skill definitions for Pi's ad-hoc subagent tools
allowed-tools:
  - read
  - write
  - edit
  - bash
  - grep
  - ls
  - find
---

# Create Subagent Skill

This skill teaches you how to create effective **subagent skill definitions** for Pi's ad-hoc subagent extension. Unlike agent files (which are gone), subagent skills are pure instruction documents that teach the LLM how to construct effective ad-hoc subagent calls.

## What a Subagent Skill Is

A subagent skill is a **skill** (like this one) that provides reusable patterns for constructing `subagent_run`, `subagent_fork`, and `subagent_fork` calls. It's not a machine-readable template — it's **instructions** for the LLM on how to configure subagents for a specific purpose.

## Skill Structure

Every subagent skill should include:

1. **Frontmatter** with `name`, `description`, and `allowed-tools` (standard skill format)
2. **Role Definition Pattern** — what system prompts work for this type of subagent
3. **Tool Scoping Guidance** — which tools to allow for this type of task
4. **Routing Category** — which subagent intent category this skill maps to (model/thinking is prescribed by the routing table in Pi settings)
5. **Composition Patterns** — how to chain or parallelize this type of subagent
6. **Anti-patterns** — what to avoid
7. **Worked Example** — a concrete example subagent call

## System Prompt Patterns

Good system prompts follow this structure:

```
You are a [role]. Your task is to [scope].
[constraints]
[output format]
```

**Examples:**
- Code review: "You are a senior code reviewer. Analyze the code for bugs, security issues, and style problems. Use `read` and `grep` tools only — do not modify any files. Output your findings in structured sections: Bugs, Security, Style, Suggestions."
- Test writer: "You are a test engineer. Write comprehensive tests for the specified module. Focus on edge cases and error paths. Output all test files."
- Security scanner: "You are a security auditor. Focus on injection vulnerabilities and authentication bypass patterns. Use read-only tools only. Report findings in a structured vulnerability format."

## Tool Scoping Guidance

| Purpose | Tools | Constraint |
|---------|-------|-----------|
| Code review | `read, grep, bash` | Bash read-only in system prompt |
| Implementation | `read, write, bash, edit` | Full access |
| Scouting/exploration | `read, grep, find, ls` | Read-only exploration |
| Testing | `read, write, bash` | Write test files, run tests |

**Principle**: Scope tools to the minimum needed. Over-scoping leads to unexpected modifications. Under-scoping blocks the subagent from completing its task.

## Composition Patterns

### Scout → Implementer → Reviewer Chain
```
subagent_run({
  chain: [
    { name: "scout", task: "Investigate the auth module", systemPrompt: "You are a scout...", tools: "read,grep" },
    { name: "implementer", task: "Fix issues from: {previous}", systemPrompt: "You are an implementer...", tools: "read,write,bash,edit" },
    { name: "reviewer", task: "Review changes from: {previous}", systemPrompt: "You are a reviewer...", tools: "read,grep" },
  ]
})
```

### Parallel Review
```
subagent_fork({
  tasks: [
    { name: "review-auth", task: "Review auth module", systemPrompt: "You are a code reviewer...", tools: "read,grep" },
    { name: "review-api", task: "Review API module", systemPrompt: "You are a code reviewer...", tools: "read,grep" },
    { name: "review-db", task: "Review database layer", systemPrompt: "You are a code reviewer...", tools: "read,grep" },
  ]
})
```

### Research + Implementation Parallel
```
subagent_fork({
  tasks: [
    { name: "researcher", task: "Research best practices for X", systemPrompt: "You are a researcher...", tools: "read,grep,bash" },
    { name: "planner", task: "Draft an implementation plan for X", systemPrompt: "You are a planner...", tools: "read,grep" },
  ]
})
```

## Anti-patterns

1. **Vague system prompts**: "Be helpful" or "You are an assistant" — these produce mediocre results. Always specify the role, scope, and output format.

2. **Overly narrow tool scoping**: Giving a reviewer only `read` when they need `grep` for searching. Ensure tools match the task needs.

3. **No output format specification**: Without guiding the output format, subagents return unstructured walls of text. Always say "Output your findings in sections" or "Return a structured report."

4. **Forgetting {previous} handoff instructions in chains**: In chain mode, the second step needs clear instructions on how to use `{previous}`. Add: "Use the previous step's output as input. Build on it, don't repeat it."

5. **Using model shorthand inconsistently**: If you specify `provider` at the top level and `model` in per-item, the per-item model fully replaces the top-level. Use explicit `provider` params for clarity.

6. **Bare-task chains**: Chains work best with explicit system prompts. Bare-task chains (no systemPrompt) produce inconsistent handoffs.

## Template

When creating a subagent skill, use this template:

```markdown
---
name: [skill-name]
description: [What this skill teaches — be specific]
metadata:
  short-description: [One-line summary]
allowed-tools:
  - read
  - write
  - edit
  - bash
  - grep
  - ls
  - find
---

# [Skill Name]

## Purpose
[What kind of subagent this skill creates]

## System Prompt Template
```
You are a [role]. [Scope definition].
[Constraints — what NOT to do]
[Output format specification]
```

## Recommended Configuration
- **tools**: [Tool list]
- **routing category**: [scout | planner | reviewer | implementer
- **Single or parallel**: [When to use single vs parallel vs chain]

## Example Usage
[Concrete subagent_run or subagent_fork call]

## Common Mistakes
[2-3 bullet points of what to avoid]
```

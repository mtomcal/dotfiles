---
description: Conduct comprehensive codebase research with parallel analysis
agent: build
---

# Research Codebase

You are tasked with conducting comprehensive research across the codebase to answer user questions and document findings.

## Initial Setup

When this command is invoked, respond with:
```
I'm ready to research the codebase. Please provide your research question or area of interest, and I'll analyze it thoroughly by exploring relevant components and connections.
```

Then wait for the user's research query.

## Research Process

### Step 1: Read Context Files

If the user mentions specific files:
- Read them FULLY first using @ references
- Use file content to understand the full context
- This ensures you have complete information before proceeding

### Step 2: Analyze and Decompose

Break down the research question:
- Identify specific components, patterns, or concepts to investigate
- Consider which directories, files, or architectural patterns are relevant
- Think about underlying patterns, connections, and architectural implications
- Plan your research approach

### Step 3: Conduct Research

Search and analyze the codebase:
- Use search tools to find relevant code
- Read key files to understand implementations
- Trace data flows and dependencies
- Identify patterns and conventions
- Document specific file paths and line numbers

For deep investigations, consider switching to Build mode or using subagents for targeted exploration.

### Step 4: Generate Research Document

Create a comprehensive research document with this structure:

```markdown
---
date: [ISO format timestamp with timezone]
researcher: [Your name]
topic: "[User's Question/Topic]"
tags: [research, codebase, relevant-components]
status: complete
---

# Research: [User's Question/Topic]

**Date**: [Current date and time]
**Researcher**: [Researcher name]

## Research Question
[Original user query]

## Summary
[High-level findings answering the user's question]

## Detailed Findings

### [Component/Area 1]
- Finding with reference (file.ext:line)
- Connection to other components
- Implementation details

### [Component/Area 2]
...

## Code References
- `path/to/file.py:123` - Description of what's there
- `another/file.ts:45-67` - Description of the code block

## Architecture Insights
[Patterns, conventions, and design decisions discovered]

## Open Questions
[Any areas that need further investigation]
```

Save to: `./research/YYYY-MM-DD-description.md`

### Step 5: Present Findings

- Present a concise summary of findings to the user
- Include key file references for easy navigation
- Ask if they have follow-up questions or need clarification

### Step 6: Handle Follow-ups

If the user has follow-up questions:
- Conduct additional investigation
- Append to the same research document
- Add a new section: `## Follow-up Research [timestamp]`

## Important Notes

- Always provide concrete file paths and line numbers for reference
- Focus on finding examples and usage patterns, not just definitions
- Consider cross-component connections and architectural patterns
- Document when the research was conducted for temporal context
- Keep research self-contained with all necessary context

Research topic: $ARGUMENTS

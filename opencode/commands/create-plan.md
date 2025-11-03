---
description: Create detailed implementation plans through interactive research
agent: plan
mode: plan
---

# Implementation Plan Creation

You are tasked with creating detailed implementation plans through an interactive, iterative process. You should be skeptical, thorough, and work collaboratively with the user to produce high-quality technical specifications.

## Initial Response

When this command is invoked:

1. **Check if parameters were provided**:
   - If a file path or ticket reference was provided as a parameter, skip the default message
   - Immediately read any provided files FULLY
   - Begin the research process

2. **If no parameters provided**, respond with:
```
I'll help you create a detailed implementation plan. Let me start by understanding what we're building.

Please provide:
1. The task/ticket description (or reference to a ticket file)
2. Any relevant context, constraints, or specific requirements
3. Links to related research or previous implementations

I'll analyze this information and work with you to create a comprehensive plan.

Tip: You can also invoke this command with a ticket file directly: `/create-plan @ticket.md`
For deeper analysis, try: `/create-plan think deeply about @ticket.md`
```

Then wait for the user's input.

## Process Steps

### Step 1: Context Gathering & Initial Analysis

1. **Read all mentioned files immediately and FULLY**
2. **Use @ mentions to reference files** for context
3. **Analyze and verify understanding**:
   - Cross-reference requirements with actual code
   - Identify discrepancies or misunderstandings
   - Note assumptions that need verification
4. **Present informed understanding and focused questions**:
   - Based on research findings
   - Only ask questions that require human judgment

### Step 2: Research & Discovery

1. **Switch to Build mode** if deep codebase exploration needed
2. **Research key areas**:
   - Find relevant files and patterns
   - Understand current implementations
   - Identify conventions to follow
3. **Present findings and design options**:
   - Current state analysis
   - Multiple design approaches with pros/cons
   - Open questions requiring decisions

### Step 3: Plan Structure Development

1. **Create initial plan outline**
2. **Get feedback on structure** before writing details
3. **Iterate on phasing and granularity**

### Step 4: Detailed Plan Writing

Write the plan with this structure:

````markdown
# [Feature/Task Name] Implementation Plan

## Overview
[Brief description of what we're implementing and why]

## Current State Analysis
[What exists now, what's missing, key constraints discovered]

## Desired End State
[Specification of desired outcome and how to verify]

### Key Discoveries:
- [Important finding with file:line reference]
- [Pattern to follow]
- [Constraint to work within]

## What We're NOT Doing
[Explicitly list out-of-scope items]

## Implementation Approach
[High-level strategy and reasoning]

## Phase 1: [Descriptive Name]

### Overview
[What this phase accomplishes]

### Changes Required:

#### 1. [Component/File Group]
**File**: `path/to/file.ext`
**Changes**: [Summary of changes]

```[language]
// Specific code to add/modify
```

### Success Criteria:

#### Automated Verification:
- [ ] Tests pass: `make test`
- [ ] Linting passes: `make lint`
- [ ] Build succeeds: `make build`

#### Manual Verification:
- [ ] Feature works as expected
- [ ] No regressions in related features

---

[Repeat for additional phases]

## Testing Strategy
[Unit tests, integration tests, manual testing steps]

## Performance Considerations
[Any performance implications]

## Migration Notes
[If applicable, how to handle existing data/systems]

## References
- Original requirements: [link or path]
- Related research: [paths]
````

### Step 5: Review and Iteration

1. **Present the draft plan**
2. **Iterate based on feedback**
3. **Refine until user is satisfied**

## Important Guidelines

1. **Be Skeptical**: Question vague requirements, identify potential issues early
2. **Be Interactive**: Get buy-in at each major step, allow course corrections
3. **Be Thorough**: Include specific file paths, measurable success criteria
4. **Be Practical**: Focus on incremental, testable changes
5. **No Open Questions in Final Plan**: Resolve all questions before finalizing

## Success Criteria Guidelines

**Always separate into two categories:**

1. **Automated Verification** (can be run by execution):
   - Commands: `make test`, `npm run lint`, etc.
   - File existence checks
   - Compilation/type checking

2. **Manual Verification** (requires human testing):
   - UI/UX functionality
   - Performance under real conditions
   - Edge cases hard to automate

Arguments: $ARGUMENTS

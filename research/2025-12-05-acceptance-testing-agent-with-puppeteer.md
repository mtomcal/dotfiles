---
date: 2025-12-05T00:00:00Z
researcher: Claude (Sonnet 4.5)
topic: "Adding a Claude Code Subagent for Acceptance Testing with Puppeteer MCP Server"
tags: [research, claude-code, agents, mcp, puppeteer, acceptance-testing]
status: complete
---

# Research: Adding a Claude Code Subagent for Acceptance Testing with Puppeteer MCP Server

**Date**: 2025-12-05
**Researcher**: Claude (Sonnet 4.5)

## Research Question
How can I add a Claude Code subagent that will be handed acceptance criteria to test, then it will run puppeteer MCP server to test the URL, then return any issues and feedback?

## Summary
You can create a custom Claude Code agent that leverages the Puppeteer MCP server for automated acceptance testing. The agent will be defined as a Markdown file with YAML frontmatter in `~/dotfiles/claude/agents/` (global) or `.claude/agents/` (project-specific), can access the Puppeteer MCP server once configured via `claude mcp add`, and will execute browser automation tests based on acceptance criteria provided in the conversation context.

## Detailed Findings

### Component 1: Custom Agent Architecture

**Agent File Location:**
- User-level (global, recommended): `~/dotfiles/claude/agents/acceptance-tester.md`
  - Symlinked to `~/.claude/agents/` for global availability
- Project-level (highest priority): `.claude/agents/acceptance-tester.md`
  - Use for project-specific testing requirements

**Agent Structure:**
```markdown
---
name: acceptance-tester
description: Use this agent when you need to validate acceptance criteria by testing a web application URL. The agent receives acceptance criteria, uses Puppeteer MCP server to automate browser testing, and returns detailed feedback on any issues found.
model: sonnet
color: green
permissionMode: default
---

[System prompt with testing instructions]
```

**Key Configuration Options:**
- `model: sonnet` - Good balance of capability and cost for testing tasks
- `model: haiku` - Faster, cheaper option for simple test scenarios
- `model: opus` - Most capable for complex test scenarios
- `permissionMode: default` - Agent asks before making file edits (test reports, etc.)

**Reference Files:**
- Existing agent examples: `/Users/mtomcal/dotfiles/claude/agents/code-quality-guardian.md:1-320`
- Existing agent examples: `/Users/mtomcal/dotfiles/claude/agents/documentation-updater.md`

### Component 2: Puppeteer MCP Server Setup

**Installation:**
The official Puppeteer MCP server is available as an npm package:
```bash
npm i @modelcontextprotocol/server-puppeteer
```

**Available Capabilities:**
- Navigate to URLs and interact with web pages
- Fill forms and click buttons programmatically
- Capture screenshots of full pages or specific elements
- Execute JavaScript in the browser context
- Monitor console logs and network activity
- Handle authentication cookies
- 16 comprehensive tools including advanced mouse interactions

**Adding to Claude Code:**
```bash
# Using npx for stdio transport (recommended for local testing)
claude mcp add --transport stdio puppeteer -- npx -y @modelcontextprotocol/server-puppeteer

# Verify installation
claude mcp list
```

**Configuration Format:**
The above command creates a configuration equivalent to:
```json
{
  "puppeteer": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-puppeteer"]
  }
}
```

**Transport Type:**
- `stdio` transport runs as a local process on your machine
- Ideal for tools needing direct system access
- Process isolation provides security (no network exposure)
- No authentication layer needed for local development

**Reference Documentation:**
- NPM package: https://www.npmjs.com/package/@modelcontextprotocol/server-puppeteer
- MCP registry: https://mcp.so/server/puppeteer
- Claude Code MCP docs: https://code.claude.com/docs/en/mcp

### Component 3: Agent Design for Acceptance Testing

**System Prompt Structure:**

The agent should include:

1. **Role Definition:**
   - Senior QA Engineer with expertise in automated testing
   - Specializes in acceptance testing and browser automation
   - Understands user acceptance criteria formats (Given/When/Then, etc.)

2. **Workflow Instructions:**
   ```
   1. Parse acceptance criteria from conversation context
   2. Plan test scenarios based on criteria
   3. Use Puppeteer MCP tools to navigate and interact with the URL
   4. Verify expected outcomes match acceptance criteria
   5. Capture screenshots of failures or unexpected behavior
   6. Document all issues with specific reproduction steps
   7. Return structured feedback with pass/fail status
   ```

3. **Output Format:**
   ```markdown
   # Acceptance Test Report: [Feature Name]

   ## Test Summary
   - URL Tested: [url]
   - Test Date: [timestamp]
   - Overall Status: ✅ PASS | ⚠️ PARTIAL | ❌ FAIL

   ## Acceptance Criteria Results

   ### ✅ [Criterion 1]: PASS
   - Expected: [description]
   - Actual: [what happened]
   - Screenshot: [if captured]

   ### ❌ [Criterion 2]: FAIL
   - Expected: [description]
   - Actual: [what happened]
   - Issue: [specific problem]
   - Reproduction Steps: [1, 2, 3...]
   - Screenshot: [path to screenshot]

   ## Issues Found
   1. [Critical] - [Description with line/element reference]
   2. [Important] - [Description]

   ## Recommendations
   - [Actionable feedback for developers]
   ```

4. **Error Handling:**
   - Handle navigation timeouts gracefully
   - Report when elements cannot be found
   - Document JavaScript console errors
   - Capture screenshots on failures

**Example Agent Description Field:**
```markdown
description: Use this agent when you need to validate acceptance criteria by testing a web application URL. The agent receives acceptance criteria, uses Puppeteer MCP server to automate browser testing, and returns detailed feedback on any issues found.

<example>
Context: Developer completed implementing a login feature
user: "I've implemented the login feature. Here are the acceptance criteria: 1) User can enter email and password, 2) Valid credentials redirect to dashboard, 3) Invalid credentials show error message. Please test at http://localhost:3000/login"
assistant: "I'll launch the acceptance-tester agent to validate your login feature against the acceptance criteria."
<Task tool invocation with agent: acceptance-tester>
</example>

<example>
Context: Testing a deployed feature in staging
user: "Run acceptance tests for the checkout flow at https://staging.example.com/checkout with these criteria: [criteria list]"
assistant: "Let me use the acceptance-tester agent to verify the checkout flow meets all acceptance criteria."
<Task tool invocation with agent: acceptance-tester>
</example>
```

### Component 4: Agent Invocation and Context Flow

**How Context Flows to the Agent:**

1. **Conversation History:** The agent receives the full conversation leading up to invocation
2. **Acceptance Criteria:** Provided in the user's message or previous context
3. **Target URL:** Specified in the conversation
4. **Project Context:** Access to AGENTS.md, CLAUDE.md for testing standards

**Invocation Pattern:**
```
User: "Test the registration form at http://localhost:3000/register with these criteria:
       - User can enter name, email, and password
       - Password must be at least 8 characters
       - Email validation works
       - Form submits successfully"
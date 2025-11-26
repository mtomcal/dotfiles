---
date: 2025-11-26T12:00:00-05:00
researcher: opencode
topic: "Best place to develop new prompts for running"
tags: [research, codebase, commands, prompts, claude, opencode]
status: complete
---

# Research: Best place to develop new prompts for running

**Date**: November 26, 2025
**Researcher**: opencode

## Research Question
Where is the best place to develop new prompts for running (commands) in this dotfiles project?

## Summary
The optimal location for developing new command prompts is both `claude/commands/` and `opencode/commands/` directories, using markdown files with YAML frontmatter. Commands contain procedural instructions for specific workflows, while agents handle specialized AI roles.

## Detailed Findings

### Command Architecture

**Command Locations:**
- Claude Code: `claude/commands/` directory (9 command files)
- OpenCode CLI: `opencode/commands/` directory (9 command files)

**Command vs Agent Distinction:**
- **Commands**: Procedural instructions for specific workflows (create plans, save sessions, worktree management)
- **Agents**: Specialized AI roles with comprehensive prompt instructions (code review, documentation updates)

### Command File Structure

Each command file follows this format:

```yaml
---
description: Brief description of what the command does
---

[Full procedural instructions and workflow guidance]
```

**Example command types:**
- `save-session.md`: Creates conversation summaries (75 lines)
- `worktree_create.md`: Manages git worktrees for parallel development (107 lines)
- `create_plan.md`: Interactive implementation planning (435 lines)
- `research_codebase.md`: Comprehensive codebase research (varies)

### Current Command Inventory

**Shared Commands (both Claude and OpenCode):**
- `/save-session` - Create conversation summaries
- `/create-plan` or `/create_plan` - Interactive implementation planning
- `/implement-plan` or `/implement_plan` - Execute approved plans
- `/research-codebase` or `/research_codebase` - Comprehensive codebase research
- `/validate-plan` or `/validate_plan` - Verify plan execution

**Worktree Commands:**
- `/worktree_create` (Claude) / `/worktree-create` (OpenCode)
- `/worktree_merge` (Claude) / `/worktree-merge` (OpenCode)
- `/worktree_list` (Claude) / `/worktree-list` (OpenCode)
- `/worktree_status` (Claude) / `/worktree-status` (OpenCode)

## Code References
- `claude/commands/save-session.md` - Simple command with summary creation workflow
- `claude/commands/worktree_create.md` - Complex command with detailed procedural steps
- `claude/commands/create_plan.md` - Comprehensive planning workflow (435 lines)
- `AGENTS.md:60-68` - Documentation of shared commands between tools

## Architecture Insights

**Dual Tool Support:**
- Commands are duplicated between Claude Code and OpenCode CLI
- Each tool has tool-specific adaptations and naming conventions
- Claude uses underscores in command names, OpenCode uses hyphens

**Command Categories:**
- **Workflow commands**: Plan creation, implementation, validation
- **Research commands**: Codebase analysis and documentation
- **Session management**: Conversation summaries and context preservation
- **Development tools**: Git worktree management for parallel AI development

**Development Pattern:**
- Commands focus on procedural guidance rather than AI specialization
- Include step-by-step instructions, examples, and error handling
- Often include bash commands to execute and verification steps

## Open Questions
None - the command architecture is well-established with clear patterns.

## Recommendations

**For new command development:**
1. Create new `.md` files in both `claude/commands/` and `opencode/commands/` directories
2. Use YAML frontmatter with `description` field
3. Follow established naming conventions (underscores for Claude, hyphens for OpenCode)
4. Include comprehensive procedural instructions, examples, and error handling
5. Test commands with both tools before finalizing

**File naming convention:**
- Use descriptive names: `command-purpose.md`
- Maintain consistency between Claude and OpenCode versions</content>
<parameter name="filePath">research/2025-11-26-agent-prompts-development-location.md
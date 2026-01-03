---
date: 2025-12-27T12:00:00-08:00
researcher: Claude Code
topic: "Global Claude Code Skill for Spawning Instances"
tags: [research, codebase, claude-code, cli, spawning, nested-workflows]
status: complete
---

# Research: Global Claude Code Skill for Spawning Instances

**Date**: 2025-12-27
**Researcher**: Claude Code

## Research Question
How to build a global Claude Code skill that can spawn another Claude Code instance to enable nested workflows (like readyq:full-cycle.md with subagents), since nested subagents are not currently supported.

## Summary

Claude Code supports **non-interactive mode** via the `-p`/`--print` flag, which allows spawning child instances programmatically. The key flags for automation are:

1. **`-p` (print mode)**: Non-interactive execution
2. **`--allowedTools`**: Pre-approve specific tools to avoid permission prompts
3. **`--dangerously-skip-permissions`**: Skip ALL permission prompts (use cautiously)
4. **`--output-format json/stream-json`**: Structured output for parsing results
5. **`--resume`/`-r`**: Continue existing sessions
6. **`--session-id`**: Use specific session UUIDs for tracking

Global skills are configured via symlinks from `~/dotfiles/claude/commands/` to `~/.claude/commands/`, making them available in all projects.

## Detailed Findings

### 1. Current Limitation: Nested Subagents

The existing `readyq:full-cycle.md` uses the Task tool to spawn subagents:
```xml
<action>Launch <tool id="subagent" type="readyq-implementer" /> with the hashId</action>
```

However, these subagents **cannot spawn their own subagents** (nested subagents), creating workflow limitations for complex multi-phase orchestration.

**Reference**: `claude/commands/readyq:full-cycle.md:121-129`

### 2. Solution: CLI Instance Spawning

Instead of using the Task tool for nested workflows, spawn a **new Claude Code CLI instance** using the Bash tool:

```bash
# Basic non-interactive execution
claude -p "Your prompt here"

# With structured output
claude -p "Your prompt here" --output-format json

# With pre-approved tools
claude -p "Run tests and fix failures" --allowedTools "Bash,Read,Edit"

# With full permissions (use cautiously)
claude -p --dangerously-skip-permissions "Fix all lint errors"
```

### 3. Key CLI Flags for Programmatic Spawning

| Flag | Purpose | Example |
|------|---------|---------|
| `-p, --print` | Non-interactive mode, exit after completion | `claude -p "query"` |
| `--output-format` | Structured output: `text`, `json`, `stream-json` | `--output-format json` |
| `--allowedTools` | Pre-approve specific tools | `--allowedTools "Bash,Read,Edit"` |
| `--dangerously-skip-permissions` | Skip all permission prompts | Use in controlled environments |
| `--resume, -r` | Resume existing session by ID | `--resume abc123` |
| `--session-id` | Specify session UUID | `--session-id "uuid-here"` |
| `--max-turns` | Limit agentic turns | `--max-turns 10` |
| `--model` | Select model | `--model sonnet` |
| `--add-dir` | Add working directories | `--add-dir ../other-project` |
| `--append-system-prompt` | Add instructions to system prompt | `--append-system-prompt "Be concise"` |

### 4. Global Skill Architecture

Skills become globally available through symlinks established in `install.sh:699-735`:

```bash
ln -s "$DOTFILES_DIR/claude/commands" "$HOME/.claude/commands"
ln -s "$DOTFILES_DIR/claude/agents" "$HOME/.claude/agents"
ln -s "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
```

**Key directories**:
- `~/.claude/commands/` - Slash commands (available via `/command-name`)
- `~/.claude/agents/` - Agent definitions (available via Task tool)
- `~/.claude/settings.json` - Global settings

### 5. Skill File Structure

Commands use markdown with XML-style workflow definitions:

```markdown
---
model: haiku
---

# Spawn Instance

<system-instructions>
    <role>You are a workflow orchestrator</role>
    <purpose>Spawn Claude Code instances for nested workflows</purpose>
</system-instructions>

<template-variable>
    <symbol>{workflow}</symbol>
    <description>The workflow/command to execute</description>
    <required>true</required>
</template-variable>

<workflow-engine>
    <phase num="1" title="Spawn Instance">
        <action>Run <tool id="cli">claude -p "/workflow-name args" --output-format json</tool></action>
    </phase>
</workflow-engine>
```

### 6. Implementation Pattern: Spawn Skill

**Proposed file**: `claude/commands/spawn.md`

```markdown
---
model: haiku
---

# Spawn Claude Instance

<system-instructions>
    <role>You are a workflow orchestration specialist</role>
    <purpose>Spawn new Claude Code CLI instances for nested workflow execution</purpose>
</system-instructions>

<critical>NEVER use shell redirection operators (>, >>, |, 2>&1) - they suppress exit codes</critical>
<critical>Always capture session IDs for potential resumption</critical>

<template-variable>
    <symbol>{command}</symbol>
    <description>The slash command to execute (e.g., /readyq:full-cycle abc123)</description>
    <required>true</required>
</template-variable>

<template-variable>
    <symbol>{workdir}</symbol>
    <description>Working directory for the spawned instance</description>
    <optional>true</optional>
    <default>current directory</default>
</template-variable>

<template-variable>
    <symbol>{allowedTools}</symbol>
    <description>Comma-separated list of tools to pre-approve</description>
    <optional>true</optional>
    <default>all tools (requires user confirmation)</default>
</template-variable>

<workflow-engine>
    <phase num="1" title="Validate Environment">
        <action>Run <tool id="cli">command -v claude</tool> to verify CLI is available</action>
        <action>Run <tool id="cli">pwd</tool> to capture current directory</action>
        <decision>
            <condition>If claude not found</condition>
            <action-if-true>STOP - Claude Code CLI not installed</action-if-true>
            <action-if-false>Proceed to phase 2</action-if-false>
        </decision>
    </phase>

    <phase num="2" title="Prepare Spawn Command">
        <action>Construct the spawn command based on parameters</action>
        <template>
            cd {workdir} && claude -p "{command}" --output-format json --max-turns 50
        </template>
        <note>If allowedTools provided, add: --allowedTools "{allowedTools}"</note>
    </phase>

    <phase num="3" title="Execute Spawned Instance">
        <action>Run the constructed command via <tool id="cli" /></action>
        <action>Parse JSON output to extract session_id and result</action>
        <action>Report completion status to user</action>
    </phase>

    <phase num="4" title="Handle Results">
        <decision>
            <condition>If spawned instance failed or returned error</condition>
            <action-if-true>Report error details and suggest resumption</action-if-true>
            <action-if-false>Report success with summary</action-if-false>
        </decision>
        <action>If session_id captured, offer to resume: claude --resume {session_id}</action>
    </phase>
</workflow-engine>
```

### 7. Session Management Pattern

For complex workflows, capture and track session IDs:

```bash
# Execute and capture session
result=$(claude -p "/readyq:full-cycle abc123" --output-format json)
session_id=$(echo "$result" | jq -r '.session_id')

# Resume if needed
claude --resume "$session_id" -p "Continue from where you left off"
```

### 8. Context Window Efficiency

From existing patterns in `readyq:full-cycle.md:7-8`:
- Spawned instances should log detailed output to external storage (files, ReadyQ)
- Return only brief status summaries to minimize context usage
- Parent orchestrator reads progress from external logs, not subagent output

### 9. Permission Strategies

**Option A: Pre-approved Tools (Recommended)**
```bash
claude -p "query" --allowedTools "Bash(git:*),Read,Edit,Glob,Grep"
```

**Option B: Full Permissions (Use Cautiously)**
```bash
claude -p --dangerously-skip-permissions "query"
```
- Risks: Data loss, system corruption, prompt injection vulnerabilities
- Mitigations: Run in containers, disable network access, audit commands

**Option C: Permission Prompt Tool (Advanced)**
```bash
claude -p --permission-prompt-tool mcp_auth_tool "query"
```
Routes permission requests to an MCP tool for programmatic approval.

### 10. Known Issues and Limitations

**Node.js Subprocess Bug** (GitHub Issue #771):
- Claude Code may not run correctly when spawned from Node.js scripts
- Works correctly from Python and direct shell execution
- Workaround: Use shell scripts or Python for orchestration

**Shell Redirection Warning** (from `readyq-implementer.md:14`):
- NEVER use `2>&1`, `>`, `>>`, `|` in commands
- These suppress exit codes and hide errors
- Let stdout/stderr flow directly

## Code References

- `claude/commands/readyq:full-cycle.md:121-129` - Subagent spawning pattern
- `claude/commands/readyq:full-cycle.md:7-8` - Context window efficiency rules
- `claude/commands/readyq-implementer.md:14` - Shell redirection warning
- `install.sh:699-735` - Symlink setup for global commands
- `AGENTS.md:32-52` - AI assistant configuration documentation

## Architecture Insights

### Current Architecture
```
User → Claude Code → Task Tool → Subagent (readyq-implementer)
                                      ↓
                               Cannot spawn nested subagents
```

### Proposed Architecture
```
User → Claude Code → /spawn command → New Claude CLI Instance
                                            ↓
                                      Full capability (can use Task tool)
                                            ↓
                                      Can spawn its own subagents
```

### Communication Pattern
```
Parent Instance                 Child Instance
      |                               |
      |------ spawn command --------->|
      |                               |
      |                     [executes workflow]
      |                               |
      |<----- JSON output ------------|
      |       (session_id, result)    |
      |                               |
      |------ resume (if needed) ---->|
```

## Open Questions

1. **Background Execution**: Should spawned instances run in background with monitoring, or block until completion?
   - Recommendation: Block for simple workflows, background for long-running ones

2. **Worktree Compatibility**: How should spawn handle git worktrees?
   - Recommendation: Always specify `--add-dir` for worktree context

3. **Resource Limits**: Should there be limits on concurrent spawned instances?
   - Recommendation: Start with serial execution, add parallelism later

4. **Error Recovery**: How to handle partial failures in spawned workflows?
   - Recommendation: Capture session IDs and provide resume commands

5. **Credential Isolation**: Do spawned instances inherit API credentials?
   - Answer: Yes, they inherit from `~/.claude/` configuration

## Implementation Recommendations

1. **Start Simple**: Create a basic `/spawn` command that executes synchronously
2. **Add JSON Output**: Parse results for session tracking and error handling
3. **Implement Resume**: Add ability to continue failed/interrupted workflows
4. **Consider tmux**: For long-running workflows, spawn in tmux panes for monitoring
5. **Log to Files**: Store detailed output in files, return paths to orchestrator

## Sandboxing Options

For safe execution with `--dangerously-skip-permissions`, sandboxing provides isolation so spawned instances cannot damage the host system.

### Option 1: Docker Sandbox (Recommended - Cross-Platform)

**Official Docker integration** provides the safest option:

```bash
# Quick start
docker sandbox run claude

# With custom workspace
docker sandbox run -w ~/my-project claude

# Pass prompts directly
docker sandbox run claude "Your task description here"

# Continue previous conversation
docker sandbox run claude -c
```

**Benefits**:
- Complete filesystem isolation - only mounted directories accessible
- Network isolation available
- Credentials stored in persistent Docker volume (`docker-claude-sandbox-data`)
- Includes dev tools: Docker CLI, Node.js, Python 3, Git, GitHub CLI
- Runs as non-root `agent` user with sudo

**Setup**: Requires Docker Desktop with AI sandboxes feature enabled.

**Source**: [Docker Claude Code Sandbox](https://docs.docker.com/ai/sandboxes/claude-code/)

### Option 2: Native Claude Code Sandboxing (Built-in)

Claude Code has **native sandboxing** using OS primitives:

```bash
# Enable via slash command
/sandbox

# Or via CLI flag
claude -sb
```

**Filesystem isolation**:
- Read/write: Current working directory and subdirectories only
- Read-only: Rest of filesystem (except denied paths)
- Blocked: Cannot modify `~/.bashrc`, `/bin/`, etc.

**Network isolation**:
- Proxy-based filtering
- Only approved domains accessible
- New domains require permission

**Configuration** in `settings.json`:
```json
{
  "sandbox": {
    "network": {
      "httpProxyPort": 8080,
      "socksProxyPort": 8081
    }
  }
}
```

**Source**: [Claude Code Sandboxing Docs](https://code.claude.com/docs/en/sandboxing)

### Option 3: Linux - Bubblewrap (Low-level Control)

**Bubblewrap** (`bwrap`) provides fine-grained namespace isolation:

```bash
# Install
sudo apt install bubblewrap  # Debian/Ubuntu
sudo pacman -S bubblewrap    # Arch

# Example: Sandbox claude with read-only root, writable workspace
bwrap \
  --ro-bind / / \
  --bind ~/projects ~/projects \
  --dev /dev \
  --proc /proc \
  --unshare-net \
  --die-with-parent \
  claude -p --dangerously-skip-permissions "Your prompt"
```

**Key flags**:
- `--ro-bind / /` - Mount root as read-only
- `--bind src dest` - Writable bind mount
- `--unshare-net` - Network namespace isolation
- `--unshare-pid` - PID namespace isolation
- `--die-with-parent` - Kill sandbox when parent exits

**Best for**: Fine-grained control, scripting, minimal overhead

**Source**: [Bubblewrap GitHub](https://github.com/containers/bubblewrap)

### Option 4: Linux - Firejail (User-Friendly)

**Firejail** provides easy sandboxing with sensible defaults:

```bash
# Install
sudo apt install firejail  # Debian/Ubuntu

# Basic sandboxed execution
firejail --private claude -p --dangerously-skip-permissions "prompt"

# With network disabled
firejail --net=none claude -p --dangerously-skip-permissions "prompt"

# With specific directory access
firejail --whitelist=~/projects/myapp claude -p "prompt"
```

**Key flags**:
- `--private` - Private home directory
- `--net=none` - No network access
- `--whitelist=path` - Allow only specific paths
- `--read-only=path` - Make path read-only

**Best for**: Desktop users, quick isolation, pre-built profiles

**Source**: [Firejail](https://firejail.wordpress.com/)

### Option 5: macOS - Seatbelt/sandbox-exec

**Native macOS sandboxing** via `sandbox-exec` (deprecated but functional):

```bash
# Basic profile restricting writes
sandbox-exec -p '
(version 1)
(allow default)
(deny file-write*)
(allow file-write* (subpath "/tmp"))
(allow file-write* (subpath "~/projects/myapp"))
' claude -p --dangerously-skip-permissions "prompt"
```

**Alternative - Alcoholless** (2025):
```bash
# Install
brew install nttlabs/tap/alcoholless

# Run in sandbox as separate user
alcoholless claude -p --dangerously-skip-permissions "prompt"
```

**Best for**: macOS-native isolation without Docker

**Sources**:
- [sandbox-exec Guide](https://igorstechnoclub.com/sandbox-exec/)
- [Alcoholless](https://medium.com/nttlabs/alcoholless-lightweight-security-sandbox-for-macos-ccf0d1927301)

### Option 6: Community Docker Solutions

Several community projects provide pre-configured Docker sandboxes:

**textcortex/claude-code-sandbox**:
```bash
git clone https://github.com/textcortex/claude-code-sandbox
cd claude-code-sandbox
docker-compose up
```

**rvaidya/claude-code-sandbox**:
```bash
git clone https://github.com/rvaidya/claude-code-sandbox
cd claude-code-sandbox
./run.sh ~/my-project
```

**Source**: [GitHub - claude-code-sandbox](https://github.com/textcortex/claude-code-sandbox)

### Sandbox Comparison Matrix

| Feature | Docker | Native | Bubblewrap | Firejail | macOS Seatbelt |
|---------|--------|--------|------------|----------|----------------|
| **Platform** | All | All | Linux | Linux | macOS |
| **Setup Complexity** | Medium | Low | High | Low | Medium |
| **Filesystem Isolation** | Strong | Medium | Strong | Strong | Medium |
| **Network Isolation** | Strong | Medium | Strong | Strong | Limited |
| **Overhead** | Medium | Low | Low | Low | Low |
| **Credential Handling** | Volume | Native | Manual | Manual | Manual |
| **Best Use Case** | Production | Development | Custom scripts | Quick isolation | macOS native |

### Recommended Approach for Spawn Skill

For the `/spawn` skill, consider a **tiered approach**:

1. **Development**: Use native Claude Code sandboxing (`-sb` flag)
2. **CI/CD**: Use Docker sandbox for full isolation
3. **Production automation**: Use bubblewrap (Linux) or Docker with network disabled

**Example spawn with sandbox**:
```bash
# Native sandbox
claude -sb -p "/readyq:full-cycle abc123" --output-format json

# Docker sandbox
docker sandbox run -w $(pwd) claude "/readyq:full-cycle abc123"

# Bubblewrap (Linux)
bwrap --ro-bind / / --bind $(pwd) $(pwd) --unshare-net \
  claude -p --dangerously-skip-permissions "/readyq:full-cycle abc123"
```

## Next Steps

1. Create `claude/commands/spawn.md` with basic synchronous execution
2. Test with simple workflows first (`/commit`, `/create_plan`)
3. Iterate to support `readyq:full-cycle` and other complex workflows
4. Add background execution and monitoring for long-running tasks
5. Document usage patterns in AGENTS.md
6. Add sandbox mode parameter to spawn skill for production safety

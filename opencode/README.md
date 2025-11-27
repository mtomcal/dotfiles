# OpenCode CLI Configuration

Custom commands and configuration for [OpenCode CLI](https://opencode.ai).

## Structure

```
opencode/
├── commands/                    # Custom commands
│   ├── save-session.md         # Save conversation summaries
│   ├── create-plan.md          # Create implementation plans
│   ├── implement-plan.md       # Execute implementation plans
│   ├── research-codebase.md    # Comprehensive codebase research
│   └── validate-plan.md        # Validate plan execution
├── opencode.json               # Standard global configuration
├── opencode.project.json       # Project-level configuration template
└── .gitignore                 # Prevents committing sensitive data
```

## Configuration Management

OpenCode uses a hierarchical configuration system with global and project-level settings that are merged together.

### Global Configuration (`opencode.json`)

The standard global configuration is version-controlled and symlinked to `~/.config/opencode/opencode.json`. It includes:

- **Theme**: Default to OpenCode theme
- **UI Settings**: Scroll speed and acceleration
- **Model Configuration**: OpenRouter free models (Gemini 2.0 Pro, Gemini 2.0 Flash Lite, Llama 3.3 70B, DeepSeek R1)
- **Provider Setup**: OpenRouter custom provider configuration
- **Tool Permissions**: Allow edit/bash/webfetch, ask for doom_loop
- **Auto-updates**: Notify on updates
- **Instructions**: Load shared AGENTS.md

### Project Configuration (`opencode.project.json`)

A template for project-specific overrides. Copy this to project roots as `opencode.json` to customize:

- **Model overrides**: Project-specific model preferences
- **Additional instructions**: Project docs like CONTRIBUTING.md
- **Tool settings**: Project-specific tool permissions
- **Custom agents**: Project-specific agent configurations

### Installation Behavior

The install script automatically:
1. **Installs OpenCode CLI** via official installer
2. **Creates config directory** at `~/.config/opencode/`
3. **Links global config** `~/.config/opencode/opencode.json` → `~/dotfiles/opencode/opencode.json`
4. **Links commands** `~/.config/opencode/command/` → `~/dotfiles/opencode/commands/`
5. **Links instructions** `~/.config/opencode/AGENTS.md` → `~/dotfiles/AGENTS.md`
6. **Backs up existing configs** with timestamps before linking

### OpenRouter Free Models Setup

This configuration uses **free models from OpenRouter** for cost-effective AI assistance. To complete the setup:

1. **Get OpenRouter API Key**:
   - Visit [OpenRouter.ai](https://openrouter.ai/)
   - Sign up/Login and create an API key (starts with `sk-or-v1...`)

2. **Authenticate OpenCode**:
   ```bash
   opencode auth login
   ```
   - Select "Custom Provider" or "openrouter"
   - Paste your API key when prompted

3. **Available Free Models**:
   - **Grok 4.1 Fast (Free)** - Fast and capable model from xAI
   - **Qwen3 235B A22B (Free)** - Large context model from Alibaba
   - **Kimi K2 (Free)** - Advanced reasoning model from Moonshot AI

4. **Switch Models**: Use `/models` command in OpenCode to switch between available models.

**Note**: Free models may have rate limits or queues. If one model is slow, try switching to another.

### Configuration Hierarchy

```
Global config (symlinked) ← Project config (optional)
├── opencode.json (standard) ← opencode.json (project overrides)
├── AGENTS.md (shared) ← CONTRIBUTING.md, docs/ (project docs)
└── commands/ (shared) ← project commands (if any)
```

## Commands

### `/save-session`
Creates detailed session summaries and saves them to `./sessions/` directory.

**Usage**: `/save-session [optional timestamp]`

### `/create-plan`
Interactive planning command that:
- Uses Plan mode for strategic thinking
- Researches the codebase thoroughly
- Creates detailed implementation plans
- Saves plans to project-appropriate location

**Usage**:
- `/create-plan` - Interactive mode
- `/create-plan @ticket.md` - With file reference

### `/implement-plan`
Executes approved technical plans:
- Uses Build mode for implementation
- Reads and validates plan files
- Implements changes phase by phase
- Tracks progress with checkboxes

**Usage**: `/implement-plan @path/to/plan.md`

### `/research-codebase`
Conducts comprehensive codebase research:
- Searches and analyzes code
- Documents findings with file references
- Generates detailed research documents

**Usage**:
- `/research-codebase` - Interactive mode
- `/research-codebase @context.md` - With context file

### `/validate-plan`
Validates implementation plan execution:
- Checks completion status
- Runs automated verification
- Generates validation reports

**Usage**: `/validate-plan @path/to/plan.md`

## Installation

The install script will automatically:
1. Install OpenCode CLI via official installer
2. Create `~/.config/opencode/` directory
3. Symlink `~/.config/opencode/command/` → `~/dotfiles/opencode/commands/`
4. Symlink `~/.config/opencode/AGENTS.md` → `~/dotfiles/AGENTS.md`
5. Preserve existing credentials and configuration

## Authentication

After installation, configure your API keys:

```bash
# Interactive authentication
opencode auth login

# List authenticated providers
opencode auth list

# Logout from a provider
opencode auth logout
```

Credentials are stored in `~/.local/share/opencode/auth.json`.

## Adding Custom Commands

Create a new markdown file in `commands/`:

```bash
# Create new command
nvim ~/dotfiles/opencode/commands/my-command.md
```

Command format with optional frontmatter:

```markdown
---
description: Brief description of what the command does
agent: build  # or plan, or omit for default
mode: build   # or plan, or all
---

Your command prompt here.

Use $ARGUMENTS for command arguments.
Use @file.md to reference files.
```

The command will be available as `/my-command` after creating the file.

## Mode Switching

OpenCode has two primary modes:
- **Plan mode** (Tab or switch keybind): Strategic planning and design
- **Build mode** (Tab or switch keybind): Implementation and coding

Commands can specify which mode they prefer via frontmatter.

## Shared Configuration

OpenCode shares the `AGENTS.md` file with Claude Code, located at:
- `~/dotfiles/AGENTS.md`

This file contains project-specific instructions and context for all AI coding assistants.

## What's NOT Included

For privacy and security, the following are excluded from version control:
- `auth.json` - API credentials
- `history.jsonl` - Conversation history
- `projects/` - Project-specific data
- `.opencode-cache/` - Generated caches
- Session data and logs

These files remain in your local `~/.config/opencode/` or `~/.local/share/opencode/` directories but are not synced to dotfiles.

## Comparison with Claude Code

| Feature | Claude Code | OpenCode CLI |
|---------|-------------|--------------|
| Interface | Web/Desktop | Terminal TUI |
| Mode switching | N/A | Plan/Build modes |
| Commands | Slash commands | Custom commands |
| File references | Direct paths | @ mentions |
| Agent system | Task agents | Plan/Build agents + subagents |
| Configuration | `~/.claude/` | `~/.config/opencode/` |

Both tools share the same custom commands with optimized implementations for each platform.

## Shell Aliases

Convenient aliases are available after sourcing `.zshrc`:

```bash
oc          # Launch OpenCode (alias for 'opencode')
opencode    # Full command name
```

## OpenCode-Specific Features

### File References with @ Mentions
In OpenCode, use `@` to reference files:
```
Please review @src/main.go and @docs/architecture.md
```

### Subagent Invocation
Invoke subagents directly:
```
@general search for authentication functions
```

### Plan/Build Mode Optimization
Commands are optimized for each mode:
- `/create-plan` runs in Plan mode for strategic thinking
- `/implement-plan` runs in Build mode for execution
- `/research-codebase` uses Build mode with full tool access

## Tips

1. **Use Plan mode first**: Switch to Plan mode when designing solutions
2. **Build mode for execution**: Use Build mode when implementing changes
3. **@ references**: Always use @ to reference files for better context
4. **Subagents**: Leverage subagents for specialized tasks
5. **Command arguments**: Pass arguments with `$ARGUMENTS` in command templates

## Credits

The custom commands are based on techniques from [Advanced Context Engineering for Coding Agents](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md) and optimized for OpenCode's Plan/Build mode architecture.

## Learn More

- [OpenCode Documentation](https://opencode.ai/docs)
- [OpenCode GitHub](https://github.com/opencode-ai/opencode)
- [Command Configuration](https://opencode.ai/docs/commands/)
- [Agent Configuration](https://opencode.ai/docs/agents/)

# OpenCode CLI Configuration

Custom configuration for [OpenCode CLI](https://opencode.ai).

## Structure

```
opencode/
├── commands/                    # Custom commands (empty - available for future use)
├── agents/                      # Custom agents (empty - available for future use)
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
- **Model Configuration**: OpenRouter free models
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
5. **Links agents** `~/.config/opencode/agent/` → `~/dotfiles/opencode/agents/`
6. **Links instructions** `~/.config/opencode/AGENTS.md` → `~/dotfiles/AGENTS.md`
7. **Backs up existing configs** with timestamps before linking

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

## Installation

The install script will automatically:
1. Install OpenCode CLI via official installer
2. Create `~/.config/opencode/` directory
3. Symlink `~/.config/opencode/command/` → `~/dotfiles/opencode/commands/`
4. Symlink `~/.config/opencode/agent/` → `~/dotfiles/opencode/agents/`
5. Symlink `~/.config/opencode/AGENTS.md` → `~/dotfiles/AGENTS.md`
6. Preserve existing credentials and configuration

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

## Learn More

- [OpenCode Documentation](https://opencode.ai/docs)
- [OpenCode GitHub](https://github.com/opencode-ai/opencode)
- [Command Configuration](https://opencode.ai/docs/commands/)
- [Agent Configuration](https://opencode.ai/docs/agents/)

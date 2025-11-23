---
date: 2025-11-03T15:30:00-08:00
researcher: opencode
topic: "OpenCode Configuration Management"
tags: [research, codebase, opencode, configuration]
status: complete
---

# Research: OpenCode Configuration Management

**Date**: 2025-11-03 15:30:00 PST
**Researcher**: opencode

## Research Question
How does OpenCode config management work?

## Summary

OpenCode configuration management uses a symlink-based architecture that separates version-controlled configuration from local data. The system installs custom commands, links shared instruction files, and maintains security by excluding sensitive credentials from version control.

## Detailed Findings

### Installation and Directory Structure

OpenCode configuration is managed through the install script (`install.sh:488-540`) which:

1. **Installs OpenCode CLI** via official installer (`install.sh:493`)
2. **Creates config directory** at `~/.config/opencode/` (`install.sh:504-508`)
3. **Sets up symlinks** for commands and shared files

### Symlink Architecture

The configuration uses these key symlinks:

- **Commands**: `~/.config/opencode/command/` → `~/dotfiles/opencode/commands/` (`install.sh:520`)
- **Shared Instructions**: `~/.config/opencode/AGENTS.md` → `~/dotfiles/AGENTS.md` (`install.sh:535`)

This allows:
- Version control of custom commands in dotfiles
- Shared context between Claude Code and OpenCode
- Easy updates by modifying dotfiles

### Command System

Custom commands are stored as markdown files in `opencode/commands/`:

- `create-plan.md` - Interactive planning with Plan mode
- `implement-plan.md` - Plan execution with Build mode  
- `research-codebase.md` - Comprehensive code analysis
- `save-session.md` - Session summaries
- `validate-plan.md` - Plan validation

Each command includes frontmatter specifying:
```yaml
---
description: Brief description
agent: plan  # or build
mode: plan   # or build
---
```

### Security and Privacy

The `.gitignore` (`opencode/.gitignore:1-21`) excludes sensitive data:

- `auth.json` - API credentials
- `history.jsonl` - Conversation history  
- `projects/` - Project-specific data
- `.opencode-cache/` - Generated caches
- Session data and logs

Credentials are stored locally in `~/.local/share/opencode/auth.json` and never committed.

### Mode Switching Architecture

OpenCode uses Plan/Build mode switching (`opencode/README.md:117-121`):

- **Plan mode**: Strategic planning and design
- **Build mode**: Implementation and coding
- Commands specify preferred mode via frontmatter
- Users can switch modes with Tab or keybinds

### Authentication Flow

Post-installation authentication (`opencode/README.md:74-87`):

```bash
opencode auth login    # Interactive authentication
opencode auth list     # List providers
opencode auth logout   # Logout from provider
```

### Shared Configuration with Claude Code

Both tools share:
- `AGENTS.md` - Project instructions and context
- Similar command sets with platform-specific optimizations
- Same symlink strategy for configuration management

## Code References

- `install.sh:488-540` - OpenCode installation and symlink setup
- `install.sh:520` - Commands symlink creation
- `install.sh:535` - AGENTS.md symlink creation
- `opencode/.gitignore:1-21` - Security exclusions
- `opencode/README.md:117-121` - Plan/Build mode documentation
- `opencode/commands/create-plan.md:1-5` - Command frontmatter example

## Architecture Insights

### Design Patterns

1. **Separation of Concerns**: Version-controlled config vs local data
2. **Symlink Strategy**: Centralized dotfiles with distributed deployment
3. **Mode-Based Workflow**: Plan vs Build modes for different cognitive tasks
4. **Security-First**: Credentials and sensitive data excluded from VCS

### Configuration Hierarchy

```
~/.config/opencode/          # Runtime configuration
├── command/ → ~/dotfiles/opencode/commands/  # Custom commands
├── AGENTS.md → ~/dotfiles/AGENTS.md          # Shared instructions
└── [local files]            # auth.json, history, etc.

~/dotfiles/opencode/          # Version-controlled source
├── commands/                 # Command definitions
├── .gitignore              # Security exclusions
└── README.md               # Documentation
```

### Integration Points

- **Shell Integration**: `oc` and `opencode` aliases in zsh
- **AI Assistant Ecosystem**: Shared context with Claude Code
- **File Reference System**: @ mentions for file references
- **Subagent System**: Specialized agents for different tasks

## Follow-up Research 2025-11-03T15:45:00-08:00

### Authentication Data Storage

Based on OpenCode documentation research, the system does save auth provider configuration:

**Credentials Storage**: `~/.local/share/opencode/auth.json`
- Stores API keys for all configured providers
- Created via `opencode auth login` command
- Supports 75+ LLM providers (Anthropic, OpenAI, Azure, etc.)
- Excluded from version control via `.gitignore`

**Provider Configuration**: Can be set in:
- Global config: `~/.config/opencode/opencode.json`
- Project config: `./opencode.json`
- Environment variables: `OPENCODE_CONFIG`

**Auth Methods**:
1. **Interactive**: `opencode auth login` with browser OAuth
2. **API Keys**: Direct key entry for providers
3. **Environment**: AWS, Google Cloud, etc.
4. **Custom**: Any OpenAI-compatible provider

**Security Features**:
- Credentials stored locally, never in dotfiles
- Support for environment variable substitution: `{env:API_KEY}`
- File-based secrets: `{file:~/.secrets/key}`
- Provider-specific auth flows (OAuth, API keys, service accounts)

## Open Questions

1. How does OpenCode handle command conflicts between different versions?
2. What is the upgrade path when OpenCode CLI releases breaking changes?
3. How are custom commands discovered and loaded by the OpenCode runtime?
4. What happens if symlink targets are missing or corrupted?

The configuration management system is well-architected with clear separation between version-controlled configuration and local runtime data, using symlinks to maintain a single source of truth while preserving security and flexibility. The auth system properly separates sensitive credentials from version control while supporting multiple authentication methods across 75+ providers.
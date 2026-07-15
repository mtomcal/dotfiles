# Claude Code Configuration

Custom commands and settings for [Claude Code](https://claude.com/claude-code).

## Structure

```
claude/
├── agents/                       # Custom AI agents
│   └── test-quality-verifier.md  # Test-quality specialist
├── statusline.sh                 # Custom status line script
└── .gitignore                    # Prevents committing sensitive data
```

## Installation

The install script will automatically:
1. Create `~/.claude/` directory if needed
2. Symlink `~/.claude/commands` → `~/dotfiles/claude/commands`
3. Symlink `~/.claude/agents` → `~/dotfiles/claude/agents`
4. Preserve local `~/.claude/settings.json` across installer updates and migrate the legacy managed symlink to local state
5. Symlink `~/.claude/statusline.sh` → `~/dotfiles/claude/statusline.sh` and configure it in local settings
6. Remove legacy Playwright MCP server if present
7. Preserve existing credentials and history

**Note**: Playwright CLI is now a separate install module (`./install.sh --modules playwright`).

## Adding Custom Commands

Create a new markdown file in `commands/`:

```bash
nvim ~/dotfiles/claude/commands/my-command.md
```

The command will be available as `/my-command` after creating the file.

## Settings

Claude Code preferences remain local at `~/.claude/settings.json`. Edit that file or use Claude Code's settings UI, then reload Claude Code to apply changes.

## What's NOT Included

For privacy and security, the following are excluded from version control:
- `settings.json` - Mutable runtime preferences
- `.credentials.json` - API credentials
- `history.jsonl` - Conversation history
- `projects/` - Project-specific data
- Session data, file history, and generated caches

These files remain in your local `~/.claude/` directory but are not synced to dotfiles.

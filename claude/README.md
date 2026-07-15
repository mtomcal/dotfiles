# Claude Code Configuration

Custom commands and settings for [Claude Code](https://claude.com/claude-code).

## Structure

```
claude/
├── agents/                       # Custom AI agents
│   └── test-quality-verifier.md  # Test-quality specialist
├── settings.json                 # Claude Code settings
├── statusline.sh                 # Custom status line script
└── .gitignore                    # Prevents committing sensitive data
```

## Installation

The install script will automatically:
1. Create `~/.claude/` directory if needed
2. Symlink `~/.claude/commands` → `~/dotfiles/claude/commands`
3. Symlink `~/.claude/agents` → `~/dotfiles/claude/agents`
4. Symlink `~/.claude/settings.json` → `~/dotfiles/claude/settings.json`
5. Symlink `~/.claude/statusline.sh` → `~/dotfiles/claude/statusline.sh`
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

The `settings.json` file contains Claude Code preferences. Edit and reload Claude Code to apply changes.

## What's NOT Included

For privacy and security, the following are excluded from version control:
- `.credentials.json` - API credentials
- `history.jsonl` - Conversation history
- `projects/` - Project-specific data
- Session data, file history, and generated caches

These files remain in your local `~/.claude/` directory but are not synced to dotfiles.

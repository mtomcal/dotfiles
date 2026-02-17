# Claude Code Configuration

Custom commands and settings for [Claude Code](https://claude.com/claude-code).

## Structure

```
claude/
├── commands/              # Custom slash commands (skills)
│   └── ralph.md          # Configure & launch loop.sh agent jobs
├── agents/                # Custom AI agents
│   └── playwright-visual-qa.md  # Visual QA via Playwright CLI
├── settings.json         # Claude Code settings
├── statusline.sh         # Custom status line script
└── .gitignore           # Prevents committing sensitive data
```

## Commands

### `/ralph`

Configures and launches a `loop.sh` agentic loop job. Ralph runs Claude Code in a loop via `loop.sh`, where each iteration reads a prompt file fresh, does work, and repeats until output contains `/done` or the iteration limit is hit.

**What it sets up:**

- **PROMPT.md** — concise task instructions the worker reads every iteration
- **IMPLEMENTATION_PLAN.md** — heavy reference with change context, task order, progress checklist, and process rules
- **ORCHESTRATOR.md** — monitoring playbook for a human or second Claude session that auto-checks progress every 5 minutes

**Configuration options:**
- Task description (what should the worker accomplish)
- Bare metal or Docker sandbox execution
- Max iterations (default 25, 0 = unlimited)
- Prompt file name (default PROMPT.md)

**Launch:**
```bash
# Bare metal
./loop.sh 25 PROMPT.md

# Docker sandbox
SANDBOX=1 ./loop.sh 25 PROMPT.md
```

**Notes:**
- `loop.sh` must already exist in the project root
- Auth: ANTHROPIC_API_KEY > CLAUDE_CODE_OAUTH_TOKEN > ~/.claude/.credentials.json
- OAuth tokens expire after ~8h; API keys are more reliable for long sessions
- Logs go to `.loop-logs/iteration-{N}.log`
- Worker uses `--dangerously-skip-permissions` and `--model opus`

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

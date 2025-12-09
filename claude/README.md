# Claude Code Configuration

Custom commands and settings for [Claude Code](https://claude.com/claude-code).

## Structure

```
claude/
├── agents/                # Custom AI agents
│   └── code-quality-guardian.md  # Language-agnostic code reviewer
├── commands/              # Custom slash commands
│   ├── save-session.md   # Save conversation summaries
│   ├── create_plan.md    # Create implementation plans
│   ├── implement_plan.md # Execute implementation plans
│   ├── research_codebase.md # Comprehensive codebase research
│   └── validate_plan.md  # Validate plan execution
├── settings.json         # Claude Code settings
└── .gitignore           # Prevents committing sensitive data
```

## Agents

### `code-quality-guardian`

Language-agnostic code quality reviewer that provides automated reviews after completing features, bug fixes, or refactors.

**Supported Languages**:
- TypeScript, JavaScript, Python, Go, Rust, Java, Kotlin

**Features**:
- Automatic language detection from files and project config
- Comprehensive reviews: tests, maintainability, security, modularity, complexity
- Language-specific tooling awareness (ESLint, mypy, clippy, gofmt, etc.)
- Actionable feedback with priority levels (Critical/Important/Minor)
- Structured output with verdict (Approved/Needs Changes/Needs Revision)

**When it runs**:
- Automatically invoked after completing significant work units
- After marking tasks as complete
- When explicitly requested

The agent adapts its review criteria to the detected language ecosystem.

## Commands

### Planning & Research

#### `/save-session`
Creates detailed session summaries and saves them to `./sessions/` directory.

#### `/create_plan`
Interactive planning command that:
- Researches the codebase thoroughly
- Creates detailed implementation plans
- Saves plans to `thoughts/shared/plans/`

#### `/implement_plan`
Executes approved technical plans:
- Reads and validates plan files
- Implements changes phase by phase
- Tracks progress with checkboxes

#### `/research_codebase`
Conducts comprehensive codebase research:
- Spawns parallel research agents
- Generates detailed research documents
- Saves to `thoughts/shared/research/`

#### `/validate_plan`
Validates implementation plan execution:
- Checks completion status
- Runs automated verification
- Generates validation reports

## Installation

The install script will automatically:
1. Create `~/.claude/` directory if needed
2. Symlink `~/.claude/commands` → `~/dotfiles/claude/commands`
3. Symlink `~/.claude/agents` → `~/dotfiles/claude/agents`
4. Symlink `~/.claude/settings.json` → `~/dotfiles/claude/settings.json`
5. Preserve existing credentials and history

## Adding Custom Commands

Create a new markdown file in `commands/`:

```bash
# Create new command
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

## Credits

The custom commands (`/create_plan`, `/implement_plan`, `/research_codebase`, `/validate_plan`) are based on techniques from Dexter Horthy's article on [Advanced Context Engineering for Coding Agents](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md).

The `/save-session` command is a custom implementation for tracking conversation history.

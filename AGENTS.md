# AI Agent Instructions

This file provides guidance to AI coding agents (Claude Code, OpenCode, and others) when working with code in this repository.

## Repository Overview

Personal dotfiles repository for a tmux + neovim + zsh development environment. The repository uses a symlink-based architecture to maintain configurations in version control while deploying them to standard system locations.

## Installation and Setup

The primary entry point is `./install.sh`, which:
- Auto-detects OS (Ubuntu/Debian via apt, or macOS via brew)
- Installs dependencies (tmux, neovim 0.10+, zsh, ripgrep, fd, build tools)
- Sets up Oh My Zsh framework
- Clones official kickstart.nvim to `~/.config/nvim`
- Creates symlinks for configurations
- Installs Go (Golang) 1.24+ with architecture detection (x86_64/arm64)
- Installs fnm (Fast Node Manager) and Node.js LTS
- Links AI coding assistant configurations (Claude Code, OpenCode)
- Installs OpenCode CLI and optionally GitHub Copilot CLI
- Installs wtp (git worktree manager) for parallel development
- Sets up Mason LSP/formatter packages (Python, Go, Lua)

**Key behavior**: The script is idempotent and safe to re-run for updates.

## Architecture

### Configuration Strategy

**Philosophy**: Use official upstream configurations (kickstart.nvim) as base, layer custom configs on top via symlinks.

**Symlink structure**:
- `~/.tmux.conf` → `~/dotfiles/tmux/.tmux.conf`
- `~/.config/nvim/lua/custom/` → `~/dotfiles/nvim/custom/`
- `~/.claude/commands` → `~/dotfiles/claude/commands`
- `~/.claude/agents` → `~/dotfiles/claude/agents`
- `~/.claude/settings.json` → `~/dotfiles/claude/settings.json`
- `~/.config/opencode/command/` → `~/dotfiles/opencode/commands/`
- `~/.config/opencode/AGENTS.md` → `~/dotfiles/AGENTS.md` (this file)
- Custom zsh config sourced in `~/.zshrc` (not symlinked)

### AI Coding Assistants

This dotfiles setup supports both **Claude Code** and **OpenCode CLI**:

**Claude Code**:
- Configuration: `claude/` directory
- Commands: Custom slash commands in `claude/commands/`
- Agents: Custom agents in `claude/agents/`
  - `code-quality-guardian`: Language-agnostic code quality reviewer (TypeScript, JS, Python, Go, Rust, Java, Kotlin)
  - `documentation-updater`: Automatically reviews git diffs and updates relevant documentation files
- Settings: `claude/settings.json`

**OpenCode CLI**:
- Configuration: `opencode/` directory
- Commands: Optimized commands in `opencode/commands/`
- Standard config: `opencode/opencode.json` (symlinked globally)
- Project template: `opencode/opencode.project.json` (for project-specific overrides)
- Shared instructions: This AGENTS.md file
- Uses Build/Plan mode switching

**Shared Commands**:
Both tools have access to:
- `/save-session` - Create conversation summaries
- `/create-plan` or `/create_plan` - Interactive implementation planning
- `/implement-plan` or `/implement_plan` - Execute approved plans
- `/research-codebase` or `/research_codebase` - Comprehensive codebase research
- `/validate-plan` or `/validate_plan` - Verify plan execution

These commands use similar approaches but are optimized for each tool's specific features.

### Neovim Configuration

Uses **two-layer architecture**:
1. **Base layer**: Official kickstart.nvim (git repo at `~/.config/nvim`)
2. **Custom layer**: User customizations at `~/dotfiles/nvim/custom/` (symlinked into kickstart)

This design allows updating kickstart.nvim independently (`cd ~/.config/nvim && git pull`) while preserving custom plugins and configurations.

**Adding custom neovim plugins**: Create files in `~/dotfiles/nvim/custom/plugins/` using lazy.nvim format. The install script ensures `{ import = 'custom.plugins' }` is uncommented in kickstart's init.lua (line ~402-403 of install.sh).

**Current custom plugins**:
- `go.lua` - Go debugging (nvim-dap-go) and testing (neotest-golang)
- `python.lua` - Python linting with Ruff and Poetry auto-detection
- `markdown.lua` - Beautiful markdown rendering
- `neo-tree.lua` - File explorer with SSH-friendly ASCII icons
- `diffview.lua` - Git diff viewer optimized for code review
- `neogit.lua` - Interactive git interface for commits, rebases, pulls, pushes

### Tmux Configuration

**Prefix key**: Ctrl-a (not default Ctrl-b)

**Critical settings** for neovim integration:
- Zero escape delay: `set -sg escape-time 0`
- True color support: `set -g default-terminal "tmux-256color"`
- Focus events enabled: `set -g focus-events on`

Vim-style navigation keybindings throughout (h/j/k/l for panes, H/J/K/L for resizing).

### Platform-Specific Handling

The install script contains OS detection logic (install.sh:48-68):
- **Ubuntu/Debian**: Uses apt, installs xclip for clipboard, downloads Neovim AppImage with architecture detection
- **macOS**: Uses brew, installs fd (not fd-find), uses pbcopy/pbpaste for clipboard, Neovim via Homebrew

When modifying the install script, ensure platform-specific packages use correct names (e.g., `fd-find` on Ubuntu, `fd` on macOS).

**Go (Golang) Installation**:
- **Ubuntu/Debian**: Official binary from golang.org with architecture detection (amd64/arm64)
- **macOS**: Via Homebrew with version checking
- Requires Go 1.24+ (required by gofumpt formatter)
- PATH configuration includes `/usr/local/go/bin` and `$HOME/go/bin`
- Optional: govulncheck security scanner
- Mason Go tools installed conditionally: gopls, delve, gofumpt, goimports

### SSH Auto-Attach Behavior

On SSH connections, tmux automatically attaches to session "1" or creates it (zsh/.zshrc.custom:24-28). This ensures remote sessions always start in tmux.

## Development Workflows

### Testing Install Script Changes

```bash
# Always test with a backup first
cp install.sh install.sh.backup

# Test specific sections by commenting out others
# The script uses `set -e` so it will exit on first error
./install.sh
```

### Adding New Tools/Dependencies

Update the install script's dependency installation section (install.sh:114-138). Use the `install_package` function which handles both apt and brew.

### Modifying Configuration Files

- **Tmux**: Edit `tmux/.tmux.conf`, reload with `tmux source-file ~/.tmux.conf` or Ctrl-a r
- **Zsh**: Edit `zsh/.zshrc.custom`, reload with `source ~/.zshrc`
- **Neovim**: Add plugins in `nvim/custom/plugins/`, restart neovim (lazy.nvim auto-installs)
- **Claude Code**: Add markdown files to `claude/commands/`, they become slash commands
- **OpenCode**: Add markdown files to `opencode/commands/`, they become custom commands

### Language-Specific Development

**Python Development**:
- LSP: Pyright (via Mason) with type checking mode set to 'basic'
- Linting: Ruff with Poetry auto-detection (nvim-lint)
- Formatting: Ruff format on save
- Keybindings: `<leader>f` (format), `<leader>l` (lint), `K` (hover docs)
- See `docs/PYTHON_DEVELOPMENT.md` for comprehensive guide

**Go (Golang) Development**:
- LSP: gopls (via Mason) for code completion and navigation
- Debugger: delve with nvim-dap-go integration
- Testing: neotest-golang for test running and visualization
- Formatting: gofumpt, goimports (via Mason)
- Keybindings:
  - `<leader>dt` (debug test), `<leader>db` (breakpoint), `<leader>dc` (continue)
  - `<leader>tn` (nearest test), `<leader>tf` (file tests), `<leader>to` (output), `<leader>ts` (summary)

### Updating Kickstart.nvim

```bash
cd ~/.config/nvim
git pull
```

The install script handles this automatically when re-run (install.sh:296-301), including conflict resolution.

## Important Implementation Details

### Git Configuration Prompt

The install script optionally prompts for git user.name and user.email (install.sh:473-489) if not already set. This is safe to skip during automated deployments.

### Neovim Cache Management

Fresh installations clean all cache directories (install.sh:412-421). Updates preserve `~/.local/share/nvim` (Mason packages) but clear `~/.cache/nvim` to prevent stale plugin issues.

### Neovim Git Integration for Code Review

Two plugins work together for comprehensive git workflows:

**diffview.nvim** - Git diff visualization:
- `<leader>dv` - Open diffview (perfect for reviewing AI-generated code changes)
- `<leader>dc` - Close diffview
- `<leader>dh` - Diff history for current file
- `<leader>df` - Diff history for all files
- Single-tabpage interface with horizontal diffs
- Tree-style file listing

**neogit.nvim** - Interactive git operations:
- `<leader>gg` - Open Neogit interface
- `<leader>gc` - Git commit
- `<leader>gp` - Git pull
- `<leader>gP` - Git push
- Integrates with diffview for visual diffs
- Interactive rebasing, staging, and committing

### Code Quality Guardian Agent

The `code-quality-guardian` agent provides automated code reviews for completed work:

**Features:**
- **Language-agnostic**: Supports TypeScript, JavaScript, Python, Go, Rust, Java, Kotlin
- **Automatic language detection**: Examines file extensions and project config
- **Comprehensive review**: Tests, maintainability, security, modularity, complexity
- **Actionable feedback**: Specific file locations, line numbers, and remediation steps

**When to use:**
- After completing a feature implementation
- After fixing a bug
- After refactoring code
- When marking a task as complete (e.g., `./readyq.py update <id> --status done`)

**How it works:**
1. Detects project language(s) from files and configuration
2. Checks for project-specific standards (CLAUDE.md, AGENTS.md)
3. Reviews tests, code quality, security, and architecture
4. Provides structured feedback with priority levels (Critical/Important/Minor)
5. Gives verdict: Approved, Approved with changes, or Needs revision

The agent automatically invokes when you complete significant work units.

### Documentation Updater Agent

The `documentation-updater` agent keeps documentation synchronized with code changes:

**Features:**
- **Git diff analysis**: Examines recent code changes to identify documentation impacts
- **Multi-file support**: Updates README.md, AGENTS.md, CHANGELOG.md, and other documentation
- **Smart detection**: Identifies new features, configuration changes, workflow modifications
- **Specific proposals**: Provides exact before/after content with rationale
- **Maintains consistency**: Preserves documentation tone, style, and structure

**When to use:**
- After completing a new feature
- After modifying configuration files or workflows
- After adding new commands, agents, or tools
- After refactoring that affects user-facing behavior
- Before creating a pull request or release

**How it works:**
1. Analyzes git diff to understand code changes
2. Reads existing documentation to understand structure
3. Identifies sections that need updates
4. Proposes specific changes with before/after content
5. Prioritizes updates (critical vs. optional)
6. Provides clear rationale linking changes to code

The agent ensures users always have accurate, up-to-date information about the project.

### AI Assistant Privacy

The `.gitignore` files in `claude/` and `opencode/` exclude sensitive files (credentials, history, project data) while tracking commands, agents, and settings. When modifying configs, never commit:
- `.credentials.json` or `auth.json`
- `history.jsonl`
- Project-specific data

### Zsh Shell Change Detection

Recent addition (commit b41aca0) checks if zsh is already the default shell to avoid unnecessary chsh calls (install.sh:180-201).

## Common Pitfalls

1. **Symlink conflicts**: The install script backs up existing non-symlink configs with timestamps before linking
2. **Homebrew path on Apple Silicon**: Script handles `/opt/homebrew/bin/brew` vs `/usr/local/bin/brew` (install.sh:76-79)
3. **Custom plugin imports**: Must uncomment `{ import = 'custom.plugins' }` in kickstart's init.lua for custom neovim plugins to load
4. **fnm initialization**: Requires both PATH export and `fnm env` eval in shell config (zsh/.zshrc.custom:42-46)
5. **AI assistant authentication**: Both Claude Code and OpenCode require separate authentication setup by the user

## Command Line Aliases

Shell aliases are available for common operations:
- `claude` - Launch Claude Code
- `oc` or `opencode` - Launch OpenCode CLI
- Tmux aliases: `t`, `ta`, `tn`, `tl`, `tk`, `td`

## Session Summaries

Session summaries are stored in `./sessions/` (project-specific, gitignored). Use `/save-session` to create detailed conversation summaries for future reference.

## Working with Multiple AI Assistants

This setup allows seamless switching between Claude Code and OpenCode:
- Both tools share the same project context via this AGENTS.md file
- Commands are adapted to each tool's strengths
- OpenCode leverages Plan/Build modes for different workflows
- Claude Code uses its agent system for parallel task execution
- Choose the tool based on your needs - both have full context

## Git Worktrees for Parallel AI Development

This dotfiles repository is configured to support **parallel AI development workflows** using git worktrees. This enables running multiple AI coding agents simultaneously on different features without context switching.

### What Are Git Worktrees?

Git worktrees allow multiple working directories from a single Git repository:
- Each worktree can be on a different branch
- All worktrees share the same `.git` directory (commits, branches, remotes synchronized)
- Perfect for running multiple Claude Code or OpenCode instances in parallel
- No context switching means each AI agent maintains full understanding of the codebase

### Directory Structure

```
dotfiles/
├── .git/                    # Shared Git database
├── .gitignore               # Contains: trees/
├── AGENTS.md                # This file
├── install.sh               # Installs wtp automatically
└── trees/                   # Worktrees directory (GITIGNORED)
    ├── feature-auth/        # Worktree 1: authentication feature
    ├── refactor-config/     # Worktree 2: config refactor
    └── experiment-zsh/      # Worktree 3: zsh experiments
```

### Quick Start

**Create a new worktree:**
```bash
wtp create feature-name
# or: git worktree add trees/feature-name -b feature-name
```

**Work in the worktree:**
```bash
cd trees/feature-name
claude    # or: opencode
```

**List active worktrees:**
```bash
wtp list
# or: git worktree list
```

**Merge and cleanup:**
```bash
git checkout main
git merge feature-name
wtp delete feature-name
```

### Available Commands

Both Claude Code and OpenCode have specialized worktree commands:

**Claude Code:**
- `/worktree_create` - Create new worktree with guided setup
- `/worktree_merge` - Safely merge worktree back to main
- `/worktree_list` - List all active worktrees
- `/worktree_status` - Detailed status of all worktrees

**OpenCode CLI:**
- `/worktree-create` - Create new worktree with guided setup
- `/worktree-merge` - Safely merge worktree back to main
- `/worktree-list` - List all active worktrees
- `/worktree-status` - Detailed status of all worktrees

### Common Use Cases

1. **Parallel Feature Development**
   - Terminal 1: `cd trees/feature-nvim-plugin && claude`
   - Terminal 2: `cd trees/feature-tmux-theme && claude`
   - Terminal 3: `cd trees/refactor-install && opencode`

2. **Competitive Implementations**
   - Try 3 different approaches to the same problem
   - Review all implementations and pick the winner
   - Example: Test different zsh themes, choose the best

3. **Development + Review**
   - One agent implements a feature
   - Another agent reviews the code and suggests improvements
   - Keep work isolated until both are satisfied

4. **Large Refactors**
   - Divide refactoring work across multiple agents
   - Each agent handles a specific component or directory
   - Merge incrementally as each piece completes

### Best Practices

✅ **DO:**
- Keep worktrees short-lived (hours to days, not weeks)
- Use descriptive branch names with prefixes: `feature-`, `fix-`, `refactor-`, `experiment-`
- Delete worktrees immediately after merging
- Run `/worktree-status` before merging to check all worktrees
- Copy `.env`, `AGENTS.md`, `CLAUDE.md`, `.readyq.jsonl` files to new worktrees (commands do this automatically)
- Limit active worktrees to 3-5 simultaneously

❌ **DON'T:**
- Create worktrees "just in case" - create them when starting work
- Leave merged worktrees around
- Use the same branch name in multiple worktrees (not possible anyway)
- Work in the wrong worktree by accident (check with `pwd` and `git branch`)

### Installation

The `install.sh` script automatically installs `wtp` (git worktree manager):
- **macOS**: Installed via Homebrew (`brew tap satococoa/tap && brew install satococoa/tap/wtp`)
- **Linux**: Downloads pre-built binary from GitHub releases to `~/.local/bin/wtp`
- Supports x86_64 and arm64 architectures

### Shell Completions

Add to your shell configuration for enhanced productivity:

**Bash:**
```bash
eval "$(wtp completion bash)"
```

**Zsh:**
```bash
eval "$(wtp completion zsh)"
```

**Fish:**
```bash
wtp completion fish | source
```

### Benefits of Worktree Workflow

- **No Context Switching**: Each AI agent maintains accumulated understanding
- **True Parallelization**: Work on 3-5 features simultaneously
- **Experimentation**: Try multiple approaches, pick the winner
- **Productivity**: 2-3x faster development reported by production teams
- **Tool Agnostic**: Works with Claude Code, OpenCode, VSCode Copilot, Cursor, etc.

### Troubleshooting

**"fatal: already checked out"**
→ A branch can only be checked out in one worktree at a time. Use a different branch name.

**Can't see changes from other worktrees**
→ This is expected! Each worktree is isolated. Merge to main to share changes.

**Worktree left in broken state**
→ Run: `git worktree prune` to clean up metadata

**Lost track of active worktrees**
→ Run: `/worktree-list` or `wtp list` to see all active worktrees

### Resources

- Tool: [wtp](https://github.com/satococoa/wtp) - Git worktree manager
- Docs: [Git Worktree](https://git-scm.com/docs/git-worktree) - Official git documentation
- Guide: See `worktrees.md` in this repository for comprehensive documentation

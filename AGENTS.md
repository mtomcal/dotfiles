# AI Agent Instructions

This file provides guidance to AI coding agents (Claude Code, Pi, and others) when working with code in this repository.

## Repository Overview

Personal dotfiles repository for a tmux + neovim + zsh development environment. The repository uses a symlink-based architecture to maintain configurations in version control while deploying them to standard system locations.

## Installation and Setup

The primary entry point is `./install.sh`, which:
- Auto-detects OS (Ubuntu/Debian via apt, or macOS via brew)
- Installs dependencies (tmux, neovim 0.10+, zsh, ripgrep, fd, build tools)
- Sets up Oh My Zsh framework
- Clones official kickstart.nvim to `~/.config/nvim`
- Creates symlinks for configurations (and seeds local Codex config from template)
- Installs TUI tools (lazygit, yazi, zoxide) with config symlinks
- Installs Go (Golang) 1.24+ with architecture detection (x86_64/arm64)
- Installs fnm (Fast Node Manager) and Node.js LTS
- Links AI coding assistant configurations (Codex CLI, Claude Code, Pi)
- Installs Codex CLI, Pi coding agent, and Gemini CLI
- Sets up Mason LSP/formatter packages (Python, Go, Lua)

**Key behavior**: The script is idempotent and safe to re-run for updates.

## Architecture

### Configuration Strategy

**Philosophy**: Use official upstream configurations (kickstart.nvim) as base, layer custom configs on top via symlinks.

**Symlink structure**:
- `~/.tmux.conf` → `~/dotfiles/tmux/.tmux.conf`
- `~/.config/nvim/lua/custom/` → `~/dotfiles/nvim/custom/`
- **lazygit**: `~/.config/lazygit/config.yml` → `~/dotfiles/lazygit/config.yml`
- **yazi**: `~/.config/yazi/{yazi,keymap,theme}.toml` → `~/dotfiles/yazi/*.toml`
- **Shared skills** (all agents):
  - All agent skill paths → `~/dotfiles/shared/skills/` (single canonical source)
  - Skills installed via `npx skills@latest add` into any agent's skills dir land directly in `shared/skills/` via the symlink
- **Codex CLI**:
  - `~/.codex/config.toml` ← copied from `~/dotfiles/codex/config.toml` template
  - `~/.codex/agents/` → `~/dotfiles/codex/agents/`
  - `~/.codex/AGENTS.md` → `~/dotfiles/codex/AGENTS.md` (optional global instructions)
  - `~/.agents/skills/` → `~/dotfiles/shared/skills/`
- **Claude Code**:
  - `~/.claude/agents` → `~/dotfiles/claude/agents`
  - `~/.claude/skills/` → `~/dotfiles/shared/skills/`
  - `~/.claude/settings.json` → `~/dotfiles/claude/settings.json`
- **Pi Coding Agent**:
  - `~/.pi/agent/skills/` → `~/dotfiles/shared/skills/`
  - `~/.pi/agent/settings.json` → `~/dotfiles/pi/settings.json`
  - `~/.pi/agent/models.json` → `~/dotfiles/pi/models.json`
  - `~/.pi/agent/agents/` → `~/dotfiles/pi/agents/`
- **Gemini CLI**:
  - `~/.gemini/settings.json` → `~/dotfiles/gemini/settings.json`
  - `~/.gemini/commands/` → `~/dotfiles/gemini/commands/`
  - `~/.gemini/agents/` → `~/dotfiles/gemini/agents/`
  - `~/.gemini/skills/` → `~/dotfiles/shared/skills/`
- **GitHub Copilot CLI**:
  - `~/.config/copilot/agents/` → `~/dotfiles/copilot/agents/`
  - `~/.config/copilot/skills/` → `~/dotfiles/shared/skills/`
- Custom zsh config sourced in `~/.zshrc` (not symlinked)

### AI Coding Assistants

This dotfiles setup supports **Codex CLI**, **Claude Code**, **Pi**, **Gemini CLI**, and **GitHub Copilot CLI**, with **Playwright CLI** (`playwright-cli`) available for browser automation:

**Shared Skills**:
- All agents share a single canonical skills directory: `shared/skills/`
- Every agent's skills path is symlinked to `shared/skills/` — skills installed via `npx skills@latest add` to any agent land here automatically
- Frontmatter union schema: `name`, `description`, `metadata.short-description` (Codex/Pi), `allowed-tools` (Claude Code)

**Codex CLI**:
- Configuration: `codex/` directory
- Skills: `shared/skills/` (symlinked to `~/.agents/skills/`)
- Agent roles: `codex/agents/` (symlinked to `~/.codex/agents/`)
- Global config template: `codex/config.toml` (copied to local `~/.codex/config.toml`)

**Claude Code**:
- Configuration: `claude/` directory
- Agents: `claude/agents/` — includes `test-quality-verifier` for post-implementation test quality checks and `playwright-visual-qa` for browser-based Visual QA via Playwright CLI
- Settings: `claude/settings.json`

**Pi Coding Agent**:
- Configuration: `pi/` directory
- Skills: `shared/skills/` (symlinked to `~/.pi/agent/skills/`)
- Settings: `pi/settings.json` (symlinked to `~/.pi/agent/settings.json`)
- Models: `pi/models.json` (symlinked to `~/.pi/agent/models.json`)
- Agents: `pi/agents/` (symlinked to `~/.pi/agent/agents/`) — agent MD files are used by the subagent extension for named agent lookup with frontmatter configuration
- Installed via npm to `~/.local` (same pattern as Codex/Gemini)
- Multi-provider cloud agent (Anthropic, OpenAI, Google, and 30+ others)
- Extensible via TypeScript extensions, prompt templates, and themes
- **Sandbox mode**: `pis` runs Pi inside an ephemeral Docker container with full toolchains (Node.js, Python, Go, tmux). CWD is mounted read-write; extra directories can be added as positional args (read-only by default, `-rw` for read-write).
- **Subagent extension** (`pi/extensions/subagent/`): Six async-first tools replace the old single `subagent` tool:
  - `subagent_run` — blocking: single, parallel, or chain mode
  - `subagent_fork` — async: start background job(s), returns immediately, max 8 concurrent
  - `subagent_status` — list all jobs or show specific job status
  - `subagent_results` — full output of a completed job
  - `subagent_wait` — block until a specific job completes (default 300s timeout)
  - `subagent_cancel` — cancel one or all running jobs
  - Job IDs: `{agentName}-{6hex}` format (e.g., `code-reviewer-a3f2b7`)
  - Completion notifications via `pi.sendMessage({ deliverAs: "steer", triggerTurn: true })`

**Gemini CLI**:
- Configuration: `gemini/` directory (symlinked into `~/.gemini/`)
- Settings: `gemini/settings.json` → `~/.gemini/settings.json`
- User subagents (Markdown): `gemini/agents/` → `~/.gemini/agents/`
- User skills: `gemini/skills/` → `~/.gemini/skills/`
- Installed via `npm install -g --prefix ~/.local @google/gemini-cli@latest` (same `~/.local` prefix as Codex so it survives `fnm` Node version switches)
- Reference clone: `~/Code/gemini-cli` (upstream repo for docs and source spelunking)
- Authenticate by running `gemini` — first launch prompts for Google account / API key

**GitHub Copilot CLI**:
- Configuration: `copilot/` directory
- Agents: `copilot/agents/` (symlinked to `~/.config/copilot/agents/`)
- Skills: `copilot/skills/` (symlinked to `~/.config/copilot/skills/`); `playwright-cli` skill symlinked from `.claude/skills/playwright-cli`
- Installed via `curl -fsSL https://gh.io/copilot-install | bash` (binary at `~/.local/bin/copilot`)
- Authenticate by running `copilot login`
- Requires an active GitHub Copilot subscription

### Ralph — Agentic Loop Job Runner (Claude Code / Pi)

The `/ralph` command configures and launches a `loop.sh` agentic loop job. It walks through setting up three files:

- **PROMPT.md** — concise task instructions the worker reads every iteration (kept small, <20 lines)
- **IMPLEMENTATION_PLAN.md** — heavy reference with change context, task order, progress checklist, and process rules
- **ORCHESTRATOR.md** — monitoring playbook for a human or second Claude session

The worker loop runs Claude Code repeatedly against the prompt file until output contains `/done` or the iteration limit is hit. An optional orchestrator monitors progress and writes course corrections into the prompt file between iterations.

**Launch:**
```bash
# Bare metal
./loop.sh 25 PROMPT.md

# Docker sandbox
SANDBOX=1 ./loop.sh 25 PROMPT.md
```

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
- `formatting.lua` - Multi-language formatting via conform.nvim (Go, Python, JS/TS, Lua, web); `<leader>f` to format on demand, also formats on save; prettier takes precedence over eslint_d for JS/TS; both only activate when their config file is found in the project
- `indent-detect.lua` - vim-sleuth for heuristic indent auto-detection (fallback for projects without .editorconfig); EditorConfig support is built into Neovim 0.9+
- `statusline-indent.lua` - Adds indent indicator to mini.statusline (e.g. `·2` = 2-space spaces, `→4` = 4-wide tabs)

### Tmux Configuration

**Prefix key**: Ctrl-a (not default Ctrl-b)

**Critical settings** for neovim integration:
- Zero escape delay: `set -sg escape-time 0`
- True color support: `set -g default-terminal "tmux-256color"`
- Focus events enabled: `set -g focus-events on`

Vim-style navigation keybindings throughout (h/j/k/l for panes, H/J/K/L for resizing).

**Nested tmux session support**:
- **F12 toggle**: Press F12 to switch between outer and inner session control
  - When toggled to inner mode, status bar dims (darker background) as visual indicator
  - All outer tmux keybindings are disabled, commands go directly to inner session
  - Press F12 again to toggle back to outer session control
- **Double prefix**: Use `Ctrl-a Ctrl-a` to send prefix to inner session
  - Example: `Ctrl-a Ctrl-a c` creates a new window in the inner session
- **Use case**: Essential for tmux orchestration systems that manage Claude Code sessions via nested tmux
  - Outer session: Human tmux windows for general development
  - Inner session: Orchestrator managing AI agent sessions
  - F12 toggle provides clear visual indication of which session you're controlling

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
- **Pi**: Add TypeScript extensions to `~/.pi/agent/extensions/` for custom workflows

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

### AI Assistant Privacy

The `.gitignore` files in `claude/` and `pi/` exclude sensitive files (credentials, history, project data) while tracking settings and config. When modifying configs, never commit:
- `.credentials.json` or `auth.json`
- `history.jsonl`
- Project-specific data

Codex CLI stores sensitive/runtime data under `~/.codex/` (for example `auth.json`, `history.jsonl`, `sessions/`). Keep those local and out of git.

### Zsh Shell Change Detection

Recent addition (commit b41aca0) checks if zsh is already the default shell to avoid unnecessary chsh calls (install.sh:180-201).

## Common Pitfalls

1. **Symlink conflicts**: The install script backs up existing non-symlink configs with timestamps before linking
2. **Homebrew path on Apple Silicon**: Script handles `/opt/homebrew/bin/brew` vs `/usr/local/bin/brew` (install.sh:76-79)
3. **Custom plugin imports**: Must uncomment `{ import = 'custom.plugins' }` in kickstart's init.lua for custom neovim plugins to load
4. **fnm initialization**: Requires both PATH export and `fnm env` eval in shell config (zsh/.zshrc.custom:42-46)
5. **AI assistant authentication**: Each AI agent requires separate authentication setup by the user

## Command Line Aliases

Shell aliases are available for common operations:
- `lg` - Launch lazygit
- `y` - Launch yazi file manager
- `z` - zoxide smart cd (e.g. `z dotfiles` jumps to ~/dotfiles)
- `claude` - Launch Claude Code
- `pi` - Launch Pi coding agent
- `gm` or `gemini` - Launch Gemini CLI
- `cop` or `copilot` - Launch GitHub Copilot CLI
- Tmux aliases: `t`, `ta`, `tn`, `tl`, `tk`, `td`

## Working with Multiple AI Assistants

All five agents (Claude Code, Codex, Pi, Gemini, Copilot) share:
- Project context via this AGENTS.md file
- Skills via the single `shared/skills/` directory
- Choose the tool based on your needs — all have full context

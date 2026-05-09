# Dotfiles

Personal development environment configuration for tmux, neovim, and zsh.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
  - [Installation](#installation)
  - [Post-Installation](#post-installation)
- [Structure](#structure)
- [Configuration Details](#configuration-details)
  - [Tmux](#tmux)
    - [Session Management](#session-management)
    - [Windows & Panes](#windows--panes)
    - [Copy Mode](#copy-mode)
    - [Pane Layout Bindings](#pane-layout-bindings)
    - [Nested Sessions](#nested-sessions)
  - [Neovim](#neovim)
    - [General Navigation](#general-navigation)
    - [LSP (all languages)](#lsp-all-languages)
    - [Git (inside Neovim)](#git-inside-neovim)
    - [Adding Custom Plugins](#adding-custom-plugins)
  - [Zsh](#zsh)
  - [Node.js (fnm)](#nodejs-fnm)
  - [Language Development](#language-development)
    - [Python Development](#python-development)
    - [Go (Golang) Development](#go-golang-development)
  - [TUI Tools](#tui-tools)
    - [Lazygit](#lazygit)
    - [Yazi (File Manager)](#yazi-file-manager)
    - [Zoxide (Smart cd)](#zoxide-smart-cd)
  - [AI Coding Tools](#ai-coding-tools)
    - [Shared Skills](#shared-skills)
    - [Codex CLI](#codex-cli)
    - [Claude Code](#claude-code)
    - [Pi Coding Agent](#pi-coding-agent)
      - [Pi Sandbox (`pis`)](#pi-sandbox-pis)
    - [Gemini CLI](#gemini-cli)
    - [GitHub Copilot CLI](#github-copilot-cli)
- [Platform-Specific Notes](#platform-specific-notes)
  - [Ubuntu/Debian](#ubuntudebian)
  - [macOS](#macos)
- [Updating](#updating)
- [Customization](#customization)
- [Deploying to New Servers](#deploying-to-new-servers)
- [Troubleshooting](#troubleshooting)
- [Requirements](#requirements)
- [Credits](#credits)

## Features

- **Tmux**: Vim-style navigation and keybindings with optimized settings for neovim
- **Neovim**: Official [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) base with custom plugin layer
- **Zsh**: Oh My Zsh with custom aliases and tmux integration
- **TUI Tools**: lazygit, yazi file manager, zoxide smart directory jumping
- **AI Coding Tools**: Codex CLI, Claude Code, Pi, Gemini CLI, and GitHub Copilot CLI with shared instructions
- **Language Support**:
  - **Python**: Pyright LSP + Ruff linting/formatting with Poetry auto-detection
  - **Go (Golang)**: Full toolchain (gopls, delve debugger, gofumpt, goimports) with testing and debugging support
  - **Lua**: stylua formatting
- **Node.js**: fnm (Fast Node Manager) with auto-version switching
- **Git Integration**: diffview and neogit for comprehensive code review workflows
- **Cross-platform**: Supports both Ubuntu/Debian (apt) and macOS (Homebrew)


## Quick Start

### Installation

Clone this repository and run the install script:

```bash
git clone https://github.com/mtomcal/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer provides a **menu-driven interface** with multiple installation profiles:

**Interactive Mode** (default):
- Choose from preset profiles: Full, Minimal, or Work
- Or customize by selecting specific components

**Preset Profiles**:

| Profile | Includes | Best For |
|---------|----------|----------|
| **Full** | Everything (Neovim, Tmux, Zsh, Go dev, Node.js, TUI tools, AI agents) | Complete development setup |
| **Minimal** | Neovim + Tmux configs only | Quick editor setup |
| **Work** | Neovim, Tmux, TUI tools, Copilot CLI | Work machines |

**Non-Interactive Mode** (command-line flags):
```bash
# Install everything (includes Go development environment)
./install.sh --profile full

# Minimal installation (editors only)
./install.sh --profile minimal

# Work profile
./install.sh --profile work

# Custom module selection
./install.sh --modules neovim,nvim_config,tmux_config

# Go development environment
./install.sh --modules golang_full,neovim,nvim_config

# View all options
./install.sh --help
```

**Available Modules**:
- `base_tools` - Git, curl, tmux, zsh, ripgrep, jq, gh
- `neovim` - Neovim 0.10+ (AppImage on Ubuntu, Homebrew on macOS)
- `nvim_config` - Kickstart.nvim + custom plugins
- `tmux_config` - Tmux configuration with vim bindings
- `zsh_ohmyzsh` - Zsh + Oh My Zsh installation
- `zsh_config` - Custom zsh configuration
- `golang` - Go 1.24+ toolchain only (basic)
- `golang_full` - Complete Go development environment:
  - Go 1.24+ toolchain
  - gopls (LSP server)
  - delve (debugger)
  - gofumpt (formatter)
  - goimports (import manager)
  - govulncheck (security scanner)
- `nodejs` - Node.js LTS via fnm
- `tui_tools` - TUI tools (lazygit, yazi, zoxide)
- `codex` - Codex CLI + skills + agent roles
- `claude` - Claude Code CLI + MCP servers
- `pi` - Pi Coding Agent
- `pi_sandbox` - Pi Sandbox (Docker image + `pis` script)
- `gemini` - Gemini CLI (Google's open-source AI agent)
- `copilot` - GitHub Copilot CLI (curl installer, work-network friendly)

**Features**:
- Automatic dependency resolution
- Idempotent (safe to run multiple times)
- Handles partial failures gracefully
- Cross-platform (Ubuntu/Debian and macOS)

### Post-Installation

After installation completes:

```bash
# Restart your shell
source ~/.zshrc

# Start tmux
tmux

# Launch neovim
nvim
```

## Structure

```
dotfiles/
├── install.sh              # Installation script (Ubuntu + macOS)
├── README.md              # This file
├── AGENTS.md              # Shared AI agent instructions (all agents read this)
├── shared/
│   └── skills/            # Canonical skills dir — symlinked into every agent
│       ├── playwright-cli/
│       ├── playwright-visual-qa/
│       ├── test-quality-verifier/
│       ├── ralph/
│       ├── write-a-skill/
│       ├── improve-codebase-architecture/
│       ├── tmux-agent-orchestration/
│       ├── ubiquitous-language/
│       ├── audit-shared-skills/
│       └── grill-me/
├── codex/
│   ├── agents/            # Codex agent role configs (~/.codex/agents)
│   ├── config.toml        # Codex config template (copied to ~/.codex/config.toml)
│   └── README.md          # Codex documentation
├── claude/
│   ├── agents/            # Claude Code subagents

│   ├── settings.json      # Claude Code settings
│   └── README.md          # Claude Code documentation
├── pi/
│   ├── settings.json      # Pi settings (symlinked to ~/.pi/agent/)
│   ├── models.json        # Pi custom provider definitions (Ollama Cloud)
│   ├── agents/            # Subagent definitions (scout, planner, reviewer, worker)
│   ├── prompts/           # Workflow prompt templates (implement, scout-and-plan, etc.)
│   ├── extensions/        # Pi extensions (subagent tool)
│   ├── Dockerfile         # Pi sandbox Docker image
│   └── pis.sh             # Pi sandbox wrapper script (~/.local/bin/pis)
├── gemini/

│   ├── agents/            # Gemini CLI user-level subagents (Markdown)
│   ├── settings.json      # Gemini CLI settings (~/.gemini/settings.json)
│   └── README.md          # Gemini CLI documentation
├── copilot/

│   └── agents/            # Copilot CLI agents
├── lazygit/
│   └── config.yml             # lazygit configuration
├── yazi/
│   ├── yazi.toml              # Yazi general settings
│   ├── keymap.toml            # Vim keybindings + quick jumps
│   └── theme.toml             # ASCII-friendly icons (no Nerd Fonts)
├── docs/
│   └── PYTHON_DEVELOPMENT.md  # Python development guide
├── tmux/
│   ├── .tmux.conf         # Tmux configuration
│   └── reverse-panes.sh   # Helper script for Ctrl-a R pane reversal
├── zsh/
│   └── .zshrc.custom      # Custom zsh configuration
└── nvim/
    └── custom/            # Custom neovim configs (symlinked)
        └── plugins/       # Your custom plugins (6 plugins)
            ├── go.lua     # Go debugging and testing
            ├── python.lua # Python linting with Ruff
            ├── markdown.lua   # Markdown rendering
            ├── neo-tree.lua   # File explorer
            ├── diffview.lua   # Git diff viewer
            └── neogit.lua     # Git operations
```

## Configuration Details

### Tmux

**Prefix Key**: `Ctrl-a` (changed from default `Ctrl-b`)

### Session Management

| Command | Action |
|---------|--------|
| `tn work` | New session named "work" |
| `ta work` | Attach to session "work" |
| `tl` | List all sessions |
| `tk work` | Kill session "work" |
| `td` | Detach from current session |
| `Ctrl-a d` | Detach (inside tmux) |

### Windows & Panes

| Key | Action |
|-----|--------|
| `Ctrl-a c` | New window (adjacent to current) |
| `Ctrl-a \|` | Split into side-by-side panes (left/right) |
| `Ctrl-a -` | Split into stacked panes (top/bottom) |
| `Ctrl-a h/j/k/l` | Navigate panes (vim-style) |
| `Ctrl-a H/J/K/L` | Resize panes |
| `Ctrl-a Ctrl-h` | Previous window |
| `Ctrl-a Ctrl-l` | Next window |
| `Ctrl-a <` | Move current window left (swap with previous) |
| `Ctrl-a >` | Move current window right (swap with next) |
| `Ctrl-a r` | Reload config |

### Copy Mode

| Key | Action |
|-----|--------|
| `Ctrl-a [` | Enter copy mode |
| `v` | Start selection (in copy mode) |
| `y` | Yank selection to clipboard |
| `q` | Exit copy mode |

### Pane Layout Bindings

| Key | Action |
|-----|--------|
| `Ctrl-a M` | Merge current window's panes into previous window as side-by-side splits |
| `Ctrl-a B` | Break current pane into a new window |
| `Ctrl-a E` | Explode all panes into separate windows |
| `Ctrl-a V` | Rearrange panes into equal vertical columns |
| `Ctrl-a R` | Reverse order of all panes in current window |

**Features**:
- True color support
- Zero escape delay (optimized for neovim)
- Mouse support enabled
- 50,000 line scrollback
- Vim-style copy mode
- Auto tmux on SSH login (Ubuntu)
- Automatic window naming with folder name and current process
- Adjacent window creation for parallel development workflows
- Nested tmux session support for orchestration systems

**Nested Sessions**:

Perfect for managing tmux orchestration systems (like Claude Code session managers) within your existing tmux workflow.

| Key | Action |
|-----|--------|
| `F12` | Toggle control to inner session (status bar dims) |
| `F12` again | Toggle back to outer session |
| `Ctrl-a Ctrl-a <key>` | Send command to inner session directly |

*Two methods available:*

1. **F12 Toggle** (Recommended) — status bar dims as visual indicator
2. **Double Prefix** — `Ctrl-a Ctrl-a` followed by your command

*Example workflow:*
```bash
# In your outer tmux session (human windows)
tmux new-window -n orchestrator

# Inside that window, start nested tmux for orchestration
tmux new-session -s claude-orchestrator

# Now press F12 to control the inner session
# Status bar will dim to show you're in "inner mode"
# All commands now go to the orchestrator session

# Press F12 again to return control to outer session
```

*Use cases:*
- Outer session: Your human development windows
- Inner session: Automated orchestration managing AI agent sessions
- Clear visual separation prevents accidentally controlling the wrong session

### Neovim

Uses official **kickstart.nvim** as the base configuration with a custom plugin layer.

**Philosophy**: Keep kickstart.nvim clean and update-able, add customizations in a separate layer.

**Directory Structure**:
- `~/.config/nvim/` - Official kickstart.nvim (git repo)
- `~/.config/nvim/lua/custom/` - Your customizations (symlink to `~/dotfiles/nvim/custom/`)

**Updating Kickstart**:
```bash
cd ~/.config/nvim
git pull
```

Your custom configs persist across updates!

### General Navigation

| Key | Action |
|-----|--------|
| `\` | Toggle file explorer (neo-tree) |
| `<leader>sf` | Search files (Telescope) |
| `<leader>sg` | Search by grep (Telescope) |
| `<leader>sb` | Search buffers |
| `<leader>sh` | Search help tags |
| `<leader>sd` | Search diagnostics |
| `K` | Hover documentation |

### LSP (all languages)

| Key | Action |
|-----|--------|
| `grd` | Go to definition |
| `grr` | Go to references |
| `gri` | Go to implementation |
| `grt` | Go to type definition |
| `grn` | Rename symbol |
| `gra` | Code action |
| `<leader>f` | Format buffer |

### Git (inside Neovim)

**Neogit** (interactive git):

| Key | Action |
|-----|--------|
| `<leader>gg` | Open Neogit status |
| `<leader>gc` | Git commit |
| `<leader>gp` | Git pull |
| `<leader>gP` | Git push |

**Diffview** (code review):

| Key | Action |
|-----|--------|
| `<leader>dv` | Open diff view (unstaged changes) |
| `<leader>dc` | Close diff view |
| `<leader>dh` | File history (current file) |
| `<leader>df` | File history (all files) |

**Current Custom Plugins**:

1. **go.lua** - Go development with debugging and testing
   - nvim-dap-go for debugging
   - neotest-golang for test running

2. **python.lua** - Python linting with Ruff
   - Poetry project auto-detection
   - Real-time linting on save

3. **markdown.lua** - Beautiful markdown rendering
   - MeanderingProgrammer/render-markdown.nvim
   - Only loads for markdown files

4. **neo-tree.lua** - File explorer
   - SSH-friendly ASCII icons
   - Git status tracking

5. **diffview.nvim** - Git diff viewer for code review

6. **neogit.nvim** - Interactive git operations

**Adding Custom Plugins**:

Create a file in `~/dotfiles/nvim/custom/plugins/`:

```lua
-- ~/dotfiles/nvim/custom/plugins/my-plugin.lua
return {
  'author/plugin-name',
  config = function()
    require('plugin-name').setup({
      -- your config
    })
  end,
}
```

**Adding Custom Keymaps**:

Add to `~/dotfiles/nvim/custom/init.lua`:

```lua
-- Custom keymaps
vim.keymap.set('n', '<leader>x', '<cmd>MyCommand<CR>', { desc = 'My custom command' })
```

### Zsh

**Features**:
- Oh My Zsh framework
- Custom aliases for tmux and neovim
- Neovim set as default editor
- Auto-attach to tmux on SSH (Ubuntu)
- fnm (Fast Node Manager) integration

**Aliases**:

| Alias | Expands To |
|-------|------------|
| `vim`, `vi` | `nvim` |
| `lg` | `lazygit` |
| `y` | `yazi` |
| `t` | `tmux` |
| `ta <name>` | `tmux attach -t <name>` |
| `tn <name>` | `tmux new -s <name>` |
| `tl` | `tmux ls` |
| `tk <name>` | `tmux kill-session -t <name>` |
| `td` | `tmux detach` |
| `pi` | Pi coding agent (no alias, binary name) |
| `cx` | `codex` |
| `gm` | `gemini` |
| `cop` | `copilot` |

### Node.js (fnm)

**Fast Node Manager (fnm)** is included for managing Node.js versions.

**Features**:
- Automatically installed during setup
- Node.js LTS installed by default
- Auto-switches Node versions based on `.node-version` or `.nvmrc` files
- Much faster than nvm

**Usage**:
```bash
# List available Node versions
fnm list

# Install a specific version
fnm install 20

# Use a specific version
fnm use 20

# Set default version
fnm default 20

# Install latest LTS
fnm install --lts
```

**Auto-switching**: fnm automatically switches Node versions when you `cd` into directories with `.node-version` or `.nvmrc` files.

### Language Development

#### Python Development

Full Python development environment with LSP, linting, and formatting.

**Features**:
- **Pyright LSP**: Type checking and code intelligence
- **Ruff**: Fast linting and formatting
- **Poetry Detection**: Automatically uses Poetry virtual environment when detected
- **Real-time linting**: Triggers on save and edit

**Keybindings**:
- `<leader>f` - Format buffer with Ruff
- `<leader>l` - Manually trigger linting
- `K` - Show hover documentation
- `grd` - Go to definition
- `grr` - Find references

See [docs/PYTHON_DEVELOPMENT.md](docs/PYTHON_DEVELOPMENT.md) for comprehensive guide.

#### Go (Golang) Development

Complete Go development toolchain with debugging and testing support.

**Features**:
- **gopls**: Official Go LSP server
- **delve**: Go debugger with DAP integration
- **gofumpt**: Go formatter (requires Go 1.24+)
- **goimports**: Import organizer
- **neotest-golang**: Test runner integration

**Debugging Keybindings**:
- `<leader>dt` - Debug nearest test
- `<leader>db` - Toggle breakpoint
- `<leader>dc` - Continue debugging

**Testing Keybindings**:
- `<leader>tn` - Run nearest test
- `<leader>tf` - Run all tests in file
- `<leader>to` - Show test output panel
- `<leader>ts` - Toggle test summary

**Installation**:
- macOS: Via Homebrew (automatic)
- Ubuntu: Official binary with architecture detection (amd64/arm64)
- Version check: Ensures Go 1.24+ is installed

### TUI Tools

Terminal UI tools for file management, git, and navigation.

#### Lazygit

A terminal UI for git commands. Launch with `lg`.

### Navigation

| Key | Action |
|-----|--------|
| `1-5` | Switch panels (status, files, branches, commits, stash) |
| `h/l` | Cycle panels left/right |
| `j/k` | Move up/down in panel |
| `Enter` | Focus/expand item |
| `q` | Quit |
| `?` | Show all keybindings |

### Common Operations

| Key | Panel | Action |
|-----|-------|--------|
| `Space` | Files | Stage/unstage file |
| `a` | Files | Stage/unstage all |
| `c` | Files | Commit staged changes |
| `P` | Files | Push |
| `p` | Files | Pull |
| `e` | Files | Edit file in neovim |
| `Space` | Branches | Checkout branch |
| `n` | Branches | New branch |
| `M` | Branches | Merge into current |
| `r` | Branches | Rebase onto current |
| `z` | Any | Undo last action |

**Workflow**:
```
lg                    # Launch lazygit
Space (on files)      # Stage files
c                     # Open commit message editor
:wq                   # Save commit message
P                     # Push to remote
q                     # Quit
```

**Config**: `~/dotfiles/lazygit/config.yml` (auto-fetch enabled, neovim as editor)

#### Yazi (File Manager)

Blazing-fast terminal file manager with vim keybindings. Launch with `y`.

### Navigation

| Key | Action |
|-----|--------|
| `h` | Go to parent directory |
| `l` or `Enter` | Open file / enter directory |
| `j/k` | Move down/up |
| `G` | Jump to bottom |
| `g g` | Jump to top |
| `/` | Search in current directory |
| `z` | Fuzzy jump with zoxide |
| `Z` | Fuzzy jump with fzf |

### Quick Directory Jumps (custom)

| Key | Action |
|-----|--------|
| `g h` | Go to `~` (home) |
| `g d` | Go to `~/dotfiles` |
| `g p` | Go to `~/projects` |
| `g t` | Go to `/tmp` |

### File Operations

| Key | Action |
|-----|--------|
| `y` | Yank (copy) |
| `x` | Cut (mark for move) |
| `p` | Paste (complete copy/move) |
| `d` | Delete (trash) |
| `D` | Permanent delete |
| `r` | Rename |
| `a` | Create new file |
| `A` | Create new directory |
| `.` | Toggle hidden files |
| `e` | Edit in neovim |

### Selection

| Key | Action |
|-----|--------|
| `Space` | Toggle select current file |
| `v` | Enter visual mode (select range) |
| `V` | Select all in directory |
| `Esc` | Clear selection |

**Workflow: Move Files**:
```
j/k          # Navigate to file
x            # Cut (mark for move)
h/l          # Navigate to destination directory
p            # Paste (completes the move)
```

**Config**: `~/dotfiles/yazi/` (SSH-friendly ASCII icons, no Nerd Fonts required)

#### Zoxide (Smart cd)

Tracks your most-visited directories and jumps to them with partial matches.

| Command | Action |
|---------|--------|
| `z foo` | Jump to highest-ranked directory matching "foo" |
| `z foo bar` | Jump to directory matching both "foo" and "bar" |
| `z ~/projects` | Works like regular `cd` for full paths |
| `zi` | Interactive selection with fzf |
| `zoxide query -ls` | Show all tracked directories with scores |

Also integrates with yazi (`z` key).

### AI Coding Tools

Five AI coding assistants are configured:

#### Shared Skills

All five agents share a single skills directory at `shared/skills/`. Every agent's skills path is symlinked here, so a skill installed via `npx skills@latest add` into any agent lands in one canonical place and is instantly available to all agents.

**Available skills**:

| Skill | Description |
|-------|-------------|
| `playwright-cli` | Browser automation — navigate, click, fill, screenshot, and debug web pages via `playwright-cli` |
| `playwright-visual-qa` | Quick visual QA loop: screenshot, a11y snapshot, console and network checks against a URL |
| `test-quality-verifier` | Audit tests for vague assertions, improve coverage, produce a structured report |
| `ralph` | Set up and launch a `loop.sh` iterative agentic job (PROMPT.md + IMPLEMENTATION_PLAN.md + ORCHESTRATOR.md) |
| `improve-codebase-architecture` | Find and fix architectural friction — shallow modules, poor seams, testability gaps _(based on [mattpocock/skills](https://github.com/mattpocock/skills))_ |
| `tmux-agent-orchestration` | Launch, steer, and monitor parallel CLI agents in tmux with per-worker clones |
| `ubiquitous-language` | Extract a DDD-style glossary from a conversation and save it to `UBIQUITOUS_LANGUAGE.md` _(based on [mattpocock/skills](https://github.com/mattpocock/skills))_ |
| `audit-shared-skills` | Audit `shared/skills/` for cross-agent frontmatter compatibility, flag and fix issues |
| `grill-me` | Interview the user relentlessly about a plan or design, resolving each branch of the decision tree _(based on [mattpocock/skills](https://github.com/mattpocock/skills))_ |
| `write-a-skill` | Interactively create a new agent skill with proper structure and frontmatter _(based on [mattpocock/skills](https://github.com/mattpocock/skills))_ |

**Adding a new skill**:

Skills from any GitHub-hosted collection can be installed with one command. Because all agent skills paths are symlinked to `shared/skills/`, installing into any agent puts the skill everywhere.

```bash
# Install from a GitHub skills repo (e.g. mattpocock/skills)
npx skills@latest add mattpocock/skills/tdd
npx skills@latest add mattpocock/skills/grill-me
npx skills@latest add mattpocock/skills/git-guardrails-claude-code

# Browse all available skills in a collection first
npx skills@latest list mattpocock/skills

# Or create a skill from scratch (interactive)
npx skills@latest add
```

After installing, run the `audit-shared-skills` skill to verify the new skill's frontmatter is compatible across all agents.

```bash
# Or create a skill file manually
mkdir shared/skills/my-skill
nvim shared/skills/my-skill/SKILL.md
```

**Skill frontmatter schema** (required fields for all agents):

```yaml
---
name: skill-name
description: What it does. Use when [trigger condition].  # max 1024 chars
metadata:
  short-description: Short label (≤6 words)   # Codex/Pi
allowed-tools: Bash(cmd:*)                    # Claude Code only, if needed
---
```

Run the `audit-shared-skills` skill in any agent to verify all skills are compatible.

#### Codex CLI

Codex CLI is configured via `codex/` (agents + config). See `codex/README.md`.

**Authentication**:
```bash
codex login
```

#### Claude Code

See [claude/README.md](claude/README.md) for details.

**Authentication**:
```bash
claude auth login
```


#### Pi Coding Agent

Minimal, extensible terminal-based AI coding agent with 30+ provider support. Built from the [pi-mono](https://github.com/nickvdyck/pi-mono) project.

**Authentication**:
```bash
pi  # First launch prompts for authentication
```

**Features**:
- 30+ LLM providers (Anthropic, OpenAI, Google, and more)
- Ollama Cloud models (GLM 5.1, MiniMax M2.7, Kimi K2.6, DeepSeek V4 Pro/Flash)
- TypeScript extensions for custom tools and workflows
- Session tree navigation and branching
- Multiple modes: interactive TUI, print, JSON, RPC

**Usage**:
```bash
pi  # Start interactive session
```

##### Subagents

Pi includes a subagent extension for delegating tasks to specialized agents with isolated context windows. Each subagent runs as a separate `pi` process.

**Agents** (in `pi/agents/`, symlinked to `~/.pi/agent/agents/`):

| Agent | Purpose | Tools |
|-------|---------|-------|
| `scout` | Fast codebase recon, returns compressed context | read, grep, find, ls, bash |
| `planner` | Creates implementation plans (read-only) | read, grep, find, ls |
| `reviewer` | Code review for quality and security | read, grep, find, ls, bash |
| `worker` | General-purpose with full capabilities | all |

All agents inherit the active model — switch models with `Ctrl+P` and subagents follow.

**Three execution modes**:
- **Single**: `Use scout to find all authentication code`
- **Parallel**: `Run 2 scouts in parallel: one to find models, one to find providers` (max 8 tasks, 4 concurrent)
- **Chain**: `Use a chain: scout finds the code, planner creates a plan, worker implements it`

**Workflow prompts** (in `pi/prompts/`, symlinked to `~/.pi/agent/prompts/`):

| Prompt | Flow |
|--------|------|
| `/implement <task>` | scout → planner → worker |
| `/scout-and-plan <task>` | scout → planner (no implementation) |
| `/implement-and-review <task>` | worker → reviewer → worker |

##### Pi Sandbox (`pis`)

Run Pi inside a Docker container for safe agentic coding. The container is ephemeral — destroyed after each session. Your project directory is mounted read-write; everything else on the host is isolated. Pi runs inside a tmux session, enabling the tmux orchestration skill to spawn additional Pi agents in separate panes/windows.

**Prerequisites**: Docker must be installed. The image builds automatically on first run.

**Basic usage**:
```bash
pis                     # Run pi in cwd (sandboxed)
pis --build             # Rebuild the Docker image
```

**Mounting extra directories** (read-only by default):
```bash
pis ~/Code/shared-lib                    # Mount read-only
pis -rw ~/Code/shared-lib               # Mount read-write
pis ~/Code/lib1 ~/Code/lib2             # Multiple dirs (both read-only)
pis -rw ~/Code/lib1 ~/Code/lib2         # First read-write, second read-only
```

**Passing arguments to Pi** (use `--` separator):
```bash
pis -- --mode print -p "fix the tests"  # Pi args after --
pis ~/Code/lib -- --mode rpc            # Extra dir + pi args
```

**What's mounted in the container**:

| Host path | Container path | Mode |
|-----------|---------------|------|
| Current directory | Same absolute path | read-write |
| Extra directories | Same absolute path | read-only (or `-rw`) |
| `~/.pi/agent/sessions/` | `/root/.pi/agent/sessions/` | read-write |
| `~/.pi/agent/auth.json` | `/root/.pi/agent/auth.json` | read-only |
| `~/.pi/agent/settings.json` | `/root/.pi/agent/settings.json` | read-only |
| `~/.pi/agent/models.json` | `/root/.pi/agent/models.json` | read-only |
| `~/.pi/agent/skills/` | `/root/.pi/agent/skills/` | read-only |
| `~/.pi/agent/agents/` | `/root/.pi/agent/agents/` | read-only |
| `~/.pi/agent/prompts/` | `/root/.pi/agent/prompts/` | read-only |
| `~/.pi/agent/extensions/` | `/root/.pi/agent/extensions/` | read-only |

**Environment**: API key env vars (`*_API_KEY`) are forwarded automatically.

**Container toolchains**: Ubuntu 24.04, Node.js LTS (fnm), Python 3, Go 1.24+, tmux, git, ripgrep, fd, jq, gh, build-essential, zsh.

#### Gemini CLI

[Google's open-source AI agent](https://github.com/google-gemini/gemini-cli) for the terminal,
backed by Gemini models with a generous free tier (60 req/min, 1000 req/day with a personal
Google account). See [gemini/README.md](gemini/README.md) for details.

**Authentication**:
```bash
gemini  # First launch prompts for Google account / API key
```

**Features**:
- User-level subagents in `~/.gemini/agents/`
- User-level skills in `~/.gemini/skills/`
- MCP server support via `~/.gemini/settings.json`

**Usage**:
```bash
gemini  # or `gm`
```

#### GitHub Copilot CLI

GitHub's AI coding assistant for the terminal, requires an active Copilot subscription.

**Installation**: Uses `curl -fsSL https://gh.io/copilot-install | bash` (work-network friendly, no npm required).

**Authentication**:
```bash
copilot login
```

**Features**:
- Skills in `~/.config/copilot/skills/` (symlinked to `shared/skills/`)
- Included in both **full** and **work** profiles

**Usage**:
```bash
copilot  # or `cop`
```

**Adding Custom Skills** (shared across all agents):

```bash
# Install from a GitHub skills collection
npx skills@latest add mattpocock/skills/tdd

# Or create manually — lands in shared/skills/ and is available everywhere
mkdir ~/dotfiles/shared/skills/my-skill
nvim ~/dotfiles/shared/skills/my-skill/SKILL.md
```


## Platform-Specific Notes

### Ubuntu/Debian

**Dependencies Installed**:
- git, curl, tmux, neovim, zsh
- build-essential (C compiler)
- ripgrep, fd-find (telescope searching)
- xclip (clipboard support)
- python3-venv (Python virtual environments)

**Neovim Installation**:
- Downloads official AppImage (v0.11.5) with architecture detection (x86_64/arm64)
- Script offers upgrade if current version is < 0.10
- Installs to `/usr/local/bin/nvim` (with sudo) or `~/.local/bin/nvim` (without)

**Go Installation**:
- Official binary from golang.org
- Architecture detection (amd64/arm64)
- Version 1.24+ installed
- PATH: `/usr/local/go/bin` and `$HOME/go/bin`

**Clipboard**:
- Uses xclip for system clipboard integration

### macOS

**Dependencies Installed**:
- git, curl, tmux, neovim, zsh
- gcc (C compiler via Homebrew)
- ripgrep, fd (telescope searching)

**Neovim Installation**:
- Installs/updates neovim via Homebrew (always latest)

**Go Installation**:
- Via Homebrew (go package)
- Version checking and upgrade prompts
- Automatic PATH configuration

**Clipboard**:
- Uses built-in pbcopy/pbpaste

**Homebrew**:
- Script will install Homebrew if not present
- Supports both Intel and Apple Silicon Macs

## Updating

### Update Kickstart.nvim

```bash
cd ~/.config/nvim
git pull
```

### Update Your Dotfiles

```bash
cd ~/dotfiles
git pull
```

### Re-run Install Script

Safe to run multiple times - it will update packages and configs:

```bash
cd ~/dotfiles
./install.sh
```

## Customization

### Modifying Tmux Config

Edit `~/dotfiles/tmux/.tmux.conf` and reload:

```bash
tmux source-file ~/.tmux.conf
# or inside tmux: Ctrl-a r
```

### Modifying Zsh Config

Edit `~/dotfiles/zsh/.zshrc.custom` and reload:

```bash
source ~/.zshrc
```

### Adding Neovim Plugins

1. Create a new file in `~/dotfiles/nvim/custom/plugins/`
2. Restart neovim - lazy.nvim will auto-install

### Version Control

Commit your customizations:

```bash
cd ~/dotfiles
git add .
git commit -m "feat: add custom neovim plugins"
git push
```

## Deploying to New Servers

On a new Ubuntu server or Mac:

```bash
# Clone your dotfiles
git clone https://github.com/mtomcal/dotfiles.git ~/dotfiles

# Run install script
cd ~/dotfiles
./install.sh

# Restart shell
exec zsh
```

Everything will be configured automatically!

## Troubleshooting

### Neovim plugins not loading

Clean cache and reinstall:
```bash
rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
nvim --headless "+Lazy! sync" +qa
```

### Tmux colors look wrong

Ensure your terminal supports true color. Check with:
```bash
echo $TERM
```

Should be `xterm-256color` or similar.

### Zsh not default shell

Run:
```bash
chsh -s $(which zsh)
```

Then log out and back in.

### Custom configs not loading in neovim

Check symlink:
```bash
ls -la ~/.config/nvim/lua/custom
```

Should point to `~/dotfiles/nvim/custom`

## Requirements

### Ubuntu/Debian
- Ubuntu 20.04+ or Debian 11+
- sudo access
- Internet connection

### macOS
- macOS 11+ (Big Sur or later)
- Xcode Command Line Tools (installed automatically if needed)
- Internet connection

## Credits

- [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) - Neovim configuration by TJ DeVries
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) - Zsh framework
- [tmux](https://github.com/tmux/tmux) - Terminal multiplexer
- [mattpocock/skills](https://github.com/mattpocock/skills) - Original source for `improve-codebase-architecture`, `ubiquitous-language`, `grill-me`, and `write-a-skill` skills (modified for cross-agent compatibility)

## License

MIT

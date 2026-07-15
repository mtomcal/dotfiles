# Dotfiles

Personal development environment configuration for Herdr, tmux fallback, neovim, and zsh.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
  - [Installation](#installation)
  - [Post-Installation](#post-installation)
- [Testing](#testing)
- [Structure](#structure)
- [Configuration Details](#configuration-details)
  - [Herdr](#herdr)
    - [Agent Integrations](#agent-integrations)
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

- **Herdr**: Default terminal workspace manager for persistent agent/workspace sessions
- **Tmux**: Legacy fallback with vim-style navigation and keybindings optimized for neovim
- **Neovim**: Official [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) base with custom plugin layer
- **Zsh**: Oh My Zsh with custom aliases and Herdr-first SSH auto-attach
- **TUI Tools**: lazygit, yazi file manager, zoxide smart directory jumping
- **AI Coding Tools**: Codex CLI, Claude Code, Pi, and GitHub Copilot CLI with shared instructions
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
| **Full** | Everything (Neovim, Tmux fallback, Herdr, Zsh, Go dev, Node.js, TUI tools, AI agents) | Complete development setup |
| **Minimal** | Neovim + Tmux fallback + Herdr | Quick editor and workspace setup |
| **Work** | Neovim, Tmux fallback, Herdr, TUI tools, Copilot CLI | Work machines |

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

# Herdr workspace manager and agent integrations
./install.sh --modules herdr,herdr_config,herdr_integrations

# View all options
./install.sh --help
```

**Available Modules**:
- `base_tools` - Git, curl, tmux, zsh, ripgrep, jq, gh
- `neovim` - Neovim 0.10+ (AppImage on Ubuntu, Homebrew on macOS)
- `nvim_config` - Kickstart.nvim + custom plugins
- `tmux_config` - Tmux configuration with vim bindings
- `herdr` - Herdr terminal workspace manager via official curl installer
- `herdr_config` - Symlinks `herdr/config.toml` to `~/.config/herdr/config.toml`
- `herdr_integrations` - Deploys repo-owned Herdr hooks and Pi integration wiring
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

# Start Herdr
herdr

# Launch neovim
nvim
```

## Testing

Run the shell test suite with:

```bash
bash tests/run.sh
```

The runner syntax-checks the shell test files, discovers `tests/*.test.sh` in sorted order, and runs each file. Use this before committing changes to `install.sh`, installer helpers, or shell test coverage. Full installer changes still need platform/idempotency checks beyond these unit-style tests.

## Structure

```
dotfiles/
├── install.sh              # Installation script (Ubuntu + macOS)
├── README.md              # This file
├── AGENTS.md              # Shared AI agent instructions (all agents read this)
├── tests/                 # Shell test runner, harness, and install-script tests
├── shared/
│   └── skills/            # Canonical skill catalog — exposed to all agents
│       ├── playwright/
│       ├── video-to-contact-sheet/
│       ├── create-plan/
│       ├── teach/
│       ├── research/
│       ├── code-review/
│       ├── herdr/
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
│   ├── extensions/        # Pi extensions (web-search, inherit-last-model, herdr-agent-state)
│   ├── settings.json      # Pi settings (~/.pi/agent/settings.json)
│   ├── models.json        # Pi model/provider config (~/.pi/agent/models.json)
│   ├── skills/            # Pi-visible skills
│   ├── pi.sh              # Pi wrapper (~/.local/bin/pi)
│   ├── pis.sh             # Pi sandbox wrapper (~/.local/bin/pis)
│   └── Dockerfile         # Pi sandbox Docker image
├── herdr/
│   ├── config.toml        # Herdr config (~/.config/herdr/config.toml)
│   └── integrations/      # Repo-owned Herdr hooks for claude/codex/copilot
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
            ├── python.lua # Python LSP (pyright) + ruff linting
            ├── markdown.lua   # Markdown rendering
            ├── neo-tree.lua   # File explorer
            ├── diffview.lua   # Git diff viewer
            └── neogit.lua     # Git operations
```

## Configuration Details

### Herdr

Herdr is the primary terminal workspace manager for persistent workspaces, tabs, panes, and AI agent session reporting. Tmux remains installed and configured as a fallback, especially for older workflows and sandboxed sessions.

**Config**:

| Source | Target |
|--------|--------|
| `herdr/config.toml` | `~/.config/herdr/config.toml` |

**Basic commands**:

| Command | Action |
|---------|--------|
| `herdr` or `h` | Start Herdr |
| `ha` | Attach to a Herdr session |
| `hl` | List Herdr sessions |
| `hu` | Update Herdr |

#### Agent Integrations

The `herdr_integrations` module deploys repo-owned integration artifacts from `herdr/integrations/{claude,codex,copilot}/` so Herdr can report agent session state:

| Agent | Integration |
|-------|-------------|
| Claude Code | `herdr/integrations/claude/herdr-agent-state.sh` symlinked into `~/.claude/hooks/` |
| Codex CLI | `herdr/integrations/codex/herdr-agent-state.sh` symlinked into `~/.codex/` |
| GitHub Copilot CLI | `herdr/integrations/copilot/herdr-agent-state.sh` symlinked into `~/.config/copilot/hooks/` |
| Pi | `pi/extensions/herdr-agent-state/` deployed to `~/.pi/agent/extensions/` |

Agents also share the `shared/skills/herdr/` skill, which lets agents running inside Herdr inspect panes, split workspaces, wait on output, and coordinate other panes through the `herdr` CLI.

Re-run integrations after changing agent config:

```bash
./install.sh --modules herdr,herdr_config,herdr_integrations
```

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
| `y` | Yank selection to clipboard (tmux buffer + system via xclip/OSC 52) |
| `q` | Exit copy mode |
| `Ctrl-a =` | Choose from all tmux buffers to paste |

### Copy & Paste over SSH (Tmux + Neovim)

Copying and pasting between a remote server and your local machine is a multi-layer problem: your local terminal emulator, the SSH connection, tmux, and neovim all have their own clipboard/buffer systems. Here's how to make it seamless.

#### How the Layers Work

```
Local Machine                          Remote Server
┌──────────────┐     SSH      ┌─────────────────────────┐
│ Terminal     │◄───────────►│ tmux (buffers)          │
│ (OS clip)    │              │  ├─ neovim (registers)   │
│              │              │  └─ shell (stdin/stdout) │
└──────────────┘              └─────────────────────────┘
```

By default, the remote server has no direct access to your local clipboard. Tmux's `set-clipboard on` and the `xclip` pipe only work when the remote has a running X server. Over SSH, you need **OSC 52** — a terminal escape sequence that writes to your local clipboard through the terminal emulator itself.

#### Method 1: Tmux Copy Mode (Works Everywhere, Zero Setup)

The simplest approach — yank text into tmux's internal buffer, then use your terminal's native selection to get it locally.

**Copy from remote to local:**

1. `Ctrl-a [` — enter tmux copy mode
2. Navigate with vim keys (`h/j/k/l`, `/` to search, `w/b` for words)
3. `v` — start visual selection
4. Move to select text, then `y` — yank to tmux buffer
5. Hold **Shift** and select the text with your mouse — this bypasses tmux mouse handling and uses your terminal's native selection, which goes straight to your local system clipboard

**Why this works:** Most terminals (iTerm2, kitty, Alacritty, Terminal.app) copy mouse-selected text to the system clipboard. Holding Shift tells the terminal to use its own selection rather than forwarding the mouse event to tmux.

**Paste from local to remote:**
- **In any tmux pane:** `⌘V` (macOS) or `Ctrl+Shift+V` (Linux) in your terminal — this sends text as keyboard input
- **From tmux buffer:** `Ctrl-a ]` pastes the last tmux buffer
- **Choose buffer:** `Ctrl-a =` to browse all tmux buffers and pick one

#### Method 2: OSC 52 Clipboard (Seamless Neovim Integration)

OSC 52 lets the remote server write directly to your local clipboard via terminal escape codes. Configure this once and `"+y` / `"+p` in neovim will work over SSH — just like they do on your local machine.

**Step 1: Check your terminal supports OSC 52**

| Terminal | OSC 52 Support |
|----------|---------------|
| iTerm2 | ✅ Built-in (enable in Preferences → General → "Applications in terminal may access clipboard") |
| kitty | ✅ Built-in (no config needed) |
| WezTerm | ✅ Built-in |
| Alacritty | ✅ Built-in |
| Terminal.app (macOS) | ❌ Not supported |
| Windows Terminal | ✅ Built-in |
| Ghostty | ✅ Built-in |

**Step 2: Enable OSC 52 passthrough in tmux**

This config ships with OSC 52 terminal features enabled. These lines in `tmux/.tmux.conf` tell tmux to forward the escape sequences instead of eating them:

```tmux
# Already in your tmux/.tmux.conf — no changes needed
set -g set-clipboard on
set -as terminal-features ",tmux-256color*:clipboard"
set -as terminal-features ",xterm-256color*:clipboard"
```

Reload after changes: `Ctrl-a r` or `tmux source-file ~/.tmux.conf`

**Step 3: Configure neovim for OSC 52**

Neovim 0.10+ includes `vim.ui.clipboard.osc52` built-in — no plugins required. Add this to your neovim config:

```lua
-- Add to lua/custom/init.lua (create if it doesn't exist)
-- or add as a new plugin file in lua/custom/plugins/

-- OSC 52 clipboard provider — makes "+y / "+p work over SSH
vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}
```

**After setup, these neovim commands work over SSH:**
- `"+y` / `"*y` — yank to local system clipboard
- `"+p` / `"*p` — paste from local system clipboard
- `"+d` / `"*d` — cut to local system clipboard
- Visual select then `y` (with `set clipboard+=unnamedplus`) — auto-yanks to system clipboard

#### Method 3: Tmux Buffers as a Bridge (No Terminal Support Needed)

When OSC 52 isn't available (e.g., Terminal.app on macOS), use tmux buffers and shell pipes:

```bash
# Remote → Local: dump last tmux buffer to local clipboard
# Run this on the remote machine — the pipe writes through SSH to your local:
tmux show-buffer | pbcopy           # macOS local machine

# If you're on a Linux remote SSH'd from a Linux local:
tmux show-buffer | ssh $LOCAL_HOST 'xclip -selection clipboard'

# Local → Remote: send local clipboard to tmux buffer
pbpaste | tmux load-buffer -         # macOS local → remote tmux
xclip -o -selection clipboard | tmux load-buffer -   # Linux local → remote tmux
# Then paste in tmux with: Ctrl-a ]
```

#### Quick Reference: Copy/Paste Cheat Sheet

| Task | Where | How |
|------|-------|-----|
| Copy remote text to local | Tmux | `Ctrl-a [`, `v`, select, `y`, then **Shift+mouse-select** |
| Paste local text to remote | Terminal | `⌘V` or `Ctrl+Shift+V` |
| Yank to system clipboard | Neovim (SSH) | `"+y` (requires OSC 52 from Method 2) |
| Paste from system clipboard | Neovim (SSH) | `"+p` (requires OSC 52 from Method 2) |
| Paste last tmux buffer | Tmux/Shell | `Ctrl-a ]` |
| Browse all tmux buffers | Tmux | `Ctrl-a =` (select with `j/k`, Enter to paste) |
| List all tmux buffers | Shell | `tmux list-buffers` |
| Copy tmux buffer to macOS clipboard | Shell (SSH) | `tmux show-buffer \| pbcopy` |
| Send macOS clipboard to tmux buffer | Shell (SSH) | `pbpaste \| tmux load-buffer -` |

#### Common SSH Copy/Paste Pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| `"+y` in neovim does nothing over SSH | No clipboard provider configured for headless remote | Set up OSC 52 (Method 2) or use tmux copy mode (Method 1) |
| Mouse selection disappears when I release the button | Tmux mouse mode is intercepting | Hold **Shift** while selecting — forces terminal-native selection |
| `xclip: command not found` or DISPLAY errors on remote | Remote has no X display | Use OSC 52 (Method 2), or Shift+mouse-select (Method 1) |
| Pasting indented code gets cascading indentation | Neovim auto-indent in insert mode | Use `:set paste` before pasting, or paste with `"+p` in normal mode |
| Large copies (>1MB) are slow with OSC 52 | Escape sequence overhead | Use `scp` or `rsync` for files; OSC 52 is for snippets |

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
- Fallback SSH multiplexer when `DOTFILES_SSH_MULTIPLEXER=tmux`
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

### Clipboard & Yank History

A `TextYankPost` autocmd syncs **only explicit yanks** (`y`, `yw`, `yiw`, etc.) to the system clipboard (`+` register). Deletes (`dd`, `x`, `c`) stay in the unnamed register only — `vim.v.event.operator == 'y'` gates the sync.

**How it works**: kickstart.nvim sets `clipboard=unnamedplus` via `vim.schedule` at startup, which would push deletes to the OS clipboard. Our custom layer queues a later `vim.schedule` to clear it — no patching of kickstart required. The autocmd then handles yank→`+` explicitly, preserving register type (char/line/block). For SSH clipboard, see [Copy & Paste over SSH](#copy--paste-over-ssh-tmux--neovim).

**The delete-crushes-yank problem**: you `yiw` to yank a word, then `dd` deletes a line, and your yank is gone from the unnamed register (`""`). Two defenses:

| Method | Key | What it does |
|--------|-----|-------------|
| Paste last yank | `gp` / `gP` | Paste from register `0` — never overwritten by deletes |
| Browse registers | `<leader>pr` | Open `:registers` to find lost text in any register |

**Yank history** — yanky.nvim (loaded via `vim.pack.add`, same as other custom plugins) provides a searchable, persistent yank ring:

| Key | Action |
|-----|--------|
| `<leader>py` | Browse yank history with Telescope (search, preview, paste) |
| `y` | Yank to unnamed register + yank ring |
| `p` / `P` | Paste; repeat `p` to cycle through recent yanks |

Example: recover a yank crushed by a delete:
```
yiw                  # Yank inner word
dd                   # Delete a line (crushed your yank)
gp                   # Paste from register 0 — your yank is still there!

# Or browse all history:
<leader>py           # Telescope yank history — search, preview, paste
```

**Numbered registers reference:**

| Register | Holds | Recover with |
|----------|-------|-------------|
| `""` | Last yank or delete (unnamed) | `p` |
| `"0` | Last yank only | `"0p` or `gp` |
| `"1` | Last delete (>1 line) | `"1p` |
| `"2`–`"9` | Older deletes (shift down) | `"2p`, `"3p`, ... |
| `"-` | Small deletes (<1 line) | `"-p` |
| `"+` | System clipboard | `"+p` (synced from unnamed) |

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

2. **python.lua** - Python LSP (pyright) + ruff linting
   - pyright: go-to-definition, hover, autocomplete, type checking
   - ruff: fast linting with Poetry auto-detection
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
- Auto-attach to Herdr on SSH, with tmux fallback via `DOTFILES_SSH_MULTIPLEXER=tmux`
- fnm (Fast Node Manager) integration

**SSH multiplexer selection**:

| Setting | Behavior |
|---------|----------|
| unset / `DOTFILES_SSH_MULTIPLEXER=herdr` | Start Herdr on SSH login |
| `DOTFILES_SSH_MULTIPLEXER=tmux` | Attach/create tmux session `${TMUX_AUTO_SESSION:-0}` |
| `DOTFILES_SSH_MULTIPLEXER=none` | Do not auto-start a multiplexer |

**Aliases**:

| Alias | Expands To |
|-------|------------|
| `vim`, `vi` | `nvim` |
| `lg` | `lazygit` |
| `y` | `yazi` |
| `h` | `herdr` |
| `ha` | `herdr session attach` |
| `hl` | `herdr session list` |
| `hu` | `herdr update` |
| `t` | `tmux` |
| `ta <name>` | `tmux attach -t <name>` |
| `tn <name>` | `tmux new -s <name>` |
| `tl` | `tmux ls` |
| `tk <name>` | `tmux kill-session -t <name>` |
| `td` | `tmux detach` |
| `pi` | Pi coding agent (no alias, binary name) |
| `cx` | `codex` |
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

Four AI coding assistants are configured:

#### Shared Skills

Codex, Claude, Pi, and Copilot share a single skills directory at `shared/skills/`. Non-Pi agents symlink their skills path directly to it; Pi exposes shared skills through `pi/skills/`.

**Workflow highlights** (run `ls shared/skills/` for the complete catalog):

| Skill | Description |
|-------|-------------|
| `playwright` | Browser automation, scripted capture, and Playwright test workflows |
| `video-to-contact-sheet` | Convert recordings into trimmed clips, contact sheets, and focused crops |
| `create-plan` | Operate a recoverable plan workspace of dependency-ordered TDD slices and verification artifacts |
| `teach` | Build a durable, researched teaching workspace with HTML lessons and learning records |
| `code-review` | Review a fixed diff independently against repository standards and originating requirements |
| `research` | Produce durable primary-source-backed investigation artifacts |
| `test-quality-verifier` | Audit tests for vague assertions, improve coverage, produce a structured report |
| `improve-codebase-architecture` | Find architecture deepening opportunities and present a visual HTML review _(adapted from [mattpocock/skills](https://github.com/mattpocock/skills))_ |
| `herdr` | Control Herdr workspaces, tabs, panes, agent status, and output from inside a Herdr pane |
| `ubiquitous-language` | Extract a DDD-style glossary from project evidence _(adapted from [mattpocock/skills](https://github.com/mattpocock/skills))_ |
| `audit-shared-skills` | Audit `shared/skills/` for cross-agent frontmatter compatibility, flag and fix issues |
| `grill-me` | Resolve design branches through evidence-grounded, term-aware interviewing |
| `write-a-skill` | Create or revise cross-agent skills with progressive disclosure and completion criteria |

**Adding a new skill**:

Skills from any GitHub-hosted collection can be installed with one command. Because shared skills are canonical, installing into a supported agent puts the skill in `shared/skills/`.

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
- Herdr agent-state extension enabled in the Pi runtime
- Session tree navigation and branching
- Multiple modes: interactive TUI, print, JSON, RPC

**Usage**:
```bash
pi                 # Start interactive session
```

**Config layout**:

The installer preserves the npm-installed executable as `~/.local/bin/pi-bin`, then installs the repo wrapper at `~/.local/bin/pi`. Pi reads one repo-owned config tree at `~/.pi/agent`.

| Target | Source |
|--------|--------|
| `~/.pi/agent/settings.json` | `pi/settings.json` |
| `~/.pi/agent/models.json` | `pi/models.json` |
| `~/.pi/agent/skills` | `pi/skills` |
| `~/.pi/agent/extensions/herdr-agent-state` | `pi/extensions/herdr-agent-state` |
| `~/.pi/agent/extensions/inherit-last-model` | `pi/extensions/inherit-last-model` |
| `~/.pi/agent/extensions/web-search` | `pi/extensions/web-search` |

Sessions and auth stay local under `~/.pi/agent/` and are not tracked.

##### Pi Sandbox (`pis`)

Run Pi inside a Docker container for safe agentic coding. The container is ephemeral — destroyed after each session. Your project directory is mounted read-write; everything else on the host is isolated. Pi runs inside a tmux session for stable terminal behavior inside the container.

**Prerequisites**: Docker must be installed. The image builds automatically on first run.

**Basic usage**:
```bash
pis                     # Run Pi in cwd (sandboxed)
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
| `~/.pi/agent/sessions/` | `/home/<user>/.pi/agent/sessions/` | read-write |
| `~/.pi/agent/auth.json` | `/home/<user>/.pi/agent/auth.json` | read-only |
| `~/.pi/agent/settings.json` | `/home/<user>/.pi/agent/settings.json` | read-only |
| `~/.pi/agent/models.json` | `/home/<user>/.pi/agent/models.json` | read-only |
| `~/.pi/agent/skills/` | `/home/<user>/.pi/agent/skills/` | read-only |
| `~/.pi/agent/extensions/` | `/home/<user>/.pi/agent/extensions/` | read-only |

**Environment**: API key env vars (`*_API_KEY`) are forwarded automatically.

**Container toolchains**: Ubuntu 24.04, Node.js LTS (fnm), Python 3, Go 1.24+, tmux, git, ripgrep, fd, jq, gh, build-essential, zsh.

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

To refresh only Herdr and its managed integrations:

```bash
./install.sh --modules herdr,herdr_config,herdr_integrations
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

### Herdr agent sessions not showing

Refresh Herdr and the managed agent integrations:

```bash
cd ~/dotfiles
./install.sh --modules herdr,herdr_config,herdr_integrations
```

Then verify the expected links exist:

```bash
ls -la ~/.config/herdr/config.toml
ls -la ~/.claude/hooks/herdr-agent-state.sh
ls -la ~/.codex/herdr-agent-state.sh
ls -la ~/.config/copilot/hooks/herdr-agent-state.sh
```

Start an agent inside Herdr and check that the pane reports agent state:

```bash
herdr pane list
```

For Pi, rerun the `pi` install module after changing tracked Pi config or extension sources.

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

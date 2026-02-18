# Dotfiles

Personal development environment configuration for tmux, neovim, and zsh.

## Features

- **Tmux**: Vim-style navigation and keybindings with optimized settings for neovim
- **Neovim**: Official [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) base with custom plugin layer
- **Zsh**: Oh My Zsh with custom aliases and tmux integration
- **AI Coding Tools**: Codex CLI, Claude Code, and OpenCode CLI with shared instructions
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
| **Full** | Everything (Neovim, Tmux, Zsh, Go dev, Node.js, AI agents) | Complete development setup |
| **Minimal** | Neovim + Tmux configs only | Quick editor setup |
| **Work** | Neovim, Tmux, OpenCode (no personal tools) | Work machines |

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
- `codex` - Codex CLI + skills + agent roles
- `claude` - Claude Code CLI + MCP servers
- `opencode` - OpenCode CLI

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
├── AGENTS.md              # Shared AI agent instructions
├── codex/
│   ├── agents/            # Codex agent role configs (~/.codex/agents)
│   ├── skills/            # Codex skills (~/.agents/skills)
│   ├── config.toml        # Codex global config (~/.codex/config.toml)
│   └── README.md          # Codex documentation
├── claude/
│   ├── agents/            # Custom AI agents (available for future use)
│   ├── commands/          # Claude Code slash commands
│   │   └── ralph.md      # Agentic loop job runner
│   ├── settings.json      # Claude Code settings
│   └── README.md          # Claude Code documentation
├── opencode/
│   ├── commands/          # OpenCode CLI commands (available for future use)
│   ├── agents/            # OpenCode CLI agents (available for future use)
│   └── README.md          # OpenCode documentation
├── docs/
│   └── PYTHON_DEVELOPMENT.md  # Python development guide
├── tmux/
│   └── .tmux.conf         # Tmux configuration
├── zsh/
│   └── .zshrc.custom      # Custom zsh configuration
└── nvim/
    ├── README.md          # Neovim setup documentation
    └── custom/            # Custom neovim configs (symlinked)
        ├── README.md      # Custom config documentation
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

**Key Bindings**:
- `Ctrl-a |` - Split window vertically
- `Ctrl-a -` - Split window horizontally
- `Ctrl-a h/j/k/l` - Navigate panes (vim-style)
- `Ctrl-a H/J/K/L` - Resize panes (vim-style)
- `Ctrl-a c` - Create new window (adjacent to current window)
- `Ctrl-a d` - Detach from session
- `Ctrl-a r` - Reload tmux config
- `Ctrl-a [` - Enter copy mode (use vim keys)
- `F12` - Toggle nested tmux session control (see Nested Sessions below)

**Aliases** (in zsh):
- `t` - Start tmux
- `ta <session>` - Attach to session
- `tn <session>` - New session
- `tl` - List sessions
- `tk <session>` - Kill session
- `td` - Detach

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

*Two methods available:*

1. **F12 Toggle** (Recommended)
   - Press `F12` to toggle between outer and inner session control
   - Visual indicator: Status bar dims when controlling inner session
   - Press `F12` again to toggle back to outer session

2. **Double Prefix**
   - Use `Ctrl-a Ctrl-a` followed by your command
   - Example: `Ctrl-a Ctrl-a c` creates a new window in the inner session

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

**Current Custom Plugins**:

1. **go.lua** - Go development with debugging and testing
   - nvim-dap-go for debugging
   - neotest-golang for test running
   - Keybindings: `<leader>dt` (debug test), `<leader>db` (breakpoint), `<leader>tn` (nearest test)

2. **python.lua** - Python linting with Ruff
   - Poetry project auto-detection
   - Real-time linting on save
   - Keybindings: `<leader>l` (lint)

3. **markdown.lua** - Beautiful markdown rendering
   - MeanderingProgrammer/render-markdown.nvim
   - Only loads for markdown files

4. **neo-tree.lua** - File explorer
   - SSH-friendly ASCII icons
   - Git status tracking

5. **diffview.nvim** - Git diff viewer
   - Perfect for code review
   - Keybindings: `<leader>dv` (open), `<leader>dc` (close), `<leader>dh` (history)

6. **neogit.nvim** - Interactive git operations
   - Keybindings: `<leader>gg` (open), `<leader>gc` (commit), `<leader>gp` (pull)

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
- `vim` → `nvim`
- `vi` → `nvim`
- All tmux aliases listed above

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

### AI Coding Tools

Three AI coding assistants are configured:

#### Codex CLI

Codex CLI is configured via `codex/` (skills + agent roles). See `codex/README.md`.

**Authentication**:
```bash
codex login
```

#### Claude Code

Custom `/ralph` skill for running agentic loop jobs. See [claude/README.md](claude/README.md) for details.

**Authentication**:
```bash
claude auth login
```

**Available Commands**:
- `/ralph` - Configure and launch `loop.sh` agentic loop jobs (PROMPT.md + IMPLEMENTATION_PLAN.md + ORCHESTRATOR.md)

#### OpenCode CLI

Multi-model AI coding assistant with terminal TUI. See [opencode/README.md](opencode/README.md) for details.

**Authentication**:
```bash
opencode auth login
```

**Features**:
- Plan/Build mode switching
- OpenRouter free model support
- Shared project context via AGENTS.md

**Usage**:
```bash
opencode  # Start interactive session
```

**Adding Custom Commands / Skills**:

```bash
# Codex (skills)
ls ~/dotfiles/codex/skills

# Claude Code
nvim ~/dotfiles/claude/commands/my-command.md

# OpenCode
nvim ~/dotfiles/opencode/commands/my-command.md
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

## License

MIT

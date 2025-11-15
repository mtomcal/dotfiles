# Dotfiles

Personal development environment configuration for tmux, neovim, and zsh.

## Features

- **Tmux**: Vim-style navigation and keybindings with optimized settings for neovim
- **Neovim**: Official [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) base with custom plugin layer
- **Zsh**: Oh My Zsh with custom aliases and tmux integration
- **AI Coding Tools**: Claude Code, OpenCode CLI, and GitHub Copilot CLI with custom commands and agents
- **Git Worktrees**: Parallel AI development workflow with `wtp` for running multiple agents simultaneously
- **Code Quality**: Language-agnostic code-quality-guardian agent for automated reviews
- **Node.js**: fnm (Fast Node Manager) with auto-version switching
- **Cross-platform**: Supports both Ubuntu/Debian (apt) and macOS (Homebrew)

## Quick Start

### Installation

Clone this repository and run the install script:

```bash
git clone https://github.com/mtomcal/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The install script will:
- Detect your OS (Ubuntu or macOS)
- Install required dependencies (tmux, neovim, zsh, etc.)
- Set up Oh My Zsh
- Clone official kickstart.nvim
- Link configuration files
- Install neovim plugins
- Install AI coding tools (Claude Code, OpenCode CLI, GitHub Copilot CLI)
- Install wtp (git worktree manager) for parallel AI workflows
- Configure code-quality-guardian agent for automated code reviews

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
├── claude/
│   ├── agents/            # Custom AI agents (e.g., code-quality-guardian)
│   ├── commands/          # Claude Code slash commands
│   ├── settings.json      # Claude Code settings
│   └── README.md          # Claude Code documentation
├── opencode/
│   ├── commands/          # OpenCode CLI slash commands
│   └── README.md          # OpenCode documentation
├── tmux/
│   └── .tmux.conf         # Tmux configuration
├── zsh/
│   └── .zshrc.custom      # Custom zsh configuration
└── nvim/
    ├── README.md          # Neovim setup documentation
    └── custom/            # Custom neovim configs (symlinked)
        ├── README.md      # Custom config documentation
        └── plugins/       # Your custom plugins
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
- Adjacent window creation (optimized for worktree workflows)

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

### AI Coding Tools

Three AI coding assistants are configured with custom workflows:

#### Claude Code

**Custom slash commands** and **AI agents** for enhanced development workflows. See [claude/README.md](claude/README.md) for details.

**Authentication**:
```bash
claude auth login
```

**Available Commands**:
- `/save-session` - Create detailed session summaries
- `/create_plan` - Interactive implementation planning
- `/implement_plan` - Execute approved technical plans
- `/research_codebase` - Comprehensive codebase research
- `/validate_plan` - Validate plan execution
- `/worktree_create` - Create new git worktree for parallel development
- `/worktree_merge` - Merge worktree back to main branch
- `/worktree_list` - List all active worktrees
- `/worktree_status` - Show detailed status of all worktrees

**AI Agents**:
- **code-quality-guardian** - Language-agnostic code reviewer
  - Automatically invoked after completing features, bug fixes, or refactors
  - Supports TypeScript, JavaScript, Python, Go, Rust, Java, Kotlin
  - Reviews tests, security, maintainability, and architecture
  - Provides actionable feedback with priority levels
- **documentation-updater** - Automated documentation synchronization
  - Analyzes git diffs and updates relevant documentation files
  - Keeps README.md, AGENTS.md, and other docs in sync with code changes
  - Provides specific before/after proposals with rationale
  - Maintains documentation consistency and accuracy

**Adding Custom Commands**:

Create a new markdown file in `~/dotfiles/claude/commands/`:

```bash
nvim ~/dotfiles/claude/commands/my-command.md
```

The command will be available as `/my-command` in Claude Code.

#### OpenCode CLI

Multi-model AI coding assistant with shared custom commands. See [opencode/README.md](opencode/README.md) for details.

**Authentication**:
```bash
opencode auth login
```

**Features**:
- Shares the same custom slash commands as Claude Code
- Uses the shared `AGENTS.md` for agent instructions
- Supports multiple AI models

**Usage**:
```bash
opencode  # Start interactive session
```

#### GitHub Copilot CLI

Terminal-based GitHub Copilot powered by AI. Requires Node.js v22+.

**Requirements**:
- Active GitHub Copilot subscription
- Node.js v22 or higher

**Authentication**:
```bash
copilot             # Start interactive session
# Then use /login   # Authenticate with GitHub
```

Alternatively, set a GitHub Personal Access Token with "Copilot Requests" permission:
```bash
export GH_TOKEN=your_token_here
```

**Usage**:
```bash
copilot                                    # Start interactive mode
copilot -p "explain this code"             # Non-interactive prompt
copilot --continue                         # Resume last session
copilot --model gpt-5                      # Use specific model
```

**Features**:
- Natural language terminal commands
- Code explanation and debugging
- Integration with GitHub workflows
- Powered by Claude Sonnet 4.5 by default
- Session management and resumption
- Custom agents and MCP server support

#### AI Command Helper (`ai-commands`)

**Universal command access** for AI tools that don't support custom slash commands.

**Purpose**: Makes your Claude Code custom commands available to **any** AI agent that can execute bash commands (like GitHub Copilot CLI).

**Setup in any project**:
```bash
cd ~/my-project
ai-commands setup           # Adds instructions to AGENTS.md
```

**What it does**: Adds instructions to `AGENTS.md` that tell AI agents how to retrieve command prompts using bash.

**AI agents can then**:
```bash
ai-commands get save-session        # Returns full save-session prompt
ai-commands get create-plan         # Returns full create-plan prompt
ai-commands list                    # Lists all available commands
```

**Usage example with Copilot CLI**:
```bash
copilot
# User: "save the session"
# Copilot reads AGENTS.md, sees instruction
# Copilot runs: ai-commands get save-session
# Copilot receives full prompt and executes workflow
```

**Available commands**:
- `save-session` - Create detailed conversation summaries
- `create-plan` - Interactive implementation planning
- `implement-plan` - Execute approved technical plans
- `research-codebase` - Comprehensive codebase research
- `validate-plan` - Validate plan execution
- `worktree-create` - Create git worktree for parallel development
- `worktree-merge` - Merge worktree back to main
- `worktree-list` - List all active worktrees
- `worktree-status` - Show detailed worktree status

**Benefits**:
- Single source of truth - commands only in `~/dotfiles/claude/commands/`
- Works with Copilot CLI, Claude Code custom agents, and any AI that can run bash
- Commands auto-update when dotfiles change
- No content duplication across projects

**Adding new commands**: Create `.md` files in `~/dotfiles/claude/commands/` and they're automatically available.

### Git Worktrees for Parallel AI Development

**wtp** (git worktree manager) enables running multiple AI agents simultaneously on different features.

**What are git worktrees?**
- Multiple working directories from a single Git repository
- Each worktree on a different branch
- Perfect for parallel AI development workflows
- No context switching = better AI performance

**Quick Start**:
```bash
# Create a worktree
wtp create feature-name

# Work in the worktree
cd trees/feature-name
claude  # or opencode

# List worktrees
wtp list

# Merge and cleanup
git checkout main
git merge feature-name
wtp delete feature-name
```

**Use Cases**:
- Run 3-5 Claude Code instances on different features simultaneously
- Try multiple implementation approaches, pick the winner
- One agent codes while another reviews
- Divide large refactors across multiple agents

**Directory Structure**:
```
project/
├── .git/                  # Shared Git database
├── main-code/             # Main worktree
└── trees/                 # Additional worktrees (gitignored)
    ├── feature-auth/
    ├── refactor-db/
    └── experiment-ui/
```

**Commands Available**:
- Claude Code: `/worktree_create`, `/worktree_merge`, `/worktree_list`, `/worktree_status`
- OpenCode: `/worktree-create`, `/worktree-merge`, `/worktree-list`, `/worktree-status`

**Benefits**:
- 2-3x faster development (parallel work)
- No context switching for AI agents
- Experiment-driven development
- Tool agnostic (works with VSCode, Cursor, etc.)

See [AGENTS.md](AGENTS.md) for comprehensive documentation.

## Platform-Specific Notes

### Ubuntu/Debian

**Dependencies Installed**:
- git, curl, tmux, neovim, zsh
- build-essential (C compiler)
- ripgrep, fd-find (telescope searching)
- xclip (clipboard support)

**Neovim Version**:
- Script offers to install latest neovim from neovim-ppa/unstable if your version is < 0.11

**Clipboard**:
- Uses xclip for system clipboard integration

### macOS

**Dependencies Installed**:
- git, curl, tmux, neovim, zsh
- gcc (C compiler via Homebrew)
- ripgrep, fd (telescope searching)

**Neovim Version**:
- Installs/updates neovim via Homebrew (always latest)

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

---

**Happy coding!** 🚀

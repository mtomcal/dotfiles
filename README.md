# Dotfiles

Personal development environment configuration for tmux, neovim, and zsh.

## Features

- **Tmux**: Vim-style navigation and keybindings with optimized settings for neovim
- **Neovim**: Official [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) base with custom plugin layer
- **Zsh**: Oh My Zsh with custom aliases and tmux integration
- **Claude Code**: Custom slash commands for development workflows
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
├── claude/
│   ├── commands/          # Claude Code slash commands
│   ├── settings.json      # Claude Code settings
│   └── README.md          # Claude Code documentation
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
- `Ctrl-a c` - Create new window
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

### Claude Code

**Custom slash commands** for enhanced development workflows. See [claude/README.md](claude/README.md) for details.

**Available Commands**:
- `/save-session` - Create detailed session summaries
- `/create_plan` - Interactive implementation planning
- `/implement_plan` - Execute approved technical plans
- `/research_codebase` - Comprehensive codebase research
- `/validate_plan` - Validate plan execution

**Adding Custom Commands**:

Create a new markdown file in `~/dotfiles/claude/commands/`:

```bash
nvim ~/dotfiles/claude/commands/my-command.md
```

The command will be available as `/my-command` in Claude Code.

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

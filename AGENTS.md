# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Repository Overview

Personal dotfiles repository for a tmux + neovim + zsh development environment. The repository uses a symlink-based architecture to maintain configurations in version control while deploying them to standard system locations.

## Installation and Setup

The primary entry point is `./install.sh`, which:
- Auto-detects OS (Ubuntu/Debian via apt, or macOS via brew)
- Installs dependencies (tmux, neovim 0.11+, zsh, ripgrep, fd, build tools)
- Sets up Oh My Zsh framework
- Clones official kickstart.nvim to `~/.config/nvim`
- Creates symlinks for configurations
- Installs fnm (Fast Node Manager) and Node.js LTS
- Links Claude Code custom commands and settings

**Key behavior**: The script is idempotent and safe to re-run for updates.

## Architecture

### Configuration Strategy

**Philosophy**: Use official upstream configurations (kickstart.nvim) as base, layer custom configs on top via symlinks.

**Symlink structure**:
- `~/.tmux.conf` → `~/dotfiles/tmux/.tmux.conf`
- `~/.config/nvim/lua/custom/` → `~/dotfiles/nvim/custom/`
- `~/.claude/commands` → `~/dotfiles/claude/commands`
- `~/.claude/settings.json` → `~/dotfiles/claude/settings.json`
- Custom zsh config sourced in `~/.zshrc` (not symlinked)

### Neovim Configuration

Uses **two-layer architecture**:
1. **Base layer**: Official kickstart.nvim (git repo at `~/.config/nvim`)
2. **Custom layer**: User customizations at `~/dotfiles/nvim/custom/` (symlinked into kickstart)

This design allows updating kickstart.nvim independently (`cd ~/.config/nvim && git pull`) while preserving custom plugins and configurations.

**Adding custom neovim plugins**: Create files in `~/dotfiles/nvim/custom/plugins/` using lazy.nvim format. The install script ensures `{ import = 'custom.plugins' }` is uncommented in kickstart's init.lua (line ~402-403 of install.sh).

### Tmux Configuration

**Prefix key**: Ctrl-a (not default Ctrl-b)

**Critical settings** for neovim integration:
- Zero escape delay: `set -sg escape-time 0`
- True color support: `set -g default-terminal "tmux-256color"`
- Focus events enabled: `set -g focus-events on`

Vim-style navigation keybindings throughout (h/j/k/l for panes, H/J/K/L for resizing).

### Platform-Specific Handling

The install script contains OS detection logic (install.sh:48-64):
- **Ubuntu/Debian**: Uses apt, installs xclip for clipboard, optionally adds neovim-ppa/unstable
- **macOS**: Uses brew, installs fd (not fd-find), uses pbcopy/pbpaste for clipboard

When modifying the install script, ensure platform-specific packages use correct names (e.g., `fd-find` on Ubuntu, `fd` on macOS).

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

### Claude Code Privacy

The `.gitignore` in `claude/` excludes sensitive files (credentials, history, project data) while tracking commands and settings. When modifying Claude config, never commit `.credentials.json` or `history.jsonl`.

### Zsh Shell Change Detection

Recent addition (commit b41aca0) checks if zsh is already the default shell to avoid unnecessary chsh calls (install.sh:180-201).

## Common Pitfalls

1. **Symlink conflicts**: The install script backs up existing non-symlink configs with timestamps before linking
2. **Homebrew path on Apple Silicon**: Script handles `/opt/homebrew/bin/brew` vs `/usr/local/bin/brew` (install.sh:76-79)
3. **Custom plugin imports**: Must uncomment `{ import = 'custom.plugins' }` in kickstart's init.lua for custom neovim plugins to load
4. **fnm initialization**: Requires both PATH export and `fnm env` eval in shell config (zsh/.zshrc.custom:42-46)

## Session Summaries

Session summaries are stored in `./sessions/` (project-specific, gitignored). Use `/save-session` to create detailed conversation summaries for future reference.

# Neovim Configuration

This setup uses kickstart.nvim as the base configuration.

## Installation

The install script will automatically clone official kickstart.nvim to `~/.config/nvim`.

If you need to do it manually:

```bash
git clone https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
```

## First Launch

On first launch, neovim will automatically install all plugins via lazy.nvim.
This may take a minute or two.

## Requirements

- Neovim 0.11+ (ideally 0.12.0-dev from neovim-ppa/unstable)
- Git
- A C compiler (build-essential)
- ripgrep (for telescope searching)
- fd-find (for telescope file finding)
- xclip (for clipboard support)

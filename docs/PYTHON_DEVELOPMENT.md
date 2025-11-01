# Python Development Setup

This document describes the Python development tools and configuration for Neovim in this dotfiles repository.

## Overview

The Neovim configuration includes comprehensive Python support with LSP-based type checking, real-time linting, and automatic formatting.

## System Requirements

### Linux (Ubuntu/Debian)

The install script automatically installs:
- `python3-venv` - Required for Mason to create virtual environments for Python tools

This package is installed in `install.sh:138` as part of platform-specific dependencies.

### macOS

No additional packages needed. Python's venv module is included by default with macOS Python installations.

## Installed Tools

All tools are automatically installed via Mason when you open Neovim.

### 1. Pyright (LSP Server)

**What it does:**
- Type checking and type hint validation
- Intelligent code completion
- Hover documentation
- Go to definition/references
- Rename refactoring

**Configuration:** `~/.config/nvim/init.lua:702-713`

**Settings:**
- Type checking mode: `basic` (can be changed to `off` or `strict`)
- Auto-searches for Python paths
- Uses library code for better type inference
- Workspace-wide diagnostics

### 2. Ruff (Linter & Formatter)

**What it does:**
- Combines functionality of: flake8, black, isort, pylint, and more
- Extremely fast (written in Rust)
- Fixes code style issues
- Organizes imports automatically
- Enforces PEP 8 standards

**Configuration:**
- Mason install: `~/.config/nvim/init.lua:732`
- Formatters: `~/.config/nvim/init.lua:785`
- Linting: `~/dotfiles/nvim/custom/plugins/python.lua`

### 3. nvim-lint

**What it does:**
- Provides real-time linting as you type
- Integrates with diagnostic system
- Shows issues inline with virtual text

**Configuration:** `~/dotfiles/nvim/custom/plugins/python.lua`

**Triggers linting on:**
- Opening a file (`BufEnter`)
- Saving a file (`BufWritePost`)
- Leaving insert mode (`InsertLeave`)

## Keybindings

### LSP Actions (Python files only)

| Key | Action | Description |
|-----|--------|-------------|
| `grd` | Go to Definition | Jump to where a function/class/variable is defined |
| `grr` | Go to References | Find all uses of symbol under cursor |
| `gri` | Go to Implementation | Jump to implementation |
| `grt` | Go to Type Definition | Jump to type definition |
| `grn` | Rename | Rename symbol across entire project |
| `gra` | Code Action | Show available code actions (add imports, etc.) |
| `grD` | Go to Declaration | Jump to declaration |
| `K` | Hover Documentation | Show documentation for symbol under cursor |
| `gO` | Document Symbols | Fuzzy find symbols in current file |
| `gW` | Workspace Symbols | Fuzzy find symbols in entire project |

### Formatting

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>f` | Format Buffer | Format current file with ruff |

**Note:** Python files auto-format on save by default.

### Linting

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>l` | Manual Lint | Trigger linting on current file |

### Diagnostics

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>q` | Quickfix List | Open list of all diagnostics in current file |
| `<leader>sd` | Search Diagnostics | Search all diagnostics with Telescope |
| `[d` | Previous Diagnostic | Jump to previous diagnostic |
| `]d` | Next Diagnostic | Jump to next diagnostic |

## Working with Type Hints

### Viewing Type Information

1. **Hover over any variable/function:**
   - Press `K` to see its type and documentation

2. **Inlay hints (optional):**
   - Toggle with `<leader>th` to show inline type hints
   - Shows parameter types and return types inline

### Type Checking Modes

Edit `~/.config/nvim/init.lua:706` to change strictness:

```lua
typeCheckingMode = "off"    -- No type checking
typeCheckingMode = "basic"  -- Balanced (default)
typeCheckingMode = "strict" -- Maximum type safety
```

### Example Type Errors

Pyright will show errors for:
- Missing type hints (in strict mode)
- Incorrect argument types
- Undefined variables
- Wrong return types
- And more...

## Linting Rules

Ruff enforces hundreds of rules including:

- **PEP 8:** Code style (line length, naming conventions)
- **Pyflakes:** Detect unused imports, undefined names
- **isort:** Import organization
- **pep8-naming:** Naming conventions
- **flake8-bugbear:** Likely bugs and design problems
- And many more...

### Customizing Ruff

Create a `pyproject.toml` or `ruff.toml` in your project root:

```toml
[tool.ruff]
line-length = 100
select = ["E", "F", "W", "I"]
ignore = ["E501"]  # Ignore specific rules

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

## Auto-formatting Behavior

**On save:** Python files automatically run:
1. `ruff_organize_imports` - Sorts and organizes imports
2. `ruff_format` - Formats code to style standards

**To disable auto-format:** Remove Python from the format_on_save in `~/.config/nvim/init.lua:772`.

## Installation & Updates

### First Time Setup

1. Run the install script: `./install.sh` (installs python3-venv automatically on Linux)
2. Open any Python file in Neovim
3. Mason will auto-install: pyright and ruff
4. Wait for installation to complete (check status with `:Mason`)

### Manual Installation

```vim
:Mason
" Navigate to pyright and ruff, press 'i' to install
```

### Updates

```vim
:Mason
" Navigate to tool, press 'u' to update
" Or press 'U' to update all tools
```

### Checking Health

```vim
:checkhealth mason
:checkhealth nvim-lint
:checkhealth conform
```

## Troubleshooting

### Mason can't install Python tools

**Error:** `python3-venv not available` or `ensurepip is not available`

**Solution:**
```bash
# Linux (Ubuntu/Debian)
sudo apt install python3-venv

# macOS - should work by default
```

This is automatically handled by the install script, but if you installed manually, you'll need this package.

### Type checking not working

1. Check pyright is installed: `:Mason`
2. Check LSP attached: `:LspInfo`
3. Verify Python interpreter detected: `:!which python3`

### Linting not showing

1. Check ruff installed: `:Mason`
2. Manually trigger: `<leader>l`
3. Check nvim-lint status: `:lua =require('lint').get_running()`

### Formatting not working

1. Check ruff installed: `:Mason`
2. Check conform status: `:ConformInfo`
3. Try manual format: `<leader>f`

### Virtual Environments

Pyright auto-detects virtual environments in:
- `venv/`
- `.venv/`
- `env/`
- Pipenv/Poetry environments

If not detected, create a `pyrightconfig.json`:

```json
{
  "venvPath": ".",
  "venv": "venv"
}
```

## Files Modified

- `install.sh:138` - Added python3-venv to Ubuntu dependencies
- `~/.config/nvim/init.lua:702-713` - Pyright LSP configuration
- `~/.config/nvim/init.lua:732` - Ruff in ensure_installed
- `~/.config/nvim/init.lua:785` - Python formatters configuration
- `~/dotfiles/nvim/custom/plugins/python.lua` - Linting configuration

## Additional Resources

- [Pyright Documentation](https://github.com/microsoft/pyright)
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [nvim-lint Documentation](https://github.com/mfussenegger/nvim-lint)
- [conform.nvim Documentation](https://github.com/stevearc/conform.nvim)

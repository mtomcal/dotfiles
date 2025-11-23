---
date: 2025-11-23T05:03:26+00:00
researcher: Claude
git_commit: d34f457d896789c2bbcc8140ba0366f292e7a37f
branch: main
repository: mtomcal/dotfiles
topic: "Neovim Telescope/Ruff ENOENT Errors"
tags: [research, neovim, ruff, telescope, linting, troubleshooting]
status: complete
last_updated: 2025-11-23
last_updated_by: Claude
---

# Research: Neovim Telescope/Ruff ENOENT Errors

**Date**: 2025-11-23T05:03:26+00:00
**Researcher**: Claude
**Git Commit**: d34f457d896789c2bbcc8140ba0366f292e7a37f
**Branch**: main
**Repository**: mtomcal/dotfiles

## Research Question

Why am I constantly getting this error in Neovim?

```
E5108: Lua: ...share/nvim/lazy/telescope.nvim/lua/telescope/pickers.lua:137:
BufEnter Autocommands for "*": Vim(append):Error running ruff: ENOENT: no such file or directory
```

## Summary

The error occurs when **telescope.nvim closes/opens buffers**, triggering a **BufEnter autocommand** that attempts to run **ruff linting**. The "ENOENT" (No such file or directory) error indicates that the `ruff` executable cannot be found on your system.

**Root Cause**: The custom nvim-lint configuration in `nvim/custom/plugins/python.lua:39-46` automatically runs linting on every buffer enter event, but ruff is either:
1. Not installed via Mason
2. Not in the executable PATH
3. Mason's virtual environment not properly configured

## Detailed Findings

### The Error Chain

1. **Telescope closes a buffer** (when you select a file or cancel search)
2. **BufEnter autocommand fires** (defined in python.lua)
3. **nvim-lint tries to run ruff** via `lint.try_lint()`
4. **Ruff command fails** with ENOENT (executable not found)
5. **Error propagates through telescope** stack trace

### BufEnter Autocommand Configuration

**File**: `nvim/custom/plugins/python.lua:39-46`

```lua
local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
  group = lint_augroup,
  callback = function()
    lint.try_lint()
  end,
})
```

This autocommand runs on **every buffer enter**, including when telescope switches buffers during search operations.

### Ruff Linter Configuration

**File**: `nvim/custom/plugins/python.lua:1-53`

The plugin configures ruff in two modes:

1. **Poetry projects** (lines 15-32):
   ```lua
   lint.linters.ruff.cmd = 'poetry'
   lint.linters.ruff.args = { 'run', 'ruff', 'check', '--output-format', 'json', '--stdin-filename' }
   ```

2. **Non-Poetry projects** (lines 34-36):
   ```lua
   lint.linters.ruff.cmd = 'ruff'
   lint.linters.ruff.args = { 'check', '--output-format', 'json', '--stdin-filename' }
   ```

Both configurations expect the executable to be available in PATH.

### Expected Installation Method

**File**: `install.sh:134-144` and Mason auto-installation

Ruff should be automatically installed by **Mason** (Neovim's package manager) when you first open a Python file. Prerequisites:
- **Ubuntu/Debian**: `python3-venv` package (installed by install.sh:138)
- **Mason LSP config**: `~/.config/nvim/init.lua:732`

Mason installs tools into isolated virtual environments at:
```
~/.local/share/nvim/mason/packages/
```

## Code References

- `nvim/custom/plugins/python.lua:39-46` - BufEnter autocommand that triggers linting
- `nvim/custom/plugins/python.lua:15-36` - Ruff command configuration
- `install.sh:138` - python3-venv installation (required for Mason)
- `docs/PYTHON_DEVELOPMENT.md:209-250` - Troubleshooting documentation

## Solutions

### Option 1: Install Ruff via Mason (Recommended)

1. Open Neovim
2. Run `:Mason`
3. Search for "ruff" (press `/` and type "ruff")
4. Press `i` to install ruff
5. Restart Neovim

### Option 2: Verify python3-venv is Installed

Mason requires `python3-venv` to create virtual environments:

```bash
# Ubuntu/Debian
sudo apt install python3-venv

# Check if installed
python3 -m venv --help
```

### Option 3: Install Ruff System-Wide

If Mason installation fails, install ruff directly:

```bash
# Using pipx (recommended)
pipx install ruff

# Using pip
pip install --user ruff

# Using apt (Ubuntu 23.10+)
sudo apt install ruff
```

### Option 4: Disable Auto-Linting on BufEnter (Temporary Workaround)

Edit `nvim/custom/plugins/python.lua:41` to remove BufEnter:

```lua
vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave' }, {  -- Removed BufEnter
  group = lint_augroup,
  callback = function()
    lint.try_lint()
  end,
})
```

This will prevent linting from running when telescope switches buffers, but you'll still get linting on save and when leaving insert mode.

### Option 5: Add File Type Check

Make the autocommand only run for Python files:

```lua
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
  group = lint_augroup,
  callback = function()
    -- Only lint Python files
    if vim.bo.filetype == 'python' then
      lint.try_lint()
    end
  end,
})
```

## Diagnostic Commands

Check Mason installation status:
```vim
:Mason
:checkhealth mason
:checkhealth nvim-lint
```

Check if ruff is in PATH:
```bash
which ruff
ruff --version
```

Check Mason packages directory:
```bash
ls -la ~/.local/share/nvim/mason/packages/
ls -la ~/.local/share/nvim/mason/bin/
```

Check nvim-lint configuration:
```vim
:lua print(vim.inspect(require('lint').linters.ruff))
```

## Architecture Insights

The dotfiles use a **layered configuration approach**:

1. **Base**: kickstart.nvim (community-maintained starter config)
   - Location: `~/.config/nvim/`
   - Provides: lazy.nvim, telescope, LSP, formatting via conform.nvim

2. **Custom Layer**: Symlinked from dotfiles
   - Location: `~/dotfiles/nvim/custom/` → `~/.config/nvim/lua/custom/`
   - Provides: Additional plugins (nvim-lint for linting, neo-tree, markdown renderer)

3. **Tool Management**: Mason
   - Auto-installs LSP servers, linters, formatters
   - Isolates tools in virtual environments
   - Requires `python3-venv` for Python tools

The issue arises because the custom layer (nvim-lint) expects tools that should be installed by Mason, but the installation chain may not have completed or succeeded.

## Related Research

- Python development setup: `docs/PYTHON_DEVELOPMENT.md`
- Neovim configuration guide: `nvim/README.md`
- Installation script: `install.sh:1-811`

## Open Questions

1. Did Mason successfully install ruff? (Check with `:Mason`)
2. Is `python3-venv` installed on the system? (Check with `python3 -m venv --help`)
3. Are there any Mason-related errors in `:messages`?
4. Does the error only occur in non-Python files? (Would suggest file type filtering is needed)

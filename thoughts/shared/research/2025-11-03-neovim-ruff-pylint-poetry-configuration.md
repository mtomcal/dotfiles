---
date: 2025-11-03T16:46:33+00:00
researcher: Claude
git_commit: 5af6f6d3445a7975eeb4fff985f798f98ff96927
branch: main
repository: dotfiles
topic: "Configuring Ruff and Pylint to Work in Neovim with Poetry Projects"
tags: [research, neovim, ruff, pylint, poetry, nvim-lint, python, linting]
status: complete
last_updated: 2025-11-03
last_updated_by: Claude
---

# Research: Configuring Ruff and Pylint to Work in Neovim with Poetry Projects

**Date**: 2025-11-03T16:46:33+00:00
**Researcher**: Claude
**Git Commit**: 5af6f6d3445a7975eeb4fff985f798f98ff96927
**Branch**: main
**Repository**: dotfiles

## Research Question

How do I get ruff and pylint to use the project linting configuration as it passes in poe and poetry project but fails in the editor (Neovim)?

## Summary

The core issue is that nvim-lint calls linter binaries directly without using the Poetry virtualenv context. When running through `poe` tasks, Poetry ensures the correct virtualenv is active and `pyproject.toml` is respected. However, nvim-lint bypasses this by calling the system-installed linter directly.

**Primary Solution**: Configure nvim-lint to run linters as Python modules using the active Python interpreter (`python -m ruff` instead of `ruff`). This ensures the linter uses the Poetry virtualenv and finds `pyproject.toml`.

## Detailed Findings

### Current Neovim Configuration

The dotfiles repository uses kickstart.nvim as the base with custom plugins in `nvim/custom/plugins/`.

- `nvim/custom/plugins/python.lua:10` - Currently configured with `python = { 'ruff' }`
- `nvim/custom/plugins/python.lua:6-11` - Uses mfussenegger/nvim-lint plugin for linting

### Root Cause Analysis

#### Problem: nvim-lint and Virtualenv Isolation

1. **Direct Binary Execution**: nvim-lint calls linter binaries directly (e.g., `ruff`, `pylint`) without virtualenv context
2. **Missing Configuration**: Without virtualenv context, linters can't find `pyproject.toml` or project-specific dependencies
3. **Works in Poe**: Poetry/Poe tasks work because they activate the virtualenv before running linters

#### Why `poe` Tasks Work

When running linters through Poe tasks:
- Poetry activates the project virtualenv
- The virtualenv's `ruff`/`pylint` are used
- `pyproject.toml` is detected in the project root
- All project dependencies are available

### Solution 1: Configure nvim-lint to Use Virtualenv Python (Recommended)

Modify `nvim/custom/plugins/python.lua` to run linters as Python modules:

```lua
-- Python development setup with linting
return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local lint = require('lint')

    -- Configure linters by filetype
    lint.linters_by_ft = {
      python = { 'ruff' },
    }

    -- Configure ruff to use the virtualenv's Python
    lint.linters.ruff.cmd = 'python'
    lint.linters.ruff.args = { '-m', 'ruff', 'check', '--output-format', 'json', '--stdin-filename' }
    -- Note: nvim-lint will automatically append the filename

    -- If you also use pylint:
    -- lint.linters.pylint.cmd = 'python'
    -- lint.linters.pylint.args = { '-m', 'pylint', '-f', 'json' }

    -- Create autocommand to trigger linting
    local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    -- Keymap to manually trigger linting
    vim.keymap.set('n', '<leader>l', function()
      lint.try_lint()
    end, { desc = 'Trigger [L]inting for current file' })
  end,
}
```

**Why this works**: Using `python -m ruff` instead of `ruff` directly ensures it uses the currently active Python interpreter from your virtualenv, which has access to the correct ruff installation and will find `pyproject.toml`.

### Solution 2: Configure Poetry for In-Project Virtualenvs

Configure Poetry to create `.venv` in the project directory for more reliable detection:

```bash
# Configure Poetry to create .venv in your project directory
poetry config virtualenvs.in-project true

# If you already have a virtualenv, recreate it
poetry env remove python
poetry install
```

**Benefits**:
- Virtualenv is always at a predictable location (`.venv/`)
- Easier for editors and tools to detect
- No need to search Poetry's cache directory

**Important**: If a virtualenv already exists, you must recreate it after changing this setting.

### Solution 3: Launch Neovim Through Poetry

Ensure Neovim runs with the correct virtualenv context:

```bash
# Option A: Run neovim through poetry (recommended)
poetry run nvim

# Option B: Activate the virtualenv first
poetry shell
nvim

# Option C: Source the virtualenv manually (after configuring virtualenvs.in-project)
source .venv/bin/activate
nvim
```

### Solution 4: Advanced Virtualenv Auto-Detection

For sophisticated automatic virtualenv detection:

```lua
-- Add to your python.lua config function
local lint = require('lint')

-- Detect virtualenv
local VENV = os.getenv("VIRTUAL_ENV")
if VENV then
  -- Use virtualenv's Python to run ruff
  lint.linters.ruff.cmd = 'python'
  lint.linters.ruff.args = { '-m', 'ruff', 'check', '--output-format', 'json', '--stdin-filename' }
else
  -- Fallback: try to find .venv in project
  local venv_python = vim.fn.getcwd() .. '/.venv/bin/python'
  if vim.fn.executable(venv_python) == 1 then
    lint.linters.ruff.cmd = venv_python
    lint.linters.ruff.args = { '-m', 'ruff', 'check', '--output-format', 'json', '--stdin-filename' }
  end
end
```

This checks:
1. If `VIRTUAL_ENV` environment variable is set
2. Falls back to checking for `.venv/bin/python` in the current working directory

## Code References

- `nvim/custom/plugins/python.lua:1-28` - Current nvim-lint configuration for Python
- `nvim/README.md:1-28` - Neovim setup documentation using kickstart.nvim

## Architecture Insights

### nvim-lint Design

The mfussenegger/nvim-lint plugin is designed to be flexible but doesn't automatically detect virtualenvs. It:
- Calls linter binaries directly via `cmd` and `args` configuration
- Expects linters to be available in the system PATH
- Doesn't inherit shell environment virtualenv activation

### Poetry Virtualenv Management

Poetry manages virtualenvs in two ways:
1. **Default**: Creates virtualenvs in Poetry's cache directory (`~/.cache/pypoetry/virtualenvs/`)
2. **In-project**: Creates `.venv` directory in project root when `virtualenvs.in-project = true`

The in-project approach is more editor-friendly as it's easier to detect and configure.

### Integration Pattern

The recommended pattern for Poetry + Neovim + nvim-lint:

```
1. Configure Poetry: virtualenvs.in-project = true
2. Configure nvim-lint: Use `python -m <linter>` instead of `<linter>` directly
3. Launch Neovim: Use `poetry run nvim` or activate virtualenv first
```

This ensures:
- Consistent linter behavior between CLI and editor
- `pyproject.toml` is always respected
- Project dependencies are available to linters

## External Resources

### Key Documentation

- **nvim-lint virtualenv setup**: [GitHub Gist by Norbiox](https://gist.github.com/Norbiox/652befc91ca0f90014aec34eccee27b2)
  - Shows how to configure nvim-lint with `python -m pylint` approach

- **Ruff Editor Setup**: [Ruff Documentation](https://docs.astral.sh/ruff/editors/setup/)
  - Official Ruff editor integration guide

- **Poetry Configuration**: [Poetry Docs - Configuration](https://python-poetry.org/docs/configuration/)
  - Documentation for `virtualenvs.in-project` and other settings

### Key GitHub Issues

- **ruff-lsp #71**: "Supporting Virtualenv in NeoVim"
  - Discusses virtualenv detection challenges in Neovim

- **ruff-lsp #177**: "Neovim + Mason + ruff_lsp, trying to pass in a pyproject.toml"
  - Configuration examples for passing pyproject.toml to Ruff LSP

- **ruff-vscode #425**: "VSCode setting should be overridden by discovered toml"
  - Similar issue in VS Code showing configuration precedence problems

### Community Solutions

From web research (November 2025):
- Multiple users report success with `python -m ruff` approach
- `virtualenvs.in-project = true` is widely recommended for editor integration
- `poetry run nvim` is considered best practice for Poetry projects

## Verification Steps

After implementing the solution:

1. **Check ruff installation in Poetry environment**:
   ```bash
   poetry run which ruff
   poetry run ruff --version
   ```

2. **Verify nvim-lint is using correct Python**:
   ```bash
   # In your project directory with virtualenv active
   which python
   python -m ruff check --version
   ```

3. **Test in Neovim**:
   - Open a Python file with intentional style violations
   - Check that nvim-lint shows the same diagnostics as `poe` tasks
   - Verify errors match your `pyproject.toml` configuration

## Recommended Implementation

**Best Practice**: Combine Solutions 1 + 2 + 3

1. Configure Poetry for in-project virtualenvs:
   ```bash
   poetry config virtualenvs.in-project true
   poetry env remove python
   poetry install
   ```

2. Update `nvim/custom/plugins/python.lua` to use `python -m ruff`

3. Launch Neovim with `poetry run nvim` or activate virtualenv first

This ensures nvim-lint uses the correct ruff from your Poetry environment and respects your `pyproject.toml` configuration.

## Open Questions

- Should we add automatic virtualenv detection to the nvim-lint configuration?
- Would using ruff-lsp (Language Server Protocol) be better than nvim-lint for this use case?
- Should we create a wrapper script or shell alias to always launch `poetry run nvim` for Python projects?

## Related Research

This research complements general Python development environment setup and could be extended to cover:
- Formatting tools (black, ruff format) integration
- Type checkers (mypy, pyright) configuration
- Testing integration (pytest) in Neovim
- Pre-commit hooks alignment with editor linting

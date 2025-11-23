---
date: 2025-11-23T05:22:37+00:00
researcher: Claude
git_commit: a9dfbb863be9dbeb30dd4637ada02dbe15567e82
branch: main
repository: dotfiles
topic: "Golang Development Setup for Neovim 2025"
tags: [research, codebase, golang, neovim, lsp, development-tools]
status: complete
last_updated: 2025-11-23
last_updated_by: Claude
---

# Research: Golang Development Setup for Neovim 2025

**Date**: 2025-11-23T05:22:37+00:00
**Researcher**: Claude
**Git Commit**: a9dfbb863be9dbeb30dd4637ada02dbe15567e82
**Branch**: main
**Repository**: dotfiles

## Research Question

What are the essential tools and configurations needed for Golang development in Neovim in 2025?

## Summary

Based on current best practices for 2025, a modern Golang development setup in Neovim requires:

1. **gopls** - Official Go language server for LSP features
2. **nvim-treesitter** with Go parser - For syntax highlighting and AST-based operations
3. **nvim-dap** + **nvim-dap-go** OR **go.nvim** - For debugging support
4. **neotest-golang** - For running and debugging tests
5. **conform.nvim** or similar - For code formatting (gofmt/gofumpt)
6. **Mason** - For easy installation of Go tools

Your current Kickstart.nvim setup has a solid foundation with LSP, Treesitter, and Mason already configured, but lacks Go-specific tooling.

## Detailed Findings

### Current Configuration Analysis

**What You Have:**
- Kickstart.nvim base configuration at `/home/mtomcal/.config/nvim/init.lua`
- LSP infrastructure with `nvim-lspconfig`, Mason, and blink.cmp
- Treesitter for syntax highlighting
- Telescope for fuzzy finding
- conform.nvim for formatting
- Custom plugin setup via `/home/mtomcal/dotfiles/nvim/custom/plugins/`
- Python development already configured with ruff linting

**What's Missing for Go:**
- gopls LSP server configuration (commented out at line 675)
- Go treesitter parser
- Go-specific tooling (debugging, testing)
- Go formatters configuration

### Essential Go Tools for 2025

#### 1. Language Server - gopls

**Installation:**
```bash
go install golang.org/x/tools/gopls@latest
```

**Features:**
- Code completion and intelligence
- Go to definition, find references
- Hover documentation
- Code actions (e.g., fill struct, extract function)
- Diagnostics and error checking
- Auto-imports organization
- Supports staticcheck, unusedparams analysis
- Inlay hints for types and parameters

**Version Support:** gopls supports all Go versions as language versions, though it only supports the two most recent Go releases as build versions.

**Configuration Requirements:**
- Requires `go.mod`, `go.work`, or `.git` in project root for LSP to attach
- Works with filetypes: `go`, `gomod`, `gowork`, `gotmpl`

#### 2. Syntax Highlighting - nvim-treesitter

**Setup:**
Add `'go'` to the `ensure_installed` list in treesitter configuration (line 947).

**Note:** For proper test discovery with neotest-golang, use treesitter's main branch and run `:TSUpdate go`.

#### 3. Debugging - Two Options

**Option A: go.nvim (Comprehensive)**
- Plugin: `ray-x/go.nvim`
- Features:
  - Built-in DAP support with zero-config debugging
  - AST-based tools (treesitter + go AST)
  - Test management and coverage
  - Code generation helpers
  - All-in-one Go development plugin

**Option B: nvim-dap-go (Minimal)**
- Plugins: `mfussenegger/nvim-dap` + `leoluz/nvim-dap-go`
- Features:
  - Focused on debugging with Delve
  - Treesitter integration for test debugging
  - VSCode launch.json support
  - Lightweight alternative

**Recommendation:** Use `nvim-dap-go` if you want minimal dependencies, or `go.nvim` for a comprehensive IDE-like experience.

#### 4. Testing - neotest-golang

**Plugin:** `fredrikaverpil/neotest-golang`

**Features:**
- Run individual tests, test functions, or entire files
- Treesitter-based test discovery
- Table test and nested test support
- DAP integration for debugging tests
- gotestsum integration
- Testify framework support

**Alternative:** `nvim-neotest/neotest-go` (older, less actively maintained)

#### 5. Formatting Tools

**Primary Formatters:**
- **gofmt** - Standard Go formatter (comes with Go)
- **gofumpt** - Stricter version of gofmt (recommended for 2025)
- **goimports** - Automatically manages imports

**Installation via Mason:**
```lua
ensure_installed = { 'gofumpt', 'goimports' }
```

**Configuration in conform.nvim:**
```lua
formatters_by_ft = {
  go = { "goimports", "gofumpt" }, -- Run sequentially
}
```

#### 6. Additional Tools

**Linting:**
- **staticcheck** - Go static analysis tool (integrated with gopls)
- **golangci-lint** - Meta-linter running multiple linters

**Code Generation:**
- **impl** - Generate method stubs for interfaces
- **gotests** - Generate Go tests

## Recommended Configuration

### Step 1: Enable gopls in init.lua

Edit `/home/mtomcal/.config/nvim/init.lua:675`:

```lua
local servers = {
  gopls = {
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
          shadow = true,
        },
        staticcheck = true,
        gofumpt = true,
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
      },
    },
  },
  lua_ls = {
    -- existing config
  },
}
```

### Step 2: Add Go to Treesitter

Edit `/home/mtomcal/.config/nvim/init.lua:947`:

```lua
ensure_installed = {
  'bash', 'c', 'diff', 'html', 'lua', 'luadoc',
  'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc',
  'go', 'gomod', 'gowork', 'gosum' -- Add Go parsers
},
```

### Step 3: Add Go Formatting

Edit `/home/mtomcal/.config/nvim/init.lua:769` (in conform.nvim config):

```lua
formatters_by_ft = {
  lua = { 'stylua' },
  go = { 'goimports', 'gofumpt' },
},
```

### Step 4: Install Go Tools via Mason

Edit `/home/mtomcal/.config/nvim/init.lua:717`:

```lua
local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
  'stylua', -- Used to format Lua code
  'gopls',  -- Go language server
  'gofumpt', -- Go formatter
  'goimports', -- Go imports manager
  'golangci-lint', -- Go linter (optional)
  'delve', -- Go debugger
})
```

### Step 5: Create Go Plugin Configuration

Create `/home/mtomcal/dotfiles/nvim/custom/plugins/go.lua`:

**Option A - Minimal (DAP only):**

```lua
return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'nvim-neotest/nvim-nio',
    },
  },
  {
    'leoluz/nvim-dap-go',
    ft = 'go',
    dependencies = { 'mfussenegger/nvim-dap' },
    config = function()
      require('dap-go').setup()

      -- Keymaps for debugging
      vim.keymap.set('n', '<leader>dt', function() require('dap-go').debug_test() end,
        { desc = '[D]ebug [T]est' })
      vim.keymap.set('n', '<leader>db', function() require('dap').toggle_breakpoint() end,
        { desc = '[D]ebug Toggle [B]reakpoint' })
      vim.keymap.set('n', '<leader>dc', function() require('dap').continue() end,
        { desc = '[D]ebug [C]ontinue' })
    end,
  },
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'fredrikaverpil/neotest-golang',
    },
    config = function()
      require('neotest').setup({
        adapters = {
          require('neotest-golang')({
            go_test_args = { '-v', '-race', '-count=1' },
            dap_go_enabled = true,
          }),
        },
      })

      -- Keymaps for testing
      vim.keymap.set('n', '<leader>tn', function() require('neotest').run.run() end,
        { desc = '[T]est [N]earest' })
      vim.keymap.set('n', '<leader>tf', function() require('neotest').run.run(vim.fn.expand('%')) end,
        { desc = '[T]est [F]ile' })
      vim.keymap.set('n', '<leader>to', function() require('neotest').output.open() end,
        { desc = '[T]est [O]utput' })
      vim.keymap.set('n', '<leader>ts', function() require('neotest').summary.toggle() end,
        { desc = '[T]est [S]ummary' })
    end,
  },
}
```

**Option B - Comprehensive (go.nvim):**

```lua
return {
  {
    'ray-x/go.nvim',
    dependencies = {
      'ray-x/guihua.lua',
      'neovim/nvim-lspconfig',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('go').setup({
        lsp_cfg = false, -- Use existing lspconfig setup
        lsp_inlay_hints = {
          enable = true,
        },
        dap_debug = true,
        dap_debug_gui = true,
      })

      -- Auto-format on save with goimports
      vim.api.nvim_create_autocmd('BufWritePre', {
        pattern = '*.go',
        callback = function()
          require('go.format').goimports()
        end,
      })
    end,
    event = { 'CmdlineEnter' },
    ft = { 'go', 'gomod' },
  },
}
```

### Step 6: Auto-import Organization on Save

Add to gopls configuration in init.lua (inside the LspAttach autocmd):

```lua
-- Add after line 626 in the LspAttach callback
if client.name == 'gopls' then
  -- Organize imports on save
  vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '*.go',
    callback = function()
      local params = vim.lsp.util.make_range_params()
      params.context = {only = {"source.organizeImports"}}
      local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
      for _, res in pairs(result or {}) do
        for _, r in pairs(res.result or {}) do
          if r.edit then
            vim.lsp.util.apply_workspace_edit(r.edit, "utf-8")
          end
        end
      end
    end,
  })
end
```

## Code References

Configuration files to modify:
- `/home/mtomcal/.config/nvim/init.lua:675` - Add gopls server configuration
- `/home/mtomcal/.config/nvim/init.lua:947` - Add Go treesitter parsers
- `/home/mtomcal/.config/nvim/init.lua:769` - Add Go formatters to conform.nvim
- `/home/mtomcal/.config/nvim/init.lua:717` - Add Go tools to Mason
- `/home/mtomcal/dotfiles/nvim/custom/plugins/go.lua` - Create new Go plugin config

Current custom plugins location:
- `/home/mtomcal/dotfiles/nvim/custom/plugins/` (currently has python.lua, markdown.lua, neo-tree.lua)

## Architecture Insights

**Kickstart.nvim Structure:**
- Uses Lazy.nvim plugin manager
- Main configuration in single `init.lua` file
- Custom plugins loaded from `lua/custom/plugins/*.lua` via import (line 987)
- Mason handles LSP/tool installation automatically
- LSP configuration uses capabilities from blink.cmp
- Python development already follows similar pattern as recommended for Go

**Best Practices for 2025:**
1. Use gopls for all Go language features (don't duplicate with separate tools)
2. Enable inlay hints for better type visibility
3. Use treesitter for syntax highlighting and AST operations
4. Integrate DAP for debugging (essential for Go)
5. Use neotest for test management (better than raw go test)
6. Auto-organize imports on save (prevents manual import management)
7. Use gofumpt instead of gofmt (stricter, more consistent)

## Installation Steps Summary

1. **Install Go tools:**
   ```bash
   go install golang.org/x/tools/gopls@latest
   go install github.com/go-delve/delve/cmd/dlv@latest
   ```

2. **Update init.lua** with the configurations from Step 1-4 above

3. **Create go.lua** in custom/plugins/ with Option A or B configuration

4. **Restart Neovim** and run:
   ```vim
   :Lazy sync
   :Mason
   :TSUpdate
   ```

5. **Verify installation:**
   ```vim
   :checkhealth
   :LspInfo (in a .go file)
   :Mason (check gopls, gofumpt, goimports, delve are installed)
   ```

## Additional Resources

- [Official gopls documentation](https://go.dev/gopls/)
- [gopls Vim/Neovim setup](https://go.dev/gopls/editor/vim)
- [go.nvim GitHub](https://github.com/ray-x/go.nvim)
- [nvim-dap-go GitHub](https://github.com/leoluz/nvim-dap-go)
- [neotest-golang GitHub](https://github.com/fredrikaverpil/neotest-golang)

## Open Questions

1. Do you prefer the minimal (nvim-dap-go) or comprehensive (go.nvim) approach?
2. Do you want golangci-lint for additional static analysis beyond gopls?
3. Should we enable test coverage visualization?
4. Do you use any Go-specific frameworks (e.g., testify) that need special configuration?

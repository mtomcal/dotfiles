-- Extended formatter configuration for conform.nvim
-- Note: conform.nvim is already installed and configured by kickstart.nvim (Section 6).
-- This file extends it with additional formatters_by_ft and formatter-specific configs.

local conform = require('conform')

-- Reconfigure with extended formatter definitions
conform.setup({
  format_on_save = function(bufnr)
    local ignore_filetypes = {}
    if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
      return
    end
    return { timeout_ms = 2000, lsp_fallback = true }
  end,

  formatters_by_ft = {
    -- Go: goimports handles imports + gofumpt handles style
    go = { 'goimports', 'gofumpt' },

    -- Python: ruff format (fast, replaces black)
    python = { 'ruff_format' },

    -- JS/TS: prettier first, fall back to eslint_d --fix
    javascript = { 'prettier', 'eslint_d' },
    typescript = { 'prettier', 'eslint_d' },
    javascriptreact = { 'prettier', 'eslint_d' },
    typescriptreact = { 'prettier', 'eslint_d' },

    -- Web
    html = { 'prettier' },
    css = { 'prettier' },
    scss = { 'prettier' },

    -- Data/config
    json = { 'prettier' },
    jsonc = { 'prettier' },
    yaml = { 'prettier' },
    markdown = { 'prettier' },

    -- Lua
    lua = { 'stylua' },
  },

  formatters = {
    -- eslint_d: only run --fix, skip if no eslint config found
    eslint_d = {
      condition = function(_, ctx)
        return vim.fs.find(
          { '.eslintrc', '.eslintrc.js', '.eslintrc.cjs', '.eslintrc.json', 'eslint.config.js', 'eslint.config.mjs' },
          { path = ctx.filename, upward = true }
        )[1] ~= nil
      end,
    },
    -- prettier: skip if no prettier config found (avoids reformatting projects that don't use it)
    prettier = {
      condition = function(_, ctx)
        return vim.fs.find(
          { '.prettierrc', '.prettierrc.js', '.prettierrc.cjs', '.prettierrc.json', '.prettierrc.yaml', '.prettierrc.yml', 'prettier.config.js', 'prettier.config.cjs' },
          { path = ctx.filename, upward = true }
        )[1] ~= nil
      end,
    },
  },
})

-- Override kickstart's format keymap with lsp_fallback support
vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
  conform.format { async = true, lsp_fallback = true }
end, { desc = '[F]ormat buffer' })

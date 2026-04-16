-- Multi-language formatter support via conform.nvim
return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>f',
      function()
        require('conform').format { async = true, lsp_fallback = true }
      end,
      desc = '[F]ormat buffer',
    },
  },
  opts = {
    -- Format on save
    format_on_save = function(bufnr)
      -- Disable for files without a configured formatter
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

    -- Formatter-specific config
    formatters = {
      -- eslint_d: only run --fix (not full format), skip if no eslint config found
      eslint_d = {
        condition = function(_, ctx)
          -- Only activate if there's an eslint config in the project
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
  },
}

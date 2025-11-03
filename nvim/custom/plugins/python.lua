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
    -- This ensures ruff uses the Poetry virtualenv and finds pyproject.toml
    lint.linters.ruff.cmd = 'python'
    lint.linters.ruff.args = { '-m', 'ruff', 'check', '--output-format', 'json', '--stdin-filename' }

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

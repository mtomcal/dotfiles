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

    -- Configure ruff to use Poetry if available, otherwise fall back to direct ruff
    -- This ensures ruff uses the Poetry virtualenv and finds pyproject.toml when available
    local function find_poetry_root()
      -- Look for pyproject.toml with [tool.poetry] section
      local root = vim.fn.findfile('pyproject.toml', vim.fn.getcwd() .. ';')
      if root ~= '' then
        local pyproject_path = vim.fn.fnamemodify(root, ':p')
        local content = vim.fn.readfile(pyproject_path)
        for _, line in ipairs(content) do
          if line:match('%[tool%.poetry%]') then
            return true
          end
        end
      end
      return false
    end

    if find_poetry_root() then
      lint.linters.ruff.cmd = 'poetry'
      lint.linters.ruff.args = { 'run', 'ruff', 'check', '--output-format', 'json', '--stdin-filename' }
    else
      -- Fallback to direct ruff command for non-Poetry projects
      lint.linters.ruff.cmd = 'ruff'
      lint.linters.ruff.args = { 'check', '--output-format', 'json', '--stdin-filename' }
    end

    -- Create autocommand to trigger linting
    local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      group = lint_augroup,
      callback = function()
        -- Only lint Python files
        if vim.bo.filetype == 'python' then
          -- Wrap in pcall to catch any errors and prevent them from propagating
          local ok, err = pcall(lint.try_lint)
          if not ok then
            -- Silently log the error instead of showing it to the user
            vim.notify('Linting error: ' .. tostring(err), vim.log.levels.DEBUG)
          end
        end
      end,
    })

    -- Keymap to manually trigger linting
    vim.keymap.set('n', '<leader>l', function()
      lint.try_lint()
    end, { desc = 'Trigger [L]inting for current file' })
  end,
}

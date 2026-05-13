-- Python tooling: LSP via pyright, linting via ruff

-- ============================================================
-- 1. Treesitter: ensure Python parser is installed
--    Enables syntax highlighting, folds, and indentation
-- ============================================================
require('nvim-treesitter').install('python')

-- ============================================================
-- 2. LSP: pyright for code intelligence
--    Provides go-to-definition, hover, autocomplete, type checking
-- ============================================================
vim.lsp.config('pyright', {
  root_markers = { 'pyrightconfig.json', 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', '.git' },
  filetypes = { 'python' },
  settings = {
    python = {
      analysis = {
        typeCheckingMode = 'basic',
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = 'openFilesOnly',
      },
    },
  },
  before_init = function(client, config)
    -- Dynamically detect a .venv and point pyright at it
    -- so that packages like langchain resolve correctly
    local root = config.root_dir
    if not root then return end

    local venv_dir = vim.fn.resolve(root .. '/.venv')
    if vim.fn.isdirectory(venv_dir) ~= 1 then
      -- Also check for 'venv' instead of '.venv'
      venv_dir = vim.fn.resolve(root .. '/venv')
      if vim.fn.isdirectory(venv_dir) ~= 1 then return end
    end

    config.settings = config.settings or {}
    config.settings.python = config.settings.python or {}

    -- Point to the venv Python interpreter
    local python_bin = venv_dir .. '/bin/python'
    if vim.fn.executable(python_bin) == 1 then
      config.settings.python.pythonPath = python_bin
    end

    -- Add site-packages as an extra path for reliable resolution
    -- Find the right python version dir inside the venv
    local handle = vim.uv.fs_scandir(venv_dir .. '/lib')
    if handle then
      while true do
        local name, type = vim.uv.fs_scandir_next(handle)
        if not name then break end
        if type == 'directory' then
          local site_pkgs = venv_dir .. '/lib/' .. name .. '/site-packages'
          if vim.fn.isdirectory(site_pkgs) == 1 then
            config.settings.python.analysis = config.settings.python.analysis or {}
            config.settings.python.analysis.extraPaths = { site_pkgs }
            break
          end
        end
      end
    end
  end,
})
vim.lsp.enable('pyright')

-- Ensure pyright gets installed via Mason if not present
vim.defer_fn(function()
  pcall(vim.cmd.MasonInstall, 'pyright')
end, 2000)

-- ============================================================
-- 3. Linting with Ruff via nvim-lint
--    Provides fast, inline diagnostics outside of LSP
-- ============================================================
vim.pack.add({
  { src = 'https://github.com/mfussenegger/nvim-lint' },
})

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

-- Autocommand to trigger linting on Python files
local lint_augroup = vim.api.nvim_create_augroup('custom-lint', { clear = true })
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

-- Auto-detect indentation from file content (vim-sleuth)
-- Note: kickstart.nvim provides guess-indent.nvim by default.
-- vim-sleuth is only loaded here as a fallback if guess-indent is not available.

local has_guess_indent = pcall(require, 'guess-indent')
if not has_guess_indent then
  vim.pack.add({
    { src = 'https://github.com/tpope/vim-sleuth' },
  })
end

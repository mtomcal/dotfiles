-- Diffview.nvim - Single tabpage interface for reviewing diffs
-- Perfect for reviewing AI-generated code changes from Claude Code or Pi

vim.pack.add({
  { src = 'https://github.com/sindrets/diffview.nvim' },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
})

vim.keymap.set('n', '<leader>dv', '<cmd>DiffviewOpen<cr>', { desc = 'Open [D]iff[v]iew' })
vim.keymap.set('n', '<leader>dc', '<cmd>DiffviewClose<cr>', { desc = '[D]iff [C]lose' })
vim.keymap.set('n', '<leader>dh', '<cmd>DiffviewFileHistory %<cr>', { desc = '[D]iff [H]istory (current file)' })
vim.keymap.set('n', '<leader>df', '<cmd>DiffviewFileHistory<cr>', { desc = '[D]iff [F]ile history (all files)' })

require('diffview').setup({
  enhanced_diff_hl = true, -- Better diff highlighting
  view = {
    default = { layout = 'diff2_horizontal' },
    merge_tool = { layout = 'diff3_horizontal' },
  },
  file_panel = {
    listing_style = 'tree',
    win_config = { position = 'left', width = 35 },
  },
})

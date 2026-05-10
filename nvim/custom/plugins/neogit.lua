-- Neogit - Interactive git interface for commits, rebases, and workflow
-- Integrates with diffview.nvim for a complete git experience

vim.pack.add({
  { src = 'https://github.com/NeogitOrg/neogit' },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/sindrets/diffview.nvim' },
  { src = 'https://github.com/nvim-telescope/telescope.nvim' },
})

vim.keymap.set('n', '<leader>gg', '<cmd>Neogit<cr>', { desc = 'Open Neo[g]it' })
vim.keymap.set('n', '<leader>gc', '<cmd>Neogit commit<cr>', { desc = '[G]it [C]ommit' })
vim.keymap.set('n', '<leader>gp', '<cmd>Neogit pull<cr>', { desc = '[G]it [P]ull' })
vim.keymap.set('n', '<leader>gP', '<cmd>Neogit push<cr>', { desc = '[G]it [P]ush' })

require('neogit').setup({
  integrations = { diffview = true },
  graph_style = 'unicode',
  -- Use telescope for branch selection and other pickers
  telescope_sorter = function()
    return require('telescope').extensions.fzy_native.native_fzy_sorter()
  end,
})

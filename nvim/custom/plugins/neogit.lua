-- Neogit - Interactive git interface for commits, rebases, and workflow
-- Integrates with diffview.nvim for a complete git experience
return {
  'NeogitOrg/neogit',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'sindrets/diffview.nvim',
    'nvim-telescope/telescope.nvim',
  },
  cmd = 'Neogit',
  keys = {
    { '<leader>gg', '<cmd>Neogit<cr>', desc = 'Open Neo[g]it' },
    { '<leader>gc', '<cmd>Neogit commit<cr>', desc = '[G]it [C]ommit' },
    { '<leader>gp', '<cmd>Neogit pull<cr>', desc = '[G]it [P]ull' },
    { '<leader>gP', '<cmd>Neogit push<cr>', desc = '[G]it [P]ush' },
  },
  opts = {
    integrations = {
      diffview = true,
    },
    graph_style = 'unicode',
    -- Use telescope for branch selection and other pickers
    telescope_sorter = function()
      return require('telescope').extensions.fzy_native.native_fzy_sorter()
    end,
  },
}

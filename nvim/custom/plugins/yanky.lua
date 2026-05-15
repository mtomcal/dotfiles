return {
  'gbprod/yanky.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  config = function()
    require('yanky').setup({
      highlight = { timer = 300 },   -- pulse yanked text for 300ms
      ring = { storage = 'shada' },  -- persist yank history across neovim sessions
      system_clipboard = {
        sync_with_osc52 = false,     -- only explicit yanks (y, yw, etc.) go to system clipboard
      },                             -- deletes (dd, x, c, etc.) stay out of OS clipboard
    })
    vim.keymap.set({ 'n', 'x' }, '<leader>py', '<cmd>Telescope yank_history<cr>', { desc = 'Yank history' })
  end,
}

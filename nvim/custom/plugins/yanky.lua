return {
  'gbprod/yanky.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  config = function()
    require('yanky').setup({
      highlight = { timer = 300 },   -- pulse yanked text for 300ms
      ring = { storage = 'shada' },  -- persist yank history across neovim sessions
      system_clipboard = {
        sync_with_ring = false,      -- don't sync ring ↔ system clipboard (deletes would leak)
      },
    })
    vim.keymap.set({ 'n', 'x' }, '<leader>py', '<cmd>Telescope yank_history<cr>', { desc = 'Yank history' })
  end,
}

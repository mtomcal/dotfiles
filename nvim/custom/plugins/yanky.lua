-- Yank history. This config uses vim.pack, not lazy.nvim, so this file must
-- execute the install/setup directly rather than returning a lazy plugin spec.
vim.pack.add({
  { src = 'https://github.com/gbprod/yanky.nvim' },
})

require('yanky').setup({
  highlight = { timer = 300 },   -- pulse yanked text for 300ms
  ring = { storage = 'shada' },  -- persist yank history across neovim sessions
  system_clipboard = {
    sync_with_ring = false,      -- don't sync ring ↔ system clipboard (deletes would leak)
  },
})

vim.keymap.set({ 'n', 'x' }, '<leader>py', '<cmd>Telescope yank_history<cr>', { desc = 'Yank history' })

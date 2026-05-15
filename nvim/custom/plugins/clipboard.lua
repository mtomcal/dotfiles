-- Clipboard: sync yank/delete to system clipboard (+ register)
vim.opt.clipboard = 'unnamedplus'

-- Paste from register 0 (last yank) — survives deletes that crush unnamed.
-- Use gp after a stray dd/x destroyed your yank.
vim.keymap.set({ 'n', 'x' }, 'gp', '"0p', { desc = 'Paste last yank (preserved across deletes)' })
vim.keymap.set({ 'n', 'x' }, 'gP', '"0P', { desc = 'Paste last yank before cursor' })

-- Quick peek at all registers
vim.keymap.set('n', '<leader>pr', ':registers<CR>', { desc = 'Show registers' })

-- Only sync explicit yanks to system clipboard — deletes stay local.
-- (clipboard=unnamedplus is avoided because it pushes dd/x/c to OS clipboard)
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    if vim.v.event.operator == 'y' then
      vim.fn.setreg('+', vim.v.event.regcontents)
    end
  end,
})

-- Paste from register 0 (last yank) — survives deletes that crush unnamed.
-- Use gp after a stray dd/x destroyed your yank.
vim.keymap.set({ 'n', 'x' }, 'gp', '"0p', { desc = 'Paste last yank (preserved across deletes)' })
vim.keymap.set({ 'n', 'x' }, 'gP', '"0P', { desc = 'Paste last yank before cursor' })

-- Quick peek at all registers
vim.keymap.set('n', '<leader>pr', ':registers<CR>', { desc = 'Show registers' })

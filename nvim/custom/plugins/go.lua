-- Go development: debugging (nvim-dap-go) and testing (neotest-golang)

-- Install all Go-related plugins
vim.pack.add({
  -- Debugging
  { src = 'https://github.com/mfussenegger/nvim-dap' },
  { src = 'https://github.com/rcarriga/nvim-dap-ui' },
  { src = 'https://github.com/nvim-neotest/nvim-nio' },
  { src = 'https://github.com/leoluz/nvim-dap-go' },
  -- Testing
  { src = 'https://github.com/nvim-neotest/neotest' },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },
  { src = 'https://github.com/fredrikaverpil/neotest-golang' },
})

-- Configure nvim-dap-go and debug keymaps only for Go files
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'go',
  callback = function()
    require('dap-go').setup()

    vim.keymap.set('n', '<leader>dt', function()
      require('dap-go').debug_test()
    end, { buffer = true, desc = '[D]ebug [T]est' })
    vim.keymap.set('n', '<leader>db', function()
      require('dap').toggle_breakpoint()
    end, { buffer = true, desc = '[D]ebug Toggle [B]reakpoint' })
    vim.keymap.set('n', '<leader>dc', function()
      require('dap').continue()
    end, { buffer = true, desc = '[D]ebug [C]ontinue' })
  end,
})

-- Configure neotest with Go adapter
require('neotest').setup({
  adapters = {
    require('neotest-golang')({
      go_test_args = { '-v', '-race', '-count=1' },
      dap_go_enabled = true,
    }),
  },
})

-- Testing keymaps
vim.keymap.set('n', '<leader>tn', function()
  require('neotest').run.run()
end, { desc = '[T]est [N]earest' })
vim.keymap.set('n', '<leader>tf', function()
  require('neotest').run.run(vim.fn.expand('%'))
end, { desc = '[T]est [F]ile' })
vim.keymap.set('n', '<leader>to', function()
  require('neotest').output.open()
end, { desc = '[T]est [O]utput' })
vim.keymap.set('n', '<leader>ts', function()
  require('neotest').summary.toggle()
end, { desc = '[T]est [S]ummary' })

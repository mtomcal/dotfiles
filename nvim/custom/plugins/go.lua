return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'nvim-neotest/nvim-nio',
    },
  },
  {
    'leoluz/nvim-dap-go',
    ft = 'go',
    dependencies = { 'mfussenegger/nvim-dap' },
    config = function()
      require('dap-go').setup()

      -- Keymaps for debugging
      vim.keymap.set('n', '<leader>dt', function()
        require('dap-go').debug_test()
      end, { desc = '[D]ebug [T]est' })
      vim.keymap.set('n', '<leader>db', function()
        require('dap').toggle_breakpoint()
      end, { desc = '[D]ebug Toggle [B]reakpoint' })
      vim.keymap.set('n', '<leader>dc', function()
        require('dap').continue()
      end, { desc = '[D]ebug [C]ontinue' })
    end,
  },
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'fredrikaverpil/neotest-golang',
    },
    config = function()
      require('neotest').setup {
        adapters = {
          require('neotest-golang') {
            go_test_args = { '-v', '-race', '-count=1' },
            dap_go_enabled = true,
          },
        },
      }

      -- Keymaps for testing
      vim.keymap.set('n', '<leader>tn', function()
        require('neotest').run.run()
      end, { desc = '[T]est [N]earest' })
      vim.keymap.set('n', '<leader>tf', function()
        require('neotest').run.run(vim.fn.expand '%')
      end, { desc = '[T]est [F]ile' })
      vim.keymap.set('n', '<leader>to', function()
        require('neotest').output.open()
      end, { desc = '[T]est [O]utput' })
      vim.keymap.set('n', '<leader>ts', function()
        require('neotest').summary.toggle()
      end, { desc = '[T]est [S]ummary' })
    end,
  },
}

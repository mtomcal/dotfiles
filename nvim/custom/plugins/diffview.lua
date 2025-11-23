-- Diffview.nvim - Single tabpage interface for reviewing diffs
-- Perfect for reviewing AI-generated code changes from Claude Code or OpenCode
return {
  'sindrets/diffview.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- optional, for file icons
  },
  cmd = {
    'DiffviewOpen',
    'DiffviewClose',
    'DiffviewToggleFiles',
    'DiffviewFocusFiles',
    'DiffviewRefresh',
    'DiffviewFileHistory',
  },
  keys = {
    { '<leader>dv', '<cmd>DiffviewOpen<cr>', desc = 'Open [D]iff[v]iew' },
    { '<leader>dc', '<cmd>DiffviewClose<cr>', desc = '[D]iff [C]lose' },
    { '<leader>dh', '<cmd>DiffviewFileHistory %<cr>', desc = '[D]iff [H]istory (current file)' },
    { '<leader>df', '<cmd>DiffviewFileHistory<cr>', desc = '[D]iff [F]ile history (all files)' },
  },
  opts = {
    enhanced_diff_hl = true, -- Better diff highlighting
    view = {
      default = {
        layout = 'diff2_horizontal',
      },
      merge_tool = {
        layout = 'diff3_horizontal',
      },
    },
    file_panel = {
      listing_style = 'tree',
      win_config = {
        position = 'left',
        width = 35,
      },
    },
  },
}

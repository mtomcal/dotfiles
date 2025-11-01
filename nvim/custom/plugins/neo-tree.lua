-- Neo-tree configuration optimized for SSH terminals without Nerd Fonts
return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    close_if_last_window = true,
    default_component_configs = {
      icon = {
        folder_closed = "+",
        folder_open = "-",
        folder_empty = "o",
        default = " ",
      },
      git_status = {
        symbols = {
          added     = "A",
          modified  = "M",
          deleted   = "D",
          renamed   = "R",
          untracked = "U",
          ignored   = "I",
          unstaged  = "u",
          staged    = "s",
          conflict  = "C",
        }
      },
    },
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
      filtered_items = {
        visible = false,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
  },
}

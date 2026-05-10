-- Neo-tree file explorer optimized for SSH terminals without Nerd Fonts
-- Replaces file icons with ASCII characters

vim.pack.add({
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range('*') },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  { src = 'https://github.com/MunifTanjim/nui.nvim' },
})

vim.keymap.set('n', '\\', ':Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

-- Override nvim-web-devicons with ASCII letters (zero font dependencies)
require('nvim-web-devicons').setup({
  override = {
    -- Markup / web
    html = { icon = 'H', color = '#e44d26', name = 'Html' },
    css = { icon = 'C', color = '#42a5f5', name = 'Css' },
    scss = { icon = 'C', color = '#f06292', name = 'Scss' },
    less = { icon = 'C', color = '#1b79c6', name = 'Less' },
    svg = { icon = 'V', color = '#ffb74d', name = 'Svg' },
    xml = { icon = '<', color = '#e44d26', name = 'Xml' },
    -- JavaScript / TypeScript
    javascript = { icon = 'J', color = '#f0db4f', name = 'Js' },
    javascriptreact = { icon = 'J', color = '#00bcd4', name = 'Jsx' },
    typescript = { icon = 'T', color = '#3178c6', name = 'Ts' },
    typescriptreact = { icon = 'T', color = '#03a9f4', name = 'Tsx' },
    vue = { icon = 'V', color = '#41b883', name = 'Vue' },
    svelte = { icon = 'S', color = '#ff3e00', name = 'Svelte' },
    -- Data
    json = { icon = 'J', color = '#fbc02d', name = 'Json' },
    jsonc = { icon = 'J', color = '#fbc02d', name = 'Jsonc' },
    yaml = { icon = 'Y', color = '#ff7043', name = 'Yaml' },
    yml = { icon = 'Y', color = '#ff7043', name = 'Yml' },
    toml = { icon = 'T', color = '#9e9e9e', name = 'Toml' },
    -- Languages
    lua = { icon = 'L', color = '#51a0cf', name = 'Lua' },
    python = { icon = 'P', color = '#ffd43b', name = 'Py' },
    go = { icon = 'G', color = '#00add8', name = 'Go' },
    rust = { icon = 'R', color = '#dea584', name = 'Rs' },
    ruby = { icon = 'R', color = '#cc342d', name = 'Rb' },
    c = { icon = 'C', color = '#599eff', name = 'C' },
    cpp = { icon = 'C', color = '#599eff', name = 'Cpp' },
    java = { icon = 'J', color = '#f89820', name = 'Java' },
    kotlin = { icon = 'K', color = '#7f52ff', name = 'Kt' },
    swift = { icon = 'S', color = '#f05138', name = 'Swift' },
    -- Shell
    sh = { icon = '>', color = '#89e051', name = 'Sh' },
    bash = { icon = '>', color = '#89e051', name = 'Bash' },
    zsh = { icon = '>', color = '#89e051', name = 'Zsh' },
    -- Config / docs
    markdown = { icon = 'M', color = '#519aba', name = 'Md' },
    vim = { icon = 'V', color = '#019833', name = 'Vim' },
    makefile = { icon = 'M', color = '#6d8086', name = 'Make' },
    -- Container
    dockerfile = { icon = 'D', color = '#384d54', name = 'Docker' },
    -- Git
    gitcommit = { icon = 'G', color = '#f54d27', name = 'Git' },
    gitconfig = { icon = 'G', color = '#f54d27', name = 'Gitcfg' },
    gitignore = { icon = 'G', color = '#f54d27', name = 'Gitign' },
    -- Misc
    licence = { icon = 'L', color = '#c0c0c0', name = 'License' },
    lock = { icon = 'L', color = '#ffca28', name = 'Lock' },
    log = { icon = 'L', color = '#9e9e9e', name = 'Log' },
    env = { icon = 'E', color = '#fbc02d', name = 'Env' },
  },
})

require('neo-tree').setup({
  close_if_last_window = true,
  default_component_configs = {
    icon = {
      folder_closed = '+',
      folder_open = '-',
      folder_empty = 'o',
      default = ' ',
    },
    git_status = {
      symbols = {
        added     = 'A',
        modified  = 'M',
        deleted   = 'D',
        renamed   = 'R',
        untracked = 'U',
        ignored   = 'I',
        unstaged  = 'u',
        staged    = 's',
        conflict  = 'C',
      },
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
})

-- Markdown rendering plugin for beautiful in-editor viewing

vim.pack.add({
  { src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
})

require('render-markdown').setup({})

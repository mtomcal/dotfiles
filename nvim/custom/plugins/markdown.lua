-- Markdown rendering plugin for beautiful in-editor viewing
return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {},
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons"
  },
  -- Only load for markdown files
  ft = { "markdown" },
}

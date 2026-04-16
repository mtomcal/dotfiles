-- Auto-detect indentation from file content (vim-sleuth)
-- EditorConfig is built into Neovim 0.9+ and enabled by default.
-- vim-sleuth acts as fallback for projects without .editorconfig.
return {
  'tpope/vim-sleuth',
  event = { 'BufReadPre', 'BufNewFile' },
}

-- Adds an indent indicator to mini.statusline showing current tab settings.
-- Examples: "·2" = spaces width 2, "→4" = tabs width 4
-- Note: mini.nvim is already installed by kickstart.nvim; this just enhances it.

local statusline = require('mini.statusline')

-- Patch the statusline: add indent info between filename and right sections
statusline.active = function()
  local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
  local git = statusline.section_git({ trunc_width = 75 })
  local diagnostics = statusline.section_diagnostics({ trunc_width = 75 })
  local filename = statusline.section_filename({ trunc_width = 140 })
  local fileinfo = statusline.section_fileinfo({ trunc_width = 120 })
  local location = statusline.section_location({ trunc_width = 75 })

  -- Indent indicator: · for spaces, → for tabs
  local indent_char = vim.bo.expandtab and '\xc2\xb7' or '\xe2\x86\x92'
  local indent_size = vim.bo.expandtab and vim.bo.shiftwidth or vim.bo.tabstop
  local indent_info = indent_char .. tostring(indent_size)

  return statusline.combine_groups({
    { hl = mode_hl, strings = { mode } },
    { hl = 'MiniStatuslineDevinfo', strings = { git, diagnostics } },
    '%<', -- truncation point
    { hl = 'MiniStatuslineFilename', strings = { filename } },
    '%=', -- right-align remainder
    { hl = 'MiniStatuslineFileinfo', strings = { indent_info, fileinfo } },
    { hl = mode_hl, strings = { location } },
  })
end

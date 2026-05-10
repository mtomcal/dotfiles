-- Auto-loads all plugin files in this directory using vim.fn.glob().
-- Each file is a self-contained vim.pack plugin specification.

local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')

for _, file in ipairs(vim.fn.glob(plugin_dir .. '/*.lua', false, true)) do
  local basename = vim.fn.fnamemodify(file, ':t')
  if basename ~= 'init.lua' then
    local ok, err = pcall(require, 'custom.plugins.' .. vim.fn.fnamemodify(basename, ':r'))
    if not ok then
      vim.notify('Error loading custom plugin ' .. basename .. ': ' .. tostring(err), vim.log.levels.ERROR)
    end
  end
end

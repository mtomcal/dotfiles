# Custom Neovim Configuration

This directory is linked to `~/.config/nvim/lua/custom` on top of the installer-managed kickstart.nvim checkout.

## Loader contract

Kickstart loads `custom.plugins`, which resolves to `plugins/init.lua`. That loader executes every other `.lua` file in `plugins/` as `custom.plugins.<filename>`.

Each plugin file is therefore a self-contained Lua module. It should install dependencies with `vim.pack.add`, configure them directly, and register its own keymaps or autocmds. Do not return a lazy.nvim plugin specification.

## Add a plugin

Create `plugins/my-plugin.lua`:

```lua
vim.pack.add({
  { src = 'https://github.com/author/plugin-name' },
})

require('plugin-name').setup({
  -- options
})

vim.keymap.set('n', '<leader>xx', '<cmd>PluginCommand<CR>', {
  desc = 'Plugin command',
})
```

Restart Neovim so `vim.pack` can install and load the addition.

## Add configuration without a plugin

Plain configuration can use the same module layout. Create a descriptively named file under `plugins/` and make its effects idempotent enough for ordinary Neovim startup.

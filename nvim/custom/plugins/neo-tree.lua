-- Neo-tree file explorer optimized for SSH terminals without Nerd Fonts
-- Replaces all file icons with ASCII letters

vim.pack.add({
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range('*') },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  { src = 'https://github.com/MunifTanjim/nui.nvim' },
})

vim.keymap.set('n', '\\', ':Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

-- ── ASCII icon definitions (extension → {icon, color, name}) ────────────
local ascii_ext = {
  -- Markup / web
  html = { icon = 'H', color = '#e44d26', name = 'Html' },
  htm = { icon = 'H', color = '#e44d26', name = 'Htm' },
  css = { icon = 'C', color = '#42a5f5', name = 'Css' },
  scss = { icon = 'C', color = '#f06292', name = 'Scss' },
  less = { icon = 'C', color = '#1b79c6', name = 'Less' },
  svg = { icon = 'V', color = '#ffb74d', name = 'Svg' },
  xml = { icon = '<', color = '#e44d26', name = 'Xml' },
  -- JavaScript / TypeScript
  js = { icon = 'J', color = '#f0db4f', name = 'Js' },
  mjs = { icon = 'J', color = '#f0db4f', name = 'Mjs' },
  cjs = { icon = 'J', color = '#f0db4f', name = 'Cjs' },
  jsx = { icon = 'J', color = '#00bcd4', name = 'Jsx' },
  ts = { icon = 'T', color = '#3178c6', name = 'Ts' },
  mts = { icon = 'T', color = '#3178c6', name = 'Mts' },
  cts = { icon = 'T', color = '#3178c6', name = 'Cts' },
  tsx = { icon = 'T', color = '#03a9f4', name = 'Tsx' },
  vue = { icon = 'V', color = '#41b883', name = 'Vue' },
  svelte = { icon = 'S', color = '#ff3e00', name = 'Svelte' },
  astro = { icon = 'A', color = '#ff5a03', name = 'Astro' },
  -- Data formats
  json = { icon = 'J', color = '#fbc02d', name = 'Json' },
  jsonc = { icon = 'J', color = '#fbc02d', name = 'Jsonc' },
  yaml = { icon = 'Y', color = '#ff7043', name = 'Yaml' },
  yml = { icon = 'Y', color = '#ff7043', name = 'Yml' },
  toml = { icon = 'T', color = '#9e9e9e', name = 'Toml' },
  csv = { icon = 'C', color = '#9e9e9e', name = 'Csv' },
  -- Languages
  lua = { icon = 'L', color = '#51a0cf', name = 'Lua' },
  py = { icon = 'P', color = '#ffd43b', name = 'Py' },
  pyi = { icon = 'P', color = '#ffd43b', name = 'Pyi' },
  go = { icon = 'G', color = '#00add8', name = 'Go' },
  rs = { icon = 'R', color = '#dea584', name = 'Rs' },
  rb = { icon = 'R', color = '#cc342d', name = 'Rb' },
  c = { icon = 'C', color = '#599eff', name = 'C' },
  h = { icon = 'C', color = '#599eff', name = 'H' },
  cpp = { icon = 'C', color = '#599eff', name = 'Cpp' },
  hpp = { icon = 'C', color = '#599eff', name = 'Hpp' },
  java = { icon = 'J', color = '#f89820', name = 'Java' },
  kt = { icon = 'K', color = '#7f52ff', name = 'Kt' },
  swift = { icon = 'S', color = '#f05138', name = 'Swift' },
  php = { icon = 'P', color = '#4f5b93', name = 'Php' },
  ex = { icon = 'E', color = '#a074c4', name = 'Ex' },
  exs = { icon = 'E', color = '#a074c4', name = 'Exs' },
  zig = { icon = 'Z', color = '#f7a41d', name = 'Zig' },
  dart = { icon = 'D', color = '#00b4ab', name = 'Dart' },
  r = { icon = 'R', color = '#2266b1', name = 'R' },
  scala = { icon = 'S', color = '#dc322f', name = 'Scala' },
  -- Shell / scripting
  sh = { icon = '>', color = '#89e051', name = 'Sh' },
  bash = { icon = '>', color = '#89e051', name = 'Bash' },
  zsh = { icon = '>', color = '#89e051', name = 'Zsh' },
  fish = { icon = '>', color = '#89e051', name = 'Fish' },
  ps1 = { icon = '>', color = '#4273ca', name = 'Ps1' },
  -- Config / docs
  md = { icon = 'M', color = '#519aba', name = 'Md' },
  mdx = { icon = 'M', color = '#519aba', name = 'Mdx' },
  vim = { icon = 'V', color = '#019833', name = 'Vim' },
  ini = { icon = 'I', color = '#9e9e9e', name = 'Ini' },
  cfg = { icon = 'I', color = '#9e9e9e', name = 'Cfg' },
  conf = { icon = 'I', color = '#9e9e9e', name = 'Conf' },
  editorconfig = { icon = 'I', color = '#9e9e9e', name = 'EditorConfig' },
  -- Database
  sql = { icon = 'S', color = '#f29111', name = 'Sql' },
  graphql = { icon = 'G', color = '#e10098', name = 'GraphQL' },
  gql = { icon = 'G', color = '#e10098', name = 'Gql' },
  prisma = { icon = 'P', color = '#2d3748', name = 'Prisma' },
  -- IaC
  tf = { icon = 'T', color = '#5c4ee5', name = 'Tf' },
  tfvars = { icon = 'T', color = '#5c4ee5', name = 'Tfvars' },
  -- Docs
  txt = { icon = 'T', color = '#9e9e9e', name = 'Txt' },
  rst = { icon = 'R', color = '#9e9e9e', name = 'Rst' },
  tex = { icon = 'T', color = '#9e9e9e', name = 'Tex' },
  -- Misc
  lock = { icon = 'L', color = '#ffca28', name = 'Lock' },
  log = { icon = 'L', color = '#9e9e9e', name = 'Log' },
  env = { icon = 'E', color = '#fbc02d', name = 'Env' },
}

-- ── Manual filename overrides (no extension) ─────────────────────────────
local ascii_manual_filename = {
  ['Dockerfile'] = { icon = 'D', color = '#384d54', name = 'Docker' },
  ['.dockerignore'] = { icon = 'D', color = '#384d54', name = 'Dockerign' },
  ['Makefile'] = { icon = 'M', color = '#6d8086', name = 'Make' },
  ['CMakeLists.txt'] = { icon = 'C', color = '#6d8086', name = 'CMake' },
  ['.gitignore'] = { icon = 'G', color = '#f54d27', name = 'Gitign' },
  ['.gitconfig'] = { icon = 'G', color = '#f54d27', name = 'Gitcfg' },
  ['.gitattributes'] = { icon = 'G', color = '#f54d27', name = 'Gitattr' },
  ['LICENSE'] = { icon = 'L', color = '#c0c0c0', name = 'License' },
  ['LICENCE'] = { icon = 'L', color = '#c0c0c0', name = 'License' },
}

-- ── Generate overrides for built-in compound keys ────────────────────────
-- nvim-web-devicons checks exact filename before extension.  Built-in tables
-- contain hundreds of compound keys (package.json, tsconfig.json, etc.) that
-- block extension overrides.  We regenerate matching ASCII entries at runtime
-- so every built-in compound key gets our ASCII icon based on its extension.

local function extension_icon(key)
  -- Extract the rightmost extension from a dotted key, walking left
  -- until we match our ascii_ext table.
  --  "package.json" → "json" → found
  --  "blade.php"    → "php"  → found
  --  "d.ts"         → "ts"   → found
  local rest = key:lower():match('%.(.+)')
  while rest do
    if ascii_ext[rest] then
      return ascii_ext[rest]
    end
    rest = rest:match('%.(.+)')
  end
end

local function merged_module_icon_keys(module_name, target)
  local ok, tbl = pcall(require, module_name)
  if not ok then
    return
  end
  for key in pairs(tbl) do
    if key:find('%.') then
      local icon = extension_icon(key)
      if icon then
        target[key:lower()] = icon
      end
    end
  end
end

-- Compound extension keys (e.g. "test.ts", "spec.tsx", "stories.js", "d.ts")
local ext_with_compounds = vim.deepcopy(ascii_ext)
merged_module_icon_keys('nvim-web-devicons.default.icons_by_file_extension', ext_with_compounds)
merged_module_icon_keys('nvim-web-devicons.light.icons_by_file_extension', ext_with_compounds)

-- Compound filename keys (e.g. "package.json", "tsconfig.json", "compose.yml")
local auto_filename = {}
merged_module_icon_keys('nvim-web-devicons.default.icons_by_filename', auto_filename)
merged_module_icon_keys('nvim-web-devicons.light.icons_by_filename', auto_filename)

-- Merge manual + auto overrides
local filename_overrides = vim.tbl_extend('force', auto_filename, ascii_manual_filename)

-- ── Apply ─────────────────────────────────────────────────────────────────
require('nvim-web-devicons').setup({
  default = true,
  strict = true,
  override_by_extension = ext_with_compounds,
  override_by_filename = filename_overrides,
})

-- ── Neo-tree configuration ────────────────────────────────────────────────
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

# Neovim Configuration Specification

> **Version**: 1.0.0
> **Last Updated**: 2026-05-01
> **Depends On**: [Parameters](parameters.md), [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md), [Design Language](DESIGN_LANGUAGE.md)
> **Depended By**: Install Orchestrator

---

## Overview

The Neovim configuration system provides a two-layer editor setup: an official upstream **kickstart** base layer and a user-authored **custom layer** that is symlinked into place. The kickstart layer provides core plugin management (lazy.nvim), LSP configuration, and default keybindings. The custom layer adds language-specific development plugins, formatting, linting, git integration, file management, and visual enhancements — all defined as lazy.nvim plugin specifications.

The system ensures that kickstart remains independently updatable (via git operations) while preserving all user customizations in a separate directory tree. Installation is idempotent: re-running the install script reconciles the symlink, re-enables the custom plugin import, and refreshes plugins and Mason packages.

---

## Dependencies

### Technology Dependencies

| Dependency | Minimum Version | Purpose |
|------------|----------------|---------|
| Neovim | 0.10 | Required for all kickstart features and custom plugins |
| lazy.nvim | Latest (auto-installed) | Plugin manager, bootstrapped by kickstart |
| Mason | Latest (via kickstart) | LSP server, formatter, and linter package manager |
| Git | Any | Kickstart repo cloning and updates |
| ripgrep | Any | Telescope live grep backend |
| fd | Any | Telescope file finder backend |
| Tree-sitter | Via kickstart | Syntax highlighting and markdown rendering |
| Go | 1.24 | Required by gofumpt formatter and govulncheck |
| nvim-dap | Latest (via lazy.nvim) | Debug Adapter Protocol framework for Go debugging |
| nvim-dap-ui | Latest (via lazy.nvim) | Visual debugger UI for DAP |
| nvim-nio | Latest (via lazy.nvim) | Async library required by nvim-dap-ui and neotest |

### Spec Dependencies

| Spec | Reason |
|------|--------|
| [Parameters](parameters.md) | Authoritative values for `NVIM_LEADER_KEY`, `FORMAT_ON_SAVE`, `PRETTIER_PRIORITY`, `MASON_TOOLS_GO`, `MASON_TOOLS_PYTHON` |
| [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md) | Terms: kickstart, custom layer, plugin (Neovim), install (Mason), formatter, LSP server |
| [Design Language](DESIGN_LANGUAGE.md) | Leader command, Which-key menu, Statusline component definitions |

---

## Parameters

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| `NVIM_LEADER_KEY` | Space | key | Most ergonomic leader key; accessible from both hands; widely used convention |
| `FORMAT_ON_SAVE` | conditional function | function | Returns format options (timeout_ms and lsp_fallback) per-buffer; returns nil for ignored filetypes to skip formatting; functionally equivalent to enabling format-on-save with an empty ignore list |
| `FORMAT_TIMEOUT_MS` | 2000 | milliseconds | Two-second timeout balances responsiveness against slow formatters on large files |
| `LSP_FORMAT_FALLBACK` | true | toggle | When no conform.nvim formatter is configured, fall back to LSP formatting |
| `PRETTIER_PRIORITY` | higher than eslint_d | ordering | Prettier takes precedence for JS/TS formatting when both config files exist; avoids conflicting style rules |
| `MASON_TOOLS_PYTHON` | pyright | list | Python language server (canonical name from parameters.md); installed alongside always-installed packages during nvim_config module |
| _Always-installed Mason packages_ | stylua, ruff, prettier, eslint_d | list | Lua formatting, Python/JS linting, JS/TS formatting; installed alongside MASON_TOOLS_PYTHON during nvim_config module |
| `MASON_TOOLS_GO` | gopls, delve, gofumpt, goimports | list | Go development toolchain: language server, debugger, formatter, import manager |
| `DIFFVIEW_LAYOUT` | diff2_horizontal | enum | Horizontal two-pane diff for default view; three-pane for merge tool |
| `DIFFVIEW_PANEL_WIDTH` | 35 | columns | File panel width balances visibility against editor space |
| `NEOTREE_HIDE_DOTFILES` | false | toggle | Dotfiles visible by default for dotfiles-centric workflow |
| `NEOTREE_HIDE_GITIGNORED` | false | toggle | Gitignored files visible by default for environment-aware navigation |
| `INDICATOR_SPACE` | · (middle dot, U+00B7) | character | Visually distinct from regular space and hyphen |
| `INDICATOR_TAB` | → (right arrow, U+2192) | character | Universally recognized directional symbol for tab indentation |
| `STATUSLINE_MODE_WIDTH` | 120 | columns | Active mode section truncates below this width |
| `STATUSLINE_GIT_WIDTH` | 75 | columns | Git branch section truncates below this width |
| `STATUSLINE_DIAGNOSTICS_WIDTH` | 75 | columns | Diagnostics section truncates below this width |
| `STATUSLINE_FILENAME_WIDTH` | 140 | columns | Filename section truncates below this width |
| `STATUSLINE_FILEINFO_WIDTH` | 120 | columns | File info section truncates below this width |
| `STATUSLINE_LOCATION_WIDTH` | 75 | columns | Cursor location section truncates below this width |
| `GO_TEST_ARGS` | -v -race -count=1 | flags | Verbose output, race detector, no test caching — strict test discipline |
| `DAP_GO_ENABLED` | true | toggle | Enables debug adapter protocol integration for Go test debugging |
| `NEOGIT_GRAPH_STYLE` | unicode | enum | Unicode branch graph for visual clarity in git log |
| `LAZY_LOAD_EVENTS` | Per-plugin | event list | Each plugin specifies its own lazy-load trigger (see Behavior section) |

---

## Data Structures

### Plugin Specification

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| name | string | Required, lazy.nvim short URL | Plugin identifier (e.g., `stevearc/conform.nvim`) |
| lazy | boolean | Default: true for most plugins | Whether to defer loading; `false` only for neo-tree |
| event | list of string | Lazy-load trigger events | Autocommand events that trigger load (e.g., `BufWritePre`) |
| cmd | list of string | Lazy-load trigger commands | User commands that trigger load |
| ft | list of string | Lazy-load trigger filetypes | Filetypes that trigger load (e.g., `go`, `markdown`) |
| keys | list of map | Keymaps that trigger load + bind | Each entry: `{lhs, rhs, desc}` |
| dependencies | list of string | Plugin names | Other plugins that must load first |
| opts | map | Passed to plugin setup | Configuration table forwarded to plugin's `.setup()` |

### Git Status Symbol Map

| Symbol | Meaning |
|--------|---------|
| A | Added |
| M | Modified |
| D | Deleted |
| R | Renamed |
| U | Untracked |
| I | Ignored |
| u | Unstaged |
| s | Staged |
| C | Conflict |

### Formatter Configuration

| Filetype | Formatters (ordered) | Condition |
|----------|---------------------|-----------|
| go | goimports, gofumpt | Always active |
| python | ruff_format | Always active |
| javascript | prettier, eslint_d | prettier: requires prettier config file; eslint_d: requires eslint config file |
| typescript | prettier, eslint_d | prettier: requires prettier config file; eslint_d: requires eslint config file |
| javascriptreact | prettier, eslint_d | Same conditions as javascript |
| typescriptreact | prettier, eslint_d | Same conditions as javascript |
| html | prettier | Requires prettier config file |
| css | prettier | Requires prettier config file |
| scss | prettier | Requires prettier config file |
| json | prettier | Requires prettier config file |
| jsonc | prettier | Requires prettier config file |
| yaml | prettier | Requires prettier config file |
| markdown | prettier | Requires prettier config file |
| lua | stylua | Always active |

### Indent Indicator

| Mode | Character | Source Field |
|------|-----------|-------------|
| Spaces | · (U+00B7) | `shiftwidth` |
| Tabs | → (U+2192) | `tabstop` |

---

## Behavior

### Two-Layer Architecture

1. The kickstart layer is a git-cloned repository at the standard Neovim config path.
2. The custom layer resides in the dotfiles repository and is symlinked into the kickstart layer.
3. The kickstart configuration MUST import the custom plugin module — the install script enables this by uncommenting the import line if it is commented out.
4. The kickstart layer MUST NOT be manually edited; all customization goes through the custom layer.
5. Kickstart updates (fetch and hard reset to origin/master) MUST NOT destroy or conflict with custom layer configurations.

### Kickstart Compatibility Patch

| Condition | Action |
|-----------|--------|
| kickstart contains commented-out custom plugin import | Uncomment the line to enable custom plugin loading |
| kickstart contains active custom plugin import | No change needed |
| kickstart uses deprecated treesitter configuration API | Update to the current treesitter configuration module |

### Plugin Lazy Loading

Each plugin loads on a specific trigger to minimize startup time:

| Plugin | Load Trigger | Rationale |
|--------|-------------|-----------|
| conform.nvim | `BufWritePre` event | Formats on save; must be present before first write |
| diffview.nvim | `<leader>d*` keymaps and `:Diffview*` commands | Only needed during code review sessions |
| render-markdown.nvim | `markdown` filetype | Only needed when viewing markdown |
| nvim-dap-go | `go` filetype | Only needed for Go debugging |
| nvim-lint | `BufReadPre`, `BufNewFile` events | Must lint on file open |
| vim-sleuth | `BufReadPre`, `BufNewFile` events | Must detect indentation on file open |
| neo-tree.nvim | `\` keymap | File explorer loads on demand; set `lazy = false` so it initializes at startup (nav sidebar) |
| neogit.nvim | `<leader>g*` keymaps and `:Neogit` command | Only needed during git operations |
| mini.nvim (statusline) | `VeryLazy` event | Statusline hooks must load shortly after UI init |
| neotest | Config function (Go filetype) | Only needed for Go testing |

### Format on Save

1. On `BufWritePre`, conform.nvim invokes formatting.
2. If the current filetype has a configured formatter, apply it with FORMAT_TIMEOUT_MS timeout and LSP_FORMAT_FALLBACK enabled.
3. If the current filetype is in the configured ignore list (currently empty), skip formatting.
4. Prettier activates ONLY when a prettier configuration file is found upward from the buffer's path.
5. eslint_d activates ONLY when an eslint configuration file is found upward from the buffer's path.
6. For JS/TS filetypes, both prettier and eslint_d may run; prettier runs first.
7. For filetypes with no configured formatter, LSP fallback delegates to the active LSP server.

### Manual Format

Pressing `<leader>f` triggers async formatting with LSP fallback for the current buffer.

### Python Linting

1. nvim-lint configures `ruff` as the linter for Python filetypes.
2. Poetry detection runs once at config load time based on the current working directory. If Neovim starts in a Poetry project (pyproject.toml with [tool.poetry] section), ruff is invoked through Poetry's virtual environment wrapper for all subsequent buffers.
3. If Neovim starts outside a Poetry project, ruff is invoked directly for all subsequent buffers.
4. Linting triggers on `BufEnter`, `BufWritePost`, and `InsertLeave` autocommands — but ONLY for Python filetypes.
5. Linting errors are caught gracefully and logged at DEBUG level (never shown to the user as an intrusive notification).
6. Pressing `<leader>l` manually triggers a lint check for the current buffer.

### Go Development

1. DAP (Debug Adapter Protocol) provides debugging: `<leader>dt` debug test, `<leader>db` toggle breakpoint, `<leader>dc` continue.
2. neotest with neotest-golang adapter provides test running: `<leader>tn` nearest test, `<leader>tf` file tests, `<leader>to` test output, `<leader>ts` test summary.
3. Go test arguments are `-v -race -count=1` for strict discipline.
4. dap-go integration is enabled within the neotest-golang adapter.

### Git Integration

#### diffview.nvim

| Keybinding | Action |
|------------|--------|
| `<leader>dv` | Open diffview |
| `<leader>dc` | Close diffview |
| `<leader>dh` | File history for current file |
| `<leader>df` | File history for all files |

- Enhanced diff highlighting is enabled.
- File panel uses tree listing style, positioned at left with 35-column width.

#### neogit.nvim

| Keybinding | Action |
|------------|--------|
| `<leader>gg` | Open neogit status |
| `<leader>gc` | Open neogit commit |
| `<leader>gp` | Open neogit pull |
| `<leader>gP` | Open neogit push |

- neogit integrates with diffview for visual diffs.
- Branch graph uses unicode style.
- Telescope sorter is used for branch selection.

### File Management (neo-tree)

| Keybinding | Action |
|------------|--------|
| `\` | Reveal current file in neo-tree |

- Backslash in the neo-tree window closes the sidebar.
- When neo-tree is the last window, it closes automatically.
- Dotfiles and gitignored files are visible (not hidden).
- Icons use ASCII characters (no Nerd Fonts required) for SSH compatibility.

### Markdown Rendering

- render-markdown.nvim loads exclusively for `markdown` filetype.
- Depends on nvim-treesitter and nvim-web-devicons.

### Indent Detection (vim-sleuth)

- vim-sleuth auto-detects indentation from file content.
- Acts as fallback when no `.editorconfig` exists (Neovim 0.9+ has built-in EditorConfig support).

### Statusline Indent Indicator

1. The mini.statusline `active` function is overridden to inject an indent indicator between the filename and fileinfo sections.
2. The indicator format is `{indent_char}{indent_size}`.
3. The indicator appears right-aligned in the fileinfo group.
4. Character selection follows the table in Data Structures above.

### Mason Package Installation

1. Always-installed Mason packages, including MASON_TOOLS_PYTHON (pyright) and language-agnostic tools (stylua, ruff, prettier, eslint_d), are installed during the nvim_config module of install.
2. Go Mason packages (gopls, delve, gofumpt, goimports) are installed during the `golang_full` module, conditional on Neovim being present.
3. Installation runs the Mason package manager in headless mode to install the required packages.

### Plugin Installation and Cache Management

1. Plugins are synced by running the plugin manager in headless mode.
2. If sync fails due to dirty local changes in lazy.nvim cache:
   - The system cleans dirty plugin directories (those with uncommitted changes).
   - A single retry of the plugin sync is attempted.
3. On a fresh installation (no `~/.local/share/nvim/lazy` directory), the entire nvim data directory is cleaned before first launch.
4. On an update installation, plugin data (`~/.local/share/nvim`) is preserved but cache is cleared.
5. Treesitter parsers are updated by running the parser update command in headless mode after plugin sync.

---

## Error Handling

| Error Case | Trigger | Detection | Response | Recovery |
|-----------|---------|------------|----------|----------|
| Neovim version too old | Neovim < 0.10 detected | Version string check in install script | Print warning with current version; install or upgrade Neovim | Successful install/upgrade resolves |
| Dirty lazy.nvim cache | Plugin sync fails with local changes message | Check sync output for local changes indication | Clean dirty plugin directories; retry sync once | If retry fails, print manual intervention instructions |
| Plugin sync failure (non-dirty) | Plugin sync fails without local changes | Non-zero exit code without local changes indication | Print warning; show manual command | User runs manual plugin sync via Lazy |
| Treesitter parser update failure | Parser update returns non-zero | Non-zero exit code | Print warning about parser issues | Most parsers degrade gracefully; manual parser update within Neovim |
| Mason install failure | Mason install returns non-zero | Non-zero exit code | Print warning; show manual Mason installation guidance | User installs packages manually inside Neovim |
| Kickstart git repo conflict | Existing `~/.config/nvim/.git` with non-kickstart remote | Remote URL mismatch check | Back up existing config with timestamp; clone fresh kickstart | User can restore from backup if needed |
| Existing custom directory | Non-symlink `~/.config/nvim/lua/custom` directory exists | Directory exists and is not a symlink | Back up existing directory with timestamp; create symlink | Previous custom configs preserved in backup |
| Symlink already correct | Symlink points to expected target | Symlink exists and resolves to correct target | Remove and recreate (or skip if identical) | No action needed |
| Poetry lint invocation failure | ruff invocation via Poetry wrapper fails at runtime | Error is caught gracefully | Silently log at DEBUG level | Falls through gracefully; next lint cycle retries |
| eslint_d / prettier condition false | No config file found | No matching configuration file is found in the buffer's path ancestors | Formatter skipped for this buffer | No formatting applied; LSP fallback may activate |
| Format timeout exceeds threshold | Formatting operation exceeds FORMAT_TIMEOUT_MS | Formatter returns unformatted buffer with no error displayed | No error shown; buffer remains unformatted | User can retry with manual format command |
| Missing ruff binary | ruff linter not installed as Mason package or system binary | Error caught during lint invocation | Logged at DEBUG level | User installs ruff via Mason to resolve |
| Neotest eager load | Module evaluation loads neotest before filetype trigger | Potential increase in Neovim startup time | No data loss; neotest functions normally once loaded | No action needed; restructure lazy-load triggers if startup impact is significant |
| Go not installed when golang_full runs | `command -v go` fails | Shell command check | Skip Mason Go tool installation; print guidance message | User installs Go first, then runs Mason install command manually |

---

## Implementation Notes

1. **Symlink integrity**: The custom layer uses a directory-level symlink (`~/dotfiles/nvim/custom` → `~/.config/nvim/lua/custom`). Individual plugin files must NOT be symlinked separately; the entire directory is one unit.
2. **Kickstart immutability**: Never modify files inside `~/.config/nvim/` except for the custom plugin import line (which must be uncommented). All user configuration goes through `~/dotfiles/nvim/custom/`.
3. **Nerd Font independence**: neo-tree uses ASCII characters for folder and git status icons to ensure full functionality over SSH connections without Nerd Font support.
4. **Formatter conditions**: prettier and eslint_d are opt-in per project. They activate only when their respective configuration files exist. This prevents reformatting projects that don't use these tools.
5. **Poetry-aware Python linting**: The ruff linter's invocation is determined once at config load time based on whether the initial working directory is a Poetry project. All buffers subsequently use the same invocation, providing virtual environment awareness without manual configuration.
6. **Indent statusline composition with truncation**: The indent indicator is injected into the existing mini.statusline flow by overriding the active function. The override preserves all original sections and their configurable truncation widths (see STATUSLINE_*_WIDTH parameters), inserting the indent indicator in the right-aligned group.
7. **Idempotent installation**: All install operations (symlink creation, kickstart cloning, Mason installation, plugin sync) are safe to re-run. Existing correct state is preserved; conflicts are backed up with timestamps.
8. **Cache hygiene**: Dirty plugin cache entries (uncommitted changes in lazy.nvim plugin git repos) are cleaned before retrying a failed sync. Fresh installations clear the entire nvim data directory; updates preserve it but clear the cache directory.
9. **Platform-aware Neovim install**: On Linux, Neovim is installed as an AppImage (with architecture detection for x86_64 and arm64). On macOS, Neovim is installed/upgraded via Homebrew. If an old apt-installed Neovim exists on Linux, it is removed first.

---

## Test Scenarios

TS-NVIM-001: Custom layer symlink creation
Category: Integration
Priority: Critical
Preconditions: Kickstart cloned at ~/.config/nvim; ~/dotfiles/nvim/custom/plugins/ contains plugin files
Input: install.sh runs configure_neovim module
Expected Output: ~/.config/nvim/lua/custom is a symlink pointing to ~/dotfiles/nvim/custom; all plugin files are accessible via the symlink path

TS-NVIM-002: Custom plugin import activation
Category: Integration
Priority: Critical
Preconditions: Kickstart configuration has commented-out custom plugin import
Input: install.sh runs configure_neovim module
Expected Output: The custom plugin import line is uncommented in init.lua; Neovim loads all custom plugins on startup

TS-NVIM-003: Kickstart update preserves custom layer
Category: Integration
Priority: Critical
Preconditions: Custom layer symlink exists; kickstart git repo at ~/.config/nvim
Input: Install script performs kickstart update (fetch and hard reset to origin/master)
Expected Output: Kickstart updates to latest upstream; custom layer symlink remains intact; custom plugins load normally

TS-NVIM-004: Format on save with project prettier config
Category: Integration
Priority: High
Preconditions: A JS/TS file in a project with .prettierrc
Input: Buffer write on a JS file in that project
Expected Output: Prettier formats the file on save with 2000ms timeout; if prettier fails, LSP fallback activates

TS-NVIM-005: Format on save without project prettier config
Category: Integration
Priority: High
Preconditions: A JS/TS file in a project without any prettier config file
Input: Buffer write on a JS file in that project
Expected Output: Prettier is skipped; only eslint_d runs if an eslint config exists; otherwise LSP fallback applies

TS-NVIM-006: Python linting with Poetry project
Category: Integration
Priority: High
Preconditions: Neovim starts in a directory with pyproject.toml containing [tool.poetry] section
Input: BufWritePost event triggers
Expected Output: ruff is invoked through Poetry's virtual environment wrapper for all Python buffers

TS-NVIM-007: Python linting without Poetry
Category: Integration
Priority: High
Preconditions: Neovim starts in a directory without Poetry config
Input: BufWritePost event triggers
Expected Output: ruff is invoked directly without Poetry wrapper for all Python buffers

TS-NVIM-008: Go debug test keybinding
Category: Unit
Priority: High
Preconditions: Go file open; nvim-dap-go loaded
Input: `<leader>dt` pressed on a Go test function
Expected Output: Debug test starts with delve adapter; breakpoint set at test function entry

TS-NVIM-009: Diffview open and close
Category: Unit
Priority: Medium
Preconditions: Git repository with changes
Input: `<leader>dv` then `<leader>dc`
Expected Output: Diffview opens with horizontal two-pane layout and tree-style file panel; closing removes diffview tab

TS-NVIM-010: Neo-tree file reveal
Category: Unit
Priority: Medium
Preconditions: A file open in buffer
Input: `\` key pressed
Expected Output: Neo-tree sidebar opens with the current file highlighted; dotfiles and gitignored files are visible

TS-NVIM-011: Neo-tree last window close
Category: Unit
Priority: Medium
Preconditions: Neo-tree is the only open window
Input: Close all other windows
Expected Output: Neo-tree closes automatically

TS-NVIM-012: Indent statusline indicator for spaces
Category: Visual
Priority: Low
Preconditions: File with expandtab=true and shiftwidth=2
Input: Buffer displayed in Neovim
Expected Output: Statusline shows "·2" in the right-aligned fileinfo section

TS-NVIM-013: Indent statusline indicator for tabs
Category: Visual
Priority: Low
Preconditions: File with expandtab=false and tabstop=4
Input: Buffer displayed in Neovim
Expected Output: Statusline shows "→4" in the right-aligned fileinfo section

TS-NVIM-014: Markdown rendering loads only for markdown filetype
Category: Unit
Priority: Medium
Preconditions: Neovim startup complete
Input: Open a .lua file, then open a .md file
Expected Output: render-markdown.nvim is NOT loaded for the .lua file; IS loaded for the .md file

TS-NVIM-015: Dirty plugin cache recovery
Category: End-to-End
Priority: High
Preconditions: A lazy.nvim plugin directory has uncommitted local changes
Input: install.sh runs plugin sync
Expected Output: Dirty directories are cleaned; sync retries once; plugins install successfully

TS-NVIM-016: Fresh installation cleans cache
Category: End-to-End
Priority: High
Preconditions: No ~/.local/share/nvim/lazy directory exists (fresh install)
Input: install.sh runs configure_neovim module
Expected Output: ~/.local/share/nvim, ~/.local/state/nvim, and ~/.cache/nvim are all removed before first launch; plugins install cleanly

TS-NVIM-017: Existing config backed up on conflict
Category: Integration
Priority: Critical
Preconditions: ~/.config/nvim exists as a non-kickstart git repo or plain directory
Input: install.sh runs configure_neovim module
Expected Output: Existing config moved to ~/.config/nvim.backup.{timestamp}; fresh kickstart cloned; custom layer symlinked

TS-NVIM-018: Neogit opens with diffview integration
Category: Integration
Priority: Medium
Preconditions: Git repository; diffview.nvim and neogit.nvim loaded
Input: `<leader>gg` opens neogit; user initiates a diff action
Expected Output: Diff view opens in diffview with horizontal layout

TS-NVIM-019: Mason Go tools conditional install
Category: Integration
Priority: High
Preconditions: Go 1.24+ installed; Neovim installed
Input: golang_full module of install.sh
Expected Output: Mason installs gopls, delve, gofumpt, goimports; prints success message

TS-NVIM-020: Mason Go tools skipped without Neovim
Category: Integration
Priority: Medium
Preconditions: Go installed; Neovim NOT installed
Input: golang_full module of install.sh
Expected Output: Mason Go tools installation is skipped; guidance message printed with manual command

TS-NVIM-021: Deprecated treesitter module fixed
Category: Unit
Priority: Medium
Preconditions: Kickstart configuration contains a deprecated treesitter configuration API reference
Input: install.sh runs configure_neovim module
Expected Output: The treesitter configuration reference is updated to the current module

TS-NVIM-022: Manual format keybinding
Category: Unit
Priority: Medium
Preconditions: conform.nvim loaded; file open in buffer
Input: `<leader>f` pressed
Expected Output: Async format with LSP fallback triggered for current buffer

TS-NVIM-023: Manual lint keybinding
Category: Unit
Priority: Medium
Preconditions: nvim-lint loaded; Python file open in buffer
Input: `<leader>l` pressed
Expected Output: Manual lint check triggered for current buffer

TS-NVIM-024: Existing correct symlink skipped
Category: Integration
Priority: Medium
Preconditions: ~/.config/nvim/lua/custom already points to ~/dotfiles/nvim/custom
Input: install.sh runs configure_neovim module
Expected Output: Symlink is recreated (idempotent); no backup created; no error

---

## Changelog

| Version | Date | Summary |
|---------|------|---------|
| 1.0.0 | 2026-05-01 | Initial specification extracted from neovim custom plugins, install.sh neovim configuration, and parameters |
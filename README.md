# Dotfiles

Personal development environment for tmux, Neovim, Zsh, and three coding-agent harnesses. The installer supports Ubuntu/Debian and macOS while keeping mutable credentials, histories, sessions, and machine-specific settings outside Git.

## Install

```bash
git clone https://github.com/mtomcal/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The interactive installer offers three profiles:

| Profile | Purpose |
|---------|---------|
| `full` | Complete development environment, including Go, Node.js, TUI tools, Codex, Claude Code, Playwright, and Copilot |
| `minimal` | Neovim and tmux with their managed configuration |
| `work` | Neovim, tmux, Python, TUI tools, and Copilot |

On macOS, the `full` and `work` profiles also install and configure Visual Studio Code Desktop. The browser-based code-server target is Ubuntu/Debian-only and must be selected explicitly.

Profiles and individual modules can also be selected non-interactively:

```bash
./install.sh --profile full
./install.sh --profile minimal
./install.sh --profile work
./install.sh --modules neovim,nvim_config,tmux_config
./install.sh --modules golang_full,neovim,nvim_config
./install.sh --modules code_server --code-server-bind 127.0.0.1:8080
./install.sh --help
```

The installer resolves missing prerequisites, reports each module independently, and is designed to be rerun. Agent authentication, generated secrets, editor runtime state, and other mutable tool data remain local.

After installation, restart the shell:

```bash
exec zsh
```

## Tmux

Tmux is the default terminal multiplexer. SSH shells automatically attach to or create the stable `main` session:

```bash
tmux new-session -A -s main
```

Set `DOTFILES_TMUX_AUTO_ATTACH=0` before starting the shell to opt out on a particular host. Local shells and shells already inside tmux do not auto-attach.

The prefix is `Ctrl-a`.

### Sessions and windows

| Command or key | Action |
|----------------|--------|
| `tn work` | Create session `work` |
| `ta work` | Attach to session `work` |
| `tl` | List sessions |
| `tk work` | Kill session `work` |
| `td` / `Ctrl-a d` | Detach |
| `Ctrl-a c` | Create an adjacent window in the current directory |
| `Ctrl-a Ctrl-h` / `Ctrl-a Ctrl-l` | Select previous/next window |
| `Ctrl-a <` / `Ctrl-a >` | Move the current window left/right |
| `Ctrl-a r` | Reload `~/.tmux.conf` |

### Panes

| Key | Action |
|-----|--------|
| `Ctrl-a \|` | Split horizontally in the current directory |
| `Ctrl-a -` | Split vertically in the current directory |
| `Ctrl-a h/j/k/l` | Navigate panes |
| `Ctrl-a H/J/K/L` | Resize panes |
| `Ctrl-a M` | Merge panes into the previous window |
| `Ctrl-a B` | Break the current pane into a new window |
| `Ctrl-a E` | Break every pane into its own window |
| `Ctrl-a V` | Arrange panes as equal columns |
| `Ctrl-a R` | Reverse pane order |

### Copy mode and nesting

Copy mode uses Vim keys. `Ctrl-a [` enters copy mode, `v` begins selection, and `y` copies through the configured tmux buffer/clipboard command. Tmux also enables clipboard passthrough for terminals that support it.

Nested tmux remains supported:

| Key | Action |
|-----|--------|
| `F12` | Toggle control between outer and inner sessions; the outer status bar dims while disabled |
| `Ctrl-a Ctrl-a` | Send the prefix to an inner session |

The tracked source is [`tmux/.tmux.conf`](tmux/.tmux.conf).

## Neovim

The installer maintains an official kickstart.nvim checkout at `~/.config/nvim` and links `nvim/custom` into `~/.config/nvim/lua/custom`. Repository-owned plugin modules use `vim.pack` and are loaded by `nvim/custom/plugins/init.lua`.

The custom layer currently owns:

- Explicit-yank clipboard behavior and persistent yank history.
- Formatting through conform.nvim.
- Python Pyright and Ruff integration.
- Go debugging and neotest integration.
- Neo-tree, Diffview, Neogit, and rendered Markdown.
- Indentation detection and statusline indentation display.

### Repository-owned keybindings

| Key | Action |
|-----|--------|
| `\` | Reveal the current file in Neo-tree |
| `gp` / `gP` | Paste the last explicit yank from register `0` |
| `<leader>pr` | Show registers |
| `<leader>py` | Browse yank history with Telescope |
| `<leader>f` | Format the current buffer or selection |
| `<leader>l` | Run Python linting manually |
| `<leader>gg` | Open Neogit |
| `<leader>gc` | Open Neogit commit |
| `<leader>gp` / `<leader>gP` | Pull/push through Neogit |
| `<leader>dv` | Open Diffview |
| `<leader>dh` / `<leader>df` | Current/all-file Git history |

Go-specific bindings:

| Key | Action |
|-----|--------|
| `<leader>dt` | Debug nearest test |
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Continue debugging |
| `<leader>tn` | Run nearest test |
| `<leader>tf` | Run tests in the current file |
| `<leader>to` | Open test output |
| `<leader>ts` | Toggle test summary |

To add a plugin, create a self-contained module under `nvim/custom/plugins`:

```lua
vim.pack.add({
  { src = 'https://github.com/author/plugin-name' },
})

require('plugin-name').setup({})
```

See [`nvim/custom/README.md`](nvim/custom/README.md) for the loader contract.

## Zsh and terminal tools

The custom Zsh layer sets Neovim as `$EDITOR`, keeps user-local agent commands early in `$PATH`, initializes fnm and zoxide when installed, and exposes these shortcuts:

| Alias | Command |
|-------|---------|
| `vim`, `vi` | `nvim` |
| `t` | `tmux` |
| `ta`, `tn`, `tl`, `tk`, `td` | Common tmux session operations |
| `lg` | `lazygit` |
| `y` | `yazi` |
| `cx` | `codex` |
| `cop` | `copilot` |

Repository-owned Yazi jumps are:

| Key | Destination |
|-----|-------------|
| `g h` | Home directory |
| `g d` | `~/dotfiles` |
| `g p` | `~/projects` |
| `g t` | `/tmp` |

Lazygit uses Neovim as its editor and enables automatic fetch/refresh. The tracked configurations live under `zsh/`, `lazygit/`, and `yazi/`.

## Coding-agent harnesses

The supported harnesses are Codex CLI, Claude Code, and GitHub Copilot CLI.

```bash
codex login
claude auth login
copilot login
```

Runtime credentials, histories, conversations, and generated settings are not stored in this repository. Codex configuration is documented in [`codex/README.md`](codex/README.md); Claude Code configuration is documented in [`claude/README.md`](claude/README.md).

### Harness-specific skills

Skills are intentionally separated by harness because different models benefit from different information and instruction styles:

| Repository source | Runtime exposure |
|-------------------|------------------|
| `skills/claude` | `~/.claude/skills` |
| `skills/codex` | `~/.agents/skills` and individual links under `~/.codex/skills` |
| `skills/copilot` | `~/.config/copilot/skills` |

Codex’s sync helper preserves its built-in `.system` skills while reconciling repository-owned links. Each catalog starts empty. Add a skill only when model-native capability lacks required material or when a repeatable tool contract needs durable instructions.

## Managed editor targets

The repository owns a shared VS Code settings, keybindings, snippets, and extension layer under `vscode/`.

- Visual Studio Code Desktop is supported on macOS and participates in the `full` and `work` profiles.
- code-server is supported on Ubuntu/Debian as an explicit module.
- Machine-specific endpoint configuration, generated credentials, extension state, and service state remain local.
- Settings Sync for managed Desktop settings and extensions must remain disabled manually so the repository stays authoritative.

The capture helper at `vscode/capture.sh` can import an existing target configuration into the managed layer for review. It is never invoked during normal installation.

## Testing

Run the shell suite from the repository root:

```bash
bash tests/run.sh
```

The runner:

- Checks shell syntax.
- Applies a static Bash 3.2 compatibility guard for macOS.
- Discovers and runs `tests/*.test.sh` in sorted order.
- Cleans suite-owned temporary state after success or failure.

Installer changes still require proportional real-platform and idempotency validation; the static compatibility guard does not prove runtime behavior on macOS Bash 3.2.

## Updating and customization

Update the repository and converge the selected environment again:

```bash
cd ~/dotfiles
git pull
./install.sh
```

Common configuration sources:

| Area | Source |
|------|--------|
| Tmux | `tmux/.tmux.conf` |
| Zsh | `zsh/.zshrc.custom` |
| Neovim | `nvim/custom/plugins/` |
| Lazygit | `lazygit/config.yml` |
| Yazi | `yazi/` |
| Codex template | `codex/config.toml` |
| Claude status line | `claude/statusline.sh` |
| VS Code layer | `vscode/` |

Reload tmux with `Ctrl-a r` and Zsh with `source ~/.zshrc`. Neovim installs `vim.pack` additions when its custom modules load.

## Requirements

- Ubuntu/Debian with `apt`, or macOS with Homebrew support.
- Internet access for tool and package installation.
- `sudo` access where system packages or `/usr/local` installations require it.

Run `./install.sh --help` for the current module catalog, platform restrictions, and command-line options.

## License

MIT

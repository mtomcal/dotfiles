# Quick Reference Guide

Quick-start cheat sheets for every tool in this dotfiles setup. For detailed configuration, see the main [README](../README.md).

---

## Tmux

**Prefix**: `Ctrl-a` (not the default `Ctrl-b`)

### Session Management

| Command | Action |
|---------|--------|
| `tn work` | New session named "work" |
| `ta work` | Attach to session "work" |
| `tl` | List all sessions |
| `tk work` | Kill session "work" |
| `td` | Detach from current session |
| `Ctrl-a d` | Detach (inside tmux) |

### Windows & Panes

| Key | Action |
|-----|--------|
| `Ctrl-a c` | New window (adjacent to current) |
| `Ctrl-a \|` | Split vertically |
| `Ctrl-a -` | Split horizontally |
| `Ctrl-a h/j/k/l` | Navigate panes (vim-style) |
| `Ctrl-a H/J/K/L` | Resize panes |
| `Ctrl-a Ctrl-h` | Previous window |
| `Ctrl-a Ctrl-l` | Next window |
| `Ctrl-a r` | Reload config |

### Copy Mode

| Key | Action |
|-----|--------|
| `Ctrl-a [` | Enter copy mode |
| `v` | Start selection (in copy mode) |
| `y` | Yank selection to clipboard |
| `q` | Exit copy mode |

### Nested Sessions (F12)

For running tmux inside tmux (e.g., SSH or orchestration):

| Key | Action |
|-----|--------|
| `F12` | Toggle control to inner session (status bar dims) |
| `F12` again | Toggle back to outer session |
| `Ctrl-a Ctrl-a <key>` | Send command to inner session directly |

---

## Neovim

Built on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) with a custom plugin layer.

### General Navigation

| Key | Action |
|-----|--------|
| `\` | Toggle file explorer (neo-tree) |
| `<leader>sf` | Search files (Telescope) |
| `<leader>sg` | Search by grep (Telescope) |
| `<leader>sb` | Search buffers |
| `<leader>sh` | Search help tags |
| `<leader>sd` | Search diagnostics |
| `K` | Hover documentation |

### LSP (all languages)

| Key | Action |
|-----|--------|
| `grd` | Go to definition |
| `grr` | Go to references |
| `gri` | Go to implementation |
| `grt` | Go to type definition |
| `grn` | Rename symbol |
| `gra` | Code action |
| `<leader>f` | Format buffer |

### Git (inside Neovim)

**Neogit** (interactive git):

| Key | Action |
|-----|--------|
| `<leader>gg` | Open Neogit status |
| `<leader>gc` | Git commit |
| `<leader>gp` | Git pull |
| `<leader>gP` | Git push |

**Diffview** (code review):

| Key | Action |
|-----|--------|
| `<leader>dv` | Open diff view (unstaged changes) |
| `<leader>dc` | Close diff view |
| `<leader>dh` | File history (current file) |
| `<leader>df` | File history (all files) |

### Go Development

| Key | Action |
|-----|--------|
| `<leader>dt` | Debug nearest test |
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Continue debugger |
| `<leader>tn` | Run nearest test |
| `<leader>tf` | Run all tests in file |
| `<leader>to` | Show test output |
| `<leader>ts` | Toggle test summary |

### Python Development

| Key | Action |
|-----|--------|
| `<leader>f` | Format with Ruff |
| `<leader>l` | Trigger linting |
| `<leader>th` | Toggle inlay type hints |

Auto-formats on save. Auto-detects Poetry projects. See [PYTHON_DEVELOPMENT.md](PYTHON_DEVELOPMENT.md) for full details.

---

## Lazygit

Launch: `lg` (alias) or `lazygit`

### Navigation

| Key | Action |
|-----|--------|
| `1-5` | Switch panels (status, files, branches, commits, stash) |
| `h/l` | Cycle panels left/right |
| `j/k` | Move up/down in panel |
| `Enter` | Focus/expand item |
| `q` | Quit |
| `?` | Show all keybindings |

### Common Operations

| Key | Panel | Action |
|-----|-------|--------|
| `Space` | Files | Stage/unstage file |
| `a` | Files | Stage/unstage all |
| `c` | Files | Commit staged changes |
| `P` | Files | Push |
| `p` | Files | Pull |
| `e` | Files | Edit file in neovim |
| `Space` | Branches | Checkout branch |
| `n` | Branches | New branch |
| `M` | Branches | Merge into current |
| `r` | Branches | Rebase onto current |
| `z` | Any | Undo last action |

### Workflow Example

```
lg                    # Launch lazygit
Space (on files)      # Stage files
c                     # Open commit message editor
:wq                   # Save commit message
P                     # Push to remote
q                     # Quit
```

---

## Yazi (File Manager)

Launch: `y` (alias) or `yazi`

### Navigation

| Key | Action |
|-----|--------|
| `h` | Go to parent directory |
| `l` or `Enter` | Open file / enter directory |
| `j/k` | Move down/up |
| `G` | Jump to bottom |
| `g g` | Jump to top |
| `/` | Search in current directory |
| `z` | Fuzzy jump with zoxide |
| `Z` | Fuzzy jump with fzf |

### Quick Directory Jumps (custom)

| Key | Action |
|-----|--------|
| `g h` | Go to `~` (home) |
| `g d` | Go to `~/dotfiles` |
| `g p` | Go to `~/projects` |
| `g t` | Go to `/tmp` |

### File Operations

| Key | Action |
|-----|--------|
| `y` | Yank (copy) |
| `x` | Cut (mark for move) |
| `p` | Paste (complete copy/move) |
| `d` | Delete (trash) |
| `D` | Permanent delete |
| `r` | Rename |
| `a` | Create new file |
| `A` | Create new directory |
| `.` | Toggle hidden files |
| `e` | Edit in neovim |

### Selection

| Key | Action |
|-----|--------|
| `Space` | Toggle select current file |
| `v` | Enter visual mode (select range) |
| `V` | Select all in directory |
| `Esc` | Clear selection |

### Workflow: Move Files

```
j/k          # Navigate to file
x            # Cut (mark for move)
h/l          # Navigate to destination directory
p            # Paste (completes the move)
```

### Workflow: Bulk Operations

```
v            # Enter visual mode
j/k          # Select range of files
y            # Yank all selected (or x to cut)
# navigate to destination
p            # Paste
```

---

## Zoxide (Smart cd)

Zoxide learns your most-visited directories and lets you jump to them with partial matches.

### Shell Usage

| Command | Action |
|---------|--------|
| `z foo` | Jump to highest-ranked directory matching "foo" |
| `z foo bar` | Jump to directory matching both "foo" and "bar" |
| `z ~/projects` | Works like regular `cd` for full paths |
| `zi` | Interactive selection with fzf |
| `zoxide query -ls` | Show all tracked directories with scores |

### Inside Yazi

Press `z` to open zoxide fuzzy finder within yazi.

### How It Works

- Every time you `cd` into a directory, zoxide records it
- Directories get a "score" based on frequency and recency
- `z` fuzzy-matches your query against scored directories
- The more you visit a directory, the higher it ranks

### Examples

```bash
z dot          # Jumps to ~/dotfiles (if visited before)
z proj         # Jumps to ~/projects
z src comp     # Jumps to best match containing both "src" and "comp"
```

---

## Zsh Aliases

| Alias | Expands To |
|-------|------------|
| `vim`, `vi` | `nvim` |
| `lg` | `lazygit` |
| `y` | `yazi` |
| `t` | `tmux` |
| `ta <name>` | `tmux attach -t <name>` |
| `tn <name>` | `tmux new -s <name>` |
| `tl` | `tmux ls` |
| `tk <name>` | `tmux kill-session -t <name>` |
| `td` | `tmux detach` |
| `oc` | `opencode` |
| `cx` | `codex` |

---

## AI Coding Assistants

### Claude Code

```bash
claude                # Start interactive session
claude auth login     # Authenticate
```

Commands: `/ralph` (agentic loop job runner)

### OpenCode CLI

```bash
opencode              # Start TUI session (alias: oc)
opencode auth login   # Authenticate
```

Features: Plan/Build mode switching, multi-model support.

### Codex CLI

```bash
codex                 # Start session (alias: cx)
codex login           # Authenticate
```

### Ralph (Agentic Loop Runner)

Available in Claude Code (`/ralph`) and OpenCode (`/ralph`). Sets up:
1. `PROMPT.md` — worker task instructions
2. `IMPLEMENTATION_PLAN.md` — detailed plan with progress tracking
3. `ORCHESTRATOR.md` — monitoring playbook

```bash
./loop.sh 25 PROMPT.md            # Run 25 iterations
SANDBOX=1 ./loop.sh 25 PROMPT.md  # Run in Docker sandbox
```

---

## Node.js (fnm)

| Command | Action |
|---------|--------|
| `fnm list` | List installed versions |
| `fnm install --lts` | Install latest LTS |
| `fnm install 20` | Install specific version |
| `fnm use 20` | Switch to version |
| `fnm default 20` | Set default version |

Auto-switches versions when entering directories with `.node-version` or `.nvmrc`.

---

## Installation Cheat Sheet

```bash
# Full setup
./install.sh --profile full

# Editors only
./install.sh --profile minimal

# Work machines
./install.sh --profile work

# Pick specific modules
./install.sh --modules neovim,nvim_config,tui_tools

# See all options
./install.sh --help
```

Available modules: `base_tools`, `neovim`, `nvim_config`, `tmux_config`, `zsh_ohmyzsh`, `zsh_config`, `golang`, `golang_full`, `nodejs`, `tui_tools`, `codex`, `claude`, `opencode`, `playwright`

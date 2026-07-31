# Design Language

> **Version**: 0.3.0
> **Last Updated**: 2026-07-31
> **Purpose**: Shared interface vocabulary and visual tokens for all user-facing specs. Read this before authoring any UI, CLI, or config spec.

---

## Interface Vocabulary

### CLI (install.sh)

> **Pseudocode convention**: Specs SHOULD use these token names in their Behavioral pseudocode, e.g., "Output success-msg: 'Symlink created'" rather than "Print 'Symlink created'". This ensures implementation fidelity between spec intent and actual CLI output formatting.

| Element | Definition | When to use | When NOT to use |
|---------|-----------|-------------|-----------------|
| **Status message** | A line of output indicating what the script is currently doing | During each major phase of install (OS detection, dependency install, symlink creation, etc.) | For detailed debug information — use verbose mode |
| **Prompt** | An interactive question that blocks script execution until answered | When user input is required (git config, optional features) | When a sensible default exists and the user hasn't requested interactivity |
| **Warning** | A highlighted message indicating a non-fatal issue | When an existing config was backed up, or a tool is already installed | For fatal errors — those should halt execution |
| **Error** | A message indicating a fatal problem, followed by script exit (set -e) | When a required dependency fails to install or a critical file is missing | For recoverable situations — use warnings instead |
| **Phase header** | A formatted section marker indicating the start of a major install phase | At the beginning of each major section of install.sh | For sub-steps within a phase — use status messages |
| **Backup notice** | A message indicating an existing file was moved to a timestamped copy | When deploy encounters a non-symlink file at the target path | When the target path is already a symlink — silent skip is preferred |

### Config UI (Terminal Multiplexers)

| Element | Definition | When to use | When NOT to use |
|---------|-----------|-------------|-----------------|
| **Prefix command** | A key sequence starting with a multiplexer prefix key (Ctrl-a in this dotfiles environment) | Herdr and tmux operations such as pane management, tab/window management, resizing, copy mode | Direct keybindings (no prefix) |
| **Vim-style navigation** | h/j/k/l for pane movement, H/J/K/L or Herdr equivalents for resize/swap | Pane navigation and resize operations | When vim-style would conflict with running applications |
| **Toggle indicator** | Visual change in a multiplexer UI indicating a mode change | Persistent mode changes such as tmux F12 inner/outer control | For transient notifications |

### Config UI (Neovim)

| Element | Definition | When to use | When NOT to use |
|---------|-----------|-------------|-----------------|
| **Leader command** | A key sequence starting with the Neovim leader key (Space) | Most custom operations: git, format, debug, test | Mappings that start with g, z, or other built-in prefixes |
| **Which-key menu** | A popup showing available keybindings after a partial prefix | After pressing the leader key or other prefix | For single-key direct mappings that need no discovery |
| **Statusline component** | An indicator in the mini.statusline showing mode, indent, or git status | Persistent information that aids navigation without being intrusive | Ephemeral information that changes too rapidly to be useful |

### Config UI (VS Code)

| Element | Definition | When to use | When NOT to use |
|---------|-----------|-------------|-----------------|
| **VS Code command** | An editor action identified by a stable command identity and invoked from a keybinding or command interface | Managed format, diagnostics, file, Git, test, and debug actions | For shell commands or extension identities |
| **Vim leader command (VS Code)** | A VSCodeVim normal-mode sequence beginning with Space | Modal equivalents of managed editor actions | When a native browser/editor shortcut must retain precedence |
| **shortcut exception** | A key intentionally excluded from VSCodeVim handling so the browser or editor receives it | Native shortcuts required for editor, browser, or accessibility behavior | As an undocumented workaround for accidental mapping conflicts |
| **manual action notice** | A completion message identifying a required UI action the installer cannot enforce through a supported interface | Disabling official Visual Studio Code Settings Sync | For behavior the installer can enforce and verify directly |
| **private endpoint notice** | A completion message identifying the local endpoint configuration location and trust boundary without printing secrets | code-server bind, certificate, and password discovery guidance | To print passwords, private hostnames, or network-product details |

---

## Visual Tokens

### CLI Output Formatting

| Token | Value | Usage |
|-------|-------|-------|
| `phase-header-fmt` | `echo -e "\n== {text} =="` | Major phase boundaries in install.sh |
| `success-msg` | `echo "✓ {text}"` | Successful completion of a step |
| `warning-msg` | `echo "⚠ {text}"` | Non-fatal issues (backups, skips) |
| `error-msg` | `echo "✗ {text}" >&2` | Fatal errors that halt the script |
| `prompt-fmt` | `read -p "{text}"` | Interactive user input |

### Multiplexer Visual Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `multiplexer-prefix-key` | Ctrl-a | Herdr and tmux command sequences |
| `tmux-prefix-indicator` | Status line prefix display | Shows active tmux prefix state |
| `tmux-nested-dim` | Darker status bar background | Visual indicator when F12 toggles tmux to inner session |
| `herdr-workspace` | Workspace label/list item | Herdr top-level repo/task/investigation unit |

### Indentation Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `indent-spaces` | Detected by vim-sleuth (fallback) | Default indentation when no .editorconfig present |
| `editorconfig` | Project .editorconfig settings | Takes precedence over heuristics |

### VS Code Interaction Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `vscode-vim-leader` | Space | Shared VSCodeVim leader commands |
| `code-server-default-bind` | 0.0.0.0:8080 | First-install private-network browser endpoint |
| `settings-sync-action` | Manual disablement required | Supported limitation notice for official desktop Visual Studio Code |

---

## Naming Conventions

| Context | Convention | Example |
|---------|-----------|---------|
| Symlink source files | Kebab-case or dot-prefixed as they appear on disk | `.tmux.conf`, `.zshrc.custom`, `config.yml` |
| Neovim plugin files | Kebab-case Lua modules | `go.lua`, `neo-tree.lua`, `formatting.lua` |
| Spec file names | Kebab-case | `symlink-manager.md`, `tool-provisioning.md` |
| Test scenario prefixes | TS-{PREFIX}-{NUMBER} | `TS-SYMLK-001`, `TS-TMUX-012` |
| Zsh aliases | Short lowercase abbreviations | `lg`, `y`, `z`, `ta`, `tn`, `h`, `ha` |
| Tmux keybindings | Mnemonic single keys after prefix | `c` (create window), `|` (split vertical), `-` (split horizontal) |
| Herdr keybindings | Herdr action names with prefix-compatible bindings | `new_tab = "prefix+c"`, `split_horizontal = "prefix+minus"` |
| VS Code extension manifests | Target-qualified lowercase filenames | `shared.txt`, `desktop.txt`, `code-server.txt` |
| VS Code managed settings | Upstream conventional filenames | `settings.json`, `keybindings.json` |

---

## Changelog

| Version | Date | Summary |
|---------|------|---------|
| 0.3.0 | 2026-07-31 | Added VS Code command, Vim leader, shortcut exception, manual action, private endpoint, interaction token, and naming vocabulary. |
| 0.2.0 | 2026-07-05 | Established CLI, multiplexer, and Neovim interface vocabulary and visual tokens. |

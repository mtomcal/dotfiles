# Design Language

> **Version**: 0.1.0
> **Last Updated**: 2026-05-01
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

### Config UI (Tmux Keybindings)

| Element | Definition | When to use | When NOT to use |
|---------|-----------|-------------|-----------------|
| **Prefix command** | A key sequence starting with the tmux prefix key (Ctrl-a) | All tmux operations — pane management, window management, resizing | Direct keybindings (no prefix) — only for rarely-used operations |
| **Vim-style navigation** | h/j/k/l for pane movement, H/J/K/L for resize | Pane navigation and resize operations | When vim-style would conflict with running applications |
| **Toggle indicator** | Visual change in the tmux status bar indicating a mode change | When F12 switches between inner/outer session control | For transient notifications — only persistent mode changes get indicators |

### Config UI (Neovim)

| Element | Definition | When to use | When NOT to use |
|---------|-----------|-------------|-----------------|
| **Leader command** | A key sequence starting with the Neovim leader key (Space) | Most custom operations: git, format, debug, test | Mappings that start with g, z, or other built-in prefixes |
| **Which-key menu** | A popup showing available keybindings after a partial prefix | After pressing the leader key or other prefix | For single-key direct mappings that need no discovery |
| **Statusline component** | An indicator in the mini.statusline showing mode, indent, or git status | Persistent information that aids navigation without being intrusive | Ephemeral information that changes too rapidly to be useful |

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

### Tmux Visual Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `prefix-key` | Ctrl-a | All tmux command sequences |
| `prefix-indicator` | Status line prefix display | Shows active prefix state |
| `nested-dim` | Darker status bar background | Visual indicator when F12 toggles to inner session |

### Indentation Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `indent-spaces` | Detected by vim-sleuth (fallback) | Default indentation when no .editorconfig present |
| `editorconfig` | Project .editorconfig settings | Takes precedence over heuristics |

---

## Naming Conventions

| Context | Convention | Example |
|---------|-----------|---------|
| Symlink source files | Kebab-case or dot-prefixed as they appear on disk | `.tmux.conf`, `.zshrc.custom`, `config.yml` |
| Neovim plugin files | Kebab-case Lua modules | `go.lua`, `neo-tree.lua`, `formatting.lua` |
| Spec file names | Kebab-case | `symlink-manager.md`, `tool-provisioning.md` |
| Test scenario prefixes | TS-{PREFIX}-{NUMBER} | `TS-SYMLK-001`, `TS-TMUX-012` |
| Zsh aliases | Short lowercase abbreviations | `lg`, `y`, `z`, `ta`, `tn` |
| Tmux keybindings | Mnemonic single keys after prefix | `c` (create window), `|` (split vertical), `-` (split horizontal) |
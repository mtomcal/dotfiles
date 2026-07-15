# Parameters

> **Spec Version**: 2.0.0
> **Last Updated**: 2026-07-15
> **Depends On**: None (foundational spec)
> **Depended By**: All other specs

---

## Overview

This specification is the **single source of truth** for all tuning values, configuration parameters, and thresholds in the Personal Dotfiles Manager. Every parameter MUST include a rationale explaining WHY that specific value was chosen.

Parameters serve three purposes:
1. **Consistency**: All implementations use identical values
2. **Tuning**: Values are centralized for easy adjustment
3. **Rationale**: Future implementers understand the intent behind each value

**Critical Rule**: Parameters defined here take precedence over any hardcoded values in implementation. If a conflict exists, this document is authoritative.

---

## Install Script

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| `REQUIRED_NVIM_VERSION` | 0.12 | major.minor | Minimum Neovim version that supports vim.pack plugin format and all required features in kickstart.nvim and custom plugins |
| `REQUIRED_GO_VERSION` | 1.24 | major.minor | Required by gofumpt formatter and govulncheck |
| `NODE_LTS_VERSION` | LTS | version selector | fnm installs the current LTS release for stability; AI CLI tools don't need bleeding-edge Node |
| `SHELL_NAME` | zsh | string | Chosen as primary shell for Oh My Zsh framework support and superior interactive features |
| `BACKUP_TIMESTAMP_FMT` | %Y%m%d_%H%M%S | strftime format | Timestamps on backup files must be sortable chronologically and granular to seconds to avoid collisions; underscore separates date and time for readability |
| `OH_MY_ZSH_REPO` | https://github.com/ohmyzsh/ohmyzsh.git | URL | Official upstream; not forked to avoid maintenance burden |
| `KICKSTART_NVIM_REPO` | https://github.com/nvim-lua/kickstart.nvim.git | URL | Official upstream; not forked so `git pull` stays clean |
| `FNM_INSTALL_SCRIPT` | https://fnm.vercel.app/install | URL | Official fnm install script; not available via apt/brew on all platforms |
| `SCRIPT_MODE` | set -e | bash flag | Any command failure halts the script immediately; individual module functions use `|| return 1` to convert failures into tracked module failures |
| `DOTFILES_DIR` | Resolved via `dirname` of `$BASH_SOURCE` | path | Repository root is auto-detected from the script location; never hard-coded |
| `MAX_PROFILE_CHOICE` | 4 | integer | Highest valid choice on the interactive profile menu (Full=1, Minimal=2, Work=3, Custom=4) |
| `CODEX_CONFIG_TEMPLATE_MODE` | preserve | enum: preserve, overwrite | Controls whether an existing local Codex config is kept (preserve) or replaced from the dotfiles template (overwrite); preserve avoids losing user-customized runtime values |
| `NPM_GLOBAL_PREFIX` | ~/.local | path | npm-based global installs (Codex and Pi) use this prefix so binaries land in ~/.local/bin/ and survive fnm Node version switches |
| `GO_INSTALL_PATH` | /usr/local/go | path | Official Go binary installation directory on Ubuntu/Debian; standard location for system-wide Go |
| `GO_WORKSPACE` | ~/go-workspace | path | GOPATH for Go user binaries (govulncheck, etc.); isolated from system Go install; must be on PATH alongside Go install path |
| `BACKUP_SUFFIX_SEPARATOR` | .backup. | string | Delimiter between original filename and timestamp in backup names; unambiguous and unlikely to collide with real filenames |
| `SYMLINK_FORCE_FLAG` | true | toggle | `ln -sf` flag is used to overwrite existing symlinks at the target path; ensures atomic replacement without manual removal |

## Tmux

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| `TMUX_PREFIX` | Ctrl-a | key | Screen-compatible prefix; easier to reach than default Ctrl-b; single-key for most operations after prefix |
| `TMUX_ESCAPE_TIME` | 0 | milliseconds | Zero delay required for Neovim keybinding responsiveness; any delay causes noticeable lag in modal editing |
| `TMUX_DEFAULT_TERMINAL` | tmux-256color | terminfo | Required for true color support in Neovim and terminal applications |
| `TMUX_FOCUS_EVENTS` | on | toggle | Required for Neovim autoread and autowrite features to detect focus changes |
| `NESTED_SESSION_KEY` | F12 | key | Rarely used by applications; easy to toggle; dims status bar as visual feedback |
| `TMUX_HISTORY_LIMIT` | 50000 | lines | Large scrollback for reviewing long-running process output without truncation |
| `TMUX_DISPLAY_TIME` | 4000 | milliseconds | Status messages visible long enough to read without lingering |
| `TMUX_STATUS_INTERVAL` | 5 | seconds | Clock updates every 5 seconds; balances responsiveness with performance |
| `TMUX_RESIZE_INCREMENT` | 5 | cells | Standard resize step for pane resizing; repeatable via `-r` flag |
| `TMUX_BASE_INDEX` | 1 | number | Windows and panes numbered starting from 1, which is more natural than 0 |
| `TMUX_STATUS_LEFT_LENGTH` | 20 | characters | Maximum width for session name and username in status-left; truncates long session names cleanly |
| `TMUX_STATUS_RIGHT_LENGTH` | 150 | characters | Maximum width for clock and date in status-right; generous enough for full date-time display |

## Herdr

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| `HERDR_CONFIG_SOURCE` | ~/dotfiles/herdr/config.toml | path | Single tracked Herdr config source in the dotfiles repository |
| `HERDR_CONFIG_TARGET` | ~/.config/herdr/config.toml | path | Herdr's XDG TOML config location |
| `HERDR_INSTALL_SCRIPT` | https://herdr.dev/install.sh | URL | Official direct installer; chosen over Homebrew on both Linux and macOS for one update model |
| `HERDR_UPDATE_COMMAND` | herdr update | command | Herdr's update path for direct-installer installs |
| `HERDR_PREFIX` | ctrl+a | key | Matches existing tmux muscle memory and migration parity requirements |
| `HERDR_PANE_HISTORY` | true | boolean | Pane history is acceptable as local runtime state as long as it remains out of git |
| `HERDR_ALLOW_NESTED` | false | boolean | Prevents accidental Herdr-inside-Herdr sessions; tmux remains available as fallback |
| `HERDR_RESUME_AGENTS_ON_RESTORE` | true | boolean | Enables supported agent panes to resume native sessions after Herdr restore |
| `HERDR_SCROLLBACK_LIMIT_BYTES` | 10485760 | bytes | Matches Herdr's documented 10 MiB scrollback example and provides useful process output history |
| `HERDR_TOAST_DELIVERY` | off | enum | Keeps popup notifications quiet by default |
| `HERDR_SOUND_ENABLED` | false | boolean | Avoids unexpected audio on shared or remote machines |

## Neovim

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| `NVIM_LEADER_KEY` | Space | key | Most ergonomic leader key; accessible from both hands; widely used convention |
| `FORMAT_ON_SAVE` | true | toggle | Automatic formatting on save reduces friction; can be disabled per-buffer if needed |
| `FORMAT_TIMEOUT_MS` | 2000 | milliseconds | Two-second timeout balances responsiveness against slow formatters on large files |
| `LSP_FORMAT_FALLBACK` | true | toggle | When no conform.nvim formatter is configured, fall back to LSP formatting to ensure most files still get formatted |
| `PRETTIER_PRIORITY` | higher than eslint_d | ordering | Prettier takes precedence for JS/TS formatting when both config files exist; avoids conflicting style rules |
| `MASON_TOOLS_PYTHON` | stylua, ruff, pyright, prettier, eslint_d | list | Base language support installed during Neovim configuration; includes Lua formatting, Python linting/type-checking, and JS/TS formatting and linting |
| `MASON_TOOLS_GO` | gopls, delve, gofumpt, goimports | list | Go development toolchain: language server, debugger, formatter, import manager; installed only when golang_full module is selected |
| `DIFFVIEW_LAYOUT` | diff2_horizontal | enum | Horizontal two-pane diff for default view; three-pane for merge tool |
| `DIFFVIEW_PANEL_WIDTH` | 35 | columns | File panel width balances visibility against editor space |
| `NEOTREE_HIDE_DOTFILES` | false | toggle | Dotfiles visible by default for dotfiles-centric workflow |
| `NEOTREE_HIDE_GITIGNORED` | false | toggle | Gitignored files visible by default for environment-aware navigation |
| `INDICATOR_SPACE` | · (middle dot, U+00B7) | character | Visually distinct from regular space and hyphen |
| `INDICATOR_TAB` | → (right arrow, U+2192) | character | Universally recognized directional symbol for tab indentation |
| `GO_TEST_ARGS` | -v -race -count=1 | flags | Verbose output, race detector, no test caching — strict test discipline |
| `DAP_GO_ENABLED` | true | toggle | Enables debug adapter protocol integration for Go test debugging |
| `NEOGIT_GRAPH_STYLE` | unicode | enum | Unicode branch graph for visual clarity in git log |

## Shell

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| `ZSH_CUSTOM_FILE` | ~/dotfiles/zsh/.zshrc.custom | path | Separate file keeps custom settings independent of Oh My Zsh updates; sourced at end of .zshrc via conditional guard |
| `ZSH_ALIAS_LAZYGIT` | lg | string | Two-char alias for most frequently used git UI |
| `ZSH_ALIAS_YAZI` | y | string | Single-char alias for file manager; yazi starts fast enough for single-char |
| `ZSH_ALIAS_ZOXIDE` | z | string | Single-char alias matching zoxide's natural invocation pattern |
| `ZSH_ALIAS_TMUX` | t | string | Universal tmux launcher shortcut |
| `ZSH_ALIAS_TMUX_ATTACH` | ta | string | Mnemonic: tmux attach |
| `ZSH_ALIAS_TMUX_NEW` | tn | string | Mnemonic: tmux new |
| `ZSH_ALIAS_TMUX_LIST` | tl | string | Mnemonic: tmux list |
| `ZSH_ALIAS_TMUX_KILL` | tk | string | Mnemonic: tmux kill |
| `ZSH_ALIAS_TMUX_DETACH` | td | string | Mnemonic: tmux detach |
| `ZSH_ALIAS_HERDR` | h | string | Herdr-specific launcher that does not steal tmux's existing `t` alias |
| `ZSH_ALIAS_HERDR_ATTACH` | ha | string | Mnemonic: Herdr attach |
| `ZSH_ALIAS_HERDR_LIST` | hl | string | Mnemonic: Herdr list |
| `ZSH_ALIAS_HERDR_UPDATE` | hu | string | Mnemonic: Herdr update |
| `ZSH_ALIAS_VIM` | nvim | string | Muscle-memory redirect; all vim invocations launch neovim |
| `ZSH_ALIAS_VI` | nvim | string | Same redirect for the shorter invocation |
| `ZSH_ALIAS_CODEX` | cx | string | Two-char alias for Codex CLI |
| `ZSH_ALIAS_COPILOT` | cop | string | Short alias for Copilot CLI |
| `EDITOR` | nvim | string | Ensures all tools respecting EDITOR use neovim |
| `VISUAL` | nvim | string | Ensures all tools respecting VISUAL use neovim |
| `GOPATH` | ~/go-workspace | path | Isolated from system Go; user owns the entire workspace |
| `FNM_PATH` | ~/.local/share/fnm | path | Default fnm installation directory; used to guard fnm initialization |
| `TERM` | xterm-256color | string | Ensures 256-color support for tmux and neovim integration |
| `TMUX_AUTO_SESSION` | 0 | session name | Legacy SSH tmux fallback target session number; attaches to existing session 0 or creates one |
| `SSH_MULTIPLEXER_DEFAULT` | herdr | enum: herdr, tmux, none | SSH sessions default to Herdr as the tmux replacement path |
| `SSH_MULTIPLEXER_OVERRIDE_ENV` | DOTFILES_SSH_MULTIPLEXER | env var | Allows per-machine fallback to tmux or disabling SSH auto-attach without editing tracked shell config |

## AI Agent Configuration

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| `AGENT_INSTALL_PREFIX` | ~/.local | path prefix | Shared prefix for npm-installed agents so binaries survive fnm Node version switches; matches NPM_GLOBAL_PREFIX |
| `AGENT_CONFIG_DIR_CODEX` | ~/.codex | path | Codex CLI's canonical config directory |
| `AGENT_CONFIG_DIR_CLAUDE` | ~/.claude | path | Claude Code's canonical config directory |
| `AGENT_CONFIG_DIR_PI` | ~/.pi/agent | path | Pi's single runtime config directory |
| `AGENT_CONFIG_DIR_COPILOT` | ~/.config/copilot | path | Copilot CLI's canonical config directory (XDG-style) |
| `AGENT_SKILLS_DIR_CODEX` | ~/.agents/skills | path | Codex CLI resolves skills from this path; symlinked to shared skills |
| `AGENT_SKILLS_DIR_PI` | ~/.pi/agent/skills | path | Pi resolves skills through the single runtime config directory |
| `HERDR_SKILL_DIR` | ~/dotfiles/shared/skills/herdr | path | Tracked shared Herdr skill source available to every supported agent |
| `SANDBOX_BASE_IMAGE_NAME` | dotfiles-dev-base:{UID}-{GID} | Docker image tag | Shared sandbox base image containing common dev tools and host-matched user |
| `SANDBOX_IMAGE_NAME` | pis:latest | Docker image tag | Default Pi sandbox Docker image name |
| `CODEX_SANDBOX_IMAGE_NAME` | cods:latest | Docker image tag | Default Codex sandbox Docker image name |
| `SANDBOX_NETWORK` | sandbox-net | Docker network name | Isolated network for sandbox containers; subnet 172.30.0.0/24 |
| `SANDBOX_MEMORY_DEFAULT` | 8g | memory limit | Default Docker container memory for Pi sandbox |
| `SANDBOX_CPU_DEFAULT` | 4 | CPU limit | Default CPU cores for Pi sandbox |
| `SANDBOX_PIDS_DEFAULT` | 512 | PID limit | Default process count cap for Pi sandbox |
| `SANDBOX_HOST_USER_ARG` | `HOST_USER` | string | Docker build arg name for the host username; defaults to `mtomcal` in the Dockerfile, overridden by `pis` script at build time |
| `SANDBOX_HOST_UID_ARG` | `HOST_UID` | string | Docker build arg name for the host user UID; defaults to `1000` in the Dockerfile, overridden by `pis` script at build time |
| `SANDBOX_HOST_GID_ARG` | `HOST_GID` | string | Docker build arg name for the host user GID; defaults to `1000` in the Dockerfile, overridden by `pis` script at build time |

## Skill Library

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| `SKILL_CATALOG_ROOT` | ~/dotfiles/shared/skills | path | One canonical repository-owned source for cross-agent skill definitions |
| `SKILL_ENTRY_FILE` | SKILL.md | filename | Portable discovery metadata and invoked skill body use one conventional entry point |
| `SKILL_DIRECTORY_PATTERN` | lowercase-hyphenated | naming rule | Stable names resolve consistently across supported agents |
| `SKILL_DESCRIPTION_MAX_CHARS` | 1024 | characters | Maximum portable discovery-description length supported by the catalog contract |
| `SKILL_DESCRIPTION_TRIGGER_PHRASE` | Use when | literal phrase | Makes portable invocation triggers explicit |
| `SKILL_REFERENCE_MAX_DEPTH` | 1 | file traversal | Prevents nested context chains and avoidable hill climbing |
| `SKILL_BODY_SECTION_ORDER` | Language Definitions, Workflow, Activities, Reference | ordered list | Gives each optional or mandatory section one canonical semantic position |

---

*This document is the single source of truth for all parameters. Individual specs reference these values; any parameter defined here supersedes locally-defined duplicates in subsystem specs.*

---

## Changelog

| Version | Date | Summary |
|---------|------|---------|
| 2.0.0 | 2026-07-15 | Removed parameters owned solely by retired catalog workflows. |
| 1.7.0 | 2026-07-14 | Added canonical Skill Library paths, naming, discovery, Reference-depth, and section-order parameters. |
| 1.6.0 | 2026-07-05 | Added Herdr install, config, alias, SSH multiplexer, pane history, and shared skill parameters for the Herdr replacement path. |
| 1.4.0 | 2026-05-19 | Added AGENT_SKILLS_DIR_PI for Pi's composed skills directory |
| 1.3.0 | 2026-05-13 | Updated REQUIRED_NVIM_VERSION from 0.10 to 0.12; added crof provider parameters for Pi models.json |

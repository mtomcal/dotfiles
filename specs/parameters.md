# Parameters

> **Spec Version**: 1.5.0
> **Last Updated**: 2026-06-02
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
| `NPM_GLOBAL_PREFIX` | ~/.local | path | All npm-based global installs (Codex, Pi, Gemini) use this prefix so binaries land in ~/.local/bin/ and survive fnm Node version switches |
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
| `ZSH_ALIAS_VIM` | nvim | string | Muscle-memory redirect; all vim invocations launch neovim |
| `ZSH_ALIAS_VI` | nvim | string | Same redirect for the shorter invocation |
| `ZSH_ALIAS_CODEX` | cx | string | Two-char alias for Codex CLI |
| `ZSH_ALIAS_GEMINI` | gm | string | Two-char alias for Gemini CLI |
| `ZSH_ALIAS_COPILOT` | cop | string | Short alias for Copilot CLI |
| `EDITOR` | nvim | string | Ensures all tools respecting EDITOR use neovim |
| `VISUAL` | nvim | string | Ensures all tools respecting VISUAL use neovim |
| `GOPATH` | ~/go-workspace | path | Isolated from system Go; user owns the entire workspace |
| `FNM_PATH` | ~/.local/share/fnm | path | Default fnm installation directory; used to guard fnm initialization |
| `TERM` | xterm-256color | string | Ensures 256-color support for tmux and neovim integration |
| `TMUX_AUTO_SESSION` | 0 | session name | SSH auto-attach target session number; attaches to existing session 0 or creates one |

## AI Agent Configuration

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| `AGENT_INSTALL_PREFIX` | ~/.local | path prefix | Shared prefix for npm-installed agents so binaries survive fnm Node version switches; matches NPM_GLOBAL_PREFIX |
| `AGENT_CONFIG_DIR_CODEX` | ~/.codex | path | Codex CLI's canonical config directory |
| `AGENT_CONFIG_DIR_CLAUDE` | ~/.claude | path | Claude Code's canonical config directory |
| `AGENT_CONFIG_DIR_PI` | ~/.pi/agent | path | Compatibility symlink pointing to the active Pi profile runtime directory |
| `PI_PROFILE_ROOT_DIR` | ~/.pi/profiles | path | Runtime parent directory containing one deployed Pi profile per subdirectory |
| `PI_ACTIVE_PROFILE_FILE` | ~/.pi/active-profile | path | Stores the active Pi profile name so `pim current`, `pi`, and `pis` can resolve the selected profile |
| `PI_ACTIVE_PROFILE_NAME` | coding | string | Default Pi profile selected after install unless changed with `pim use` |
| `PI_PROFILE_SOURCE_ROOT` | ~/dotfiles/pi/profiles | path | Repository source root for Pi profile authoring inputs and committed resolved output |
| `AGENT_CONFIG_DIR_GEMINI` | ~/.gemini | path | Gemini CLI's canonical config directory |
| `AGENT_CONFIG_DIR_COPILOT` | ~/.config/copilot | path | Copilot CLI's canonical config directory (XDG-style) |
| `AGENT_SKILLS_DIR_CODEX` | ~/.agents/skills | path | Codex CLI resolves skills from this path; symlinked to shared skills |
| `AGENT_SKILLS_DIR_PI` | ~/.pi/agent/skills | path | Pi resolves skills through the active profile runtime; every profile includes shared skills plus any profile-local skills |
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
| `SUBAGENT_MAX_RUNNING_JOBS` | 8 | count | Maximum concurrent async subagent jobs |
| `SUBAGENT_MAX_PARALLEL_TASKS` | 20 | count | Maximum tasks in a single parallel subagent_run call |
| `SUBAGENT_WAIT_TIMEOUT_DEFAULT` | 300 | seconds | Default timeout for subagent_wait blocking calls |
| `RALPH_DEFAULT_ITERATIONS` | 25 | count | Default max loop iterations for Ralph agentic loop |
| `RALPH_DONE_PATTERN` | /done | string | Pattern that signals loop completion in Ralph worker output |
| `SUBAGENT_ROUTING_SCOUT_MODEL` | deepseek-v4-flash | string | Flash-tier model for fast read-only codebase recon; no reasoning needed, speed and cost efficiency prioritize |
| `SUBAGENT_ROUTING_SCOUT_PROVIDER` | ollama-cloud | string | Provider for scout-tier subagent models |
| `SUBAGENT_ROUTING_SCOUT_THINKING` | low | enum: off, minimal, low, medium, high, xhigh | Minimal thinking for retrieval tasks; reasoning depth is wasted on scouting |
| `SUBAGENT_ROUTING_PLANNER_MODEL` | glm-5.1 | string | Good instruction-following and breadth for planning; medium-tier model balances capability and cost |
| `SUBAGENT_ROUTING_PLANNER_PROVIDER` | ollama-cloud | string | Provider for planner-tier subagent models |
| `SUBAGENT_ROUTING_PLANNER_THINKING` | medium | enum: off, minimal, low, medium, high, xhigh | Balanced thinking for analysis and plan generation |
| `SUBAGENT_ROUTING_REVIEWER_MODEL` | deepseek-v4-pro | string | Reasoning model for deep code analysis, security audit, and architecture review |
| `SUBAGENT_ROUTING_REVIEWER_PROVIDER` | ollama-cloud | string | Provider for reviewer-tier subagent models |
| `SUBAGENT_ROUTING_REVIEWER_THINKING` | high | enum: off, minimal, low, medium, high, xhigh | High thinking for catching subtle bugs and security issues |
| `SUBAGENT_ROUTING_IMPLEMENTER_MODEL` | glm-5.1 | string | Workhorse model for code generation; sufficient for most implementation tasks |
| `SUBAGENT_ROUTING_IMPLEMENTER_PROVIDER` | ollama-cloud | string | Provider for implementer-tier subagent models |
| `SUBAGENT_ROUTING_IMPLEMENTER_THINKING` | medium | enum: off, minimal, low, medium, high, xhigh | Medium thinking balances generation quality with cost |
| `SUBAGENT_ROUTING_EXPERT_1ST_MODEL` | deepseek-v4-pro | string | Primary expert model for deep domain problems and first consultation when stuck |
| `SUBAGENT_ROUTING_EXPERT_1ST_PROVIDER` | ollama-cloud | string | Provider for primary expert model |
| `SUBAGENT_ROUTING_EXPERT_1ST_THINKING` | high | enum: off, minimal, low, medium, high, xhigh | Maximum reasoning depth for hardest problems |
| `SUBAGENT_ROUTING_EXPERT_2ND_MODEL` | glm-5.1 | string | Fallback expert model for second consultation — different architectural perspective on same issue |
| `SUBAGENT_ROUTING_EXPERT_2ND_PROVIDER` | ollama-cloud | string | Provider for second consultation expert model |
| `SUBAGENT_ROUTING_EXPERT_2ND_THINKING` | high | enum: off, minimal, low, medium, high, xhigh | High thinking on GLM-5.1 provides deeper reasoning than the default medium used in main sessions |
| `SUBAGENT_ROUTING_EXPERT_3RD_MODEL` | kimi-k2.6 | string | Final fallback expert model — third architecture for fresh perspective before user escalation |
| `SUBAGENT_ROUTING_EXPERT_3RD_PROVIDER` | opencode-go | string | Provider for third consultation expert model (overridden by crof in current settings) |
| `SUBAGENT_ROUTING_EXPERT_3RD_THINKING` | high | enum: off, minimal, low, medium, high, xhigh | High reasoning for final consultation attempt |
| `SUBAGENT_ROUTING_CROF_PROVIDER_ENABLED` | crof | string | Additional provider added to models.json with 22 models including DeepSeek V4, MiMo V2.5, GLM 5.x, Kimi K2.x, Qwen3.x, Gemma 4, and experimental models; used as active defaultProvider in Pi settings.json |
| `SUBAGENT_ROUTING_CROF_DEFAULT_MODEL` | deepseek-v4-pro | string | Default model on crof provider for main Pi session |
| `SUBAGENT_TOOLS_BRACKET_MAX_CHARS` | 30 | characters | Maximum character length for the `[tools]` bracket in display surfaces; brackets exceeding this length are truncated with `+N` overflow showing the count of remaining tools |
| `SUBAGENT_TOOLS_DISPLAY_STATUS_FORMAT` | `**Tools:** tool1, tool2, ...` | format | Format for displaying tools in `subagent_status` and `subagent_results` markdown output; comma-separated with spaces for readability |
| `SUBAGENT_TOOLS_DISPLAY_UNDEFINED` | omit | behavior | When `tools` is `undefined` (all default tools), no tool bracket or label is displayed on any surface; absence indicates unrestricted access |

---

*This document is the single source of truth for all parameters. Individual specs reference these values; any parameter defined here supersedes locally-defined duplicates in subsystem specs.*

---

## Changelog

| Version | Date | Summary |
|---------|------|---------|
| 1.5.0 | 2026-06-02 | Added Pi profile parameters for runtime root, active profile state, profile source root, and active-profile-compatible config and skills paths. |
| 1.4.0 | 2026-05-19 | Added AGENT_SKILLS_DIR_PI for Pi's composed skills directory |
| 1.3.0 | 2026-05-13 | Updated REQUIRED_NVIM_VERSION from 0.10 to 0.12; added crof provider parameters for Pi models.json |
| 1.2.0 | 2026-05-01 | Added subagent routing parameters (scout, planner, reviewer, implementer, expert 1st/2nd/3rd model/provider/thinking), tools display parameters (SUBAGENT_TOOLS_BRACKET_MAX_CHARS, SUBAGENT_TOOLS_DISPLAY_STATUS_FORMAT, SUBAGENT_TOOLS_DISPLAY_UNDEFINED) |

# Shell Configuration Specification

> **Version**: 2.0.0
> **Last Updated**: 2026-08-01
> **Depends On**: [Parameters](parameters.md), [Ubiquitous Language](../UBIQUITOUS-LANGUAGE.md), [Design Language](DESIGN_LANGUAGE.md), [Herdr Config](herdr-config.md), [Execution Coordination](execution-coordination.md)
> **Depended By**: Install Orchestrator

---

## Overview

The shell configuration system provisions and configures Zsh as the primary interactive shell, managing its setup across two distinct layers: an **Oh My Zsh base layer** installed by the install script, and a **custom shell config** sourced from the dotfiles repository. The system ensures Zsh is installed, set as the default shell, Oh My Zsh is bootstrapped, and user-specific aliases, PATH entries, and tool integrations are consistently applied on every shell session.

The design is deliberately additive: the custom shell config is sourced at the end of `.zshrc` and never replaces it, ensuring Oh My Zsh updates remain clean while user customizations persist across reinstalls.

---

## Dependencies

### Technology Dependencies

| Dependency | Minimum Version | Purpose | Install Method |
|-----------|----------------|---------|---------------|
| zsh | System default | Primary shell binary | apt (Ubuntu) / brew (macOS) |
| git | System default | Oh My Zsh clone | apt / brew |
| Oh My Zsh | Latest (master branch) | Framework providing plugins, themes, and completion | Curl-based install script |
| fnm | Latest | Fast Node Manager — manages Node.js versions | Curl-based install script |
| zoxide | Latest | Smart directory navigation (replaces cd) | apt / brew / curl script |
| Go | 1.24+ | GOPATH/bin must appear on PATH | apt (Ubuntu binary) / brew (macOS) |
| Herdr | stable | Default SSH multiplexer | Direct curl installer |
| tmux | 3.2+ | Legacy SSH fallback multiplexer | apt / brew |
| Beads | stable | Global command-repo routing when bootstrap exists | Official direct installer |

### Spec Dependencies

| Spec | Relationship |
|------|-------------|
| [Parameters](parameters.md) | Provides `ZSH_CUSTOM_FILE`, `ZSH_ALIAS_LAZYGIT`, `ZSH_ALIAS_YAZI`, `ZSH_ALIAS_ZOXIDE`, `SHELL_NAME` |
| [Ubiquitous Language](../UBIQUITOUS-LANGUAGE.md) | Defines terms: custom shell config, deploy, backup, idempotent |
| [Design Language](DESIGN_LANGUAGE.md) | Defines visual tokens for CLI output and naming conventions |
| [Execution Coordination](execution-coordination.md) | Defines the external command repo and global Beads routing contract |

---

## Parameters

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| `SHELL_NAME` | zsh | string | Chosen for Oh My Zsh framework support and superior interactive features over bash |
| `ZSH_CUSTOM_FILE` | ~/.zshrc.custom | path | Deployed path of the custom shell config; the source file resides at `~/dotfiles/zsh/.zshrc.custom` in the dotfiles repository. The parameter references the canonical deployed location, while the source line injected into `.zshrc` references the repository path directly |
| `ZSH_ALIAS_LAZYGIT` | lg | string | Two-character alias for the most frequently used git TUI tool |
| `ZSH_ALIAS_YAZI` | y | string | Single-character alias; yazi start time is fast enough for a one-key invocation |
| `ZSH_ALIAS_ZOXIDE` | z | string | Single-character alias matching zoxide's natural invocation pattern |
| `ZSH_ALIAS_TMUX` | t | string | Universal tmux launcher shortcut |
| `ZSH_ALIAS_TMUX_ATTACH` | ta | string | Mnemonic: tmux attach |
| `ZSH_ALIAS_TMUX_NEW` | tn | string | Mnemonic: tmux new |
| `ZSH_ALIAS_TMUX_LIST` | tl | string | Mnemonic: tmux list |
| `ZSH_ALIAS_TMUX_KILL` | tk | string | Mnemonic: tmux kill |
| `ZSH_ALIAS_TMUX_DETACH` | td | string | Mnemonic: tmux detach |
| `ZSH_ALIAS_HERDR` | h | string | Herdr launcher shortcut; does not replace tmux's `t` alias |
| `ZSH_ALIAS_HERDR_ATTACH` | ha | string | Mnemonic: Herdr attach |
| `ZSH_ALIAS_HERDR_LIST` | hl | string | Mnemonic: Herdr list |
| `ZSH_ALIAS_HERDR_UPDATE` | hu | string | Mnemonic: Herdr update |
| `ZSH_ALIAS_VIM` | vim → nvim | alias | Muscle-memory redirect; all vim invocations launch neovim |
| `ZSH_ALIAS_VI` | vi → nvim | alias | Same redirect for the shorter invocation |
| `ZSH_ALIAS_CODEX` | cx | string | Two-character alias for Codex CLI |
| `ZSH_ALIAS_COPILOT` | cop | string | Short alias for Copilot CLI |
| `EDITOR` | nvim | string | Ensures all tools respecting EDITOR use neovim |
| `VISUAL` | nvim | string | Ensures all tools respecting VISUAL use neovim |
| `GOPATH` | ~/go-workspace | path | Isolated from system Go; user owns the entire workspace |
| `FNM_PATH` | ~/.local/share/fnm | path | Default fnm installation directory |
| `TERM` | xterm-256color | string | Ensures 256-color support for tmux and neovim integration |
| `TMUX_AUTO_SESSION` | 0 | session name string | Legacy SSH tmux fallback target; the value "0" is a session name string, not a boolean. Attaches to existing session "0" or creates one |
| `SSH_MULTIPLEXER_DEFAULT` | herdr | enum | Default SSH multiplexer when no override is set |
| `SSH_MULTIPLEXER_OVERRIDE_ENV` | DOTFILES_SSH_MULTIPLEXER | env var | Optional per-machine override: `herdr`, `tmux`, or `none` |
| `BEADS_COMMAND_CONFIG_PATH` | ~/.config/beads-command/env | path | Local unversioned bootstrap result containing the selected external Beads path |
| `BEADS_COMMAND_ENV` | BEADS_DIR | env var | Native discovery override globally routing ordinary `bd` commands to the command repo |

---

## Data Structures

### Custom Shell Config

The custom shell config is a sourced file — not a standalone script. It MUST NOT contain a shebang line or execute independently.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| editor_export | map{string: string} | Keys: EDITOR, VISUAL; Values: nvim | Sets the preferred editor for local and remote sessions |
| path_prepend | list{string} | Ordered; ~/.local/bin appears first (highest priority) | Directories prepended to PATH before system defaults |
| aliases | map{string: string} | Key = alias name, Value = expanded command | Shell aliases grouped by domain (tmux, editor, TUI tools, AI agents) |
| shell_options | map{string: boolean} | Key = zsh option name, Value = desired state | Zsh options that differ from defaults |
| go_config | map{string: string} | Keys: GOPATH, PATH additions | Go-specific environment variables and PATH entries |
| fnm_config | conditional{string} | Guarded by directory existence check | fnm environment initialization |
| zoxide_config | conditional{string} | Guarded by command existence check | zoxide shell integration |
| ssh_multiplexer_rule | conditional{string} | Guarded by SSH_CONNECTION, HERDR_ENV, TMUX, and DOTFILES_SSH_MULTIPLEXER checks | Auto-attach rule for SSH sessions |
| command_repo_route | conditional{path} | Guarded by valid local runtime config | Globally exports the external command repo through `BEADS_DIR` |

### Oh My Zsh Installation Record

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| install_directory | string | Default: ~/.oh-my-zsh | Oh My Zsh framework directory |
| install_method | string | Value: "unattended" | Prevents the Oh My Zsh installer from prompting for shell restart |
| current_shell | string | Read from $SHELL | Used to check whether chsh is needed |

### Install Script Zsh Module

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| module_name | string | Value: "zsh_ohmyzsh" | Installs Zsh binary and Oh My Zsh framework |
| module_name_config | string | Value: "zsh_config" | Deploys custom shell config sourcing line into .zshrc |
| dependency_guard | string | Value: "zsh command must exist" | install_zsh is called if zsh is missing |
| source_line | string | References `$ZSH_CUSTOM_FILE` resolved to `~/dotfiles/zsh/.zshrc.custom` via the repository path | The line injected into .zshrc to source the custom config; uses the repository path rather than the deployed symlink path |

---

## Behavior

### BR-SHELL-001: Install Zsh Binary

| Condition | Action |
|-----------|--------|
| zsh command not found on system | Install zsh via system package manager (apt on Ubuntu/Debian, brew on macOS) |
| zsh command found | Skip installation, log success |

### BR-SHELL-002: Install Oh My Zsh Framework

| Condition | Action |
|-----------|--------|
| ~/.oh-my-zsh directory does not exist | Clone Oh My Zsh from official repository using unattended install mode |
| ~/.oh-my-zsh directory exists | Skip installation, log success |

### BR-SHELL-003: Set Default Shell to Zsh

| Condition | Action |
|-----------|--------|
| Current default shell (basename of `$SHELL`) is not zsh | Change the default shell to zsh; user must restart the shell session for the change to take effect |
| Current default shell is already zsh | Skip, log that zsh is already the default |

### BR-SHELL-004: Deploy Custom Shell Config Source Line

| Condition | Action |
|-----------|--------|
| Substring search of `~/.zshrc` does not find the custom config source guard | Append to `~/.zshrc`: a blank line, a comment "# Source custom dotfiles configuration", and a file-existence guard that conditionally sources the custom config via the `$ZSH_CUSTOM_FILE` reference path |
| Substring search of `~/.zshrc` finds the custom config source guard | Skip, log that custom config is already sourced |

### BR-SHELL-005: Set Editor Environment Variables

On every shell session startup, the custom shell config MUST set both `EDITOR` and `VISUAL` to `nvim`, ensuring all tools and protocols that respect these variables use neovim as the default editor.

### BR-SHELL-006: Configure PATH

On every shell session startup, the custom shell config MUST prepend `~/.local/bin` to PATH. This ensures user-local binaries (fnm-managed Node, globally installed npm packages like Codex and Pi) take precedence over system packages.

### BR-SHELL-007: Register Tmux Aliases

On every shell session startup, the following tmux aliases MUST be available:

| Alias | Expansion |
|-------|-----------|
| `t` | `tmux` |
| `ta` | `tmux attach -t` |
| `tn` | `tmux new -s` |
| `tl` | `tmux ls` |
| `tk` | `tmux kill-session -t` |
| `td` | `tmux detach` |

### BR-SHELL-008: Register Herdr Aliases

On every shell session startup, the following Herdr aliases MUST be available:

| Alias | Expansion |
|-------|-----------|
| `h` | `herdr` |
| `ha` | `herdr session attach` |
| `hl` | `herdr session list` |
| `hu` | `herdr update` |

The tmux aliases MUST NOT be repointed to Herdr. Herdr receives its own `h*` alias family.

### BR-SHELL-008a: SSH Auto-Attach to Multiplexer

On shell session startup, the system MUST evaluate the following conditions in order:

| Condition | Action |
|-----------|--------|
| `$DOTFILES_SSH_MULTIPLEXER` is `none` | Do nothing |
| `$HERDR_ENV` is `1` | Do nothing - already inside a Herdr session |
| `$TMUX` environment variable is set | Do nothing — already inside a tmux session |
| `$SSH_CONNECTION` environment variable is empty | Do nothing — not an SSH session |
| `$DOTFILES_SSH_MULTIPLEXER` is `tmux` AND `$SSH_CONNECTION` is set | Attempt to attach to tmux session `$TMUX_AUTO_SESSION`; if that session does not exist, create a new session named `$TMUX_AUTO_SESSION` |
| `$DOTFILES_SSH_MULTIPLEXER` is unset or `herdr` AND `$SSH_CONNECTION` is set | Start or attach Herdr by running `herdr` |

This ensures remote SSH sessions start inside Herdr by default, while local sessions and nested multiplexer sessions are unaffected. Tmux remains available as a per-machine fallback through `DOTFILES_SSH_MULTIPLEXER=tmux`.

### BR-SHELL-009: Register Editor Aliases

On every shell session startup, the following editor aliases MUST be available:

| Alias | Expansion |
|-------|-----------|
| `vim` | `nvim` |
| `vi` | `nvim` |

### BR-SHELL-010: Disable AUTO_CD

On every shell session startup, the shell option `AUTO_CD` MUST be unset. This prevents zsh from implicitly changing directories when a directory name is typed as a command — mistyped or missing commands MUST produce an error rather than an unintended `cd`.

### BR-SHELL-011: Register TUI Tool Aliases

On every shell session startup, the following TUI tool aliases MUST be available:

| Alias | Expansion |
|-------|-----------|
| `lg` | `lazygit` |
| `y` | `yazi` |

### BR-SHELL-012: Register AI Agent Aliases

On every shell session startup, the following AI agent aliases MUST be available:

| Alias | Expansion |
|-------|-----------|
| `cx` | `codex` |
| `cop` | `copilot` |

### BR-SHELL-013: Set Terminal Type

On every shell session startup, the `TERM` environment variable MUST be set to `xterm-256color`. This ensures 256-color support for tmux and neovim integration across platform variations.

### BR-SHELL-014: Configure Go Environment

On every shell session startup, the Go environment MUST be configured:

| Condition | Action |
|-----------|--------|
| System is Linux AND /usr/local/go/bin exists | Prepend /usr/local/go/bin to PATH |
| System is macOS | Homebrew manages Go binary location automatically; no PATH addition needed |
| Always (both platforms) | Set GOPATH to ~/go-workspace; prepend $GOPATH/bin to PATH |

On macOS, Homebrew's Go binary location MUST be resolved dynamically by brew itself and MUST NOT be hardcoded in the custom shell config.

### BR-SHELL-015: Initialize Zoxide

On every shell session startup, the system MUST conditionally initialize zoxide:

| Condition | Action |
|-----------|--------|
| `zoxide` command is available in PATH | Evaluate zoxide's zsh initialization (`zoxide init zsh`) to enable the `z` command and integration |
| `zoxide` command is not available | Skip silently — no error, no warning |

### BR-SHELL-016: Initialize fnm (Fast Node Manager)

On every shell session startup, the system MUST conditionally initialize fnm:

| Condition | Action |
|-----------|--------|
| Directory at `$FNM_PATH` exists | Prepend fnm directory to PATH; evaluate fnm environment with `--use-on-cd --shell zsh`; re-prepend `~/.local/bin` to PATH (ensuring user-local npm binaries remain ahead of fnm-managed globals) |
| Directory at `$FNM_PATH` does not exist | Skip silently — no error, no warning |

The `--use-on-cd` flag causes fnm to automatically switch to the Node version specified by `.node-version` or `.nvmrc` files when changing directories.

The second `~/.local/bin` PATH prepend after fnm initialization is critical: without it, fnm's managed Node binaries would shadow user-installed global npm tools (such as Codex CLI and Pi) installed via `npm install -g --prefix ~/.local`.

### BR-SHELL-017: Route Beads to the Command Repo

On every shell session startup, the custom shell config MUST inspect `BEADS_COMMAND_CONFIG_PATH`:

| Condition | Action |
|-----------|--------|
| Runtime config exists, is readable, and names an absolute existing `.beads/` directory | Load the local value and globally export `BEADS_DIR` |
| Runtime config is absent | Leave `BEADS_DIR` unchanged and produce no shell-startup error |
| Runtime config exists but is malformed or stale | Do not export the invalid path; make the condition inspectable without blocking ordinary shell use |

The runtime config is machine-local mutable state and MUST NOT be symlinked into or captured by dotfiles. Once exported, ordinary `bd` commands from every source checkout use the external command repo rather than creating source-repository state. Execution workflows MUST stop with bootstrap guidance when no valid route exists.

### BR-SHELL-018: Dependency Resolution for Zsh Modules

The install script's dependency resolver MUST enforce the following before executing either Zsh module:

| Module | Prerequisite Check | Auto-Add |
|--------|-------------------|----------|
| zsh_ohmyzsh | zsh command must exist | If missing, auto-add `base_tools` module |
| zsh_ohmyzsh | git command must exist | If missing, auto-add `base_tools` module |
| zsh_config | zsh command must exist | If missing, auto-add `base_tools` module |

---

## Error Handling

### EH-SHELL-001: Zsh Binary Not Found During Config Module

| Attribute | Value |
|-----------|-------|
| **Trigger** | `zsh_config` module selected but zsh not installed |
| **Detection** | `command -v zsh` fails |
| **Response** | Automatically invoke `base_tools` module first to install zsh |
| **Recovery** | Proceed with `zsh_config` after successful zsh installation |

### EH-SHELL-002: Oh My Zsh Install Failure

| Attribute | Value |
|-----------|-------|
| **Trigger** | Oh My Zsh clone fails (network, permissions) |
| **Detection** | ~/.oh-my-zsh directory does not exist after install attempt |
| **Response** | Module is added to `FAILED_MODULES` list; script continues with remaining modules |
| **Recovery** | User must manually install Oh My Zsh or re-run the install script with network access |

### EH-SHELL-003: Default Shell Change Failure

| Attribute | Value |
|-----------|-------|
| **Trigger** | `chsh -s $(which zsh)` returns non-zero |
| **Detection** | Shell exit code from chsh command |
| **Response** | Warning message displayed; script does NOT halt (due to `set -e` being per-module) |
| **Recovery** | User must manually run `chsh -s $(which zsh)` and restart the shell session |

### EH-SHELL-004: Custom Source Line Already Exists

| Attribute | Value |
|-----------|-------|
| **Trigger** | Substring search finds the custom config source guard in `~/.zshrc` |
| **Detection** | Substring match for the `$ZSH_CUSTOM_FILE` reference (resolved to `~/dotfiles/zsh/.zshrc.custom` via the repository path) anywhere in `~/.zshrc` content |
| **Response** | Skip injection; log that custom config is already sourced |
| **Recovery** | None needed — idempotent behavior |

### EH-SHELL-005: FNM Directory Missing

| Attribute | Value |
|-----------|-------|
| **Trigger** | `$FNM_PATH` directory does not exist when custom shell config is sourced |
| **Detection** | Directory existence check `[ -d "$FNM_PATH" ]` fails |
| **Response** | Skip fnm initialization entirely; Node.js and npm commands will not be available |
| **Recovery** | Run `install.sh --modules nodejs` to install fnm and Node.js, then restart shell |

### EH-SHELL-006: Zoxide Not Installed

| Attribute | Value |
|-----------|-------|
| **Trigger** | `zoxide` command not found when custom shell config is sourced |
| **Detection** | `command -v zoxide` returns non-zero |
| **Response** | Skip zoxide initialization silently; `z` command will not be available |
| **Recovery** | Run `install.sh --modules tui_tools` to install zoxide, then restart shell |

### EH-SHELL-007: SSH Herdr Launch Fails

| Attribute | Value |
|-----------|-------|
| **Trigger** | SSH session starts with Herdr as the selected SSH multiplexer but `herdr` cannot launch |
| **Detection** | `herdr` command exits non-zero or is not found |
| **Response** | Print the shell error normally; do not silently start tmux unless `DOTFILES_SSH_MULTIPLEXER=tmux` is set |
| **Recovery** | Install Herdr or set `DOTFILES_SSH_MULTIPLEXER=tmux` for that machine |

### EH-SHELL-007a: SSH Tmux Fallback Attach Fails on No Sessions

| Attribute | Value |
|-----------|-------|
| **Trigger** | SSH session starts with `DOTFILES_SSH_MULTIPLEXER=tmux` but no tmux session named `$TMUX_AUTO_SESSION` exists |
| **Detection** | Attach attempt to session `$TMUX_AUTO_SESSION` returns non-zero |
| **Response** | Fallback: create a new tmux session named `$TMUX_AUTO_SESSION` |
| **Recovery** | Automatic; no user intervention needed |

### EH-SHELL-008: Command-Repo Runtime Config Invalid

| Attribute | Value |
|-----------|-------|
| **Trigger** | Local command-repo config exists but is malformed, relative, unreadable, or points to a missing `.beads/` directory |
| **Detection** | Shell route validation fails |
| **Response** | Do not export the invalid `BEADS_DIR`; preserve ordinary shell startup |
| **Recovery** | Rerun explicit command-repo bootstrap or repair the local runtime path |

### EH-SHELL-009: Package Manager Not Available

| Attribute | Value |
|-----------|-------|
| **Trigger** | Neither apt nor brew is found during OS detection |
| **Detection** | OSTYPE check yields neither linux-gnu nor darwin, OR apt not found on Linux |
| **Response** | Print error and exit with non-zero code |
| **Recovery** | Install apt (Ubuntu/Debian) or Homebrew (macOS) and re-run the install script |

---

## Implementation Notes

1. **Source-order matters**: The custom shell config is sourced at the end of `.zshrc`, which means its PATH entries, aliases, and initializations take effect after all Oh My Zsh processing. This is intentional — Oh My Zsh must never override user-defined PATH entries or aliases.

2. **PATH priority cascade**: PATH entries are prepended in this order of priority (highest first): `~/.local/bin` (user-local binaries), fnm-managed Node, `$GOPATH/bin`, `/usr/local/go/bin` (Linux only). Each prepension ensures later shells don't shadow earlier entries.

3. **Conditional initialization is silent**: Both fnm and zoxide initialization guards MUST NOT produce any output (error messages, warnings, or status lines) when the tool is not installed. A missing tool is an expected state on a fresh system before running `install.sh`.

4. **Idempotent source injection**: The `.zshrc` source line injection MUST be idempotent. Running the config module multiple times MUST NOT produce duplicate source lines in `.zshrc`. Idempotency is verified via substring match — the deploy logic checks whether the source guard appears anywhere in `.zshrc` content, not via exact line comparison.

5. **Platform branching in shell config**: The custom shell config includes OS-detection branching for Go PATH. This MUST use `uname` at source time (not during install), because the same dotfiles repo may be deployed across heterogeneous machines.

6. **AUTO_CD is deliberately disabled**: The rationale is safety — mistyped command names that happen to match directory names MUST produce "command not found" errors rather than silently changing the working directory.

7. **The ~/.local/bin PATH prepension appears twice**: Once at the top of the custom shell config (before fnm) and once after fnm initialization. The second prepension is NOT redundant — it ensures that user-installed npm global packages (installed into `~/.local/bin`) remain ahead of fnm's managed Node binaries in the PATH order.

8. **SSH multiplexer default**: SSH sessions default to Herdr. Tmux is a fallback selected explicitly with `DOTFILES_SSH_MULTIPLEXER=tmux`, and `DOTFILES_SSH_MULTIPLEXER=none` disables SSH auto-attach.

9. **SSH tmux fallback target**: The session name `0` (`TMUX_AUTO_SESSION`) is a string, not a boolean. The value "0" is used as a tmux session name — it avoids ambiguity with named sessions and matches the default tmux session numbering.

10. **Beads routing is local state**: The tracked custom shell config owns only conditional loading behavior. Bootstrap owns the unversioned absolute path, and missing bootstrap state must not make every shell noisy or unusable.

---

## Test Scenarios

### TS-SHELL-001: Custom Config Source Line Injection

**Category**: Integration
**Priority**: Critical
**Preconditions**: Oh My Zsh is installed; ~/.zshrc exists and does not contain the custom source line
**Input**: Run `install.sh --modules zsh_config`
**Expected Output**: `~/.zshrc` contains exactly one source guard block that conditionally sources the custom config via the `$ZSH_CUSTOM_FILE` reference path

### TS-SHELL-002: Idempotent Source Line Injection

**Category**: Integration
**Priority**: Critical
**Preconditions**: ~/.zshrc already contains the custom source line
**Input**: Run `install.sh --modules zsh_config`
**Expected Output**: ~/.zshrc is unchanged (no duplicate source lines added)

### TS-SHELL-003: Editor Environment Variables

**Category**: Unit
**Priority**: High
**Preconditions**: Custom shell config is sourced
**Input**: `echo $EDITOR` and `echo $VISUAL`
**Expected Output**: Both output `nvim`

### TS-SHELL-004: PATH Priority for User-Local Binaries

**Category**: Unit
**Priority**: Critical
**Preconditions**: Custom shell config is sourced; ~/.local/bin contains binaries
**Input**: `which <binary-in-dot-local-bin>`
**Expected Output**: Path resolves to `~/.local/bin/<binary>` — user-local binaries MUST appear before system paths

### TS-SHELL-005: FNM PATH Priority After Init

**Category**: Unit
**Priority**: High
**Preconditions**: fnm is installed at ~/.local/share/fnm; Node.js is installed via fnm; a global npm package exists in ~/.local/bin
**Input**: `which <global-npm-package>`
**Expected Output**: Path resolves to `~/.local/bin/<package>` — NOT to fnm's managed globals. The second `~/.local/bin` PATH prepend ensures this.

### TS-SHELL-006: Tmux Aliases Available

**Category**: Unit
**Priority**: High
**Preconditions**: Custom shell config is sourced
**Input**: `alias t`, `alias ta`, `alias tn`, `alias tl`, `alias tk`, `alias td`
**Expected Output**: Each alias expands to its corresponding tmux command

### TS-SHELL-006a: Herdr Aliases Available

**Category**: Unit
**Priority**: High
**Preconditions**: Custom shell config is sourced
**Input**: `alias h`, `alias ha`, `alias hl`, `alias hu`
**Expected Output**: Each alias expands to its corresponding Herdr command; tmux aliases remain unchanged

### TS-SHELL-007: SSH Auto-Attach Starts Herdr By Default

**Category**: Integration
**Priority**: Critical
**Preconditions**: SSH session starts; `$DOTFILES_SSH_MULTIPLEXER` is unset; `$HERDR_ENV` and `$TMUX` are unset
**Input**: SSH login to the machine
**Expected Output**: User is placed in Herdr automatically

### TS-SHELL-008: SSH Auto-Attach Uses Tmux Fallback

**Category**: Integration
**Priority**: High
**Preconditions**: SSH session starts; `$DOTFILES_SSH_MULTIPLEXER=tmux`; no tmux sessions exist
**Input**: SSH login to the machine
**Expected Output**: User is placed in tmux session 0 automatically

### TS-SHELL-009: No Auto-Attach in Local Session

**Category**: Unit
**Priority**: High
**Preconditions**: `$SSH_CONNECTION` is empty (local session); `$HERDR_ENV` and `$TMUX` are empty
**Input**: Start a new terminal on the local machine
**Expected Output**: No multiplexer auto-attach occurs; user remains in a plain zsh session

### TS-SHELL-010: No Auto-Attach When Already in a Multiplexer

**Category**: Unit
**Priority**: Medium
**Preconditions**: `$HERDR_ENV` is `1` or `$TMUX` is set; `$SSH_CONNECTION` is non-empty
**Input**: Nested SSH from inside an existing multiplexer
**Expected Output**: No second multiplexer attach attempt; existing multiplexer session continues

### TS-SHELL-010a: SSH Auto-Attach Can Be Disabled

**Category**: Unit
**Priority**: Medium
**Preconditions**: `$DOTFILES_SSH_MULTIPLEXER=none`; `$SSH_CONNECTION` is non-empty
**Input**: SSH login to the machine
**Expected Output**: No Herdr or tmux auto-attach occurs

### TS-SHELL-011: AUTO_CD Disabled

**Category**: Unit
**Priority**: Medium
**Preconditions**: Custom shell config is sourced
**Input**: Type a directory name as a command (e.g., just `Documents` at the prompt)
**Expected Output**: "command not found" error — NOT an implicit directory change

### TS-SHELL-012: Editor Aliases Redirect to Neovim

**Category**: Unit
**Priority**: Medium
**Preconditions**: Custom shell config is sourced; neovim is installed
**Input**: `alias vim`, `alias vi`
**Expected Output**: `vim` expands to `nvim`; `vi` expands to `nvim`

### TS-SHELL-013: TUI Tool Aliases

**Category**: Unit
**Priority**: Medium
**Preconditions**: Custom shell config is sourced; lazygit and yazi are installed
**Input**: `alias lg`, `alias y`
**Expected Output**: `lg` expands to `lazygit`; `y` expands to `yazi`

### TS-SHELL-014: AI Agent Aliases

**Category**: Unit
**Priority**: Medium
**Preconditions**: Custom shell config is sourced
**Input**: `alias cx`, `alias cop`
**Expected Output**: `cx` expands to `codex`; `cop` expands to `copilot`

### TS-SHELL-015: Go GOPATH and PATH on Linux

**Category**: Unit
**Priority**: High
**Preconditions**: Custom shell config is sourced on Linux; /usr/local/go/bin exists; Go is installed
**Input**: `echo $GOPATH` and `which go`
**Expected Output**: GOPATH is `~/go-workspace`; Go binary resolves from `/usr/local/go/bin/go` or `$GOPATH/bin`

### TS-SHELL-016: Go GOPATH on macOS Without Hardcoded Path

**Category**: Unit
**Priority**: High
**Preconditions**: Custom shell config is sourced on macOS; Go is installed via Homebrew
**Input**: `echo $GOPATH`
**Expected Output**: GOPATH is `~/go-workspace`; `/usr/local/go/bin` is NOT in PATH (Homebrew manages this)

### TS-SHELL-017: Zoxide Init Skipped When Missing

**Category**: Unit
**Priority**: Medium
**Preconditions**: zoxide is not installed; custom shell config is sourced
**Input**: `type z`
**Expected Output**: `z` is not found (or is the shell built-in); no error message printed during shell startup

### TS-SHELL-018: FNM Init Skipped When Missing

**Category**: Unit
**Priority**: Medium
**Preconditions**: ~/.local/share/fnm directory does not exist; custom shell config is sourced
**Input**: `type fnm`
**Expected Output**: `fnm` is not found; no error message printed during shell startup

### TS-SHELL-019: Default Shell Change Skipped When已是 Zsh

**Category**: Integration
**Priority**: Medium
**Preconditions**: Current default shell is already zsh
**Input**: Run `install.sh --modules zsh_ohmyzsh`
**Expected Output**: Install script logs that zsh is already the default shell; `chsh` is not invoked

### TS-SHELL-020: Dependency Resolution Auto-Adds Base Tools

**Category**: Integration
**Priority**: High
**Preconditions**: zsh is NOT installed on the system
**Input**: Run `install.sh --modules zsh_config`
**Expected Output**: Dependency resolver auto-adds `base_tools` module; zsh is installed before config deployment proceeds

### TS-SHELL-021: Terminal Type Set for Tmux Compatibility

**Category**: Unit
**Priority**: Medium
**Preconditions**: Custom shell config is sourced
**Input**: `echo $TERM`
**Expected Output**: `xterm-256color`

### TS-SHELL-022: Valid Command-Repo Route

**Category**: Integration
**Priority**: Critical
**Preconditions**: Bootstrap wrote valid local runtime config naming an external `.beads/` directory
**Input**: Start a fresh shell and run `bd` from an unrelated source checkout
**Expected Output**: `BEADS_DIR` is globally exported to the external command repo and no source-repository `.beads/` directory is created

### TS-SHELL-023: Missing or Stale Command-Repo Route

**Category**: Unit
**Priority**: High
**Preconditions**: Runtime config is absent, then present with a stale path
**Input**: Start a fresh shell in each state
**Expected Output**: Shell startup succeeds without exporting an invalid path; execution workflows provide bootstrap guidance

---

## Changelog

| Version | Date | Summary |
|---------|------|---------|
| 2.0.0 | 2026-08-01 | Added machine-local external command-repo routing and global guarded `BEADS_DIR` export. |
| 1.1.0 | 2026-07-05 | Added Herdr aliases, changed SSH auto-attach default from tmux to Herdr, and specified tmux/none environment overrides. |
| 1.0.0 | 2026-05-01 | Initial specification: Zsh/Oh My Zsh installation, custom shell config deployment, aliases, PATH configuration, SSH tmux auto-attach, Go environment, fnm/zoxide conditional init |

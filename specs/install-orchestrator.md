# Install Orchestrator

> **Spec Version**: 2.1.0
> **Last Updated**: 2026-08-02
> **Depends On**: [Parameters](parameters.md), [Ubiquitous Language](../UBIQUITOUS-LANGUAGE.md), [Design Language](DESIGN_LANGUAGE.md), [Tool Provisioning](tool-provisioning.md), [Symlink Manager](symlink-manager.md), [Herdr Config](herdr-config.md), [VS Code Configuration](vscode-config.md), [Execution Coordination](execution-coordination.md)
> **Depended By**: None (this is the top-level orchestrator)

---

## Overview

The Install Orchestrator is the top-level entry point for deploying the entire dotfiles-managed development environment. It detects the platform, resolves module dependencies, presents an interactive or command-line-driven module selection interface, and then executes each selected module in dependency order. The orchestrator guarantees idempotency — running it multiple times with the same module list MUST produce the same system state without errors, data loss, or redundant operations.

For Pi, the orchestrator deploys tracked runtime resources under `~/.pi/agent`, preserves mutable local settings, and installs wrapper commands.

For editors, the orchestrator provides official Visual Studio Code Desktop only on macOS, an explicit custom-only code-server service only on Ubuntu/Debian, and a separately selectable Python 3.10+ baseline runtime. These are approved desired modules and are not yet implemented.

The orchestrator does NOT implement any module's internal logic (package installation, symlink creation, etc.). It calls per-module functions that own those details. This spec governs the orchestration flow, phase ordering, platform branching, module dependency resolution, interactive menu behavior, and failure reporting.

---

## Dependencies

### Technology Dependencies

| Technology | Purpose                              | Version Constraint                 |
| ---------- | ------------------------------------ | ---------------------------------- |
| Bash       | Runtime interpreter                  | Compatible with macOS system shell |
| apt        | Package manager (Ubuntu/Debian)      | —                                  |
| Homebrew   | Package manager (macOS)              | Auto-installed if missing          |
| curl       | Downloading external installers      | System-provided                    |
| git        | Cloning kickstart.nvim and Oh My Zsh | System-provided                    |

### Spec Dependencies

| Spec                                                | Relationship                                                                                |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| [Parameters](parameters.md)                         | All tuning values (versions, URLs, thresholds) live there                                   |
| [Ubiquitous Language](../UBIQUITOUS-LANGUAGE.md)       | Shared term definitions                                                                     |
| [Design Language](DESIGN_LANGUAGE.md)               | CLI output formatting tokens                                                                |
| [Tool Provisioning](tool-provisioning.md)           | Per-module install/configure function specifications                                        |
| [Symlink Manager](symlink-manager.md)               | Cross-cutting symlink deployment and backup rules                                           |
| [VS Code Configuration](vscode-config.md)           | Platform-scoped managed layer, extension, capture, Vim, and code-server lifecycle contracts |
| [Execution Coordination](execution-coordination.md) | Beads/Dolt profile inclusion and command-repo bootstrap separation                          |

---

## Parameters

| Parameter                    | Value                          | Unit                          | Rationale                                                                                                                                                                             |
| ---------------------------- | ------------------------------ | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SCRIPT_MODE`                | strict                         | enum: `strict`                | Any command failure halts execution immediately; module functions MUST catch their own failures and convert them into tracked module failures rather than allowing the script to exit |
| `BACKUP_TIMESTAMP_FMT`       | `%Y%m%d_%H%M%S`                | strftime                      | Sortable, second-granular timestamps for conflict backups                                                                                                                             |
| `DOTFILES_DIR`               | Auto-detected script directory | path                          | The repository root MUST be auto-detected from the script's own location at runtime, never hard-coded                                                                                 |
| `CODEX_CONFIG_TEMPLATE_MODE` | `preserve`                     | enum: `preserve`, `overwrite` | Controls whether an existing local Codex config is kept or replaced from the dotfiles template                                                                                        |
| `MAX_PROFILE_CHOICE`         | 4                              | integer                       | Highest valid choice on the profile menu (Full, Minimal, Work, Custom)                                                                                                                |
| `NPM_GLOBAL_PREFIX`          | `~/.local`                     | path                          | All npm-based global installs (Codex and Pi) use this prefix so they survive fnm Node version switches                                                                                |

---

## Data Structures

### Platform Identity

| Field             | Type                    | Constraints                       | Description                                                                                |
| ----------------- | ----------------------- | --------------------------------- | ------------------------------------------------------------------------------------------ |
| `OS`              | enum: `ubuntu`, `macos` | Set exactly once during detection | Determines package manager, architecture detection method, and platform-specific branching |
| `PACKAGE_MANAGER` | enum: `apt`, `brew`     | Derived from `OS`                 | Drives all package operations                                                              |

### Module

| Field   | Type   | Constraints                         | Description                                     |
| ------- | ------ | ----------------------------------- | ----------------------------------------------- |
| `name`  | string | One of the valid module identifiers | Unique identifier for a selectable install unit |
| `label` | string | Human-readable description          | Displayed in menus and summaries                |

**Valid module identifiers**: `base_tools`, `neovim`, `nvim_config`, `vscode`, `vscode_config`, `code_server`, `tmux_config`, `herdr`, `herdr_config`, `herdr_integrations`, `zsh_ohmyzsh`, `zsh_config`, `python`, `golang` (toolchain only), `golang_full` (toolchain + LSP + tools), `nodejs`, `tui_tools`, `beads`, `codex`, `codex_sandbox`, `claude`, `pi`, `pi_sandbox`, `copilot`, `playwright`

### Pi Module Deployment Contract

When the `pi` module is selected, the orchestrator MUST:

1. Install the shared Pi binary once.
2. Deploy `pi/models.json`, `pi/skills`, and enabled Pi extensions into `~/.pi/agent/`.
3. Initialize and preserve local Pi settings, auth, and session state under `~/.pi/agent/`; migrate a legacy managed settings symlink to a regular file without losing content.
4. Deploy wrapper commands `pi` and `pis`.

### Editor Module Contracts

| Module          | Supported Platform      | Contract                                                                                                                      |
| --------------- | ----------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `vscode`        | macOS                   | Install or update official stable Visual Studio Code through Homebrew Cask                                                    |
| `vscode_config` | macOS                   | Deploy the VS Code managed layer, reconcile extensions, configure Vim key repeat, and report manual Settings Sync disablement |
| `code_server`   | Ubuntu/Debian           | Install/update, configure, enable, start, reconcile, and health-check the authenticated HTTPS service                         |
| `python`        | Ubuntu/Debian and macOS | Install and verify native Python 3.10+ plus virtual-environment capability                                                    |

`code_server` MUST be available in the Custom menu and through `--modules`, but MUST NOT be included in any standard installation profile.

### Installation Profile

| Profile   | Common Modules Included                                                                                                                                                                                                          | macOS-only Additions  |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| `full`    | base_tools, neovim, nvim_config, tmux_config, herdr, herdr_config, herdr_integrations, zsh_ohmyzsh, zsh_config, python, golang_full, nodejs, tui_tools, beads, codex, codex_sandbox, claude, playwright, pi, pi_sandbox, copilot | vscode, vscode_config |
| `minimal` | base_tools, neovim, nvim_config, tmux_config, herdr, herdr_config, herdr_integrations                                                                                                                                            | none                  |
| `work`    | base_tools, neovim, nvim_config, tmux_config, herdr, herdr_config, herdr_integrations, python, tui_tools, beads, copilot                                                                                                         | vscode, vscode_config |

On Ubuntu/Debian, standard profiles MUST omit the macOS-only additions rather than selecting and skipping them.

### Dependency Map

Modules declare implicit prerequisites via the dependency resolver. The resolver adds missing prerequisites **conditionally** — only when the prerequisite tool is not already found on the system. If a tool is already installed, its prerequisite module is not added.

| Module               | Conditional Prerequisite(s)          | Condition                                                                                       |
| -------------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------- |
| `nvim_config`        | `base_tools`                         | Only if `git` is not found                                                                      |
| `nvim_config`        | `neovim`                             | Only if `nvim` is not found                                                                     |
| `zsh_ohmyzsh`        | `base_tools`                         | Only if `zsh` or `git` is not found                                                             |
| `zsh_config`         | `base_tools`                         | Only if `zsh` is not found                                                                      |
| `tmux_config`        | `base_tools`                         | Only if `tmux` is not found                                                                     |
| `herdr`              | `base_tools`                         | Only if `curl` is not found                                                                     |
| `herdr_config`       | `herdr`                              | Only if `herdr` is not found                                                                    |
| `herdr_integrations` | `herdr`                              | Only if `herdr` is not found; agent-specific integration deployment skips missing agent configs |
| `claude`             | `base_tools`                         | Only if `curl` or `jq` is not found                                                             |
| `copilot`            | `base_tools`                         | Only if `curl` is not found                                                                     |
| `pi`                 | `nodejs`                             | Only if `npm` is not found                                                                      |
| `pi_sandbox`         | Docker (external)                    | Not auto-installed; warning issued if missing                                                   |
| `codex`              | `nodejs`                             | Only if `npm` is not found                                                                      |
| `codex_sandbox`      | `codex`, `nodejs`, Docker (external) | `nodejs` only if `npm` is not found; Docker warning issued if missing                           |
| `playwright`         | `nodejs`                             | Only if `npm` is not found                                                                      |
| `golang_full`        | `golang`                             | Always (golang_full calls golang install internally)                                            |
| `vscode_config`      | `vscode`                             | Only on macOS and only if the desktop editor command is not found                               |
| `code_server`        | `base_tools`                         | Only if curl is not found; service manager is a platform prerequisite                           |
| `python`             | none                                 | Native package manager is initialized during platform setup                                     |
| `beads`              | `base_tools`                         | Only if curl is missing; embedded storage needs no separate Dolt install                        |

**Deduplication rule**: After dependency resolution, duplicate modules MUST be removed while preserving insertion order.

### Failure Tracking

| Field              | Type           | Constraints                                         | Description                          |
| ------------------ | -------------- | --------------------------------------------------- | ------------------------------------ |
| `FAILED_MODULES`   | list of string | Appended to when a module function returns non-zero | Modules that failed during execution |
| `SELECTED_MODULES` | list of string | Final resolved list after dependency expansion      | All modules that were attempted      |

---

## Behavior

### Phase Ordering

The orchestrator MUST execute phases in this exact order:

```
Phase 1: ARGUMENT PARSING
  → Parse CLI flags (--profile, --modules, --codex-config-template, --help)
  → If --help, display help and exit

Phase 2: PLATFORM DETECTION
  → Detect OS and package manager
  → Setup package manager (install Homebrew on macOS if missing)
  → Update package manager index

Phase 3: MODULE SELECTION
  → If modules were provided via CLI (--profile or --modules), use those
  → If no modules provided, show interactive profile menu
  → Validate module names

Phase 4: DEPENDENCY RESOLUTION
  → Expand selected modules to include implicit prerequisites
  → Deduplicate while preserving order

Phase 5: CONFIRMATION
  → Show installation summary with human-readable labels
  → Prompt user to confirm (y/n)
  → If declined, exit cleanly

Phase 6: MODULE EXECUTION
  → Iterate resolved modules in order
  → Call each module's install/configure function
  → Track failures; do NOT halt script on individual module failure

Phase 7: COMPLETION REPORT
  → Display list of successfully installed modules
  → Display list of failed modules (if any)
  → Display next-steps guidance (shell restart, tool auth)
  → Exit non-zero if any module failed
```

### Platform Detection Rules

| Condition                                                 | `OS`     | `PACKAGE_MANAGER`       |
| --------------------------------------------------------- | -------- | ----------------------- |
| `$OSTYPE` matches `linux-gnu*` AND `apt` is available     | `ubuntu` | `apt`                   |
| `$OSTYPE` matches `linux-gnu*` AND `apt` is NOT available | —        | Script exits with error |
| `$OSTYPE` matches `darwin*`                               | `macos`  | `brew`                  |
| Any other `$OSTYPE`                                       | —        | Script exits with error |

**Homebrew auto-install**: On macOS, if `brew` is not found, the orchestrator MUST install Homebrew automatically. For Apple Silicon Macs, it MUST also add Homebrew shell environment initialization to `~/.zprofile`.

### Package Install Idempotency

| Condition                 | Action                                  |
| ------------------------- | --------------------------------------- |
| Package NOT installed     | Install via appropriate package manager |
| Package already installed | Log success, skip installation          |

### Interactive Menu Behavior

**Profile Menu**: Presents four options (Full, Minimal, Work, Custom) plus Exit (0). Invalid input re-displays the menu.

**Custom Menu**: Presents a toggle list of all modules. User toggles individual modules by number. Includes "Toggle All" and "Done" actions. The menu implementation MUST remain compatible with the system shell on all supported platforms.

**Summary Confirmation**: Displays resolved module list with human-readable labels. Requires `y` or `Y` to proceed. Any other input cancels the installation.

### Command-Line Interface

| Flag                      | Argument                     | Description                                                                    |
| ------------------------- | ---------------------------- | ------------------------------------------------------------------------------ |
| `--profile`               | `full`, `minimal`, `work`    | Select a predefined profile                                                    |
| `--modules`               | comma-separated module names | Select specific modules                                                        |
| `--codex-config-template` | `preserve` or `overwrite`    | Control Codex config template behavior                                         |
| `--code-server-bind`      | `address:port`               | Set or replace the local code-server bind value when `code_server` is selected |
| `--help`                  | —                            | Display help text and exit                                                     |

**Precedence**: CLI arguments override interactive menu. If `--profile` or `--modules` is provided, the interactive menu is skipped entirely.

**Terminology rule**: The `--profile` flag in `install.sh` refers to an installation profile (`full`, `minimal`, `work`), not the Default Profile (VS Code).

**Bind persistence rule**: On first `code_server` installation, absence of `--code-server-bind` selects the default bind. On reruns, absence of the flag preserves the local value. The orchestrator MUST NOT infer or persist hostnames, interface identities, or network-product details in tracked files.

### Module Execution Semantics

- Modules execute sequentially in resolved order
- Standard profile expansion is platform-aware before dependency resolution
- Explicit selection of `vscode` or `vscode_config` outside macOS fails the selected module
- Explicit selection of `code_server` outside Ubuntu/Debian fails the selected module
- `code_server` is never inferred from another module or standard profile
- `beads` is included in Full and Work and omitted from Minimal
- normal module execution installs tools only; it MUST NOT bootstrap, synchronize, migrate, clean, or delete a command repo or legacy Beads data
- command-repo bootstrap and legacy cleanup are explicit operations outside profile expansion
- Each module function returns 0 on success, non-zero on failure
- On failure: the module name is appended to `FAILED_MODULES`, execution continues to the next module
- The script runs in strict failure mode (errors halt execution by default), but module functions catch their own errors and report them to the failure tracker, allowing execution to continue to the next module

### Symlink Management Rules (Cross-Cutting)

The orchestrator delegates symlink creation to per-module functions, but all MUST follow these uniform rules:

| Existing Path Condition                         | Action                                             |
| ----------------------------------------------- | -------------------------------------------------- |
| Symlink pointing to the correct dotfiles target | Remove and recreate (ensure freshness)             |
| Symlink pointing elsewhere                      | Remove, then create new symlink                    |
| Regular file or directory                       | Back up with timestamp suffix, then create symlink |
| Path does not exist                             | Create parent directories, then create symlink     |

**Backup naming**: `{original_path}.backup.{TIMESTAMP}` where `TIMESTAMP` uses `BACKUP_TIMESTAMP_FMT`.

**Exception — Codex config.toml**: This file is COPIED from the dotfiles template, never symlinked, because the agent writes machine-specific values into it. The `CODEX_CONFIG_TEMPLATE_MODE` parameter controls whether an existing copy is preserved or overwritten.

### Fresh Installation vs Update Cache Management

| Condition                                            | Cache Handling                                                                      |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Neovim data directory does NOT exist (fresh install) | Delete `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim` to start clean |
| Neovim data directory EXISTS (update)                | Preserve `~/.local/share/nvim` (Mason packages); delete only `~/.cache/nvim`        |

### Dirty Plugin Cache Cleanup

When Neovim's Lazy plugin sync reports local changes in cached plugins:

| Step | Action                                                                                                  |
| ---- | ------------------------------------------------------------------------------------------------------- |
| 1    | Enumerate all plugin directories under `~/.local/share/nvim/lazy/`                                      |
| 2    | For each directory with a `.git` subdirectory, check for uncommitted changes (`git status --porcelain`) |
| 3    | Remove any plugin directory with dirty state                                                            |
| 4    | Retry Lazy sync once                                                                                    |
| 5    | If retry also fails, log a warning with manual remediation steps                                        |

---

## Error Handling

| Error Case                           | Trigger                                                                           | Detection                      | Response                                                                          | Recovery                                                      |
| ------------------------------------ | --------------------------------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| Unsupported OS                       | Operating system type is not a Linux variant or macOS                             | Platform detection phase       | Print error with detected OS type, exit 1                                         | User must run on Ubuntu/Debian or macOS                       |
| Linux without apt                    | Linux detected but apt package manager not found                                  | Platform detection phase       | Print error, exit 1                                                               | User must install apt or use a supported platform             |
| Module install failure               | A module function signals failure                                                 | Failure tracking               | Append module name to `FAILED_MODULES`, continue execution                        | Report at completion; user re-runs with failed modules        |
| Neovim below minimum version         | Installed Neovim version reports less than 0.10                                   | `configure_neovim` module      | Remove apt version if present, download and install AppImage from GitHub releases | Automatic; fails if download or architecture unsupported      |
| Unsupported CPU architecture         | Detected architecture is not x86_64, aarch64, or arm64                            | Neovim or Go install modules   | Print error, skip module                                                          | User must build from source or use supported hardware         |
| Homebrew install failure             | Homebrew installation script exits non-zero                                       | `setup_package_manager`        | Script exits                                                                      | User troubleshoots Homebrew install manually                  |
| Lazy sync dirty cache                | `Lazy! sync` reports local changes in plugins                                     | Plugin sync phase              | Clean dirty plugin caches, retry once                                             | Automatic; manual Lazy sync if retry fails                    |
| Mason package install failure        | MasonInstall command exits non-zero                                               | Mason installation phase       | Print warning with manual remediation command                                     | User runs `:Mason` inside Neovim                              |
| npm not found for agent install      | Node.js/npm is not available when installing Codex or Pi                          | Dependency resolver            | Auto-add `nodejs` module to resolved list                                         | Automatic; user notified via warning message                  |
| Docker not found for Pi sandbox      | Docker command not found when installing `pi_sandbox`                             | `install_pi_sandbox` module    | Print error, skip module                                                          | User must install Docker separately before re-running         |
| Docker not found for Codex sandbox   | Docker command not found when installing `codex_sandbox`                          | `install_codex_sandbox` module | Print error, skip module                                                          | User must install Docker separately before re-running         |
| Herdr install failure                | Herdr direct installer exits non-zero or `herdr` remains unavailable              | `herdr` module                 | Append `herdr` to failed modules; continue with remaining modules                 | Check network/PATH and re-run install                         |
| Herdr integration target missing     | A managed agent config directory does not exist when `herdr_integrations` runs    | `herdr_integrations` module    | Skip that agent integration and continue                                          | Install the relevant agent module and re-run                  |
| Go version fetch failure             | Version endpoint returns empty result                                             | `install_golang` module        | Print error, signal module failure                                                | Module fails; user retries or installs Go manually            |  | PATH conflict for npm-installed agents | The agent binary is found via PATH but not at `~/.local/bin/` | Post-install verification | Print warning identifying the conflicting binary path | User must ensure `~/.local/bin` is earlier in PATH |
| Codex config symlink detected        | Existing `~/.codex/config.toml` is a symlink                                      | `install_codex` module         | Remove symlink, copy template as regular file                                     | Automatic; local config file created from template            |
| Unsupported desktop editor selection | `vscode` or `vscode_config` explicitly selected outside macOS                     | Module platform gate           | Append selected module to failures; install no substitute editor                  | Select supported platform/module                              |
| Unsupported code-server selection    | `code_server` explicitly selected outside Ubuntu/Debian                           | Module platform gate           | Append module to failures; create no service                                      | Select supported platform/module                              |
| Invalid code-server bind             | Bind lacks valid address and port shape                                           | Argument validation            | Exit before module execution with usage guidance                                  | Correct flag value                                            |
| code-server port conflict            | Selected local port is occupied                                                   | Module preflight/startup       | Append module to failures; do not choose alternate                                | Stop conflict or pass explicit bind                           |
| Required VS Code extension failure   | One or more manifest entries fail after all are attempted                         | Extension reconciliation       | Append owning module to failures and list every failed extension                  | Correct manifest/marketplace or rerun                         |
| Python below required version        | Native interpreter reports less than 3.10                                         | `python` module verification   | Append `python` to failures; add no third-party repository                        | Upgrade supported OS/package source                           |
| Beads provisioning failure           | Stable installer, `bd version` minimum, or embedded-capability verification fails | `beads` module                 | Append `beads`; preserve every command-repo path                                  | Repair network/PATH and rerun                                 |
| Bootstrap selected implicitly        | Profile or normal module execution would create command-repo state                | Orchestrator boundary check    | Refuse implicit bootstrap and complete tool installation only                     | Run the explicit bootstrap operation with path and remote URL |

---

## Implementation Notes

1. **Shell compatibility**: The interactive menu system uses indexed arrays (parallel arrays), not associative arrays, to remain compatible with the default shell on all supported platforms (including macOS). All module menus and selection state MUST use indexed arrays.

2. **Idempotency contract**: Every module function MUST be safe to run multiple times. The script MUST NOT fail, produce errors, or cause data loss when re-run with already-installed state. This is achieved through:
   - Checking for existing installations before installing, except for tools such as Claude Code that delegate idempotent updates to their official installer
   - Backing up (never overwriting) existing non-symlink configuration files
   - Removing and recreating symlinks to ensure they point to the correct target

3. **Platform branching pattern**: All platform-specific logic uses `if [ "$OS" == "ubuntu" ]` / `elif [ "$OS" == "macos" ]` branching. The `OS` variable is set once during detection and referenced throughout. No module function should re-detect the platform.

4. **Module isolation**: Each module function is self-contained — it performs its own prerequisite checks (e.g., checking if `npm` exists before installing an npm package). The dependency resolver adds modules to the execution list but does not skip internal prerequisite checks.

5. **Global install prefix**: npm-based global tools (Codex and Pi) MUST be installed with `--prefix` pointing to `NPM_GLOBAL_PREFIX` (`~/.local`) to ensure they survive fnm Node version switches. The resulting binaries land in `~/.local/bin/`. Claude Code and Copilot CLI use curl-based installers instead of npm (see Tool Provisioning spec for installer type details).

6. **Herdr default replacement**: Herdr, Herdr config, and Herdr integrations are included in every standard installation profile. Tmux remains in every standard profile during migration as a fallback, but SSH defaults are governed by the shell config's Herdr-first multiplexer rule.

7. **Architecture detection**: Ubuntu modules detect `x86_64` → `amd64` and `aarch64`/`arm64` → `arm64` for binary downloads. macOS uses Homebrew's architecture-aware install. Unsupported architectures cause module failure with an error message.

8. **Temp directory cleanup**: All download operations MUST use a temporary directory and MUST clean it up (remove all contents) on both success and failure paths. No temporary files should leak.

9. **Version comparison**: Version comparisons MUST use semantic version ordering (so that e.g. 0.9 < 0.10). The Neovim version check on Ubuntu uses floating-point comparison (`bc -l`), while the Go version check uses version-sort comparison.

10. **In-place file edits**: File modifications MUST use platform-appropriate in-place editing. The implementation details differ between macOS and Ubuntu/Debian.

11. **Git config prompting**: Git user.name and user.email prompting is described in AGENTS.md but is **not currently implemented** in the install script. This feature may be added in a future version; for now, users must configure git identity manually.

12. **Shell test suite**: Install-script unit tests MUST be runnable through `bash tests/run.sh`. The runner MUST syntax-check the runner, shared harness, and all top-level `tests/*.test.sh` files before execution. It MUST discover top-level `tests/*.test.sh` files in sorted order so new install-script tests are included by convention. Shared shell-test helpers SHOULD live in `tests/lib/harness.sh` to keep individual test files focused on behavior.

13. **Platform-aware profiles**: Standard profiles define common modules plus macOS editor additions. Unsupported modules are omitted during profile expansion, while explicit unsupported selections remain errors.

14. **Manual Settings Sync action**: The desktop completion report MUST state that Settings Sync must be disabled manually. It MUST NOT claim unsupported enforcement.

15. **Private network neutrality**: Argument parsing and completion output MAY identify a generic bind value and local config path but MUST NOT name or configure a private-network product.

16. **Execution tools are not execution state**: Full and Work provision Beads, but profile execution never creates the private command repo, writes its runtime path, synchronizes its remote, or removes legacy data.

---

## Test Scenarios

### TS-INSTL-001: Full Profile Installs All Modules
Category: End-to-End
Priority: Critical
Preconditions: Fresh Ubuntu machine with apt available, no prior dotfiles installation
Input: `--profile full`
Expected Output: All standard full-profile modules, including Herdr modules, are resolved and executed. `FAILED_MODULES` is empty. No backup files created (fresh system). All symlinks point to dotfiles repo.

### TS-INSTL-002: Minimal Profile Installs Only Editors
Category: End-to-End
Priority: Critical
Preconditions: Fresh system, no prior installation
Input: `--profile minimal`
Expected Output: Only `base_tools`, `neovim`, `nvim_config`, `tmux_config`, `herdr`, `herdr_config`, and `herdr_integrations` are resolved and executed. No AI agent or TUI tool modules run, and integrations skip missing agent configs.

### TS-INSTL-003: Dependency Resolution Adds Missing Prerequisites
Category: Integration
Priority: Critical
Preconditions: User selects `nvim_config` but not `neovim` or `base_tools`; `git` and `nvim` are NOT installed on the system
Input: `--modules nvim_config`
Expected Output: `resolve_dependencies` adds `base_tools` and `neovim` before `nvim_config`. Final list: `base_tools`, `neovim`, `nvim_config`.

### TS-INSTL-004: Dependency Deduplication Preserves Order
Category: Unit
Priority: High
Preconditions: User selects both `pi` (requires `nodejs`) and `codex` (requires `nodejs`); `npm` is NOT installed
Input: `--modules pi,codex`
Expected Output: `nodejs` appears exactly once in the resolved list, before both `pi` and `codex`.

### TS-INSTL-005: Idempotent Re-Run Skips Existing Installations
Category: Integration
Priority: Critical
Preconditions: Full profile already installed
Input: `--profile full` (second run)
Expected Output: Module functions either detect existing installations and log "already installed" messages, or run an idempotent official updater such as Claude Code's `latest` installer. No backups are created for already-symlinked configs. No data loss.

### TS-INSTL-006: Symlink Conflict Creates Timestamped Backup
Category: Unit
Priority: High
Preconditions: Regular file exists at `~/.tmux.conf` (not a symlink)
Input: Module `tmux_config`
Expected Output: Existing `~/.tmux.conf` moved to `~/.tmux.conf.backup.{TIMESTAMP}`. New symlink created pointing to dotfiles repo.

### TS-INSTL-007: Existing Symlink Is Replaced Not Backed Up
Category: Unit
Priority: High
Preconditions: Symlink already exists at `~/.tmux.conf`
Input: Module `tmux_config`
Expected Output: Old symlink removed (no backup). New symlink created with correct target. No `.backup` file generated.

### TS-INSTL-008: Unsupported OS Exits With Error
Category: Unit
Priority: Critical
Preconditions: `$OSTYPE` is neither `linux-gnu*` nor `darwin*`
Input: Run install script
Expected Output: Error message printed with actual `$OSTYPE` value. Script exits with code 1.

### TS-INSTL-009: Linux Without Apt Exits With Error
Category: Unit
Priority: Critical
Preconditions: `$OSTYPE` matches `linux-gnu*` but `apt` is not found
Input: Run install script
Expected Output: Error message stating apt is required. Script exits with code 1.

### TS-INSTL-010: Module Failure Does Not Halt Other Modules
Category: Integration
Priority: High
Preconditions: Go binary download fails (network error)
Input: `--modules golang_full,tmux_config`
Expected Output: `golang_full` is added to `FAILED_MODULES`. `tmux_config` still executes and succeeds. Completion report shows both failed and succeeded modules.

### TS-INSTL-011: Codex Config Template Preserve Mode
Category: Unit
Priority: Medium
Preconditions: `~/.codex/config.toml` already exists as a regular file; `CODEX_CONFIG_TEMPLATE_MODE=preserve`
Input: Module `codex`
Expected Output: Existing `config.toml` is untouched. No overwrite, no backup created.

### TS-INSTL-012: Codex Config Template Overwrite Mode
Category: Unit
Priority: Medium
Preconditions: `~/.codex/config.toml` already exists as a regular file; `CODEX_CONFIG_TEMPLATE_MODE=overwrite`
Input: Module `codex` with `--codex-config-template overwrite`
Expected Output: Existing `config.toml` backed up with timestamp. Template copied from dotfiles repo to replace it.

### TS-INSTL-013: Codex Config Symlink Converted To Local File
Category: Unit
Priority: Medium
Preconditions: `~/.codex/config.toml` is a symlink to the dotfiles template
Input: Module `codex`
Expected Output: Symlink removed. Template copied as a regular file in its place. Log message indicates conversion.

### TS-INSTL-014: Interactive Menu Cancel Exits Cleanly
Category: Integration
Priority: Medium
Preconditions: No `--profile` or `--modules` flags
Input: User selects profile 0 (Exit) at profile menu
Expected Output: Script prints "Installation cancelled" and exits with code 0.

### TS-INSTL-015: Summary Confirmation Declined
Category: Integration
Priority: Medium
Preconditions: Modules selected (any method)
Input: User presses `n` at confirmation prompt
Expected Output: Script prints "Installation cancelled" and exits with code 0. No modules executed.

### TS-INSTL-016: Neovim Fresh Install Clears All Caches
Category: Unit
Priority: High
Preconditions: `~/.local/share/nvim/lazy` does NOT exist (no prior Neovim installation)
Input: Module `nvim_config`
Expected Output: Three directories are deleted: `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim`.

### TS-INSTL-017: Neovim Update Preserves Mason Data
Category: Unit
Priority: High
Preconditions: `~/.local/share/nvim/lazy` directory exists (prior installation)
Input: Module `nvim_config`
Expected Output: Only `~/.cache/nvim` is deleted. `~/.local/share/nvim` and `~/.local/state/nvim` are preserved.

### TS-INSTL-018: Kickstart Nvim Update Preserves Custom Layer
Category: Integration
Priority: High
Preconditions: `~/.config/nvim/.git` exists with remote URL matching official kickstart.nvim
Input: Module `nvim_config`
Expected Output: `git fetch origin` and `git reset --hard origin/master` are executed. The custom layer symlink at `~/.config/nvim/lua/custom` is preserved (not deleted by the git reset).

### TS-INSTL-019: Kickstart Custom Plugin Import Enabled
Category: Unit
Priority: High
Preconditions: `~/.config/nvim/init.lua` contains commented-out `-- { import = 'custom.plugins' },`
Input: Module `nvim_config`
Expected Output: The line is uncommented to `{ import = 'custom.plugins' },`. This is persistent across re-runs.

### TS-INSTL-020: Dirty Lazy Plugin Cache Cleanup And Retry
Category: Unit
Priority: Medium
Preconditions: `Lazy! sync` fails with "You have local changes" error
Input: Module `nvim_config`
Expected Output: Dirty plugin directories are removed, Lazy sync is retried once. If retry succeeds, log success. If retry fails, log warning with manual command.

### TS-INSTL-021: Agent Install Auto-Adds Node.js Dependency
Category: Integration
Priority: High
Preconditions: `npm` is not found on the system
Input: `--modules pi`
Expected Output: Dependency resolver detects missing `npm` and adds `nodejs` before `pi` in the resolved list. `install_nodejs` runs first, then `install_pi`.

### TS-INSTL-022: PATH Conflict Warning For Agent Binary
Category: Unit
Priority: Medium
Preconditions: A `codex` binary exists on PATH at a location other than `~/.local/bin/codex`
Input: Module `codex`
Expected Output: Warning message printed showing the conflicting binary path. Installation still proceeds to `~/.local/bin/codex`.

### TS-INSTL-023: macOS Homebrew Auto-Install
Category: Unit
Priority: High
Preconditions: macOS system, `brew` command not found
Input: Phase 2 (platform detection)
Expected Output: Homebrew installed via official install script. For Apple Silicon, shell environment initialization appended to `~/.zprofile`. `brew update` runs after install.

### TS-INSTL-024: Architecture Detection For Binary Downloads
Category: Unit
Priority: High
Preconditions: Ubuntu, `uname -m` returns `aarch64`
Input: Module `neovim` or `golang`
Expected Output: Correct ARM64 binary variant is selected for download (e.g., `nvim-linux-arm64.appimage` for Neovim, `linux-arm64` tarball for Go).

### TS-INSTL-025: Completion Report Lists Failed Modules
Category: Integration
Priority: High
Preconditions: One or more modules failed during execution
Input: Any profile where at least one module fails
Expected Output: Completion summary shows `✗` for each failed module and `✓` for each succeeded module. Exit code is 1.

### TS-INSTL-026: Completion Report Success
Category: Integration
Priority: Medium
Preconditions: All modules succeeded
Input: Any successful profile
Expected Output: Completion summary shows `✓` for every module. No failure section displayed. Exit code is 0.

### TS-INSTL-027: Custom Module Selection Toggle
Category: Integration
Priority: Medium
Preconditions: No CLI flags; interactive mode entered
Input: User selects profile 4 (Custom), toggles modules 1 and 5, then selects Done
Expected Output: Only the toggled modules appear in the resolved and confirmed lists.

### TS-INSTL-028: Agent Skills Directories Linked
Category: Integration
Priority: High
Preconditions: Multiple agent modules selected (e.g., `claude`, `pi`, `codex`, `copilot`)
Input: `--modules claude,pi,codex,copilot`
Expected Output: Claude, Codex, and Copilot skills directory symlinks point to `~/dotfiles/shared/skills/`. Pi's skills directory resolves through `~/.pi/agent/skills` to `~/dotfiles/pi/skills`.

### TS-INSTL-029: Herdr Present In Every Standard Profile
Category: Integration
Priority: Critical
Preconditions: Fresh system; Herdr is not installed
Input: Run each standard installation profile (`full`, `minimal`, `work`)
Expected Output: Each profile resolves `herdr`, `herdr_config`, and `herdr_integrations`. Herdr config is deployed, and missing agent integration targets are skipped without failing minimal/work profiles.

### TS-INSTL-030: Shell Test Runner Discovers Install Tests
Category: Unit
Priority: High
Preconditions: Top-level shell tests exist under `tests/*.test.sh`
Input: `bash tests/run.sh`
Expected Output: The runner syntax-checks shell test files, executes each top-level `*.test.sh` file in sorted order, reports per-file execution, and exits non-zero if syntax checking or any test file fails.

### TS-INSTL-031: macOS profiles include desktop editor
Category: Integration
Priority: Critical
Preconditions: macOS platform
Input: Expand `full` and `work` profiles
Expected Output: Both include python, vscode, and vscode_config; minimal omits all three except its existing modules

### TS-INSTL-032: Linux profiles omit desktop editor
Category: Integration
Priority: Critical
Preconditions: Ubuntu/Debian platform
Input: Expand all standard profiles
Expected Output: Full and work include python but omit vscode and vscode_config; no standard profile includes code_server

### TS-INSTL-033: code-server is explicit only
Category: Unit
Priority: Critical
Preconditions: Any supported profile selection
Input: Resolve dependencies and execute profiles
Expected Output: code_server appears only when explicitly selected through Custom or `--modules`

### TS-INSTL-034: code-server bind first install and preservation
Category: Integration
Priority: Critical
Preconditions: Supported Ubuntu/Debian host
Input: First run with explicit bind, then rerun without bind flag
Expected Output: Explicit value is stored locally and preserved on rerun; no address or hostname enters tracked files

### TS-INSTL-035: Unsupported editor modules fail explicitly
Category: Unit
Priority: High
Preconditions: Ubuntu/Debian for desktop case; macOS for server case
Input: Explicit unsupported module selection
Expected Output: Selected module is reported failed; no substitute editor or service is installed; unrelated modules continue

### TS-INSTL-036: Python module is independently selectable
Category: Integration
Priority: High
Preconditions: Supported platform without Python 3.10+
Input: `--modules python`
Expected Output: Native baseline is installed and verified without selecting an editor module

### TS-INSTL-037: Desktop completion reports manual Settings Sync action
Category: Unit
Priority: High
Preconditions: macOS vscode_config succeeds
Input: Completion report
Expected Output: Report requires manual Settings Sync disablement and does not claim persistent installer enforcement

### TS-INSTL-038: Execution Coordination Tools By Profile
Category: Integration
Priority: Critical
Preconditions: Supported platform without bd
Input: Expand Full, Work, and Minimal profiles
Expected Output: Full and Work include beads; Minimal omits it; no profile selects a Dolt module

### TS-INSTL-039: Explicit Beads Module Resolves Its Prerequisites
Category: Integration
Priority: High
Preconditions: bd is absent
Input: `--modules beads`
Expected Output: Dependency resolution adds `base_tools` only when curl is missing and selects no Dolt module

### TS-INSTL-040: Normal Install Preserves Operational State
Category: Integration
Priority: Critical
Preconditions: Legacy Beads data and an existing private command repo are present
Input: Run Full and Work profiles
Expected Output: Tools install/update successfully while no command-repo bootstrap, sync, migration, legacy deletion, or runtime-path rewrite occurs

---

## Changelog

| Version | Date       | Summary                                                                                                                                                                                                     |
| ------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2.1.0   | 2026-08-02 | Removed the `dolt` module after adopting single-writer embedded Beads storage; `beads` now depends only on `base_tools`.                                                                                    |
| 2.0.0   | 2026-08-01 | Added Beads and Dolt modules to Full and Work, preserved Minimal, and separated tool installation from command-repo bootstrap and legacy cleanup.                                                           |
| 1.6.0   | 2026-07-31 | Added platform-aware macOS Visual Studio Code modules, explicit Ubuntu/Debian code-server, Python 3.10+ provisioning, bind override semantics, extension failure handling, and manual Settings Sync action. |
| 1.5.0   | 2026-07-15 | Made Claude settings local runtime state and added jq-backed status-line configuration.                                                                                                                     |
| 1.4.0   | 2026-07-15 | Made Pi settings local runtime state and required content-preserving migration from the former repo-managed symlink.                                                                                        |
| 1.3.2   | 2026-07-06 | Added the shell test suite contract: `bash tests/run.sh` discovers top-level shell tests, syntax-checks them, and uses a shared harness for install-script unit tests.                                      |
| 1.3.1   | 2026-07-06 | Clarified idempotency wording for modules that run official updater paths such as Claude Code's `latest` installer.                                                                                         |
| 1.3.0   | 2026-07-05 | Added Herdr modules, included Herdr in every standard installation profile, specified Herdr integration skip behavior, and documented the Herdr default replacement migration rule.                         |
| 1.2.0   | 2026-06-02 | Added Pi deployment requirements.                                                                                                                                                                           |
| 1.1.0   | 2026-05-19 | Updated skills deployment expectations for Pi's composed skills directory                                                                                                                                   |
| 1.0.0   | 2026-05-01 | Initial spec: orchestration flow, phase ordering, platform branching, dependency resolution, idempotency rules, error handling, interactive/CLI modes                                                       |

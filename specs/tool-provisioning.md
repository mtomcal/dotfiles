# Tool Provisioning

> **Version**: 1.5.0
> **Last Updated**: 2026-08-01
> **Depends On**: [Parameters](parameters.md), [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md), [Design Language](DESIGN_LANGUAGE.md), [Symlink Manager](symlink-manager.md)
> **Depended By**: [VS Code Configuration](vscode-config.md), [Execution Coordination](execution-coordination.md), Install Orchestrator

---

## Overview

The Tool Provisioning system is responsible for installing, upgrading, and verifying all external tools and packages required by the dotfiles environment. It operates across two platforms (Ubuntu/Debian via apt, macOS via Homebrew) and installs three categories of software:

1. **System packages** — installed via the native package manager (apt or brew)
2. **Downloaded binaries** — fetched from upstream release URLs with architecture detection and placed in system or user-local paths
3. **Mason packages** — LSP servers, formatters, and linters installed inside Neovim via headless Mason commands
4. **Direct upstream installers** — official curl installers for selected user-local tools whose update path is owned by the tool itself
5. **Editor distributions and runtimes** — platform-scoped Visual Studio Code, code-server, and baseline Python provisioning
6. **Execution-coordination tools** — stable Beads CLI plus Dolt for concurrent command-repo storage

The system is **idempotent**: every function either checks whether the tool is already present and at a satisfactory version before attempting installation, or delegates idempotent update behavior to the tool's official installer. Re-running the full install produces the same result without errors, warnings, or unnecessary side effects.

For Pi, tool provisioning installs one shared Pi binary. Profile-specific behavior is provided by deployed runtime configs and wrapper commands, not separate binary installs per profile.

The Python, Visual Studio Code Desktop, code-server, Beads, Dolt, command-repo bootstrap, and legacy cleanup clauses introduced after the current implementation are approved desired behavior and are not yet implemented.

---

## Dependencies

### Technology Dependencies

- A supported operating system: Ubuntu/Debian with apt, or macOS with Homebrew
- Internet connectivity for package manager updates, binary downloads, and git clones
- `curl` and `wget` for downloading files
- `git` for cloning and updating repositories
- Utility for floating-point version comparison (used for Neovim version checking on Ubuntu/Debian)
- Neovim with Mason for LSP/formatter/linter installation (lazy-loaded: only required when `nvim_config` or `golang_full` modules are selected)

### Spec Dependencies

- [Parameters](parameters.md) — all tuning values (`REQUIRED_NVIM_VERSION`, `REQUIRED_GO_VERSION`, `NODE_LTS_VERSION`, `MASON_TOOLS_GO`, `MASON_TOOLS_PYTHON`, `BACKUP_TIMESTAMP_FMT`)
- [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md) — terms: install, install (dependency), install (Mason), TUI tool, LSP server, formatter, deploy, backup, idempotent
- [Design Language](DESIGN_LANGUAGE.md) — CLI output tokens: `phase-header-fmt`, `success-msg`, `warning-msg`, `error-msg`

---

## Parameters

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| `REQUIRED_NVIM_VERSION` | 0.10 | major.minor | Minimum Neovim version that supports all features in kickstart.nvim and custom plugins; triggers AppImage download on Ubuntu if below threshold |
| `REQUIRED_GO_VERSION` | 1.24 | major.minor | Required by gofumpt formatter and govulncheck; triggers upgrade path if detected version is below threshold |
| `NODE_LTS_VERSION` | LTS | version selector | fnm installs the current LTS release for stability; AI CLI tools do not need bleeding-edge Node |
| `MASON_TOOLS_PYTHON` | stylua, ruff, pyright, prettier, eslint_d | list | Base language support installed during Neovim configuration; includes Lua formatting, Python linting/type-checking, and JS/TS formatting |
| `MASON_TOOLS_GO` | gopls, delve, gofumpt, goimports | list | Go development toolchain: language server, debugger, formatter, import manager; installed only when golang_full module is selected |
| `BACKUP_TIMESTAMP_FMT` | %Y%m%d_%H%M%S | strftime format | Timestamps on backup files must be sortable chronologically and granular to seconds |
| `NPM_GLOBAL_PREFIX` | ~/.local | path | npm global install prefix shared across fnm Node versions; ensures CLI tools survive fnm version switches |
| `GO_INSTALL_PATH` | /usr/local/go | path | Official Go binary installation directory on Ubuntu/Debian |
| `GO_WORKSPACE` | ~/go-workspace | path | Go workspace directory (GOPATH); must be on PATH alongside Go install path; binaries installed via `go install` land in `~/go-workspace/bin/` |
| `FNM_INSTALL_SCRIPT` | https://fnm.vercel.app/install | URL | Official fnm install script; not available via apt/brew on all platforms |
| `HERDR_INSTALL_SCRIPT` | https://herdr.dev/install.sh | URL | Official Herdr direct installer; used on Linux and macOS to keep `herdr update` as the consistent update path |
| `PYTHON_REQUIRED_VERSION` | 3.10 | major.minor | Native-package baseline for modern editor and project compatibility |
| `PYTHON_UBUNTU_PACKAGES` | python3, python3-venv | list | Distro interpreter and virtual-environment support without third-party repositories |
| `PYTHON_MACOS_PACKAGE` | python | Homebrew formula | Current stable interpreter without replacing system Python |
| `VSCODE_MACOS_CASK` | visual-studio-code | Homebrew Cask | Official stable desktop distribution on macOS |
| `CODE_SERVER_INSTALL_SCRIPT` | https://code-server.dev/install.sh | URL | Official stable code-server installation and update path on Ubuntu/Debian |
| `CODE_SERVER_BIND_DEFAULT` | 0.0.0.0:8080 | address:port | First-install private-network listener default |
| `BEADS_INSTALL_SCRIPT` | https://raw.githubusercontent.com/gastownhall/beads/main/scripts/install.sh | URL | Official checksum-verifying stable Beads release channel for Linux and macOS |
| `DOLT_INSTALL_SCRIPT_LINUX` | https://github.com/dolthub/dolt/releases/latest/download/install.sh | URL | Official stable Dolt installer for Ubuntu/Debian |
| `DOLT_MACOS_PACKAGE` | dolt | Homebrew formula | Official stable Dolt package for macOS |
| `BEADS_COMMAND_CONFIG_PATH` | ~/.config/beads-command/env | path | Local runtime record written only by explicit command-repo bootstrap |

---

## Data Structures

### Platform

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `os` | enum | ubuntu, macos | Detected operating system |
| `package_manager` | enum | apt, brew | Package manager derived from OS detection |
| `architecture` | enum | x86_64, aarch64 | CPU architecture from `uname -m`, mapped for binary downloads |

### Architecture Mapping

| uname -m output | Neovim AppImage suffix | Go binary suffix | lazygit archive suffix | yazi archive suffix |
|-----------------|----------------------|-------------------|----------------------|---------------------|
| x86_64 | nvim-linux-x86_64.appimage | amd64 | Linux_x86_64 | x86_64-unknown-linux-gnu |
| aarch64 | nvim-linux-arm64.appimage | arm64 | Linux_arm64 | aarch64-unknown-linux-gnu |
| arm64 | nvim-linux-arm64.appimage | arm64 | Linux_arm64 | aarch64-unknown-linux-gnu |

### Package Name Mapping

Packages with different names across platforms MUST use the `install_package` function's second parameter to specify the brew name when it differs from the apt name.

| apt name | brew name | Notes |
|----------|-----------|-------|
| fd-find | fd | Ubuntu ships fd as fd-find; macOS uses fd directly |
| build-essential | gcc | Both provide C compiler; Ubuntu uses meta-package, macOS uses gcc formula |
| xclip | — | Clipboard support; macOS not needed |
| python3 | python | Baseline Python interpreter; Ubuntu uses distro package, macOS uses Homebrew formula |
| python3-venv | — | Python virtual environments; macOS Homebrew Python includes venv support |
| tree-sitter-cli | tree-sitter-cli | CLI split from library in 0.26+; macOS only |

### Tool Download Specification

| Tool | Ubuntu method | macOS method | Version source |
|------|-------------|-------------|---------------|
| Neovim | GitHub AppImage (latest stable) | Homebrew (install or upgrade) | GitHub releases list (excluding nightly/stable tags) |
| Go | Official tarball from go.dev | Homebrew (install or upgrade) | go.dev VERSION endpoint |
| fnm | curl \| bash install script | same as Ubuntu | N/A (script manages version) |
| Node.js | fnm install --lts | same as Ubuntu | fnm resolves LTS |
| lazygit | GitHub release tarball (architecture-specific) | Homebrew | GitHub `/releases/latest` endpoint `tag_name` field |
| yazi | GitHub release zip (architecture-specific) | Homebrew | GitHub `/releases/latest` endpoint `tag_name` field |
| zoxide | curl \| sh install script | Homebrew | N/A (script manages version) |
| Herdr | curl \| sh installer | curl \| sh installer | Herdr stable channel; update via `herdr update` |
| Codex CLI | npm global install (NPM_GLOBAL_PREFIX) | same as Ubuntu | npm resolves @latest |
| Pi Coding Agent | npm global install (NPM_GLOBAL_PREFIX) | same as Ubuntu | npm resolves @latest |
| Playwright CLI | npm global install (no prefix — inconsistent) | same as Ubuntu | npm resolves @latest |
| Copilot CLI | curl \| bash installer | same as Ubuntu | Official installer script; binary lands in ~/.local/bin |
| Claude Code | curl \| bash installer with `latest` target | same as Ubuntu | Official installer script resolves latest release; binary lands in ~/.local/bin |
| Visual Studio Code Desktop | Unsupported | Homebrew Cask install/upgrade | Homebrew stable Cask release |
| code-server | Official direct installer | Unsupported | Official installer stable release |
| Beads | Official checksum-verifying direct installer | Same as Ubuntu | Official stable GitHub release |
| Dolt | Official direct installer | Homebrew formula | Official stable release |

### Mason Package Set

| Set | Packages | When installed |
|-----|----------|---------------|
| Python base | stylua, ruff, pyright, prettier, eslint_d | Always during Neovim configuration |
| Go development | gopls, delve, gofumpt, goimports | Only when golang_full module is selected AND Neovim is present |

### Version Check Result

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `tool_name` | string | required | Name of the tool being checked |
| `installed_version` | string | optional | Parsed version number; empty if tool not found |
| `meets_requirement` | boolean | required | Whether installed version satisfies the minimum |
| `action` | enum | install, upgrade, skip | Determined action based on version check |

### Module Dependency

| Module | Requires | Reason |
|--------|----------|--------|
| nvim_config | git, neovim | Config clone needs git; Mason commands need nvim binary |
| zsh_ohmyzsh | zsh, git | Oh My Zsh clone needs git and zsh |
| tmux_config | tmux | Config deployment needs tmux installed |
| herdr | curl | Direct installer download |
| herdr_config | herdr | Config deployment assumes Herdr can be launched after install |
| herdr_integrations | herdr, relevant agent configs | Repo-owned integration source generation/deployment |
| zsh_config | zsh | Shell config sourcing needs zsh |
| claude | curl, jq | Installer needs curl; local settings updates need jq |
| pi | npm | npm global install for Pi binary |
| codex | npm | npm global install for Codex binary |
| copilot | curl | Installer needs curl |
| playwright | npm | npm global install for Playwright CLI |
| sandbox_base | docker | Shared Docker base image for agent sandboxes |
| pi_sandbox | docker | Sandbox runs in Docker container |
| codex_sandbox | docker | Codex `--yolo` sandbox runs in Docker container |
| python | native package manager | Baseline interpreter and venv support |
| vscode | Homebrew | Official desktop Cask; macOS only |
| vscode_config | vscode when desktop command is absent | Managed desktop files and extension CLI require Visual Studio Code |
| code_server | curl, service manager | Official installer, persistent service, and HTTPS verification; Ubuntu/Debian only |
| dolt | curl on Ubuntu/Debian; Homebrew on macOS | Required for Beads server mode and private-remote synchronization |
| beads | dolt, curl | Beads CLI requires the Dolt command surface selected for execution coordination |

### Pi Command Surface

The Pi binary is installed once, but the provisioning system MUST ensure the following command surface exists after the `pi` module deploys config:

| Command | Backing behavior |
|---------|------------------|
| `pi` | Launch Pi against `~/.pi/agent` |
| `pis` | Launch sandboxed Pi against `~/.pi/agent` |

---

## Behavior

### OS Detection

```
IF OSTYPE matches linux-gnu* AND apt is available
    SET os = ubuntu, package_manager = apt
ELSE IF OSTYPE matches darwin*
    SET os = macos, package_manager = brew
ELSE
    EMIT error "Unsupported operating system"
    EXIT with failure
```

### Package Manager Setup

```
IF os = macos AND brew not found
    INSTALL Homebrew via official script
    IF architecture = arm64
        APPEND Homebrew shell eval to ~/.zprofile
        EVAL Homebrew shell env for current session
    END IF
END IF
```

### Package Installation (install_package)

```
FUNCTION install_package(apt_name, brew_name DEFAULTS TO apt_name):
    IF package_manager = apt
        IF dpkg shows apt_name as installed
            EMIT success "already installed"
            RETURN
        ELSE
            INSTALL via apt install -y apt_name
        END IF
    ELSE IF package_manager = brew
        IF brew list shows brew_name as installed
            EMIT success "already installed"
            RETURN
        ELSE
            INSTALL via brew install brew_name
        END IF
    END IF
```

**Key rule**: The idempotency check MUST use the correct tool per platform. The apt path MUST check `dpkg -l`; the brew path MUST check `brew list`. Both checks MUST emit a success confirmation when the package is already present.

### Version Comparison

Two version comparison mechanisms are used:

**Go version comparison** uses version-sort ordering:
```
FUNCTION version_lt(a, b):
    RETURN version-sorted list of [a, b] has a as the first element AND a ≠ b
```
This ensures `0.9 < 0.10` evaluates correctly (unlike lexicographic string comparison).

**Neovim version comparison** on Ubuntu uses floating-point arithmetic comparison (`bc -l`):
```
FUNCTION nvim_version_below_required(version, required):
    RETURN (version < required) evaluates to true via floating-point comparison
```
This handles simple major.minor version comparisons (e.g., `0.9 < 0.10`). If version parsing or comparison fails, the function MUST treat the installed version as `0.0` to trigger a safe upgrade.

### Neovim Installation

```
IF os = ubuntu
    IF nvim is found
        EXTRACT major.minor version
        IF version < REQUIRED_NVIM_VERSION
            REMOVE any apt-installed neovim (best-effort, ignore failure)
            FETCH latest stable version tag from GitHub releases API (exclude nightly/stable tags)
            DETECT architecture
            DOWNLOAD matching AppImage to temp directory
            IF /usr/local/bin is writable
                MOVE AppImage to /usr/local/bin/nvim
            ELSE
                CREATE ~/.local/bin if needed
                MOVE AppImage to ~/.local/bin/nvim
                WARN user to add ~/.local/bin to PATH if not present
            END IF
            VERIFY installed version via nvim --version
        ELSE
            EMIT success "version meets requirements"
        END IF
    ELSE
        PERFORM same download-and-install path as above
    END IF
ELSE IF os = macos
    IF neovim not in brew
        INSTALL via brew install neovim
    ELSE
        UPGRADE via brew upgrade neovim (suppress error if already latest)
    END IF
END IF
```

**Architecture detection** for Neovim on Ubuntu: map `uname -m` → `x86_64` uses `nvim-linux-x86_64.appimage`, `aarch64` or `arm64` uses `nvim-linux-arm64.appimage`. Unsupported architectures MUST cause the function to return failure.

**Critical rule**: The GitHub API query MUST exclude `nightly` and `stable` tags, selecting only the latest versioned release.

### Go Installation

```
IF os = macos
    IF go not found
        INSTALL via brew install go
    ELSE IF go version < REQUIRED_GO_VERSION
        IF go was installed via brew
            UPGRADE via brew upgrade go
        ELSE
            INSTALL via brew install go
        END IF
    ELSE
        EMIT success "already installed and meets version"
    END IF
ELSE IF os = ubuntu
    IF go not found
        DETECT architecture: x86_64 → amd64, aarch64/arm64 → arm64
        FETCH latest Go version from go.dev VERSION endpoint
        DOWNLOAD matching tarball to temp directory
        IF GO_INSTALL_PATH exists
            REMOVE previous installation
        END IF
        EXTRACT tarball to /usr/local
        CLEANUP temp directory
    ELSE IF go version < REQUIRED_GO_VERSION
        EMIT warning "version below recommended"
    ELSE
        EMIT success "already installed and meets version"
    END IF
END IF

UNSET GOROOT (prevent stale GOROOT from poisoning go binary)
IF os = macos
    PREPEND brew go bin directory to PATH
END IF
SET GOPATH to GO_WORKSPACE value
ENSURE GO_WORKSPACE/bin exists
IF os = ubuntu
    PREPEND GO_INSTALL_PATH/bin to PATH
END IF
PREPEND GO_WORKSPACE/bin to PATH
VERIFY installation via go version
```

**Critical rule**: The `GOROOT` environment variable MUST be unset after installation to prevent poisoning the Go binary with stale paths.

**Critical rule**: On macOS, the Homebrew Go binary path MUST be prepended to PATH to prevent shadowing by other Go installations.

### Python Runtime Installation

```
IF os = ubuntu
    INSTALL distro packages python3 and python3-venv
ELSE IF os = macos
    INSTALL or UPGRADE Homebrew Python
END IF

VERIFY interpreter version is at least PYTHON_REQUIRED_VERSION
CREATE a temporary virtual environment
RUN its interpreter
REMOVE the temporary environment
```

The module MUST use native package-manager sources only. It MUST NOT add third-party Python repositories, replace a system interpreter symlink, define a global `python` alias, or install Poetry, pyenv, project dependencies, test tools, or global Python packages. If the native interpreter is below the required version, the module MUST fail with supported-version guidance.

### Visual Studio Code Desktop Installation

```
IF os is not macos
    FAIL as unsupported platform
ELSE IF official desktop Cask is absent
    INSTALL the stable Cask
ELSE
    REQUEST stable Cask upgrade
END IF
VERIFY the desktop editor command interface is available
```

The desktop module MUST retain official Microsoft Visual Studio Code rather than substitute VSCodium or another Code OSS distribution. It MUST NOT patch the application bundle or invalidate its signature to alter Settings Sync.

### code-server Installation and Service Provisioning

```
IF os is not ubuntu
    FAIL as unsupported platform
END IF
RUN the official stable installer
PRESERVE local bind, password, and certificate state
RECONCILE managed editor configuration and extensions
ENABLE and START the service
VERIFY active service state
VERIFY local HTTPS response while accepting the generated certificate
```

Selecting `code_server` MUST actively request a stable update on every run. The module MUST leave the service enabled and running, MUST fail when its selected port is occupied, and MUST never choose a replacement port or alter firewall rules. Password and certificate material MUST remain local and absent from logs.

### Node.js Installation (via fnm)

```
IF fnm not found
    INSTALL fnm via official curl script
    ADD fnm directory to PATH for current session
ELSE
    EMIT success "fnm already installed"
END IF

IF fnm is available
    ADD fnm directory to PATH
    EVAL fnm env for current session
    INSTALL Node.js LTS via fnm
    SET fnm default to lts-latest
    VERIFY via node --version
END IF
```

**Critical rule**: npm global installs for AI CLI tools (Codex and Pi) MUST use `--prefix` pointing to `NPM_GLOBAL_PREFIX` (`~/.local`) so that binaries survive fnm Node version switches. The `~/.local/bin` directory MUST be on PATH.

### Herdr Installation

```
IF herdr is not found
    INSTALL Herdr by running the official direct installer from HERDR_INSTALL_SCRIPT
    VERIFY herdr is available on PATH
ELSE
    EMIT success "Herdr already installed"
END IF
```

Herdr MUST use the official curl installer on both Linux and macOS. Homebrew, mise, and Nix MUST NOT be used by the dotfiles installer for Herdr. This keeps updates on the same `herdr update` channel across supported platforms.

The Herdr install function MUST be idempotent: if `command -v herdr` succeeds, it MUST skip the installer. If Herdr is installed but not on PATH, the function MUST report a PATH warning rather than installing duplicate binaries blindly.

### Beads and Dolt Installation

```
DOLT:
    IF os = ubuntu
        RUN the official stable DOLT_INSTALL_SCRIPT_LINUX
    ELSE IF os = macos
        INSTALL or UPGRADE the DOLT_MACOS_PACKAGE Homebrew formula
    END IF
    VERIFY dolt version succeeds

BEADS:
    RUN the official checksum-verifying BEADS_INSTALL_SCRIPT on every selected module execution
    VERIFY bd version succeeds
    VERIFY the installed binary is not the retired pre-Dolt local build
    VERIFY bd can discover the installed dolt command
```

The Beads installer MUST request the current stable release rather than a prerelease or source checkout. The Dolt module MUST complete before Beads when both are selected. Re-running either module MUST use its supported update path and preserve all command-repo data.

Normal installation MUST NOT initialize, clone, migrate, delete, or synchronize a command repo. A separate explicit idempotent bootstrap operation accepts one absolute local path and private remote URL, then creates or clones the command repo, initializes Beads server mode, configures its Dolt remote, writes `BEADS_COMMAND_CONFIG_PATH`, and verifies server health plus pull/checkpoint/push. Credentials remain local and MUST NOT appear in arguments retained by tracked files or logs.

Legacy cleanup is a separate one-time explicit migration operation, never an install side effect. Before deletion it MUST archive and verify the untracked `~/code/beads/research/` contents outside that clone. It may then remove the approved retired Beads binary and alias symlink, global and project legacy databases, and `~/code/beads/`. Any archive failure blocks every deletion.

### Go Full Development Environment

```
PERFORM Go installation (above)

IF go is available
    CLEAR go build cache
    INSTALL govulncheck via go install
    IF neovim is available
        INSTALL Mason Go packages: gopls, delve, gofumpt, goimports
    ELSE
        EMIT info "Neovim not found — skip Go LSP tools"
        EMIT info "Install neovim first, then run MasonInstall command"
    END IF
END IF
```

**Critical rule**: Go build cache MUST be cleared before installing govulncheck to prevent stale toolchain version mismatches after Go upgrades.

**Critical rule**: The `GOTOOLCHAIN=auto` environment variable MUST be set when installing govulncheck to allow Go to fetch the required toolchain version automatically.

### TUI Tool Installation

```
LAZYGIT:
    IF already installed → skip
    ELSE IF os = ubuntu
        FETCH latest version from GitHub /releases/latest endpoint
        DETECT architecture for archive suffix
        DOWNLOAD tarball to temp directory
        EXTRACT and install binary to /usr/local/bin via sudo
        CLEANUP temp directory
    ELSE IF os = macos
        INSTALL via brew install lazygit
    END IF

YAZI:
    IF already installed → skip
    ELSE IF os = ubuntu
        FETCH latest version from GitHub /releases/latest endpoint
        DETECT architecture for archive suffix
        DOWNLOAD zip to temp directory
        EXTRACT and install binary to /usr/local/bin via sudo
        CLEANUP temp directory
    ELSE IF os = macos
        INSTALL via brew install yazi
    END IF

ZOXIDE:
    IF already installed → skip
    ELSE IF os = ubuntu
        INSTALL via official curl script
    ELSE IF os = macos
        INSTALL via brew install zoxide
    END IF

CONFIG SYMLINKS:
    DEPLOY lazygit config symlink to platform-specific config directory
        (macOS: ~/Library/Application Support/lazygit/config.yml)
        (ubuntu: ~/.config/lazygit/config.yml)
    DEPLOY yazi config symlinks for yazi.toml, keymap.toml, theme.toml
```

### Mason Package Installation

```
BASE PACKAGES (during Neovim configuration):
    ATTEMPT headless Mason install: stylua ruff pyright prettier eslint_d
    IF success → EMIT success
    ELSE → EMIT warning "may require manual installation"

GO PACKAGES (during golang_full):
    IF neovim available
        ATTEMPT headless Mason install: gopls delve gofumpt goimports
        IF success → EMIT success
        ELSE → EMIT warning "may require manual installation"
    END IF
```

**Lazy.nvim Plugin Sync** (during Neovim configuration):

```
ATTEMPT headless Lazy! sync
IF success → EMIT success
ELSE IF error message contains "local changes"
    CLEANUP dirty plugin cache entries (remove directory for each dirty plugin)
    RETRY Lazy! sync once
    IF success → EMIT success
    ELSE → EMIT warning "may require manual intervention"
END IF
ELSE
    EMIT warning "may require manual intervention"
END IF

ATTEMPT headless TSUpdateSync
IF success → EMIT success
ELSE → EMIT warning "parser update had issues"
```

**Critical rule**: Dirty lazy.nvim plugin cache entries MUST be removed entirely (not reset) before retry, because a simple git reset may not resolve merge conflicts or local modifications.

### Neovim Cache Management

```
IF lazy.nvim data directory does NOT exist (fresh installation)
    DELETE ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim
ELSE (update)
    PRESERVE ~/.local/share/nvim (Mason packages)
    DELETE ~/.cache/nvim only
END IF
```

**Key rule**: Mason packages in `~/.local/share/nvim` MUST be preserved on updates. Only the cache directory is cleared to prevent stale plugin issues.

### AI CLI Tool Installation

All npm-based AI CLI tools (Codex and Pi) follow the same pattern:

```
IF npm not found
    TRIGGER Node.js installation as dependency
END IF

ENSURE NPM_GLOBAL_PREFIX/bin directory exists
INSTALL via npm install -g --prefix=NPM_GLOBAL_PREFIX <package>@latest

VERIFY the binary exists and is executable at NPM_GLOBAL_PREFIX/bin/<name>

IF a different <name> binary appears earlier in PATH
    EMIT warning about PATH priority
END IF

SETUP agent config directory
DEPLOY config symlinks for settings, agents, skills
```

**Critical rule**: The `--prefix` flag (pointing to `NPM_GLOBAL_PREFIX`, i.e., `~/.local`) is mandatory for npm-based AI CLI tools so that binaries survive fnm Node version switches. The global npm prefix MUST NOT be inside an fnm-managed Node directory.

**Exception — Playwright CLI**: Playwright CLI is installed via `npm install -g @playwright/cli@latest` WITHOUT the `--prefix` flag, placing it in the fnm-managed Node directory. This is inconsistent with the npm agent install pattern and means Playwright CLI would be lost on fnm Node version switches. This exception exists because Playwright CLI is not an AI agent and may have browser dependency requirements that differ from the agent install pattern.

**Installer type variants**: AI CLI tools use two distinct installation patterns:

| Tool | Installer type | Install command | Install location |
|------|---------------|-----------------|----------------|
| Codex CLI | npm global | `npm install -g --prefix ~/.local` | `~/.local/bin/` |
| Pi Coding Agent | npm global | `npm install -g --prefix ~/.local` | `~/.local/bin/` |
| Playwright CLI | npm global (no prefix) | `npm install -g` | fnm Node directory |
| Claude Code | curl installer | `curl -fsSL https://claude.ai/install.sh \| bash -s latest` | `~/.local/bin/` |
| Copilot CLI | curl installer | `curl -fsSL https://gh.io/copilot-install \| bash` | `~/.local/bin/` |

**Claude Code update rule**: The Claude Code module MUST run the official installer with the `latest` target on every module execution:

```
curl -fsSL https://claude.ai/install.sh | bash -s latest
```

This rule applies even when `command -v claude` succeeds so the module delegates idempotent updates to the official installer. Existing local `~/.claude/settings.json` content MUST be protected from installer rewrites and restored afterward; settings generated on a fresh installation MUST remain local. A legacy dotfiles-managed settings symlink MUST be migrated to a regular local file without losing its resolved content. When the tracked status-line script is deployed, the module MUST set local `statusLine` configuration to execute `~/.claude/statusline.sh` without replacing unrelated settings. After the installer runs, the module MUST verify that `~/.local/bin/claude` exists and is executable. If another `claude` binary appears earlier in `PATH`, the module MUST emit a warning.

**Codex config.toml special case**: The config.toml file MUST be copied (not symlinked) from the dotfiles template because Codex writes machine-specific values into it. The behavior is controlled by the `CODEX_CONFIG_TEMPLATE_MODE` parameter:
- `preserve` (default): If a local config.toml exists, keep it; if only a symlink exists, convert it to a local copy
- `overwrite`: Backup existing config.toml and replace with fresh template copy

### Dependency Resolution

```
FUNCTION resolve_dependencies(selected_modules):
    resolved = []
    FOR EACH module IN selected_modules
        IF module HAS unmet prerequisite (tool not found on system)
            ADD prerequisite module to resolved
        END IF
        ADD module itself to resolved
    END FOR
    DEDUPLICATE resolved while preserving insertion order
    RETURN resolved
```

Dependencies are resolved dynamically at runtime by checking whether prerequisite tools exist on the system. This means dependency resolution is **environment-aware**: on a system where Node.js is already installed, selecting the `codex` module will NOT auto-add `nodejs`.

---

## Error Handling

### OS Detection Failure

| Trigger | Detection | Response | Recovery |
|---------|-----------|----------|----------|
| Linux distro without apt | Linux detected but apt package manager not found | EMIT error "Linux detected but apt not found. This script requires Ubuntu/Debian." | EXIT with failure; user must install apt or use a supported OS |
| Unsupported OS | Operating system is neither Linux nor macOS | EMIT error "Unsupported operating system" | EXIT with failure; no recovery path |

### Package Manager Errors

| Trigger | Detection | Response | Recovery |
|---------|-----------|----------|----------|
| apt package install fails | apt install returns non-zero | Script exits | User must resolve package conflict or network issue |
| Homebrew not found on macOS | `brew` command not found | INSTALL Homebrew automatically | If Homebrew install fails, script exits |
| Homebrew install fails on Apple Silicon | brew not in PATH after install | APPEND eval to ~/.zprofile; EVAL for current session | User may need to restart shell |

### Version Check Failures

| Trigger | Detection | Response | Recovery |
|---------|-----------|----------|----------|
| Neovim below minimum version | `nvim --version` returns version < 0.10 | DOWNLOAD latest AppImage on Ubuntu; WARN on macOS | On Ubuntu: replaces any apt-installed neovim; On macOS: upgrades via brew |
| Neovim version parse fails | Floating-point comparison fails or returns error | TREAT as version 0.0 (triggers upgrade) | Full reinstall always safe |
| Go below minimum version | `go version` returns version < 1.24 | UPGRADE via Homebrew (macOS); WARN (Ubuntu, binary path) | On macOS: brew upgrade; On Ubuntu: user must re-run install |
| Go version fetch fails | Version endpoint returns empty result | EMIT error "Failed to fetch version" | RETURN failure from golang module; user may retry |
| Herdr installer fails | Official installer exits non-zero or `herdr` is still unavailable after install | EMIT error "Herdr install failed" | RETURN failure from herdr module; user may retry after checking network and PATH |
| Beads installer fails | Official installer exits non-zero or `bd version` fails | Fail `beads` without touching command-repo data | Repair network/PATH and rerun |
| Dolt installer fails | Official installer/package update fails or `dolt version` fails | Fail `dolt`; do not initialize Beads server mode | Repair installer/package manager and rerun |
| Command-repo bootstrap incomplete | Path, remote, server health, or synchronization validation fails | Leave no globally routed partial command repo; report exact state | Correct path/remote/credentials and rerun explicit bootstrap |
| Legacy archive fails | Research archive cannot be verified | Delete none of the approved legacy paths | Correct archive destination and rerun explicit cleanup |

### Download Failures

| Trigger | Detection | Response | Recovery |
|---------|-----------|----------|----------|
| Neovim AppImage download fails | curl returns non-zero | EMIT error; RETURN failure from module | Temp directory cleaned up before return |
| Go tarball download fails | wget returns non-zero | EMIT error; CLEANUP temp directory; RETURN failure | User may retry; previous Go installation preserved |
| Lazygit version fetch fails | GitHub API returns empty tag | EMIT error | Module continues; lazygit not installed |
| Lazygit download fails | curl returns non-zero | EMIT error | Module continues; lazygit not installed |
| Yazi version fetch fails | GitHub API returns empty tag | EMIT error | Module continues; yazi not installed |
| Yazi download fails | curl returns non-zero | EMIT error | Module continues; yazi not installed |

### Mason Installation Failures

| Trigger | Detection | Response | Recovery |
|---------|-----------|----------|----------|
| Mason base packages fail | Headless nvim command returns non-zero | EMIT warning "may require manual installation" | User runs `:Mason` inside Neovim |
| Lazy sync fails with dirty cache | Error message contains "local changes" | CLEANUP dirty plugins (remove each directory); RETRY sync once | If retry fails, EMIT warning with manual command |
| Lazy sync fails for other reason | Headless nvim returns non-zero | EMIT warning "may require manual intervention" | User runs Lazy! sync manually inside Neovim |
| Treesitter update fails | Headless TSUpdateSync returns non-zero | EMIT warning "parser update had issues" | Non-blocking; most parsers still work |
| Neovim not found for Mason Go install | `nvim` command not found | EMIT info "Neovim not found — skip Go LSP tools" | User installs nvim first, then re-runs or uses `:MasonInstall` manually |

### Python and Editor Provisioning Failures

| Trigger | Detection | Response | Recovery |
|---------|-----------|----------|----------|
| Native Python is below 3.10 | Interpreter version check | Fail `python`; do not add third-party repository | Upgrade supported OS/package source |
| Python virtual environment cannot run | Temporary venv verification fails | Fail `python`; remove temporary state | Repair native Python packages and rerun |
| Desktop VS Code selected outside macOS | Platform check | Fail selected module | Use macOS desktop target |
| code-server selected outside Ubuntu/Debian | Platform check | Fail selected module | Use supported Linux target |
| Visual Studio Code Cask install/upgrade fails | Homebrew non-zero status | Fail `vscode` | Repair Homebrew/network and rerun |
| code-server installer fails | Official installer non-zero status | Fail `code_server` | Check network and installer output, then rerun |
| code-server port is occupied | Listener preflight or service bind failure | Fail without selecting another port | Stop conflicting process or provide explicit bind |
| code-server service does not become active | Service manager status | Fail and report service diagnostics | Correct local config/service and rerun |
| code-server HTTPS endpoint does not respond | Local HTTPS health verification | Fail without exposing secrets | Inspect service, bind, and certificate state |

### npm Global Install Failures

| Trigger | Detection | Response | Recovery |
|---------|-----------|----------|----------|
| npm not found during AI CLI install | npm command not found | TRIGGER Node.js installation as dependency | If Node.js install succeeds, retry the AI CLI install |
| Binary not at expected path after npm install | Expected binary path not found or not executable | EMIT error "install failed: binary not found" | RETURN failure from module |
| Different binary shadows the installed one | Another binary with same name appears earlier in PATH | EMIT warning about PATH priority; EMIT info about ensuring NPM_GLOBAL_PREFIX/bin is first | Non-blocking; user must adjust PATH |

### PATH Issues

| Trigger | Detection | Response | Recovery |
|---------|-----------|----------|----------|
| NPM_GLOBAL_PREFIX/bin not in PATH after install | PATH string does not contain the expected prefix bin directory | EMIT info "Add ~/.local/bin to your PATH" | User must add to shell config |
| Homebrew not in PATH on Apple Silicon | After install, brew not found | APPEND to ~/.zprofile; EVAL for current session | User may need to restart shell |

### Architecture Edge Cases

| Trigger | Detection | Response | Recovery |
|---------|-----------|----------|----------|
| Unsupported CPU architecture | Detected architecture is not x86_64, aarch64, or arm64 | EMIT error "Unsupported architecture" | RETURN failure; no binary available |

---

## Implementation Notes

1. **Idempotency is paramount**. Every installation function MUST check whether the tool is already present and at a satisfactory version before attempting installation. The script MUST be safe to re-run without errors, data loss, or unnecessary side effects.

2. **Temp directory discipline**. All binary downloads MUST use a temporary directory and MUST clean it up before returning, both on success and on failure paths. No temporary files should leak.

3. **Platform divergence is localized**. The `install_package` function abstracts the apt/brew split. For tools that require different download methods per platform, the OS check is inside the specific install function. The architecture mapping is always inside the Ubuntu branch since macOS Homebrew handles architecture automatically.

4. **Version comparison uses two mechanisms**. Go version checks use version-sort comparison, while the Neovim version check on Ubuntu uses floating-point comparison. Both ensure that `0.9 < 0.10` evaluates correctly (unlike lexicographic string comparison). The implementation MUST use version-sort ordering for Go and floating-point comparison for Neovim.

5. **Herdr direct installer exception**. Herdr intentionally bypasses Homebrew on macOS. This is a tool-specific exception so `herdr update` remains the consistent update path across Linux and macOS direct installs.

5. **npm global prefix MUST be NPM_GLOBAL_PREFIX**. Codex and Pi install with `npm install -g --prefix` pointing to `NPM_GLOBAL_PREFIX` (`~/.local`). This ensures binaries land in `~/.local/bin/` and survive fnm Node version switches. Never use the fnm-managed Node directory as the global prefix.

6. **Codex config.toml is a copy, not a symlink**. Unlike other agent configs, Codex writes machine-specific values into `~/.codex/config.toml`. The dotfiles template MUST be copied; subsequent runs preserve the local copy unless `--codex-config-template overwrite` is specified.

7. **Lazy.nvim dirty cache handling**. When plugin sync fails due to local changes, the dirty plugin directories MUST be removed entirely (not reset). A retry MUST be attempted exactly once. If it fails again, the user is told to run the sync manually inside Neovim.

8. **Neovim cache vs. data preservation**. On fresh installations (no `~/.local/share/nvim/lazy` directory), all nvim state directories are cleared. On updates, only `~/.cache/nvim` is cleared while `~/.local/share/nvim` (containing Mason packages) is preserved.

9. **Go build cache cleanup**. Before installing govulncheck, the Go build cache MUST be cleared to prevent stale toolchain version mismatches after Go upgrades.

10. **Module dependency resolution is runtime-dynamic**. Dependencies are not static — they depend on what is already installed on the system. A module that would normally need a prerequisite skips it if the prerequisite tool is already present.

11. **Backup timestamp format MUST be consistent**. All file backups use the `BACKUP_TIMESTAMP_FMT` format (`%Y%m%d_%H%M%S`). This ensures chronological sortability and second-level granularity.

12. **Python remains a baseline runtime**. The `python` module owns only a native interpreter and virtual-environment capability. Editor configuration and projects remain separate owners.

13. **Editor targets are asymmetric by design**. Official desktop Visual Studio Code is macOS-only; code-server is Ubuntu/Debian-only. Unsupported explicit selection fails rather than silently skipping.

14. **code-server secrets are local state**. Stable updates and configuration reconciliation preserve password, certificate, and bind state unless the user explicitly overrides the bind.

15. **Command-repo state is not install state**. Normal Beads/Dolt provisioning never initializes, syncs, or deletes the private command repo; bootstrap and legacy cleanup are explicit operations with separate authority.

16. **Server mode requires Dolt**. The Beads execution workflow uses a Beads-managed Dolt server, so tool verification covers both binaries before command-repo bootstrap.

---

## Test Scenarios

```
TS-TOOL-001: Fresh Ubuntu installation — all tools installed from scratch
Category: Integration
Priority: Critical
Preconditions: Clean Ubuntu system with apt; no tools pre-installed
Input: --profile full
Expected Output: All base tools installed via apt; Neovim AppImage downloaded and installed to /usr/local/bin; Go binary downloaded to /usr/local/go; fnm and Node.js LTS installed; lazygit, yazi, zoxide binaries installed; Mason base packages and Go packages installed; all AI CLI tools installed to ~/.local/bin; all config symlinks created; exit code 0
```

```
TS-TOOL-002: Fresh macOS installation — all tools installed via Homebrew
Category: Integration
Priority: Critical
Preconditions: Clean macOS system with Homebrew; no tools pre-installed
Input: --profile full
Expected Output: All base tools installed via brew; Neovim installed via brew; Go installed via brew; fnm and Node.js LTS installed; lazygit, yazi, zoxide installed via brew; all config symlinks created; exit code 0
```

```
TS-TOOL-003: Idempotent re-run — no changes on second run
Category: Integration
Priority: Critical
Preconditions: Full installation already completed
Input: --profile full (re-run)
Expected Output: Every tool reports "already installed", "already at required version", or runs its idempotent official updater; no backups created; no unnecessary duplicate installs; exit code 0
```

```
TS-TOOL-004: Architecture detection — x86_64 Ubuntu
Category: Unit
Priority: High
Preconditions: Ubuntu system with x86_64 architecture
Input: OS detection module
Expected Output: Neovim downloads nvim-linux-x86_64.appimage; Go downloads *amd64.tar.gz; lazygit downloads *_Linux_x86_64.tar.gz; yazi downloads *-x86_64-unknown-linux-gnu.zip
```

```
TS-TOOL-005: Architecture detection — ARM64 Ubuntu
Category: Unit
Priority: High
Preconditions: Ubuntu system with aarch64 or arm64 architecture
Input: OS detection module
Expected Output: Neovim downloads nvim-linux-arm64.appimage; Go downloads *arm64.tar.gz; lazygit downloads *_Linux_arm64.tar.gz; yazi downloads *-aarch64-unknown-linux-gnu.zip
```

```
TS-TOOL-006: Unsupported architecture — no matching binary
Category: Unit
Priority: Medium
Preconditions: System with unsupported architecture (e.g., MIPS, RISC-V)
Input: Neovim or Go installation attempt on Ubuntu
Expected Output: Error message "Unsupported architecture"; function returns failure; other modules continue; exit code 1 if all modules in the run fail
```

```
TS-TOOL-007: Neovim version below minimum triggers upgrade
Category: Unit
Priority: Critical
Preconditions: Ubuntu system with Neovim 0.9 installed via apt
Input: install_neovim module
Expected Output: apt-installed neovim removed; latest stable AppImage downloaded and installed; installed version ≥ 0.10; temp directory cleaned up
```

```
TS-TOOL-008: Neovim already meets version requirement
Category: Unit
Priority: High
Preconditions: Neovim 0.10+ already installed
Input: install_neovim module
Expected Output: Success message "version meets requirements"; no download attempted; no AppImage installation
```

```
TS-TOOL-009: Go version below minimum on macOS triggers upgrade
Category: Unit
Priority: High
Preconditions: macOS with Go 1.23 installed via Homebrew
Input: golang_full module
Expected Output: Homebrew upgrades Go to 1.24+; govulncheck installed; Mason Go packages installed
```

```
TS-TOOL-010: Go not found on Ubuntu triggers fresh install
Category: Unit
Priority: High
Preconditions: Ubuntu system with no Go installation
Input: golang_full module
Expected Output: Latest Go version fetched from go.dev; tarball downloaded and extracted to /usr/local/go; GO_WORKSPACE set; PATH updated; govulncheck installed
```

```
TS-TOOL-011: Package name differences across platforms
Category: Unit
Priority: High
Preconditions: Both Ubuntu and macOS systems
Input: install_package for fd-find/fd
Expected Output: On Ubuntu: installs `fd-find` via apt; On macOS: installs `fd` via brew
```

```
TS-TOOL-012: npm global prefix survives fnm version switch
Category: Integration
Priority: Critical
Preconditions: fnm installed with Node.js LTS; Codex CLI installed to ~/.local
Input: fnm install <different-node-version>; then which codex
Expected Output: codex binary still resolves at ~/.local/bin/codex; path does not change after fnm switch
```

```
TS-TOOL-013: Lazy.nvim dirty cache is cleaned and retried
Category: Unit
Priority: High
Preconditions: Neovim installed; lazy.nvim has local changes in one or more plugin directories
Input: configure_neovim module
Expected Output: Dirty plugin directories removed; Lazy! sync retried; success message or warning with manual command
```

```
TS-TOOL-014: Neovim fresh install clears all cache directories
Category: Unit
Priority: Medium
Preconditions: No ~/.local/share/nvim/lazy directory exists (fresh install)
Input: configure_neovim module
Expected Output: ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim all deleted before plugin sync
```

```
TS-TOOL-015: Neovim update preserves Mason packages
Category: Unit
Priority: High
Preconditions: ~/.local/share/nvim/lazy exists (update scenario)
Input: configure_neovim module
Expected Output: ~/.local/cache/nvim deleted; ~/.local/share/nvim preserved; Mason packages intact
```

```
TS-TOOL-016: Dependency resolution adds missing prerequisites dynamically
Category: Integration
Priority: High
Preconditions: System with no npm installed; user selects golang_full module only
Input: --modules golang_full
Expected Output: resolve_dependencies adds base_tools (for Go) and neovim (for Mason packages); golang_full module runs after prerequisites
```

```
TS-TOOL-017: Dependency resolution skips already-installed prerequisites
Category: Integration
Priority: High
Preconditions: System with npm already installed; user selects codex module
Input: --modules codex
Expected Output: resolve_dependencies does NOT add nodejs module; codex is installed using existing npm
```

```
TS-TOOL-018: Codex config.toml is copied not symlinked
Category: Unit
Priority: Critical
Preconditions: Fresh ~/.codex/ directory; dotfiles/codex/config.toml exists
Input: install_codex module
Expected Output: ~/.codex/config.toml is a regular file (not a symlink) with contents copied from dotfiles template
```

```
TS-TOOL-019: Codex config.toml symlink converted to local file on re-run
Category: Unit
Priority: High
Preconditions: ~/.codex/config.toml is a symlink to dotfiles
Input: install_codex module (re-run, default preserve mode)
Expected Output: Symlink removed; contents copied to regular file; EMIT info about conversion
```

```
TS-TOOL-020: Codex config.toml overwrite mode replaces with template
Category: Unit
Priority: Medium
Preconditions: ~/.codex/config.toml exists as a regular file with custom values
Input: --modules codex --codex-config-template overwrite
Expected Output: Existing config.toml backed up with timestamp; fresh template copied in its place
```

```
TS-TOOL-021: Go build cache cleared before govulncheck install
Category: Unit
Priority: Medium
Preconditions: Go 1.24+ installed; build cache contains old artifacts
Input: golang_full module
Expected Output: go clean -cache runs before go install govulncheck; no stale toolchain errors
```

```
TS-TOOL-022: Homebrew not found on Apple Silicon macOS
Category: Unit
Priority: High
Preconditions: macOS arm64 system with no Homebrew
Input: setup_package_manager
Expected Output: Homebrew installed via official script; /opt/homebrew/bin/brew eval appended to ~/.zprofile; eval applied for current session
```

```
TS-TOOL-023: GitHub API failure for binary version — lazygit
Category: Unit
Priority: Medium
Preconditions: No lazygit installed; network failure or API rate limit
Input: install_tui_tools module
Expected Output: EMIT error "Failed to fetch lazygit version"; lazygit skipped; other TUI tools continue; module does not fail entirely
```

```
TS-TOOL-024: Mason Go packages skipped when Neovim absent
Category: Unit
Priority: Medium
Preconditions: Go installed; Neovim not installed
Input: golang_full module
Expected Output: EMIT info "Neovim not found — skip Go LSP tools"; EMIT info with manual MasonInstall command; module succeeds for Go toolchain portion
```

```
TS-TOOL-025: PATH shadowing warning for AI CLI tools
Category: Unit
Priority: Medium
Preconditions: Another binary with the same name exists earlier in PATH (e.g., system codex)
Input: install_codex module
Expected Output: EMIT warning about PATH shadowing; EMIT info about ensuring ~/.local/bin is first in PATH; installation still succeeds
```

```
TS-TOOL-026: Herdr direct installer used on Linux and macOS
Category: Integration
Priority: Critical
Preconditions: herdr is not installed; curl is available
Input: herdr module on Linux or macOS
Expected Output: Official HERDR_INSTALL_SCRIPT is executed; Homebrew is not used; command -v herdr succeeds after install
```

```
TS-TOOL-027: Herdr install is idempotent
Category: Unit
Priority: High
Preconditions: herdr is already available on PATH
Input: herdr module
Expected Output: Installer is skipped and success is emitted without reinstalling or changing channel state
```

```
TS-TOOL-028: Python native baseline on Ubuntu
Category: Integration
Priority: Critical
Preconditions: Supported Ubuntu/Debian with no Python runtime
Input: python module
Expected Output: Native python3 and venv support are installed; version is at least 3.10; temporary venv executes successfully
```

```
TS-TOOL-029: Python native baseline on macOS
Category: Integration
Priority: Critical
Preconditions: macOS with Homebrew
Input: python module
Expected Output: Homebrew Python is installed/upgraded without replacing system Python; temporary venv executes successfully
```

```
TS-TOOL-030: Old native Python fails without external repository
Category: Unit
Priority: High
Preconditions: Native package source provides Python below 3.10
Input: python module
Expected Output: Module fails with version guidance and no third-party repository is added
```

```
TS-TOOL-031: Official Visual Studio Code updates on macOS
Category: Integration
Priority: Critical
Preconditions: macOS with Homebrew
Input: vscode module twice
Expected Output: Official stable Cask is installed then receives an idempotent upgrade request; command interface remains available
```

```
TS-TOOL-032: code-server stable update preserves local state
Category: Integration
Priority: Critical
Preconditions: Ubuntu/Debian with existing bind, password, and certificate state
Input: code_server module
Expected Output: Official stable installer runs; local state is preserved; service is enabled, active, and HTTPS-responsive
```

```
TS-TOOL-033: Editor distribution platform boundaries
Category: Unit
Priority: High
Preconditions: Ubuntu/Debian for desktop case and macOS for server case
Input: Select unsupported editor module
Expected Output: Selected module fails with supported-platform guidance and performs no substitute installation
```

```
TS-TOOL-034: Beads and Dolt official stable provisioning
Category: Integration
Priority: Critical
Preconditions: Supported platform without bd or dolt
Input: Select dolt and beads modules twice
Expected Output: Official stable channels install and then idempotently update/verify both binaries; no command repo is created or mutated
```

```
TS-TOOL-035: Explicit command-repo bootstrap
Category: End-to-End
Priority: Critical
Preconditions: bd and dolt are installed; private remote and credentials are valid
Input: Bootstrap with an absolute local path and private remote URL, then rerun
Expected Output: One server-mode command repo is created or cloned, local runtime config is written, health and synchronization pass, and rerun preserves operational data
```

```
TS-TOOL-036: Legacy cleanup archives before delete
Category: Integration
Priority: Critical
Preconditions: Approved legacy paths and untracked research exist
Input: Run normal install, then explicit legacy cleanup with valid and invalid archive destinations
Expected Output: Normal install deletes nothing; invalid archive deletes nothing; valid archive is verified before every approved legacy path is removed
```

---

## Changelog

| Version | Date | Summary |
|---------|------|---------|
| 1.5.0 | 2026-08-01 | Added official Beads and Dolt provisioning, explicit private command-repo bootstrap, and archive-gated one-time legacy cleanup. |
| 1.4.0 | 2026-07-31 | Added native Python 3.10+ provisioning, macOS official Visual Studio Code installation/update, and Ubuntu/Debian code-server installation, service, security-state preservation, and health verification. |
| 1.3.0 | 2026-07-15 | Made Claude settings local runtime state, preserved them across installer runs, and defined legacy symlink migration. |
| 1.2.1 | 2026-07-06 | Required Claude Code to run the official installer with the `latest` target on every Claude module execution, with user-local binary verification. |
| 1.2.0 | 2026-07-05 | Added Herdr direct-installer provisioning, Herdr modules, error handling, and tests. |
| 1.1.0 | 2026-06-02 | Clarified that Pi installs a single shared binary. |
| 1.0.0 | 2026-05-01 | Initial spec extracted from install.sh. Covers OS detection, package installation, tool downloads, fnm/Node.js, TUI tools, Mason packages, AI CLI tools, dependency resolution, and error handling. |

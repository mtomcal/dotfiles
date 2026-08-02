# Personal Dotfiles Manager Specification Suite

> **Version**: 0.17.0
> **Last Updated**: 2026-08-02
> **Purpose**: Complete specification for the personal dotfiles manager — automates setup of a Herdr/tmux + Beads + Neovim + platform-scoped VS Code + zsh dev environment across Linux and macOS. Primarily for personal use, serves as reference/inspiration for others.

---

## Project Summary

A personal dotfiles manager that automates the setup of a Herdr-first terminal workspace with tmux retained as a legacy fallback, Beads execution coordination, Neovim, platform-scoped Visual Studio Code/code-server, baseline Python, and zsh across Linux (Ubuntu/Debian) and macOS. It uses a symlink-based architecture to maintain configurations in version control while deploying them to standard system locations. The primary user is the owner, but the repository serves as a reference for others seeking a reproducible, version-controlled development environment.

---

## Technology Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Install script | Bash | 4+ | Idempotent setup orchestrator |
| Shell | Zsh + Oh My Zsh | latest | Primary interactive shell |
| Terminal multiplexer | Herdr | stable | Default session/workspace manager and SSH multiplexer |
| Legacy multiplexer | Tmux | 3+ | Fallback session management and migration compatibility |
| Editor | Neovim | 0.10+ | Primary terminal editor (kickstart.nvim + custom layer) |
| Desktop editor | Official Visual Studio Code | stable | Managed macOS desktop editor and Remote SSH client |
| Browser editor | code-server | stable | Explicit Ubuntu/Debian private-network browser endpoint |
| Runtime | Python | 3.10+ | Native-package baseline interpreter and virtual environments |
| Editor plugin manager | lazy.nvim | latest | Neovim plugin management |
| Editor packages | Mason | latest | LSP/formatter/linter installation |
| Extension language | Lua | 5.1 (LuaJIT) | Neovim custom plugins |
| Runtime | Go | 1.24+ | Development language and tooling |
| Runtime | Node.js (via fnm) | LTS | AI CLI tools and extensions |
| File manager | Yazi | latest | Terminal file manager |
| Git UI | lazygit | latest | Terminal git interface |
| Smart cd | Zoxide | latest | Directory jumping |
| Execution graph | Beads (embedded Dolt) | stable | Private command-repo planning, orchestration state, and recovery |

---

## Reading Order

For an extracting or implementing agent, read specs in this order:

### Phase 1: Foundation

1. **[UBIQUITOUS_LANGUAGE.md](UBIQUITOUS_LANGUAGE.md)** — Shared domain vocabulary
2. **[DESIGN_LANGUAGE.md](DESIGN_LANGUAGE.md)** — Interface vocabulary (CLI + config UI)
3. **[parameters.md](parameters.md)** — All tuning values with rationale

### Phase 2: Core

4. **[symlink-manager.md](symlink-manager.md)** — Symlink creation, backup, and verification
5. **[tool-provisioning.md](tool-provisioning.md)** — Dependency and tool installation

### Phase 3: Supporting

6. **[herdr-config.md](herdr-config.md)** — Herdr default multiplexer, config, SSH behavior, integrations
7. **[execution-coordination.md](execution-coordination.md)** — Private command repo, execution molecules, model/review policy, attempts, synchronization, and recovery
8. **[shell-config.md](shell-config.md)** — Zsh + Oh My Zsh configuration and global command-repo routing
9. **[tmux-config.md](tmux-config.md)** — Tmux keybindings, nested sessions, legacy fallback integration
10. **[neovim-config.md](neovim-config.md)** — Kickstart base + custom plugin layer
11. **[vscode-config.md](vscode-config.md)** — macOS desktop managed layer + explicit Ubuntu/Debian code-server
12. **[skill-library.md](skill-library.md)** — Shared-skill catalog, authoring semantics, progressive disclosure, and execution-workflow composition
13. **[ai-agent-config.md](ai-agent-config.md)** — AI agent installation, runtime configuration, catalog exposure, and symlink wiring

### Phase 4: Leaf

14. **[install-orchestrator.md](install-orchestrator.md)** — Top-level orchestrator that calls everything

---

## Dependency Graph

```mermaid
graph TD
    symlink[Symlink Manager] --> tool[Tool Provisioning]
    symlink --> shell[Shell Config]
    symlink --> herdr[Herdr Config]
    symlink --> tmux[Tmux Config]
    symlink --> nvim[Neovim Config]
    symlink --> vscode[VS Code Config]
    symlink --> ai[AI Agent Config]
    tool --> shell
    tool --> herdr
    tool --> exec[Execution Coordination]
    tool --> nvim
    tool --> vscode
    tool --> ai
    herdr --> exec
    herdr --> shell
    herdr --> skill[Skill Library]
    exec --> shell
    exec --> skill
    exec --> install[Install Orchestrator]
    skill --> ai
    herdr --> ai
    shell --> install
    herdr --> install
    tmux --> install
    nvim --> install
    vscode --> install
    ai --> install
    tool --> install
    symlink --> install
```

---

## Key Dependencies

| Spec | Depends On | Depended By |
|------|------------|-------------|
| symlink-manager.md | — | tool-provisioning, shell-config, herdr-config, tmux-config, neovim-config, vscode-config, ai-agent-config, install-orchestrator |
| tool-provisioning.md | symlink-manager | shell-config, herdr-config, execution-coordination, neovim-config, vscode-config, ai-agent-config, install-orchestrator |
| shell-config.md | symlink-manager, tool-provisioning, execution-coordination | install-orchestrator |
| herdr-config.md | symlink-manager, tool-provisioning | shell-config, execution-coordination, skill-library, ai-agent-config, install-orchestrator |
| execution-coordination.md | parameters, ubiquitous language, tool-provisioning, herdr-config | shell-config, skill-library, install-orchestrator |
| tmux-config.md | symlink-manager | install-orchestrator |
| neovim-config.md | symlink-manager, tool-provisioning | install-orchestrator |
| vscode-config.md | parameters, ubiquitous language, design language, symlink-manager, tool-provisioning | install-orchestrator |
| skill-library.md | parameters, ubiquitous language, herdr-config, execution-coordination | ai-agent-config |
| ai-agent-config.md | symlink-manager, tool-provisioning, herdr-config, skill-library | install-orchestrator |
| install-orchestrator.md | all other specs | — |

---

## Quick Reference

| Spec | Description | Version |
|------|-------------|---------|
| [parameters.md](parameters.md) | All tuning values with rationale | 2.4.0 |
| [symlink-manager.md](symlink-manager.md) | Symlink creation, backup, and verification | 2.0.0 |
| [tool-provisioning.md](tool-provisioning.md) | Dependency and tool installation | 1.6.0 |
| [shell-config.md](shell-config.md) | Zsh + Oh My Zsh configuration | 2.0.0 |
| [herdr-config.md](herdr-config.md) | Herdr default multiplexer and migration contract | 0.3.0 |
| [tmux-config.md](tmux-config.md) | Tmux keybindings and nested sessions | 1.1.0 |
| [neovim-config.md](neovim-config.md) | Kickstart + custom plugin layer | 1.0.0 |
| [vscode-config.md](vscode-config.md) | Managed VS Code/code-server configuration and extensions | 1.0.0 |
| [execution-coordination.md](execution-coordination.md) | Beads command-repo execution and recovery contract | 1.3.0 |
| [skill-library.md](skill-library.md) | Shared-skill catalog and authoring contracts | 8.0.0 |
| [ai-agent-config.md](ai-agent-config.md) | AI agent runtime configs and catalog exposure | 4.1.0 |
| [install-orchestrator.md](install-orchestrator.md) | Top-level idempotent setup orchestrator | 2.1.0 |

---

## Implementation Checklist

### Phase 1: Foundation

- [x] Extract all parameters with values and rationale from install.sh and config files
- [x] Review ubiquitous language for term consistency across all specs

### Phase 2: Core

- [x] Extract symlink-manager spec from install.sh symlink functions
- [x] Extract tool-provisioning spec from install.sh dependency installation logic

### Phase 3: Supporting

- [x] Extract shell-config spec from zsh/.zshrc.custom
- [x] Extract herdr-config spec from herdr/config.toml
- [ ] Implement and validate execution-coordination against the approved command-repo, molecule, assignment, attempt, and recovery contracts — bootstrap, routing, and the encoding skills (`beads`, `create-engineering-plan`, `execute-engineering-molecule`) are complete; molecule creation and execution remain unexercised at runtime
- [x] Extract tmux-config spec from tmux/.tmux.conf
- [x] Extract neovim-config spec from nvim/custom/ plugin files
- [ ] Implement and validate vscode-config against the approved managed-layer, extension, service, and capture contracts
- [x] Validate skill-library spec against `shared/skills/` and its authoring workflows
- [x] Extract ai-agent-config spec from codex/, claude/, pi/, copilot/ directories

### Phase 4: Leaf

- [x] Extract install-orchestrator spec from install.sh main flow and OS detection

---

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 0.17.0 | 2026-08-02 | Renamed the execution entries to `create-engineering-plan` and `execute-engineering-molecule` and required a molecule map at creation. |
| 0.16.0 | 2026-08-02 | Added the execution planning scope boundary separating engineering work from authoring work. |
| 0.15.0 | 2026-08-02 | Registered the `beads` base skill, removed the retired filesystem execution contract and legacy-ledger grandfathering, and updated affected spec versions. |
| 0.14.0 | 2026-08-02 | Adopted single-writer embedded Beads storage, removed the Dolt module, and updated affected spec versions. |
| 0.13.0 | 2026-08-01 | Registered Execution Coordination, Beads/Dolt tooling, command-repo shell routing, updated dependency order, and current spec versions. |
| 0.12.0 | 2026-08-01 | Synced the Copilot catalog-exposure vs runtime-state parameter split into parameters.md, added the `catalog exposure` glossary term, and corrected the implementation checklist to reflect extracted specs. |
| 0.11.0 | 2026-08-01 | Synchronized Herdr 0.7.5 agent coordination, current repo-owned integration targets, and affected spec versions. |
| 0.10.0 | 2026-07-31 | Registered VS Code Configuration, baseline Python provisioning, platform-scoped editor targets, dependency graph edges, and current spec versions. |

# Herdr Configuration Specification

> **Version**: 0.3.0
> **Last Updated**: 2026-08-01
> **Depends On**: [Parameters](parameters.md), [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md), [Design Language](DESIGN_LANGUAGE.md), [Symlink Manager](symlink-manager.md), [Tool Provisioning](tool-provisioning.md)
> **Depended By**: Shell Config, Skill Library, AI Agent Config, Install Orchestrator
> **Prefix**: HERDR

---

## Overview

The Herdr configuration defines the replacement-path terminal multiplexer for the dotfiles environment. Herdr becomes the default multiplexer for SSH sessions and all installation profiles, while tmux remains installed and configured as a legacy fallback during migration.

Herdr is configured to preserve tmux muscle memory where it matters most: the **Herdr prefix key** MUST be Ctrl-a, daily pane/tab navigation MUST use vim-style bindings, and advanced tmux-only pane operations MAY remain migration gaps until real usage proves they are required. Herdr's native **Herdr workspace** model is adopted as the new top-level unit for repo, task, or investigation work.

The tracked configuration source is `herdr/config.toml`, deployed as a symlink to `~/.config/herdr/config.toml`. Herdr session files, pane history, sockets, and generated state are **Herdr runtime state** and MUST remain local-only.

---

## Dependencies

### Technology Dependencies

| Dependency | Version Constraint | Purpose |
|------------|-------------------|---------|
| Herdr | stable channel | Terminal multiplexer and agent workspace manager |
| curl | Any | Direct Herdr installer download |
| zsh | System default | SSH auto-attach and Herdr aliases |
| tmux | 3.2+ | Legacy fallback multiplexer during migration |

### Spec Dependencies

| Spec | Reason |
|------|--------|
| [Parameters](parameters.md) | Authoritative source for Herdr paths, aliases, and migration defaults |
| [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md) | Defines Herdr config, Herdr workspace, Herdr runtime state, and repo-owned Herdr integration |
| [Symlink Manager](symlink-manager.md) | Defines deployment and backup rules for `~/.config/herdr/config.toml` |
| [Tool Provisioning](tool-provisioning.md) | Defines direct curl installer behavior |

---

## Parameters

All Herdr parameters defined in [Parameters](parameters.md) are authoritative. They are repeated here for reference but MUST match the Parameters spec.

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| `HERDR_CONFIG_SOURCE` | `~/dotfiles/herdr/config.toml` | path | Version-controlled Herdr config source |
| `HERDR_CONFIG_TARGET` | `~/.config/herdr/config.toml` | path | Herdr's XDG config path |
| `HERDR_INSTALL_SCRIPT` | `https://herdr.dev/install.sh` | URL | Official direct installer; used on both Linux and macOS for consistent update behavior |
| `HERDR_UPDATE_COMMAND` | `herdr update` | command | Direct-installer update path for Linux and macOS |
| `HERDR_PREFIX` | `ctrl+a` | key | Matches tmux muscle memory and the existing dotfiles multiplexer convention |
| `HERDR_PANE_HISTORY` | `true` | boolean | Allows pane screen history as local runtime state, while keeping history files out of git |
| `HERDR_ALLOW_NESTED` | `false` | boolean | Blocks accidental Herdr-inside-Herdr launches; tmux remains the fallback nested tool |
| `HERDR_RESUME_AGENTS_ON_RESTORE` | `true` | boolean | Allows supported agents to resume native conversations after Herdr server restore |
| `SSH_MULTIPLEXER_DEFAULT` | `herdr` | enum | Starts SSH sessions in Herdr by default |
| `SSH_MULTIPLEXER_OVERRIDE_ENV` | `DOTFILES_SSH_MULTIPLEXER` | env var | Allows per-machine fallback to tmux without editing the tracked shell config |

---

## Data Structures

### Herdr Config

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `keys.prefix` | string | Required; value `ctrl+a` | The Herdr prefix key |
| `keys.*` | string or list | Optional; Herdr binding syntax | Daily-use pane, tab, workspace, and copy-mode bindings |
| `session.resume_agents_on_restore` | boolean | Required | Whether Herdr restarts supported agents in their native sessions after restore |
| `advanced.scrollback_limit_bytes` | integer | Required; positive | Scrollback buffer size for new panes |
| `experimental.pane_history` | boolean | Required | Whether pane contents are persisted across full server restarts |
| `experimental.allow_nested` | boolean | Required; value `false` | Whether Herdr may launch inside Herdr |
| `ui.toast.delivery` | enum | `off`, `herdr`, `terminal`, `system` | Popup notification delivery mode |
| `ui.sound.enabled` | boolean | Required | Whether Herdr plays local sounds |

### Herdr Runtime State

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `sessionFile` | path | Local-only | Herdr session state such as workspaces, tabs, panes, layout, cwd, and focus |
| `sessionHistoryFile` | path | Local-only | Pane screen history when `experimental.pane_history` is enabled |
| `socketState` | path | Local-only | Running server/client communication state |
| `trackedByGit` | boolean | Must be `false` | Runtime state MUST NOT be committed |

### Migration Parity Matrix

| tmux Capability | Herdr Requirement | Migration Status |
|-----------------|-------------------|------------------|
| Ctrl-a prefix | `keys.prefix = "ctrl+a"` | Required before default switch |
| New window | New Herdr tab | Required |
| Split panes | Split Herdr panes right/down | Required |
| Vim pane focus | `prefix+h/j/k/l` focus bindings | Required |
| Copy mode | Herdr copy mode | Required |
| Nested session F12 toggle | Block nested Herdr launches; keep tmux fallback | Deliberate non-parity |
| Merge/explode/reverse/equalize panes | No required first-pass Herdr equivalent | Deferred migration gap |

---

## Behavior

### HERDR-CONFIG-001: Deploy Herdr Config

| Condition | Action |
|-----------|--------|
| `herdr/config.toml` exists in the dotfiles repo | Deploy it to `~/.config/herdr/config.toml` using replace-symlink behavior |
| Existing target is a symlink | Replace it with a symlink to the dotfiles source |
| Existing target is a regular file | Back it up with timestamp, then create the symlink |
| Existing target is absent | Create parent directories and create the symlink |

### HERDR-CONFIG-002: Configure Prefix Parity

The Herdr config MUST set the Herdr prefix key to Ctrl-a. The default upstream Ctrl-b prefix MUST NOT be accepted as the dotfiles default because it breaks tmux migration muscle memory.

### HERDR-CONFIG-003: Adopt Herdr Workspace Model

New work SHOULD be organized with one Herdr workspace per repo, task, or investigation. The system MUST NOT try to emulate tmux sessions exactly. Herdr tabs replace daily-use tmux windows, and Herdr panes replace tmux panes.

### HERDR-CONFIG-004: Preserve Local Runtime State Only

Pane history MAY be enabled in Herdr config, but all Herdr runtime state MUST remain outside git. The dotfiles repo MAY contain ignore rules protecting Herdr runtime paths, but MUST NOT track `session.json`, `session-history.json`, sockets, logs, or equivalent generated state.

### HERDR-CONFIG-005: Block Nested Herdr

The config MUST set nested Herdr launches to disabled. tmux remains installed and configured as a manual fallback for legacy nested multiplexer workflows.

### HERDR-CONFIG-006: SSH Default Replacement

The custom shell config MUST default SSH auto-attach to Herdr. If the configured override environment variable requests tmux, SSH auto-attach MUST use the tmux fallback path instead.

### HERDR-CONFIG-007: Repo-Owned Integrations

Herdr integrations for agents managed by this repo MUST be repo-owned. The implementation MAY use Herdr's upstream installer to inspect or generate source material, but it MUST NOT let `herdr integration install` directly mutate live default config paths as the authoritative deployment mechanism.

### HERDR-CONFIG-008: Shared Skill Distribution

The generic Herdr skill MUST live under `shared/skills/herdr/`, and the Claude Code specialization MUST live under `shared/skills/herdr-claude-code/`. Non-Pi agents receive both through their shared skills symlink. Pi receives both through `pi/skills/`. The specialization MUST compose the generic skill rather than copy its CLI mechanics.

### HERDR-CONFIG-009: Use the Current Agent Facade

The shared Herdr skill MUST use the installed stable CLI's agent facade for validated agent startup, atomic prompt submission, logical agent keys, output inspection, and server-owned settled-state waiting. Ordinary terminal commands MUST use the pane facade and its output wait. Removed top-level wait commands and client-owned status races MUST NOT remain in executable skill guidance.

---

## Error Handling

| Error Case | Trigger | Detection | Response | Recovery |
|------------|---------|-----------|----------|----------|
| Missing Herdr binary | Herdr config or SSH default selected but `herdr` is not on PATH | `command -v herdr` fails | Install Herdr through the direct curl installer module; if install fails, report module failure | Re-run install with network access |
| Herdr config conflict | `~/.config/herdr/config.toml` exists as a regular file | File exists and is not a symlink | Back up with timestamp and deploy symlink | Inspect backup if local settings are needed |
| Herdr runtime state in repo | Runtime files appear under tracked paths | Git status or ignore audit detects state/history files | Fail review or warn before commit | Move state out of repo and update ignore rules |
| Nested Herdr attempted | User launches Herdr from inside Herdr | Herdr detects existing Herdr session | Block launch according to upstream nested-launch behavior | Use tmux manually if nested multiplexer behavior is required |
| Direct integration mutation | `herdr integration install` writes to live config paths during install | Generated files appear directly under `~/.codex`, `~/.claude`, `~/.pi`, or `~/.copilot` outside dotfiles deploy flow | Treat as implementation violation; do not rely on mutated files | Capture desired generated files into repo-owned sources and redeploy |
| Removed Herdr command in a shared skill | Skill guidance references a command absent from installed stable help | Static skill check or command-group discovery finds the removed surface | Stop before delegation and update the shared skill to the current facade | Rerun skill tests and inspect installed help |

---

## Implementation Notes

1. **Default replacement, not immediate deletion**: Herdr becomes the default SSH multiplexer and appears in every installation profile, but tmux remains installed, configured, and aliased during migration.

2. **Config-only repository source**: The repo owns `herdr/config.toml` and Herdr integration source files. It does not own live sessions, pane history, or generated runtime state.

3. **Direct installer consistency**: Herdr MUST be installed through the official curl installer on both Linux and macOS. Homebrew is intentionally not used for this tool so `herdr update` remains the consistent update path.

4. **Integration ownership boundary**: Herdr integrations cross into agent config ownership. For Codex, Claude, Copilot, and Pi, implementation must add tracked source files and deploy them through existing agent config paths. Copilot's Herdr hook and hook-bearing settings use `~/.copilot`, independently of the repository's existing catalog exposure under `~/.config/copilot`.

5. **Pi layer boundary**: Herdr's Pi integration MUST be the tracked file `pi/extensions/herdr-agent-state.ts`, deployed to `~/.pi/agent/extensions/herdr-agent-state.ts` through the Pi agent config. It MUST NOT be installed by mutating live runtime files directly.

---

## Test Scenarios

```
TS-HERDR-001: Herdr config is deployed by symlink
Category: Integration
Priority: Critical
Preconditions: Herdr module selected; no target config exists
Input: Run install
Expected Output: ~/.config/herdr/config.toml is a symlink pointing to ~/dotfiles/herdr/config.toml

TS-HERDR-002: Existing Herdr config is backed up
Category: Integration
Priority: High
Preconditions: ~/.config/herdr/config.toml exists as a regular file
Input: Run Herdr config deployment
Expected Output: Existing file is moved to ~/.config/herdr/config.toml.backup.{TIMESTAMP}; symlink is created

TS-HERDR-003: Herdr prefix is Ctrl-a
Category: Integration
Priority: Critical
Preconditions: Herdr starts with deployed config
Input: Inspect config or press Ctrl-a followed by a Herdr command
Expected Output: Ctrl-a acts as Herdr prefix; Ctrl-b is not required for dotfiles-default operation

TS-HERDR-004: SSH auto-attach defaults to Herdr
Category: Integration
Priority: Critical
Preconditions: SSH session starts; DOTFILES_SSH_MULTIPLEXER is unset; HERDR_ENV is unset; TMUX is unset
Input: Start shell
Expected Output: Shell launches or attaches Herdr instead of tmux

TS-HERDR-005: SSH auto-attach can fall back to tmux
Category: Integration
Priority: High
Preconditions: SSH session starts; DOTFILES_SSH_MULTIPLEXER=tmux; TMUX is unset
Input: Start shell
Expected Output: Shell attaches to tmux session 0 or creates it

TS-HERDR-006: Pane history stays out of git
Category: Integration
Priority: High
Preconditions: Herdr pane history is enabled and Herdr has generated runtime state
Input: Run git status in ~/dotfiles
Expected Output: No Herdr session/history files appear as tracked or untracked repo files

TS-HERDR-007: Herdr integrations are repo-owned
Category: Integration
Priority: Critical
Preconditions: Herdr integrations module selected
Input: Run install
Expected Output: Integration files are deployed from dotfiles-managed sources; no direct default-path Herdr installer mutation is required for steady state

TS-HERDR-008: Herdr skills are available to all agents
Category: Integration
Priority: High
Preconditions: shared/skills/herdr/SKILL.md and shared/skills/herdr-claude-code/SKILL.md exist
Input: Inspect non-Pi skills symlinks and Pi skills
Expected Output: Non-Pi agents resolve both skills through shared/skills; Pi includes herdr and herdr-claude-code through pi/skills; the specialization composes the base skill

TS-HERDR-009: Shared skills use the current agent facade
Category: Integration
Priority: Critical
Preconditions: Stable Herdr is installed and the shared Herdr skills exist
Input: Compare executable skill commands with installed agent and pane command groups
Expected Output: Agent startup, prompts, keys, reads, and settled-state waits use the agent facade; ordinary output waits use the pane facade; no removed top-level wait command remains
```

---

## Changelog

| Version | Date | Summary |
|---------|------|---------|
| 0.3.0 | 2026-08-01 | Migrated shared skills to Herdr 0.7.5's agent facade and current Pi and Copilot integration targets. |
| 0.2.0 | 2026-07-15 | Added cross-agent distribution of the composing Claude Code Herdr specialization beside the generic base skill. |
| 0.1.1 | 2026-07-14 | Registered the Skill Library as a consumer of Herdr delegation and runtime-identity contracts. |
| 0.1.0 | 2026-07-05 | Initial Herdr migration spec: Herdr default replacement path, Ctrl-a parity, SSH default, runtime-state hygiene, repo-owned integrations, and shared Herdr skill distribution. |

# AI Agent Configuration Specification

> **Version**: 4.1.0
> **Last Updated**: 2026-08-01
> **Depends On**: [Parameters](parameters.md), [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md), [Design Language](DESIGN_LANGUAGE.md), [Symlink Manager](symlink-manager.md), [Tool Provisioning](tool-provisioning.md), [Herdr Config](herdr-config.md), [Skill Library](skill-library.md)
> **Depended By**: Install Orchestrator (INSTL)
> **Prefix**: AIAGT

---

## Overview

The AI Agent Configuration system provisions and configures four AI coding assistants: Codex CLI, Claude Code, Pi, and GitHub Copilot CLI. Each supported **agent** receives a repo-owned **agent config** deployed by the dotfiles symlink pattern, while mutable Pi settings remain local runtime state. It exposes the canonical [Skill Library](skill-library.md) to each runtime without owning skill content or authoring semantics.

The system MUST ensure that:

1. Each supported agent's runtime configuration directory is wired to the dotfiles repository through symlinks or documented template copies.
2. Sensitive data such as credentials, auth tokens, session history, and local runtime state NEVER enters version control.
3. Every supported agent exposes canonical Skill Library entries without creating agent-specific copies.
4. Codex and Pi are installed to the user-local npm prefix so binaries survive Node.js version manager switches.
5. The install process is **idempotent**.
6. Herdr integrations for managed agents are repo-owned and deployed through dotfiles-managed config paths.

---

## Parameters

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `NPM_GLOBAL_PREFIX` | `~/.local` | Shared prefix for npm-installed agents so binaries survive fnm Node version switches |
| `AGENT_CONFIG_DIR_CODEX` | `~/.codex` | Codex CLI runtime config directory |
| `AGENT_CONFIG_DIR_CLAUDE` | `~/.claude` | Claude Code runtime config directory |
| `AGENT_CONFIG_DIR_PI` | `~/.pi/agent` | Pi's single runtime config directory |
| `AGENT_CONFIG_DIR_COPILOT` | `~/.config/copilot` | Repository-managed Copilot catalog exposure directory |
| `AGENT_STATE_DIR_COPILOT` | `~/.copilot` | Current Copilot runtime settings and Herdr hook directory |
| `AGENT_SKILLS_DIR_CODEX` | `~/.agents/skills` | Codex skill path, symlinked to shared skills |
| `AGENT_SKILLS_DIR_PI` | `~/.pi/agent/skills` | Pi skill path, symlinked to `pi/skills` |
| `SANDBOX_BASE_IMAGE_NAME` | `dotfiles-dev-base:{UID}-{GID}` | Shared Docker base image for agent sandboxes |
| `SANDBOX_IMAGE_NAME` | `pis:latest` | Pi sandbox image |
| `CODEX_SANDBOX_IMAGE_NAME` | `cods:latest` | Codex sandbox image |

---

## Deployment

### Codex CLI

| Target Path | Source Path | Deploy Mode |
|-------------|-------------|-------------|
| `~/.codex/config.toml` | `codex/config.toml` | copy from template, preserving local updates |
| `~/.codex/agents/` | `codex/agents/` | symlink |
| `~/.codex/AGENTS.md` | `codex/AGENTS.md` | symlink when present |
| `~/.codex/herdr-agent-state.sh` | `herdr/integrations/codex/herdr-agent-state.sh` | symlink |
| `~/.agents/skills/` | `shared/skills/` | symlink |
| `~/.local/bin/cods` | `codex/cods.sh` | symlink |

### Claude Code

| Target Path | Source Path | Deploy Mode |
|-------------|-------------|-------------|
| `~/.claude/commands/` | `claude/commands/` | symlink |
| `~/.claude/agents/` | `claude/agents/` | symlink |
| `~/.claude/skills/` | `shared/skills/` | symlink |
| `~/.claude/settings.json` | — | local file; generate, migrate, and preserve |
| `~/.claude/statusline.sh` | `claude/statusline.sh` | symlink when present |
| `~/.claude/hooks/herdr-agent-state.sh` | `herdr/integrations/claude/herdr-agent-state.sh` | symlink |

`~/.claude/settings.json` is mutable local runtime state and MUST NOT be symlinked to a tracked file. Installation MUST preserve existing local settings across upstream installer runs, migrate the resolved content of the legacy managed settings symlink into a regular local file, and configure the tracked `~/.claude/statusline.sh` command without replacing unrelated settings.

### Pi Coding Agent

Pi has one runtime config rooted at `~/.pi/agent`; tracked resources are repo-owned while mutable settings remain local.

| Target Path | Source Path | Deploy Mode |
|-------------|-------------|-------------|
| `~/.pi/agent/settings.json` | — | local file; initialize, migrate, and preserve |
| `~/.pi/agent/models.json` | `pi/models.json` | symlink |
| `~/.pi/agent/skills/` | `pi/skills/` | symlink |
| `~/.pi/agent/extensions/herdr-agent-state.ts` | `pi/extensions/herdr-agent-state.ts` | symlink |
| `~/.pi/agent/extensions/inherit-last-model/` | `pi/extensions/inherit-last-model/` | symlink |
| `~/.pi/agent/extensions/web-search/` | `pi/extensions/web-search/` | symlink |
| `~/.local/bin/pi` | `pi/pi.sh` | symlink wrapper |
| `~/.local/bin/pis` | `pi/pis.sh` | symlink wrapper |

`~/.pi/agent/settings.json`, `~/.pi/agent/auth.json`, and `~/.pi/agent/sessions/` are local runtime state and MUST NOT be symlinked to tracked files. When migrating a legacy managed settings symlink, installation MUST preserve its resolved content in a regular local file.

### GitHub Copilot CLI

| Target Path | Source Path | Deploy Mode |
|-------------|-------------|-------------|
| `~/.config/copilot/commands/` | `copilot/commands/` | symlink |
| `~/.config/copilot/agents/` | `copilot/agents/` | symlink |
| `~/.config/copilot/skills/` | `shared/skills/` | symlink |
| `~/.copilot/hooks/herdr-agent-state.sh` | `herdr/integrations/copilot/herdr-agent-state.sh` | symlink |
| `~/.copilot/settings.json` | — | local file; preserve and add the Herdr SessionStart hook |

---

## Installation

| Agent | Installer | Requirement |
|-------|-----------|-------------|
| Codex CLI | npm global with `--prefix ~/.local` | Binary must land in `~/.local/bin/` |
| Pi | npm global with `--prefix ~/.local` | The npm `pi` binary is preserved as `~/.local/bin/pi-bin`; wrapper owns `~/.local/bin/pi` |
| Claude Code | official curl installer | Local settings are preserved and the tracked status line is configured after installer runs |
| Copilot CLI | official curl installer | Binary lands under the user-local path |

The installer MUST remove legacy Pi wrapper symlinks for `pim`, `pi-*`, and `pis-*` when they point at dotfiles-managed Pi wrapper scripts.

When the Copilot Herdr integration is configured, the installer MUST migrate away the prior legacy hook deployment under `~/.config/copilot`: it MUST remove the dotfiles-managed legacy hook symlink at `~/.config/copilot/hooks/herdr-agent-state.sh` only when it points at the tracked Copilot integration source, and MUST remove the exact-matching `SessionStart` entry from `~/.config/copilot/settings.json` whose command equals that legacy hook's command. The installer MUST preserve unrelated settings and unrelated hook entries in the legacy settings file, MUST NOT delete the legacy settings file or user-owned hooks, and MUST prune emptied `SessionStart` arrays and `hooks` objects without removing non-empty containers.

---

## Pi Sandbox

The `pis` script provides a Docker sandbox wrapper for Pi.

1. The Pi sandbox image MUST build from the shared sandbox base image.
2. The current working directory MUST be mounted read-write at its original path.
3. `~/.pi/agent/sessions` MUST be mounted read-write.
4. `~/.pi/agent/auth.json`, `settings.json`, `models.json`, `skills`, and `extensions` MUST be mounted read-only.
5. The container MUST run as the host user.
6. The `HOME` environment variable inside the container MUST be set to `/home/{HOST_USER}`.
7. API key environment variables MUST be forwarded for well-known keys (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GOOGLE_API_KEY`) and any variables matching `*_API_KEY`, `*_API_TOKEN`, or `*_APIKEY`.
8. Extra directories specified as positional arguments MUST be mounted read-only by default; `-rw` switches the next path to read-write.
9. `--no-rebuild` skips the version check; `--build` forces a build.
10. Containers MUST be ephemeral and removed on exit.

---

## Sensitive Data

| Agent | Excluded Categories |
|-------|---------------------|
| Codex CLI | Credentials, session/history data, local runtime state, local config overrides |
| Claude Code | Credentials, session/history data, project-specific data, mutable settings, local runtime state, debug artifacts |
| Pi | Credentials, session/history data, local runtime binaries, sessions, auth files, mutable settings |
| Copilot CLI | Auth state and local runtime data under `~/.copilot`, plus unrelated local state under the user's XDG config directory |

---

## Skill Library Integration

The [Skill Library](skill-library.md) owns canonical skill definitions, discovery metadata, skill-body semantics, progressive disclosure, composition, provenance, workflow-state contracts, and semantic review.

AI Agent Configuration owns only catalog exposure:

1. Claude, Codex, and Copilot MUST receive the canonical shared catalog through their configured skills paths.
2. Pi MUST receive the tracked `pi/skills/` visibility layer, whose entries point to canonical shared skills.
3. Agent-specific deployment MUST NOT duplicate or rewrite canonical skill definitions.
4. Catalog deployment and semantic catalog validation MUST remain separate concerns.

## Behavior Rules

1. Pi-visible skills under `pi/skills/` SHOULD be symlinks to canonical Skill Library entries.
2. The Pi config surface MUST remain single-config. Do not reintroduce Pi profiles, `pim`, profile-local skills, profile runtimes, sub-agent roles, or the subagent extension.
3. The Pi extension set is fixed to the `herdr-agent-state.ts` file and the `inherit-last-model` and `web-search` directories.
4. The install process MUST prune stale Pi extension symlinks from `~/.pi/agent/extensions/` when the source extension is no longer shipped.
5. Herdr integration deployment MUST use repo-owned hook files and dotfiles-managed config paths.

---

## Test Scenarios

### TS-AIAGT-001: Shared Skill Links

Preconditions: Agent modules are installed.

Input: Inspect `~/.claude/skills`, `~/.agents/skills`, `~/.pi/agent/skills`, and `~/.config/copilot/skills`.

Expected Output: Claude, Codex, and Copilot skills paths resolve to `shared/skills`; Pi resolves to `pi/skills`.

### TS-AIAGT-002: Single Pi Config Deployment

Preconditions: The Pi module runs.

Input: Inspect `~/.pi/agent`.

Expected Output: `models.json`, `skills`, and the three shipped extensions are symlinks to the dotfiles repo. `settings.json`, `auth.json`, and `sessions/` are local state; a legacy settings symlink is migrated without losing its content.

### TS-AIAGT-003: Removed Pi Surfaces Stay Removed

Preconditions: The Pi module runs after an older profile-based install.

Input: Inspect `~/.local/bin` and `~/.pi/agent/extensions`.

Expected Output: dotfiles-managed `pim`, `pi-*`, and `pis-*` symlinks are absent, and `subagent` is not deployed.

### TS-AIAGT-004: Pi Sandbox Mounts Single Runtime

Preconditions: `~/.pi/agent` exists.

Input: Run `PIS_DRY_RUN=1 pis`.

Expected Output: Runtime, sessions, and auth paths all point under `~/.pi/agent`.

### TS-AIAGT-005: Canonical Catalog Exposure

Category: Integration
Priority: High
Preconditions: The repository checkout contains the canonical Skill Library and tracked Pi visibility entries.
Input: Compare the canonical catalog with Claude, Codex, Copilot, and Pi skill paths.
Expected Output: Claude, Codex, and Copilot expose the canonical catalog directly; every Pi-visible entry resolves to a canonical skill; no agent-specific deployment duplicates or rewrites a skill definition.

### TS-AIAGT-006: Current Herdr Integration Targets

Category: Integration
Priority: Critical
Preconditions: Managed agents and the Herdr integrations module are installed.
Input: Inspect each deployed Herdr integration and its hook-bearing local settings.
Expected Output: Claude and Codex hooks resolve to their tracked shell sources, Pi resolves `herdr-agent-state.ts` to its tracked file, and Copilot resolves its hook under `~/.copilot` while preserving local settings. When a prior legacy Copilot hook exists under `~/.config/copilot`, the dotfiles-managed legacy hook symlink and its exact-matching `SessionStart` entry are removed while unrelated settings and hooks survive and emptied containers are pruned.

---

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 4.1.0 | 2026-08-01 | Required migration of the legacy `~/.config/copilot` Herdr hook: remove the dotfiles-managed legacy symlink and exact-matching `SessionStart` entry while preserving unrelated settings and hooks and pruning emptied containers. |
| 4.0.0 | 2026-08-01 | Migrated Pi's Herdr integration to a single TypeScript file, registered current Claude/Codex/Copilot hook targets, and separated Copilot catalog exposure from its runtime hook root. |
| 3.2.0 | 2026-07-15 | Made mutable Claude settings unversioned local state and required preservation across installation and migration. |
| 3.1.0 | 2026-07-15 | Made mutable Pi settings unversioned local state with content-preserving migration from the legacy managed symlink. |
| 3.0.0 | 2026-07-15 | Removed retired catalog visibility entries and specialist agent surfaces. |
| 2.4.0 | 2026-07-14 | Moved shared-skill content, authoring, composition, provenance, and workflow-state contracts into the Skill Library bounded context; retained catalog exposure and runtime deployment ownership. |
| 2.3.0 | 2026-07-14 | Added the canonical shared-skill body and semantic YAGNI contracts, behavior-preservation gates, catalog ownership and composition boundaries, qualified workflow artifacts, provenance gates, and verification scenarios. |
| 2.2.0 | 2026-07-14 | Added teaching workflows, a recoverable file-based plan control plane, domain-aware grilling, and repaired post-decomposition skill visibility. |
| 2.1.0 | 2026-07-14 | Added locally maintained cross-agent workflow skills, delegation fallbacks, provenance requirements, and the visual architecture-report contract. |
| 2.0.0 | 2026-07-08 | Unshipped retired agent/profile/delegation surfaces. Pi now deploys one repo-owned config under `~/.pi/agent`. |

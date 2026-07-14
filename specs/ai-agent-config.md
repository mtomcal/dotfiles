# AI Agent Configuration Specification

> **Version**: 2.1.0
> **Last Updated**: 2026-07-14
> **Depends On**: [Parameters](parameters.md), [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md), [Design Language](DESIGN_LANGUAGE.md), [Herdr Config](herdr-config.md)
> **Depended By**: Install Orchestrator (INSTL)
> **Prefix**: AIAGT

---

## Overview

The AI Agent Configuration system provisions and configures four AI coding assistants: Codex CLI, Claude Code, Pi, and GitHub Copilot CLI. Each supported **agent** receives a repo-owned **agent config** deployed by the dotfiles symlink pattern. Cross-agent skills live in the canonical **shared skills directory**; Pi exposes those skills through `pi/skills/`.

The system MUST ensure that:

1. Each supported agent's runtime configuration directory is wired to the dotfiles repository through symlinks or documented template copies.
2. Sensitive data such as credentials, auth tokens, session history, and local runtime state NEVER enters version control.
3. The shared skills directory is the single source of truth for cross-agent skill definitions.
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
| `AGENT_CONFIG_DIR_COPILOT` | `~/.config/copilot` | Copilot CLI runtime config directory |
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
| `~/.agents/skills/` | `shared/skills/` | symlink |
| `~/.local/bin/cods` | `codex/cods.sh` | symlink |

### Claude Code

| Target Path | Source Path | Deploy Mode |
|-------------|-------------|-------------|
| `~/.claude/commands/` | `claude/commands/` | symlink |
| `~/.claude/agents/` | `claude/agents/` | symlink |
| `~/.claude/skills/` | `shared/skills/` | symlink |
| `~/.claude/settings.json` | `claude/settings.json` | symlink when present |
| `~/.claude/statusline.sh` | `claude/statusline.sh` | symlink when present |

### Pi Coding Agent

Pi has one repo-owned runtime config rooted at `~/.pi/agent`.

| Target Path | Source Path | Deploy Mode |
|-------------|-------------|-------------|
| `~/.pi/agent/settings.json` | `pi/settings.json` | symlink |
| `~/.pi/agent/models.json` | `pi/models.json` | symlink |
| `~/.pi/agent/skills/` | `pi/skills/` | symlink |
| `~/.pi/agent/extensions/herdr-agent-state/` | `pi/extensions/herdr-agent-state/` | symlink |
| `~/.pi/agent/extensions/inherit-last-model/` | `pi/extensions/inherit-last-model/` | symlink |
| `~/.pi/agent/extensions/web-search/` | `pi/extensions/web-search/` | symlink |
| `~/.local/bin/pi` | `pi/pi.sh` | symlink wrapper |
| `~/.local/bin/pis` | `pi/pis.sh` | symlink wrapper |

`~/.pi/agent/auth.json` and `~/.pi/agent/sessions/` are local runtime state and MUST NOT be symlinked to tracked files.

### GitHub Copilot CLI

| Target Path | Source Path | Deploy Mode |
|-------------|-------------|-------------|
| `~/.config/copilot/commands/` | `copilot/commands/` | symlink |
| `~/.config/copilot/agents/` | `copilot/agents/` | symlink |
| `~/.config/copilot/skills/` | `shared/skills/` | symlink |

---

## Installation

| Agent | Installer | Requirement |
|-------|-----------|-------------|
| Codex CLI | npm global with `--prefix ~/.local` | Binary must land in `~/.local/bin/` |
| Pi | npm global with `--prefix ~/.local` | The npm `pi` binary is preserved as `~/.local/bin/pi-bin`; wrapper owns `~/.local/bin/pi` |
| Claude Code | official curl installer | Dotfiles settings are restored after installer runs |
| Copilot CLI | official curl installer | Binary lands under the user-local path |

The installer MUST remove legacy Pi wrapper symlinks for `pim`, `pi-*`, and `pis-*` when they point at dotfiles-managed Pi wrapper scripts.

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
| Claude Code | Credentials, session/history data, project-specific data, local runtime state, debug artifacts |
| Pi | Credentials, session/history data, local runtime binaries, sessions, auth files |
| Copilot CLI | Auth state and local runtime data under the user's XDG config directory |

---

## Shared Skill Contract

Every newly added or modified shared skill MUST provide the cross-agent frontmatter fields `name`, `description`, `metadata.short-description`, and `allowed-tools`. Descriptions MUST state concrete `Use when` triggers and remain within the supported 1024-character limit.

The shipped workflow catalog includes these locally owned skills:

| Skill | Required behavior |
|-------|-------------------|
| `codebase-design` | Owns deep-module vocabulary and progressively disclosed deepening and alternative-interface guidance |
| `diagnosing-bugs` | Establishes a tight red-capable command, minimizes the reproduction, tests ranked hypotheses, and routes fixes through TDD |
| `code-review` | Keeps Standards and Spec reviews independent, with Herdr delegation or an in-process fallback |
| `resolving-merge-conflicts` | Traces both intents, stages verified resolutions, and leaves commit/continue operations to explicit user approval |
| `handoff` | Writes redacted timestamped Markdown under the OS temporary handoff directory and reports the absolute path |
| `research` | Produces durable primary-source-backed notes using the repository's existing convention or an approved location |
| `improve-codebase-architecture` | Always produces a temporary visual HTML report with before/after diagrams and candidate comparison |

Imported skill material MUST be treated as a locally maintained fork: provenance and required license attribution MUST live in the repository-level `THIRD_PARTY_NOTICES.md`, while automatic upstream synchronization is outside the shipped contract.

When a skill delegates work under `HERDR_ENV=1`, it SHOULD load the shared Herdr skill rather than duplicate Herdr commands. The same workflow MUST provide an in-process fallback outside Herdr. Read-only delegated agents MAY share a checkout; delegated agents that edit files MUST use isolated clones or worktrees.

## Behavior Rules

1. Shared skills MUST live under `shared/skills/`.
2. Pi-visible skills under `pi/skills/` SHOULD be symlinks to `shared/skills/`.
3. The Pi config surface MUST remain single-config. Do not reintroduce Pi profiles, `pim`, profile-local skills, profile runtimes, sub-agent roles, or the subagent extension.
4. The Pi extension set is fixed to `herdr-agent-state`, `inherit-last-model`, and `web-search`.
5. The install process MUST prune stale Pi extension symlinks from `~/.pi/agent/extensions/` when the source extension is no longer shipped.
6. Herdr integration deployment MUST use repo-owned hook files and dotfiles-managed config paths.

---

## Test Scenarios

### TS-AIAGT-001: Shared Skill Links

Preconditions: Agent modules are installed.

Input: Inspect `~/.claude/skills`, `~/.agents/skills`, `~/.pi/agent/skills`, and `~/.config/copilot/skills`.

Expected Output: Claude, Codex, and Copilot skills paths resolve to `shared/skills`; Pi resolves to `pi/skills`.

### TS-AIAGT-002: Single Pi Config Deployment

Preconditions: The Pi module runs.

Input: Inspect `~/.pi/agent`.

Expected Output: `settings.json`, `models.json`, `skills`, and the three shipped extensions are symlinks to the dotfiles repo. `auth.json` and `sessions/` are local state.

### TS-AIAGT-003: Removed Pi Surfaces Stay Removed

Preconditions: The Pi module runs after an older profile-based install.

Input: Inspect `~/.local/bin` and `~/.pi/agent/extensions`.

Expected Output: dotfiles-managed `pim`, `pi-*`, and `pis-*` symlinks are absent, and `subagent` is not deployed.

### TS-AIAGT-004: Pi Sandbox Mounts Single Runtime

Preconditions: `~/.pi/agent` exists.

Input: Run `PIS_DRY_RUN=1 pis`.

Expected Output: Runtime, sessions, and auth paths all point under `~/.pi/agent`.

### TS-AIAGT-005: Cross-Agent Workflow Skills

Preconditions: The repository checkout contains the shipped shared skill catalog.

Input: Audit shared skill frontmatter and inspect Pi-visible entries for `codebase-design`, `diagnosing-bugs`, `code-review`, `resolving-merge-conflicts`, `handoff`, and `research`.

Expected Output: Required frontmatter is valid, every named Pi entry resolves to its canonical shared skill, and provenance attribution is present in the repository-level `THIRD_PARTY_NOTICES.md`.

---

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 2.1.0 | 2026-07-14 | Added locally maintained cross-agent workflow skills, delegation fallbacks, provenance requirements, and the visual architecture-report contract. |
| 2.0.0 | 2026-07-08 | Unshipped retired agent/profile/delegation surfaces. Pi now deploys one repo-owned config under `~/.pi/agent`. |

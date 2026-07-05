# Herdr Migration Implementation Plan
## Default replacement path for tmux

> **Status: PLANNING** - Spec-driven from `specs/herdr-config.md` plus grill-me decisions from 2026-07-05.

## Overview

Implement Herdr as the default terminal workspace manager while keeping tmux configured as a legacy fallback. The migration installs Herdr in every standard installation profile, deploys `herdr/config.toml`, changes SSH auto-attach to Herdr by default with a tmux override, adds Herdr-specific aliases, tracks the upstream Herdr skill in `shared/skills/herdr/`, and installs repo-owned Herdr integrations for managed agents without letting Herdr mutate live config paths as the source of truth.

## Decisions

| # | Question | Decision | Source |
|---|----------|----------|--------|
| D1 | Default strategy | Herdr begins the default replacement path for tmux | grill-me |
| D2 | SSH auto-attach | SSH defaults to Herdr; `DOTFILES_SSH_MULTIPLEXER=tmux` falls back | grill-me |
| D3 | Prefix parity | Herdr prefix is `ctrl+a` | grill-me and Herdr docs |
| D4 | Top-level model | Adopt Herdr workspaces as repo/task/investigation units | grill-me |
| D5 | Nested behavior | Block nested Herdr; keep tmux as legacy nested fallback | grill-me |
| D6 | Advanced tmux ops | Defer merge/explode/reverse/equalize parity | grill-me |
| D7 | Pane history | Enable Herdr pane history if it stays out of git | grill-me |
| D8 | Install method | Use Herdr official curl installer on Linux and macOS | grill-me |
| D9 | Profiles | Include Herdr modules in full, minimal, and work profiles | grill-me |
| D10 | Aliases | Keep tmux `t*`; add Herdr `h*` aliases | grill-me |
| D11 | Integrations | Install automatically, but as repo-owned dotfiles artifacts | grill-me |
| D12 | Skill | Track Herdr skill under shared skills and include Pi via rebuild | grill-me |

## Spec Delta To Implement

1. `specs/herdr-config.md` defines Herdr config deployment, Ctrl-a parity, SSH default behavior, runtime-state hygiene, and repo-owned integrations.
2. `specs/shell-config.md` changes SSH auto-attach from tmux-only to Herdr-first with tmux/none overrides.
3. `specs/tool-provisioning.md` adds Herdr direct curl installer behavior.
4. `specs/install-orchestrator.md` adds `herdr`, `herdr_config`, and `herdr_integrations` modules to every standard profile.
5. `specs/ai-agent-config.md` adds shared Herdr skill and repo-owned Herdr integration contracts.
6. `specs/symlink-manager.md` adds `~/.config/herdr/config.toml` symlink deployment.

## Current Code State

Already correct:

- tmux config is complete and should remain available as fallback.
- `install.sh` already has module selection, dependency resolution, symlink backup patterns, and shell config deployment.
- shared skills architecture exists under `shared/skills/` and Pi consumes shared skills through profile resolved output.

Out of alignment:

- No `herdr/` source directory or `herdr/config.toml` exists.
- `install.sh` has no Herdr modules and standard profiles do not include Herdr.
- `zsh/.zshrc.custom` auto-attaches tmux on SSH and lacks Herdr aliases.
- Herdr shared skill and repo-owned integrations are absent.
- Specs now require behavior that implementation does not yet satisfy.

Important constraint:

Do not remove tmux config or aliases. Herdr becomes the default path, not a destructive tmux deletion. Do not run `herdr integration install` against live agent config paths as the steady-state implementation.

## Intended Implementation Shape

Add Herdr as its own small module family: `install_herdr`, `configure_herdr`, and `configure_herdr_integrations`. Keep integration deployment conservative: first create repo-owned source artifacts, then deploy through existing agent config/Profile lifecycle paths. Implement SSH switching in `zsh/.zshrc.custom` with explicit guards for `HERDR_ENV`, `TMUX`, `SSH_CONNECTION`, and `DOTFILES_SSH_MULTIPLEXER`.

## Red/Green TDD Slices

### Slice 1: Herdr Config Deployment

#### Red - Write tests first, no implementation code yet

- Test file: `tests/install/herdr-config.bats` or the repo's nearest existing install test harness.
- What the test proves: `configure_herdr` creates `~/.config/herdr/config.toml` as a symlink to `~/dotfiles/herdr/config.toml`, backs up existing regular files, and is idempotent.
- Assertion strategy: filesystem assertions in a temporary HOME.
- Existing tests to rewrite: none.

#### Green - Make the red test pass, minimum change only

- Source files: `install.sh`, `herdr/config.toml`.
- What to change: add `configure_herdr`; create Herdr TOML with `keys.prefix = "ctrl+a"`, pane history enabled, nested disabled, and agent restore enabled.
- Constraint: do not add integrations yet.
- Decisions/spec delta this satisfies: D3, D7, `HERDR-CONFIG-001`.

#### Refactor

- Extract common symlink helper only if existing duplication makes the Herdr module noisy.

### Slice 2: Herdr Direct Install Module

#### Red - Write tests first, no implementation code yet

- Test file: `tests/install/herdr-install.bats`.
- What the test proves: `install_herdr` skips when `herdr` exists, otherwise invokes `curl -fsSL https://herdr.dev/install.sh | sh`, and fails if `herdr` is still unavailable.
- Assertion strategy: stub `command`, `curl`, and PATH in a temporary environment.

#### Green - Make the red test pass, minimum change only

- Source file: `install.sh`.
- What to change: add `install_herdr`; add dependency resolver entries for `herdr` and `herdr_config`.
- Constraint: use curl on macOS and Linux; do not use Homebrew.
- Decisions/spec delta this satisfies: D8.

#### Refactor

- Keep installer logic isolated from Herdr config deployment.

### Slice 3: Standard Profile Wiring

#### Red - Write tests first, no implementation code yet

- Test file: `tests/install/profiles-herdr.bats`.
- What the test proves: `full`, `minimal`, and `work` resolve Herdr modules, and custom module validation accepts them.
- Assertion strategy: run module selection/dependency resolution in isolation.

#### Green - Make the red test pass, minimum change only

- Source file: `install.sh`.
- What to change: add module identifiers, labels, help text, summary labels, execution dispatch, and standard profile membership.
- Constraint: keep tmux_config in all existing profiles.
- Decisions/spec delta this satisfies: D1, D9.

#### Refactor

- None unless module labels are duplicated in several switch statements.

### Slice 4: Shell Aliases And SSH Default

#### Red - Write tests first, no implementation code yet

- Test file: `tests/shell/herdr-ssh.bats`.
- What the test proves: `h`, `ha`, `hl`, and `hu` aliases exist; SSH auto-attach runs Herdr by default; `DOTFILES_SSH_MULTIPLEXER=tmux` uses tmux session `0`; `none` disables auto-attach; existing `t*` aliases remain tmux.
- Assertion strategy: source `zsh/.zshrc.custom` with stubbed commands and environment variables.

#### Green - Make the red test pass, minimum change only

- Source file: `zsh/.zshrc.custom`.
- What to change: add Herdr aliases and replace tmux-only SSH rule with Herdr-first multiplexer selection.
- Constraint: do not start Herdr in local non-SSH shells.
- Decisions/spec delta this satisfies: D2, D10.

#### Refactor

- Extract a small shell function only if the conditional becomes hard to audit.

### Slice 5: Shared Herdr Skill

#### Red - Write tests first, no implementation code yet

- Test file: use `audit-shared-skills` or a lightweight test checking `shared/skills/herdr/SKILL.md` frontmatter and Pi symlink/resolved inclusion expectation.
- What the test proves: Herdr skill exists with required cross-agent frontmatter.
- Assertion strategy: parse frontmatter fields; verify no duplicate profile-local skill names.

#### Green - Make the red test pass, minimum change only

- Source files: `shared/skills/herdr/SKILL.md`, `pi/skills/herdr` symlink if Pi still needs the runtime symlink catalog.
- What to change: add the Herdr skill from upstream instructions, preserving cross-agent frontmatter.
- Constraint: do not install the skill only into a global external skill location.
- Decisions/spec delta this satisfies: D12.

#### Refactor

- Run `audit-shared-skills` and fix only compatibility issues it reports.

### Slice 6: Repo-Owned Herdr Integrations

#### Red - Write tests first, no implementation code yet

- Test file: `tests/install/herdr-integrations.bats`.
- What the test proves: integration module deploys repo-owned artifacts for existing Codex/Claude/Pi/Copilot configs, skips missing agents, and does not require live-path mutation by `herdr integration install`.
- Assertion strategy: temporary HOME with selected config directories present/absent; assert deployed files originate from repo paths.

#### Green - Make the red test pass, minimum change only

- Source files: `install.sh`, agent config source directories, Pi profile source/resolved artifacts as required.
- What to change: add `configure_herdr_integrations` and source artifacts for Codex, Claude, Pi, and Copilot.
- Constraint: for Pi, write through profile source/resolved lifecycle, not directly to `~/.pi/agent`.
- Decisions/spec delta this satisfies: D11.

#### Refactor

- If integration generation is complex, move it into a small repo script and keep `install.sh` orchestration thin.

### Slice 7: Docs And Final Spec Sync

#### Red - Write tests first, no implementation code yet

- Test file: documentation/spec consistency checks, or manual grep checklist if no doc test harness exists.
- What the test proves: README, AGENTS map, specs, and install help all mention Herdr modules consistently.
- Assertion strategy: grep for module list/profile references and stale "tmux + neovim + zsh" claims.

#### Green - Make the red test pass, minimum change only

- Source files: `README.md`, `AGENTS.md` if needed, specs changelogs if implementation changes spec contracts.
- What to change: update user-facing install/module docs and migration notes.
- Constraint: do not document Herdr integrations as live-path installer-owned.

#### Refactor

- Keep docs concise; link to specs for full contracts.

## Verification

Local verification sequence:

1. Run targeted install/shell tests added in each slice.
2. Run `shellcheck install.sh zsh/.zshrc.custom` if shellcheck is available.
3. Run `./install.sh --help` and verify Herdr modules appear.
4. Run dry-run or temp-HOME install tests for `--profile minimal`, `--profile work`, and `--profile full`.
5. Run `audit-shared-skills` after adding `shared/skills/herdr/`.
6. Run `git status --short` after exercising Herdr locally and confirm no Herdr runtime/history files appear.

Review passes:

- Test-quality pass: verify tests assert behavior rather than implementation detail.
- Premortem pass: focus on SSH login lockout, PATH issues, direct integration mutation, Pi profile layer confusion, and accidental history commits.
- Manual smoke pass: start Herdr, confirm Ctrl-a prefix, split/focus panes, detach/reattach, and SSH override behavior.

## Acceptance Criteria

1. `./install.sh --profile minimal`, `work`, and `full` include Herdr modules.
2. `~/.config/herdr/config.toml` is deployed from `~/dotfiles/herdr/config.toml`.
3. Herdr uses `ctrl+a`, pane history is enabled, nested Herdr launches are disabled.
4. SSH sessions default to Herdr, `DOTFILES_SSH_MULTIPLEXER=tmux` uses tmux, and `none` disables auto-attach.
5. Existing tmux aliases remain unchanged; Herdr aliases use the `h*` family.
6. `shared/skills/herdr/SKILL.md` exists and passes shared-skill audit.
7. Herdr integrations for Codex, Claude, Pi, and Copilot are repo-owned and skip missing agents.
8. Herdr runtime/session/history files stay out of git.

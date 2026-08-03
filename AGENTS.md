# AI Agent Instructions

This file provides guidance to AI coding agents when working with this dotfiles repo — a Herdr + tmux fallback + neovim + zsh environment using symlinks to deploy configs. Claude Code, Codex, Pi, and GitHub Copilot CLI all share context through this file. Cross-agent skills live in `shared/skills/`; Pi sees those skills through `pi/skills/`.

## Map

<!-- TREE-HASH: ddb7f58a572b1a3043ecee3a1a4b8fb8fd2f8b95050a398c3d5f8d7fe5411a7c -->

<!-- TREE-START -->
```
.
|-- claude
|   `-- agents
|-- codex
|   `-- agents
|-- copilot
|   |-- agents
|   `-- commands
|-- docker
|-- herdr
|   `-- integrations
|       |-- claude
|       |-- codex
|       `-- copilot
|-- lazygit
|-- nvim
|   `-- custom
|       `-- plugins
|-- pi
|   |-- extensions
|   |   |-- inherit-last-model
|   |   `-- web-search
|   |-- skills
|   |   |-- audit-shared-skills -> ../../shared/skills/audit-shared-skills
|   |   |-- beads -> ../../shared/skills/beads
|   |   |-- bootstrap-specs -> ../../shared/skills/bootstrap-specs
|   |   |-- codebase-design -> ../../shared/skills/codebase-design
|   |   |-- code-review -> ../../shared/skills/code-review
|   |   |-- create-agents-md -> ../../shared/skills/create-agents-md
|   |   |-- create-engineering-plan -> ../../shared/skills/create-engineering-plan
|   |   |-- curator -> ../../shared/skills/curator
|   |   |-- design-md -> ../../shared/skills/design-md
|   |   |-- diagnosing-bugs -> ../../shared/skills/diagnosing-bugs
|   |   |-- execute-engineering-molecule -> ../../shared/skills/execute-engineering-molecule
|   |   |-- grill-me -> ../../shared/skills/grill-me
|   |   |-- handoff -> ../../shared/skills/handoff
|   |   |-- herdr -> ../../shared/skills/herdr
|   |   |-- herdr-claude-code -> ../../shared/skills/herdr-claude-code
|   |   |-- herdr-supervise -> ../../shared/skills/herdr-supervise
|   |   |-- herdr-watchdog -> ../../shared/skills/herdr-watchdog
|   |   |-- improve-codebase-architecture -> ../../shared/skills/improve-codebase-architecture
|   |   |-- playwright -> ../../shared/skills/playwright
|   |   |-- prototype -> ../../shared/skills/prototype
|   |   |-- python-tracing -> ../../shared/skills/python-tracing
|   |   |-- research -> ../../shared/skills/research
|   |   |-- resolving-merge-conflicts -> ../../shared/skills/resolving-merge-conflicts
|   |   |-- tdd -> ../../shared/skills/tdd
|   |   |-- teach -> ../../shared/skills/teach
|   |   |-- test-quality-verifier -> ../../shared/skills/test-quality-verifier
|   |   |-- ubiquitous-language -> ../../shared/skills/ubiquitous-language
|   |   |-- update-specs -> ../../shared/skills/update-specs
|   |   |-- video-to-contact-sheet -> ../../shared/skills/video-to-contact-sheet
|   |   |-- visual-explainer -> ../../shared/skills/visual-explainer
|   |   `-- write-a-skill -> ../../shared/skills/write-a-skill
|   `-- tests
|-- shared
|   `-- skills
|       |-- audit-shared-skills
|       |-- beads
|       |-- bootstrap-specs
|       |-- codebase-design
|       |-- code-review
|       |-- create-agents-md
|       |   `-- scripts
|       |-- create-engineering-plan
|       |-- curator
|       |-- design-md
|       |-- diagnosing-bugs
|       |-- execute-engineering-molecule
|       |-- grill-me
|       |-- handoff
|       |-- herdr
|       |-- herdr-claude-code
|       |-- herdr-supervise
|       |-- herdr-watchdog
|       |-- improve-codebase-architecture
|       |-- playwright
|       |   `-- references
|       |-- prototype
|       |-- python-tracing
|       |   `-- references
|       |-- research
|       |-- resolving-merge-conflicts
|       |-- tdd
|       |-- teach
|       |-- test-quality-verifier
|       |-- ubiquitous-language
|       |-- update-specs
|       |-- video-to-contact-sheet
|       |-- visual-explainer
|       |   |-- references
|       |   `-- templates
|       `-- write-a-skill
|-- specs
|-- tests
|   `-- lib
|-- tmux
|-- vscode
|   |-- extensions
|   `-- snippets
|-- yazi
`-- zsh

102 directories
```
<!-- TREE-END -->

## Modules

### Agent configs (`claude/`, `codex/`, `pi/`, `copilot/`)
- **Purpose**: Each directory holds one AI agent's role files, tracked configuration, commands, or runtime wrappers. All are deployed by `install.sh`; Claude and Pi keep mutable settings in their local runtime directories.
- **Owns**: Per-agent: `agents/` where supported, `commands/` where supported, and tracked configuration such as `config.toml` or `models.json`. Pi also owns `extensions/` (custom TypeScript — currently `inherit-last-model` and `web-search`), `skills/` (Pi-visible shared skill symlinks), and the `pi`/`pis` wrappers.
- **Depends on**: `shared/skills/` for cross-agent skills. Pi's runtime skills path resolves to `pi/skills/`, which is a visibility layer of symlinks to shared skills.
- **Rules**: Agents never reference each other's configs. Shared skills `npx skills@latest add` into any non-Pi agent lands in `shared/skills/` automatically. Claude's `~/.claude/settings.json` and Pi's `~/.pi/agent/settings.json` are unversioned local state while tracked resources remain repo-owned. Pi has one runtime config at `~/.pi/agent`; do not reintroduce Pi profiles, `pim`, subagent roles, or the subagent extension.
- **Entry points**: Agent root dirs. Each contains the settings file(s), wrappers, or config sources the agent loads at startup.

### `herdr/`
- **Purpose**: Herdr terminal workspace manager config and repo-owned Herdr integration artifacts.
- **Owns**: `herdr/config.toml`, `herdr/integrations/{claude,codex,copilot}/herdr-agent-state.sh`.
- **Depends on**: Managed agent config directories at deployment time only; integration sources are tracked here and deployed by `install.sh`.
- **Rules**: Do not run `herdr integration install` as the steady-state dotfiles deployment path. Capture/update repo-owned integration sources, then deploy symlinks or config entries through `install.sh`. Runtime state, sessions, logs, and pane history stay under Herdr's local config/state directories and out of git.
- **Entry points**: `install.sh` modules `herdr`, `herdr_config`, `herdr_integrations`; source config at `herdr/config.toml`.

### `docker/`
- **Purpose**: Shared Docker base image definitions for agent sandboxes.
- **Owns**: `docker/dev-base.Dockerfile` — common Ubuntu dev environment, host-matched user, Go, Node/fnm, GitHub CLI, and base shell/build tools.
- **Depends on**: Docker at build time; no runtime dependency on agent configs.
- **Rules**: Agent-specific sandbox images (`pi/Dockerfile`, `codex/Dockerfile`) build FROM the shared base image tagged as `dotfiles-dev-base:{UID}-{GID}`. Keep agent-specific npm packages, labels, entrypoints, and auth mounts in the agent modules, not in the shared base.
- **Entry points**: `docker/dev-base.Dockerfile`; built automatically by `pis --build`, `cods --build`, and the matching install modules.

### `vscode/`
- **Purpose**: One repository-authoritative VS Code managed layer serving two editor targets — Visual Studio Code Desktop on macOS, and `code-server` on Ubuntu/Debian as an explicitly selected private-network browser endpoint.
- **Owns**: `vscode/settings.json`, `vscode/keybindings.json`, `vscode/snippets/global.code-snippets`, `vscode/capture.sh`, and the extension manifests `vscode/extensions/{shared,desktop,code-server}.txt`.
- **Depends on**: `specs/vscode-config.md` for behavior; `install.sh` for deployment via `deploy_vscode_managed_layer` and `reconcile_vscode_extensions`.
- **Rules**: Tracked sources carry no credentials, private endpoints, hostnames, or machine-specific paths — the code-server bind override is runtime-only and never written to a tracked file. Mutable editor state, profiles, and certificates stay untracked. `shared.txt` applies to both targets; `desktop.txt` and `code-server.txt` absorb marketplace and licensing differences. Desktop VS Code is macOS-only; `code-server` is custom-profile-only because selecting it enables a persistent authenticated network service.
- **Entry points**: `install.sh` module `vscode`; behavior contract at `specs/vscode-config.md`. Covered by 67 tests in `tests/`.

### `nvim/`
- **Purpose**: Custom Neovim plugins layered on top of kickstart.nvim (the base at `~/.config/nvim`).
- **Owns**: `nvim/custom/`, `nvim/custom/plugins/` — one `.lua` file per tool (go, python, formatting, etc.). High-change area; use `ls nvim/custom/plugins/` to see current plugins rather than enumerating here.
- **Depends on**: kickstart.nvim (external, independently updatable via `git pull`). Plugins must never patch or monkey-patch kickstart internals.
- **Rules**: Two-layer architecture — extend, never patch. All customizations go in `nvim/custom/plugins/` using lazy.nvim format. The `{ import = 'custom.plugins' }` line in kickstart's `init.lua` is required (install.sh handles this).
- **Entry points**: Plugin files autoloaded by lazy.nvim.

### `lazygit/`, `yazi/`, `tmux/`, `zsh/`
- **Purpose**: TUI tool and shell configs, each with a single config file (or small set of files) symlinked to the system location by `install.sh`.
- **Owns**: `lazygit/config.yml`, `yazi/*.toml`, `tmux/.tmux.conf`, `zsh/.zshrc.custom`.
- **Depends on**: none.
- **Rules**: `tmux/.tmux.conf` — prefix is Ctrl-a, escape-time 0, focus-events on. F12 toggles outer/inner session control; Ctrl-a Ctrl-a sends prefix to inner session. `zsh/.zshrc.custom` is sourced (not symlinked) from `~/.zshrc`. On SSH, Herdr starts by default; set `DOTFILES_SSH_MULTIPLEXER=tmux` to attach/create tmux session `${TMUX_AUTO_SESSION:-0}`, or `none` to disable auto-attach.
- **Entry points**: The config file for each tool.

### `shared/skills/`
- **Purpose**: Single canonical source for cross-agent skills. Non-Pi agents' skills dirs symlink here; Pi consumes shared skills through symlinks inside `pi/skills/`. High-change area (skills added/removed frequently).
- **Owns**: Everything under `shared/skills/*/`. Current skills visible in the tree above. Each skill has a `SKILL.md`.
- **Depends on**: none — leaf dependency. Skills never reference agent configs.
- **Rules**: Skills installed via `npx skills@latest add` into non-Pi agents land here automatically. Repo-wide workflows such as `update-specs` belong here, not in `pi/skills/`. New shared skills must have the union frontmatter schema. Run `audit-shared-skills` to verify cross-agent compatibility after changes. Imported skill material is a locally maintained fork, never auto-synced upstream; record its source, revision, and license in `THIRD_PARTY_NOTICES.md` before moving or rewriting it. Adding a skill also requires a matching `pi/skills/` symlink.
- **Entry points**: `ls shared/skills/` to list current skills, then load the relevant `SKILL.md`.

### `pi/skills/`
- **Purpose**: Pi's runtime skills directory. Symlinks cross-agent skills from `shared/skills/` so Pi has the shared skill catalog.
- **Owns**: Pi-visible skill symlinks.
- **Depends on**: `shared/skills/` through per-skill symlinks for cross-agent skills.
- **Rules**: Do not move general cross-agent skills here. If a Pi-visible workflow becomes useful across Codex, Claude, Copilot, and Pi in this repo, promote it to `shared/skills/` and keep only the Pi symlink here. When adding a shared skill, add a matching symlink in `pi/skills/` if Pi should see it.
- **Entry points**: `ls pi/skills/` to list Pi-visible skills; entries should be symlinks to shared skills.

### `specs/`
- **Purpose**: Specification suite for the dotfiles manager — business rules, behavior contracts, and design language. Built via the bootstrap-specs skill.
- **Owns**: `specs/*.md`. Spec files define what symlink management, install orchestration, and tool provisioning must do.
- **Depends on**: none — specs inform all implementation modules.
- **Rules**: Specs are the behavioral source of truth. `install.sh` and all configs conform to specs, not the reverse. Changes to deployment or tool setup must be reflected here.
- **Entry points**: `specs/SPEC-OF-SPECS.md`, `specs/README.md`.

## Installation

Primary entry point: `./install.sh` — idempotent, safe to re-run. Auto-detects OS (Ubuntu/Debian vs macOS), installs dependencies, sets up Herdr and tmux fallback, sets up Oh My Zsh, clones kickstart.nvim, creates symlinks for all configs, installs Go 1.24+, fnm/Node.js, and AI tools. Uses the `install_package` function for platform-specific package names (use it when adding deps).

## Dependency Rules

- **`shared/skills/` is a cross-agent leaf**: Shared skills never depend on or reference individual agent configs. Dependency flows one way: agents → skills.
- **`specs/` informs all modules**: Implementation conforms to specs, not the reverse.
- **Agent configs are independent**: `claude/`, `codex/`, `pi/`, and `copilot/` never reference each other. Cross-agent skills stay in `shared/skills/`.
- **Neovim extends kickstart, never patches**: Custom plugins must work with current kickstart without monkey-patching. Must survive `git pull` updates to kickstart.
- **install.sh is the sole deployment entry point**: No other script replicates installation logic.

## Anti-patterns

- **Versioning mutable agent settings**: `~/.claude/settings.json` and `~/.pi/agent/settings.json` are runtime-owned and intentionally untracked; do not add repo-managed copies.
- **Modifying `~/.config/nvim/` directly**: Changes are lost on kickstart updates. All customizations go in `nvim/custom/plugins/`.
- **Wrong platform package names** (e.g., `fd` on Ubuntu): Always use `install_package()` (install.sh:114-138) which handles platform mapping. Test both platforms.
- **Skills missing cross-agent frontmatter**: Every skill needs `name`, `description`, `metadata.short-description`, `allowed-tools`. Run `audit-shared-skills` to verify.
- **Committing credentials or history**: `.gitignore` in `claude/` and `pi/` excludes `auth.json`, `history.jsonl`, sessions. Never override these patterns.

## Coding Principles

### Test-Driven Development (extension/plugin/script work)

For Pi extensions (`pi/extensions/`), Neovim plugins (`nvim/custom/plugins/`), or `install.sh` changes — use TDD with vertical (tracer-bullet) slices:

1. **Plan**: Confirm interface changes and which behaviors to test. Keep modules deep (small interface, deep implementation).
2. **Tracer bullet** (RED → GREEN): One test for the first behavior → fails. Minimal code to pass → passes.
3. **Incremental loop**: Each remaining behavior — write test → fail → minimal code → pass. One at a time. Never write all tests first (horizontal slicing).
4. **Refactor** (only when GREEN): Extract duplication, deepen modules. Run tests after each step.

Per-cycle checklist:
```
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
```

### Review Gates

- **install.sh changes**: Run `bash tests/run.sh`, test on both Ubuntu/Debian and macOS, and verify idempotency (re-run).
- **Neovim plugins**: Restart neovim, verify lazy.nvim loads without errors.
- **Skills/agents**: Run `audit-shared-skills` to verify cross-agent frontmatter.
- **Symlink changes**: Run `install.sh` to verify all links resolve.

## Development Workflows

### Configuration File Changes

- **Tmux**: Edit `tmux/.tmux.conf`, reload with `tmux source-file ~/.tmux.conf` or Ctrl-a r
- **Zsh**: Edit `zsh/.zshrc.custom`, reload with `source ~/.zshrc`
- **Neovim**: Add plugin files to `nvim/custom/plugins/`, restart neovim
- **Pi**: Add TypeScript extensions to `pi/extensions/`

### Code Review with Neovim

Two plugins for git workflows:
- **diffview.nvim**: `<leader>dv` to open, `<leader>dc` to close, `<leader>dh` for file history
- **neogit.nvim**: `<leader>gg` to open interface, `<leader>gc` for commit

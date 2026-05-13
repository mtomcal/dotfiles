# AI Agent Instructions

This file provides guidance to AI coding agents when working with this dotfiles repo — a tmux + neovim + zsh environment using symlinks to deploy configs. Claude Code, Codex, Pi, and Gemini CLI all share context through this file and skills through `shared/skills/`.

## Map

<!-- TREE-HASH: 758fed63228f34d166c8d50981bfc4c92689f9fcbac7140d12e7e4f0da2f2160 -->

<!-- TREE-START -->
```
.
|-- claude
|   `-- agents
|-- codex
|   `-- agents
|-- gemini
|   |-- agents
|   `-- commands
|-- lazygit
|-- nvim
|   `-- custom
|       `-- plugins
|-- pi
|   |-- agents
|   `-- extensions
|       |-- inherit-last-model
|       |-- subagent
|       |   `-- tests
|       `-- web-search
|-- shared
|   `-- skills
|       |-- audit-shared-skills
|       |-- bootstrap-specs
|       |-- create-agents-md
|       |   `-- scripts
|       |-- create-explainer
|       |   `-- lab
|       |-- create-plan
|       |-- create-slice-plan
|       |-- create-subagent-skill
|       |-- expert-consultation
|       |-- grill-me
|       |-- improve-codebase-architecture
|       |-- orchestrate
|       |-- plan
|       |-- playwright-cli
|       |   `-- references
|       |-- playwright-visual-qa
|       |-- ralph
|       |   `-- references
|       |-- review
|       |-- tdd
|       |-- test-quality-verifier
|       |-- tmux-agent-orchestration
|       |-- ubiquitous-language
|       `-- write-a-skill
|-- specs
|-- tmux
|-- yazi
`-- zsh
```
<!-- TREE-END -->

## Modules

### Agent configs (`claude/`, `codex/`, `pi/`, `gemini/`)
- **Purpose**: Each directory holds one AI agent's role files, settings, and (for pi) TypeScript extensions. All are symlinked into `~/.<agent>/` by `install.sh`.
- **Owns**: Per-agent: `agents/` (role MD files), `settings.json` / `config.toml` / `models.json`. Pi also owns `extensions/` (custom TypeScript).
- **Depends on**: `shared/skills/` — every agent's skills path resolves here via symlink.
- **Rules**: Agents never reference each other's configs. Shared skills `npx skills@latest add` into any agent lands in `shared/skills/` automatically. Role MD files use frontmatter: `name`, `description`, `metadata.short-description`, `allowed-tools`.
- **Entry points**: Agent root dirs. Each contains the settings file(s) the agent loads at startup.

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
- **Rules**: `tmux/.tmux.conf` — prefix is Ctrl-a, escape-time 0, focus-events on. F12 toggles outer/inner session control; Ctrl-a Ctrl-a sends prefix to inner session. `zsh/.zshrc.custom` is sourced (not symlinked) from `~/.zshrc`. On SSH, tmux auto-attaches to session "1".
- **Entry points**: The config file for each tool.

### `shared/skills/`
- **Purpose**: Single canonical source for all cross-agent skills. Every agent's skills dir symlinks here. High-change area (skills added/removed frequently).
- **Owns**: Everything under `shared/skills/*/`. Current skills visible in the tree above. Each skill has a `SKILL.md`.
- **Depends on**: none — leaf dependency. Skills never reference agent configs.
- **Rules**: Skills installed via `npx skills@latest add` into any agent land here automatically. New skills must have the union frontmatter schema. Run `audit-shared-skills` to verify cross-agent compatibility after changes.
- **Entry points**: `ls shared/skills/` to list current skills, then load the relevant `SKILL.md`.

### `specs/`
- **Purpose**: Specification suite for the dotfiles manager — business rules, behavior contracts, and design language. Built via the bootstrap-specs skill.
- **Owns**: `specs/*.md`. Spec files define what symlink management, install orchestration, and tool provisioning must do.
- **Depends on**: none — specs inform all implementation modules.
- **Rules**: Specs are the behavioral source of truth. `install.sh` and all configs conform to specs, not the reverse. Changes to deployment or tool setup must be reflected here.
- **Entry points**: `specs/SPEC-OF-SPECS.md`, `specs/README.md`.

## Installation

Primary entry point: `./install.sh` — idempotent, safe to re-run. Auto-detects OS (Ubuntu/Debian vs macOS), installs dependencies, sets up Oh My Zsh, clones kickstart.nvim, creates symlinks for all configs, installs Go 1.24+, fnm/Node.js, and AI tools. Uses the `install_package` function for platform-specific package names (use it when adding deps).

## Dependency Rules

- **`shared/skills/` is a leaf**: Skills never depend on or reference individual agent configs. Dependency flows one way: agents → skills.
- **`specs/` informs all modules**: Implementation conforms to specs, not the reverse.
- **Agent configs are independent**: `claude/`, `codex/`, `pi/`, `gemini/` never reference each other. They share only through `shared/skills/`.
- **Neovim extends kickstart, never patches**: Custom plugins must work with current kickstart without monkey-patching. Must survive `git pull` updates to kickstart.
- **install.sh is the sole deployment entry point**: No other script replicates installation logic.

## Anti-patterns

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

- **install.sh changes**: Test on both Ubuntu/Debian and macOS. Verify idempotency (re-run).
- **Neovim plugins**: Restart neovim, verify lazy.nvim loads without errors.
- **Skills/agents**: Run `audit-shared-skills` to verify cross-agent frontmatter.
- **Symlink changes**: Run `install.sh` to verify all links resolve.

### Built-in Review Pipeline

The `/review` skill (`shared/skills/review/SKILL.md`) provides auto-detecting multi-dimension code review:
- Always fires: test-reviewer, quality-reviewer, **premortem-reviewer**
- File-signal-gated: security-reviewer, design-reviewer, visual-qa
- Runs on `git diff` by default, specific files via path args, `--full` for full audit
- Produces consolidated report with summary card and per-reviewer verdicts
- Referenced as the canonical review source by `/orchestrate`

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

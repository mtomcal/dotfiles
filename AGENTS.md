# AI Agent Instructions

This file provides guidance to AI coding agents when working with this dotfiles repo — a tmux + neovim + zsh environment using symlinks to deploy configs. Claude Code, Codex, Pi, and Gemini CLI all share context through this file. Cross-agent skills live in `shared/skills/`; Pi-specific subagent workflow skills live in `pi/skills/`.

## Map

<!-- TREE-HASH: 6099ce2551f36dcef40ebb8758e1a1e83b1606055471cbfbf8c6ee53536a32f6 -->

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
|   |-- extensions
|   |   |-- inherit-last-model
|   |   |-- subagent
|   |   |   `-- tests
|   |   `-- web-search
|   `-- skills
|       |-- audit-shared-skills -> ../../shared/skills/audit-shared-skills
|       |-- bootstrap-specs -> ../../shared/skills/bootstrap-specs
|       |-- create-agents-md -> ../../shared/skills/create-agents-md
|       |-- create-explainer -> ../../shared/skills/create-explainer
|       |-- create-plan -> ../../shared/skills/create-plan
|       |-- create-slice-plan
|       |-- create-subagent-skill
|       |-- em-train -> ../../shared/skills/em-train
|       |-- grill-me -> ../../shared/skills/grill-me
|       |-- improve-codebase-architecture -> ../../shared/skills/improve-codebase-architecture
|       |-- orchestrate
|       |-- plan
|       |-- playwright-cli -> ../../shared/skills/playwright-cli
|       |-- playwright-visual-qa -> ../../shared/skills/playwright-visual-qa
|       |-- prototype -> ../../shared/skills/prototype
|       |-- ralph -> ../../shared/skills/ralph
|       |-- review
|       |-- tdd -> ../../shared/skills/tdd
|       |-- test-quality-verifier -> ../../shared/skills/test-quality-verifier
|       |-- tmux-agent-orchestration -> ../../shared/skills/tmux-agent-orchestration
|       |-- ubiquitous-language -> ../../shared/skills/ubiquitous-language
|       |-- update-specs
|       `-- write-a-skill -> ../../shared/skills/write-a-skill
|-- shared
|   `-- skills
|       |-- audit-shared-skills
|       |-- bootstrap-specs
|       |-- create-agents-md
|       |   `-- scripts
|       |-- create-explainer
|       |   `-- lab
|       |-- create-plan
|       |-- em-train
|       |   `-- scripts
|       |-- grill-me
|       |-- improve-codebase-architecture
|       |-- playwright-cli
|       |   `-- references
|       |-- playwright-visual-qa
|       |-- prototype
|       |-- ralph
|       |   `-- references
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
- **Owns**: Per-agent: `agents/` (role MD files), `settings.json` / `config.toml` / `models.json`. Pi also owns `extensions/` (custom TypeScript) and `skills/` (Pi-specific subagent workflow skills plus symlinks to shared skills).
- **Depends on**: `shared/skills/` for cross-agent skills. Pi's runtime skills path resolves to `pi/skills/`, which composes Pi-only skills with symlinks to `shared/skills/`.
- **Rules**: Agents never reference each other's configs. Shared skills `npx skills@latest add` into any non-Pi agent lands in `shared/skills/` automatically. Pi-specific skills that require `subagent_run`, `subagent_fork`, Pi role files, or `/tree` handoff live in `pi/skills/`. Role MD files use frontmatter: `name`, `description`, `metadata.short-description`, `allowed-tools`.
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
- **Purpose**: Single canonical source for cross-agent skills. Non-Pi agents' skills dirs symlink here; Pi consumes shared skills through symlinks inside `pi/skills/`. High-change area (skills added/removed frequently).
- **Owns**: Everything under `shared/skills/*/`. Current skills visible in the tree above. Each skill has a `SKILL.md`.
- **Depends on**: none — leaf dependency. Skills never reference agent configs.
- **Rules**: Skills installed via `npx skills@latest add` into non-Pi agents land here automatically. New shared skills must have the union frontmatter schema. Run `audit-shared-skills` to verify cross-agent compatibility after changes.
- **Entry points**: `ls shared/skills/` to list current skills, then load the relevant `SKILL.md`.

### `pi/skills/`
- **Purpose**: Pi's runtime skills directory. Owns Pi-specific subagent workflow skills and symlinks each cross-agent skill from `shared/skills/` so Pi still has the full skill catalog.
- **Owns**: Pi-only skills that depend on `subagent_run`, `subagent_fork`, Pi role files, or `/tree` handoff.
- **Depends on**: `shared/skills/` through per-skill symlinks for cross-agent skills.
- **Rules**: Do not move general cross-agent skills here. When adding a shared skill, add a matching symlink in `pi/skills/` if Pi should see it.
- **Entry points**: `ls pi/skills/` to list Pi-visible skills; real directories are Pi-only, symlinks point to shared skills.

### `specs/`
- **Purpose**: Specification suite for the dotfiles manager — business rules, behavior contracts, and design language. Built via the bootstrap-specs skill.
- **Owns**: `specs/*.md`. Spec files define what symlink management, install orchestration, and tool provisioning must do.
- **Depends on**: none — specs inform all implementation modules.
- **Rules**: Specs are the behavioral source of truth. `install.sh` and all configs conform to specs, not the reverse. Changes to deployment or tool setup must be reflected here.
- **Entry points**: `specs/SPEC-OF-SPECS.md`, `specs/README.md`.

## Installation

Primary entry point: `./install.sh` — idempotent, safe to re-run. Auto-detects OS (Ubuntu/Debian vs macOS), installs dependencies, sets up Oh My Zsh, clones kickstart.nvim, creates symlinks for all configs, installs Go 1.24+, fnm/Node.js, and AI tools. Uses the `install_package` function for platform-specific package names (use it when adding deps).

## Dependency Rules

- **`shared/skills/` is a cross-agent leaf**: Shared skills never depend on or reference individual agent configs. Dependency flows one way: agents → skills.
- **`specs/` informs all modules**: Implementation conforms to specs, not the reverse.
- **Agent configs are independent**: `claude/`, `codex/`, `pi/`, `gemini/` never reference each other. Pi-specific subagent workflow skills stay in `pi/skills/`; cross-agent skills stay in `shared/skills/`.
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

The `/review` skill (`pi/skills/review/SKILL.md`) provides Pi's auto-detecting multi-dimension subagent code review:
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

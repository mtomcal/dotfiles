# Ubiquitous Language

> **Version**: 0.3.0
> **Last Updated**: 2026-06-02
> **Purpose**: Shared vocabulary for all specs. Every term used in multiple specs MUST be defined here. Read this before any other spec.

> **Usage note**: Throughout all specs, the bare term "install" should be disambiguated using one of the three defined terms: **install** (the complete install.sh run), **install (dependency)** (a single package), or **install (Mason)** (a Neovim package). Use the specific term wherever context is ambiguous.

---

## Dotfiles Domain

| Term | Definition | Aliases to avoid | Context notes |
|------|-----------|-------------------|---------------|
| **dotfiles** | The collection of configuration files managed in the version-controlled repository at ~/dotfiles | "config files", "dotfiles" (ambiguous — see config) | Refers to the repo and its contents as a coherent unit |
| **symlink** | A symbolic link from a system path pointing to a file in the dotfiles repository | "link", "soft link" | The primary deployment mechanism — configs stay in the repo, symlinks point to them |
| **install** | A full run of install.sh that sets up the entire development environment | — | Overloaded — see "install (dependency)" and "install (Mason)" for disambiguation |
| **install (dependency)** | Installing a single system package or tool (e.g., via apt, brew) | "package install" | A sub-step of the full install process |
| **install (Mason)** | Installing an LSP server, formatter, or linter via Neovim's Mason package manager | "Mason install" | Different concern — Neovim-internal, not system-level |
| **deploy** | Creating a symlink that connects a system path to its source in the dotfiles repo | "link", "wire up" | Preferred over "install" when referring specifically to symlink creation |
| **backup** | Moving an existing non-symlink config file to a timestamped copy before deploying the symlink version | — | Happens automatically during deploy if a conflict exists |
| **idempotent** | An operation that produces the same result whether run once or multiple times | — | Core design principle of install.sh — safe to re-run |

## Editor Domain

| Term | Definition | Aliases to avoid | Context notes |
|------|-----------|-------------------|---------------|
| **kickstart** | The official Neovim kickstart.nvim configuration used as the base layer | "base config" | Cloned from upstream, never modified in place |
| **custom layer** | User-authored Neovim configurations layered on top of kickstart via the custom/ symlink | "custom config", "user config" | Lives in ~/dotfiles/nvim/custom/, symlinked into kickstart |
| **plugin (Neovim)** | A lazy.nvim plugin specification in the custom layer | — | Overloaded — disambiguate from Oh My Zsh plugin and Pi extension |
| **plugin (Oh My Zsh)** | A Zsh plugin managed by the Oh My Zsh framework | — | Overloaded — disambiguate from Neovim plugin and Pi extension |
| **extension (Pi)** | A TypeScript extension for the Pi coding agent | — | Overloaded — disambiguate from Neovim plugin and Oh My Zsh plugin |
| **Mason package** | An LSP server, formatter, or linter installed via Mason inside Neovim | — | Not a "plugin" — these are external tools, not Neovim extensions |

## Shell Domain

| Term | Definition | Aliases to avoid | Context notes |
|------|-----------|-------------------|---------------|
| **shell config** | The Zsh configuration including Oh My Zsh, aliases, PATH, and custom settings | "zsh config" | Refers to the entire shell setup, not just .zshrc |
| **custom shell config** | The user-authored additions in .zshrc.custom (aliases, PATH exports, tool init) | "zshrc custom" | Sourced by .zshrc, never replaces it |
| **prefix key** | The tmux prefix key (Ctrl-a instead of default Ctrl-b) | "leader key" | Tmux-specific; not to be confused with Neovim leader key |
| **dimmed** | A visual state of the tmux status bar indicating that outer-session keybindings are disabled and keypresses pass through to the inner session. Triggered by F12 toggle | "dim status bar" | Distinct from the normal status bar appearance; used only for nested tmux session control |

## Agent Domain

| Term | Definition | Aliases to avoid | Context notes |
|------|-----------|-------------------|---------------|
| **agent** | An AI coding assistant (Codex CLI, Claude Code, Pi, Gemini CLI, or Copilot CLI) | "AI", "assistant" | Used generically when referring to any or all of the supported agents |
| **skill** | A reusable instruction set for one or more AI agents | "instruction" | Cross-agent skills live in `shared/skills/`. Pi profiles always include shared skills and MAY add profile-local skills. |
| **shared skills directory** | The canonical cross-agent skills directory at `~/dotfiles/shared/skills/` | — | Non-Pi agent skill paths are symlinks pointing here. Every Pi profile includes these skills in its resolved runtime skills directory. |
| **Pi profile** | A named Pi configuration variant with its own settings, models, agents, enabled extensions, runtime state, and optional profile-local skills, while sharing the installed Pi binary with other profiles | "Pi config", "Pi mode" | Examples include `coding`, `local`, and loop-oriented profiles |
| **active profile** | The Pi profile currently selected as the default target for bare `pi` and `pis` commands | "default Pi", "current Pi config" | Materialized as a stable runtime pointer; switching it does not change other profiles |
| **profile manager** | The command-line interface that creates, builds, lists, inspects, and switches Pi profiles | "Pi manager" | The canonical command name is `pim` |
| **profile-local skill** | A Pi-only skill defined for a specific Pi profile in addition to the shared skills directory | "custom skill" | Duplicate names between profile-local skills and shared skills are a build error |
| **deployable profile output** | The committed, generated directory for a Pi profile that the install process deploys into runtime paths | "generated config", "built profile" | Derived from `pi/base/` plus profile overrides; contains resolved `settings.json`, `models.json`, `agents/`, `skills/`, and `extensions/` |
| **sub-agent role** | A named agent definition stored as a Markdown file in a Pi profile's resolved `agents/` directory with YAML frontmatter. Each role pre-configures a model, provider, thinking level, allowed tools, and guardrail thresholds (maxTurns, maxCost, maxTokens, maxTime). The subagent extension reads these definitions at session start and builds a catalog, making them available for delegation via `subagent_run` or `subagent_fork` | "agent file", "role file" | Distinct from "agent" (an AI coding assistant like Codex/Claude) — sub-agent roles are delegatable specialists scoped to Pi's subagent system. Examples: design-reviewer, premortem-reviewer, visual-qa, implementer, sage |
| **subagent model routing** | A prescriptive mapping from subagent intent categories (scout, planner, reviewer, implementer, expert (1st), expert (2nd), expert (3rd)) to specific model, provider, and thinking level configurations, stored in Pi's settings.json and injected into subagent tool descriptions. The expert categories form a 3-model fallback chain for consultation when the main model is stuck | "model selection", "model choosing" | Ensures cost-effective model selection; the LLM MUST follow the routing table for subagent calls |
| **scout** | A subagent intent category for fast, read-only codebase reconnaissance that returns compressed context for handoff | "explorer", "looker" | Mapped to flash-tier models with low thinking; no modifications, no deep analysis |
| **planner** | A subagent intent category for read-only analysis and implementation planning with moderate reasoning | "analyst" | Mapped to medium-tier models with medium thinking; produces structured plans, does not write code |
| **reviewer** | A subagent intent category for deep code quality, security, and architecture analysis | "auditor" | Mapped to reasoning models with high thinking; read-only, catches subtle bugs and security issues |
| **implementer** | A subagent intent category for writing or modifying code autonomously | "coder", "builder" | Mapped to workhorse models with medium thinking; full read-write capability |
| **expert** | A subagent intent category for deep domain reasoning with two modes: delegation (handing off hard problems) and consultation (getting unstuck when looping). Has a 3-model fallback chain: primary (deepseek-v4-pro), secondary (glm-5.1), tertiary (kimi-k2.6). File-scoped issues allow up to 3 consultations with different models before user escalation | "specialist" | Replaces the former "specialist" category; the fallback chain provides architectural diversity across consultations |
| **agent config** | An agent-specific configuration directory or configuration variant managed from the dotfiles repo | — | Most agents have one config directory; Pi supports multiple profile-specific config variants under one agent family |

## Tooling Domain

| Term | Definition | Aliases to avoid | Context notes |
|------|-----------|-------------------|---------------|
| **TUI tool** | A terminal user interface tool installed by the script (lazygit, yazi, zoxide) | "CLI tool" | Distinct from shell utilities — these have interactive interfaces |
| **LSP server** | A Language Server Protocol server providing code intelligence in Neovim | "language server" | Installed via Mason, not via system packages |
| **formatter** | A code formatting tool configured for Neovim's on-save formatting | — | Managed via conform.nvim in the custom layer |

---

## Relationships

- A **dotfiles** repo contains multiple **agent configs** (one per supported agent, with Pi supporting multiple **Pi profiles**)
- Non-Pi **agent configs** have their **skills** directory symlinked to the **shared skills directory**
- Each **Pi profile** includes the **shared skills directory** plus any **profile-local skills** in its **deployable profile output**
- The **active profile** is exposed through a stable runtime pointer so bare `pi` and `pis` commands resolve to the selected **Pi profile**
- A **custom layer** can contain multiple **plugins (Neovim)**
- A **kickstart** configuration imports exactly one **custom layer**
- The **install** process **deploys** multiple **symlinks** and **installs (dependency)** multiple system packages and Mason packages
- A **symlink** always points from a system path to a source file in the **dotfiles** repo
- **Tool provisioning** depends on **symlink management** for config deployment of TUI tools

---

## Flagged Ambiguities

- **"install"** is used to mean the full install.sh run, a single system package installation, and a Mason package installation. These are distinct operations: use **install**, **install (dependency)**, and **install (Mason)** respectively.
- **"plugin"** is used to mean a Neovim lazy.nvim plugin, an Oh My Zsh plugin, or a Pi extension. These are distinct concepts: use **plugin (Neovim)**, **plugin (Oh My Zsh)**, or **extension (Pi)** respectively.
- **"config"** is used to mean a source file in the dotfiles repo, a deployed file on disk, or an application's own config format. Use **dotfiles** (repo source), **symlink** (deployed pointer), or name the specific application config format.
- **"manager"** could mean the overall dotfiles manager concept, fnm (Fast Node Manager), or Mason (LSP manager). Use **dotfiles** (the system), **fnm**, or **Mason** specifically.
- **"custom"** could mean the nvim/custom/ symlink layer, user customization in general, or the .zshrc.custom file. Use **custom layer** (Neovim), **custom shell config** (zsh), or **user customization** (general) respectively.
- **"strong model"** or **"weak model"** are informal terms that should be avoided in specs. Use specific subagent intent categories (scout, planner, reviewer, implementer, expert (1st), expert (2nd), expert (3rd)) or refer to the `subagentModelRouting` table instead. The routing table defines the canonical model assignments; calling a model "strong" or "weak" without context is ambiguous.
- **"profile"** is overloaded between install profiles (Full, Minimal, Work, Custom) and **Pi profiles**. Use **installation profile** for install.sh menu choices and **Pi profile** for Pi runtime variants.

---

## Example Dialogue

> **Dev**: "When a **symlink** already exists pointing to the correct target, does **install** skip it?"
> **Domain Expert**: "Yes. The install script is **idempotent** — if the symlink is already correct, it moves on without error or backup."
> **Dev**: "So if I change a file in the dotfiles repo, I don't need to re-run install?"
> **Domain Expert**: "Correct. The symlink always points to the current version. You only re-run install if you add a new symlink or system package."

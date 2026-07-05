# Ubiquitous Language

> **Version**: 0.5.0
> **Last Updated**: 2026-07-05
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
| **multiplexer prefix key** | The reserved key that tells a terminal multiplexer to handle the following keypress instead of passing it to the foreground application | "leader key", "prefix key" when the multiplexer is ambiguous | Distinct from the Neovim leader key; tmux and Herdr both use Ctrl-a in this dotfiles environment |
| **tmux prefix key** | The tmux-specific multiplexer prefix key, configured as Ctrl-a instead of default Ctrl-b | "leader key" | Use when discussing tmux behavior specifically |
| **Herdr prefix key** | The Herdr-specific multiplexer prefix key, configured as Ctrl-a for tmux muscle-memory parity | "leader key" | Use when discussing Herdr behavior specifically |
| **dimmed** | A visual state of the tmux status bar indicating that outer-session keybindings are disabled and keypresses pass through to the inner session. Triggered by F12 toggle | "dim status bar" | Tmux-specific; Herdr nested launches are blocked rather than controlled with an F12 toggle |
| **SSH multiplexer** | The terminal multiplexer automatically launched for SSH sessions by the custom shell config | "SSH tmux" | Defaults to Herdr during migration, with tmux available through an environment override |

## Herdr Domain

| Term | Definition | Aliases to avoid | Context notes |
|------|-----------|-------------------|---------------|
| **Herdr config** | The version-controlled TOML configuration for Herdr, sourced from `~/dotfiles/herdr/config.toml` and deployed to `~/.config/herdr/config.toml` | "Herdr settings" | The config is tracked; session state and pane history are not tracked |
| **Herdr workspace** | Herdr's top-level workspace unit for a repo, task, or investigation | "tmux session" | Replaces tmux session/window mental models for new work; contains tabs and panes |
| **Herdr tab** | A tab inside a Herdr workspace, analogous to a daily-use tmux window | "Herdr window" | Use "tab" because that is Herdr's term |
| **Herdr pane** | A terminal pane inside a Herdr tab | "terminal", "split" | Panes may run shells, editors, or agents |
| **Herdr runtime state** | Local-only Herdr session files, pane history, sockets, and generated state outside the dotfiles repo | "Herdr config" | Must remain out of git even when pane history is enabled |
| **Herdr integration** | A hook, plugin, or agent-side file that reports agent lifecycle/session state to Herdr | "Herdr plugin" | Use "integration" unless the upstream artifact is specifically a Pi extension/plugin |
| **repo-owned Herdr integration** | A Herdr integration whose files are tracked or generated inside the dotfiles repo and deployed by the dotfiles flow instead of written directly by Herdr's installer to live config paths | "default Herdr install path" | Required for this repo so agent config ownership stays centralized |
| **Herdr skill** | The upstream Herdr operating instructions stored as a cross-agent skill under `shared/skills/herdr/` | "global Herdr skill" | Tracked in the shared skills directory so all supported agents can use it consistently |

## Agent Domain

| Term | Definition | Aliases to avoid | Context notes |
|------|-----------|-------------------|---------------|
| **agent** | An AI coding assistant (Codex CLI, Claude Code, Pi, Gemini CLI, or Copilot CLI) | "AI", "assistant" | Used generically when referring to any or all of the supported agents |
| **skill** | A reusable instruction set for one or more AI agents | "instruction" | Cross-agent skills live in `shared/skills/`. Pi profiles always include shared skills and MAY add profile-local skills. |
| **shared skills directory** | The canonical cross-agent skills directory at `~/dotfiles/shared/skills/` | — | Non-Pi agent skill paths are symlinks pointing here. Every Pi profile includes these skills in its resolved runtime skills directory. |
| **Pi profile** | A named Pi configuration variant with its own settings, models, agents, enabled extensions, runtime state, and optional profile-local skills, while sharing the installed Pi binary with other profiles | "Pi config", "Pi mode" | Examples include `coding`, `local`, and loop-oriented profiles |
| **profile source** | The authoring inputs for one Pi profile under `pi/profiles/<profile>/` | "profile config", "source profile" | Contains overrides, `extensions.list`, and profile-local skills before composition |
| **resolved output** | The committed deployable artifact for one Pi profile under `pi/profiles/<profile>/resolved/` | "deployable profile output", "generated config" | Distinct from both profile source and runtime; built from base inputs plus profile overrides |
| **profile runtime** | The deployed runtime tree for one Pi profile under `~/.pi/profiles/<profile>/agent/` | "deployed profile", "runtime dir" | Pi reads from this layer at runtime; it may also contain profile-local sessions |
| **compatibility path** | The stable path `~/.pi/agent` that points to the active profile runtime | "active symlink", "agent path" | Exists so bare `pi` and `pis` commands always resolve through one canonical path |
| **active profile** | The Pi profile currently selected as the default target for bare `pi` and `pis` commands | "default Pi", "current Pi config" | Materialized as a stable runtime pointer; switching it does not change other profiles |
| **profile manager** | The command-line interface that creates, builds, lists, inspects, and switches Pi profiles | "Pi manager" | The canonical command name is `pim` |
| **enabled extension set** | The list of Pi extensions selected for one profile by `extensions.list` | "extension list", "profile extensions" | MAY be empty; deployment must treat an absent resolved `extensions/` directory as an empty set |
| **profile-local skill** | A Pi-only skill defined for a specific Pi profile in addition to the shared skills directory | "custom skill" | Duplicate names between profile-local skills and shared skills are a build error |
| **build** | The `pim build <profile>` operation that composes profile source into resolved output without changing runtime symlinks or active state | "compile profile", "refresh resolved output" | Used when profile artifacts need to be regenerated or reviewed before activation |
| **activate** | The unified operation triggered by `pim activate <profile>` (also via `pim use <profile>` or bare `pim <profile>`) that builds resolved output, deploys the runtime, and then swaps the compatibility path | "switch", "rebuild and deploy" | Atomic with respect to active state: failures leave the existing active profile unmodified |
| **dashboard** | Zero-argument bare `pim` output that lists all available profiles and whether each one has resolved output plus a deployed runtime. The active profile is clearly marked. | "profile overview", "list" | A user-friendly convenience not tied to any specific operation; purely informational |
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
- Each **Pi profile** starts as **profile source**, composes into **resolved output**, deploys into a **profile runtime**, and may be selected through the **compatibility path**
- Each **Pi profile** includes the **shared skills directory** plus any **profile-local skills** in its **resolved output**
- The **active profile** is exposed through the **compatibility path** so bare `pi` and `pis` commands resolve to the selected **profile runtime**
- A **custom layer** can contain multiple **plugins (Neovim)**
- A **kickstart** configuration imports exactly one **custom layer**
- The **install** process **deploys** multiple **symlinks** and **installs (dependency)** multiple system packages and Mason packages
- A **symlink** always points from a system path to a source file in the **dotfiles** repo
- **Tool provisioning** depends on **symlink management** for config deployment of TUI tools
- The **SSH multiplexer** defaults to Herdr and MAY fall back to tmux through an environment override
- A **Herdr workspace** contains one or more **Herdr tabs**, and a **Herdr tab** contains one or more **Herdr panes**
- **Herdr config** is deployed by the **dotfiles** repo, while **Herdr runtime state** remains local-only and out of git
- A **repo-owned Herdr integration** is generated or copied into **agent configs** or **profile source** before deployment, rather than installed directly into live runtime paths
- The **Herdr skill** lives in the **shared skills directory** and is included in every **Pi profile** through the resolved skills composition process

---

## Flagged Ambiguities

- **"install"** is used to mean the full install.sh run, a single system package installation, and a Mason package installation. These are distinct operations: use **install**, **install (dependency)**, and **install (Mason)** respectively.
- **"plugin"** is used to mean a Neovim lazy.nvim plugin, an Oh My Zsh plugin, or a Pi extension. These are distinct concepts: use **plugin (Neovim)**, **plugin (Oh My Zsh)**, or **extension (Pi)** respectively.
- **"config"** is used to mean a source file in the dotfiles repo, a deployed file on disk, or an application's own config format. Use **dotfiles** (repo source), **symlink** (deployed pointer), or name the specific application config format.
- **"manager"** could mean the overall dotfiles manager concept, fnm (Fast Node Manager), or Mason (LSP manager). Use **dotfiles** (the system), **fnm**, or **Mason** specifically.
- **"custom"** could mean the nvim/custom/ symlink layer, user customization in general, or the .zshrc.custom file. Use **custom layer** (Neovim), **custom shell config** (zsh), or **user customization** (general) respectively.
- **"strong model"** or **"weak model"** are informal terms that should be avoided in specs. Use specific subagent intent categories (scout, planner, reviewer, implementer, expert (1st), expert (2nd), expert (3rd)) or refer to the `subagentModelRouting` table instead. The routing table defines the canonical model assignments; calling a model "strong" or "weak" without context is ambiguous.
- **"profile"** is overloaded between install profiles (Full, Minimal, Work, Custom) and **Pi profiles**. Use **installation profile** for install.sh menu choices and **Pi profile** for Pi runtime variants.
- **"resolved"**, **"runtime"**, and **"active"** are easy to blur together in Pi discussions. Use **resolved output** for the committed artifact, **profile runtime** for the deployed tree under `~/.pi/profiles/`, and **compatibility path** for `~/.pi/agent`.
- **"integration"** is overloaded between Herdr integrations, shell integrations, and editor integrations. Use **Herdr integration** when referring to Herdr agent lifecycle/session hooks.
- **"workspace"** is overloaded between generic project workspace, terminal workspace, and **Herdr workspace**. Use **Herdr workspace** when referring to Herdr's top-level unit.
- **"prefix key"** is ambiguous after Herdr adoption. Use **multiplexer prefix key** for shared behavior, **tmux prefix key** for tmux, and **Herdr prefix key** for Herdr.

---

## Example Dialogue

> **Dev**: "If I edit a **profile source**, is that immediately live in Pi?"
> **Domain Expert**: "No. The change must first become **resolved output**. Pi runs from the **profile runtime**, not directly from source."
> **Dev**: "So what does `pim build local` actually change?"
> **Domain Expert**: "Only the **resolved output** for `local`. It does not switch the **active profile** or rewrite the **compatibility path**."
> **Dev**: "What if the **enabled extension set** is empty and Git has no `resolved/extensions/` directory?"
> **Domain Expert**: "That still means the profile is valid. Deploy treats the missing directory as an empty extension set, not a broken profile."
> **Dev**: "Should SSH still auto-attach tmux?"
> **Domain Expert**: "No. The **SSH multiplexer** defaults to Herdr now, but tmux remains available through the fallback environment override."
> **Dev**: "Where do Herdr's saved panes go?"
> **Domain Expert**: "They are **Herdr runtime state**. They can exist locally, including pane history, but they must never be committed as **Herdr config**."

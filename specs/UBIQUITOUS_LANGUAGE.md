# Ubiquitous Language

> **Version**: 0.7.0
> **Last Updated**: 2026-07-14
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
| **caller pane** | The Herdr pane whose process invoked an operation | "current pane", "focused pane" | Identified through environment or current-pane discovery, never inferred from UI focus |
| **focused pane** | The Herdr pane currently selected in the interface | "caller pane", "current pane" | May differ from the caller pane |
| **public Herdr ID** | An opaque refreshable runtime identifier for a Herdr entity | "stable ID", "durable ID" | Refresh after topology changes and never persist as durable identity |
| **legacy display selector** | An unstable numeric position selector for a Herdr entity | "Herdr ID", "stable selector" | May resolve differently after topology changes and must not be guessed or persisted |
| **Herdr runtime state** | Local-only Herdr session files, pane history, sockets, and generated state outside the dotfiles repo | "Herdr config" | Must remain out of git even when pane history is enabled |
| **Herdr integration** | A hook, plugin, or agent-side file that reports agent lifecycle/session state to Herdr | "Herdr plugin" | Use "integration" unless the upstream artifact is specifically a Pi extension/plugin |
| **repo-owned Herdr integration** | A Herdr integration whose files are tracked or generated inside the dotfiles repo and deployed by the dotfiles flow instead of written directly by Herdr's installer to live config paths | "default Herdr install path" | Required for this repo so agent config ownership stays centralized |
| **Herdr skill** | The upstream Herdr operating instructions stored as a cross-agent skill under `shared/skills/herdr/` | "global Herdr skill" | Tracked in the shared skills directory so all supported agents can use it consistently |

## Agent Domain

| Term | Definition | Aliases to avoid | Context notes |
|------|-----------|-------------------|---------------|
| **agent** | An AI coding assistant (Codex CLI, Claude Code, Pi, or Copilot CLI) | "AI", "assistant" | Used generically when referring to any or all of the supported agents |
| **skill** | A reusable instruction set for one or more AI agents | "instruction" | Cross-agent skills live in `shared/skills/`; Pi exposes them through `pi/skills/`. |
| **skill body** | The invoked Markdown instructions that follow a skill's frontmatter | "skill prompt", "instructions" | Uses the canonical shared-skill body sections when the skill is new or materially modified |
| **shared skills directory** | The canonical cross-agent skills directory at `~/dotfiles/shared/skills/` | — | Non-Pi agent skill paths point here directly. Pi-visible skill entries point here through `pi/skills/` symlinks. |
| **agent config** | An agent-specific configuration directory managed from the dotfiles repo | — | Each supported agent has one repo-owned config surface. Pi's config deploys to `~/.pi/agent`. |
| **unshipping** | Removing a feature, tool, config surface, or workflow entirely from the repo's tracked and deployed contract | "disable", "hide" | Includes implementation, tests, docs, specs, generated artifacts, and installer surfaces unless explicitly scoped otherwise. |

## Agent Workflow Domain

| Term | Definition | Aliases to avoid | Context notes |
|------|-----------|-------------------|---------------|
| **Language Definitions section** | The mandatory skill-body section containing execution-relevant skill-local vocabulary or the statement “No skill-specific terms” | "glossary", "terminology section" | Project-domain terms remain in the applicable project glossary |
| **Workflow section** | The optional skill-body section containing at most one primary end-to-end process with routing or mode selection first | "process section", "multiple workflows" | Branches remain inside the single primary Workflow |
| **Activity** | An independently reusable command, action, or recipe selected outside a required end-to-end sequence | "Workflow step", "procedure" | Activities do not restate ordinary Workflow steps |
| **Reference section** | The optional skill-body section containing pointers that state when and why supporting Markdown must be loaded | "resources", "appendix" | Required main-path behavior cannot be hidden behind optional loading |
| **progressive disclosure** | The staged loading of a catalog description, an invoked skill body, and conditionally selected support | "documentation split", "shortening" | A split is earned only when the remaining main path stays executable |
| **behavior-preservation ledger** | An audit record mapping each required behavior to its retained location or replacement owner | "change summary", "checklist" | Covers triggers, branches, gates, failures, guardrails, outputs, ownership, and completion conditions |
| **spec-extraction plan** | The brownfield Bootstrap Specs artifact that directs extraction of specifications from implementation evidence | "plan workspace", "slice graph" | It is not a plan workspace or implementation slice graph |
| **Ralph job plan** | The mutable `IMPLEMENTATION_PLAN.md` state used by a Ralph job | "plan workspace", "orchestration index" | It is not the repository plan workspace |
| **teaching workspace** | The dedicated durable directory containing one learner's mission, resources, lessons, references, assets, and evidence | "plan workspace", "Herdr workspace" | Teaching state has its own owner and lifecycle |
| **neutral diff artifact** | Structured observable image differences without criteria, severity, recommendations, or verdict | "visual review", "acceptance verdict" | Owned by `image-diff-describer`; it does not imply visual acceptance |
| **Wayfinder map** | The low-resolution Markdown index for one uncertainty-resolution effort, containing its destination, decision summaries, fog of war, and scope boundary | "roadmap", "issue epic" | Lives under `.wayfinder/<effort-slug>/MAP.md`; detailed answers remain in decision tickets. |
| **decision ticket** | A session-sized question whose evidenced resolution advances a Wayfinder map toward its destination | "implementation ticket", "slice" | Resolves uncertainty rather than delivering production behavior. |
| **frontier** | The derived set of currently actionable items whose dependency blockers have reached the required terminal state | "queue", "backlog" | Wayfinder blockers must be resolved; plan slice blockers must be integrated. |
| **plan workspace** | The temporary, file-based control plane for one implementation effort, containing its orchestration index, slices, and verification artifacts | "PLAN.md", "plan file" | Stored under the OS temporary plan root and reached through the active-plan pointer. |
| **slice** | A fresh-context implementation packet that delivers one vertical behavior through ordered red, green, and refactor cycles | "task", "ticket" | Editable slices receive isolated worktrees and branches. |
| **verification artifact** | A durable Markdown record of one review axis, fixed point, criteria, attempts, evidence, and verdict | "review output", "review note" | Owned by the parent agent; failed attempts are appended rather than overwritten. |
| **active-plan pointer** | The repository-local text file `.plan` whose single absolute path identifies the active plan workspace | "plan state", "plan link" | It is locally excluded from Git; a missing target is stale state and must not be guessed. |

## Tooling Domain

| Term | Definition | Aliases to avoid | Context notes |
|------|-----------|-------------------|---------------|
| **TUI tool** | A terminal user interface tool installed by the script (lazygit, yazi, zoxide) | "CLI tool" | Distinct from shell utilities — these have interactive interfaces |
| **LSP server** | A Language Server Protocol server providing code intelligence in Neovim | "language server" | Installed via Mason, not via system packages |
| **formatter** | A code formatting tool configured for Neovim's on-save formatting | — | Managed via conform.nvim in the custom layer |

---

## Relationships

- A **dotfiles** repo contains multiple **agent configs** (one per supported agent)
- Non-Pi **agent configs** have their **skills** directory symlinked to the **shared skills directory**
- Pi exposes shared skills through `pi/skills/`, which is deployed to `~/.pi/agent/skills`
- A **custom layer** can contain multiple **plugins (Neovim)**
- A **kickstart** configuration imports exactly one **custom layer**
- The **install** process **deploys** multiple **symlinks** and **installs (dependency)** multiple system packages and Mason packages
- A **symlink** always points from a system path to a source file in the **dotfiles** repo
- **Tool provisioning** depends on **symlink management** for config deployment of TUI tools
- The **SSH multiplexer** defaults to Herdr and MAY fall back to tmux through an environment override
- A **Herdr workspace** contains one or more **Herdr tabs**, and a **Herdr tab** contains one or more **Herdr panes**
- The **caller pane** invokes an operation, while the **focused pane** reflects UI selection; they MAY differ
- A **public Herdr ID** MUST be refreshed after topology changes, while a **legacy display selector** MUST NOT be treated as durable identity
- **Herdr config** is deployed by the **dotfiles** repo, while **Herdr runtime state** remains local-only and out of git
- A **repo-owned Herdr integration** is generated or copied into **agent configs** before deployment, rather than installed directly into live runtime paths
- The **Herdr skill** lives in the **shared skills directory** and is visible to supported agents through their skills deployment paths
- A **Wayfinder map** indexes multiple **decision tickets** and derives its **frontier** from resolved ticket blockers
- An **active-plan pointer** identifies one **plan workspace**, which contains multiple **slices** and their **verification artifacts**
- A plan **frontier** contains ready **slices** only after every blocking slice is integrated
- A **skill body** uses the **Language Definitions section** and only the optional sections earned by its behavior
- A **behavior-preservation ledger** is required before a material skill-body restructure
- A **plan workspace**, **spec-extraction plan**, **Ralph job plan**, **teaching workspace**, and **Herdr workspace** have distinct owners and lifecycles
- A **neutral diff artifact** may inform visual review but does not supply acceptance

---

## Flagged Ambiguities

- **"install"** is used to mean the full install.sh run, a single system package installation, and a Mason package installation. These are distinct operations: use **install**, **install (dependency)**, and **install (Mason)** respectively.
- **"plugin"** is used to mean a Neovim lazy.nvim plugin, an Oh My Zsh plugin, or a Pi extension. These are distinct concepts: use **plugin (Neovim)**, **plugin (Oh My Zsh)**, or **extension (Pi)** respectively.
- **"config"** is used to mean a source file in the dotfiles repo, a deployed file on disk, or an application's own config format. Use **dotfiles** (repo source), **symlink** (deployed pointer), or name the specific application config format.
- **"manager"** could mean the overall dotfiles manager concept, fnm (Fast Node Manager), or Mason (LSP manager). Use **dotfiles** (the system), **fnm**, or **Mason** specifically.
- **"custom"** could mean the nvim/custom/ symlink layer, user customization in general, or the .zshrc.custom file. Use **custom layer** (Neovim), **custom shell config** (zsh), or **user customization** (general) respectively.
- **"strong model"** or **"weak model"** are informal terms that should be avoided in specs. Prefer specific model/provider names and rationale.
- **"profile"** refers to install profiles (Full, Minimal, Work, Custom). Pi profiles are no longer a supported concept in this repo.
- **"integration"** is overloaded between Herdr integrations, shell integrations, and editor integrations. Use **Herdr integration** when referring to Herdr agent lifecycle/session hooks.
- **"workspace"** is overloaded between a project workspace, **plan workspace**, **teaching workspace**, and **Herdr workspace**. Use the qualified term for each durable or terminal context.
- **"plan"** is overloaded between a **plan workspace**, **spec-extraction plan**, and **Ralph job plan**. These artifacts are non-interchangeable and MUST use their qualified names.
- **"current pane"** can mean the **caller pane** or **focused pane**. Discover the caller from runtime context rather than inferring it from focus.
- **"visual comparison"** can mean neutral description or acceptance judgment. Use **neutral diff artifact** only for no-verdict evidence.
- Skill-local definitions belong in the owning **skill body**; terms shared by specs or multiple workflows belong in this project glossary.
- **"prefix key"** is ambiguous after Herdr adoption. Use **multiplexer prefix key** for shared behavior, **tmux prefix key** for tmux, and **Herdr prefix key** for Herdr.

---

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 0.7.0 | 2026-07-14 | Added the shared-skill body vocabulary, qualified workflow artifacts, Herdr caller and runtime identity distinctions, and neutral visual evidence ownership. |

## Example Dialogue

> **Dev**: "If I edit `pi/settings.json`, what makes it live in Pi?"
> **Domain Expert**: "Run the Pi install module. It deploys the repo file to the single Pi **agent config** under `~/.pi/agent`."
> **Dev**: "Can I add a second Pi runtime variant?"
> **Domain Expert**: "No. Pi profiles were unshipped. This repo now supports one Pi **agent config**."
> **Dev**: "Should SSH still auto-attach tmux?"
> **Domain Expert**: "No. The **SSH multiplexer** defaults to Herdr now, but tmux remains available through the fallback environment override."
> **Dev**: "Where do Herdr's saved panes go?"
> **Domain Expert**: "They are **Herdr runtime state**. They can exist locally, including pane history, but they must never be committed as **Herdr config**."

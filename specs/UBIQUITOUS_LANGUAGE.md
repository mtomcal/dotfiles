# Ubiquitous Language

> **Version**: 2.2.0
> **Last Updated**: 2026-08-03
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
| **Visual Studio Code Desktop** | The official stable Microsoft desktop editor managed on macOS through its Homebrew Cask | "VS Code" when the target is ambiguous | Distinct from code-server and excluded on Linux in this dotfiles environment |
| **code-server** | The browser-accessible Code OSS distribution managed as an explicit Ubuntu/Debian service | "VS Code server", "Codespace" | Distinct from Microsoft VS Code Server, Remote Tunnels, and GitHub Codespaces |
| **Default Profile (VS Code)** | The unnamed base Visual Studio Code configuration scope whose user settings apply when no named profile is active | "global profile", "default settings" | The only VS Code profile scope owned by the dotfiles system |
| **VS Code managed layer** | The repository-owned VS Code settings, keybindings, snippets, and extension manifests deployed to supported editor targets | "VS Code User folder", "synced settings" | Excludes authentication, profile internals, history, UI state, certificates, and machine-specific values |
| **extension (VS Code)** | A publisher-qualified editor capability installed from a target's extension marketplace | "plugin", bare "extension" | Overloaded — disambiguate from extension (Pi), plugin (Neovim), and browser extensions |
| **extension manifest (VS Code)** | A repository-owned required-presence list of unpinned or exceptionally pinned VS Code extension identities for one or both supported targets | "extension lockfile", "installed extension list" | Reconciliation installs or updates listed entries but never prunes unlisted extensions |
| **private-network browser endpoint** | An authenticated HTTPS code-server listener intended for reachability through operator-controlled trusted networking | "public code server", "Codespace endpoint" | The repository does not name, discover, or configure a particular network product |
| **VS Code capture** | An explicit non-deployment operation that imports existing desktop settings, keybindings, snippets, and extension identities into the VS Code managed layer | "sync", "install" | Normal install never captures or writes repository sources |

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
| **Herdr skill** | The adapted upstream operating instructions under `shared/skills/herdr/` that own generic Herdr CLI transport and status-observation mechanics | "global Herdr skill" | Tracked in the shared skills directory so all supported agents can use it consistently. |
| **Claude Code Herdr skill** | The repository-authored specialization under `shared/skills/herdr-claude-code/` that composes the Herdr skill and owns Claude Code launch, readiness, prompt-submission, and steering behavior | "Claude Herdr mechanics", "Claude transport fork" | It does not duplicate or replace generic Herdr commands. |

## Agent Domain

| Term | Definition | Aliases to avoid | Context notes |
|------|-----------|-------------------|---------------|
| **agent** | An AI coding assistant (Codex CLI, Claude Code, Pi, or Copilot CLI) | "AI", "assistant" | Used generically when referring to any or all of the supported agents |
| **skill** | A reusable instruction set for one or more AI agents | "instruction" | Cross-agent skills live in `shared/skills/`; Pi exposes them through `pi/skills/`. |
| **Skill Library** | The bounded context that owns the canonical shared-skill catalog, authoring semantics, progressive disclosure, composition boundaries, provenance, and semantic quality | "agent config", "skills folder" | Agent configuration exposes the library but does not own its content contracts |
| **skill body** | The invoked Markdown instructions that follow a skill's frontmatter | "skill prompt", "instructions" | Uses the canonical shared-skill body sections when the skill is new or materially modified |
| **core instruction** | A compact, universally required behavior kept directly in the skill body | "mandatory reference", "support rule" | Core instructions remain local rather than being displaced into universally loaded companion files |
| **shared skills directory** | The canonical cross-agent skills directory at `~/dotfiles/shared/skills/` | — | Non-Pi agent skill paths point here directly. Pi-visible skill entries point here through `pi/skills/` symlinks. |
| **agent config** | An agent-specific configuration directory managed from the dotfiles repo | — | Each supported agent has one repo-owned config surface. Pi's config deploys to `~/.pi/agent`. |
| **catalog exposure** | An agent config directory's role of exposing the shared skill catalog and repo-managed commands and agents to a runtime | "catalog directory", "skills folder" | Copilot separates catalog exposure (`~/.config/copilot`) from its runtime settings and Herdr hook directory (`~/.copilot`); other agents combine both in one config directory. |
| **unshipping** | Removing a feature, tool, config surface, or workflow entirely from the repo's tracked and deployed contract | "disable", "hide" | Includes implementation, tests, docs, specs, generated artifacts, and installer surfaces unless explicitly scoped otherwise. |
| **explainer page** | A self-contained HTML artifact that conveys a system, change, plan, or dataset to a reader, carrying no interactive assessment | "diagram", "report", "visual" | Owned by `visual-explainer`. Distinct from a **learning artifact**, which requires learner response, and from the architecture review report, which is one explainer page with a caller-owned content contract. |
| **learning artifact** | An interactive retrieval-practice artifact that requires a learner response, such as a quiz, prediction exercise, or sequencing problem | "explainer", "lesson" | Owned solely by `teach`. The catalog currently ships no learning-artifact templates. |

## Agent Workflow Domain

| Term | Definition | Aliases to avoid | Context notes |
|------|-----------|-------------------|---------------|
| **Language Definitions section** | The mandatory skill-body section containing execution-relevant skill-local vocabulary or the statement “No skill-specific terms” | "glossary", "terminology section" | Project-domain terms remain in the applicable project glossary |
| **Workflow section** | The optional skill-body section containing at most one primary end-to-end process with routing or mode selection first | "process section", "multiple workflows" | Branches remain inside the single primary Workflow |
| **Activity** | An independently reusable command, action, or recipe selected outside a required end-to-end sequence | "Workflow step", "procedure" | Activities do not restate ordinary Workflow steps |
| **branch outcome** | A selected route or concrete runtime condition that makes branch-specific context necessary | "workflow stage", "eventual step" | At least one successful supported route must not produce the outcome |
| **Reference section** | The optional skill-body index containing only branch-conditioned Reference pointers | "resources", "appendix", "links" | It is a progressive-disclosure mechanism, not a miscellaneous support section |
| **Reference pointer** | A conditional link stating the branch outcome that requires added context and why its target must then be loaded | "link", "resource pointer" | Loading becomes mandatory when the condition is true |
| **Reference file** | Supporting Markdown containing necessary detail for a selected branch and loaded only after its Reference pointer condition becomes true | "required companion", "overflow file" | At least one successful supported route must complete without loading it |
| **progressive disclosure** | The staged loading of a catalog description, an invoked skill body, and Reference files selected by branch outcomes | "documentation split", "delayed loading", "shortening" | Deferring content reached by every successful route is sequencing, not progressive disclosure |
| **semantic YAGNI** | Retaining skill content only when it changes execution behavior, safety, ownership, outputs, or completion evidence | "line limit", "make it shorter" | Unnecessary content is removed rather than relocated to a Reference file |
| **hill climbing** | Avoidable repository navigation required to reconstruct an executable contract that should be locally available | "code exploration" | Universally loaded companion files create hill climbing without progressive-disclosure benefit |
| **behavior-preservation ledger** | An audit record mapping each required behavior to its retained location or replacement owner | "change summary", "checklist" | Covers triggers, branches, gates, failures, guardrails, outputs, ownership, and completion conditions |
| **command repo** | The private external repository whose Beads database is authoritative for execution coordination across multiple source repositories | "planning repo", "central beads folder" | It stores operational state rather than source code or dotfiles configuration, and source repositories contain no `.beads/` state. |
| **scope snapshot** | The frozen human-approved objective, acceptance criteria, failure criteria, and exclusions that authorize one execution molecule | "spec diff", "mutable brief" | A specification diff is optional evidence rather than a creation precondition; changing scope requires an approved decision bead. |
| **execution molecule** | A Beads molecule whose root scope and dependency-ordered work beads form one execution-ready implementation and review graph | "implementation plan", "execution ledger", "plan file" | Created directly by `create-engineering-plan`; it combines planning and execution state without durable workflow Markdown. |
| **legacy execution ledger** | The single grandfathered filesystem execution record allowed to reach a terminal state during Beads adoption | "current plan", "new ledger" | No new legacy execution ledger may be created, and support is removed after it becomes terminal. |
| **work bead** | A dependency-aware executable or decision record within an execution molecule | "task file", "slice file" | Work beads include slices, review beads, remediation beads, mechanical gates, and decision beads. |
| **review policy** | The human-approved review breadth, depth, and independence requirements selected when an execution molecule is created | "review budget", "review configuration" | Lean, Standard, and High-assurance presets provide defaults with explicit overrides. |
| **review gate** | A required acceptance condition in a review policy, satisfied by mechanical evidence or one or more independent review beads | "review pass", "review step" | Repository gates and Scope fidelity form the minimum final floor; other gates and redundant passes are creation-time choices. |
| **review bead** | A work bead representing one independent pass for a review gate against a fixed candidate | "verification artifact", "review file" | A gate may have multiple review beads when its approved depth exceeds one. |
| **proposed execution trace** | An evidence-grounded representation of intended runtime call order and depth for a slice, with binding order distinguished from permitted internal variance | "call graph", "stack trace", "sequence diagram" | It lives on the slice bead and is neither a captured runtime trace nor an exhaustive control-flow diagram. |
| **coordinator** | The actor with exclusive authority over an execution molecule's structure, scope, acceptance, integration, and recovery without implementing or reviewing | "parent owner", "parent agent" | Beads stores durable authority while Herdr provides live transport and communication. |
| **coordinator lease** | The non-expiring exclusive authority granted to one coordinator session on one host for one execution molecule | "timeout lock", "pane ownership" | Takeover requires evidence inspection, human approval, and an auditable decision. |
| **coordinator session** | A permanent bead representing one coordinator incarnation, including its exact model, host, lease events, checkpoints, and terminal outcome | "coordinator pane", "current coordinator" | The molecule root points to one active session while preserving prior sessions. |
| **model assignment** | The exact command, provider, model id, thinking level, role, and applicable independence rule approved for an executable bead or coordinator | "model hint", "strong model" | An unavailable initial assignment blocks until approved reassignment. |
| **escalation ladder** | The human-approved ordered list of exact model assignments permitted for automatic escalation within one execution molecule | "stronger model ranking", "fallback guess" | Runtime escalation moves only to an available higher approved rung. |
| **worker attempt** | A permanent non-blocking bead recording one agent launch, its exact model, durable instructions, semantic transitions, evidence, and outcome | "worker pane", "attempt comment" | Attempts link to their owning work bead but never determine the executable frontier directly. |
| **write-ahead attempt** | A worker attempt durably created and checkpointed before its corresponding Herdr launch or consequential message | "launch record", "post-hoc attempt" | It makes coordinator death between intent and side effect recoverable. |
| **worker-attempt graph** | The non-blocking operational graph of coordinator sessions and worker attempts linked to executable work beads | "Herdr topology", "terminal graph" | Beads owns durable attempt history while Herdr owns live sessions, communication, and observation. |
| **spec-extraction plan** | The brownfield Bootstrap Specs artifact that directs extraction of specifications from implementation evidence | "execution molecule", "slice graph" | It does not direct code implementation or execution orchestration. |
| **teaching workspace** | The dedicated durable directory containing one learner's mission, resources, lessons, references, assets, and evidence | "command repo", "Herdr workspace" | Teaching state has its own owner and lifecycle. |
| **frontier** | The derived set of currently actionable work beads whose blocking dependencies are closed after integration | "queue", "backlog" | Worker attempts are non-blocking and never appear in the frontier. |
| **slice** | A context-sized work bead that delivers one vertical behavior through ordered red, green, and refactor cycles | "task", "ticket", "slice file" | Editable slices receive isolated worktrees and close only after verification and integration. |
| **decision bead** | A durable approval record authorizing a change to frozen scope, review policy, model assignment, escalation, or coordinator lease | "decision comment", "silent override" | The prior contract and approved replacement remain auditable. |

## Tooling Domain

| Term | Definition | Aliases to avoid | Context notes |
|------|-----------|-------------------|---------------|
| **TUI tool** | A terminal user interface tool installed by the script (lazygit, yazi, zoxide) | "CLI tool" | Distinct from shell utilities — these have interactive interfaces |
| **LSP server** | A Language Server Protocol server providing code intelligence in Neovim | "language server" | Installed via Mason, not via system packages |
| **formatter** | A code formatting tool configured for Neovim's on-save formatting | — | Managed via conform.nvim in the custom layer |
| **Beads** | The graph issue tracker whose CLI and database represent durable execution-coordination state in the command repo | "Markdown plan tracker", "filesystem ledger" | `bd` is globally routed to the external command repo after bootstrap. |
| **embedded Dolt** | The versioned SQL storage engine linked into the `bd` binary, running in-process as a single writer and backing private-remote synchronization | "Dolt server", "Beads daemon", "Git database" | No separate Dolt binary, server process, or port exists; durable writes serialize through one writer position. |

---

## Relationships

- A **dotfiles** repo contains multiple **agent configs** (one per supported agent)
- Non-Pi **agent configs** have their **skills** directory symlinked to the **shared skills directory**
- Pi exposes shared skills through `pi/skills/`, which is deployed to `~/.pi/agent/skills`
- A **custom layer** can contain multiple **plugins (Neovim)**
- A **kickstart** configuration imports exactly one **custom layer**
- A **VS Code managed layer** deploys to the **Default Profile (VS Code)** of one or more supported editor targets
- A **VS Code managed layer** contains three **extension manifests (VS Code)**: shared, desktop-specific, and code-server-specific
- An **extension manifest (VS Code)** contains zero or more **extensions (VS Code)** and declares required presence without declaring an exact installed inventory
- **VS Code capture** may initialize the **VS Code managed layer**, while install deploys that layer and never performs capture
- **code-server** exposes one **private-network browser endpoint** whose bind value, password, and certificate remain local
- The **install** process **deploys** multiple **symlinks** and **installs (dependency)** multiple system packages and Mason packages
- A **symlink** always points from a system path to a source file in the **dotfiles** repo
- **Tool provisioning** depends on **symlink management** for config deployment of TUI tools
- The **SSH multiplexer** defaults to Herdr and MAY fall back to tmux through an environment override
- A **Herdr workspace** contains one or more **Herdr tabs**, and a **Herdr tab** contains one or more **Herdr panes**
- The **caller pane** invokes an operation, while the **focused pane** reflects UI selection; they MAY differ
- A **public Herdr ID** MUST be refreshed after topology changes, while a **legacy display selector** MUST NOT be treated as durable identity
- **Herdr config** is deployed by the **dotfiles** repo, while **Herdr runtime state** remains local-only and out of git
- A **repo-owned Herdr integration** is generated or copied into **agent configs** before deployment, rather than installed directly into live runtime paths
- The **Herdr skill** and **Claude Code Herdr skill** live in the **shared skills directory** and are visible to supported agents through their skills deployment paths
- The **Claude Code Herdr skill** composes the **Herdr skill**, which retains generic terminal transport and server-owned settled-state waiting
- One **command repo** contains one **Beads** database backed by **embedded Dolt** and zero or more **execution molecules** for multiple source repositories, while each source repository contains no Beads workspace
- One **execution molecule** contains one frozen **scope snapshot**, multiple dependency-ordered **work beads**, one approved **review policy**, and one non-blocking **worker-attempt graph**
- A **slice** carries its TDD contract and applicable **proposed execution traces** directly as Beads content rather than a Markdown packet
- A **review policy** contains one or more **review gates**, and a review gate may require multiple independent **review beads**
- A **model assignment** is materialized onto every executable bead, while an **escalation ladder** constrains automatic runtime escalation
- A **coordinator lease** points to one active **coordinator session** and never expires automatically
- A **write-ahead attempt** precedes every Herdr agent side effect, while the owning **worker attempt** stores instructions and evidence
- The **worker-attempt graph** is durable in Beads, while Herdr provides ephemeral agent transport, communication, and observation
- An execution **frontier** contains ready **work beads** only after every blocker closes following integration; worker attempts never enter it
- The **Skill Library** owns each canonical **skill** in the **shared skills directory**, while **agent configs** expose that catalog to supported runtimes
- A **skill body** uses the **Language Definitions section** and only the optional sections earned by its behavior
- A **core instruction** remains in the **skill body**, while a **Reference pointer** loads a **Reference file** only after its **branch outcome** occurs
- **Semantic YAGNI** removes unnecessary content instead of moving it into a Reference file, reducing avoidable **hill climbing**
- A **behavior-preservation ledger** is required before a material skill-body restructure
- One **legacy execution ledger** may finish during migration, but every new execution uses an **execution molecule**
- An **execution molecule**, **spec-extraction plan**, **teaching workspace**, **command repo**, and **Herdr workspace** have distinct owners and lifecycles

---

## Flagged Ambiguities

- **"install"** is used to mean the full install.sh run, a single system package installation, and a Mason package installation. These are distinct operations: use **install**, **install (dependency)**, and **install (Mason)** respectively.
- **"plugin"** is used to mean a Neovim lazy.nvim plugin, an Oh My Zsh plugin, or an editor/agent extension. These are distinct concepts: use **plugin (Neovim)**, **plugin (Oh My Zsh)**, **extension (Pi)**, or **extension (VS Code)** respectively.
- **"VS Code server"** can mean Microsoft VS Code Server, Remote Tunnels, GitHub Codespaces, or **code-server**. This suite uses **code-server** only for the managed browser distribution and excludes the other three.
- **"profile"** can mean an installation profile or **Default Profile (VS Code)**. Qualify the term; named VS Code profiles are outside managed ownership.
- **"sync"** can mean cloud Settings Sync or importing configuration. Use **VS Code capture** for repository import; Settings Sync is not authoritative and must be disabled manually.
- **"config"** is used to mean a source file in the dotfiles repo, a deployed file on disk, or an application's own config format. Use **dotfiles** (repo source), **symlink** (deployed pointer), or name the specific application config format.
- **"manager"** could mean the overall dotfiles manager concept, fnm (Fast Node Manager), or Mason (LSP manager). Use **dotfiles** (the system), **fnm**, or **Mason** specifically.
- **"custom"** could mean the nvim/custom/ symlink layer, user customization in general, or the .zshrc.custom file. Use **custom layer** (Neovim), **custom shell config** (zsh), or **user customization** (general) respectively.
- **"strong model"** or **"weak model"** are informal terms that should be avoided in specs. Prefer specific model/provider names and rationale.
- **"profile"** refers to install profiles (Full, Minimal, Work, Custom). Pi profiles are no longer a supported concept in this repo.
- **"integration"** is overloaded between Herdr integrations, shell integrations, and editor integrations. Use **Herdr integration** when referring to Herdr agent lifecycle/session hooks.
- **"workspace"** is overloaded between a project workspace, **teaching workspace**, **command repo**, and **Herdr workspace**. Use the qualified term for each durable or terminal context.
- **"plan"** is overloaded between an **execution molecule**, a **spec-extraction plan**, and an informal proposed approach. Use the qualified artifact or process name.
- **"review"** may mean a **review policy**, **review gate**, or **review bead**. Use policy for topology, gate for an acceptance condition, and bead for one executable pass.
- **"trace"** is ambiguous between a **proposed execution trace** and an actual captured runtime stack trace. Slice beads use the proposed form; they never claim captured runtime evidence.
- **"stronger model"** has no runtime meaning outside an approved **escalation ladder**; use the exact higher rung rather than reputation-based labels.
- **"parent"** or **"parent owner"** formerly named the actor controlling implementation state. Use **coordinator** for the execution-molecule authority.
- **"current pane"** can mean the **caller pane** or **focused pane**. Discover the caller from runtime context rather than inferring it from focus.
- Skill-local definitions belong in the owning **skill body**; terms shared by specs or multiple workflows belong in this project glossary.
- Bare **"Reference"** can mean the section, pointer, or target file. Use **Reference section**, **Reference pointer**, or **Reference file**; a universally required companion file is not a Reference file.
- **"progressive disclosure"** is sometimes used for any delayed file load. In the Skill Library it requires a branch outcome and a successful supported route that does not load the selected file.
- **"prefix key"** is ambiguous after Herdr adoption. Use **multiplexer prefix key** for shared behavior, **tmux prefix key** for tmux, and **Herdr prefix key** for Herdr.
- **"Herdr skill"** means the generic base transport workflow. Use **Claude Code Herdr skill** for Claude-specific launch, composer, and steering behavior.

---

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 2.2.0 | 2026-08-03 | Added **explainer page** and **learning artifact** to separate communication rendering from interactive retrieval practice after `create-explainer` was removed. |
| 2.1.0 | 2026-08-02 | Replaced the "Dolt server" term with single-writer **embedded Dolt**. |
| 2.0.0 | 2026-08-01 | Replaced filesystem plans and ledgers with command-repo execution molecules, exact model and review policy, coordinator leases/sessions, and write-ahead worker-attempt graphs. |
| 1.5.0 | 2026-08-01 | Added `catalog exposure` to name the agent config role that exposes the shared skill catalog, distinguishing Copilot's catalog exposure directory from its runtime settings directory. |
| 1.4.0 | 2026-08-01 | Updated the Herdr skill relationship from client-owned concurrent status races to server-owned settled-state waiting. |
| 1.3.0 | 2026-07-31 | Added Visual Studio Code Desktop, code-server, Default Profile, VS Code managed layer, VS Code extension manifest, capture, and private-network browser endpoint terminology and distinctions. |
| 1.2.0 | 2026-07-15 | Added `review gate` and `proposed execution trace`; redefined the immutable implementation plan to define binding final review gates while still excluding review results, reviewer/model configuration, and execution state. |
| 1.1.0 | 2026-07-15 | Distinguished the generic Herdr skill from its composing Claude Code orchestration specialization. |
| 1.0.0 | 2026-07-15 | Replaced plan-workspace and parent-owner terminology with immutable implementation plans, coordinator-owned execution ledgers, and active-ledger routing. |
| 0.9.0 | 2026-07-15 | Removed vocabulary and relationships owned solely by retired workflows while preserving plan-frontier terminology. |
| 0.8.0 | 2026-07-14 | Established the Skill Library bounded context and distinguished core instructions, branch outcomes, Reference sections, Reference pointers, Reference files, semantic YAGNI, progressive disclosure, and hill climbing. |
| 0.7.0 | 2026-07-14 | Added the shared-skill body vocabulary, qualified workflow artifacts, and Herdr caller and runtime identity distinctions. |

## Example Dialogue

> **Dev**: "Can install copy my current editor state into the repo?"
> **Domain Expert**: "No. **VS Code capture** initializes the **VS Code managed layer** explicitly; install only deploys it to the **Default Profile (VS Code)**."
> **Dev**: "Does the **extension manifest (VS Code)** remove extensions I installed experimentally?"
> **Domain Expert**: "No. It requires listed **extensions (VS Code)** to be present but never prunes unlisted extensions."
> **Dev**: "Does the **private-network browser endpoint** reveal which network product reaches it?"
> **Domain Expert**: "No. **code-server** provides generic authenticated HTTPS access, while product-specific networking stays outside the repository."
>
> **Dev**: "Does AI Agent Configuration own how a shared skill is written?"
> **Domain Expert**: "No. The **Skill Library** owns skill semantics; the **agent config** only exposes canonical skills to a runtime."
> **Dev**: "Does a **review gate** identify its exact reviewer?"
> **Domain Expert**: "The gate defines the acceptance condition; each generated **review bead** carries its own exact **model assignment** and result."

### Additional Agent Workflow Examples

> **Dev**: "Can every successful route load the same **Reference file** if the pointer appears near a later step?"
> **Domain Expert**: "No. That is sequencing. A valid **Reference pointer** requires a **branch outcome** and at least one successful no-load route."
> **Dev**: "Where does universally required behavior go?"
> **Domain Expert**: "Keep it as a compact **core instruction** in the skill body; **semantic YAGNI** removes unnecessary detail instead of creating **hill climbing**."
> **Dev**: "Does `create-engineering-plan` write a `PLAN.md` before execution?"
> **Domain Expert**: "No. It creates one execution-ready **execution molecule** whose **slices**, review policy, and model assignments are already explicit."
> **Dev**: "Should `execute-engineering-molecule` own Claude-specific launch or waiting mechanics?"
> **Domain Expert**: "No. It composes the **Herdr skill** for generic transport and server-owned settled-state waiting, and the **Claude Code Herdr skill** for Claude-specific launch arguments, task interpretation, and steering behavior."
> **Dev**: "Is a **proposed execution trace** a real stack trace I captured at runtime?"
> **Domain Expert**: "No. It is an evidence-grounded intended call tree carried directly by an applicable **slice** bead."
> **Dev**: "If Herdr disappears, is the execution lost?"
> **Domain Expert**: "No. The **worker-attempt graph** retains intent, instructions, evidence, and pending transitions; fresh Herdr only recreates live communication sessions."
> **Dev**: "Can a replacement coordinator take over after a timeout?"
> **Domain Expert**: "No. A **coordinator lease** never expires automatically; takeover requires inspection, human approval, and a **decision bead**."
> **Dev**: "May a failed worker choose a stronger model?"
> **Domain Expert**: "Only by moving to an exact higher assignment in the approved **escalation ladder**."

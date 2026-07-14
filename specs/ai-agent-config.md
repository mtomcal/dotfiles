# AI Agent Configuration Specification

> **Version**: 2.3.0
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

### Shared Skill Body Contract

The **skill body** of every newly added or materially modified shared skill MUST use these semantic sections in this order:

1. `Language Definitions` is mandatory. It MUST contain only execution-relevant skill-local terms, or the exact statement “No skill-specific terms.”
2. `Workflow` is optional. When present, it MUST contain at most one primary end-to-end process and MUST put routing or mode selection at its beginning.
3. `Activities` is optional. When present, it MUST contain independently reusable commands, actions, or recipes and MUST NOT restate ordinary Workflow steps.
4. `Reference` is optional. When present, each Markdown pointer MUST state when and why its support file must be loaded.

A skill MAY omit any optional section that its behavior does not require. Required main-path behavior MUST NOT be hidden behind optional wording or conditional Reference loading.

Skill-body content MUST be retained when it changes invocation or routing, workflow correctness, reusable Activity execution, guardrails or failure handling, output or artifact contracts, or required cross-agent or repository behavior. Fixed line limits MUST NOT be used as the YAGNI standard; size changes are evidence only.

Guardrails, failure handling, approvals, output contracts, and completion criteria MUST remain beside the Workflow step or Activity they govern. Literal or detail-heavy schemas and templates MAY move to Reference when the main skill body retains a compact executable contract and an explicit load condition.

Before materially restructuring a skill body, the author MUST create a **behavior-preservation ledger**. Every trigger, branch, gate, failure, guardrail, output, ownership rule, and completion condition MUST either remain in the resulting skill or name its replacement owner.

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
| `wayfinder` | Resolves uncertainty in local Markdown maps and decision tickets, preserves fog/frontier/scope distinctions, and routes only clarified work onward |
| `create-plan` | Stores recoverable orchestration state in a temporary plan workspace with fresh-context TDD slices and independent verification artifacts |
| `teach` | Requires an approved dedicated teaching workspace and preserves mission, resources, learning records, HTML lessons, references, assets, and notes |
| `grill-me` | Loads root and spec-suite ubiquitous language, tests relationships with concrete edge cases, checks claims against code/specs, and defers file edits until shared understanding |

### Catalog Ownership and Composition

The shared-skill catalog MUST preserve these ownership boundaries:

1. `write-a-skill` owns skill-body authoring, progressive disclosure, independently invocable split tests, and semantic YAGNI pruning.
2. `audit-shared-skills` owns executable validation of the repository's existing union-frontmatter schema. It MUST NOT be represented as the owner of semantic or YAGNI review.
3. Terminal transport skills own terminal command mechanics. Their callers retain the task brief, workflow state, acceptance decision, returned-evidence contract, and in-process fallback.
4. Checkout isolation MUST be selected before terminal transport. Read-only delegates MAY share a checkout; any delegate authorized to edit files MUST use an isolated clone or worktree.
5. Composing another skill imports its process, not its ownership. The caller retains its artifact location, user gates, state, and return criteria.
6. `code-review` owns generic fixed-point Standards and Spec review semantics. Specialist reviewers retain authority over their narrow contracts and MUST NOT silently waive or rerank another review axis.
7. Visual work MUST preserve the applicable stages: capture, optional recording conversion, optional neutral diff production, general QA or scoped judgment, and caller or human acceptance. A specialist verdict MUST NOT claim final human acceptance.
8. Templates, output contracts, ranking models, and checklists MUST remain owned by their domain producer rather than being normalized into a universal schema.

### Workflow Artifact and State Ownership

Wayfinder decision tickets, plan-workspace slices, **spec-extraction plans**, **Ralph job plans**, teaching state, and generated artifacts are non-interchangeable. Each workflow MUST use the qualified artifact name, preserve its own writer and lifecycle, and MUST NOT infer another workflow's state transitions from a generic “plan” or “workspace” label.

Reciprocal routing MAY compose workflows, but it MUST NOT transfer state or artifact ownership. A caller MUST retain its destination, durable writer, approval gates, and return criteria unless another approved contract explicitly names a replacement owner.

Imported skill material MUST be treated as a locally maintained fork. Before imported material is moved or rewritten, its source, revision, and license MUST be identified, and provenance plus required license attribution MUST live in the repository-level `THIRD_PARTY_NOTICES.md`. Automatic upstream synchronization is outside the shipped contract.

When a skill delegates through Herdr under `HERDR_ENV=1`, it SHOULD load the shared Herdr skill rather than duplicate Herdr commands. The same workflow MUST provide an in-process fallback outside Herdr. A separate pane MUST NOT be treated as checkout isolation. Public Herdr IDs MUST be refreshed after topology changes, and neither public IDs nor legacy display selectors may be persisted as durable workflow identity.

### Wayfinder State Contract

A Wayfinder effort MUST store one `MAP.md` and numbered ticket files under `.wayfinder/<effort-slug>/`. Ticket frontmatter MUST contain an effort-local id, one of the supported ticket types, one supported lifecycle status, and a blocker list. The parent agent MUST be the sole writer of map and ticket state; delegated findings MUST return through agent output rather than direct state mutation.

Wayfinder MUST resolve uncertainty rather than production implementation. Completion MUST route durable behavior and terminology to the spec-maintenance workflows and route implementation to `create-plan`.

### Plan Workspace Contract

An active implementation plan MUST be stored beneath `/tmp/agent-plans/<repo-id>/<plan-id>/` with `PLAN.md`, a `slices/` directory, and a `verifications/` directory. The repository-local `.plan` file MUST contain the active workspace's absolute path and MUST be registered in local Git exclude metadata. A missing pointer target MUST be reported as stale; agents MUST NOT infer or silently reconstruct its state.

`PLAN.md` MUST record the immutable objective, context sources, baseline, integration branch, explicit execution defaults, dependency DAG, derived frontier, slice states, Git/Herdr session references, verification matrix, acceptance criteria, and recovery instructions. The parent agent MUST be the sole writer of control-plane state.

Every editable slice MUST use an isolated worktree and branch and MUST fit one fresh agent context. Slice blockers gate on integration. Every slice MUST receive independent Standards and Spec reviews after the worker commit and before parent integration; additional Tests, Premortem, Security, and Visual passes MUST be enabled by risk. Failed attempts MUST remain in the same verification artifact and return fixes to the original slice branch. Final integration and acceptance reviews MUST run after all slices integrate.

### Teaching Workspace Contract

The teaching workflow MUST ask for and receive approval for a dedicated workspace before scaffolding. It MUST ground lessons in an agreed mission, use primary-source research, maintain durable resources and demonstrated-learning records, prefer reusable lesson assets, and distinguish knowledge acquisition, skill practice, and wisdom from real-world interaction. Interactive codebase lessons SHOULD compose `create-explainer` without weakening teaching-workspace ownership or citation requirements.

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

Category: Integration
Priority: High
Preconditions: The repository checkout contains the shipped shared skill catalog.

Input: Audit shared skill frontmatter and inspect Pi-visible entries for `codebase-design`, `diagnosing-bugs`, `code-review`, `resolving-merge-conflicts`, `handoff`, `research`, `wayfinder`, and `teach`.

Expected Output: Required frontmatter is valid, every named Pi entry resolves to its canonical shared skill, stale pre-decomposition Playwright visibility entries are absent, and provenance attribution is present in the repository-level `THIRD_PARTY_NOTICES.md`.

### TS-AIAGT-006: Workflow State Ownership

Category: Integration
Priority: High
Preconditions: The shipped Wayfinder and create-plan skill definitions are available.

Input: Inspect their state schemas, delegation rules, and lifecycle gates.

Expected Output: Wayfinder uses parent-owned local Markdown decision state and stops before implementation; create-plan uses an active-plan pointer, parent-owned temporary control plane, isolated editable slices, mandatory independent Standards and Spec reviews, risk-selected additional reviews, and integration-gated dependencies.

### TS-AIAGT-007: Canonical Shared-Skill Body

Category: Integration
Priority: High
Preconditions: A new or materially modified shared skill and any supporting Markdown are available.

Input: Inspect the skill body's section order, section semantics, and Reference pointers.

Expected Output: `Language Definitions` is present; any `Workflow`, `Activities`, and `Reference` sections occur in canonical order and satisfy their distinct contracts; every Reference pointer states when and why to load its target; required main-path behavior remains inline.

### TS-AIAGT-008: Behavior Preservation and Ownership

Category: Integration
Priority: Critical
Preconditions: A shared skill is proposed for material restructuring and its pre-change behavior is known.

Input: Compare its behavior-preservation ledger, proposed body, composition pointers, and owner contracts.

Expected Output: Every trigger, branch, gate, failure, guardrail, output, ownership rule, and completion condition remains or names an approved replacement owner; composed workflows do not transfer caller state, gates, or acceptance authority.

### TS-AIAGT-009: Qualified Artifacts and Editable Delegation

Category: Integration
Priority: Critical
Preconditions: A workflow routes among plan-like artifacts and delegates work through terminal transport.

Input: Inspect artifact names, state ownership, checkout topology, and transport selection.

Expected Output: Decision tickets, plan-workspace slices, spec-extraction plans, Ralph job plans, teaching state, and generated artifacts remain qualified and non-interchangeable; checkout isolation is selected before transport; editable delegates use isolated checkouts; separate panes alone do not satisfy isolation.

---

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 2.3.0 | 2026-07-14 | Added the canonical shared-skill body and semantic YAGNI contracts, behavior-preservation gates, catalog ownership and composition boundaries, qualified workflow artifacts, provenance gates, and verification scenarios. |
| 2.2.0 | 2026-07-14 | Added Wayfinder and teaching workflows, a recoverable file-based plan control plane, domain-aware grilling, and repaired post-decomposition skill visibility. |
| 2.1.0 | 2026-07-14 | Added locally maintained cross-agent workflow skills, delegation fallbacks, provenance requirements, and the visual architecture-report contract. |
| 2.0.0 | 2026-07-08 | Unshipped retired agent/profile/delegation surfaces. Pi now deploys one repo-owned config under `~/.pi/agent`. |

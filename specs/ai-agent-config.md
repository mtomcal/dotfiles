# AI Agent Configuration Specification

> **Version**: 1.7.0
> **Last Updated**: 2026-06-02
> **Depends On**: [Parameters](parameters.md), [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md), [Design Language](DESIGN_LANGUAGE.md)
> **Depended By**: Install Orchestrator (INSTL)
> **Prefix**: AIAGT

---

## Overview

The AI Agent Configuration system provisions, configures, and manages five AI coding assistants — Codex CLI, Claude Code, Pi, Gemini CLI, and GitHub Copilot CLI — for a shared dotfiles environment. Pi additionally supports multiple **Pi profiles** — named configuration variants such as coding, local, or loop-oriented setups — that share one installed Pi binary but deploy separate runtime configs. Each Pi profile also supports **sub-agent roles** — named agent definitions in its resolved `agents/` directory that pre-configure model, provider, thinking level, tools, and guardrails for specialized tasks (design review, premortem analysis, visual QA, implementation, expert consultation). Every **agent** receives version-controlled configuration from the dotfiles repository via the **symlink deployment** pattern. Cross-agent skills live in the canonical **shared skills directory**; every Pi profile includes those shared skills and MAY add profile-local skills.

The system MUST ensure that:

1. Each agent's runtime configuration directory is wired to the dotfiles repository through symlinks, so edits in the repo are immediately live.
2. Sensitive data (credentials, session history, auth tokens) NEVER enters version control.
3. The shared skills directory is the single source of truth for cross-agent skill definitions. Non-Pi agent skills paths point directly to it; every Pi profile consumes those shared skills in its resolved runtime skills directory.
4. Each agent is installed to a user-local prefix that survives Node.js version manager switches.
5. The install process is **idempotent** — re-running it produces the same end state without errors or data loss.
6. Pi profile switching MUST change only the active runtime pointer and MUST NOT rewrite or mutate other deployed profiles.

---

## Dependencies

### Technology Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| Node.js | LTS | Runtime for Codex CLI, Pi, Gemini CLI (installed via fnm) |
| npm | Bundled with Node.js | Package installation for CLI agents |
| Docker | Any stable | Pi sandbox container runtime |
| curl | Any | Claude Code and Copilot CLI installation |
| fnm | Latest | Node.js version manager (survives version switches) |

### Spec Dependencies

| Spec | Relationship |
|------|-------------|
| [Parameters](parameters.md) | Defines `NODE_LTS_VERSION` and all installation parameters |
| [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md) | Defines **agent**, **skill**, **shared skills directory**, **agent config**, **deploy** |
| [Design Language](DESIGN_LANGUAGE.md) | Defines CLI output formatting tokens |
| [Symlink Manager](symlink-manager.md) | Defines the deploy/backup pattern used for all agent symlinks |

---

## Parameters

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| `NPM_GLOBAL_PREFIX` | `~/.local` | path prefix | Shared prefix for npm-installed agents so binaries survive fnm Node version switches; matches the `npm install -g --prefix` pattern |
| `AGENT_CONFIG_DIR_CODEX` | `~/.codex` | path | Codex CLI's canonical config directory |
| `AGENT_CONFIG_DIR_CLAUDE` | `~/.claude` | path | Claude Code's canonical config directory |
| `AGENT_CONFIG_DIR_PI` | `~/.pi/agent` | path | Compatibility path pointing to the active Pi profile runtime directory |
| `PI_PROFILE_ROOT_DIR` | `~/.pi/profiles` | path | Parent directory containing deployed Pi profile runtime directories |
| `PI_ACTIVE_PROFILE_FILE` | `~/.pi/active-profile` | path | File containing the active Pi profile name for inspection and recovery |
| `AGENT_CONFIG_DIR_GEMINI` | `~/.gemini` | path | Gemini CLI's canonical config directory |
| `AGENT_CONFIG_DIR_COPILOT` | `~/.config/copilot` | path | Copilot CLI's canonical config directory |
| `AGENT_SKILLS_DIR_CODEX` | `~/.agents/skills` | path | Codex CLI resolves skills from this path; symlinked to shared skills |
| `PI_ACTIVE_PROFILE_NAME` | `coding` | string | Default Pi profile selected after install unless the human switches it with `pim use` |
| `AGENT_SKILLS_DIR_PI` | `~/.pi/agent/skills` | path | Pi resolves skills from the active profile runtime's composed skills directory |
| `SANDBOX_BASE_IMAGE_NAME` | `dotfiles-dev-base:{UID}-{GID}` | image reference | Shared Docker base image for agent sandboxes, tagged by host UID/GID |
| `SANDBOX_IMAGE_NAME` | `pis:latest` | image reference | Default Pi sandbox container image |
| `CODEX_SANDBOX_IMAGE_NAME` | `cods:latest` | image reference | Default Codex sandbox container image |
| `SANDBOX_NETWORK` | `sandbox-net` | network name | Isolated network for sandbox containers (used by Ralph sandbox mode, not by `pis`) |
| `SANDBOX_RECOMMENDED_MEMORY` | `8g` | memory allocation | Recommended memory allocation for sandbox containers |
| `SANDBOX_RECOMMENDED_CPU` | `4` | CPU allocation | Recommended CPU core allocation for sandbox containers |
| `SANDBOX_RECOMMENDED_PIDS` | `512` | PID allocation | Recommended process count cap for sandbox containers |
| `SUBAGENT_MAX_RUNNING_JOBS` | `8` | count | Maximum concurrent async subagent jobs (internal constant, not user-configurable) |
| `SUBAGENT_MAX_PARALLEL_TASKS` | `20` | count | Maximum tasks in a single parallel `subagent_run` call (internal constant, not user-configurable) |
| `SUBAGENT_WAIT_TIMEOUT_DEFAULT` | `300` | seconds | Default timeout for `subagent_wait` (internal constant, not user-configurable) |
| `SUBAGENT_WIDGET_DEBOUNCE_MS` | `1000` | milliseconds | Minimum interval between TUI widget re-renders for live job progress (internal constant, not user-configurable) |
| `SUBAGENT_WIDGET_DISMISS_DELAY_MS` | `5000` | milliseconds | Delay after last job finishes before the status widget is removed (internal constant, not user-configurable) |
| `SUBAGENT_SUMMARY_MIN_LENGTH` | `50` | characters | Minimum character length for a text block to be considered substantive in summary extraction; shorter blocks are skipped when scanning backward (internal constant, not user-configurable) |
| `CODEX_CONFIG_TEMPLATE_MODE` | `preserve` | enum: `preserve` \| `overwrite` | Whether the install script overwrites existing Codex config with template; `preserve` keeps local runtime values |
| `BACKUP_TIMESTAMP_FMT` | `%Y%m%d_%H%M%S` | strftime format | Timestamp format appended to backup filenames during symlink deployment (e.g., `settings.json.backup.20260501_120000`) |
| `RALPH_DEFAULT_ITERATIONS` | `25` | count | Default max loop iterations for Ralph agentic loop |
| `RALPH_DONE_PATTERN` | `/done` | string | Pattern that signals loop completion in Ralph worker output |
| `PI_PROFILE_SOURCE_ROOT` | `~/dotfiles/pi/profiles/` | path | Source root for Pi profile definitions, overrides, and generated output |

---

## Data Structures

### Agent Descriptor

Describes a supported agent and its deployment mapping.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `name` | enum | Required; one of: `codex`, `claude`, `pi`, `gemini`, `copilot` | Agent identifier |
| `installMethod` | enum | Required; one of: `npm`, `curl`, `docker` | How the agent binary is installed |
| `installTarget` | string | Required | Binary name or package for installation |
| `configDir` | string | Required; absolute path | Agent's runtime config directory (where symlinks are created) |
| `symlinkMap` | map | Required | Mapping of target paths to dotfiles source paths |
| `skillsTarget` | string | Required | Target path in config dir that receives the agent's skills symlink |
| `sensitivePatterns` | list | Required | Glob patterns that MUST NOT be committed to version control |
| `authCommand` | string | Required | Command the human runs to authenticate |

### Pi Profile

Describes one Pi profile's source inputs, generated output, and deployed runtime locations.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `name` | string | Required; kebab-case | Profile identifier used by `pim`, `pi-<name>`, and `pis-<name>` |
| `sourceRoot` | string | Required; repo-relative path | Profile directory under `pi/profiles/<name>/` |
| `outputRoot` | string | Required; repo-relative path | Committed **deployable profile output** directory |
| `runtimeDir` | string | Required; absolute path | Deployed runtime directory under `~/.pi/profiles/<name>/agent/` |
| `includesSharedSkills` | boolean | Must be `true` | Shared skills are always included in every profile |
| `localSkillsDir` | string | Optional | Directory of profile-local skills layered on top of shared skills |
| `enabledExtensions` | list of strings | Required | Extension names included in the resolved runtime directory |
| `isDefault` | boolean | Optional | Whether install selects this profile as the initial active profile |

### Symlink Mapping

Each agent defines a set of paths in its config directory that are symlinked to the dotfiles repository.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `targetPath` | string | Required; absolute path | The path on disk where the symlink is created |
| `sourcePath` | string | Required; relative path under `~/dotfiles/` | The file or directory in the repo the symlink points to |
| `deployMode` | enum | `symlink` or `copy` | `symlink` for most files; `copy` for files the agent writes to at runtime (e.g., Codex `config.toml`) |

### Agent Symlink Maps

#### Codex CLI

| Target Path | Source Path | Deploy Mode |
|-------------|-------------|-------------|
| `~/.codex/agents/` | `~/dotfiles/codex/agents/` | symlink |
| `~/.codex/AGENTS.md` | `~/dotfiles/codex/AGENTS.md` | symlink |
| `~/.agents/skills/` | `~/dotfiles/shared/skills/` | symlink |
| `~/.codex/config.toml` | `~/dotfiles/codex/config.toml` | copy (first run only; preserve local on updates) |

#### Claude Code

| Target Path | Source Path | Deploy Mode |
|-------------|-------------|-------------|
| `~/.claude/commands/` | `~/dotfiles/claude/commands/` | symlink |
| `~/.claude/agents/` | `~/dotfiles/claude/agents/` | symlink |
| `~/.claude/skills/` | `~/dotfiles/shared/skills/` | symlink |
| `~/.claude/settings.json` | `~/dotfiles/claude/settings.json` | symlink |
| `~/.claude/statusline.sh` | `~/dotfiles/claude/statusline.sh` | symlink |

#### Pi Coding Agent

Pi deploys one runtime directory per profile plus an active compatibility path.

| Target Path | Source Path | Deploy Mode |
|-------------|-------------|-------------|
| `~/.pi/profiles/{profile}/agent/skills/` | `~/dotfiles/pi/profiles/{profile}/resolved/skills/` | symlink |
| `~/.pi/profiles/{profile}/agent/settings.json` | `~/dotfiles/pi/profiles/{profile}/resolved/settings.json` | symlink |
| `~/.pi/profiles/{profile}/agent/models.json` | `~/dotfiles/pi/profiles/{profile}/resolved/models.json` | symlink |
| `~/.pi/profiles/{profile}/agent/agents/` | `~/dotfiles/pi/profiles/{profile}/resolved/agents/` | symlink |
| `~/.pi/profiles/{profile}/agent/extensions/{extension}/` | `~/dotfiles/pi/profiles/{profile}/resolved/extensions/{extension}/` | symlink |
| `~/.pi/agent` | `~/.pi/profiles/{active-profile}/agent` | symlink |
| `~/.pi/active-profile` | `{profile-name}` | copy |

#### Gemini CLI

| Target Path | Source Path | Deploy Mode |
|-------------|-------------|-------------|
| `~/.gemini/settings.json` | `~/dotfiles/gemini/settings.json` | symlink |
| `~/.gemini/commands/` | `~/dotfiles/gemini/commands/` | symlink |
| `~/.gemini/agents/` | `~/dotfiles/gemini/agents/` | symlink |
| `~/.gemini/skills/` | `~/dotfiles/shared/skills/` | symlink |

#### GitHub Copilot CLI

| Target Path | Source Path | Deploy Mode |
|-------------|-------------|-------------|
| `~/.config/copilot/commands/` | `~/dotfiles/copilot/commands/` | symlink |
| `~/.config/copilot/agents/` | `~/dotfiles/copilot/agents/` | symlink |
| `~/.config/copilot/skills/` | `~/dotfiles/shared/skills/` | symlink |

### Sensitive Data Exclusion Patterns

Each agent's version-control exclusions MUST prevent sensitive or runtime-generated data from entering the repository. The categories of excluded data are:

1. **Credentials and auth tokens** — authentication files, OAuth tokens, API keys
2. **Session and history data** — conversation logs, session state, shell snapshots
3. **Local runtime state** — temporary files, caches, version metadata, personality migrations
4. **Project-specific data** — per-project settings, local overrides

Each agent's `.gitignore` MUST cover these categories. The specific filenames are implementation-dependent and may change across agent versions, but the categories above MUST always be excluded.

| Agent | Excluded Categories |
|-------|-------------------|
| Codex CLI | Credentials, session/history data, local runtime state, local config overrides |
| Claude Code | Credentials, session/history data, project-specific data, local runtime state, debug artifacts |
| Pi | Credentials, session/history data, local runtime binaries and tools |
| Gemini CLI | Credentials/auth tokens, session/history data, server enablement state, temporary files |
| Copilot CLI | (No agent-specific gitignore; uses XDG config dir for local-only data) |

### Skill Definition

A **skill** is a reusable instruction set. Cross-agent skills live in `shared/skills/`. Every Pi profile MUST include those shared skills in its resolved `skills/` directory. Pi profile-specific skills MAY be added from profile-local source directories.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `name` | string | Required; kebab-case | Skill identifier, matches directory name |
| `description` | string | Required | Human-readable purpose of the skill |
| `metadata.short-description` | string | Optional | Brief description for agents that support it (Codex, Pi) |
| `allowed-tools` | list of strings | Optional | Tool allowlist for agents that support it (Claude Code) |

### Pi Skills Composition

Each Pi profile's resolved runtime skills directory MUST be generated from:

1. All skills in `~/dotfiles/shared/skills/`
2. Zero or more profile-local skills from `~/dotfiles/pi/profiles/{profile}/skills/`

Rules:

1. Shared skills are always included; profiles MUST NOT opt out of them.
2. Duplicate skill directory names between `shared/skills/` and a profile-local skills directory are a build error.
3. Generated profile output MUST materialize a complete resolved `skills/` directory under `pi/profiles/{profile}/resolved/skills/`.
4. Pi-only orchestration skills MAY live in profile-local skills directories rather than a single Pi-wide `pi/skills/` directory.

The skill directory MUST contain a `SKILL.md` file with YAML frontmatter containing the fields above. A skill MAY include additional files (`REFERENCE.md`, `EXAMPLES.md`, helper scripts) in the same directory.

### Pi Extension

A Pi **extension** is a module loaded by the Pi coding agent at startup, written in TypeScript. Each extension registers tools and optionally subscribes to Pi lifecycle events (session start, session shutdown, model selection) to modify agent behavior. Extension directories are selected per profile during profile build and deployed into that profile's runtime `extensions/` directory.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `name` | string | Required; matches directory name under `pi/extensions/` | Extension identifier |
| `tools` | list | Required | Registered tool names and their schemas |
| `lifecycleHooks` | list | Optional | Pi lifecycle events the extension subscribes to (session lifecycle and model selection events) |

### Pi Sub-Agent Role

A Pi **sub-agent role** is a named agent definition stored as a Markdown file in a profile's resolved `agents/` directory with YAML frontmatter. Each role pre-configures a model, provider, thinking level, allowed tools, and guardrail thresholds. The subagent extension reads these definitions at session start and injects them into the system prompt as an agent catalog, making them available for delegation via `subagent_run` or `subagent_fork`.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `name` | string | Required; matches filename | Role identifier used in `agent` parameter of subagent tools |
| `description` | string | Required | Purpose of this sub-agent role |
| `model` | string | Required | Model ID matching an entry in `models.json` |
| `provider` | string | Required | Provider ID matching an entry in `models.json` |
| `thinking` | enum | Required; one of: `off`, `minimal`, `low`, `medium`, `high`, `xhigh` | Thinking level for this role |
| `tools` | string | Optional; comma-separated | Tool allowlist; defaults to all tools if omitted |
| `maxTurns` | number | Optional | Maximum LLM turns before auto-kill |
| `maxCost` | number | Optional | Maximum USD cost before auto-kill |
| `maxTokens` | number | Optional | Maximum total tokens (input+output) before auto-kill |
| `maxTime` | number | Optional | Maximum wall-clock seconds before auto-kill |

### Pi Subagent Job

An async background subagent job managed by the Pi subagent extension.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | string | Format: `{name}-{6hex}` | Unique job identifier |
| `name` | string | Required | Display label for the job |
| `task` | string | Required | Task text delegated to the subagent |
| `status` | enum | `running`, `completed`, `failed`, `cancelled` | Current job state |
| `startedAt` | timestamp | Set on creation | When the job was created |
| `completedAt` | timestamp | Set on completion | When the job finished |
| `result` | SingleResult | Updated on every `message_end` event while running; finalized on completion | Partial or full output including messages, usage, exit code |
| `provider` | string | Optional | Provider override for the subagent |
| `model` | string | Optional | Model override for the subagent |
| `thinking` | enum | `off`, `minimal`, `low`, `medium`, `high`, `xhigh` | Thinking level override |
| `tools` | list of strings | Optional | Resolved tool allowlist for the subagent. `undefined` means all default tools. Displayed as a comma-separated bracket (e.g. `[read,grep]`) when defined; omitted from display when `undefined` |

### Subagent Live Progress

The live progress system provides real-time visibility into running forked subagent jobs through three surfaces: a TUI status widget, enhanced `subagent_status` output, and `subagent_wait` streaming updates.

#### Status Widget

A TUI widget displayed above the editor while any forked job is running. The widget provides always-on visibility without requiring the LLM to query status.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| Widget ID | string | Fixed: `subagent-jobs` | Identifier for `ctx.ui.setWidget()` |
| Placement | enum | `aboveEditor` | Widget position (above the input editor) |
| Interactivity | boolean | Always `false` | Display-only; no keyboard input. Cancelling goes through `subagent_cancel` |
| Dismiss delay | number | `SUBAGENT_WIDGET_DISMISS_DELAY_MS` (5000ms) | Widget remains visible for this duration after last job finishes |

**Widget format (running job — two lines):**

```
⏳ {name} [{tools}] ({elapsed}) {usage} {turns} turns
  "{last text snippet}"  → {last tool call}
```

The `[{tools}]` bracket is shown only when `tools` is defined (custom tool allowlist). When `tools` is `undefined` (all default tools), the bracket is omitted entirely. The bracket content is truncated at the first newline boundary and then clipped to 30 characters; if truncation is needed, the format is `[tool1,tool2,... +N]` where `N` is the count of remaining tools.

**Widget format (completed/failed job — one line):**

```
✓ {name} [{tools}] ({elapsed}) {usage} "{truncated result}"
```

The `[{tools}]` bracket follows the same display rules as the running format: shown only when `tools` is defined, truncated at 30 characters with `+N` overflow.

**Widget header line (always shown):**

```
⏳ {done}/{total} jobs — {completed} done, {failed} failed, {running} running ({total elapsed})
```

**Text truncation rules:**

1. Truncate at the first newline boundary.
2. Then clip to fit remaining terminal width after the status prefix.

**Update cadence:** Debounced to `SUBAGENT_WIDGET_DEBOUNCE_MS` (1000ms) minimum between re-renders. State transitions (completion, failure, cancellation) trigger immediate re-render regardless of debounce.

#### Summary Extraction

When selecting the text snippet for a completion notification, widget, or status output, the extension MUST scan backward through assistant display items and select the first text block with length ≥ `SUBAGENT_SUMMARY_MIN_LENGTH` (50 chars). If no text block meets the threshold (e.g., a tool-call-only subagent), the extension MUST fall back to the last text block regardless of length.

### Subagent Model Routing

A prescriptive mapping from subagent intent categories to model, provider, and thinking level. The routing table is stored in Pi's `settings.json` as the `subagentModelRouting` key and injected into the `subagent_run` and `subagent_fork` tool descriptions by the subagent extension as a markdown table. Categories `scout`, `planner`, `reviewer`, and `implementer` each map to a single model/provider/thinking combination; the `expert` category has an ordered fallback chain of three rows (`expert (1st)`, `expert (2nd)`, `expert (3rd)`), each consulted sequentially for the same file-scoped issue as prior consultations fail to resolve it.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `subagentModelRouting` | map | Required in Pi settings; key is routing category name | Top-level key in Pi settings containing the routing table |
| category key | string | Required; one of: `scout`, `planner`, `reviewer`, `implementer`, `expert (1st)`, `expert (2nd)`, `expert (3rd)` | Intent category that classifies the subagent's task; `expert` rows form an ordered fallback chain consulted sequentially for the same issue |
| `description` | string | Required | Brief description of what counts as this category; helps the LLM classify tasks correctly |
| `model` | string | Required | Model ID matching an entry in `models.json` |
| `provider` | string | Required | Provider ID matching an entry in `models.json` |
| `thinking` | enum | Required; one of: `off`, `minimal`, `low`, `medium`, `high`, `xhigh` | Thinking level for this category |
| `rationale` | string | Required | One-line explanation of why this model/thinking pair was chosen for this category |

### Shared Skills Directory

The single canonical directory for cross-agent skills is `~/dotfiles/shared/skills/`. Non-Pi agent skill configuration paths MUST point here via symlinks. Pi profile builds MUST include this directory's contents in every resolved profile `skills/` directory.

---

## Behavior

### B1: Agent Installation

Each agent MUST be installed via its designated method:

| Agent | Install Method | Command |
|-------|---------------|---------|
| Codex CLI | npm | `npm install -g --prefix ~/.local @openai/codex@latest` |
| Claude Code | curl | `curl -fsSL https://claude.ai/install.sh \| bash` |
| Pi | npm | `npm install -g --prefix ~/.local @earendil-works/pi-coding-agent@latest` |
| Gemini CLI | npm | `npm install -g --prefix ~/.local @google/gemini-cli@latest` |
| Copilot CLI | curl | `curl -fsSL https://gh.io/copilot-install \| bash` |

**Rules:**

1. npm-installed agents MUST use `NPM_GLOBAL_PREFIX` (`~/.local`) as the install prefix so the binary lands in `~/.local/bin/`, outside fnm's managed directory tree, surviving Node version switches.
2. After installation, the system MUST verify the binary exists at the expected path.
3. If another binary with the same name is earlier in PATH, a warning MUST be displayed.
4. Each agent MUST prompt the user to authenticate on first run (see B6).

### B2: Symlink Deployment

For each agent, the install process deploys symlinks from the agent's config directory to the dotfiles repository.

**Deployment rules:**

1. If the target path already exists and IS a symlink, the existing symlink MUST be removed and replaced.
2. If the target path already exists and is NOT a symlink (regular file or directory), it MUST be backed up with a timestamp suffix (format: `BACKUP_TIMESTAMP_FMT`, default `%Y%m%d_%H%M%S`) before creating the new symlink.
3. If the target path does not exist, the symlink MUST be created directly.
4. Symlink creation MUST NOT fail if the source does not exist — the symlink is still created (dangling symlinks are acceptable for optional files).
5. Non-Pi agents MUST symlink their skills target paths to `shared/skills/`.
6. Pi MUST symlink each deployed profile runtime's skills target path to that profile's resolved `skills/` directory, and `~/.pi/agent/skills` MUST resolve through the active profile runtime.

**Copy deployment (Codex config.toml only):**

1. On first install, the template MUST be copied to `~/.codex/config.toml`.
2. If an existing symlink is found, it MUST be converted to a local file copy (removed, then copied from template).
3. On subsequent installs, by default the existing local file MUST be preserved (`CODEX_CONFIG_TEMPLATE_MODE=preserve`).
4. If `CODEX_CONFIG_TEMPLATE_MODE=overwrite` is set, the existing file MUST be backed up and replaced with the template.

### B3: Skills Distribution

The skills distribution system MUST satisfy:

1. There is exactly ONE physical directory containing cross-agent skills: `~/dotfiles/shared/skills/`.
2. Non-Pi agents' skills configuration paths are symlinks pointing to `~/dotfiles/shared/skills/`.
3. Each Pi profile's skills configuration path is a symlink pointing to `~/dotfiles/pi/profiles/{profile}/resolved/skills/`.
4. Every Pi profile's resolved `skills/` directory contains all cross-agent skills from `~/dotfiles/shared/skills/` plus any profile-local skills with unique names.
5. When a cross-agent skill is installed or updated in `~/dotfiles/shared/skills/`, it is visible to non-Pi agents immediately and to Pi after the affected profiles are rebuilt.
6. A skill MUST have a `SKILL.md` with frontmatter containing at minimum `name` and `description`.
7. Skills MAY include cross-agent frontmatter fields: `metadata.short-description` (for Codex and Pi) and `allowed-tools` (for Claude Code).

### B4: Agent-Specific Configuration

#### B4.1: Codex CLI Configuration

1. The `config.toml` template MUST declare `multi_agent = true` and `apps = true` under `[features]`.
2. Agent role definitions in `[agents.*]` sections MUST specify a `description` and a `config_file` pointing to a TOML file under `agents/`.
3. Each agent role TOML file MUST define `name`, `description`, `model_reasoning_effort`, and `developer_instructions`.
4. The global `AGENTS.md` symlinked to `~/.codex/AGENTS.md` provides cross-project default instructions.

#### B4.2: Claude Code Configuration

1. `settings.json` MUST set `DISABLE_AUTOUPDATER` to `"1"`, enable `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`, and configure the statusline command.
2. Agent definitions MUST be Markdown files under `agents/` with YAML frontmatter containing `name`, `tools`, and `model`.
3. Custom commands MUST be Markdown files under `commands/` and are invoked as `/command-name` within Claude Code.
4. On deployment, the install script MUST remove any legacy Playwright MCP server entry from Claude Code's MCP configuration.

#### B4.3: Pi Configuration

1. `settings.json` MUST set `enableSkillCommands` to `true` and define `defaultProvider`, `defaultModel`, `defaultThinkingLevel`, and `subagentModelRouting`.
2. `models.json` MUST define providers with `baseUrl`, `api`, `apiKey` (env var reference), and model arrays specifying `id`, `name`, `contextWindow`, `maxTokens`, and optional flags `reasoning`, `input`, and `api` (for per-model API overrides). Model entries MUST include a `contextWindow` field defining the model's maximum token capacity.
3. Each Pi profile MUST resolve its own `settings.json`, `models.json`, `agents/`, `skills/`, and enabled `extensions/` into committed output under `pi/profiles/{profile}/resolved/`.
4. Sub-agent role definitions are stored in each profile's resolved `agents/` directory and deployed to `~/.pi/profiles/{profile}/agent/agents/`. Each role file MUST include YAML frontmatter with `name`, `description`, `model`, `provider`, and `thinking`; MAY include `tools`, `maxTurns`, `maxCost`, `maxTokens`, `maxTime`.
5. Extensions are loaded from the active profile runtime's `~/.pi/agent/extensions/`, where each enabled extension directory is a symlink to that profile's resolved output.
6. The active profile compatibility path `~/.pi/agent` MUST be a symlink to one deployed profile runtime directory under `~/.pi/profiles/`.
7. The `pim` command MUST manage Pi profiles with at least `list`, `current`, `use <profile>`, `path <profile>`, `doctor`, `create <profile>`, and `build [profile]`.
8. `pim create <profile>` MUST scaffold authoring inputs and generate committed resolved output immediately.
9. Bare `pi` and `pis` MUST target the active profile. Explicit wrappers `pi-<profile>` and `pis-<profile>` MUST target their named profile directly without changing the active profile.
10. `pim use <profile>` MUST switch the active profile by updating the runtime pointer and active-profile file atomically. It MUST NOT rewrite wrapper scripts.

#### B4.4: Gemini CLI Configuration

1. `settings.json` MUST set `ide.enabled` to `true`, `security.auth.selectedType` to `"oauth-personal"`, and `general.disableAutoUpdate` to `false`.
2. Custom commands MUST be TOML files under `commands/` containing a `prompt` field.
3. Agent definitions MUST be Markdown files under `agents/`.

#### B4.5: Copilot CLI Configuration

1. The agent config directory (`~/.config/copilot/`) receives symlinks for `commands/`, `agents/`, and `skills/`.
2. No settings file is currently managed — Copilot CLI uses its own auth flow.

### B5: Pi Extensions

#### B5.1: Subagent Extension

The subagent extension registers six tools and one command:

| Tool | Behavior | Blocking |
|------|----------|----------|
| `subagent_run` | Run subagent(s) synchronously in single, parallel, or chain mode | Yes |
| `subagent_fork` | Start background job(s); returns immediately with job IDs | No |
| `subagent_status` | List all jobs or show specific job status | No (query) |
| `subagent_results` | Get full output of a completed job | No (query) |
| `subagent_wait` | Block until a specific job completes | Yes |
| `subagent_cancel` | Cancel one or all running jobs | No |

| Command | Behavior |
|---------|----------|
| `/reload-agents` | Hot-reload agent catalog from the active profile runtime `~/.pi/agent/agents/` without restarting Pi; used after adding or modifying agent role files. Does NOT update tool parameter descriptions — user must run `/reload` separately. |

**Rules:**

1. `subagent_run` requires exactly one of: `task` (single), `tasks[]` (parallel), or `chain[]` (sequential).
2. Chain mode replaces `{previous}` placeholders in each step's task with the output of the preceding step.
3. Parallel execution within `subagent_run` MUST respect `MAX_PARALLEL_TASKS` (20) and `MAX_CONCURRENCY` limits.
4. `subagent_fork` MUST NOT exceed `MAX_RUNNING_JOBS` (8) concurrent jobs. If the cap is reached, an error MUST be returned.
5. Job IDs MUST follow the format `{name}-{6hex}`.
6. On `session_shutdown`, all running jobs MUST be cancelled.
7. Job state MUST be persisted so that jobs survive across session switches.
8. On `session_start`, persisted job state MUST be restored from session entries.
9. Completion notifications MUST be delivered as steering messages that trigger a new turn.
10. Cancellation notifications MUST be delivered as steering messages that trigger a new turn, using the same delivery mode as completion notifications (`deliverAs: "steer"`, `triggerTurn: true`).
11. The `AsyncJob.result` field MUST be updated on every `message_end` and `tool_result_end` event from the subagent process, enabling live progress visibility for running jobs.
12. A TUI status widget (`subagent-jobs`) MUST be displayed above the editor while any forked job is running. The widget MUST show a header line, two-line progress for each running job (last text snippet + last tool call from completed messages only), and one-line summary for each completed/failed job. The widget MUST be removed `SUBAGENT_WIDGET_DISMISS_DELAY_MS` after the last running job finishes.
13. Widget re-renders MUST be debounced to `SUBAGENT_WIDGET_DEBOUNCE_MS`, except for state transitions (completion, failure, cancellation) which MUST trigger immediate re-render.
14. `subagent_status` for a running job MUST include a "Progress" section showing turns so far, usage so far, last text snippet, and last tool call (from completed messages only).
15. `subagent_wait` MUST use `onUpdate` to stream progress during the wait, using the same two-line format as the widget (last text snippet + last tool call). The update MUST be refreshed on each `message_end` event.
16. Summary extraction for notifications and displays MUST scan backward through assistant display items and select the first text block with length ≥ `SUBAGENT_SUMMARY_MIN_LENGTH` (50 chars). If no text block meets the threshold, the last text block MUST be used as fallback.
17. Text truncation in the widget and notifications MUST truncate at the first newline boundary, then clip to fit the remaining terminal width after the status prefix.
18. Notification content for cancelled jobs MUST include partial usage stats (tokens consumed before cancellation) and a partial trace showing the last completed assistant text and last completed tool call at the time of cancellation. Only completed messages MUST be shown — partial/mid-stream data MUST NOT appear.
19. The `subagent_fork` `promptGuidelines` MUST mention that a status widget is shown while jobs are running.
20. The status widget MUST be display-only with no keyboard input. Cancelling jobs goes through `subagent_cancel`.

**Agent catalog injection rules:**

21. On `before_agent_start`, the extension MUST build a markdown catalog of all agent role files in the active profile runtime `~/.pi/agent/agents/`. The catalog MUST list each agent's name, description, model, provider, thinking level, tools, and guardrail thresholds (maxTurns, maxCost, maxTokens, maxTime).
22. The catalog MUST be injected into the agent's system prompt exactly once per session. Subsequent agent starts within the same session MUST NOT re-inject the catalog.
23. The `agent` parameter description for `subagent_run` and `subagent_fork` MUST be dynamically generated from the agent catalog, listing available agent names and their descriptions. If no agent files exist, the description MUST fall back to a static message.
24. The `/reload-agents` command MUST reset the injection flag, allowing the catalog to be re-injected on the next agent start. It MUST log the count of discovered agents.

**Tools display rules:**

25. The resolved tool allowlist (`SubagentConfig.tools`) MUST be stored on both `AsyncJob` and `SingleResult` as a `tools?: string[]` field. When `tools` is `undefined`, it means all default tools are available — this MUST NOT be displayed. When `tools` is a non-empty array, it MUST be displayed as a comma-separated bracket `[tool1,tool2,...]`.

26. The bracket convention MUST use square brackets `[...]` for tool scope and parentheses `(...)` for model/provider/thinking config. These two visual delimiters distinguish config metadata: parentheses for model identity, brackets for capability scope.

27. Tool brackets MUST be truncated at 30 characters. When truncation is needed, the format MUST be `[tool1,tool2,... +N]` where `N` is the count of remaining tools that don't fit. Example: `[read,write,bash,edit,grep,find,ls]` (39 chars) becomes `[read,write,bash,edit,grep,find +1]` (29 chars).

28. The `tools` field MUST appear on the following display surfaces when `tools` is defined (and MUST be omitted when `tools` is `undefined`):
    a. **Widget**: After the job name on line 1 of both running and completed/failed job lines. NOT on line 2 (snippet + tool call line). NOT in the header line.
    b. **`subagent_status` single job**: As a `**Tools:**` line after `**Task:**`, comma-separated with spaces for readability (e.g. `**Tools:** read, grep`).
    c. **`subagent_results`**: As a `**Tools:**` line after `**Task:**`, same format as status.
    d. **`subagent_wait` progress**: After the job name on the progress line, same bracket format as the widget.
    e. **`renderCall()`**: After model/provider/thinking parentheses, before task preview. Format: `(model/thinking) [tool1,tool2]`.
    f. **`renderSingleResult()`**: On the identity line in both expanded and collapsed views. Format: `(provider/model) [tool1,tool2]`.
    g. **`renderJobStatusLine()`**: After the job name. Format: `✓ name [tool1,tool2] (elapsed) task...`.
    h. **`subagent_run` text output**: In per-task headings for parallel and chain results. Format: `## name [tool1,tool2] (completed)`.
    i. **`subagent_fork` response text**: In per-job lines. Format: `**name** [tool1,tool2] — task (running)`.

29. The `tools` field MUST NOT appear on the following surfaces:
    a. Completion notifications (steer messages)
    b. Cancellation notifications
    c. Widget line 2 (snippet + tool call)
    d. Widget header line (summary counts)

30. The `tools` field on `AsyncJob` MUST be persisted in `SerializedJob` for session persistence. On deserialization, a missing `tools` field (from older data) MUST be treated as `undefined` (all default tools), consistent with the display rule that `undefined` = omitted from display.

31. The `tools` field on `SingleResult` MUST be set in `spawnSubagentProcess()` alongside `provider`, `model`, and `thinking`, from the resolved `SubagentConfig`. The `tools` field on `AsyncJob` MUST be set after job creation via `job.tools = config.tools`, before spawning the process.

**Model routing rules:**

10. When `subagentModelRouting` is present in Pi's `settings.json`, the extension MUST read it and inject a markdown table into the tool descriptions of `subagent_run` and `subagent_fork`. The table MUST include columns for category, description, model, provider, thinking, and rationale, INCLUDING the three expert rows (`expert (1st)`, `expert (2nd)`, `expert (3rd)`).
11. The LLM MUST select a routing category from the table and use the prescribed `model`, `provider`, and `thinking` values in the subagent call. Valid categories are: `scout`, `planner`, `reviewer`, `implementer`, `expert (1st)`, `expert (2nd)`, `expert (3rd)`. For expert consultations, the LLM MUST select the row matching the consultation number (1st, 2nd, or 3rd) based on how many consultations have already been done on the same file-scoped issue. Deviation from the routing table requires explicit justification in the call.
12. When `subagentModelRouting` is absent from `settings.json`, the extension MUST log a warning and fall back to the parent agent's default model and thinking level for all subagent calls.
13. The routing table MUST NOT include fallback chains — each category maps to exactly one model/provider/thinking combination. When models change, the table MUST be updated manually in `settings.json`.

**Subagent configuration (ad-hoc):**

Each tool invocation configures the subagent inline. Configuration includes a display name, the task text, optional system prompt, optional tool/model/provider/thinking-level overrides, working directory, and flags controlling whether project context files and Pi extensions are loaded. Top-level parameters serve as defaults; per-item parameters take precedence.

#### B5.2: Inherit-Last-Model Extension

1. On every `model_select` event, the current model's provider and modelId MUST be written to `~/.pi/agent/last-model.json`.
2. On `session_before_switch` with reason `"new"`, the current model MUST be persisted as a safety net.
3. On `session_start` with reason `"new"`, the extension MUST attempt to restore the last-used model by reading the persisted state, looking up the model in the registry, and switching to it.
4. If the temp file is missing, corrupt, the model was removed from `models.json`, or auth is unavailable, the extension MUST skip silently without error — allowing Pi's defaults to take over.

#### B5.3: Web Search Extension

1. Registers two tools: `web_search` and `web_fetch`, backed by the Ollama Cloud API.
2. Requires `OLLAMA_API_KEY` environment variable. If missing, the tool MUST return an error.
3. Search results and fetched content MUST be truncated to `MAX_CONTENT_CHARS` (30,000) and `MAX_SNIPPET_CHARS` (500) respectively to stay context-safe.
4. Errors from the API MUST be returned as tool errors, not thrown as exceptions.

### B6: Agent Authentication

| Agent | Auth Command | Method |
|-------|-------------|--------|
| Codex CLI | `codex login` | Interactive OAuth or API key |
| Claude Code | `claude auth login` | Interactive OAuth |
| Pi | First run prompts | Provider-specific (API key, env var, or OAuth) |
| Gemini CLI | `gemini` (first run) | Google account OAuth or API key |
| Copilot CLI | `copilot login` | GitHub OAuth (requires active subscription) |

**Rules:**

1. The install script MUST NOT store or prompt for credentials during installation.
2. Authentication MUST be performed by the user outside the install flow.
3. The install script MAY print a reminder to authenticate after completing agent setup.

### B7: Pi Sandbox Mode

The `pis` script provides a Docker sandbox wrapper for the Pi coding agent.

**Rules:**

1. The Pi sandbox image MUST build from the shared sandbox base image (`dotfiles-dev-base:{UID}-{GID}`), ensuring that base image through a cached Docker build before rebuilding the Pi image.
1. The current working directory MUST be mounted read-write at its original path inside the container.
2. The active Pi agent runtime (settings, models, skills, extensions, agents) plus shared auth and profile-local sessions/history MUST be mounted into the container under the container user's home directory (`/home/{HOST_USER}/`, not `/root/`).
3. The container MUST run as the host user (`--user UID:GID`) so that files written to mounted volumes are owned by the host user, not root.
4. The `HOME` environment variable inside the container MUST be set to `/home/{HOST_USER}/` so that tools (git, ssh, pi) resolve the correct home directory.
5. The Dockerfile MUST create a user matching the host username, UID, and GID at build time via `HOST_USER`, `HOST_UID`, and `HOST_GID` build arguments, ensuring `/etc/passwd` has a proper entry for git and other tools that require a username.
6. API key environment variables MUST be forwarded to the container: the well-known keys (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GOOGLE_API_KEY`, `GEMINI_API_KEY`) if set, plus any environment variables matching the patterns `*_API_KEY`, `*_API_TOKEN`, or `*_APIKEY`.
7. Extra directories specified as positional arguments MUST be mounted read-only by default; the read-write flag switches to read-write.
8. The script MUST auto-rebuild the Docker image if the installed Pi version in the image label doesn't match the latest npm version.
9. `--no-rebuild` skips the version check; `--build` forces a build.
10. Container MUST run as ephemeral (removed on exit). Recommended resource allocation is 8g memory, 4 CPUs, and 512 PIDs, but these limits are NOT enforced by the `pis` command — they are applied only when running under the Ralph sandbox mode.

### B8: Codex Sandbox Mode

The `cods` script provides a Docker sandbox wrapper for running Codex with `--yolo`.

**Rules:**

1. The Codex sandbox image MUST build from the shared sandbox base image (`dotfiles-dev-base:{UID}-{GID}`), ensuring that base image through a cached Docker build before rebuilding the Codex image.
1. The current working directory MUST be mounted read-write at its original path inside the container.
2. `~/.codex` MUST be mounted read-write under the container user's home directory.
3. If `~/.codex/auth.json` exists, it MUST be overlaid as a read-only bind mount.
4. The container MUST run as the host user (`--user UID:GID`) and the Dockerfile MUST create a matching user with `HOST_USER`, `HOST_UID`, and `HOST_GID`.
5. The `HOME` environment variable inside the container MUST be set to `/home/{HOST_USER}/`.
6. The script MUST invoke `codex --yolo` by default.
7. API-key-shaped environment variables MUST be forwarded by default; forwarded names MAY be displayed, but values MUST NOT be printed.
8. Extra paths MUST only be mounted through explicit `--mount-ro PATH` or `--mount-rw PATH` flags. High-risk paths such as `/`, `$HOME`, `~/.ssh`, and the Docker socket MUST be rejected unless explicitly overridden.
9. Host SSH credentials, SSH agent sockets, and global Git credentials MUST NOT be mounted by default.
10. The script MUST auto-rebuild the Docker image if the installed Codex version in the image label doesn't match the latest npm version. `--no-rebuild` skips the version check; `--build` forces a build.
11. Container resource limits MUST be applied by default: 8g memory, 4 CPUs, and 512 PIDs, configurable through environment variables.
12. `--dry-run` MUST print the generated Docker command without requiring Docker or building the image.
13. Strict network egress allowlisting is out of scope for v1; the standalone `cods` command uses normal Docker networking.

### B9: Ralph Agentic Loop

Ralph has two implementations:

- **Codex-based skill** (`shared/skills/ralph/SKILL.md`) — a shared skill definition using Codex CLI as the worker. This is the cross-agent version available to all agents via the shared skills directory.
- **Claude Code command** (`claude/commands/ralph.md`) — a richer implementation using Claude Code as the worker with sandbox (Docker) support, an orchestrator pattern, and resource-constrained containers.

Both implementations share the same core loop pattern: an iterative `loop.sh` that reads a prompt file each iteration and terminates on `/done` or iteration limit.

**Rules (shared):**

1. The loop MUST read the prompt file fresh on every iteration.
2. The loop MUST terminate when output contains `/done` or when the iteration limit is reached.

**Rules (Claude Code sandbox mode only):**

3. The worker MUST use `--dangerously-skip-permissions` and `--model opus`.
4. Auth priority for sandbox mode: `ANTHROPIC_API_KEY` > `CLAUDE_CODE_OAUTH_TOKEN` > credentials file extraction.
5. Logs MUST be stored in `.loop-logs/iteration-{N}.log` within the project directory.
6. The orchestrator MUST only use its allowed tool list — it MUST NOT edit files other than `PROMPT.md`.
7. The orchestrator MUST append `CORRECTION:` lines to PROMPT.md's IMPORTANT section to steer the worker.
8. Sandbox containers MUST use a dedicated network (`sandbox-net`) with firewall rules that allow only DNS and specific service endpoints.
9. Sandbox containers SHOULD apply the recommended resource allocation (8g memory, 4 CPUs, 512 PIDs).

### B9: Agent Role Definitions

Six sub-agent roles and two shared agent roles are defined:

#### B9.1: Test Reviewer

1. MUST read the task for slice context to understand which tests are being verified.
2. MUST run the test suite for the tests specified in the RED section of the slice brief.
3. MUST verify each test assertion from the RED section passes.
4. MUST check for vague assertions that would pass even if the implementation is wrong, including:
   - `expect(true).toBe(true)` or literal-equals-literal patterns.
   - `.toBeTruthy()` as the only assertion in a test.
   - `.toBeDefined()` as sole assertion.
   - Empty test bodies.
   - Zero-assertion tests.
5. MUST check the expected test count range from the brief is met.
6. MUST output a structured verdict as formatted text with pass/fail result and details of what was checked, what passed, and what needs fixing.

#### B9.2: Visual QA

1. MUST verify `playwright-cli` is available before starting; MUST NOT proceed if missing.
2. MUST execute a structured checklist against a live web application using `playwright-cli` Bash commands (never MCP tools).
3. MUST follow a three-phase process:
   - **Phase 1**: Open browser via `playwright-cli open`.
   - **Phase 2**: Execute each checklist step in order — navigation (`goto`), actions (`click`, `fill`, `type`, `select`, `check`, `uncheck`, `press`, `hover`, `upload`), and verification (`snapshot`, `eval`, `screenshot`).
   - **Phase 3**: Final checks — full-page screenshot, `playwright-cli console`, `playwright-cli network`, `playwright-cli close`.
4. MUST use assertion guidelines: element visible via snapshot, text match via `eval`, URL changed via `eval`, state change (modal/validation/toast), no regression.
5. MUST classify results per step: ❌ FAIL (assertion failed, action had no effect, console/network error blocks functionality) or ⚠️ NOTE (console warning, slow request — do not fail step).
6. MUST output a structured Visual QA Report with:
   - Slice name and URL under test.
   - Step Results table (Step, Action, Expected, Result, Evidence).
   - Final Checks summary (console errors, console warnings, network failures, full-page screenshot path).
   - Verdict: ✅ PASS or ❌ NEEDS-FIX with per-step failure count and summary.

#### B9.3: Design Reviewer

1. MUST read the task for slice context — what UI was built or changed.
2. MUST find the project's design system reference (DESIGN_SYSTEM.md, Tailwind config, component library docs, design tokens) if one exists; use it as the primary standard.
3. MUST render relevant pages or component states with `playwright-cli`; capture screenshots at 375px, 768px, and 1280px widths; check network/console.
4. MUST evaluate across three dimensions:
   - **Visual consistency**: spacing scale uniform, typography hierarchy respected, color tokens used (not ad-hoc hex), component variants match documented patterns.
   - **Interaction patterns**: loading states rendered, empty states handled, error states surfaced, hover/focus/active states visible, transitions not jarring.
   - **Responsiveness**: layout functional at all three widths, no horizontal overflow, touch targets ≥ 44x44px on mobile, content reflow makes sense per breakpoint.
5. MUST apply general heuristics where no design system rule exists: consistent rhythm, clear visual hierarchy, no orphaned elements, information density appropriate to viewport.
6. MUST return a severity-tagged review card with:
   - 🔴 blocking issues that must be fixed before merge.
   - 🟡 advisory issues that should be fixed.
   - 🟢 praise for well-executed design decisions.
   - Screenshot paths for evidence.
   - Verdict: ✅ PASS or ❌ NEEDS-FIX.

#### B9.4: Premortem Reviewer

1. MUST read the task for slice/ad-hoc context — what code or feature is being reviewed.
2. MUST read the implementation source files modified by this change.
3. MUST evaluate across six failure mode categories:
   - **Operational failure modes**: null pointers, race conditions, timeout cascades, resource exhaustion (memory/connections/disk).
   - **Edge cases**: empty states, boundary values, concurrent access, partial failure in upstream/downstream calls, retry storms, backpressure.
   - **Deployment risks**: order-of-operations (migrations before code?), rollback plan, feature flags, canary safety, data migration reversibility.
   - **Data integrity**: what happens if the process crashes mid-write? Are mutations idempotent? Are transactions scoped correctly?
   - **Observability**: if this fails, can we tell from logs/metrics/traces? Are error paths logged with enough context? Would a page get triggered?
   - **Latency and scale**: could this introduce slowdown? N+1 queries? Unbounded loops or collection growth? What happens at 10× the current load?
4. MUST return a structured verdict with:
   - 🔴 blocking risks with specific file:line references.
   - 🟡 advisory risks with specific file:line references.
   - 🟢 resilience noted — things done well for reliability.
   - Summary paragraph with concise verdict (✅ PASS or ❌ NEEDS-FIX).

### B10: Modular Installation

The install script supports module-based installation:

1. Agent modules: `codex`, `codex_sandbox`, `claude`, `pi`, `pi_sandbox`, `gemini`, `copilot`.
2. Module dependencies MUST be resolved automatically (e.g., `pi` requires `nodejs`, `claude` requires `curl`).
3. The user MAY choose a profile (Full, Minimal, Work, Custom) or specify modules directly.
4. The `--modules` flag accepts a comma-separated list of module names.
5. Installing an agent module MUST install the agent binary, create the config directory, and deploy all symlinks.

### B11: Agent Settings

| Agent | Settings File | Key Settings |
|-------|---------------|--------------|
| Codex | `config.toml` (copy, not symlink) | `multi_agent = true`, `apps = true`, agent role definitions |
| Claude | `settings.json` (symlink) | `DISABLE_AUTOUPDATER`, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`, statusline command |
| Pi | `settings.json` (per-profile symlink) | `enableSkillCommands`, `defaultProvider`, `defaultModel`, `defaultThinkingLevel`, `subagentModelRouting` |
| Pi | `models.json` (per-profile symlink) | Provider definitions with models, context windows, API compatibility flags |
| Gemini | `settings.json` (symlink) | `ide.enabled`, `security.auth.selectedType`, `general.disableAutoUpdate` |
| Copilot | None | Auth via `copilot login` |

---

## Error Handling

| Error ID | Trigger | Detection | Response | Recovery |
|----------|---------|-----------|----------|----------|
| AIAGT-001 | Agent binary not found after install | `command -v` check fails | Display error message with expected path | Verify PATH includes `~/.local/bin`; re-run install |
| AIAGT-002 | Another binary with same name earlier in PATH | Path comparison with expected install location | Display warning with the conflicting binary path | Add `~/.local/bin` to PATH early in shell config |
| AIAGT-003 | npm not available for npm-based agent install | `command -v npm` fails | Install Node.js first, then retry | Run `install_nodejs` sub-function |
| AIAGT-004 | Docker not available for Pi sandbox | `command -v docker` fails | Display error requiring Docker | Install Docker separately; re-run `pi_sandbox` module |
| AIAGT-005 | Docker image build fails | Docker build exits non-zero | Display error with Docker output | Check Dockerfile, network, Pi version |
| AIAGT-006 | Target path is a non-symlink file during deploy | File exists and is not a symlink | Back up with timestamp (`BACKUP_TIMESTAMP_FMT`), then create symlink | User can inspect backup at `*.backup.YYYYMMDD_HHMMSS` |
| AIAGT-007 | Sandbox OOM kill | Container exit code 137 | Display OOM warning, retry after 5s delay | Increase recommended resource allocation or reduce task complexity |
| AIAGT-008 | Sandbox timeout | Container exit code 124 | Display timeout warning, retry after 5s delay | Increase timeout or simplify task |
| AIAGT-009 | Subagent fork over capacity | Running jobs ≥ `MAX_RUNNING_JOBS` (8) | Return error with current count and max | Cancel a job or wait, then retry |
| AIAGT-010 | Missing API key for web search | `OLLAMA_API_KEY` env var not set | Tool returns error message | Set environment variable and retry |
| AIAGT-011 | Invalid subagent_run parameters | More or fewer than 1 of task/tasks/chain | Return error with usage guidance | Provide exactly one mode parameter |
| AIAGT-012 | Codex config overwrite attempted | `CODEX_CONFIG_TEMPLATE_MODE=overwrite` with existing file | Back up existing config, copy template | Restore from backup if needed |
| AIAGT-013 | Subagent model routing missing | `subagentModelRouting` key absent from Pi settings.json | Extension logs warning; tool descriptions omit routing table | Fall back to parent agent's default model and thinking level |
| AIAGT-014 | Widget render failure | Exception during widget rendering | Log error, skip re-render, widget may be stale | Widget continues on next successful render; user can check `subagent_status` as fallback |
| AIAGT-015 | Duplicate skill name in Pi profile build | Same skill directory name exists in `shared/skills/` and a profile-local skills directory | Abort `pim build` or `pim create` with explicit duplicate name error | Rename or remove the profile-local skill, then rebuild |

---

## Implementation Notes

1. **Symlink resilience**: All symlink operations use the three-way pattern (if symlink → remove, if file → backup then link, if absent → create link). This ensures idempotent re-runs without data loss.

2. **Copy vs symlink for runtime-mutable config**: Codex `config.toml` is copied (not symlinked) because the agent writes machine-specific values at runtime (e.g., `personality`, trusted project paths). The `CODEX_CONFIG_TEMPLATE_MODE` variable controls overwrite behavior.

3. **fnm independence**: Installing agents with the `NPM_GLOBAL_PREFIX` prefix puts binaries in `~/.local/bin/`, which is outside fnm's managed path. This means switching Node versions with fnm does not remove or break agent installations.

4. **Shared skills source**: Cross-agent skills live in `~/dotfiles/shared/skills/`. Non-Pi agents read that directory directly through symlinks. Every Pi profile includes those skills in its resolved runtime `skills/` directory and MAY add profile-local skills if no names collide.

5. **Pi subagent isolation**: Subagent processes are spawned as separate Pi child processes with isolation flags. Each subagent gets its own context window and system prompt. Extensions are NOT loaded by default in subagents (explicit opt-in required).

6. **Pi sandbox security**: The sandbox uses network isolation when running under Ralph's Docker sandbox mode — a dedicated network (`sandbox-net`) with iptables rules that allow only DNS and specific service endpoints. The standalone `pis` command runs containers on the default Docker network without resource limits or network isolation.

6a. **Codex sandbox security**: The standalone `cods` command is designed for accidental overreach and malicious prompt/tool behavior inside `codex --yolo`. It constrains mounted host paths, overlays Codex auth read-only, runs as the host UID/GID, and applies resource limits. It does not claim to prevent container escapes or network exfiltration from mounted/project secrets or forwarded API environment variables.

7. **Ralph loop resilience**: The `loop.sh` script handles container crashes (exit code 137 for OOM, 124 for timeout) by logging the error and continuing to the next iteration. The orchestrator monitors progress every 5 minutes and can inject course corrections by appending to `PROMPT.md`.

8. **Agent .gitignore hygiene**: Each agent config directory includes a `.gitignore` that excludes credentials, history, session data, and local runtime files. Sensitive files MUST remain local-only and NEVER be committed.

9. **Pi model persistence**: The `inherit-last-model` extension writes to a temp file on every model change, ensuring that even if Pi crashes before a `/new` command, the last-selected model is still available for restoration.

10. **Extension symlink pattern**: Pi extensions are symlinked as directories (not individual files), ensuring the extension's source code and compiled artifacts live in the dotfiles repository while appearing at the expected path in each profile runtime's `extensions/` directory.

---

## Test Scenarios

### Installation and Deployment

**TS-AIAGT-001**: Idempotent symlink deployment
Category: Integration
Priority: Critical
Preconditions: Agent config directory does not exist
Input: Run install script twice
Expected Output: After first run, all symlinks point to dotfiles sources. After second run, all symlinks still point to dotfiles sources with no errors, no backups created, and no data loss.

**TS-AIAGT-002**: Backup of existing non-symlink config
Category: Integration
Priority: Critical
Preconditions: `~/.claude/settings.json` exists as a regular file with user data
Input: Run install script
Expected Output: Existing file is moved to `~/.claude/settings.json.backup.{timestamp}`; symlink replaces it pointing to `~/dotfiles/claude/settings.json`; backed-up data is preserved.

**TS-AIAGT-003**: Skills symlink target verification
Category: Integration
Priority: Critical
Preconditions: Fresh install completed for all five agents
Input: Read the symlink target of `~/.claude/skills`, `~/.pi/agent/skills`, `~/.agents/skills`, `~/.gemini/skills`, `~/.config/copilot/skills`
Expected Output: `~/.claude/skills`, `~/.agents/skills`, `~/.gemini/skills`, and `~/.config/copilot/skills` resolve to `~/dotfiles/shared/skills/`. `~/.pi/agent/skills` resolves to the active profile runtime's resolved `skills/` directory, which contains all shared skills.

**TS-AIAGT-004**: Skill availability across agents
Category: Integration
Priority: High
Preconditions: A new skill is added to `~/dotfiles/shared/skills/my-skill/SKILL.md`
Input: Check skill availability from each agent
Expected Output: The new skill is immediately visible to non-Pi agents. The new skill becomes visible to every Pi profile after rebuilding profile output.

**TS-AIAGT-004a**: Duplicate skill names fail profile build
Category: Integration
Priority: High
Preconditions: A Pi profile defines `pi/profiles/local/skills/my-skill/` and `shared/skills/my-skill/` already exists
Input: Run `pim build local`
Expected Output: Build fails with an error identifying the duplicate skill name; existing deployed profile output is not partially overwritten.

**TS-AIAGT-005**: Codex config template preservation
Category: Integration
Priority: High
Preconditions: `~/.codex/config.toml` exists with local runtime values (e.g., `personality`, trusted project paths)
Input: Run install script with `CODEX_CONFIG_TEMPLATE_MODE=preserve` (default)
Expected Output: Existing `config.toml` is left unchanged; no template overwrites occur.

**TS-AIAGT-006**: Codex config template overwrite
Category: Integration
Priority: High
Preconditions: `~/.codex/config.toml` exists with user customizations
Input: Run install script with `CODEX_CONFIG_TEMPLATE_MODE=overwrite`
Expected Output: Existing file is backed up with timestamp; template is copied in its place; user can restore customizations from backup.

**TS-AIAGT-007**: npm install prefix independence
Category: Unit
Priority: Critical
Preconditions: fnm manages multiple Node.js versions
Input: Install Pi via `npm install -g --prefix ~/.local`; switch Node version with fnm; check `~/.local/bin/pi`
Expected Output: Pi binary still exists and functions at `~/.local/bin/pi` regardless of active Node version.

**TS-AIAGT-008**: Codex config symlink conversion
Category: Integration
Priority: Medium
Preconditions: `~/.codex/config.toml` is currently a symlink to dotfiles template
Input: Run install script
Expected Output: Symlink is removed; template content is copied as a regular file; local file persists independently of dotfiles changes.

### Agent-Specific Configuration

**TS-AIAGT-009**: Claude Code MCP cleanup on deploy
Category: Integration
Priority: Medium
Preconditions: Claude Code has a `playwright` MCP server configured
Input: Run install script for Claude module
Expected Output: Legacy `playwright` MCP server is removed from Claude's config.

**TS-AIAGT-010**: Pi model inheritance across sessions
Category: Unit
Priority: High
Preconditions: Pi is running with model `glm-5.1` on provider `ollama-cloud`
Input: User runs `/new` to start a fresh session
Expected Output: The new session starts with the same model (`glm-5.1`) and provider (`ollama-cloud`) as the previous session.

**TS-AIAGT-011**: Pi model inheritance — removed model
Category: Unit
Priority: Medium
Preconditions: Pi previously used model X; model X has been removed from `models.json`
Input: User starts a new session
Expected Output: The extension silently skips restore; Pi falls through to its configured default model.

### Pi Subagent System

**TS-AIAGT-012**: Subagent run — single task
Category: Unit
Priority: Critical
Preconditions: Pi coding agent is running
Input: `subagent_run` with `task: "list files in current directory"`
Expected Output: Tool returns result with the output of the subagent; job is not tracked in background (synchronous execution).

**TS-AIAGT-013**: Subagent run — parallel tasks
Category: Unit
Priority: High
Preconditions: Pi coding agent is running
Input: `subagent_run` with `tasks: [{task: "read file A"}, {task: "read file B"}]`
Expected Output: Both tasks execute concurrently; result includes success/failure count and individual summaries.

**TS-AIAGT-014**: Subagent run — chain with {previous} substitution
Category: Unit
Priority: High
Preconditions: Pi coding agent is running
Input: `subagent_run` with `chain: [{task: "find all TODOs"}, {task: "categorize: {previous}"}]`
Expected Output: First step runs to completion; its output replaces `{previous}` in the second step's task; second step runs with the substituted text.

**TS-AIAGT-015**: Subagent fork — background job creation
Category: Unit
Priority: Critical
Preconditions: No running background jobs
Input: `subagent_fork` with `task: "analyze large codebase"`
Expected Output: Returns immediately with job ID; job runs in background; completion notification is sent via steer message; status widget appears above editor showing the running job.

**TS-AIAGT-015a**: Subagent fork — live progress widget
Category: Unit
Priority: Critical
Preconditions: No running background jobs
Input: `subagent_fork` with `tasks: [{task: "review auth"}, {task: "run tests"}, {task: "check lint"}]`
Expected Output: Widget appears above editor with header line showing total job count. Running jobs show two-line format: last text snippet + last tool call. As jobs complete, they collapse to one-line summary. When last job finishes, widget remains visible for 5 seconds then disappears.

**TS-AIAGT-015b**: Subagent fork — widget dismiss delay
Category: Unit
Priority: Medium
Preconditions: One forked job is running
Input: Job completes
Expected Output: Widget shows completed job as one-line summary. After 5 seconds (`SUBAGENT_WIDGET_DISMISS_DELAY_MS`), widget is removed.

**TS-AIAGT-015c**: Subagent fork — widget update debounce
Category: Unit
Priority: Medium
Preconditions: A forked job is active and producing messages rapidly
Input: Multiple `message_end` events arrive within 1 second
Expected Output: Widget re-renders at most once per `SUBAGENT_WIDGET_DEBOUNCE_MS` (1000ms). State transitions (completion, failure) trigger immediate re-render regardless of debounce.

**TS-AIAGT-015d**: Subagent fork — partial result available on running job
Category: Unit
Priority: High
Preconditions: A forked job is running and has processed at least 2 assistant messages
Input: `subagent_status` with the running job's ID
Expected Output: Status output includes "Progress" section with turns so far, usage so far, last text snippet, and last tool call from completed messages.

**TS-AIAGT-016**: Subagent fork — concurrency cap
Category: Unit
Priority: High
Preconditions: 8 background jobs already running
Input: `subagent_fork` with `task: "one more task"`
Expected Output: Error returned indicating maximum concurrent jobs reached; job is NOT created.

**TS-AIAGT-017**: Subagent wait — timeout
Category: Unit
Priority: Medium
Preconditions: A job is running that takes longer than the specified timeout
Input: `subagent_wait` with `jobId` and `timeout: 10`
Expected Output: After 10 seconds, returns error indicating the job is still running; job is NOT cancelled.

**TS-AIAGT-017a**: Subagent wait — streaming progress
Category: Unit
Priority: High
Preconditions: A forked job is running
Input: `subagent_wait` with the running job's ID
Expected Output: Tool result area streams progress updates using two-line format (last text snippet + last tool call), refreshed on each `message_end` event. When job completes, final result is returned.

**TS-AIAGT-018**: Subagent cancel — cancel all
Category: Unit
Priority: Medium
Preconditions: 3 background jobs running
Input: `subagent_cancel` with `all: true`
Expected Output: All 3 jobs are cancelled; `subagent_status` shows no running jobs; cancellation notification is delivered via steer message for each cancelled job.

**TS-AIAGT-018a**: Subagent cancel — notification content
Category: Unit
Priority: High
Preconditions: One forked job is running and has consumed tokens
Input: `subagent_cancel` with the running job's ID
Expected Output: Cancellation steer message includes: status icon (⊘), job name, elapsed time, partial usage stats (tokens consumed before cancellation), last completed assistant text, and last completed tool call. No partial/mid-stream data is shown.

**TS-AIAGT-018b**: Subagent cancel — silent cancellation detection
Category: Unit
Priority: Medium
Preconditions: A job is cancelled via `subagent_cancel`
Input: LLM does NOT call `subagent_status` after cancellation
Expected Output: LLM receives a steer notification about the cancellation without needing to poll.

### Pi Sandbox

**TS-AIAGT-019**: Pi sandbox — basic launch
Category: Integration
Priority: High
Preconditions: Docker is installed; `pis:latest` image built; CWD is a project directory
Input: Run `pis`
Expected Output: Pi starts inside a Docker container with the project directory mounted read-write; agent state (auth, settings, skills) accessible.

**TS-AIAGT-020**: Pi sandbox — auto-rebuild on Pi version change
Category: Integration
Priority: Medium
Preconditions: `pis:latest` image exists with Pi @ version X; npm latest shows version Y
Input: Run `pis` (without `--no-rebuild`)
Expected Output: Image is automatically rebuilt with Pi @ version Y; user sees rebuild notification.

**TS-AIAGT-021**: Pi sandbox — extra directory mount
Category: Integration
Priority: Medium
Preconditions: Additional project directory exists at `~/Code/lib`
Input: Run `pis ~/Code/lib`
Expected Output: Container mounts `~/Code/lib` as read-only; CWD is mounted read-write.

**TS-AIAGT-022**: Pi sandbox — read-write extra directory
Category: Integration
Priority: Medium
Preconditions: Additional project directory exists
Input: Run `pis -rw ~/Code/lib`
Expected Output: Container mounts `~/Code/lib` as read-write.

**TS-AIAGT-022b**: Pi sandbox — non-root container user
Category: Integration
Priority: Critical
Preconditions: Docker image built with `HOST_USER`, `HOST_UID`, and `HOST_GID` build args matching the host user
Input: Run `pis` and create a file inside the container at the mounted CWD
Expected Output: File is created with the host user's UID and GID ownership (not root). `ls -la` on the host shows the file owned by the host user.

**TS-AIAGT-022c**: Pi sandbox — container home directory matches host user
Category: Integration
Priority: High
Preconditions: Docker image built with host user build args
Input: Run `pis` and check `echo $HOME` and `whoami` inside the container
Expected Output: `$HOME` is `/home/{HOST_USER}/`, `whoami` returns `{HOST_USER}`, and Pi agent state is mounted at `/home/{HOST_USER}/.pi/agent/`.

### Codex Sandbox

**TS-AIAGT-022d**: Codex sandbox — dry-run safety contract
Category: Unit
Priority: Critical
Preconditions: CWD is a project directory; `~/.codex` exists; `~/.codex/auth.json` may exist
Input: Run `cods --dry-run`
Expected Output: The generated Docker command mounts CWD read-write at the same path, sets `-w` to CWD, runs as the host UID/GID, sets `HOME=/home/{HOST_USER}`, mounts `~/.codex` read-write, overlays `~/.codex/auth.json` read-only when present, applies memory/CPU/PID limits, and invokes `codex --yolo`.

**TS-AIAGT-022e**: Codex sandbox — default-deny extra mounts
Category: Unit
Priority: High
Preconditions: High-risk path such as `~/.ssh` exists
Input: Run `cods --mount-ro ~/.ssh --dry-run`
Expected Output: The command is rejected unless `--allow-dangerous-mount` is supplied.

**TS-AIAGT-022f**: Codex sandbox — extra directory mounts
Category: Unit
Priority: Medium
Preconditions: Additional project directory exists at `~/Code/lib`
Input: Run `cods --mount-ro ~/Code/lib --mount-rw ~/Code/worktree --dry-run`
Expected Output: The generated Docker command mounts the read-only path with `:ro` and the read-write path with `:rw`, both at their same absolute paths.

### Agent Roles

**TS-AIAGT-023**: Test quality verifier — vague assertion detection
Category: Unit
Priority: High
Preconditions: Project with test files containing `expect(true).toBe(true)` assertions
Input: Run test quality verifier agent
Expected Output: Report identifies vague assertions; suggests specific replacements; passes only if all vauge assertions are fixed and coverage meets thresholds.

**TS-AIAGT-024**: Playwright Visual QA — missing playwright-cli
Category: Unit
Priority: Medium
Preconditions: `playwright-cli` is not installed
Input: Run playwright visual QA agent
Expected Output: Agent reports that `playwright-cli` is not found and instructs the user to install it; does not proceed with browser automation.

**TS-AIAGT-042**: Visual QA — checklist execution with pass/fail report
Category: Unit
Priority: High
Preconditions: `playwright-cli` is installed; a target web application is running locally at `http://localhost:3000`; a structured checklist is provided
Input: Run visual QA agent with checklist containing navigation, form fill, button click, and verification steps
Expected Output: Agent opens browser, executes each step in order, captures screenshots, runs console/network checks, closes browser, and produces a structured Visual QA Report with a Step Results table and a pass/fail verdict. Any step failure is recorded as ❌ FAIL with evidence.

**TS-AIAGT-043**: Visual QA — console error detection in final checks
Category: Unit
Priority: Medium
Preconditions: `playwright-cli` is installed; target app has a known console error on page load
Input: Run visual QA agent with a navigation-only checklist
Expected Output: Agent opens browser, navigates to URL, runs final checks, reports the console error in the Final Checks summary section with error count and details. Verdict reflects failure due to console errors.

**TS-AIAGT-044**: Design reviewer — multi-viewport screenshot capture
Category: Unit
Priority: High
Preconditions: `playwright-cli` is installed; a rendered UI page is available; a design system reference exists
Input: Run design reviewer agent with a task targeting a specific UI component
Expected Output: Agent renders the page at 375px, 768px, and 1280px widths; saves screenshots for each viewport; evaluates visual consistency, interaction patterns, and responsiveness across all three widths; returns a severity-tagged review card with screenshot evidence paths and a pass/fail verdict.

**TS-AIAGT-045**: Design reviewer — missing design system fallback
Category: Unit
Priority: Medium
Preconditions: `playwright-cli` is installed; target page has NO design system reference files
Input: Run design reviewer agent
Expected Output: Agent discovers no design system reference; applies general heuristics (consistent rhythm, clear visual hierarchy, no orphaned elements) instead; returns review card with advisory and blocking issues; verdict references heuristic standards explicitly.

**TS-AIAGT-046**: Premortem reviewer — operational risk detection
Category: Unit
Priority: High
Preconditions: Implementation source files contain a known risk (e.g., unbounded loop, missing null check, non-idempotent mutation)
Input: Run premortem reviewer agent with task context describing the feature
Expected Output: Agent reads task and source files; identifies the known risk under the appropriate failure mode category (operational, edge case, deployment, data integrity, observability, latency/scale); returns structured verdict with 🔴 blocking items referencing specific file:line locations and a pass/fail verdict.

**TS-AIAGT-047**: Premortem reviewer — resilience note for well-handled patterns
Category: Unit
Priority: Medium
Preconditions: Implementation source files contain well-handled reliability patterns (proper error handling, idempotent mutations, adequate logging)
Input: Run premortem reviewer agent
Expected Output: Agent identifies well-handled patterns and includes a 🟢 resilience noted section in the verdict; summary paragraph acknowledges the positive practices alongside any blocking or advisory items.

**TS-AIAGT-048**: Design reviewer — blocking issue classification
Category: Unit
Priority: Medium
Preconditions: A rendered page has a critical a11y failure (missing alt text on primary navigation image) and a minor spacing inconsistency
Input: Run design reviewer agent
Expected Output: Agent classifies the a11y failure as 🔴 blocking and the spacing issue as 🟡 advisory; review card clearly separates blocking from advisory items with specific references and screenshot evidence.

**TS-AIAGT-049**: Visual QA — step failure does not abort remaining steps
Category: Unit
Priority: High
Preconditions: A checklist has 5 steps; step 2 is expected to fail (element not found)
Input: Run visual QA agent
Expected Output: Agent records step 2 as ❌ FAIL with evidence, continues to execute steps 3–5, produces a complete report showing all step results and a verdict of ❌ NEEDS-FIX with failure count.

**TS-AIAGT-050**: Premortem reviewer — deployment risk identification for migration order
Category: Unit
Priority: Medium
Preconditions: Implementation includes a database migration after application code change with no rollback plan documented
Input: Run premortem reviewer agent
Expected Output: Agent identifies the migration order risk under deployment risks category; flags missing rollback plan as a separate advisory item; returns structured verdict.

**TS-AIAGT-025**: Subagent model routing — prescriptive model selection
Category: Unit
Priority: Critical
Preconditions: Pi settings.json contains `subagentModelRouting` with rows for scout, planner, reviewer, and implementer; the LLM invokes `subagent_run` with a scouting task
Input: LLM classifies task as "scout" and uses the prescribed model/provider/thinking from the routing table
Expected Output: The subagent is launched with the exact model, provider, and thinking level specified in the routing table for the "scout" category; no deviation without explicit justification.

**TS-AIAGT-026**: Subagent model routing — missing routing table
Category: Unit
Priority: High
Preconditions: Pi settings.json does NOT contain `subagentModelRouting`
Input: LLM invokes `subagent_run` for any task
Expected Output: Extension logs a warning about missing routing configuration; subagent uses parent agent's default model and thinking level; tool descriptions do not include routing guidance.

**TS-AIAGT-027**: Subagent model routing — routing table injected into tool descriptions
Category: Unit
Priority: High
Preconditions: Pi settings.json contains `subagentModelRouting` with rows for scout, planner, reviewer, and implementer)
Input: Pi starts a new session
Expected Output: The `subagent_run` and `subagent_fork` tool descriptions include a markdown table with columns: category, description, model, provider, thinking, rationale; the table contains entries for scout, planner, reviewer, and implementer.

**TS-AIAGT-028**: Subagent fork — summary extraction threshold
Category: Unit
Priority: High
Preconditions: A subagent's last assistant message is a short acknowledgment ("Done.", 5 chars); the second-to-last assistant message contains a substantive 200-character analysis
Input: Subagent completes; notification is emitted
Expected Output: Notification summary uses the 200-character analysis text, not the 5-char acknowledgment, because the acknowledgment is below `SUBAGENT_SUMMARY_MIN_LENGTH` (50 chars).

**TS-AIAGT-029**: Subagent fork — widget text truncation
Category: Unit
Priority: Medium
Preconditions: A running subagent's last text output contains newlines
Input: `subagent_fork` with a job producing multi-line text
Expected Output: Widget shows the text truncated at the first newline boundary, then clipped to fit remaining terminal width. No line-wrapping occurs in the widget.

### Tools Display

**TS-AIAGT-030**: Tools display — custom toolset shown as bracket
Category: Unit
Priority: High
Preconditions: A subagent is spawned with `tools: "read,grep"`
Input: Check widget, status, results, and call rendering for the job
Expected Output: Every display surface shows `[read,grep]` after the job/model name. Bracket content is comma-separated without spaces.

**TS-AIAGT-031**: Tools display — undefined tools means all defaults, no display
Category: Unit
Priority: High
Preconditions: A subagent is spawned without `tools` parameter (undefined)
Input: Check widget, status, results, and call rendering for the job
Expected Output: No tool bracket appears on any display surface. The absence of `[...]` indicates all default tools are available.

**TS-AIAGT-032**: Tools display — bracket convention distinguishes scope from model config
Category: Unit
Priority: Medium
Preconditions: A subagent is spawned with `provider: "ollama-cloud"`, `model: "deepseek-v4-pro"`, `thinking: "high"`, `tools: "read,grep"`
Input: Check call rendering and expanded result view
Expected Output: Model config appears in parentheses: `(ollama-cloud/deepseek-v4-flash, think:high)`. Tool scope appears in brackets: `[read,grep]`. The full line shows both: `name (ollama-cloud/deepseek-v4-flash, think:high) [read,grep]`.

**TS-AIAGT-033**: Tools display — long tool list truncated at 30 chars
Category: Unit
Priority: Medium
Preconditions: A subagent is spawned with `tools: "read,write,bash,edit,grep,find,ls"`
Input: Check any display surface for the job
Expected Output: Bracket is truncated at 30 chars with `+N` overflow: `[read,write,bash,edit,grep,find +1]`. The count `+1` represents the number of tools that didn't fit (ls).

**TS-AIAGT-034**: Tools display — widget shows tools on line 1 only
Category: Unit
Priority: High
Preconditions: A forked subagent is running with `tools: "read,grep"`
Input: Check the widget content for the running job
Expected Output: Line 1 shows: `⏳ {name} [read,grep] ({elapsed}) {usage}`. Line 2 (snippet + tool call) does NOT show the tools bracket.

**TS-AIAGT-035**: Tools display — status shows Tools line after Task
Category: Unit
Priority: High
Preconditions: A completed job with `tools: "read,write,bash"`
Input: `subagent_status` with the job ID
Expected Output: Output includes `**Task:** {task}` followed by `**Tools:** read, write, bash` (comma-separated with spaces for readability in markdown output).

**TS-AIAGT-036**: Tools display — results shows Tools line after Task
Category: Unit
Priority: High
Preconditions: A completed job with `tools: "read,grep"`
Input: `subagent_results` with the job ID
Expected Output: Output includes `**Task:** {task}` followed by `**Tools:** read, grep`.

**TS-AIAGT-037**: Tools display — notifications do NOT show tools
Category: Unit
Priority: Medium
Preconditions: A forked job with `tools: "read,grep"` completes
Input: Check the completion notification (steer message)
Expected Output: Notification includes `**Job:**`, `**Task:**`, summary text, and usage — but does NOT include a `**Tools:**` line.

**TS-AIAGT-038**: Tools display — renderCall shows bracket after model config
Category: Unit
Priority: High
Preconditions: `subagent_run` is called with `provider: "ollama-cloud"`, `model: "glm-5.1"`, `thinking: "medium"` (default), `tools: "read,write,bash,edit"`
Input: Check the `renderCall()` output for the tool call
Expected Output: Call rendering shows: `subagent_run {name} (ollama-cloud/glm-5.1) [read,write,bash,edit]` followed by task preview. The `think:medium` is omitted (it's the default), and the tool bracket appears after the model parentheses.

**TS-AIAGT-039**: Tools display — fork response shows bracket per job
Category: Unit
Priority: High
Preconditions: `subagent_fork` spawns 2 parallel jobs, one with `tools: "read,grep"` and one with all defaults
Input: Check the fork response text
Expected Output: The job with custom tools shows: `**scout** [read,grep] — {task} (running)`. The job with default tools shows: `**implementer** — {task} (running)` (no bracket).

**TS-AIAGT-040**: Tools display — parallel/chain result text headings include brackets
Category: Unit
Priority: Medium
Preconditions: `subagent_run` with parallel tasks, one scoped to `tools: "read,grep"`, one with all defaults
Input: Check the parallel result text output
Expected Output: The scoped task heading shows: `## scout [read,grep] (completed)`. The default task heading shows: `## implementer (completed)` (no bracket).

**TS-AIAGT-041**: Tools display — deserialization treats missing tools as undefined
Category: Unit
Priority: Medium
Preconditions: A job was serialized in an older version that did not include the `tools` field
Input: Deserialize the job and check `subagent_status`
Expected Output: `tools` is `undefined`; no tool bracket appears in any display surface. The job is treated as having all default tools, consistent with the display rule.

---

## Changelog

| Version | Date | Summary |
|---------|------|---------|
| 1.7.0 | 2026-06-02 | Added Pi profiles as first-class deployable agent-config variants. Specified `pim` as the profile manager, per-profile resolved output under `pi/profiles/{profile}/resolved/`, active profile switching via `~/.pi/agent` and `~/.pi/active-profile`, profile-specific settings/models/agents/extensions, shared skills inclusion across all profiles, profile-local skill layering, and duplicate-skill build errors. |
| 1.6.0 | 2026-05-19 | Split Pi-specific subagent workflow skills into `pi/skills/`; Pi now links `~/.pi/agent/skills` to the composed Pi skills directory while non-Pi agents continue to link to `shared/skills/`. |
| 1.5.0 | 2026-05-13 | Updated B9 Agent Role Definitions: B9.1 (Test Reviewer) matches actual `test-reviewer.md` agent behavior; B9.2 (Visual QA) expanded to full three-phase checklist workflow matching `visual-qa.md`; added B9.3 (Design Reviewer) from `design-reviewer.md` with multi-viewport rendering and severity-tagged review cards; added B9.4 (Premortem Reviewer) from `premortem-reviewer.md` with six failure mode categories. Added 9 test scenarios (TS-AIAGT-042 through TS-AIAGT-050) covering visual QA checklist execution and console error detection, design reviewer multi-viewport capture and missing-design-system fallback, premortem reviewer operational risk detection and resilience notes, blocking issue classification, step-failure continuation, and deployment risk identification. |
| 1.0.0 | 2026-05-01 | Initial specification extracted from brownfield codebase. Covers all five agents, shared skills, Pi extensions (subagent, inherit-last-model, web-search), Pi sandbox, Ralph agentic loop, agent role definitions, symlink deployment, and error handling. |
| 1.1.0 | 2026-05-01 | Added subagent model routing: prescriptive model selection via `subagentModelRouting` in Pi settings, injected into subagent tool descriptions. Added data structure, behavior rules, error handling, and test scenarios. |
| 1.3.0 | 2026-05-01 | Added subagent live progress: TUI status widget for forked jobs, partial result updates on running jobs, cancellation notifications, `subagent_status` progress section, `subagent_wait` streaming updates, improved summary extraction (skip short text blocks), widget debounce and dismiss delay. |
| 1.2.0 | 2026-05-01 | Pi sandbox runs as host user (not root): Dockerfile creates host user via build args, `pis` script passes `--user` flag and mounts agent state under `/home/{HOST_USER}/`. Files written by the container are now owned by the host user. |
| 1.4.0 | 2026-05-02 | Added tools display: resolved tool allowlist shown as `[tool1,tool2,...]` brackets across all subagent display surfaces. Added `tools?: string[]` to `AsyncJob`, `SingleResult`, and `SerializedJob` data structures. Brackets use `()` for model config and `[]` for tool scope. Undefined tools (all defaults) omitted from display. Truncation at 30 chars with `+N` overflow. Notifications and widget line 2 exclude tools. Added 12 test scenarios (TS-AIAGT-030 through TS-AIAGT-041). |

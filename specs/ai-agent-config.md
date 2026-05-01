# AI Agent Configuration Specification

> **Version**: 1.2.0
> **Last Updated**: 2026-05-01
> **Depends On**: [Parameters](parameters.md), [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md), [Design Language](DESIGN_LANGUAGE.md)
> **Depended By**: Install Orchestrator (INSTL)
> **Prefix**: AIAGT

---

## Overview

The AI Agent Configuration system provisions, configures, and manages five AI coding assistants — Codex CLI, Claude Code, Pi, Gemini CLI, and GitHub Copilot CLI — for a shared dotfiles environment. Every **agent** receives version-controlled configuration from the dotfiles repository via the **symlink deployment** pattern, and shares a single canonical **shared skills directory** across all agents.

The system MUST ensure that:

1. Each agent's runtime configuration directory is wired to the dotfiles repository through symlinks, so edits in the repo are immediately live.
2. Sensitive data (credentials, session history, auth tokens) NEVER enters version control.
3. The shared skills directory is the single source of truth for cross-agent skill definitions — any symlinked agent skills path points to the same physical directory.
4. Each agent is installed to a user-local prefix that survives Node.js version manager switches.
5. The install process is **idempotent** — re-running it produces the same end state without errors or data loss.

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
| `AGENT_CONFIG_DIR_PI` | `~/.pi/agent` | path | Pi coding agent's canonical config directory |
| `AGENT_CONFIG_DIR_GEMINI` | `~/.gemini` | path | Gemini CLI's canonical config directory |
| `AGENT_CONFIG_DIR_COPILOT` | `~/.config/copilot` | path | Copilot CLI's canonical config directory |
| `AGENT_SKILLS_DIR_CODEX` | `~/.agents/skills` | path | Codex CLI resolves skills from this path; symlinked to shared skills |
| `SANDBOX_IMAGE_NAME` | `pis:latest` | image reference | Default Pi sandbox container image |
| `SANDBOX_NETWORK` | `sandbox-net` | network name | Isolated network for sandbox containers (used by Ralph sandbox mode, not by `pis`) |
| `SANDBOX_RECOMMENDED_MEMORY` | `8g` | memory allocation | Recommended memory allocation for sandbox containers |
| `SANDBOX_RECOMMENDED_CPU` | `4` | CPU allocation | Recommended CPU core allocation for sandbox containers |
| `SANDBOX_RECOMMENDED_PIDS` | `512` | PID allocation | Recommended process count cap for sandbox containers |
| `SUBAGENT_MAX_RUNNING_JOBS` | `8` | count | Maximum concurrent async subagent jobs (internal constant, not user-configurable) |
| `SUBAGENT_MAX_PARALLEL_TASKS` | `20` | count | Maximum tasks in a single parallel `subagent_run` call (internal constant, not user-configurable) |
| `SUBAGENT_WAIT_TIMEOUT_DEFAULT` | `300` | seconds | Default timeout for `subagent_wait` (internal constant, not user-configurable) |
| `CODEX_CONFIG_TEMPLATE_MODE` | `preserve` | enum: `preserve` \| `overwrite` | Whether the install script overwrites existing Codex config with template; `preserve` keeps local runtime values |
| `BACKUP_TIMESTAMP_FMT` | `%Y%m%d_%H%M%S` | strftime format | Timestamp format appended to backup filenames during symlink deployment (e.g., `settings.json.backup.20260501_120000`) |
| `RALPH_DEFAULT_ITERATIONS` | `25` | count | Default max loop iterations for Ralph agentic loop |
| `RALPH_DONE_PATTERN` | `/done` | string | Pattern that signals loop completion in Ralph worker output |

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
| `sharedSkillsTarget` | string | Required | Target path in config dir that receives the shared skills symlink |
| `sensitivePatterns` | list | Required | Glob patterns that MUST NOT be committed to version control |
| `authCommand` | string | Required | Command the human runs to authenticate |

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

| Target Path | Source Path | Deploy Mode |
|-------------|-------------|-------------|
| `~/.pi/agent/skills/` | `~/dotfiles/shared/skills/` | symlink |
| `~/.pi/agent/settings.json` | `~/dotfiles/pi/settings.json` | symlink |
| `~/.pi/agent/models.json` | `~/dotfiles/pi/models.json` | symlink |
| `~/.pi/agent/extensions/subagent/` | `~/dotfiles/pi/extensions/subagent/` | symlink |
| `~/.pi/agent/extensions/web-search/` | `~/dotfiles/pi/extensions/web-search/` | symlink |
| `~/.pi/agent/extensions/inherit-last-model/` | `~/dotfiles/pi/extensions/inherit-last-model/` | symlink |

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

A **skill** is a reusable instruction set shared across agents.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `name` | string | Required; kebab-case | Skill identifier, matches directory name |
| `description` | string | Required | Human-readable purpose of the skill |
| `metadata.short-description` | string | Optional | Brief description for agents that support it (Codex, Pi) |
| `allowed-tools` | list of strings | Optional | Tool allowlist for agents that support it (Claude Code) |

The skill directory MUST contain a `SKILL.md` file with YAML frontmatter containing the fields above. A skill MAY include additional files (`REFERENCE.md`, `EXAMPLES.md`, helper scripts) in the same directory.

### Pi Extension

A Pi **extension** is a module loaded by the Pi coding agent at startup, written in TypeScript. Each extension registers tools and optionally subscribes to Pi lifecycle events (session start, session shutdown, model selection) to modify agent behavior. Extension directories are symlinked from the dotfiles repository into `~/.pi/agent/extensions/`.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `name` | string | Required; matches directory name under `pi/extensions/` | Extension identifier |
| `tools` | list | Required | Registered tool names and their schemas |
| `lifecycleHooks` | list | Optional | Pi lifecycle events the extension subscribes to (session lifecycle and model selection events) |

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
| `result` | SingleResult | Set on completion | Full output including messages, usage, exit code |
| `provider` | string | Optional | Provider override for the subagent |
| `model` | string | Optional | Model override for the subagent |
| `thinking` | enum | `off`, `minimal`, `low`, `medium`, `high`, `xhigh` | Thinking level override |

### Subagent Model Routing

A prescriptive mapping from subagent intent categories to model, provider, and thinking level. The routing table is stored in Pi's `settings.json` as the `subagentModelRouting` key and injected into the `subagent_run` and `subagent_fork` tool descriptions by the subagent extension as a markdown table.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `subagentModelRouting` | map | Required in Pi settings; key is routing category name | Top-level key in Pi settings containing the routing table |
| category key | string | Required; one of: `scout`, `planner`, `reviewer`, `implementer`, `specialist` | Intent category that classifies the subagent's task |
| `description` | string | Required | Brief description of what counts as this category; helps the LLM classify tasks correctly |
| `model` | string | Required | Model ID matching an entry in `models.json` |
| `provider` | string | Required | Provider ID matching an entry in `models.json` |
| `thinking` | enum | Required; one of: `off`, `minimal`, `low`, `medium`, `high`, `xhigh` | Thinking level for this category |
| `rationale` | string | Required | One-line explanation of why this model/thinking pair was chosen for this category |

### Shared Skills Directory

The single canonical directory at `~/dotfiles/shared/skills/` — all agent skill configuration paths MUST point here via symlinks. When a skill is installed via any agent's skill installer (e.g., `npx skills@latest add`), it lands directly in this directory because every agent's skills path is already a symlink to it.

---

## Behavior

### B1: Agent Installation

Each agent MUST be installed via its designated method:

| Agent | Install Method | Command |
|-------|---------------|---------|
| Codex CLI | npm | `npm install -g --prefix ~/.local @openai/codex@latest` |
| Claude Code | curl | `curl -fsSL https://claude.ai/install.sh \| bash` |
| Pi | npm | `npm install -g --prefix ~/.local @mariozechner/pi-coding-agent@latest` |
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
5. The `shared/skills/` directory MUST be symlinked to every agent's skills target path.

**Copy deployment (Codex config.toml only):**

1. On first install, the template MUST be copied to `~/.codex/config.toml`.
2. If an existing symlink is found, it MUST be converted to a local file copy (removed, then copied from template).
3. On subsequent installs, by default the existing local file MUST be preserved (`CODEX_CONFIG_TEMPLATE_MODE=preserve`).
4. If `CODEX_CONFIG_TEMPLATE_MODE=overwrite` is set, the existing file MUST be backed up and replaced with the template.

### B3: Shared Skills Distribution

The shared skills system MUST satisfy:

1. There is exactly ONE physical directory containing all skills: `~/dotfiles/shared/skills/`.
2. Every agent's skills configuration path is a symlink pointing to this single directory.
3. When a skill is installed or updated via any agent's skill installer, the change is instantly visible to all agents (because they all read from the same physical directory).
4. A skill MUST have a `SKILL.md` with frontmatter containing at minimum `name` and `description`.
5. Skills MAY include cross-agent frontmatter fields: `metadata.short-description` (for Codex and Pi) and `allowed-tools` (for Claude Code).

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
2. `models.json` MUST define providers with `baseUrl`, `api`, `apiKey` (env var reference), and model arrays specifying `id`, `name`, `contextWindow`, `maxTokens`, and optional flags `reasoning`, `input`, and `api` (for per-model API overrides).
3. Extensions are loaded from `~/.pi/agent/extensions/`, where each extension directory is a symlink to the dotfiles repo.

#### B4.4: Gemini CLI Configuration

1. `settings.json` MUST set `ide.enabled` to `true`, `security.auth.selectedType` to `"oauth-personal"`, and `general.disableAutoUpdate` to `false`.
2. Custom commands MUST be TOML files under `commands/` containing a `prompt` field.
3. Agent definitions MUST be Markdown files under `agents/`.

#### B4.5: Copilot CLI Configuration

1. The agent config directory (`~/.config/copilot/`) receives symlinks for `commands/`, `agents/`, and `skills/`.
2. No settings file is currently managed — Copilot CLI uses its own auth flow.

### B5: Pi Extensions

#### B5.1: Subagent Extension

The subagent extension registers six tools:

| Tool | Behavior | Blocking |
|------|----------|----------|
| `subagent_run` | Run subagent(s) synchronously in single, parallel, or chain mode | Yes |
| `subagent_fork` | Start background job(s); returns immediately with job IDs | No |
| `subagent_status` | List all jobs or show specific job status | No (query) |
| `subagent_results` | Get full output of a completed job | No (query) |
| `subagent_wait` | Block until a specific job completes | Yes |
| `subagent_cancel` | Cancel one or all running jobs | No |

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

**Model routing rules:**

10. When `subagentModelRouting` is present in Pi's `settings.json`, the extension MUST read it and inject a markdown table into the tool descriptions of `subagent_run` and `subagent_fork`. The table MUST include columns for category, description, model, provider, thinking, and rationale.
11. The LLM MUST select a routing category from the table and use the prescribed `model`, `provider`, and `thinking` values in the subagent call. Deviation from the routing table requires explicit justification in the call.
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

1. The current working directory MUST be mounted read-write at its original path inside the container.
2. Pi agent state (sessions, auth, settings, models, skills, extensions) MUST be mounted into the container under the container user's home directory (`/home/{HOST_USER}/`, not `/root/`).
3. The container MUST run as the host user (`--user UID:GID`) so that files written to mounted volumes are owned by the host user, not root.
4. The `HOME` environment variable inside the container MUST be set to `/home/{HOST_USER}/` so that tools (git, ssh, pi) resolve the correct home directory.
5. The Dockerfile MUST create a user matching the host username, UID, and GID at build time via `HOST_USER`, `HOST_UID`, and `HOST_GID` build arguments, ensuring `/etc/passwd` has a proper entry for git and other tools that require a username.
6. API key environment variables MUST be forwarded to the container: the well-known keys (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GOOGLE_API_KEY`, `GEMINI_API_KEY`) if set, plus any environment variables matching the patterns `*_API_KEY`, `*_API_TOKEN`, or `*_APIKEY`.
7. Extra directories specified as positional arguments MUST be mounted read-only by default; the read-write flag switches to read-write.
8. The script MUST auto-rebuild the Docker image if the installed Pi version in the image label doesn't match the latest npm version.
9. `--no-rebuild` skips the version check; `--build` forces a build.
10. Container MUST run as ephemeral (removed on exit). Recommended resource allocation is 8g memory, 4 CPUs, and 512 PIDs, but these limits are NOT enforced by the `pis` command — they are applied only when running under the Ralph sandbox mode.

### B8: Ralph Agentic Loop

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

Two shared agent roles are defined for use across agents that support them:

#### B9.1: Test Quality Verifier

1. MUST discover the project's language, test framework, and configuration.
2. MUST identify vague assertions — tests that would pass with any truthy/non-nil return value.
3. MUST run project-configured coverage tools when available; use advisory thresholds (80% lines, 70% branches, 80% functions) when project thresholds are absent.
4. MUST output a structured report with files scanned, issues found/fixed, tests added, coverage metrics, and pass/fail result with reasons.

#### B9.2: Playwright Visual QA

1. MUST verify `playwright-cli` is available before starting.
2. MUST navigate to the target URL, capture viewport and full-page screenshots, dump accessibility snapshots, and check for console/network errors.
3. MUST classify issues by severity: high (broken functionality, critical a11y failure), medium (layout issues, missing alt text), low (minor spacing, deprecation warnings).
4. MUST output a structured Visual QA Report with URL, viewport, screenshots, issues table, accessibility summary, console summary, and network summary.

### B10: Modular Installation

The install script supports module-based installation:

1. Agent modules: `codex`, `claude`, `pi`, `pi_sandbox`, `gemini`, `copilot`.
2. Module dependencies MUST be resolved automatically (e.g., `pi` requires `nodejs`, `claude` requires `curl`).
3. The user MAY choose a profile (Full, Minimal, Work, Custom) or specify modules directly.
4. The `--modules` flag accepts a comma-separated list of module names.
5. Installing an agent module MUST install the agent binary, create the config directory, and deploy all symlinks.

### B11: Agent Settings

| Agent | Settings File | Key Settings |
|-------|---------------|--------------|
| Codex | `config.toml` (copy, not symlink) | `multi_agent = true`, `apps = true`, agent role definitions |
| Claude | `settings.json` (symlink) | `DISABLE_AUTOUPDATER`, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`, statusline command |
| Pi | `settings.json` (symlink) | `enableSkillCommands`, `defaultProvider`, `defaultModel`, `defaultThinkingLevel`, `subagentModelRouting` |
| Pi | `models.json` (symlink) | Provider definitions with models, context windows, API compatibility flags |
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

---

## Implementation Notes

1. **Symlink resilience**: All symlink operations use the three-way pattern (if symlink → remove, if file → backup then link, if absent → create link). This ensures idempotent re-runs without data loss.

2. **Copy vs symlink for runtime-mutable config**: Codex `config.toml` is copied (not symlinked) because the agent writes machine-specific values at runtime (e.g., `personality`, trusted project paths). The `CODEX_CONFIG_TEMPLATE_MODE` variable controls overwrite behavior.

3. **fnm independence**: Installing agents with the `NPM_GLOBAL_PREFIX` prefix puts binaries in `~/.local/bin/`, which is outside fnm's managed path. This means switching Node versions with fnm does not remove or break agent installations.

4. **Shared skills single source**: Because all agent skill directories are symlinks to the same physical directory (`~/dotfiles/shared/skills/`), any skill added by any agent's installer is instantly available to all agents. This eliminates the need for skill synchronization.

5. **Pi subagent isolation**: Subagent processes are spawned as separate Pi child processes with isolation flags. Each subagent gets its own context window and system prompt. Extensions are NOT loaded by default in subagents (explicit opt-in required).

6. **Pi sandbox security**: The sandbox uses network isolation when running under Ralph's Docker sandbox mode — a dedicated network (`sandbox-net`) with iptables rules that allow only DNS and specific service endpoints. The standalone `pis` command runs containers on the default Docker network without resource limits or network isolation.

7. **Ralph loop resilience**: The `loop.sh` script handles container crashes (exit code 137 for OOM, 124 for timeout) by logging the error and continuing to the next iteration. The orchestrator monitors progress every 5 minutes and can inject course corrections by appending to `PROMPT.md`.

8. **Agent .gitignore hygiene**: Each agent config directory includes a `.gitignore` that excludes credentials, history, session data, and local runtime files. Sensitive files MUST remain local-only and NEVER be committed.

9. **Pi model persistence**: The `inherit-last-model` extension writes to a temp file on every model change, ensuring that even if Pi crashes before a `/new` command, the last-selected model is still available for restoration.

10. **Extension symlink pattern**: Pi extensions are symlinked as directories (not individual files), ensuring the extension's source code and compiled artifacts live in the dotfiles repository while appearing at the expected path in `~/.pi/agent/extensions/`.

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

**TS-AIAGT-003**: Shared skills single source verification
Category: Integration
Priority: Critical
Preconditions: Fresh install completed for all five agents
Input: Read the symlink target of `~/.claude/skills`, `~/.pi/agent/skills`, `~/.agents/skills`, `~/.gemini/skills`, `~/.config/copilot/skills`
Expected Output: All five paths resolve to the same physical directory: `~/dotfiles/shared/skills/`.

**TS-AIAGT-004**: Skill availability across agents
Category: Integration
Priority: High
Preconditions: A new skill is added to `~/dotfiles/shared/skills/my-skill/SKILL.md`
Input: Check skill availability from each agent
Expected Output: The new skill is immediately visible to all five agents without any additional installation steps.

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
Expected Output: Returns immediately with job ID; job runs in background; completion notification is sent via steer message.

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

**TS-AIAGT-018**: Subagent cancel — cancel all
Category: Unit
Priority: Medium
Preconditions: 3 background jobs running
Input: `subagent_cancel` with `all: true`
Expected Output: All 3 jobs are cancelled; `subagent_status` shows no running jobs.

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

**TS-AIAGT-025**: Subagent model routing — prescriptive model selection
Category: Unit
Priority: Critical
Preconditions: Pi settings.json contains `subagentModelRouting` with all five categories; the LLM invokes `subagent_run` with a scouting task
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
Preconditions: Pi settings.json contains `subagentModelRouting` with all five categories
Input: Pi starts a new session
Expected Output: The `subagent_run` and `subagent_fork` tool descriptions include a markdown table with columns: category, description, model, provider, thinking, rationale; the table contains entries for scout, planner, reviewer, implementer, and specialist.

---

## Changelog

| Version | Date | Summary |
|---------|------|---------|
| 1.0.0 | 2026-05-01 | Initial specification extracted from brownfield codebase. Covers all five agents, shared skills, Pi extensions (subagent, inherit-last-model, web-search), Pi sandbox, Ralph agentic loop, agent role definitions, symlink deployment, and error handling. |
| 1.1.0 | 2026-05-01 | Added subagent model routing: prescriptive model selection via `subagentModelRouting` in Pi settings, injected into subagent tool descriptions. Added data structure, behavior rules, error handling, and test scenarios. |
| 1.2.0 | 2026-05-01 | Pi sandbox runs as host user (not root): Dockerfile creates host user via build args, `pis` script passes `--user` flag and mounts agent state under `/home/{HOST_USER}/`. Files written by the container are now owned by the host user. |
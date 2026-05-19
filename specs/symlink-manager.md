# Symlink Manager

> **Version**: 1.1.0
> **Last Updated**: 2026-05-19
> **Depends On**: [Parameters](parameters.md), [Ubiquitous Language](UBIQUITOUS_LANGUAGE.md)
> **Depended By**: [AI Agent Config](ai-agent-config.md), [Install Orchestrator](install-orchestrator.md), [Neovim Config](neovim-config.md)

---

## Overview

The Symlink Manager is responsible for deploying configuration files from the dotfiles repository to their expected locations on the filesystem by creating symbolic links. It ensures that every configuration file lives in exactly one canonical source — the version-controlled repository — and that the system path points to that source via a symlink.

The system MUST handle three concerns:

1. **Conflict resolution** — deciding what to do when the target path already exists (symlink, regular file, or directory)
2. **Backup management** — preserving existing non-symlink files before replacing them
3. **Idempotent deployment** — producing the same result whether run once or many times, without data loss

The Symlink Manager is not a standalone program. It is a behavioral contract embedded within the install orchestrator. Every module that creates symlinks MUST adhere to the rules defined here.

---

## Dependencies

### Technology Dependencies

- A POSIX-compliant filesystem that supports symbolic links
- A facility for creating symbolic links, including forced replacement of existing links
- A facility for generating timestamps with second granularity
- A facility for recursively creating parent directories

### Spec Dependencies

- **[Parameters](parameters.md)** — defines `BACKUP_TIMESTAMP_FMT` used in backup filenames
- **[Ubiquitous Language](UBIQUITOUS_LANGUAGE.md)** — defines terms: *symlink*, *deploy*, *backup*, *dotfiles*, *idempotent*, *agent config*, *shared skills directory*, *custom layer*, *kickstart*

---

## Parameters

All parameters referenced here are defined and rationalized in [Parameters](parameters.md).

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `BACKUP_TIMESTAMP_FMT` | %Y%m%d_%H%M%S | Format for timestamped backup filenames; ensures chronological sortability and second-granularity collision avoidance |

### Local Parameters

| Parameter | Value | Unit | Rationale |
|-----------|-------|------|-----------|
| `SYMLINK_FORCE_FLAG` | true | toggle | When an existing symlink is found at the target path, the system removes it before creating the new symlink, rather than requiring manual removal |
| `BACKUP_SUFFIX_SEPARATOR` | `.backup.` | string | Delimiter between original filename and timestamp in backup names; unambiguous, unlikely to collide with real filenames |

---

## Data Structures

### Symlink Mapping

The complete set of symlink deployments the system MUST establish. Each entry defines a source location within the dotfiles repository and a target location on the filesystem.

| Category | Target Path | Source Path (within dotfiles repo) | Deployment Type | Condition |
|----------|-------------|-------------------------------------|-----------------|-----------|
| **Tmux** | ~/.tmux.conf | tmux/.tmux.conf | replace-symlink | Always |
| **Neovim** | ~/.config/nvim/lua/custom | nvim/custom | replace-symlink (directory) | Always |
| **Lazygit** | ~/.config/lazygit/config.yml (Linux) or ~/Library/Application Support/lazygit/config.yml (macOS) | lazygit/config.yml | replace-symlink | Always |
| **Yazi** | ~/.config/yazi/yazi.toml | yazi/yazi.toml | replace-symlink | Source file must exist |
| **Yazi** | ~/.config/yazi/keymap.toml | yazi/keymap.toml | replace-symlink | Source file must exist |
| **Yazi** | ~/.config/yazi/theme.toml | yazi/theme.toml | replace-symlink | Source file must exist |
| **Zsh** | ~/.zshrc | — | append-source | Always (see Behavior section) |
| **Claude Code** | ~/.claude/commands | claude/commands | replace-symlink (directory) | Always |
| **Claude Code** | ~/.claude/agents | claude/agents | replace-symlink (directory) | Always |
| **Claude Code** | ~/.claude/skills | shared/skills | replace-symlink (directory) | Always |
| **Claude Code** | ~/.claude/settings.json | claude/settings.json | replace-symlink | Source file must exist |
| **Claude Code** | ~/.claude/statusline.sh | claude/statusline.sh | replace-symlink | Source file must exist |
| **Pi** | ~/.pi/agent/skills | pi/skills | replace-symlink (directory) | Always |
| **Pi** | ~/.pi/agent/settings.json | pi/settings.json | replace-symlink | Source file must exist |
| **Pi** | ~/.pi/agent/models.json | pi/models.json | replace-symlink | Source file must exist |
| **Pi** | ~/.pi/agent/extensions/subagent | pi/extensions/subagent | replace-symlink (directory) | Always |
| **Pi** | ~/.pi/agent/extensions/web-search | pi/extensions/web-search | replace-symlink (directory) | Always |
| **Pi** | ~/.pi/agent/extensions/inherit-last-model | pi/extensions/inherit-last-model | replace-symlink (directory) | Always |
| **Codex** | ~/.codex/config.toml | codex/config.toml | copy-from-template | Always (see Behavior section) |
| **Codex** | ~/.codex/agents | codex/agents | replace-symlink (directory) | Always |
| **Codex** | ~/.codex/AGENTS.md | codex/AGENTS.md | replace-symlink | Source file must exist |
| **Codex** | ~/.agents/skills | shared/skills | replace-symlink (directory) | Always |
| **Gemini** | ~/.gemini/settings.json | gemini/settings.json | replace-symlink | Always |
| **Gemini** | ~/.gemini/commands | gemini/commands | replace-symlink (directory) | Always |
| **Gemini** | ~/.gemini/agents | gemini/agents | replace-symlink (directory) | Always |
| **Gemini** | ~/.gemini/skills | shared/skills | replace-symlink (directory) | Always |
| **Copilot** | ~/.config/copilot/commands | copilot/commands | replace-symlink (directory) | Always |
| **Copilot** | ~/.config/copilot/agents | copilot/agents | replace-symlink (directory) | Always |
| **Copilot** | ~/.config/copilot/skills | shared/skills | replace-symlink (directory) | Always |
| **Pi Sandbox** | ~/.local/bin/pis | pi/pis.sh | replace-symlink | Always |

### Deployment Types

| Type | Description | Backup before deploy? |
|------|-------------|-----------------------|
| **replace-symlink** | Remove any existing symlink or non-symlink file at target; create new symlink pointing to source. Backs up non-symlink files. | Yes, if target is a non-symlink file |
| **replace-symlink (directory)** | Same as replace-symlink but the target and source are directories. Backs up existing non-symlink directories. | Yes, if target is a non-symlink directory |
| **copy-from-template** | Copy the source file to the target location. This is NOT a symlink — the target is an independent local file. | Yes, if target exists and is not a symlink (mode-dependent; see Behavior) |
| **append-source** | Append a source directive to the target file. Does not create a symlink. Never backs up. | No |

### Conflict Classification

| Conflict Type | Condition | Action |
|---------------|-----------|--------|
| **No conflict** | Target path does not exist | Create symlink |
| **Symlink exists** | Target path is a symlink (to any target) | Remove symlink, create new symlink |
| **Regular file exists** | Target path is a regular file | Back up file with timestamp, create symlink |
| **Directory exists** | Target path is a directory (non-symlink) | Back up directory with timestamp, create symlink |
| **Symlink to wrong target** | Target path is a symlink pointing somewhere other than the dotfiles source | Remove symlink, create new symlink (treated same as any existing symlink) |

---

## Behavior

### Core Deployment Rules

**Rule 1: Idempotent deployment.** Running the deploy operation multiple times for the same mapping MUST produce the same filesystem state as running it once. If a correct symlink already exists at the target, the operation MUST leave it unchanged.

**Rule 2: No data loss.** When a non-symlink file or directory exists at the target path, the system MUST back it up before replacing it. Backups MUST include the original filename, the backup suffix separator, and a timestamp. The system MUST NOT delete any user data without creating a backup first.

**Rule 3: Source existence check.** For mappings marked with the condition "Source file must exist", the system MUST verify that the source file exists in the dotfiles repository before creating the symlink. If the source does not exist, the system MUST skip that mapping without error.

**Rule 4: Parent directory creation.** The system MUST ensure that all parent directories on the target path exist before attempting to create a symlink. Missing parent directories MUST be created recursively.

**Rule 5: Directory symlink handling.** When the source is a directory, the symlink MUST point to the directory itself (creating a directory-level symlink), NOT to individual files within the directory. This ensures the dotfiles repository remains the single source of truth for all files under that directory.

### Backup Strategy

```
WHEN deploying a target path:
  IF target is a symlink THEN
    Remove the symlink
  ELSE IF target is a regular file THEN
    Rename target to "{target}.backup.{timestamp}"
  ELSE IF target is a directory (non-symlink) THEN
    Rename target to "{target}.backup.{timestamp}"
  END IF
  Create symlink from target to dotfiles source
END WHEN
```

**Backup naming convention**: `{original_name}.backup.YYYYMMDD_HHMMSS`

The timestamp uses the `BACKUP_TIMESTAMP_FMT` parameter value. This ensures:
- Backups are chronologically sortable
- Multiple backups of the same file do not collide (second granularity)
- The original filename is preserved in the backup name for easy identification

### Special Deployment Behaviors

#### Zsh Configuration (append-source)

The zsh configuration uses an **append-source** deployment type. Rather than symlinking the entire `.zshrc`, the system appends a conditional source directive to the existing `.zshrc`:

```
IF ".zshrc" exists AND does not contain the source directive THEN
  Append the source directive block to the end of .zshrc
ELSE
  Skip (the source directive is already present)
END IF
```

The source directive MUST be wrapped in a conditional that checks for file existence before sourcing. This prevents errors if the dotfiles repository is moved or removed.

#### Codex Configuration (copy-from-template)

The Codex CLI configuration uses a **copy-from-template** deployment type instead of a symlink. This is because the Codex CLI writes machine-specific and project-specific values to its configuration file, which must remain local and not flow back to the dotfiles repository.

**Template modes**:

| Mode | Behavior |
|------|----------|
| **preserve** (default) | If a local config file exists and is not a symlink, keep it unchanged. If it is a symlink, convert it to a local copy. If no file exists, copy from the template. |
| **overwrite** | Always replace the local config with a fresh copy from the template. Back up any existing file before replacing. |

The mode is controlled by a runtime parameter (`CODEX_CONFIG_TEMPLATE_MODE`) that defaults to `preserve`. In preserve mode, the system additionally converts an existing symlink to a regular file copy, ensuring the local config is never a symlink that could leak local changes back to the repository.

#### Claude Code Statusline Deployment

The Claude Code statusline script uses a conditional deployment: the symlink is only created if the source file exists in the dotfiles repository. This allows the statusline to be optional — if it is not present in the repo, the system silently skips it.

#### Pi Extensions Deployment

Pi extensions use directory symlinks from `~/.pi/agent/extensions/{name}` to the dotfiles source. Parent directories MUST be created before the symlink. The system creates the `~/.pi/agent/extensions/` directory tree if it does not exist.

#### Lazygit Platform Path

The lazygit configuration target path varies by operating system:
- On Linux: `~/.config/lazygit/config.yml`
- On macOS: `~/Library/Application Support/lazygit/config.yml`

The system MUST detect the current OS and use the appropriate path.

#### Neovim Custom Layer Deployment

The neovim custom layer has special handling:

1. If `~/.config/nvim/lua/custom` already exists as a symlink, remove it
2. If `~/.config/nvim/lua/custom` exists as a non-symlink directory, back it up with a timestamp and remove it
3. Create a symlink from `~/.config/nvim/lua/custom` to the dotfiles custom layer source

Additionally, if the kickstart `init.lua` exists, the system MUST uncomment the custom plugin import line to ensure the custom layer is loaded. This is a text transformation on a non-symlinked file, separate from the symlink deployment.

#### Pi Sandbox Script Deployment

The Pi sandbox runner script (`pis`) is symlinked from the dotfiles repository into `~/.local/bin/`. The system MUST ensure `~/.local/bin/` exists before creating the symlink. If a non-symlink file exists at the target, it MUST be backed up before replacement.

### Shared Skills Architecture

Multiple agent configs share a single canonical skills directory through symlinks:

- `~/.claude/skills` → shared/skills
- `~/.pi/agent/skills` → shared/skills
- `~/.codex/../agents/skills` (via `~/.agents/skills`) → shared/skills
- `~/.gemini/skills` → shared/skills
- `~/.config/copilot/skills` → shared/skills

All skill directory symlinks point to the same source directory in the dotfiles repository. This means installing a skill into any one agent's skills directory immediately makes it available to all agents. This is an intentional architectural choice — the system MUST NOT break this shared reference pattern.

---

## Error Handling

| Error Case | Trigger | Detection | Response | Recovery |
|------------|---------|-----------|----------|----------|
| **Source file missing (conditional)** | A mapping with condition "Source file must exist" references a file that does not exist in the dotfiles repo | File existence check before symlink creation | Skip the mapping silently; do not create a dangling symlink | Ensure the source file exists in the dotfiles repo and re-run |
| **Source file missing (unconditional)** | A mapping with condition "Always" references a file that does not exist | File existence check or symlink creation failure | Log a warning; the symlink will be dangling | Install the corresponding module that provides the source file and re-run |
| **Parent directory creation failure** | Recursive parent directory creation fails due to permissions or filesystem errors | Creation operation returns a failure status | Halt the current module with an error; report to the orchestrator's failed module list | Fix filesystem permissions or free disk space and re-run |
| **Backup collision** | A backup file with the same timestamp already exists (extremely unlikely) | Attempt to rename the original file to the backup path fails or overwrites an existing backup | The second-granularity timestamp makes this nearly impossible; if it occurs, the newer backup silently replaces the older one | Not a concern in practice due to timestamp granularity |
| **Symlink creation failure** | Symlink creation fails due to permissions or filesystem errors | Creation operation returns a failure status | Log a warning; report to the orchestrator | Fix filesystem permissions and re-run |
| **Existing symlink points to wrong target** | A target path has a symlink pointing to a different source than expected | Not explicitly detected — treated the same as any existing symlink | Remove the existing symlink and create a new one pointing to the correct source | This is the correct behavior; re-running the deploy fixes the symlink |
| **Dotfiles repo moved or removed** | Symlinks point to a dotfiles directory that no longer exists at the expected path | Symlinks become dangling; attempting to follow them fails | Not detected by the Symlink Manager at deploy time — this is an operational concern | Move the dotfiles repo back to its expected path or re-run install from the new location |
| **Codex config symlink leakage** | The Codex config file at `~/.codex/config.toml` is a symlink instead of a regular file | Symlink test on the target path | If a symlink is detected, remove it and copy the template as a regular file (preserve mode) | This automatic conversion prevents local writes from flowing back to the repository |

---

## Implementation Notes

### Symlink Direction Convention

All symlinks point FROM a system path TO a source path within the dotfiles repository. The direction is always:

```
system_path → dotfiles_source
```

Never the reverse. This ensures that editing files in the dotfiles repository immediately takes effect, and that version control tracks the canonical source.

### Replacing Existing Symlinks

When replacing an existing symlink, the system first removes the existing symlink, then creates a new symlink pointing to the source. This is a two-step operation — there is a brief window between the removal and the creation where the target path does not exist. For non-symlink files and directories at the target path, the system backs up the existing item before removing it and creating the new symlink.

### Directory vs. File Symlink Semantics

When deploying a directory symlink (e.g., `~/.claude/agents` → `claude/agents`), the symlink covers the entire directory. Individual files within the directory are NOT separately symlinked. This means:
- Adding a file to the source directory in the dotfiles repo automatically makes it available at the target
- Removing a file from the source directory removes it from the target
- Local files created directly in the target directory (not through the symlink) will be visible but will not exist in the repository

### Module-Local Symlink Functions

Each install module (function) is responsible for its own symlink management. There is no centralized "deploy all symlinks" function. This means:
- Each module MUST follow the same conflict resolution and backup rules
- Each module MUST create its own parent directories before symlinking
- Test scenarios MUST be written to validate each module's symlink behavior independently

### Strict Error Handling Context

The installer runs in strict mode where any unhandled operation failure terminates the process. Each symlink operation MUST NOT cause an unhandled failure. The backup-and-replace pattern is designed to avoid unexpected termination: existing symlinks are explicitly removed before creating new ones, and backups are created by renaming, which is guaranteed to succeed if the source file exists.

### Conditional Source Existence

Some mappings have the condition "Source file must exist" — these are for optional configuration files that may or may not be present in the dotfiles repository. The system MUST check for source existence and skip deployment if the source is absent. Examples include `claude/settings.json`, `claude/statusline.sh`, `pi/settings.json`, and `pi/models.json`.

### Zsh Source Append Idempotency

The zsh source append is idempotent because it checks whether the source directive string already exists in `.zshrc` before appending. The check uses substring matching — it searches for the distinctive source directive pattern within the file content, which is sufficient because the pattern is specific enough to avoid false positives. The appended block MUST include a conditional guard that checks file existence before sourcing.

---

## Test Scenarios

### TS-SYMLK-001: Fresh deployment creates all symlinks correctly
Category: Integration
Priority: Critical
Preconditions: Clean home directory with no existing config files; dotfiles repo is populated
Input: Run the full install with the "full" profile
Expected Output: Every symlink in the mapping table is created; each symlink target points to the correct source within the dotfiles repository; no backup files exist since there was nothing to back up

### TS-SYMLK-002: Existing non-symlink file is backed up before replacement
Category: Integration
Priority: Critical
Preconditions: A regular file exists at `~/.tmux.conf` with user content; dotfiles repo is populated
Input: Run the tmux configuration module
Expected Output: The original `~/.tmux.conf` is renamed to `~/.tmux.conf.backup.YYYYMMDD_HHMMSS`; a new symlink is created at `~/.tmux.conf` pointing to the dotfiles source; the content of the backup file matches the original user content

### TS-SYMLK-003: Existing symlink is replaced without backup
Category: Unit
Priority: Critical
Preconditions: A symlink exists at the target path (either correct or pointing to a different target)
Input: Deploy the symlink for that target path
Expected Output: The old symlink is removed; a new symlink is created pointing to the dotfiles source; no backup file is created; the symlink correctly resolves to the dotfiles source

### TS-SYMLK-004: Existing non-symlink directory is backed up before replacement
Category: Integration
Priority: High
Preconditions: A non-symlink directory exists at `~/.claude/agents` with user content; dotfiles repo is populated
Input: Run the Claude Code module
Expected Output: The original `~/.claude/agents` directory is renamed to `~/.claude/agents.backup.YYYYMMDD_HHMMSS`; a new directory symlink is created pointing to the dotfiles `claude/agents` source; the backup directory retains all original content

### TS-SYMLK-005: Idempotent re-run leaves correct symlinks unchanged
Category: Integration
Priority: Critical
Preconditions: All symlinks are already correctly deployed from a previous run
Input: Run the same install module again
Expected Output: All symlinks remain correctly pointing to the dotfiles sources; no backup files are created; no errors are produced; the system reports success for each step

### TS-SYMLK-006: Conditional symlink skipped when source absent
Category: Unit
Priority: High
Preconditions: The dotfiles repository does not contain `claude/settings.json`
Input: Run the Claude Code module
Expected Output: The settings.json symlink is NOT created; no error is reported; all other Claude Code symlinks are created normally

### TS-SYMLK-007: Codex config template preserve mode
Category: Unit
Priority: High
Preconditions: `~/.codex/config.toml` exists as a regular file with local content
Input: Run the Codex module with `CODEX_CONFIG_TEMPLATE_MODE=preserve` (default)
Expected Output: The existing `config.toml` is left untouched; no backup is created; no symlink is created; a log message indicates the existing config is being preserved

### TS-SYMLK-008: Codex config template overwrite mode
Category: Unit
Priority: High
Preconditions: `~/.codex/config.toml` exists as a regular file with local content
Input: Run the Codex module with `CODEX_CONFIG_TEMPLATE_MODE=overwrite`
Expected Output: The existing `config.toml` is backed up with a timestamp; a fresh copy from the dotfiles template replaces it; the new file is a regular file (not a symlink)

### TS-SYMLK-009: Codex config symlink auto-converted to copy
Category: Unit
Priority: High
Preconditions: `~/.codex/config.toml` is a symlink (from a previous install version)
Input: Run the Codex module in preserve mode
Expected Output: The symlink is removed; the dotfiles template is copied as a regular file to `~/.codex/config.toml`; the file is no longer a symlink; local changes will not propagate back to the repository

### TS-SYMLK-010: Shared skills symlinks all point to same source
Category: Integration
Priority: Critical
Preconditions: Dotfiles repo is populated with shared/skills directory
Input: Run all agent modules (Claude, Pi, Codex, Gemini, Copilot)
Expected Output: All five skill directory symlinks resolve to the same canonical directory in the dotfiles repository; adding a skill file to any one of them makes it immediately visible in all others

### TS-SYMLK-011: Lazygit config uses correct platform path
Category: Unit
Priority: Medium
Preconditions: A macOS system with lazygit installed
Input: Run the TUI tools module on macOS
Expected Output: The lazygit config symlink is created at `~/Library/Application Support/lazygit/config.yml`; on Linux, it would be at `~/.config/lazygit/config.yml`

### TS-SYMLK-012: Neovim custom layer removes existing directory before symlinking
Category: Integration
Priority: High
Preconditions: `~/.config/nvim/lua/custom` exists as a non-symlink directory with user content
Input: Run the neovim configuration module
Expected Output: The existing directory is backed up to `~/.config/nvim/lua/custom.backup.YYYYMMDD_HHMMSS`; a symlink is created pointing to the dotfiles custom layer; the backup directory preserves original content

### TS-SYMLK-013: Zsh source directive appended exactly once
Category: Unit
Priority: High
Preconditions: `~/.zshrc` exists without the custom source directive
Input: Run the zsh configuration module twice
Expected Output: After the first run, the source directive is appended; after the second run, the file is unchanged (the directive appears exactly once); the source block includes a conditional file existence check

### TS-SYMLK-014: Pi extension parent directories created automatically
Category: Unit
Priority: Medium
Preconditions: `~/.pi/agent/extensions/` directory does not exist
Input: Run the Pi module
Expected Output: The `~/.pi/agent/extensions/` directory is created; the extension symlinks are created within it pointing to the correct dotfiles sources

### TS-SYMLK-015: Yazi config symlinks skipped when source files absent
Category: Unit
Priority: Medium
Preconditions: Only `yazi/yazi.toml` and `yazi/keymap.toml` exist in the dotfiles repo; `yazi/theme.toml` does not exist
Input: Run the TUI tools module
Expected Output: Symlinks are created for `yazi.toml` and `keymap.toml`; no symlink is created for `theme.toml`; no error is reported for the missing theme file

### TS-SYMLK-016: Pi sandbox script parent directory created
Category: Unit
Priority: Medium
Preconditions: `~/.local/bin/` directory does not exist
Input: Run the Pi sandbox module
Expected Output: The `~/.local/bin/` directory is created; the `pis` symlink is created within it pointing to the dotfiles `pi/pis.sh` source

### TS-SYMLK-017: Repeated backup does not overwrite previous backup
Category: Unit
Priority: Medium
Preconditions: A backup file `~/.tmux.conf.backup.20260501_120000` exists from a previous run; the current `~/.tmux.conf` is a regular file with new content
Input: Run the tmux configuration module again
Expected Output: The current file is backed up with a NEW timestamp (e.g., `~/.tmux.conf.backup.20260501_140000`); the previous backup is NOT modified; both backups exist with their respective content

### TS-SYMLK-018: Full install followed by re-run is safe and idempotent
Category: End-to-End
Priority: Critical
Preconditions: Clean system; dotfiles repo is populated
Input: Run full install, then re-run the same full install
Expected Output: First run: all symlinks created, backups made for any conflicting files. Second run: all symlinks remain correct, no new backups created, no errors, all steps report "already installed" or "already linked"

---

## Changelog

| Version | Date | Summary |
|---------|------|---------|
| 1.1.0 | 2026-05-19 | Changed Pi skills symlink source from `shared/skills` to `pi/skills` for Pi-specific skill composition |
| 1.0.0 | 2026-05-01 | Initial brownfield extraction — complete specification of symlink management behavior from existing install.sh |

# Personal Dotfiles Manager Spec Extraction Plan

> **Created**: 2026-05-01
> **Mode**: Brownfield — extracting specs from existing codebase
> **Approach**: Descriptive requirements extraction (no code references)

---

## Project Context

A personal dotfiles manager that automates setup of a Herdr-first terminal workspace with tmux retained as fallback, plus neovim and zsh, across Linux (Ubuntu/Debian) and macOS. Uses a symlink-based architecture where configs live in the version-controlled repo and symlinks deploy them to standard system locations. The install script is idempotent and safe to re-run. Primarily for personal use, but structured to serve as reference or inspiration for others.

---

## Systems to Specify

| System | Spec File | Primary Code Locations | Discovery Strategy |
|--------|-----------|----------------------|-------------------|
| Symlink Manager | symlink-manager.md | install.sh (symlink functions, backup logic) | Search for `ln -s`, `symlink`, `backup`, `link_` functions in install.sh |
| Tool Provisioning | tool-provisioning.md | install.sh (package install, OS detection, tool download) | Search for `install_package`, `apt`, `brew`, `curl`, `fnm`, `go` in install.sh |
| Shell Config | shell-config.md | zsh/.zshrc.custom | Read the entire file; it's small and self-contained |
| Tmux Config | tmux-config.md | tmux/.tmux.conf | Read the entire file; single config file |
| Neovim Config | neovim-config.md | nvim/custom/plugins/*.lua, nvim/custom/init.lua (if exists) | Enumerate all files in nvim/custom/plugins/ |
| AI Agent Config | ai-agent-config.md | codex/, claude/, pi/, gemini/, copilot/ dirs + install.sh agent section | List each agent's config files; trace symlink targets in install.sh |
| Install Orchestrator | install-orchestrator.md | install.sh (main flow, OS detection, section ordering) | Read install.sh top to bottom; map phase structure |

---

## Extraction Approach

For each system, the extracting agent MUST:

1. **Read the code** to understand current behavior
2. **Write prescriptive specs** — define what the system MUST do, phrased as requirements and rules, not as a description of what the code currently does
3. **Include no code** — no file paths, no code snippets, no implementation references. Specs are behavior contracts.
4. **Extract parameters** — any magic numbers, thresholds, or configuration values belong in parameters.md with rationale
5. **Identify error cases** — look for error handling, edge cases, and failure modes in the code
6. **Derive test scenarios** — from existing tests, from documented behavior, and from error paths discovered

---

## Authoring Order

Follow the reading order defined by the dependency graph. Foundation specs first.

1. **[ubiquitous-language.md](UBIQUITOUS_LANGUAGE.md)** — Preambled during bootstrap; refine terms discovered during extraction
2. **[parameters.md](parameters.md)** — Extract magic numbers and configuration from install.sh and config files
3. **[symlink-manager.md](symlink-manager.md)** — Extract symlink creation, backup, and conflict resolution logic
4. **[tool-provisioning.md](tool-provisioning.md)** — Extract OS detection, package installation, and tool download logic
5. **[shell-config.md](shell-config.md)** — Extract shell configuration, aliases, and PATH setup
6. **[tmux-config.md](tmux-config.md)** — Extract keybindings, nested sessions, and integration settings
7. **[neovim-config.md](neovim-config.md)** — Extract plugin system, custom layer, and Mason configuration
8. **[ai-agent-config.md](ai-agent-config.md)** — Extract agent configs, shared skills, and symlink wiring
9. **[install-orchestrator.md](install-orchestrator.md)** — Extract the top-level orchestrator flow, OS detection, and idempotency guarantees

---

## Code Mapping

### Symlink Manager

**Known paths**: install.sh (symlink-related functions and the main deploy section)

**Discovery strategy**: Search install.sh for functions containing `symlink`, `link`, `backup`, and the section that creates all symlinks

**Extraction focus**:
- Backup strategy: when and how existing files are backed up before symlinking
- Conflict resolution: what happens when a symlink already exists (correct target vs. wrong target vs. non-symlink file)
- Idempotency rules: how the script decides whether to skip, replace, or error
- Target path mapping: the complete list of symlink source → destination pairs

### Tool Provisioning

**Known paths**: install.sh (OS detection, package installation, tool downloads)

**Discovery strategy**: Search install.sh for `install_package`, `apt`, `brew`, `curl`, `fnm`, `go`, `npm`, `pip`

**Extraction focus**:
- OS detection: how the script determines Ubuntu/Debian vs macOS
- Package installation order: what must be installed before what
- Architecture detection: x86_64 vs arm64 for Go binary
- Error handling: what happens when a package install fails
- Idempotency: how the script checks if a tool is already installed

### Shell Config

**Known paths**: zsh/.zshrc.custom

**Discovery strategy**: Read the entire file; it's self-contained

**Extraction focus**:
- PATH construction: what directories are added and in what order
- Tool initialization: fnm, zoxide, and any other tool init scripts
- Alias definitions: all custom shortcuts and their targets
- SSH auto-attach: the tmux auto-attach logic for SSH sessions

### Tmux Config

**Known paths**: tmux/.tmux.conf

**Discovery strategy**: Read the entire file; it's self-contained

**Extraction focus**:
- Prefix key and keybinding mappings
- Nested session support: F12 toggle behavior and visual indicators
- Neovim integration settings (escape-time, focus-events, true color)
- Pane and window management keybindings
- Status line configuration

### Neovim Config

**Known paths**: nvim/custom/plugins/*.lua

**Discovery strategy**: Enumerate all .lua files in nvim/custom/plugins/

**Extraction focus**:
- Plugin dependency chain: which plugins depend on which
- Formatting configuration: conform.nvim setup, formatter priority rules
- LSP configuration: which servers and which file types they activate for
- Debug and test configuration: dap-go and neotest-golang setup
- Keybinding assignments: leader-key mappings across plugins

### AI Agent Config

**Known paths**: codex/, claude/, pi/, gemini/, copilot/ directories; install.sh agent section

**Discovery strategy**: List each agent directory's contents; trace symlink targets in install.sh

**Extraction focus**:
- Shared skills architecture: how the single canonical skills directory is symlinked to each agent
- Per-agent config structure: settings, agents, skills symlink targets
- Privacy boundaries: what's tracked in git vs. excluded
- Authentication patterns: how each agent expects credentials

### Install Orchestrator

**Known paths**: install.sh (top-level flow)

**Discovery strategy**: Read install.sh from top to bottom; map the phase structure and ordering

**Extraction focus**:
- Phase ordering: what runs before what and why
- Idempotency guarantees: which operations are safe to repeat
- Platform branching: where the macOS vs Linux paths diverge
- Optional features: git config prompt and other interactive sections
- Cleanup: cache and state directory management

---

## Quality Gates

After each spec is authored:

- [ ] All required sections are present (Overview through Changelog)
- [ ] No code or file path references appear in the spec
- [ ] Every parameter has a rationale
- [ ] Every behavior has at least one test scenario
- [ ] All cross-references link to existing specs
- [ ] The ubiquitous language is consistent with terms used in the spec
- [ ] Version is bumped to 1.0.0 (spec is now authoritative)

# Codex CLI Configuration

This directory contains version-controlled configuration for Codex CLI.

## Structure

```
codex/
├── config.toml                 # Base Codex config template (copied to ~/.codex/config.toml)
├── agents/                     # Agent role configs (symlinked to ~/.codex/agents/)
├── skills/                     # Skills (symlinked to ~/.agents/skills/)
├── AGENTS.md                   # Optional global instructions for Codex (symlinked to ~/.codex/AGENTS.md)
└── .gitignore                  # Prevents committing sensitive data
```

## Installation Behavior

The install script will:
- Install Codex CLI (via npm) if missing
- Create `~/.codex/config.toml` from `~/dotfiles/codex/config.toml` if missing
- Convert old `~/.codex/config.toml` symlink installs into local files
- Optionally refresh local config from template with `--codex-config-template overwrite`
- Symlink `~/.codex/agents/` → `~/dotfiles/codex/agents/`
- Symlink `~/.codex/AGENTS.md` → `~/dotfiles/codex/AGENTS.md` (optional)
- Symlink `~/.agents/skills/` → `~/dotfiles/codex/skills/`
- Preserve existing local `~/.codex/config.toml` values (for runtime keys like trusted projects)

## Privacy

Do not commit runtime data:
- `~/.codex/auth.json`
- `~/.codex/history.jsonl`
- `~/.codex/sessions/`

These remain local and are not synced.

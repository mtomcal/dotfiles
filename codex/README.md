# Codex CLI Configuration

This directory contains version-controlled configuration for Codex CLI.

## Structure

```
codex/
├── config.toml                 # Base Codex config template (copied to ~/.codex/config.toml)
├── AGENTS.md                   # Optional global instructions for Codex (symlinked to ~/.codex/AGENTS.md)
├── sync-skills.sh              # Exposes skills/codex while preserving built-ins
└── .gitignore                  # Prevents committing sensitive data
```

## Installation Behavior

The install script will:
- Install Codex CLI (via npm) if missing
- Create `~/.codex/config.toml` from `~/dotfiles/codex/config.toml` if missing
- Convert old `~/.codex/config.toml` symlink installs into local files
- Optionally refresh local config from template with `--codex-config-template overwrite`
- Symlink `~/.codex/AGENTS.md` → `~/dotfiles/codex/AGENTS.md` (optional)
- Symlink `~/.agents/skills/` → `~/dotfiles/skills/codex/`
- Symlink each Codex-specific skill into `~/.codex/skills/` while preserving Codex's built-in `~/.codex/skills/.system/`
- Preserve existing local `~/.codex/config.toml` values (for runtime keys like trusted projects)

Codex's `.system` skills mean `~/.codex/skills` cannot be a direct symlink to
`skills/codex/`. The `codex/sync-skills.sh` helper keeps the per-skill symlink
farm fresh. It runs during install and from the zsh `codex`/`cx` wrapper
functions, so dropping a new skill in `skills/codex/`
is picked up before the next Codex session starts.

Directly executing `~/.local/bin/codex` bypasses the zsh wrapper. For script or
non-zsh usage, run `~/dotfiles/codex/sync-skills.sh` first or re-run the Codex
install module to refresh the symlink farm.

## Privacy

Do not commit runtime data:
- `~/.codex/auth.json`
- `~/.codex/history.jsonl`
- `~/.codex/sessions/`

These remain local and are not synced.

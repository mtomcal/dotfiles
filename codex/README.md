# Codex CLI Configuration

This directory contains version-controlled configuration for Codex CLI.

## Structure

```
codex/
├── config.toml                 # Global Codex config (symlinked to ~/.codex/config.toml)
├── agents/                     # Agent role configs (symlinked to ~/.codex/agents/)
├── skills/                     # Skills (symlinked to ~/.agents/skills/)
├── AGENTS.md                   # Optional global instructions for Codex (symlinked to ~/.codex/AGENTS.md)
└── .gitignore                  # Prevents committing sensitive data
```

## Installation Behavior

The install script will:
- Install Codex CLI (via npm) if missing
- Symlink `~/.codex/config.toml` → `~/dotfiles/codex/config.toml`
- Symlink `~/.codex/agents/` → `~/dotfiles/codex/agents/`
- Symlink `~/.codex/AGENTS.md` → `~/dotfiles/codex/AGENTS.md` (optional)
- Symlink `~/.agents/skills/` → `~/dotfiles/codex/skills/`
- Back up any existing non-symlinked config paths with timestamps before linking

## Privacy

Do not commit runtime data:
- `~/.codex/auth.json`
- `~/.codex/history.jsonl`
- `~/.codex/sessions/`

These remain local and are not synced.


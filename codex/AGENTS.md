# Global Codex Instructions

These instructions apply to Codex CLI sessions in any repository unless overridden by a repo-local `AGENTS.md`.

## Defaults

- Prefer small, surgical changes over rewrites.
- Prefer `rg` for search and `sed`/`cat` for reads.
- Avoid destructive commands (`rm -rf`, `git reset --hard`) unless explicitly requested.
- If a task can’t be validated, say so and suggest the smallest next verification step.

## Dotfiles Conventions

- Keep secrets and histories out of git; store them only in tool-owned directories.

# Gemini CLI Configuration

Personal configuration for [Gemini CLI](https://github.com/google-gemini/gemini-cli),
Google's open-source AI agent for the terminal.

## Layout

This directory is symlinked into `~/.gemini/` by `install.sh` (`gemini` module).

| Dotfiles path | Linked to | Purpose |
|---------------|-----------|---------|
| `gemini/settings.json` | `~/.gemini/settings.json` | User settings (theme, tools, MCP servers, etc.) |
| `gemini/commands/` | `~/.gemini/commands/` | Custom slash commands (`.toml` files) |
| `gemini/agents/` | `~/.gemini/agents/` | Personal subagents (`.md` files) |
| `shared/skills/` | `~/.gemini/skills/` | Cross-agent skills (directories with `SKILL.md`) |

Sensitive runtime data (credentials, session history, browser profiles, OAuth
tokens, trusted-folders state, etc.) lives directly under `~/.gemini/` and is
excluded from version control by `.gitignore`.

## Installation

```bash
./install.sh --modules gemini
```

This installs `@google/gemini-cli` globally via npm into `~/.local` (sharing the
same prefix as Codex CLI so it survives `fnm` Node version switches), then
creates the symlinks above.

## Authentication

```bash
gemini  # First run will prompt for Google account / API key auth
```

See [Gemini CLI authentication docs](https://github.com/google-gemini/gemini-cli/blob/main/docs/get-started/authentication.md)
for OAuth, API key, and Vertex AI options.

## Adding a custom command

Custom commands are TOML files. Example: create
`gemini/commands/explain.toml`:

```toml
prompt = "Explain the following code in plain English: $ARGS"
```

Then in Gemini CLI run `/explain <your code>`.

See `~/Code/gemini-cli/docs/cli/custom-commands.md` for the full schema.

## Adding a custom agent

Drop a markdown file in `gemini/agents/`. See
`~/Code/gemini-cli/docs/core/subagents.md`.

## Global memory (`GEMINI.md`)

If you want a global instructions file, create `gemini/GEMINI.md` and add a
symlink line to `install.sh`. By default we keep instructions in the shared
`AGENTS.md` at the repo root and let Gemini's project-level discovery pick it
up via `~/.gemini/GEMINI.md` only when you opt in.

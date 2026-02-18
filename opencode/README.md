# OpenCode CLI Configuration

Lean OpenCode setup aligned with the existing Claude/Codex workflow.

## What Is Included

```
opencode/
├── commands/
│   └── ralph.md
├── agents/
│   ├── playwright-visual-qa.md
│   └── test-quality-verifier.md
├── skills/
│   ├── playwright-visual-qa/SKILL.md
│   ├── ralph/SKILL.md
│   └── test-quality-verifier/SKILL.md
├── opencode.json
├── opencode.project.json
└── .gitignore
```

## One-to-One Parity

- **Command parity**: Claude `/ralph` -> OpenCode `/ralph`
- **Agent parity**:
  - `test-quality-verifier`
  - `playwright-visual-qa`
- **Skill parity**:
  - `ralph`
  - `test-quality-verifier`
  - `playwright-visual-qa`

## Install Behavior

`./install.sh --modules opencode` now links:

- `~/.config/opencode/opencode.json` -> `~/dotfiles/opencode/opencode.json`
- `~/.config/opencode/commands/` -> `~/dotfiles/opencode/commands/`
- `~/.config/opencode/agents/` -> `~/dotfiles/opencode/agents/`
- `~/.config/opencode/skills/` -> `~/dotfiles/opencode/skills/`
- `~/.config/opencode/AGENTS.md` -> `~/dotfiles/AGENTS.md`

The installer also removes old legacy paths if present:

- `~/.config/opencode/command/`
- `~/.config/opencode/agent/`

## Authentication

```bash
opencode auth login
opencode auth list
```

Credentials remain local in `~/.local/share/opencode/` and are excluded from git.

## Usage Notes

- Run OpenCode with `oc` or `opencode`.
- Use `/ralph` for loop-job setup.
- Invoke agents directly when useful:
  - `@test-quality-verifier`
  - `@playwright-visual-qa`

## References

- https://opencode.ai/docs/commands/
- https://opencode.ai/docs/agents/
- https://opencode.ai/docs/skills/

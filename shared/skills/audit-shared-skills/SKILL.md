---
name: audit-shared-skills
description: Audit skills in shared/skills/ for cross-agent frontmatter compatibility, flagging missing fields and offering to fix them. Use when skills have been added via npx or manually and need to be checked for compatibility across Claude Code, Codex, Pi, and Copilot CLI.
metadata:
  short-description: Audit shared skills for cross-agent compatibility
allowed-tools: read,edit,bash
---

# Audit Shared Skills

Review every skill in `shared/skills/` and verify it meets the union frontmatter schema required for compatibility across all CLI agents.

## Union Schema

Every skill in `shared/skills/` should have:

| Field | Required | Used by |
|-------|----------|---------|
| `name` | yes | all agents |
| `description` | yes | all agents (max 1024 chars, include "Use when...") |
| `metadata.short-description` | yes | Codex, Pi |
| `allowed-tools` | yes | Claude Code; ignored where unsupported |

Agent-specific fields (`compatibility`, `disable-model-invocation`) are fine to keep — agents ignore fields they don't recognize.

## Process

1. **Discover all skills** — list every subdirectory of `shared/skills/` that contains a `SKILL.md`
2. **Parse frontmatter** — for each skill, read the YAML block between `---` delimiters
3. **Check each skill** against the union schema:
   - Missing `name` → error
   - Missing `description` → error
   - `description` over 1024 chars → warning
   - `description` missing "Use when" → warning
   - Missing `metadata.short-description` → error
   - Missing `allowed-tools` → error
   - `allowed-tools` grants tools the workflow never uses → warning
4. **Report** findings grouped by skill, with severity (error / warning / info)
5. **Offer to fix** each warning/error interactively — ask the user before writing changes

## Report Format

```
skill: ralph
  [ok] name
  [ok] description
  [ok] metadata.short-description
  [warn] description missing "Use when" trigger phrase

skill: some-new-skill
  [ok] name
  [error] missing description
  [warn] missing metadata.short-description
```

## Fixing

For each issue found, propose a fix and ask for confirmation before writing:
- Missing `metadata.short-description` → derive a short (≤6 word) version from `description`
- Missing `allowed-tools` → derive the smallest set needed by the workflow
- Missing `description` → ask user to provide one
- Description too long → summarize and propose a trimmed version
- Missing "Use when" → propose appending a trigger phrase based on the skill content

After all fixes are applied, re-run the audit to confirm clean.

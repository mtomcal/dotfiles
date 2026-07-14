---
name: audit-shared-skills
description: Audit skills in shared/skills/ for cross-agent frontmatter compatibility, flagging missing fields and offering to fix them. Use when skills have been added via npx or manually and need to be checked for compatibility across Claude Code, Codex, Pi, and Copilot CLI.
metadata:
  short-description: Audit shared skills for cross-agent compatibility
allowed-tools: read,edit,bash
---

# Audit Shared Skills

## Language Definitions

- **Union schema** — repository-required combination of fields across supported harnesses, distinct from one external standard.
- **Error** — violation of a required shared-skill field.
- **Warning** — portability, clarity, or least-privilege risk that remains loadable.

## Workflow

1. **Discover and parse the complete catalog.** From the repository root, run:

   ```bash
   find shared/skills -mindepth 2 -maxdepth 2 -type f -name SKILL.md -print | sort
   ```

   For every discovered file, parse the opening YAML block between standalone `---` delimiters with a YAML-aware parser. If no YAML-aware parser is available, report the audit as blocked and stop without editing or claiming a catalog result. Report missing, empty, unterminated, or unparseable frontmatter as an error; do not silently replace parsing with a regex. Record the discovered count and account for every path before continuing.

2. **Apply only the union-frontmatter checks.** This skill validates existing frontmatter, not skill-body structure, semantics, or YAGNI quality. Treat an absent, null, or empty required value as missing.

   | Field | Required | Used by |
   |-------|----------|---------|
   | `name` | yes | all agents |
   | `description` | yes | all agents |
   | `metadata.short-description` | yes | Codex, Pi |
   | `allowed-tools` | yes | Claude Code; ignored where unsupported |

   For every parseable skill, apply every condition:

   - Missing `name` → error
   - Missing `description` → error
   - `description` over 1024 characters → warning
   - `description` missing the exact phrase `Use when` → warning
   - Missing `metadata.short-description` → error
   - Missing `allowed-tools` → error
   - `allowed-tools` grants tools the workflow never uses → warning

   Agent-specific fields such as `compatibility` and `disable-model-invocation` are allowed. This step is complete only when every discovered skill has a result for all applicable checks.

3. **Report every skill and finding.** Group results by skill, show `[ok]` for passing fields, and use only `[error]` and `[warn]` for findings:

   ```text
   skill: ralph
     [ok] name
     [ok] description
     [ok] metadata.short-description
     [warn] description missing "Use when" trigger phrase

   skill: some-new-skill
     [ok] name
     [error] missing description
     [error] missing metadata.short-description
   ```

   Include the discovered and parsed counts plus total errors and warnings. Do not omit clean skills or parser failures.

4. **Propose fixes and obtain approval before editing.** Present the exact proposed change for each finding, or for an explicitly enumerated batch, then ask the user to approve it. Do not write unapproved changes.

   - Missing or malformed frontmatter → propose valid YAML while preserving recognized fields.
   - Missing `name` → propose the lowercase hyphenated directory name after checking the skill content.
   - Missing `description` → ask the user for the intended behavior and triggers.
   - Missing `metadata.short-description` → derive a version of at most six words from `description`.
   - Missing `allowed-tools` → derive the smallest set used by the workflow.
   - Description too long → propose a version of at most 1024 characters.
   - Missing `Use when` → propose a trigger phrase based on the skill content.
   - Unused tool grants → propose removing only the unnecessary grants.

   Apply only approved fixes. Keep declined or unfixable findings in the report rather than weakening their severity.

5. **Rerun the complete audit after edits.** Repeat discovery, parsing, every check, and the full report after all approved fixes. The audit is clean only when the rerun accounts for every discovered skill and reports zero errors and zero warnings; otherwise report the unresolved findings and do not claim clean completion.

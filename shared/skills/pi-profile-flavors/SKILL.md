---
name: pi-profile-flavors
description: Build and modify Pi profile variants using pim, including extensions, profile-local skills, settings, models, agents, build, deploy, and validation. Use when creating Pi flavors such as local, coding, review-only, sandbox, loop, cheap, fast, high-reasoning, or tool-specific profiles.
metadata:
  short-description: Build Pi profile flavors
allowed-tools: read, write, edit, bash
---

# Pi Profile Flavors

## Purpose

Use this skill to shape `pi/profiles/<profile>/` variants in this dotfiles repo. A Pi profile is a source-controlled flavor of Pi runtime config with its own resolved settings, models, agents, extensions, skills, sessions, and history while sharing the installed `pi-bin` executable.

## First Checks

1. Confirm you are in the dotfiles repo root.
2. Check current profile state:
   ```bash
   pim list
   pim current
   pim doctor
   ```
3. Inspect the target profile inputs:
   ```bash
   find pi/profiles/<profile> -maxdepth 3 -type f -o -type l
   ```
4. Preserve unrelated untracked profiles or user edits. Never stage or delete a profile the user created unless explicitly asked.

## Flavor Workflow

1. Define the flavor contract in plain terms:
   - intended use: coding, local models, review-only, loop worker, cheap/fast, high-reasoning, tool-heavy, sandboxed
   - default provider/model/thinking level
   - enabled extensions
   - included profile-local skills
   - agent role overrides or additions
2. Create the profile if needed:
   ```bash
   pim create <profile>
   ```
3. Edit profile inputs only:
   - `pi/profiles/<profile>/extensions.list`
   - `pi/profiles/<profile>/settings.json`
   - `pi/profiles/<profile>/models.json`
   - `pi/profiles/<profile>/agents/`
   - `pi/profiles/<profile>/skills/`
4. Build resolved output:
   ```bash
   pim build <profile>
   ```
5. Deploy or switch:
   ```bash
   pim deploy <profile>
   pim use <profile>
   ```
6. Validate:
   ```bash
   pim doctor
   pim path <profile>
   ```

## Editing Rules

- `extensions.list` contains one extension directory name per line from `pi/extensions/`; comments and blank lines are okay.
- `settings.json` and `models.json` are full-file overrides. If absent, the profile inherits from `pi/base/`.
- `agents/` can add or override role files from `pi/base/agents/`.
- `skills/` is for profile-local skills only. Names must not duplicate `shared/skills/`; `pim build` must fail on duplicates.
- `resolved/` is generated deployable output. Do not hand-edit it; change inputs and rerun `pim build`.
- Every profile automatically includes all `shared/skills/` in resolved output.

## Common Flavor Patterns

- **local**: set `defaultProvider` to a local provider, narrow models to local defaults, keep `subagent` and `inherit-last-model`, add local-only routing notes as a profile-local skill if needed.
- **review-only**: keep reviewer agents, reduce write-capable skills, use lower default cost/turn guardrails in agent frontmatter.
- **loop worker**: enable extensions needed for orchestration, keep skills like `ralph`, `tmux-agent-orchestration`, `create-plan`, `tdd`, and `test-quality-verifier`.
- **cheap/fast**: lower default thinking, pick cheaper default models, keep high-reasoning agents available as explicit overrides.
- **tool-heavy**: enable `web-search` and profile-local skills for external workflows; verify no secret material enters profile inputs.

## Verification Checklist

Run these before finishing:

```bash
pim build <profile>
pim deploy <profile>
pim doctor
bash pi/tests/pim-cli.test.sh
bash pi/tests/profile-layout.test.sh
git diff --check
```

If a profile should be committed, include its authoring inputs and generated `resolved/` output. If it is an experimental local profile, leave it untracked and say so.

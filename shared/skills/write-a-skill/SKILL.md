---
name: write-a-skill
description: Design, create, or revise cross-agent skills for predictable invocation and execution with progressive disclosure and checkable completion criteria. Use when writing a new skill, editing an existing skill, splitting skill workflows, or auditing skill clarity and sprawl.
metadata:
  short-description: Write predictable cross-agent skills
allowed-tools: read,write,edit,bash
---

# Writing Skills

A skill should make the agent follow a predictable process, not force identical output.

## 1. Define invocation and branches

Identify the task, distinct branches, expected artifacts, required tools, and failure states. Choose a strong **leading word** already associated with the desired behavior, such as tracer bullet or tight loop.

Balance two costs:

- **Context load** — model-discoverable descriptions occupy every agent turn.
- **Human cognitive load** — explicitly requested skills must be remembered and invoked by a person.

Cross-agent reality varies: some harnesses support `disable-model-invocation`, some ignore it, and all shared skills still require a valid description. Write a precise “Use when…” description for portable discovery. Use explicit-only metadata only when the target agents support it and the human deliberately accepts reduced discovery; never rely on it as the sole cross-agent control.

Completion criterion: each genuine branch has a trigger, and duplicate synonyms do not inflate the description.

## 2. Design the information hierarchy

Put ordered actions in `SKILL.md`. Keep always-needed rules beside the step they govern. Move branch-only or detailed reference behind a clearly worded context pointer in a sibling Markdown file. Add scripts only for deterministic, repeated operations where generated commands would be less reliable.

Split into another skill only when it has an independently useful invocation or reusable workflow. Split by sequence only when visible later steps cause premature completion. Otherwise keep one source of truth.

Completion criterion: every linked reference says when to load it, relative paths resolve from the skill directory, and required instructions are not hidden behind optional wording.

## 3. Write checkable steps

Each step should specify:

1. the action and evidence to gather
2. relevant branches or failure handling
3. a **completion criterion** the agent can actually verify

Demand enough legwork to prevent premature completion: “every modified file accounted for” is stronger than “review the changes.” Prefer positive target behavior; reserve prohibitions for hard guardrails and pair them with what to do instead.

## 4. Apply cross-agent structure

Use a lowercase hyphenated directory with `SKILL.md`. Shared skills use the union frontmatter:

```yaml
---
name: skill-name
description: What it does. Use when specific trigger conditions occur.
metadata:
  short-description: Short human label
allowed-tools: read,write,bash
---
```

Keep descriptions under 1024 characters. Add references or scripts only when they earn their context pointer. Preserve license and provenance when adapting external material.

## 5. Prune and verify

Prune sentence by sentence:

- **duplication** — one meaning has multiple homes
- **sediment** — stale instructions remain after behavior changed
- **sprawl** — live detail overwhelms the main path
- **no-op** — a line does not change default agent behavior

Prefer a strong leading word over repeated explanation. Check name/description validity, frontmatter, links, script executability, examples, completion criteria, and repository-specific audit commands. For this repo, run `audit-shared-skills` and follow repository guidance for visibility links.

Completion criterion: all branches are reachable, every step has a checkable finish, references resolve one level deep, duplicated guidance is removed, and required audits pass.

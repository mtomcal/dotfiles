---
name: write-a-skill
description: Design, create, or revise cross-agent skills for predictable invocation and execution with progressive disclosure and checkable completion criteria. Use when writing a new skill, editing an existing skill, splitting skill workflows, or auditing skill clarity and sprawl.
metadata:
  short-description: Write predictable cross-agent skills
allowed-tools: read,write,edit,bash
---

# Writing Skills

## Language Definitions

- **Branch** — workflow path selected by a concrete trigger.
- **Leading word** — recognizable term that cues the intended behavior.
- **Context load** — instructions consuming model context.
- **Human cognitive load** — effort to remember, select, and invoke a skill.
- **Reference pointer** — conditional link that names a concrete branch outcome, states why support is needed, and makes the selected Reference file mandatory once the branch is true.
- **Reference file** — local Markdown support loaded only after its pointer is selected and containing only the detail necessary for that branch.
- **Successful no-load route** — a supported branch path that completes without loading the selected Reference file.
- **Progressive disclosure** — staged loading of the catalog description, invoked `SKILL.md`, and conditionally selected support.
- **Sediment** — stale instruction remaining after behavior changed.
- **Sprawl** — live detail obscuring the primary path.
- **No-op instruction** — guidance that does not change likely default behavior.

## Workflow

Use this workflow to design, create, materially revise, split, or semantically audit a skill. A skill should make the agent follow a predictable process, not force identical output.

### 1. Route invocation, revision, and splitting

Identify the task, distinct branches, expected artifacts, required tools, and failure states. Choose a strong leading word already associated with the desired behavior, such as tracer bullet or tight loop.

When materially revising an existing skill body, create a behavior-preservation ledger before restructuring. Map every trigger, branch, gate, failure, guardrail, output, ownership rule, and completion condition to its retained location or an explicitly approved replacement owner.

Balance two invocation costs:

- **Context load** — model-discoverable descriptions occupy every agent turn.
- **Human cognitive load** — explicitly requested skills must be remembered and invoked by a person.

Cross-agent reality varies: some harnesses support `disable-model-invocation`, some ignore it, and all shared skills still require a valid description. Write a precise “Use when…” description for portable discovery. Use explicit-only metadata only when the target agents support it and the human deliberately accepts reduced discovery; never rely on it as the sole cross-agent control.

Keep one source of truth by default. Split into another skill only when it has an independently useful invocation or reusable workflow. Split a sequence only when visible later steps cause premature completion. Otherwise keep branches inside one primary Workflow.

Completion criterion: each genuine branch has a concrete trigger, duplicate synonyms do not inflate the description, any proposed split passes one of the stated tests, and any material revision has a complete behavior-preservation ledger.

### 2. Design the body and disclosure

Use only the semantic sections the skill earns, in this order:

1. `Language Definitions` is mandatory and contains only execution-relevant skill-local terms, or the exact statement “No skill-specific terms.”
2. `Workflow` is optional and contains at most one primary end-to-end process, with routing or mode selection first.
3. `Activities` is optional and contains independently reusable commands, actions, or recipes selected outside the required end-to-end sequence; it does not restate ordinary Workflow steps.
4. `Reference` is optional and contains only branch-specific Reference pointers. Each pointer must name the concrete branch outcome that selects it, say why the target is necessary, give enough routing information to choose the branch before loading, and point to a local Markdown file one level deep from the skill directory.

Omit optional sections the behavior does not require. Put ordered main-path actions in `Workflow` when a process exists. Keep always-needed rules beside the Workflow step or Activity they govern. Move only branch-specific or detail-heavy material behind a clearly worded Reference pointer in a sibling Markdown file, while retaining a compact executable contract inline. Keep scripts, templates, and composed skills beside the governing Workflow step or Activity instead of in Reference. Once the branch outcome is true, loading the selected target becomes mandatory. Required instructions must not hide behind optional wording.
Add scripts only for deterministic, repeated operations where generated commands would be less reliable. Keep one source of truth for each behavior.

Completion criterion: every included section earns its role, every Reference pointer names a concrete branch outcome, states when and why to load its target, preserves at least one successful supported no-load route, relative paths resolve one level deep from the skill directory, and the required main path remains executable without conditionally loaded support.

### 3. Write checkable behavior

Each Workflow step or Activity should specify:

1. the action and evidence to gather;
2. relevant branches or failure handling; and
3. a completion criterion the agent can actually verify.

Keep guardrails, failures, approvals, output contracts, and completion criteria beside the step or Activity they govern. Demand enough legwork to prevent premature completion: “every modified file accounted for” is stronger than “review the changes.” Prefer positive target behavior; reserve prohibitions for hard guardrails and pair them with what to do instead.

Completion criterion: every step or Activity has an observable finish, and its governing branches, failures, guardrails, approvals, and outputs are local rather than hidden elsewhere.

### 4. Apply cross-agent structure and provenance

Use a lowercase hyphenated directory with `SKILL.md`. Shared skills use the existing union frontmatter:

```yaml
---
name: skill-name
description: What it does. Use when specific trigger conditions occur.
metadata:
  short-description: Short human label
allowed-tools: read,write,bash
---
```

Keep descriptions under 1024 characters. Before moving or rewriting imported material, identify its source, revision, and license; preserve required attribution and license text in the repository-level provenance notice.

Completion criterion: the directory and frontmatter satisfy the repository contract, and every imported source is accounted for before its material changes.

### 5. Apply semantic YAGNI and verify

Prune sentence by sentence according to behavioral value, never a fixed line target:

- **duplication** — one meaning has multiple homes;
- **sediment** — stale instructions remain after behavior changed;
- **sprawl** — live detail overwhelms the main path; and
- **no-op** — a sentence does not change likely default behavior.

Prefer a strong leading word over repeated explanation. Retain content when it changes invocation or routing, workflow correctness, reusable Activity execution, guardrails or failure handling, output or artifact contracts, or required cross-agent or repository behavior.

Check name and description validity, the existing union frontmatter, canonical section order and semantics, links, script syntax and executability, examples, completion criteria, behavior-preservation coverage, provenance, and repository-specific audit commands. For this repo, run `audit-shared-skills` under the existing union schema and follow repository guidance for visibility links.

Completion criterion: all branches are reachable; every Workflow step and Activity has a checkable finish; required behavior remains inline or names an approved replacement owner; references resolve one level deep; duplicated guidance is removed; every modified file is accounted for; and required audits pass.

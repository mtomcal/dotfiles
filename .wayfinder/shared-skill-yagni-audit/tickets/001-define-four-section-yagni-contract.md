---
id: WF-001
type: grilling
status: resolved
blocked-by: []
---

# Define the four-section YAGNI contract

## Question
What body structure and YAGNI standard should govern the shared-skill audit without forcing artificial uniformity?

## Why it matters
Every per-skill recommendation needs the same semantic distinctions and retention test before skills can be compared consistently.

## Completion evidence
The user confirms section requirements, section boundaries, YAGNI retention criteria, audit scope, and explicit exclusions after those choices are checked against current skills and repository contracts.

## Resolution
The audit uses four canonical level-two sections in this order:

1. `Language Definitions` is mandatory and defines only skill-specific operational terms. When a skill has none, it says so explicitly rather than copying project-domain vocabulary.
2. `Workflow` is optional and contains at most one primary end-to-end process. Routing and mode selection occur at its beginning; independently invocable processes should become separate skills rather than additional workflows.
3. `Activities` is optional and contains independently reusable commands, actions, or recipes. It is not a restatement of Workflow steps. Activity-oriented skills such as `herdr` may omit Workflow.
4. `Reference` is optional and points to load-on-demand Markdown covering domain knowledge, schemas, templates, API details, or extended examples. Each pointer states when to load it.

Guardrails, failure handling, completion criteria, and output contracts remain beside the Workflow step or Activity they govern. Large supporting schemas and templates may be linked from Reference, but required main-path behavior must not be hidden there.

The YAGNI test retains content only when it changes invocation or routing, workflow correctness, reusable activity execution, guardrails or failure handling, output/artifact contracts, or required cross-agent/repository behavior. Size changes are evidence, not a fixed target.

All 33 shared skills are in scope. Valid recommendations include retain, simplify, consolidate, move detail to references, split, or retire. Imported material must preserve provenance and licensing. Frontmatter redesign and production rewrites are out of scope.

Evidence: user decisions in the Wayfinder intake; `shared/skills/write-a-skill/SKILL.md`; `shared/skills/audit-shared-skills/SKILL.md`; `specs/ai-agent-config.md`; Pi `docs/skills.md`; structural inventory of `shared/skills/*/SKILL.md`.

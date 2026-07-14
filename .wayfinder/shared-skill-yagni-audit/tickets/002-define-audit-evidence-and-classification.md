---
id: WF-002
type: research
status: resolved
blocked-by: [WF-001]
---

# Define comparable audit evidence and classification

## Question
What compact evidence fields and skill profiles will make 33 per-skill YAGNI recommendations comparable without reducing the audit to heading or line-count compliance?

## Why it matters
The three skill-family audits need one method that preserves behavior while distinguishing workflows, activity catalogs, routers, artifact producers, and compact skills.

## Completion evidence
A reusable per-skill record format accounts for current purpose, applicable profile, required behavior, terms, workflow, activities, references, duplication, behavioral risks, size evidence, provenance, and one recommendation with rationale. The method explicitly handles fenced examples and does not mistake subheadings for top-level structure.

## Resolution
Use one semantic profile and one disclosure posture per skill.

### Profiles

- **Ordered workflow** — one required end-to-end sequence; branches remain inside that Workflow.
- **Routed workflow** — one routing decision selects a mode at the beginning, then the selected branch runs as the Workflow.
- **Activity catalog** — independently selected commands or recipes with no required end-to-end order; Workflow may be absent.
- **Artifact workflow** — an ordered producer or reviewer whose output shape and acceptance contract are central; keep those contracts beside the producing step or Activity.

A profile is an audit lens, not permission to add another top-level section. Reclassify a skill when its evidence contradicts the candidate grouping in later tickets.

Record a separate disclosure posture:

- **Self-contained** — extracting detail would add more indirection than context savings.
- **Progressively disclosed** — supporting detail already has, or clearly earns, a conditional pointer.
- **Overloaded** — independently useful behavior, duplicated detail, or branch-only material obscures the main path.

“Compact” is evidence for self-containment, not a profile or line threshold.

### Per-skill audit record

Each skill receives this compact record:

```markdown
### <skill-name>
- Profile / disclosure: <profile>; <posture>
- Authorities: <frontmatter trigger; relevant spec or none; provenance; supporting files>
- Baseline: <lines; words; level-two headings outside fences; Markdown references>
- Behavior ledger:
  - Language: <skill-local terms, duplicated project terms, or none>
  - Workflow/routing: <ordered path, gates, branches, completion evidence, or none>
  - Activities: <independently selectable operations or none>
  - Inline contracts: <guardrails, failures, outputs, ownership, user approvals>
  - Reference: <current and candidate conditional material or none>
- YAGNI findings: <exact duplication, sediment, sprawl, or no-op evidence; or none>
- Recommendation: <one primary verdict and proposed Language Definitions / Workflow / Activities / Reference shape>
- Preservation and risk: <where every affected behavior goes; dependencies; confidence>
```

The primary verdict is one of: **retain**, **simplify inline**, **move detail to Reference**, **consolidate/delegate**, **split**, or **retire**. A verdict may list subordinate moves, but every skill has exactly one primary recommendation.

### Decision rules

1. Read frontmatter, the complete `SKILL.md`, directly linked Markdown, applicable specs, and provenance before judging.
2. Count headings only outside frontmatter and fenced examples. Heading conformity alone is never evidence of quality.
3. Map every trigger, branch, gate, failure state, guardrail, output, approval, ownership rule, and completion condition before recommending removal or relocation.
4. Require `Language Definitions` in the proposed shape. Define only execution-relevant skill-local terms; otherwise state that no skill-specific terms exist.
5. Treat Workflow, Activities, and Reference as optional semantic sections. Do not invent Activities from ordinary Workflow steps or extract required main-path behavior behind optional wording.
6. Use line and word counts only as before/after context evidence. A move earns progressive disclosure only when its load condition is clear and the reduced main path remains independently executable.
7. Record suspected cross-skill duplication and a candidate owner, but defer catalog-wide ownership decisions to WF-006.
8. Preserve repository-required frontmatter, provenance, licensing, relative-link integrity, and behavior contracted by `specs/ai-agent-config.md`.
9. Treat new, changed, duplicated, or ambiguous Language Definitions as candidates until a human confirms them one skill at a time after the family audits. Do not require individual confirmation when the complete result is “No skill-specific terms.”

Evidence: structural inventory of all 33 `shared/skills/*/SKILL.md` files (3,000 lines, 21,517 words, median 65 lines); representative ordered, routed, activity, artifact, compact, and overloaded skills; `shared/skills/write-a-skill/SKILL.md`; `shared/skills/audit-shared-skills/SKILL.md`; `specs/ai-agent-config.md`; `specs/UBIQUITOUS_LANGUAGE.md`; `THIRD_PARTY_NOTICES.md`; and Pi `docs/skills.md`. Pi documents freeform skill bodies and progressive disclosure, while the repository spec supplies the behavioral and cross-agent preservation contract.

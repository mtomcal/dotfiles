# Shared Skill YAGNI Audit Wayfinder Map

## Destination
Produce a decision-ready audit rubric and evidenced recommendation for each of the 33 skills in the shared skills directory, using the confirmed four-section contract and YAGNI test. The result must be ready to route into specification updates and an implementation plan without rewriting skills during this effort.

## Context and notes
- Relevant specs: `specs/UBIQUITOUS_LANGUAGE.md`, `specs/ai-agent-config.md`, and `AGENTS.md`.
- Relevant code and guidance: `shared/skills/write-a-skill/SKILL.md`, `shared/skills/audit-shared-skills/SKILL.md`, Pi's `docs/skills.md`, and all `shared/skills/*/SKILL.md` files.
- Baseline: 33 shared skills; current exact level-two headings include nine `Workflow`, one `Reference`, and no `Language Definitions` or `Activities` headings.
- Standing constraints: preserve required cross-agent frontmatter, provenance, licensing, behavioral contracts, and progressive disclosure. Frontmatter redesign and production rewrites are outside this effort.
- The pre-existing modification to `pi/settings.json` is unrelated and must remain untouched.

## Decisions so far
- [Define the four-section YAGNI contract](tickets/001-define-four-section-yagni-contract.md) — require skill-local Language Definitions, allow one optional Workflow plus optional Activities and Reference, colocate required rules, and judge content by behavioral value rather than line limits.
- [Define comparable audit evidence and classification](tickets/002-define-audit-evidence-and-classification.md) — audit each skill through one semantic profile, one disclosure posture, a behavior-preservation ledger, and one primary recommendation; human-confirm material Language Definition candidates before reconciliation.
- [Audit workflow-centric skills](tickets/003-audit-workflow-centric-skills.md) — all 14 skills have preservation ledgers and primary recommendations; seven retain their current substance while the rest chiefly simplify duplication or disclosure.
- [Audit activity and reference-centric skills](tickets/004-audit-activity-reference-skills.md) — `herdr`, `playwright`, and `ralph` need structural simplification, with command drift and missing provenance requiring follow-up.
- [Audit artifact, router, and compact skills](tickets/005-audit-artifact-router-compact-skills.md) — all 16 skills have recommendations that protect compact contracts while moving overloaded detail and duplicated ownership behind clearer routes or references.
- [Confirm skill Language Definitions](tickets/008-confirm-skill-language-definitions.md) — the human confirmed material language for 32 skills, revised hill climbing to mean avoidable context-loading exploration, assigned neutral diff ownership to `image-diff-describer`, and rejected the unused Info severity.
- [Reconcile cross-skill duplication and composition](tickets/006-reconcile-cross-skill-duplication.md) — assign transport, state, review, visual, artifact, language, and authoring behavior to narrow owners; retain critical local gates and split generic Git delivery from tmux orchestration.
- [Synthesize the audit and route follow-up](tickets/007-synthesize-audit-and-route-follow-up.md) — preserve 11 skills, simplify 16, disclose 4, and consolidate 2 through a durable-contract-first sequence, with Git delivery and frontmatter kept as separate follow-up lanes.

## Not yet specified
None.

## Out of scope
- Rewriting, splitting, consolidating, retiring, or otherwise implementing changes to shared skills; those changes belong in a later implementation plan.
- Redesigning cross-agent frontmatter or resolving harness-specific `allowed-tools` portability concerns; preserve the current repository contract and track those concerns separately.
- Changing agent discovery, deployment, or Pi visibility symlinks.

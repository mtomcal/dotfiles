---
name: design-md
description: Create, update, audit, and validate Google DESIGN.md files for AI coding agents from existing UI, CSS, assets, screenshots, or design direction. Use when the user asks for DESIGN.md, design.md, an agent-readable design spec, design tokens, visual design contracts, or wants UI agents to follow an existing product style.
metadata:
  short-description: Build and validate DESIGN.md files
allowed-tools:
  - read
  - bash
  - grep
  - ls
  - find
---

# DESIGN.md

## Language Definitions

- **Design contract** — agent-readable `DESIGN.md` combining machine tokens and human rules for visual identity.
- **Design token** — named reusable visual value or component rule.
- **Token reference** — `{category.name}` pointer to a declared token.
- **Orphaned token** — declared token with no current use or explained future use.

## Workflow

1. **Route first.** Select the target and mode:
   - **Create** — write a new design contract.
   - **Update** — revise one from evidence or explicit direction.
   - **Audit** — compare one with implementation and rendered evidence without editing.
   - **Validate** — lint structure; lint does not establish rendered fidelity.

2. **Extract before inventing.** For create, update, and audit, inspect applicable `AGENTS.md`, READMEs, specs, visual QA docs, CSS/themes, components, assets, screenshots, and product references. Prefer existing variables, tokens, classes, renders, and repeated patterns. Label explicit direction rather than presenting it as extracted evidence. Finish when every rule has evidence or direction.

3. **Create or update the exact artifact contract.** YAML front matter contains:
   - `version`, `name`, and optional `description`
   - `colors` as hex sRGB values
   - `typography` with `fontFamily`, `fontSize`, `fontWeight`, `lineHeight`, and `letterSpacing`
   - `rounded`, `spacing`, and `components`

   Use token references such as `{colors.primary}` and `{typography.button}`:
   - Store colors as `#` hex values and opacity as a base color token plus prose.
   - Give dimensions units where required; use `0px`, not `"0"`, for zero letter spacing.
   - Correct the model behind contrast warnings. Model colored text on a dark surface rather than falsely modeling a filled colored badge.
   - Reject orphaned tokens unless prose explains future use.
   - Focus component tokens on reusable buttons, panels, cards, nav, progress, forms, status, and major repeated surfaces.

   Write concise rationale in this exact Markdown section order:

   1. `## Overview`
   2. `## Colors`
   3. `## Typography`
   4. `## Layout`
   5. `## Elevation & Depth`
   6. `## Shapes`
   7. `## Components`
   8. `## Do's and Don'ts`

   Explain when to use patterns, what to avoid, and how agents preserve the product's visual identity. Production is complete when the token rules and section order are exact.

4. **Apply mode gates.** Each applicable gate must pass.
   - **Update:** Preserve naming unless clearly misleading and explain intent, not only changed values. When comparing versions, run `npx @google/design.md diff DESIGN.md DESIGN-v2.md`; the first path is before and the second after. Update repository guidance such as `AGENTS.md` only when needed for discovery or compliance.
   - **Audit:** Compare tokens, components, and prose with source and rendered evidence. Report mismatches and reject broad generic guidance, one-off visual trivia, copied CSS dumps, invented style, ungrounded tokens, or advice conflicting with rendered UI or project instructions. Do not edit in audit-only mode.
   - **Lint:** For create, update, audit, and validate, run `npx @google/design.md lint DESIGN.md` with the actual path when network/package access is available. Correct failures only in create or update mode; otherwise report them. If unavailable, disclose that lint did not run and do not claim lint-clean completion.

5. **Report by mode.** Return the artifact path, create/update evidence or direction, update intent and applicable diff result, audit findings, and exact lint outcome. A useful design contract is compact, specific, grounded in the actual product, and lint-clean when lint can run.

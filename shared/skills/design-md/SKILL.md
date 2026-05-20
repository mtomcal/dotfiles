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

## Quick Start

Use this skill to create or maintain a Google-style `DESIGN.md`: YAML front matter for machine-readable tokens plus Markdown sections for human-readable design rationale.

Canonical section order:

1. `## Overview`
2. `## Colors`
3. `## Typography`
4. `## Layout`
5. `## Elevation & Depth`
6. `## Shapes`
7. `## Components`
8. `## Do's and Don'ts`

## Workflow

1. Inspect existing durable context first: `AGENTS.md`, README files, specs, visual QA docs, CSS/theme files, component files, asset directories, screenshots, and product references.
2. Extract current design decisions instead of inventing a new style. Prefer existing CSS variables, theme tokens, component classes, rendered screenshots, and repeated UI patterns.
3. Write YAML front matter with exact tokens:
   - `version`, `name`, and optional `description`
   - `colors` as hex sRGB values
   - `typography` with `fontFamily`, `fontSize`, `fontWeight`, `lineHeight`, and `letterSpacing`
   - `rounded`, `spacing`, and `components`
4. Use token references in components, for example `{colors.primary}` and `{typography.button}`.
5. Write concise Markdown rationale in canonical section order. Explain when to use patterns, what to avoid, and how agents should preserve the product's visual identity.
6. Validate with the official linter when network/package access is available:

```sh
npx @google/design.md lint DESIGN.md
```

## Token Rules

- Colors must be `#` hex values. If implementation uses opacity, store the base color token and explain opacity in prose.
- Dimensions need units where the spec expects dimensions. Use `0px`, not `"0"`, for zero letter spacing.
- Component contrast warnings often mean the token is modeled incorrectly. If the UI uses colored text on a dark surface, model that rather than a filled colored badge.
- Avoid orphaned tokens unless the prose clearly explains future use.
- Keep component tokens focused on reusable surfaces: buttons, panels, cards, nav, progress, forms, status, and major repeated UI elements.

## Updating Existing DESIGN.md

When updating an existing file:

- Preserve established naming unless it is clearly misleading.
- Diff intent, not just values: explain any design direction changes in prose.
- Run `npx @google/design.md diff DESIGN.md DESIGN-v2.md` when comparing two versions.
- Update repo guidance such as `AGENTS.md` if agents need to discover or obey the design contract.

## Quality Bar

A useful `DESIGN.md` is compact, specific, lint-clean, and grounded in the actual product. Reject broad generic guidance, one-off visual trivia, copied CSS dumps, and style advice that conflicts with the rendered UI or existing project instructions.

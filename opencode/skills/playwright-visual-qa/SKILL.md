---
name: playwright-visual-qa
description: Perform browser-based visual QA via playwright-cli: screenshots, a11y snapshot, console and network checks. Pairs well with @playwright-visual-qa.
compatibility: opencode
metadata:
  short-description: Visual QA with Playwright CLI
---

# Playwright Visual QA

Use this skill to do quick, repeatable visual QA against a URL using `playwright-cli`.

## Prerequisite

Verify `playwright-cli` exists:
`command -v playwright-cli`

If missing, install it (how you do this depends on your environment). If you don't have `playwright-cli`, you can also do visual QA with any Playwright setup you already use, but this skill assumes the `playwright-cli` interface.

## Workflow

1. Navigate: `playwright-cli navigate --url "<url>"`
2. Screenshot:
   - Viewport: `playwright-cli screenshot --filename viewport.png`
   - Full-page: `playwright-cli screenshot --full-page --filename full.png`
3. Accessibility: `playwright-cli snapshot`
4. Console: `playwright-cli console`
5. Network: `playwright-cli network`
6. Report issues (layout/a11y/console/network) with severity and suggested fixes.
7. Close: `playwright-cli close`

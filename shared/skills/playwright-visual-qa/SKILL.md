---
name: playwright-visual-qa
description: "Perform browser-based visual QA via playwright-cli: screenshots, a11y snapshot, console and network checks. Pairs well with @playwright_visual_qa. Use when performing visual QA, accessibility checks, or browser-based UI verification."
allowed-tools: Bash(playwright-cli:*)
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

## Checklist-Based QA (Orchestrated)

When invoked as the `visual-qa` subagent in an orchestrated context, the workflow uses a step-by-step checklist format. The orchestrator provides a numbered list of actions and expected outcomes, and the agent executes each sequentially, producing a per-step pass/fail report with evidence.

### Checklist format

```
1. Navigate to [URL] — Expected: [what should appear]
2. [Action: click, fill, type, select, check] [target] — Expected: [outcome]
3. ...
Final: Take full-page screenshot, check console, check network.
```

### Per-step verification

After each action, verify the outcome:
- Take a snapshot to confirm expected elements are present
- Use `playwright-cli eval` to read specific text or attribute values
- Capture screenshots for failed steps as evidence

### Report format

Report as a table with columns: Step | Action | Expected | Result | Evidence. Each step marked ✅ PASS or ❌ FAIL. Conclude with a summary verdict — ✅ PASS or ❌ NEEDS-FIX — plus console and network check results.

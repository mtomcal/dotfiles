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

If Playwright is installed but its bundled browser cannot launch because native dependencies are missing, try a system browser before attempting privileged dependency installation:

```bash
which google-chrome || which chromium || which chromium-browser || true
```

For Node-based Playwright checks, launch with an explicit executable path:

```javascript
const browser = await chromium.launch({
  headless: true,
  executablePath: '/opt/google/chrome/chrome',
  args: ['--no-sandbox', '--disable-dev-shm-usage'],
});
```

Only escalate to `npx playwright install-deps` or OS package installation when no usable system browser is available or the system browser also fails.

## Workflow

1. Navigate: `playwright-cli navigate --url "<url>"`
   - After CSS, layout, or static asset edits, prefer a cache-busted URL such as `?v=<timestamp>` or perform a hard reload before trusting screenshots.
   - If browser output contradicts local files, verify the served DOM/CSS before diagnosing the page.
2. Screenshot:
   - Viewport: `playwright-cli screenshot --filename viewport.png`
   - Full-page: `playwright-cli screenshot --full-page --filename full.png`
3. Accessibility: `playwright-cli snapshot`
4. Console: `playwright-cli console`
5. Network: `playwright-cli network`
6. Report issues (layout/a11y/console/network) with severity and suggested fixes. Include viewport size, screenshot path, console warning/error count, network failures, missing hash targets when relevant, horizontal scroll width, and visible overflow/offscreen notes.
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

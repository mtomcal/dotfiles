---
name: visual-qa
description: "Perform visual QA across browser, app, and recorded artifacts. Use when checking layout, responsive behavior, console/network issues, motion/readability problems, screenshots, or review videos, and route to browser-specific skills or video-to-contact-sheet as needed."
allowed-tools: Bash(ffmpeg:*) Bash(ffprobe:*) Bash(find:*) Bash(mkdir:*) Bash(ls:*) Bash(du:*) Bash(jq:*) Bash(sed:*) Bash(cat:*)
metadata:
  short-description: Tool-agnostic visual QA and evidence review
---

# Visual QA

Use this skill when the job is to decide whether a human-visible result is acceptable. Keep the workflow tool-agnostic and pull in browser or capture skills only for the surface you need.

## Routing

- Use `Playwright` when you need scripted browser automation, deterministic capture, or Playwright-managed recordings.
- Use `browser:control-in-app-browser` for localhost or side-by-side in-app browser checks.
- Use `chrome:control-chrome` when you need the user's Chrome profile, cookies, or logged-in tabs.
- Use `video-to-contact-sheet` when the evidence is a recording or when a static screenshot is no longer enough.

## Workflow

1. Pick the human question first.
   - Examples: "Does the layout overflow on mobile?", "Does the animation read clearly?", "Does the recording prove the bug is fixed?"
2. Choose the right evidence format.
   - Single screenshot for layout and spacing.
   - Full-page or multi-viewport evidence for responsive issues.
   - Motion evidence for animation, occlusion, attachment, timing, or directional-read questions.
3. Gather runtime context alongside visuals.
   - Console warnings/errors.
   - Network failures.
   - Structured scenario artifacts, when present.
4. Escalate when stills stop being trustworthy.
   - If the complaint is about pose, shadow, weapon/tool anchoring, causality, timing, or something that only appears wrong in motion, switch to `video-to-contact-sheet`.
   - If logs and screenshots say "fine" but the human-visible result still looks wrong, trust the visible complaint and keep narrowing the evidence.
5. Report findings in human terms.
   - Lead with the visible failure or pass condition.
   - Include the evidence path, runtime context, and whether the issue is product behavior, capture setup, or artifact limitation.

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
- Take a snapshot or screenshot to confirm expected elements are present
- Use the active browser skill to read text, attributes, or console/network state
- Capture screenshots for failed steps as evidence

### Report format

Report as a table with columns: Step | Action | Expected | Result | Evidence. Each step marked ✅ PASS or ❌ FAIL. Conclude with a summary verdict — ✅ PASS or ❌ NEEDS-FIX — plus console and network check results.

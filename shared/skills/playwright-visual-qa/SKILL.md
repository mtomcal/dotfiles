---
name: playwright-visual-qa
description: "Perform browser-based visual QA via playwright-cli: screenshots, a11y snapshot, console and network checks, plus recorded video artifact review with ffmpeg/ffprobe. Pairs well with @playwright_visual_qa. Use when performing visual QA, accessibility checks, browser-based UI verification, reviewing recorded demos, gameplay videos, Playwright WebM artifacts, or visual scenario recordings."
allowed-tools: Bash(playwright-cli:*) Bash(ffmpeg:*) Bash(ffprobe:*) Bash(find:*) Bash(mkdir:*) Bash(ls:*) Bash(du:*) Bash(jq:*) Bash(sed:*) Bash(cat:*)
metadata:
  short-description: Visual and video QA with Playwright CLI
---

# Playwright Visual QA

Use this skill to do quick, repeatable visual QA against a URL using `playwright-cli`, and to review recorded browser/demo videos using `ffmpeg` and structured artifacts.

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

## Recorded Video Review

Use this workflow when the deliverable is a recorded demo, gameplay clip, Playwright WebM, or deterministic visual scenario. Artifact existence is not enough; the recording must prove the requested behavior to a human reviewer.

### 1. Locate the Evidence Bundle

Prefer the artifact directory produced by the test or runner. If the project has a standard artifact root, find the newest video:

```bash
LATEST=$(find artifacts -path '*/video.webm' -printf '%T@ %h\n' | sort -nr | head -1 | cut -d' ' -f2-)
ls -lh "$LATEST"
```

If there are structured artifacts, inspect them before watching the video:

```bash
find "$LATEST" -maxdepth 1 -type f -print | sort
jq . "$LATEST/scenario-result.json" 2>/dev/null || true
sed -n '1,80p' "$LATEST/server-authored-events.ndjson" 2>/dev/null || true
sed -n '1,80p' "$LATEST/browser-observed-events.ndjson" 2>/dev/null || true
sed -n '1,80p' "$LATEST/server-events.ndjson" 2>/dev/null || true
sed -n '1,120p' "$LATEST/browser-console.ndjson" 2>/dev/null || true
sed -n '1,120p' "$LATEST/browser-console.log" 2>/dev/null || true
```

### 2. Probe the Recording

Confirm duration, resolution, codec, file size, and whether audio is present:

```bash
ffprobe -v error -show_entries format=duration,size -show_streams "$LATEST/video.webm"
```

Call out missing audio explicitly. Many Playwright WebM captures have no audio stream, so do not treat silence as proof that product audio is broken.

### 3. Build a Contact Sheet

Create a low-frequency overview first. This catches wrong-camera, blank-screen, and "only spawn is visible" failures quickly:

```bash
mkdir -p /tmp/video-review
ffmpeg -y -i "$LATEST/video.webm" \
  -vf "fps=5,scale=320:-1,tile=5x7" \
  -frames:v 1 /tmp/video-review/contact.png
```

Review the contact sheet before deeper analysis. Confirm the expected actor, target, UI, object, or interaction is visible for the meaningful part of the recording, not only at setup.

### 4. Create Focused Clips Or Crops

Use higher FPS contact sheets around the suspected moment when checking short-lived effects:

```bash
ffmpeg -y -ss 2.0 -t 2.0 -i "$LATEST/video.webm" \
  -vf "fps=12,scale=480:-1,tile=6x4" \
  -frames:v 1 /tmp/video-review/focused.png
```

Crop when the important action is small in the full frame:

```bash
ffmpeg -y -ss 2.0 -t 2.0 -i "$LATEST/video.webm" \
  -vf "crop=420:260:760:320,fps=12,scale=420:-1,tile=6x4" \
  -frames:v 1 /tmp/video-review/crop.png
```

Adjust `-ss`, `-t`, and `crop=w:h:x:y` from the contact sheet evidence. Do not guess once the frames show a better region.

### 5. Cross-Check Semantics

Compare the visible story with structured evidence:

- Does the intended actor stay on camera through the behavior?
- Does the video show the requested outcome, not merely setup or spawn?
- Does the visible cause align with the visible effect? For example, an actor's tool, cursor, weapon, animation, or gesture should point into or otherwise lead to the resulting projectile, hit spark, UI transition, object movement, or state change.
- Do console and network logs show errors that explain missing visuals?
- Do authoritative events or scenario results agree with the video timeline?
- Are domain-specific semantics visible? For example, a shotgun demo should show a pellet spread, not just one generic projectile.
- Are artifact limitations being mistaken for product bugs? Missing audio in WebM is a recording limitation unless another capture proves otherwise.

For deterministic game scenario recordings, compare server-authored evidence first, then browser-observed evidence, then the video:

- Server-authored events are the runtime truth for what happened in the simulation.
- Browser-observed events diagnose whether the browser received the expected state.
- The video diagnoses camera targeting, timing, rendering, animation, and human-review credibility.
- Verify domain-specific counts and identifiers, such as projectile count, burst IDs, sequence indexes, pickup-before-use ordering, and visible spread or impact behavior.
- Verify visual causality with focused frames. For example, a shotgun barrel and arms should point into the pellet fan, not away from it, even when the event log has the right projectile count.

### 6. Report Findings

Lead with failures that would mislead a human reviewer. Include:

- Video path and duration
- Contact sheet and crop paths
- Console/network error count
- Structured artifact mismatch, if any
- The exact visual expectation that failed
- Whether the issue is recording setup, test artifact limitation, or product/runtime behavior

For game or animation work, a passing review means the artifact would convince a person watching it that the requested behavior happened correctly.

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

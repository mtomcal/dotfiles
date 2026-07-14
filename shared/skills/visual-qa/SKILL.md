---
name: visual-qa
description: "Perform visual QA across browser, app, and recorded artifacts. Use when checking layout, responsive behavior, console/network issues, motion/readability problems, screenshots, or review videos, and route to browser-specific skills or video-to-contact-sheet as needed."
allowed-tools: Bash(find:*) Bash(ls:*) Bash(jq:*) Bash(sed:*) Bash(cat:*)
metadata:
  short-description: Tool-agnostic visual QA and evidence review
---

# Visual QA

## Language Definitions

- **Human-visible result** — rendered appearance/behavior a person perceives.
- **Evidence surface** — browser, app, screenshot, recording, or derived artifact selected for inspection.
- **Runtime context** — scenario plus console, network, auth, viewport, and environment needed to interpret evidence.
- **Capture setup failure** — invalid evidence caused by wrong environment/state/timing/tooling rather than a proven product defect.
- **Artifact limitation** — information missing or distorted by the review medium.
- **Machine/visual mismatch** — disagreement between structured signals and visible result that must be reported without silently favoring either.

## Workflow

Use this workflow to decide whether a Human-visible result is acceptable. It owns general visual interpretation and its report; the caller or human retains final acceptance.

1. **Route the mode, then state the human question.** Use orchestrated mode when the caller supplies a numbered checklist of actions and expected outcomes; otherwise use ad hoc mode. In either mode, state the visible question before selecting evidence or tooling. If the expected Human-visible result cannot be established, ask the caller rather than inventing acceptance criteria. This step is complete when the mode, question, and each orchestrated expected outcome are explicit.

2. **Select an available Evidence surface and owner.** Inventory supplied artifacts and the browser, app, or capture routes actually available in the runtime; do not assume a named integration exists. Prefer supplied evidence when it validly covers the question. For new browser evidence, select an available capture owner that satisfies the required auth/profile/session, environment, and determinism. Use `playwright` when it is available and deterministic browser automation, capture, or recording is needed; its skill owns browser commands and cleanup. Use `video-to-contact-sheet` when a recording needs trimming or frame-sampled evidence; its skill owns conversion recipes and hands off source and generated paths with each purpose and limitation.

   Choose a single still for layout or spacing, full-page or multiple viewport captures for responsive behavior, and motion evidence for animation, occlusion, attachment, causality, timing, or directional readability. If no available route can produce valid required evidence, report a Capture setup failure and the missing capability without issuing a product verdict. This step is complete when the selected route and Evidence surface are recorded and either valid evidence exists or the review is explicitly blocked.

3. **Gather Runtime context beside the visible evidence.** Record the scenario and structured scenario artifacts when present, console warnings/errors, network failures, auth or application state, viewport, and environment. Mark unavailable context as unavailable rather than clean. Inspect the Human-visible result itself; artifact existence or a machine-reported pass is not proof of visible correctness. This step is complete when every evidence path is named and each Runtime context field has evidence or an explicit limitation.

4. **Interpret, escalate, and classify.** When stills are untrustworthy for pose, shadow, anchoring, occlusion, causality, timing, direction, or another transient behavior, use an available capture owner to obtain motion evidence and route the recording through `video-to-contact-sheet` when conversion is needed. If the visible complaint remains while logs, stills, or structured checks look fine, preserve the complaint and narrow or recapture the Evidence surface instead of dismissing it. For every Machine/visual mismatch, report both signals without silently favoring either.

   Classify each finding as product behavior, Capture setup failure, or Artifact limitation. Invalid environment, state, timing, or tooling cannot prove a product defect; an Artifact limitation must state what the medium omits or distorts. This step is complete when every finding is tied to visible evidence, relevant Runtime context, a classification, and any mismatch or limitation.

5. **Execute and report the selected mode.**

   - **Ad hoc:** Lead with the visible pass or failure condition. Report the question, selected route, Evidence surface paths, Runtime context including console and network status, findings, Machine/visual mismatches, classifications, and Artifact limitations. Issue `PASS` or `NEEDS-FIX` only when valid evidence supports a verdict; otherwise report `BLOCKED` and the Capture setup failure without a product verdict.
   - **Orchestrated:** Execute each numbered action sequentially and verify its expected outcome before continuing. Report a table with `Step | Action | Expected | Outcome | Result | Evidence`; mark each executed step `PASS` or `FAIL`. Capture a screenshot or equivalent visible artifact for every failed step when capture remains available. If a failure invalidates later actions, mark them `BLOCKED` with the reason and last valid evidence rather than fabricating outcomes. Conclude with `PASS` only when every applicable expected outcome passes, `NEEDS-FIX` when valid evidence proves a failure, or `BLOCKED` when Capture setup failure prevents a product verdict. Include final console and network results.

   The capture owner retains interaction and raw-capture mechanics; `video-to-contact-sheet` retains derived-artifact production and limitations; this skill owns the general QA interpretation and report. Return the report and all cited paths to the caller for final human acceptance. Completion requires every requested question or orchestrated step to be accounted for, every failed step to have capture evidence or an explicit capture limitation, console and network status to be stated, and the verdict boundary to be clear.

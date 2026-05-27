---
name: image-comparison-judge
description: Runs a neutral visual comparison workflow between a reference image and candidate screenshots, contact sheets, or generated assets. Use when a task needs pass/fail image judgment, concept-fidelity review, visual regression triage, or independent artifact review after captures or renders.
metadata:
  short-description: Judge images against a reference
---

# Image Comparison Judge

Use this skill when the implementation agent needs an independent visual judgment rather than another round of self-evaluation.

## Workflow

1. Gather the reference image path and candidate image paths.
2. Gather the domain constraints that change the verdict, such as truthful-HUD rules or forbidden mechanics that must remain visually absent.
3. If subagents are available, delegate the comparison to the `image-comparison-judge` subagent.
4. Ask for a strict PASS/FAIL verdict with:
   - blocking mismatches
   - secondary gaps
   - evidence checked
   - suggested next comparison focus
5. Treat PASS as visual acceptance only for the requested comparison surface.

## Delegation Brief

Include:

- reference image path
- candidate image paths
- what the candidate is supposed to match
- blocking review dimensions
- forbidden visible elements
- whether the task is full-scene comparison, asset comparison, or HUD comparison

If a repo-local wrapper exists for the current project, use it before calling the subagent directly.

## Fallback

If subagents are unavailable, perform the same comparison manually and say that the independent judge pass could not be run.

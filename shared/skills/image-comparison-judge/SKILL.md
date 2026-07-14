---
name: image-comparison-judge
description: Runs a criteria-based visual judgment workflow between a reference image and candidate screenshots, contact sheets, or generated assets. Use when a task needs PASS/FAIL image judgment after a neutral diff report, concept-fidelity review, visual regression triage, or independent artifact review after captures or renders.
metadata:
  short-description: Judge images against a reference
allowed-tools: read,bash
---

# Image Comparison Judge

Use this skill when the implementation agent needs an independent visual judgment rather than another round of self-evaluation.

## Workflow

1. Gather the reference image path and candidate image paths.
2. Gather the domain constraints that change the verdict, such as truthful-HUD rules or forbidden mechanics that must remain visually absent.
3. Prefer consuming a neutral diff artifact from `image-diff-describer` or an equivalent first-stage comparison when one is available.
4. If you are already running as the `image-comparison-judge` subagent, perform the comparison directly. Otherwise, if subagents are available, delegate the comparison to the `image-comparison-judge` subagent.
5. Ask for a strict PASS/FAIL verdict with:
   - blocking mismatches
   - secondary gaps
   - evidence checked
   - suggested next comparison focus
6. Treat PASS as visual acceptance only for the requested comparison surface. It does not replace a separate final human acceptance step when a workflow requires one.

## Delegation Brief

Include:

- reference image path
- candidate image paths
- neutral diff artifact path when available
- what the candidate is supposed to match
- blocking review dimensions
- forbidden visible elements
- whether the task is full-scene comparison, asset comparison, or HUD comparison

If a repo-local wrapper exists for the current project, use it before calling the subagent directly.

## Fallback

If you are already running as the `image-comparison-judge` subagent, do not claim the independent judge pass was unavailable. If subagents are unavailable and you are not already that subagent, perform the same comparison manually and say that the independent judge pass could not be run.

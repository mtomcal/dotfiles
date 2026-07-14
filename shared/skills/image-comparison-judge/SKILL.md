---
name: image-comparison-judge
description: Runs a criteria-based visual judgment workflow between a reference image and candidate screenshots, contact sheets, or generated assets. Use when a task needs PASS/FAIL image judgment after a neutral diff report, concept-fidelity review, visual regression triage, or independent artifact review after captures or renders.
metadata:
  short-description: Judge images against a reference
allowed-tools: read,bash
---

# Image Comparison Judge

## Language Definitions

- **Visual acceptance** — criteria-based decision about the requested visible result.
- **Comparison surface** — explicit visible scope covered by the verdict.
- **Blocking finding** — visible acceptance-criterion violation preventing PASS.

## Workflow

1. **Select the preferred available route without invoking it.** Select direct judging when already running as the `image-comparison-judge` subagent; otherwise select a repo-local wrapper when one exists, direct `image-comparison-judge` delegation when available, or the in-process fallback. Do not test whether the selected route can complete before gathering its brief.
2. **Gather the evidence and criteria.** Obtain the reference image path, every candidate image path, what the candidate should match, the Comparison surface (full scene, asset, or HUD), blocking review dimensions, and verdict-changing domain constraints such as truthful-HUD rules or forbidden visible elements. Consume a neutral diff artifact from `image-diff-describer` when available, but do not produce or own it or treat it as a verdict.
3. **Execute the selected route after gathering the brief.** Inspect every named image. If already the judge, compare directly and do not claim the independent pass was unavailable. Invoke a selected wrapper or delegate with all gathered inputs, including the neutral diff artifact path when available. If a wrapper cannot complete, continue to direct delegation when available; if the wrapper or delegate cannot complete, use the in-process fallback and disclose that the independent judge pass could not run. Judge the visible result against the reference, intended match, review dimensions, and constraints. Issue a strict PASS or FAIL only for the Comparison surface: any Blocking finding prevents PASS; report lesser visible gaps as secondary findings.
4. **Return the judgment** with:
   1. verdict: PASS or FAIL
   2. blocking findings
   3. secondary findings
   4. evidence checked
   5. suggested next comparison focus

   PASS is Visual acceptance only for the Comparison surface and does not replace a separately required final human acceptance step. Complete the workflow only after every named image and criterion is accounted for, findings are classified, the execution route or fallback is clear, and all five output fields are present.

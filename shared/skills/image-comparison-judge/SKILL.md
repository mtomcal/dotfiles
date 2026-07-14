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

1. **Select the judging route first.** If already running as the `image-comparison-judge` subagent, judge directly and do not claim the independent pass was unavailable. Otherwise, try a repo-local wrapper when one exists. If no wrapper exists or it cannot complete the comparison, delegate directly to the `image-comparison-judge` subagent when available. If neither route can complete, perform the same comparison in process and disclose that the independent judge pass could not run.
2. **Gather the evidence and criteria.** Obtain the reference image path, every candidate image path, what the candidate should match, the Comparison surface (full scene, asset, or HUD), blocking review dimensions, and verdict-changing domain constraints such as truthful-HUD rules or forbidden visible elements. Consume a neutral diff artifact from `image-diff-describer` when available, but do not produce or own it or treat it as a verdict.
3. **Execute the selected route.** Inspect every named image. For a wrapper or delegate, provide all gathered inputs, including the neutral diff artifact path when available. Judge the visible result against the reference, intended match, review dimensions, and constraints. Issue a strict PASS or FAIL only for the Comparison surface: any Blocking finding prevents PASS; report lesser visible gaps as secondary findings.
4. **Return the judgment** with:
   1. verdict: PASS or FAIL
   2. blocking findings
   3. secondary findings
   4. evidence checked
   5. suggested next comparison focus

   PASS is Visual acceptance only for the Comparison surface and does not replace a separately required final human acceptance step. Complete the workflow only after every named image and criterion is accounted for, findings are classified, the execution route or fallback is clear, and all five output fields are present.

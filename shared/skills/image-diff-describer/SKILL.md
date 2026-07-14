---
name: image-diff-describer
description: Produces a neutral, detailed description of visible differences between a reference image and candidate images without making acceptance judgments. Use when a workflow needs an unbiased image diff artifact before a separate judge, reviewer, or downstream criteria pass.
metadata:
  short-description: Describe image differences without a verdict
allowed-tools: read,bash
---

# Image Diff Describer

## Language Definitions

- **Neutral diff artifact** — structured observable differences without criteria, severity, recommendations, or verdict.
- **Raw diffing** — comparison intentionally excluding hidden goals and acceptance rules.
- **Verdict** — acceptance judgment outside this skill’s authority.
- **Visual ambiguity** — evidence too unclear for confident description and reported with uncertainty.

## Workflow

Use this workflow when the implementation agent needs a bias-resistant image diff rather than a verdict. This skill owns the neutral diff artifact; downstream judgment and acceptance stay elsewhere.

1. **Gather the evidence and scope.** Record the reference image path, candidate image paths, and whether the comparison is full-scene, asset-only, or HUD-only. This step is complete when every image path and the comparison scope are explicit.

2. **Select the raw-comparison route without exposing the goal.** If a repo-local wrapper exists, use it before improvising a prompt. Otherwise, if a raw-image-comparison delegate is available, delegate only that comparison; if not, compare in process.

   When a prompt or delegation brief is needed, include:

   - reference image path
   - candidate image paths
   - whether the task is full-scene, asset-only, or HUD-only
   - the instruction that the task is raw diffing only, with no verdict

   Keep the prompt free of acceptance criteria, forbidden elements, and expected outcomes. This step is complete when the selected route has the evidence and scope but no hidden judgment criteria; an in-process fallback must not be presented as an independent delegate.

3. **Compare only observable evidence.** Describe visible differences without inferring desired behavior. Report visual ambiguity explicitly whenever the evidence is too unclear for a confident description. This step is complete when each reported difference is tied to visible evidence and every low-confidence read is identified as uncertain.

4. **Produce the neutral diff artifact.** Save or return a structured artifact for a separate reviewer or judge with exactly these fields:

   1. Evidence checked
   2. Overall composition differences
   3. Detailed differences by category
   4. Highest-salience visual deltas
   5. Ambiguities or low-confidence reads

   Apply these rules while producing it:

   - Do not issue PASS/FAIL.
   - Do not classify findings as blocking or non-blocking.
   - Do not apply project-specific acceptance criteria unless asked to quote them as visible text.
   - Do not include recommendations, including implementation changes based on hidden goals.
   - Call out uncertainty explicitly when the evidence is ambiguous.

   Completion criterion: all five fields are present, evidence and uncertainty are explicit, and the artifact contains no applied criteria, severity, recommendation, or verdict. Report the saved path when a file is written; otherwise return the complete artifact directly for the separate reviewer or judge.

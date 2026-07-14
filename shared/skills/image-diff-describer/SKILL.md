---
name: image-diff-describer
description: Produces a neutral, detailed description of visible differences between a reference image and candidate images without making acceptance judgments. Use when a workflow needs an unbiased image diff artifact before a separate judge, reviewer, or downstream criteria pass.
metadata:
  short-description: Describe image differences without a verdict
allowed-tools: read,bash
---

# Image Diff Describer

Use this skill when the implementation agent needs a bias-resistant image diff rather than a verdict.

## Workflow

1. Gather the reference image path and candidate image paths.
2. If available, delegate to a subagent whose only task is raw image comparison. Keep the prompt free of acceptance criteria, forbidden elements, or expected outcomes.
3. Compare the evidence and describe only observable visual differences.
4. Save or return a structured diff artifact for a separate reviewer or judge to consume.

## Output rules

- Do not issue PASS/FAIL.
- Do not classify findings as blocking or non-blocking.
- Do not apply project-specific acceptance criteria unless asked to quote them as visible text.
- Do not recommend implementation changes based on hidden goals.
- Call out uncertainty explicitly when the evidence is ambiguous.

## Required output

1. Evidence checked
2. Overall composition differences
3. Detailed differences by category
4. Highest-salience visual deltas
5. Ambiguities or low-confidence reads

## Delegation Brief

Include:

- reference image path
- candidate image paths
- whether the task is full-scene, asset-only, or HUD-only
- the instruction that the task is raw diffing only, with no verdict

If a repo-local wrapper exists, use it before improvising a prompt.

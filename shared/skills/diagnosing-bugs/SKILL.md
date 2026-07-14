---
name: diagnosing-bugs
description: Diagnose hard bugs and performance regressions with a tight red-capable feedback loop, minimal reproduction, falsifiable hypotheses, and targeted instrumentation. Use when debugging broken, failing, throwing, flaky, incorrect, or unexpectedly slow behavior.
metadata:
  short-description: Diagnose bugs with tight feedback loops
allowed-tools: read,write,edit,bash
---

# Diagnosing Bugs

Build evidence before theories. Read relevant repository guidance, specs, and `specs/UBIQUITOUS_LANGUAGE.md` when present so the symptom and hypotheses use the project's terms.

## 1. Establish one tight command

Create the smallest agent-runnable command that exercises the real bug path and asserts the user's exact symptom. Prefer, in order: an existing focused test; a test invocation with a fixture; a CLI or HTTP reproduction; a headless browser script; captured-trace replay; a throwaway harness; a seeded stress, differential, or bisection loop.

Tight means:

- **red-capable** — it catches this exact bug, not merely a crash
- **deterministic** — or a pinned, high reproduction rate for flaky behavior
- **fast** — focused enough to rerun repeatedly
- **agent-runnable** — unattended whenever possible

Run it and record the invocation plus observed failure. If no such loop can be built, stop theorizing, list attempts, and request the missing environment access, captured artifact, or permission for temporary instrumentation.

Completion criterion: one named command has already gone red on the reported symptom.

## 2. Reproduce and minimize

Confirm repeated runs show the same symptom. Remove inputs, callers, configuration, data, and steps one at a time, rerunning after each removal. Keep only load-bearing elements.

Completion criterion: the smallest known scenario remains red and removing any remaining element changes the verdict.

## 3. Rank hypotheses

Write three to five ranked hypotheses. Every hypothesis must predict an observable result:

> If X causes the bug, changing or measuring Y will produce Z.

Show the ranking to the user when available, but continue with the evidence-based order rather than blocking. Reject hypotheses that cannot be falsified.

## 4. Probe surgically

Test one prediction at a time. Prefer debugger or REPL inspection, then targeted logs or measurements at points that distinguish hypotheses. Tag temporary instrumentation with a unique marker such as `[DEBUG-a4f2]`. For performance, establish a timing/profile/query-plan baseline before changing code.

Completion criterion: evidence falsifies alternatives and identifies a causal explanation, not merely a correlated line.

## 5. Lock the behavior with TDD

Load the `tdd` skill. Turn the minimized reproduction into a failing regression test at the pre-agreed seam, then use its discovered-bug red-green-refactor path for the smallest fix. If no honest seam can reproduce the bug, document that architecture finding rather than adding a tautological or shallow test.

Re-run both the regression test and the original command.

## 6. Clean up and report

Remove all tagged instrumentation and throwaway harnesses unless they became the regression test. Report the root cause, evidence, fix, test seam, commands run, and any remaining architectural risk. Route a missing or harmful seam to `improve-codebase-architecture` only after the bug is fixed.

Completion criterion: the original command and regression test are green, debug tags are absent, and the causal explanation is recorded.

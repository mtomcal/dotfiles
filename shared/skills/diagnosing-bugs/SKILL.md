---
name: diagnosing-bugs
description: Diagnose hard bugs and performance regressions with a tight red-capable feedback loop, minimal reproduction, falsifiable hypotheses, and targeted instrumentation. Use when debugging broken, failing, throwing, flaky, incorrect, or unexpectedly slow behavior.
metadata:
  short-description: Diagnose bugs with tight feedback loops
allowed-tools: read,write,edit,bash
---

# Diagnosing Bugs

## Language Definitions

- **Tight command** — smallest quickly repeatable agent-runnable command exercising the real bug path.
- **Red-capable** — detects the reported symptom specifically.
- **Minimized reproduction** — smallest known failing scenario where another removal changes the verdict.
- **Falsifiable hypothesis** — proposed cause predicting an observable result capable of disproving it.
- **Causal explanation** — evidence-backed account of why the symptom occurs after meaningful alternatives are ruled out.

## Workflow

Build evidence before theories. Read relevant repository guidance, proposals, and `UBIQUITOUS-LANGUAGE.md` when present so the symptom and hypotheses use the project's terms.

1. **Establish one tight command.** Create the smallest command that exercises the real bug path and asserts the user's exact symptom. Prefer, in order: an existing focused test; a test invocation with a fixture; a CLI or HTTP reproduction; a headless browser script; captured-trace replay; a throwaway harness; a seeded stress, differential, or bisection loop.

   The command must be red-capable, deterministic or pinned to a high reproduction rate for flaky behavior, fast enough for repeated runs, and unattended whenever possible. Run it and record the invocation plus observed failure. If no such loop can be built, stop theorizing, list the attempts, and request the missing environment access, captured artifact, or permission for temporary instrumentation.

   Completion criterion: one named tight command has already gone red on the reported symptom.

2. **Reproduce and minimize.** Confirm repeated runs show the same symptom. Remove inputs, callers, configuration, data, and steps one at a time, rerunning after each removal. Keep only load-bearing elements.

   Completion criterion: the minimized reproduction remains red, and removing any remaining element changes the verdict.

3. **Rank hypotheses.** Write three to five ranked hypotheses. Give each one an observable prediction:

   > If X causes the bug, changing or measuring Y will produce Z.

   Show the ranking to the user when available, but continue in evidence order rather than blocking. Reject hypotheses that cannot be falsified.

   Completion criterion: three to five falsifiable hypotheses are ranked, each with a prediction that a probe can disprove.

4. **Probe surgically.** Test one prediction at a time. Prefer debugger or REPL inspection, then targeted logs or measurements at points that distinguish hypotheses. Tag temporary instrumentation with a unique marker such as `[DEBUG-a4f2]`. For performance, establish a timing, profile, or query-plan baseline before changing code.

   Completion criterion: evidence rules out meaningful alternatives and identifies a causal explanation, not merely a correlated line.

5. **Lock and fix the behavior through TDD.** Load the `tdd` skill. Turn the minimized reproduction into a failing regression test at the pre-agreed honest seam, observe it red for the diagnosed symptom, then use the discovered-bug path for the smallest fix. If no honest seam can reproduce the bug, document that architecture finding instead of adding a tautological or shallow test, and drive the smallest fix with the original red command. Architecture work must not replace fixing the requested bug.

   Completion criterion: the regression test was red and is now green after the smallest fix, or the no-seam finding is recorded and the original command is green after the smallest fix.

6. **Rerun, clean up, and report.** Re-run both the regression test and the original command. In the no-seam branch, re-run the original command and explicitly report why no regression test or second rerun is available. Remove all tagged instrumentation and throwaway harnesses unless they became the regression test. Report the root cause, evidence, fix, test seam or no-seam finding, commands run, and any remaining architectural risk. Route a missing or harmful seam to `improve-codebase-architecture` only after the bug is fixed.

   Completion criterion: the original command and any created regression test are green, debug tags are absent, and the causal explanation and remaining risk are recorded.

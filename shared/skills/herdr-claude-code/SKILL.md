---
name: herdr-claude-code
description: Launch and reliably coordinate Claude Code in Herdr by composing the base Herdr transport skill, handling readiness, explicit prompt submission, concurrent completion/blocking observation, and evidence-driven steering. Use when a caller selects Claude Code as a Herdr worker or reviewer.
metadata:
  short-description: Coordinate Claude Code through Herdr
allowed-tools: Bash(herdr:*)
---

# Herdr Claude Code

## Language Definitions

- **Claude readiness** — inspected evidence that the launched Claude Code TUI can accept a task, normally detected agent state `idle` plus a visible input composer.
- **Pasted-text indicator** — Claude Code's `[Pasted text #1]` composer display, which proves text arrived but not that the prompt was submitted.
- **Submission evidence** — inspected state or output showing Claude left the ready composer and began processing the intended prompt.

Agent statuses, caller panes, public Herdr IDs, and terminal transport use the base Herdr skill's definitions.

## Workflow

### 1. Compose base transport and select the checkout

Require `HERDR_ENV=1`, then load and follow [`herdr`](../herdr/SKILL.md) before issuing any Herdr command. It owns runtime discovery, current IDs, pane creation, input commands, concurrent status waiting, output inspection, and resource cleanup. Do not copy or improvise those mechanics here.

Select checkout topology before transport. Read-only Claude work may share the relevant checkout; editable work requires an isolated worktree with exact scope. The caller retains the task brief, workflow state, returned-evidence contract, steering decisions, and acceptance.

Completion criterion: the base skill's runtime gate passed, the checkout matches edit authority, and the caller has a current target-pane source and explicit Claude task contract.

### 2. Launch Claude and establish readiness

Use the base skill's split/run Activity to launch exactly:

```text
claude --dangerously-skip-permissions
```

This command disables Claude Code permission prompts; use it only in the checkout and scope selected by the caller. Capture the new public pane ID from the base Activity's mutation response, inspect pane state and recent output, and wait for Claude readiness before sending a task. When agent detection is available, readiness normally appears as `idle`; if status is `unknown`, use the base output-wait and inspection fallback to confirm the input composer. If startup reports `blocked` or an error, inspect and steer or stop before task submission.

Completion criterion: the exact Claude command is running in the authorized checkout and inspected evidence shows a ready input composer rather than merely a live process.

### 3. Submit the prompt with explicit evidence

Use the base input Activity in this order:

1. send the complete prompt as text without Enter;
2. inspect recent output to confirm the intended text or `[Pasted text #1]` reached Claude's composer;
3. send an explicit `Enter` key;
4. inspect pane state and output for submission evidence.

`[Pasted text #1]` alone is not submission. If it remains in the composer and Claude remains `idle`, send one additional explicit `Enter` only after that inspection, then inspect again. Do not resend the full prompt and do not press Enter repeatedly without evidence, because either can duplicate or alter the task. If Claude still does not begin processing, report the observed composer/state instead of claiming launch success.

Completion criterion: inspection shows Claude processing the intended task, or the caller receives exact evidence that submission failed.

### 4. Observe completion or steer blocking

Invoke the base Herdr skill's concurrent `done`/`idle`/`blocked` waiting Activity with the caller's timeout; do not implement another status race here. After it returns, inspect recent unwrapped output:

- `done` or `idle` is a completion candidate; validate the caller's required evidence before accepting it.
- `blocked` requires immediate steering. Read the request, send only the missing input through the base input Activity, use the same explicit Enter-and-inspect submission discipline, and resume the base concurrent wait.
- `idle` without required completion evidence may mean the prompt never submitted or Claude stopped prematurely; inspect and steer rather than accepting it.
- timeout or `unknown` requires current pane-state and output inspection through the base Activity before retrying or reporting a limitation.

If steering would require an unapproved product, scope, security, or acceptance decision, return that decision to the caller instead of inventing it. Never infer completion from a quiet, idle, missing, or compacted pane without the required output evidence.

Completion criterion: Claude returns the contracted evidence and the caller decides acceptance, or the exact blocked/failed state and required next decision are reported from inspected output.

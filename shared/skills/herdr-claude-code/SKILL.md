---
name: herdr-claude-code
description: Launch and reliably coordinate Claude Code in Herdr by composing the base Herdr transport skill, handling validated startup, atomic prompt submission, settled-state observation, and evidence-driven steering. Use when a caller selects Claude Code as a Herdr worker or reviewer.
metadata:
  short-description: Coordinate Claude Code through Herdr
allowed-tools: Bash(herdr:*)
---

# Herdr Claude Code

## Language Definitions

- **Claude readiness** — successful `agent start` evidence that Herdr detected Claude Code in the selected pane and found it ready for interactive input.
- **Submission evidence** — a successful atomic `agent prompt` request followed by an observed lifecycle change and the requested settled state.

Agent statuses, caller panes, public Herdr IDs, agent names, and terminal transport use the base Herdr skill's definitions.

## Workflow

### 1. Compose base transport and select the checkout

Require `HERDR_ENV=1`, then load and follow [`herdr`](../herdr/SKILL.md) before issuing any Herdr command. It owns runtime discovery, current IDs, named task-tab creation, agent and pane input primitives, settled-state waiting, output inspection, and resource cleanup. Do not copy or improvise those mechanics here.

Select checkout topology before transport. Read-only Claude work may share the relevant checkout; editable work requires an isolated worktree with exact scope. The caller retains the task brief, workflow state, returned-evidence contract, steering decisions, and acceptance.

Completion criterion: the base skill's runtime gate passed, the checkout matches edit authority, and the caller has an explicit Claude task and evidence contract.

### 2. Launch Claude through the validated agent facade

Use the base skill to create the task-owned named tab and capture its root pane ID. Start Claude with a unique task-specific agent name and the exact native argument required by this workflow:

```bash
AGENT_NAME=${AGENT_NAME:?set a unique lowercase task name}
TARGET_PANE=${TARGET_PANE:?set from the task-tab creation response}
herdr agent start "$AGENT_NAME" --kind claude --pane "$TARGET_PANE" -- --dangerously-skip-permissions
```

This runs `claude --dangerously-skip-permissions`, which disables Claude Code permission prompts; use it only in the checkout and scope selected by the caller. `agent start` validates the kind, starts it in the existing pane, and returns only after Herdr detects Claude and finds it ready. If startup fails, inspect `agent get` when available and `pane read` before steering or stopping.

Completion criterion: validated startup succeeded in the authorized checkout, or exact startup state and output evidence were returned without submitting a task.

### 3. Submit and observe atomically

Submit the complete prompt through Herdr's agent facade:

```bash
herdr agent prompt "$AGENT_NAME" "${TASK_PROMPT:?set the Claude task}" --wait --timeout "${TIMEOUT_MS:-120000}"
```

`agent prompt` atomically handles text, live bracketed-paste mode, and encoded Enter. From a non-working state it requires an observed lifecycle change within five seconds; otherwise it reports `agent_prompt_stalled`. Do not manually paste, resend the prompt, or add Enter presses after a failed request without first inspecting `agent get` and `agent read`.

The default wait returns on `done`, `idle`, or `blocked`. Inspect recent unwrapped output after every result. `done` or `idle` is only a completion candidate and still requires the caller's contracted evidence. `blocked` requires immediate inspection and steering. Timeout, `unknown`, or `agent_prompt_stalled` requires current state and output inspection before any retry.

Completion criterion: Claude reached an inspected settled state after processing the intended task, or the caller receives exact failure/state evidence without blind resubmission.

### 4. Steer blocking and finish

When Claude is blocked, read the request and send only the missing response through a new atomic prompt operation. If an already-running turn needs observation after steering or reconnection, use the base `herdr agent wait` Activity; do not reimplement its waiting logic. Resume inspection after each settled result.

If steering would require an unapproved product, scope, security, or acceptance decision, return that decision to the caller instead of inventing it. Never infer completion from a quiet, idle, missing, or compacted pane without the required output evidence.

Completion criterion: Claude returns the contracted evidence and the caller decides acceptance, or the exact blocked/failed state and required next decision are reported from inspected output.

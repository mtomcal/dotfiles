---
name: herdr
description: "Control herdr from inside it. Manage workspaces and tabs, split panes, spawn agents, read output, and wait for state changes — all via CLI commands that talk to the running herdr instance over a local unix socket. Use when running inside herdr (HERDR_ENV=1)."
metadata:
  short-description: Control Herdr panes and workspaces
allowed-tools: Bash(herdr:*)
---

# herdr — agent skill

## Language Definitions

- **Caller pane** — pane whose process invoked Herdr, identified through environment or current-pane discovery rather than UI focus.
- **Focused pane** — pane selected in the interface; it may differ from the caller pane.
- **Public Herdr ID** — opaque runtime identifier. Refresh it after topology changes and never persist it as durable identity.
- **Legacy display selector** — numeric position selector that may resolve differently after topology changes. Never guess or persist one.
- **Agent status** — `idle`, `working`, `blocked`, `done`, or `unknown`.
- **Done** — agent output finished but not yet observed.
- **Idle** — agent is awaiting input or its completion has already been observed.

Workspace, tab, and pane use the project definitions in `UBIQUITOUS-LANGUAGE.md` rather than skill-local definitions.

## Activities

### Route supervision before transport

Use this skill directly for terminal transport and resource control. When the caller asks to select implementation and escalation models, supervise a bounded editable worker, independently accept its candidate, or compare delegated cost against one strong model, load [`herdr-supervise`](../herdr-supervise/SKILL.md); it owns that supervision contract while this skill continues to own transport. When an explicit execution molecule needs recoverable execution, route to [`execute-engineering-molecule`](../execute-engineering-molecule/SKILL.md) instead.

Completion: transport-only work remains here, bounded supervision composes `herdr-supervise`, and molecule execution composes `execute-engineering-molecule` without copying either workflow into this skill.

### Verify runtime context and discover live state

Before any Herdr control command, verify this process is inside Herdr:

```bash
test "${HERDR_ENV:-}" = 1
```

If that fails, say you are not running inside a Herdr-managed pane and stop. Do not inspect or control the focused Herdr session from outside Herdr.

The installed binary is authoritative for syntax. Discover only through help and command groups; do not probe a nested mutating command by omitting arguments because some creates are valid with defaults.

```bash
herdr --help
herdr workspace --help
herdr tab --help
herdr pane --help
herdr agent --help
```

Use the injected caller context, not UI focus:

```bash
herdr pane current --current
herdr workspace list
herdr tab list --workspace "$HERDR_WORKSPACE_ID"
herdr pane list --workspace "$HERDR_WORKSPACE_ID"
```

`HERDR_WORKSPACE_ID`, `HERDR_TAB_ID`, and `HERDR_PANE_ID` identify the caller's live context. A `focused` field identifies UI focus, not the caller. Treat every returned ID as opaque, use it directly from the environment or JSON response, refresh after topology changes, and never copy it into durable workflow state, documentation, commits, proposals, or handoffs.

Completion: the environment gate passed, relevant group help was checked, and the caller and target resources were identified from current data rather than display position.

### Inspect pane state and output

Set `TARGET_PANE` only from the caller environment or a fresh list/create/split response, then inspect current state before waiting for future output:

```bash
TARGET_PANE=${TARGET_PANE:-"$HERDR_PANE_ID"}
herdr pane get "$TARGET_PANE"
herdr pane read "$TARGET_PANE" --source recent --lines 50
```

Choose the source by evidence needed:

- `visible` — current rendered viewport.
- `recent` — recent scrollback as rendered, including soft wraps.
- `recent-unwrapped` — recent terminal text with soft wraps joined; use for logs and for the transcript matched by a recent-output wait.

`pane read` prints text, not JSON. Use `--format ansi` or `--ansi` when terminal styling is evidence; otherwise use text.

Completion: the requested current state or transcript was read in the format that preserves the evidence needed.

### Create a named task tab, then run or launch

For every command, server, test, or agent started for your work, create a new task-owned **named tab** in the caller's workspace, preserve caller focus, parse the root pane from the creation response, then run, wait, and read. Name the tab for the concrete task; never use a default numbered label. Do not split the caller pane, add work to the caller's tab, or reuse another existing tab or pane merely because it is idle.

```bash
TASK_LABEL=${TASK_LABEL:?set a concrete task label}
TASK_CWD=${TASK_CWD:?set the command or isolated-worktree cwd}
CREATE_RESULT=$(herdr tab create \
  --workspace "$HERDR_WORKSPACE_ID" \
  --cwd "$TASK_CWD" \
  --label "$TASK_LABEL" \
  --no-focus)
TASK_TAB=$(
  printf '%s' "$CREATE_RESULT" |
    python3 -c 'import sys,json; print(json.load(sys.stdin)["result"]["tab"]["tab_id"])'
)
TARGET_PANE=$(
  printf '%s' "$CREATE_RESULT" |
    python3 -c 'import sys,json; print(json.load(sys.stdin)["result"]["root_pane"]["pane_id"])'
)
herdr pane run "$TARGET_PANE" "${COMMAND:?set COMMAND}"
herdr pane wait-output "$TARGET_PANE" --match "${EXPECTED_OUTPUT:?set EXPECTED_OUTPUT}" --timeout "${TIMEOUT_MS:-30000}"
herdr pane read "$TARGET_PANE" --source recent-unwrapped --lines 50
```

Use task-specific substitutions for servers, tests, and ordinary commands; do not copy the topology into separate recipes. For an interactive agent, start the supported agent through Herdr's validated facade, then submit the task atomically and wait for its first settled state:

```bash
AGENT_NAME=${AGENT_NAME:?set a unique lowercase task name}
AGENT_KIND=${AGENT_KIND:?set a supported agent kind}
herdr agent start "$AGENT_NAME" --kind "$AGENT_KIND" --pane "$TARGET_PANE"
herdr agent prompt "$AGENT_NAME" "${TASK_PROMPT:?set the agent task}" --wait --timeout "${TIMEOUT_MS:-120000}"
herdr agent get "$AGENT_NAME"
herdr agent read "$AGENT_NAME" --source recent-unwrapped --lines 100
```

Pass native agent arguments after `--` on `agent start`. Agent targets are unique live names or current hosting pane IDs, never bare agent-kind labels. If detection reports `unknown`, inspect `agent get` and `agent read` rather than treating it as completion. The caller chooses the kind, name, task, timeout, and acceptance evidence.

A task-owned tab MAY be split for additional processes only after the named tab exists. Split from a pane ID returned by that tab's create response or a later fresh list; never use `pane split --current` for background work because UI focus and caller context can diverge. Keep every resulting pane inside the task-owned tab.

Input commands remain distinct. Send input to an existing pane only when the caller explicitly targeted that pane or when it belongs to the current task-owned tab; set `TARGET_PANE` from fresh Herdr data before using it:

```bash
herdr pane send-text "$TARGET_PANE" "${TEXT:?set TEXT}"
herdr pane send-keys "$TARGET_PANE" Enter
herdr pane run "$TARGET_PANE" "${COMMAND:?set COMMAND}"
herdr agent prompt "$AGENT_NAME" "${TASK_PROMPT:?set the agent task}"
herdr agent send-keys "$AGENT_NAME" esc
```

`send-text` does not press Enter. `send-keys` sends named keys. `pane run` atomically sends shell command text and Enter. `agent prompt` atomically submits agent text and encoded Enter while honoring live bracketed-paste mode; use it instead of raw pane input for normal agent tasks. `agent send-keys` is for logical interactive controls such as `esc` or `ctrl+c`.

Herdr supplies terminal transport only. The caller retains the task brief, workflow state, returned-evidence contract, and acceptance decision. A named tab is not checkout isolation; choose a shared read-only checkout or isolated editable worktree before selecting Herdr transport.

Completion: a task-specific named tab was created without focus, the tab and root-pane IDs came from its mutation response, no existing user tab or pane was reused for launched work, and the requested command or agent reached an inspected result.

### Wait, diagnose, and coordinate

Read existing output first, then use the pane or agent wait that matches the target:

```bash
herdr pane read "$TARGET_PANE" --source recent --lines 40
herdr pane wait-output "$TARGET_PANE" --match "${EXPECTED_OUTPUT:?set EXPECTED_OUTPUT}" --timeout "${TIMEOUT_MS:-30000}"
herdr pane read "$TARGET_PANE" --source recent-unwrapped --lines 40
```

Use `--regex` for a regular-expression match. `pane wait-output` searches the selected snapshot immediately, so existing output can match; inspect logs with `recent-unwrapped`. An output-wait timeout exits with status `1`.

For a prompt submitted now, prefer the atomic prompt-and-wait operation shown above. For an already-running detected agent, use Herdr's server-owned settled-state wait rather than racing statuses in the shell:

```bash
TARGET_AGENT=${TARGET_AGENT:?set a unique agent name or hosting pane ID}
if WAIT_RESULT=$(herdr agent wait "$TARGET_AGENT" --timeout "${TIMEOUT_MS:-120000}"); then
  TERMINAL_STATUS=$(
    printf '%s' "$WAIT_RESULT" |
      python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["agent"]["agent_status"])'
  )
  herdr agent read "$TARGET_AGENT" --source recent-unwrapped --lines 100
  case "$TERMINAL_STATUS" in
    done|idle) printf 'agent completion observed: %s\n' "$TERMINAL_STATUS" ;;
    blocked) printf 'agent blocked: inspect the transcript and steer now\n' >&2 ;;
  esac
else
  herdr agent get "$TARGET_AGENT"
  herdr agent read "$TARGET_AGENT" --source recent-unwrapped --lines 100
fi
```

Without `--until`, `agent wait` matches `idle`, `done`, or `blocked`, including an already-reported settled state. Use repeated `--until` only when a workflow intentionally selects other exact states. Both `done` and `idle` mean completion; `blocked` requires immediate steering based on the transcript. `unknown` does not prove completion, so inspect current agent state and output after a failed wait rather than waiting blindly or resubmitting the prompt.

Pane-output and agent waits print JSON on success. Completion: the expected state or output was observed, or timeout/current evidence was returned with the applicable limitation.

### Manage explicitly requested resources

Use current IDs from environment, list, or mutation responses. Resource management changes terminal topology or user context, so create, label, rename, or focus resources only for the explicitly requested task. Prefer `--no-focus` for background creation.

Workspace capabilities:

```bash
herdr workspace list
herdr workspace create --cwd "$CWD" --label "$LABEL" --no-focus
herdr workspace create --no-focus
herdr workspace get "$WORKSPACE_ID"
herdr workspace focus "$WORKSPACE_ID"
herdr workspace rename "$WORKSPACE_ID" "$LABEL"
herdr workspace close "$WORKSPACE_ID"
```

Tab capabilities:

```bash
herdr tab list --workspace "$WORKSPACE_ID"
herdr tab create --workspace "$WORKSPACE_ID" --cwd "$CWD" --label "$LABEL" --no-focus
herdr tab create --workspace "$WORKSPACE_ID" --no-focus
herdr tab get "$TAB_ID"
herdr tab focus "$TAB_ID"
herdr tab rename "$TAB_ID" "$LABEL"
herdr tab close "$TAB_ID"
```

Process-specific environment may be added to workspace/tab create or pane split with `--env KEY=VALUE`. Without `--label`, workspace create keeps cwd-based naming and tab create keeps numbered naming. `--label` applies the custom name immediately. `--no-focus` on workspace create, tab create, and pane split preserves caller context.

Close a pane only under the ownership rule below:

```bash
herdr pane close "$TARGET_PANE"
```

Close resources created for the current task when its cleanup contract requires it. Do not close a workspace, tab, pane, or session you did not create unless the user explicitly asks or approves it. Do not stop the active Herdr server unless the user explicitly intends to stop it and its pane processes.

Parse every mutation response before continuing. Workspace create returns `result.workspace`, `result.tab`, and `result.root_pane`; tab create returns `result.tab` and `result.root_pane`; pane split returns the new ID at `result.pane.pane_id`. Workspace/tab management, pane list/get/split, agent operations, and waits return JSON on success. `pane read` and `agent read` return text; `pane send-text`, `pane send-keys`, and `pane run` are silent on success.

Completion: the explicitly requested topology change is confirmed from its response, fresh IDs replace stale ones, user context moved only when requested, and cleanup respects resource ownership.

## Reference

- When changing or auditing this adapted skill, load the [repository Herdr notice](../../../THIRD_PARTY_NOTICES.md#herdr) and the [upstream skill revision used for the Herdr 0.7.5 migration](https://github.com/herdrdev/herdr/blob/ef4c23f5775bb8cfec05f05d0844226ff959a07a/SKILL.md) to verify source revision, local-fork status, and AGPL-3.0-or-later attribution before editing.
- When installed help and remembered behavior differ, inspect the relevant command-group help first, then consult the current upstream skill to understand newer operating guidance while keeping the installed binary authoritative for executable syntax.
- When implementing a raw protocol client, direct request/response control, or a long-lived event subscriber, load the [socket API documentation](https://herdr.dev/docs/socket-api/); ordinary operation should stay on the CLI Activities above.

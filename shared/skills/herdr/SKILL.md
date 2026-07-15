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

Workspace, tab, and pane use the project definitions in `specs/UBIQUITOUS_LANGUAGE.md` rather than skill-local definitions.

## Activities

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
herdr wait --help
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

### Split, run, send, or launch an agent

For a command, server, test, or agent in a sibling pane, split the caller, preserve caller focus, parse the new public ID, then run, wait, and read. Set `DIRECTION` to `right` or `down`; set the command and expected output for the task.

```bash
DIRECTION=${DIRECTION:-right}
NEW_PANE=$(
  herdr pane split --current --direction "$DIRECTION" --no-focus |
    python3 -c 'import sys,json; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])'
)
herdr pane run "$NEW_PANE" "${COMMAND:?set COMMAND}"
herdr wait output "$NEW_PANE" --match "${EXPECTED_OUTPUT:?set EXPECTED_OUTPUT}" --timeout "${TIMEOUT_MS:-30000}"
herdr pane read "$NEW_PANE" --source recent-unwrapped --lines 50
```

Use task-specific substitutions for servers, tests, and ordinary commands; do not copy the topology into separate recipes. For an interactive agent, run its normal executable first, inspect `pane get`, wait for `idle` when agent detection is available, then submit the task with `pane run`. If status is `unknown` or the pane is a plain shell, fall back to an expected prompt/output wait and transcript inspection. The caller chooses the executable, task, readiness signal, timeout, and acceptance evidence.

Input commands remain distinct. For an existing pane, set `TARGET_PANE` from current context before using them:

```bash
TARGET_PANE=${TARGET_PANE:-"$HERDR_PANE_ID"}
herdr pane send-text "$TARGET_PANE" "${TEXT:?set TEXT}"
herdr pane send-keys "$TARGET_PANE" Enter
herdr pane run "$TARGET_PANE" "${COMMAND:?set COMMAND}"
```

`send-text` does not press Enter. `send-keys` sends the named keys. `pane run` sends text and then a real Enter in one request. These three commands print nothing on success.

Herdr supplies terminal transport only. The caller retains the task brief, workflow state, returned-evidence contract, and acceptance decision. A separate pane is not checkout isolation; choose a shared read-only checkout or isolated editable worktree before selecting Herdr transport.

Completion: the target ID came from the mutation response, caller focus was preserved unless a context switch was explicitly requested, and the requested command or agent reached an inspected result.

### Wait, diagnose, and coordinate

Read existing output first, then wait only for the next output or status expected:

```bash
herdr pane read "$TARGET_PANE" --source recent --lines 40
herdr wait output "$TARGET_PANE" --match "${EXPECTED_OUTPUT:?set EXPECTED_OUTPUT}" --timeout "${TIMEOUT_MS:-30000}"
herdr pane read "$TARGET_PANE" --source recent-unwrapped --lines 40
```

Use `--regex` for a regular-expression match. For `--source recent`, matching uses unwrapped recent text even though `pane read --source recent` remains rendered; inspect the matching form with `recent-unwrapped`. An output-wait timeout exits with status `1`.

For detected agents, precheck current state, then race `done`, `idle`, and `blocked` instead of waiting for one status sequentially:

```bash
wait_agent_terminal_state() (
  TARGET_PANE=${TARGET_PANE:?set TARGET_PANE from current Herdr data}
  TIMEOUT_MS=${TIMEOUT_MS:-60000}
  WAIT_DIR=
  WAIT_PIDS=()

  cleanup_waiters() {
    local pid
    for pid in "${WAIT_PIDS[@]}"; do [ -z "$pid" ] || kill "$pid" 2>/dev/null || true; done
    for pid in "${WAIT_PIDS[@]}"; do [ -z "$pid" ] || wait "$pid" 2>/dev/null || true; done
    [ -z "$WAIT_DIR" ] || rm -rf "$WAIT_DIR"
  }
  trap cleanup_waiters EXIT

  CURRENT_STATUS=$(
    herdr pane get "$TARGET_PANE" |
      python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["pane"].get("agent_status", "unknown"))'
  ) || exit 1
  case "$CURRENT_STATUS" in
    done|idle|blocked) printf '%s\n' "$CURRENT_STATUS"; exit 0 ;;
    unknown) exit 1 ;;
  esac

  WAIT_DIR=$(mktemp -d)
  WAIT_STATUSES=(done idle blocked)
  for status in "${WAIT_STATUSES[@]}"; do
    herdr wait agent-status "$TARGET_PANE" --status "$status" --timeout "$TIMEOUT_MS" \
      >"$WAIT_DIR/$status.json" 2>"$WAIT_DIR/$status.err" &
    WAIT_PIDS+=("$!")
  done

  REMAINING=${#WAIT_PIDS[@]}
  while [ "$REMAINING" -gt 0 ]; do
    for i in "${!WAIT_PIDS[@]}"; do
      pid=${WAIT_PIDS[$i]}
      [ -n "$pid" ] || continue
      if ! kill -0 "$pid" 2>/dev/null; then
        WAIT_PIDS[$i]=
        REMAINING=$((REMAINING - 1))
        if wait "$pid"; then printf '%s\n' "${WAIT_STATUSES[$i]}"; exit 0; fi
      fi
    done
    [ "$REMAINING" -eq 0 ] || sleep 0.05
  done
  exit 1
)

if TERMINAL_STATUS=$(wait_agent_terminal_state); then
  herdr pane read "$TARGET_PANE" --source recent-unwrapped --lines 100
  case "$TERMINAL_STATUS" in
    done|idle) printf 'agent completion observed: %s\n' "$TERMINAL_STATUS" ;;
    blocked) printf 'agent blocked: inspect the transcript and steer now\n' >&2 ;;
  esac
else
  herdr pane get "$TARGET_PANE"
  herdr pane read "$TARGET_PANE" --source recent-unwrapped --lines 100
fi
```

The function handles already-reported terminal states before creating waiters, starts all three waits concurrently, continues after the first success, and cancels/reaps the rest through its exit trap. Both `done` and `idle` mean completion; `blocked` requires immediate steering based on the transcript. Do not wait for only `done`, because observing the result can move the agent to `idle`.

`unknown` may be a plain shell or an agent not yet detected, so inspect output instead of waiting blindly on status. If all three waits fail or time out, the failure branch inspects current state and output before retrying, steering, or reporting failure.

Output and agent-status waits print JSON on success. Completion: the expected future event was observed, or timeout/current evidence was returned with the applicable limitation.

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

Parse every mutation response before continuing. Workspace create returns `result.workspace`, `result.tab`, and `result.root_pane`; tab create returns `result.tab` and `result.root_pane`; pane split returns the new ID at `result.pane.pane_id`. Workspace/tab management, pane list/get/split, and waits return JSON on success. `pane read` returns text; `pane send-text`, `pane send-keys`, and `pane run` are silent on success.

Completion: the explicitly requested topology change is confirmed from its response, fresh IDs replace stale ones, user context moved only when requested, and cleanup respects resource ownership.

## Reference

- When changing or auditing this adapted skill, load the [repository Herdr notice](../../../THIRD_PARTY_NOTICES.md#herdr) and the [exact imported upstream skill](https://github.com/ogulcancelik/herdr/blob/6cbdba434fd15fc3818302a5843593da47db2eb4/SKILL.md) to verify source revision, local-fork status, and AGPL-3.0-or-later attribution before editing.
- When installed help and remembered behavior differ, consult the [current upstream skill revision inspected for this migration](https://github.com/ogulcancelik/herdr/blob/b0d46fb9bc2a3e7fb58864939e2580b8a9a2f1bc/SKILL.md) to understand newer operating guidance, then keep the installed binary authoritative for executable syntax.
- When implementing a raw protocol client, direct request/response control, or a long-lived event subscriber, load the [socket API documentation](https://herdr.dev/docs/socket-api/); ordinary operation should stay on the CLI Activities above.

# Tmux Agent Orchestration Reference

Load this file only for tmux-specific command formation or recovery after the worker scope, ownership, isolation, names, and bounds are fixed in `SKILL.md`. Replace every placeholder with the current run's values; examples are not authorization to create additional workers or resources.

## Preflight and Runtime Variables

Use names containing only letters, digits, `_`, and `-`, and make the session name unique to the bounded run.

```bash
SOURCE=/absolute/path/to/original
SOURCE_OID=$(git -C "$SOURCE" rev-parse 'HEAD^{commit}')
CLONE_PARENT=/absolute/path/to/owned-clone-parent
BUNDLE="$CLONE_PARENT/run-name"
SESSION=agent-run-name
POLL_SECONDS=30
DEADLINE_EPOCH=0                 # replace with the agreed deadline

command -v tmux
tmux -V
PREEXISTING_SESSIONS=$(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
printf '%s\n' "$PREEXISTING_SESSIONS"
if tmux has-session -t "=$SESSION" 2>/dev/null; then
  printf 'session collision: %s\n' "$SESSION" >&2
  exit 1
fi
```

Do not kill or reuse a collision. Choose a new deterministic name only within the caller-approved run scope. Keep session/window/pane observations as current-run state, not durable workflow identity.

## Inspect the Exact Agent Command

Ask which CLI to use only when the request did not specify one. Every selected executable must pass discovery before launch:

```bash
command -v "$CLI"
"$CLI" --version
"$CLI" --help
```

Read current help for:

- working-directory selection;
- interactive versus non-interactive mode;
- whether an initial prompt is an argument or must be submitted in the TUI;
- approval, sandbox, permission, and tool controls; and
- continuation/session behavior.

Codex, Claude, Pi, and Copilot do not share one flag shape. Form and record the exact `CLI_COMMAND` for this run. Tmux's `-c "$CLONE"` establishes the pane directory, but it does not replace a CLI-specific directory flag when current help requires one. Do not carry a remembered `--yolo`, `-C`, `-p`, or permission flag across CLIs or versions.

If the selected CLI is absent or its safe command shape cannot be established, launch nothing for that worker and return to the caller's in-process fallback.

## Create and Verify Worker Clones

For each scoped task, choose one clone path, one branch, and one window name:

```bash
TASK=task-a
CLONE="$BUNDLE/$TASK"
BRANCH=worker/task-a
WINDOW=task-a

mkdir -p -- "$BUNDLE"
git clone --no-hardlinks "$SOURCE" "$CLONE"
git -C "$CLONE" switch -c "$BRANCH" "$SOURCE_OID"

realpath "$CLONE"
git -C "$CLONE" rev-parse --show-toplevel
git -C "$CLONE" branch --show-current
git -C "$CLONE" remote -v
git -C "$CLONE" status --short --branch
```

Compare canonical paths across all workers and reject duplicates. Verify the source revision is committed before cloning; uncommitted source changes are not silently transferred. A local-path `origin` is valid clone evidence and must not be repointed by this skill. If later delivery is requested, `git-delivery` discovers and validates its own topology.

If workers were accidentally started in one checkout, interrupt only affected workers, preserve their changes, create the correct clones/branches, and relaunch within the original worker bound. Do not delete the collided checkout until its work is accounted for.

## Build the Full Prompt

Store one complete prompt per worker in the owned bundle. It must state:

```text
Worker clone: <absolute clone path>
Task branch: <branch>
Task: <complete task and source authorities>
Editing authority: <exact editable files/areas>
Forbidden paths/actions: <protected scope>
Further delegation: <authorized or forbidden>
Required checks: <commands/evidence>
Required result: <commit, files, summary, limitations>
Do not edit the original checkout or another worker clone.
Return evidence to the caller; do not expand scope or claim caller acceptance.
```

Use `write` or a quoted heredoc to create the prompt without shell interpolation. Review the complete file before injecting it. Prompt files are run-owned temporary artifacts removed with the clone bundle only after results are retained.

## Launch Named Windows

Start the first worker in the named session and the rest in named windows. `CLI_COMMAND` is the exact interactive command established from current help; submit the full prompt only after its TUI is ready.

```bash
tmux new-session -d -s "$SESSION" -n "$WINDOW" -c "$CLONE" "$CLI_COMMAND"

# For each additional worker, with its own WINDOW, CLONE, and CLI_COMMAND:
tmux new-window -d -t "=$SESSION" -n "$WINDOW" -c "$CLONE" "$CLI_COMMAND"

tmux list-windows -t "=$SESSION" -F '#{window_name}'
tmux list-panes -s -t "=$SESSION" \
  -F '#{session_name}:#{window_name}.#{pane_index} #{pane_current_path} #{pane_current_command}'
```

Wait until capture output shows the CLI is ready. Target the full session/window name rather than a numeric index. For every worker, compare `pane_current_path` with `realpath "$CLONE"` before giving edit authority.

Inject the initial prompt with a run-unique named buffer:

```bash
TARGET="$SESSION:$WINDOW"
BUFFER="${SESSION}_${WINDOW}_prompt"
PROMPT_TEXT=$(<"$PROMPT_FILE")

tmux set-buffer -b "$BUFFER" -- "$PROMPT_TEXT"
tmux paste-buffer -d -b "$BUFFER" -t "$TARGET"
tmux send-keys -t "$TARGET" Enter
sleep 1
tmux capture-pane -p -S -120 -t "$TARGET"
```

If text remains in the composer with no new activity, send one raw carriage return and inspect again:

```bash
tmux send-keys -t "$TARGET" C-m
sleep 1
tmux capture-pane -p -S -120 -t "$TARGET"
```

A working indicator, new assistant/tool output, a changed capture beyond the pasted text, or corresponding Git activity proves the processing transition. Raw prompt text alone does not. If neither `Enter` nor one `C-m` produces a transition, classify the prompt as unsubmitted; do not keep sending keys blindly or add a replacement worker beyond the bound.

## Steer an Existing TUI

Capture before steering, inject one concise follow-up through a unique buffer, and capture after each submission attempt:

```bash
TARGET="$SESSION:$WINDOW"
BUFFER="${SESSION}_${WINDOW}_followup"
BEFORE=$(tmux capture-pane -p -S -120 -t "$TARGET")

tmux set-buffer -b "$BUFFER" -- "$FOLLOWUP"
tmux paste-buffer -d -b "$BUFFER" -t "$TARGET"
tmux send-keys -t "$TARGET" Enter
sleep 1
AFTER=$(tmux capture-pane -p -S -120 -t "$TARGET")
printf '%s\n' "$AFTER"
```

If `AFTER` only adds the visible prompt, send `C-m` once and recapture. Verify new processing or Git activity before saying the worker accepted the follow-up. When steering repeatedly fails or the CLI has a safer non-interactive form, stop TUI steering and return the task to the caller's in-process fallback; do not infer a command shape without current help.

## Monitor Pane and Git State

Use the bounded cadence and deadline. Prefer named targets and the scoped session rather than polling all server panes.

```bash
TARGET="$SESSION:$WINDOW"

date -Is
tmux capture-pane -p -S -120 -t "$TARGET" | tail -n 50
tmux display-message -p -t "$TARGET" \
  '#{pane_current_path} #{pane_current_command} #{pane_dead}'
git -C "$CLONE" rev-parse --show-toplevel
git -C "$CLONE" branch --show-current
git -C "$CLONE" remote -v
git -C "$CLONE" status --short --branch
git -C "$CLONE" log --oneline --decorate -n 5
```

Classify each worker as:

- **active** — recent processing evidence and/or expected Git movement;
- **blocked** — explicit question, permission prompt, error, or missing authority;
- **exited** — pane/window ended before result evidence was collected; or
- **complete** — the worker returned its result and required pane plus Git/check evidence agrees.

An idle-looking pane may be awaiting input or finished; a vanished short-lived window may have succeeded or failed. Inspect Git state and returned output rather than guessing. On deadline, stop polling and report the latest evidence and owner/action.

For delivery tasks, monitor only transport evidence here. Invoke `git-delivery` with the delivery scope, base/head or PR identity, authorized mutations, checks, and bound; use its report for PR/CI/stale-head/pushed-head claims. Do not add GitHub, branch-rebuild, check-log, merge/rebase, or conflict-resolution commands to this reference.

## Tmux-Specific Failure Handling

### Session-name collision

**Evidence:** `tmux has-session -t "=$SESSION"` succeeds before launch.

**Response:** preserve that session. Stop or choose a new deterministic caller-approved name; never kill/reuse it as presumed stale.

### Same-checkout collision

**Evidence:** two pane paths or `rev-parse --show-toplevel` results match.

**Response:** interrupt affected workers, preserve changes, create distinct clones/branches, and relaunch only within the authorized worker set.

### Wrong clone, branch, or remote

**Evidence:** pane current path, canonical clone path, branch, or `remote -v` differs from scope.

**Response:** stop the affected worker before edits, correct or recreate its clone, reverify all four fields, and resend the complete prompt.

### Prompt not submitted

**Evidence:** raw prompt remains in the composer; capture has no working indicator, assistant/tool output, or corresponding Git activity.

**Response:** send `Enter`, inspect, then send one `C-m` only if still unsubmitted. If no transition follows, report unsubmitted and return to caller control.

### Worker blocked on authority or permission

**Evidence:** pane asks for scope, approval, sandbox, tool, credential, or destructive-action permission.

**Response:** compare the request with the recorded authority. Steer only an already-authorized clarification; otherwise return the decision to the caller. Never widen authority merely to clear a prompt.

### Worker window disappears

**Evidence:** the named window is absent before a result was collected.

**Response:** inspect the clone branch/status/log and any captured return output. Classify it as exited unless the required result and checks are independently evidenced. Relaunch in the same clone/window only when the caller's original bound and scope still authorize it.

### Monitoring deadline reached

**Evidence:** current time reaches the recorded deadline without verified completion.

**Response:** stop polling, preserve session/clones, and report each worker's pane/Git state and exact next owner/action. Do not turn timeout into cleanup authorization.

### Dirty or unretained clone at cleanup

**Evidence:** short status, branch, or expected commit/result shows work not safely retained or explicitly abandoned.

**Response:** do not remove the bundle. Return the evidence to the caller for retention or abandonment choice.

### Exact cleanup check fails

**Evidence:** the named session or exact bundle still exists after its targeted removal.

**Response:** directly rerun `tmux has-session`, `ls -ld`, or `find` for that exact resource. Report what remains; never widen to `kill-server`, wildcard deletion, a parent path, or unrelated sessions.

## Exact Cleanup

Before cleanup, collect every result and inspect every clone:

```bash
for clone in "$BUNDLE"/*; do
  test -d "$clone/.git" || continue
  printf '=== %s ===\n' "$clone"
  git -C "$clone" status --short --branch
  git -C "$clone" log --oneline --decorate -n 3
done
```

Validate the target before destructive action:

```bash
BUNDLE_REAL=$(realpath -m -- "$BUNDLE")
PARENT_REAL=$(realpath -m -- "$CLONE_PARENT")
test -n "$BUNDLE_REAL"
test "$BUNDLE_REAL" != /
case "$BUNDLE_REAL" in
  "$PARENT_REAL"/*) ;;
  *) printf 'bundle outside owned parent\n' >&2; exit 1 ;;
esac
```

Confirm that the bundle contains only this run's known clones and that all work is retained or explicitly abandoned. Then target only the exact resources:

```bash
if tmux has-session -t "=$SESSION" 2>/dev/null; then
  tmux kill-session -t "=$SESSION"
fi
if tmux has-session -t "=$SESSION" 2>/dev/null; then
  printf 'session still exists: %s\n' "$SESSION" >&2
  exit 1
fi

rm -rf -- "$BUNDLE_REAL"
if test -e "$BUNDLE_REAL"; then
  ls -ld -- "$BUNDLE_REAL"
  exit 1
fi
```

Finally list session names and compare them with `PREEXISTING_SESSIONS`:

```bash
AFTER_SESSIONS=$(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
printf '%s\n' "$AFTER_SESSIONS"
while IFS= read -r existing; do
  test -z "$existing" || printf '%s\n' "$AFTER_SESSIONS" | grep -Fx -- "$existing" >/dev/null || {
    printf 'unrelated session missing: %s\n' "$existing" >&2
    exit 1
  }
done <<EOF_SESSIONS
$PREEXISTING_SESSIONS
EOF_SESSIONS
```

Cleanup is complete only when the exact session and bundle are absent and every unrelated pre-existing session remains. If cleanup was not authorized or is blocked by unretained work, preserve resources and report their exact names/paths instead.

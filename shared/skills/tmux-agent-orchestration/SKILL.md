---
name: tmux-agent-orchestration
description: Launches, steers, and monitors multiple CLI agents in tmux with separate clones, explicit prompt submission, and progress checks. Use when running parallel Codex, Claude, or mixed CLI workers in tmux, coordinating one worker per plan/task, relaunching agents into isolated clones, or monitoring whether TUI prompts were actually submitted.
metadata:
  short-description: Orchestrate parallel CLI agents in tmux
allowed-tools: read,write,bash
---

# Tmux Agent Orchestration

## Language Definitions

- **Worker clone** — isolated checkout for one editable agent/task/branch.
- **Orchestration session** — tmux session controlling a bounded worker set.
- **TUI steering** — text/keys sent to an active interactive agent.
- **Prompt submission** — verified processing transition; pasted visible text alone is insufficient.

## Workflow

### 1. Fix the worker scope and ownership

If the caller did not select an agent CLI, ask whether to use Codex, Claude, Pi, Copilot, or a mixed set. Record the task and branch for every worker, exact editing authority and forbidden paths, checks and return evidence, whether further delegation is authorized, and the caller's acceptance criteria. Bound the worker count, orchestration session name, one deterministic window name per worker, monitoring cadence/deadline, and cleanup disposition.

The caller retains the brief, workflow state, scope changes, acceptance, and cleanup decision. If tmux or a selected CLI is unavailable, or delegated work cannot continue safely, the caller performs the authorized work in the current process under the same checks and return contract.

Completion criterion: every bounded worker has one task, branch, window, edit scope, and expected result; caller ownership and the in-process fallback are explicit.

### 2. Isolate each editable worker before transport

Create exactly one Worker clone and one task branch per worker. Pin the committed source revision, then verify each canonical clone path is unique and each clone has the expected branch and remote. A separate pane is not checkout isolation. Do not launch a worker in the original checkout or another worker's clone.

If a clone/path/branch/remote is wrong or two workers share a checkout, stop affected workers, create correct isolated clones, and relaunch only the authorized worker set.

Completion criterion: pane-independent Git evidence proves one isolated clone/task/branch for every editable worker.

### 3. Inspect the selected CLI and launch the bounded session

For each selected CLI, run `command -v`, `--version`, and current `--help`. Determine its exact working-directory, interactive or non-interactive prompt, approval/sandbox/permission, and initial-prompt shape; do not assume flags shared by another CLI.

Inventory existing tmux session names. Refuse to reuse or kill a colliding session. Launch one named Orchestration session with one named window per scoped worker, each rooted in its Worker clone and running the command formed from current help. Give each worker a full prompt containing its clone path, branch, task, editing authority and forbidden paths, delegation authority, checks, commit/return evidence, and prohibition on editing the original checkout.

Use the **Launch workers** Activity for command execution. If the CLI never becomes ready or the full prompt cannot be proven submitted, report the worker as unlaunched and use the caller's in-process fallback rather than adding an unscoped worker.

Completion criterion: the exact named windows exist, their pane paths match distinct clones, and every worker shows a verified processing transition for its full prompt.

### 4. Monitor, steer, and compose delivery without transferring ownership

At the recorded cadence, use the **Monitor pane and Git state** Activity. Correlate capture/current-command/path evidence with each clone's branch, remote, status, and recent commits. A vanished window, idle-looking pane, or worker claim alone is not completion.

For follow-up in an interactive worker, use **Steer and verify**: paste into the exact named pane, send `Enter`, inspect for a processing transition, and send `C-m` only if the prompt remains unsubmitted. Never treat visible composer text as activity.

When the task includes opening/updating a pull request, following CI to green, refreshing a stale head, or proving a pushed PR head, invoke `git-delivery`. Pass the delivery goal and commit/file scope, base/head or PR identity, permitted push/metadata/rewrite/fix changes, required checks, and polling bound. A worker may run that composed process, but the caller retains delivery state and acceptance and reviews its returned evidence. If worker transport is unavailable, the caller invokes `git-delivery` directly in the current process; do not recreate its Git/PR/CI/conflict manual here.

Completion criterion: each worker is evidenced as active, blocked, or complete from pane plus Git state; follow-ups have verified Prompt submission; and any delivery result comes from the composed owner with caller acceptance still pending.

### 5. Collect results and clean only owned resources

Record each worker's result, branch, commit and check evidence, limitations, and unresolved state. Before deleting clones, inspect for uncommitted or otherwise unretained work; stop cleanup until it is retained or the caller explicitly abandons it.

Use **Clean the orchestration run** only after the recorded cleanup condition. Kill only the exact named Orchestration session and remove only the exact owned clone bundle after validating its path and contents. Never use `kill-server`, wildcard session deletion, or broad clone removal. Verify the exact session and bundle are absent and every unrelated pre-existing session remains present.

Completion criterion: the caller has all worker evidence, cleanup is either exactly verified or blocked with the preserving reason, and no unrelated session or path changed.

## Activities

### Launch workers

For an already scoped and isolated run, create the first named window with `tmux new-session -d -s "$SESSION" -n "$WINDOW" -c "$CLONE" "$CLI_COMMAND"` and each remaining named window with `tmux new-window -d -t "$SESSION" -n "$WINDOW" -c "$CLONE" "$CLI_COMMAND"`. Use only a `CLI_COMMAND` derived from current help.

Wait for the CLI to be ready, inject the complete prompt through a uniquely named tmux buffer, delete that buffer after paste, send `Enter`, and immediately capture the pane. If the prompt remains in the composer, send `C-m` once and recapture. Stop rather than launching replacements beyond the bounded worker set when no processing transition appears.

Completion criterion: `tmux list-windows` and `tmux list-panes` show the intended names/paths, and every full prompt has transitioned to a working indicator, new assistant/tool output, changed capture, or corresponding Git activity.

### Steer and verify

Set and paste a uniquely named buffer into the exact named pane, deleting the buffer on paste. Send `Enter`, capture the pane, and confirm that raw prompt text is no longer merely sitting in the composer and that new processing evidence appears. If not, send `C-m` once and inspect again. If no transition follows, classify the prompt as unsubmitted and return control to the caller.

Completion criterion: a before/after capture or corresponding Git change proves the follow-up is processing; pasted text alone never passes.

### Monitor pane and Git state

Capture recent pane output and inspect pane current path/command. For the matching Worker clone, inspect canonical path, branch, remote, short status, and recent log. Classify the worker only from the combined evidence, and respect the recorded cadence/deadline. If a window exits, use Git evidence to determine what remains but do not infer success.

Completion criterion: every worker has a timestamped active, blocked, exited, or complete assessment supported by both available pane evidence and Git state, with missing evidence called out.

### Clean the orchestration run

Recheck the exact session name and clone-bundle path against the run scope. Refuse deletion when the bundle path is empty, `/`, outside the recorded parent, contains an unrelated clone, or has unretained changes. Kill the exact session, remove the exact bundle, then directly test that both are absent and compare session names with the pre-launch inventory.

Completion criterion: exact absence checks pass and all unrelated pre-existing sessions remain; otherwise stop and report the surviving resource without widening deletion.

## Reference

- Load [REFERENCE.md](REFERENCE.md) only after a tmux-specific failure branch is selected: session collision, same-checkout collision, wrong clone/branch/remote, prompt not submitted, blocked on authority or permission, worker window disappears, monitoring deadline reached, dirty or unretained clone at cleanup, or exact cleanup check failure. It contains recovery-only detail; ordinary launch, steering, monitoring, and cleanup commands stay in the Activities above.

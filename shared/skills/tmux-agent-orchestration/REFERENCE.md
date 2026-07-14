# Tmux Agent Orchestration Reference

Load this file only after `SKILL.md` selects a tmux-specific recovery branch. Ordinary launch, steering, monitoring, and cleanup commands stay in `SKILL.md` Activities.

## Failure Handling

### Session-name collision

**Evidence:** `tmux has-session -t "=$SESSION"` succeeds before launch.

**Response:** preserve that session. Choose a new deterministic caller-approved name within scope; never kill or reuse the colliding session.

### Same-checkout collision

**Evidence:** two pane paths or `git -C "$CLONE" rev-parse --show-toplevel` results match.

**Response:** interrupt affected workers, preserve changes, create distinct clones/branches, and relaunch only within the authorized worker set.

### Wrong clone, branch, or remote

**Evidence:** pane current path, canonical clone path, branch, or `remote -v` differs from scope.

**Response:** stop the affected worker before edits, correct or recreate its clone, reverify all four fields, and resend the complete prompt.

### Prompt not submitted

**Evidence:** raw prompt remains in the composer; capture has no working indicator, assistant/tool output, or corresponding Git activity.

**Response:** send `Enter`, inspect, then send one `C-m` only if still unsubmitted. If no transition follows, report unsubmitted and return to caller control.

### Worker blocked on authority or permission

**Evidence:** pane asks for scope, approval, sandbox, tool, credential, or destructive-action permission.

**Response:** compare the request with the recorded authority. Steer only an already-authorized clarification; otherwise return the decision to the caller.

### Worker window disappears

**Evidence:** the named window is absent before a result was collected.

**Response:** inspect the clone branch/status/log and any captured return output. Classify it as exited unless the required result and checks are independently evidenced.

### Monitoring deadline reached

**Evidence:** current time reaches the recorded deadline without verified completion.

**Response:** stop polling, preserve session/clones, and report each worker's pane/Git state and exact next owner/action.

### Dirty or unretained clone at cleanup

**Evidence:** short status, branch, or expected commit/result shows work not safely retained or explicitly abandoned.

**Response:** do not remove the bundle. Return the evidence to the caller for retention or abandonment choice.

### Exact cleanup check fails

**Evidence:** the named session or exact bundle still exists after its targeted removal.

**Response:** directly rerun `tmux has-session`, `ls -ld`, or `find` for that exact resource. Report what remains; never widen to `kill-server`, wildcard deletion, a parent path, or unrelated sessions.

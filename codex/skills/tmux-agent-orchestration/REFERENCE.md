# Tmux Agent Orchestration Reference

## Preferred Shape

For parallel implementation work:

- one `tmux` session
- one named window per task
- one separate clone per task
- one branch per task

This avoids workers stomping on each other in one worktree.

## First Step: Choose The CLI Agent

If the user has not already specified the agent CLI, ask before launching.

Recommended question:

```text
Which CLI agent should I launch in tmux for these workers: codex, claude, or a mixed setup?
```

Do not assume `codex` just because this skill is being used.

Common cases:

- `codex` everywhere
- `claude` everywhere
- Codex as the top-level orchestrator launching Claude workers
- Claude as the top-level orchestrator launching Codex workers

## Agent Command Shape

Do not hardcode `codex --yolo` as the only launch pattern.

First inspect or confirm the CLI:

```bash
command -v codex
command -v claude
codex --help | sed -n '1,120p'
claude --help | sed -n '1,120p'
```

The exact command flags, prompt submission model, and non-interactive options may differ.

Treat these as variables:

- executable name
- working-directory flag
- approval / sandbox flags
- whether initial prompt can be passed as an argument
- whether a non-interactive mode exists
- whether a TUI prompt needs special submission handling

## Launch Pattern

### 1. Create clones

Use a timestamped parent directory and one clone per task:

```bash
BASE="/home/mtomcal/code/project-clones/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BASE"
git clone /path/to/original "$BASE/task-a"
git clone /path/to/original "$BASE/task-b"
```

### 2. Start tmux session and windows

For Codex:

```bash
tmux new-session -d -s my-session -c "$BASE/task-a" -n task-a \
  "bash -lc 'codex --yolo -C \"$BASE/task-a\" \"$(cat /tmp/task-a.prompt)\"'"

tmux new-window -t my-session -c "$BASE/task-b" -n task-b \
  "bash -lc 'codex --yolo -C \"$BASE/task-b\" \"$(cat /tmp/task-b.prompt)\"'"
```

For other CLIs, adapt the command shape after checking help output.

Prompt text should explicitly include:

- the exact clone path
- do not use the original checkout
- whether subagents are authorized
- any commit / PR / verification requirements

## Steering Existing TUI Panes

This section applies to any CLI TUI, not just Codex.

### Safe prompt injection

Use `tmux set-buffer`, `paste-buffer`, then `send-keys Enter`:

```bash
tmux set-buffer -- "Open the PR now..."
tmux paste-buffer -t my-session:1
tmux send-keys -t my-session:1 Enter
```

If the prompt still appears in the composer, send a raw carriage return:

```bash
tmux send-keys -t my-session:1 C-m
```

### Required submission verification

After steering a TUI pane, always verify submission immediately.

Minimum rule:

1. paste prompt
2. send `C-m`
3. inspect the pane
4. confirm one of:
   - `Working` appears
   - new assistant or tool activity appears
   - the raw `› ...` prompt is no longer just sitting in the composer

If none of those happen, treat the prompt as not submitted and retry.

## Critical Lesson: Seeing Text Is Not Submission

A pasted prompt can sit in the TUI composer without being submitted.

Evidence that it was **not** submitted:

- the pane still shows the raw `›` prompt text
- there is no assistant response after it
- there is no `Working` indicator
- no new shell/git activity follows

Evidence that it **was** submitted:

- the pane shows `• Working`
- the model starts printing new reasoning or tool activity
- later `capture-pane` output changes beyond the pasted prompt

Always verify this after steering a pane.

This is a hard rule, not a nice-to-have.

## Monitoring Commands

### List windows and current paths

```bash
tmux list-windows -t my-session -F '#I:#W'
tmux list-panes -a -F '#S:#I:#W #{pane_current_path}'
```

### Inspect recent pane output

```bash
tmux capture-pane -p -t my-session:1 | tail -n 40
```

### Poll multiple panes

```bash
for w in 1 2 3; do
  echo "=== WINDOW $w ==="
  tmux capture-pane -p -t my-session:$w | tail -n 30
done
```

### Check clone state

```bash
git -C /path/to/clone status --short
git -C /path/to/clone log --oneline --decorate -n 3
git -C /path/to/clone remote -v
```

## Clone Isolation Rules

For coding tasks, always verify:

- each pane path is a different clone
- each clone has the expected remote
- each clone is on the expected branch

Useful check:

```bash
tmux list-panes -a -F '#S:#I:#W #{pane_current_path}'
```

If workers were started in the same checkout by mistake:

1. stop or interrupt them
2. create separate clones
3. relaunch each worker against its own clone
4. state clearly in each prompt that the clone is exclusive and the original checkout must not be modified

## PR Kickoff Guidance

If implementation workers are done and need PRs:

- prefer giving the PR task in the worker's initial prompt if you already know that is required
- otherwise steer the pane with a very short concrete follow-up
- include branch name, commit to cherry-pick, base branch, and PR title/body requirements

Example follow-up:

```text
Open the PR now. Repoint origin to the GitHub repo, create branch codex/task-name from origin/main, cherry-pick only <commit>, push, and run gh pr create --base main.
```

## Clean PR Branch Workflow

Do not assume the worker's current branch is PR-ready.

Preferred PR shape:

1. verify the implementation commit hash
2. verify the clone remote points at GitHub, not a local path
3. fetch `origin`
4. create a fresh branch from `origin/main`
5. cherry-pick only the intended implementation commit
6. push that branch
7. create the PR

Why:

- worker clones may still contain earlier setup commits
- worker branches may start from a docs or scaffolding commit
- unrelated local changes may exist in the clone

### Remote sanity check

Before pushing a PR branch, confirm the clone remote:

```bash
git -C /path/to/clone remote -v
```

If `origin` points at a local path, repoint it or add a GitHub remote first.

## CI Follow-Through

After a PR is opened, do not stop at `PR created`.

Check status:

```bash
gh pr checks <pr-number>
gh pr view <pr-number> --json statusCheckRollup
```

If CI is red:

1. route the original worker back onto that same PR
2. tell it to stay on the PR until checks are green
3. pull logs for the failing run
4. reproduce locally in the worker clone
5. fix, push, and continue monitoring

Useful commands:

```bash
gh run view <run-id> --log-failed
gh run view <run-id> --job <job-id> --log
```

Hard rule:

- `fix pushed` is not done
- `all required checks green` is done

## When To Avoid TUI Steering

For one-shot tasks like opening a PR, a non-interactive mode such as `codex exec` can be more reliable than steering an idle TUI pane.

Use TUI steering when:

- you want the same worker context to continue
- you are actively watching the pane
- you verify submission succeeded

Use a non-interactive path when:

- you need deterministic execution
- you want captured output
- the TUI keeps leaving prompts in the composer
- the chosen CLI has a better non-interactive path than its TUI
- the task is a one-shot operational step such as opening a PR

## Failure Modes To Watch For

### Same-worktree collision

Symptom:
- multiple workers modify one checkout

Fix:
- stop them and relaunch in separate clones

### Prompt not submitted

Symptom:
- raw prompt remains visible as `› ...`

Fix:
- send `Enter` or `C-m`, then verify `Working`

### Wrong remote in clones

Symptom:
- clone `origin` points at a local path

Fix:
- repoint origin or add a GitHub remote before push/PR work

### Temporary tmux windows disappear

Symptom:
- short-lived jobs exit and their window numbers vanish

Fix:
- inspect outcomes via git state, remote branches, or PR list instead of assuming they completed

## Monitoring Cadence

For each worker, keep checking:

1. pane output
2. clone path
3. branch name
4. remote correctness
5. intended commit present
6. PR created
7. CI green

Useful commands:

```bash
tmux capture-pane -p -t my-session:1 | tail -n 40
git -C /path/to/clone status --short
git -C /path/to/clone log --oneline --decorate -n 3
gh pr list --state open
gh pr checks <pr-number>
git ls-remote --heads https://github.com/owner/repo.git 'codex/*'
```

## Checklist

- [ ] ask which CLI agent to use unless already specified
- [ ] confirm the chosen CLI command shape before launch
- [ ] one clone per worker
- [ ] named tmux session and windows
- [ ] initial prompt includes clone path and authorization rules
- [ ] TUI follow-up prompts are actually submitted and verified with `Working` or new activity
- [ ] pane shows `Working` after steering
- [ ] clone remotes are correct before push/PR tasks
- [ ] PRs are created from clean branches off `origin/main`
- [ ] CI is monitored until green, not just until PR creation
- [ ] monitor by pane output and git state, not assumption

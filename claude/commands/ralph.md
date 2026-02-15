# Ralph: Configure and Launch a loop.sh Agent Job

You are setting up a `loop.sh` agentic loop job. Walk the user through configuring the three files and the launch command.

## Background

Ralph runs Claude Code in a loop via `loop.sh`. Each iteration reads a prompt file fresh, does work, and repeats until output contains `/done` or the iteration limit is hit. An optional orchestrator (separate Claude session) monitors progress and writes course corrections into the prompt file between iterations.

The system has three files with distinct responsibilities:
- **PROMPT.md** — concise task instructions the worker reads every iteration (keep it small)
- **IMPLEMENTATION_PLAN.md** — heavy reference: change context, task order, progress checklist, process rules (worker reads once per iteration, updates progress/discoveries here)
- **ORCHESTRATOR.md** — monitoring playbook for a human or second Claude session

## Your Task

### Step 1: Gather Configuration

Ask the user (use AskUserQuestion tool):

1. **What should the worker accomplish?** — The task description. Be specific about what success looks like.
2. **Bare metal or Docker sandbox?** — Sandbox adds resource limits and isolation.
3. **Max iterations?** — Default 25, 0 = unlimited.
4. **Prompt file name?** — Default PROMPT.md.
5. **Run in a git worktree?** — Give the work a short name (e.g. `auth-refactor`). This creates an isolated worktree so multiple ralph jobs can run in parallel without collision. Leave blank to run in the current directory.

### Step 1.5: Create Worktree (if user provided a name)

If the user provided a worktree name, create an isolated worktree:

1. Detect the repo root (`git rev-parse --show-toplevel`) and repo name (basename of repo root)
2. Slugify the work name: lowercase, replace spaces/special chars with hyphens, strip leading/trailing hyphens
3. Compute the worktrees directory as a **sibling** to the repo root: `{repo-root}/../{repo-name}-worktrees/` (e.g. if repo is at `~/projects/myapp`, worktrees go to `~/projects/myapp-worktrees/`)
4. Create the worktrees directory if it doesn't exist: `mkdir -p {worktrees-dir}`
5. Run `git worktree add {worktrees-dir}/{slugified-name} -b ralph/{slugified-name}` to create the worktree with a new branch based on current HEAD
6. Copy `loop.sh` into the worktree if it exists in the repo root (worker needs it)
7. Tell the user the worktree was created and that they should `cd` into it (or launch loop.sh from that path)
8. Write all subsequent files (PROMPT.md, IMPLEMENTATION_PLAN.md, ORCHESTRATOR.md) into the worktree directory

If the user left the worktree name blank, proceed as before (no worktree, all files written to current directory).

### Step 2: Write PROMPT.md

The prompt must be **concise and natural** — like casual instructions to a competent developer. No headers, no formal structure. Follow this format exactly:

```
{one sentence describing what to do each iteration — reference the plan file by name}

IMPORTANT:

check the course corrections section FIRST every iteration — follow any active corrections before doing anything else.
{constraint: what files CAN be edited}
{constraint: what files CANNOT be edited}
{update instruction: tell worker to update the plan file when done / when discovering new things}
{commit convention if applicable}
output `/done` when {completion criteria}.
```

Key rules:
- ONE checklist item per iteration — worker does one item, commits, then stops. The loop restarts fresh for the next one.
- NO progress tracking in PROMPT.md — that lives in the plan file
- NO discoveries section in PROMPT.md — worker updates the plan file directly
- Keep it under 20 lines
- Each iteration reads this fresh, so it must be self-contained
- The orchestrator appends `CORRECTION: {message}` lines to the IMPORTANT section
- **Worktree cleanup rule:** When running in a worktree, add this line to the IMPORTANT section: `When outputting /done, first delete PROMPT.md, IMPLEMENTATION_PLAN.md, and ORCHESTRATOR.md, then commit the deletion with message "chore: clean up ralph job files", then merge this branch into main with "git checkout main && git merge ralph/{name}", then output /done. This prevents merge conflicts and lands the work on main automatically.`

### Step 3: Write IMPLEMENTATION_PLAN.md

This is the heavy reference file. Include these sections:

1. **Context table** — What changed since the task was defined. Columns: #, Feature/Change, Key Files, Affected Items. This gives the worker orientation.

2. **Task order** — Ordered by risk/priority. Group into tiers (High/Medium/Low priority) with a "What to Check" column.

3. **Progress checklist** — `- [ ] 1. item-name` for every task item. Worker checks these off.

4. **Discoveries section** — Tells the worker to add rows to the context table when they find things the plan missed.

5. **Per-item process** — Numbered steps the worker follows for each task item (read, diff, edit, commit, check off).

6. **Rules** — Numbered list of constraints (read before editing, preserve structure, update don't rewrite, code is truth, etc). Tailor to the specific task.

### Step 4: Write ORCHESTRATOR.md

Create the monitoring playbook with these sections:

**How to Run** — Launch command with `SANDBOX=1` env var for Docker mode, or bare. The orchestrator launches the loop in the background from its own Claude session and auto-checks on a blocking 5-minute interval (`sleep 300` between cycles).

**What to Check** — 7 checks:
1. **Progress** — Read plan file, count `[x]` vs `[ ]`
2. **Git History** — `git log --oneline -10`. Red flags: wrong files touched, thrashing, stuck
3. **Latest Log** — Read most recent `.loop-logs/iteration-*.log`. Look for errors, drift
4. **Diff Size** — `git diff --stat HEAD~1`. Red flag: 200+ lines in one file = rewrite
5. **Discoveries** — Check if worker added new rows to the plan's context table. If a discovery affects completed items, write a correction
6. **Container Resources** — `docker stats --no-stream` filtered to sandbox container. Red flags: memory >80% of limit (OOM risk), PIDs near cap, CPU pegged
7. **Spot Check** — Read one recently-committed file. Verify quality.

**Course Corrections** — Append `CORRECTION: {what's wrong and what to do}` to PROMPT.md's IMPORTANT section. Worker picks it up next iteration.

**Status Report Template:**
```
## Check #{N} — {time}

**Progress:** {X}/{total} complete ({Y} since last check)
**Current item:** {name}
**Health:** {OK | WARNING | PROBLEM}
**Container:** {MEM usage/limit, CPU%, PIDs} or "bare mode"
**Recent commits:** {list}
```

**Post-Job Cleanup (worktree mode only):**

When the job is running in a worktree, add this section to the orchestrator playbook:

- After the worker outputs `/done`, verify the job files (PROMPT.md, IMPLEMENTATION_PLAN.md, ORCHESTRATOR.md) were deleted and the deletion was committed
- If not, manually delete them and commit: `rm PROMPT.md IMPLEMENTATION_PLAN.md ORCHESTRATOR.md && git add -A && git commit -m "chore: clean up ralph job files"`
- Verify the branch was merged to main. If not, merge it: `git checkout main && git merge ralph/{name}`
- From the main repo, remove the worktree: `git worktree remove ../{repo-name}-worktrees/{name}`
- Delete the branch: `git branch -d ralph/{name}`

**When to Intervene vs Let It Run:**
- **Let it run:** steady progress, reasonable diff sizes, correct commit pattern
- **Write a correction:** wrong files edited, rewrites instead of targeted edits, stuck 2+ iterations, skipping items, not committing
- **Alert the user:** error loop, garbled output, fundamental misunderstanding, faking progress

### Step 5: Show Summary

```
Ralph Job Configuration
━━━━━━━━━━━━━━━━━━━━━━
Prompt:       {file}
Plan:         IMPLEMENTATION_PLAN.md
Orchestrator: ORCHESTRATOR.md
Mode:         {bare | sandbox}
Iterations:   {N | unlimited}
Resources:    {memory/cpu/pids if sandbox}
Worktree:     {path | "none (running in current directory)"}
Branch:       {ralph/{slugified-name} | "(current branch)"}

Launch (sandbox):
  SANDBOX=1 ./loop.sh {iterations} {prompt_file}

Launch (bare):
  ./loop.sh {iterations} {prompt_file}

Orchestrator auto-checks every 5 min (blocking sleep).
```

When running in a worktree, also show:
```
Worktree launch:
  cd ../{repo-name}-worktrees/{name} && ./loop.sh {iterations} {prompt_file}

Cleanup (after job completes):
  git checkout main && git merge ralph/{name}   # if not already merged
  git worktree remove ../{repo-name}-worktrees/{name}
  git branch -d ralph/{name}
```

## Important Notes

- `loop.sh` must already exist in the project root (this command does NOT create it)
- Auth resolved automatically: ANTHROPIC_API_KEY > CLAUDE_CODE_OAUTH_TOKEN > ~/.claude/.credentials.json
- OAuth tokens expire after ~8h; API keys are more reliable for long sessions
- Logs go to `.loop-logs/iteration-{N}.log` (gitignored)
- Worker uses `--dangerously-skip-permissions` and `--model opus`
- The done pattern is `/done` — worker must output this exact string when finished
- The worker updates the plan file (progress, discoveries) — the orchestrator NEVER edits the plan, only PROMPT.md

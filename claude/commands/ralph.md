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
- NO progress tracking in PROMPT.md — that lives in the plan file
- NO discoveries section in PROMPT.md — worker updates the plan file directly
- Keep it under 20 lines
- Each iteration reads this fresh, so it must be self-contained
- The orchestrator appends `CORRECTION: {message}` lines to the IMPORTANT section

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

Launch (sandbox):
  SANDBOX=1 ./loop.sh {iterations} {prompt_file}

Launch (bare):
  ./loop.sh {iterations} {prompt_file}

Orchestrator auto-checks every 5 min (blocking sleep).
```

## Important Notes

- `loop.sh` must already exist in the project root (this command does NOT create it)
- Auth resolved automatically: ANTHROPIC_API_KEY > CLAUDE_CODE_OAUTH_TOKEN > ~/.claude/.credentials.json
- OAuth tokens expire after ~8h; API keys are more reliable for long sessions
- Logs go to `.loop-logs/iteration-{N}.log` (gitignored)
- Worker uses `--dangerously-skip-permissions` and `--model opus`
- The done pattern is `/done` — worker must output this exact string when finished
- The worker updates the plan file (progress, discoveries) — the orchestrator NEVER edits the plan, only PROMPT.md

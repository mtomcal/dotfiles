---
description: Configure and launch a loop.sh agentic loop job (PROMPT + IMPLEMENTATION_PLAN + ORCHESTRATOR)
---

# Ralph: Configure and Launch a loop.sh Agent Job

You are setting up a `loop.sh` agentic loop job. Walk the user through configuring the three files and the launch command.

## Background

Ralph runs an AI coding assistant in a loop via `loop.sh`. Each iteration reads a prompt file fresh, does work, and repeats until output contains `/done` or the iteration limit is hit. An optional orchestrator (separate session) monitors progress and writes course corrections into the prompt file between iterations.

The system has three files with distinct responsibilities:
- **PROMPT.md** - concise task instructions the worker reads every iteration (keep it small)
- **IMPLEMENTATION_PLAN.md** - heavy reference: change context, task order, progress checklist, process rules (worker reads once per iteration, updates progress/discoveries here)
- **ORCHESTRATOR.md** - monitoring playbook for a human or second agent session

## Your Task

### Step 1: Gather Configuration

Ask the user:

1. **What should the worker accomplish?** - The task description. Be specific about what success looks like.
2. **Bare metal or Docker sandbox?** - Sandbox adds resource limits and isolation.
3. **Max iterations?** - Default 25, 0 = unlimited.
4. **Prompt file name?** - Default PROMPT.md.

### Step 2: Write PROMPT.md

The prompt must be **concise and natural** - like casual instructions to a competent developer. No headers, no formal structure. Follow this format exactly:

```
{one sentence describing what to do each iteration - reference the plan file by name}

IMPORTANT:

check the course corrections section FIRST every iteration - follow any active corrections before doing anything else.
{constraint: what files CAN be edited}
{constraint: what files CANNOT be edited}
{update instruction: tell worker to update the plan file when done / when discovering new things}
after implementing, use the @test-quality-verifier agent to check test quality. Fix any issues it finds before committing.
{commit convention if applicable}
commit your work at the end of every iteration. Use git author: `git commit --author="{user's git name} <{user's git email}>"`.
output `/done` when {completion criteria}.
```

Key rules:
- Before writing PROMPT.md, detect the user's git identity with `git config user.name` and `git config user.email`. Bake the `--author` flag into the commit instruction so the worker always commits as the user.
- ONE checklist item per iteration - worker does one item, commits, then stops. The loop restarts fresh for the next one.
- NO progress tracking in PROMPT.md - that lives in the plan file
- NO discoveries section in PROMPT.md - worker updates the plan file directly
- Keep it under 20 lines
- Each iteration reads this fresh, so it must be self-contained
- The orchestrator appends `CORRECTION: {message}` lines to the IMPORTANT section

### Step 3: Write IMPLEMENTATION_PLAN.md

This is the heavy reference file. Include these sections:

1. **Context table** - What changed since the task was defined. Columns: #, Feature/Change, Key Files, Affected Items. This gives the worker orientation.
2. **Task order** - Ordered by risk/priority. Group into tiers (High/Medium/Low priority) with a "What to Check" column.
3. **Progress checklist** - `- [ ] 1. item-name` for every task item. Worker checks these off.
4. **Discoveries section** - Tells the worker to add rows to the context table when they find things the plan missed.
5. **Per-item process** - Numbered steps the worker follows for each task item (read, diff, edit, commit, check off).
6. **Rules** - Numbered list of constraints (read before editing, preserve structure, update don't rewrite, code is truth, etc). Tailor to the specific task.

### Step 4: Write ORCHESTRATOR.md

Create the monitoring playbook with these sections:

- **How to Run** - Use a second terminal/tmux pane in a separate session. It should monitor on a blocking 5-minute interval (`sleep 300` between cycles).
- **What to Check** - Progress, git history, latest loop log, diff size, discoveries, container resources, spot-check one recent file.
- **Course Corrections** - Append `CORRECTION: {what's wrong and what to do}` to PROMPT.md's IMPORTANT section. Worker picks it up next iteration.
- **Status Report Template**:

```
## Check #{N} - {time}

**Progress:** {X}/{total} complete ({Y} since last check)
**Current item:** {name}
**Health:** {OK | WARNING | PROBLEM}
**Container:** {MEM usage/limit, CPU%, PIDs} or "bare mode"
**Recent commits:** {list}
```

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
```

## Important Notes

- If `loop.sh` doesn't exist in the project root, offer to create it from the reference template below
- Auth resolved automatically: ANTHROPIC_API_KEY > CLAUDE_CODE_OAUTH_TOKEN > ~/.claude/.credentials.json
- OAuth tokens expire after ~8h; API keys are more reliable for long sessions
- Logs go to `.loop-logs/iteration-{N}.log` (gitignored)
- Worker uses `--dangerously-skip-permissions` and `--model opus`
- The done pattern is `/done` - worker must output this exact string when finished
- The worker updates the plan file (progress, discoveries) - the orchestrator NEVER edits the plan, only PROMPT.md
- The worker should use the `test-quality-verifier` agent after implementation and before committing each iteration. This agent detects vague assertions, checks coverage, and adds tests if needed.

## Reference: loop.sh

If the project doesn't have `loop.sh`, offer to create one using this template. Adapt the `SANDBOX_IMAGE` default to the project name.

Use: `~/dotfiles/opencode/skills/ralph/references/loop.sh`

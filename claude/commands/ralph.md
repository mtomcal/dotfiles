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
commit your work at the end of every iteration.
output `/done` when {completion criteria}.
```

Key rules:
- ONE checklist item per iteration — worker does one item, commits, then stops. The loop restarts fresh for the next one.
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

- If `loop.sh` doesn't exist in the project root, offer to create it from the reference template below
- Auth resolved automatically: ANTHROPIC_API_KEY > CLAUDE_CODE_OAUTH_TOKEN > ~/.claude/.credentials.json
- OAuth tokens expire after ~8h; API keys are more reliable for long sessions
- Logs go to `.loop-logs/iteration-{N}.log` (gitignored)
- Worker uses `--dangerously-skip-permissions` and `--model opus`
- The done pattern is `/done` — worker must output this exact string when finished
- The worker updates the plan file (progress, discoveries) — the orchestrator NEVER edits the plan, only PROMPT.md

## Reference: loop.sh

If the project doesn't have `loop.sh`, offer to create one using this template. Adapt the `SANDBOX_IMAGE` default to the project name.

```bash
#!/bin/bash
# Usage: ./loop.sh [max_iterations] [prompt_file]
# Examples:
#   ./loop.sh              # Unlimited iterations, PROMPT.md
#   ./loop.sh 20           # Max 20 iterations
#   ./loop.sh 20 TASK.md   # Custom prompt file
#
# Environment variables:
#   SANDBOX=1              # Run Claude inside a Docker container
#   MEMORY_LIMIT=8g        # Container memory cap (default: 8g)
#   CPU_LIMIT=4            # Container CPU cap (default: 4)
#   PIDS_LIMIT=512         # Container PID cap (default: 512)
#   SANDBOX_IMAGE=project-sandbox  # Docker image name
#   SANDBOX_NETWORK=sandbox-net    # Docker network name
#   JOB_NAME=my-task               # Job name for container identification (default: basename of cwd)

MAX_ITERATIONS=${1:-0}
PROMPT_FILE=${2:-PROMPT.md}
JOB_NAME=${JOB_NAME:-$(basename "$(pwd)")}
ITERATION=0
CURRENT_BRANCH=$(git branch --show-current)
LOG_DIR=".loop-logs"
DONE_PATTERN="/done"
SANDBOX=${SANDBOX:-0}

mkdir -p "$LOG_DIR"

# --- Sandbox auto-build ---
if [ "$SANDBOX" = "1" ]; then
    IMAGE="${SANDBOX_IMAGE:-project-sandbox}"
    if ! docker image inspect "$IMAGE" &>/dev/null; then
        echo "Sandbox image '$IMAGE' not found — building..."
        docker build \
            --build-arg USER_ID="$(id -u)" \
            --build-arg GROUP_ID="$(id -g)" \
            -t "$IMAGE" \
            -f Dockerfile.sandbox .
        echo "Image '$IMAGE' built successfully"
    fi
fi

# --- Claude auth (sandbox mode) ---
# Priority: ANTHROPIC_API_KEY > CLAUDE_CODE_OAUTH_TOKEN > auto-extract
# OAuth tokens expire after ~8h but loop.sh re-extracts each iteration.
# For long sessions, ANTHROPIC_API_KEY is more reliable.
resolve_claude_auth() {
    if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        return 0
    fi
    if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
        return 0
    fi
    local CREDS="$HOME/.claude/.credentials.json"
    if [ -f "$CREDS" ]; then
        CLAUDE_CODE_OAUTH_TOKEN=$(python3 -c "
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    print(d.get('claudeAiOauth', {}).get('accessToken', ''))
except Exception:
    pass
" "$CREDS" 2>/dev/null || true)
        export CLAUDE_CODE_OAUTH_TOKEN
    fi
    if [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
        echo "warning: no Claude auth found. Worker will show login prompt." >&2
        echo "  fix: export ANTHROPIC_API_KEY=sk-ant-... or run 'claude login' on host." >&2
    fi
}

# --- Git auth (sandbox mode) ---
resolve_git_auth() {
    GH_TOKEN="${GH_TOKEN:-}"
    if [ -z "$GH_TOKEN" ] && command -v gh &>/dev/null; then
        GH_TOKEN=$(gh auth token 2>/dev/null || true)
    fi
    if [ -z "$GH_TOKEN" ]; then
        echo "warning: no GH_TOKEN found. git push will fail inside the container." >&2
        echo "  fix: run 'gh auth login' or export GH_TOKEN=ghp_..." >&2
    fi
    export GH_TOKEN
}

# --- Claude execution functions ---

run_claude_bare() {
    local prompt_file="$1"
    local iter_log="$2"

    cat "$prompt_file" | claude -p \
        --dangerously-skip-permissions \
        --output-format=stream-json \
        --model opus \
        --verbose 2>&1 | tee "$iter_log.raw" | jq -jr '
  (.event.delta.text // empty),
  (select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text // empty)
' | tee "$iter_log"
}

run_claude_sandboxed() {
    local prompt_file="$1"
    local iter_log="$2"

    resolve_claude_auth
    resolve_git_auth

    local CLAUDE_SETTINGS
    CLAUDE_SETTINGS=$(readlink -f "$HOME/.claude/settings.json" 2>/dev/null || echo "$HOME/.claude/settings.json")

    local TTY_FLAG=""
    [ -t 0 ] && TTY_FLAG="-it"

    docker run --rm $TTY_FLAG \
        --name "ralph-${JOB_NAME}-${ITERATION}" \
        --memory="${MEMORY_LIMIT:-8g}" \
        --memory-swap="${MEMORY_LIMIT:-8g}" \
        --cpus="${CPU_LIMIT:-4}" \
        --pids-limit="${PIDS_LIMIT:-512}" \
        --network="${SANDBOX_NETWORK:-sandbox-net}" \
        -v "$(pwd):/workspace" \
        -v "$CLAUDE_SETTINGS:/home/loopuser/.claude/settings.json:ro" \
        -v "$HOME/.claude/projects:/home/loopuser/.claude/projects" \
        -e ANTHROPIC_API_KEY \
        -e CLAUDE_CODE_OAUTH_TOKEN \
        -e DISABLE_AUTOUPDATER=1 \
        -e "GH_TOKEN=$GH_TOKEN" \
        -w /workspace \
        "${SANDBOX_IMAGE:-project-sandbox}" \
        sh -c "claude -p \
            --dangerously-skip-permissions \
            --output-format=stream-json \
            --model opus \
            --verbose < /workspace/$prompt_file 2>&1" \
        | tee "$iter_log.raw" \
        | jq -jr '
            (.event.delta.text // empty),
            (select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text // empty)
        ' | tee "$iter_log"
}

# --- Banner ---
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Prompt: $PROMPT_FILE"
echo "Branch: $CURRENT_BRANCH"
echo "Logs:   $LOG_DIR/"
[ "$MAX_ITERATIONS" -gt 0 ] && echo "Max:    $MAX_ITERATIONS iterations"
echo "Done:   when output contains '$DONE_PATTERN'"
if [ "$SANDBOX" = "1" ]; then
    echo "Mode:   SANDBOX (Docker)"
    echo "  Image:   ${SANDBOX_IMAGE:-project-sandbox}"
    echo "  Network: ${SANDBOX_NETWORK:-sandbox-net}"
    echo "  Memory:  ${MEMORY_LIMIT:-8g}"
    echo "  CPUs:    ${CPU_LIMIT:-4}"
    echo "  PIDs:    ${PIDS_LIMIT:-512}"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: $PROMPT_FILE not found"
    exit 1
fi

while true; do
    ITERATION=$((ITERATION + 1))

    if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$ITERATION" -gt "$MAX_ITERATIONS" ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"
        break
    fi

    echo -e "\n======================== ITERATION $ITERATION ========================"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"

    ITER_LOG="$LOG_DIR/iteration-$ITERATION.log"

    if [ "$SANDBOX" = "1" ]; then
        run_claude_sandboxed "$PROMPT_FILE" "$ITER_LOG"
    else
        run_claude_bare "$PROMPT_FILE" "$ITER_LOG"
    fi
    EXIT_CODE=${PIPESTATUS[0]}

    echo ""
    echo "Finished: $(date '+%Y-%m-%d %H:%M:%S')"

    if [ "$SANDBOX" = "1" ] && [ "$EXIT_CODE" -ne 0 ]; then
        case $EXIT_CODE in
            137)
                echo "WARNING: Container OOM-killed (hit ${MEMORY_LIMIT:-8g} limit)"
                echo "  Iteration $ITERATION lost — restarting in 5s"
                sleep 5
                continue
                ;;
            124)
                echo "WARNING: Container timed out"
                sleep 5
                continue
                ;;
            *)
                echo "WARNING: Container exited with code $EXIT_CODE"
                sleep 5
                continue
                ;;
        esac
    fi

    if grep -q "$DONE_PATTERN" "$ITER_LOG"; then
        echo "Done pattern found in output - task completed"

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Loop completed after $ITERATION iteration(s)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        break
    fi

    echo "Continuing to next iteration..."
    sleep 2
done
```

## Reference: Dockerfile.sandbox

If the user chose sandbox mode and the project doesn't have `Dockerfile.sandbox`, offer to create one using this template. Tailor the dependency installation section to the project's language/toolchain.

```dockerfile
FROM ubuntu:24.04

# Base tools required by Claude Code, git, and project builds
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git jq curl ca-certificates gnupg \
        libicu74 libstdc++6 \
        make \
    && rm -rf /var/lib/apt/lists/*

# Node.js 22 via NodeSource (required by Claude Code)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# --- Project-specific dependencies ---
# Add language runtimes, build tools, etc. for the project here.
# Examples:
#   # Go
#   RUN curl -fsSL https://go.dev/dl/go1.24.1.linux-amd64.tar.gz | tar -C /usr/local -xz
#   ENV PATH="/usr/local/go/bin:${PATH}"
#
#   # Python
#   RUN apt-get update && apt-get install -y python3 python3-pip && rm -rf /var/lib/apt/lists/*

# Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Run as non-root user matching host UID (avoids permission issues on bind mounts)
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN if getent passwd $USER_ID >/dev/null; then userdel -r $(getent passwd $USER_ID | cut -d: -f1); fi && \
    if getent group $GROUP_ID >/dev/null; then groupdel $(getent group $GROUP_ID | cut -d: -f1) 2>/dev/null || true; fi && \
    groupadd -g $GROUP_ID loopuser && \
    useradd -m -u $USER_ID -g $GROUP_ID loopuser

# Pre-configure Claude Code to skip first-time theme picker
RUN mkdir -p /home/loopuser/.claude && \
    echo '{"theme":"dark"}' > /home/loopuser/.claude/settings.local.json && \
    chown -R $USER_ID:$GROUP_ID /home/loopuser/.claude

USER loopuser

# Git auth: use GH_TOKEN env var for HTTPS pushes (no SSH keys needed)
RUN git config --global credential.https://github.com.helper \
    '!f() { echo "protocol=https"; echo "host=github.com"; echo "username=x-access-token"; echo "password=$GH_TOKEN"; }; f'

WORKDIR /workspace
ENTRYPOINT []
CMD ["bash"]
```

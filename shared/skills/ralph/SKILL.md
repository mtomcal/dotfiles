---
name: ralph
description: Configure and run a bounded loop.sh agentic job with PROMPT.md, IMPLEMENTATION_PLAN.md, and optional ORCHESTRATOR.md monitoring. Use when setting up or launching a loop.sh iterative agentic job.
metadata:
  short-description: Set up loop.sh iterative jobs
allowed-tools: read,write,edit,bash
---

# Ralph (Loop Job Runner)

## Language Definitions

- **Ralph job** — repeated fresh-agent execution driven by a prompt and mutable checklist until a bound or sentinel.
- **Worker iteration** — one execution that rereads the prompt, completes one checklist item, updates state, commits, and exits.
- **Ralph job plan** — mutable `IMPLEMENTATION_PLAN.md`, distinct from the repository plan workspace.
- **Orchestrator** — optional monitor that adds corrections without doing the worker item.
- **Course correction** — high-priority instruction prepended after drift or failure.
- **Done sentinel** — exact `/done` final output that stops a complete job.

## Workflow

Use this workflow to configure or launch a bounded Ralph job. It owns its Ralph job plan; do not treat that file as a `create-plan` plan workspace or import that workflow's state transitions.

### 1. Configure the job artifacts

Create these files in the job repository:

- `PROMPT.md` — concise worker instructions, preferably about 20 lines. Its first line names `IMPLEMENTATION_PLAN.md` and tells every fresh worker to read the `IMPORTANT:` course corrections immediately below it before doing anything else. Require exactly one remaining checklist item per iteration, relevant tests, a Ralph job plan update with progress and discoveries, at least one commit, and then exit.
- `IMPLEMENTATION_PLAN.md` — the worker-owned task order, checklist, discoveries, rules, and verification evidence. Check off work only after its evidence exists.
- `ORCHESTRATOR.md` — optional playbook for a separately started monitor. If used, tell it to inspect `.loop-logs` and Git, prepend `IMPORTANT:` course corrections to `PROMPT.md`, avoid doing worker items or owning the Ralph job plan, and stop when the runner exits.

After test changes, require the worker to invoke or follow the shared `test-quality-verifier` skill and record the result in the Ralph job plan. Permit `/done` only as the complete final response after the final item, plan updates, tests, test-quality routing when applicable, and commit are complete. Explanatory text containing `/done` is not completion.

Completion criterion: the prompt routes every fresh worker through one item and checkable evidence; the Ralph job plan has the full mutable checklist; and any optional orchestrator playbook has a separately launched monitor and no worker authority.

### 2. Install and validate the runner

Resolve `RALPH_SKILL_DIR` to the absolute directory of this loaded skill, inspect any existing project `loop.sh`, and obtain approval before replacing it. Install the required [runner template](references/loop.sh) as an executable project file:

```bash
install -m 0755 "$RALPH_SKILL_DIR/references/loop.sh" ./loop.sh
```

The runner requires Codex, a readable prompt, and a Git repository with an existing `HEAD`. It accepts only a positive iteration bound, defaults to 25 and `PROMPT.md`, and validates `SANDBOX_MODE` before starting. It retains combined output, final worker responses, and commit evidence under `.loop-logs/`. Every invocation allocates persistent evidence sequence numbers above all existing logs, final messages, and durable claim markers; it never reuses an earlier invocation's paths.

Completion criterion: `./loop.sh` is the reviewed executable template, `bash -n ./loop.sh` passes, required files and Git state exist, and no existing runner was overwritten without approval.

### 3. Select the sandbox and launch

Use `workspace-write` for normal jobs. `read-only` remains available for a diagnostic execution, but it cannot satisfy the required plan update and descendant commit, so expect the runner to stop rather than complete. Before selecting `danger-full-access`, explain the requested unrestricted access and obtain explicit human approval for this job; only then set the approval evidence:

```bash
export SANDBOX_MODE=danger-full-access
export RALPH_DANGER_FULL_ACCESS_APPROVED=1
```

Launch the default bounded job with `./loop.sh`, or use `./loop.sh <max_iterations> <prompt_file>`. The bound applies only to workers launched by this invocation, independent of retained evidence sequence numbers. Each worker iteration starts a fresh `codex exec`, rereads the current prompt, and must advance `HEAD` by at least one descendant commit. The runner logs the commit count, hashes, and subjects before continuing.

Completion criterion: the selected sandbox is approved, the bound is positive (25 when omitted), and the foreground runner starts a fresh logged worker iteration at a new evidence sequence. This skill and runner do not read `ORCHESTRATOR.md` or launch an orchestrator process.

### 4. Monitor, correct, and recover

Inspect `.loop-logs/iteration-N.log`, the matching `.last-message.md`, the Ralph job plan, and the recorded Git range. A separately launched orchestrator may perform the same observation and prepend course corrections; edits during an active iteration apply only when the next fresh worker rereads the prompt.

The runner stops non-zero on invalid setup, Codex or logging failure, missing or rewritten commit history, evidence-path collision, or bound exhaustion without the exact sentinel. It never advances automatically after failure and never removes, truncates, appends to, or replaces evidence from an earlier invocation. Preserve the logs, diagnose the failed iteration, add a course correction when needed, and rerun explicitly; the rerun allocates a new evidence sequence while retaining prior log and final-message bytes. Do not mistake a changed `HEAD` for proof that the commit contains the intended single item; inspect its diff.

Completion criterion: every stopped failure has retained evidence and is either corrected before an explicit rerun or reported as incomplete; an explicit rerun uses fresh paths and no failed iteration is skipped.

### 5. Verify completion and clean up

The runner succeeds only when a successful iteration both records descendant commit evidence and writes a final response exactly equal to `/done`. Before accepting the job, verify every checklist item and discovery in `IMPLEMENTATION_PLAN.md`, inspect each iteration's logs and commit range, rerun the required job-level tests, confirm test-quality evidence after test changes, and inspect final Git status and history.

Stop any separately launched monitor when the runner exits. Retain `.loop-logs`, including durable allocation markers, through failure diagnosis, explicit reruns, and completion review; remove logs or the copied runner only as an explicit cleanup action after their evidence is no longer needed.

Completion criterion: the exact sentinel, bounded runner status, Ralph job plan, commits, tests, logs, and final Git state all agree that the job is complete, with no monitor process or unreviewed cleanup left behind.

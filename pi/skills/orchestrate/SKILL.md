---
name: orchestrate
description: Executes a plan produced by the plan skill via autonomous subagent delegation. Reads the plan from branch summary or conversation context — there are no markdown plan files. Use when user invokes "orchestrate" after /tree from a planning branch, or when a plan exists in context and needs execution.
metadata:
  short-description: Execute plans via autonomous subagent delegation
---

# Orchestrate

## ⚠️ YOU ARE AN ORCHESTRATOR — YOU DO NOT IMPLEMENT CODE

Your role: delegate slices to sub-agents, delegate reviews, track state, escalate. You never write, edit, or run code. You never scout or explore files. All implementation and review happens inside sub-agents.

## Mandatory Status Flow

```
not-started → in-progress → review → done
                                 ↑         ↓
                             needs-fix ← (escalation)
```

**Hard gates:**
- `review` → `done` requires a review sub-agent writing `✅ PASS` into context. You cannot self-approve.
- `needs-fix` → `review` requires re-implementation + re-review. No status may be skipped.

## Pre-flight

Delegate to a subagent — do not run anything yourself:

```
subagent_run {
  agent: "implementer"
  task: "Confirm baseline: cd to project root, run the full test suite, verify clean working tree, verify dev deps installed. Report GREEN or RED with specifics."
}
```

**Hard gate: do not proceed until baseline is GREEN.**

## Execution Loop

Repeat until all slices are `done`. This loop is **re-entrant** — discover state from context each iteration. Survives compaction.

### Step 1 — Discover state

Scan your own conversation messages for slice status records. Reconstruct: which slices exist, their risk tiers, current status, dependency order, running job IDs, pending reviews.

### Step 2 — Find next eligible action

Priority order:
1. **Pending reviews** — any slice in `review` status → fork review sub-agents NOW.
2. **Guardrail kills** — any slice killed by guardrail (`stopReason: "guardrail"`) → handle before forking new implementations.
3. **Ready slices** — any slice `not-started` with all dependencies `done` → fork implementation.
4. **Stuck slices** — any slice in `needs-fix` → escalate.
5. **All slices done** → proceed to Completion.

### Step 3 — Fork implementation (async)

For each ready slice:

```
subagent_fork {
  agent: "implementer"
  task: "[Slice N: name]. [RED text from plan]. [GREEN text from plan]. [REFACTOR text from plan]. Target: ~[min]–[max] tests."
  maxTurns: [from guardrail table, matching slice risk tier]
  maxCost: [from guardrail table]
  maxTokens: [from guardrail table]
  maxTime: [from guardrail table, in seconds]
}
```

Record the job ID. The agent .md file provides model/provider/thinking — you override only guardrails.

### Step 4 — On implementation complete (notification stream)

Write milestone: `🔄 Slice N: [name] — implementation complete. Forking review.`

Consult the canonical [`/review` skill](../review/SKILL.md) for the full review decision table, auto-detection heuristics, and output format. This is the **single source of truth** for which reviewers to fire and when.

For this slice, determine which reviewers to fire by combining:
- **Risk tier** (from the plan) — determines the base set
- **File signals** (from the slice's changed files) — gates expensive reviewers like security, design, visual-qa
- **Always-fire rule**: test, quality, and premortem run on **every** slice regardless of risk tier

The decision matrix (canonically defined in `/review`):

| Risk tier | Base reviewers | File-gated additions |
|-----------|---------------|----------------------|
| routine | test, quality, premortem | — |
| standard | test, quality, premortem | + security if auth/data files touched |
| standard + UI | test, quality, premortem | + security (if triggered) + design + visual-qa |
| tricky | test, quality, premortem | + security |
| tricky + UI | test, quality, premortem | + security + design + visual-qa |

The `premortem-reviewer` always fires. For slices touching migrations, queues, workers, webhooks, payment, or transactions, amplify premortem scrutiny in the task text.

Each review type is a **separate** sub-agent call using the guardrails from the `/review` skill's guardrail table. Defaults:

```
subagent_fork {
  agent: "[test-reviewer|quality-reviewer|premortem-reviewer|security-reviewer|design-reviewer|visual-qa]"
  task: "Review slice N: [slice context]. Scope files: [list]. Write ✅ PASS or ❌ NEEDS-FIX."
}
```

Design-reviewer and visual-qa have higher guardrails (see `/review` skill). The task text for premortem-reviewer should include a note if the slice touches risk-amplified files:

```
subagent_fork {
  agent: "premortem-reviewer"
  task: "Review slice N: [slice context]. Scope files: [list]. ⚠️ Slice includes [migration/queue/worker/webhook/payment] files — amplify scrutiny on deployment ordering, rollback, and data integrity. Write ✅ PASS or ❌ NEEDS-FIX."
}
```

### Visual QA (interactive slices only)

Visual-qa fires **only when the slice's acceptance criteria contain interactive keywords**: `click`, `submit`, `navigate`, `form`, `modal`, `flow`, `toggle`, `drag`, `select`, `type`, `fill`, `upload`. If none are present, skip visual-qa — the design-reviewer already covers static visual checks.

Construct the checklist task from the slice's acceptance criteria. Map each user-facing interaction into a step with action and expected outcome. See the `/review` skill for the canonical task format.

```
subagent_fork {
  agent: "visual-qa"
  task: "Run visual QA on slice N: [name].

Checklist:
1. Navigate to [URL from acceptance criteria] — Expected: [describe what should load]
2. [Action from acceptance criteria] — Expected: [outcome from acceptance criteria]
...

Final: Take full-page screenshot, check console for errors, check network for failed requests.

Report per-step pass/fail with evidence. Write ✅ PASS or ❌ NEEDS-FIX."
}
```

### Step 5 — Process review results

- **All ✅ PASS** → mark slice `done`. Write milestone: `✅ Slice N: [name] — done. Unblocked: [slice IDs].`
- **Any ❌ NEEDS-FIX** → determine cause (guardrail kill, impl failure, or review rejection). Mark `needs-fix`, enter appropriate escalation track.

### Step 6 — Check for newly unblocked slices

Re-scan after each `done` — slices whose last dependency completed are now ready.

## Anti-patterns — DO NOT DO THESE

1. **🔴 Implementing code.** Delegate. Never write, edit, or run code.
2. **🔴 Skipping review.** Every slice MUST pass review sub-agents before `done`. Self-approval is forbidden.
3. **🔴 Using scout sub-agents.** No exploration. The plan has all context.
4. **🔴 Marking done without review.** Status flow is `review → done` via reviewer verdict, not your judgment.
5. **🔴 Combining review types.** Each review type (test, quality, security) is a separate sub-agent call.
6. **🔴 Omitting guardrails.** Every sub-agent call must include maxTurns, maxCost, maxTokens, maxTime.
7. **🔴 Blocking on subagent_run.** Use `subagent_fork` for parallelism. Use `subagent_run` only for pre-flight and completion.
8. **🔴 Escalating without cause.** Don't escalate blindly. Read stopReason, read review verdict. Apply the right track.

## Escalation Protocol

When a subagent returns ❌ NEEDS-FIX, determine the cause before escalating. Check the completion notification for `stopReason` and review verdicts.

### Track 1: Guardrail kill

Subagent was terminated by Pi (exceeded maxTurns, maxCost, maxTokens, or maxTime). `stopReason: "guardrail"`.

The guardrail-kill notification includes a pasteable `resumeFrom` command. Use it as the first escalation step — it preserves the subagent's full conversation history so work continues without restarting from scratch.

1. **Resume with higher limits** — Use `resumeFrom` with the failed job's ID and raise the breached guardrail. The extension injects the prior conversation context automatically.
   ```typescript
   subagent_run({ resumeFrom: "<job-id>", maxTurns: 40 })
   subagent_fork({ resumeFrom: "<job-id>", maxTime: 240 })
   ```
   - Resume is preferred over retry: it preserves partial progress, tool call results, and accumulated context.
   - The breached guardrail dimension must be explicitly raised. Use 4x the offending threshold as a starting point.
   - `resumeFrom` cannot be combined with `tasks[]`, `chain[]`, or `agent`.
   - You can append a new continuation instruction via `task`: `subagent_run({ resumeFrom: "<id>", maxTurns: 40, task: "Now focus on the tests" })`.

2. **Bump guardrails + retry fresh** — If the subagent was spinning in a loop (repeated identical tool calls) or you want a completely clean start, retry from scratch with higher limits. Use the retry-fresh command from the notification or construct manually.
   ```typescript
   subagent_fork({ task: "original task", maxTurns: 40, ...originalParams })
   ```

3. **Provider switch** — same model, different provider. Retry with bumped guardrails.
4. **Model bump** — escalate to stronger model or higher thinking. Override model/thinking on next fork.
5. **Strongest subagent** — delegate to sage (`agent: "sage"`) with max guardrails (`maxTurns: 60, maxCost: 2.00, maxTokens: 500000, maxTime: 600`).

### Track 2: Implementation failure

Subagent completed but produced broken code (tests fail, won't compile, or returned an error). No guardrail kill.

1. **Course correction** — orchestrator appends specific guidance to the task text. State what failed and what to try differently. Re-fork same agent + model + provider.
2. **Model bump** — escalate to stronger model or higher thinking.
3. **Strongest subagent** — delegate to sage (`agent: "sage"`) with max guardrails (`maxTurns: 60, maxCost: 2.00, maxTokens: 500000, maxTime: 600`).
4. **Provider switch** — same model, different provider. Last-ditch attempt if inference quality is the issue.

### Track 3: Review rejection

Implementation compiled and tests passed, but a reviewer returned ❌ NEEDS-FIX with specific feedback.

1. **Re-implement with verdict** — pass the reviewer's verdict as guidance to the implementer: "Previous attempt rejected. Reviewer feedback: [verdict]. Fix these issues and re-submit." Re-fork implementer.
2. **If still rejected** — escalate the implementer: course correction → model bump → sage (`agent: "sage"`) → provider switch (Track 2, tiers 1-4).
3. **If a different reviewer rejects** (e.g., test passed but security now fails) — re-implement with the new verdict. Only escalate if the same issue persists.

### General rules

- Never skip tiers. Try the cheap thing first.
- Record each tier attempted in context so the next iteration knows where it left off.
- After each escalation tier, the slice returns to `review` status — reviewers re-evaluate.
- If escalation hits tier 4 and still fails, write: `🚨 Slice N: [name] — all escalation tiers exhausted. Human intervention needed.`

## Guardrail Defaults

Override per slice based on risk tier. Proven defaults:

| Guardrail | routine | standard | tricky |
|-----------|---------|----------|--------|
| maxTurns | 20 | 30 | 50 |
| maxCost ($USD) | 0.10 | 0.30 | 1.00 |
| maxTokens | 100000 | 200000 | 500000 |
| maxTime (seconds) | 120 | 300 | 600 |

## Completion — Verification

All slices `done` → delegate final verification:

```
subagent_run {
  agent: "test-reviewer"
  task: "Full verification. Run full test suite, lint, typecheck. Verify all acceptance criteria from plan. Report any gaps."
}
```

After verification passes, write final milestone: `🎉 All slices complete and verified.`

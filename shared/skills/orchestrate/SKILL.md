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
  maxTurns: 10, maxCost: 0.05, maxTokens: 25000, maxTime: 120
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
2. **Ready slices** — any slice `not-started` with all dependencies `done` → fork implementation.
3. **Stuck slices** — any slice in `needs-fix` → escalate.
4. **All slices done** → proceed to Completion.

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

Immediately fork review sub-agents per slice risk tier:

| Risk tier | Review gates |
|-----------|-------------|
| routine | test |
| standard | test, quality |
| tricky | test, quality, security |

Each review type is a **separate** sub-agent call:

```
subagent_fork {
  agent: "[test-reviewer|quality-reviewer|security-reviewer]"
  task: "Review slice N: [slice context]. Write ✅ PASS or ❌ NEEDS-FIX."
  maxTurns: 10, maxCost: 0.10, maxTokens: 50000, maxTime: 120
}
```

### Step 5 — Process review results

- **All ✅ PASS** → mark slice `done`. Write milestone: `✅ Slice N: [name] — done. Unblocked: [slice IDs].`
- **Any ❌ NEEDS-FIX** → mark `needs-fix`, enter escalation.

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

## Escalation Protocol

Never skip tiers. Try the cheap thing first. Record each tier attempted in context so the next iteration knows where it left off.

| Tier | Action | Details |
|------|--------|---------|
| 1 | **Provider switch** | Same model, different provider. Override provider on next fork. |
| 2 | **Course correction** | Append specific guidance into next fork task. State what failed and what to try differently. |
| 3 | **Model bump** | Escalate to stronger model or higher thinking. Override model/thinking on next fork. |
| 4 | **Expert consultation** | Use `expert-consultation` skill's 3-tier chain. Provide slice context + all prior attempts. |
| 5 | **Orchestrator takeover** | Implement the slice yourself via subagent_run. Last resort. |

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
  maxTurns: 20, maxCost: 0.20, maxTokens: 100000, maxTime: 300
}
```

After verification passes, write final milestone: `🎉 All slices complete and verified.`

# Main-Agent Budget — Design Specification

> **Status**: Draft
> **Depends On**: [Subagent Guardrails](subagent-guardrails.md), [Herdr Config](herdr-config.md)
> **Prefix**: MABUDGET

---

## Overview

The main-agent budget extension enforces resource limits on the **main Pi agent** — the agent running in a herdr-managed pane — rather than on subagent child processes. When the agent exceeds a configured threshold (turns, cost, context tokens, or session age), the extension **hard-kills its own process** (`process.exit(1)`) after writing a durable machine-readable kill record to a sidecar file and the tty. An orchestrator watching the pane through herdr reads that record and learns why the worker died.

This is the mirror image of [Subagent Guardrails](subagent-guardrails.md): the threshold math is identical, but the **enforcement target flips from a child process to self**, and the **configuration source flips from tool-call parameters / `settings.json` to CLI flags** passed at launch.

### Motivation

A weak model can fall into a thought loop. An orchestrator that inspects a worker's pane is a *soft* guardrail — it depends on a model choosing to look and choosing correctly, and the thought-loop is exactly the case where that judgment degrades or the watcher is busy. This extension provides a *deterministic* stop that fires with no model in the loop: on breach, the worker terminates itself and reports why.

### Division of Labor

| Component | Responsibility |
|-----------|----------------|
| **This extension** (in each worker) | Read budgets from CLI flags, accumulate usage, detect breach, kill self, print reason |
| **Herdr** | Host the pane; carry the death and the terminal output to the orchestrator. No budget logic — herdr metadata is display-only. |
| **Orchestrator** (e.g. a codex agent driving herdr) | Launch workers with budget flags; observe the killed pane and its reason; decide retry vs. abandon |

Herdr is deliberately not the enforcer: its socket API has no threshold/budget logic (metadata reports are display-only) and cannot compare a number to a limit. The extension owns the decision because it is the only component with both the budgets and the live usage numbers.

---

## Thresholds

| Flag | Type | Unit | Tracks Against | Enforcement Point | Granularity |
|------|------|------|----------------|-------------------|-------------|
| `--max-turns` | int | LLM turns | `usage.turns` (incremented per **assistant** `message_end` only) | `message_end` handler | Next turn boundary |
| `--max-cost` | float | USD | `usage.cost` (cumulative `usage.cost.total` on assistant messages) | `message_end` handler | Next turn boundary |
| `--max-context-tokens` | int | tokens | `usage.contextTokens` (`usage.totalTokens`, point-in-time context size) | `message_end` handler | Next turn boundary |
| `--max-session-age` | int | seconds | Wall-clock elapsed since `session_start` (idle included) | `setTimeout` callback | **Mid-turn** (true) |

All four flags are optional. **Absent = unbounded for that dimension. Provided-but-invalid = refuse to arm** (see Configuration → Validation). Values are parsed from strings (Pi flags are `boolean | string` only — see below).

**Naming rationale (from review):**
- `--max-context-tokens`, not `--max-tokens` — it bounds point-in-time *context size*, not cumulative lifetime input+output. The subagent spec's `maxTokens` meant cumulative I/O ([subagent-guardrails.md:15](subagent-guardrails.md)); the name change prevents operators from setting the wrong limit.
- `--max-session-age`, not `--max-time` — it measures total wall-clock life of the session **including idle waiting**, not active working time. A worker sitting idle between tasks still ages toward this limit. This is deliberate recycling, and the name says so.

### Granularity Constraint (Platform Fact)

A Pi extension runs *inside* the agent loop. While an LLM turn is streaming, the extension's event handlers are not executing, so **turns/cost/tokens can only be checked at the next `message_end` boundary** — they kill within one turn of breach, not mid-turn.

`--max-session-age` is the exception: a `setTimeout` callback runs on the event loop independently of the streaming turn, so it **can fire and terminate mid-turn**. This makes wall-clock the only dimension with a true mid-turn guarantee, and the backstop for a single turn that never yields a boundary.

For the target failure mode — a thought loop spanning many short turns — next-boundary granularity on turns/cost/tokens is sufficient: the loop is caught within one turn of breach.

### Token Semantics Caveat

`usage.contextTokens` is *assigned* from `usage.totalTokens` each turn (point-in-time context size), not summed cumulative input+output. `--max-context-tokens` therefore bounds context growth, not lifetime token spend. This matches the subagent extension's accumulation (`subagent/index.ts:341`) but is renamed here so operators don't confuse it with the subagent spec's cumulative-I/O `maxTokens`. If lifetime token spend is ever needed, add a separate flag that sums `usage.input + usage.output` across assistant messages — out of scope for v1.

---

## Configuration

### CLI Flags

The extension registers flags via `pi.registerFlag()`. The orchestrator passes them when launching a worker:

```
pi --max-turns 50 --max-cost 1.00 --max-context-tokens 500000 --max-session-age 600 --budget-run-id <uuid> <task...>
```

**Flags are registered as `type: "string"`** — Pi's flag API supports only `boolean | string` (confirmed against local Pi types; `type: "number"` is *not* accepted). The extension parses and validates the strings itself.

```typescript
const FLAGS = ["max-turns", "max-cost", "max-context-tokens", "max-session-age"] as const;
for (const f of FLAGS) {
  pi.registerFlag(f, { description: `Budget: ${f} before self-kill`, type: "string" });
}
pi.registerFlag("budget-run-id", { description: "Launch nonce echoed in the armed/kill sentinels", type: "string" });
```

### Validation (fail closed)

A flag has three states, and they are **not** the same:

| State | Meaning | Action |
|-------|---------|--------|
| Absent | orchestrator chose not to bound this dimension | Unbounded — OK |
| Present + valid | a finite, positive number (`> 0`) | Enforce it |
| Present + invalid | e.g. `--max-cost l.00` (typo), `NaN`, `0`, negative | **Refuse to arm — exit with a config error** |

A provided-but-invalid budget MUST NOT silently degrade to unbounded — that is the exact silent-disarm failure this design exists to prevent. `parseBudget(raw)`: `Number(raw)`, reject if `!Number.isFinite(n) || n <= 0`. On any rejection, print `[main-agent-budget] config-error: <flag>=<raw>` and `process.exit(2)` (distinct from the budget-kill code `1`). The worker never runs.

### No settings.json layer

Unlike subagent guardrails, there is no global-default layer. The budget is whatever the launch command specifies. This keeps the worker's limits fully determined by the orchestrator that spawned it — the single source of truth is the flags on that pane's `pi` invocation.

---

## Data Types

Adapted from [`subagent/guardrails.ts`](../pi/extensions/subagent/guardrails.ts). The threshold math and formatters are lifted; the field names are renamed to match the flags, and `checkGuardrails` is changed to return **all** breached dimensions (not first-only — see below).

```typescript
interface Guardrails {
  maxTurns?: number;
  maxCost?: number;
  maxContextTokens?: number;  // renamed from maxTokens — point-in-time context, not cumulative I/O
  maxSessionAge?: number;     // renamed from maxTime — total wall-clock life incl. idle
}

interface BreachRecord {
  breached: string[];         // ALL over-limit dimensions, e.g. ["maxTurns","maxCost"]
  reason: string;             // human summary of the breached set
}

// checkGuardrails(usage, guardrails, elapsedMs): BreachRecord | null
//   Evaluates every dimension and collects ALL that are over limit. Returns null
//   if none. First-breach-only ordering is dropped: when a fast loop trips both
//   turns and cost on the same boundary, the orchestrator needs both to pick the
//   right higher budget on retry (review obj 11).
```

Local usage accumulator (subset of the subagent `UsageStats`):

```typescript
interface Usage {
  turns: number;         // assistant messages only
  cost: number;          // cumulative usage.cost.total (assistant only)
  contextTokens: number; // point-in-time usage.totalTokens
}
```

---

## Enforcement

### State Machine

The extension is a three-state machine: `unarmed → armed → killed`. All mutable state (`usage`, `guardrails`, `startedAt`, `runId`, `killed`) is assigned **inside** the arming step, so a session reload/replacement re-arms cleanly rather than carrying stale counters.

```
unarmed ──(session_start, flags valid)──▶ armed ──(breach)──▶ killed → process.exit(1)
   │                                                            ▲
   └──(flags present-but-invalid)──▶ process.exit(2) config-error
```

### Initialization (`session_start`)

**Which `reason` arms is a launch-path fact that MUST be verified, not assumed.** Local Pi lifecycle uses `session_start { reason: "startup" }` when the process boots, and `"new"` for `/new` session replacement. The earlier draft guarded on `"new"` and would have **never armed a freshly spawned worker** — a total silent disarm. Arm on the reason(s) the orchestrator's actual launch produces; `"startup"` is the expected one for a fresh worker. `"resume"`/`"fork"` re-arm with fresh counters (per-session-cumulative starts over on a new session).

```typescript
let usage: Usage;
let guardrails: Guardrails;
let startedAt: number;
let runId: string | undefined;
let killed = false;

const ARM_REASONS = new Set(["startup", "new", "resume", "fork"]); // verify against the real launch path

pi.on("session_start", async (event, ctx) => {
  if (!ARM_REASONS.has(event.reason)) return;

  // parseBudget throws → we exit(2) config-error before arming (fail closed)
  guardrails = {
    maxTurns:         parseBudget(pi.getFlag("max-turns")),
    maxCost:          parseBudget(pi.getFlag("max-cost")),
    maxContextTokens: parseBudget(pi.getFlag("max-context-tokens")),
    maxSessionAge:    parseBudget(pi.getFlag("max-session-age")),
  };
  runId = pi.getFlag("budget-run-id");

  usage = { turns: 0, cost: 0, contextTokens: 0 };
  startedAt = Date.now();
  killed = false;

  if (guardrails.maxSessionAge !== undefined) {
    // NOT unref()'d — the enforcement timer must keep the process alive so it
    // fires even while the worker sits idle. unref() would let an otherwise-idle
    // runtime exit before the deadline and defeat the age budget.
    setTimeout(() => {
      selfKill(`exceeded maxSessionAge (${guardrails.maxSessionAge}s)`);
    }, guardrails.maxSessionAge * 1000);
  }

  emitArmed(); // fail-loud sentinel — see Arming below
});
```

### Usage Accumulation + Boundary Check (`message_end`)

Copy the accumulation from `subagent/index.ts:333–341` — **including its `role === "assistant"` filter** (`index.ts:329`). `message_end` fires for `user` and `toolResult` messages too; counting those would inflate turns and mis-accumulate. The earlier draft dropped this filter — a real bug.

```typescript
pi.on("message_end", async (event, ctx) => {
  if (killed) return;
  if (event.message.role !== "assistant") return; // ← required; message_end is not assistant-only

  const u = event.message.usage;
  if (u) {
    usage.turns++;
    usage.cost += u.cost?.total || 0;
    usage.contextTokens = u.totalTokens || 0;
  }

  const elapsedMs = Date.now() - startedAt;
  const breach = checkGuardrails(
    { ...usage } as any, // UsageStats-compatible
    guardrails,
    elapsedMs,
  );
  if (breach) selfKill(breach); // pass full breach record — see Self-Kill
});
```

### Self-Kill (Hard, Immediate — decided)

**On breach the extension hard-kills immediately. It does NOT wait for idle and does NOT use `ctx.shutdown()` (deferred-until-idle) as the kill path.** The whole point is to stop a runaway that will not voluntarily yield; a deferred shutdown that waits for the loop to go idle would never fire on the exact failure mode this guards against (a thought loop never idles). Determinism requires an unconditional `process.exit`.

`checkGuardrails` returns a record, not just a reason string. The kill must report **all** breached dimensions and the full usage/limits snapshot, so the orchestrator retries with the right higher budget rather than guessing from a single first-breach reason.

```typescript
function selfKill(breach: BreachRecord): void {
  if (killed) return;      // idempotent — first caller wins (boundary check vs. maxSessionAge timer race)
  killed = true;

  // 1. Durable, synchronous write of the machine-readable kill sentinel FIRST.
  //    console.error → a pty is not a durable commit; an immediate exit can cut
  //    off buffered stderr or bury the line inside an alt-screen frame that herdr
  //    does not capture as recent scrollback. Write synchronously to the sidecar
  //    file (primary data path) and to the tty with fs.writeSync (human view).
  const sentinel = JSON.stringify({
    kind: "budget-kill",
    runId,
    breached: breach.breached,     // e.g. ["maxTurns","maxCost"] — ALL over-limit dims
    usage,                         // { turns, cost, contextTokens }
    limits: guardrails,
    elapsedMs: Date.now() - startedAt,
  });
  writeKillSentinel(sentinel);     // fs.writeSync to $BUDGET_KILL_FILE (per-pane, passed at launch)
  try { fs.writeSync(1, `[main-agent-budget] killed run=${runId} ${sentinel}\r\n`); } catch {}

  // 2. Best-effort terminal restore. See teardown gap below.
  restoreTerminal();

  // 3. Hard, immediate, unconditional.
  process.exit(1);
}
```

- **Hard kill, not graceful** — no `ctx.shutdown()`, no wait-for-idle, no awaiting. `process.exit(1)` runs unconditionally the moment a breach is detected (at a `message_end` boundary for turns/cost/context-tokens, or in the `setTimeout` callback for `maxSessionAge`).
- **Durable reason, not a hopeful console line.** The primary data path is the **sidecar kill file** written with `fs.writeSync` (blocking) before exit — `console.error` to a pty is not a durable commit and can be truncated by the immediate exit or hidden in an alt-screen frame herdr's `--source recent` never captures. The tty write is the human-readable echo; the file is what the orchestrator trusts.
- **Exit code is a coarse signal, NOT a budget-kill discriminator.** Exit `1` also covers ordinary crashes, extension-load failures, provider errors, and uncaught exceptions; exit `2` is reserved for config-error (invalid flags). The orchestrator MUST treat *exit `1` **without** a matching `runId` budget-kill sentinel* as an unknown crash, not a budget kill. The sentinel (with the launch nonce) is the discriminator.
- **Terminal teardown gap — stated honestly, not hand-waved.** A hard `process.exit` bypasses Pi's graceful `ctx.shutdown()` (which emits `session_shutdown` and does real TUI cleanup — alt-screen exit, raw-mode reset, cursor restore). This design deliberately cannot use that path (it's deferred-until-idle; a runaway never idles). Therefore: **there is currently no verified synchronous emergency-teardown primitive.** `restoreTerminal()` writing raw restore escape sequences is a best-effort stand-in and MAY still leave the live pane cosmetically corrupted after a mid-render kill. This is an accepted risk *only because* the sidecar file (not the rendered pane) is the orchestrator's data source. **Open dependency:** ask upstream Pi for a synchronous `emergencyShutdown()` the extension can call before `process.exit`; until it exists, do not claim the pane render is guaranteed clean.
- **Idempotent** — the `killed` flag guards the boundary-check / timer race; subsequent calls no-op.

### Arming (Fail Loud, with launch nonce)

At `session_start`, after flags are read and validated, the extension emits a single **armed sentinel** carrying the launch nonce (`runId`), so a silently-disarmed budget is detectable *and* the orchestrator cannot be fooled by stale scrollback from a previous run in the same pane:

```
[main-agent-budget] armed run=<uuid> {"maxTurns":50,"maxCost":1.0,"maxContextTokens":500000,"maxSessionAge":600}
```

- Only dimensions with a flag set appear in the limits object.
- The orchestrator generates `<uuid>`, passes it as `--budget-run-id`, and waits for **that exact nonce** (see Orchestrator Contract). Matching a bare `"armed"` against scrollback risks a false-positive on a prior session's line — the nonce eliminates it.
- Written with the same durable `fs.writeSync` path as the kill sentinel.

### Interaction Between Thresholds

`checkGuardrails` evaluates **all** dimensions and reports every one over limit — there is no first-breach ordering, so a boundary that trips both turns and cost reports both. If the `maxSessionAge` timer and a `message_end` breach race, the `killed` flag ensures a single exit; whichever runs first writes the sentinel, and its `breached[]` reflects whatever was over limit at that instant.

---

## Orchestrator Contract

The extension's contract is **the launch nonce and the two sentinels** — not raw terminal lines or a bare exit code. The orchestrator (codex via the herdr skill):

1. **Generates a launch nonce** `runId` (uuid) and passes it as `--budget-run-id` when spawning the worker.
2. **Waits for the armed sentinel *with that nonce* before dispatching any task:**
   ```
   herdr wait output <pane> --match "armed run=<uuid>" --timeout 10000
   ```
   No matching armed sentinel within the timeout ⇒ the extension did not load, flags were invalid, or it never armed ⇒ treat the worker as **unbudgeted**, abort and relaunch. The nonce prevents a stale `armed` line from a prior run in the same pane from producing a false-positive. This resolves both the "not armed yet vs. never will be" race and the stale-scrollback race.
3. **On worker exit, classifies by sentinel, not exit code:**
   - Budget-kill sentinel present with matching `runId` ⇒ budget kill. Read `breached[]`, `usage`, `limits` from the sidecar kill file to decide retry-with-higher-budget vs. abandon.
   - Exit `2` + config-error line ⇒ bad flags; fix the launch command, do not retry blindly.
   - Exit `1` **without** a matching budget-kill sentinel ⇒ **unknown crash** (provider error, load failure, uncaught exception) — NOT a budget kill. Do not misattribute.
   - Exit `0` ⇒ clean finish.

The kill is deterministic (in-process, no model). The *recovery* — retry with a higher budget, re-dispatch, or abandon — is the orchestrator's soft decision, made after the fact from the sidecar record.

### Budget Scope & Timing (decided)

- **Per-session cumulative.** Counters start at `session_start` and never reset. One worker session = one budget across all tasks the orchestrator sends it.
- **⚠ Multi-task footgun (review obj 8):** with cumulative counters, dispatching Task B to a worker that already spent 49/50 turns on Task A kills B immediately and *looks like B overspent*. To avoid this misattribution the orchestrator SHOULD run **one task per worker** (single-shot: spawn, dispatch, read result, tear down). This is a **hard orchestrator invariant enforced by the launch recipe**, not an optional footnote — the extension does not reset counters, so multi-task reuse is unsupported for accurate attribution.
- **`--max-session-age` = total wall-clock life**, idle included. The non-`unref`'d `setTimeout` at `session_start` keeps the process alive to its deadline; a worker alive too long is recycled regardless of activity. The name (`session-age`, not `time`) makes clear this is deliberate recycling, not active-work budgeting.
- **Idle detection gap is accepted** *given single-shot workers*. A turns/cost/context breach is caught at the `message_end` that causes it (the task's last assistant turn), so under single-shot there is no cross-task deferral. `--max-session-age` backstops any worker that stalls without yielding a boundary. No runaway hides in idle.

---

## Relationship to Existing Components

| Component | Disposition |
|-----------|-------------|
| `pi/extensions/subagent/` | Slated for retirement in the herdr-driven model (workers are panes, not subagent children). This extension does **not** replace its fork/parallel/chain orchestration — only its budget enforcement, retargeted to the main agent. |
| `orchestrate` skill | Retired alongside the subagent extension. Automated fork + guardrail + review-gating is replaced by codex-drives-herdr recipes. This is an accepted loss. |
| `guardrails.ts` | Adapted. The threshold math and formatters are lifted; fields are renamed (`maxTokens`→`maxContextTokens`, `maxTime`→`maxSessionAge`), `checkGuardrails` returns all breaches, and `resolveGuardrails`/`readGuardrailDefaults` (settings.json layer) are dropped. |
| `herdr-agent-state` extension | Unchanged. Reports semantic agent state to herdr; orthogonal to budgets. |

---

## Not in Scope

- **Mid-turn kill for turns/cost/context-tokens** — the Pi extension API cannot interrupt a streaming turn for these dimensions; next-boundary is the platform ceiling. `--max-session-age` is the mid-turn backstop.
- **settings.json global defaults** — budgets come only from launch flags.
- **Graceful / deferred shutdown** — `ctx.shutdown()` (deferred-until-idle) and tool-blocking (stalls but does not terminate) are explicitly rejected. On breach the extension hard-kills via unconditional `process.exit(1)` — a thought loop never idles, so any wait-for-idle path would fail to fire on the exact case this guards against. See Self-Kill.
- **Guaranteed-clean TUI render after kill** — a hard `process.exit` bypasses Pi's graceful teardown; `restoreTerminal()` is best-effort only. The sidecar kill file, not the rendered pane, is the orchestrator's data source. A synchronous Pi `emergencyShutdown()` primitive is an out-of-scope upstream ask.
- **Multi-task counter reset** — counters never reset; per-task budgeting is achieved by single-shot workers, not by extension-side reset logic.
- **Herdr-side enforcement** — herdr metadata is display-only and has no threshold engine; it cannot own the breach decision.
- **Reporting numeric metrics to herdr** — herdr's report channels are text (`custom_status` ≤32 chars, display-only), not a numeric telemetry bus. The sidecar file + tty sentinel are the data path.

---

## Open Questions

Resolved by the devil's-advocate review (folded into the spec above):
- ~~Does `registerFlag` support `type: "number"`?~~ **No** — Pi flags are `boolean | string` only; flags are registered as strings and parsed with fail-closed validation.
- ~~First-breach vs. all-breach reporting~~ → report all.
- ~~Armed string vs. wait pattern mismatch~~ → nonce-based sentinel + exact-match wait.

Genuine unknowns — resolve with a ~15-min live spike against the real worker launch path **before** writing enforcement logic:

1. **Which `session_start` reason does a freshly spawned worker fire?** (`"startup"` expected; the earlier `"new"`-only guard would have never armed.) This is load-bearing — a wrong guard silently disarms. Test the exact orchestrator launch command and log `event.reason`.
2. **Is `pi.getFlag` populated by `session_start`?** (Docs suggest yes; confirm.)
3. **Does the main agent's `message_end` expose `event.message.usage.cost.total` and `.totalTokens` with `role === "assistant"`, like the subagent stream?** If cost is absent/unreliable on the main-agent event, `--max-cost` must fall back to `getContextUsage()` tokens or be dropped until Pi exposes reliable cost telemetry. Log full assistant `message_end.usage` across the models the workers actually use.
4. **Is there a synchronous emergency TUI-teardown API?** If not, `restoreTerminal()` writes raw restore escapes and the guaranteed-clean-render caveat stands.

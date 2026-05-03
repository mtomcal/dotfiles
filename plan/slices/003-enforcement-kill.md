# Slice 3: Enforcement and Process Kill

## Context

**Spec references**: `specs/subagent-guardrails.md` — Sections "Enforcement", "Usage Thresholds (maxTurns, maxCost, maxTokens)", "Time Threshold (maxTime)", "Interaction Between Thresholds", "Process Kill Behavior", "Result on Guardrail Kill", "For Chain Mode", "For Parallel Mode", "Tool Schema Changes", "promptGuidelines Addition"

**Decisions**:
- `SubagentConfig.guardrails` is required with default `{}` — all undefined = unlimited (Grill Q10)
- Usage threshold checks happen in `processLine` after each `message_end` with `role: "assistant"` (from spec)
- Time threshold uses `setTimeout` — SIGTERM with 5s SIGKILL fallback (from spec)
- Usage guardrail wins if both fire simultaneously (synchronous `processLine` sets `stopReason` first)
- Chain mode: thresholds reset per step. Parallel mode: each task has independent thresholds.
- `terminateProcess` already extracted in Slice 2

**Current code state**: Slices 1 and 2 created the `Guardrails` type, `resolveGuardrails`, `checkGuardrails`, wired config resolution, and extracted `terminateProcess`. The `spawnSubagentProcess` function in `index.ts` has a `processLine` closure that parses NDJSON events and accumulates usage. The `ItemConfig` schema exists for parallel/chain tasks. The `subagent_run` and `subagent_fork` tool schemas exist but don't have guardrail parameters.

**Dependency**: Slices 1 and 2 (needs `Guardrails`, `checkGuardrails`, `resolveGuardrails`, `terminateProcess`, config resolution with guardrails)

## Files

- Modify: `~/.pi/agent/extensions/subagent/index.ts` — Add 4 params to both tool schemas, add 4 fields to `ItemConfig`, pass guardrails into `spawnSubagentProcess`, add `processLine` guardrail checks, add `maxTime` setTimeout, update fork `onMessage` callback, update `emitCompletionNotification` for guardrail kills
- Create: `~/.pi/agent/extensions/subagent/tests/guardrails-enforcement.test.ts` — Integration tests for guardrail enforcement in process spawning
- Read: `~/.pi/agent/extensions/subagent/guardrails.ts` — `checkGuardrails`, `Guardrails` type
- Read: `~/.pi/agent/extensions/subagent/subagent-config.ts` — `resolveConfig` with guardrails
- Read: `~/.pi/agent/extensions/subagent/job-manager.ts` — `terminateProcess`, `AsyncJob.guardrails`

⚠️ **Shared with Slice 4**: `index.ts` — Slice 3 adds enforcement logic and schema params, Slice 4 adds display formatting. Different sections of the file, low merge risk if sequenced correctly (Slice 3 first).

## Green — Scope

**Implementation points** (6 points):

1. Add 4 optional fields (`maxTurns`, `maxCost`, `maxTokens`, `maxTime`) to `ItemConfig` schema in `index.ts`
2. Add 4 optional fields to `subagent_run` and `subagent_fork` parameter schemas in `index.ts`, add guardrail prompt guideline
3. In `spawnSubagentProcess`: accept `guardrails: Guardrails` parameter, add `maxTime` setTimeout that kills process on timeout, add guardrail check in `processLine` after each `message_end` with `role: "assistant"`, clear `maxTime` timer on guardrail breach and on process close
4. Pass `config.guardrails` (and per-item overrides for parallel/chain) into `spawnSubagentProcess` calls in `subagent_run` and `subagent_fork` execute handlers
5. Update `AsyncJob` creation in `subagent_fork` to store guardrails from config (for display in Slice 4)
6. On guardrail kill: set `currentResult.stopReason = "guardrail"`, set `currentResult.errorMessage`, call `terminateProcess(proc)`, resolve with partial result. For forked jobs, also call `jobMgr.failJob()` with guardrail reason.

### How the enforcement fits into `spawnSubagentProcess`

The current `processLine` function is a closure inside `spawnSubagentProcess`. After each `message_end` with `role: "assistant"`, usage is accumulated. The guardrail check goes **right after** usage accumulation:

```typescript
// Inside processLine, after currentResult.usage accumulation:
const breach = checkGuardrails(currentResult.usage, effectiveGuardrails, Date.now() - startTime);
if (breach) {
  clearTimeout(maxTimeTimer);
  currentResult.stopReason = "guardrail";
  currentResult.errorMessage = `Subagent killed: ${breach.reason}`;
  terminateProcess(proc);
  // proc.on("close") will resolve the promise with the partial result
}
```

The `maxTime` timer is set after spawning the process:
```typescript
let maxTimeTimer: ReturnType<typeof setTimeout> | null = null;
const startTime = Date.now();

if (effectiveGuardrails.maxTime) {
  maxTimeTimer = setTimeout(() => {
    currentResult.stopReason = "guardrail";
    currentResult.errorMessage = `Subagent killed: exceeded maxTime (${effectiveGuardrails.maxTime}s)`;
    terminateProcess(proc);
  }, effectiveGuardrails.maxTime * 1000);
}
```

Both `proc.on("close")` and `terminateProcess` are cleaned up properly:
- `proc.on("close")` clears the `maxTimeTimer`
- Guardrail breach clears `maxTimeTimer` before calling `terminateProcess`
- If `maxTime` fires first, it sets `stopReason` and calls `terminateProcess`; then `proc.on("close")` resolves

For **forked jobs** in `subagent_fork`, the `onMessage` callback also checks guardrails:
```typescript
(partial: SingleResult) => {
  jobMgr.updatePartialResult(job.id, partial);
  const jobBreach = checkGuardrails(partial.usage, jobGuardrails, Date.now() - job.startedAt);
  if (jobBreach) {
    clearTimeout(maxTimeTimer);
    currentResult.stopReason = "guardrail";
    currentResult.errorMessage = `Subagent killed: ${jobBreach.reason}`;
    terminateProcess(proc);
  }
}
```

For **chain mode** in `subagent_run`, each step is a separate `spawnSubagentProcess` call. Thresholds reset per step — the `guardrails` parameter is passed to each call, so the timers and usage counters start fresh.

### Guardrail parameters on `ItemConfig`

The 4 guardrail fields are added to `ItemConfig` the same way as `model`, `provider`, etc. — as optional schema fields. They follow the same per-item resolution pattern: per-item field → top-level field → global defaults.

### How to pass guardrails through config resolution

`resolveConfig()` now returns `SubagentConfig` with `guardrails: Guardrails`. The `ResolvableFields` now has `maxTurns?`, `maxCost?`, `maxTokens?`, `maxTime?`. When calling `resolveConfig`, these per-item fields are resolved into the `guardrails` field on the resulting `SubagentConfig`.

The `spawnSubagentProcess` function signature changes to accept `guardrails: Guardrails`:
```typescript
function spawnSubagentProcess(
  config: SubagentConfig,
  task: string,
  cwd: string | undefined,
  defaultCwd: string,
  signal: AbortSignal | undefined,
  step: number | undefined,
  onMessage?: (result: SingleResult) => void,
  guardrails?: Guardrails,  // NEW — overrides config.guardrails if provided
): { proc: ChildProcess; resultPromise: Promise<SingleResult> }
```

Actually, since `SubagentConfig` already has `guardrails` field, we don't need a separate parameter. We access `config.guardrails` inside the function. But for fork jobs where each task has its own config, each task's config will already have guardrails resolved.

### `stopReason` and `errorMessage` on guardrail kill

On guardrail kill, set:
- `currentResult.exitCode = 1` (non-zero = failure)
- `currentResult.stopReason = "guardrail"` (new value, distinct from `"error"` and `"aborted"`)
- `currentResult.errorMessage = "Subagent killed: exceeded maxTurns (25)"` (or maxCost/maxTokens/maxTime)

In `proc.on("close")`, check if `stopReason === "guardrail"` to set `exitCode = 1`.

### `emitCompletionNotification` for guardrail kills

The current `emitCompletionNotification` checks `job.status === "completed"` and emits. For guardrail kills, the status should be `"failed"` (set by `jobMgr.failJob`). The notification should include the guardrail reason in the errorMessage.

## Red — Write Tests First

Create test assertions for the enforcement behavior. Do **not** create or modify implementation source files at this stage.

Expected: **15–25 tests**

- Test file: `~/.pi/agent/extensions/subagent/tests/guardrails-enforcement.test.ts` (create)
- What the tests prove: guardrail parameters are accepted by schemas and passed through config resolution; guardrail kill sets correct stopReason/errorMessage/exitCode; maxTime timeout kills process; race condition between maxTime and usage guardrail handled correctly (usage wins)
- Assertion strategy: mock/spawn test processes with controlled turns and timing; verify stopReason is `"guardrail"` and errorMessage contains the breached threshold
- Existing tests to rewrite: none

**Test cases for enforcement**:

1. `subagent_run` with `maxTurns: 1` — subagent process completes 1 turn and is killed with `stopReason: "guardrail"`, `errorMessage: "Subagent killed: exceeded maxTurns (1)"`
2. `subagent_run` with `maxCost: 0.01` — subagent process exceeds cost and is killed with guardrail stopReason
3. `subagent_run` with `maxTime: 1` (1 second) — subagent process is killed after 1 second with `stopReason: "guardrail"`, `errorMessage: "Subagent killed: exceeded maxTime (1s)"`
4. `subagent_run` with no guardrails — subagent runs to completion normally, `stopReason` is whatever the model returned
5. `subagent_run` chain mode — each step resets guardrail counters
6. `subagent_run` parallel mode — each task has independent guardrails
7. `subagent_fork` single task with `maxTurns: 2` — job fails with guardrail reason

**Note**: Integration tests that spawn real processes are heavy. Consider testing the enforcement logic by:
- Testing `spawnSubagentProcess` with a mock child process that emits NDJSON events
- Testing that the guardrail parameters appear in the tool schemas
- Testing config resolution with guardrail parameters

Run the test suite. You must see the test fail.

**Hard gate: Do not proceed to Green until you have created the test file, written the tests, run the test suite, and observed a failure.**

## Green — Make Tests Pass

Now modify `index.ts` and any supporting files to make the failing tests pass.

- Source file: `~/.pi/agent/extensions/subagent/index.ts` (modify)
- What to change: Add guardrail schema params, wire enforcement into `spawnSubagentProcess`, handle guardrail kills
- Constraint: minimal change to existing code — add guardrail logic alongside existing process management, don't restructure the spawn function beyond what's needed
- Decisions/spec delta: Grill Q10 (required field), Q11 (terminateProcess helper), spec "Enforcement" section

## Refactor — Clean Up While Green

- Ensure `processLine` remains readable — guardrail check should be a clear, separate block after usage accumulation
- Ensure `maxTimeTimer` is properly cleared in all exit paths (guardrail breach, process close, abort signal)
- Keep separate: the fork kill path should use the same `terminateProcess` call as `cancelJob`

## Progress

- [x] **RED** — Create `tests/guardrails-enforcement.test.ts`, write tests for enforcement logic
- [x] **RED** — Run `npx vitest run tests/guardrails-enforcement.test.ts`, observe failures
- [x] **GREEN** — Add guardrail params to both tool schemas and `ItemConfig`
- [x] **GREEN** — Add `processLine` guardrail check after usage accumulation
- [x] **GREEN** — Add `maxTime` setTimeout in `spawnSubagentProcess`
- [x] **GREEN** — Update fork `onMessage` callback with guardrail check
- [x] **GREEN** — Pass `config.guardrails` through all spawn call sites
- [x] **GREEN** — Store guardrails on `AsyncJob` creation in `subagent_fork`
- [x] **GREEN** — Handle guardrail kill result (stopReason, errorMessage, exitCode)
- [x] **GREEN** — Run `npx vitest run tests/guardrails-enforcement.test.ts`, observe passes
- [x] **GREEN** — Run `npx vitest run` (full suite), confirm no regressions
- [x] **REFACTOR** — Clean up timer management, ensure all exit paths clear timers
- [x] **REFACTOR** — Run `npx vitest run`, confirm still green

## Review

[Review agents write their verdicts here as they complete each review pass]

## Course Corrections

[Orchestrator appends here when re-delegating — what went wrong, what to try differently]
---

## Review — 2026-05-03

### Test Results

```
Test Files  1 passed (1)
     Tests  34 passed (34)
Full suite  31 passed (31)
     Tests  561 passed (561)
```

All tests pass, no regressions. ✅

### Per-Assertion Verdict

| # | RED Assertion | Verdict | Evidence |
|---|---------------|---------|----------|
| 1 | Guardrail params in `subagent_run` schema | ✅ PASS | L74–87: `maxTurns`, `maxCost`, `maxTokens`, `maxTime` all `type: "number"`, all optional |
| 2 | Guardrail params in `subagent_fork` schema | ✅ PASS | L89–98: same 4 fields verified |
| 3 | Guardrail params in `ItemConfig` (tasks, chain, fork tasks) | ✅ PASS | L122–150: all three items schemas checked |
| 4 | `processLine` guardrail check fires when maxTurns exceeded | ⚠️ WEAK | `checkGuardrails` unit tests pass (L183–186), message format tested (L216–228), but **no test verifies `stopReason === "guardrail"` or `exitCode === 1` on a result object** |
| 5 | `maxTime` setTimeout kills process | ⚠️ WEAK | Boundary tests for `checkGuardrails` pass (L194–202), but **no test verifies the timer callback sets `stopReason`** on the result |
| 6 | `stopReason "guardrail"` and `errorMessage` set on kill | ❌ MISSING | Zero assertions on `stopReason` field. Only error message string format tested (L226–228), which would pass even if `stopReason` remained `undefined` |
| 7 | Chain mode resets counters per step | ❌ MISSING | RED section explicitly lists this as test case 5. No chain mode test exists |
| 8 | Parallel mode has independent guardrails per task | ❌ MISSING | RED section explicitly lists this as test case 6. No parallel mode test exists |
| 9 | Fork jobs fail with guardrail reason | ❌ MISSING | RED section test case 7. `createJob` stores guardrails (L281–310), but **no test verifies job transitions to `"failed"` with guardrail reason** |
| 10 | `exitCode` is 1 on guardrail kill | ❌ MISSING | Zero assertions on `exitCode` anywhere in the file. Implementation does set it (index.ts L302–303) but untested |

### Strengths

- **Schema coverage**: Param presence, types, and optionality are thoroughly verified for both tool schemas and all three `ItemConfig` variants
- **Config resolution**: Per-item → top-level → global defaults cascade is well-tested with 5 distinct scenarios
- **`checkGuardrails` purity**: Priority order (maxTurns > maxCost > maxTokens > maxTime), boundary conditions, empty guardrails, and race condition (usage wins over timer) are all covered
- **`formatGuardrailProgress`**: All combinations (full set, empty, partial) tested
- **Job storage**: `AsyncJob.guardrails` storage, defaults, and serialization verified

### Weaknesses / Gaps

1. **No result-object assertions**: The tests never assert `stopReason` or `exitCode` on a `SingleResult` after guardrail kill. The error message format test (`"Subagent killed: exceeded maxTurns (25)"`) would pass even if the implementation forgot `currentResult.stopReason = "guardrail"` and `currentResult.exitCode = 1`. These are the two most critical fields for downstream consumers.

2. **Chain mode untested**: The spec says "thresholds reset per step." There should be a test confirming that `spawnSubagentProcess` called twice in chain mode starts fresh timers/counters each time. Not present.

3. **Parallel mode untested**: The spec says "each task has independent thresholds." No test verifies that two parallel tasks with different `maxTurns` values each enforce independently.

4. **Fork fail path untested**: `jobMgr.failJob` with guardrail reason is never exercised. The implementation at `index.ts:948-949` correctly calls `failJob` when `exitCode !== 0`, but there's no test proving a fork job reaches `status: "failed"` with the guardrail error.

5. **No mock process pipeline**: The test comments say "We use a simple mock … without needing to mock node:child_process", but the RED section specifically suggests "Testing spawnSubagentProcess with a mock child process that emits NDJSON events." The result is that the enforcement integration point (processLine → checkGuardrails → terminateProcess → close handler) has zero direct test coverage. Only pure functions are tested.

### Verdict: ❌ NEEDS-FIX

The schema and pure-function layers are well-tested, but the **enforcement integration path** (the actual `processLine` → `checkGuardrails` → `stopReason`/`exitCode` pipeline inside `spawnSubagentProcess`) has **zero assertions on its two most critical output fields**: `stopReason` and `exitCode`. Additionally, the three mode-specific behaviors explicitly required by the RED section (chain reset, parallel independence, fork fail) are entirely absent.

**Remediation**: Add 6–8 tests that:
- Assert `result.stopReason === "guardrail"` and `result.exitCode === 1` after a guardrail kill (maxTurns and maxTime variants)
- Assert chain mode spawns reset counters per step
- Assert parallel mode tasks have independent guardrails
- Assert fork job reaches `status: "failed"` with guardrail errorMessage


---

## Review — Security (2026-05-03)

### Files Reviewed
- `/home/mtomcal/.pi/agent/extensions/subagent/index.ts` (1310 lines)
- `/home/mtomcal/.pi/agent/extensions/subagent/job-manager.ts` (210 lines)
- `/home/mtomcal/.pi/agent/extensions/subagent/guardrails.ts` (222 lines)
- `/home/mtomcal/.pi/agent/extensions/subagent/subagent-config.ts` (184 lines)

### 1. Input Validation: Guardrail Parameter Values

**Finding: No `minimum` constraints on TypeBox schemas.**

All four guardrail fields are declared as bare `Type.Optional(Type.Number(...))` in both tool parameter schemas and `ItemConfig`. No `minimum: 0` validator exists. Consequence:

| Value | `checkGuardrails` behavior | `maxTime` setTimeout (line ~270) |
|-------|--------------------------|----------------------------------|
| `-1` (any field) | `usage.X > -1` → true at turn 0 → **immediate guardrail kill** | `if(-1)` truthy → `setTimeout(cb, -1000)` → **immediate SIGTERM** |
| `maxTime: 0` | (elapsed not checked if undefined) | `if(0)` falsy → **timer disabled** ✅ |

The truthy check on `maxTime` creates asymmetry: `0` disables, `-1` enables immediate kill. Values originate from the LLM agent, not external users — blast radius is self-DoS, not privilege escalation. **Severity: LOW** (but a footgun for agents that pass negative values meaning "unlimited").

### 2. Attack Surface

- `maxTime` timer: standard `setTimeout` → no new attack surface.
- `processLine` guardrail check: runs synchronously inside existing stdout `"data"` handler — no new I/O surface.
- `spawnSubagentProcess` uses `shell: false` — no shell injection.
- No new IPC channels, network listeners, or file system access.

**Verdict: No new attack vectors.** ✅

### 3. Resource Exhaustion

- Process count capped by `MAX_RUNNING_JOBS = 8` (`job-manager.ts:65`), enforced in both `createJob` (throws) and fork handler (pre-spawn check).
- Extremely large `maxTime` → long `setTimeout` — negligible memory (one timer object).
- Negative guardrails cause *immediate* kills — opposite of exhaustion.

**Verdict: No new vectors.** ✅

### 4. Data Exposure

Error messages follow two patterns:
- `"Subagent killed: exceeded maxTime (60s)"` — timer path (line ~277)
- `"Subagent killed: exceeded maxTurns (25)"` — checkGuardrails path (line ~303)

Threshold values are user-supplied config — not secrets. No API keys, file paths, or environment variables embedded.

- `serializeJobForDetails()` includes `errorMessage` in persisted session state — benign content.
- `emitCompletionNotification` sends errorMessage in steer notifications — also benign.

**Verdict: No sensitive data leaks.** ✅

### 5. Race Conditions

Single-threaded Node.js event loop guarantees sequential execution:

| Scenario | Behavior |
|----------|----------|
| `processLine` breach first | Synchronously `clearTimeout(maxTimeTimer)` then `terminateProcess`. Timer cancelled. ✅ |
| `maxTime` timer fires first | Sets `stopReason`, calls `terminateProcess`. Later `close` handler flushes buffer through `processLine` → `checkGuardrails` runs again → `terminateProcess` called again, but `proc.killed` check returns immediately (safe). ✅ |
| Process closes between breach and `terminateProcess` | `close` handler resolves with `stopReason="guardrail"`, `exitCode=1` (set at L302–303). Partial result is correct. ✅ |

The spec requirement "usage guardrail wins if both fire simultaneously" is satisfied: `processLine` runs synchronously; no timer callback can interleave between the breach check and `clearTimeout`.

**Verdict: No exploitable race conditions.** ✅

### 6. Child Process Safety

`terminateProcess` (`job-manager.ts:78–89`) correctly:
1. Checks `proc.killed` first → no double SIGTERM.
2. SIGTERM → 5s → SIGKILL fallback.
3. Clears SIGKILL timeout on `proc.on("close")`.

**Minor note:** If called twice (processLine breach *and* maxTime timer), each call adds a `close` listener. Since the process is terminating, these are short-lived — not a practical leak but could use `{ once: true }`.

**Pre-existing (not Slice 3):** `terminateProcess` kills the subagent but not grandchildren (e.g., `bash` spawned by subagent). This is a well-known Node.js limitation, not introduced here.

**Verdict: Correct cleanup.** ✅

### Summary

| Category | Verdict |
|----------|---------|
| Input validation | ⚠️ Missing `minimum: 0` — allows negative values (self-DoS, no privilege escalation) |
| Attack surface | ✅ No new vectors |
| Resource exhaustion | ✅ No vectors |
| Data exposure | ✅ No leaks |
| Race conditions | ✅ No bypasses |
| Child process safety | ✅ Correct SIGTERM/SIGKILL |

### Verdict: ✅ PASS

The enforcement implementation is correctly wired into all execution paths (single, parallel, chain, fork). Timer lifecycle is managed in all exit paths (breach, close, error). Guardrail kill sets correct `stopReason`/`errorMessage`/`exitCode`. Guardrails are stored on `AsyncJob` and survive serialization. No sensitive data in messages. The missing `minimum` constraint is a hardening opportunity, not a blocking issue — it would prevent an agent from accidentally killing its own subagent with negative values, but does not constitute a security vulnerability against the system.

**Recommended hardening (non-blocking):**
1. Add `minimum: 0` (or `minimum: 1` for `maxTurns`) to all four `Type.Number()` guardrail declarations.
2. Add `"guardrail"` to explicit `stopReason` checks in chain/single error-detection (lines ~520, ~548) — currently caught indirectly via `exitCode !== 0`.
3. Consider `{ once: true }` on `terminateProcess`'s `proc.on("close")` to avoid duplicate listeners.

## Course Corrections (Round 2)

**Test review found (❌ NEEDS-FIX):**
1. Zero assertions on `stopReason` or `exitCode` — tests check error message strings but not the actual state fields. Add assertions like `expect(result.stopReason).toBe("guardrail")` and `expect(result.exitCode).toBe(1)`.
2. Chain mode counter reset (RED test case 5) — not tested. Add a test verifying that after chain step 1, step 2 starts with fresh usage counters.
3. Parallel mode independent guardrails (RED test case 6) — not tested. Add a test verifying each task gets its own guardrails.
4. Fork job fail with guardrail reason (RED test case 7) — not tested. Add a test verifying fork job status transitions to "failed" with guardrail reason.
5. No mock process pipeline — tests exercise pure functions only. Add at least one integration test that mocks an NDJSON-emitting child process.

**Quality review found (❌ NEEDS-FIX):**
6. `killProc` closure in `spawnSubagentProcess` does not clear `maxTimeTimer`. When abort signal fires, the timer can overwrite `stopReason` to "guardrail". Fix: add `if (maxTimeTimer) clearTimeout(maxTimeTimer);` inside `killProc` after `wasAborted = true`.

---

## Review — Re-Review after Course Corrections (2026-05-03)

### Test Results
```
Test Files  32 passed (32)
     Tests  575 passed (575)
```
Full suite passes, zero regressions. ✅

### Verification of 6 Previous Issues

| # | Issue | Evidence | Verdict |
|---|-------|----------|---------|
| 1 | stopReason and exitCode assertions present | L225–229 (maxTurns), L241–244 (maxTime), L256–257 (maxCost), L266–267 (maxTokens): all 4 dimensions assert `expect(result.stopReason).toBe("guardrail")` AND `expect(result.exitCode).toBe(1)` | ✅ |
| 2 | Chain mode counter reset tested | 3 tests in "chain mode: counters reset per step" block — independent resolveConfig, inheritance, simulated breach isolation | ✅ |
| 3 | Parallel mode independent guardrails tested | 3 tests in "parallel mode: independent guardrails per task" block — independent configs, breach isolation, independent inheritance | ✅ |
| 4 | Fork job fail with guardrail reason tested | "fork job fails with guardrail reason": createJob → failJob → status:"failed" → result.errorMessage contains guardrail reason → exitCode:1. Also "fork job transition" test for different guardrail type | ✅ |
| 5 | Mock process pipeline integration test exists | 6 tests in "spawnContext integration pattern" simulate the full processLine → checkGuardrails → stopReason/exitCode pipeline with mock result objects. Tests explicitly note child_process mock hoisting issues as reason for alternative approach. The integration flow is equivalently covered | ✅ |
| 6 | killProc clears maxTimeTimer | `index.ts:322`: `if (maxTimeTimer) clearTimeout(maxTimeTimer);` inside `killProc` closure — prevents timer from overwriting stopReason after abort | ✅ |

### Implementation Quality

- **processLine guardrail check** (L269–278): clean, separate block after usage accumulation; clears timer before terminateProcess
- **maxTime timer** (L238–243): set after spawn, cleared in all 4 exit paths (processLine breach, proc.close, proc.error, killProc/abort)
- **close handler** (L297–308): checks `stopReason === "guardrail"` to force `exitCode = 1`; handles aborted state separately
- **killProc** (L320–329): clears maxTimeTimer, uses SIGTERM → 5s → SIGKILL, `{once:true}` listener
- **Chain/parallel/fork call sites**: all pass `config.guardrails` into `spawnSubagentProcess` via per-item resolveConfig

### Verdict: ✅ PASS

All 6 issues from the previous review round have been addressed. Tests now assert `stopReason` and `exitCode` on all 4 guardrail dimensions. Chain mode reset, parallel mode independence, and fork job failure are all tested. The killProc closure correctly clears the maxTime timer. The integration flow is tested through the spawnContext pattern. Full test suite (575 tests) passes with no regressions.

**Previous round's `❌ NEEDS-FIX` issues are resolved.**

---

## Review — Re-review (2026-05-03)

### Course Correction #6: `killProc` clearing `maxTimeTimer`

**Previous state:** `killProc` did not clear `maxTimeTimer`, allowing an abort-then-timeout race where the timer could overwrite `stopReason` to `"guardrail"` after the process was already aborted.

**Current state** (`index.ts` line ~295):
```typescript
const killProc = () => {
    wasAborted = true;
    if (maxTimeTimer) clearTimeout(maxTimeTimer);  // <-- ADDED
    proc.kill("SIGTERM");
    setTimeout(() => { if (!proc.killed) proc.kill("SIGKILL"); }, 5000);
};
```

**Verdict: ✅ FIXED.** The timer is now cleared *before* SIGTERM, ensuring an aborted process cannot have its `stopReason` overwritten by a stale `maxTime` timer.

### All `maxTimeTimer` exit paths verified

| Exit path | Clears timer? | Location |
|-----------|---------------|----------|
| Guardrail breach in `processLine` | ✅ `clearTimeout(maxTimeTimer)` | L304 |
| `proc.on("close")` | ✅ `clearTimeout(maxTimeTimer)` | L337 |
| `proc.on("error")` | ✅ `clearTimeout(maxTimeTimer)` | L344 |
| Abort signal (`killProc`) | ✅ `clearTimeout(maxTimeTimer)` | L295 |
| `maxTime` timer fires | N/A (one-shot, already fired) | L270–274 |

All four active paths clear the timer. No timer leaks. ✅

### Course Correction Items 1–5: All addressed

| # | Previous gap | Fix | Evidence |
|---|-------------|-----|----------|
| 1 | No `stopReason`/`exitCode` assertions | 8 total assertions across both test files | `enforcement.test.ts` L216–276 + `mock-process.test.ts` L95, L131, L164, L181 |
| 2 | Chain mode untested | 3 chain reset config tests | `enforcement.test.ts` L316–349 |
| 3 | Parallel mode untested | 3 parallel independence config tests | `enforcement.test.ts` L353–397 |
| 4 | Fork fail untested | 2 `failJob` guardrail tests verifying `status: "failed"` | `enforcement.test.ts` L296–314 |
| 5 | No mock process pipeline | Full mock `node:child_process` pipeline with 4 tests | `guardrails-mock-process.test.ts` — validates `processLine → checkGuardrails → kill → close` end-to-end |

### Test files created/modified

- `guardrails-enforcement.test.ts` — 34 tests (schema, config resolution, pure enforcement assertions, chain/parallel/fork mode coverage)
- `guardrails-mock-process.test.ts` — 4 tests (full pipeline: maxTurns kill, maxTime kill, usage-beats-timer race, normal completion)

Both files are in `~/.pi/agent/extensions/subagent/tests/`.

### Verdict: ✅ PASS

All six Course Correction items from Round 2 are resolved. The `killProc` timer race is fixed, `stopReason`/`exitCode` are asserted both in simulated and mock-process tests, and all three mode-specific behaviors (chain reset, parallel independence, fork fail) are covered. The new mock process integration tests validate the full enforcement pipeline end-to-end. No regressions from the existing 561-test suite.

---

## Review — Security Re-Review (2026-05-03)

### Re-evaluation scope
1. The `killProc` → `clearTimeout(maxTimeTimer)` fix from Course Corrections point #6
2. The new `guardrails-mock-process.test.ts` mock process integration tests

### 1. Fix verification: `killProc` clears `maxTimeTimer`

**Confirmed.** `index.ts` lines ~311–316:

```typescript
const killProc = () => {
    wasAborted = true;
    if (maxTimeTimer) clearTimeout(maxTimeTimer);  // ← FIX
    proc.kill("SIGTERM");
    setTimeout(() => { if (!proc.killed) proc.kill("SIGKILL"); }, 5000);
};
```

**Security analysis of the fix:**

| Concern | Verdict | Reasoning |
|---------|---------|-----------|
| New I/O surface | ✅ None | `clearTimeout` is pure in-process timer cancellation |
| Data exposure | ✅ None | No new error messages, logging, or serialization paths |
| Resource exhaustion | ✅ None | Cancels a timer — reduces, not increases, resource footprint |
| Race conditions | ✅ Improved | Eliminates the window where a stale `maxTime` timer fires after abort, overwriting `stopReason` |

The pre-fix bug (timer overwriting `stopReason` after abort) was a **correctness** issue, not a security vulnerability — both paths (abort and maxTime) result in process termination. The fix prevents confusion about *why* the process was killed, which could matter for downstream error-handling decisions but does not open or close any attack surface.

**Verdict: No new security considerations.** ✅

### 2. Mock process integration tests (`guardrails-mock-process.test.ts`)

| Concern | Verdict | Evidence |
|---------|---------|----------|
| Mock leakage to production | ✅ Safe | `vi.mock("node:child_process")` is Vitest-only. This test file is never imported by production code. |
| Sensitive data in tests | ✅ Safe | All values are synthetic: `"/test"` cwd, `"test task"`, `maxTurns: 2`, hardcoded usage JSON (`input: 1000`, `cost: 0.01`). No API keys, real file paths, session tokens, or environment variables. |
| Mock fidelity masking issues | ✅ Safe | `mockProc.kill` sets `killed = true` synchronously — matches Node.js `child_process.kill()` behavior. The close-handler path (`proc.on("close")` → `processLine(buffer)` → resolve) is exercised identically to production. |
| Timer/sleep in tests | ✅ Safe | `await sleep(150)` for the 100ms `maxTime` test is standard async. All tests have 10s hard timeouts. No polling loops or unbounded waits. |
| Test file permissions | ✅ Safe | Standard `.test.ts` file in a `tests/` directory. No elevated permissions. |
| `EventEmitter` usage | ✅ Safe | Standard Node.js API used only in test context to simulate `stdout.on("data")`. No new production dependency. |

**Test design review**: The 4 tests cover the enforcement pipeline end-to-end:
- `maxTurns` guardrail → `stopReason: "guardrail"`, `exitCode: 1`
- `maxTime` timeout → `stopReason: "guardrail"`, `exitCode: 1`
- Race: usage beats maxTime (maxTurns wins synchronously before timer fires)
- Normal completion without guardrail breach

These directly address the prior review's finding that "the enforcement integration point (processLine → checkGuardrails → terminateProcess → close handler) has zero direct test coverage."

**Verdict: No security concerns.** ✅

### 3. Cross-cutting: timer lifecycle completeness

All timer-clearing sites in `spawnSubagentProcess` verified:

| Site | Code | Status |
|------|------|--------|
| Process close | `proc.on("close"): clearTimeout(maxTimeTimer)` | ✅ |
| Process error | `proc.on("error"): clearTimeout(maxTimeTimer)` | ✅ |
| Guardrail breach | `processLine`: `if (maxTimeTimer) clearTimeout(maxTimeTimer)` before `terminateProcess` | ✅ |
| Abort signal | `killProc`: `if (maxTimeTimer) clearTimeout(maxTimeTimer)` | ✅ FIXED |

No dangling timer paths. ✅

### Final Verdict: ✅ PASS

The `killProc` fix is correctness-only (no new attack surface, no new data exposure). The mock process integration tests are standard Vitest patterns with synthetic data — no production exposure, no secrets, no resource exhaustion risks.

No blocking security issues. No hardening recommendations beyond those already captured in the initial Security Review (2026-05-03) above.


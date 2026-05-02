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

- [ ] **RED** — Create `tests/guardrails-enforcement.test.ts`, write tests for enforcement logic
- [ ] **RED** — Run `npx vitest run tests/guardrails-enforcement.test.ts`, observe failures
- [ ] **GREEN** — Add guardrail params to both tool schemas and `ItemConfig`
- [ ] **GREEN** — Add `processLine` guardrail check after usage accumulation
- [ ] **GREEN** — Add `maxTime` setTimeout in `spawnSubagentProcess`
- [ ] **GREEN** — Update fork `onMessage` callback with guardrail check
- [ ] **GREEN** — Pass `config.guardrails` through all spawn call sites
- [ ] **GREEN** — Store guardrails on `AsyncJob` creation in `subagent_fork`
- [ ] **GREEN** — Handle guardrail kill result (stopReason, errorMessage, exitCode)
- [ ] **GREEN** — Run `npx vitest run tests/guardrails-enforcement.test.ts`, observe passes
- [ ] **GREEN** — Run `npx vitest run` (full suite), confirm no regressions
- [ ] **REFACTOR** — Clean up timer management, ensure all exit paths clear timers
- [ ] **REFACTOR** — Run `npx vitest run`, confirm still green

## Review

[Review agents write their verdicts here as they complete each review pass]

## Course Corrections

[Orchestrator appends here when re-delegating — what went wrong, what to try differently]
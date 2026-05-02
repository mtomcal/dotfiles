# Subagent Guardrails — Design Specification

## Overview

Subagent guardrails enforce resource limits on subagent processes. When a subagent exceeds a defined threshold (turns, cost, tokens, or wall-clock time), the extension kills the process and returns a partial result with a clear error message.

This document covers the full design, including data flow, enforcement mechanics, configuration resolution, and integration points.

## Thresholds

| Parameter | Type | Unit | Tracks Against | Enforcement Point |
|-----------|------|------|----------------|-------------------|
| `maxTurns` | number | LLM turns | `usage.turns` (incremented per `message_end` with `role: "assistant"`) | `processLine` — checked after each turn |
| `maxCost` | number | USD | `usage.cost` (cumulative `cost.total` per `message_end`) | `processLine` — checked after each turn |
| `maxTokens` | number | tokens | `usage.contextTokens` (cumulative `totalTokens` per `message_end`) — input + output | `processLine` — checked after each turn |
| `maxTime` | number | seconds | Wall-clock elapsed since process spawn | `setTimeout` — fires after N seconds |

All four parameters are optional. Resolution chain: **per-call → settings.json → unlimited**.

When a parameter is unset at all levels, that dimension is unbounded (current behavior).

## Configuration

### Per-Call Parameters

Added to `subagent_run` and `subagent_fork` tool schemas:

```typescript
maxTurns: Type.Optional(Type.Number({ description: "Max LLM turns before auto-kill" })),
maxCost: Type.Optional(Type.Number({ description: "Max USD cost before auto-kill" })),
maxTokens: Type.Optional(Type.Number({ description: "Max total tokens (input+output) before auto-kill" })),
maxTime: Type.Optional(Type.Number({ description: "Max wall-clock seconds before auto-kill" })),
```

Applied per-subagent-process. In parallel mode, each task gets its own thresholds. In chain mode, each step resets its timers and counters.

Per-item overrides in `tasks[]` and `chain[]` arrays follow the same resolution as `model`, `provider`, `thinking`, `tools`:

**Resolution order:** per-item field → top-level field of the same name → settings.json global default → unlimited.

### Global Defaults in settings.json

```json
{
  "subagentGuardrails": {
    "maxTurns": 50,
    "maxCost": 1.00,
    "maxTokens": 500000,
    "maxTime": 600
  }
}
```

- Absent section → no global defaults (unlimited for all dimensions)
- Present section with missing fields → those dimensions are unlimited
- All fields are optional
- Validated at extension load time (via `readRoutingTable` pattern — same settings path, separate read)

## Data Types

### Guardrails

```typescript
interface Guardrails {
  maxTurns?: number;
  maxCost?: number;
  maxTokens?: number;
  maxTime?: number;
}
```

All fields optional. Undefined = unlimited for that dimension.

### Resolution Function

```typescript
function resolveGuardrails(
  perCall: Guardrails | undefined,
  globalDefaults: Guardrails | undefined,
): Guardrails
```

Returns the merged guardrails: per-call field wins over global default, undefined field = unlimited.

### Check Function

```typescript
function checkGuardrails(usage: UsageStats, guardrails: Guardrails): { breached: true; reason: string } | null
```

Compares current accumulated usage against thresholds. Returns `null` if all within bounds. Returns a breach descriptor if any threshold is exceeded. Checked after each `message_end` event in `processLine`.

Reason format:
- `"exceeded maxTurns (25)"`
- `"exceeded maxCost ($0.50)"`
- `"exceeded maxTokens (200000)"`
- `"exceeded maxTime (300s)"`

## Enforcement

### Usage Thresholds (maxTurns, maxCost, maxTokens)

Enforced in `processLine` inside `spawnSubagentProcess`, after updating `currentResult.usage`:

```typescript
// After each message_end with role === "assistant":
currentResult.usage.turns++;
currentResult.usage.cost += msg.usage?.cost?.total ?? 0;
// ... other accumulation ...

const guardrails = effectiveGuardrails; // resolved from config
const breach = checkGuardrails(currentResult.usage, guardrails);
if (breach) {
  clearTimeout(maxTimeTimer);
  currentResult.stopReason = "guardrail";
  currentResult.errorMessage = `Subagent killed: ${breach.reason}`;
  proc.kill("SIGTERM");
  // proc.on("close") handler will resolve the promise with the partial result
}

// For forked jobs, the onMessage callback also checks:
const jobBreach = checkGuardrails(currentResult.usage, jobGuardrails);
if (jobBreach) {
  clearTimeout(maxTimeTimer);
  jobMgr.cancelJob(job.id); // Uses existing cancel path — kills process, marks cancelled
  // Override stopReason and errorMessage on the result
  currentResult.stopReason = "guardrail";
  currentResult.errorMessage = `Subagent killed: ${jobBreach.reason}`;
}
```

For forked jobs, the `onMessage` callback in `subagent_fork`'s execute handler also checks thresholds and calls `jobMgr.cancelJob()` when breached. The cancellation notification includes the guardrail reason.

### Time Threshold (maxTime)

Enforced via `setTimeout` in `spawnSubagentProcess`:

```typescript
let maxTimeTimer: ReturnType<typeof setTimeout> | null = null;

if (guardrails.maxTime) {
  maxTimeTimer = setTimeout(() => {
    currentResult.stopReason = "guardrail";
    currentResult.errorMessage = `Subagent killed: exceeded maxTime (${guardrails.maxTime}s)`;
    proc.kill("SIGTERM");
    setTimeout(() => { if (!proc.killed) proc.kill("SIGKILL"); }, 5000);
  }, guardrails.maxTime * 1000);
}
```

Cleared in `proc.on("close")` and on any usage guardrail kill (prevent dangling timer for a dead process).

### Interaction Between Thresholds

If multiple thresholds are breached simultaneously (e.g., both maxTurns and maxCost exceeded on the same turn), the first one checked wins. The check order is: `maxTurns` → `maxCost` → `maxTokens`. The process is killed once — no double-kill.

If `maxTime` fires while a usage guardrail is also being processed in `processLine`, the usage guardrail wins because `processLine` runs synchronously and sets `stopReason` first. The `proc.on("close")` handler resolves the promise with whichever `stopReason` was set.

### Process Kill Behavior

When a guardrail fires:

1. **Usage guardrails** (in `processLine`): `clearTimeout(maxTimeTimer)`, set `currentResult.stopReason` and `currentResult.errorMessage`, then `proc.kill("SIGTERM")`.
2. **Time guardrail** (in `setTimeout`): Set `currentResult.stopReason` and `currentResult.errorMessage`, then `proc.kill("SIGTERM")` with 5-second SIGKILL fallback.
3. `proc.on("close")` handler: `clearTimeout(maxTimeTimer)` (no-op if already cleared/fired), `currentResult.exitCode = code ?? 0` (but guardrail kills set `exitCode` to 1 on close), resolve the promise.

### Result on Guardrail Kill

The `SingleResult` contains:

| Field | Value |
|-------|-------|
| `exitCode` | `1` (non-zero = failure) |
| `stopReason` | `"guardrail"` (new value, distinct from `"error"` and `"aborted"`) |
| `errorMessage` | `"Subagent killed: exceeded maxTurns (25)"` (or cost/tokens/time) |
| `messages` | Whatever was accumulated before the kill |
| `usage` | Cumulative stats up to the kill point |

For `subagent_run` (blocking): returned as `isError: true` tool result with the error message.
For `subagent_fork` (async): `emitCompletionNotification` fires with status `"failed"` and the guardrail reason.

### for Chain Mode

Each step is a separate `spawnSubagentProcess` call. Thresholds reset per step:
- Step 1 completes → thresholds reset → Step 2 starts with fresh `usage` and a new `maxTime` timer
- If Step 2 hits a guardrail, the chain stops at Step 2. Step 1's output is preserved, Step 2 returns a partial result with `stopReason: "guardrail"`.

### For Parallel Mode

Each task is a separate `spawnSubagentProcess` call with its own thresholds, timers, and usage counters. Breaches are independent — one task hitting maxTurns doesn't affect others.

## Data Flow

### SubagentConfig Extension

```typescript
// subagent-config.ts
interface SubagentConfig {
  name: string;
  systemPrompt: string | undefined;
  tools: string[] | undefined;
  model: string | undefined;
  provider: string | undefined;
  thinking: ThinkingLevel;
  contextFiles: boolean;
  extensions: boolean;
  guardrails: Guardrails; // NEW
}

interface ResolvableFields {
  // ... existing fields ...
  maxTurns?: number;  // NEW
  maxCost?: number;   // NEW
  maxTokens?: number;  // NEW
  maxTime?: number;    // NEW
}
```

`resolveConfig()` resolves guardrails with the same per-item > top-level pattern as other fields, then merges with global defaults from `settings.json`:

```typescript
// In resolveConfig():
const perCallGuardrails: Guardrails = {
  maxTurns: perItem.maxTurns ?? topLevel?.maxTurns,
  maxCost: perItem.maxCost ?? topLevel?.maxCost,
  maxTokens: perItem.maxTokens ?? topLevel?.maxTokens,
  maxTime: perItem.maxTime ?? topLevel?.maxTime,
};
config.guardrails = resolveGuardrails(perCallGuardrails, globalDefaults);
```

### AsyncJob Extension

```typescript
// job-manager.ts
interface AsyncJob {
  // ... existing fields ...
  guardrails?: Guardrails; // NEW
}
```

Serialized and deserialized alongside existing fields. Used for status display.

### Settings Reading

`guardrails.ts` reads `subagentGuardrails` from `settings.json` (same path as routing), validates field types, returns `Guardrails | null`:

```typescript
function readGuardrailDefaults(settingsPath: string): Guardrails | null
```

## Tool Schema Changes

### subagent_run

Added to the parameters schema:

```typescript
maxTurns: Type.Optional(Type.Number({ description: "Max LLM turns before auto-kill" })),
maxCost: Type.Optional(Type.Number({ description: "Max USD cost before auto-kill" })),
maxTokens: Type.Optional(Type.Number({ description: "Max total tokens (input+output) before auto-kill" })),
maxTime: Type.Optional(Type.Number({ description: "Max wall-clock seconds before auto-kill" })),
```

Top-level thresholds apply to single and chain modes. In parallel mode (`tasks[]`), each `ItemConfig` also gains these four fields. Chain mode (`chain[]`), each step also gains these four fields. Per-item > top-level > settings.json > unlimited.

### subagent_fork

Same four parameters at top level and in `ItemConfig` for the `tasks[]` array.

### promptGuidelines Addition

```
"Set maxTurns, maxCost, maxTokens, or maxTime to enforce resource limits on subagents. When a threshold is exceeded, the subagent is killed and returns a partial result with an error message. Per-call overrides take precedence over global defaults in settings.json."
```

### promptSnippet

No change — the snippet is already concise.

## Display Changes

### subagent_status Output

For running jobs with guardrails, show progress against thresholds:

```
⏳ codegen-a3f2b7 — running
Progress:
- Turns: 18/25
- Cost: $0.32/$0.50
- Tokens: 84K/200K
- Time: 2m30s/5m
- Last tool call: edit src/auth.ts
```

Format: `current/default` for each dimension that has a threshold. Omit dimensions without thresholds.

### TUI Widget

The status widget above the editor shows guardrail progress for running jobs:

```
⏳ codegen  18/25T  $0.32/$0.50  84K/200K  2m30s/5m
```

Compact single-line format. Only shows dimensions with thresholds set.

### Completion Notification

Guardrail kills trigger `emitCompletionNotification` with status `"failed"` and the error message:

```
✗ Subagent: `codegen-a3f2b7` — failed
Job: codegen-a3f2b7
Task: Refactor the auth module
Subagent killed: exceeded maxTurns (25)
Usage: 24 turns, $0.38, 142K tokens
```

### Fork Result

The immediate return from `subagent_fork` when a job is spawned includes guardrails in the job listing:

```
- `codegen-a3f2b7`: **codegen** [read,write,bash,edit] — Refactor auth module (running)
  Guardrails: 25 turns, $0.50, 200K tokens, 5m
```

## New File: guardrails.ts

The `guardrails.ts` module contains:

1. **`Guardrails` type** — interface with optional `maxTurns`, `maxCost`, `maxTokens`, `maxTime`
2. **`readGuardrailDefaults(settingsPath: string): Guardrails | null`** — reads `subagentGuardrails` from settings.json, validates, returns defaults
3. **`resolveGuardrails(perCall: Guardrails, globalDefaults: Guardrails | null): Guardrails`** — per-call > global > unlimited
4. **`checkGuardrails(usage: UsageStats, guardrails: Guardrails): { breached: true; reason: string } | null`** — checks usage against thresholds, returns breach descriptor or null
5. **`formatGuardrailProgress(usage: UsageStats, guardrails: Guardrails | undefined, elapsedMs: number): string`** — formats "18/25T $0.32/$0.50" progress strings
6. **`formatGuardrailLine(guardrails: Guardrails | undefined): string`** — formats "25 turns, $0.50, 200K tokens, 5m" for spawn/fork display

## Modified Files

| File | Changes |
|------|---------|
| `guardrails.ts` (new) | Types, resolution, checking, formatting |
| `subagent-config.ts` | Add `Guardrails` to `SubagentConfig`, add threshold fields to `ResolvableFields`, extend `resolveConfig()` |
| `job-manager.ts` | Add `guardrails` field to `AsyncJob` and `SerializedJob`, update `createJob()` signature |
| `index.ts` | Add 4 params to `subagent_run`/`subagent_fork` schemas, read global defaults from settings, pass guardrails into `spawnSubagentProcess`, add `processLine` checks, add `maxTime` timer, clear timer on close/kill, update status output, update widget, update renderers |
| `renderers.ts` | Add `formatGuardrailProgress()` and `formatGuardrailLine()` for display |
| `widget.ts` | Show guardrail progress in TUI widget |
| `settings.json` | Add `subagentGuardrails` section (example defaults, not forced) |

## Not in Scope for v1

- **`maxOutputTokens`** — too narrow, `maxTokens` and `maxTurns` cover the use case
- **`action: "warn"` mode** — injecting steer messages into child processes requires stdin pipe protocol changes
- **Pooled budgets across jobs** — per-subagent only; global session budget is a separate feature
- **Per-routing-category guardrail defaults** — flat global defaults only; category overrides can be added later
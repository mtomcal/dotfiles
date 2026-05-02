# Slice 1: Pure Guardrails Module

## Context

**Spec references**: `specs/subagent-guardrails.md` — Sections "Thresholds", "Configuration", "Data Types", "New File: guardrails.ts"

**Decisions**: 
- Guardrails type: required field on SubagentConfig with default `{}` (all fields undefined = unlimited) — Grill Q10
- Format functions: live in `guardrails.ts`, not `renderers.ts` — Grill Q5
- Settings defaults: will be added in Slice 2, this slice only provides `readGuardrailDefaults`

**Current code state**: No `guardrails.ts` file exists yet. This is a new file. The `routing.ts` file provides the pattern for reading from `settings.json`.

**Dependency**: none

## Files

- Create: `~/.pi/agent/extensions/subagent/guardrails.ts` — New module with types, resolution, checking, formatting, and settings reading
- Create: `~/.pi/agent/extensions/subagent/tests/guardrails.test.ts` — Unit tests for all functions in guardrails.ts
- Read: `~/.pi/agent/extensions/subagent/routing.ts` — Pattern for `readGuardrailDefaults` (reads from settings.json, validates, returns typed result or null)
- Read: `~/.pi/agent/extensions/subagent/job-manager.ts` — `UsageStats` interface (imported by `checkGuardrails`)

## Green — Scope

**Implementation points** (target: ≤6 per slice):

1. Define `Guardrails` interface in `guardrails.ts` with 4 optional fields: `maxTurns?`, `maxCost?`, `maxTokens?`, `maxTime?`
2. Implement `resolveGuardrails(perCall: Guardrails | undefined, globalDefaults: Guardrails | null): Guardrails` — per-call field wins over global default, undefined field = unlimited
3. Implement `checkGuardrails(usage: UsageStats, guardrails: Guardrails, elapsedMs: number): { breached: true; reason: string } | null` — check order: maxTurns → maxCost → maxTokens → maxTime
4. Implement `formatGuardrailProgress(usage: UsageStats, guardrails: Guardrails | undefined, elapsedMs: number): string` — format like `18/25T $0.32/$0.50 84K/200K 2m30s/5m`
5. Implement `formatGuardrailLine(guardrails: Guardrails | undefined): string` — format like `25 turns, $0.50, 200K tokens, 5m`
6. Implement `readGuardrailDefaults(settingsPath: string): Guardrails | null` — read `subagentGuardrails` from settings.json, validate field types, return typed result or null

## Red — Write Tests First

Create the test file and write assertions for the behavior this slice requires. Do **not** create or modify any implementation source files at this stage.

Expected: **25–35 tests**

- Test file: `~/.pi/agent/extensions/subagent/tests/guardrails.test.ts`
- What the tests prove: correct behavior of each pure function in isolation
- Assertion strategy: deterministic — these are all pure functions with no I/O side effects (except `readGuardrailDefaults` which reads a file)
- Existing tests to rewrite: none

**Input/output examples for `formatGuardrailProgress`**:

| Usage | Guardrails | Elapsed | Expected output |
|-------|-----------|---------|-----------------|
| `{ turns: 18, cost: 0.32, contextTokens: 84000 }` | `{ maxTurns: 25, maxCost: 0.50, maxTokens: 200000, maxTime: 300 }` | 150000 | `18/25T $0.32/$0.50 84K/200K 2m30s/5m` |
| `{ turns: 5, cost: 0.01, contextTokens: 10000 }` | `{ maxTurns: 20 }` | 30000 | `5/20T` |
| `{ turns: 3, cost: 0, contextTokens: 5000 }` | `undefined` | 10000 | `` (empty string) |
| `{ turns: 10, cost: 0.50, contextTokens: 100000 }` | `{ maxTurns: 10, maxCost: 1.00, maxTokens: 500000 }` | 120000 | `10/10T $0.50/$1.00 100K/500K` |

**Input/output examples for `formatGuardrailLine`**:

| Guardrails | Expected output |
|-----------|-----------------|
| `{ maxTurns: 25, maxCost: 0.50, maxTokens: 200000, maxTime: 300 }` | `25 turns, $0.50, 200K tokens, 5m` |
| `{ maxTurns: 20 }` | `20 turns` |
| `undefined` | `` (empty string) |
| `{ maxCost: 1.00 }` | `$1.00` |

**Input/output examples for `checkGuardrails`**:

| Usage | Guardrails | Elapsed (ms) | Expected |
|-------|-----------|---------------|----------|
| `{ turns: 26, cost: 0, contextTokens: 0, ... }` | `{ maxTurns: 25 }` | 0 | `{ breached: true, reason: "exceeded maxTurns (25)" }` |
| `{ turns: 10, cost: 0.60, contextTokens: 0, ... }` | `{ maxCost: 0.50 }` | 0 | `{ breached: true, reason: "exceeded maxCost ($0.50)" }` |
| `{ turns: 5, cost: 0, contextTokens: 0, ... }` | `{ maxTurns: 10 }` | 0 | `null` (within bounds) |
| `{ turns: 5, cost: 0, contextTokens: 0, ... }` | `{}` | 0 | `null` (no limits) |
| `{ turns: 5, cost: 0, contextTokens: 0, ... }` | `{ maxTime: 300 }` | 310000 | `{ breached: true, reason: "exceeded maxTime (300s)" }` |
| `{ turns: 25, cost: 0.60, contextTokens: 0, ... }` | `{ maxTurns: 25, maxCost: 0.50 }` | 0 | `{ breached: true, reason: "exceeded maxTurns (25)" }` (maxTurns checked first) |

**Input/output examples for `resolveGuardrails`**:

| Per-call | Global defaults | Result |
|----------|----------------|--------|
| `{ maxTurns: 20 }` | `{ maxTurns: 50, maxCost: 1.00 }` | `{ maxTurns: 20, maxCost: 1.00 }` (per-call wins) |
| `{}` | `{ maxTurns: 50 }` | `{ maxTurns: 50 }` (global fallback) |
| `undefined` | `{ maxTurns: 50 }` | `{ maxTurns: 50 }` (global only) |
| `{ maxTurns: 20 }` | `null` | `{ maxTurns: 20 }` (no globals) |
| `undefined` | `null` | `{}` (all unlimited) |

**Test structure for `readGuardrailDefaults`**:
- Read a valid settings.json with `subagentGuardrails` section → returns `Guardrails`
- Read settings.json without `subagentGuardrails` → returns `null`
- Read nonexistent file → returns `null` (with console.warn)
- Read settings.json with invalid field types (e.g., `maxTurns: "fifty"`) → ignores invalid fields, returns partial `Guardrails`
- Read settings.json with `subagentGuardrails: {}` → returns `null` (empty section = no defaults)

Run the test suite. You must see the test fail. If the test passes, it's not a red test.

**Hard gate: Do not proceed to Green until you have created the test file, written the tests, run the test suite, and observed a failure.**

## Green — Make Tests Pass

Now create the implementation source files to make the failing tests pass. Write the smallest change that turns red to green.

- Source file: `~/.pi/agent/extensions/subagent/guardrails.ts` (create)
- What to create: `Guardrails` interface, `resolveGuardrails`, `checkGuardrails`, `formatGuardrailProgress`, `formatGuardrailLine`, `readGuardrailDefaults`
- Constraint: import `UsageStats` from `./job-manager.js` — do not duplicate the type. Import `formatTokens` from `./renderers.js` for token formatting in `formatGuardrailProgress`.
- Decisions/spec delta: Grill Q10 (required field, default `{}`), Q5 (in guardrails.ts), Q6 (spec values for defaults)

### Key implementation notes

**`Guardrails` interface**:
```typescript
export interface Guardrails {
  maxTurns?: number;
  maxCost?: number;
  maxTokens?: number;
  maxTime?: number;
}
```

**`resolveGuardrails`**: Per-call field wins over global default. If per-call field is defined, use it. If per-call field is undefined and global default exists for that field, use global. If both are undefined, the field is undefined (= unlimited). Undefined per-call parameter is treated as `{}` (not undefined — per the grill decision, `SubagentConfig.guardrails` is always a `Guardrails` object).

**`checkGuardrails`**: Check order is `maxTurns → maxCost → maxTokens → maxTime`. If multiple thresholds are breached on the same check, the first one checked wins (return immediately). `elapsedMs` is a separate parameter — not part of `UsageStats`. `null` return means all within bounds.

**`formatGuardrailProgress`**: Only show dimensions that have thresholds set. Format: `18/25T $0.32/$0.50 84K/200K 2m30s/5m` — each dimension separated by a space. Use `formatTokens` from renderers for token counts. Cost format: `$0.32/$0.50` with 2 decimal places. Time format: `Xm Ys/Xm Ys` for minutes+seconds, or `Xs/Xs` for under a minute. Return empty string if `guardrails` is `undefined` or all fields are `undefined`.

**`formatGuardrailLine`**: Format: `25 turns, $0.50, 200K tokens, 5m` — comma-separated, no trailing comma. Use `formatTokens` for token counts. Time: `Xm` for minutes, `Xs` for seconds. Return empty string if `guardrails` is `undefined` or all fields are `undefined`.

**`readGuardrailDefaults`**: Follow the `readRoutingTable` pattern from `routing.ts`. Read `subagentGuardrails` from settings.json. Validate each field type (number or undefined). Ignore non-number fields with a console.warn. Return `null` if the section is absent, empty, or the file doesn't exist. Return a `Guardrails` object with only valid number fields set.

## Refactor — Clean Up While Green

- Ensure `formatTokens` import from `renderers.js` doesn't create a circular dependency (it doesn't — renderers doesn't import from guardrails)
- Consider whether `readGuardrailDefaults` should be in a separate file for testability — it's fine in `guardrails.ts` since it's a pure reader function
- Keep separate: `Guardrails` type stays in `guardrails.ts` (not moved to `job-manager.ts` since it's a new domain concept)

## Progress

- [ ] **RED** — Create test file `tests/guardrails.test.ts`, write tests for all 6 functions
- [ ] **RED** — Run `npx vitest run tests/guardrails.test.ts`, observe failures
- [ ] **GREEN** — Implement `guardrails.ts` with all 6 exports
- [ ] **GREEN** — Run `npx vitest run tests/guardrails.test.ts`, observe all passes
- [ ] **GREEN** — Run `npx vitest run` (full suite), confirm no regressions
- [ ] **REFACTOR** — Check for circular deps, verify import patterns
- [ ] **REFACTOR** — Run `npx vitest run`, confirm still green

## Review

[Review agents write their verdicts here as they complete each review pass]

## Course Corrections

[Orchestrator appends here when re-delegating — what went wrong, what to try differently]
# Slice 2: Config and Job Wiring

## Context

**Spec references**: `specs/subagent-guardrails.md` — Sections "Configuration", "Data Types", "SubagentConfig Extension", "AsyncJob Extension", "Settings Reading"

**Decisions**:
- `SubagentConfig.guardrails` is a required field with default `{}` — all fields undefined means unlimited (Grill Q10)
- `readGuardrailDefaults` already created in Slice 1
- Settings defaults: `{ maxTurns: 50, maxCost: 1.00, maxTokens: 500000, maxTime: 600 }` to be added to `~/.pi/agent/settings.json` (Grill Q6)
- Extract `terminateProcess` helper from `cancelJob` — shared SIGTERM/SIGKILL logic (Grill Q11)

**Current code state**: Slice 1 created `guardrails.ts` with the `Guardrails` type and all pure functions. This slice wires those into the existing config resolution, adds the field to `AsyncJob`, and adds defaults to settings.json.

**Dependency**: Slice 1 (needs `Guardrails` type and `resolveGuardrails` from `guardrails.ts`)

## Files

- Modify: `~/.pi/agent/extensions/subagent/subagent-config.ts` — Add 4 guardrail fields to `ResolvableFields`, add `guardrails: Guardrails` to `SubagentConfig`, update `resolveConfig()` to resolve guardrails
- Modify: `~/.pi/agent/extensions/subagent/job-manager.ts` — Add `guardrails?: Guardrails` to `AsyncJob` and `SerializedJob`, extract `terminateProcess` helper, update `cancelJob`/`cancelAll` to use it
- Modify: `~/dotfiles/pi/settings.json` — Add `subagentGuardrails` section with default values
- Modify: `~/.pi/agent/extensions/subagent/tests/subagent-config.test.ts` — Add tests for guardrails in config resolution
- Modify: `~/.pi/agent/extensions/subagent/tests/job-manager.test.ts` — Add tests for `guardrails` field on `AsyncJob`, `terminateProcess` behavior
- Read: `~/.pi/agent/extensions/subagent/guardrails.ts` — Import `Guardrails`, `resolveGuardrails`, `readGuardrailDefaults`
- Read: `~/.pi/agent/extensions/subagent/routing.ts` — Pattern for reading settings.json

⚠️ **Shared with Slice 3**: `job-manager.ts` — Slice 2 adds `terminateProcess` and the `guardrails` field. Slice 3 uses `terminateProcess` and reads `guardrails` from `AsyncJob`. Different functions, low merge risk.

## Green — Scope

**Implementation points** (6 points):

1. Add `maxTurns?`, `maxCost?`, `maxTokens?`, `maxTime?` optional number fields to `ResolvableFields` in `subagent-config.ts`
2. Add `guardrails: Guardrails` required field (default `{}`) to `SubagentConfig` in `subagent-config.ts`
3. Update `resolveConfig()` to call `resolveGuardrails()` merging per-call fields, top-level fields, and global defaults from settings
4. Add `guardrails?: Guardrails` to `AsyncJob` and `SerializedJob` interfaces in `job-manager.ts`, update `createJob()` to accept and store guardrails
5. Extract `terminateProcess(proc: ChildProcess): Promise<void>` helper from `cancelJob` and `cancelAll` in `job-manager.ts` — sends SIGTERM, waits up to 5s, sends SIGKILL if still alive
6. Add `subagentGuardrails` defaults to `~/dotfiles/pi/settings.json` with `{ "maxTurns": 50, "maxCost": 1.00, "maxTokens": 500000, "maxTime": 600 }`

## Red — Write Tests First

Create test assertions for the behavior this slice requires. Do **not** create or modify implementation source files at this stage.

Expected: **12–18 tests**

- Test file: `~/.pi/agent/extensions/subagent/tests/subagent-config.test.ts` (extend)
- Test file: `~/.pi/agent/extensions/subagent/tests/job-manager.test.ts` (extend)
- What the tests prove: guardrails field is correctly resolved and stored on config; `terminateProcess` correctly sends SIGTERM and SIGKILL; `AsyncJob` carries guardrails through create/serialize/deserialize
- Assertion strategy: deterministic config resolution tests; mock child process for `terminateProcess`
- Existing tests to rewrite: none

**Test cases for guardrails in config resolution** (`subagent-config.test.ts`):

| Per-call | Top-level | Global defaults | Expected `config.guardrails` |
|----------|-----------|-----------------|------------------------------|
| `maxTurns: 20` | none | `maxTurns: 50, maxCost: 1.00` | `{ maxTurns: 20, maxCost: 1.00 }` |
| none | `maxCost: 0.30` | `maxTurns: 50, maxCost: 1.00` | `{ maxTurns: 50, maxCost: 0.30 }` |
| none | none | `null` | `{}` (all unlimited) |
| `maxTurns: 10, maxTokens: 100000` | `maxTurns: 30` | `{ maxTurns: 50, maxTokens: 500000 }` | `{ maxTurns: 10, maxTokens: 100000, maxCost: undefined }` — per-call wins over top-level over globals |

**Test cases for job manager** (`job-manager.test.ts`):
- `createJob` with guardrails stores them on the job
- `createJob` without guardrails leaves `guardrails` undefined
- `serialize`/`deserialize` round-trip preserves `guardrails` field
- `terminateProcess` sends SIGTERM, then SIGKILL after 5s timeout if process doesn't exit
- `terminateProcess` resolves immediately if process already exited

Run the test suite. You must see the test fail. If the test passes, it's not a red test.

**Hard gate: Do not proceed to Green until you have created/extended the test files, written the tests, run the test suite, and observed a failure.**

## Green — Make Tests Pass

Now modify the implementation source files to make the failing tests pass. Write the smallest change that turns red to green.

- Source file: `~/.pi/agent/extensions/subagent/subagent-config.ts` (modify)
- Source file: `~/.pi/agent/extensions/subagent/job-manager.ts` (modify)
- Source file: `~/dotfiles/pi/settings.json` (modify)

### Key implementation notes

**`ResolvableFields` extension** in `subagent-config.ts`:
Add 4 optional fields:
```typescript
maxTurns?: number;
maxCost?: number;
maxTokens?: number;
maxTime?: number;
```

**`SubagentConfig` extension** in `subagent-config.ts`:
Add required field:
```typescript
guardrails: Guardrails;
```
Import `Guardrails` from `./guardrails.js`.

**`resolveConfig()` update** in `subagent-config.ts`:
After resolving all other fields, resolve guardrails:
1. Build per-call `Guardrails` from per-item fields (`perItem.maxTurns` etc.) → top-level fields (`topLevel?.maxTurns` etc.)
2. Call `readGuardrailDefaults(settingsPath)` to get global defaults (read once at extension init, not on every call)
3. Call `resolveGuardrails(perCallGuardrails, globalDefaults)` to merge
4. Assign to `config.guardrails`

**Important**: The `settingsPath` for `readGuardrailDefaults` must be the same path used by `readRoutingTable` — it's set at extension init time in `index.ts`. Pass it as a parameter to `resolveConfig` or read it at module init time. The spec says "same settings path as routing" — share the path already resolved in `index.ts`.

**`AsyncJob`/`SerializedJob` extension** in `job-manager.ts`:
Add optional field:
```typescript
interface AsyncJob {
  // ... existing fields ...
  guardrails?: Guardrails;
}

interface SerializedJob {
  // ... existing fields ...
  guardrails?: Guardrails;
}
```
Import `Guardrails` from `./guardrails.js`.

**`createJob()` update**: Change signature to accept guardrails:
```typescript
createJob(name: string, task: string, guardrails?: Guardrails): AsyncJob {
  // ... existing logic ...
  const job: AsyncJob = {
    // ... existing fields ...
    guardrails,
  };
  // ...
}
```

**`terminateProcess` extraction** in `job-manager.ts`:
```typescript
export function terminateProcess(proc: ChildProcess): Promise<void> {
  return new Promise((resolve) => {
    if (proc.killed) { resolve(); return; }
    proc.kill("SIGTERM");
    const timeout = setTimeout(() => {
      if (!proc.killed) proc.kill("SIGKILL");
    }, 5000);
    proc.on("close", () => {
      clearTimeout(timeout);
      resolve();
    });
  });
}
```

Then update `cancelJob` and `cancelAll` to use `terminateProcess`:
```typescript
cancelJob(jobId: string): void {
  const job = this.jobs.get(jobId);
  if (job && job.status === "running") {
    const proc = job.process;
    job.status = "cancelled";
    job.completedAt = Date.now();
    this.onCancel?.(job);
    job.process = null;
    if (proc) {
      terminateProcess(proc); // fire and forget — don't await
    }
  }
}
```

Note: `cancelJob` and `cancelAll` are synchronous. `terminateProcess` returns a Promise but we don't need to await it — the SIGTERM is sent synchronously, the 5s timer fires independently. The existing behavior is preserved because `proc.kill("SIGTERM")` happens before the Promise resolves.

**`settings.json` update** at `~/dotfiles/pi/settings.json`:
Add inside the existing JSON object:
```json
"subagentGuardrails": {
  "maxTurns": 50,
  "maxCost": 1.00,
  "maxTokens": 500000,
  "maxTime": 600
}
```

## Refactor — Clean Up While Green

- Verify that `resolveConfig` still passes all existing tests after adding guardrails resolution
- Verify that `createJob` still passes all existing tests after adding the `guardrails` parameter (it's optional, so existing callers should work)
- Verify that `cancelJob`/`cancelAll` behavior is unchanged by the `terminateProcess` extraction
- Keep separate: `terminateProcess` is exported for Slice 3 to use in guardrail kill logic

## Progress

- [ ] **RED** — Extend `tests/subagent-config.test.ts` with guardrails resolution tests
- [ ] **RED** — Extend `tests/job-manager.test.ts` with guardrails field and terminateProcess tests
- [ ] **RED** — Run `npx vitest run tests/subagent-config.test.ts tests/job-manager.test.ts`, observe failures
- [ ] **GREEN** — Add guardrail fields to `ResolvableFields`, `SubagentConfig`, `AsyncJob`, `SerializedJob`
- [ ] **GREEN** — Update `resolveConfig()` to resolve guardrails with `readGuardrailDefaults`
- [ ] **GREEN** — Extract `terminateProcess` from `cancelJob`/`cancelAll`
- [ ] **GREEN** — Add `subagentGuardrails` to `settings.json`
- [ ] **GREEN** — Run `npx vitest run tests/subagent-config.test.ts tests/job-manager.test.ts`, observe passes
- [ ] **GREEN** — Run `npx vitest run` (full suite), confirm no regressions
- [ ] **REFACTOR** — Verify existing cancelJob/cancelAll tests still pass
- [ ] **REFACTOR** — Run `npx vitest run`, confirm still green

## Review

[Review agents write their verdicts here as they complete each review pass]

## Course Corrections

[Orchestrator appends here when re-delegating — what went wrong, what to try differently]
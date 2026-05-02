# Slice 1: Data Structures — Add `tools` Field

## Context

**Spec references**: AIAGT v1.4.0 rules 21, 26, 27
- Rule 21: `tools?: string[]` on `AsyncJob`, `SingleResult`, `SerializedJob`. Undefined = all default tools. Non-empty = comma-separated bracket `[t1,t2,...]`.
- Rule 26: `tools` on `AsyncJob` persisted in `SerializedJob`. Missing `tools` (from older data) treated as `undefined`.
- Rule 27: `tools` on `SingleResult` set in `spawnSubagentProcess()` alongside `provider`, `model`, `thinking`.

**Current code state**: `AsyncJob`, `SingleResult`, and `SerializedJob` in `job-manager.ts` have no `tools` field. `SubagentConfig.tools` exists as `string[] | undefined` but is not threaded into job/result/serialization.

**Dependency**: None — this is the foundation slice.

## Red — Write Tests First

Test file: `tests/tools-data-structures.test.ts`

Assertions:
1. `AsyncJob` type accepts optional `tools?: string[]` field
2. `SingleResult` type accepts optional `tools?: string[]` field
3. `SerializedJob` type accepts optional `tools?: string[]` field
4. `createJob()` returns a job with `tools: undefined` by default
5. After setting `job.tools = ["read","grep"]`, the field persists
6. `serialize()` includes `tools` on jobs that have it defined
7. `serialize()` omits `tools` when it's `undefined` (or includes it as undefined)
8. `deserialize()` with `tools` data populates the field correctly
9. `deserialize()` with missing `tools` field (legacy data) treats it as `undefined`
10. `SingleResult` constructed with `tools: ["read","write","bash"]` carries it through
11. `SingleResult` constructed without `tools` has `tools: undefined`

Run: `npx vitest run tests/tools-data-structures.test.ts`

**Hard gate: Do not proceed to Green until tests are created and observed to fail (type errors or assertion failures).**

## Green — Make Tests Pass

- Source file: `pi/extensions/subagent/job-manager.ts`
- Changes:
  1. Add `tools?: string[]` to `SingleResult` interface (after `thinking` field)
  2. Add `tools?: string[]` to `AsyncJob` interface (after `completedAt` field)
  3. Add `tools?: string[]` to `SerializedJob` interface (after `completedAt` field)
  4. Update `createJob()` — no change needed (undefined by default, set externally per rule 27)
  5. Update `serialize()` — include `tools` in output mapping
  6. Update `deserialize()` — read `tools` from data, treat missing field as `undefined`

- Source file: `pi/extensions/subagent/renderers.ts`
  7. Add `tools?: string[]` to the local `SingleResult` interface (keep in sync with job-manager)
  8. Add `tools` to `SubagentDetails` if needed — actually not needed yet, that's slice 3

Constraint: Minimal type additions only. No rendering changes. No formatting utilities yet.

## Refactor — Clean Up While Green

- Ensure `tools` field is consistently typed as `string[] | undefined` (not `string[] | null`)
- Verify that existing tests in `job-manager.test.ts` still pass (backward compat with no `tools` field)

## Progress

- [ ] **RED** — Create test file `tests/tools-data-structures.test.ts`, write tests for tools field presence
- [ ] **RED** — Run `npx vitest run tests/tools-data-structures.test.ts`, observe type/assertion failures
- [ ] **GREEN** — Add `tools?: string[]` to `SingleResult`, `AsyncJob`, `SerializedJob` in `job-manager.ts`
- [ ] **GREEN** — Update `serialize()` and `deserialize()` to handle `tools` field
- [ ] **GREEN** — Add `tools?: string[]` to `SingleResult` in `renderers.ts` (local interface)
- [ ] **GREEN** — Run `npx vitest run tests/tools-data-structures.test.ts`, observe all pass
- [ ] **GREEN** — Run `npx vitest run`, observe existing tests still pass
- [ ] **REFACTOR** — Verify consistent `string[] | undefined` typing, not `string[] | null`
- [ ] **REFACTOR** — Run `npx vitest run`, confirm still green

## Review

[Review agents write their verdicts here as they complete each review pass]

## Course Corrections

[Orchestrator appends here when re-delegating — what went wrong, what to try differently]
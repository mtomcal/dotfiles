# Slice 3: Widget and Renderers — Tools Display in `renderWidgetContent`, `renderSingleResult`, `renderJobStatusLine`

## Context

**Spec references**: AIAGT v1.4.0 rules 21, 24a, 24e, 24f, 24g, 25c, 25d

**Display surfaces this slice covers:**
- **24a** Widget: After name on line 1 (both running and completed/failed). NOT on line 2. NOT in header.
- **24e** `renderCall()`: After model/provider/thinking parentheses, format: `(model/thinking) [tool1,tool2]`
- **24f** `renderSingleResult()`: On identity line in both expanded and collapsed views, format: `(provider/model) [tool1,tool2]`
- **24g** `renderJobStatusLine()`: After job name, format: `✓ name [tool1,tool2] (elapsed) task...`

**Exclusion surfaces (must NOT show tools):**
- **25c** Widget line 2 (snippet + tool call)
- **25d** Widget header line (summary counts)

**Current code state**: 
- `renderWidgetContent()` in `widget.ts` builds lines with name, elapsed, usage, but no tools bracket
- `renderSingleResult()` in `renderers.ts` shows identity line with `(provider/model)` but no tools
- `renderJobStatusLine()` in `renderers.ts` shows `✓ name (elapsed)` but no tools
- `renderCall()` is defined per-tool in `index.ts` (not in renderers.ts) — that's in slice 4

**Dependency**: Slices 1 (data structures) and 2 (formatting utilities)

## Red — Write Tests First

Test file: `tests/tools-widget-renderers.test.ts`

**Widget tests:**
1. Running job with `tools: ["read","grep"]` → line 1 contains `[read,grep]` after name, before elapsed
2. Running job with undefined tools → line 1 does NOT contain `[`
3. Completed job with tools → line contains `[read,grep]`
4. Completed job with undefined tools → no bracket
5. Failed job with tools → line contains bracket
6. Running job line 2 does NOT contain tools bracket (even when tools defined)
7. Header line does NOT contain tools bracket
8. Widget with mixed jobs (some with tools, some without) → correct per-job display

**renderSingleResult tests:**
9. Expanded view: identity line shows `(provider/model) [read,grep]` when tools defined
10. Expanded view: identity line shows `(provider/model)` without bracket when tools undefined
11. Collapsed view: identity line shows bracket when defined, omits when undefined
12. Result with tools but no provider/model → shows just `[read,grep]` after name

**renderJobStatusLine tests:**
13. Job with tools: `✓ name [read,grep] (elapsed) task...`
14. Job without tools: `✓ name (elapsed) task...` — no bracket
15. Failed job with tools: bracket appears

Run: `npx vitest run tests/tools-widget-renderers.test.ts`

**Hard gate: Do not proceed to Green until tests are created and observed to fail.**

## Green — Make Tests Pass

### widget.ts changes:
1. Import `formatToolsBracket` from `renderers.ts`
2. In `renderWidgetContent()`:
   - Running line 1: After the name, before `(elapsed)`, insert `formatToolsBracket(job.result?.tools)` — but the job itself might have tools while the result is null. Use `job.tools` from `AsyncJob` when available (from Slice 1), fall back to `job.result?.tools`
   - Actually: per the data model, `job.tools` is set from `config.tools` at job creation time. Use that.
   - Running line 1 format: `⏳ {name} [{tools}] ({elapsed}) {usage}` when tools defined
   - Running line 1 format: `⏳ {name} ({elapsed}) {usage}` when tools undefined
   - Completed/Failed line: same pattern, bracket after name before `(elapsed)`
   - Line 2 (snippet + tool call): NO tools bracket
   - Header line: NO tools bracket

### renderers.ts changes:
1. In `renderSingleResult()`:
   - Expanded: after `(provider/model)` parentheses, add `formatToolsBracket(r.tools)` — but since this uses `SingleResult` directly, use `r.tools`
   - Collapsed: same, add bracket after model config parentheses
2. In `renderJobStatusLine()`:
   - After `{nameStr}`, add `formatToolsBracket(job.tools ?? job.result?.tools)` — accept both AsyncJob-like and SingleResult-like objects
   - Actually: the function signature takes `{ id, name, task, status, startedAt, completedAt, result? }`. We need to add `tools` to this parameter type or pass it separately. Simplest: add `tools?: string[]` to the inline type.

Constraint: Only touch the specified rendering surfaces. Do NOT change `formatToolCall` or any other rendering logic.

## Refactor — Clean Up While Green

- Ensure `formatToolsBracket` is called consistently with a single source of truth (no inline bracket construction)
- Verify the bracket position matches spec: `[]` after `()` model config, not before

## Progress

- [x] **RED** — Create test file `tests/tools-widget-renderers.test.ts`, write all widget/renderer test assertions
- [x] **RED** — Run `npx vitest run tests/tools-widget-renderers.test.ts`, observe failures
- [x] **GREEN** — Update `renderWidgetContent()` in `widget.ts` to include tools bracket on line 1
- [x] **GREEN** — Update `renderSingleResult()` in `renderers.ts` to include tools bracket on identity line
- [x] **GREEN** — Update `renderJobStatusLine()` in `renderers.ts` to include tools bracket after name
- [x] **GREEN** — Run `npx vitest run tests/tools-widget-renderers.test.ts`, observe all pass
- [x] **GREEN** — Run `npx vitest run`, observe existing widget/renderer tests still pass
- [x] **REFACTOR** — Verify consistent bracket positioning (after `()`, before `elapsed`)
- [x] **REFACTOR** — Run `npx vitest run`, confirm still green

## Review

### ✅ PASS — Slice 3: Widget and Renderers — Tools Display

**Reviewer**: Code Review Agent  
**Date**: 2026-05-02

#### Test Results
- `npx vitest run tests/tools-widget-renderers.test.ts`: **16 tests passed** (1 file)
- `npx vitest run` (full suite): **411 tests passed** (27 files, 0 failures)

#### Requirements Verified

| # | Requirement | Status |
|---|-------------|--------|
| 24a | Widget line 1: `[tools]` after name (running) | ✅ |
| 24a | Widget line 1: `[tools]` after name (completed) | ✅ |
| 24a | Widget line 1: `[tools]` after name (failed) | ✅ |
| 24f | `renderSingleResult()` expanded: `(provider/model) [tools]` | ✅ |
| 24f | `renderSingleResult()` collapsed: `(provider/model) [tools]` | ✅ |
| 24g | `renderJobStatusLine()`: `✓ name [tools] (elapsed) task...` | ✅ |
| 25c | Widget line 2: NO tools bracket | ✅ |
| 25d | Widget header: NO tools bracket | ✅ |
| — | Tools bracket omitted when `tools` is undefined/empty | ✅ |
| — | Mixed jobs (some with tools, some without) display correctly | ✅ |
| — | `formatToolsBracket` as single source of truth (no inline bracket construction) | ✅ |

#### Implementation Notes
- `widget.ts`: Uses `formatToolsBracket(job.tools)` from `AsyncJob` on all relevant status lines (running, completed, failed). Line 2 and header are correctly excluded.
- `renderers.ts`: `renderSingleResult()` appends bracket after `(provider/model)` in both expanded (Container-based) and collapsed (Text-based) views. `renderJobStatusLine()` adds `tools?: string[]` to the parameter type and uses `formatToolsBracket(job.tools ?? job.result?.tools)` for fallback.
- `formatToolCall` and other rendering logic were not modified (per constraint).
- All bracket positioning matches the spec: `[]` after model parentheses, before elapsed time.

#### Edge Cases Covered
- Undefined/empty tools → bracket omitted
- Tools defined but no provider/model → bracket still shows
- Mixed jobs with varying tools state → per-job correct display
- Expanded vs collapsed views both show bracket consistently
- Failed and running jobs with tools show bracket correctly


## Course Corrections

[Orchestrator appends here when re-delegating — what went wrong, what to try differently]
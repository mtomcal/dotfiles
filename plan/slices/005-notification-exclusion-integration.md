# Slice 5: Notification Exclusion + Integration Tests

## Context

**Spec references**: AIAGT v1.4.0 rules 24d (partial — `subagent_wait` is slice 4), 25a, 25b, 25c, 25d

**Exclusion surfaces this slice verifies:**
- **25a** Completion notifications do NOT show a `**Tools:**` line
- **25b** Cancellation notifications do NOT show a `**Tools:**` line
- **25c** Widget line 2 (snippet + tool call line) does NOT show tools bracket — verified in slice 3 but double-checked here
- **25d** Widget header line (summary counts) does NOT show tools bracket — verified in slice 3 but double-checked here

This slice also:
- Sets `tools` on `AsyncJob` in `subagent_fork` (the last remaining piece from rule 27)
- Adds integration-style tests that verify end-to-end tool display behavior
- Confirms backward compatibility of deserialization (rule 26)
- Runs the full spec test scenarios TS-AIAGT-030 through TS-AIAGT-041

**Current code state**: 
- `emitCompletionNotification()` in `index.ts` constructs notification text with `**Job:**`, `**Task:**`, summary, usage — no `**Tools:**`
- `emitCancellationNotification()` similarly has no tools display
- Widget line 2 and header are in `widget.ts` — slice 3 handles those, but this slice adds explicit exclusion tests

**Dependency**: Slices 3 (widget/renderers) and 4 (index surfaces)

## Red — Write Tests First

Test file: `tests/tools-notification-exclusion.test.ts` + `tests/tools-integration.test.ts`

**Notification exclusion tests:**
1. Completion notification with `tools: ["read","grep"]` does NOT contain `**Tools:**`
2. Completion notification with `tools: ["read","grep"]` does NOT contain `[read,grep]`
3. Cancellation notification with `tools: ["read","grep"]` does NOT contain `**Tools:**`
4. Cancellation notification with `tools: ["read","grep"]` does NOT contain `[read,grep]`
5. Widget header line (`⏳ Subagents:...`) does NOT contain `[` bracket even when jobs have tools
6. Widget line 2 (`  "snippet" → tool call`) does NOT contain `[read,grep]` bracket

**Integration / spec scenario tests (TS-AIAGT-030 through TS-AIAGT-041):**

7. **TS-AIAGT-030**: Custom toolset shown as bracket — spawn with `tools: "read,grep"`, every surface shows `[read,grep]`
8. **TS-AIAGT-031**: Undefined tools means all defaults, no display — spawn without `tools`, no bracket anywhere
9. **TS-AIAGT-032**: Bracket convention distinguishes scope from model config — `(provider/model, think:high) [read,grep]`
10. **TS-AIAGT-033**: Long tool list truncation at 30 chars — `[read,write,bash,edit,grep,find +1]`
11. **TS-AIAGT-034**: Widget shows tools on line 1 only
12. **TS-AIAGT-035**: Status shows Tools line after Task
13. **TS-AIAGT-036**: Results shows Tools line after Task
14. **TS-AIAGT-037**: Notifications do NOT show tools
15. **TS-AIAGT-038**: renderCall shows bracket after model config
16. **TS-AIAGT-039**: Fork response shows bracket per job
17. **TS-AIAGT-040**: Parallel/chain result headings include brackets
18. **TS-AIAGT-041**: Deserialization treats missing tools as undefined

Run: `npx vitest run tests/tools-notification-exclusion.test.ts tests/tools-integration.test.ts`

**Hard gate: Do not proceed to Green until tests are created and observed to fail.**

## Green — Make Tests Pass

This slice primarily verifies that the exclusions hold. Implementation changes should be minimal:

1. If `emitCompletionNotification` or `emitCancellationNotification` accidentally received tools display from slice 4, REMOVE it — these are exclusion surfaces
2. If widget line 2 or header line accidentally show tools, REMOVE the bracket from those specific lines
3. Ensure `subagent_fork` sets `job.tools = config.tools` after `jobMgr.createJob()` — this may have been done in slice 4, but verify it's there
4. Add `tools` to the `spawnedJobs` array in `subagent_fork` (for `j.tools` in the fork response)
5. Verify the `subagent-result` message renderer does NOT add tools bracket (this is the notification renderer)

### Potential implementation touchpoints:
- `index.ts` — `emitCompletionNotification()`: verify no `**Tools:**` line
- `index.ts` — `emitCancellationNotification()`: verify no `**Tools:**` line
- `index.ts` — `subagent-result` message renderer: verify no tools bracket in notification rendering
- `index.ts` — `subagent_fork` spawned jobs array: include `tools`
- `widget.ts` — verify line 2 and header don't show tools (covered by slice 3, double-check here)

Constraint: This slice should primarily ADD tests, not change implementation. If implementation changes are needed, they are corrective (removing accidentally-added tools display from exclusion surfaces).

## Refactor — Clean Up While Green

- Remove any redundant test assertions that duplicate slice 3's widget tests
- Ensure integration tests use realistic job fixtures that exercise the full pipeline
- Verify all 12 spec test scenarios pass

## Progress

- [ ] **RED** — Create `tests/tools-notification-exclusion.test.ts` with notification exclusion assertions
- [ ] **RED** — Create `tests/tools-integration.test.ts` with TS-AIAGT-030 through TS-AIAGT-041 scenarios
- [ ] **RED** — Run `npx vitest run tests/tools-notification-exclusion.test.ts tests/tools-integration.test.ts`, observe failures
- [ ] **GREEN** — Verify no tools in completion/cancellation notifications
- [ ] **GREEN** — Verify no tools in widget line 2 or header
- [ ] **GREEN** — Verify `job.tools` is set in fork flow
- [ ] **GREEN** — Add `tools` to spawnedJobs detail in fork response
- [ ] **GREEN** — Run `npx vitest run tests/tools-notification-exclusion.test.ts`, observe all pass
- [ ] **GREEN** — Run `npx vitest run tests/tools-integration.test.ts`, observe all pass
- [ ] **GREEN** — Run `npx vitest run`, observe ALL tests pass (existing + new)
- [ ] **REFACTOR** — Remove redundant test assertions
- [ ] **REFACTOR** — Run `npx vitest run`, confirm still green

## Review

[Review agents write their verdicts here as they complete each review pass]

## Course Corrections

[Orchestrator appends here when re-delegating — what went wrong, what to try differently]
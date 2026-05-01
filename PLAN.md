# Subagent Live Progress Implementation Plan
## Spec v1.3.0 — TUI Widget, Partial Results, Cancellation Notifications, Streaming Updates

**Based on spec commit:** `35c948c` - `specs: add subagent live progress for forked jobs`

---

## Overview

This plan implements the subagent live progress system defined in spec v1.3.0 (AIAGT). The system provides real-time visibility into running forked subagent jobs through three surfaces: (1) a TUI status widget displayed above the editor, (2) enhanced `subagent_status` output with a Progress section for running jobs, and (3) `subagent_wait` streaming progress updates. It also adds cancellation notifications via steer messages, improved summary extraction (skip short text blocks), and text truncation rules for widget/notification display.

The core architectural idea: the fork execution path already has per-message streaming via `onMessage` callbacks. We need to wire these callbacks into (a) an in-memory live-progress store on each `AsyncJob`, (b) a debounced widget renderer, (c) a cancellation notification emitter, and (d) the status/wait tool outputs.

---

## Spec Delta to Implement

1. **TUI status widget** (`subagent-jobs`): displayed above the editor while any forked job is running, with header line, two-line progress for running jobs (last text snippet + last tool call from completed messages), one-line summary for completed/failed jobs, and 5s dismiss delay after last job finishes.
2. **Partial result updates**: `AsyncJob.result` updated on every `message_end` and `tool_result_end` event from the subagent process, enabling live progress visibility.
3. **Cancellation notifications**: Delivered as steer messages with partial usage and trace (last completed text + last tool call). Only completed messages shown — no partial/mid-stream data.
4. **`subagent_status` Progress section**: For running jobs, includes turns so far, usage so far, last text snippet, and last tool call from completed messages only.
5. **`subagent_wait` streaming updates**: Uses `onUpdate` to stream progress with two-line format (last text snippet + last tool call), refreshed on each `message_end`.
6. **Summary extraction**: Scan backward through assistant display items; select first text block with length ≥ `SUBAGENT_SUMMARY_MIN_LENGTH` (50 chars). Fallback to last text block regardless of length.
7. **Text truncation rules**: First newline boundary, then terminal-width clip.
8. **Widget debounce** (`SUBAGENT_WIDGET_DEBOUNCE_MS` = 1000ms) with instant state-transition renders.
9. **Widget dismiss delay** (`SUBAGENT_WIDGET_DISMISS_DELAY_MS` = 5000ms) after last job finishes.
10. **`subagent_fork` promptGuidelines**: Must mention that a status widget is shown while jobs are running.
11. **Status widget**: display-only, no keyboard input. Cancelling goes through `subagent_cancel`.
12. **Error handling AIAGT-014**: Widget render failure → log error, skip re-render, widget may be stale. Continue on next successful render.

---

## Current Code State

### What is already correct

- **Job lifecycle**: `JobManager` already supports `createJob`, `completeJob`, `failJob`, `cancelJob`, `cancelAll`. Job state is serialized/deserialized across sessions.
- **Fork execution**: `subagent_fork` spawns subagent processes and handles completion via `resultPromise.then()`.
- **Completion notifications**: `emitCompletionNotification` already delivers steer messages for completed/failed jobs.
- **Running result update framework**: `spawnSubagentProcess` already accepts an `onMessage` callback and calls it on every `message_end` and `tool_result_end` event. The callback is already wired for `subagent_run` (parallel and chain modes) but NOT for `subagent_fork`.
- **Display items**: `getDisplayItems()` and `formatToolCall()` already extract text blocks and tool calls from messages.
- **`getFinalOutput()`**: Already exists but needs enhancement to support summary extraction threshold.
- **Renderers**: `renderJobStatusLine` and `formatUsageStats` exist for text-based status output.
- **Routing**: `buildToolDescription` already appends routing tables to tool descriptions.

### What is currently out of spec / out of alignment

1. **`AsyncJob.result` is only set on completion**: The `result` field is `null` while the job is running. Spec requires it to be updated on every `message_end`/`tool_result_end` event. Currently `result` is only assigned in `completeJob()` and `failJob()`.
2. **No TUI status widget**: There is no `ctx.ui.setWidget` call anywhere. The extension doesn't render any widget above the editor.
3. **No cancellation notifications**: `cancelJob()` and `cancelAll()` kill the process and set status to "cancelled" but don't emit steer messages.
4. **`subagent_status` has no Progress section**: For running jobs, status output only shows `status`, `name`, `task`, `elapsed`. No turns, usage progression, last text snippet, or last tool call.
5. **`subagent_wait` has no streaming**: The current implementation polls every 500ms in a loop but doesn't use `onUpdate` to stream progress.
6. **Summary extraction is simple**: `emitCompletionNotification` takes the last text block. It doesn't skip short text blocks (< 50 chars) or scan backward.
7. **No text truncation rules**: Widget and notification text can contain newlines and exceed terminal width without truncation.
8. **No widget constants**: `SUBAGENT_WIDGET_DEBOUNCE_MS`, `SUBAGENT_WIDGET_DISMISS_DELAY_MS`, and `SUBAGENT_SUMMARY_MIN_LENGTH` don't exist.
9. **`subagent_fork` promptGuidelines** don't mention the status widget.
10. **No debounce mechanism**: Widget updates would fire on every message event without throttling.

### Important implementation constraints

- The `setWidget` API accepts `string[]` or a `(tui, theme) => Component` factory. For the subagent widget, the string-array form is simpler and sufficient — no interactive keyboard handling needed.
- The widget must handle the case where `terminal.columns` is 0 or undefined (non-interactive/headless mode) gracefully — fall back to a default width.
- The `onMessage` callback in `spawnSubagentProcess` is already wired for subagent_run; for subagent_fork we need to add it and connect it to both the job's partial result AND the widget updater.
- The `pi.sendMessage` API with `{ deliverAs: "steer", triggerTurn: true }` is already used for completion notifications. Cancellation notifications must use the same delivery path.

---

## Intended Implementation Shape

The simplest acceptable implementation:

1. **Add three constants** (`SUBAGENT_SUMMARY_MIN_LENGTH`, `SUBAGENT_WIDGET_DEBOUNCE_MS`, `SUBAGENT_WIDGET_DISMISS_DELAY_MS`) to a new `constants.ts` or at the top of `index.ts`.

2. **Extend `AsyncJob`** with a partial `result` that gets updated on every message event. This replaces the `null` during running state with a growing `SingleResult`. No new data structure — just update `.result` in-place as messages stream in.

3. **Add `extractSummary()` function** that scans backward through display items, skipping text blocks under 50 chars, falling back to the last text block. This replaces the simple "last text block" extraction in `emitCompletionNotification`.

4. **Add `truncateForWidget()` function** that applies newline-boundary truncation, then terminal-width clip. Used by widget and notification rendering.

5. **Add widget rendering** via `ctx.ui.setWidget("subagent-jobs", lines, { placement: "aboveEditor" })`. The widget reads jobs from `JobManager`, formats header + running lines + completed lines, and returns an array of strings. Debounce via `setTimeout`/`clearTimeout`. State transitions bypass debounce.

6. **Add cancellation notification** as a new `emitCancellationNotification()` function that sends a steer message with partial usage and trace. Called from `cancelJob()` and `cancelAll()`.

7. **Enhance `subagent_status`** to include a Progress section for running jobs, reading from the partial `result`.

8. **Enhance `subagent_wait`** to use the `onUpdate` callback for streaming progress with two-line format.

9. **Wire fork `onMessage`** to update `job.result` incrementally, trigger widget re-render, and update `subagent_wait` streaming.

10. **Update `subagent_fork` promptGuidelines** to mention the status widget.

---

## Red/Green TDD Slices

### Slice 1: Constants and Summary Extraction

#### Red — Write tests first, no implementation code yet

Create test file: `tests/summary-extraction.test.ts`

- Test: `extractSummary(messages)` returns the last assistant text block with length ≥ 50 chars
- Test: `extractSummary(messages)` skips text blocks under 50 chars and returns the first substantive one found scanning backward
- Test: `extractSummary(messages)` falls back to the last text block if none meet the 50-char threshold
- Test: `extractSummary(messages)` returns empty string when there are no assistant messages
- Test: `truncateForWidget(text, maxWidth)` truncates at first newline boundary
- Test: `truncateForWidget(text, maxWidth)` clips to maxWidth after prefix is subtracted
- Test: `truncateForWidget(text, maxWidth)` handles text with no newlines
- Test: `truncateForWidget(text, maxWidth)` handles empty string

Run `npx vitest run tests/summary-extraction.test.ts`. All tests must fail (function doesn't exist yet).

**Hard gate**: Do not proceed to Green until the test file is created, tests written, and observed failing.

#### Green — Make the red tests pass, minimum change only

Create source file: `pi/extensions/subagent/summary.ts`

- Export `SUBAGENT_SUMMARY_MIN_LENGTH = 50`
- Export `SUBAGENT_WIDGET_DEBOUNCE_MS = 1000`
- Export `SUBAGENT_WIDGET_DISMISS_DELAY_MS = 5000`
- Export `extractSummary(messages: Message[]): string` — scans backward through assistant display items, returns first text block ≥ 50 chars, fallback to last text block
- Export `truncateForWidget(text: string, maxWidth: number): string` — truncate at first newline, then clip to maxWidth

Run `npx vitest run tests/summary-extraction.test.ts`. All tests must pass.

#### Refactor — Clean up while keeping tests green

- Consider if `extractSummary` should live alongside `getFinalOutput` and `getDisplayItems` in `renderers.ts`. If so, move it there and update imports. Keep constants in `summary.ts` (or rename to `live-progress.ts`).
- Keep `truncateForWidget` in the same module as it's closely related to the widget display logic.

Run `npx vitest run` to confirm all existing + new tests pass.

---

### Slice 2: Partial Result Updates on Running Jobs

#### Red — Write tests first

Create test additions in: `tests/job-manager.test.ts` (extend existing)

- Test: Creating a job leaves `result` as null (current behavior, verifies baseline)
- Test: `updatePartialResult(jobId, partialResult)` updates `result` on a running job
- Test: `updatePartialResult(jobId, partialResult)` does not update a completed or failed job (frozen state)
- Test: `updatePartialResult` increments usage stats correctly across multiple calls

Run `npx vitest run tests/job-manager.test.ts`. Tests for `updatePartialResult` must fail (method doesn't exist yet).

#### Green — Make the red tests pass

Modify: `pi/extensions/subagent/job-manager.ts`

- Add `updatePartialResult(jobId: string, partial: SingleResult): void` method to `JobManager`
- It only updates `result` if `job.status === "running"`
- It merges usage (additive) and appends messages, replacing previous partial data
- The method is the sole way to update `result` on a running job — `completeJob` and `failJob` will call it internally or just set final result directly

Run `npx vitest run tests/job-manager.test.ts`. All tests must pass.

#### Refactor — Clean up while keeping tests green

- Review `completeJob` and `failJob` — they currently set `job.result` directly. Ensure `updatePartialResult` doesn't conflict with the final result setting. Since the job status transitions from "running" → "completed"/"failed", `updatePartialResult` will stop writing once status changes, which is correct.

Run `npx vitest run` to confirm all tests pass.

---

### Slice 3: Cancellation Notifications

#### Red — Write tests first

Create test file: `tests/cancellation-notification.test.ts`

- Test: Cancellation notification includes ⊘ icon, job name, elapsed time, partial usage stats
- Test: Cancellation notification includes last completed assistant text and last completed tool call
- Test: Cancellation notification excludes partial/mid-stream data (only completed messages)
- Test: `emitCancellationNotification(pi, job)` sends message via `pi.sendMessage` with `deliverAs: "steer", triggerTurn: true`
- Test: `emitCancellationNotification` uses `extractSummary` for content selection (≥ 50 chars)

Run `npx vitest run tests/cancellation-notification.test.ts`. All must fail.

#### Green — Make the red tests pass

Modify: `pi/extensions/subagent/index.ts`

- Add `emitCancellationNotification(pi: ExtensionAPI, job: AsyncJob): void` function
- It reads `job.result` (which was partially updated via `updatePartialResult` before cancellation)
- It extracts display items only from completed assistant messages
- It sends a steer message with: ⊘ icon, job name, elapsed time, partial usage summary, last completed text, last completed tool call
- Wire `cancelJob()` to call `emitCancellationNotification(pi, job)` after setting status to "cancelled"
- Wire `cancelAll()` to call `emitCancellationNotification` for each cancelled job

Since `cancelJob` and `cancelAll` are in `JobManager` (which doesn't have access to `pi`), we need to:
- Add an `onCancel` callback option to `JobManager` that takes `(job: AsyncJob) => void`
- Register this callback in the extension entry point
- `cancelJob` calls `onCancel(job)` after setting status (with a copy of job data before nullifying process)

Run `npx vitest run tests/cancellation-notification.test.ts`. All tests must pass.

#### Refactor

- Verify that the completion notification path (`emitCompletionNotification`) still works and doesn't conflict. In the fork execution path, `completeJob`/`failJob` are already called before `emitCompletionNotification`. The cancellation notification is called from `cancelJob`/`cancelAll`. These paths are mutually exclusive (a job can't be both completed and cancelled), so no conflict.

Run `npx vitest run` to confirm all tests pass.

---

### Slice 4: TUI Status Widget

#### Red — Write tests first

Create test file: `tests/widget.test.ts`

- Test: `renderWidgetContent(jobs, terminalWidth)` returns array of strings with header line showing done/total/failed/running counts
- Test: `renderWidgetContent` shows two-line format for running jobs: `⏳ name (elapsed) usage X turns` + `  "last text snippet" → last tool call`
- Test: `renderWidgetContent` shows one-line format for completed jobs: `✓ name (elapsed) usage "truncated result"`
- Test: `renderWidgetContent` includes 5s dismiss delay logic (handled by caller, not function — verify widget is removed after dismiss delay)
- Test: Widget renders correctly when no jobs are running (empty/undefined — clears widget)
- Test: Widget handle error during rendering gracefully (try/catch, log error, return empty — AIAGT-014)
- Test: Text truncation applies to widget content (newlines removed, terminal width respected)

Run `npx vitest run tests/widget.test.ts`. All must fail.

#### Green — Make the red tests pass

Create source file: `pi/extensions/subagent/widget.ts`

- Export `renderWidgetContent(jobs: AsyncJob[], terminalWidth?: number): string[] | undefined`
  - Returns `undefined` when no running/completed-pending-dismiss jobs exist (signals widget removal)
  - Returns string array with header line and per-job lines
  - Uses `extractSummary` for text snippet selection
  - Uses `truncateForWidget` for line clipping
  - Wraps in try/catch; on error, logs to console.warn and returns `undefined`

Modify: `pi/extensions/subagent/index.ts`

- Add widget management logic in the extension entry point:
  - `let widgetDebounceTimer: ReturnType<typeof setTimeout> | null = null`
  - `let widgetDismissTimer: ReturnType<typeof setTimeout> | null = null`
  - `function updateWidget(): void` — clears debounce timer, renders content, calls `ctx.ui.setWidget("subagent-jobs", content, { placement: "aboveEditor" })`
  - `function scheduleWidgetUpdate(): void` — debounced version (1000ms) that calls `updateWidget` after the delay, EXCEPT on state transitions (completion/failure/cancellation) which call `updateWidget()` immediately
  - `function scheduleWidgetDismiss(): void` — sets a timer for 5000ms after last job finishes, then calls `ctx.ui.setWidget("subagent-jobs", undefined)` to remove the widget and clears the dismiss timer
  - Call `scheduleWidgetUpdate()` on every `onMessage` callback from fork processes
  - Call `updateWidget()` immediately on state transitions (completion, failure, cancellation)
  - On `session_shutdown`, clear widget timers and remove widget

Run `npx vitest run tests/widget.test.ts`. All tests must pass.

#### Refactor

- The widget rendering is pure (takes jobs array, returns string array). The side effects (timer management, `setWidget` calls) are in `index.ts`. Keep this separation clean.
- Consider if `scheduleWidgetUpdate`, `updateWidget`, `scheduleWidgetDismiss` should be in a small `WidgetManager` class for testability. If the functions are small and the debounce/delay logic is clear, pure functions may suffice.

Run `nix vitest run` to confirm all tests pass.

---

### Slice 5: Enhanced subagent_status — Progress Section

#### Red — Write tests first

Create test additions in: `tests/subagent-status.test.ts` (extend existing)

- Test: `subagent_status` for a running job includes a "Progress" section
- Test: Progress section shows turns so far, usage so far, last text snippet, last tool call
- Test: Progress section only shows completed messages (not mid-stream data)
- Test: Progress section uses `extractSummary` for text snippet (skips < 50 char blocks)

Run `npx vitest run tests/subagent-status.test.ts`. Progress section tests must fail.

#### Green — Make the red tests pass

Modify: `pi/extensions/subagent/index.ts` — `subagent_status` tool's execute handler

- When `job.status === "running"` and `job.result` is non-null (partial result from live updates):
  - Add a `**Progress:**` section after the existing elapsed time line
  - Show turns so far from `job.result.usage.turns`
  - Show usage stats from `job.result.usage`
  - Show last text snippet via `extractSummary(job.result.messages)` (truncated with `truncateForWidget`)
  - Show last tool call from `getDisplayItems(job.result.messages).filter(i => i.type === "toolCall").pop()`
- When `job.result` is null (legacy/edge case), show "No progress data available yet"

Run `npx vitest run tests/subagent-status.test.ts`. All tests must pass.

#### Refactor

- Verify that the progress section rendering doesn't duplicate the existing status output format. It should be an additional section, not a replacement.

Run `npx vitest run` to confirm all tests pass.

---

### Slice 6: Enhanced subagent_wait — Streaming Progress

#### Red — Write tests first

Create test additions in: `tests/subagent-wait.test.ts` (extend existing)

- Test: `subagent_wait` calls `onUpdate` with progress content on each partial result update
- Test: Progress update format includes two-line trace (last text snippet + last tool call)
- Test: `subagent_wait` returns final result when job completes
- Test: `subagent_wait` respects timeout

Run `npx vitest run tests/subagent-wait.test.ts`. Streaming tests must fail.

#### Green — Make the red tests pass

Modify: `pi/extensions/subagent/index.ts` — `subagent_wait` tool's execute handler

- Currently, `subagent_wait` polls every 500ms in a loop checking job status.
- Replace the polling loop with an approach that:
  1. Registers an `onProgress` callback with the job (via `JobManager`)
  2. On each `updatePartialResult` call, triggers the `onUpdate` callback for `subagent_wait`
  3. When the job transitions to completed/failed, resolves the `resultPromise`
- However, since `onUpdate` is a tool execution parameter (only available during `execute`), we can use a `Promise`-based approach:
  - Keep the polling loop (500ms) as the foundation since `onUpdate` needs to be called from within the tool
  - On each poll iteration where the job is still running and has a partial result, call `onUpdate` with the two-line progress format
  - When the job completes, resolve normally

The two-line progress format:
```
⏳ {name} ({elapsed}) {usage} {turns} turns
  "{last text snippet}"  → {last tool call}
```

Using `extractSummary` for the text snippet and getting the last tool call from `getDisplayItems`.

Run `npx vitest run tests/subagent-wait.test.ts`. All tests must pass.

#### Refactor

- Ensure the polling interval is reasonable. The original 500ms is fine for status checks. The `onUpdate` calls happen within the existing poll loop when partial results are available.
- Make sure `onUpdate` is called with `content` and `details` matching the existing `subagent_wait` result format.

Run `npx vitest run` to confirm all tests pass.

---

### Slice 7: Fork onMessage Wiring and Widget Integration

#### Red — Write tests first

Create test additions in: `tests/subagent-fork.test.ts` (extend existing)

- Test: Fork creates job with `result` initially null, then partial result is updated on first `message_end`
- Test: Widget update is triggered on each partial result (verify `setWidget` was called)
- Test: Widget is removed 5000ms after last job completes (dismiss delay)
- Test: Widget update is debounced (multiple rapid updates result in only one `setWidget` call within 1000ms)
- Test: State transition (completion) triggers immediate widget update (bypasses debounce)
- Test: Cancellation triggers immediate widget update and steer notification

Run `npx vitest run tests/subagent-fork.test.ts`. Integration tests must fail.

#### Green — Make the red tests pass

Modify: `pi/extensions/subagent/index.ts` — `subagent_fork` tool's execute handler

- Wire the `onMessage` callback from `spawnSubagentProcess` to:
  1. Call `jobMgr.updatePartialResult(job.id, partialResult)` on each `message_end`/`tool_result_end`
  2. Call `scheduleWidgetUpdate()` to trigger debounced widget refresh
- On completion (in the `resultPromise.then()` handler):
  1. Call `completeJob`/`failJob` (already done)
  2. Call `persist()` (already done)
  3. Call `updateWidget()` immediately (state transition — bypass debounce)
  4. Call `emitCompletionNotification` (already done)
  5. Schedule widget dismiss if no more running jobs
- On cancellation (in `cancelJob`/`cancelAll` handlers):
  1. Call `emitCancellationNotification` (new)
  2. Call `updateWidget()` immediately (state transition)
- On error (in `resultPromise.catch()` handler):
  1. Call `failJob` (already done)
  2. Call `updateWidget()` immediately
  3. Call `emitCompletionNotification` (already done)

Modify job creation in `JobManager`:
- Ensure `cancelJob` and `cancelAll` call the registered `onCancel` callback so that `emitCancellationNotification` is triggered

Also update `subagent_fork` promptGuidelines to mention the status widget:
```typescript
promptGuidelines: [
  // ... existing guidelines ...
  "The `subagent_fork` `promptGuidelines` MUST mention that a status widget is shown while jobs are running.",
]
```

Add: "A TUI status widget is displayed above the editor while jobs are running, showing live progress. You'll also receive a completion notification when each job finishes."

Run `npx vitest run tests/subagent-fork.test.ts`. All tests must pass.

#### Refactor

- Review the widget lifecycle management: creation on first fork, updates on events, dismiss after all jobs finish. Ensure cleanup on `session_shutdown`.
- Review the `cancelJob` path: it currently sets status to "cancelled" directly. Ensure the `onCancel` callback is called AFTER the partial result is captured but BEFORE or concurrent with the process kill.

Run `npx vitest run` to confirm all tests pass.

---

### Slice 8: Completion Notification Summary Enhancement

#### Red — Write tests first

Create test additions in: `tests/notification-renderer.test.ts` (extend existing)

- Test: Completion notification uses `extractSummary` for content (skips text blocks < 50 chars)
- Test: Completion notification truncates summary text at first newline then clips to terminal width
- Test: When all assistant text blocks are < 50 chars, fallback to last text block

Run `npx vitest run tests/notification-renderer.test.ts`. New tests must fail.

#### Green — Make the red tests pass

Modify: `pi/extensions/subagent/index.ts` — `emitCompletionNotification`

- Replace the simple loop that finds "last text block" with a call to `extractSummary(job.result.messages)`
- Apply `truncateForWidget` to the summary text with appropriate max width
- Ensure the notification format matches the spec: one-line for completed jobs with usage and truncated result

Run `npx vitest run tests/notification-renderer.test.ts`. All tests must pass.

#### Refactor

- Verify that `emitCancellationNotification` (from Slice 3) and `emitCompletionNotification` use consistent formatting. They share similar structure — extract a helper if useful, but keep them separate since cancellation has different content requirements (partial usage, partial trace).

Run `npx vitest run` to confirm all tests pass.

---

## Verification

### Local verification sequence

1. Run `npx vitest run tests/summary-extraction.test.ts` — new summary + truncation tests
2. Run `npx vitest run tests/job-manager.test.ts` — partial result update tests
3. Run `npx vitest run tests/cancellation-notification.test.ts` — cancellation steer message tests
4. Run `npx vitest run tests/widget.test.ts` — widget rendering tests
5. Run `npx vitest run tests/subagent-status.test.ts` — progress section tests
6. Run `npx vitest run tests/subagent-wait.test.ts` — streaming progress tests
7. Run `npx vitest run tests/subagent-fork.test.ts` — fork integration tests
8. Run `npx vitest run tests/notification-renderer.test.ts` — enhanced notification tests
9. Run `npx vitest run` — full test suite
10. Run `npx tsc --noEmit` — TypeScript type checking

### Subagent verification passes

#### Test verifier pass 1

Use `test-quality-verifier` on:
- `tests/summary-extraction.test.ts`
- `tests/widget.test.ts`
- `tests/cancellation-notification.test.ts`

Prompt focus:
`Review the new test files for the subagent live progress feature. Identify weak assertions — tests that would pass even if the implementation was wrong (e.g. testing that a function returns "some string" without checking specific content, or testing only happy paths without edge cases). Check that extractSummary tests cover: all blocks under threshold, mixed blocks, empty messages, single block under threshold, single block over threshold. Check widget tests cover: empty jobs, all running, all completed, mixed, terminal width clipping, newline truncation.`

#### Pre-mortem pass

Use a default subagent for pre-mortem review.

Prompt focus:
`Perform a pre-mortem on the subagent live progress implementation. Assume the code passed all tests but still ships a bad experience. Find the most likely failure modes: (1) race conditions between message events and widget updates, (2) memory leaks from timers that aren't cleaned up on session_shutdown, (3) widget showing stale data after rapid job creation/completion, (4) cancellation notification arriving after completion notification for the same job, (5) terminal width being 0 or unavailable in headless mode causing NaN or infinite values. The pre-mortem should produce risks, not a rewrite plan.`

---

## Acceptance Criteria

1. A TUI status widget (`subagent-jobs`) is displayed above the editor while any forked job is running, showing header line + two-line progress per running job + one-line summary per completed/failed job.
2. Widget dismisses 5000ms (`SUBAGENT_WIDGET_DISMISS_DELAY_MS`) after the last running job finishes.
3. Widget updates are debounced to 1000ms (`SUBAGENT_WIDGET_DEBOUNCE_MS`) minimum, with instant re-render on state transitions (completion, failure, cancellation).
4. `AsyncJob.result` is updated on every `message_end` and `tool_result_end` event, enabling live progress for running jobs.
5. Cancellation notifications are delivered via steer messages with ⊘ icon, job name, elapsed time, partial usage stats, last completed text, and last completed tool call. No partial/mid-stream data.
6. `subagent_status` for a running job includes a "Progress" section showing turns, usage, last text snippet, and last tool call.
7. `subagent_wait` streams progress updates using two-line format (last text snippet + last tool call), refreshed on each `message_end`.
8. Summary extraction scans backward through assistant display items, selecting the first text block ≥ 50 chars (`SUBAGENT_SUMMARY_MIN_LENGTH`), falling back to the last text block.
9. Text truncation in widget and notifications truncates at first newline boundary, then clips to terminal width.
10. Widget render failures are caught, logged, and skipped — not thrown (AIAGT-014).
11. The `subagent_fork` promptGuidelines mention the status widget.
12. Widget is display-only; cancelling jobs goes through `subagent_cancel` only.
13. All quality gates pass (vitest, TypeScript type checking).
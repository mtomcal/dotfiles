# Slice 4: Index.ts — Tools Display in `subagent_status`, `subagent_results`, `subagent_wait`, `subagent_run`, `subagent_fork`

## Context

**Spec references**: AIAGT v1.4.0 rules 21, 24b, 24c, 24d, 24h, 24i, 27

**Display surfaces this slice covers:**
- **24b** `subagent_status` single job: `**Tools:** read, grep` line after `**Task:**` when tools defined
- **24c** `subagent_results`: `**Tools:** read, grep` line after `**Task:**` when tools defined
- **24d** `subagent_wait` progress: bracket after name on progress line, same format as widget
- **24h** `subagent_run` text output: parallel/chain headings `## name [tool1,tool2] (completed)`
- **24i** `subagent_fork` response text: `**name** [tool1,tool2] — task (running)`

**Rule 27**: `tools` on `SingleResult` set in `spawnSubagentProcess()` alongside `provider`, `model`, `thinking`, from resolved `SubagentConfig`. `tools` on `AsyncJob` set after job creation via `job.tools = config.tools`, before spawning the process.

**Current code state**:
- `spawnSubagentProcess()` sets `provider`, `model`, `thinking`, `step` on `currentResult` but NOT `tools`
- `subagent_status` single job output has `**Task:**` but no `**Tools:**` line
- `subagent_results` has `**Task:**` but no `**Tools:**` line
- `subagent_wait` progress line shows `⏳ name (elapsed)` but no tools bracket
- `subagent_run` parallel output: `## name (completed)` — no tools bracket
- `subagent_fork` response: `**name** — task (running)` — no tools bracket
- `renderCall` for `subagent_run` shows `(provider/model)` but no tools bracket
- `renderCall` for `subagent_fork` shows name but no tools bracket

**Dependency**: Slices 1 (data structures) and 2 (formatting utilities)

## Red — Write Tests First

Test file: `tests/tools-index-surfaces.test.ts`

**spawnSubagentProcess tests:**
1. `SingleResult` from spawn includes `tools: ["read","grep"]` when config has tools
2. `SingleResult` from spawn includes `tools: undefined` when config has no tools

**subagent_status tests:**
3. Single job with tools: output includes `**Tools:** read, grep` after `**Task:**`
4. Single job without tools: output does NOT include `**Tools:**`
5. List all jobs: each line via `renderJobStatusLine` includes bracket when that job has tools

**subagent_results tests:**
6. Completed job with tools: output includes `**Tools:** read, grep` after `**Task:**`
7. Completed job without tools: output does NOT include `**Tools:**`

**subagent_wait tests:**
8. Progress update includes `[read,grep]` bracket after name when tools defined
9. Progress update has no bracket when tools undefined

**subagent_run tests (parallel/chain headings):**
10. Parallel: heading shows `## scout [read,grep] (completed)` when tools defined
11. Parallel: heading shows `## implementer (completed)` when tools undefined
12. Chain: same pattern for step headings

**subagent_fork tests:**
13. Response line shows `**scout** [read,grep] — task (running)` when tools defined
14. Response line shows `**implementer** — task (running)` when tools undefined

**renderCall tests:**
15. `subagent_run` renderCall: single mode shows `(provider/model) [read,grep]` when tools specified
16. `subagent_run` renderCall: parallel/chain items show bracket per task
17. `subagent_fork` renderCall: shows bracket per task item

Run: `npx vitest run tests/tools-index-surfaces.test.ts`

**Hard gate: Do not proceed to Green until tests are created and observed to fail.**

## Green — Make Tests Pass

### spawnSubagentProcess changes:
1. After `const currentResult: SingleResult = { ... }` where `provider`, `model`, `thinking`, `step` are set, add `tools: config.tools`

### AsyncJob.tools setting (rule 27):
2. In `subagent_fork` execute, after `job = jobMgr.createJob(...)`, add `job.tools = t.config.tools;`
3. In `subagent_run` — not applicable (synchronous, no AsyncJob)

### subagent_status changes:
4. Single job output: after `**Task:** ${job.task}`, add `formatToolsLabel(job.tools ?? job.result?.tools)` on a new line when defined

### subagent_results changes:
5. After `**Task:** ${job.task}`, add `formatToolsLabel(job.result.tools)` on a new line when defined

### subagent_wait changes:
6. Progress line: after name, insert `formatToolsBracket(current.tools ?? current.result?.tools)` — match widget format

### subagent_run changes (parallel/chain output text):
7. Parallel headings: `## ${r.name} ${formatToolsBracket(r.tools)} (${r.exitCode === 0 ? "completed" : "failed"})`
8. Chain doesn't produce per-step headings in text output (it returns final output only), but if it did: same pattern

### subagent_fork changes:
9. spawnedJobs.push: include `tools` in the per-job detail object
10. jobLines: `**${j.name}** ${formatToolsBracket(j.tools)} — ${j.task} (${j.status})`

### renderCall changes:
11. `subagent_run` single mode: after model parentheses, add `formatToolsBracket(parseTools(args.tools))` — but args.tools is a comma-separated string at this point. Resolve it: `args.tools ? parseTools(args.tools) : undefined`
12. `subagent_run` parallel/chain: per-item, `formatToolsBracket(parseTools(step.tools))`
13. `subagent_fork` renderCall: same per-item pattern

### serializeJobForDetails changes:
14. Include `tools` in the serialized detail object

Constraint: Do NOT change notification functions (`emitCompletionNotification`, `emitCancellationNotification`) — those are handled in slice 5.

## Refactor — Clean Up While Green

- Ensure `parseTools` is used consistently to convert string `tools` from args to `string[]`
- Verify that `job.tools` is set exactly once (at job creation in fork) and not mutated later
- Check that `subagent_run` synchronous results also get `tools` set via `spawnSubagentProcess`

## Progress

- [x] **RED** — Create test file `tests/tools-index-surfaces.test.ts`, write all test assertions
- [x] **RED** — Run `npx vitest run tests/tools-index-surfaces.test.ts`, observe failures
- [x] **GREEN** — Set `tools: config.tools` in `spawnSubagentProcess()` `currentResult`
- [x] **GREEN** — Set `job.tools = config.tools` after `jobMgr.createJob()` in fork
- [x] **GREEN** — Add `**Tools:**` line in `subagent_status` and `subagent_results` outputs
- [x] **GREEN** — Add bracket in `subagent_wait` progress line
- [x] **GREEN** — Add bracket in `subagent_run` parallel/chain headings
- [x] **GREEN** — Add bracket in `subagent_fork` response lines and renderCall
- [x] **GREEN** — Update `renderCall` for `subagent_run` and `subagent_fork` to show tools bracket
- [x] **GREEN** — Run `npx vitest run tests/tools-index-surfaces.test.ts`, observe all pass
- [x] **GREEN** — Run `npx vitest run`, observe existing tests still pass
- [x] **REFACTOR** — Verify consistent tools resolution via `parseTools` in renderCall
- [x] **REFACTOR** — Run `npx vitest run`, confirm still green

## Review

✅ **PASS** — Slice 4 review complete. All implementation items verified against the slice brief:


- **spawnSubagentProcess**: `tools: config.tools` set on `currentResult` (line ~136)

- **AsyncJob.tools**: `job.tools = t.config.tools` set after `createJob()` in fork execute (line ~375)

- **subagent_status**: `formatToolsLabel(job.tools ?? job.result?.tools)` line after Task (line ~616)

- **subagent_results**: `formatToolsLabel(job.result.tools ?? job.tools)` line after Task (line ~666)

- **subagent_wait**: `formatToolsBracket(current.tools ?? current.result?.tools)` on progress line (line ~737)

- **subagent_run parallel**: `formatToolsBracket(r.tools)` in `## name` headings (line ~478)

- **subagent_fork**: `tools` in spawnedJobs detail (line ~373) and `formatToolsBracket(j.tools)` in jobLines (line ~389)

- **renderCall**: `parseTools(args.tools)` used consistently in subagent_run single/parallel/chain and subagent_fork

- **serializeJobForDetails**: `tools: job.tools ?? job.result?.tools` included (line ~298)

- **Notifications**: unchanged (constraint respected — slice 5 handles those)


**Test results**: 30/30 slice tests pass, 411/411 full suite passes (27 test files). Zero regressions.

[Review agents write their verdicts here as they complete each review pass]

## Course Corrections

[Orchestrator appends here when re-delegating — what went wrong, what to try differently]
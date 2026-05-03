# Subagent Guardrails Slice Plan

## ⚠️ YOU ARE AN ORCHESTRATOR — YOU DO NOT IMPLEMENT CODE

This plan is executed by delegating work to sub-agents. Your role:

1. **Delegate implementation** to sub-agents via `subagent_run` / `subagent_fork`
2. **Delegate review** to review sub-agents (mandatory — not optional)
3. **Update manifest status** after each delegation
4. **Escalate** when sub-agents get stuck

You do NOT:
- Write, edit, or modify implementation source files
- Write, edit, or modify test files
- Run tests yourself
- Scout or explore code before delegating — the slice brief has all context inlined
- Mark a slice `done` without a passing review from a review sub-agent

If you find yourself about to write code or edit a file — STOP. Delegate the slice to an implementation sub-agent instead. Orchestrator takeover is the absolute last resort (tier 5 escalation) after all other tiers have failed.

## Mandatory Status Flow

Every slice follows this lifecycle. **No status may be skipped.**

```
not-started → in-progress → review → done
                              ↑         ↓
                          needs-fix ← (escalation)
```

**Hard gates:**
- `review` → `done` requires a **review sub-agent call** that writes ✅ PASS in the slice file. You cannot mark a slice `done` yourself after implementation.
- `needs-fix` → `review` requires a re-implementation call followed by a re-review call.
- A slice in `review` status **blocks** all downstream slices that depend on it.

```
WRONG:  implement slice → mark done → next slice
RIGHT:  implement slice → mark review → delegate review → reviewer passes → mark done → next slice
```

## Pre-flight

Before delegating any slice, confirm the baseline is clean:

- [x] `cd ~/.pi/agent/extensions/subagent && npx vitest run` — all existing tests pass
- [x] `tsc --noEmit` — typecheck passes
- [x] No unrelated changes in the working tree

Run this as a `subagent_run` with `tools: "read,bash"` if needed. Do not proceed until the baseline is green.

## Overview

Implement subagent guardrails for the Pi subagent extension — resource limits (`maxTurns`, `maxCost`, `maxTokens`, `maxTime`) that kill a subagent process when exceeded and return a partial result with `stopReason: "guardrail"`. The feature includes: types and resolution logic, config wiring, enforcement in the process spawn loop, and display updates in TUI/status/fork output.

## Context Input

The guardrails spec is at `specs/subagent-guardrails.md` in the dotfiles repo. It defines 4 thresholds, 3-level resolution (per-call → settings.json → unlimited), enforcement in `processLine` and via `setTimeout`, and display in status/widget/fork output.

## Current Code State

### What is already correct
- `subagent-config.ts` has a clean `SubagentConfig` interface and `ResolvableFields` with per-item > top-level resolution
- `job-manager.ts` has a clean `AsyncJob`/`SingleResult`/`UsageStats` structure and `cancelJob` with SIGTERM/SIGKILL pattern
- `index.ts` has `spawnSubagentProcess` with NDJSON parsing, `processLine` function, and usage accumulation
- `renderers.ts` has `formatTokens`, `formatUsageStats`, `renderJobStatusLine`, `renderSingleResult`
- `widget.ts` has `renderWidgetContent` that formats running/completed/failed/cancelled jobs
- `routing.ts` has `readRoutingTable` pattern for reading from `settings.json`
- 33 existing test files with solid coverage using Vitest

### What is currently out of alignment
- No `Guardrails` type or resolution logic
- No guardrail parameters on tool schemas (`subagent_run`, `subagent_fork`)
- No guardrail enforcement in `spawnSubagentProcess`
- No `guardrails` field on `AsyncJob` or `SubagentConfig`
- No display of guardrail progress in status/widget/fork output
- No `subagentGuardrails` section in `settings.json`

### Important implementation constraints
- Do not change the `UsageStats` interface (it's shared between `job-manager.ts` and `renderers.ts`)
- Do not change the `ItemConfig` schema structure — only add new optional fields
- Do not modify the `cancelJob`/`cancelAll` kill pattern — we extract a shared helper alongside it
- The `processLine` function is a closure inside `spawnSubagentProcess` — all guardrail checks must go there
- Both `subagent_run` and `subagent_fork` need the same 4 parameters added to their schemas and `ItemConfig`

## Intended Implementation Shape

Add a new `guardrails.ts` module with types, resolution, checking, and formatting functions. Wire guardrails into `SubagentConfig` (required field, default `{}`), `ResolvableFields` (4 new optional fields), and `AsyncJob` (optional field, runtime only). Add enforcement in `spawnSubagentProcess` via `processLine` checks after each turn and a `maxTime` setTimeout. Extract a shared `terminateProcess` helper from `cancelJob`. Update status, widget, and fork spawn output to show guardrail progress.

## Manifest

| # | Slice | File | Status | Model | Provider | Thinking | Guardrails | Review Model | Review Provider | Reviews | Dependency |
|---|-------|------|--------|-------|----------|----------|------------|--------------|-----------------|---------|-------------|
| 1 | Pure guardrails module | `slices/001-pure-guardrails.md` | ✅ done | minimax-m2.7 | ollama-cloud | medium | 20T $0.10 100K 2m | deepseek-v4-pro | ollama-cloud | test | — |
| 2 | Config and job wiring | `slices/002-config-job-wiring.md` | ✅ done | minimax-m2.7 | ollama-cloud | medium | 30T $0.30 200K 5m | deepseek-v4-pro | ollama-cloud | test, quality | 1 |
| 3 | Enforcement and process kill | `slices/003-enforcement-kill.md` | ✅ done | deepseek-v4-pro | ollama-cloud | high | 50T $1.00 500K 10m | deepseek-v4-pro | ollama-cloud | test, quality, security | 1, 2 |
| 4 | Display updates | `slices/004-display-updates.md` | ✅ done | minimax-m2.7 | ollama-cloud | medium | 30T $0.30 200K 5m | deepseek-v4-pro | ollama-cloud | test, quality | 1, 3 |

Guardrails column format: `maxTurns`T `maxCost` `maxTokens` maxTime (e.g., `20T $0.10 100K 2m`). Passed as `maxTurns`, `maxCost`, `maxTokens`, `maxTime` params to `subagent_run` / `subagent_fork`.

Status values: `not-started`, `blocked`, `in-progress`, `review`, `needs-fix`, `done`

Review pass types: **test** = brief assertions pass, no vague/weak tests; **quality** = code structure, naming, consistency, adherence to spec; **security** = no new attack surface, input validation, data exposure. Each type is a **separate** review sub-agent call — do not combine them.

## Execution Loop

Repeat until all slices are `done`:

1. **Read this manifest.** Find the next eligible action:
   - If any slice has status `review` → **delegate a review sub-agent before doing anything else.** Review is the highest priority.
   - If any slice has status `not-started` and all dependencies are `done` → delegate implementation.
   - If no slices are eligible → wait for running sub-agents or escalate `needs-fix` slices.

2. **Delegate implementation.** For each ready slice, call `subagent_run` or `subagent_fork`:
   ```
   systemPrompt: "You are an implementation agent. Follow the TDD brief in your assigned slice file exactly. Execute RED, GREEN, REFACTOR cycle. Update checkboxes as you complete each step."
   task: "Read the slice brief at plan/slices/NNN-[name].md. Execute the RED, GREEN, REFACTOR cycle. Update checkboxes as you complete each step."
   model: [from manifest]
   provider: [from manifest]
   thinking: [from manifest]
   tools: "read,write,bash,edit"
   maxTurns: [from manifest Guardrails column]
   maxCost: [from manifest Guardrails column]
   maxTokens: [from manifest Guardrails column]
   maxTime: [from manifest Guardrails column, in seconds]
   ```
   After the sub-agent completes → update manifest status to `review`.

3. **Delegate review.** **This step is mandatory. It is not optional.** Each review type is a separate sub-agent call. For a slice with `test, quality` reviews, you make two calls:
   ```
   # test review
   systemPrompt: "You are a test reviewer. Verify that the brief's test assertions pass and there are no vague or weak tests."
   task: "Review slice N at plan/slices/NNN-[name].md. Run the test suite. Verify each test assertion from the RED section passes. Check for vague assertions that would pass even if the implementation is wrong. Write your verdict with ✅ PASS or ❌ NEEDS-FIX in the Review section."
   model: deepseek-v4-pro
   provider: ollama-cloud
   thinking: high
   tools: "read,bash"
   maxTurns: 10
   maxCost: 0.10
   maxTime: 120
   ```

   # quality review (separate call)
   systemPrompt: "You are a code quality reviewer. Check code structure, naming, consistency, and adherence to the spec."
   task: "Review slice N at plan/slices/NNN-[name].md. Evaluate the implementation for code quality: naming, structure, coupling, adherence to the spec constraints. Write your verdict with ✅ PASS or ❌ NEEDS-FIX in the Review section."
   model: deepseek-v4-pro
   provider: ollama-cloud
   thinking: high
   tools: "read,bash"
   maxTurns: 10
   maxCost: 0.10
   maxTime: 120
   ```
   Review sub-agents must NOT have `write` or `edit` tools.
   After all review types pass → update manifest status to `done`.
   If any review type returns ❌ NEEDS-FIX → update manifest status to `needs-fix`, begin escalation.

4. **Process needs-fix.** Append a course correction to the slice file, re-delegate implementation, then re-review all types.

5. **When all slices are `done`**, run the verification sequence from the Verification section.

## Anti-Patterns — DO NOT DO THESE

1. **🔴 Implementing code yourself.** You are an orchestrator. You delegate. You never write code, edit files, or run tests. If you're about to write code — delegate a sub-agent instead.
2. **🔴 Skipping review.** Every slice MUST go through a review sub-agent before `done`. You cannot mark a slice `done` after implementation without a reviewer's ✅ PASS verdict. Each review type is a **separate** sub-agent call.
3. **🔴 Using scout sub-agents.** Do not spawn "scout" or "research" sub-agents to explore code before delegating. The slice brief inlines all context. The implementation sub-agent reads the slice file and then reads/writes code. Scouting is the sub-agent's job, not yours.
4. **Marking a slice done without review.** The status flow is `not-started → in-progress → review → done`. You cannot jump from `in-progress` to `done`.
5. **Giving review sub-agents write/edit tools.** Reviewers read code and run tests. They never modify source files.
6. **Combining review types into one call.** Each review type (test, quality, security) is a separate sub-agent call with a focused system prompt. Do not combine them.
7. **Omitting guardrails on sub-agent calls.** Every `subagent_run` and `subagent_fork` call must include `maxTurns`, `maxCost`, `maxTokens`, and `maxTime` from the manifest. Without guardrails, a stuck sub-agent burns resources indefinitely.

## Escalation Protocol

1. **Provider switch** — same model, different provider (e.g., ollama-cloud → openrouter)
2. **Course correction** — append guidance to slice's Course Corrections section, re-delegate same model+provider
3. **Model bump** — escalate to stronger model or higher thinking
4. **Expert consultation** — use `expert-consultation` skill
5. **Orchestrator takeover** — you implement directly (last resort only)

Never skip tiers. Try the cheap thing first.

## Turn-Count Heuristics

These are **soft heuristics** for the orchestrator to monitor progress. They are separate from **hard guardrails** (maxTurns, maxCost, maxTokens, maxTime) which kill the sub-agent automatically when exceeded.

- **Caution**: Read the slice file's Progress section. If checkboxes are being checked, let it ride. If no progress in 10 turns, course-correct.
- **Escalate**: Switch provider (tier 1). If still no progress after 15 more turns, course-correct (tier 2).
- **Guardrails** handle the hard kill: a sub-agent that exceeds its maxTurns/maxCost/maxTokens/maxTime threshold is terminated automatically. The orchestrator does not need to monitor for hard limits — only for soft "no progress" signals below the guardrail threshold.

| Model tier | Caution (check progress) | Escalate (switch to stronger model) | Hard kill (maxTurns guardrail) |
|------------|--------------------------|-------------------------------------|-------------------------------|
| routine (minimax-m2.7) | 15 turns | 20 turns | 20T |
| standard (minimax-m2.7) | 20 turns | 30 turns | 30T |
| tricky (deepseek-v4-pro) | 30 turns | 40 turns | 50T |

## Orchestration Notes

- **Serial execution**: All 4 slices are fully serial. Slice 2 depends on Slice 1, Slice 3 depends on Slices 1+2, Slice 4 depends on Slices 1+3.
- **Shared files**: Slices 2 and 3 both modify `job-manager.ts` (Slice 2 adds `guardrails` field + `terminateProcess` refactor, Slice 3 adds guardrail logic in fork `onMessage`). Slice 3 and Slice 4 both modify `index.ts` (Slice 3 adds enforcement, Slice 4 adds display formatting). Sequence these as planned — Slice 2 before 3, Slice 3 before 4.
- **Test naming**: New test file `tests/guardrails.test.ts` for Slice 1. Extend `tests/subagent-config.test.ts` for Slice 2, extend `tests/job-manager.test.ts` for Slice 2. New `tests/guardrails-enforcement.test.ts` for Slice 3. Extend `tests/rendering.test.ts` and `tests/widget.test.ts` for Slice 4.
- **Global defaults in settings.json**: Slice 2 adds `subagentGuardrails` to `~/.pi/agent/settings.json` with `{ "maxTurns": 50, "maxCost": 1.00, "maxTokens": 500000, "maxTime": 600 }`. This lives in the dotfiles repo at `pi/settings.json`.

## Acceptance Criteria

1. `npx vitest run` — all existing and new tests pass
2. `tsc --noEmit` — typecheck passes with no errors
3. Guardrail kill works: `subagent_run` with `maxTurns: 1` terminates after 1 turn and returns `stopReason: "guardrail"`
4. Guardrail resolution works: per-call params override global defaults, unset fields fall back to global defaults, all-unset means unlimited
5. Display: `subagent_status` shows guardrail progress (e.g., `18/25T $0.32/$0.50 84K/200K 2m30s/5m`) for running jobs with guardrails
6. Display: TUI widget shows compact guardrail progress line
7. Display: `subagent_fork` spawn output includes guardrail line
8. Completion notification for guardrail kills includes the guardrail reason and usage stats
9. All quality gates pass (naming, structure, coupling)

## Verification

1. Run `npx vitest run` — full suite
2. Run `cd ~/.pi/agent/extensions/subagent && npx tsc --noEmit`
3. Manual guardrail smoke test: start pi, verify `subagent_run` with `maxTurns: 1` returns `stopReason: "guardrail"` and partial result
4. Run `test-quality-verifier` pass on all new test files

## References

- `specs/subagent-guardrails.md` — the design specification
- `~/.pi/agent/extensions/subagent/subagent-config.ts` — config types and resolution
- `~/.pi/agent/extensions/subagent/job-manager.ts` — job lifecycle and types
- `~/.pi/agent/extensions/subagent/index.ts` — tool registration, spawn, enforcement
- `~/.pi/agent/extensions/subagent/renderers.ts` — display formatters
- `~/.pi/agent/extensions/subagent/widget.ts` — TUI widget rendering
- `~/.pi/agent/extensions/subagent/routing.ts` — settings.json reading pattern
- `~/.pi/agent/extensions/subagent/tests/helpers.ts` — test fixtures
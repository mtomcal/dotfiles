# Tools Display for Subagent Extension — Slice Plan

## Overview

Implement resolved tool allowlist (`tools?: string[]`) display across all subagent surfaces. When a subagent is spawned with a custom tool allowlist (e.g. `tools: "read,grep"`), the bracket `[read,grep]` appears in 9 defined rendering surfaces. When `tools` is `undefined` (all default tools), no bracket appears anywhere. This ensures users can see at a glance which tools a subagent is scoped to.

## Context Input

**Spec delta**: `ai-agent-config.md` v1.2.0 → v1.4.0 (commit e3730b3)
- Added `tools?: string[]` to `AsyncJob`, `SingleResult`, and `SerializedJob` data structures
- Added behavior rules 21–27 for tools display, storage, and truncation
- Added 3 parameters: `SUBAGENT_TOOLS_BRACKET_MAX_CHARS` (30), `SUBAGENT_TOOLS_DISPLAY_STATUS_FORMAT`, `SUBAGENT_TOOLS_DISPLAY_UNDEFINED`
- Added 12 test scenarios (TS-AIAGT-030 through TS-AIAGT-041)
- Bracket convention: `()` for model/provider/thinking config, `[]` for tool scope
- Undefined tools = all defaults = omitted from display

## Current Code State

### What is already correct
- `SubagentConfig.tools` exists as `string[] | undefined`, resolved from `ResolvableFields.tools` (comma-separated string)
- `buildSpawnArgs` correctly passes `--tools` CLI flag when tools is defined
- `parseTools` correctly splits comma-separated tool strings
- All 9 rendering surfaces already exist and function correctly for model/provider/thinking display
- Widget, renderers, status, results, fork, run, wait, and notifications all have established patterns
- Test infrastructure is solid: vitest, helpers.ts fixtures, mock extension context

### What is currently out of alignment
- `AsyncJob` has no `tools` field — tools allowlist is lost after job creation
- `SingleResult` has no `tools` field — tools allowlist is not persisted in result data
- `SerializedJob` has no `tools` field — session persistence loses tools info
- `spawnSubagentProcess` does not set `tools` on `currentResult` or `AsyncJob`
- No rendering surface shows the tools bracket — `renderCall`, `renderSingleResult`, `renderJobStatusLine`, `renderWidgetContent`, `subagent_status` text, `subagent_results` text, `subagent_wait` progress, `subagent_run` parallel/chain headings, `subagent_fork` response text
- No `formatToolsBracket` utility function exists for consistent truncation and formatting
- Notification messages (completion, cancellation) must NOT show tools

### Important implementation constraints
- Do NOT change `SubagentConfig` — it already has `tools` working correctly
- Do NOT change any existing rendering for model/provider/thinking — only ADD tools brackets
- Backward compatibility: missing `tools` field in deserialized data must be treated as `undefined` (all defaults), consistent with the spec (rule 26)
- The 30-character truncation with `+N` overflow is a fixed parameter — extract as a constant
- Notifications and widget line 2 must NOT show tools (spec rules 25a–25d)

## Intended Implementation Shape

Add a `tools?: string[]` field to `AsyncJob`, `SingleResult`, and `SerializedJob`. Thread it through `spawnSubagentProcess` and job creation. Create a shared `formatToolsBracket(tools: string[] | undefined): string` utility that returns `""` for undefined, `[t1,t2,...]` for defined (truncated at 30 chars with `+N` overflow). Create a `formatToolsLabel(tools: string[] | undefined): string` utility for markdown output (`""` for undefined, `**Tools:** t1, t2, ...` for defined with spaces for readability). Add the bracket/label to all 9 specified surfaces and verify the 4 exclusion surfaces remain clean.

## Manifest

| # | Slice | Status | Model | Provider | Thinking | Review Model | Review Provider | Reviews | Dependency |
|---|-------|--------|-------|----------|----------|--------------|-----------------|---------|-------------|
| 1 | Data structures: add `tools` field | ⏳ not-started | minimax-m2.7 | ollama-cloud | medium | deepseek-v4-pro | opencode-go | test | — |
| 2 | Formatting utilities | ⏳ not-started | minimax-m2.7 | ollama-cloud | medium | deepseek-v4-pro | opencode-go | test | 1 |
| 3 | Widget + renderers | ⏳ not-started | glm-5.1 | opencode-go | high | deepseek-v4-pro | opencode-go | test, quality | 1, 2 |
| 4 | Index.ts: status, results, wait, run, fork | ⏳ not-started | glm-5.1 | opencode-go | high | deepseek-v4-pro | opencode-go | test, quality | 1, 2 |
| 5 | Notifications exclusion + integrations | ⏳ not-started | minimax-m2.7 | ollama-cloud | medium | deepseek-v4-pro | opencode-go | test, quality, security | 3, 4 |

Status values: `not-started`, `blocked`, `in-progress`, `review`, `needs-fix`, `done`

## Orchestrator Instructions

### Execution Loop

1. Read this manifest. Identify slices whose dependencies are met and status is `not-started`.
2. For serial slices: use `subagent_run` with the model, provider, and thinking level specified.
3. Slices 1 and 2 can run in sequence (2 depends on 1). Slices 3 and 4 can potentially run in parallel after 2 completes. Slice 5 depends on 3 and 4.
4. When a sub-agent completes, delegate a review agent to evaluate the slice file.
5. If reviewer marks `done`: update manifest status to `done`.
6. If reviewer marks `needs-fix`: append course correction, re-delegate same model+provider, then escalate.
7. When all slices are `done`, run the verification sequence.

### Parallelization

- Slices 1 and 2 must be serial (2 depends on 1's type definitions).
- Slices 3 and 4 can run in parallel (both depend on 1 and 2 but not each other).
- Slice 5 must be last (depends on 3 and 4 being complete for integration testing).

### Review Policy

Each slice gets the review passes specified in its Reviews column. Review blocks downstream slices that depend on it.

## Acceptance Criteria

1. `AsyncJob.tools`, `SingleResult.tools`, and `SerializedJob.tools` are `string[] | undefined`, populated from `SubagentConfig.tools`
2. `formatToolsBracket(["read","grep"])` returns `"[read,grep]"`; `formatToolsBracket(undefined)` returns `""`
3. `formatToolsBracket` with 7 tools truncates at 30 chars: `"[read,write,bash,edit,grep,find +1]"`
4. Widget line 1 shows `[tools]` bracket after name when tools is defined; line 2 does NOT show tools
5. `subagent_status` single job shows `**Tools:** read, grep` line after `**Task:**` when tools defined
6. `subagent_results` shows `**Tools:** read, grep` line after `**Task:**` when tools defined
7. `subagent_wait` progress line shows `[tools]` bracket after name when tools defined
8. `renderCall` shows bracket after model parentheses: `(provider/model) [tools]`
9. `renderSingleResult` shows bracket on identity line in both expanded and collapsed views
10. `renderJobStatusLine` shows bracket after name: `✓ name [tools] (elapsed)`
11. `subagent_run` parallel/chain headings show `## name [tools] (completed)`
12. `subagent_fork` response shows `**name** [tools] — task (running)`
13. Completion and cancellation notifications do NOT show tools
14. Widget header line and widget line 2 do NOT show tools
15. Deserialization treats missing `tools` as `undefined` (backward compatible)
16. All existing tests continue to pass

## Verification

1. Run `npx vitest run` — full suite passes
2. All 12 spec test scenarios (TS-AIAGT-030 through TS-AIAGT-041) verified via dedicated tests
3. `test-quality-verifier` pass on all new test files
4. Manual verification: spawn subagent with `tools: "read,grep"` and confirm bracket appears in widget, status, results, and fork output; spawn without tools and confirm no bracket appears

## References

- Spec: `specs/ai-agent-config.md` v1.4.0 (commit e3730b3)
- Parameters: `specs/parameters.md` (SUBAGENT_TOOLS_BRACKET_MAX_CHARS, SUBAGENT_TOOLS_DISPLAY_STATUS_FORMAT, SUBAGENT_TOOLS_DISPLAY_UNDEFINED)
- Source: `pi/extensions/subagent/job-manager.ts` (AsyncJob, SingleResult, SerializedJob)
- Source: `pi/extensions/subagent/renderers.ts` (renderSingleResult, renderJobStatusLine, formatUsageStats)
- Source: `pi/extensions/subagent/widget.ts` (renderWidgetContent)
- Source: `pi/extensions/subagent/index.ts` (spawnSubagentProcess, tool execute/renderCall/renderResult, notifications)
- Source: `pi/extensions/subagent/subagent-config.ts` (SubagentConfig, resolveConfig, parseTools)
- Tests: `pi/extensions/subagent/tests/` (existing test patterns)
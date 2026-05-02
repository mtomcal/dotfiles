# Slice 2: Formatting Utilities — `formatToolsBracket` and `formatToolsLabel`

## Context

**Spec references**: AIAGT v1.4.0 rules 21–23, 25
- Rule 21: tools displayed as comma-separated bracket `[t1,t2,...]` when defined; omitted when undefined
- Rule 22: bracket convention uses `[]` for tool scope, `()` for model config — these are distinct visual delimiters
- Rule 23: truncation at 30 chars with `+N` overflow: `[read,write,bash,edit,grep,find +1]` (7 tools, 39 chars raw → truncated to ≤30 chars)
- Rule 25: tools must NOT appear on notifications, widget line 2, widget header

**Parameters**: 
- `SUBAGENT_TOOLS_BRACKET_MAX_CHARS = 30`
- `SUBAGENT_TOOLS_DISPLAY_STATUS_FORMAT = "**Tools:** tool1, tool2, ..."` (markdown, comma-separated with spaces)
- `SUBAGENT_TOOLS_DISPLAY_UNDEFINED = omit` (no display when undefined)

**Current code state**: No formatting utility exists for tools display. Each rendering surface would need to independently implement bracket formatting and truncation, leading to duplication and inconsistency.

**Dependency**: Slice 1 (needs `tools?: string[]` on `SingleResult` and `AsyncJob`)

## Red — Write Tests First

Test file: `tests/tools-formatting.test.ts`

Assertions:
1. `formatToolsBracket(["read", "grep"])` returns `"[read,grep]"` (no spaces in bracket)
2. `formatToolsBracket(undefined)` returns `""` (empty string, caller decides whether to append space)
3. `formatToolsBracket([])` returns `""` (empty array = omitted, same as undefined)
4. `formatToolsBracket(["read", "write", "bash", "edit", "grep", "find", "ls"])` returns `"[read,write,bash,edit,grep,find +1]"` (30 chars total, 7th tool in overflow)
5. `formatToolsBracket(["bash"])` returns `"[bash]"` (single tool)
6. `formatToolsBracket(["a", "b", "c", "d", "e"])` — verify bracket stays under 30 chars
7. Edge case: tool name that itself is long, e.g. `formatToolsBracket(["subagent_run"])` returns `"[subagent_run]"` (under 30)
8. Edge case: tool name that pushes past 30 — verify truncation works
9. `formatToolsLabel(["read", "grep"])` returns `"**Tools:** read, grep"` (markdown format with spaces)
10. `formatToolsLabel(undefined)` returns `""` (empty string)
11. `formatToolsLabel([])` returns `""` (empty array = omitted)
12. `formatToolsLabel(["read", "write", "bash"])` returns `"**Tools:** read, write, bash"` (full list, no truncation in label)
13. Constant `SUBAGENT_TOOLS_BRACKET_MAX_CHARS` is 30

Run: `npx vitest run tests/tools-formatting.test.ts`

**Hard gate: Do not proceed to Green until tests are created and observed to fail.**

## Green — Make Tests Pass

- Source file: `pi/extensions/subagent/renderers.ts` (add the utilities here, they're rendering helpers)
- Changes:
  1. Export `SUBAGENT_TOOLS_BRACKET_MAX_CHARS = 30` constant
  2. Export `formatToolsBracket(tools: string[] | undefined): string`
     - If tools is undefined or empty, return `""`
     - Build comma-separated string: tools.join(",")
     - If full bracket string `[joined]` is ≤ 30 chars, return as-is
     - Otherwise, truncate: include as many complete tool names as fit, append ` +N` where N = remaining count
  3. Export `formatToolsLabel(tools: string[] | undefined): string`
     - If tools is undefined or empty, return `""`
     - Return `**Tools:** tool1, tool2, ...` (comma-separated with spaces, NO truncation — this is for full markdown output)

Constraint: These are pure functions with no side effects. No rendering surface changes yet.

## Refactor — Clean Up While Green

- Consider renaming to match existing naming patterns (e.g. `formatUsageStats` follows a pattern)
- Verify constants are at module scope and exported alongside the functions

## Progress

- [ ] **RED** — Create test file `tests/tools-formatting.test.ts`, write all test assertions
- [ ] **RED** — Run `npx vitest run tests/tools-formatting.test.ts`, observe failures
- [ ] **GREEN** — Add `SUBAGENT_TOOLS_BRACKET_MAX_CHARS`, `formatToolsBracket`, `formatToolsLabel` to `renderers.ts`
- [ ] **GREEN** — Run `npx vitest run tests/tools-formatting.test.ts`, observe all pass
- [ ] **GREEN** — Run `npx vitest run`, observe existing tests still pass
- [ ] **REFACTOR** — Verify naming consistency with existing exports
- [ ] **REFACTOR** — Run `npx vitest run`, confirm still green

## Review

[Review agents write their verdicts here as they complete each review pass]

## Course Corrections

[Orchestrator appends here when re-delegating — what went wrong, what to try differently]
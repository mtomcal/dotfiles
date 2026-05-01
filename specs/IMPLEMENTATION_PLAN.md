# Subagent Model Routing — Implementation Plan

**Based on spec commit:** `3350e02` - `feat: add subagent model routing and run Docker sandbox as host user`

**Spec versions:** ai-agent-config v1.2.0, parameters v1.2.0, ubiquitous language v0.1.0 (updated)

---

## Overview

This plan implements the **subagent model routing** feature from spec commit 3350e02:

The subagent extension reads a `subagentModelRouting` table from Pi's `settings.json` and injects it as a markdown table into the `subagent_run` and `subagent_fork` tool descriptions. The LLM must then classify its subagent tasks into one of five intent categories (scout, planner, reviewer, implementer, specialist) and use the prescribed model/provider/thinking values. When the routing table is absent, the extension falls back to defaults with a warning.

The data in `pi/settings.json` is already in place. The gap is in the subagent extension code: it does not yet read the routing config or inject it into tool descriptions.

---

## Context Input — Spec Delta

### From ai-agent-config.md v1.2.0

1. **Subagent model routing data structure** (B5.1, rules 10-13): `subagentModelRouting` is a map in `settings.json` with keys `scout`, `planner`, `reviewer`, `implementer`, `specialist`. Each entry has `description`, `model`, `provider`, `thinking`, `rationale`.

2. **Injection into tool descriptions** (rule 10): When `subagentModelRouting` is present, the extension MUST inject a markdown table into `subagent_run` and `subagent_fork` tool descriptions with columns: category, description, model, provider, thinking, rationale.

3. **Prescriptive model selection** (rule 11): The LLM MUST select a routing category and use the prescribed values. Deviation requires explicit justification.

4. **Missing routing table fallback** (rule 12): When absent, the extension MUST log a warning and fall back to parent agent's default model/thinking. Tool descriptions MUST NOT include routing guidance.

5. **No fallback chains** (rule 13): Each category maps to exactly one combination.

6. **Pi configuration** (B4.3, rule 1): `settings.json` MUST include `subagentModelRouting`.

7. **Agent settings table**: Pi `settings.json` now lists `subagentModelRouting` as a required key.

8. **Error handling** (AIAGT-013): Missing `subagentModelRouting` → extension logs warning → falls back to defaults.

9. **Test scenarios**:
   - TS-AIAGT-025: LLM classifies task as "scout" → uses prescribed model/provider/thinking
   - TS-AIAGT-026: Missing routing table → warning logged → defaults used
   - TS-AIAGT-027: Tool descriptions include markdown routing table on session start

### From parameters.md v1.2.0

10. **15 new parameters**: `SUBAGENT_ROUTING_SCOUT_*`, `SUBAGENT_ROUTING_PLANNER_*`, `SUBAGENT_ROUTING_REVIEWER_*`, `SUBAGENT_ROUTING_IMPLEMENTER_*`, `SUBAGENT_ROUTING_SPECIALIST_*` (3 each: model, provider, thinking).

### From ubiquitous language v0.1.0

11. **6 new terms**: subagent model routing, scout, planner, reviewer, implementer, specialist.

12. **New flagged ambiguity**: "strong model" / "weak model" → use routing categories instead.

### From create-subagent-skill SKILL.md

13. **Routing category field** added to skill template: `routing category: [scout | planner | reviewer | implementer | specialist]`.

14. **Model/thinking heuristics removed** from the skill template (replaced by routing category reference).

---

## Current Code State

### What is already correct

- **`pi/settings.json`**: Contains `subagentModelRouting` with all 5 categories, each with `description`, `model`, `provider`, `thinking`, `rationale`. ✅
- **`shared/skills/create-subagent-skill/SKILL.md`**: Has `routing category` field in template. ✅
- **`specs/UBIQUITOUS_LANGUAGE.md`**: All 6 new terms added. ✅
- **`specs/parameters.md`**: All 15 routing parameters added. ✅
- **`specs/ai-agent-config.md`**: All routing data structures, behavior rules, error handling, and test scenarios updated. ✅

### What is currently out of spec / not yet implemented

1. **`pi/extensions/subagent/index.ts`**: Does NOT read `subagentModelRouting` from `settings.json`. Does NOT inject a routing table into `subagent_run` or `subagent_fork` tool descriptions. The tool descriptions are currently static strings — they need dynamic routing table injection.

2. **`pi/extensions/subagent/index.ts`**: No `session_start` handler reading `subagentModelRouting` from settings. The `session_start` handler only restores job state — it doesn't load routing config.

3. **`pi/extensions/subagent/index.ts`**: No fallback warning when `subagentModelRouting` is absent from `settings.json`.

4. **`pi/extensions/subagent/index.ts`**: No error handling for missing `subagentModelRouting` per AIAGT-013.

5. **`pi/extensions/subagent/subagent-config.ts`**: Does not reference routing categories. Model/provider/thinking in subagent configs come from the LLM's tool call parameters directly — this is correct per the spec (the LLM picks from the routing table in the tool description).

### Important implementation constraint

The subagent extension is a Pi extension written in TypeScript. It has access to the Pi `ExtensionAPI` (`ctx`) which provides settings access, but the extension must handle:

- Reading `settings.json` at session start or when building tool descriptions
- Format the routing table as markdown and inject it into tool description strings
- Gracefully handle missing config (warning + fallback)

The tool descriptions in `registerTool` are currently static strings. The spec requires them to be **dynamic** — conditionally including the routing table markdown. This means we need to either:
- Build the description string at tool registration time (if Pi supports dynamic descriptions), OR
- Use Pi's lifecycle hooks to update tool descriptions when settings change, OR
- Build the description dynamically in a way that Pi picks up

We need to investigate the Pi extension API for dynamic description injection.

---

## Intended Implementation Shape

The simplest acceptable implementation:

1. **On `session_start`**, read `subagentModelRouting` from Pi's settings via `ctx.settings` or by reading `$HOME/.pi/agent/settings.json` directly.
2. **When registering tools** (`subagent_run` and `subagent_fork`), build the description string dynamically:
   - If `subagentModelRouting` is present, append a markdown table to the tool description with columns: Category, Description, Model, Provider, Thinking, Rationale.
   - If absent, log a warning and omit the table.
3. **The routing table in the description** tells the LLM which values to use. The LLM then sets `model`, `provider`, and `thinking` explicitly in its subagent call — no code change needed in the subagent spawning logic, since model/provider/thinking are already parameters.

This is a **feature-flag configuration** approach — the extension doesn't enforce routing, it **informs** the LLM. The LLM is expected to follow the table per spec rule 11. Enforcement is social, not technical (the spec says "deviation requires explicit justification in the call").

---

## Red/Green TDD Slices

### Slice 1: Read subagentModelRouting from settings.json

#### Red

- Test file: `pi/extensions/subagent/tests/routing.test.ts`
- What the test proves: The extension can read `subagentModelRouting` from Pi's settings file and parse it into a structured routing table.
- Assertion strategy: Mock `settings.json` with known routing data; verify that the parsing function returns the correct 5 categories with correct model/provider/thinking values.
- Also test: Empty/missing `subagentModelRouting` key returns `null` (for fallback path).
- Also test: Partial routing data (only 3 of 5 categories) returns what's available (the spec says each category is "Required" but we should handle partial gracefully for forward-compat).
- Existing tests to rewrite: none

#### Green

- Source file: `pi/extensions/subagent/routing.ts` (new file)
- What to change: Create a `RoutingTable` type and a `readRoutingTable(settingsPath: string)` function that:
  1. Reads `settings.json` from the given path
  2. Parses the `subagentModelRouting` key
  3. Returns `RoutingEntry[] | null` (null if missing)
  4. Logs a warning to stderr if `subagentModelRouting` is absent
- Constraint: Minimal — just settings reading and parsing. No tool description formatting yet.
- Decisions/spec delta this satisfies: B5.1 rules 10-12, AIAGT-013

#### Refactor

- none needed

### Slice 2: Format routing table as markdown

#### Red

- Test file: `pi/extensions/subagent/tests/routing.test.ts`
- What the test proves: The `formatRoutingTable` function produces correct markdown with the right columns and rows.
- Assertion strategy: Call with a known `RoutingEntry[]` and assert exact markdown string output. Test with all 5 categories present. Test with 0 categories (empty array returns empty string or descriptive fallback).
- Existing tests to rewrite: none

#### Green

- Source file: `pi/extensions/subagent/routing.ts`
- What to change: Add `formatRoutingTable(entries: RoutingEntry[]): string` that produces a markdown table with columns: Category | Description | Model | Provider | Thinking | Rationale.
- Constraint: Pure formatting function. No side effects.
- Decisions/spec delta this satisfies: B5.1 rule 10 (injection format)

#### Refactor

- none needed

### Slice 3: Inject routing table into tool descriptions

#### Red

- Test file: `pi/extensions/subagent/tests/routing.test.ts`
- What the test proves: The `buildToolDescription` function correctly appends (or omits) the routing table markdown to the base tool description.
- Assertion strategy: Call with base description + routing table present → description includes markdown. Call with base description + null routing table → description does NOT include routing markdown and includes a note about falling back to defaults.
- Existing tests to rewrite: none

#### Green

- Source file: `pi/extensions/subagent/routing.ts`
- What to change: Add `buildToolDescription(baseDescription: string, routingTable: RoutingEntry[] | null): string` that:
  - If routing table is present and non-empty: appends `\n\n### Subagent Model Routing\n\n` + markdown table + `\n\nSelect a routing category and use the prescribed model, provider, and thinking values. Deviation requires explicit justification.`
  - If routing table is null: appends `\n\n> **Note**: No subagent model routing configured. Using default model and thinking level for all subagent calls.` (the warning is logged separately by `readRoutingTable`)
- Constraint: Don't modify the base description, only append.
- Decisions/spec delta this satisfies: B5.1 rule 10 (injection), rule 12 (fallback behavior in descriptions)

#### Refactor

- none needed

### Slice 4: Wire routing into subagent_run and subagent_fork registration

#### Red

- Test file: `pi/extensions/subagent/tests/routing.test.ts`
- What the test proves: `subagent_run` and `subagent_fork` tool descriptions include the routing table when routing is configured, and omit it when not.
- Assertion strategy: Integration-style test that checks the tool registration descriptions include the routing table markdown. This may require mocking the Pi extension API's `registerTool` call or testing through the extension's initialization function.
- Existing tests to rewrite: none

#### Green

- Source file: `pi/extensions/subagent/index.ts`
- What to change:
  1. Read `subagentModelRouting` at extension initialization (or `session_start`).
  2. Pass the routing table through to `buildToolDescription`.
  3. Use the built description in `subagent_run` and `subagent_fork` `registerTool` calls.
- Constraint: Don't change the tool execution logic — only the descriptions. The routing table is informational for the LLM.
- Decisions/spec delta this satisfies: B5.1 rules 10-12

#### Refactor

- Consider extracting description strings to constants since they're now built dynamically.

---

## Verification

### Local verification sequence

1. `cd pi/extensions/subagent && npm test` — run all unit tests
2. `cd pi/extensions/subagent && npx tsc --noEmit` — type-check
3. Manual: Verify `settings.json` contains `subagentModelRouting` with all 5 categories:
   ```bash
   cat ~/dotfiles/pi/settings.json | jq '.subagentModelRouting | keys'
   # Expected: ["implementer", "planner", "reviewer", "scout", "specialist"]
   ```

### Subagent verification passes

#### Test quality verifier pass

Use `test-quality-verifier` on:
- `pi/extensions/subagent/tests/routing.test.ts`

Prompt focus:

`Review the routing table tests for: (1) missing test cases for partial routing data, (2) assertions that would pass even if the markdown table was malformed, (3) edge cases like empty categories or null settings, (4) whether the fallback path produces user-visible output that actually helps debug a missing config.`

#### Pre-mortem pass

Prompt focus:

`Assume the subagent model routing feature shipped and passed all tests, but users are still experiencing problems. What are the most likely failure modes? Consider: (1) Pi's extension API might not support dynamic descriptions — how does the extension handle that? (2) The settings.json might be read before it's available or after it changes mid-session. (3) The LLM might ignore the routing table — is that acceptable per spec?`

---

## Acceptance Criteria

1. `subagent_run` and `subagent_fork` tool descriptions include a markdown routing table with all 5 categories (scout, planner, reviewer, implementer, specialist) when `subagentModelRouting` is present in `settings.json`.
2. Each routing table row has 6 columns: Category, Description, Model, Provider, Thinking, Rationale — matching the data in `pi/settings.json`.
3. When `subagentModelRouting` is absent from `settings.json`, the extension logs a warning and tool descriptions include a fallback note instead of the routing table.
4. All unit tests pass (`npm test` in `pi/extensions/subagent/`).
5. TypeScript type-checking passes (`npx tsc --noEmit`).
6. The routing table does not include fallback chains — each category maps to exactly one model/provider/thinking combination.
7. `create-subagent-skill/SKILL.md` template includes the `routing category` field.

---

## Implementation Checklist

- [ ] **Slice 1: Read subagentModelRouting from settings.json** — Create `pi/extensions/subagent/tests/routing.test.ts`, write tests for parsing `subagentModelRouting` (5 categories present, missing key returns null, partial data returns what's available)
- [ ] **Slice 1: RED** — Run `npm test` in `pi/extensions/subagent/`, observe failure for `readRoutingTable` tests
- [ ] **Slice 1: GREEN** — Create `pi/extensions/subagent/routing.ts` with `RoutingEntry` type, `RoutingTable` type, and `readRoutingTable(settingsPath: string): RoutingEntry[] | null`
- [ ] **Slice 1: GREEN** — Run `npm test` in `pi/extensions/subagent/`, observe pass for `readRoutingTable` tests
- [ ] **Slice 1: REFACTOR** — none needed
- [ ] **Slice 1: REFACTOR** — Run `npm test`, confirm still green

- [ ] **Slice 2: Format routing table as markdown** — Add tests to `pi/extensions/subagent/tests/routing.test.ts` for `formatRoutingTable` (5 categories → correct markdown, 0 categories → empty string/fallback)
- [ ] **Slice 2: RED** — Run `npm test` in `pi/extensions/subagent/`, observe failure for `formatRoutingTable` tests
- [ ] **Slice 2: GREEN** — Add `formatRoutingTable(entries: RoutingEntry[]): string` to `pi/extensions/subagent/routing.ts`
- [ ] **Slice 2: GREEN** — Run `npm test` in `pi/extensions/subagent/`, observe pass for `formatRoutingTable` tests
- [ ] **Slice 2: REFACTOR** — none needed
- [ ] **Slice 2: REFACTOR** — Run `npm test`, confirm still green

- [ ] **Slice 3: Inject routing table into tool descriptions** — Add tests to `pi/extensions/subagent/tests/routing.test.ts` for `buildToolDescription` (routing present → markdown in description, null → fallback note)
- [ ] **Slice 3: RED** — Run `npm test` in `pi/extensions/subagent/`, observe failure for `buildToolDescription` tests
- [ ] **Slice 3: GREEN** — Add `buildToolDescription(base: string, routing: RoutingEntry[] | null): string` to `pi/extensions/subagent/routing.ts`
- [ ] **Slice 3: GREEN** — Run `npm test` in `pi/extensions/subagent/`, observe pass for `buildToolDescription` tests
- [ ] **Slice 3: REFACTOR** — none needed
- [ ] **Slice 3: REFACTOR** — Run `npm test`, confirm still green

- [ ] **Slice 4: Wire routing into subagent_run and subagent_fork registration** — Add tests to `pi/extensions/subagent/tests/routing.test.ts` that tool descriptions include routing table when configured and omit it when not
- [ ] **Slice 4: RED** — Run `npm test` in `pi/extensions/subagent/`, observe failure for integration tests
- [ ] **Slice 4: GREEN** — Wire `readRoutingTable` + `buildToolDescription` into `pi/extensions/subagent/index.ts` — read settings at init, build descriptions for `subagent_run` and `subagent_fork`; add warning log for missing `subagentModelRouting`
- [ ] **Slice 4: GREEN** — Run `npm test` in `pi/extensions/subagent/`, observe pass for all tests
- [ ] **Slice 4: REFACTOR** — Extract description strings to constants (now built dynamically)
- [ ] **Slice 4: REFACTOR** — Run `npm test`, confirm still green

- [ ] Run full test suite: `npm test` in `pi/extensions/subagent/`
- [ ] Run type-check: `npx tsc --noEmit` in `pi/extensions/subagent/`
- [ ] Verify `settings.json` has all 5 routing categories
- [ ] Verify `create-subagent-skill/SKILL.md` has routing category field
- [ ] Run `test-quality-verifier` pass on `pi/extensions/subagent/tests/routing.test.ts`
- [ ] Run pre-mortem subagent pass

---

## References

- `specs/ai-agent-config.md` v1.2.0 (B5.1 rules 10-13, B4.3 rule 1, AIAGT-013, TS-AIAGT-025/026/027)
- `specs/parameters.md` v1.2.0 (SUBAGENT_ROUTING_* parameters)
- `specs/UBIQUITOUS_LANGUAGE.md` v0.1.0 (subagent model routing, scout, planner, reviewer, implementer, specialist)
- `pi/extensions/subagent/index.ts` (current subagent tool registration)
- `pi/extensions/subagent/subagent-config.ts` (current subagent config resolution)
- `pi/settings.json` (current routing table data)
- `shared/skills/create-subagent-skill/SKILL.md` (current skill template with routing category)
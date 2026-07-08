# Create Slice Plan — Reference

This file contains the templates and reference material for creating a slice plan. The **README.md Template** below is what the orchestrator agent reads at execution time. It must contain all guardrails, role assertions, and anti-patterns directly — do not assume the orchestrator will read this REFERENCE.md.

## File Structure

```
plan/
├── README.md              # Manifest, context, orchestrator instructions (the orchestrator reads THIS)
└── slices/
    ├── 001-setup-types.md
    ├── 002-config-resolution.md
    └── 003-core-logic.md
```

No sprawl. All slice state lives in one file per slice.

---

## README.md Template

> **This is the single most important artifact.** The orchestrator agent reads this file and follows its instructions at execution time. Every guardrail — role assertion, status flow, review gates, anti-patterns — must be in THIS file. Do not assume the orchestrator will read any other document.

Copy this template and fill in the bracketed sections. **Do not remove the role assertion, status flow, anti-patterns, or delegation format sections** — these are the guardrails that prevent common orchestrator failure modes.

```markdown
# [Feature Name] Slice Plan

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

- [ ] `cd [project-dir] && [test-command]` — all existing tests pass
- [ ] Dev dependencies are installed
- [ ] No unrelated changes in the working tree

Run this as a `subagent_run` with `tools: "read,bash"` if needed. Do not proceed until the baseline is green.

## Overview
[One paragraph: what this plan implements and why]

## Context Input
[Spec delta, decisions table, or research summary — same format as create-plan]

## Current Code State
### What is already correct
- [List what the codebase already does right]

### What is currently out of alignment
- [List specific files/behaviors that violate specs or decisions]

### Important implementation constraints
[One paragraph on what NOT to change unless a test proves it necessary]

## Intended Implementation Shape
[Conceptual architectural direction — not step-by-step]

## Manifest

| # | Slice | File | Status | Model | Provider | Thinking | Guardrails | Review Model | Review Provider | Reviews | Dependency |
|---|-------|------|--------|-------|----------|----------|------------|--------------|-----------------|---------|-------------|
| 1 | Setup types | `slices/001-setup-types.md` | ⏳ not-started | minimax-m2.7 | ollama-cloud | medium | 20T $0.10 100K 2m | deepseek-v4-pro | opencode-go | test | — |
| 2 | Config resolution | `slices/002-config-resolution.md` | ⏳ not-started | minimax-m2.7 | ollama-cloud | medium | 30T $0.30 200K 5m | deepseek-v4-pro | opencode-go | test, quality | 1 |
| 3 | Core logic | `slices/003-core-logic.md` | ⏳ not-started | glm-5.1 | opencode-go | high | 50T $1.00 500K 10m | deepseek-v4-pro | opencode-go | test, quality, security | 1, 2 |

Guardrails column format: `maxTurns`T `maxCost` `maxTokens` maxTime (e.g., `20T $0.10 100K 2m`). Passed as `maxTurns`, `maxCost`, `maxTokens`, `maxTime` params to `subagent_run` / `subagent_fork`.

Status values: `not-started`, `blocked`, `in-progress`, `review`, `needs-fix`, `done`

The **File** column is mandatory. Every sub-agent task must reference the slice file path.

Review pass types: **test** = brief assertions pass, no vague/weak tests; **quality** = code structure, naming, consistency, adherence to spec; **security** = no new attack surface, input validation, data exposure. Each type is a **separate** review sub-agent call — do not combine them.

## Execution Loop

Repeat until all slices are `done`:

1. **Read this manifest.** Find the next eligible action:
   - If any slice has status `review` → **delegate a review sub-agent before doing anything else.** Review is the highest priority.
   - If any slice has status `not-started` and all dependencies are `done` → delegate implementation.
   - If no slices are eligible → wait for running sub-agents or escalate `needs-fix` slices.

2. **Delegate implementation.** For each ready slice, call `subagent_run` or `subagent_fork`:
   ```
   agent: "implementer"
   task: "Read the slice brief at plan/slices/NNN-[name].md. Execute the RED, GREEN, REFACTOR cycle. Update checkboxes as you complete each step."
   maxTurns: [from manifest Guardrails column]
   maxCost: [from manifest Guardrails column]
   maxTokens: [from manifest Guardrails column]
   maxTime: [from manifest Guardrails column, in seconds]
   ```
   The implementer agent file in ~/.pi/agent/agents/implementer.md provides the system prompt, tools, model, and thinking level. Only per-slice guardrails are overridden.

   After the sub-agent completes → update manifest status to `review`.

3. **Delegate review.** **This step is mandatory. It is not optional.** Each review type is a separate sub-agent call. For a slice with `test, quality` reviews:
   ```
   # test review
   agent: "test-reviewer"
   task: "Review slice N at plan/slices/NNN-[name].md. Run the test suite. Verify each test assertion from the RED section passes. Check for vague assertions. Write your verdict with ✅ PASS or ❌ NEEDS-FIX in the Review section."
   model: [from manifest Review Model column]
   provider: [from manifest Review Provider column]
   maxTurns: 10
   maxCost: 0.10
   maxTime: 120

   # quality review (separate call)
   agent: "quality-reviewer"
   task: "Review slice N at plan/slices/NNN-[name].md. Evaluate implementation for code quality: naming, structure, coupling, adherence to spec constraints. Write your verdict with ✅ PASS or ❌ NEEDS-FIX in the Review section."
   model: [from manifest Review Model column]
   provider: [from manifest Review Provider column]
   maxTurns: 10
   maxCost: 0.10
   maxTime: 120
   ```

   For security review, use `agent: "security-reviewer"` with a similar pattern. The agent .md files in ~/.pi/agent/agents/ provide the system prompts and tool scoping. Review agent files already scope tools to read+bash — do not override.
   After all review types pass → update manifest status to `done`.
   If any review type returns ❌ NEEDS-FIX → update manifest status to `needs-fix`, begin escalation.

4. **Process needs-fix.** Append a course correction to the slice file, re-delegate implementation, then re-review all types.

5. **When all slices are `done`**, run the verification sequence from the Verification section.

## Anti-Patterns — DO NOT DO THESE

1. **🔴 Implementing code yourself.** You are an orchestrator. You delegate. You never write code, edit files, or run tests. If you're about to write code — delegate a sub-agent instead.
2. **🔴 Skipping review.** Every slice MUST go through a review sub-agent before `done`. You cannot mark a slice `done` after implementation without a reviewer's ✅ PASS verdict. Each review type is a **separate** sub-agent call.
3. **🔴 Using scout sub-agents.** Do not spawn "scout" or "research" sub-agents to explore code before delegating. The slice brief inlines all context. The implementation sub-agent reads the slice file and then reads/writes code. Scouting is the sub-agent's job, not yours.
4. **Marking a slice done without review.** The status flow is `not-started → in-progress → review → done`. You cannot jump from `in-progress` to `done`.
5. **Overriding review agent tool scopes.** Review agent files (test-reviewer, quality-reviewer, security-reviewer) already scope tools to read+bash. Do not add `write` or `edit` to review sub-agent calls.
6. **Combining review types into one call.** Each review type (test, quality, security) is a separate sub-agent call with its own named agent. Do not combine them.
7. **Omitting guardrails on sub-agent calls.** Every `subagent_run` and `subagent_fork` call must include `maxTurns`, `maxCost`, `maxTokens`, and `maxTime` from the manifest. Without guardrails, a stuck sub-agent burns resources indefinitely.

## Escalation Protocol

1. **Provider switch** — same model, different allowed provider (e.g., ollama-cloud → opencode-go, where available)
2. **Course correction** — append guidance to slice's Course Corrections section, re-delegate same model+provider
3. **Model bump** — escalate to stronger model or higher thinking
4. **Orchestrator takeover** — you implement directly (last resort only)

Never skip tiers. Try the cheap thing first.

## Turn-Count Heuristics

These are **soft heuristics** for the orchestrator to monitor progress. They are separate from **hard guardrails** (maxTurns, maxCost, maxTokens, maxTime) which kill the sub-agent automatically when exceeded.

- **Caution**: Read the slice file's Progress section. If checkboxes are being checked, let it ride. If no progress in 10 turns, course-correct.
- **Escalate**: Switch provider. If still no progress after 15 more turns, course-correct.
- **Guardrails** handle the hard kill: a sub-agent that exceeds its maxTurns/maxCost/maxTokens/maxTime threshold is terminated automatically. The orchestrator does not need to monitor for hard limits — only for soft "no progress" signals below the guardrail threshold.

| Model tier | Caution (check progress) | Escalate (switch to stronger model) | Hard kill (maxTurns guardrail) |
|------------|--------------------------|-------------------------------------|-------------------------------|
| routine (minimax-m2.7) | 15 turns | 20 turns | 20T |
| standard (minimax-m2.7) | 20 turns | 30 turns | 30T |
| tricky (glm-5.1) | 30 turns | 40 turns | 50T |

## Orchestration Notes
[Any plan-specific notes about which slices can run in parallel, risk tier assignments, budget constraints, provider preferences, shared-file warnings]

## Acceptance Criteria
[Numbered list of testable conditions]

1. [Specific measurable behavior]
2. [Tolerance or constraint]
3. All quality gates pass (lint, typecheck, test suites)

## Verification

1. Run `make test` — full suite
2. Run `make lint`
3. Run `make typecheck`
4. Run `test-quality-verifier` pass on all new test files
5. Run pre-mortem subagent pass
6. [Additional review passes grilled during plan creation]

## References

[List every spec file, research file, decision source, API doc, and source/test file referenced]
```

---

## Slice File Template

Each slice file is self-contained. A sub-agent on a weak model should open this ONE file and have everything it needs. **Inline all context — do not link to external files.**

```markdown
# Slice N: [Descriptive Name]

## Context

**Spec references**: [Inline the relevant spec sections, not just links]
**Decisions**: [Inline the relevant decision rows from grill-me]
**Current code state**: [Only what this slice touches — what's already correct, what's out of alignment]
**Dependency**: [Which slices must be done first, or "none"]

## Files

List every file this slice touches, with full paths from project root and what action you'll take:

- Modify: `path/to/existing-file.ts` — [what you'll change: e.g., "add tools field to interface"]
- Create: `path/to/new-file.test.ts` — [what you'll create: e.g., "test file for formatToolsBracket"]
- Read: `path/to/reference-file.ts` — [why you need it: e.g., "reference for SubagentConfig.tools type"]

If this slice shares a file with another slice, add a ⚠️ warning:

- Modify: `path/to/shared-file.ts` ⚠️ **Shared with Slice M** (different functions, low merge risk) — or — ⚠️ **Shared with Slice M** (overlapping edits, sequence this slice after M)

## Green — Scope

**Implementation points** (target: ≤6 per slice; if more, consider splitting):

1. [Change X in file Y]
2. [Change X in file Y]
3. [Change X in file Y]
4. [Change X in file Y]
5. [Change X in file Y]
6. [Change X in file Y]

If you find yourself writing 8+ implementation points, split this slice in two.

## Red — Write Tests First

Create the test file and write assertions for the behavior this slice requires. Do **not** create or modify any implementation source files at this stage.

Expected: **~[min]–[max] tests** (range allows ±2 flexibility)

- Test file: `path/to/test.file`
- What the test proves: [specific behavior]
- Assertion strategy: [deterministic / pure helper / state check — not snapshots]
- Existing tests to rewrite: [any tests endorsing wrong behavior, or "none"]

For non-trivial logic (formatting, parsing, truncation), provide **3–4 input/output examples** in a table so the implementer can verify their algorithm:

| Input | Expected output | Why |
|-------|----------------|-----|
| [input] | [output] | [edge case this covers] |
| [input] | [output] | [edge case this covers] |
| [input] | [output] | [edge case this covers] |

Run the test suite. You must see the test fail. If the test passes, it's not a red test.

**Hard gate: Do not proceed to Green until you have created the test file, written the tests, run the test suite, and observed a failure.**

## Green — Make Tests Pass

Now create or modify implementation source files to make the failing test pass. Write the smallest change that turns red to green.

- Source file: `path/to/source.file` (create if it doesn't exist yet)
- What to change: [specific function, class, or behavior]
- Constraint: [minimal change — one sentence about what the green step must NOT do]
- Decisions/spec delta this satisfies: [Q3 / spec item 2]

## Refactor — Clean Up While Green

- [Extract helper / consolidate / rename — or "none needed"]
- Keep separate: [what must not be merged]

## Progress

- [ ] **RED** — Create test file `path`, write tests for [behavior]
- [ ] **RED** — Run `[test command]`, observe failure for [test names]
- [ ] **GREEN** — Implement [specific change] in `source file`
- [ ] **GREEN** — Run `[test command]`, observe pass for [test names]
- [ ] **REFACTOR** — [refactor action, or "none needed"]
- [ ] **REFACTOR** — Run `[test command]`, confirm still green

## Review

[Review agents write their verdicts here as they complete each review pass]

## Course Corrections

[Orchestrator appends here when re-delegating — what went wrong, what to try differently]
```

---

## Authoring Quality Checklist

When writing a slice plan, verify these before finalizing:

- [ ] README contains the role assertion ("YOU ARE AN ORCHESTRATOR — YOU DO NOT IMPLEMENT CODE")
- [ ] README contains the mandatory status flow diagram with hard gates
- [ ] README contains the anti-patterns section (especially: don't implement, don't skip review, don't use scouts)
- [ ] README contains the execution loop with explicit review delegation step (separate per review type)
- [ ] README contains review pass type definitions (test, quality, security)
- [ ] README contains pre-flight checks
- [ ] README contains turn-count escalation heuristics
- [ ] Manifest table has a File column with slice file paths
- [ ] Manifest table has a Guardrails column with per-slice thresholds (maxTurns, maxCost, maxTokens, maxTime)
- [ ] Every `subagent_run` / `subagent_fork` call in the execution loop includes guardrails from the manifest
- [ ] Every slice brief has a `## Files` section with full paths and Modify/Create/Read verbs
- [ ] Shared files between parallel slices have ⚠️ warnings with merge-risk assessment
- [ ] Every slice brief inlines its own context (no "see README" or "see spec" links)
- [ ] Every slice brief has specific file paths for test files and source files
- [ ] Every slice RED section has an expected test count range
- [ ] Slice briefs with non-trivial logic have 3–4 input/output example table
- [ ] No slice has more than ~6 Green implementation points (split if more)
- [ ] Progress checklists follow RED → GREEN → REFACTOR cycle (not flat task lists)
- [ ] Orchestration Notes call out shared-file warnings and parallel/serial decisions

---

## Escalation Protocol

Full 4-tier escalation ladder, tried in order:

1. **Provider switch** — same model, different allowed provider (e.g., ollama-cloud → opencode-go, where available)
2. **Course correction** — orchestrator appends guidance to the slice file's Course Corrections section, re-delegates to same model+provider
3. **Model bump** — escalate to a stronger model (e.g., glm-5.1 → deepseek-v4-pro, or thinking: medium → high)
4. **Orchestrator takeover** — the orchestrator agent itself implements the slice directly

Each escalation is recorded in the slice file's Course Corrections section with:
- Why the escalation happened
- What was tried at lower tiers
- What changed for this attempt

**Never skip tiers.** Switch provider before appending a course correction. Append a correction before bumping the model. Bump the model before orchestrator takeover.

---

## Risk Tier Defaults

| Decision | routine | standard | tricky |
|----------|---------|----------|--------|
| Implementation model | minimax-m2.7 | minimax-m2.7 | glm-5.1 |
| Implementation thinking | medium | medium | high |
| Implementation provider | ollama-cloud | ollama-cloud | opencode-go |
| Implementation guardrails | 20T $0.10 100K 2m | 30T $0.30 200K 5m | 50T $1.00 500K 10m |
| Review model | deepseek-v4-pro | deepseek-v4-pro | deepseek-v4-pro |
| Review thinking | high | high | high |
| Review provider | opencode-go | opencode-go | opencode-go |
| Review guardrails | 10T $0.10 50K 2m | 10T $0.10 50K 2m | 10T $0.10 50K 2m |
| Review gates | test | test, quality | test, quality, security |
| Escalation retries | 2 | 2 | 3 |
| Final escalation | orchestrator takeover | orchestrator takeover | orchestrator takeover |

---

## Review Pass Types

Each review type listed in a slice's Reviews column triggers a **separate** review sub-agent call. Do not combine review types into a single call.

**Definitions** (also included in the manifest legend):

- **test** — Verify brief's test assertions pass. Identify vague or weak assertions that would pass even if the implementation is wrong. Check expected test count range is met.
- **quality** — Code structure, naming, consistency, coupling. Verify adherence to spec constraints in the slice brief.
- **security** — Input validation, auth boundaries, data exposure. Check for new attack surfaces introduced by the slice's changes.

A review pass is a `subagent_run` call with the review model and provider from the manifest. The reviewer reads the slice file, examines the relevant code files, and writes a verdict into the slice file's Review section:

```
### [type] review — deepseek-v4-pro — ✅ PASS / ❌ NEEDS-FIX

[Verdict details: what was checked, what passed, what needs fixing]

[If NEEDS-FIX: specific items that must be addressed]
```

---

## Comparison with create-plan

`create-plan` and `create-slice-plan` serve different purposes:

| | create-plan | create-slice-plan |
|---|---|---|
| **Best for** | Single capable agent (Claude, Codex) | Multi-model orchestration on Pi |
| **Output** | Single PLAN.md | plan/ directory with README + slice files |
| **Model routing** | Not needed — one agent | Manifest specifies model + provider per slice |
| **Review** | Optional subagent passes | Mandatory per-slice review gates (separate per type) |
| **Escalation** | Not built in | 5-tier escalation ladder with turn-count heuristics |
| **Durable state** | Single document | Per-slice files survive sub-agent context resets |
| **Parallelization** | N/A — single agent | Default serial, opt-in parallel |

---
name: create-plan
description: Create a structured implementation plan with red/green TDD slices, verification passes, and acceptance criteria. Adapts to the available context — spec-driven, research-driven, decision-driven (grill-me outcomes), or hybrid. Use when planning a feature implementation, bug fix, refactor, or any change that needs a rigorous step-by-step plan with test-first design and verification gates.
metadata:
  short-description: Create TDD-sliced implementation plans
---

# Create Plan

Produce a structured implementation plan document (usually `PLAN.md`) that breaks work into red/green/refactor TDD slices with explicit verification passes. The plan must be detailed enough for an autonomous agent or a different engineer to execute without hidden context.

## Context Engines — How Plans Get Their Input

Plans are fed by different sources of truth depending on the project and the nature of the change. The plan structure is the same regardless — what varies is the **Context Basis** section and how decisions appear.

### Context engine taxonomy

| Engine | When | What feeds the plan | Key trait |
|--------|------|---------------------|-----------|
| **Spec-driven** | Project has active `specs/` (like stick-rumble) | Spec versions + spec delta | Specs are the contract; code is the implementation |
| **Research-driven** | New territory, no spec yet | Research notes, spikes, experiments | Research replaces specs as the reference |
| **Decision-driven** | Grill-me session, design discussion | Decisions table (grill outcomes) | Resolved decisions replace spec authority |
| **Hybrid** | Mix of the above | Spec delta for known ground + decisions table for new ground | Most common for nontrivial changes |

### How to determine which engine applies

1. **Specs exist and the change is covered by them** → spec-driven
2. **No specs, but research/notes/spikes exist** → research-driven
3. **User just did a grill-me session or design discussion** → decision-driven
4. **Some specs cover part of the change, but new ground needs decisions** → hybrid

A single plan can mix engines. For example: spec delta covers the rendering contract, but the data persistence approach required a grill-me decision table.

### How each engine shapes the plan

Each engine shapes the plan differently. See [EXAMPLES.md](EXAMPLES.md) for concrete worked patterns from real projects.

**Spec-driven**: Context Basis = spec commit. Spec Delta = numbered spec changes. Slices = red/green against spec requirements. References = spec files + source files.

**Decision-driven**: Context Basis = decisions table. No spec delta — decisions ARE the spec. Slices = red/green against decision outcomes. References = source files + API docs.

**Research-driven**: Context Basis = research findings. No spec delta — research replaces it. Slices = red/green against research conclusions.

**Hybrid**: Spec delta for spec-covered ground + decisions table for new ground. Slices trace back to both.

## Process

1. **Identify context engine** — specs? decisions? research? hybrid? (see table above)
2. **Gather context** — read specs, research, or decision outcomes; read current code
3. **Write Context Basis** — spec delta, decisions table, research summary, or combination
4. **Assess current code state** — what's already correct, what's out of spec/out of alignment, constraints
5. **Shape the implementation** — the intended approach at a conceptual level
6. **Slice into red/green/refactor** — each slice is a vertical slice with a test-first cycle
7. **Define verification** — local run order + subagent passes with focused prompts
8. **Write acceptance criteria** — numbered, testable, verifiable
9. **Build checklist** — per-slice TDD cycle checklist + verification gates (not a flat list)

## Plan Structure

Every plan document must include these sections in order:

### 1. Title and Context Basis

The header identifies what this plan is grounded in.

**Spec-driven:**
```markdown
# [Feature Name] Implementation Plan
## [Short subtitle]

**Based on spec commit:** `abc1234` - `type(scope): message`
```

**Decision-driven:**
```markdown
# [Feature Name] Implementation Plan
## [Short subtitle]

> **Status: PLANNING** — N design decisions resolved. Ready for TDD implementation.
```

**Hybrid:**
```markdown
# [Feature Name] Implementation Plan
## [Short subtitle]

**Based on spec commit:** `abc1234` - `type(scope): message`

> **Status:** Spec-driven for rendering contract. Decision-driven for persistence approach.
```

### 2. Overview

Plain-language description of what this plan implements and why. State the core requirement in one paragraph. Ground the reader immediately — is this primarily rendering, physics, API design, architecture, tooling?

### 3. Context Input — Spec Delta, Decisions, or Both

Choose the right format based on context engine:

**Spec Delta** (spec-driven or hybrid):
```markdown
## Spec Delta To Implement

1. The visible body's outer extents must match the authoritative hitbox within 1 pixel per side.
2. The live body must stay axis-aligned in idle, movement, aim, and dodge roll states.
```

**Decisions Table** (decision-driven or hybrid):
```markdown
## Decisions (grill outcomes)

| # | Question | Decision | Source |
|---|----------|----------|--------|
| Q1 | Which hook? | `session_before_switch` for write | Lifecycle diagram |
| Q2 | Persistence across reload? | Temp file bridge | Extensions are torn down between sessions |
| Q3 | No model selected? | Skip write, fall through to defaults | `ctx.model` can be undefined |
```

The decisions table comes from grill-me sessions, design discussions, or research conclusions. Each decision must have a **Source** column explaining why — even if it's just "grill-me session" or "spike proved X doesn't work." Decisions without rationale are assertions, not decisions.

**Research Summary** (research-driven):
```markdown
## Research Findings

1. **Spike result**: Approach A fails because [specific reason]. Approach B works with [caveat].
2. **Benchmark**: Approach B handles 10k ops/sec within latency budget.
3. **Constraint discovered**: The upstream API rate-limits at 100 req/min.
```

### 4. Current Code State

Two or three subsections:
- **What is already correct** — list what the codebase already does right; don't re-implement
- **What is currently out of spec / out of alignment** — list specific files, specific behaviors that violate the spec or decisions
- **Important implementation constraint** — one paragraph on what NOT to change unless a test proves it necessary

This section prevents scope creep and redundant work. For decision-driven plans, "out of alignment" means "doesn't match the resolved decisions."

### 5. Intended Implementation Shape

Describe the approach at a conceptual level. Not step-by-step, but the architectural direction: what the simplest acceptable implementation looks like, where complexity belongs, and what a conservative approach would avoid.

### 6. Red/Green TDD Slices

This is the core of the plan. Each slice is a self-contained red/green/refactor cycle with **structurally separated** Red and Green sections. The Red section and Green section must be distinct — never combine them into a single paragraph or bullet list.

#### Slice template

```markdown
### Slice N: [Descriptive name]

#### Red — Write tests first, no implementation code yet

Create the test file and write assertions for the behavior this slice requires. Do **not** create or modify any implementation source files at this stage.

- Test file: `[path/to/test.file]`
- What the test proves: [specific behavior]
- Assertion strategy: [deterministic geometry / pure helper / state check — not snapshots]
- Existing tests to rewrite: [any tests endorsing wrong behavior, or "none"]

Run the test suite. You must see the test fail. If the test passes, it's not a red test — either the behavior already exists, or the test is not asserting what you think it is. Fix the test and re-run until it fails.

**Hard gate: Do not proceed to Green until you have created the test file, written the tests, run the test suite, and observed a failure.** No implementation source files should exist or be modified at this point.

#### Green — Make the red test pass, minimum change only

Now — and only now — create or modify implementation source files to make the failing test pass. Write the smallest change that turns red to green.

- Source file: `[path/to/source.file]` (create if it doesn't exist yet)
- What to change: [specific function, class, or behavior]
- Constraint: [minimal change — one sentence about what the green step must NOT do]
- Decisions/spec delta this satisfies: [Q3 / spec item 2]

Run the test suite again. The tests that were red must now pass. If they don't, you changed too much or too little — adjust and re-run.

#### Refactor — Clean up while keeping tests green

Optional cleanup after green:

- [Extract helper / consolidate / rename — or "none needed"]
- Keep separate: [what must not be merged]

Run the test suite again to confirm everything is still green after refactoring.
```

**Why the Red and Green sections must be separated:**
- Red is the **contract** — it defines what correct behavior looks like
- Green is the **implementation** — it defines the minimum change to satisfy the contract
- Combining them creates ambiguity about whether a behavior is required (red) or accidental (green)
- A future reader must be able to read the Red section alone and know exactly what the system must do
- A future implementer must be able to read the Green section alone and know exactly what to change
- There is a **hard gate** between Red and Green: the test file must be created, tests written, the suite run, and a failure observed before any implementation source file is touched. This gate is what makes TDD work — it proves the test actually tests something that didn't exist before.

**Slicing rules:**
- Each slice addresses one vertical concern — a coherent set of behaviors
- **Red writes tests first. No implementation source files are created or modified until Red is complete.** The test file is the only file that should be created or changed during the Red phase.
- Red must be confirmed failing before Green begins. Write the test, **run the suite, observe the failure** — only then proceed to Green. Writing a test without running it is not red — it's untested intent.
- Every Red section must name the test file and what the test proves
- Every Green section must name the source file and the specific change. If the source file doesn't exist yet, say "Create" explicitly.
- Green makes the smallest change that turns red to green. Do not add functionality that the red test doesn't require.
- Existing tests that endorse wrong behavior must be rewritten in the Red section, not retained alongside
- Prefer assertions against deterministic geometry or pure helpers over brittle snapshot checks
- Slices are ordered by dependency — earlier slices create foundations later slices build on
- For decision-driven plans, each Green section traces back to at least one decision it implements
- If the Refactor step is significant, consider whether it should be its own slice
- The implementation checklist (Section 10) must mirror slice order exactly — each slice's full RED → GREEN → REFACTOR cycle appears as a contiguous group before the next slice begins. Never flatten all tests into one block followed by all implementation.

### 7. Verification

Two subsections:

**Local verification sequence** — numbered list of commands to run, in order. Start with targeted tests, then expand to full suites, then quality gates:

```markdown
1. Run targeted tests for: [specific test files]
2. Run `make test-client`
3. Run `make lint`
4. Run `make typecheck`
5. Run `make test`
```

**Subagent verification passes** — these run after local red/green work is green. Each pass has:
- A tool/agent to use (e.g., `test-quality-verifier`, generic subagent)
- Specific files to review
- A **prompt focus** — a single paragraph directing the agent's attention

```markdown
#### Test verifier pass 1

Use `test-quality-verifier` on:
- `[specific test file]`

Prompt focus:

`Review the recent test changes for [specific concern]. Identify weak assertions,
missing edge cases around [specific behavior], and any places where the tests
would pass even if [wrong behavior happened].`

#### Pre-mortem pass

Use a generic/default subagent type for a pre-mortem review.

Prompt focus:

`Perform a pre-mortem on [feature]. Assume the code passed tests but still ships
a bad experience. Find the most likely failure modes around [specific risks].`

The pre-mortem should produce risks, not a rewrite plan.
```

**Key principle**: Subagent passes catch what automated tests miss. They run after tests are green, not before. Every pass needs a prompt focus — "review the tests" produces garbage; "identify places where tests would pass even if the body rotated" produces gold.

### 8. Reviewer Findings (Optional)

If a pre-implementation review was done (code review, design review, grill-me), include a findings table:

```markdown
## Reviewer Findings (Addressed)

| Finding | Severity | Fix |
|---------|----------|-----|
| Interface retains dead field | Critical | Cycle 4: explicitly remove |
| No backward-compat deserialization | Critical | Cycle 2: add guard |
| Edge case untested | Warning | Cycle 3: add test |
```

This section proves that review input was handled, not ignored. Each finding maps to the slice that addresses it. Include this when review happened; skip it when there was no review.

### 9. Acceptance Criteria

Numbered list of testable conditions. Each criterion must be verifiable by a human or machine.

```markdown
1. [Specific measurable behavior].
2. [Tolerance or constraint — e.g., "within 1 rendered pixel per side"].
3. [State coverage — e.g., "idle, walking, aiming, and rolling all preserve..."].
```

The last criterion should always be: "All quality gates pass" (lint, typecheck, test suites).

### 10. Implementation Checklist

Markdown checklist that mirrors the slice order, preserving the RED → GREEN → REFACTOR cycle for each slice. Every slice must show its full TDD cycle as a contiguous group of checkboxes — never flatten all test creation into one block followed by all implementation.

```markdown
- [ ] **Slice 1: [Descriptive name]** — Create test file `[path]`, write tests for [behavior]
- [ ] **Slice 1: RED** — Run `[test command]`, observe failure for [test names]
- [ ] **Slice 1: GREEN** — Implement [specific change] in `[source file]`
- [ ] **Slice 1: GREEN** — Run `[test command]`, observe pass for [test names]
- [ ] **Slice 1: REFACTOR** — [refactor action, or "none needed"]
- [ ] **Slice 1: REFACTOR** — Run `[test command]`, confirm still green
- [ ] **Slice 2: [Descriptive name]** — Create test file `[path]`, write tests for [behavior]
- [ ] **Slice 2: RED** — Run `[test command]`, observe failure for [test names]
- [ ] **Slice 2: GREEN** — Implement [specific change] in `[source file]`
- [ ] **Slice 2: GREEN** — Run `[test command]`, observe pass for [test names]
- [ ] **Slice 2: REFACTOR** — [refactor action, or "none needed"]
- [ ] **Slice 2: REFACTOR** — Run `[test command]`, confirm still green
...
- [ ] Run full test suite (`make test`)
- [ ] Run `make lint`
- [ ] Run `make typecheck`
- [ ] Run `test-quality-verifier` pass on [specific test files]
- [ ] Run pre-mortem subagent pass
```

**Why the checklist must preserve per-slice cycles:**
- A flat list that puts all implementation before all tests is the opposite of TDD — it encourages writing all the code first, then writing tests afterward as an afterthought.
- Each slice's RED step must come before its GREEN step, and both must appear before the next slice begins.
- The checklist is the executable contract — if an agent (or human) can follow the checklist top-to-bottom and produce correct TDD work, the plan is well-structured. If they have to jump around, the checklist is broken.
- Slices are ordered by dependency, so earlier slices must be complete (green + refactored) before later ones begin.

**Verification gates are mandatory, not optional:**
- The subagent verification passes (test-quality-verifier, pre-mortem) listed in Section 7 are mandatory completion gates — they are not suggestions or nice-to-haves.
- Every verification pass listed in Section 7 must appear as a checked-off item in the checklist. If the plan lists a test-quality-verifier pass and a pre-mortem pass, both must be checked off before the work is considered complete.
- Skipping verification passes means the plan is not finished, even if all tests are green.

### 11. References

List every spec file, research file, decision source, API doc, and source/test file referenced in the plan. Full paths.

## Anti-patterns

1. **Vague slices** — "Add tests for the player" is not a slice. Name the file, name the assertion, name the expected behavior.

2. **Combined red/green paragraphs** — "Add a test that X is true and update the source to make X true" destroys the TDD contract. Red and Green must be separate sections so a reader can understand the requirement (Red) without reading the implementation (Green).

3. **Red step without running the test** — Writing a test and immediately moving to Green without running it is not TDD. You must execute the test suite and observe the failure. A test you never ran might pass for the wrong reason (e.g., it's not actually asserting what you think), making your "green" step meaningless.

4. **Flat checklist that batches all implementation then all tests** — The implementation checklist must preserve the per-slice RED → GREEN → REFACTOR cycle. A checklist that lists all source changes first, then tacks on "create test file" and "run tests" at the end is not TDD — it's test-after. Each slice must show: write tests → run red → implement → run green → refactor → run green, as a contiguous group, before the next slice begins. The checklist is the executable contract; if you can't follow it top-to-bottom and produce correct TDD work, it's structured wrong.

5. **Retaining tests that endorse wrong behavior** — If existing tests assert that the body rotates during roll, and the decision says it shouldn't, rewrite those tests in the Red section. Don't keep old and new assertions side by side.

6. **Verification without prompt focus** — A subagent told to "review the tests" will produce generic output. Give it a specific concern: "Identify places where tests would pass even if the body rotated."

7. **Skipping verification passes** — Subagent verification passes (test-quality-verifier, pre-mortem) are mandatory completion gates, not nice-to-haves. An implementation is not done until every verification pass listed in Section 7 has been executed and its findings addressed. Leaving these unchecked at the end of a session means the plan is incomplete — the checklist item must be checked off, not just listed.

8. **Scope creep in slices** — Each slice is one coherent concern. Don't bundle "fix rendering AND fix physics AND add map coverage" into a single slice.

9. **Spec delta as intent** — "Make the player body correct" is not a spec delta. "The visible body's outer extents must match the authoritative hitbox within 1 rendered pixel per side" is.

10. **Skipping current code state** — If you don't audit what's already correct, you'll re-implement working code. If you don't name what's out of alignment, you'll miss the actual gap.

11. **Decisions without source** — A decision that says "Use temp files" without a Source column explaining WHY is an assertion, not a decision. The Source column is what makes the table auditable and defensible.

12. **Force-fitting one context engine** — Not every project has specs. Not every change needs a grill-me session. Read the room: use whichever engine(s) match the available context. Don't invent spec delta for a change that came from a design discussion.

13. **Orphan reviewer findings** — If you include a Reviewer Findings section, every finding must map to a specific slice. Findings without implementation traceability are noise.

## References

- `write-a-skill` skill — skill authoring mechanics
- `test-quality-verifier` skill — subagent tool used in verification passes
- `grill-me` skill — produces decision tables that feed into decision-driven plans

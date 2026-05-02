# Create Slice Plan — Reference

## File Structure

```
plan/
├── README.md              # Manifest, context, orchestrator instructions
└── slices/
    ├── 001-setup-types.md
    ├── 002-config-resolution.md
    └── 003-core-logic.md
```

No sprawl. All slice state lives in one file per slice.

---

## README.md Template

The README is the orchestrator's single source of truth. It contains global context, the manifest table, and the execution instructions.

```markdown
# [Feature Name] Slice Plan

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

| # | Slice | Status | Model | Provider | Thinking | Review Model | Review Provider | Reviews | Dependency |
|---|-------|--------|-------|----------|----------|--------------|-----------------|---------|-------------|
| 1 | Setup types | ⏳ not-started | minimax-m2.7 | ollama-cloud | medium | deepseek-v4-pro | opencode-go | test | — |
| 2 | Config resolution | ⏳ not-started | minimax-m2.7 | ollama-cloud | medium | deepseek-v4-pro | opencode-go | test, quality | 1 |
| 3 | Core logic | ⏳ not-started | glm-5.1 | opencode-go | high | deepseek-v4-pro | opencode-go | test, quality, security | 1, 2 |

Status values: `not-started`, `blocked`, `in-progress`, `review`, `needs-fix`, `done`

## Orchestrator Instructions

### Execution Loop

1. Read this manifest. Identify slices whose dependencies are met and status is `not-started`.
2. For serial slices: use `subagent_run` with the model, provider, and thinking level specified.
3. For parallelizable slices (marked in orchestrator notes): use `subagent_fork`, then monitor completion.
4. When a sub-agent completes, delegate a review agent to evaluate the slice file.
5. If reviewer marks `done`: update manifest status to `done`.
6. If reviewer marks `needs-fix`:
   - **First retry**: append course correction to slice file, re-delegate same model+provider.
   - **Second retry**: bump model in manifest, re-delegate.
   - **Third retry**: escalate via expert-consultation skill.
   - **Final resort**: orchestrator takes over the slice directly.
7. When all slices are `done`, run the verification sequence.
8. Mark plan complete.

### Provider Fallback

If a provider is slow or unresponsive, switch to the same model on a different provider before escalating the model. Provider switch is the cheapest escalation.

### Stall Detection

Check slice file checklists after delegation. If no new checkbox has been checked after a reasonable interval, treat as stalled and begin escalation.

### Parallelization

Default serial execution. Only run slices in parallel when the manifest's orchestrator notes explicitly allow it and dependencies are met.

### Review Policy

Every slice gets the review passes specified in its Reviews column. Review blocks downstream slices that depend on it.

## Orchestration Notes
[Any plan-specific notes about which slices can run in parallel, risk tier assignments, budget constraints, provider preferences]

## Acceptance Criteria
[Numbered list of testable conditions — same format as create-plan]

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

Each slice file is self-contained. A sub-agent on a weak model should open this ONE file and have everything it needs.

```markdown
# Slice N: [Descriptive Name]

## Context

**Spec references**: [Inline the relevant spec sections, not just links]
**Decisions**: [Inline the relevant decision rows from grill-me]
**Current code state**: [Only what this slice touches — what's already correct, what's out of alignment]
**Dependency**: [Which slices must be done first, or "none"]

## Red — Write Tests First

Create the test file and write assertions for the behavior this slice requires. Do **not** create or modify any implementation source files at this stage.

- Test file: `[path/to/test.file]`
- What the test proves: [specific behavior]
- Assertion strategy: [deterministic / pure helper / state check — not snapshots]
- Existing tests to rewrite: [any tests endorsing wrong behavior, or "none"]

Run the test suite. You must see the test fail. If the test passes, it's not a red test.

**Hard gate: Do not proceed to Green until you have created the test file, written the tests, run the test suite, and observed a failure.**

## Green — Make Tests Pass

Now create or modify implementation source files to make the failing test pass. Write the smallest change that turns red to green.

- Source file: `[path/to/source.file]` (create if it doesn't exist yet)
- What to change: [specific function, class, or behavior]
- Constraint: [minimal change — one sentence about what the green step must NOT do]
- Decisions/spec delta this satisfies: [Q3 / spec item 2]

## Refactor — Clean Up While Green

- [Extract helper / consolidate / rename — or "none needed"]
- Keep separate: [what must not be merged]

## Progress

- [ ] **RED** — Create test file `[path]`, write tests for [behavior]
- [ ] **RED** — Run `[test command]`, observe failure for [test names]
- [ ] **GREEN** — Implement [specific change] in `[source file]`
- [ ] **GREEN** — Run `[test command]`, observe pass for [test names]
- [ ] **REFACTOR** — [refactor action, or "none needed"]
- [ ] **REFACTOR** — Run `[test command]`, confirm still green

## Review

[Review agents write their verdicts here as they complete each review pass]

## Course Corrections

[Orchestrator appends here when re-delegating — what went wrong, what to try differently]
```

---

## Escalation Protocol

Full 5-tier escalation ladder, tried in order:

1. **Provider switch** — same model, different provider (e.g., ollama-cloud → openrouter)
2. **Course correction** — orchestrator appends guidance to the slice file's Course Corrections section, re-delegates to same model+provider
3. **Model bump** — escalate to a stronger model (e.g., glm-5.1 → deepseek-v4-pro, or thinking: medium → high)
4. **Expert consultation** — uses the `expert-consultation` skill's 3-tier chain (deepseek-v4-pro → glm-5.1 → kimi-k2.6). The orchestrator provides the accumulated slice state as the consultation payload.
5. **Orchestrator takeover** — the orchestrator agent itself implements the slice directly

Each escalation is recorded in the slice file's Course Corrections section with:
- Why the escalation happened
- What was tried at lower tiers
- What changed for this attempt

**Never skip tiers.** Switch provider before appending a course correction. Append a correction before bumping the model. Bump the model before consulting an expert.

---

## Risk Tier Defaults

| Decision | routine | standard | tricky |
|----------|---------|----------|--------|
| Implementation model | minimax-m2.7 | minimax-m2.7 | glm-5.1 |
| Implementation thinking | medium | medium | high |
| Implementation provider | ollama-cloud | ollama-cloud | opencode-go |
| Review model | deepseek-v4-pro | deepseek-v4-pro | deepseek-v4-pro |
| Review thinking | high | high | high |
| Review provider | opencode-go | opencode-go | opencode-go |
| Review gates | test | test, quality | test, quality, security |
| Escalation retries | 2 | 2 | 3 |
| Final escalation | expert consultation | expert consultation | orchestrator takeover |

---

## Review Pass Types

Each slice's Reviews column specifies which passes it requires. The three pass types:

- **test** — Run `test-quality-verifier` skill on the slice's test files. Prompt focus: identify weak assertions, missing edge cases, tests that would pass even if the implementation is wrong.
- **quality** — Code quality review via sub-agent. Prompt focus: architecture, naming, coupling, adherence to spec, code smells.
- **security** — Security review via sub-agent. Prompt focus: input validation, auth boundaries, data exposure, dependency vulnerabilities.

A review pass is a `subagent_run` call with the review model and provider from the manifest. The reviewer reads the slice file, examines the relevant code files, and writes a verdict into the slice file's Review section:

```
### test review — deepseek-v4-pro — ✅ PASS / ❌ NEEDS-FIX

[Verdict details: what was checked, what passed, what needs fixing]

[If NEEDS-FIX: specific items that must be addressed]
```

---

## Anti-patterns

1. **Vague slices** — "Add tests for the player" is not a slice. Name the file, name the assertion, name the expected behavior.
2. **Slice files without inlined context** — A weak model following a link to the README will lose focus. Inline the relevant spec excerpts and decision rows directly in the slice file.
3. **Skipping the manifest** — The orchestrator must be able to read ONE table to know what's next, what model to use, and what reviews to run. If status isn't in the manifest, the orchestrator is flying blind.
4. **Review verdicts in separate files** — All state for a slice lives in the slice file. Reviewers write there, orchestrators read there, sub-agents get corrections there.
5. **Parallel without explicit opt-in** — Never assume slices can run in parallel. The plan must explicitly mark which slices are safe to parallelize.
6. **Skipping escalation tiers** — Never go straight to model bump when a provider switch might fix it. Never consult an expert when a course correction might fix it. Try the cheap thing first.
7. **Course corrections that don't explain what went wrong** — Every correction must explain why the previous attempt failed and what to try differently. "Try again" is not a course correction.
8. **Manifest without provider column** — Models have different availability and speed on different providers. The orchestrator needs to know both.
9. **Flat checklist** — The Progress checklist must follow RED → GREEN → REFACTOR cycle per slice, not batch all tests then all implementation.
10. **Orchestrator implementing instead of delegating** — The orchestrator's job is to delegate, monitor, review, and escalate. Orchestrator takeover is the last resort, not the default.

---

## Comparison with create-plan

`create-plan` and `create-slice-plan` serve different purposes:

| | create-plan | create-slice-plan |
|---|---|---|
| **Best for** | Single capable agent (Claude, Codex) | Multi-model orchestration on Pi |
| **Output** | Single PLAN.md | plan/ directory with README + slice files |
| **Model routing** | Not needed — one agent | Manifest specifies model + provider per slice |
| **Review** | Optional subagent passes | Mandatory per-slice review gates |
| **Escalation** | Not built in | 5-tier escalation ladder |
| **Durable state** | Single document | Per-slice files survive sub-agent context resets |
| **Parallelization** | N/A — single agent | Default serial, opt-in parallel |
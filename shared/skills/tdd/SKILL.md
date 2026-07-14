---
name: tdd
description: Test-driven development through vertical red-green-refactor tracer bullets at agreed seams. Use when implementing behavior or regression fixes test-first, when the user requests TDD or integration tests, or after diagnosis identifies a bug to lock down.
metadata:
  short-description: TDD with red-green-refactor tracer bullets
allowed-tools: read,write,bash,edit
---

# Test-Driven Development

## Language Definitions

- **Tracer bullet** — smallest honest end-to-end behavior through an agreed public interface.
- **Red** — focused behavior test observed failing for the intended reason.
- **Green** — minimum implementation passes it without focused regressions.
- **Refactor** — behavior-preserving structural improvement performed while green.
- **Independent oracle** — expectation source independent of implementation logic.
- **Vertical slice** — one behavior test plus minimum cross-layer implementation before the next behavior.
- **Discovered-bug fast path** — abbreviated intake when diagnosis, intended behavior, and existing seam are unambiguous.

`Seam` remains defined and owned by `codebase-design`. Load that skill whenever choosing or changing a module interface, seam, or depth.

## Workflow

### 1. Route the mode and establish the test contract

Select the mode before planning:

- **Discovered-bug mode:** select only when diagnosis, intended behavior and its source, and the existing seam are unambiguous.
- **Normal mode:** select for every other request.

After selecting the mode, read repository guidance, relevant specs, and the project glossary. In discovered-bug mode, state the observed bug, intended behavior and source, existing seam, smallest regression target, independent oracle, and tight command. Proceed without a full pre-agreement interview unless behavior, seam, or risk is ambiguous; if any is ambiguous, confirm it with the user first. In normal mode, confirm with the user the public interface, agreed seams, prioritized behavior order, independent oracle, and test commands before writing a test.

In either mode, test caller-observable outcomes through the public interface. Do not test private methods, internal calls, or side channels, and do not expose an internal seam merely for testing. Derive expected values from specs, worked examples, known literals, trusted external oracles, or invariants capable of disagreeing with the implementation—not by recomputing its logic.

Completion criterion: the mode, first behavior, public interface, seam, independent expected result, and tight command are explicit, with every required agreement obtained.

### 2. Prove one tracer bullet with Red

Choose one honest end-to-end behavior through the smallest agreed public interface. Write one focused behavior test, run the tightest command, and observe it fail for the missing or broken behavior—not because of a fixture, syntax, or environment failure. Do not write implementation-shaped tests or all tests before implementation.

Completion criterion: one vertical tracer bullet is Red for the intended reason and would pass only when the behavior exists.

### 3. Reach minimal Green

Implement only enough behavior to pass the current test; do not add speculative branches for later tests. Run the focused command, then nearby required checks.

Completion criterion: the current vertical slice is Green and no previously green focused test regressed.

### 4. Repeat one behavior at a time

Use what the previous slice taught you to select the next highest-value agreed behavior. Repeat Red then Green with one test and its minimum implementation before starting another. All-tests-first horizontal slicing is not this workflow.

Per cycle:

- [ ] test describes observable behavior at an agreed seam
- [ ] expectation has an independent source of truth
- [ ] test failed for the intended reason before implementation
- [ ] code is minimal for this slice
- [ ] focused tests are green

Completion criterion: every agreed behavior has completed its own Red and Green cycle and every checklist item holds.

### 5. Refactor only while green

With tests green, improve names; remove duplication; shorten long methods without coupling tests to private helpers; move feature-envying logic toward the data it uses; introduce value objects when primitive obsession obscures behavior; and address nearby existing code only when completed behavior exposes evidence. Use `codebase-design` to combine or deepen shallow modules. Run tests after each refactor step.

Keep the agreed public interface and seam stable. Before changing either, obtain user approval and load `codebase-design`.

Completion criterion: each refactor preserves behavior, its rerun stays green, and any interface or seam change has explicit approval.

### 6. Complete the work

Run the focused tests, nearby required checks, and broader required checks. Do not claim completion while any agreed behavior or required check is failing.

Completion criterion: all agreed behavior is green, refactoring preserved behavior, and focused, nearby, and broader required checks pass.

## Reference

- When examples are needed to distinguish caller-visible behavior tests, implementation coupling, or tautological expectations, load [tests.md](tests.md) for good/bad tests and independent-oracle examples.
- When behavior crosses an external dependency and a test adapter may be needed, load [mocking.md](mocking.md) to choose an external seam and narrow adapter without exposing internals.

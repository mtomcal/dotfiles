---
name: tdd
description: Test-driven development through vertical red-green-refactor tracer bullets at agreed seams. Use when implementing behavior or regression fixes test-first, when the user requests TDD or integration tests, or after diagnosis identifies a bug to lock down.
metadata:
  short-description: TDD with red-green-refactor tracer bullets
allowed-tools: read,write,bash,edit
---

# Test-Driven Development

Tests specify observable behavior through public interfaces. They should survive internal refactors. Read repository guidance, relevant specs, and the project glossary before naming behavior.

See [tests.md](tests.md) for examples, [mocking.md](mocking.md) for external seams, and [refactoring.md](refactoring.md) after green. Load `codebase-design` when choosing or changing a module interface, seam, or depth.

## Guardrails

- **Pre-agree seams.** Before writing tests, name the public interfaces where behavior will be observed and confirm them with the user. In an unambiguous discovered-bug path, state the existing seam and regression target, then proceed unless risk or ambiguity requires confirmation.
- **Behavior over implementation.** Test outcomes callers care about; avoid private methods, internal call assertions, and side-channel verification.
- **Independent expectations.** A tautological test recomputes the expected result using the implementation's own logic and cannot catch disagreement. Derive expected values from specs, worked examples, known literals, or another independent oracle.
- **Vertical slices.** One test, one minimal implementation, then repeat. Writing all tests before all code is horizontal slicing and commits to imagined behavior.
- **Green before refactor.** Refactoring remains part of this repo's red-green-refactor contract, but never refactor while red.

## Discovered bug fast path

When diagnosis reveals a bug the user already wants fixed, briefly state:

1. the observed bug
2. the intended behavior and its source
3. the existing seam and smallest regression target

Then enter the loop without a full planning interview unless behavior, seam, or risk is ambiguous.

## 1. Plan the first tracer bullet

Confirm the interface change, agreed test seams, and prioritized behaviors. Choose one end-to-end behavior through the smallest honest public interface. Do not plan implementation-shaped tests.

Completion criterion: the first behavior, seam, expected result, and command are explicit.

## 2. Red

Write one focused behavior test. Run the tightest command and observe the expected failure for the missing or broken behavior—not a fixture, syntax, or environment failure.

Completion criterion: the new test is red for the intended reason and would pass only when the behavior exists.

## 3. Green

Implement only enough behavior to pass the current test. Avoid speculative branches for later tests. Run the focused command, then any nearby required checks.

Completion criterion: the tracer bullet is green and no previously green focused test regressed.

## 4. Repeat vertically

Use what the previous slice taught you to choose the next highest-value behavior. Repeat Red then Green one test at a time until the agreed behaviors are covered.

Per cycle:

- [ ] test describes observable behavior at an agreed seam
- [ ] expectation has an independent source of truth
- [ ] test failed for the intended reason before implementation
- [ ] code is minimal for this slice
- [ ] focused tests are green

## 5. Refactor while green

Improve names, remove duplication, and deepen modules where the completed behavior reveals a better shape. Run tests after each refactor step. Keep the agreed interface stable unless the user approves a seam change.

Completion criterion: all agreed behavior is green, refactoring preserved behavior, and broader required checks pass.

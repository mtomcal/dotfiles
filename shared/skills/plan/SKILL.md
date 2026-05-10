---
name: plan
description: Produce a TDD implementation plan entirely in conversation context — no files written. Each slice is pre-formatted as directly-passable task text with full RED/GREEN/REFACTOR structure, file manifests, and risk-tier labels. Use when planning an implementation that will be executed slice-by-slice (by Pi, a sub-agent, or a human), or when you want a zero-artifact plan that hands off to /tree for execution.
metadata:
  short-description: Zero-artifact TDD plans with /tree handoff
---

# Plan

Produce a TDD implementation plan entirely in conversation context. No files are written — no `PLAN.md`, no `plan/` directory, no slice briefs. Every slice is pre-formatted task text ready to pass directly to an executor: Pi in the same conversation, a sub-agent, or a `/tree` execution branch.

## Quick Start

```
User: /plan — implement the session-persistence hook we grilled
Pi: identifies context engine, reads decisions, grills for gaps, produces plan in context, offers /tree handoff
```

## Process

1. **Identify context engine** — spec-driven, research-driven, decision-driven, or hybrid. Same taxonomy as `create-plan` (see that skill for the full table). State which engine applies and why.
2. **Gather context** — read specs, research, decisions, or grill outcomes; read current code. Surface the state of play.
3. **Grill to distill** — confirm intent, pin down implementation shape, surface edge cases. Use `grill-me` if the user hasn't already resolved key decisions.
4. **Produce plan in context** — output the structure below directly in the conversation. No files. Everything stays in context.
5. **Offer /tree handoff** — end with: `Ready to execute. Run /tree [branch-name] to fork an execution branch for these slices.`

## Plan Output Structure

Output directly in the conversation:

- **Goal** — one sentence, what this plan delivers
- **Constraints** — what NOT to change, guardrails, explicit non-goals
- **Implementation shape** — conceptual approach, where complexity lives, what stays simple
- **Slice breakdown** — numbered, dependency-ordered. Each slice uses the template below.
- **Verification sequence** — ordered commands to run when all slices are green (lint, typecheck, full suite, sub-agent passes like `test-quality-verifier`)

## Slice Template

Each slice is self-contained task text — passable as-is to an executor:

```
### Slice N: [Name]
Risk: routine | standard | tricky
Reviews: test | test,quality | test,quality,security
Depends on: [slice numbers or "none"]
Parallel: ["ok with slice N" or "serial only"]

Files:
- Create: path/to/test.file — [purpose]
- Modify: path/to/source.file — [what to change]
- Read: path/to/reference.file — [why]

RED — Write tests first, no implementation code yet
- Test file: path/to/test.file
- Expected tests: ~N–M
- What the test proves: [specific behavior]
- Assertion strategy: [deterministic / pure helper / state check]
- Existing tests to rewrite: [or "none"]
- Hard gate: run test suite, observe failure before proceeding

GREEN — Minimum change to pass, only after RED confirmed failing
- Source file: path/to/source.file
- What to change: [specific function/class/behavior]
- Constraint: [what NOT to do]

REFACTOR — Clean up while green
- [action or "none needed"]
```

### Risk Tiers

| Tier | Guardrail | Review gates |
|------|-----------|--------------|
| **routine** | Standard — straightforward, low blast radius | test |
| **standard** | Moderate — some complexity, multi-file | test, quality |
| **tricky** | Tight — subtle logic, high blast radius, or security-sensitive | test, quality, security |

Risk tier determines guardrail thresholds and review depth. Plan does **not** name models or providers — agent `.md` files handle routing at execution time.

### Parallelization

Default is serial (slices run in order). Mark a slice as parallelizable when its file set has zero overlap with another slice and neither depends on the other's output. Mark as "serial only" for foundation slices and chained dependencies.

## Anti-patterns

1. **Writing files** — plan produces no markdown files, no `plan/` directory, no slice briefs. Everything is in context.
2. **Naming models** — plan doesn't specify which model executes which slice. Agent `.md` files handle routing.
3. **Vague slices** — "Add tests for auth" is not a slice. Name the file, the assertion, the expected count.
4. **Combined RED/GREEN** — RED and GREEN must be separate. The hard gate (observe failure before proceeding) is the contract.
5. **Orphan slices** — every slice after the first must either depend on a prior slice or be explicitly marked parallel.

## References

- `create-plan` skill — full context engine taxonomy and RED/GREEN/REFACTOR slicing discipline
- `grill-me` skill — produces decision tables for decision-driven plans
- `test-quality-verifier` skill — sub-agent tool for post-green review passes

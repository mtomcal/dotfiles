---
name: ralph
description: Configure and run a loop.sh agentic loop job (PROMPT.md + IMPLEMENTATION_PLAN.md + ORCHESTRATOR.md).
metadata:
  short-description: Set up loop.sh iterative jobs
---

# Ralph (Loop Job Runner)

This skill sets up a simple iterative loop job where each iteration re-reads a prompt file, does one checklist item, commits, and stops. An optional orchestrator monitors progress and adds course corrections.

## Files

- `PROMPT.md`: concise instructions the worker reads every iteration (keep under ~20 lines).
- `IMPLEMENTATION_PLAN.md`: heavy reference (task order, checklist, discoveries, rules).
- `ORCHESTRATOR.md`: monitoring playbook (log review, git checks, when to intervene).

## Launch

Use `./loop.sh <iterations> <prompt_file>` (a generic template is included in `references/loop.sh`).

## PROMPT.md Rules of Thumb

- One checklist item per iteration.
- First line should reference the plan file by name.
- Put course corrections at the top under `IMPORTANT:` and tell the worker to read them first every iteration.
- Require the worker to update `IMPLEMENTATION_PLAN.md` (check items off, record discoveries).
- If test changes were made, require running `@test_quality_verifier` (or follow the test-quality-verifier skill) before finishing the iteration.
- Output `/done` exactly when complete.

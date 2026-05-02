---
name: create-slice-plan
description: Create a multi-model orchestration plan with TDD slices, per-slice briefs, and an orchestrator manifest. Designed for coordinating open-source or less capable models via Pi sub-agent delegation — a strong parent orchestrator delegates work to weaker sub-agents, monitors progress, and escalates when stuck. Use when planning implementation that will be executed by multiple sub-agents on different models, or when orchestrating open-source models like GLM, Kimi, and DeepSeek.
metadata:
  short-description: Create orchestrated multi-model TDD slice plans
---

# Create Slice Plan

Produce a `plan/` directory with an orchestrator manifest (README.md) and per-slice brief files. Each slice is a self-contained TDD cycle delegated to a sub-agent on a specific model. The orchestrator (parent agent) reads the manifest, delegates slices, monitors checklists, and escalates when sub-agents get stuck.

**Use `create-plan` for single capable agents (Claude, Codex). Use `create-slice-plan` for multi-model orchestration on Pi.**

## When to Use This Skill

- Planning work that will be executed by multiple sub-agents on different models
- Orchestrating open-source models that lose context or loop when working independently
- Any plan where you need model routing, review gates, and escalation strategies
- When you want durable state that survives sub-agent context resets

## Authoring Principles

The plan you write will be read by an orchestrator agent at execution time. That orchestrator will be a model like GLM, Kimi, or DeepSeek — capable but prone to:

1. **Implementing code itself** instead of delegating to sub-agents
2. **Skipping review** and marking slices done after implementation
3. **Using scout sub-agents** instead of delegating slice briefs as tasks
4. **Losing track of status** and re-doing work or skipping dependencies

To prevent these failures, your plan must include:

- **Explicit role assertion** in the README telling the orchestrator "YOU ARE AN ORCHESTRATOR, YOU DO NOT IMPLEMENT"
- **Mandatory status flow** showing `review → done` requires a review sub-agent call, not self-approval
- **Slice file paths** in the manifest table so the orchestrator knows exactly what to delegate
- **Anti-patterns section** in the README listing exactly what NOT to do
- **Inline context** in every slice brief so sub-agents don't need to scout

The [REFERENCE.md](REFERENCE.md) template embeds all of these guardrails. Use it as-is — don't strip the role assertion, status flow, or anti-patterns when writing your plan.

## Slice Sizing

A slice's Green section should have **no more than ~6 distinct implementation points** (individual "change X in file Y" items). If a slice has more than 6, split it. Oversized slices burn excessive sub-agent turns, create merge conflicts with parallel slices, and make review harder.

When writing the Green section, count the bullet points. If you see 8+ "change X in file Y" items, find a seam and split into two slices.

## Process

1. **Identify context engine** — spec-driven, research-driven, decision-driven, or hybrid (same taxonomy as `create-plan`)
2. **Gather context** — read specs, research, or decision outcomes; read current code
3. **Grill Phase 1: Scope and content** — what are we building, what slices, what TDD briefs, what dependency order. Use `grill-me` skill if needed.
4. **Grill Phase 2: Orchestration** — structural decisions (parallelization, risk tiers), then per-slice decisions (model assignment, review gates, providers, budget). All grill questions have **recommended defaults**.
5. **Write artifacts** — `plan/README.md` (from the REFERENCE.md template — keep all guardrails intact) and `plan/slices/001-*.md` through `plan/slices/N-*.md` (from the slice template)

## Grill Phase 2 — Orchestration Defaults

Every orchestration decision has a recommended default. Present defaults, let the user override.

**Structural decisions (holistic):**

| Decision | Default | Rationale |
|----------|---------|-----------|
| Parallelization | Default serial, opt-in parallel | Conservative for weak models |
| Dependency ordering | Follow slice number order | Slices ordered by dependency during Phase 1 |
| Risk tiers | routine / standard / tricky | Three tiers, batch similar-risk slices |

**Per-slice decisions (batched by risk tier):**

| Decision | routine | standard | tricky |
|----------|---------|----------|--------|
| Implementation model | minimax-m2.7 medium | minimax-m2.7 medium | glm-5.1 high |
| Implementation provider | ollama-cloud | ollama-cloud | opencode-go |
| Review model | deepseek-v4-pro high | deepseek-v4-pro high | deepseek-v4-pro high |
| Review provider | opencode-go | opencode-go | opencode-go |
| Review gates | test | test, quality | test, quality, security |
| Escalation retries | 2 | 2 | 3 |

**Budget decisions (grilled):**

| Decision | Default |
|----------|---------|
| Provider preference | ollama-cloud for implementation, ollama-cloud for review |
| Provider fallback | openrouter for slow providers, same model |
| Budget strategy | Prefer cheapest provider per model; fall back to alternatives if slow |

See [REFERENCE.md](REFERENCE.md) for the full README template, slice file template, escalation protocol, and anti-patterns.
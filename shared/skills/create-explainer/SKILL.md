---
name: create-explainer
description: Creates interactive, codebase-accurate HTML explainers for any concept in a software project. Asks the engineer about experience level and specialty to tailor analogies, depth, and code density. Includes a mandatory reviewer pass that independently discovers source files to verify factual claims. Use when the user wants to understand how a system or feature works across code boundaries, create onboarding docs, build interactive learning materials, or explain a complex flow to a teammate.
---

# create-explainer

Build an interactive HTML explainer that teaches any concept in the current codebase — from frontend input through backend logic and back. The output is a self-contained explainer served locally via `python3 -m http.server`.

## Quick start

1. Ask the user: **"What concept should I explain?"**
2. Run the [intake interview](REFERENCE.md#intake-interview) to determine persona and scope.
3. Present proposed scope and pause for **one human checkpoint**.
4. Execute the [9-step workflow](REFERENCE.md#workflow) autonomously.
5. Use [lab templates](lab/README.md) for interactive components instead of writing from scratch.
6. For large Full Lab explainers (10+ sections, multiple labs), [delegate drafting to sub-agents](REFERENCE.md#delegating-drafting-to-sub-agents-full-lab-only-optional) in parallel to reduce wall-clock time.
7. Open the served URL in a browser to verify it renders.

Delegation is described in abstract terms — adapt to whatever sub-agent mechanism your environment provides. The key invariant: **you write the shell + CSS + navigation, delegate sections and labs, merge results, then run a single reviewer pass at the end.**

## Output tiers

| Tier | Time budget | What you get |
|------|-------------|-------------|
| **Condensed** | ≤ 5 min | Static single-page reference with diagrams, key messages, and file map. No interactivity. |
| **Guided** | ≤ 15 min | Static doc + one interactive simulation (e.g., toggleable state machine). |
| **Full Lab** | > 15 min (default) | Static doc + interactive simulations + quizzes + architecture map + concept graph builder. |

The skill defaults to **Full Lab** unless the user explicitly requests less.

## Core principles

- **Source-first**: Read actual code and specs before writing claims. Never invent gate logic, message fields, or file paths.
- **Persona-adaptive**: Match analogies, terminology depth, and code snippet density to the engineer's experience level and specialty. See [persona mapping](REFERENCE.md#persona-mapping).
- **Cross-language explainers**: When the user knows language A but the codebase uses language B, generate side-by-side code comparisons (split-code blocks) throughout. Include a syntax reference section. See [cross-language patterns](REFERENCE.md#cross-language-explainers).
- **Server-authoritative mindset**: Teach *why* the architecture works the way it does, not just *what* happens. Every explainer answers: "Who owns the truth for each piece of state?"
- **Self-contained**: Single `index.html` for static tiers. `index.html` + `main.js` for interactive tiers. No build step, no external dependencies except a local server.
- **Reuse lab templates**: The `lab/` folder contains 8 working, copy-pasteable interactive components. Use them instead of writing interactivity from scratch.
- **Full-width layout for code-heavy explainers**: Use `max-width: 1400px` (not 960px) when the explainer has extensive code blocks or side-by-side comparisons. Keep `padding: 0 32px` and collapse to 16px on mobile.
- **Validate with Playwright before serving**: After drafting, take screenshots at the designed viewport and at 700px mobile width. Verify code blocks don't overflow and interactive elements render. Store all screenshots and generated files in `/tmp/` or another temporary directory — never in the project root or explainer folder.

## Reviewer pass (mandatory)

After drafting, always delegate a reviewer sub-agent with:
- The full explainer content
- Access to read source files independently
- Instructions to flag any claim that doesn't match reality

Address every finding before serving. Never skip this step. For large explainers, split review across multiple sub-agents (syntax reviewer, architecture reviewer, code accuracy reviewer, interactive lab reviewer), each receiving only their sections plus a claim checklist.

## Serving

```bash
cd /path/to/explainer && python3 -m http.server 3456 --bind 0.0.0.0
```

Present the URL (e.g., `http://localhost:3456/` or the machine's public URL) to the user.

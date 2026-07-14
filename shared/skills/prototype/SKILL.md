---
name: prototype
description: Build a throwaway prototype to flesh out a design before committing to it. Routes between two branches — a runnable terminal app for state/business-logic questions, or several radically different UI variations toggleable from one route. Use when the user wants to prototype, sanity-check a data model or state machine, mock up a UI, explore design options, or says "prototype this", "let me play with it", "try a few designs".
metadata:
  short-description: Build throwaway prototypes
allowed-tools: read,write,edit,bash
---

# Prototype

## Language Definitions

- **Prototype** — throwaway reaction surface answering one design question.
- **Logic prototype** — small terminal artifact testing state or business rules.
- **UI variant** — one intentionally distinct visual approach presented alongside alternatives.
- **Durable answer** — retained question, verdict, evidence, and implications.
- **Absorb** — deliberately promote useful code through normal production implementation and verification; prototype code remains throwaway by default.

## Workflow

### 1. Route by the question

Identify the question from the prompt or surrounding code, asking the user when available:

- For “Does this logic or state model feel right?”, choose the logic branch for an interactive terminal app that exercises business rules, state transitions, or data shape.
- For “What should this look like?”, choose the UI branch for several radically different visual approaches on one route.

Load only the selected branch document from Reference before building. If the question remains genuinely ambiguous and the user is unavailable, infer from surrounding code—backend module means logic; page or component means UI—and state that assumption at the top of the prototype. The branch is selected only when its question and any inferred assumption are explicit.

### 2. Build a runnable reaction surface

Apply these rules while executing the selected branch:

1. Mark the code as a prototype and locate it near the module or page it explores. Follow existing routing conventions rather than inventing a top-level structure.
2. Add or document and report one exact run command supported by the host project's existing task runner or runtime. Do not introduce a package manager or runtime only for the prototype.
3. Keep state in memory by default. If persistence is the question, use a scratch database or a disposable local file clearly named `PROTOTYPE — wipe me`, never the production database.
4. Optimize for learning: one question, no tests, no speculative generalization, no production polish, and no error handling or abstraction beyond what makes the prototype runnable.
5. Surface the full relevant state after every logic action or UI variant switch.

This step is complete when the reported command runs the selected branch and the user can observe the relevant state while testing the stated question.

### 3. Capture the answer and clean up

Before cleanup, record the durable answer in an artifact the repository already uses, such as a spec, plan, issue, decision note, or resulting implementation. It must identify the question, verdict, evidence, and implications.

Delete the prototype by default. Absorb useful code only as a deliberate production implementation that receives the repository's normal verification; neither a selected UI variant nor portable pure logic is production-ready merely because the prototype validated its idea.

Preserve source code on a clearly named throwaway branch only when it contains primary evidence that prose, screenshots, or the resulting implementation cannot adequately retain. Keep that branch outside the main line and place a durable pointer to it in the owning artifact. Completion requires a durable answer and no unowned prototype code left on the main line.

## Reference

- For state, business-rule, data-shape, or API-feel questions, load [LOGIC.md](LOGIC.md) to build and hand over the one-command terminal reaction surface.
- For appearance, layout, or visual-design questions, load [UI.md](UI.md) to build, compare, and retire the routed UI variants.

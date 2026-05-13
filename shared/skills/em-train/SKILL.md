---
name: em-train
description: Acts as an engineering manager to help you build fluency in a codebase's language and ecosystem. Interviews you about what the project needs, right-sizes a ticket to your skill level, generates a brief, creates a training branch, reviews your work via real CI, and produces a summary report. Use when you want to learn a new language/framework by doing real work on a real codebase, prepare for interviews, or build hands-on fluency through structured TDD tasks.
---

# EM Train — Engineering Manager Training Skill

## Quick start

1. **Start a session**: "I want to work on something in this codebase."
2. **Intake**: EM runs the intake interview (borrowed from `create-explainer`) to gauge your level.
3. **Explore + scope**: EM reads roadmap/specs/git log, discusses what to build, right-sizes the ticket.
4. **Ticket generated**: Story context + acceptance criteria + `create-explainer` brief.
5. **Setup**: Auto-creates branch `train/<skill>/<ticket-slug>`, drops a temp guidance skill, switches to branch.
6. **You work**: Use the temp guidance skill for API/language questions. Never ask it for the answer.
7. **Review**: Come back. EM runs CI, delegates to review subagents, curates top 2-3 feedback items.
8. **Iterate**: Fix feedback. Max 2 rounds. EM re-verifies.
9. **Cleanup**: Summary report (what you learned, next steps). Temp skill removed. Branch stays.

## Core principles

- **You learn by doing, not by being told.** The guidance skill never gives you the answer — it teaches you how to find it.
- **Right-size, don't ladder.** No fixed difficulty tiers. The EM scopes the *next meaningful slice* of real project work to your current ability.
- **Real CI, real feedback.** Reviews run actual tests. No rubber stamps.
- **Honor system.** You choose to learn. Gaming it only hurts you.

## Workflows

See [REFERENCE.md](REFERENCE.md) for detailed workflows:

- [Intake interview](REFERENCE.md#intake-interview)
- [Ticket generation](REFERENCE.md#ticket-generation)
- [Setup phase](REFERENCE.md#setup-phase)
- [Review phase](REFERENCE.md#review-phase)
- [Cleanup phase](REFERENCE.md#cleanup-phase)
- [Temp guidance skill template](REFERENCE.md#temp-guidance-skill-template)

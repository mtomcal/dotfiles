---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Loads the ubiquitous language glossary (UBIQUITOUS_LANGUAGE.md) when available to ask questions using the project's bounded-context domain terms. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead.

## Pre-Grilling: Load the Ubiquitous Language

Before asking the first question:

1. Check for `UBIQUITOUS_LANGUAGE.md` in the working directory.
2. If it exists: read it and internalize the glossary — canonical terms, aliases to avoid, relationships, and flagged ambiguities.
3. If it does NOT exist: note that running `/ubiquitous-language` first would ground the grilling in the project's domain terms, then proceed with generic language.

## Term-Aware Questioning

When the glossary is loaded:

- **Use canonical terms** in every question. Bold them to match the glossary's visual convention.
- **Surface boundary tensions** between related concepts. Ask questions that probe the edges where one term meets another — cardinality, lifecycle coupling, preconditions.
- **Correct synonyms gently.** When the user uses an alias from the "Aliases to avoid" column, respond with:
  > "You said 'alias' — I think you mean **CanonicalTerm** (as defined in the ubiquitous language). Let me re-ask using that: [question restated with the canonical term]"

## Flagging New Terms

If a domain term emerges in the conversation that does NOT appear in the glossary:

> ⚠️ Term candidate: "**NewTerm**" — this isn't in the ubiquitous language. Should it be? I'm tracking it for a later `/ubiquitous-language` update.

If a canonical definition appears to shift during the discussion, flag that too:

> ⚠️ Definition drift: "**CanonicalTerm**" is currently defined as "[definition]". Your usage suggests it also includes "[new behavior]". Should the glossary definition be expanded?

## Post-Grilling Summary

After the decision tree is exhausted, offer a summary of:

- **Resolved tensions** — which boundary questions were settled and how
- **New term candidates** — domain terms that emerged and should be added to the glossary
- **Definition updates** — canonical terms whose meaning shifted during the discussion

Present these as inputs ready for `/ubiquitous-language` to consume and update `UBIQUITOUS_LANGUAGE.md`.

---
name: ubiquitous-language
description: Extract a DDD-style ubiquitous language glossary from the current conversation, proposals, plans, documentation, or brownfield domain language, flagging ambiguities and proposing canonical terms. Writes the repository's canonical root glossary. Use when users want to define domain terms, build a glossary, harden terminology, create or update ubiquitous language, refine project vocabulary, extract bounded-context terms from brownfield systems, or discuss a domain model or DDD.
metadata:
  short-description: Extract DDD glossary from conversation
allowed-tools: read,write,edit,bash
---

# Ubiquitous Language

## Language Definitions

- **Ubiquitous language** — shared vocabulary used consistently by humans, specs, and implementation in an applicable context.
- **Bounded context** — scope where a term has one authoritative meaning.
- **Canonical term** — preferred name for one concept in that context.
- **Alias to avoid** — synonym or shorthand obscuring the canonical distinction.
- **Flagged ambiguity** — unresolved collision, overload, or boundary question recorded explicitly.

## Workflow

Use this workflow to create a glossary or update its terminology as understanding evolves.

### 1. Route mode and canonical location

Choose **create** when no applicable glossary exists and **update** when refining, rerunning, or adding evidence to an existing glossary. Resolve one canonical path before gathering terms or writing:

1. Use the glossary path declared by repository guidance or the applicable spec suite.
2. Otherwise, use the existing glossary for the requested bounded context.
3. Otherwise, follow the repository's established documentation or spec convention.
4. Only when no authority, applicable glossary, or convention exists, create `UBIQUITOUS-LANGUAGE.md` at the repository root.

If multiple locations remain plausibly authoritative, ask the user which bounded context and glossary owns the terms; do not create a competing file. In update mode, read the complete canonical glossary before proceeding.

Completion criterion: create/update mode, applicable bounded context, and exactly one authoritative artifact path are known.

### 2. Gather domain evidence

Scan the current conversation, relevant proposals, plans, and documentation, and brownfield system evidence such as domain-facing source and tests. Extract domain-relevant nouns, verbs, and concepts, then identify:

- one word used for different concepts;
- different words used for the same concept;
- vague or overloaded terms; and
- meanings that differ across bounded contexts.

Include module, class, or other implementation names only when they carry domain meaning. Exclude generic programming concepts such as arrays, functions, or endpoints unless the domain gives them a specific meaning.

Completion criterion: every candidate is grounded in available evidence, and each synonym, overload, or context collision is identified rather than silently normalized.

### 3. Propose canonical language

Make opinionated choices: select the best canonical term and list competing synonyms or shorthand as aliases to avoid. Keep each definition to one sentence that says what the concept **is**, not merely what it does. Do not force one meaning across bounded contexts.

Record unresolved conflicts as flagged ambiguities with a clear recommended distinction instead of presenting them as settled. Identify relationships among canonical terms and express cardinality where evidence supports it.

Completion criterion: every included term has one proposed meaning in its context, aliases are explicit, relationships are evidenced, and unresolved choices remain visibly flagged.

### 4. Write or merge the glossary

For a new artifact, use this compact schema:

```md
# Ubiquitous Language

## <Natural term group>

| Term | Definition | Aliases to avoid |
|------|------------|------------------|
| **<Canonical term>** | <One-sentence definition of what it is> | <Synonyms or shorthand> |

## Relationships

- A **<Term>** relates to one or more **<Other terms>**.

## Example dialogue

> **Dev:** "<Question using canonical terms>"
> **Domain expert:** "<Answer clarifying a relationship or boundary>"
> <Continue for 3–5 exchanges.>

## Flagged ambiguities

- "<ambiguous wording>" was used for <conflicting meanings> — <recommended distinction>.
```

Create multiple term tables only when natural subdomains, lifecycles, or actor groups emerge, with each group under its own heading; use one table for a cohesive domain rather than forcing groups. Use bold canonical terms in relationships and include cardinality where evident. Write a 3–5-exchange developer/domain-expert dialogue that uses the terms naturally and clarifies boundaries. Keep `Flagged ambiguities`; state `None` when no ambiguity remains.

In update mode, preserve the canonical artifact's established preamble, table shape, and project-owned fields. Merge new evidence without dropping unrelated accepted terms or groups, revise definitions whose meaning evolved, rewrite the dialogue to incorporate new terms or relationships, and add or re-flag unresolved ambiguities.

Completion criterion: the saved artifact follows its authoritative form, contains grouped terms, relationships, one example dialogue, and explicit ambiguity status, and preserves unrelated accepted content during updates.

### 5. Verify and report

Reread the complete saved glossary. Confirm terms are domain-relevant, definitions are one sentence, canonical choices and aliases are consistent, relationships match the evidence, the dialogue demonstrates the vocabulary, and every known conflict is explicit.

Report the exact artifact path, create/update mode, principal canonical choices, and unresolved flagged ambiguities in a concise conversational summary.

Completion criterion: the artifact is internally consistent and the final response identifies what changed, where it was written, and what remains unresolved.

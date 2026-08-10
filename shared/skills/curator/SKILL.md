---
name: curator
description: Curate durable agent improvements from a human retrospective, current session, recent history, git activity, skills, docs, specs, and plans. Use when the user runs /curator, asks what should be learned from a session, wants compounding engineering recommendations, asks to steer recommendations with a retrospective, or asks whether to add, update, remove, rename, refactor, or consolidate skills or docs.
metadata:
  short-description: Curate compounding agent improvements
allowed-tools:
  - read
  - bash
  - grep
  - ls
  - find
---

# Curator

## Language Definitions

- **Durable agent state** — persistent artifact capable of changing future agent behavior.
- **Human-steered evidence** — retrospective/priority directing investigation but corroborated where practical.
- **Tentative approval** — preliminary acceptance that does not authorize writes.
- **Runtime availability** — whether the intended agent discovers and loads an artifact in a future session.
- **Stuck moment** — best-evidenced point of highest friction.

## Workflow

Curator is a human-steered router and ranker, not an autonomous writer. Use one workflow to gather evidence, rank durable improvements, obtain one final approval, apply only the approved edits, and report their availability and repository state.

### 1. Route retrospective intake and presentation mode

If the user already supplied retrospective context, acknowledge it and do not ask again. Otherwise invite this optional input before scanning:

```md
Before I scan evidence, share any retrospective notes you want curator to consider:
- what felt inefficient, brittle, or surprising
- what worked well and should be preserved
- what you want future agents to know or do differently
- any areas you do not want changed

You can also say `skip retrospective`.
```

Treat a skip as neutral. Treat supplied priorities as human-steered evidence: use them to focus inspection and ranking, corroborate them where practical, label uncorroborated steering honestly, and surface conflicts with local evidence rather than silently choosing. Respect every stated boundary on files, repositories, private history, skills, or recommendation types.

Select one-at-a-time sequential presentation by default. Select full-summary mode only when the user explicitly asks for the full list, all recommendations at once, or a ranked summary.

Completion criterion: retrospective status, explicit boundaries, and presentation mode are known before local evidence is inspected.

### 2. Scan bounded evidence

Detect the active agent before reading agent-specific history or runtime state. If detection is ambiguous, record that and inspect only clearly relevant sources. Before proposing, inspect the approved scope for current context, recent Git evidence, available skills, durable docs/specs/plans, active-agent history when available, runtime discovery, stale guidance, machine/visual cross-evidence mismatches, and the hardest stall. When logs, tests, schemas, or structured events pass but video, screenshots, or direct inspection show different causality, preserve the disagreement and return the conflicting evidence to the caller or human without inventing acceptance. In a Git repository, start with `git status --short` and classify owned, unrelated, generated, and tool-owned changes before ranking. Do not expose private transcript text, secrets, credentials, or unrelated project details.

Completion criterion: the evidence ledger accounts for every mandatory surface, active-agent ambiguity and unavailable evidence are disclosed, cross-evidence mismatches are preserved or absent, the hardest stall is identified or explicitly absent, and protected worktree state is classified before ranking.

### 3. Rank 3–5 durable recommendations

For every ranking pass, use the owner routes, evidence labels, and quality filters defined in this step. Build exactly 3–5 recommendations internally, ranked by expected compound value and efficiency gain rather than confidence. Prefer updating, delegating to, consolidating, renaming, removing, archiving, or refactoring existing durable state when it already owns the learning. Route to the smallest durable owner: project-local skills/docs/`AGENTS.md` for repo-specific learning, shared skills only for cross-repository behavior, existing skills before new skills, proposals or glossaries for durable intent and terminology, frontmatter or runtime-availability repair for discovery failures, and removal/archive/consolidation/rename/refactor when current state slows future agents. When a narrow follow-up owner applies, use it (`write-a-skill`, `audit-shared-skills`, `create-agents-md`, `ubiquitous-language`, `proposal-first`, `create-engineering-plan`, `execute-engineering-molecule`, `grill-me`, or `test-quality-verifier`) while Curator retains recommendation scope, human gates, target, acceptance, and final reporting. Always consider at least one independently useful new-skill candidate; recommend it only if no existing owner should absorb it, otherwise explicitly account for why it did not rank. Reject or down-rank one-off trivia, duplicate guidance, contradicted evidence, missing future triggers, missing runtime paths, and changes whose maintenance cost exceeds their value.

Use evidence honestly:
- Human-steered, pattern-backed, correction-backed, discovery-backed, premortem-backed, or speculative.
- State the action, target, owner route, concise evidence signal, why now, future trigger, expected compound value, expected efficiency gain, confidence, maintenance burden, duplication/staleness risk, and runtime consequence when applicable.

Completion criterion: 3–5 self-contained recommendations are ranked, the strongest new-skill candidate is accounted for, and each item names evidence, future trigger, target, owner, and availability impact.

### 4. Present and collect tentative decisions

In sequential mode, show only the next highest-ranked active recommendation with approximate progress and concise approve, skip, edit, rerank, or stop choices:

```md
Recommendation N of M (~X% through)

Decision: <short recommendation title>

Why this matters:
<1–2 short sentences focused on the outcome>

What would change:
- <concrete artifact or behavior>
- <concrete artifact or behavior>

Your choices:
- Approve
- Skip
- Edit: <change>
- Rerank remaining
- Stop

Evidence:
<brief supporting details, after the decision>
```

Use full-summary mode only when the user explicitly asks for the complete ranked set. Keep decisions recommendation-first and evidence-light enough to review. In full-summary mode, every recommendation must still name the action, target, owner route, future trigger, evidence signal, value/efficiency/confidence, maintenance burden, duplication or staleness risk, and runtime consequence. For removal, consolidation, rename, or refactor proposals, also state the replacement or source of truth, risk if kept, risk if changed, rollback path, and migration notes. End the summary with practical tentative selection shortcuts such as approving all high-value items, approving specific numbers, converting one item to a different owner, skipping and reranking, or approving one as a draft; none of these shortcuts authorizes a write.

Every approval, including terse, repeated, multi-item, or full-summary approval, is tentative. It may change the active set but cannot authorize a write. Track the tentative set visibly, apply edits or reranking only to the proposal set, and continue until all active items are reviewed or the user stops.

Completion criterion: review has stopped without writes, or every active recommendation has an explicit tentative disposition and the complete tentative approval set is visible.

### 5. Obtain one final approval

If no recommendation is tentatively approved, report that nothing will be written and stop. Otherwise show the tentative approval list once and ask for one final confirmation covering the complete approved edit set. Include commit and push choices only for affected Git repositories, and name repositories separately when more than one would be changed.

```md
Ready for final confirmation:
- `Apply approved recommendations`
- `Apply and commit approved recommendations`
- `Apply, commit, and push approved recommendations`
- `Revise before applying: <change>`
- `Cancel without applying`

Tentatively approved:
- <approved item>
- <approved item>

Advice for Next Time:
<one short ephemeral paragraph, or one line saying no meaningful stall occurred>
```

A tentative approval never substitutes for this final confirmation. If the bounded scan found a meaningful stall, ground it in repeated failures, corrections, loops, explicit stuck statements, or a late invalidating assumption before writing `Advice for Next Time:`. Classify cheaper causes first: missing assumptions or context; skipped worked examples, prior slices, or sharp specs; stronger oracle availability such as tests, builds, or measurable checks; whether the work needed smaller independently checked done-states; and whether it was a structural cliff such as a migration or conversion with no valid halfway state. Only after those checks, frame the advice as a capability ceiling, decomposition problem, or dated set-down reason. Shape the one advisory paragraph to the evidence: oracle plus large task means smaller machine-checked pieces; oracle plus structural cliff means one deliberate hand-driven change; no oracle means a cheap human judgment loop; cheaper cause found means name the missing context or skipped example/spec. Keep the advice ephemeral: show it once, never rank it, ask approval for it, convert it into a recommendation, or write it to durable state. If no meaningful stall occurred, say so in one line.

Completion criterion: the user either cancels with no writes or gives one explicit final approval whose exact recommendations, repositories, and apply/commit/push authority are known.

### 6. Apply only approved edits, verify, and report

Change only the artifacts and actions included in the final approval. When a follow-up has a relevant owner skill, load that skill and compose its process; Curator retains recommendation scope, artifact targets, user gates, acceptance, and final reporting. If required editing or delivery tools are unavailable, report the blocked action instead of weakening approval or claiming it ran.

Preserve all unrelated, generated, and tool-owned state. For every changed skill, command, wrapper, symlink, agent config, or other runtime-loaded artifact, verify runtime availability for the intended agent and state whether a restart, registration, install hook, or unresolved fix remains. Commit or push only when the final approval included that action.

Report the exact files changed, owner workflows used, runtime-availability results, commit/push results when authorized, unresolved concerns, and whether each affected repository is clean or still dirty. Distinguish approved changes from pre-existing or protected changes.

Completion criterion: every write maps to the final approved set, runtime-loaded artifacts have availability evidence, protected state remains untouched, and repository state is reported without claiming unperformed actions.

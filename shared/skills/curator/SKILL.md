---
name: curator
description: Curate durable agent improvements from the current session, recent history, git activity, skills, docs, specs, and plans. Use when the user runs /curator, asks what should be learned from a session, wants compounding engineering recommendations, or asks whether to add, update, remove, rename, refactor, or consolidate skills or docs.
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

Curator turns session evidence into a ranked, human-approved proposal for improving durable agent state. It is a router and ranker, not an autonomous writer.

## Operating Rules

- Produce a ranked proposal only. Do not edit files until the user approves specific recommendations.
- Always produce 3-5 recommendations, ranked by expected compound value and efficiency gain.
- Prefer updating, delegating to, consolidating, renaming, or removing existing durable state before creating something new.
- Treat the existing skill ecosystem as first-class evidence and routing infrastructure.
- Include improvements to `curator` itself when the session reveals a reusable improvement to evidence scanning, ranking, routing, approval phrases, privacy handling, or dead-weight detection.
- Do not overfit `curator` to one session. Self-improvement recommendations need a clear future trigger or repeated failure mode.
- Minimize sensitive details from history. Summarize patterns instead of quoting private user text, secrets, credentials, or unrelated project details.

## Evidence Scan

Before proposing, inspect enough local context to avoid duplicate or low-value recommendations.

1. Identify the active agent:
   - Codex: current Codex runtime, `$CODEX_HOME`, `~/.codex/`, Codex session/history files.
   - Pi: `~/.pi/`, `pi/skills/`, Pi runtime markers, Pi session or extension-owned state.
   - Claude: `~/.claude/`, `.claude/`, Claude transcript/history conventions.
   - Gemini: `~/.gemini/`, Gemini transcript/history conventions.
   - If detection is ambiguous, say so in the evidence ledger and inspect only clearly relevant sources.
2. Inspect the current context window for:
   - user corrections
   - failed commands, tests, reviews, or assumptions
   - discovered unknown unknowns
   - repeated friction or inefficiency
   - successful workflow patterns worth preserving
3. Inspect recent git history and current diff for repeated fixes, churn, abandoned plans, duplicated docs, or missing review gates.
4. Inventory available skills before proposing any skill work. Prefer existing skill updates or delegation paths over new skills.
5. Inspect durable project context when present: `AGENTS.md`, specs, ubiquitous language, README files, plans, TODOs, and local skill directories.
6. Inspect active-agent session history by default when available. Summarize only patterns and counts.
7. For recommendations that add or change skills, commands, wrappers, symlinks, agent configs, or other runtime-loaded artifacts, inspect how the active agent discovers that artifact and whether it will be available in the next session.

## Recommendation Types

Recommendations may add, update, consolidate, remove, archive, rename, or refactor durable state.

Use this targeting hierarchy:

1. Project-local skill, local docs, or repo `AGENTS.md` when the learning is codebase-specific.
2. Shared/global skill when the learning generalizes across repositories.
3. Existing skill update before new skill creation.
4. Spec or glossary update when the learning changes domain language or behavioral contracts.
5. Skill frontmatter tuning when an existing skill should have triggered but likely did not because its `description`, `Use when` phrase, `metadata.short-description`, name, or tool hints were unclear.
6. Runtime availability fixes when durable state exists in the repo but will not be loaded by the intended agent because of missing symlinks, wrappers, config registration, install hooks, or session restart requirements.
7. Removal, archival, consolidation, rename, or refactor when existing durable state slows future agents down.
8. No durable capture only when the evidence is one-off, vague, contradicted by existing guidance, or lacks a future trigger.

## Skill Ecosystem Routing

Every recommendation must consider whether another skill should perform the approved follow-up.

Common routing:

- `write-a-skill` or `skill-creator`: create or materially rewrite a skill.
- `audit-shared-skills`: audit or repair shared skill frontmatter and cross-agent compatibility.
- `create-agents-md`: update `AGENTS.md` or codebase maps.
- `ubiquitous-language`: add or refine domain terms.
- `create-plan`: turn an approved change into a testable implementation plan.
- `grill-me`: resolve open design questions before making durable changes.
- `test-quality-verifier`: improve vague tests or validation coverage.

If proposing a new skill, explain why no existing skill should absorb the learning.

If the session reveals that a relevant skill was available but was not selected, consider that a skill ecosystem defect. Prefer a frontmatter or description update over creating a new skill when the missed trigger is caused by vague naming, missing keywords, weak "Use when" guidance, absent `metadata.short-description`, or misleading `allowed-tools`.

## Ranking Model

Rank by expected compound value and efficiency gain, not confidence.

Consider:

- future time saved
- failure prevention value
- reuse breadth
- likelihood the trigger recurs
- artifact smallness
- clarity improvement
- maintenance burden
- staleness risk
- duplication risk
- privacy or safety risk

Evidence types:

- Pattern-backed: repeated across context, history, git, or sessions.
- Correction-backed: explicit user correction or validation failure.
- Discovery-backed: newly found unknown unknown with a clear future trigger.
- Premortem-backed: inferred future bottleneck from the success path.
- Speculative: weak signal; include only when needed to reach 3 recommendations, and label clearly.

## Proposal Format

Use this structure:

```md
# Curator Proposal

## Evidence Ledger

- Current context: inspected
- Active agent: <detected agent or ambiguous>
- Agent history: <source and approximate count, or unavailable>
- Git history: <range inspected>
- Current diff: <inspected/unavailable>
- Skills inventory: <count or scope inspected>
- Durable docs/specs/plans: <scope inspected>

## Ranked Recommendations

### 1. <action-oriented title>

Action: Add | Update | Consolidate | Remove | Archive | Rename | Refactor | Monitor
Target artifact: <path or artifact type>
Follow-up skill: <skill name or "none">
Expected compound value: High | Medium | Low
Expected efficiency gain: High | Medium | Low
Confidence: High | Medium | Low
Evidence type: Pattern-backed | Correction-backed | Discovery-backed | Premortem-backed | Speculative
Evidence: <brief pattern summary, not sensitive transcript text>
Why now: <why this should be handled now>
Future trigger: <when this durable state will help>
Maintenance burden: High | Medium | Low
Duplication/staleness risk: High | Medium | Low
Recommended action: <specific next step>
Approval phrase: `Apply recommendation 1`
Alternate approvals: `Apply 1 as project-local`, `Apply 1 globally`, `Skip 1 and rerank`
```

For removal/archive/consolidation recommendations, also include:

```md
Replacement/source of truth:
Risk if kept:
Risk if removed:
Rollback path:
```

For skill rename/refactor recommendations, also include:

```md
Current skill:
Proposed skill shape:
Migration notes:
```

End with approval shortcuts:

```md
Approval shortcuts:
- `Apply all high-value recommendations`
- `Apply recommendations 1, 3, and 4`
- `Apply 2 only as a draft`
- `Convert 3 into an AGENTS.md update`
- `Skip 1 and rerank`
```

## Quality Bar

Reject or down-rank recommendations that:

- duplicate existing guidance
- lack a clear future trigger
- preserve local trivia as global policy
- add broad instructions where a small test, spec, or checklist would work better
- make skill selection harder
- create or update durable state without a path for the intended agent to load it
- increase maintenance burden more than they save future work

When forced to produce 3-5 recommendations from weak evidence, label low-confidence or monitor-only items honestly.

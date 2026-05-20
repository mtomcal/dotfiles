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

- Produce a ranked proposal internally, but present recommendations to the user one at a time by default. Do not dump the full ranked list unless the user explicitly asks for the full list, summary, or all recommendations at once.
- Do not edit files until the user has reviewed recommendations and gives final confirmation to apply the tentative approvals.
- Always produce 3-5 recommendations, ranked by expected compound value and efficiency gain.
- Prefer updating, delegating to, consolidating, renaming, or removing existing durable state before creating something new.
- Treat the existing skill ecosystem as first-class evidence and routing infrastructure.
- Include improvements to `curator` itself when the session reveals a reusable improvement to evidence scanning, ranking, routing, approval phrases, privacy handling, or dead-weight detection.
- Always consider at least one new-skill candidate during ranking. Recommend it only if it clears the quality bar; otherwise note briefly that no new skill was recommended and why existing durable state is the better target.
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
8. When the session includes extracting a prototype, archived app, demo, or standalone repo from another codebase, check whether durable guidance should capture the extraction boundary and runtime verification lessons:
   - the source artifact and extracted repository should have a clear source-of-truth relationship
   - generated artifacts and tool-owned browser artifacts should be ignored
   - a build should be paired with a browser smoke check when a UI can build while rendering blank
   - optional secret-backed integrations should fail gracefully without local secrets
   - private repo creation and push status should be verified when publication is part of the task

## Worktree Triage

When the current directory is inside a git repository, inspect `git status --short` before proposing and include a concise worktree triage in the evidence ledger.

If `git status --short` shows a newly created durable artifact as untracked, for example `?? AGENTS.md`, `?? DESIGN.md`, `?? SKILL.md`, `?? README.md`, specs, plans, or docs, inspect the file directly with `sed`/`cat`/`grep`. Do not rely on `git diff -- <file>` for untracked files; it will be empty unless invoked with special options.

Classify visible changes as:

- **Owned changes**: files changed by the current curator-approved work.
- **Unrelated changes**: files changed before curator or outside the approved recommendations.
- **Generated artifacts**: build outputs, explainers, screenshots, caches, reports, or temporary files.
- **Tool-owned artifacts**: agent runtime folders such as `.pi/`, `.playwright-*`, or session/log outputs.

Do not modify, stage, delete, or normalize unrelated changes, generated artifacts, or tool-owned artifacts unless the user explicitly approves that cleanup. If a recommendation could affect those files, call out the risk in the recommendation.

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

If not proposing any new skill, explicitly account for the strongest new-skill candidate considered and why it did not beat updating, consolidating, or routing to existing durable state.

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

## Default Sequential Proposal Format

After the evidence scan, build a ranked set of 3-5 recommendations internally. The first user-facing proposal must be the highest-ranked recommendation only, using this concise format:

```md
Recommendation N of M (~X% through)

Decision: <short recommendation title>

Why this matters:
<1-2 short sentences focused on the outcome>

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

Sequential review is recommendation-first and evidence-light. Follow the same interaction style as `grill-me`: ask one question at a time and show approximate progress. Do not prescribe a default answer; the user should choose without a recommended approval/skip/edit nudge. Avoid burying the decision in evidence text.

Rules for default sequential review:

1. Present only the next highest-ranked active recommendation.
2. Treat approvals during sequential review as tentative decisions only. Record them in a short running list and do not edit files yet.
3. Offer concise actions:
   - `Approve this recommendation`
   - `Skip this recommendation`
   - `Edit this recommendation: <change>`
   - `Rerank remaining recommendations`
   - `Stop curator review`
4. After an approval, record it as tentatively approved and present the next active recommendation. Do not apply it immediately unless the user explicitly says to apply immediately.
5. After a skip, remove that recommendation from the active list and present the next one.
6. After an edit or rerank request, update the remaining list and continue one at a time.
7. After all active recommendations have been reviewed, show the tentative approval list and ask for final confirmation before applying any writes:

   ```md
   Ready for final confirmation:
   - `Apply approved recommendations`
   - `Revise before applying: <change>`
   - `Cancel without applying`
   ```

8. If the user approves multiple numbered recommendations at once outside sequential review, treat them as tentative approvals unless the user explicitly says to apply now. Confirm once before writing.

## Full Summary Format

Use the full summary only when the user explicitly asks for the full list, all recommendations at once, or a ranked summary. Do not use this as the default initial output.

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

### At a Glance

1. <recommendation title> - <target artifact>
2. <recommendation title> - <target artifact>
3. <recommendation title> - <target artifact>

### 1. <action-oriented title>

Recommendation: <one sentence that says exactly what should change>
Target: <path or artifact type>
Recommended action: <specific next step>

Evidence:
- Type: Pattern-backed | Correction-backed | Discovery-backed | Premortem-backed | Speculative
- Signal: <brief pattern summary, not sensitive transcript text>
- Why now: <why this should be handled now>
- Future trigger: <when this durable state will help>

Decision:
- Recommendation type: Add | Update | Consolidate | Remove | Archive | Rename | Refactor | Monitor
- Follow-up skill: <skill name or "none">
- Expected compound value: High | Medium | Low
- Expected efficiency gain: High | Medium | Low
- Confidence: High | Medium | Low
- Maintenance burden: High | Medium | Low
- Duplication/staleness risk: High | Medium | Low
- Approval phrase: `Apply recommendation 1`
- Alternate approvals: `Apply 1 as project-local`, `Apply 1 globally`, `Skip 1 and rerank`
```

Make every recommendation its own self-contained entry. The first visible line under each numbered heading must be `Recommendation:` so the user can skim the proposed changes without reading the evidence ledger or scoring metadata. Keep evidence short and put it after the recommendation. Put approval and routing details under `Decision`, not before the evidence.

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

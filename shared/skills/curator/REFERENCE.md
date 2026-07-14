# Curator Reference

This file owns detailed execution support for Curator. Load each section only under the mandatory condition stated in `SKILL.md`; none of this detail weakens the inline privacy, scope, approval, runtime, ownership, or ephemeral-advice gates.

## Bounded Evidence Scan

Use the following active-agent signals before opening agent-specific history:

- **Codex:** current Codex runtime, `$CODEX_HOME`, `~/.codex/`, and Codex session/history conventions.
- **Pi:** current Pi runtime markers, `~/.pi/`, `pi/skills/`, and Pi session or extension-owned state.
- **Claude:** current Claude runtime, `~/.claude/`, `.claude/`, and Claude transcript/history conventions.
- **Ambiguous:** record the ambiguity and inspect only sources clearly relevant to the current agent and approved scope.

Runtime identifiers and session files are evidence, not durable identity. Never copy tool-owned runtime state, credentials, transcript text, or live pane/session identifiers into recommendations or repository artifacts.

Use `read` for known artifacts, `find` or `ls` to inventory bounded paths, `grep` to locate targeted guidance or patterns, and `bash` for Git evidence; do not broaden the scan merely because a tool is available.

Account for these evidence surfaces:

1. **Current context:** retrospective and boundaries, user corrections, failed commands/tests/reviews/assumptions, discovered unknown unknowns, repeated friction, and successful patterns worth preserving.
2. **Recent Git evidence:** current diff and enough history to detect repeated fixes, churn, abandoned plans, duplicated guidance, or missing review gates. Record the inspected range.
3. **Skill inventory:** inspect available project and shared skills before proposing skill work. Prefer an existing owner or delegation path when it fits.
4. **Durable project context:** applicable `AGENTS.md`, ubiquitous language, specs, README files, plan artifacts, changelogs, TODOs, recipes, and local skill directories.
5. **Active-agent history:** inspect it by default when available and within the human's boundaries. Report patterns and approximate counts only, not sensitive quotations.
6. **Runtime discovery:** for any recommendation affecting a skill, command, wrapper, symlink, config, hook, or runtime-loaded artifact, determine how the active agent discovers it and whether a future session will load it.
7. **Stale guidance:** when work implements or closes a planned follow-up, compare applicable plan artifacts, changelogs, `AGENTS.md`, specs, TODOs, unknown-unknown lists, workarounds, and related recipes. Flag future-facing language that is now misleading.
8. **Cross-evidence mismatch:** when logs, tests, schemas, or structured events pass but video, screenshots, or visual review show a different issue, preserve the disagreement. Consider a spec, QA recipe, or visual-review owner when future agents must compare machine truth with human-visible causality.
9. **Human steering:** target investigation with the retrospective, but still check for duplicate guidance and runtime availability. Surface conflicts rather than treating steering or local evidence as an automatic override.
10. **Hardest stall:** identify the best-evidenced stuck moment, if any, from repeated failed attempts or corrections, loops without progress, explicit stuck statements, or a late-discovered assumption that invalidated earlier work. Defer its routing decision to [Stuck-Moment Analysis](#stuck-moment-analysis).

The scan is complete when every surface is accounted for as inspected, unavailable, out of scope, or not applicable and no recommendation depends on undisclosed private evidence.

## Worktree Triage

When the current directory is in Git, begin with:

```bash
git status --short
```

If a durable artifact such as `AGENTS.md`, `DESIGN.md`, `SKILL.md`, `README.md`, a spec, plan, or doc is untracked, inspect the file directly. An ordinary `git diff -- <untracked-file>` is empty and is not evidence that the file has no content.

Classify every visible change:

- **Owned change:** created or changed by the current, finally approved Curator application.
- **Unrelated change:** predates Curator or lies outside the approved recommendations.
- **Generated artifact:** build output, explainer, screenshot, cache, report, or temporary file.
- **Tool-owned artifact:** agent/browser/runtime state such as `.pi/`, `.playwright-*`, sessions, or logs.

Do not modify, stage, delete, normalize, expose, or fold unrelated, generated, or tool-owned artifacts into an approved change unless the final approval explicitly names that cleanup. State the risk before approval when a recommendation could overlap one of these files. After application, report owned changes separately from protected dirty state.

## Recommendation Targeting and Routing

A recommendation may **add**, **update**, **consolidate**, **remove**, **archive**, **rename**, **refactor**, or **monitor** durable state. Select the smallest durable target that owns the future trigger:

1. Project-local skill, local docs, or repository `AGENTS.md` for codebase-specific learning.
2. Shared skill only when the learning generalizes across repositories.
3. Existing skill update before new skill creation.
4. Spec or canonical glossary update for changed behavioral contracts or domain language.
5. Skill frontmatter tuning when a skill likely missed invocation because its name, description, exact `Use when` phrase, `metadata.short-description`, or tool hints were unclear.
6. Runtime-availability repair when durable state exists but the intended agent cannot discover it because a symlink, wrapper, registration, config entry, install hook, permission, branch condition, or restart is missing.
7. Removal, archival, consolidation, rename, or refactor when current durable state slows future agents.
8. No durable capture when evidence is one-off, vague, contradicted by existing authority, or lacks a future trigger.

When shared guidance would become repo-specific or domain-heavy, prefer a project skill fork or wrapper. Name the upstream skill, added repository gates/vocabulary/fixtures/validation/lifecycle, and the `AGENTS.md` or equivalent route. Keep the shared owner unchanged unless the learning generalizes.

When one skill bundles a broad workflow, a tool-specific wrapper, and an independently reusable artifact routine, consider decomposition. Recommend a split only when each new part has an independently useful invocation, better trigger, or reusable workflow; otherwise retain one owner.

Route approved follow-up to the narrow owner when available:

- `write-a-skill` for new skills or material skill rewrites;
- `audit-shared-skills` for existing union-frontmatter validation or approved repairs, never semantic/YAGNI review;
- `create-agents-md` for repository codebase maps;
- `ubiquitous-language` for canonical domain terminology;
- `update-specs` for durable behavioral contracts and spec discrepancies;
- `create-plan` for implementation-ready multi-context work;
- `grill-me` for consequential unresolved design branches; and
- `test-quality-verifier` for vague assertions or test-quality coverage.

A composed skill imports process, not ownership: Curator keeps recommendation scope, human gates, artifact target, acceptance, and final reporting. If a relevant skill existed but was not selected, treat that as possible ecosystem evidence and prefer a trigger/frontmatter correction over a duplicate skill when discovery caused the miss.

For every proposed new skill, explain why no existing skill should absorb the learning. If no new skill ranks, identify the strongest candidate considered and why updating, consolidating, or routing to existing state has higher compound value.

Reject or down-rank recommendations that duplicate guidance, lack a future trigger, preserve local trivia globally, replace a small test/spec/checklist with broad prose, make selection harder, have no runtime path, or cost more to maintain than they save.

## Ranking Model

Rank by expected compound value and efficiency gain, not confidence. Consider:

- future time saved;
- failure-prevention value;
- reuse breadth;
- likelihood the trigger recurs;
- artifact smallness;
- clarity improvement;
- maintenance burden;
- staleness risk;
- duplication risk; and
- privacy or safety risk.

Classify evidence honestly:

- **Human-steered:** explicitly raised by the retrospective; corroborate where practical.
- **Pattern-backed:** repeated across context, history, Git, or sessions.
- **Correction-backed:** explicit user correction or validation failure.
- **Discovery-backed:** newly found unknown unknown with a clear future trigger.
- **Premortem-backed:** inferred future bottleneck from the success path.
- **Speculative:** weak signal; include only when needed to reach three recommendations and label it clearly.

Each recommendation must state its action, target, owner route, concise evidence signal, why now, future trigger, expected compound value and efficiency gain, confidence, maintenance burden, duplication/staleness risk, and runtime consequence when applicable. When evidence is weak, use low-confidence or monitor-only items honestly rather than inflating certainty.

## Default Sequential Format

Build the ranked set internally, then show only the highest-ranked active item:

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

Do not prescribe a recommended answer. After each response:

1. **Approve:** add the item to the visible tentative set and show the next active item.
2. **Skip:** remove it from the active set and show the next item.
3. **Edit:** change the proposal only, rerank if material, and continue one at a time.
4. **Rerank:** recompute remaining order using the ranking model and continue.
5. **Stop:** stop without applying anything.

For terse repeated approvals such as “approve,” “yes,” or “agreed,” keep the response short but state the running tentative count or latest title before the next item. Multi-number approval also changes only the tentative set.

After review, show one final screen:

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

Include commit/push choices only for affected Git repositories and identify separate repositories. The final screen supplies the one write authorization; all earlier decisions remain tentative.

## Full Summary Format

Use this only after an explicit request for the complete list, all recommendations, or a ranked summary:

```md
# Curator Proposal

## Evidence Ledger

- Current context: inspected
- Human retrospective: <provided/skipped/already supplied; brief steering summary>
- Active agent: <detected agent or ambiguous>
- Agent history: <source and approximate count, or unavailable>
- Git history: <range inspected>
- Current diff: <inspected/unavailable>
- Skills inventory: <count or scope inspected>
- Durable docs/specs/plans: <scope inspected>
- Runtime discovery: <scope and availability result>
- Worktree triage: <owned/unrelated/generated/tool-owned summary>

## Ranked Recommendations

### At a Glance

1. <recommendation title> — <target artifact>
2. <recommendation title> — <target artifact>
3. <recommendation title> — <target artifact>

### 1. <action-oriented title>

Recommendation: <one sentence saying exactly what should change>
Target: <path or artifact type>
Recommended action: <specific next step>

Evidence:
- Type: Human-steered | Pattern-backed | Correction-backed | Discovery-backed | Premortem-backed | Speculative
- Signal: <brief non-sensitive pattern summary>
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
- Tentative approval phrase: `Tentatively approve recommendation 1`
- Alternate choices: `Approve 1 as project-local`, `Approve 1 globally`, `Skip 1 and rerank`
```

Every numbered entry is self-contained, begins visibly with `Recommendation:`, and keeps evidence after the decision statement. Add these fields for removal, archival, or consolidation:

```md
Replacement/source of truth:
Risk if kept:
Risk if removed:
Rollback path:
```

Add these fields for skill rename or refactor:

```md
Current skill:
Proposed skill shape:
Migration notes:
```

End with selection shortcuts, all of which remain tentative:

```md
Tentative selection shortcuts:
- `Approve all high-value recommendations`
- `Approve recommendations 1, 3, and 4`
- `Approve 2 only as a draft`
- `Convert 3 into an AGENTS.md update`
- `Skip 1 and rerank`
```

After the user selects or revises items, use the same one final confirmation screen from [Default Sequential Format](#default-sequential-format). No full-summary phrase authorizes an immediate write.

## Stuck-Moment Analysis

Run this only when the bounded scan found a meaningful stall. Ground it in repeated failed attempts/corrections, loops without progress, explicit stuck statements, or a late invalidating assumption; do not invent a ceiling from ordinary effort.

Classify in this order:

1. Did the failure expose a missing assumption or missing context that should have been supplied?
2. Was a worked example, prior slice, or sharp target spec available and skipped?
3. Is there an oracle: passing test, successful build, measurable property, or other objective check?
4. Is the task large enough to decompose into independently checkable done-states?
5. Is it instead a discrete structural cliff, such as a migration, conversion, or repository restructure, with no valid halfway state?
6. Only after the cheaper causes should the event be framed as a capability ceiling, decomposition problem, or valid case to set down with a dated reason.

Write one tight, session-specific advisory paragraph:

- **Oracle + large task:** suggest smaller pieces with clear independently machine-checked done-states.
- **Oracle + structural cliff:** suggest one deliberate hand-driven change rather than looping or prompting harder.
- **No oracle:** suggest a human-in-the-loop cycle with a cheap judgment turn, and consider smaller judgments to reduce confounding.
- **Cheaper cause found:** name the missing assumption/context or the example/prior slice/spec that should come first.

Show this paragraph once on the final confirmation screen. It is advisory prose only: never rank it, ask the user to approve it, convert it into a recommendation, or write it to any durable artifact. If no meaningful stall occurred, use one line saying so.

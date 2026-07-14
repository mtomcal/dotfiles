---
id: SK-001
target: write-a-skill
status: verified
revision: 1
blocked-by: [MG-001, MG-002]
source-verdict: Simplify inline and make write-a-skill the owner of the canonical body contract, progressive disclosure, split tests, and semantic YAGNI pruning
---

# write-a-skill: canonical body-authoring owner

## Why this item is next

MG-001 revision 2 and MG-002 revision 1 are verified. WF-007 requires `write-a-skill` to become the durable body-authoring owner before any other shared skill body is normalized. This is the last sequential bootstrap item; parallel worker mode remains inactive until SK-001 is approved, implemented, and verified.

The current WF-003 verdict is **simplify inline** with high confidence. The body is already compact and self-contained, but its five numbered level-two headings do not teach or use the now-normative four-section contract. Branch and split decisions are also distributed across its first two steps. The exact replacement below preserves the current behavior ledger while adding the verified MG-001 authoring obligations.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` — destination, scope, and no-production-edit boundary.
- WF-007 — D2 requires `write-a-skill` to become the authoring owner before other skill bodies change.
- WF-003 `write-a-skill` record — complete behavior ledger, **simplify inline** verdict, no supporting Markdown, and high-confidence two-section target shape.
- WF-008 — human-confirmed definitions for Branch, Leading word, Context load, Human cognitive load, Context pointer, Progressive disclosure, Sediment, Sprawl, and No-op instruction.
- WF-006 — `write-a-skill` owns four-section body design, progressive disclosure, independently invocable split tests, and semantic YAGNI pruning; completion criteria remain local; provenance remains centralized.
- `specs/ai-agent-config.md` version `2.3.0` — normative body order, semantic YAGNI standard, behavior-preservation ledger, provenance gate, and ownership boundary with `audit-shared-skills`.
- `specs/UBIQUITOUS_LANGUAGE.md` version `0.7.0` — canonical cross-workflow wording for body sections, progressive disclosure, and behavior-preservation ledger.
- Current `shared/skills/write-a-skill/SKILL.md` — 71 lines, five numbered level-two steps, no linked support files, and all behavior retained in the replacement below.
- Pi `docs/skills.md` — skill discovery loads descriptions first and `SKILL.md` on demand; support paths are relative; names and descriptions retain their existing limits. Pi-specific frontmatter redesign remains out of scope.
- `THIRD_PARTY_NOTICES.md` — identifies `write-a-skill` in the Matt Pocock cohort at upstream commit `66898f60e8c744e269f8ce06c2b2b99ce7660d5f` under MIT and preserves the complete license.
- Upstream primary-source check on 2026-07-14 — the exact revision resolves and contains `skills/productivity/writing-great-skills/SKILL.md` plus the repository MIT `LICENSE`. The local skill remains a one-time maintained adaptation rather than an automatic mirror.
- Local history — the skill was introduced at `14d5c80cc86c440d45e84cd636aeaef310c2683d`, moved into the shared catalog at `4fcd8db204888b46ef857ea16732bcb2e4ab201b`, and materially adapted at `3b59c13906d5d7922ed236b19cfe548138f429d7`.

No current evidence conflicts with the resolved audit. The project glossary now owns the cross-workflow wording of `progressive disclosure`; the exact body below uses compatible wording rather than creating a competing definition.

## Exact files in scope

- `shared/skills/write-a-skill/SKILL.md` — replace the current body after frontmatter with the exact approved body below; preserve the frontmatter byte-for-byte.

No support file is added because the complete authoring workflow remains compact and no branch-only schema, example corpus, or reusable command earns a context pointer.

## Proposed changes

### Add

1. Add a mandatory `Language Definitions` section containing exactly the nine WF-008-confirmed operational terms, with `progressive disclosure` worded compatibly with the project glossary.
2. Add the MG-001 behavior-preservation gate at the start of material revision: before restructuring, map every trigger, branch, gate, failure, guardrail, output, ownership rule, and completion condition to its retained location or approved replacement owner.
3. Teach the canonical section contract in its required order:
   - mandatory `Language Definitions`;
   - optional single `Workflow` with routing or mode selection first;
   - optional `Activities` only for independently reusable operations outside the required sequence;
   - optional `Reference` only for conditional pointers that say when and why support must load.
4. Add the normative semantic YAGNI retention test and explicitly reject fixed line targets.
5. Strengthen the existing provenance sentence into the MG-001 gate: identify source, revision, and license before moving or rewriting imported material, and preserve repository-level notice coverage.
6. Add explicit verification of canonical section semantics and of the behavior-preservation ledger for material revisions.

### Change or move

1. Keep the frontmatter, title, triggers, grants, and union-schema example unchanged.
2. Move the opening predictability principle into the routed Workflow opening so `Language Definitions` is the first semantic body section.
3. Replace the five numbered level-two headings with one `Workflow` level-two section containing five ordered level-three stages. This is structural normalization, not five independent workflows.
4. Consolidate invocation, branch discovery, description trade-offs, material-revision intake, and both split tests in Workflow stage 1.
5. Consolidate information hierarchy, four-section selection, conditional disclosure, script threshold, and one-source-of-truth behavior in Workflow stage 2.
6. Keep action/evidence, failure handling, completion criteria, legwork, and positive-target guidance together in Workflow stage 3; colocate the MG-001 guardrail/output/approval rule there.
7. Keep directory, frontmatter, description-limit, and provenance requirements together in Workflow stage 4.
8. Keep pruning categories, leading-word use, link/script/example checks, repository audit, visibility, and final completion evidence together in Workflow stage 5.
9. Retain `audit-shared-skills` only as the executable union-frontmatter validator. Semantic body review remains owned by this skill and is not delegated to that audit.

### Remove

1. Remove only the obsolete five numbered level-two heading labels after their contents are retained and normalized under `Workflow`.
2. Remove the duplicate placement of reference/script qualification from the current cross-agent-structure step; its full rule remains once in the disclosure stage.
3. Add no `Activities` or `Reference` heading merely to fill the optional shape.
4. Delete no trigger, branch, split test, gate, failure behavior, guardrail, output or artifact contract, ownership rule, completion condition, frontmatter field, provenance duty, repository audit, or visibility check.

### Exact resulting file

Approval authorizes exactly this complete file content:

````markdown
---
name: write-a-skill
description: Design, create, or revise cross-agent skills for predictable invocation and execution with progressive disclosure and checkable completion criteria. Use when writing a new skill, editing an existing skill, splitting skill workflows, or auditing skill clarity and sprawl.
metadata:
  short-description: Write predictable cross-agent skills
allowed-tools: read,write,edit,bash
---

# Writing Skills

## Language Definitions

- **Branch** — workflow path selected by a concrete trigger.
- **Leading word** — recognizable term that cues the intended behavior.
- **Context load** — instructions consuming model context.
- **Human cognitive load** — effort to remember, select, and invoke a skill.
- **Context pointer** — conditional link stating when and why to load support.
- **Progressive disclosure** — staged loading of the catalog description, invoked `SKILL.md`, and conditionally selected support.
- **Sediment** — stale instruction remaining after behavior changed.
- **Sprawl** — live detail obscuring the primary path.
- **No-op instruction** — guidance that does not change likely default behavior.

## Workflow

Use this workflow to design, create, materially revise, split, or semantically audit a skill. A skill should make the agent follow a predictable process, not force identical output.

### 1. Route invocation, revision, and splitting

Identify the task, distinct branches, expected artifacts, required tools, and failure states. Choose a strong leading word already associated with the desired behavior, such as tracer bullet or tight loop.

When materially revising an existing skill body, create a behavior-preservation ledger before restructuring. Map every trigger, branch, gate, failure, guardrail, output, ownership rule, and completion condition to its retained location or an explicitly approved replacement owner.

Balance two invocation costs:

- **Context load** — model-discoverable descriptions occupy every agent turn.
- **Human cognitive load** — explicitly requested skills must be remembered and invoked by a person.

Cross-agent reality varies: some harnesses support `disable-model-invocation`, some ignore it, and all shared skills still require a valid description. Write a precise “Use when…” description for portable discovery. Use explicit-only metadata only when the target agents support it and the human deliberately accepts reduced discovery; never rely on it as the sole cross-agent control.

Keep one source of truth by default. Split into another skill only when it has an independently useful invocation or reusable workflow. Split a sequence only when visible later steps cause premature completion. Otherwise keep branches inside one primary Workflow.

Completion criterion: each genuine branch has a concrete trigger, duplicate synonyms do not inflate the description, any proposed split passes one of the stated tests, and any material revision has a complete behavior-preservation ledger.

### 2. Design the body and disclosure

Use only the semantic sections the skill earns, in this order:

1. `Language Definitions` is mandatory and contains only execution-relevant skill-local terms, or the exact statement “No skill-specific terms.”
2. `Workflow` is optional and contains at most one primary end-to-end process, with routing or mode selection first.
3. `Activities` is optional and contains independently reusable commands, actions, or recipes selected outside the required end-to-end sequence; it does not restate ordinary Workflow steps.
4. `Reference` is optional and contains Markdown pointers that state when and why support must be loaded.

Omit optional sections the behavior does not require. Put ordered main-path actions in `Workflow` when a process exists. Keep always-needed rules beside the Workflow step or Activity they govern. Move only branch-specific or detail-heavy material behind a clearly worded context pointer in a sibling Markdown file, while retaining a compact executable contract inline. Required instructions must not hide behind optional wording.

Add scripts only for deterministic, repeated operations where generated commands would be less reliable. Keep one source of truth for each behavior.

Completion criterion: every included section earns its role, every Reference pointer states when and why to load its target, relative paths resolve from the skill directory, and the required main path remains executable without conditionally loaded support.

### 3. Write checkable behavior

Each Workflow step or Activity should specify:

1. the action and evidence to gather;
2. relevant branches or failure handling; and
3. a completion criterion the agent can actually verify.

Keep guardrails, failures, approvals, output contracts, and completion criteria beside the step or Activity they govern. Demand enough legwork to prevent premature completion: “every modified file accounted for” is stronger than “review the changes.” Prefer positive target behavior; reserve prohibitions for hard guardrails and pair them with what to do instead.

Completion criterion: every step or Activity has an observable finish, and its governing branches, failures, guardrails, approvals, and outputs are local rather than hidden elsewhere.

### 4. Apply cross-agent structure and provenance

Use a lowercase hyphenated directory with `SKILL.md`. Shared skills use the existing union frontmatter:

```yaml
---
name: skill-name
description: What it does. Use when specific trigger conditions occur.
metadata:
  short-description: Short human label
allowed-tools: read,write,bash
---
```

Keep descriptions under 1024 characters. Before moving or rewriting imported material, identify its source, revision, and license; preserve required attribution and license text in the repository-level provenance notice.

Completion criterion: the directory and frontmatter satisfy the repository contract, and every imported source is accounted for before its material changes.

### 5. Apply semantic YAGNI and verify

Prune sentence by sentence according to behavioral value, never a fixed line target:

- **duplication** — one meaning has multiple homes;
- **sediment** — stale instructions remain after behavior changed;
- **sprawl** — live detail overwhelms the main path; and
- **no-op** — a sentence does not change likely default behavior.

Prefer a strong leading word over repeated explanation. Retain content when it changes invocation or routing, workflow correctness, reusable Activity execution, guardrails or failure handling, output or artifact contracts, or required cross-agent or repository behavior.

Check name and description validity, the existing union frontmatter, canonical section order and semantics, links, script syntax and executability, examples, completion criteria, behavior-preservation coverage, provenance, and repository-specific audit commands. For this repo, run `audit-shared-skills` under the existing union schema and follow repository guidance for visibility links.

Completion criterion: all branches are reachable; every Workflow step and Activity has a checkable finish; required behavior remains inline or names an approved replacement owner; references resolve one level deep; duplicated guidance is removed; every modified file is accounted for; and required audits pass.
````

## Proposed skill shape

1. `Language Definitions` — present and mandatory; contains exactly the nine human-confirmed `write-a-skill` terms.
2. `Workflow` — present; one routed body-authoring process with five ordered stages.
3. `Activities` — omitted; the skill has no independently reusable command or recipe outside its required authoring sequence.
4. `Reference` — omitted; the skill has no support file, and its compact authoring contract remains executable inline.

## Behavior-preservation checklist

- [x] Frontmatter `name`, `description`, `metadata.short-description`, and `allowed-tools` remain byte-for-byte unchanged.
- [x] Creation, revision, splitting, and semantic-audit triggers remain reachable.
- [x] Task, branch, artifact, tool, failure-state, and leading-word intake remain in Workflow stage 1.
- [x] Context-load versus human-cognitive-load trade-off and portable `Use when` discovery remain intact.
- [x] Harness-specific explicit-only metadata is never the sole shared-skill control.
- [x] Independent-invocation/reusable-workflow and premature-completion sequence split tests both remain intact.
- [x] Always-needed behavior remains inline and branch/detail-only support requires an explicit context pointer.
- [x] Deterministic repeated-operation threshold for scripts remains intact.
- [x] Every authored step retains action/evidence, branch/failure handling, and a checkable completion criterion.
- [x] Legwork, positive-target wording, hard-guardrail alternative, and one-source-of-truth guidance remain intact.
- [x] Lowercase hyphenated directory, `SKILL.md`, 1024-character description limit, and existing union-frontmatter example remain intact.
- [x] Provenance and license preservation remains and now implements the verified source/revision/license gate.
- [x] Duplication, sediment, sprawl, and no-op pruning categories remain intact.
- [x] Name/description, frontmatter, links, scripts, examples, completion criteria, one-level references, repository audit, and Pi visibility checks remain intact.
- [x] Canonical section order, optionality, semantic YAGNI, and behavior-preservation ledger match MG-001 without inventing optional headings.
- [x] `audit-shared-skills` remains the union-frontmatter validator and is not represented as the semantic/YAGNI owner.
- [x] No support file, spec, notice, deployment, discovery, installer, or visibility link changes.
- [x] `pi/settings.json` and the verified MG-001 and MG-002 diffs remain untouched.

## Dependencies, contradiction repairs, provenance, and risks

- MG-001 revision 2 and MG-002 revision 1 are verified blockers. SK-001 must itself be verified before SK-002 through SK-033, NEW-001, or parallel worker mode can proceed.
- There is no current-source contradiction requiring proposal revision. The target has no support files or executable command syntax to repair before movement.
- The body contract corrects the structural contradiction identified by WF-003: the authoring owner will no longer reproduce five arbitrary top-level process headings after the repository adopted the canonical section contract.
- `progressive disclosure` appears in both WF-008 and the project glossary because this skill owns the behavior while the project glossary owns cross-workflow wording. The exact replacement uses the glossary-compatible definition.
- `audit-shared-skills` remains a composed verification owner only for the existing union frontmatter. This proposal does not redesign fields, tool-grant syntax, or harness portability.
- The imported source, full upstream revision, and MIT license are already recorded in `THIRD_PARTY_NOTICES.md`; that file and legal text remain unchanged.
- Risk: the behavior-preservation ledger can sound like a repository-only ceremony. Mitigation: phrase it as a gate only for material revision, matching the normative spec.
- Risk: optional sections could be treated as a mandatory four-heading template. Mitigation: explicitly require only `Language Definitions`, define when each optional section is earned, and omit `Activities` and `Reference` from this skill.
- Risk: consolidation could hide a split or failure rule. Mitigation: the exact replacement and checklist map each WF-003 behavior before approval, followed by focused complete-file verification.
- Risk: “references resolve one level deep” is compact and may be read as a limit on support chaining. This proposal preserves the current completion condition without adding any support file; catalog-wide interpretation remains a later verification concern rather than scope growth here.

## Verification

1. Reread the complete resulting `shared/skills/write-a-skill/SKILL.md` and compare it line-for-line with the approved exact resulting file in this proposal.
2. Compare the resulting body with the WF-003 behavior ledger and check every item in the behavior-preservation checklist above.
3. Run a heading-shape check that asserts the level-two headings are exactly `Language Definitions` and `Workflow`, in that order; assert that `Activities` and `Reference` are absent rather than empty.
4. Parse the frontmatter and confirm the four existing union-schema fields and values are unchanged; confirm the description remains below 1024 characters and includes `Use when`.
5. Run the `audit-shared-skills` workflow under the existing union schema. Acceptance: `write-a-skill` has no schema error; any catalog findings outside this approved file are reported but not edited under SK-001.
6. Confirm `shared/skills/write-a-skill/` contains only `SKILL.md`, so no undisclosed Reference, script, or asset exists.
7. Run `test -L pi/skills/write-a-skill && test "$(readlink pi/skills/write-a-skill)" = '../../shared/skills/write-a-skill'`. Acceptance: Pi visibility remains the existing symlink.
8. Run `rg -n 'write-a-skill|66898f60e8c744e269f8ce06c2b2b99ce7660d5f|MIT License' THIRD_PARTY_NOTICES.md` and inspect the Matt Pocock section. Acceptance: source, revision, skill entry, and full MIT text remain present and unchanged.
9. Run `git diff --check -- shared/skills/write-a-skill/SKILL.md`.
10. Run `git diff -- shared/skills/write-a-skill/SKILL.md` and confirm the production diff is exactly the approved replacement and no frontmatter line changed.
11. Run `git status --short` and focused hashes. Acceptance: the only new production diff is `shared/skills/write-a-skill/SKILL.md`; `pi/settings.json`, all three MG-001 spec files, and MG-002 `THIRD_PARTY_NOTICES.md` retain their preserved hashes and diffs.

Observable acceptance criteria:

- The file exactly matches the approved target.
- Its only level-two sections are `Language Definitions` then `Workflow`.
- Every WF-003 behavior remains or is strengthened by MG-001; none is silently delegated.
- Existing union frontmatter passes without redesign.
- Provenance, Pi visibility, specs, notices, and preserved unrelated changes remain untouched.

## Implementation record

Focused verification completed: `2026-07-14T15:52:18+00:00`

Integrated verification completed: `2026-07-14T15:53:18+00:00`

- Actual production diff: `shared/skills/write-a-skill/SKILL.md` only, with 57 insertions and 26 removals.
- Resulting SHA-256: `ee47d6dcd714852304cf0c5a9743d54c02bb1f2392a98d36f95589b78c5d8770`.
- Complete-file comparison with the approved revision 1 target: PASS.
- Frontmatter byte comparison with `HEAD`: PASS.
- Canonical level-two shape (`Language Definitions` then `Workflow`, with no empty optional sections): PASS.
- WF-003 behavior-preservation checklist and MG-001 ownership/semantic-YAGNI comparison: PASS.
- Existing union-frontmatter audit: 33 skills, 0 errors, 0 warnings.
- Support-file scope, Pi visibility symlink, and Matt Pocock provenance checks: PASS.
- Focused `git diff --check` and approved-diff inspection: PASS.
- Preserved hashes and combined diff hash for `pi/settings.json`, MG-001, and MG-002: PASS.

## Explicit exclusions

- No file other than `shared/skills/write-a-skill/SKILL.md` may change in production.
- No support Markdown, script, example, asset, or new skill.
- No edits to `THIRD_PARTY_NOTICES.md`, the verified MG-001 specifications, or any Wayfinder artifact.
- No edits to `pi/settings.json`, `pi/skills/write-a-skill`, deployment, discovery, installer, or agent configuration.
- No frontmatter redesign, `allowed-tools` portability change, explicit-invocation policy change, or grant-schema change.
- No implementation of SK-002 or any later catalog item, and no activation of parallel worker mode before SK-001 is verified.
- No fixed line-count target and no automatic upstream synchronization.

## Decision

Proposal revision: `1`

Presented timestamp: `2026-07-14T15:47:18+00:00`

Recorded human response: `APPROVE SK-001`

Approval decision: `APPROVE SK-001`

Decision timestamp: `2026-07-14T15:50:36+00:00`

Approved proposal revision: `1`.

Reply with exactly one:

- `APPROVE SK-001`
- `DECLINE SK-001: <reason>`
- `REVISE SK-001: <instruction>`

No production file is authorized until that decision is recorded with its timestamp and approved proposal revision.

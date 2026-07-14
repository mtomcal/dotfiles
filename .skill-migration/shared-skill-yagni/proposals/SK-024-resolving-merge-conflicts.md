---
id: SK-024
target: resolving-merge-conflicts
status: ready-to-integrate
revision: 2
blocked-by: [SK-001]
source-verdict: retain substance
baseline: 60d8de80947381fc7d9844bb8750c6f7d7677d2f
---

# Resolving Merge Conflicts: retain dual-intent resolution and explicit operation authorization

## Why this item is next

SK-001 is verified, SK-024 is claimed, and no unfinished owner blocks it. WF-007 places `resolving-merge-conflicts` in D4 direct normalization with a **retain** verdict: preserve its complete self-contained conflict-resolution contract while adding the confirmed language and canonical body shape. Its exact files are disjoint from concurrently claimed SK-023.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes the preserve-before-prune destination and excludes frontmatter redesign, deployment, and Pi visibility changes.
- WF-007 assigns `resolving-merge-conflicts` the **retain** verdict: preserve dual-intent tracing, verification, selective staging, and continuation authorization. It remains the specialist conflict owner that the later generic Git-delivery workflow may compose without taking its ownership.
- The complete WF-003 target record supplies the behavior ledger: inspect status, operation, unmerged paths, stage entries, history, and ours/base/theirs identities while protecting unrelated changes; trace both introducing intents per hunk from commits/messages/history/issues/plans/specs; stop for unclear compatibility or authority; preserve compatible intents and choose incompatible intents by operation goal and authority; inspect semantic neighbors; run focused then broader checks; fix only merge-induced failures; stage only verified resolutions; inspect the staged diff; and report preserved intents, staged files, checks, operation, and the exact authorized remaining action.
- WF-008 confirms the exact meanings of Source intent, Authoritative source, Combined result, and Remaining operation, and confirms that `ours` and `theirs` are operation-dependent labels rather than stable intent terms.
- WF-006 keeps conflict-intent ownership here. A future generic Git-delivery owner may compose this workflow but cannot absorb or weaken its conflict resolution, staging, verification, or user-authorization gates. Transport and unrelated delivery behavior remain outside this item.
- `specs/ai-agent-config.md` 2.3.0 requires this skill to trace both intents, stage verified resolutions, and leave commit/continue operations to explicit user approval. It also requires canonical body structure, a behavior-preservation ledger, local guardrails/failures/outputs/completion criteria, semantic YAGNI, and retained caller ownership under composition. `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 leaves skill-local operational language in the owning skill body; `specs/SPEC-OF-SPECS.md` and `specs/README.md` confirm spec authority and reading order.
- Verified `shared/skills/write-a-skill/SKILL.md` requires a complete behavior-preservation ledger, one routed Workflow, checkable local failures and completion criteria, semantic YAGNI without a line target, and provenance review. Verified `shared/skills/audit-shared-skills/SKILL.md` owns only YAML-aware validation of the existing union frontmatter schema.
- The complete current `shared/skills/resolving-merge-conflicts/SKILL.md` is coherent and self-contained, with five ordered stages and no support files, scripts, or Markdown links. It needs the confirmed definitions, canonical section normalization, and more explicit operation/stage identity and local completion wording. One sequencing tension needs correction: stage 3 currently requires no unmerged entries before stage 4 performs selective staging, but Git clears unmerged index entries only when a resolution is added to the index. Revision 2 keeps marker removal and combined-result review in stage 3, then requires selective staging and the no-unmerged-index gate in stage 4.
- Git history shows the target and Pi visibility link were introduced at local commit `3b59c13906d5d7922ed236b19cfe548138f429d7`, and the target remains byte-identical to that introduction at the claim baseline. `THIRD_PARTY_NOTICES.md` identifies `resolving-merge-conflicts` as a locally maintained adaptation of `mattpocock/skills` revision `66898f60e8c744e269f8ce06c2b2b99ce7660d5f` and reproduces Matt Pocock's complete MIT license. Attribution is complete and unchanged.
- Installed Git 2.43.0 help confirms the retained operation mechanics: status identifies unmerged states; `git ls-files --unmerged` exposes up to three index entries; stage 1 is the common ancestor, stage 2 is ours/target, and stage 3 is theirs/merged side; merge conflicts map stage 2 to `HEAD` and stage 3 to `MERGE_HEAD`; cherry-pick records `CHERRY_PICK_HEAD`; rebase exposes the current patch through `REBASE_HEAD`; and checkout/rebase documentation explicitly warns that ours/theirs appear swapped during rebase because ours is the branch being rebased onto and theirs is the work being replayed. Merge, rebase, cherry-pick, and revert each expose operation-specific continue/abort forms. No new fixed executable command is introduced.
- `pi/skills/resolving-merge-conflicts` resolves through `../../shared/skills/resolving-merge-conflicts` to the canonical target.

No authority conflict, ownership contradiction, command correction, support-file need, or provenance gap exists. Revision 2 repairs only the evidenced no-unmerged-versus-staging order without weakening either gate or changing the authorized file set.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-024-resolving-merge-conflicts.md` — item-local authorization, behavior-preservation ledger, exact verification, and worker state.
- `shared/skills/resolving-merge-conflicts/SKILL.md` — add confirmed definitions and canonically normalize the retained five-stage workflow.

These two paths are the complete revision 2 allowed file set. No support file exists or is authorized.

## Proposed changes

### Add

- Add `Language Definitions` with the exact WF-008 meanings of Source intent, Authoritative source, Combined result, and Remaining operation, followed by the confirmed warning that `ours` and `theirs` are operation-dependent labels rather than stable intent terms.
- Make operation and index identity inspection explicit: record status, exact active operation and current step, every unmerged path, available stage entries, relevant history, and the exact commits represented by base/stage 1, ours/stage 2, and theirs/stage 3 in that operation. Retain the rebase-label reversal warning and prohibit inferring intent from labels alone.
- Make the existing per-hunk evidence gate explicit: before editing, record both source-intent statements, the introducing evidence/authority for each, and either the authority deciding precedence or explicit uncertainty.
- Give all five retained stages an observable completion criterion covering state inventory, dual-intent evidence, explained combined result and semantic neighbors, focused/broad verification plus selective staging, and the final report/authorization state.

### Change or move

- Preserve frontmatter byte-for-byte, including merge, rebase, cherry-pick, revert, unmerged-path, and user-request triggers plus the current tool grants.
- Move the unheaded `Resolve intent, not punctuation` rule into the opening of one `Workflow` after the definitions.
- Fold the five numbered level-two headings into one `Workflow` with five ordered steps: establish Git state; trace both intents; resolve each hunk; verify and stage selectively; report the remaining operation.
- At state establishment, retain status, operation, path, stage, and history inspection and unrelated working-tree/index protection. Record unrelated changes before editing so later staging and reporting can prove they remained untouched.
- At intent tracing, retain introducing commits, commit messages, blame/history, linked issues/plans, and relevant specs. If intents are irreconcilable, compatibility is unclear, or authority is insufficient, stop before editing or changing the operation; explain both intents and consequences and ask the user whether to choose a side, redesign, or abort. Never abort silently.
- At resolution, retain compatible dual-intent preservation and incompatible-intent choice according to the operation goal plus authoritative spec or explicit user decision. Retain the prohibitions on unrelated behavior and require removal of conflict markers, inspection of the complete combined result, and semantic-neighbor checks outside the textual hunk before staging.
- At verification, retain focused checks first and broader repository-required checks as practical. Fix and stage only merge-induced resolution failures; report unrelated failures or cleanup without absorbing them. Stage only verified conflict resolutions, protect unrelated changes, then require no unmerged index entries and inspect the staged diff before completion.
- At reporting, retain preserved intents/trade-offs, staged files, checks/results, active operation, and exact remaining action. State whether commit/continue/abort authorization was explicitly provided; never commit, continue, or abort without it.

### Remove

- Remove only the superseded unheaded slogan location and five noncanonical level-two step headings after every unique behavior is retained in `Language Definitions` and the single `Workflow`.
- Remove no trigger, operation, inspection source, identity warning, unrelated-change guard, per-hunk intent/authority requirement, uncertainty stop, compatible/incompatible branch, semantic-neighbor check, verification tier, merge-induced-only fix boundary, staging rule, report field, authorization gate, ownership rule, or completion condition.

## Proposed skill shape

1. `Language Definitions` — present; the four exact WF-008 definitions plus the confirmed operation-dependent ours/theirs boundary.
2. `Workflow` — present; one five-stage intent-first conflict-resolution process with operation routing and state identity first, followed by per-hunk evidence, resolution, verification/selective staging, and authorization-aware reporting.
3. `Activities` — omitted; state inspection, intent tracing, resolution, verification, staging, and reporting are required ordered stages rather than independently selected recipes.
4. `Reference` — omitted; the compact workflow is self-contained and no supporting Markdown exists. Operation-specific Git help remains runtime authority rather than copied reference material.

## Behavior-preservation checklist

- [x] Frontmatter remains byte-identical and still triggers in-progress merge, rebase, cherry-pick, or revert conflicts, Git-reported unmerged paths, and explicit user requests.
- [x] Source intent, Authoritative source, Combined result, and Remaining operation retain their exact confirmed meanings without competing definitions.
- [x] `ours` and `theirs` remain explicitly operation-dependent labels, not stable intent terms; the rebase reversal warning remains inline.
- [x] Status, exact operation/current step, all unmerged paths, index stage entries, relevant history, and base/ours/theirs commit identities remain mandatory before editing.
- [x] Every conflicted path is listed, available base and both sides are identified, and unrelated working-tree/index changes are recorded and protected.
- [x] Every hunk retains two source-intent statements grounded in introducing commits, messages, blame/history, linked issues/plans, and relevant specs as available.
- [x] Every hunk records evidence/authority for both intents and either the precedence authority or explicit uncertainty before editing.
- [x] Irreconcilable intent, unclear compatibility, or unclear authority stops editing and asks the user to choose a side, redesign, or abort after consequences are explained.
- [x] The workflow never silently aborts or changes the active operation while awaiting that decision.
- [x] Compatible intents are preserved together; incompatible intents follow the operation goal and authoritative spec or explicit user decision.
- [x] No unrelated behavior is invented and no unrelated cleanup is absorbed.
- [x] Conflict markers and unmerged entries are removed, each combined result is explainable against source intent, and semantic neighbors beyond textual hunks are inspected.
- [x] Focused checks run first, followed by broader required checks as practical, with all commands and results retained for reporting.
- [x] Only merge-induced resolution failures may be fixed; unrelated failures or cleanup are reported without being modified or staged.
- [x] Only verified conflict resolutions are staged; unrelated changes remain untouched and the staged diff is inspected.
- [x] The final report retains preserved intents/trade-offs, staged files, checks/results, active operation, and exact remaining action.
- [x] Commit, merge/rebase/cherry-pick/revert continuation, and abort remain prohibited without explicit user authorization; the report states whether that authorization exists.
- [x] Conflict-resolution ownership remains here for later Git-delivery composition; no PR, CI, stale-branch, or generic delivery behavior is added.
- [x] Existing Matt Pocock attribution, exact upstream revision, local-fork status, and complete MIT license remain accurate without a notice edit.

## Dependencies, provenance, and risks

- SK-001 is verified at the claim baseline and supplies the final canonical authoring contract. No owner/consumer sequencing conflict remains. NEW-001 is downstream of this item and cannot change this proposal's specialist ownership.
- The target has no support files or scripts. Git operation internals vary by operation and repository state, so the skill requires exact live inspection rather than prescribing one fragile sentinel recipe or treating stage labels as stable intent.
- The explicit stage-number wording refines existing `stage entries` and ours/base/theirs identity behavior using installed Git help; it does not turn `ours` or `theirs` into a semantic decision rule. Rebase remains the named warning case.
- Git's index model makes the baseline's stage-3 no-unmerged criterion impossible before stage-4 staging. Revision 2 preserves the intended outcome by checking markers and semantic correctness before staging, then checking for no unmerged index entries immediately after selective staging. No conflict may be reported resolved while an unmerged entry remains.
- Broad verification remains qualified by repository requirements and practicality, but focused checks, selective staging, staged-diff inspection, and reporting of every result remain mandatory. An unrelated failing broad check cannot authorize unrelated cleanup.
- The target is an MIT-covered locally maintained adaptation. Its source revision, target listing, fork status, Matt Pocock copyright, and complete license already live in `THIRD_PARTY_NOTICES.md`; this body normalization requires no notice edit.
- The result may grow because confirmed definitions and explicit operation/authority gates make latent requirements checkable. Semantic YAGNI, not a fixed line target, governs.

## Verification

1. Reread complete `shared/skills/resolving-merge-conflicts/SKILL.md`; map every WF-003 target-ledger item and every checked item above to one resulting location.
2. Parse level-two headings; expect exactly `Language Definitions` then `Workflow`, with no `Activities`, `Reference`, or unapproved heading.
3. Compare all four definitions and the ours/theirs boundary to WF-008; expect semantic identity and no competing duplicate definitions.
4. Inspect Workflow stage 1 for status, exact operation/current step, complete unmerged-path inventory, available stage 1/2/3 entries, relevant history, base/ours/theirs commit identities, rebase reversal warning, unrelated-change inventory/protection, and a checkable completion gate.
5. Inspect stage 2 for two intent statements per hunk, introducing commits/messages/blame/history/issues/plans/specs, authority/evidence for both, precedence authority or uncertainty, and the choose/redesign/abort user-decision stop without silent operation changes.
6. Inspect stage 3 for compatible/incompatible routing, operation goal, authoritative spec/user decision, no unrelated behavior, marker removal before staging, explainable combined result, and semantic-neighbor checks.
7. Inspect stages 4–5 for focused then broader checks, only merge-induced fixes, selective verified staging followed by no unmerged index entries, staged-diff inspection, complete report fields, and explicit commit/continue/abort authorization state.
8. Check retained Git semantics against installed Git 2.43.0 help and temporary conflict repositories for merge, rebase, cherry-pick, and revert. Acceptance: operation state and current commit can be identified; unmerged stage entries expose the available base/ours/theirs objects; rebase labels follow the documented reversal; and each operation's remaining continue/commit/abort action is distinguishable.
9. Resolve all Markdown links from the skill directory; expect none. Confirm there is no support file or script to validate.
10. Run the complete YAML-aware `audit-shared-skills` workflow against baseline and result, including all union-schema conditions and semantic unused-tool review. Acceptance: every shared skill is parsed/accounted for, target fields pass, and no finding is introduced.
11. Run `test -L pi/skills/resolving-merge-conflicts && test "$(readlink pi/skills/resolving-merge-conflicts)" = '../../shared/skills/resolving-merge-conflicts' && test -e pi/skills/resolving-merge-conflicts/SKILL.md`.
12. Recheck `git log --follow`, the introduction blob, and `THIRD_PARTY_NOTICES.md`; expect introduction at `3b59c13906d5d7922ed236b19cfe548138f429d7`, exact Matt Pocock revision coverage, local-fork statement, complete MIT license, and no notice diff.
13. Run `git diff --check -- .skill-migration/shared-skill-yagni/proposals/SK-024-resolving-merge-conflicts.md shared/skills/resolving-merge-conflicts/SKILL.md`.
14. Run `bash tests/run.sh`; expect all repository shell tests to pass.
15. Compare baseline-aware changed and untracked paths. Acceptance: exactly this proposal and target skill; no diff in `MIGRATION.md`, `pi/settings.json`, `.wayfinder`, specs/glossary, notices, deployment, visibility, tests, support files, unrelated skills, or unrelated proposals.

Acceptance requires exact two-file scope, canonical two-section body, exact confirmed definitions, byte-identical frontmatter, all four operation triggers, complete state/stage/history and base/ours/theirs identity inspection, unrelated-change protection, per-hunk dual intent and authorities, uncertainty/user-decision stop, compatible/incompatible resolution, semantic-neighbor checks, focused/broad verification, merge-induced-only fixes, selective staging and staged-diff review, complete report fields, explicit commit/continue/abort authorization, clean catalog audit, resolving Pi visibility, complete Matt Pocock/MIT provenance, clean diff checks, and passing repository tests.

## Implementation and verification record

Worker verification completed at `2026-07-14T18:08:12+00:00`.

- Proposal-before-edit control: revision 1 reached `proposal-ready`, then a final pre-edit executability review found that the baseline required no unmerged entries in stage 3 before stage 4 performed the staging that clears those entries. No production file had been edited. The proposal returned to `drafting`, revision 2 preserved both gates in executable order, passed renewed scope review, and reached `proposal-ready` before the target edit. The exact two-file set never changed.
- Actual production diff: `shared/skills/resolving-merge-conflicts/SKILL.md` has 41 insertions and 20 removals relative to claim baseline `60d8de80947381fc7d9844bb8750c6f7d7677d2f`. The resulting SHA-256 is `48aa94f0ff04d76f5ec6143320c1b1edd3a12e982b7518b21ddb4266c5e058c9`; this proposal is the only additional item-local file.
- Complete-file and behavior-ledger review: PASS. All merge/rebase/cherry-pick/revert and user-request triggers, status/operation/current-step/path/stage/history inspection, base/ours/theirs identity, rebase reversal warning, unrelated-change inventory, per-hunk dual intent and authorities, uncertainty/user-decision stop, compatible/incompatible routing, semantic-neighbor checks, focused/broad verification, merge-induced-only fix boundary, selective staging, staged-diff inspection, report fields, and commit/continue/abort authorization remain inline.
- Canonical body and confirmed language: PASS. Level-two headings are exactly `Language Definitions` then `Workflow`; `Activities` and `Reference` are correctly omitted. All four WF-008 definitions and the ours/theirs boundary are semantically exact with no competing definitions. The Workflow has exactly five ordered stages and five observable completion criteria. Frontmatter is byte-identical to baseline.
- State, intent, and resolution gates: PASS. Stage 1 accounts for the exact operation/current step, every unmerged path, available stage 1/2/3 entries and source commits, relevant history, the rebase identity reversal, and unrelated working/index changes. Stage 2 requires both evidenced source intents and both authorities per hunk plus precedence authority or explicit uncertainty; uncertainty stops for a choose/redesign/abort decision without silently changing the operation. Stage 3 preserves compatible intents, resolves incompatible ones only by operation goal and authoritative spec/user decision, rejects unrelated behavior, removes markers, and checks complete combined results and semantic neighbors before staging.
- Verification, staging, and final authorization: PASS. Focused checks precede broader required checks as practical. Only failures induced by the merge/active operation may be fixed; unrelated failures and cleanup are reported untouched. Selective staging precedes the no-unmerged-index gate, and staged-diff inspection proves unrelated changes remain excluded. The report retains all five required fields and the workflow cannot commit, continue, or abort without explicit authorization for that exact action.
- Git help and executable probes: PASS against installed Git 2.43.0. Local help confirms status unmerged states, stage 1/2/3 semantics, merge `HEAD`/`MERGE_HEAD`, cherry-pick `CHERRY_PICK_HEAD`, rebase `REBASE_HEAD`, rebase ours/theirs reversal, and operation-specific continue/abort forms. Temporary repositories produced three-stage conflicts for merge, rebase, cherry-pick, and revert and exposed each operation/current commit distinctly; no static command form was added to the skill.
- Baseline-aware union audit: PASS. PyYAML 6.0.1 parsed and accounted for all 33 baseline and all 33 result skill frontmatters with zero errors and zero warnings for required fields, description length, and exact `Use when`. The 32 unchanged tool-grant results remain baseline-identical; target grants remain used for source/spec reading, Git/check execution, conflict editing, and merge-induced fixes.
- Links, support, visibility, history, and provenance: PASS. The target has no Markdown links, support files, or scripts. `pi/skills/resolving-merge-conflicts` still resolves through `../../shared/skills/resolving-merge-conflicts`. History confirms unchanged introduction content at `3b59c13906d5d7922ed236b19cfe548138f429d7`; `THIRD_PARTY_NOTICES.md` retains the exact Matt Pocock revision, target listing, local-fork statement, copyright, and complete MIT license with no notice diff.
- Repository and exact-scope verification: PASS. `bash tests/run.sh` passed 2 shell files and all 12 tests; scoped `git diff --check` passed. Baseline-aware tracked/untracked inspection contains exactly this proposal and target. `MIGRATION.md`, `.wayfinder`, `pi/settings.json`, specs/glossary, notices, AGENTS, tests, deployment, visibility, and unrelated items have no diff.
- Residual risk: Git can represent add/delete conflicts without all three stage entries, and operation internals vary by backend and version. The workflow therefore requires mapping the **available** stage entries and live operation state rather than assuming all three exist or treating labels as intent. Broader checks also remain repository-dependent, but every skipped, failed, or limited check must be reported and cannot authorize unrelated cleanup.

The worker result is `ready-to-integrate`; this record does not claim coordinator integration, central verification, VG-001, SK-023, NEW-001, or any other migration item.

## Explicit exclusions

- No edit to `.skill-migration/shared-skill-yagni/MIGRATION.md`, any `.wayfinder/` file, `pi/settings.json`, any spec or glossary, `THIRD_PARTY_NOTICES.md`, `AGENTS.md`, tests, scripts, installer/deployment files, agent configs, Pi visibility symlinks, another skill/support file, or another proposal.
- No frontmatter schema, field, description, tool-grant, harness-portability, explicit-invocation, discovery, deployment, or visibility redesign.
- No new Reference, Activity, support file, helper script, merge-tool manual, universal Git state detector, generic Git-delivery workflow, PR/CI/stale-branch behavior, code-review behavior, or transport mechanics.
- No automatic preference for ours or theirs, no use of labels as intent, no silent abort, no unapproved commit/continue/abort, no unrelated cleanup, and no weakening of focused checks or selective staging.
- No fixed line-count target, per-item approval wait, broad catalog cleanup, central integration, coordinator verification, VG-001 claim, or claim about another migration item.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `2`
- Authorization effect: the standing no-approval directive authorizes only the exact two paths and changes enumerated in revision 2.
- Scope check: `PASS — revision 2 reread MAP → WF-007 → complete WF-003 target record → WF-008 → WF-006 → current specs/glossary → verified write-a-skill and audit-shared-skills → complete target/support set → provenance/notices/history → installed Git help/source semantics in the mandated order. Exact files remain unchanged. The revision makes the existing gates executable by requiring marker removal and semantic review before selective staging, then no unmerged index entries and staged-diff inspection after staging. Operation triggers, five-stage ledger, ours/base/theirs identity and rebase warning, unrelated-change protection, per-hunk dual intent/authorities, uncertainty stop, compatible/incompatible routing, focused/broad checks, merge-induced-only fixes, report/authorization contract, ownership, provenance/license coverage, exclusions, and verification are fixed. Production editing may continue autonomously without a per-item approval wait.`

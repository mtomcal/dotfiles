---
id: SK-014
target: code-review
status: verified
revision: 1
blocked-by: [SK-001]
source-verdict: retain substance
baseline: 48cc537d21d8f4f1d12641c197568a2ac327bfda
---

# Code Review: retain independent fixed-point Standards and Spec review

## Why this item is next

SK-001 is verified, SK-014 is claimed, and no unfinished owner blocks it. WF-007 places `code-review` in direct normalization with a **retain** verdict: preserve its compact generic-review contract while adding the confirmed language and canonical body shape. This item is independent of concurrently claimed SK-013 and edits no shared target or support path.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes the preserve-before-prune destination and excludes frontmatter redesign, deployment, and Pi visibility changes.
- WF-007 assigns `code-review` the **retain** verdict: preserve independent Standards/Spec axes, fixed-point scope, and separate outputs; the generic review owner will later be consumed by the separately scoped Git-delivery workflow.
- The complete WF-003 target record supplies the behavior ledger: require or resolve a baseline, capture commits and one stable diff, reject bad references and empty diffs early, independently discover repository guidance and the originating requirement, report `No spec available` rather than inventing one, use independent Herdr reviewers or explicitly separated in-process passes, cover every changed file, and report separate severity-ordered axis results and totals.
- WF-008 confirms exact definitions for Standards axis, Spec axis, fixed point, and review scope, plus the rule that neither axis may waive, suppress, or rerank the other.
- WF-006 makes `code-review` the narrow owner of generic fixed-point Standards/Spec semantics. Specialist reviews retain their own authority. Read-only Herdr reviewers may share a checkout; transport does not take ownership of scope, criteria, aggregation, or acceptance; an in-process fallback remains mandatory.
- `specs/ai-agent-config.md` 2.3.0 requires independent Standards/Spec review with Herdr or in-process execution, assigns generic fixed-point review ownership here, and requires canonical body structure, behavior preservation, conditional composition, and isolation before transport. `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 keeps skill-local language in the skill body. `specs/SPEC-OF-SPECS.md` and `specs/README.md` confirm spec authority and reading order.
- Verified `shared/skills/write-a-skill/SKILL.md` requires exact behavior preservation, one routed Workflow, local gates/failures/output/completion criteria, canonical section order, and semantic YAGNI rather than a line target.
- The complete current `shared/skills/code-review/SKILL.md` is self-contained and has no support files. Its four numbered stages already carry the required scope, source, independent-pass, every-file, finding, and reporting contracts; only canonical section normalization and confirmed definitions are needed.
- `THIRD_PARTY_NOTICES.md` already identifies `code-review` as a locally maintained adaptation from `mattpocock/skills` revision `66898f60e8c744e269f8ce06c2b2b99ce7660d5f` and reproduces the MIT license. Git history shows local introduction at `3b59c13906d5d7922ed236b19cfe548138f429d7`; no later target edit exists at the baseline.
- Installed Git 2.43.0 help confirms the retained command semantics: `git diff A...B` compares the merge base of `A` and `B` to `B`; `git log A..B` enumerates commits reachable from `B` but not `A`; `git rev-parse --verify '<ref>^{commit}'` accepts a commit-resolving ref and rejects a bad ref; `git diff --quiet` returns 0 for an empty diff and 1 for a changed diff. No new executable or command form is introduced.
- `pi/skills/code-review` currently resolves through `../../shared/skills/code-review` to the canonical target.

No authority conflict or target provenance correction exists. The production notice, specs, glossary, support-file set, deployment, and visibility link remain unchanged.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-014-code-review.md` — item-local authorization, behavior-preservation ledger, scope review, verification record, and worker state.
- `shared/skills/code-review/SKILL.md` — add confirmed definitions and normalize the retained self-contained review workflow.

These two paths are the complete revision 1 allowed file set. No support file exists or is authorized.

## Proposed changes

### Add

- Add `Language Definitions` with the exact WF-008 meanings of Standards axis, Spec axis, fixed point, and review scope, followed by the exact independence rule that neither axis may waive, suppress, or rerank the other.
- Add observable completion language to the existing stages without changing the contract: scope is complete only after the baseline resolves, commit list and stable diff are captured, and bad-ref/empty-diff checks pass; source discovery is complete only after Standards authority and an originating requirement or explicit `No spec available` state are recorded; review is complete only when every changed file has been considered on both available axes and every finding has location, evidence, impact, and concrete remedy; reporting is complete only with separate severity-ordered sections, per-axis pass/skip state, totals, and worst issue per axis.

### Change or move

- Preserve frontmatter and all triggers exactly.
- Move the unheaded two-axis summary into `Language Definitions`, replacing its shorter labels with the confirmed definitions rather than duplicating them.
- Fold the four numbered level-two headings into one `Workflow` with four ordered numbered steps: pin scope, identify sources, execute independent passes, and report without collapsing axes.
- At scope pinning, retain the user-supplied commit/branch/tag/merge-base route, ask-on-missing-baseline gate, fixed-point resolution, commit-list capture, normally three-dot stable diff, and early bad-ref/empty-diff failures.
- At source discovery, retain all Standards sources, the tool-enforced-formatting exclusion, independent requirement discovery from user/commit/branch/spec/plan/issue evidence, and the explicit no-spec state without invention.
- At execution routing, retain the `HERDR_ENV=1` branch that loads `herdr` and prefers two parallel read-only reviewers sharing the checkout, with identical scope but axis-specific sources/criteria. Retain the explicitly separated in-process fallback and ensure Standards notes cannot excuse, suppress, or rerank Spec findings.
- Keep documented Standards violations, citations, judgement-labelled smells, repository-guidance precedence, formatting exclusion, missing/partial/incorrect/unrequested Spec findings, requirement citations, and scope-creep-versus-harmless-detail distinctions beside their respective passes.
- Keep every-file coverage and the location/evidence/impact/remedy finding contract beside pass completion.
- Keep separate `## Standards` and `## Spec` output sections, severity ordering within each axis, pass/skip states, per-axis counts, and worst issue within each axis, with no cross-axis winner.

### Remove

- Remove only the superseded unheaded two-axis summary and the four noncanonical level-two step headings after every unique behavior has moved into the canonical sections.
- Remove no trigger, route, branch, gate, failure, source, criterion, heuristic, guardrail, output field, ownership rule, or completion condition.

## Proposed skill shape

1. `Language Definitions` — present; exact confirmed definitions for Standards axis, Spec axis, fixed point, and review scope, including the non-waiver/non-reranking rule.
2. `Workflow` — present; one four-stage fixed-point review process with scope/source routing first, Herdr/in-process execution, independent criteria, complete changed-file coverage, and separate reporting.
3. `Activities` — omitted; scope capture, source discovery, review, and reporting are required stages rather than independently selected recipes.
4. `Reference` — omitted; the compact criteria and output contract are needed on every invocation, and no support file exists.

## Behavior-preservation checklist

- [x] Frontmatter still triggers branch, pull-request, worktree, work-in-progress, and fixed-point review without schema or grant changes.
- [x] Standards and Spec remain independent axes with their confirmed meanings; neither can waive, suppress, rerank, mask, or provide a winner over the other.
- [x] A user-supplied commit, branch, tag, or merge base remains accepted; a missing baseline still requires asking rather than guessing.
- [x] The baseline is resolved to a fixed point; commit-list and stable-diff capture remain required, normally using three-dot scope.
- [x] Bad references and empty diffs remain early failures before source discovery or reviewer execution.
- [x] Standards authority still includes `AGENTS.md` and relevant contributor, test, style, and module guidance.
- [x] Tool-enforced formatting remains excluded from review findings.
- [x] Requirement discovery still independently checks user input, commit messages, branch context, specs, plans, and issue references.
- [x] A missing requirement still yields explicit `No spec available`; the workflow never invents a spec.
- [x] Under `HERDR_ENV=1`, the workflow still loads `herdr` and prefers two parallel read-only reviewers with the same scope, isolated axis criteria, and permitted shared checkout.
- [x] Outside Herdr, or when transport is not used, two explicitly separated in-process passes preserve reviewer independence and equivalent criteria.
- [x] Documented Standards violations still require file/hunk location and cited rule; smells remain labelled judgement calls subordinate to repository guidance.
- [x] Every existing smell heuristic remains available as compact decision support.
- [x] Spec findings still cover missing/partial requirements, incorrect implementation, and unrequested behavior, each with a cited requirement and scope-creep distinction.
- [x] Every changed file must still be considered independently on both available axes.
- [x] Every finding still requires location, evidence, impact, and a concrete remedy.
- [x] Output still uses separate Standards and Spec sections ordered by severity, explicit pass/skip states, separate totals, and the worst issue within each axis.
- [x] No cross-axis aggregate verdict or winner is introduced.
- [x] Generic review scope, criteria, aggregation, and acceptance remain caller-owned; Herdr remains transport and specialist reviewers retain narrow authority.
- [x] Existing MIT provenance and license coverage remain accurate without a notice edit.

## Dependencies, provenance, and risks

- SK-001 is verified at baseline `48cc537d21d8f4f1d12641c197568a2ac327bfda`; SK-014 consumes its final canonical-body contract. No owner/consumer sequencing conflict remains.
- This is normalization, not a command-correction item. The existing three-dot default is retained as the review-scope control confirmed by WF-003, and installed Git help validates it. The fixed point is pinned to an immutable commit before that comparison is captured.
- Worktree/WIP remains an invocation trigger. This item does not invent a universal Git snapshot artifact or untracked-file recipe; the workflow's stable captured diff and every-changed-file gate remain authoritative for the selected review scope.
- Herdr execution remains preferred only under its environment trigger. Both delegates are read-only, so shared checkout is valid; command mechanics stay with `herdr`, while this workflow retains briefs, criteria, result aggregation, and fallback.
- The current target is an adapted MIT-licensed local fork. Attribution, source revision, and full license are already present in `THIRD_PARTY_NOTICES.md`; restructuring does not require changing that notice.
- Existing `allowed-tools: read,bash` remains unchanged and both grants are used by source reading and Git inspection. Frontmatter redesign is outside this lane.

## Verification

1. Reread complete `shared/skills/code-review/SKILL.md`; map every WF-003 target-ledger item and every checked item above to one resulting location.
2. Parse level-two headings; expect exactly `Language Definitions` then `Workflow`, with no `Activities`, `Reference`, or unapproved heading.
3. Compare all four definitions and the non-waiver/non-reranking sentence to WF-008; expect semantic identity and no competing duplicate definitions.
4. Inspect routing and ownership: missing baseline asks; bad ref/empty diff stop before reviews; requirement discovery is independent; no-spec is explicit; Herdr reviewers are parallel/read-only/axis-scoped; in-process passes are explicitly separated; both use the same captured scope and preserve caller aggregation.
5. Inspect criteria and output: all twelve existing smell names remain; tool formatting exclusion, rule/requirement citations, scope-creep distinction, every-file coverage, four finding fields, separate severity ordering, pass/skip states, per-axis totals/worst issue, and no cross-axis winner remain.
6. Check retained Git forms against installed Git 2.43.0 help and a temporary repository: commit resolution accepts valid and rejects bad refs; three-dot diff and two-dot commit list operate on resolved commits; empty and non-empty diff checks are distinguishable before review execution.
7. Resolve all Markdown links from the skill directory; expect none. Confirm there is no support file or script to validate.
8. Run the complete YAML-aware `audit-shared-skills` workflow against baseline and result, including every union-schema condition and semantic unused-tool review. Acceptance: all 33 skills are parsed/accounted for, target fields pass, and no finding is introduced.
9. Run `test -L pi/skills/code-review && test "$(readlink pi/skills/code-review)" = '../../shared/skills/code-review' && test -e pi/skills/code-review/SKILL.md`.
10. Recheck `git log --follow`, upstream revision evidence, and `THIRD_PARTY_NOTICES.md`; expect the existing Matt Pocock/MIT provenance to remain complete and no notice diff.
11. Run `git diff --check -- .skill-migration/shared-skill-yagni/proposals/SK-014-code-review.md shared/skills/code-review/SKILL.md`.
12. Run `bash tests/run.sh`; expect all repository shell tests to pass.
13. Compare baseline-aware changed and untracked paths. Acceptance: exactly this proposal and target skill; no diff in `MIGRATION.md`, `pi/settings.json`, specs/glossary, notices, deployment, visibility, tests, support files, or unrelated items.

Acceptance requires exact two-file scope, canonical two-section body, all confirmed definitions, unchanged triggers/frontmatter, complete fixed-point and early-failure behavior, independent requirement discovery and reviewer execution in both routes, every-file/finding coverage, separate severity outputs/totals, valid command semantics, clean catalog audit, resolving Pi visibility, complete provenance, clean diff checks, and passing repository tests.

## Implementation record

Worker verification completed at `2026-07-14T17:19:14+00:00`.

- Proposal-before-edit control: revision 1 reached `proposal-ready` with the exact proposal/target file set before production editing. No material scope, authority, ownership, provenance, or behavior revision was needed.
- Actual production diff: `shared/skills/code-review/SKILL.md` has 17 insertions and 26 removals. The resulting SHA-256 is `3bd9e02ff55f3de31f71908472c8f7d458977e659151833555271f419fae29b1`; this proposal is the only additional item-local file.
- Complete-file and behavior-ledger review: PASS. All invocation triggers, fixed-point input and missing-baseline gate, commit/diff capture, early bad-ref/empty-diff failures, Standards and requirement-source discovery, no-spec state, both execution routes, criteria, every-file coverage, four finding fields, and separate output contract remain inline.
- Canonical body and confirmed language: PASS. Level-two headings are exactly `Language Definitions` then `Workflow`; `Activities` and `Reference` are correctly omitted. All four WF-008 definitions and the exact non-waiver/non-suppression/non-reranking rule are present without competing definitions. Frontmatter is byte-identical to baseline.
- Independence and ownership: PASS. Herdr reviewers are parallel, read-only, checkout-sharing, same-scope, and axis-scoped; the in-process fallback uses the same captured scope and explicitly separates notes/checklists until aggregation. Caller-owned scope, criteria, aggregation, and acceptance are not transferred to transport, and no specialist contract is absorbed.
- Criteria and outputs: PASS. All twelve existing smell names remain judgement-labelled and subordinate to repository guidance; tool-enforced formatting remains excluded. Spec findings retain missing/partial, incorrect, and unrequested categories, citations, and the scope-creep distinction. Reporting retains severity order, separate Standards/Spec sections, available-axis pass and unavailable-axis skip states, separate totals/worst issues, and no cross-axis winner.
- Git command semantics: PASS against installed Git 2.43.0 help and a temporary repository. Valid commit resolution succeeded, a bad ref failed, `base..head` selected the expected commit, `base...head` selected the expected changed file, and `git diff --quiet` returned 1 for changed and 0 for empty scope. No executable or command form changed.
- Baseline-aware union audit: PASS. PyYAML 6.0.1 parsed and accounted for all 33 baseline and result skills; both runs reported 0 errors and 0 warnings for required fields, description length, and `Use when`. The 32 unchanged tool-grant results remain identical to the clean baseline; target grants remain used (`read` for authorities and `bash` for Git scope inspection), so no unused-grant warning was introduced.
- Links/support/provenance/visibility: PASS. The target has no Markdown links, support files, or scripts. Git history confirms introduction at `3b59c13906d5d7922ed236b19cfe548138f429d7`; `THIRD_PARTY_NOTICES.md` still records the exact Matt Pocock revision and full MIT license. Pi visibility remains the resolving symlink `../../shared/skills/code-review`.
- Repository and exact-scope verification: `bash tests/run.sh` passed 2 shell files and all 12 tests; `git diff --check` passed. Baseline-aware tracked/untracked inspection contains exactly this proposal and target skill. `MIGRATION.md`, `pi/settings.json`, specs/glossary, notices, AGENTS, tests, deployment, visibility, and unrelated items have no diff.
- Residual risk: worktree/WIP remains a supported trigger, but—as at baseline—the compact contract requires a stable captured diff and exhaustive changed-file coverage rather than prescribing one universal snapshot or untracked-file recipe. No existing behavior was silently replaced to resolve that repository-dependent choice.

The worker result is `ready-to-integrate`; this record does not claim coordinator integration, central verification, VG-001, SK-013, or any other migration item.

## Integrated verification

- Coordinator verification timestamp: `2026-07-14T17:22:30+00:00`.
- Exact scope, complete skill review, canonical shape, fixed-point and early-failure gates, independent axes/routes, every-file findings, separate outputs, and provenance passed.
- Repository tests passed 12/12; diff check, Pi visibility, and preserved settings hashes passed. WIP stable-diff risk remains documented.

## Explicit exclusions

- No edit to `.skill-migration/shared-skill-yagni/MIGRATION.md`, `pi/settings.json`, any spec or glossary, `THIRD_PARTY_NOTICES.md`, `AGENTS.md`, tests, scripts, installer/deployment files, agent configs, Pi visibility symlinks, another skill/support file, or another proposal.
- No frontmatter schema, tool-grant, harness portability, explicit-invocation, discovery, deployment, or visibility redesign.
- No supporting Reference, helper script, severity taxonomy, universal report schema, generic Git-delivery behavior, PR/CI/stale-branch workflow, specialist review behavior, editable delegation, or replacement of Herdr command ownership.
- No change from three-dot default to two-dot scope, no invented baseline default, no invented requirement, no weakening of missing-spec reporting, and no cross-axis aggregate verdict.
- No fixed line-count target, per-item approval wait, broad catalog cleanup, central integration, central verification, VG-001 claim, or claim about another migration item.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization effect: the standing directive removes the per-item approval wait but authorizes only the exact two paths and changes enumerated in revision 1.
- Scope check: `PASS` — MAP, WF-007, the complete WF-003 target record, WF-008, WF-006, current specs/glossary, verified `write-a-skill`, complete target/support set, provenance/notices/history, Pi visibility, and installed Git help plus command probes were reviewed in the mandated order. Exact files, behavior ledger, ownership, contradictions, provenance, licensing, exclusions, and verification are fixed. Production editing may continue without a per-item approval wait.

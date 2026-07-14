---
id: SK-020
target: image-comparison-judge
status: verified
revision: 2
blocked-by: [SK-001]
source-verdict: simplify inline
baseline: 620b748c1f6ce7e5088c035f7ad506e654a866a5
revision-baseline: f60d0f911bf8619a3af32b0bbaf87204e86bc91b
---

# Image Comparison Judge: route judging before scoped verdict production

## Why this item is next

SK-001 is verified, SK-020 is claimed at baseline `620b748c1f6ce7e5088c035f7ad506e654a866a5`, and no unfinished owner decision blocks it. WF-007 places `image-comparison-judge` in D4 direct normalization: put role and delegation routing first, consume neutral diff evidence from its owner, and retain strict scoped PASS/FAIL without claiming final human acceptance. This exact file set is disjoint from concurrently claimed SK-019.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes the preserve-before-prune destination and excludes frontmatter redesign, deployment, and Pi visibility changes.
- WF-007 assigns **simplify inline**: route first and keep strict scoped PASS/FAIL beside the judging step.
- The complete WF-005 target record supplies the behavior ledger: route already-judge, wrapper, delegation, and fallback behavior; gather every reference/candidate path and verdict-changing domain constraint; prefer available neutral diff evidence; perform or delegate comparison; return strict PASS/FAIL with blocking mismatches, secondary gaps, evidence checked, and next focus; scope PASS to the requested visible surface; disclose non-independent fallback; and preserve the final-human-acceptance boundary.
- WF-008 confirms exactly three skill-local definitions: Visual acceptance, Comparison surface, and Blocking finding. It assigns neutral diff artifact ownership to `image-diff-describer`; this skill only consumes that artifact.
- WF-006 defines the visual pipeline and keeps criteria, forbidden elements, comparison surface, strict verdict, and output authority local to this judge. It requires specialist verdicts not to claim final human acceptance and keeps output contracts with their producer.
- `specs/ai-agent-config.md` 2.3.0 requires canonical body order, routing at the Workflow beginning, local failures/output/completion criteria, behavior preservation, specialist verdict scope, and caller or human acceptance after applicable visual stages.
- `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 defines neutral diff artifact as no-criteria/no-severity/no-recommendation/no-verdict evidence owned by `image-diff-describer`; it does not imply visual acceptance.
- Verified `shared/skills/write-a-skill/SKILL.md` requires a complete behavior-preservation ledger, one routed Workflow, checkable behavior, semantic YAGNI, and provenance review.
- The complete target and `shared/skills/image-diff-describer/SKILL.md` agree on the neutral-evidence/judgment boundary. The target has no support files, scripts, Markdown links, or fixed command syntax.
- Git history shows the target was created in this repository at `f915a0f2cf70e6016b2178782a56ea886e5c72c5`, then received local nested-judge, neutral-diff, human-acceptance, and tool-grant refinements. It is absent from `THIRD_PARTY_NOTICES.md`; no imported source, external license, or attribution requirement is evidenced.

Coordinator review of revision 1 found one sequencing contradiction: target step 1 tried a wrapper and decided whether it could complete before step 2 gathered the wrapper/delegate brief, despite the proposal requiring selection first, gathering second, and execution third. Revision 2 repairs only that ordering. No authority conflict, command correction, support-file need, provenance gap, ownership change, or broader behavior change exists.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-020-image-comparison-judge.md` — item-local proposal, authorization, behavior ledger, verification plan, and worker result.
- `shared/skills/image-comparison-judge/SKILL.md` — add confirmed definitions and normalize the existing compact judge into one route-first Workflow.

These two paths are the complete revision 2 allowed file set. No supporting file exists or is authorized.

## Proposed changes

### Add

- Add `Language Definitions` with the exact WF-008 meanings of Visual acceptance, Comparison surface, and Blocking finding; do not redefine neutral diff artifact.
- Begin the single `Workflow` by selecting, without invoking, the preferred route available at selection time in this order: already running as the judge → repo-local wrapper → direct `image-comparison-judge` delegation → in-process fallback.
- Put route execution and failure handling only after the complete brief is gathered: wrapper failure continues to direct delegation when available; wrapper or delegate failure continues to the disclosed in-process fallback.
- State that an available neutral diff artifact is consumed as observable evidence from `image-diff-describer`, not produced, owned, or treated as a verdict by this skill.
- Add an observable completion criterion requiring every named image to be checked, the comparison surface and constraints to govern the verdict, findings to be classified, the execution route or fallback to be disclosed, and all required output fields to be present.

### Change or move

- Preserve frontmatter byte-for-byte, including all invocation triggers, description scope, short description, and read/bash grants.
- Move already-judge, wrapper, direct-delegation, and unavailable-delegation selection from the current Workflow, Delegation Brief, and Fallback sections to the Workflow opening, but defer all invocation and completion decisions until the execution step after brief gathering.
- Keep already-judge execution direct in step 3 and explicitly prohibit falsely reporting that the independent pass was unavailable in that branch.
- Keep manual fallback behavior identical in authority to the judge contract while requiring disclosure that an independent judge pass could not run.
- Colocate evidence gathering after route selection: reference path, all candidate paths, intended match, explicit comparison surface, blocking review dimensions, verdict-changing domain constraints, forbidden visible elements, and available neutral diff path.
- Colocate the wrapper/delegate brief with execution and include every current brief field plus the available neutral diff artifact path.
- Keep the verdict beside judging: strict PASS/FAIL only for the requested comparison surface; any Blocking finding prevents PASS; other visible gaps remain secondary findings.
- Keep the exact five-part output contract: verdict, blocking findings, secondary findings, evidence checked, and suggested next comparison focus.
- Keep PASS limited to Visual acceptance on the Comparison surface and explicitly preserve any separately required final human acceptance step.

### Remove

- Remove the standalone opening sentence and the separate `Delegation Brief` and `Fallback` level-two sections only after their unique invocation rationale, brief fields, routes, failure handling, and disclosure rules are retained in the Workflow.
- Remove only duplicated routing and summary wording created by colocation.
- Remove no trigger, evidence input, domain constraint, forbidden-element check, brief field, execution branch, fallback disclosure, output field, strict-verdict rule, scoped-acceptance boundary, ownership rule, or completion condition.

## Proposed skill shape

1. `Language Definitions` — present; exactly Visual acceptance, Comparison surface, and Blocking finding.
2. `Workflow` — present; one route-first process covering evidence gathering, neutral-diff consumption, direct/wrapped/delegated/fallback comparison, strict scoped verdict, output, and human boundary.
3. `Activities` — omitted; judging, briefing, and fallback are required branches of the one process, not independently selected recipes.
4. `Reference` — omitted; the compact executable contract remains inline and no support file is warranted.

## Behavior-preservation checklist

- [x] Frontmatter continues to trigger criteria-based reference/candidate judgment after neutral diffing or capture, concept-fidelity review, visual regression triage, and independent artifact review.
- [x] Visual acceptance, Comparison surface, and Blocking finding use the exact human-confirmed WF-008 meanings; no fourth skill-local term is invented.
- [x] Neutral diff artifact remains owned by `image-diff-describer`; this skill only consumes it when available and never treats it as criteria, severity, recommendation, or verdict.
- [x] Already-judge, wrapper, direct delegation, and no-delegation fallback routes all remain reachable; step 1 selects only the preferred available route before evidence gathering and does not invoke it or decide whether it completes.
- [x] Step 2 gathers the complete evidence and brief before any selected wrapper or delegate executes.
- [x] A running judge compares directly in step 3 and never falsely claims its own independent judge pass was unavailable.
- [x] A repo-local wrapper remains preferred before direct subagent delegation.
- [x] Wrapper failure can continue through direct delegation or the same in-process fallback instead of terminating the workflow without a verdict.
- [x] Manual fallback performs the same criteria-based comparison and discloses that the independent judge pass could not run.
- [x] Reference image path and every candidate image path remain required evidence.
- [x] What the candidate should match remains explicit.
- [x] Full-scene, asset, or HUD scope remains explicit as the Comparison surface.
- [x] Blocking review dimensions and verdict-changing domain constraints remain required.
- [x] Truthful-HUD rules, forbidden mechanics, and other forbidden visible elements remain representable constraints.
- [x] Available neutral diff artifact path remains part of the wrapper/delegation brief.
- [x] The result remains a strict PASS or FAIL rather than a score or qualified non-verdict.
- [x] A Blocking finding prevents PASS on the requested core dimensions; secondary findings remain separately reported.
- [x] Blocking findings, secondary findings, evidence checked, and suggested next comparison focus remain required output beside the verdict.
- [x] PASS remains Visual acceptance only for the requested Comparison surface.
- [x] The verdict does not replace a separately required final human acceptance step.
- [x] Every named image, criterion, route, finding class, and output field has observable completion evidence.
- [x] Frontmatter, repo-local provenance status, no-link/no-support shape, and Pi visibility remain unchanged.

## Dependencies, provenance, and risks

- SK-001 is verified at the claimed baseline. `image-diff-describer` already owns the neutral diff artifact contract; this proposal neither edits nor depends on a pending rewrite of that skill.
- Current source revision 1 contradicts the intended select → gather → execute ordering by testing wrapper completion in step 1. Revision 2 makes route selection non-executing, gathers the complete brief in step 2, and moves invocation plus failure continuation to step 3.
- The wrapper is project-local and optional. Availability may select it in step 1, but only step 3 may invoke it and observe failure. Wrapper failure continues to direct delegation when available; wrapper or delegate failure continues to manual fallback with explicit non-independent disclosure.
- The target is repo-local by Git history and has no third-party notice. No provenance or license edit is authorized.
- Compact normalization must not import general visual-review theory, capture mechanics, neutral-diff production, or final caller acceptance into this specialist owner.

## Verification

1. Reread the complete resulting target and map every WF-005 ledger item and every checked item above to one inline location.
2. Parse level-two headings; expect exactly `Language Definitions` then `Workflow`, with no `Activities`, `Reference`, or unapproved heading.
3. Compare definitions to WF-008; expect exactly three semantically identical definitions and no definition of neutral diff artifact.
4. Compare target frontmatter byte-for-byte with baseline; expect no change.
5. Inspect the Workflow order; expect step 1 to select only the preferred available already-judge → wrapper → direct-delegation → fallback route, step 2 to gather the complete brief, and step 3 to invoke the selected route. Confirm wrapper failure continues to delegation when available and wrapper or delegate failure continues to disclosed in-process fallback.
6. Confirm the brief retains reference/candidate paths, intended match, neutral diff path when available, blocking dimensions, forbidden visible elements, and full-scene/asset/HUD comparison surface.
7. Confirm the strict output contains PASS/FAIL, blocking findings, secondary findings, evidence checked, and suggested next comparison focus; any Blocking finding prevents PASS.
8. Confirm neutral diff is consumed without ownership and PASS remains scoped Visual acceptance that does not claim final human acceptance.
9. Resolve Markdown links and inspect support/scripts/commands; expect none and no static command-help check.
10. Run the complete YAML-aware `audit-shared-skills` union-frontmatter audit; expect all 33 skills parsed/accounted for with zero errors and zero warnings, including a manual least-tool check for the target.
11. Run `test -L pi/skills/image-comparison-judge && test "$(readlink pi/skills/image-comparison-judge)" = '../../shared/skills/image-comparison-judge' && test -e pi/skills/image-comparison-judge/SKILL.md`.
12. Recheck target history and `THIRD_PARTY_NOTICES.md`; expect repo-local creation at `f915a0f2cf70e6016b2178782a56ea886e5c72c5`, no imported-material evidence, and no notice diff.
13. Run `git diff --check -- .skill-migration/shared-skill-yagni/proposals/SK-020-image-comparison-judge.md shared/skills/image-comparison-judge/SKILL.md`.
14. Run `bash tests/run.sh`; expect all repository shell tests to pass.
15. Compare baseline-aware changed and untracked paths; expect exactly this proposal and target, with no diff in `MIGRATION.md`, `.wayfinder/`, specs/glossaries, notices, tests, deployment/discovery/visibility files, `pi/settings.json`, unrelated skills, or unrelated proposals.

Acceptance requires exact two-file scope, canonical two-section body, exactly three confirmed definitions, unchanged frontmatter, non-executing route selection in step 1, complete evidence and brief gathering in step 2, route invocation and failure continuation only in step 3, neutral-diff consumption without ownership, strict scoped PASS/FAIL, blocking/secondary findings, fallback disclosure, final-human-acceptance boundary, clean union audit, resolving Pi visibility, clean diff checks, and passing repository tests.

## Implementation and verification record

Revision 1 worker verification completed at `2026-07-14T17:41:05+00:00`.

- Proposal-before-edit control: revision 1 reached `ready-to-integrate` and was committed at `f60d0f911bf8619a3af32b0bbaf87204e86bc91b`, then coordinator review returned it to `drafting` for the sequencing contradiction recorded above. Revision 2 now reaches `proposal-ready` before its production edit, retains the exact two-file scope, and changes only route-selection/execution ordering.
- Actual production diff: `shared/skills/image-comparison-judge/SKILL.md` has 16 insertions and 29 deletions relative to baseline `620b748c1f6ce7e5088c035f7ad506e654a866a5`. The result is 29 lines and 370 words versus the audited 42-line, 316-word baseline; the added words are the three confirmed definitions, explicit wrapper-failure route, neutral-evidence ownership boundary, and observable completion contract rather than new visual-review theory. Resulting target SHA-256: `0cc857e4894200b787865b4f05d166b27e54da894a1cf9f9636adfe086d971fa`.
- Complete-file and behavior-ledger review: PASS. Every trigger, reference/candidate input, intended-match field, full-scene/asset/HUD surface, blocking dimension, domain constraint, truthful-HUD/forbidden-element example, available neutral diff path, route, fallback disclosure, required output field, scoped verdict, and final-human boundary remains inline.
- Canonical shape and language: PASS. Level-two headings are exactly `Language Definitions` then `Workflow`; Activities and Reference are correctly omitted. Exactly Visual acceptance, Comparison surface, and Blocking finding are defined with WF-008 semantics; neutral diff artifact is not redefined.
- Revision 1 route sequencing: COORDINATOR REJECTED. Step 1 selected and tried the wrapper, including deciding that it could not complete, before step 2 gathered the brief. Revision 2 must verify non-executing selection in step 1, brief gathering in step 2, and invocation plus failure continuation in step 3.
- Evidence and ownership: PASS. Every named image must be inspected. Wrapper/delegate briefs retain all baseline fields plus the already-supported neutral diff path. Available neutral diff evidence is explicitly consumed from `image-diff-describer` without production, ownership, or verdict transfer.
- Verdict and acceptance authority: PASS. Output remains strict PASS/FAIL with blocking findings, secondary findings, evidence checked, and suggested next comparison focus. Any Blocking finding prevents PASS on the requested Comparison surface. PASS remains scoped Visual acceptance and cannot replace a separately required final human acceptance step.
- Frontmatter and audit: PASS. Frontmatter is byte-identical to baseline. PyYAML 6.0.1 parsed and accounted for all 33 shared skills; the complete union-schema audit reported zero errors and zero warnings. Manual least-tool review retained `read` for image/evidence inspection and `bash` for project wrapper discovery/invocation.
- Links, support, commands, visibility, and provenance: PASS. The target has no Markdown links, support files, scripts, or fixed command syntax requiring help validation. `pi/skills/image-comparison-judge` still resolves through `../../shared/skills/image-comparison-judge`. Git history confirms repo-local creation at `f915a0f2cf70e6016b2178782a56ea886e5c72c5`; no third-party notice names the target and no imported-material evidence or notice change exists.
- Repository and exact-scope verification: PASS. `git diff --check` passed. `bash tests/run.sh` passed both shell files and all 12 tests. Baseline-aware tracked/untracked inspection contains exactly this proposal and target; the migration ledger, Wayfinder records, specs/glossary, notices, tests, installer/deployment, agent config, visibility link, every Pi file including `pi/settings.json`, adjacent visual skills, and unrelated migration items have no diff.
- Residual risk: wrapper interfaces and delegation availability remain project/runtime-specific. The route requires capability discovery and preserves a disclosed in-process fallback, so no static wrapper contract or unavailable independent pass is invented.

### Revision 2 correction

Revision 2 worker verification completed at `2026-07-14T17:47:01+00:00`.

- Proposal-before-edit control: PASS. Coordinator review returned revision 1 to `drafting`; revision 2 recorded the contradiction, exact unchanged file set, sequencing repair, verification, revision baseline `f60d0f911bf8619a3af32b0bbaf87204e86bc91b`, and passing scope check before the target changed.
- Actual revision diff: PASS. Relative to revision 1, the target changes only Workflow steps 1 and 3 with two insertions and two deletions; the proposal is the only other changed file. The resulting target remains 29 lines, is 400 words, and has SHA-256 `ce49e41f14cce976480c5447877a9aa359a0cb6dd708bca04f87d40978ed4b5a`.
- Select → gather → execute sequencing: PASS. Step 1 selects the preferred available already-judge, wrapper, direct-delegation, or fallback route without invoking it or testing completion. Step 2 gathers every evidence and brief input. Step 3 invokes only after gathering, sends all inputs, continues wrapper failure to direct delegation when available, and continues wrapper or delegate failure to disclosed in-process fallback.
- Preserved contracts: PASS. All three confirmed definitions, neutral-diff consumption without ownership, every image/criteria/brief field, strict scoped PASS/FAIL, blocking and secondary findings, evidence and next-focus output, fallback disclosure, completion criterion, and final-human-acceptance boundary remain unchanged.
- Canonical shape, frontmatter, and audit: PASS. Level-two headings remain exactly `Language Definitions` then `Workflow`; frontmatter remains byte-identical to the original baseline. PyYAML parsed and accounted for all 33 shared skills with zero union-schema errors and zero warnings; the target's read/bash grants remain used.
- Repository checks: PASS. `bash tests/run.sh` passed both shell files and all 12 tests. Diff check, visibility, provenance, and protected-path checks passed. Relative to revision 1, exactly this proposal and target changed; the migration ledger, `.wayfinder`, specs, notices, tests, deployment, agent config, Pi visibility link, every Pi file including `pi/settings.json`, adjacent visual skills, and unrelated items have no diff.
- Residual risk: project wrapper and delegate failures are runtime-specific. The corrected sequence gathers a complete brief before invocation and deterministically continues through the remaining available routes without inventing a static wrapper interface.

The revision 2 worker result is `ready-to-integrate`; it does not claim coordinator integration, central `verified` state, SK-019, VG-001, or another migration item.

Coordinator integration verification completed at `2026-07-14T17:49:53+00:00` against integrated commits `399eea4` and `3a075df`: the complete target and proposal revision 2 were reread; the exact definitions, non-executing route selection, post-brief execution/failure continuation, neutral-diff ownership boundary, strict scoped verdict, secondary findings, fallback disclosure, final-human-acceptance boundary, frontmatter identity, Pi visibility, repo-local provenance, and exact scope passed independent checks. The YAML-aware audit accounted for all 33 skills with zero errors and warnings, `git diff --check` passed, and `bash tests/run.sh` passed all 12 tests. The protected `pi/settings.json` content and diff hashes remained `7d3f4713d7239e8cda3f75597a55f1767fecdf7964324630e4e74dc686d12e05` and `8298a9063e3ebf2988000d176057a41c31cf20c10bbabe92fb57d47f9f2738d5`. Residual risk: wrapper and delegation interfaces remain runtime-specific, with the required disclosed in-process fallback preserved.

## Explicit exclusions

- No edit to `.skill-migration/shared-skill-yagni/MIGRATION.md`, any `.wayfinder/` file, `pi/settings.json`, any spec or glossary, `THIRD_PARTY_NOTICES.md`, `AGENTS.md`, tests, installer/deployment files, agent configs including `codex/agents/image_comparison_judge.toml`, Pi visibility links, `image-diff-describer`, `visual-qa`, another skill/support file, or another proposal.
- No frontmatter/schema/grant redesign, new supporting file, Activity, Reference, helper script, wrapper implementation, subagent implementation, capture/conversion workflow, neutral diff production, general visual-QA theory, universal report schema, score, threshold system, or fixed line-count target.
- No ownership of caller acceptance, final human acceptance, source capture, recording conversion, neutral diff evidence, implementation fixes, central integration state, another migration item, or final catalog verification.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `2`
- Authorization effect: the standing no-approval directive and coordinator correction authorize only the exact proposal and target paths and changes enumerated in revision 2.
- Scope check: `PASS — revision 1 commit and coordinator finding → MAP → WF-007 → complete WF-005 target record → WF-008 → WF-006 → current specs/glossary → verified write-a-skill and audit-shared-skills → complete target and neutral-diff owner → provenance notices/history → command-help applicability were reviewed in the mandated order. Exact files, complete behavior ledger, non-executing route selection, post-brief execution and failure continuation, neutral-evidence ownership, verdict and human-acceptance boundaries, contradiction repair, provenance/license status, exclusions, and verification are fixed. Production editing may continue autonomously without a per-item approval wait.`

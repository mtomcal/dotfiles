---
id: SK-021
target: image-diff-describer
status: verified
blocked-by: [SK-001]
source-verdict: Retain substance while adding confirmed language and colocating the no-verdict output contract with production
---

# Image Diff Describer: retain the neutral-diff contract

## Why this item is next

SK-001 is verified and owns the canonical body contract. WF-007 places `image-diff-describer` in direct normalization (D4) with a retain verdict. The current HEAD `5cd3e4b8497ae0c0c3686654d104a7c93b711cb6` is the SK-021 claim baseline; its only change from its parent is coordinator-owned migration state, which this item must not edit.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` — SK-021 belongs to the audited 33-skill catalog; production rewriting was deferred to this migration.
- WF-007 — retain the no-verdict neutral diff contract, colocate the output schema with production, and keep `image-diff-describer` as owner of `neutral diff artifact`.
- Complete WF-005 `image-diff-describer` record — self-contained artifact workflow; preserve path gathering, raw-comparison delegation, observable-only comparison, structured return, five output fields, prohibited judgments, explicit ambiguity, delegation brief, and wrapper precedence.
- WF-008 — exact confirmed meanings for Neutral diff artifact, Raw diffing, Verdict, and Visual ambiguity; this skill owns neutral diff artifacts.
- WF-006 — neutral evidence remains an independent inline no-verdict contract; consumers retain paths and scope while withholding criteria; visual composition is capture → optional conversion → neutral diff → general QA or scoped judgment → caller/human acceptance.
- `specs/UBIQUITOUS_LANGUAGE.md` version `0.7.0`, `specs/ai-agent-config.md` version `2.3.0`, `specs/SPEC-OF-SPECS.md` version `1.1.0`, and `specs/README.md` version `0.5.0` — skill-local terms belong in the owning body; canonical order, semantic YAGNI, behavior-preservation, visual-stage ownership, frontmatter, and Pi visibility are normative.
- Verified `shared/skills/write-a-skill/SKILL.md` — material revisions require a behavior-preservation ledger, one routed Workflow, local guardrails/output/completion rules, semantic YAGNI, provenance review, and exact verification. Verified `shared/skills/audit-shared-skills/SKILL.md` owns only union-frontmatter validation.
- Complete current `shared/skills/image-diff-describer/SKILL.md` and adjacent visual-owner bodies `image-comparison-judge`, `visual-qa`, `video-to-contact-sheet`, and `playwright` — the target produces neutral evidence but does not capture, convert recordings, perform general acceptance QA, or issue scoped PASS/FAIL judgments.
- `THIRD_PARTY_NOTICES.md` and complete target history (`0152596`, `353218e`) — the target was introduced locally, has no evidenced imported source or target-specific attribution, and requires no notice change. Playwright's separate Apache provenance does not transfer through composition.
- Repository search found no target-owned wrapper, script, executable, or support file. The wrapper rule is project-conditional, so no executable help/source applies to this migration. `pi/skills/image-diff-describer` is the tracked symlink `../../shared/skills/image-diff-describer` and must remain unchanged.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-021-image-diff-describer.md` — record the exact authorized migration, preservation ledger, verification evidence, state, and residual risks.
- `shared/skills/image-diff-describer/SKILL.md` — normalize only the target body while preserving its frontmatter and neutral-diff behavior.

## Proposed changes

### Add

- Add `Language Definitions` with the four WF-008-confirmed operational definitions: Neutral diff artifact, Raw diffing, Verdict, and Visual ambiguity.
- Add explicit in-process fallback when neither a repo-local wrapper nor raw-comparison delegate is available; this makes the existing direct-comparison path checkable without changing ownership.
- Add a completion criterion requiring all five output fields, explicit uncertainty, and absence of applied criteria, severity, recommendations, or verdict.

### Change or move

- Move the unheaded invocation sentence into the opening of one routed `Workflow` without changing the frontmatter trigger or the bias-resistant-diff-versus-verdict distinction.
- Keep the four current stages in order: gather paths and comparison scope; select wrapper/delegate/in-process execution while withholding criteria; compare observable evidence; save or return the structured artifact.
- Move wrapper precedence and the complete delegation brief beside execution selection. Preserve reference path, candidate paths, full-scene/asset-only/HUD-only scope, raw-diff-only instruction, no verdict, and the ban on exposing acceptance criteria, forbidden elements, or expected outcomes.
- Move all five required output fields and all five output rules beside artifact production. Preserve no PASS/FAIL, no blocking/non-blocking classification, no project criteria except quoting requested visible text, no hidden-goal implementation recommendations, and explicit ambiguity.

### Remove

- Remove only the redundant unheaded invocation sentence and the noncanonical `Output rules`, `Required output`, and `Delegation Brief` level-two headings after every behavior is colocated in the single Workflow.
- Add no Activity, Reference, support file, tool, capture behavior, visual-acceptance behavior, severity model, recommendation behavior, or universal report schema.

## Proposed skill shape

1. `Language Definitions` — present; exactly the four confirmed image-diff terms and ownership boundary.
2. `Workflow` — present; one four-stage neutral-diff production process with routing at execution selection and the output contract beside production.
3. `Activities` — omitted; no operation is independently selected outside the required artifact workflow.
4. `Reference` — omitted; the compact contract is self-contained and has no support file.

## Behavior-preservation checklist

- [x] Frontmatter `name`, description, short description, and `allowed-tools: read,bash` remain byte-identical; the description retains its exact `Use when` triggers.
- [x] Invocation remains a bias-resistant, neutral visual description requested before a separate judge, reviewer, or downstream criteria pass.
- [x] Input gathering retains reference image path and candidate image paths.
- [x] Comparison scope retains full-scene, asset-only, and HUD-only choices.
- [x] A repo-local wrapper, when present, still takes precedence over improvising a prompt.
- [x] Raw-comparison delegation remains conditional on availability and receives the full brief without acceptance criteria, forbidden elements, or expected outcomes.
- [x] Direct in-process comparison remains the fallback and does not claim an independent delegate.
- [x] Comparison remains limited to observable visual differences and explicitly reports ambiguity or low confidence.
- [x] The skill issues no PASS/FAIL verdict, severity/blocking classification, criteria-based judgment, or hidden-goal implementation recommendation.
- [x] The project-specific-criteria exception remains limited to requested quotation as visible text.
- [x] Structured output retains exactly the five required fields: evidence checked; overall composition differences; detailed differences by category; highest-salience visual deltas; ambiguities or low-confidence reads.
- [x] The completed artifact is saved or returned for a separate reviewer or judge; this skill retains artifact ownership but not downstream acceptance authority.
- [x] No capture, recording conversion, general visual QA, scoped judgment, or final human acceptance ownership moves into this skill.
- [x] Frontmatter ownership, provenance state, target location, Pi symlink visibility, and conditional wrapper behavior remain unchanged.

## Dependencies, provenance, and risks

- SK-001 is already verified; no additional production dependency blocks this direct normalization.
- The target is repository-local based on its complete Git history and absence from `THIRD_PARTY_NOTICES.md`; no provenance or license file changes are authorized.
- Risk: definitions could accidentally broaden neutral description into judgment. Mitigation: retain the observable-only rule and colocate all prohibited outputs with artifact production.
- Risk: `highest-salience` could be mistaken for severity. Mitigation: retain it only as a visual-attention output category while explicitly forbidding severity and blocking classification.
- Risk: wrapper precedence or delegate bias controls could disappear during heading consolidation. Mitigation: preserve both beside execution selection and verify each phrase semantically against baseline.
- Risk: exact definitions add text to a compact retained skill. Mitigation: semantic YAGNI, not line count, governs; no optional section or handbook detail is invented.

## Verification

- `git diff --check` — no whitespace errors.
- Parse frontmatter with a YAML-aware parser and compare it byte-for-byte with baseline `5cd3e4b:shared/skills/image-diff-describer/SKILL.md`; validate the union schema and exact `Use when` trigger.
- Parse level-two headings — expect exactly `Language Definitions` then `Workflow`; assert `Activities`, `Reference`, and the three old output/delegation headings are absent.
- Compare the resulting body against the checklist and baseline, including wrapper precedence, all delegation fields, all five output rules, all five output fields, explicit ambiguity, save/return behavior, and the separate-reviewer boundary.
- Search the target for prohibited authority and verify each occurrence is a prohibition or boundary: PASS/FAIL, blocking/non-blocking, acceptance criteria, severity, recommendation, and verdict.
- Run the repository's YAML-aware full-catalog union-frontmatter audit defined by `audit-shared-skills`; require zero new target findings and report any unrelated baseline findings without editing them.
- `test "$(readlink pi/skills/image-diff-describer)" = '../../shared/skills/image-diff-describer' && test -f pi/skills/image-diff-describer/SKILL.md` — Pi visibility remains resolving and unchanged.
- `git diff --name-only 5cd3e4b..HEAD` plus worktree status — only the exact proposal and target production file may change; `.skill-migration/shared-skill-yagni/MIGRATION.md` remains baseline claim state and `pi/settings.json` remains untouched.

## Implementation and verification record

Worker verification completed at `2026-07-14T17:53:05+00:00`.

- Proposal-before-edit control: revision 1 reached committed `proposal-ready` state at `7be0c97` with the exact proposal/target file set before production editing. No material file-set, authority, ownership, provenance, behavior, or removal revision was needed; the same revision now records `ready-to-integrate`.
- Actual production diff: `shared/skills/image-diff-describer/SKILL.md` has 34 insertions and 24 removals relative to claim baseline `5cd3e4b8497ae0c0c3686654d104a7c93b711cb6`; its resulting SHA-256 is `659a7e87be6ede21069abd9a91bda4a525635efab8924310a3f279b5d7aa9714`. This proposal is the only additional item-local file.
- Complete-file and behavior-ledger review: PASS. All triggers, image paths, comparison scopes, wrapper precedence, delegate brief fields, in-process fallback, observable-only comparison, ambiguity handling, output prohibitions, five output fields, save/return behavior, ownership, and separate-reviewer boundary remain inline.
- Canonical body and confirmed language: PASS. Level-two headings are exactly `Language Definitions` then `Workflow`; no `Activities` or `Reference` is invented. All four WF-008 definitions appear once with exact wording, and the one Workflow retains four ordered stages with local observable completion criteria.
- Neutrality and output authority: PASS. Raw comparison receives no acceptance criteria, forbidden elements, or expected outcomes. The resulting artifact cannot issue PASS/FAIL, blocking/non-blocking or severity classification, applied criteria, recommendations, or a verdict; the visible-text quotation exception and explicit low-confidence reporting remain intact. `highest-salience` remains an observation category rather than severity.
- Routing, delegation, and wrapper behavior: PASS. A project-local wrapper still precedes prompt improvisation; an available raw-comparison delegate receives only the complete neutral brief; otherwise the workflow compares in process without claiming independent delegation.
- Frontmatter and tool grants: PASS. The opening YAML block is byte-identical to baseline. PyYAML 6.0.1 parsed all fields; `read` remains needed for image evidence and `bash` for project wrapper/path discovery and invocation. No schema, description, trigger, or tool grant changed.
- Baseline-aware union audit: PASS. PyYAML 6.0.1 parsed and accounted for all 33 baseline and all 33 result skill frontmatters; both report zero errors and zero warnings for required fields, description length, and exact `Use when` phrase. Manual target grant review found no unused grant.
- Support, executable, provenance, and visibility review: PASS. The target has no links, support files, target-owned scripts, fixed command syntax, or repository-local wrapper to validate. Complete history confirms repository-local introduction at `0152596` and only the later frontmatter update at `353218e`; no target notice or license change is required. `pi/skills/image-diff-describer` remains the resolving `../../shared/skills/image-diff-describer` symlink.
- Repository and exact-scope verification: PASS. `bash tests/run.sh` passed both shell files and all 12 tests; scoped `git diff --check` passed. Baseline-aware inspection contains exactly this proposal and target. No diff exists in `MIGRATION.md`, `pi/settings.json`, specs, notices, adjacent skills, scripts, wrappers, deployment, tests, or Pi visibility paths, and no live Herdr ID is persisted.
- Residual risk: a future project-local wrapper may have its own transport interface that must be discovered at invocation time; this repository has no wrapper whose help can be checked now. The retained rule requires that wrapper to preserve the same no-criteria brief. `Highest-salience` may be misread as severity, but the adjacent prohibition and artifact definition explicitly disallow severity classification.

The worker result is `ready-to-integrate`; this record does not claim coordinator integration, coordinator verification, or catalog-wide VG-001 completion.

Coordinator integration verification completed at `2026-07-14T17:58:36+00:00` against integrated commits `694b344` and `bdfabaf`: the complete target and proposal were reread; all four definitions, neutral ownership, wrapper/delegate/in-process routes, withheld criteria, observable-only comparison, ambiguity handling, five output fields, no-verdict/severity/recommendation rules, frontmatter identity, Pi visibility, repo-local provenance, and exact scope passed independent checks. The YAML-aware audit accounted for all 33 skills with zero errors and warnings, `git diff --check` passed, and `bash tests/run.sh` passed all 12 tests. The protected `pi/settings.json` content and diff hashes remained `7d3f4713d7239e8cda3f75597a55f1767fecdf7964324630e4e74dc686d12e05` and `8298a9063e3ebf2988000d176057a41c31cf20c10bbabe92fb57d47f9f2738d5`. Residual risks remain the runtime-specific interface of any future wrapper and possible misreading of highest-salience as severity, explicitly bounded by the no-severity contract.

## Explicit exclusions

- `.skill-migration/shared-skill-yagni/MIGRATION.md`, `pi/settings.json`, all Pi symlinks, adjacent visual skills, specs, provenance notices, scripts, wrappers, and supporting references.
- Any fixed line or word target, frontmatter redesign, new tool grant, new wrapper, subagent implementation, image capture/conversion, acceptance criteria, severity, recommendations, verdicts, or final human acceptance.
- Persisting live Herdr workspace, tab, pane, or agent IDs anywhere.
- Coordinator-only `integrating` or `verified` state and any claim that the coordinator verified this item.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization effect: the standing directive removes the per-item approval wait but authorizes only the exact two-file set and changes enumerated above.
- Scope check: `PASS — MAP → WF-007 → complete WF-005 target record → WF-008 → WF-006 → current specs/glossary → verified write-a-skill and audit-shared-skills → complete target and adjacent visual-owner bodies → provenance/notices/complete target history → executable/wrapper applicability were read in order; exact two-file scope, complete behavior ledger, no-verdict ownership, wrapper/delegation/fallback behavior, ambiguity/output contracts, contradiction review, provenance/license status, frontmatter, Pi visibility, exclusions, and verification criteria were checked. Production editing may continue autonomously under the standing directive.`

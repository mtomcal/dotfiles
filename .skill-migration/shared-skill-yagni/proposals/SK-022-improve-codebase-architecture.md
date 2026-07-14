---
id: SK-022
target: improve-codebase-architecture
status: ready-to-integrate
blocked-by: [SK-001, SK-013]
source-verdict: simplify inline
---

# Improve Codebase Architecture: normalize one evidence-to-selection workflow

## Why this item is next

SK-001 and SK-013 are verified, so SK-022 is unblocked in the D4 direct-normalization sequence. The item is claimed at baseline `51a3bde4d74c95205ab8fc9903b18db086b63f3f`; its exact file set is disjoint from concurrently claimed SK-021. The verified `codebase-design` contract now durably owns the architecture vocabulary, deletion/adaptor/test-surface rules, Deepening branch, and Design It Twice branch that this skill composes.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes a preserve-before-prune destination and excludes production changes from Wayfinder, frontmatter redesign, deployment, and Pi visibility changes.
- WF-007 assigns `improve-codebase-architecture` **simplify inline**: remove repeated design-skill loading while retaining the temporary HTML decision surface and the candidate-selection gate, after `codebase-design` ownership is durable.
- The complete WF-003 target record supplies the behavior ledger: prefer user-named pain or rank meaningful Git hotspots; read the spec entry points, glossary, relevant specs, and repository-native design records; inspect every named friction signal; apply deletion, adaptor, and interface-as-test-surface checks with Herdr or direct fallback; always load the report schema and create a temporary candidate comparison with before/after diagrams; ask the user to select; clarify constraints, invariants, migration, and tests; optionally use Design It Twice; record durable decisions; and stop before implementation.
- WF-008 confirms the only skill-local terms: **Hotspot evidence**, **Architecture candidate**, and **Spec tension**. General Module, Interface, Implementation, Depth, Seam, Adapter, Leverage, and Locality vocabulary remains owned by `codebase-design` and must not be redefined here.
- WF-006 keeps ranking and selection gates with their domain workflow owner, output/report contracts with their producer, read-only Herdr transport with an in-process fallback, checkout isolation before editable delegation, and repository-level provenance. Composition imports `codebase-design` process without transferring this skill's report location, candidate-selection gate, decision recording, or user approval boundary.
- `specs/ai-agent-config.md` 2.3.0 requires the canonical body order, one route-first Workflow, local guardrails/outputs/completion criteria, behavior-preservation coverage, transport fallback and isolation, and specifically requires this skill to always produce a temporary visual HTML report with before/after diagrams and candidate comparison. `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 leaves skill-local terms in the owner body and makes project glossary language authoritative. `specs/README.md` and `specs/SPEC-OF-SPECS.md` remain the target workflow's required suite entry points.
- Verified `shared/skills/write-a-skill/SKILL.md` requires this ledger, canonical sections, one routed Workflow, conditional Reference wording, checkable completion, semantic rather than line-count YAGNI, and provenance checks.
- Verified `shared/skills/codebase-design/SKILL.md` defines all imported architecture terms and routes consequential/requested alternatives to Design It Twice. Its unchanged `DEEPENING.md` owns dependency categories and the deletion/consolidation path; `DESIGN-IT-TWICE.md` owns at least three independent complete interfaces and a falsifiable recommendation. This target must load that skill once, then follow the already-loaded Design It Twice branch only when useful.
- The complete target and `HTML-REPORT.md` agree. The support file owns the HTML skeleton, badges, candidate-card fields, comparison axes, diagram patterns, and visual tone. No contradiction, stale syntax, or support-file change is evidenced.
- Git history shows an initial local version at `14d5c80cc86c440d45e84cd636aeaef310c2683d`, migration into shared skills at `4fcd8db204888b46ef857ea16732bcb2e4ab201b`, and the current target/report adaptation at `3b59c13906d5d7922ed236b19cfe548138f429d7`. `THIRD_PARTY_NOTICES.md` records `improve-codebase-architecture` as a locally maintained adaptation of `mattpocock/skills` revision `66898f60e8c744e269f8ce06c2b2b99ce7660d5f` and reproduces the MIT license. Attribution is complete and unchanged.
- No executable syntax changes. Git-history inspection, `${TMPDIR:-/tmp}` output, platform-opener attempt, and Herdr composition remain behavior rather than a new fixed command interface; current command mechanics stay delegated to Git, the host platform, and the verified `herdr` skill.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-022-improve-codebase-architecture.md` — item-local authorization, behavior ledger, checks, and final worker state.
- `shared/skills/improve-codebase-architecture/SKILL.md` — add confirmed definitions and normalize the current four numbered sections into the canonical single Workflow plus mandatory report Reference.

`shared/skills/improve-codebase-architecture/HTML-REPORT.md`, all `codebase-design` files, specs, notices, and Pi visibility are verification-only and remain unchanged.

## Proposed changes

### Add

- Add `Language Definitions` containing the exact WF-008 meanings of Hotspot evidence, Architecture candidate, and Spec tension, plus an ownership statement that general architecture vocabulary remains with `codebase-design`.
- At Workflow entry, load `codebase-design` exactly once before scoping or design analysis; later alternative-interface work follows its already-loaded Design It Twice branch without a repeated load instruction.
- Add an explicit Workflow completion criterion that the selected candidate has user-approved interface or implementation-plan authority before any implementation can start; until then the workflow stops at decision/design exploration.

### Change or move

- Preserve frontmatter byte-for-byte, including every architecture/deepening/coupling/testability/AI-navigation trigger and `read,write,edit,bash` grants.
- Move the four numbered level-two sections under one `Workflow` while preserving their order: scope from intent/history, explore evidenced friction, create the mandatory report, then explore only the user-selected candidate.
- Keep user-named pain first; otherwise inspect a meaningful Git range, rank repeatedly changing files/subsystems, and widen only after ranking. Keep required spec indexes, glossary, relevant specs, native design records, domain language, and invariants local to scoping.
- Keep every exploration signal and design test local to candidate production: understanding spread, shallow modules, leaking seams, duplicated orchestration, pass-throughs, internal-test coupling, scattered edits, deletion test, justified adaptors, and caller/test interface parity.
- Keep Herdr read-only explorers optional only under `HERDR_ENV=1`, permit shared checkout for read-only work, retain direct in-process fallback, and retain isolated clone/worktree for any editing delegate.
- Keep the report fresh, static, outside the repository at `${TMPDIR:-/tmp}/architecture-review-<timestamp>.html`; keep scope/hotspot evidence, all-candidate comparison, complete candidate cards, side-by-side before/after diagrams, recommendation strength, spec tension, and top recommendation/rationale. Keep Mermaid versus hand-built HTML/SVG selection, platform opener attempt, absolute-path output even on opener failure, and no report material in the repository.
- Move the sole Markdown pointer to `Reference`, with a mandatory load condition before report production and a reason naming the schema, cards, diagrams, comparison, and visual conventions it owns.
- Keep selection and approval beside the final step: ask which candidate to explore; clarify constraints, dependencies, preserved invariants, migration, and tests; use Design It Twice when alternatives help; record durable domain/design decisions in the relevant spec; offer to record a rejection only when its rationale prevents rediscovery; and do not implement before candidate selection plus interface or implementation-plan approval.

### Remove

- Remove the unsectioned introductory summary after its evidence-before-interface ordering and architecture-vocabulary ownership are retained in Language Definitions and Workflow entry.
- Remove only the second instruction to load `codebase-design`; replace it with a pointer to the already-loaded Design It Twice branch.
- Remove the four numbered level-two headings after their actions, branches, guards, outputs, and completion criteria move under one canonical Workflow.
- Remove no trigger, hotspot/ranking rule, spec/design-record input, friction signal, design test, transport/fallback/isolation rule, report field, report visual, report path/cleanup rule, selection gate, approval boundary, decision-recording route, output, ownership rule, or completion condition.

## Proposed skill shape

1. `Language Definitions` — the three confirmed skill-local terms and explicit delegation of general architecture vocabulary to `codebase-design`.
2. `Workflow` — present; one ordered evidence → candidates → mandatory visual comparison → user selection/design process, with route selection first and all local gates and completion evidence retained.
3. `Activities` — omitted; Git scoping, exploration, report production, and selected-candidate design are required stages or branches of the one process, not independently selected recipes.
4. `Reference` — present; one mandatory conditional pointer to `HTML-REPORT.md` before producing the temporary decision surface, naming the report details it owns.

## Behavior-preservation checklist

- [x] Frontmatter retains all current triggers, short description, and tool grants byte-for-byte.
- [x] Hotspot evidence, Architecture candidate, and Spec tension retain the exact human-confirmed meanings; no imported architecture term is redefined.
- [x] `codebase-design` remains the sole owner of Module, Interface, Implementation, Depth, Seam, Adapter, Leverage, and Locality and is loaded exactly once before use.
- [x] User-named area or pain remains the first scoping route.
- [x] Without user scope, a meaningful Git-history range is inspected and repeatedly changing files/subsystems are ranked before widening.
- [x] Scope states why it is likely to repay deepening work and cites relevant constraints.
- [x] `specs/README.md`, `specs/SPEC-OF-SPECS.md`, `specs/UBIQUITOUS_LANGUAGE.md`, relevant specs, and linked repository-native design records remain required when present; project domain terms and invariants govern.
- [x] Exploration retains understanding spread, shallow modules, leaking seams, duplicated orchestration, pass-through modules, internal-test coupling, and scattered-edit friction signals.
- [x] The deletion test, justified-adaptor check, and same-interface-for-callers-and-tests check remain required.
- [x] Under `HERDR_ENV=1`, the workflow loads `herdr` and prefers parallel read-only explorers for independent areas/hypotheses; outside Herdr it executes directly in-process.
- [x] Read-only delegates may share the checkout, while every editing delegate requires an isolated clone or worktree; transport does not transfer acceptance or workflow ownership.
- [x] Every Architecture candidate names files, observed friction, spec constraints, direction, and plausible gain in depth, leverage, locality, or test surface.
- [x] The report remains mandatory for every invocation and `HTML-REPORT.md` remains mandatory to load before producing it.
- [x] Every report is a fresh static HTML file under `${TMPDIR:-/tmp}` with the required timestamped architecture-review name and remains outside the repository.
- [x] Report scope and Hotspot evidence remain visible.
- [x] The report compares all candidates and gives each one files, problem, deepening direction, benefits, recommendation strength, Spec tension, and side-by-side before/after diagrams.
- [x] The report retains a top recommendation with rationale and the support-owned candidate badges, dependency category, comparison axes, diagram patterns, and evidence-specific visual tone.
- [x] Mermaid remains preferred for graph-shaped relationships and hand-built HTML/SVG for module depth; diagrams remain readable and carry the before/after argument.
- [x] The workflow attempts the platform opener, always reports the absolute report path even when opening fails, and persists none of the report in the repository.
- [x] The user must select a candidate before selected-candidate design exploration continues.
- [x] Selected-candidate exploration retains constraints, dependencies, preserved invariants, migration, and tests.
- [x] Alternative interfaces follow the already-loaded `codebase-design` Design It Twice branch without repeated skill loading.
- [x] Durable domain/design decisions go to the relevant spec; rejected rationale is offered for recording only when it prevents future rediscovery.
- [x] No refactor implementation starts until the user selects a candidate and approves its interface or implementation plan.
- [x] The HTML support contract, provenance/license notice, relative link, and Pi visibility remain intact.

## Dependencies, provenance, and risks

- SK-001 and SK-013 are verified at the claim baseline; there is no pending owner-interface decision. The final `codebase-design` route already makes Design It Twice mandatory for consequential interfaces or requested alternatives and keeps Deepening composable when dependency classification applies.
- No current authority contradiction exists. The only audited YAGNI issue is repeated `codebase-design` loading; normalization must not weaken its design tests or this skill's report and selection ownership.
- `HTML-REPORT.md` is earned mandatory progressive disclosure. Moving or shortening its schema would be material and is neither needed nor authorized.
- The temporary report is deliberately an execution artifact, not a repository file. Verification checks that the contract says to cleanly keep it outside the repository; this migration does not generate or commit a sample report.
- Provenance and the reproduced MIT license are complete in `THIRD_PARTY_NOTICES.md`; no notice edit is authorized.
- Runtime availability of Herdr and platform openers varies. The existing direct exploration fallback, opener-failure tolerance, and unconditional absolute-path return remain the risk controls; no static executable syntax is introduced.

## Verification

1. Reread the complete resulting `SKILL.md`, unchanged `HTML-REPORT.md`, verified `codebase-design/SKILL.md`, `DEEPENING.md`, and `DESIGN-IT-TWICE.md`; map every WF-003 ledger item and every checklist item above to an inline or approved owner location.
2. Inspect level-two headings; expect exactly `Language Definitions`, `Workflow`, then `Reference`, with no Activity or unapproved section.
3. Compare definitions to WF-008; expect exactly the three skill-local meanings and no redefinition of general architecture vocabulary.
4. Compare target frontmatter byte-for-byte with baseline `51a3bde4d74c95205ab8fc9903b18db086b63f3f`; expect no change.
5. Count `codebase-design` load instructions; expect exactly one load at Workflow entry and a later instruction only to follow its already-loaded Design It Twice branch.
6. Confirm route/order and local gates: user scope or Git ranking → spec/design evidence → friction/design tests with Herdr/direct parity → mandatory report → user selection → constraints/invariants/migration/tests → optional alternatives/decision recording → implementation stop pending approval.
7. Confirm the report contract retains outside-repository timestamped path, schema load, all-candidate comparison, every candidate field, readable side-by-side before/after diagrams, top recommendation, opener attempt, absolute-path return on failure, and no repository persistence.
8. Resolve every relative Markdown link one level deep; expect `HTML-REPORT.md` and its contract to remain present and coherent.
9. Run the complete YAML-aware `audit-shared-skills` union-frontmatter audit; expect all 33 skills parsed and accounted for with zero errors and zero warnings, including a manual least-tool check for this target.
10. Run `test -L pi/skills/improve-codebase-architecture && test "$(readlink pi/skills/improve-codebase-architecture)" = '../../shared/skills/improve-codebase-architecture' && test -e pi/skills/improve-codebase-architecture/SKILL.md`; expect unchanged resolving Pi visibility.
11. Recheck target/support Git history and `THIRD_PARTY_NOTICES.md`; expect the recorded upstream revision and reproduced MIT attribution to remain complete without a notice diff.
12. Run `git diff --check -- .skill-migration/shared-skill-yagni/proposals/SK-022-improve-codebase-architecture.md shared/skills/improve-codebase-architecture/SKILL.md`.
13. Run `bash tests/run.sh`; expect all repository shell tests to pass.
14. Compare baseline-aware tracked and untracked paths; expect exactly this proposal and target, with no diff in `MIGRATION.md`, `.wayfinder/`, specs/glossaries, notices, tests, deployment/discovery/visibility paths, any codebase-design or HTML support file, `pi/settings.json`, another skill, or another proposal.

Acceptance requires exact two-file scope, canonical three-section body, all three confirmed definitions, unchanged frontmatter, exactly one design-skill load, preserved evidence/ranking/candidate/report/selection/approval contracts, unchanged mandatory HTML support, clean union audit, resolving Pi visibility, clean diff checks, and passing repository tests.

## Implementation and verification record

- Worker verification timestamp: `2026-07-14T17:56:30+00:00`.
- Proposal-before-edit control: PASS. Revision 1 was created in `drafting`, then reached `proposal-ready` with the standing directive, exact two-file scope, complete behavior ledger, ownership and contradiction review, provenance/license evidence, and verification plan before the production target changed.
- Exact scope: PASS. Relative to claim baseline `51a3bde4d74c95205ab8fc9903b18db086b63f3f`, only this proposal and `shared/skills/improve-codebase-architecture/SKILL.md` differ. The migration ledger, Wayfinder records, specs/glossaries, notices, HTML report support, all `codebase-design` files, tests, deployment/discovery, Pi visibility, every Pi file including `pi/settings.json`, other skills, and other proposals are unchanged.
- Canonical shape and language: PASS. Level-two headings are exactly `Language Definitions`, `Workflow`, and `Reference`; no Activity is invented. Hotspot evidence, Architecture candidate, and Spec tension retain WF-008 semantics, and general architecture vocabulary remains delegated to `codebase-design`.
- Composition: PASS. `codebase-design` has exactly one load instruction at Workflow entry. Selected alternative-interface work follows its already-loaded Design It Twice branch, preserving composition without repeated loading or ownership transfer.
- Evidence, ranking, and candidate gates: PASS. User pain remains first; otherwise meaningful Git history is ranked before widening. Required spec/design sources, every audited friction signal, deletion/adaptor/test-surface checks, Herdr read-only/direct fallback parity, editing isolation, and per-candidate files/friction/constraints/direction/gain evidence remain inline.
- Visual decision surface: PASS. The HTML report remains mandatory, fresh, timestamped, outside the repository, and governed by the mandatory `HTML-REPORT.md` pointer. Scope/Hotspot evidence, all-candidate comparison, complete candidate cards, recommendation strength, Spec tension, side-by-side Before/After diagrams, top recommendation, Mermaid/HTML/SVG choice, opener attempt, absolute-path output on failure, and no repository persistence remain intact. The unchanged support retains badges, dependency category, comparison axes, diagram patterns, and evidence-specific visual tone.
- Selection, approvals, outputs, and durable ownership: PASS. The workflow asks the user to select one candidate, clarifies constraints/dependencies/invariants/migration/tests, conditionally follows Design It Twice, records durable decisions in the relevant spec, limits rejection recording to load-bearing rationale, and stops before implementation until candidate and interface or implementation-plan approval.
- Frontmatter and audit: PASS. Frontmatter is byte-identical to baseline. PyYAML parsed and accounted for all 33 shared skills; the complete union-schema audit reported zero errors and zero warnings. Manual least-tool review retains `read` for source/spec/report evidence, `bash` for Git/history/opener operations, and `write`/`edit` for the temporary report and approved durable decision recording.
- Links, visibility, provenance, and commands: PASS. Every target and `codebase-design` Markdown link resolves one level deep; `pi/skills/improve-codebase-architecture` still resolves through `../../shared/skills/improve-codebase-architecture`. History remains traceable from local commit `14d5c80cc86c440d45e84cd636aeaef310c2683d` through current adaptation commit `3b59c13906d5d7922ed236b19cfe548138f429d7`; the Matt Pocock revision and reproduced MIT license remain complete in `THIRD_PARTY_NOTICES.md`. No fixed executable syntax changed, so no command-help correction was applicable.
- Repository checks: PASS. `git diff --check` is clean and `bash tests/run.sh` passes both shell files and all 12 tests.
- Resulting target SHA-256: `f18a0eb1074362194a3969206cc5b4b6a40ef6b574b2425a65797852fca1f3cd`.
- Residual risk: runtime Herdr and platform-opener availability vary by environment. The preserved in-process exploration fallback, opener-failure tolerance, mandatory absolute-path return, and unchanged support contract bound that risk. No report was generated during this documentation migration because doing so would exercise rather than verify the shipped workflow and would create no production evidence beyond the complete contract review.

This worker result is `ready-to-integrate`; it does not claim coordinator integration, central `verified` state, SK-021, VG-001, or another migration item.

## Explicit exclusions

- No edit to `.skill-migration/shared-skill-yagni/MIGRATION.md`, any `.wayfinder/` file, `pi/settings.json`, any spec/glossary, `THIRD_PARTY_NOTICES.md`, `AGENTS.md`, tests, installer/deployment files, agent config/discovery, Pi visibility links, `HTML-REPORT.md`, any `codebase-design` file, another skill/support file, or another proposal.
- No frontmatter/schema/grant redesign, new architecture or project term, new support file, Activity, script, fixed Git range, fixed platform-opener syntax, copied Herdr command, generated report fixture, architecture implementation for this repository, or fixed line-count target.
- No weakening of candidate evidence, ranking, recommendation strength, Spec tension, temporary output, before/after visual, all-candidate comparison, selected-candidate approval, decision ownership, provenance, license, cleanup, in-process fallback, or isolation behavior.
- No claim that this worker performs coordinator integration, central verification, SK-021, VG-001, or another migration item.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization effect: the standing no-approval directive applies only to the exact proposal and target paths and exact changes enumerated in revision 1.
- Scope check: `PASS — MAP → WF-007 → complete WF-003 target record → WF-008 → WF-006 → current specs/glossary → verified write-a-skill and codebase-design → complete target and directly linked support files → provenance/notices/history → executable-help applicability were read in order. Exact files, complete behavior ledger, single-load composition, report and selection ownership, approval boundaries, contradiction review, provenance/license coverage, exclusions, and verification criteria were checked. Production editing may continue autonomously under the standing directive.`

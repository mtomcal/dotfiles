---
id: SK-025
target: tdd
status: verified
blocked-by: [SK-001, SK-013]
source-verdict: simplify inline
---

# TDD: route execution mode first and retire duplicate refactoring support

## Why this item is next

SK-001 and SK-013 are verified at claim baseline `231fb3864602055e88f28f07be3b32037d0656d9`. They now own canonical skill authoring and seam/interface vocabulary, so WF-007's D4 `tdd` simplification is unblocked. The target can route normal versus discovered-bug mode first, colocate its test-first gates, retain earned example and external-seam support, and retire only refactoring guidance whose live heuristics are mapped before deletion.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes the preserve-before-prune destination and excludes frontmatter redesign, deployment, and Pi visibility changes.
- WF-007 assigns `tdd` **simplify inline**: route normal versus discovered-bug mode first, colocate guardrails, and retire only duplicate reference content after seam ownership aligns with `codebase-design`; test-quality audit remains separate.
- The complete WF-003 `tdd` record supplies the behavior ledger: read guidance/specs/glossary; load design guidance for interface changes; preserve normal pre-agreement and the disclosed discovered-bug exception; agree or state the interface, seam, behavior order, independent expected result, and command; run one honest end-to-end tracer bullet; observe intended Red; implement minimal Green; run focused and nearby checks; repeat one behavior test at a time with the complete per-cycle checklist; refactor only while green; require approval for seam changes; and finish only after all agreed behavior and broader required checks pass.
- WF-008 confirms the exact definitions of Tracer bullet, Red, Green, Refactor, Independent oracle, Vertical slice, and Discovered-bug fast path. It leaves `Seam` with `codebase-design` rather than permitting a competing local definition.
- WF-006 keeps `tdd` as test-first production owner and `test-quality-verifier` as the separately requested/risk-routed assertion and coverage audit. It assigns architecture vocabulary and seam placement to `codebase-design`.
- `specs/ai-agent-config.md` 2.3.0 and `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 require canonical body sections, routing first, semantic YAGNI, local gates/completion, behavior-preservation coverage, and skill-local language without forking project or owner vocabulary. `AGENTS.md` requires vertical red-green-refactor tracer bullets, one-test cycles, public-interface behavior, minimal code, green-only refactoring, and tests after each refactor.
- Verified `shared/skills/write-a-skill/SKILL.md` requires this ledger, one routed Workflow, conditional Reference pointers, local observable completion, and sentence-level semantic YAGNI. Verified `shared/skills/codebase-design/SKILL.md` defines a seam exactly as a place where behavior can vary without changing the caller, makes callers and behavior tests cross the same interface, forbids exposing an internal seam merely for testing, and owns seam/interface changes. Verified `shared/skills/audit-shared-skills/SKILL.md` owns only complete union-frontmatter validation.
- The complete target and support review finds `tests.md` earns disclosure for public-interface, implementation-coupling, and tautological-oracle examples. `mocking.md` earns disclosure for external-dependency test-adapter recipes, but its generic “system boundaries” language needs alignment with the verified external-seam owner and its existing examples can be made more precise without changing their behavior. `refactoring.md` has six live heuristics: duplication, long methods, shallow modules, feature envy, primitive obsession, and existing code revealed by the change. Every heuristic can be mapped inline to green-only refactoring or to `codebase-design`; no unique workflow remains in the file. Repository search finds its only inbound link in `tdd/SKILL.md`, so deleting it and repairing that link leaves no consumer broken.
- Git history shows all four target files originated locally at `e5d8b9bbc391c6481c2f4d46c1c979c0162a7f30`; the current adapted TDD body and notice were established at `3b59c13906d5d7922ed236b19cfe548138f429d7`, with later trigger and discovered-bug changes at `54285f8f8c38c91a1506e0ccf568a138cd2f5a7e` and `99b4e1720d8ddf98cdcb7be4dfc662fc414655c9`.
- `THIRD_PARTY_NOTICES.md` records `tdd` as a one-time locally maintained adaptation of `mattpocock/skills` revision `66898f60e8c744e269f8ce06c2b2b99ce7660d5f` and reproduces its MIT license. Exact-revision upstream source confirms public-interface tests, pre-agreed seams, independent expectations, vertical tracer bullets, one-slice Red/Green, and no speculative Green. The local repository intentionally retains its own green-only Refactor contract from `AGENTS.md`, rather than adopting upstream's conflicting review-stage-only refactor statement. No notice edit is needed.
- The target ships no executable helper or command syntax. Verification therefore checks repository test commands and links rather than claiming executable help coverage.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-025-tdd.md` — item-local authorization, complete behavior ledger, exact scope, implementation evidence, and worker state.
- `shared/skills/tdd/SKILL.md` — preserve frontmatter, add exact definitions, route normal/discovered-bug mode first, colocate gates and command evidence, map refactoring heuristics, and retain two conditional references.
- `shared/skills/tdd/mocking.md` — align the earned external-dependency recipe with `codebase-design` seam and adapter ownership while retaining dependency-injection and operation-specific adapter examples.
- `shared/skills/tdd/refactoring.md` — delete only after all six live heuristics are mapped into the main green-only Refactor step or the verified architecture owner and its sole inbound link is removed.

`shared/skills/tdd/tests.md`, all three `shared/skills/codebase-design/*.md` files, `AGENTS.md`, specs, and `THIRD_PARTY_NOTICES.md` are verification-only and remain unchanged.

## Proposed changes

### Add

- Add the seven exact WF-008 definitions under `Language Definitions`. State ownership, without locally redefining `Seam`: use the `codebase-design` definition and load that skill whenever choosing or changing a module interface, seam, or depth.
- Begin `Workflow` with explicit mode routing:
  - **Discovered-bug mode** only when diagnosis, intended behavior and its source, and the existing seam are unambiguous. State the observed bug, intended behavior/source, existing seam, smallest regression target, independent oracle, and tight command; proceed without full pre-agreement unless behavior, seam, or risk is ambiguous.
  - **Normal mode** for every other request. After selecting either mode, read repository guidance, relevant specs, and glossary; then perform the mode's stated intake and agreement gates before writing a test.
- Make one honest vertical tracer bullet explicit: one caller-observable end-to-end behavior through the agreed public interface, followed by its minimum cross-layer implementation before another behavior.
- Keep focused, nearby, and broader commands as separate gates: intended Red on the tight focused command; focused plus nearby required checks for Green; broader required checks at completion.
- Map every retired refactoring heuristic inline while green: remove duplication; shorten long methods without testing private helpers; move misplaced logic toward the data it uses; introduce value objects when primitive obsession obscures behavior; combine or deepen shallow modules through `codebase-design`; and address nearby existing code only when the completed behavior exposes evidence. Require tests after each step and user approval plus `codebase-design` before changing an agreed interface or seam.
- Add conditional load wording to the two earned pointers: load `tests.md` when examples are needed to distinguish durable behavior tests, implementation coupling, or tautological expectations; load `mocking.md` when behavior crosses an external dependency and a test adapter may be needed.

### Change or move

- Preserve the complete frontmatter byte-for-byte, including all invocation triggers and `read,write,bash,edit` grants.
- Fold the current introduction, Guardrails, discovered-bug fast path, and five numbered stages into `Language Definitions`, one routed `Workflow`, and `Reference`, colocating each guardrail with the stage it governs.
- Keep behavior tests on caller-observable public outcomes. Keep expected values independent of implementation logic and sourced from specs, worked examples, known literals, trusted external oracles, or disagreeing invariants.
- Keep Red honest: the new test must be observed failing for the missing or broken behavior, not fixture, syntax, or environment setup.
- Keep Green minimal: add only enough behavior for the current test, avoid speculative branches, and do not regress focused tests.
- Keep one-test cycles and the complete checklist: observable behavior at an agreed seam; independent expectation; intended failure observed before implementation; minimal code; focused tests green.
- In `mocking.md`, call the supported variation an external seam and its test substitute a test adapter; prefer a faithful test database, temporary filesystem, or other real local substitute where practical; forbid mocking internal collaborators or exposing internal seams only for testing; retain dependency injection and operation-specific SDK-style examples.

### Remove

- Remove the duplicate standalone `Guardrails` section only after every rule is colocated in routing, Red, Green, Repeat, Refactor, or completion.
- Delete `refactoring.md` only with this revision's complete six-way mapping and sole inbound-link repair. Remove no live heuristic.
- Remove no trigger, mode, agreement gate, exception condition, behavior rule, independent-oracle requirement, intended-Red gate, minimal-Green rule, one-test cycle, checklist item, command tier, seam approval, final completion condition, provenance, license, frontmatter, or visibility behavior.

## Proposed skill shape

1. `Language Definitions` — the seven exact confirmed TDD terms plus an ownership pointer, not a competing definition, for `Seam`.
2. `Workflow` — present; one process routing discovered-bug versus normal mode first, then one tracer bullet and incremental Red/Green cycles, green-only Refactor, and final completion.
3. `Activities` — omitted; Red, Green, Repeat, and Refactor are required phases rather than independently selected recipes.
4. `Reference` — present; earned conditional pointers to `tests.md` for behavior/oracle examples and `mocking.md` for external-seam test-adapter guidance.

## Behavior-preservation checklist

- [x] Invocation still covers test-first behavior implementation, regression fixes, explicit TDD or integration-test requests, and diagnosed bugs needing lock-down.
- [x] Tracer bullet, Red, Green, Refactor, Independent oracle, Vertical slice, and Discovered-bug fast path retain the exact WF-008 definitions.
- [x] `codebase-design` remains the sole owner of the Seam definition and of consequential interface, seam, and module-depth design.
- [x] Both modes read repository guidance, relevant specs, and glossary; normal mode requires agreement on public interface, seams, prioritized behavior, expected result/oracle, and command before testing.
- [x] Discovered-bug mode is selected only for unambiguous diagnosis, intended behavior/source, and existing seam; it states bug, target, seam, oracle, and command and preserves confirmation whenever behavior, seam, or risk is ambiguous.
- [x] Tests describe outcomes callers care about through public interfaces, not private methods, internal calls, or side channels, and survive internal refactoring.
- [x] Every expectation has an independent source capable of disagreeing with the implementation; tautological recomputation remains prohibited.
- [x] The first slice is one honest end-to-end caller-visible behavior through the smallest agreed public interface.
- [x] Red writes one test and observes the intended missing/broken-behavior failure rather than fixture, syntax, or environment failure.
- [x] Green adds only enough behavior for the current test, avoids speculative later branches, and runs focused then nearby required checks.
- [x] Remaining work repeats one behavior test and minimum implementation at a time; all-tests-first horizontal slicing remains prohibited.
- [x] The per-cycle checklist retains all five current checks: observable behavior/agreed seam, independent source, intended prior failure, minimal code, and focused green tests.
- [x] Refactor occurs only while green, tests rerun after every step, behavior remains stable, and any agreed interface/seam change requires user approval and `codebase-design`.
- [x] All six `refactoring.md` heuristics remain mapped: duplication, long methods, shallow modules, feature envy/misplaced logic, primitive obsession, and revealed existing code.
- [x] Completion requires every agreed behavior green, refactoring behavior-preserving, and broader required checks passing.
- [x] `tests.md` remains unchanged and conditionally reachable for public-interface, implementation-coupling, and tautological-oracle examples.
- [x] `mocking.md` remains conditionally reachable for external seams, retains all four external-dependency categories and both design recipes, and does not expose or mock internal seams.
- [x] TDD does not absorb `test-quality-verifier`'s separately requested or risk-routed assertion/coverage audit.
- [x] Matt Pocock source/revision/MIT coverage and Pi visibility remain unchanged.

## Dependencies, provenance, and risks

- SK-001 and SK-013 are verified in the claim baseline. This proposal consumes their authoring and architecture contracts without editing either owner.
- The local `AGENTS.md` green-only Refactor rule is authoritative over the exact-revision upstream sentence that excludes refactoring from the loop. The resulting body preserves repository behavior and records the imported source without silently choosing upstream behavior.
- `mocking.md` currently says “system boundaries,” while the verified owner classifies dependencies and defines seams. The scoped wording change preserves the same examples but removes a vocabulary fork and makes the no-internal-test-seam rule explicit.
- Refactoring retirement is safe only as a combined edit/delete/link-repair mode. If any heuristic cannot be found in the resulting Workflow, the deletion is blocked and the proposal must return to drafting before production changes continue.
- `tests.md` remains earned and unchanged. No support detail is moved into optional wording if the executable main path needs it: public behavior, independent oracle, test-adapter boundary, and no internal seam remain compact inline.
- No script, executable helper, copied command syntax, or live Herdr identity exists in scope. No executable help check is applicable.

## Verification

- Compare the complete result against the WF-003 ledger, exact WF-008 definitions, WF-006 ownership, `AGENTS.md`, and every behavior-preservation item — every trigger, mode, gate, exception, guardrail, output, owner, and completion condition has one retained location.
- Exercise both documentation modes by inspection: normal mode cannot reach Red before agreement; discovered-bug mode cannot bypass confirmation when behavior, seam, or risk is ambiguous; both converge on the same one-test Red/Green/Refactor and completion gates.
- Inspect headings — target level-two headings are exactly `Language Definitions`, `Workflow`, and `Reference`; `Activities` is absent.
- Check all relative Markdown links one level deep across resulting `SKILL.md`, unchanged `tests.md`, changed `mocking.md`, and all owner references. Search the repository for `refactoring.md`; acceptance is no live inbound link and no unresolved local Markdown link.
- Assert each deleted refactoring heuristic has a semantic match in the resulting Workflow or verified `codebase-design` owner before accepting deletion.
- Compare target frontmatter byte-for-byte with baseline `231fb3864602055e88f28f07be3b32037d0656d9`; run a PyYAML-aware complete union-frontmatter audit over every discovered shared skill and report all entries/findings under the existing schema.
- Inspect exact-revision upstream TDD source/license, local target history, and `THIRD_PARTY_NOTICES.md` — `tdd`, revision `66898f60e8c744e269f8ce06c2b2b99ce7660d5f`, local-fork posture, and full MIT text remain covered.
- `test -L pi/skills/tdd && test "$(readlink pi/skills/tdd)" = '../../shared/skills/tdd' && test -f pi/skills/tdd/SKILL.md` — unchanged Pi visibility resolves.
- `git diff --check` and `bash tests/run.sh` — no whitespace errors and all repository tests pass.
- `git diff --name-status 231fb3864602055e88f28f07be3b32037d0656d9 --` plus scoped diff inspection — only this proposal, `SKILL.md`, `mocking.md`, and deleted `refactoring.md` differ; `tests.md`, owner references, specs, notices, `MIGRATION.md`, `pi/settings.json`, visibility links, and unrelated files remain unchanged.
- Commit the authorized files, verify a clean worktree, and report branch, commit, baseline/range, files, modes, checks, and residual risks without claiming coordinator verification.

## Implementation and verification record

Worker verification completed at `2026-07-14T18:16:07+00:00` against claim baseline `231fb3864602055e88f28f07be3b32037d0656d9`.

- Exact scope: PASS. The only intended changes are this proposal, `shared/skills/tdd/SKILL.md`, `shared/skills/tdd/mocking.md`, and deletion of `shared/skills/tdd/refactoring.md`. `tests.md`, all `codebase-design` owner references, specs, AGENTS, notices, tests, deployment, Pi visibility, `MIGRATION.md`, `pi/settings.json`, and unrelated files remain unchanged.
- Canonical shape and language: PASS. Level-two headings are exactly `Language Definitions`, `Workflow`, and `Reference`; no Activity is invented. All seven WF-008 definitions are exact, and Seam remains owned—not redefined—by `codebase-design`.
- Mode routing: PASS. Normal and discovered-bug modes are selected first. Both read repository guidance/specs/glossary; normal mode requires pre-agreement, while the discovered-bug exception applies only to unambiguous diagnosis, intended behavior/source, and an existing seam and stops for behavior, seam, or risk ambiguity.
- TDD contract: PASS. Public caller-observable behavior, independent oracles, one honest end-to-end tracer bullet, intended Red, minimal Green, one-test vertical cycles, all five checklist items, focused/nearby/broader command gates, green-only Refactor, seam-change approval, and final completion remain inline.
- Refactoring retirement: PASS. Duplication, long methods, feature envy/misplaced logic, primitive obsession, shallow modules, and revealed existing code all map to the green-only step or verified architecture owner. A corrected live-Markdown-link scan reports no `refactoring.md` consumer. An earlier intentionally broad text search returned the historical WF-003 and this proposal as mentions; neither is a live support link.
- Earned support: PASS. Unchanged `tests.md` remains conditionally linked for behavior/implementation/oracle examples. `mocking.md` remains conditionally linked for external-dependency adapters, retains all four dependency examples plus injection and operation-specific interface recipes, and now follows the verified no-internal-seam and two-adapter vocabulary.
- Frontmatter audit: PASS. Frontmatter is byte-identical to baseline. PyYAML parsed all 33 deterministically discovered shared skills; every required field and trigger/length check passed with zero errors and warnings. The other 32 skill bodies/frontmatters are unchanged from the verified clean baseline; semantic review confirms the changed target still uses `read`, `write`, `edit`, and `bash`.
- Links and visibility: PASS. Every relative link one level deep across the complete target, both retained supports, and all three architecture owner files resolves. `pi/skills/tdd` remains `../../shared/skills/tdd` and resolves.
- Provenance/history/source: PASS. Exact revision `66898f60e8c744e269f8ce06c2b2b99ce7660d5f` retains the imported public-interface, pre-agreement, oracle, and vertical-cycle material; `THIRD_PARTY_NOTICES.md` still records `tdd`, local-fork posture, and full Matt Pocock MIT license. Local green-only Refactor correctly follows authoritative `AGENTS.md` rather than upstream's conflicting review-only statement.
- Repository checks: PASS. `git diff --check` is clean. `bash tests/run.sh` passes 2 shell files and all 12 tests.
- Result hashes: `SKILL.md` `e3de3f9aaf3fc12fe877dfd1cce16a53ac6d2a0172e84189da453358da8171be`; `mocking.md` `648982e831728bb93042af89f99588e9a5298a423f27ba2ac133428bb365cf93`; unchanged `tests.md` `e4da76ed263857e2f53f88cf937a74610bcbf901aafbdf4314eae30d624559c5`.
- Residual risk: external-seam judgment remains context-dependent by design. The owner pointer, faithful-local-substitute preference, no-internal-seam rule, and concrete categories bound that discretion. No executable helper or command syntax exists in scope to validate.

Coordinator integration verification completed at `2026-07-14T18:21:51+00:00` against integrated commit `a270b36`: the complete target, retained supports, deleted refactoring support, proposal, and design owner were reread; exact definitions, seam ownership, first routing, both intake modes, public behavior, independent oracle, honest Red, minimal Green, one-test cycles/checklist, command tiers, green-only heuristic mapping, seam-change approval, final completion, conditional references, external-adapter boundaries, deletion/link repair, frontmatter identity, Pi visibility, Matt Pocock/MIT provenance, modes, and exact scope passed independent checks. The YAML-aware audit accounted for all 33 skills with zero errors and warnings, all live relative links resolved, `git diff --check` passed, and `bash tests/run.sh` passed all 12 tests. The protected `pi/settings.json` content and diff hashes remained `7d3f4713d7239e8cda3f75597a55f1767fecdf7964324630e4e74dc686d12e05` and `8298a9063e3ebf2988000d176057a41c31cf20c10bbabe92fb57d47f9f2738d5`. Residual risk remains context-dependent external-seam selection bounded by the owner contract.

## Explicit exclusions

- No edits to `.skill-migration/shared-skill-yagni/MIGRATION.md`, `.wayfinder/`, specs/glossaries, `THIRD_PARTY_NOTICES.md`, `AGENTS.md`, tests, scripts, executable sources, install/deployment files, Pi visibility links, `pi/settings.json`, unrelated skills, owner references, or unrelated proposals.
- No edit to `shared/skills/tdd/tests.md` or any `shared/skills/codebase-design` file; they are verification-only.
- No frontmatter/schema/grant redesign, fixed line target, new Activity, new skill, copied test-framework command, generic test-quality audit, implementation-specific test suite, or automatic upstream synchronization.
- No weakening of pre-agreement, its narrow discovered-bug exception, public behavior, independent oracle, honest vertical slicing, intended Red, minimal Green, one-test cycles, green-only Refactor, seam approval, command tiers, or completion.
- No live Herdr identifiers are created or persisted. No claim that this worker performs coordinator integration or verification.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Scope check: `PASS — MAP → WF-007 → complete WF-003 tdd record → WF-008 → WF-006 → current specs/AGENTS → verified write-a-skill/codebase-design/audit-shared-skills → complete target, tests.md, mocking.md, refactoring.md, and codebase-design owner references → provenance/history → exact-revision upstream source/license were read in strict authority order; exact four-file change scope, normal/discovered-bug routing, complete behavior ledger, pre-agreement exception, public behavior, independent oracle, honest vertical tracer bullet, intended Red, minimal Green, one-test cycles/checklist, focused/nearby/broad commands, green-only Refactor, seam-change approval/ownership, completion, support retention, six-heuristic retirement mapping, link repair, provenance/MIT, exclusions, and verification criteria pass. Production editing may continue autonomously under standing directive 2026-07-14T15:55:39+00:00 for proposal revision 1.`

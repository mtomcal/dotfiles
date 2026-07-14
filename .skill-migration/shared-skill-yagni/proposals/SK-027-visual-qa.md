---
id: SK-027
target: visual-qa
status: verified
revision: 1
blocked-by: [SK-001, SK-005, SK-021, SK-026]
source-verdict: simplify inline
baseline: bcd2dd29fa67219d53a731bb38dfc9d00eac2981
---

# Visual QA: route review mode and available evidence before interpretation

## Why this item is next

SK-001, SK-005, SK-021, and SK-026 are verified at the claim baseline. WF-007 places `visual-qa` in D4 direct normalization with a **simplify inline** verdict: route orchestrated checklist versus ad hoc review first, select available evidence tooling, and preserve mismatch reporting. The target and this proposal are disjoint from the concurrently claimed NEW-001 scope.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes the preserve-before-prune destination and excludes frontmatter redesign, deployment, and Pi visibility changes.
- WF-007 assigns `visual-qa` the **simplify inline** verdict after capture, conversion, neutral-diff, and verdict ownership pointers are durable.
- The complete WF-005 target record requires orchestrated/ad hoc routing first, human-question-first investigation, availability-aware browser/capture/video routing, still/multi-viewport/motion selection, console/network/scenario context, escalation when stills are untrustworthy, visible-complaint and machine/visual mismatch reporting, product/capture/artifact classification, per-step evidence, and a final verdict.
- WF-008 confirms the exact meanings of Human-visible result, Evidence surface, Runtime context, Capture setup failure, Artifact limitation, and Machine/visual mismatch.
- WF-006 keeps browser command syntax and capture in `playwright` or the active capture owner, recording conversion in `video-to-contact-sheet`, neutral no-verdict evidence in `image-diff-describer`, general interpretation in `visual-qa`, strict reference/candidate PASS/FAIL in `image-comparison-judge`, and final acceptance with the caller or human.
- `specs/ai-agent-config.md` 2.3.0 and `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 require canonical section order, semantic YAGNI, complete behavior preservation, local output/completion rules, availability-aware composition without ownership transfer, specialist verdict scope, existing union frontmatter, provenance review, and Pi visibility. `specs/README.md` and `specs/SPEC-OF-SPECS.md` establish spec authority and reading order.
- Verified `shared/skills/write-a-skill/SKILL.md` requires a complete behavior-preservation ledger, routing at the beginning of one Workflow, checkable branches, local failures/output/completion rules, semantic YAGNI without a line target, and provenance review. Verified `shared/skills/audit-shared-skills/SKILL.md` owns only YAML-aware validation of the existing union-frontmatter schema.
- Verified `shared/skills/playwright/SKILL.md` owns browser interaction/capture and has an executable minimal Activity plus conditional command References. Verified `shared/skills/video-to-contact-sheet/SKILL.md` owns recording conversion and returns source/generated paths, purposes, limitations, and machine/visual mismatch without acceptance. Verified `shared/skills/image-diff-describer/SKILL.md` owns neutral no-verdict diff evidence. Verified `shared/skills/image-comparison-judge/SKILL.md` owns strict criteria-based reference/candidate PASS/FAIL scoped below final human acceptance.
- The complete current target contains the required two modes and evidence-selection/reporting behavior but routes orchestrated mode last under a separate top-level heading, has no confirmed definitions, statically names browser routes not present in this repository or current Pi runtime, and lacks explicit output/final-human ownership. It remains compact and needs no Reference or browser manual.
- Runtime evidence at the claim baseline shows no `browser:control-in-app-browser` or `chrome:control-chrome` skill, config, or available current-harness tool. The installed `playwright-cli` 0.1.14 is available, has no open task-owned sessions, and exposes `open`, `snapshot`, `screenshot --full-page`, `console`, and `requests`; the verified Playwright owner remains the syntax authority. Runtime-specific browser/capture integrations may still exist in another harness, so the target must inventory actual availability and requirements rather than hard-code or deny them.
- Complete target history shows local ancestry: `codex/skills/playwright-visual-qa/SKILL.md` was added at `dfd67d2db28e59cc86463f54592cf5c1a4ed04c2`, moved into shared skills at `4fcd8db204888b46ef857ea16732bcb2e4ab201b`, expanded locally through recorded-review commits, and decomposed into `visual-qa` at `26119dbf3ed18cd7c6b05ae20acfb2b6f9f0d677`. `THIRD_PARTY_NOTICES.md` has no target entry and history gives no evidence of imported target material. Playwright's separate Apache provenance remains with its owner and does not transfer through composition.
- `pi/skills/visual-qa` resolves through `../../shared/skills/visual-qa` to the canonical target.

No authority conflict, support-file need, target command correction, provenance gap, or material file-set uncertainty remains.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-027-visual-qa.md` — item-local authorization, behavior ledger, verification evidence, and worker state.
- `shared/skills/visual-qa/SKILL.md` — canonical body normalization and availability-aware visual-QA routing.

These two paths are the complete revision 1 allowed file set.

## Proposed changes

### Add

- Add `Language Definitions` with the exact WF-008 meanings of Human-visible result, Evidence surface, Runtime context, Capture setup failure, Artifact limitation, and Machine/visual mismatch.
- Add first-step routing between orchestrated checklist mode, triggered by an orchestrator-supplied numbered action/expected-outcome checklist, and ad hoc mode for a caller question without that checklist.
- Add an availability and requirement check before capture: reuse supplied evidence first; for new browser evidence select an actually available capture owner that can satisfy auth/profile/session and deterministic-capture needs; use Playwright when available and deterministic automation or Playwright-managed recording is needed; route recordings requiring conversion to `video-to-contact-sheet`. If no route can produce valid required evidence, report a Capture setup failure and the missing capability rather than a product verdict.
- Add explicit output ownership: report the selected route, Human-visible result, Evidence surface paths, Runtime context, mismatches, classification, findings, and limitations to the caller; capture and conversion owners retain their mechanics and artifact contracts; this QA verdict does not replace final human acceptance.
- Add observable completion criteria to both modes.

### Change or move

- Preserve frontmatter byte-for-byte, including the existing union schema, all invocation triggers, short description, and nonportable command grants; do not redesign grants in this body migration.
- Move orchestrated-versus-ad-hoc selection to the Workflow opening, then keep the human question before tool or evidence choice.
- Replace static assumptions about `browser:control-in-app-browser` and `chrome:control-chrome` with runtime capability discovery. Preserve their intended requirements—localhost/side-by-side capture and access to an existing authenticated browser profile/session—without asserting unavailable route names.
- Keep Playwright as a conditional capture route and `video-to-contact-sheet` as the conversion route, but point to their owner contracts rather than copying commands or manuals.
- Keep evidence selection by question: a single still for layout/spacing, full-page or multiple viewports for responsive behavior, and motion evidence for animation, occlusion, attachment, causality, timing, or directional readability.
- Keep Runtime context alongside visual evidence: scenario and structured artifacts when present, console warnings/errors, network failures, auth/state, viewport, and environment.
- Keep escalation when stills are misleading or cannot prove motion. A visible complaint remains evidence even when logs, screenshots, or structured checks look fine; narrow or recapture rather than silently dismissing it. Report both sides of every Machine/visual mismatch without silently favoring either.
- Keep the final classification explicit: product behavior, Capture setup failure, or Artifact limitation. Invalid setup/evidence cannot prove a product defect; an Artifact limitation must state what the medium omits or distorts.
- In orchestrated mode, execute each numbered action sequentially and record Action, Expected, observed Outcome, PASS/FAIL Result, and Evidence. Verify after every action with the selected capture owner, preserve a screenshot/capture for every failed step when capture is available, and stop or mark downstream steps blocked when failure makes them invalid rather than fabricating results.
- Keep the orchestrated final verdict `PASS` or `NEEDS-FIX`, plus console and network results. Keep ad hoc findings led by the visible pass/failure condition with evidence, Runtime context, mismatch, classification, and limitations.

### Remove

- Remove the separate noncanonical `Routing` and `Checklist-Based QA (Orchestrated)` level-two sections after every route, checklist input, per-step field, failed-step capture, and final report requirement is retained inside one route-first Workflow.
- Remove the literal checklist example and emoji decoration; the executable contract still requires a numbered action plus expected outcome from the orchestrator and explicit PASS/FAIL per step.
- Remove static browser integration names that current repository/runtime evidence cannot establish. Do not remove their functional requirements; select any actually available capture route satisfying those requirements.
- Remove no trigger, mode, human question, still/multi-viewport/motion branch, console/network/scenario evidence, still-untrustworthy escalation, visible-complaint rule, mismatch rule, classification, per-step action/expected/outcome/evidence field, failed-step capture, final verdict, output ownership, or human-acceptance boundary.
- Add no Reference, support file, helper script, browser command catalog, ffmpeg recipe, neutral-diff workflow, strict reference/candidate judging workflow, universal report schema, or new tool grant.

## Proposed skill shape

1. `Language Definitions` — present; exactly the six WF-008-confirmed visual-QA terms.
2. `Workflow` — present; one route-first process with orchestrated and ad hoc branches, shared evidence/tool selection and interpretation rules, and branch-local outputs/completion.
3. `Activities` — omitted; ad hoc and orchestrated execution are mutually selected branches of the required end-to-end process, not reusable actions selected outside it.
4. `Reference` — omitted; all required behavior is compact and owner skills already contain browser and conversion mechanics.

## Behavior-preservation checklist

- [x] Frontmatter remains byte-identical and retains every browser/app/recording, layout, responsive, console/network, motion/readability, screenshot, and review-video trigger plus the existing union-schema fields/grants.
- [x] All six exact WF-008 definitions appear once and do not compete with project glossary or neighboring owners.
- [x] Workflow routes orchestrated checklist versus ad hoc mode before evidence/tool selection.
- [x] Both modes establish the human question or requested visible outcome before selecting tooling.
- [x] Supplied evidence is reused when sufficient; new capture checks actual runtime availability and auth/profile/session/determinism requirements.
- [x] Playwright remains the conditional deterministic browser/capture owner; active runtime capture integrations remain usable when available; no browser command manual is copied.
- [x] Recording conversion routes to `video-to-contact-sheet`, preserving its source/path/purpose/limitation contract and final-acceptance boundary without copying ffmpeg recipes.
- [x] Single still, full-page or multi-viewport, and motion evidence remain selected by layout/responsive/motion needs.
- [x] Console, network, scenario/structured artifacts, auth/state, viewport, and environment remain Runtime context gathered beside visuals.
- [x] Still evidence escalates to motion/capture conversion when pose, shadow, anchoring, occlusion, causality, timing, direction, or another transient behavior makes stills untrustworthy.
- [x] A visible complaint is not discarded because machine evidence looks fine; evidence is narrowed or recaptured.
- [x] Every Machine/visual mismatch reports both visible and structured signals without silently favoring either.
- [x] Findings distinguish product behavior, Capture setup failure, and Artifact limitation; invalid capture cannot prove product failure.
- [x] Orchestrated mode requires a numbered checklist with action and expected outcome, executes sequentially, and records Step, Action, Expected, observed Outcome, PASS/FAIL Result, and Evidence.
- [x] Every orchestrated step is verified; failed steps receive screenshot/capture evidence when available and invalid downstream steps are reported blocked rather than fabricated.
- [x] Orchestrated output ends with `PASS` or `NEEDS-FIX` plus console and network results.
- [x] Ad hoc output leads with the Human-visible result and includes evidence paths, Runtime context, mismatches, classification, and limitations.
- [x] The report identifies the selected route and all evidence paths; producer skills retain command/artifact mechanics, while `visual-qa` owns general interpretation and returns its report to the caller.
- [x] A visual-QA verdict remains scoped evidence for caller/human acceptance and never claims final human acceptance.
- [x] No capture, conversion, neutral-diff, criteria-judge, provenance, deployment, discovery, or visibility ownership moves into this skill.

## Dependencies, provenance, and risks

- All four blockers are verified at baseline. Their current interfaces are compatible: Playwright captures, Video To Contact Sheet converts, Image Diff Describer produces optional neutral evidence, and Image Comparison Judge produces a separate strict scoped judgment when explicitly needed.
- Current static in-app/Chrome route names are unverified in the repository and absent from this Pi runtime. Replacing names with requirement- and availability-based selection preserves cross-harness behavior without inventing a portable tool name. A future harness may expose either capability under another name.
- The target is repository-local based on complete ancestry and absence from `THIRD_PARTY_NOTICES.md`; no provenance or license file change is authorized. Composing Playwright does not copy or relocate its Apache-licensed material.
- The frontmatter command grants are intentionally unchanged under the separate frontmatter lane. They remain available when the composed video-conversion route runs, but their harness syntax is nonportable and may be ignored by some agents; this migration neither resolves nor expands that known risk.
- Console/network data may be unavailable for supplied stills or app captures. The report must identify that as Runtime context not gathered and, when it blocks confidence, an Artifact limitation rather than inventing a clean result.
- Failed-step capture itself may be unavailable after a crash or invalid session. The report must retain any last valid evidence, identify the Capture setup failure, and mark affected steps blocked; it must not claim a screenshot exists.

## Verification

1. Reread the complete resulting target and map every checked ledger item above to one location.
2. Parse and compare frontmatter byte-for-byte with `bcd2dd2:shared/skills/visual-qa/SKILL.md`; validate the existing union schema and exact `Use when` triggers without redesigning grants.
3. Parse level-two headings; expect exactly `Language Definitions` then `Workflow`, with no `Activities`, `Reference`, `Routing`, or `Checklist-Based QA (Orchestrated)` heading.
4. Compare all six definitions to WF-008; expect exact semantic and textual identity with no duplicate definitions.
5. Inspect Workflow ordering; expect mode selection first, human question second, then availability/requirements and evidence format, Runtime context, interpretation/escalation, and branch output.
6. Inspect availability routing; expect supplied-evidence reuse, conditional active capture owner, conditional Playwright deterministic capture, conditional `video-to-contact-sheet` conversion, and explicit no-valid-route Capture setup failure. Expect no copied browser or ffmpeg command manual and no hard-coded unavailable browser integration name.
7. Inspect evidence and interpretation; require still/full-page-or-multi-viewport/motion branches, console/network/scenario/auth/viewport/environment context, still-untrustworthy escalation, visible-complaint preservation, two-sided Machine/visual mismatch, and product/capture/artifact classification.
8. Inspect orchestrated mode; require numbered action/expected input, sequential execution, Step/Action/Expected/Outcome/Result/Evidence fields, per-step verification, failed-step capture when available, blocked downstream handling, final `PASS`/`NEEDS-FIX`, and console/network results.
9. Inspect ad hoc output and ownership; require visible result, evidence paths, Runtime context, mismatches, classification, limitations, selected route, caller return, producer ownership, and final-human-acceptance boundary.
10. Recheck installed `playwright-cli --version`, `list`, and help for `open`, `snapshot`, `screenshot`, `console`, and `requests`; this is availability/owner evidence only. Confirm no task-owned browser remains and no command syntax was copied into the target. No ffmpeg command changes require new executable testing because conversion remains with the verified owner.
11. Run the complete YAML-aware `audit-shared-skills` workflow, account for all 33 skills, require zero required-field/description findings, and manually record the intentionally unchanged nonportable target grants under the excluded frontmatter lane.
12. Run `test -L pi/skills/visual-qa && test "$(readlink pi/skills/visual-qa)" = '../../shared/skills/visual-qa' && test -e pi/skills/visual-qa/SKILL.md`.
13. Recheck complete target ancestry and `THIRD_PARTY_NOTICES.md`; require repo-local provenance, no imported-target evidence, and no notice diff.
14. Run `git diff --check -- .skill-migration/shared-skill-yagni/proposals/SK-027-visual-qa.md shared/skills/visual-qa/SKILL.md` and `bash tests/run.sh`.
15. Compare baseline-aware tracked and untracked paths. Acceptance: exactly this proposal and target; no diff in `MIGRATION.md`, `pi/settings.json`, `.wayfinder`, specs/glossary, notices, AGENTS, tests, deployment, visibility links, adjacent skills, or unrelated proposals.

Acceptance requires exact two-file scope, canonical two-section body, exact six definitions, byte-identical frontmatter, route-first modes, human-question-first execution, availability-aware capture/conversion, complete evidence selection and Runtime context, mismatch/escalation/classification behavior, complete per-step and final outputs, producer/caller/human ownership boundaries, clean required-field union audit, resolving Pi visibility, local provenance, clean diff checks, and passing repository tests.

## Implementation and verification record

Worker verification completed at `2026-07-14T18:37:08+00:00`.

- Proposal-before-edit control: revision 1 reached committed `proposal-ready` state at `3cac9ac835884821737bde7250077894bc26098d` with the exact proposal/target file set before production editing. Complete diff review found no material file-set, authority, ownership, behavior, provenance, or removal divergence, so revision 1 now records `ready-to-integrate`.
- Actual production diff: `shared/skills/visual-qa/SKILL.md` has 27 insertions and 47 removals relative to claim baseline `bcd2dd29fa67219d53a731bb38dfc9d00eac2981`; its resulting SHA-256 is `f553f4ebc02109363b626a661337743adc2ff9d233aff18399473aa9a95192f1`. This proposal is the only additional item-local file.
- Complete-file and behavior-ledger review: PASS. The Workflow routes orchestrated versus ad hoc mode first, establishes the human question before evidence/tool selection, reuses valid supplied evidence, inventories actual runtime capture capability and auth/profile/session/determinism requirements, and preserves still, full-page/multi-viewport, and motion selection. Runtime context covers scenario/structured artifacts, console, network, auth/state, viewport, and environment. Still-untrustworthy escalation, visible-complaint preservation, two-sided Machine/visual mismatch, and product/Capture setup failure/Artifact limitation classification remain inline.
- Orchestrated/ad hoc outputs and ownership: PASS. Orchestrated mode requires numbered actions and expected outcomes, sequential verification, `Step | Action | Expected | Outcome | Result | Evidence`, failed-step capture when available, and blocked downstream handling; final results distinguish `PASS`, `NEEDS-FIX`, and evidence-blocked `BLOCKED` and include console/network status. Ad hoc output leads with the visible condition and includes the selected route, all evidence paths, Runtime context, mismatches, classifications, and limitations. Capture, conversion, general interpretation, caller, and final-human boundaries remain explicit.
- Canonical body and confirmed language: PASS. Level-two headings are exactly `Language Definitions` then `Workflow`; no `Activities`, `Reference`, old `Routing`, or old orchestrated-checklist heading remains. All six WF-008 definitions are textually exact and unique.
- Frontmatter and owner composition: PASS. The opening YAML is byte-identical to baseline and retains the exact `Use when` description and grants. The target conditionally routes deterministic capture to `playwright`, recording conversion to `video-to-contact-sheet`, and returns source/generated paths, purposes, and limitations without copying browser, Playwright, ffmpeg, neutral-diff, or strict-judge mechanics. Static unavailable browser integration names are absent.
- Focused runtime evidence: PASS. Installed `playwright-cli` reports version `0.1.14`; focused help confirms `open`, `snapshot`, `screenshot --full-page`, `console`, and `requests`. `playwright-cli list` reported no browser before or after the checks, and no command manual was copied into the target.
- Union audit: PASS for required fields and descriptions. A PyYAML-aware complete-catalog run parsed all 33 discovered skills with zero errors; every description is at most 1024 characters and contains exact `Use when`. It reports one intentional warning: the target's unchanged ffmpeg/ffprobe/file-command grants are unused by the revised body and remain a nonportable least-privilege risk in the excluded frontmatter lane. No frontmatter fix is authorized in this item.
- Provenance and visibility: PASS. Complete ancestry runs from repository-local creation at `dfd67d2`, through the shared move at `4fcd8db`, local expansions, and decomposition into `visual-qa` at `26119db`; no imported target source was found. `THIRD_PARTY_NOTICES.md` has no target entry and no diff. `pi/skills/visual-qa` remains the resolving `../../shared/skills/visual-qa` symlink.
- Repository and exact-scope verification: PASS. `bash tests/run.sh` passed both shell files and all 12 tests; focused assertions and scoped `git diff --check` passed. Baseline-aware tracked paths are exactly this proposal and target, with no untracked file and no diff in protected or unrelated paths. No live Herdr ID is persisted.
- Residual risks: capture capabilities and names vary across harnesses, so route choice remains runtime-dependent. Supplied stills may omit console/network or transient behavior; unavailable context must remain explicit and can force `BLOCKED` or an Artifact limitation. The unchanged target tool grants remain nonportable and unused by this revised body until the separate frontmatter lane addresses them.

The worker result is `ready-to-integrate`; this record does not claim coordinator integration, coordinator verification, central `verified` state, or catalog-wide VG-001 completion.

Coordinator integration verification completed at `2026-07-14T18:41:08+00:00` against integrated commits `0ea1702` and `85100a9`: the complete target and proposal were reread; exact definitions, mode-first and human-question routing, availability-aware capture/conversion, evidence formats, complete Runtime context, escalation, visible-complaint and mismatch preservation, classification, orchestrated fields/failed-step evidence/blocked handling, final outputs, producer/caller/human ownership, frontmatter identity, Pi visibility, repo-local provenance, and exact scope passed independent checks. The YAML-aware audit parsed/accounted for all 33 skills with zero errors and one explicit warning: the target's byte-preserved ffmpeg/ffprobe/file-command grants are not directly used by the revised body and remain deferred to the excluded frontmatter/grant lane. `playwright-cli` 0.1.14 availability and zero open browsers were confirmed, `git diff --check` passed, and `bash tests/run.sh` passed all 12 tests. The protected `pi/settings.json` content and diff hashes remained `7d3f4713d7239e8cda3f75597a55f1767fecdf7964324630e4e74dc686d12e05` and `8298a9063e3ebf2988000d176057a41c31cf20c10bbabe92fb57d47f9f2738d5`. Residual risks are runtime-varying capture capabilities, incomplete supplied evidence, and the deferred grant warning.

## Explicit exclusions

- No edit to `.skill-migration/shared-skill-yagni/MIGRATION.md`, `.wayfinder/`, `pi/settings.json`, another skill/proposal, specs/glossary, `THIRD_PARTY_NOTICES.md`, AGENTS, tests, scripts, installer/deployment files, agent configs, or Pi visibility symlinks.
- No fixed line/word target, frontmatter/schema/tool-grant redesign, support file, helper script, static browser integration requirement, browser/Playwright command manual, ffmpeg recipe, recording capture implementation, neutral-diff production, strict reference/candidate judgment, accessibility audit expansion, severity taxonomy, or universal report schema.
- No transfer of capture mechanics, conversion mechanics, neutral-diff ownership, strict comparison ownership, caller acceptance, or final human acceptance.
- No persistence of live Herdr workspace, tab, pane, or agent IDs.
- No coordinator-only `integrating` or `verified` state and no claim that the coordinator verified this item.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization effect: after the scope check passes, the standing directive authorizes only the exact two paths and changes enumerated in revision 1 without a per-item approval wait.
- Scope check: `PASS — revision 1 reread MAP → WF-007 → complete WF-005 visual-qa record → WF-008 → WF-006 → current specs/glossary → verified write-a-skill, playwright, image-diff-describer, video-to-contact-sheet, image-comparison-judge, and audit-shared-skills → complete target and runtime browser-route evidence → provenance/notices/complete target ancestry → installed Playwright CLI 0.1.14 availability and focused help in the mandated order. Exact scope is only this proposal and the target. Frontmatter, six exact definitions, orchestrated/ad hoc routing, human question, availability and evidence selection, still/multi-viewport/motion branches, complete Runtime context, still-untrustworthy escalation, visible complaint and Machine/visual mismatch handling, product/capture/artifact classification, per-step action/expected/outcome/result/evidence, failed-step capture, final verdict with console/network, producer/caller/human ownership, provenance, Pi visibility, exclusions, and verification are fixed. Current evidence supports requirement-based runtime routing instead of static unavailable integration names; no browser or conversion manual is copied. Production editing may continue autonomously without a per-item approval wait.`

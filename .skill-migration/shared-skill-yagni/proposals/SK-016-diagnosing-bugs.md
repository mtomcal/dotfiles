---
id: SK-016
target: diagnosing-bugs
status: ready-to-integrate
revision: 1
blocked-by: [SK-001]
source-verdict: retain substance
baseline: 4f2c653d769313cba1609c644a46377c6abc6c91
---

# Diagnosing Bugs: retain six evidence gates and TDD handoff

## Why this item is next

SK-001 is verified, SK-016 is claimed, and no unfinished owner blocks it. WF-007 places `diagnosing-bugs` in D4 direct normalization with a **retain** verdict: preserve the six ordered evidence gates and TDD handoff while adding confirmed language and canonical body structure. Its exact file set is disjoint from concurrently claimed SK-015.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes a preserve-before-prune destination and excludes frontmatter redesign, deployment, and Pi visibility changes.
- WF-007 assigns `diagnosing-bugs` the **retain** verdict and requires one six-gate workflow whose requested bug fix cannot be replaced by architecture work.
- The complete WF-003 target record supplies the behavior ledger: build and run the smallest exact-symptom command using the ordered reproduction preference; stop theorizing when reproduction is impossible; repeatedly reproduce and minimize; rank three to five falsifiable hypotheses; probe one prediction at a time; tag temporary instrumentation and baseline performance; hand the minimized bug to TDD; record the no-honest-seam architecture finding rather than add a shallow test; rerun the original and regression commands; remove instrumentation; report evidence and residual risk; and route architecture only after the fix.
- WF-008 confirms the exact meanings of Tight command, Red-capable, Minimized reproduction, Falsifiable hypothesis, and Causal explanation. Project-domain vocabulary remains with the applicable project glossary.
- WF-006 keeps TDD production behavior with `tdd`, general architecture and seam vocabulary with verified `codebase-design`, architecture-improvement workflow with `improve-codebase-architecture`, and report acceptance with this producing workflow. Composition imports process, not caller ownership.
- `specs/ai-agent-config.md` 2.3.0 requires `diagnosing-bugs` to establish a tight red-capable command, minimize the reproduction, test ranked hypotheses, and route fixes through TDD. It also requires canonical section order, behavior preservation, local gates/failures/outputs, and retained ownership under composition. `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 leaves skill-local definitions in the owning skill body. `specs/DESIGN_LANGUAGE.md` contains no conflicting debugging vocabulary.
- Verified `shared/skills/write-a-skill/SKILL.md` requires a complete behavior-preservation ledger, one routed Workflow, checkable local failures and completion criteria, semantic YAGNI, and provenance review. Verified `shared/skills/codebase-design/SKILL.md` owns seam selection and treats the caller interface as the test surface.
- The complete current target is coherent and self-contained. `shared/skills/tdd/SKILL.md` provides the discovered-bug fast path, pre-agreed honest seam, focused Red, minimum Green, and green-only refactor process. `shared/skills/improve-codebase-architecture/SKILL.md` remains a separate post-fix workflow requiring candidate selection before refactoring. Neither composed owner needs an edit for this normalization.
- Git history shows the target was introduced unchanged at local commit `3b59c13906d5d7922ed236b19cfe548138f429d7`. `THIRD_PARTY_NOTICES.md` records `diagnosing-bugs` as a locally maintained adaptation of `mattpocock/skills` revision `66898f60e8c744e269f8ce06c2b2b99ce7660d5f` under the reproduced MIT license. Attribution is complete and unchanged.
- No fixed executable command syntax is owned by this skill: it deliberately selects a repository-specific focused test, CLI/HTTP reproduction, browser script, trace replay, harness, or seeded loop at invocation time. Installed command help must therefore be checked against the selected target tool when diagnosing a real bug; this item introduces or changes no static command form.

No authority conflict, ownership contradiction, command correction, support-file need, or provenance gap exists.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-016-diagnosing-bugs.md` — item-local authorization, behavior ledger, exact checks, and final worker state.
- `shared/skills/diagnosing-bugs/SKILL.md` — add confirmed definitions and canonically normalize the retained six-gate workflow.

These two paths are the complete revision 1 allowed file set. No support file exists or is authorized.

## Proposed changes

### Add

- Add `Language Definitions` with the exact WF-008 meanings of Tight command, Red-capable, Minimized reproduction, Falsifiable hypothesis, and Causal explanation.
- Give all six retained stages an observable completion criterion: exact-symptom red command; load-bearing minimized red scenario; three-to-five ranked predictions; evidence-backed causal explanation; TDD regression/fix or explicitly recorded no-seam branch; and clean dual rerun/reporting evidence.
- Make the no-honest-seam branch executable without weakening it: do not add a tautological or shallow test, still fix the requested symptom through the original red command, record the missing seam as architectural risk, and report why a regression test and its second rerun are unavailable.

### Change or move

- Preserve frontmatter byte-for-byte, including every bug/failure/flakiness/incorrectness/performance trigger and the current tool grants.
- Move the unheaded evidence-first guidance into the opening of one `Workflow` after the definitions.
- Convert the six numbered level-two headings into six ordered Workflow steps while retaining their exact sequence and distinct evidence gates.
- Keep the ordered reproduction choices: existing focused test; fixture-backed test invocation; CLI or HTTP reproduction; headless browser script; captured-trace replay; throwaway harness; seeded stress, differential, or bisection loop.
- Keep tight-command qualities beside the first gate: red-capable, deterministic or pinned/high-rate, fast, and agent-runnable.
- Keep inability-to-reproduce handling beside the first gate: stop theorizing, list attempts, and request missing access, artifact, or temporary-instrumentation permission.
- Keep one-at-a-time minimization, three-to-five ranked falsifiable hypotheses, one observable prediction per hypothesis, evidence-order continuation without an approval wait, one-prediction-at-a-time probing, uniquely tagged instrumentation, and a pre-change performance timing/profile/query-plan baseline.
- Keep TDD composition at the fix gate: load `tdd`, turn the minimized reproduction into a failing regression at the pre-agreed honest seam, then apply its discovered-bug path for the smallest fix. Preserve the no-seam branch and prevent architecture work from substituting for the requested fix.
- Keep normal dual rerun of the regression test and original reproduction command. In the no-seam branch, require the original command to be rerun and the unavailable regression rerun to be explicitly reported rather than falsely claimed.
- Keep cleanup and the complete report contract: root cause, evidence, fix, test seam or no-seam finding, commands run, and remaining architectural risk. Keep architecture routing after the fix only.

### Remove

- Remove only the standalone opening paragraph and six noncanonical level-two step headings after all unique behavior is retained in `Language Definitions` and the single `Workflow`.
- Remove no trigger, reproduction option/order, gate, branch, failure, guardrail, hypothesis count, probe rule, instrumentation rule, performance rule, TDD behavior, rerun, output field, ownership boundary, or completion condition.

## Proposed skill shape

1. `Language Definitions` — present; the five exact human-confirmed operational definitions.
2. `Workflow` — present; one six-stage evidence-first process from exact-symptom red command through minimization, hypotheses, causal probing, TDD fix, cleanup, reruns, and report.
3. `Activities` — omitted; every command and action is selected within the required diagnosis sequence rather than independently.
4. `Reference` — omitted; the compact workflow is self-contained and has no supporting Markdown. TDD and architecture are composed skills, not copied support files.

## Behavior-preservation checklist

- [x] Frontmatter still triggers hard bugs, performance regressions, broken/failing/throwing/flaky/incorrect behavior, and unexpected slowness without schema or grant changes.
- [x] Evidence remains mandatory before theory, using relevant repository guidance, specs, and project glossary terms.
- [x] Tight command, Red-capable, Minimized reproduction, Falsifiable hypothesis, and Causal explanation retain their exact confirmed meanings.
- [x] The workflow retains exactly six ordered evidence gates rather than merging diagnosis into an undifferentiated checklist.
- [x] The first gate builds the smallest agent-runnable command that exercises the real path and asserts the user's exact symptom.
- [x] The complete reproduction preference order remains intact.
- [x] Tight still requires exact-bug red capability, determinism or a pinned high flaky reproduction rate, speed, and unattended agent execution where possible.
- [x] The first gate still requires the named command to have actually gone red on the reported symptom.
- [x] Inability to build the loop still stops theorizing and requires attempts plus missing access/artifact/instrumentation needs to be reported.
- [x] Reproduction remains repeated before minimization; inputs, callers, config, data, and steps are removed one at a time with a rerun after each removal.
- [x] The minimization gate still requires a red smallest-known scenario where removing another element changes the verdict.
- [x] Exactly three to five hypotheses remain ranked in evidence order.
- [x] Every hypothesis remains falsifiable and states one observable prediction in the `If X, measuring/changing Y produces Z` form.
- [x] Hypotheses may be shown to the available user, but diagnosis continues without turning that display into an approval wait.
- [x] Probes test one prediction at a time and prefer debugger/REPL evidence before targeted logs or measurements.
- [x] Temporary instrumentation remains uniquely tagged, removable, and absent at completion.
- [x] Performance diagnosis still records a timing, profile, or query-plan baseline before code changes.
- [x] Probe completion still requires a causal explanation after meaningful alternatives are falsified; a correlated line is insufficient.
- [x] The fix gate still loads `tdd`, uses its discovered-bug path, starts from the minimized reproduction, and targets a pre-agreed honest seam.
- [x] The regression test must be observed red for the diagnosed symptom before the smallest fix is made green.
- [x] If no honest seam can reproduce the bug, the workflow records the architecture finding rather than adding a tautological or shallow test.
- [x] The no-seam branch does not allow architecture investigation or refactoring to replace fixing the requested symptom through the original red command.
- [x] The normal path reruns both the regression test and original reproduction command; the no-seam path reruns the original and explicitly reports why the second artifact is unavailable.
- [x] Cleanup removes all tagged instrumentation and throwaway harnesses unless the harness became the regression test.
- [x] The report retains root cause, evidence, fix, test seam or no-seam finding, exact commands, and remaining architectural risk.
- [x] `improve-codebase-architecture` is routed only after the bug is fixed, and only for a missing or harmful seam.
- [x] Existing Matt Pocock provenance and MIT license coverage remain accurate without a notice edit.

## Dependencies, provenance, and risks

- SK-001 and SK-013 are verified at the claimed baseline. The canonical authoring contract and general seam vocabulary are therefore stable. SK-025 may later normalize `tdd`, but its current discovered-bug public contract already supplies the required handoff and no ownership decision is pending.
- `diagnosing-bugs` owns diagnosis sequence, evidence, the original reproduction command, fix acceptance, and final report. Composing `tdd` imports test-first fixing but does not transfer those outputs or acceptance gates. Composing `improve-codebase-architecture` after the fix does not transfer or delay bug-fix ownership.
- The baseline's unconditional “re-run both” and final “both green” wording sits beside an explicit no-honest-seam branch. Revision 1 resolves only that local executability tension: the normal branch preserves dual rerun; the no-seam branch may not invent a regression and must report its absence as risk. This does not weaken the honest-seam guardrail or authorize skipping a feasible regression test.
- The target has no support files, scripts, or fixed executable syntax. Runtime command help remains target-repository-specific and no command correction is needed here.
- Provenance is already complete in `THIRD_PARTY_NOTICES.md`; restructuring the local MIT-covered adaptation does not require a notice change.
- The resulting skill may be slightly longer because confirmed definitions and explicit branch completion make latent contracts checkable; semantic YAGNI, not line count, governs the retain verdict.

## Verification

1. Reread the complete resulting `shared/skills/diagnosing-bugs/SKILL.md`; map every WF-003 target-ledger item and every checked item above to one resulting location.
2. Parse level-two headings; expect exactly `Language Definitions` then `Workflow`, with no `Activities`, `Reference`, or unapproved heading.
3. Compare all five definitions to WF-008; expect semantic identity and no competing duplicate definitions.
4. Inspect the Workflow for exactly six ordered stages and six observable completion gates.
5. Inspect gate 1 for the exact-symptom red command, complete ordered reproduction preferences, four tight qualities, actual-red requirement, and inability-to-reproduce stop/request contract.
6. Inspect gates 2–4 for repeated minimization and removal test, exactly three-to-five ranked hypotheses, one falsifiable prediction per hypothesis, one-at-a-time probes, unique debug tag, pre-change performance baseline, alternative falsification, and causal-not-correlated evidence.
7. Inspect gates 5–6 for TDD loading, pre-agreed honest seam, discovered-bug red/green path, no-shallow-test branch, requested-fix requirement, normal dual rerun, explicit no-seam report branch, cleanup, full report fields, and architecture routing only after the fix.
8. Resolve all Markdown links from the skill directory; expect none. Confirm there is no support file or script to validate and no fixed command syntax requiring a static help check.
9. Run the complete YAML-aware `audit-shared-skills` workflow against baseline and result, including every union-schema condition and semantic unused-tool review. Acceptance: all 33 skills are parsed/accounted for, target fields pass, and no finding is introduced.
10. Run `test -L pi/skills/diagnosing-bugs && test "$(readlink pi/skills/diagnosing-bugs)" = '../../shared/skills/diagnosing-bugs' && test -e pi/skills/diagnosing-bugs/SKILL.md`.
11. Recheck `git log --follow`, upstream revision evidence, and `THIRD_PARTY_NOTICES.md`; expect introduction at `3b59c13906d5d7922ed236b19cfe548138f429d7`, exact Matt Pocock revision coverage, full MIT license, and no notice diff.
12. Run `git diff --check -- .skill-migration/shared-skill-yagni/proposals/SK-016-diagnosing-bugs.md shared/skills/diagnosing-bugs/SKILL.md`.
13. Run `bash tests/run.sh`; expect all repository shell tests to pass.
14. Compare baseline-aware changed and untracked paths. Acceptance: exactly this proposal and target skill; no diff in `MIGRATION.md`, `pi/settings.json`, specs/glossary, notices, deployment, visibility, tests, support files, unrelated skills, or unrelated proposals.

Acceptance requires exact two-file scope, canonical two-section body, all five confirmed definitions, unchanged frontmatter/triggers, all six evidence gates, tight red-capable command, reproduction stop, minimization, three-to-five hypotheses with one-at-a-time predictions/probes, tagged instrumentation and performance baseline, TDD handoff and honest no-seam handling, dual rerun/reporting branches, post-fix-only architecture routing, clean catalog audit, resolving Pi visibility, complete provenance, clean diff checks, and passing repository tests.

## Implementation and verification record

Worker verification completed at `2026-07-14T17:27:50+00:00`.

- Proposal-before-edit control: revision 1 reached `proposal-ready` with the exact proposal/target file set before production editing. No material file-set, authority, ownership, provenance, or behavior revision was needed; the same revision now records `ready-to-integrate`.
- Actual production diff: `shared/skills/diagnosing-bugs/SKILL.md` has 23 insertions and 30 removals relative to baseline `4f2c653d769313cba1609c644a46377c6abc6c91`. The resulting SHA-256 is `41a4038cbad0d1b30025965091d160e68f20ba1de6c1aab261f99ab2573efaa5`; this proposal is the only additional item-local file.
- Complete-file and behavior-ledger review: PASS. Every frontmatter trigger, evidence-first rule, ordered reproduction choice, tight-command quality, actual-red gate, inability-to-reproduce stop, minimization operation/removal test, hypothesis count/ranking, prediction/probe rule, tagged instrumentation and cleanup, performance baseline, causal-evidence gate, TDD handoff, no-seam branch, rerun, report field, and post-fix architecture route remains inline.
- Canonical body and confirmed language: PASS. Level-two headings are exactly `Language Definitions` then `Workflow`; `Activities` and `Reference` are correctly omitted. All five WF-008 definitions are present with semantic identity and no competing definitions. The Workflow has exactly six ordered stages and six observable completion criteria.
- Frontmatter preservation: PASS. The complete opening YAML block is byte-identical to baseline. The target grants remain justified: `read` for evidence/spec/source inspection, `bash` for reproduction and verification commands, and `write`/`edit` for temporary instrumentation, regression tests, and the smallest fix.
- Critical workflow gates: PASS. The tight command must exercise the real path, detect the exact symptom, and already have gone red. Failed reproduction stops theory. Minimization remains removal-and-rerun based. Three to five hypotheses each predict a disprovable observation, and probes run one prediction at a time. Performance changes require a pre-change timing/profile/query-plan baseline.
- Fix and branch behavior: PASS. The normal path loads `tdd`, observes a regression red at the pre-agreed honest seam, makes the smallest fix green, and reruns both regression and original commands. The no-seam path forbids a tautological/shallow test, records the architecture finding, drives the requested fix with the original red command, reruns that command, and reports why no second artifact exists. Neither branch permits architecture work to replace or precede the requested fix.
- Cleanup and output: PASS. Tagged instrumentation and throwaway harnesses are removed unless promoted to the regression test. The report retains cause, evidence, fix, seam/no-seam state, commands, causal explanation, and remaining architecture risk; `improve-codebase-architecture` is reachable only after green.
- Baseline-aware union audit: PASS. PyYAML 6.0.1 parsed and accounted for all 33 baseline and all 33 result skill frontmatters. Both runs report zero errors and zero warnings for required union fields, description length, and exact `Use when` trigger phrase; target tool grants are used, so no least-privilege warning was introduced.
- Links, support, visibility, provenance, and help: PASS. The target has no Markdown links, support files, scripts, or static executable forms. Runtime help remains intentionally delegated to the repository-specific reproduction tool selected during diagnosis. `pi/skills/diagnosing-bugs` still resolves through `../../shared/skills/diagnosing-bugs`. Git history confirms introduction at `3b59c13906d5d7922ed236b19cfe548138f429d7`; `THIRD_PARTY_NOTICES.md` retains the exact Matt Pocock revision, target listing, and full MIT license.
- Repository and exact-scope verification: PASS. `bash tests/run.sh` passed 2 shell files and all 12 tests; scoped `git diff --check` passed. Baseline-aware tracked/untracked inspection contains exactly this proposal and target. The migration ledger, `.wayfinder`, specs/glossary, notices, AGENTS, tests, installer/deployment, all Pi paths including `pi/settings.json`, composed skills, and unrelated items have no diff.
- Residual risk: a genuinely missing honest seam cannot produce a regression test without violating the no-shallow-test guardrail. The workflow now reports that limitation explicitly while still requiring the original symptom command to go green; any seam improvement remains separate post-fix architecture work.

The worker result is `ready-to-integrate`; this record does not claim coordinator integration, central verification, VG-001, SK-015, or any other migration item.

## Explicit exclusions

- No edit to `.skill-migration/shared-skill-yagni/MIGRATION.md`, any `.wayfinder/` file, `pi/settings.json`, any spec or glossary, `THIRD_PARTY_NOTICES.md`, `AGENTS.md`, tests, scripts, installer/deployment files, agent configs, Pi visibility symlinks, another skill/support file, or another proposal.
- No frontmatter schema, field, description, tool-grant, harness portability, explicit-invocation, discovery, deployment, or visibility redesign.
- No new support file, reusable Activity, helper script, debugger command manual, test framework guidance, performance handbook, architecture implementation, generic report schema, or copied TDD/architecture workflow.
- No changed invocation trigger, reproduction preference, hypothesis count, instrument tag requirement, performance gate, seam ownership, TDD ownership, or acceptance owner.
- No architecture work before the requested bug fix, no shallow test to satisfy a checkbox, no fixed line-count target, no per-item approval wait, no broad catalog cleanup, no central integration/verification, and no claim about another migration item.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization effect: the standing no-approval directive authorizes only the exact two paths and changes enumerated in revision 1.
- Scope check: `PASS — MAP → WF-007 → complete WF-003 target record → WF-008 → WF-006 → current specs/glossary → verified write-a-skill and codebase-design → complete target and composed-owner contracts → provenance/notices/history → executable-help applicability were reviewed in the mandated order. Exact files, six-gate behavior ledger, ownership, no-seam executability repair, contradictions, provenance/license coverage, exclusions, and verification are fixed. Production editing may continue autonomously without a per-item approval wait.`

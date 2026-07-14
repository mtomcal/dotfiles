---
id: SK-032
target: em-train
status: verified
revision: 2
blocked-by: [SK-001, SK-007, SK-014]
source-verdict: consolidate/delegate while retaining the complete training lifecycle and training-only reference material
baseline: fe739dfd92d79ab65d6052ad79847cc2bbe046ec
---

# EM Train: compose verified explainer and generic review owners without weakening training

## Why this item is next

SK-001, SK-007, and SK-014 are verified, and SK-032 is claimed at the recorded baseline. The authoring contract, corrected Create Explainer workflow, and generic fixed-point review seam therefore exist. WF-007 places EM Train in D5: preserve its real-codebase learning lifecycle while removing copied or weakened explainer behavior and nonexistent generic reviewer mechanics.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes the destination, preservation constraints, and excluded frontmatter/deployment lane.
- WF-007 assigns `em-train` the **consolidate/delegate** verdict: retain the training lifecycle and training-only reference, compose corrected `create-explainer`, and preserve real CI, no spoilers, a finite review cap, cleanup, and the user's merge choice.
- The complete WF-005 EM Train record supplies the behavior ledger: interview for goal, level, role, time, and prior knowledge; inspect plans/specs/history; negotiate one real right-sized ticket; create a ticket, explainer, training branch, and temporary guidance skill; leave implementation to the user; run honest CI and educational review; curate two or three findings; iterate within the cap; report, clean temporary runtime artifacts, and let the user choose branch disposition.
- WF-008 confirms `Training ticket`, `Temporary guidance skill`, `No-spoiler rule`, and `Review round`.
- WF-006 assigns explainer production and factual review to `create-explainer`, generic fixed-point Standards/Spec review to `code-review`, and training-specific educational curation to EM Train. It identifies copied explainer behavior, nonexistent reviewer names, and the two-versus-three round conflict as corrections required before movement.
- `specs/ai-agent-config.md` 2.3.0 and `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 require canonical body structure, semantic YAGNI, behavior preservation, conditional Reference loading, composition without ownership transfer, and isolation before editable transport.
- Verified `shared/skills/write-a-skill/SKILL.md` owns the four-section shape, local guardrails/completion criteria, progressive disclosure, and semantic pruning used here.
- Verified `shared/skills/create-explainer/SKILL.md` and `REFERENCE.md` own tier routing, source mapping, tier artifacts, mandatory independent source-grounded factual review, correction gates, verified serving, browser validation, and honest fallback disclosure. EM Train must supply its learner persona, training mission, no-spoiler constraint, temporary destination, and cleanup ownership without restating or weakening that process.
- Verified `shared/skills/code-review/SKILL.md` owns generic fixed-point Standards and Spec axes. It does not own educational finding selection or training approval.
- Verified `shared/skills/audit-shared-skills/SKILL.md` owns only the existing union-frontmatter audit used in verification.
- Complete current `shared/skills/em-train/SKILL.md`, `REFERENCE.md`, and `scripts/em-guide-template.md` were read. `REFERENCE.md` copies stale Create Explainer tier/template/HTML/serve/reviewer details, makes factual review and serving optional, names nonexistent `test-reviewer`, `quality-reviewer`, and `security-reviewer` roles, masks CI failure with `|| true`, and conflicts between two and three review rounds.
- The numeric conflict resolves to **at most two review rounds**: the primary current `SKILL.md` says “Max 2 rounds,” and the current lifecycle diagram repeats “max 2 rounds”; the isolated “Max 3 rounds total” sentence in the overloaded Reference is the contradictory detail removed. A round remains WF-008's submission followed by real CI, educational feedback, and user revision. After the second revision, one final real-CI verification records success or honest failure but does not open a third feedback round.
- Git history shows repository-local creation of all three target files at `1ef39a24ec283d262b72f62fdd6d3dc6af214737`, a local Reference expansion at `1a7a3115502f9871862ed47a1de9a19c48e19802`, and later frontmatter-only target updates. `THIRD_PARTY_NOTICES.md` has no EM Train entry or imported-source indication, so no notice change is warranted.
- `pi/skills/em-train` is an existing mode-120000 symlink to `../../shared/skills/em-train` and resolves. The only file under `scripts/` is a non-executable Markdown template; there is no executable helper to preserve or validate.
- Pi `docs/skills.md` confirms recursive `SKILL.md` discovery, relative support paths, progressive disclosure, and temporary project skill locations. Runtime discovery location remains selected for the active harness rather than hardcoded as durable shared state.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-032-em-train.md` — item-local authority, behavior ledger, state, and verification record.
- `shared/skills/em-train/SKILL.md` — preserve frontmatter and replace the overloaded summary with confirmed definitions plus one complete routed training Workflow and conditional training Reference pointers.
- `shared/skills/em-train/REFERENCE.md` — retain only training ticket schema, branch/setup contract, guidance assembly, educational review rules, report schema, and cleanup/branch-choice detail.
- `shared/skills/em-train/scripts/em-guide-template.md` — keep the existing template frontmatter and make the single guidance template carry the retained no-spoiler, existing-code example, user-implementation, reference-path, and struggle-report behavior formerly duplicated in Reference.

These four paths are the complete revision 2 scope. No explainer owner file, review owner file, runtime-generated guide, session report, branch, or Pi visibility entry is created during migration.

## Proposed changes

### Add

- Add exact WF-008 Language Definitions for Training ticket, Temporary guidance skill, No-spoiler rule, and Review round.
- Add one inline route with explicit completion criteria: intake; repository evidence and ticket negotiation; one scope checkpoint; setup; composed explainer; user implementation; two capped review rounds; final report and cleanup/branch choice.
- Record the training branch's start commit as the fixed review point and record branch ownership before the user works.
- State that the user owns production implementation. During the implementation phase the EM answers through the temporary guide and waits for `ready for review`; it does not write the ticket solution.
- Invoke verified `create-explainer` as a required composed workflow. Pass the interview persona, training mission, no-spoiler constraint, and temporary destination. Require examples and claims to come from code that existed at the training fixed point, never the requested solution or the learner's new code. Accept only the composed workflow's reviewed, identity-checked, browser-validated result and retain its process/evidence ownership unchanged.
- Invoke verified `code-review` only for generic Standards/Spec assessment over the fixed point and current branch. Keep educational review local: combine CI evidence, generic findings, ticket criteria, tests, and the learner's demonstrated choices into two or three concrete level-calibrated educational findings.
- Require exact real repository CI entry points from repository guidance or CI configuration, preserve exit statuses, and report test, infrastructure, and unavailable-check failures honestly. No `|| true`, toy substitute, or claimed pass without execution.
- Preserve the Round-1 no-rubber-stamp rule without inventing defects: Round 1 always returns two or three evidence-backed learning improvements; when correctness is clean, use a concrete test, clarity, convention, or tradeoff improvement grounded in the diff and codebase.
- Resolve the cap to two review rounds. Round 2 may end with a final user revision and one final real-CI verification; failures remain failures and do not silently create Round 3.
- Add final report fields for fixed point/branch, ticket and result, CI/review evidence by round, two or three key lessons, patterns to remember, next ticket, unresolved failures, cleanup, and the preserved user-selected merge-or-leave choice.

### Change or move

- Preserve `shared/skills/em-train/SKILL.md` frontmatter byte-for-byte, including all learning/interview/real-codebase triggers and existing grants.
- Replace `Quick start`, `Core principles`, and plural `Workflows` with canonical `Language Definitions`, one `Workflow`, and `Reference`.
- Keep goal, exact experience level, specialty/role, time budget, and prior knowledge intake inline and use them to calibrate ticket size, educational feedback, and the composed explainer persona.
- Keep repository exploration inline at the behavioral level: inspect applicable plans/roadmaps, specs/architecture/AGENTS guidance, recent history, tests/CI, and existing TODO/issues; present evidenced project needs and negotiate one meaningful ticket the learner can finish in the available time. Do not use fixed difficulty ladders.
- Keep one checkpoint after ticket negotiation and before branch or temporary artifact creation. It names mission, scope, acceptance criteria, likely files, exclusions, time fit, and explainer purpose; continue only on the user's `proceed`, revise on `adjust`, stop on `cancel`.
- Create a `train/em-<date>-<ticket-slug>` branch without relying on nonexistent `slugify`; fail safely if it exists or the starting tree is unsuitable. Record the start commit and whether the branch was created by this session. Put the temporary guide in a project skill location actually discovered by the active harness, record that exact location, and keep it out of the training diff/commit.
- Keep literal ticket, setup, review, report, and cleanup schemas in `REFERENCE.md` with mandatory load points from the main Workflow.
- Make `scripts/em-guide-template.md` the sole guidance-body template. Reference supplies placeholder/assembly instructions but no copied template body.
- Preserve cleanup of the temporary guide, explainer browser/server and incidental evidence owned by the session, while leaving durable report and training branch disposition to the user. Never persist runtime process IDs, ports, pane IDs, or other live identities in repository files.

### Remove

- Remove copied Create Explainer intake matrices, tier rules, source-discovery steps, template catalog, HTML/CSS/JS conventions, serving commands, self-checks, reviewer prompt, and optional-review language from EM Train Reference. Replace them with one composition contract pointing to the verified owner and retaining only EM-specific persona, mission, no-spoiler, destination, and returned-evidence requirements.
- Remove generic reviewer-role routing to nonexistent `test-reviewer`, `quality-reviewer`, and `security-reviewer`. Replace only applicable generic diff review with `code-review`; do not delegate educational curation.
- Remove the `make test 2>&1 || true` example and hardcoded backend test example. Repository-discovered real CI with captured status owns execution.
- Remove the “Max 3 rounds total” branch and lifecycle duplication. Keep one cap of two rounds and one final verification rule.
- Remove duplicate guidance-skill body text from `REFERENCE.md`; retain the single sibling template.
- Remove no trigger, interview input, repository-evidence requirement, ticket negotiation, checkpoint, no-spoiler constraint, existing-code-example rule, user implementation phase, CI honesty gate, Round-1 improvement requirement, educational curation, finite cap, report, cleanup, branch ownership, or merge choice.

## Proposed skill shape

1. `Language Definitions` — present; the four exact human-confirmed EM Train terms.
2. `Workflow` — present; one routed evidence → negotiated ticket → setup/composed explainer → user implementation → capped review → report/cleanup lifecycle.
3. `Activities` — omitted; no command or recipe is selected outside the required training lifecycle.
4. `Reference` — present; conditional pointers load training-only ticket/setup/guidance, review/report, and cleanup detail at their governing steps.

## Behavior-preservation checklist

- [x] Target frontmatter is byte-identical; interview-prep, language/framework fluency, real-codebase work, and structured-TDD triggers remain.
- [x] Goal, `beginner`/`intermediate`/`advanced` level, specialty/role, time budget, and prior knowledge are explicitly collected or confirmed.
- [x] Applicable plans, specs, project guidance, recent history, issue/TODO evidence, tests, and real CI entry points are inspected before scope is proposed.
- [x] One real project ticket is negotiated rather than invented as a ladder exercise; its scope fits learner ability and time.
- [x] Exactly one pre-setup checkpoint records mission, scope, acceptance criteria, likely files, exclusions, time fit, and explainer purpose, with proceed/adjust/cancel handling.
- [x] Ticket keeps story, task, testable acceptance criteria, likely files, and tips without giving away the solution.
- [x] Training branch uses a safe `train/em-...` name; start commit, session ownership, tree preconditions, and branch disposition remain recorded.
- [x] Temporary guidance skill is created in an active-harness-discoverable project location, excluded from the training diff, and removed afterward.
- [x] `create-explainer` is composed rather than copied; its mandatory source-grounded review, correction, verified serve, browser validation, and honest fallback/limitation reporting are not weakened.
- [x] EM Train retains explainer persona, mission, no-spoiler, destination, evidence-return, and eventual cleanup ownership.
- [x] Explainer, ticket tips, and guidance examples use only existing fixed-point code; no learner solution, exact core call, copy-ready return shape, or registry implementation is supplied.
- [x] The temporary guidance skill teaches APIs, syntax, conventions, debugging, and existing analogous code, asks what the learner tried, and never writes the ticket implementation.
- [x] The user—not the EM—implements production code before review.
- [x] Real repository CI runs with unmasked statuses on every review round and after the final second-round revision when applicable; failures and unavailable checks are honest.
- [x] `code-review` is used only for generic fixed-point Standards/Spec axes and never replaces test evidence or educational review.
- [x] Each review curates two or three evidence-backed, actionable, level-calibrated educational findings; Round 1 cannot rubber-stamp or invent a defect.
- [x] At most two review rounds occur. No third feedback round is opened; final verification records pass or unresolved failure.
- [x] Session report records result, two or three key lessons, patterns, next step, branch/fixed point, CI/review evidence, failures, and cleanup/disposition.
- [x] Temporary guide, explainer server/browser, and incidental runtime artifacts owned by the session are cleaned; durable branch/report remain only under recorded user choice.
- [x] User chooses whether to merge or leave the branch as a learning artifact. No merge occurs without that choice; deletion is not invented as a third disposition.
- [x] No live process, port, pane, session, or runtime skill identifier is persisted in committed files.
- [x] Reference contains only training-owned schema/setup/guidance/review/report/cleanup material and every pointer states when and why to load it.
- [x] No behavior is pruned to meet a fixed line target; every removal has the verified owner or retained location named above.

## Dependencies, provenance, and risks

- SK-001, SK-007, and SK-014 are verified at baseline. No unfinished owner blocks this item.
- The two-versus-three contradiction is repaired before movement in favor of the twice-stated primary cap of two. The final CI-only check after the learner's second revision prevents an unverified “approval” without opening a third educational review round.
- Create Explainer composition imports process, not ownership. EM Train retains its temporary destination, mission, no-spoiler constraints, user gates, and cleanup; Create Explainer retains factual review/serve/browser process semantics.
- Code Review owns generic axes only. CI/test interpretation and pedagogical selection remain training-specific, and no generic PASS can approve the training session by itself.
- A runtime-discovered project skill path differs by harness. The Workflow requires discovery and recording rather than hardcoding Pi-only placement. Generated live paths and process IDs are session state, not migration artifacts.
- Repository history indicates local authorship and no third-party notice obligation. `THIRD_PARTY_NOTICES.md` remains unchanged.
- The sibling template is Markdown mode `100644`, not an executable helper. No new executable, dependency, or command surface is introduced.

## Verification

1. Compare `shared/skills/em-train/SKILL.md` frontmatter byte-for-byte with baseline `fe739dfd92d79ab65d6052ad79847cc2bbe046ec`.
2. Reread all three production files and map every checked ledger item to one resulting location or the verified `create-explainer`/`code-review` owner.
3. Parse level-two headings in `SKILL.md`; expect exactly `Language Definitions`, `Workflow`, and `Reference`, in that order, with no `Activities`.
4. Compare all four definitions with WF-008; expect semantic identity and no competing definitions.
5. Resolve every source-time Markdown path and fragment from `SKILL.md` and `REFERENCE.md`; render a temporary guide fixture and resolve the template's generated-relative links there. Confirm Reference has no copied Create Explainer lab/template/HTML/browser/reviewer mechanics and no nonexistent reviewer names.
6. Search resulting files for review-cap language; expect only an at-most-two-round contract plus final CI verification, with no third round or ambiguous max.
7. Search for `|| true`, hardcoded toy CI, `test-reviewer`, `quality-reviewer`, `security-reviewer`, optional explainer review/serve, copied Playwright/browser commands, and copied lab-template catalog; expect none.
8. Inspect composition language against verified owner files: `create-explainer` remains mandatory through factual review, correction, identity-checked serving, and browser validation; `code-review` remains generic fixed-point Standards/Spec only; educational review remains local.
9. Inspect no-spoiler and implementation ownership: all examples derive from existing fixed-point code, temporary guidance refuses implementation, and the Workflow waits for user submission.
10. Run the complete YAML-aware `audit-shared-skills` union-frontmatter workflow. Expect all catalog entries accounted for and no target finding or introduced catalog finding.
11. Run `test -L pi/skills/em-train && test "$(readlink pi/skills/em-train)" = '../../shared/skills/em-train' && test -f pi/skills/em-train/SKILL.md`.
12. Inspect `git log --follow`, file modes, and `THIRD_PARTY_NOTICES.md`; expect local provenance, production files mode `100644`, unchanged notice, and unchanged Pi link mode `120000`.
13. Run `bash tests/run.sh` and `git diff --check`.
14. Compare baseline-aware names and statuses. Expect exactly this proposal plus the three authorized production files; no diff in `MIGRATION.md`, `pi/settings.json`, specs, notices, owner skills, Pi visibility, deployment, tests, or unrelated items.
15. Commit the exact authorized result and verify the committed range and clean worktree.

Acceptance requires exact four-file scope, canonical shape, exact definitions, complete training ledger, corrected two-round cap, no copied/weakened explainer process, no nonexistent reviewer mechanics, honest real CI, preserved educational review, valid references/frontmatter, resolving Pi visibility, local provenance, passing tests/diff checks, and a clean committed worktree.

## Implementation and verification record

Worker verification recorded at `2026-07-14T19:21:18+00:00` against fixed baseline `fe739dfd92d79ab65d6052ad79847cc2bbe046ec`. The worktree had no post-baseline commit during review; the stable scope was the baseline-to-worktree diff for the three tracked production files plus the item-local proposal addition.

- Proposal control: revision 2 had reached `proposal-ready` under the standing directive before the final production correction. The complete resulting diff required no material file-set, behavior, ownership, removal, or provenance change, so revision 2 remains authoritative and worker-owned status is now `ready-to-integrate`.
- Actual production diff: `REFERENCE.md` has 141 insertions and 343 removals, `SKILL.md` has 78 insertions and 29 removals, and `scripts/em-guide-template.md` has 36 insertions and 22 removals. Resulting SHA-256 values are `c5caee9f7657617b29cb0cc3aaff85cb51a1309ddec56facc082a89c37a4dbfa`, `b870e38068c961b1f8de9aeaf81791f13770e7c40aafdfb827654d0ec240434a`, and `c8e5bff82d2bd839869778c96af93292226da38f319023f35fad3e8058495abb`, respectively.
- Standards pass: PASS — 0 findings; worst issue: none. All four changed files were considered against `AGENTS.md`, the shared-skill/body and composition contracts, `write-a-skill`, `audit-shared-skills`, proposal format, local guardrail/completion placement, links, frontmatter, provenance, Pi visibility, modes, and exact/protected scope. The proposal is item-local; the target uses exactly the earned `Language Definitions`, `Workflow`, and `Reference` sections; all pointers state when and why to load support; the main path stays executable; and no judgement-call smell warranted a finding.
- Spec pass: PASS — 0 findings; worst issue: none. In a separate fresh checklist, all four changed files were considered against the standing request, proposal revision 2, the complete WF-005 EM Train ledger, WF-006 ownership boundaries, WF-007 verdict, WF-008 definitions, and verified `create-explainer`/`code-review` contracts. Exact intake, one real ticket and joint checkpoint, safe branch/temporary guide, fixed-point/no-spoiler teaching, user implementation, honest real CI, Round-1 improvement, two or three educational findings, the two-round cap, final verification, report/cleanup, merge-or-leave choice, complete explainer composition, and narrow generic review use are all retained without unrequested production behavior.
- Structure, behavior, and disclosure: PASS. Target frontmatter and template frontmatter are byte-identical to baseline. Target level-two headings are exactly `Language Definitions`, `Workflow`, and `Reference`; all four WF-008 definitions are semantically exact; all source-time links/fragments resolve; and a rendered template fixture resolves its generated-relative ticket, explainer, and struggle references. The complete checked behavior ledger maps to the target, its training-only Reference/template, or the verified composed owner.
- Correctness repairs and semantic YAGNI: PASS. The result removes copied Create Explainer implementation mechanics, weakened optional review/serve language, nonexistent reviewer roles, masked/hardcoded CI examples, duplicate guidance-template text, the contradictory third review round, and the unearned delete-branch disposition. No fixed line target governed pruning.
- Catalog, visibility, modes, and provenance: PASS. The YAML-aware union audit accounts for all 34 shared skills with zero errors and zero warnings; the unchanged EM Train grants remain earned. `pi/skills/em-train` remains mode `120000`, targets `../../shared/skills/em-train`, and resolves; all three production files remain mode `100644`. Repository-local creation at `1ef39a24ec283d262b72f62fdd6d3dc6af214737` and Reference expansion at `1a7a3115502f9871862ed47a1de9a19c48e19802` remain confirmed, with no EM Train notice obligation.
- Repository and protected-scope verification: PASS. `bash tests/run.sh` passes both shell files and all 12 tests; focused structure/definition/link/template/forbidden-text/visibility/mode/provenance assertions and `git diff --check` pass. The baseline/current SHA-256 values remain identical for protected `.skill-migration/shared-skill-yagni/MIGRATION.md` (`3972b37c…`), `pi/settings.json` (`ccd1befa…`), and `THIRD_PARTY_NOTICES.md` (`2db33bef…`). Exactly the proposal plus three authorized production paths differ, and no live runtime identity is persisted.
- Residual risks: active-harness project skill discovery locations vary, so the runtime workflow verifies discovery or explicit loading rather than hardcoding Pi state. A post-Round-2 revision receives CI and targeted verification only; by design, it cannot silently open a third educational feedback cycle.

The worker result is `ready-to-integrate`; this record does not claim coordinator integration, coordinator verification, central `verified` state, or catalog-wide completion.

Coordinator integration verification completed at `2026-07-14T19:28:29+00:00` against integrated commit `843b5cf`: the complete target, training-only Reference/template, proposal, source ledger, confirmed definitions, and composed owner interfaces were reread. Exact four-file scope; byte-preserved target frontmatter; canonical section order; exact intake, real-ticket evidence and joint checkpoint; safe branch/fixed point/temporary-guide setup; complete mandatory Create Explainer composition; user implementation and no-spoiler ownership; honest real CI; narrow fixed-point Code Review composition; two-or-three educational findings; no-rubber-stamp rule; two-round cap plus final verification; durable report, cleanup, and merge-or-leave choice; rendered template links; Pi visibility; local provenance; and exclusions passed independent checks. The YAML-aware audit parsed/accounted for all 34 skills with zero errors and the one deferred SK-027 grant warning, `git diff --check` passed, and `bash tests/run.sh` passed all 12 tests. The protected `pi/settings.json` content and diff hashes remained `7d3f4713d7239e8cda3f75597a55f1767fecdf7964324630e4e74dc686d12e05` and `8298a9063e3ebf2988000d176057a41c31cf20c10bbabe92fb57d47f9f2738d5`. Residual risks remain harness-specific temporary skill discovery and the intentional CI-plus-targeted-check boundary after a Round-2 revision.

## Explicit exclusions

- No edits to `.skill-migration/shared-skill-yagni/MIGRATION.md`, `pi/settings.json`, `.wayfinder/`, specs/glossary, `THIRD_PARTY_NOTICES.md`, `AGENTS.md`, tests, installer/deployment, agent configs, Pi visibility, another proposal, another skill, or Create Explainer lab assets.
- No frontmatter redesign, grant change, runtime-discovery redesign, new shared skill, new executable helper, new reviewer role, generic CI/delivery workflow, fixed line target, or upstream synchronization.
- No generated live training branch, temporary guidance directory, explainer, report, browser/server, process ID, port, pane, or session identity during migration.
- No coordinator integration, central verification, VG-001, SK-031, SK-033, or other migration-item claim.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `2`
- Scope check: `PASS — revision 2 repeated the full authority, exact-file, behavior-ledger, contradiction, provenance, and verification review. It removes only revision 1's unearned delete choice, preserving the source-authoritative merge-or-leave branch decision. Exact four-file scope, owner boundaries, two-round cap, and all other authorized behavior remain unchanged; production editing may continue under the standing directive.`

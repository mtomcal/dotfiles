---
id: SK-010
target: update-specs
status: ready-to-integrate
revision: 1
blocked-by: [SK-001, MG-001]
source-verdict: retain substance; repair executable and ownership contract
baseline: 50d5fbbca7d976e01cf95883104caeaf58592f0a
---

# Update Specs: retain the gated workflow and repair its executable and ownership contracts

## Why this item is next

MG-001, SK-001, and SK-009 are verified, so SK-010 is unblocked and was claimed from baseline `50d5fbbca7d976e01cf95883104caeaf58592f0a`. WF-007 places it in the correctness-before-movement tranche: preserve the substantive discrepancy/plan/edit/review workflow, but first replace the nonexistent `update-specs --since` command and malformed range handling, route terminology through the verified owner, and make editable delegation isolation plus durable writer authority explicit. Its proposal and two target files are disjoint from the concurrently claimed SK-011 scope.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` and WF-007 — final verdict `retain`; keep one authoritative discrepancy definition set, the preflight and pre-edit plan gates, in-process fallback, three reviews, rollback, versioning, and glossary routing while repairing Git and ownership correctness before movement.
- Complete WF-005 `update-specs` record — the behavior-preservation ledger requires a clean tree, explicit resolvable boundary, non-empty diff, project/spec authority reading, five-way classification, discrepancy table and execution plan before edits, delegated or equivalent in-process execution, contract/cross-spec/mechanical reviews, rollback on guardrail failure, prescriptive language-agnostic specs, version/changelog updates, terminology routing, and the shared-skill audit when relevant. It approves progressive disclosure but requires one semantic owner for discrepancy definitions.
- WF-008 — human-confirmed definitions for spec discrepancy, coverage gap, violation, checklist drift, reasoning gap, and in-spec change.
- WF-006 — project language and spec form remain owned by the applicable glossary and `SPEC-OF-SPECS`; `ubiquitous-language` owns ongoing terminology work; editable delegates require isolated worktrees/clones selected before transport; callers retain briefs, state, acceptance, returned evidence, durable writer authority, and an in-process fallback.
- `specs/SPEC-OF-SPECS.md` version `1.1.0` — authoritative required sections, language-agnostic policy, preamble-file status, reading-order rule, semantic versioning, and changelog contract.
- `specs/README.md` version `0.5.0` — suite reading order, dependency graph, implementation checklists, and current spec versions.
- `specs/UBIQUITOUS_LANGUAGE.md` version `0.7.0` — project glossary is `specs/UBIQUITOUS_LANGUAGE.md`; skill-local terms stay in skill bodies; project-domain terminology stays in the applicable glossary.
- `specs/ai-agent-config.md` version `2.3.0` — canonical skill-body shape, behavior-preservation gate, composition boundaries, read-only/editable isolation binary, caller ownership, provenance, and union-frontmatter contract.
- Verified `shared/skills/write-a-skill/SKILL.md` — requires one routed Workflow, local gates/failures/completion criteria, earned conditional References, semantic YAGNI, and complete behavior preservation without a line target.
- Verified `shared/skills/ubiquitous-language/SKILL.md` — selects create/update mode and one repository-authoritative glossary path, preserves project form on update, and pauses rather than creating a competing glossary when authority is ambiguous.
- Complete current `shared/skills/update-specs/SKILL.md` and `REFERENCE.md` — the main body advertises a shell command that does not exist, then appends `..HEAD` even when the example already supplies `main..feature-branch`; both files partially define discrepancy classes; terminology is edited directly; delegation does not state checkout isolation, integration authority, or returned evidence.
- Git `2.43.0` local help and command probes — `git diff -h` and `git help diff` accept two endpoint commits or `<commit>..<commit>`; `git help revisions` documents `r1..r2`; `git rev-parse --verify '<rev>^{commit}'` resolves commit endpoints. `git diff main..feature-branch..HEAD` fails with exit 128. `git diff --quiet HEAD..HEAD --` returns 0, a changed comparison returns 1, and an invalid comparison returns 128.
- Git/provenance history — the skill was introduced locally at `bc7752d045d54609d4c718a811b1f838bb6a070f`, completed at `80cae589db1badcc2e9950bab7ea9a14afcb16b2`, and promoted with its current Reference at `1e03d8e3f07eadc36e59694f4cface463ce39c19`; no imported source, upstream revision, license, or `THIRD_PARTY_NOTICES.md` entry is evidenced.
- Pi visibility — `pi/skills/update-specs` is the existing symlink to `../../shared/skills/update-specs`.

No authority conflict remains. The executable contract will treat the supplied value as skill input, not a fictitious binary option: accept either one base revision, normalized to `<base>..HEAD`, or one complete two-dot comparison `<base>..<head>` with both endpoints present; reject three-dot, omitted endpoints, and multiple comparisons; verify both endpoints as commits; then use that normalized comparison unchanged for every diff. This preserves both intended examples after correcting the ranged example's execution.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-010-update-specs.md` — item-local authorization, behavior ledger, scope review, and verification record.
- `shared/skills/update-specs/SKILL.md` — canonical body normalization, authoritative discrepancy definitions, real boundary contract, terminology route, editable delegation ownership, required gates, and completion evidence.
- `shared/skills/update-specs/REFERENCE.md` — executable boundary recipe, evidence prompts, plan/delegation details, authoring rules, three review checklists, and scoped rollback procedure without duplicate discrepancy definitions.

These three paths are the complete revision 1 allowed file set. Both target files must change together because the correction removes duplicated semantics while preserving progressive disclosure.

## Proposed changes

### Add

1. Add `Language Definitions` containing exactly the six WF-008-confirmed terms. This is the sole authoritative discrepancy definition set; the Reference will point back to it rather than restating label meanings.
2. Add a routed Workflow opening that requires one caller-supplied Git boundary in either `<base>` or `<base>..<head>` form and explicitly says it is skill input, not an `update-specs` executable or `--since` option.
3. Add an executable normalization contract: a single base becomes `<base>..HEAD`; a complete two-dot comparison is used unchanged; omitted endpoints, three-dot notation, and multiple comparisons stop. Resolve both endpoints with `git rev-parse --verify '<endpoint>^{commit}'`; interpret `git diff --quiet '<base>..<head>' --` as 0 = empty/stop, 1 = changed/continue, greater than 1 = error/stop.
4. Add completion criteria for preflight, classification/plan, editing, reviews/integration, rollback, and final reporting.
5. Add explicit editable delegation rules: select checkout topology before transport; read-only reviewers may share a checkout; any editor uses an isolated clone/worktree from the recorded pre-edit commit and an exact file scope; a pane alone is not isolation. The invoking agent remains the sole plan/scope owner, durable writer/integrator, acceptance authority, and final reporter. Delegated editors return a commit or patch, exact changed paths, versions/changelogs, and concerns; they do not directly mutate the invoking checkout or workflow state.
6. Add a verified terminology composition route: when a finding requires new/refined vocabulary, load and execute `../ubiquitous-language/SKILL.md` against the repository-authoritative glossary. Update Specs retains the discrepancy plan, candidate integration, all three reviews, and acceptance; it does not directly take over terminology ownership.
7. Add a Reference boundary-normalization recipe using real Git syntax, classification evidence prompts that apply but do not redefine the six main-body terms, an expanded execution-plan contract, delegation return contract, reasoning-gap prompts, review failure handling, and path-scoped rollback for both isolated and in-process edit modes.

### Change or move

1. Preserve frontmatter byte-for-byte, including all triggers and existing union fields/tool grants; frontmatter redesign and least-privilege changes remain excluded.
2. Replace the unheaded summary, `Quick Start`, fragmented `Reasoning Gaps`, and `Review Standard` with one `Workflow` ordered as: route/preflight; detect and plan; edit through isolated delegation or in-process fallback; run three sequential reviews and integrate the exact reviewed candidate; report or rollback.
3. Move the five discrepancy labels from duplicated main/reference tables into the authoritative `Language Definitions`, adding the confirmed umbrella term `spec discrepancy` there. Keep classification commands, evidence capture, and the discrepancy-table output contract beside the classification step.
4. Move the detailed reasoning-gap trigger examples to the Reference as evidence prompts; retain the authoritative one-sentence meaning only in `Language Definitions`.
5. Preserve the pre-edit discrepancy table and execution plan as a hard sequence gate without inventing a user-approval wait. Every changed area, including in-spec no-op findings, must be accounted for before editing.
6. Preserve authoring behavior while grounding it in repository authority: do not invent behavior; specs remain prescriptive and language-agnostic; apply the target `SPEC-OF-SPECS`; bump versions and append changelogs where required; update `specs/README.md` when its versions, reading order, graph, checklist, or scope is affected.
7. Preserve all three reviews in strict order. Contract consistency checks changed requirements against implementation/test evidence; cross-spec integrity checks glossary, dependencies, reading order, prefixes, forms, and links; mechanical quality checks versioning, changelogs, sections, Markdown links, and language-agnostic form. Fix failures in the editable candidate and rerun only failed passes; never waive one pass with another.
8. In delegated mode, run the reviews against the candidate branch/commit and integrate only the exact head that passed all three. In fallback mode, the invoking agent performs the same edits and explicit reviews in process. In both modes, completion reports the normalized comparison, discrepancy disposition, exact files/versions, review evidence, audit result when applicable, and unresolved concerns.
9. Preserve the conditional `REFERENCE.md` pointer but make its load condition mandatory after preflight and through classification, editing, review, and rollback. Add the conditional terminology-owner pointer with its trigger and reason.

### Remove

1. Remove the nonexistent shell invocation `update-specs --since <ref>`, the `--since` parameter fiction, and commands that blindly append `..HEAD` to a possibly complete comparison.
2. Remove the duplicate discrepancy definition table from `REFERENCE.md` and duplicate `reasoning gap exists when` definition from the body; retain one authoritative definition set plus non-definitional operational prompts.
3. Remove direct instruction to add terms to `specs/UBIQUITOUS_LANGUAGE.md`; replace it with composition through `ubiquitous-language` and repository authority.
4. Remove delegation wording that allows an editor or generic reviewer to edit without isolated checkout, explicit scope, return evidence, and invoking-agent integration authority.
5. Remove broad rollback wording that could restore all of `specs/` without an exact produced-path inventory. Rollback remains mandatory but is limited to item-produced tracked and newly created paths recorded before editing; isolated partial candidates are never integrated.
6. Remove no trigger, clean-tree/ref/non-empty gate, authority read, discrepancy class, discrepancy table, execution plan, delegation/fallback branch, review pass, fix/rerun behavior, rollback behavior, authoring rule, version/changelog requirement, glossary route, shared-skill audit, output evidence, or completion condition.

## Proposed skill shape

1. `Language Definitions` — present and mandatory; the sole authoritative set for spec discrepancy and its five classifications.
2. `Workflow` — present; one gated synchronization process with Git-boundary routing first, then classification/plan, isolated or in-process editing, three reviews, exact integration, rollback, and report.
3. `Activities` — omitted; preflight, classification, editing, reviewing, and rollback are required stages rather than independently selected recipes.
4. `Reference` — present; conditionally points to `REFERENCE.md` after preflight for detailed execution/checklists and to `ubiquitous-language` only when terminology changes require its owner workflow.

## Behavior-preservation checklist

- [x] Frontmatter name, all invocation triggers, short description, union fields, and tool grants remain unchanged.
- [x] Clean working tree remains a hard preflight gate.
- [x] An explicit resolvable boundary and non-empty implementation diff remain hard gates; no default is guessed.
- [x] The historical single-ref intent and complete two-dot example both remain reachable through one real normalization contract.
- [x] `AGENTS.md`, `specs/README.md`, relevant specs, diff stat, and complete diff remain required evidence in authority order.
- [x] Spec discrepancy plus coverage gap, violation, checklist drift, reasoning gap, and in-spec change use all six human-confirmed definitions in one authoritative set.
- [x] Reasoning-gap lifecycle/tool/bug-rationale prompts remain available in Reference without competing definitions.
- [x] A discrepancy table and execution plan remain visible before any spec or glossary edit; no new approval wait is invented.
- [x] Every changed area, including no-update in-spec changes, receives a disposition.
- [x] Delegation remains preferred when available, with a behaviorally equivalent in-process fallback.
- [x] Editable isolation is selected before transport; read-only sharing, editor worktree/clone, exact scope, return evidence, and invoking-agent durable authority are explicit.
- [x] Composition imports the verified terminology process without transferring the spec plan, candidate, review, or acceptance ownership.
- [x] Specs remain evidence-backed, prescriptive, and language-agnostic; no behavior is invented.
- [x] Target suite form, version bumps, changelog entries, reading order, dependency graph, prefix registration, and README maintenance follow current spec authority.
- [x] Contract consistency, cross-spec integrity, and mechanical quality remain three separate sequential passes; failed passes are fixed and rerun without waiving the others.
- [x] Delegated edits are integrated only from the exact candidate head that passed all three reviews.
- [x] Guardrail interruption still rolls back partial edits rather than leaving half-synchronized artifacts; rollback is now exact-path and mode-aware.
- [x] Shared-skill behavior changes still route to the union-frontmatter audit.
- [x] Final output reports normalized scope, discrepancy dispositions, exact artifact paths/versions, review evidence, audit result when applicable, and unresolved risks.
- [x] Progressive disclosure remains earned; detailed recipes/checklists stay in Reference while main-path gates, failures, ownership, and completion remain inline.
- [x] Local provenance remains accurate; no unsupported attribution or license is added.
- [x] No spec, glossary, notice, deployment, visibility, migration-ledger, test, script, or unrelated skill/proposal changes.

## Dependencies, provenance, and risks

- MG-001 and SK-001 are verified contract blockers; SK-009 is the verified terminology owner consumed by this item. This proposal does not reopen or edit their production files.
- The malformed range is repaired before prose movement. Restricting the contract to one base or one complete two-dot comparison deliberately excludes three-dot merge-base comparison because it has different semantics; users needing that scope must first choose explicit endpoints. Risk: callers may colloquially say `--since`; the workflow reports the accepted input form instead of pretending a binary exists.
- Git documentation notes that `git diff A..B` compares two endpoints even though two-dot is revision-range notation elsewhere. The resulting prose calls it a normalized comparison when executing `git diff` and does not claim commit-set semantics.
- The terminology route may require user clarification when several glossaries are plausibly authoritative; that is inherited intentionally from the verified owner and prevents competing glossary writes.
- Editable delegation adds isolation and candidate integration but does not choose a terminal transport. Transport-specific commands remain owned elsewhere; the complete in-process fallback prevents a harness dependency.
- Broad rollback is narrowed to exact produced paths. Because preflight requires a clean tree and the workflow records the pre-edit commit/path inventory, this retains clean rollback while avoiding accidental restoration of unrelated files.
- Git history and notices support repository-local provenance. No imported source is moved, no license applies, and `THIRD_PARTY_NOTICES.md` remains unchanged.
- Existing `allowed-tools` is preserved despite possible least-privilege questions because frontmatter redesign is a separate lane. The baseline-aware audit will distinguish target regressions from unrelated catalog findings.

## Verification

1. Reread complete `shared/skills/update-specs/SKILL.md` and `REFERENCE.md`; map every WF-005 ledger item and checklist entry above to one resulting location.
2. Parse level-two headings in `SKILL.md`; expect exactly `Language Definitions`, `Workflow`, and `Reference` in that order, with no `Activities` heading.
3. Assert all six WF-008 definitions occur once in `SKILL.md`; assert `REFERENCE.md` identifies them as authoritative and contains no competing type/signal definition table.
4. Inspect all Git commands and probe them in a temporary repository with Git `2.43.0`: single base normalization, complete two-dot comparison, endpoint verification, empty exit 0, non-empty exit 1, invalid exit greater than 1, and rejection of malformed/triple-dot forms. Confirm no `update-specs --since` invocation or double-appended `..HEAD` remains.
5. Inspect route/ownership wording: terminology must load `../ubiquitous-language/SKILL.md`; editor isolation must precede transport; read-only sharing, isolated editable candidate, exact scope, return evidence, invoking-agent sole integration/durable authority, exact reviewed-head integration, and in-process fallback must all remain explicit.
6. Inspect all three review checklists, failure/rerun rules, scoped rollback, version/changelog rules, and final report contract in complete context.
7. Resolve every Markdown link from the target directory and verify target support contains no nested unresolved pointer or script.
8. Run a catalog parser implementing the loaded `audit-shared-skills` union checks against baseline and result. Acceptance: target retains all required fields, a `Use when` description within 1024 characters, and no new target/catalog error or warning is introduced; unrelated baseline findings are reported, not edited.
9. Run `test -L pi/skills/update-specs && test "$(readlink pi/skills/update-specs)" = '../../shared/skills/update-specs'`.
10. Recheck `git log --follow` for both target files and target absence from `THIRD_PARTY_NOTICES.md`; expect local provenance and no notice diff.
11. Run `git diff --check -- .skill-migration/shared-skill-yagni/proposals/SK-010-update-specs.md shared/skills/update-specs/SKILL.md shared/skills/update-specs/REFERENCE.md`.
12. Run `bash tests/run.sh`; expect repository regression checks to pass.
13. Compare changed paths from baseline plus untracked files. Acceptance: exactly this proposal, `SKILL.md`, and `REFERENCE.md`; no diff in `MIGRATION.md`, `pi/settings.json`, specs/glossary, notices, deployment, visibility, tests, or unrelated files.

Acceptance requires exact three-file scope, canonical three-section body, one authoritative definition set, a command-probed boundary contract, complete preflight/plan/edit/review/rollback/versioning behavior, owner-routed terminology, explicit editable isolation and invoking-agent authority, valid links/frontmatter/Pi visibility/provenance, clean diff checks, and passing repository tests.

## Implementation record

Focused verification completed: `2026-07-14T17:10:22+00:00`.

- Proposal-before-edit control: revision 1 reached `proposal-ready` with the exact proposal/support/target file set before either production file changed. No material scope revision was needed.
- Actual production diff: `shared/skills/update-specs/SKILL.md` has 53 insertions and 38 removals; `shared/skills/update-specs/REFERENCE.md` has 139 insertions and 73 removals. This proposal is the only additional item-local file.
- Resulting SHA-256: `SKILL.md` is `c923339e4022a4bfde88d862a458eb6b03a66201197980be771356e50a96c25c`; `REFERENCE.md` is `1050235795fbadfc24830c99394c7ffddfaa6b3a28450c35bd2d56538e80c011`.
- Complete-file and behavior-ledger review: PASS. The clean-tree/resolvable/non-empty gates, authority reading, five classifications plus umbrella term, discrepancy table, pre-edit execution plan, delegated/in-process branches, prescriptive and language-agnostic authoring, version/changelog duties, all three reviews, failed-pass reruns, rollback, audit route, and final evidence contract remain.
- Canonical body: PASS. Level-two headings are exactly `Language Definitions`, `Workflow`, and `Reference`; no `Activities` section is invented. All six WF-008 definitions occur exactly once in the authoritative definition section, and the support file points to rather than duplicates that set.
- Correctness repairs: PASS. The fictitious `update-specs --since` surface and double-appended range are gone. The contract accepts one base or one complete two-dot comparison, pins both commit OIDs, and uses the pinned comparison unchanged. Git 2.43.0 temporary-repository probes passed single-base/two-dot normalization, malformed/triple-dot/omitted endpoint rejection, endpoint failure, and diff exits 0/1/128; the Reference shell block passes `bash -n`.
- Ownership repairs: PASS. Canonical glossary location is resolved through verified `ubiquitous-language` before the pre-edit plan and continued by that owner during editing. Read-only sharing, isolated editable worktree/clone, pane non-isolation, exact editor scope/return evidence, invoking-agent plan/integration/acceptance authority, exact reviewed-head integration, and equivalent in-process fallback are explicit.
- Three reviews, rollback, and versioning: PASS. Contract consistency, cross-spec integrity, and mechanical quality remain separate and sequential; exact-path rollback covers tracked/new artifacts in both modes; applicable `SPEC-OF-SPECS`, versions, dated changelogs, and README suite metadata remain required.
- Baseline-aware union audit: PASS. Baseline and result each contain 33 skills with 0 schema/description findings and no finding delta; target description is 413 characters, contains `Use when`, and retains all union fields/tool grants unchanged.
- Links/support/provenance/visibility: PASS. Every relative link and anchor resolves; target support has no nested script/file dependency; Git history confirms local introduction/completion/promotion; no notice entry is warranted; Pi remains the symlink `../../shared/skills/update-specs`.
- Repository verification: `bash tests/run.sh` PASS (2 shell files, 12 tests); focused `git diff --check` PASS; exact baseline-aware scope PASS with only the proposal and two target files changed.
- Residual risks: three-dot merge-base scope is deliberately rejected and must be converted to explicit endpoints; repositories with ambiguous glossary authority may require the clarification gate inherited from `ubiquitous-language`; existing tool grants are unchanged because frontmatter redesign is out of scope.

The worker result is `ready-to-integrate`; this record does not claim coordinator integration, central verification, VG-001, or any other migration item.

## Explicit exclusions

- No edit to `.skill-migration/shared-skill-yagni/MIGRATION.md`, `pi/settings.json`, any file in `specs/`, `THIRD_PARTY_NOTICES.md`, AGENTS.md, README outside the target support file, tests, scripts, installer/deployment files, agent configs, or Pi visibility symlinks.
- No edit to `write-a-skill`, `ubiquitous-language`, `audit-shared-skills`, another shared skill, another migration proposal, or another support file.
- No new executable, wrapper, script, command alias, skill, spec, glossary, plan artifact, reviewer role, or transport integration.
- No frontmatter schema, tool-grant, harness portability, explicit-invocation, discovery, deployment, or visibility redesign.
- No fixed line-count target, per-item approval wait, broad catalog cleanup, central integration, central verification, VG-001 claim, or claim about SK-011 or any other item.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization effect: the standing directive removes the per-item approval wait but authorizes only the exact three paths and changes enumerated in revision 1.
- Scope check: `PASS` — MAP, WF-007, the complete WF-005 target record, WF-008, WF-006, current spec/glossary authority, verified `write-a-skill`, verified `ubiquitous-language`, complete target/support files, provenance/history, Pi visibility, and installed Git help plus command probes were reviewed in the mandated order. Exact files, behavior ledger, contradiction repairs, ownership, provenance, licensing, and verification are fixed. Production editing may continue without a per-item approval wait.

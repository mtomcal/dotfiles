---
id: SK-002
target: bootstrap-specs
status: ready-to-integrate
revision: 1
blocked-by: [SK-001]
source-verdict: simplify inline
---

# bootstrap-specs: one approval-gated bootstrap workflow

## Why this item is next

SK-001 is verified at baseline `6db8fd6e811af4009ac3b7ce63be43eefe16ddc3`, so the D2 body-authoring dependency is satisfied. WF-007 routes `bootstrap-specs` next as a direct D3 correction and simplification: preserve its interview and generation behavior while resolving approval order, qualifying the brownfield artifact, protecting glossary/rerun ownership, and routing the orphaned examples.

The WF-003 verdict is **simplify inline** with high confidence. This item has no dependency on another active worker target and does not change any owner skill, specification, notice, deployment surface, visibility link, or migration-ledger state.

## Evidence

Authorities were read in ledger order:

- `.wayfinder/shared-skill-yagni-audit/MAP.md` — migration destination, behavior-first scope, and production exclusions.
- WF-007 — final **simplify inline** verdict and D3 requirements: resolve pre/post-generation approval, qualify the brownfield extraction plan, protect glossary/rerun ownership, and conditionally link or retire examples.
- WF-003 `bootstrap-specs` record — the full WF-003 behavior ledger, current disclosure posture, repeated summary findings, unreachable `EXAMPLES.md`, and high-confidence four-section target.
- WF-008 — human-confirmed definitions of Greenfield, Brownfield, Skeleton spec, and Meta-file.
- WF-006 — Bootstrap Specs owns the distinct spec-extraction plan; composition does not transfer artifact ownership; project language remains owned by the applicable glossary workflow; examples should be linked conditionally; contradictions must be repaired before text is moved.
- `specs/ai-agent-config.md` version `2.3.0` — canonical section order, semantic YAGNI, behavior-preservation, conditional Reference, composition, qualified artifact, and ownership contracts.
- `specs/UBIQUITOUS_LANGUAGE.md` version `0.7.0` — project-authoritative definitions of the body sections and `spec-extraction plan`, including its distinction from a plan workspace or slice graph.
- `specs/SPEC-OF-SPECS.md` and `specs/README.md` — current suite conventions, reading-order contract, and concrete brownfield extraction context.
- Current `shared/skills/write-a-skill/SKILL.md` — verified D2 owner for one routed Workflow, conditional support, checkable completion, and semantic pruning.
- Current `shared/skills/bootstrap-specs/SKILL.md` — 86-line body with seven noncanonical level-two headings, duplicated summaries, one pre-generation confirmation gate, one contradictory post-generation correction step, unsafe broad meta-file rerun wording, and only `REFERENCE.md` linked.
- `shared/skills/bootstrap-specs/REFERENCE.md` — exact generation templates, including the brownfield template whose “Descriptive requirements extraction (no code references)” label conflicts with its own required code mapping and fails to qualify the artifact from implementation planning.
- `shared/skills/bootstrap-specs/EXAMPLES.md` — three useful worked examples, currently unreachable; its brownfield tree uses stale `PARAMETERS.md` casing, omits the progress tracker, and none of its generated-output transitions shows the final pre-write approval gate.
- Current `shared/skills/ubiquitous-language/SKILL.md`, `shared/skills/create-plan/SKILL.md`, and `shared/skills/grill-me/SKILL.md` — neighboring process owners checked to avoid transferring glossary, plan-workspace, or durable interview ownership.
- `THIRD_PARTY_NOTICES.md` — no Bootstrap Specs entry or third-party attribution; repository history shows local introduction at `e66ec246c0d365735364c40c78e7526094c28b25`, a local interview-flow change at `5d1b1f2c4be1f5de4c0182ea86f407fe38d7ddb6`, and a frontmatter-only catalog change at `353218e620f7261e0eedde9c62b8f9814c141830`.
- Executable/support evidence — the target directory contains only `SKILL.md`, `REFERENCE.md`, and `EXAMPLES.md`; no script or command syntax is shipped. The existing Pi visibility entry is a symlink to the shared skill and is verification-only.

No consequential authority conflict remains. The audit requires one approval before writes, while preserving post-generation reporting and correction ability. The proposed workflow resolves that as: iterate on a complete proposal before generation; obtain one explicit approval covering structure and exact overwrite scope; generate; then report actual outputs. Any later structural request returns to proposal and approval before more writes. The existing glossary remains live authority on reruns, so Bootstrap routes glossary merges/refinement through `ubiquitous-language` rather than replacing it from the seed template.

## Exact files in scope

Production/support files authorized by revision 1:

- `shared/skills/bootstrap-specs/SKILL.md` — preserve frontmatter and replace the body with the canonical routed shape; add the resolved approval, brownfield, rerun, glossary, verification, and conditional Reference contracts.
- `shared/skills/bootstrap-specs/REFERENCE.md` — repair only the brownfield `PLAN.md` template metadata and extraction rule so code locations are allowed as plan evidence while generated specs remain prescriptive and code-reference-free; explicitly distinguish the spec-extraction plan from implementation planning/control-plane artifacts.
- `shared/skills/bootstrap-specs/EXAMPLES.md` — retain as conditionally loaded support and minimally correct it to show the pre-generation approval gate, match the output contract, and qualify the brownfield artifact.

Control artifact created and updated by this item:

- `.skill-migration/shared-skill-yagni/proposals/SK-002-bootstrap-specs.md` — this exact revision, implementation record, and ready-to-integrate state.

No other production or support file is authorized.

## Proposed changes

### Add

1. Add `Language Definitions` with exactly the four WF-008-confirmed terms: Greenfield, Brownfield, Skeleton spec, and Meta-file.
2. Add one routed `Workflow` that starts by inspecting implementation-source evidence and existing `specs/`, proposes Greenfield or Brownfield, and reserves mode choice for human confirmation in interview question 3.
3. Add local completion criteria to mode routing, interview completion, proposal approval, generation, rerun safety, and final validation/reporting.
4. Make the single pre-generation approval cover the complete system list, dependency graph, reading order, selected mode, mode-specific file list, and every proposed existing-file overwrite. Corrections loop on that proposal before any generation write.
5. Qualify `specs/PLAN.md` as the Bootstrap-owned **spec-extraction plan**: it maps implementation evidence and authoring order for prescriptive specifications, and is not a `create-plan` plan workspace, implementation plan, slice graph, or `.plan` control plane.
6. Add a safe rerun path: inventory existing files; never overwrite individual system specs; render proposed meta-file updates for review; list exact overwrites in the approval proposal; preserve the existing glossary as live authority and route approved term merges/refinement through `ubiquitous-language` rather than replacing it from a seed template.
7. Add final output validation and reporting: verify exact file list, links, graph, required headings, mode-specific exclusions, approved-overwrite scope, and hashes or diffs proving individual specs were not overwritten; show the actual generated file list and graph as completion evidence.
8. Add a mandatory template pointer to `REFERENCE.md` for exact generation/validation and a conditional examples pointer to `EXAMPLES.md` only when a concrete worked interview or output would clarify a mode or interface type.
9. In the brownfield Reference template, add explicit artifact and ownership metadata and correct the extraction approach so code paths remain legal in the plan’s code mapping but forbidden in resulting behavior specs.
10. In each worked example, show final structure approval before generated output. Correct the greenfield file tree by removing the unsupported empty `reference/` directory; correct the brownfield tree to `parameters.md` and include `SPEC-OF-SPECS-PLAN.md`; state that its `PLAN.md` is the qualified spec-extraction plan.

### Change or move

1. Preserve the frontmatter byte-for-byte and retain the title.
2. Fold `Quick start`, `Two modes`, `Process`, `Key conventions`, `Re-running`, and `Relationship to other skills` into one ordered Workflow with mode routing first.
3. Keep all eight interview questions in their current order and preserve one-question-at-a-time probing, domain-heuristic system proposals, suspected collision proposals, user-facing-surface detection, dependency proposals, and reading-order derivation.
4. Move mode-specific generation into the approved generation step. Greenfield retains all meta-files, optional design language, `parameters.md`, per-system skeleton specs, and `SPEC-OF-SPECS-PLAN.md`. Brownfield retains the meta-files and progress tracker, omits per-system skeletons, and adds the qualified `PLAN.md`.
5. Keep no-code, prescriptive-language, parameter-WHY, test-id, and language-agnostic representation rules beside generation/validation rather than in a detached conventions summary.
6. Change the current post-generation “Confirm and iterate” step into report-and-validate behavior. Structural corrections remain possible, but they return to the pre-generation proposal gate before additional writes.
7. Keep Bootstrap as owner of the initial glossary seed and spec-extraction plan; retain `ubiquitous-language` as owner of evolved glossary refinement and keep `create-plan` as a downstream implementation workflow with no hard dependency.
8. Retain `EXAMPLES.md` under the WF-006 extended-example route and make its non-authoritative, conditional role explicit.

### Remove

1. Remove the duplicate `Quick start` summary after all four actions are retained in the routed Workflow.
2. Remove the duplicate `Advanced features` pointer after exact template loading is retained once under `Reference`.
3. Remove the contradictory implication that a user can change the structure after files are generated but before “final generation.”
4. Remove the unsafe implication that a rerun may blindly replace every meta-file, especially an evolved ubiquitous language.
5. Remove only stale example output entries that are not part of the production output contract; delete no example scenario.
6. Add no `Activities` section because no independently reusable recipe exists outside the main bootstrap sequence.

## Proposed skill shape

1. `Language Definitions` — present and mandatory; exactly the four human-confirmed operational terms.
2. `Workflow` — present; one mode-routed interview, approval, generation/rerun, validation, and reporting process.
3. `Activities` — omitted; interview and generation operations are required Workflow steps, not independently selected recipes.
4. `Reference` — present; one mandatory exact-template pointer and one conditional worked-example pointer, each stating when and why to load support.

## Behavior-preservation checklist

- [x] Frontmatter triggers cover new projects, onboarding, initialization, and both modes without redesigning the union schema.
- [x] Greenfield remains the no-implementation-source mode and produces `0.1.0` skeleton specs.
- [x] Existing implementation source causes Brownfield to be proposed, never silently selected; question 3 retains human confirmation.
- [x] All eight interview questions remain in order and are asked one at a time with follow-up probing.
- [x] Project purpose/user, stack, mode, systems, overloaded terms, user-facing surfaces, dependencies, and reading order are all retained.
- [x] Domain heuristics still propose missing systems; suspected collisions, graph edges, and reading order are proposed for confirmation rather than demanded from recall.
- [x] “Not sure yet” remains valid for terms and dependencies.
- [x] Complete system list, graph, reading order, output list, and overwrite scope receive explicit pre-generation approval.
- [x] Users may add, remove, or rename systems and adjust dependencies/reading order before approval; later structural corrections return through the same gate.
- [x] Greenfield output retains `SPEC-OF-SPECS.md`, `README.md`, `UBIQUITOUS_LANGUAGE.md`, conditional `DESIGN_LANGUAGE.md`, `parameters.md`, every system skeleton, and `SPEC-OF-SPECS-PLAN.md`.
- [x] Brownfield output retains suite meta-files and `SPEC-OF-SPECS-PLAN.md`, omits individual skeleton specs, and adds the qualified `PLAN.md` spec-extraction plan.
- [x] Brownfield extraction still reads code and extracts requirements, behavior, rules, error cases, parameters, and acceptance/test scenarios into fully authored prescriptive specs.
- [x] Code paths remain allowed as evidence mappings in the spec-extraction plan but code, snippets, file paths, and implementation references remain forbidden in resulting specs.
- [x] Specs remain prescriptive language-agnostic contracts using pseudocode, schema tables, and decision tables.
- [x] Every constant/parameter retains a rationale/WHY and test scenarios retain `TS-{PREFIX}-{NUMBER}`.
- [x] Exact schemas/templates remain in `REFERENCE.md` and are loaded when generation or validation needs them.
- [x] Initial glossary seeding remains Bootstrap behavior; evolved glossary refinement remains with `ubiquitous-language` at the applicable suite location.
- [x] Reruns retain meta-file regeneration while requiring reviewed exact overwrites; authored individual system specs are never overwritten.
- [x] Final completion still shows the generated file list and dependency graph and permits another approved structural iteration.
- [x] `EXAMPLES.md` retains all three worked examples and becomes reachable only under a concrete clarification condition.
- [x] `create-plan` remains a downstream implementation workflow with no hard dependency and receives no spec-extraction-plan ownership.
- [x] No provenance or license obligation is deleted or newly invented.
- [x] No spec, notice, deployment, visibility, unrelated skill, `pi/settings.json`, or `MIGRATION.md` change.

## Dependencies, contradiction repairs, provenance, and risks

- Dependency: SK-001 is verified and its resulting `write-a-skill` contract governs this body. No pending owner change blocks SK-002.
- Approval contradiction repair: one explicit gate occurs after all eight questions and before any write. Generated output is validated and reported afterward; a new structural request loops back to proposal/approval instead of pretending generation was provisional.
- Brownfield repair: `PLAN.md` is always called a spec-extraction plan and receives its own purpose/lifecycle boundary. It may map source evidence, but its resulting specs may not expose implementation references.
- Glossary/rerun repair: Bootstrap owns initial seeding. On rerun, the existing suite glossary is authoritative; approved additions are merged/refined through `ubiquitous-language`, never replaced wholesale from the Bootstrap seed. Other meta-file overwrites must be enumerated and approved; individual system specs remain immutable to this workflow.
- Examples decision: retain and conditionally link. WF-006 explicitly prefers this route, and the three examples disambiguate game/UI, SaaS/API Brownfield, and CLI output without bloating the main path. Because linking makes them reachable, stale output/approval details are repaired in the same scope before the pointer is added.
- Provenance: history and the current repository notice support the WF-003 conclusion that Bootstrap Specs was locally introduced. No external source, revision, or license is evidenced, so `THIRD_PARTY_NOTICES.md` must remain unchanged.
- Risk: “meta-file” includes potentially authored governance and parameter content. Mitigation: render/diff candidates and include each overwrite in the single approval scope rather than inferring blanket permission from file type.
- Risk: composing `ubiquitous-language` currently has its own later migration item. Mitigation: this item relies only on its established refinement ownership and applicable-glossary authority from current specs; it does not copy its current path-selection behavior or edit that skill.
- Risk: the examples could be mistaken for normative templates. Mitigation: label them illustrative; the Workflow and `REFERENCE.md` remain authoritative.
- Risk: support templates contain broader legacy detail outside the audited contradictions. Mitigation: revision 1 changes only brownfield qualification/extraction wording; unrelated template modernization remains excluded to avoid scope growth.

## Verification

1. `git diff --check -- .skill-migration/shared-skill-yagni/proposals/SK-002-bootstrap-specs.md shared/skills/bootstrap-specs/SKILL.md shared/skills/bootstrap-specs/REFERENCE.md shared/skills/bootstrap-specs/EXAMPLES.md` — no whitespace errors.
2. Parse `shared/skills/bootstrap-specs/SKILL.md` level-two headings and assert they are exactly `Language Definitions`, `Workflow`, and `Reference`, in order; assert no `Activities` heading.
3. Parse the frontmatter and compare it byte-for-byte with baseline `6db8fd6e811af4009ac3b7ce63be43eefe16ddc3`; assert `name`, `description`, `metadata.short-description`, and `allowed-tools` remain present, the description contains `Use when`, and it is at most 1024 characters.
4. Check relative Markdown links in all three target Markdown files. Acceptance: every local target exists; `REFERENCE.md` and `EXAMPLES.md` are both reachable from `SKILL.md`; every Reference pointer says when and why to load it.
5. Compare the resulting complete skill and support files against the WF-003 ledger and the checklist above. Acceptance: every listed behavior has a retained location; no main-path requirement exists only in conditional examples.
6. Search the resulting body and brownfield template for `spec-extraction plan`, `plan workspace`, `implementation`, `.plan`, source/code mapping, and no-code output rules. Acceptance: artifact qualification is explicit and code locations are restricted to extraction evidence rather than generated specs.
7. Search the resulting body for all eight numbered questions, pre-generation approval, post-generation report, rerun exact-overwrite approval, individual-spec non-overwrite, initial glossary seed, and `ubiquitous-language` refinement ownership.
8. Audit example file trees and approval transitions. Acceptance: all three examples show final pre-generation confirmation; the unsupported `reference/` tree entries are absent; brownfield uses `parameters.md`, includes `SPEC-OF-SPECS-PLAN.md`, and qualifies `PLAN.md`.
9. Run the `audit-shared-skills` union-frontmatter audit using a deterministic local parser over every `shared/skills/*/SKILL.md`. Acceptance: 33 skills, 0 errors, 0 warnings under the current schema; report but do not fix unrelated findings if evidence differs.
10. `test -L pi/skills/bootstrap-specs && test "$(readlink pi/skills/bootstrap-specs)" = '../../shared/skills/bootstrap-specs'` — existing Pi visibility remains intact.
11. Verify provenance/history with `git log --follow -- shared/skills/bootstrap-specs/SKILL.md`, `rg -n 'bootstrap-specs|Bootstrap Specs|e66ec24' THIRD_PARTY_NOTICES.md`, and repository history. Acceptance: local-introduction evidence remains and notices are unchanged.
12. Inspect `git diff --stat`, `git diff --name-only`, and `git diff --` for the proposal-authorized files. Acceptance: the only changed files are this proposal and the three enumerated target files; no spec, notice, deployment, visibility, unrelated skill, `pi/settings.json`, or `MIGRATION.md` differs from the recorded baseline.

Observable acceptance criteria:

- Canonical body shape is exact and frontmatter is unchanged.
- One unambiguous approval occurs before all generation writes.
- Brownfield `PLAN.md` is a qualified spec-extraction plan, not implementation-control state.
- Reruns preserve individual specs and live glossary authority while still allowing approved meta-file regeneration.
- All WF-003 behavior remains inline or in the mandatory template support; conditional examples are illustrative only.
- The existing union schema passes, links resolve, and actual files match revision 1 scope.

## Implementation record

Focused verification completed: `2026-07-14T16:10:18+00:00`

- Actual production/support diff: exactly the three revision 1 files, with 82 insertions and 60 removals. The proposal is the only additional control artifact.
- Resulting SHA-256:
  - `shared/skills/bootstrap-specs/SKILL.md`: `fabe97f943f6c1da68a615aaa7c4dc4b2af56abf8fc61fb9f58fe4ef723d25cc`
  - `shared/skills/bootstrap-specs/REFERENCE.md`: `4f28622306e14a249b5bb33e72a6e8453dbb141e6daebc8e8c837878f17f4175`
  - `shared/skills/bootstrap-specs/EXAMPLES.md`: `b68b260e88ff44ff12c105b64ae22ef5ff20caececd5912780c8eb2e4c3ee8ba`
- Complete resulting `SKILL.md`, `REFERENCE.md`, and `EXAMPLES.md` reread: PASS.
- Canonical level-two shape (`Language Definitions`, `Workflow`, `Reference`; no `Activities`): PASS.
- Baseline frontmatter byte comparison and description limit/trigger check: PASS (587 characters).
- WF-003 behavior ledger, all eight ordered questions, mode routing, approval loop, output sets, glossary/rerun ownership, and completion evidence: PASS.
- Brownfield template qualification and evidence-versus-output-reference boundary: PASS.
- Example route and corrections: PASS; three explicit pre-generation approvals, no unsupported `reference/`, corrected parameter casing, progress tracker present.
- Active support links: PASS. `REFERENCE.md` and `EXAMPLES.md` resolve; links inside `REFERENCE.md` are literal generated-template content rather than support navigation.
- Existing union-frontmatter audit: 33 skills, 0 errors, 0 warnings.
- Pi visibility and local-introduction/no-notice provenance checks: PASS.
- Focused diff hygiene, authorization scope, and protected-path checks: PASS. `pi/settings.json`, specs, notices, deployment, visibility, unrelated skills, Wayfinder artifacts, and `MIGRATION.md` remain untouched.

Revision 1 now satisfies the proposal acceptance criteria and is `ready-to-integrate`; only the coordinator may advance it to `integrating` or `verified`.

## Explicit exclusions

- No changes to any file outside this proposal and the three target skill files.
- No edits to `MIGRATION.md`, any Wayfinder artifact, any file under `specs/`, `THIRD_PARTY_NOTICES.md`, `AGENTS.md`, README files outside the target skill, tests, installers, or deployment configuration.
- No edits to `pi/settings.json`, `pi/skills/bootstrap-specs`, any visibility symlink, or agent discovery/configuration.
- No edits to `ubiquitous-language`, `create-plan`, `grill-me`, `write-a-skill`, `update-specs`, or another shared skill.
- No frontmatter redesign, tool-grant portability work, new script, new skill, new generated artifact type, or automatic upstream synchronization.
- No broad modernization of `REFERENCE.md` templates beyond the exact brownfield contradiction repair.
- No deletion of `EXAMPLES.md`; no additional example scenarios.
- No claim to SK-003 or any other migration item.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorized scope: this proposal record plus exactly the three production/support files enumerated above
- Scope review: **PASS** — revision 1 was checked against the complete authority order, exact authorized files, every WF-003 behavior, all three required contradiction repairs, the examples route, provenance/history, and focused verification before any production edit.

Revision 1 reached `proposal-ready` before production editing and is now `ready-to-integrate` after focused verification. The standing directive authorized only the exact scope above; no per-item approval wait applied.

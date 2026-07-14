---
id: SK-030
target: create-agents-md
status: verified
revision: 1
blocked-by: [SK-001, SK-018, SK-004, SK-012]
source-verdict: move detail to Reference
baseline: 15a3e6c6c848519cf208374afab62f79aeac1d13
---

# Create AGENTS.md: route generation and update while disclosing only the deep grill briefing

## Why this item is next

The authoring owner and the composed `grill-me`, `herdr`, and union-frontmatter audit owners are verified at the claim baseline. WF-007 places `create-agents-md` in D5 progressive disclosure: retain one routed generation/update workflow and move only the detailed grill briefing behind a conditional pointer. The target has no unresolved correctness or provenance blocker, and its scope is disjoint from other migration items.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes the preserve-before-prune destination, excludes frontmatter redesign and Pi visibility changes, and requires semantic rather than line-count YAGNI.
- WF-007 assigns **move detail to Reference** and requires the hill-climbing meaning, tree-hash limits, human-authored content, and detection script to survive.
- The complete WF-005 target record requires create-versus-update routing first; full-generation detection, template draft, confidence markers, codebase-area confirmation, mandatory deep grilling, merge, and finalization; update hash comparison, structural diff, dependency rescan, human-content preservation, removal approval, new-area confirmation, and focused grilling; parent-owned writes; Herdr user-interaction restrictions; direct fallback; and final artifact counts. It authorizes moving only the long structured grill briefing.
- WF-008 confirms the exact meanings of Codebase map, Hill climbing, Tree hash, Confidence marker, and Codebase area. Hill climbing is avoidable repeated context-loading exploration during task discovery, not locally optimal design; genuinely cross-cutting reading is excluded.
- WF-006 keeps `grill-me` as the interview-process owner and Herdr as terminal transport only. The caller retains the draft, brief, user gates, returned evidence, and acceptance; read-only delegates may share a checkout, editors require isolation, and public or legacy pane identifiers are never durable state.
- `specs/ai-agent-config.md` 2.3.0 and `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 require canonical sections, route-first single Workflow, mandatory load conditions, behavior preservation, semantic YAGNI, parent/durable-writer ownership, process-only composition, Herdr/direct fallback, and resolving Pi-visible shared-skill links.
- Root `AGENTS.md` confirms that `shared/skills/` is the canonical cross-agent leaf and `pi/skills/` is a symlink visibility layer. It also provides the current repository example of tree markers, ownership sections, dependency rules, anti-patterns, coding principles, and final map shape.
- Verified `write-a-skill` requires a pre-edit behavior ledger, one route-first Workflow, local gates and completion, conditional Reference pointers stating when and why to load support, and no fixed size target. Verified `grill-me` requires evidence-first one-question-at-a-time interviewing and confirmation before durable writes. Verified `herdr` restricts terminal control to `HERDR_ENV=1`, keeps IDs live and opaque, and leaves task/state/acceptance with the caller. Verified `audit-shared-skills` owns only YAML-aware union-frontmatter checks.
- The complete current target contains the required behavior but incorrectly defines hill climbing as locally optimal design and places the two route branches in separate level-two sections. Its detailed structured grill briefing partially repeats `PRINCIPLES_CATALOG.md` and is the only extraction candidate.
- `TEMPLATE.md` owns the exact draft skeleton and artifact headings. `PRINCIPLES_CATALOG.md` owns the seven deep-pass categories and probing inventory. `scripts/detect-structure.sh` owns deterministic detection and emits `tree`, `tree_hash`, `ecosystems`, `makefile_targets`, `modules`, `warnings`, `dependency_graph`, and `git_churn`; each module record includes name, path, convention match, confidence, dominant language, README evidence, dependencies, and entry points.
- The detection script is tracked executable mode `100755` (working-tree permissions `0775`); `bash -n` passes; its JSON run against the claim checkout parses successfully and contains string tree, 64-hex tree hash, object ecosystems, array modules, and array warnings. Installed `tree` help confirms `--gitignore`, `--dirsfirst`, `-d`, and ASCII charset support; installed `jq` and SHA-256 tooling support the script. The script's `--help` token is not an implemented option and is not advertised as one; no interface change is authorized.
- All four target files were introduced locally at `0e5d117a5695d2495aca5df6277fa013f3bb3ae9`. The target and principles catalog were later adjusted at `353218e620f7261e0eedde9c62b8f9814c141830`. Repository history and notices identify no imported source for this skill, so repo-local provenance remains accurate and `THIRD_PARTY_NOTICES.md` needs no change.
- `pi/skills/create-agents-md` resolves through `../../shared/skills/create-agents-md` to the canonical target.

No authority conflict, command correction, source/license gap, file-mode correction, or material scope uncertainty remains.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-030-create-agents-md.md` — item-local authorization, behavior ledger, verification evidence, and worker state.
- `shared/skills/create-agents-md/SKILL.md` — canonical definitions, one route-first Workflow, retained executable contracts, and conditional support pointers.
- `shared/skills/create-agents-md/GRILL_BRIEFING.md` — new owner-local support containing only the detailed structured brief used at the mandatory deep-pass step.

These three paths are the complete revision 1 allowed file set. `TEMPLATE.md`, `PRINCIPLES_CATALOG.md`, and `scripts/detect-structure.sh` are mandatory read-only support and are explicitly not edited.

## Proposed changes

### Add

- Add `Language Definitions` with the exact WF-008 meanings of Codebase map, Hill climbing, Tree hash, Confidence marker, and Codebase area. Explicitly preserve that hill climbing concerns avoidable context-loading discovery and excludes necessary cross-cutting reading.
- Add `GRILL_BRIEFING.md` containing the current detailed structured briefing: project/draft context, low-confidence focus, codebase-area rules, dependency rules, anti-patterns, seven principle categories, output schema, and unresolved findings.
- Add `Reference` pointers with mandatory when/why conditions: run `scripts/detect-structure.sh` when scanning creation or update structure; load `TEMPLATE.md` when drafting or structurally updating the artifact; load `PRINCIPLES_CATALOG.md` and `GRILL_BRIEFING.md` when the mandatory deep-pass step is reached because they own the question inventory and returned-evidence schema.
- Add explicit completion criteria to detection, generation, update, deep pass, and finalization without changing their gates.

### Change or move

- Preserve frontmatter byte-for-byte, including creation/update triggers, short description, union fields, and existing grants.
- Replace the incorrect introductory hill-climbing gloss with the confirmed context-loading definition in `Language Definitions`.
- Keep one `Workflow`; route first on whether root `AGENTS.md` exists, then run the shared structural detection and enter either full generation or incremental update as level-three branches.
- In detection, preserve executable script use, missing-`tree` installation guidance, and consumption of the `tree`, `tree_hash`, `ecosystems`, `modules`, and `warnings` fields. Preserve module name/path/convention/confidence/language/README/dependency/entry-point evidence and surface unusual warnings rather than dropping them.
- In full generation, preserve drafting from `TEMPLATE.md`, exact tree comments/hash, one Modules subsection per accepted detected candidate, README-or-low-confidence purpose, detected ownership/dependencies/entry points, convention-backed medium confidence, pending-interview rules, anti-patterns, and coding principles. Preserve section-by-section user confirmation of purpose, ownership, dependencies, and entry points, replacing confidence markers only with confirmed/corrected content.
- In incremental update, preserve stored/current hash comparison and immediate no-op on equality; on change, structurally compare old and new tree blocks, add new areas with low confidence, update moved/renamed paths, require approval before removals, rescan manifests/dependencies, and never overwrite human-authored Rules, Anti-patterns, or Coding Principles. Confirm every genuinely new area before writing.
- Make the grill-me deep pass mandatory after full-generation confirmation and after a structural update for the new/changed areas; an identical-hash no-op exits before the pass. Load the two deep-pass References only when this step is reached.
- Preserve Herdr behavior exactly at the ownership seam: only under `HERDR_ENV=1`; a read-only sibling may grill only when the user can interact with it, otherwise it may critique the brief while the parent conducts the interview; the sibling never edits `AGENTS.md`; the parent checks returned findings against user answers and remains sole writer. Outside Herdr or without interactive sibling access, conduct the complete one-question-at-a-time `grill-me` process directly in the parent, not a reduced review. Never persist pane IDs or selectors.
- Merge confirmed deep-pass findings into the parent-owned draft, replacing remaining pending-interview markers with confirmed content or explicitly unresolved uncertainty rather than inventing certainty.
- Finalize with the current tree hash and report the hash plus counts for codebase areas/modules, dependency rules, anti-patterns, and coding principles.

### Remove

- Remove only the old unconfirmed hill-climbing parenthetical, separate level-two branch placement, repeated route labels, and the detailed structured briefing after that briefing moves to `GRILL_BRIEFING.md`.
- Remove no trigger, mode, detection field, tree marker, tree-hash behavior or limitation, ecosystem/module/warning evidence, draft field, confidence state, confirmation question, hash no-op, structural diff behavior, dependency rescan, human-content protection, removal approval, new-area confirmation, grill requirement, Herdr interaction/ownership restriction, direct fallback, merge check, final write, hash report, or artifact count.
- Add no Activity, alternate template, script behavior, script option, fixed line/word target, external state, durable pane identity, or agent-specific configuration.

## Proposed skill shape

1. `Language Definitions` — present; exactly the five human-confirmed operational terms from WF-008.
2. `Workflow` — present; one creation/update workflow with mode selection first, shared detection, two internal branches, mandatory deep pass when work is needed, and finalization.
3. `Activities` — omitted; detection and grilling are required Workflow steps, not independently selected create-agents-md activities.
4. `Reference` — present; conditional pointers to the unchanged script, template, and principles catalog plus the new detailed grill briefing, each stating when and why it must be loaded.

## Behavior-preservation checklist

- [x] Frontmatter remains byte-identical and retains create, update, codebase-map, hill-climbing, boundaries, dependency, anti-pattern, and coding-principle invocation signals.
- [x] Codebase map, Hill climbing, Tree hash, Confidence marker, and Codebase area use the exact WF-008 meanings, with hill climbing limited to avoidable context-loading discovery and necessary cross-cutting reading excluded.
- [x] Root `AGENTS.md` existence selects creation versus update before other workflow behavior.
- [x] Detection remains mandatory for both non-no-op paths and uses the executable script's tree, hash, ecosystem, module, and warning outputs.
- [x] Every module record retains name, path, convention match, confidence, dominant language, README evidence, dependencies, and entry points; detected module candidates map to codebase-area ownership sections without redefining `codebase-design` Module.
- [x] Missing `tree` retains macOS and Ubuntu/Debian installation guidance and a stop/retry path.
- [x] Full generation loads the template, embeds exact tree/hash markers, drafts all required fields, and retains low/medium confidence semantics.
- [x] Every generated codebase area receives human confirmation of purpose/ownership, dependency false positives or omissions, and entry points before final writing.
- [x] Update reads stored hash, compares current hash, exits without edits on equality, and treats the hash only as a structural-change signal rather than content-accuracy proof.
- [x] Structural change compares old/new tree blocks, handles additions, approved removals, and moves/renames, then rescans manifest dependencies.
- [x] Human-authored Rules, Anti-patterns, and Coding Principles are never overwritten by detection; removals require approval and genuinely new areas require confirmation.
- [x] The `grill-me` deep pass remains mandatory for full generation and for changed/new update scope, while identical-hash no-op exits cleanly.
- [x] The deep pass retains module/codebase-area rules, dependency rules, anti-pattern rationale/right-way capture, all seven principles categories, result schema, and unresolved evidence.
- [x] Only the detailed briefing moves; template, catalog, and script ownership remain unchanged and visible through mandatory when/why pointers.
- [x] Herdr is considered only under `HERDR_ENV=1`; sibling grilling requires user interaction; otherwise the parent interviews and any sibling is read-only critique only.
- [x] The parent owns the draft, validates returned findings, and is the only writer; a sibling never edits `AGENTS.md` and no live/public/legacy pane identifier is persisted.
- [x] Outside Herdr or without sibling user access, direct one-question-at-a-time grilling is the complete fallback rather than a reduced pass.
- [x] Finalization writes the current tree hash and reports it with counts for areas/modules, dependency rules, anti-patterns, and coding principles.
- [x] The detection script remains byte-identical, executable, syntax-valid, and capable of producing valid required JSON fields.
- [x] `TEMPLATE.md` and `PRINCIPLES_CATALOG.md` remain byte-identical; all resulting relative pointers resolve.
- [x] Repo-local provenance, unchanged notices, and resolving Pi visibility remain accurate.
- [x] No behavior is pruned merely to shorten the body and no fixed size target is used.

## Dependencies, provenance, and risks

- SK-001, SK-018, SK-004, and SK-012 are verified. Composition imports process only: `create-agents-md` retains artifact location, draft state, user gates, parent writing, and acceptance.
- `GRILL_BRIEFING.md` is a local extraction of existing repo-local text, not a new imported source. No license or notice change is required.
- `TEMPLATE.md`, `PRINCIPLES_CATALOG.md`, and the detector are separate because each already owns detail-heavy reusable support. Editing them would be a material scope change and requires returning this proposal to drafting.
- Risk: calling every detector `modules` entry a Module would collide with `codebase-design`. Mitigation: preserve the JSON field name while describing accepted AGENTS ownership sections as Codebase areas.
- Risk: tree-hash equality can miss content-only manifest or architecture changes. This limitation is preserved and made explicit because WF-008 defines the hash as structural-only; this migration does not redesign update detection.
- Risk: extraction could make the mandatory deep pass appear optional. Mitigation: keep the pass and load condition inline, and move only the literal briefing/schema.
- Risk: Herdr transport could be mistaken for write authority or mandatory delegation. Mitigation: preserve the interaction gate, direct fallback, read-only sibling, parent validation, sole writing, and no-durable-ID rules inline.
- The script's lack of an advertised `--help` branch is pre-existing and does not impair its documented `[--json] [--deep] [repo-root]` interface. Adding help or changing parser behavior is outside exact scope.

## Verification

1. Reread the complete resulting target and new briefing; map every checklist item above to one resulting location.
2. Compare target frontmatter byte-for-byte with baseline and run a YAML-aware union-schema audit over every discovered shared skill; require target required fields, description length, exact `Use when`, and tool-use review to pass without redesigning grants.
3. Parse level-two headings; expect exactly `Language Definitions`, `Workflow`, and `Reference` in order, with one Workflow and no Activities or extra branch headings.
4. Compare all five definitions to WF-008; require exact semantic/textual identity, one occurrence each, and no locally-optimal-design gloss for hill climbing.
5. Inspect route and behavior coverage: create/update first; detector and required fields; full draft/confidence/confirmation; update hash/no-op/structural diff/dependency rescan/human preservation/removal approval/new confirmation; mandatory scoped deep pass; Herdr interaction/direct fallback/parent ownership/no IDs; final hash and count report.
6. Resolve every Reference pointer from the skill directory. Require explicit when/why language for `scripts/detect-structure.sh`, `TEMPLATE.md`, `PRINCIPLES_CATALOG.md`, and `GRILL_BRIEFING.md`.
7. Compare `TEMPLATE.md`, `PRINCIPLES_CATALOG.md`, and `scripts/detect-structure.sh` byte-for-byte and modes against baseline. Require tracked detector mode `100755` and an executable working-tree file.
8. Run `bash -n shared/skills/create-agents-md/scripts/detect-structure.sh`, execute `shared/skills/create-agents-md/scripts/detect-structure.sh --json .`, parse with `jq`, and assert string tree, 64-hex tree hash, object ecosystems, array modules, array warnings, and all required module fields. Compare used `tree`, `jq`, and SHA-256 syntax with installed help.
9. Run a focused temporary-repository fixture with README, manifest, and source directories; require valid JSON, deterministic repeated tree hash, detected ecosystem, module records, and warnings. Confirm no fixture residue.
10. Run `test -L pi/skills/create-agents-md && test "$(readlink pi/skills/create-agents-md)" = '../../shared/skills/create-agents-md' && test -e pi/skills/create-agents-md/SKILL.md`.
11. Recheck complete target/support history and `THIRD_PARTY_NOTICES.md`; require local introduction at `0e5d117a5695d2495aca5df6277fa013f3bb3ae9`, later target/catalog adjustment at `353218e620f7261e0eedde9c62b8f9814c141830`, no imported-source claim, and no notice diff.
12. Run `git diff --check -- .skill-migration/shared-skill-yagni/proposals/SK-030-create-agents-md.md shared/skills/create-agents-md/SKILL.md shared/skills/create-agents-md/GRILL_BRIEFING.md` and `bash tests/run.sh`.
13. Compare claim-baseline tracked and untracked paths and modes. Acceptance: exactly this proposal, target, and new briefing; no diff in `.skill-migration/shared-skill-yagni/MIGRATION.md`, `pi/settings.json`, `.wayfinder/`, specs/glossaries, notices, AGENTS, template/catalog/script, tests, deployment, visibility links, adjacent skills, or unrelated proposals.

Acceptance requires exact three-file scope, canonical three-section body, exact five definitions, byte-identical frontmatter, complete route-first generation/update behavior, only the detailed briefing extracted, mandatory deep-pass loading, parent-only writes, Herdr/direct restrictions, unchanged executable detector and existing support, clean union fields, resolving Pi visibility, repo-local provenance, clean diff checks, and passing repository tests.

## Implementation and verification record

Worker verification completed at `2026-07-14T19:01:11+00:00`.

- Proposal-before-edit control: revision 1 reached committed `proposal-ready` state at `11b23ece328597fb192d69bc3ef5f64e1cd03ae9` with the exact proposal/target/new-briefing file set before production editing. Complete post-edit review found no material file-set, authority, ownership, behavior, provenance, or removal divergence, so revision 1 now records `ready-to-integrate`.
- Actual production diff: `shared/skills/create-agents-md/SKILL.md` has 56 insertions and 131 removals relative to claim baseline `15a3e6c6c848519cf208374afab62f79aeac1d13`; its resulting SHA-256 is `bf52ba11bc011971107782ac76c24b675302e6518214ea0f4ab191ca31a8ca93`. New `GRILL_BRIEFING.md` has 66 lines and SHA-256 `387391e5d2022013c9ab866a62acf64a99c830e9cb171cd449759153156ce31e`. This proposal is the only additional item-local file.
- Complete-file and behavior-ledger review: PASS. Creation/update routing is first; detector tree/hash/ecosystem/module/warning evidence remains mandatory; full generation retains template drafting, marker/hash placement, confidence states, all artifact fields, and area confirmation; update retains hash/no-op, structural diff, addition/move/removal handling, removal approval, dependency rescan, new-area confirmation, and human-authored Rules/Anti-patterns/Coding Principles preservation.
- Confirmed language and canonical body: PASS. Level-two headings are exactly `Language Definitions`, `Workflow`, and `Reference`; one Workflow contains both internal routes and no Activities. All five WF-008 definitions are textually exact and unique. The old locally-optimal-design gloss is absent; hill climbing now means avoidable context-loading discovery and explicitly excludes necessary cross-cutting reading.
- Deep pass and composition: PASS. The `grill-me` pass is mandatory after full-generation confirmation and after changed updates, scoped to all or affected areas respectively; identical-hash no-op exits first. The main body retains the Herdr environment gate, user-interaction requirement, read-only sibling, pane-output return, no sibling edits, parent verification/sole writing, no durable IDs/selectors, and complete direct in-process fallback.
- Progressive disclosure: PASS. Only the detailed structured briefing moved to `GRILL_BRIEFING.md`. The new file retains codebase-area, dependency, anti-pattern, seven-category principle, output, and unresolved sections. All four links resolve. Reference pointers state when and why to use the unchanged detector, template, principles catalog, and new briefing; the pass itself and all gates remain inline.
- Detection support: PASS. `TEMPLATE.md` SHA-256 `b4f42c0379c588b466eb02dfefa3ab7f490ed8197144ccb098dbdf147ec6527c`, `PRINCIPLES_CATALOG.md` SHA-256 `a1709fcd59627bddfe3b64eb2db716315f61155da82ec8c9691fc2503f9496e4`, and detector SHA-256 `e4f492cd9e4cfc5b8e189016ff6c96be2be3f4ca998e80c3f4ca2cb0e2de167b` are byte-identical to baseline. The detector remains tracked mode `100755`, working-tree mode `0775`, and executable. `bash -n` passed; repository JSON output parsed with required types and all module fields; a temporary TypeScript fixture produced valid deterministic hash output with detected modules and warnings and left no residue. Installed `tree`, `jq`, and SHA-256 help support the used command forms.
- Frontmatter and union audit: PASS. Target frontmatter is byte-identical to baseline. A PyYAML-aware complete-catalog run discovered, parsed, and accounted for all 34 skills with zero required-field/description errors and zero description warnings; target grants are unchanged and support reading/writing/editing plus detector execution and its grep/list/find operations.
- Final report contract: PASS. Creation and changed updates write/refetch the current Tree hash and derive all four counts from the final artifact. No-op updates explicitly report no write, current hash, and the same four existing-artifact counts.
- Provenance and visibility: PASS. Complete ancestry confirms repo-local introduction at `0e5d117a5695d2495aca5df6277fa013f3bb3ae9` and later target/catalog adjustment at `353218e620f7261e0eedde9c62b8f9814c141830`; no imported source or notice entry exists or is needed. `THIRD_PARTY_NOTICES.md` remains unchanged. `pi/skills/create-agents-md` still resolves through `../../shared/skills/create-agents-md` to the canonical target.
- Repository and exact-scope verification: PASS. Focused definition/heading/link/frontmatter assertions, scoped `git diff --check`, unchanged-support comparisons, and protected-path checks passed. `bash tests/run.sh` passed both shell files and all 12 tests. Baseline-aware changed/untracked paths are exactly this proposal, target, and new briefing; no diff exists in `MIGRATION.md`, `.wayfinder`, `pi/settings.json`, specs/glossaries, notices, AGENTS, support files, tests, deployment, visibility links, adjacent skills, or unrelated proposals. No agent/pane was created and no live ID was recorded.
- Residual risks: Tree hash equality intentionally cannot detect content-only architecture or manifest changes, so an incremental no-op is explicitly only a structural result. Detector manifest/dependency inference remains approximate and its pre-existing deep-mode extras remain outside this migration. Unresolved human answers remain marked rather than silently confirmed. These are disclosed behavior limits, not verification failures.

The worker result is `ready-to-integrate`; this record does not claim coordinator integration, coordinator verification, central `verified` state, or catalog-wide VG-001 completion.

Coordinator integration verification completed at `2026-07-14T19:04:41+00:00` against integrated commits `d15d801` and `bd0022d`: the complete target, proposal, new briefing, unchanged template/catalog/detector, and composed owner boundaries were reread; exact definitions, create/update-first routing, detector evidence, full-generation draft/confidence/confirmation, update no-op/structural/removal/dependency/human-content gates, mandatory scoped deep pass, Herdr interaction/direct fallback/parent ownership/no-ID rules, final hash/count report, frontmatter identity, Pi visibility, repo-local provenance, exact three-file scope, links, and modes passed independent checks. The unchanged executable detector passed `bash -n` and produced parseable JSON with all actual module fields; one initial verifier assertion expected `dominant_language` while the unchanged script correctly emits `dominant_lang`, and the corrected exact-interface assertion passed without production change. The YAML-aware audit parsed/accounted for all 34 skills with zero errors and the one deferred SK-027 grant warning, `git diff --check` passed, and `bash tests/run.sh` passed all 12 tests. The protected `pi/settings.json` content and diff hashes remained `7d3f4713d7239e8cda3f75597a55f1767fecdf7964324630e4e74dc686d12e05` and `8298a9063e3ebf2988000d176057a41c31cf20c10bbabe92fb57d47f9f2738d5`. Residual risks remain structural-only tree hashes, approximate dependency inference, and explicit unresolved human answers.

## Explicit exclusions

- No edit to `.skill-migration/shared-skill-yagni/MIGRATION.md`, `.wayfinder/`, `pi/settings.json`, any spec/glossary, `THIRD_PARTY_NOTICES.md`, root `AGENTS.md`, `TEMPLATE.md`, `PRINCIPLES_CATALOG.md`, `scripts/detect-structure.sh`, tests, installer/deployment files, agent configs, Pi visibility symlinks, another skill, another support file, or another proposal.
- No frontmatter/schema/tool-grant redesign, new Activity, template or catalog rewrite, detector option/help/deep-mode redesign, new ecosystem/parser support, content-accuracy hash, automatic human-content deletion, durable external state, agent/pane creation during this migration, persisted live Herdr ID, copied Herdr commands, or fixed line/word target.
- No weakening of create/update routing, detection output, confidence markers, confirmations, no-op, structural diff, dependency rescan, human preservation, removal approval, mandatory deep pass, interaction gate, direct fallback, parent ownership, final hash, or count report.
- No coordinator-only `integrating` or `verified` state and no claim that the coordinator verified this item.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization effect: after the scope check passes, the standing directive authorizes only the exact three paths and changes enumerated in revision 1 without a per-item approval wait.
- Scope check: `PASS — revision 1 reread MAP → WF-007 → complete WF-005 create-agents-md record → WF-008 → WF-006 → current specs/glossary and AGENTS.md → verified write-a-skill, grill-me, herdr, and audit-shared-skills → complete target, TEMPLATE.md, PRINCIPLES_CATALOG.md, and detect-structure.sh → provenance/notices and complete target/support ancestry → executable mode, live JSON output, and installed command help. Exact scope is only this proposal, SKILL.md, and new GRILL_BRIEFING.md; the template, catalog, and detector are mandatory read-only support. Frontmatter, five exact definitions, create/update-first routing, detector tree/hash/ecosystem/module/warning evidence, full-generation draft/confidence/confirmation, update hash/no-op/structural diff/dependency rescan/human preservation/removal approval/new-area confirmation, mandatory scoped grill-me pass, Herdr user-interaction restriction, complete direct fallback, parent-only writing, no durable IDs, and final tree-hash/count report are fixed. Only the detailed grill briefing moves. Provenance, Pi visibility, executable detector mode/behavior, exclusions, and verification are fixed. No substantive behavior is pruned and no fixed size target applies. Production editing may continue autonomously without a per-item approval wait.`

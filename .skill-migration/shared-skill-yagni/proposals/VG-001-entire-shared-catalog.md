---
id: VG-001
target: entire-shared-catalog
status: proposal-ready
revision: 1
blocked-by: [MG-002, SK-001-SK-033, NEW-001]
source-verdict: final catalog verification and reconciliation
baseline: 179156f85b1b3e897d9555e2905a5adeeeac0cfb
---

# Entire shared catalog: verify the completed YAGNI migration

## Why this item is next

MG-001 revision 2, MG-002 revision 1, SK-001 through SK-033, and NEW-001 are centrally `verified`. VG-001 is therefore the sole frontier item and can evaluate the integrated catalog rather than worker-local candidates.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes the destination, original 33-skill baseline, preserve-before-prune rule, and excluded frontmatter/deployment/discovery lanes.
- WF-007 fixes the final recommendation classes, D0–D6 implementation sequence, generic Git-delivery split, and final verification requirement.
- WF-003, WF-004, and WF-005 contain all 33 original behavior-preservation ledgers; WF-008 contains the human-confirmed definitions; WF-006 fixes ownership, composition, contradiction repairs, provenance, and the final eight-part validation route.
- `.skill-migration/shared-skill-yagni/MIGRATION.md` records verified central integration for every blocker and requires the final gate to inspect all 33 original skills plus the authorized Git-delivery addition.
- The 36 completed prerequisite/skill/new-skill proposals record exact scopes, coordinator verification, residual risks, and local command/provenance evidence. The resulting catalog has 34 top-level skills and 86 files.
- `specs/ai-agent-config.md` 2.3.0 and `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 own the durable body, semantic YAGNI, behavior preservation, composition, artifact, provenance, and shared-language contracts. `AGENTS.md` owns repository boundaries and states that Pi-visible entries are symlinks to shared skills.
- Verified `audit-shared-skills` owns YAML-aware union-frontmatter validation only; semantic and behavior checks remain this gate's responsibility.
- Current repository evidence shows 33 Pi visibility symlinks for the original 33 skills. `git-delivery` is the only shared-skill name absent from `pi/skills/`, exactly as NEW-001 authorized and excluded. The migration's standing constraints prohibit changing Pi visibility/deployment/discovery. VG-001 therefore verifies and records that deliberate exclusion rather than silently adding a symlink; direct repository composition remains available through `tmux-agent-orchestration`'s relative owner link.
- The only known catalog warning is SK-027's unchanged unused command grants. Frontmatter redesign and harness-specific portability are separate lanes, so this gate records that baseline-aware warning and does not edit `visual-qa`.

No authority conflict requires a production edit. The apparent Git-delivery visibility tension resolves by the explicit migration-wide no-visibility-change constraint plus NEW-001's exact exclusion: this gate verifies the 33 original entries and records the new skill's intentional non-visibility as residual follow-up, rather than broadening scope.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/VG-001-entire-shared-catalog.md` — final gate authority, matrix, results, exceptions, and coordinator verification record.
- `.skill-migration/shared-skill-yagni/MIGRATION.md` — coordinator-owned transition of VG-001 through `integrating` to `verified` and final frontier summary.

These are the exact two mode-`100644` Markdown files authorized by revision 1. No production skill, support file, spec, notice, AGENTS map, test, deployment/discovery file, settings file, or symlink is authorized to change.

## Proposed changes

### Add

- Add this durable final-gate record with exact catalog counts, commands, evidence, exceptions, and residual risks.
- Add a final verification record after all checks run, including immutable baseline/range, settings hashes, and observed catalog/proposal/visibility state.

### Change or move

- Change only VG-001's central ledger status and current-frontier text after the complete gate passes.
- Reconcile the Git-delivery visibility deferral as an intentional migration exclusion: verify all 33 original Pi links and the deliberate absence of the new link, without changing deployment or discovery.
- Reconcile the SK-027 grant finding as one unchanged deferred warning, not a newly introduced clean-catalog claim or an unauthorized frontmatter repair.

### Remove

- Remove the stale duplicate early-frontier paragraph from `MIGRATION.md` when recording the final state; it is obsolete control-surface text, not migration history.
- Remove no skill behavior, support material, provenance, attribution, spec clause, visibility entry, or production file.

## Proposed skill shape

Not a skill body change.

## Behavior-preservation checklist

- [ ] All 36 prerequisite/skill/new rows before VG-001 are centrally `verified`, every corresponding proposal is `verified`, and blocker/frontier state is consistent.
- [ ] Exactly 34 top-level shared skills exist: all 33 originals plus `git-delivery`; each directory name equals frontmatter `name` and contains `SKILL.md`.
- [ ] Every skill parses under the union schema with non-empty `name`, `description`, `metadata.short-description`, and `allowed-tools`; every description contains concrete `Use when` text and is at most 1024 characters.
- [ ] Every body has `Language Definitions` first and only earned optional `Workflow`, `Activities`, and `Reference` sections in canonical order, with no unapproved level-two section.
- [ ] Each of the 33 original WF-008 definition sets, plus `handoff`'s exact no-terms statement and Git Delivery's proposal-authorized definitions, remains present and owner-local.
- [ ] Every original WF-003/004/005 behavior ledger is covered by its checked verified proposal and integrated coordinator record; no proposal has a pending checklist item or unrecorded residual risk.
- [ ] Composition pointers preserve caller ownership, required local gates, returned evidence, and full in-process fallback; owner links resolve for transport, review, visual, teaching, planning, language, authoring, and Git-delivery routes.
- [ ] Required local Markdown links/fragments resolve. Template/example/generated-output links are separately classified and validated against their generation contract rather than misreported as missing source files.
- [ ] Every changed/retained executable support surface passes syntax or installed-help checks applicable to its language: shell helpers, tmux fenced recipes, Ralph loop, structure detector, Git/gh, Playwright CLI, ffmpeg/ffprobe, and agent CLI surfaces.
- [ ] Support files named by each Reference pointer exist; mandatory load conditions are explicit in each main skill.
- [ ] Known imported sources and licenses are represented in `THIRD_PARTY_NOTICES.md`; locally authored skills are not assigned invented notices; no proposal reports an unresolved provenance conflict.
- [ ] Exactly 33 original Pi skill symlinks resolve to `../../shared/skills/<name>`; no stale or non-symlink Pi skill entry exists; `git-delivery` remains deliberately absent under the migration exclusion and is recorded as residual follow-up.
- [ ] The unchanged SK-027 unused-command-grant warning is reported baseline-aware; no frontmatter redesign or out-of-scope repair is made.
- [ ] Specs 2.3.0/0.7.0, the completed ownership/composition decisions, and the final ledger state are semantically consistent.
- [ ] `git diff --check` and all 12 repository shell tests pass.
- [ ] `pi/settings.json` remains untouched and unstaged with protected content/diff hashes `7d3f4713d7239e8cda3f75597a55f1767fecdf7964324630e4e74dc686d12e05` and `8298a9063e3ebf2988000d176057a41c31cf20c10bbabe92fb57d47f9f2738d5`.
- [ ] Final diff from the claim baseline contains only this proposal and coordinator-owned ledger changes; no production or protected path changes.

## Dependencies, provenance, and risks

- All blockers are verified. The final gate consumes their integrated state and cannot repair a failed item by silently editing it; any material failure returns the owning item to the recorded migration lifecycle.
- Markdown link checking must distinguish source-time links from literal templates, example links, generated artifacts, and virtual `skill:` routes. False positives are classified with evidence rather than waived silently.
- Command validation is version-sensitive. The gate checks installed executable/help surfaces and syntax without creating live PRs, browser sessions, tmux workers, Herdr topology, remote mutations, or generated durable artifacts.
- Catalog-wide semantic preservation is evidenced by all 33 source ledgers plus verified item proposals/coordinator records, not by frontmatter parsing alone.
- Git-delivery's missing Pi symlink is intentional under this migration's exclusion but remains a discoverability limitation for Pi. A later separately authorized visibility/deployment lane may add it.
- The SK-027 grant warning is unchanged and explicitly deferred. This gate does not claim zero semantic warnings.
- Repository-local and imported provenance has already been reviewed per item. The final pass verifies notice consistency and proposal records; it does not invent attribution for locally authored text.

## Verification

1. Parse ledger rows and proposal frontmatter with a YAML-aware script. Expect 35 verified blockers before VG-001 and 36 verified non-VG proposal records; reject pending proposal checkboxes outside explanatory code samples.
2. Parse all `shared/skills/*/SKILL.md` files. Expect 34 unique directory/name matches, valid union frontmatter, concrete trigger descriptions within 1024 characters, and canonical body sections.
3. Compare every original skill with WF-008 and its family ledger through the integrated proposal's completed checklist and coordinator verification record; separately inspect Git Delivery's authorized definitions and workflow.
4. Resolve source-time Markdown paths/fragments across all 86 catalog files. Classify bootstrap templates, generated EM Train links, and virtual `skill:` routes explicitly; validate their generation/route contracts.
5. Inspect every `Reference` pointer for an existing target plus when/why load wording; verify support inventories and no orphaned retired `tdd/refactoring.md` or `create-explainer/EXAMPLES.md`.
6. Run `bash -n` on shell support and extracted shell fences where they are executable recipes. Run structure-detector self-checks and safe Ralph loop setup/sentinel probes in temporary directories. Check installed command help/version for changed command owners without live mutation.
7. Run the complete YAML-aware `audit-shared-skills` workflow. Expect 34 parsed skills, zero errors, and exactly the one known baseline-aware SK-027 semantic warning.
8. Verify provenance history and `THIRD_PARTY_NOTICES.md` entries against all proposal records that name imported/adapted material; confirm no unresolved notice requirement.
9. Compare shared names and `pi/skills`: expect exact resolving symlinks for all 33 original skills, no stale entries, and only authorized `git-delivery` absent.
10. Check spec/body/ownership/composition clauses and final ledger statements for contradiction.
11. Run `git diff --check` and `bash tests/run.sh`; expect all 12 tests to pass.
12. Compare paths/modes from baseline `179156f85b1b3e897d9555e2905a5adeeeac0cfb`, verify protected settings hashes, and inspect status. Expect only this proposal and ledger changes plus the pre-existing unstaged `pi/settings.json` modification.

Acceptance requires all checks above, exact classification of the one visibility exclusion and one frontmatter warning, no unresolved behavior/provenance/composition contradiction, no production edit, and an exact two-file control-artifact scope.

## Explicit exclusions

- No edit to any `shared/skills/` file, `.wayfinder/` file, spec/glossary, `AGENTS.md`, `THIRD_PARTY_NOTICES.md`, test, installer/deployment/discovery source, agent config, or any Pi file/symlink.
- No edit, stage, normalization, restoration, or disclosure of `pi/settings.json`.
- No new `pi/skills/git-delivery` symlink under this migration's explicit visibility exclusion.
- No SK-027 frontmatter repair, union-schema redesign, grant portability redesign, new skill, new support file, generated artifact, or fixed line target.
- No live PR/CI/remote mutation, browser session, tmux/Herdr worker topology, agent launch, destructive cleanup, or persisted live runtime identifier.
- No claim of zero semantic warnings, provider-independent Git delivery, runtime behavior not exercised, human acceptance, or upstream synchronization.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization effect: after the scope check passes, the standing directive authorizes only this proposal and coordinator-owned final ledger changes; all production and visibility surfaces remain read-only.
- Scope check: `PASS — revision 1 read MAP → WF-007 D7 and complete recommendation set → all WF-003/004/005 family ledgers through their verified item records → WF-008 → WF-006 → current specs/AGENTS → verified audit-shared-skills and all 36 completed proposals/coordinator records → complete 34-skill/86-file inventory → provenance notices → support/installed command surfaces in the mandated order. All 36 blockers are centrally verified. The exact scope is this proposal plus coordinator-owned ledger status/frontier cleanup, both mode 100644. The complete final behavior matrix, source/generated-link classification, command/support/provenance/frontmatter/composition/visibility checks, one deferred SK-027 warning, deliberate NEW-001 Pi exclusion, no-production-edit boundary, protected settings hashes, and acceptance criteria are fixed. No authority conflict or material scope gap remains; final verification may proceed under the standing directive.`

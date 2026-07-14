---
id: SK-003
target: gameplay-asset-imagegen
status: ready-to-integrate
blocked-by: [SK-001]
source-verdict: simplify inline
---

# Gameplay Asset Imagegen: colocate generation, transformation, and integration contracts

## Why this item is next

SK-001 is verified and now owns the four-section authoring contract. WF-007 places `gameplay-asset-imagegen` in the correctness-before-movement tranche: its duplicated integration guidance may be simplified only after the nonexistent shared `imagegen` delegation is explicitly redefined. The coordinator claimed SK-003 from baseline `6db8fd6e811af4009ac3b7ce63be43eefe16ddc3`; this target does not overlap the concurrently claimed SK-002 scope.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` and WF-007 — verdict `simplify inline`; retain required behavior and correct the absent generation dependency before restructuring.
- WF-003 `gameplay-asset-imagegen` record — complete behavior ledger, four-section recommendation, locally introduced provenance at commit `337b637`, and evidence that no shared or Pi-visible `imagegen` skill exists.
- WF-008 — human-confirmed definitions for generated source, runtime asset, chroma-key background, matte spill, and gameplay scale.
- WF-006 — `write-a-skill` owns body design; visual work preserves capture/conversion/diff/QA-or-judgment/caller-acceptance stages; required local gates stay with their producing step.
- `specs/UBIQUITOUS_LANGUAGE.md` version `0.7.0` and `specs/ai-agent-config.md` version `2.3.0` — canonical section order, semantic YAGNI, behavior-preservation, composition, and ownership contracts.
- `shared/skills/write-a-skill/SKILL.md` — verified authoring owner requires a behavior-preservation ledger, one routed Workflow, independently reusable Activities, local completion criteria, and exact scope verification.
- Current `shared/skills/gameplay-asset-imagegen/SKILL.md` — one self-contained production file, with checklist/gotcha duplication and a hard dependency on an absent catalog skill.
- Catalog/visibility evidence — `find`/`rg` found no standalone `imagegen` in `shared/skills/` or `pi/skills/`; `pi/skills/gameplay-asset-imagegen` remains a tracked symlink to `../../shared/skills/gameplay-asset-imagegen`.
- Available capability evidence — this Pi worker has no `imagegen` executable or image-generation tool. The host Codex installation has an untracked harness-owned `.system/imagegen` skill whose preferred interface is a built-in `image_gen` tool and whose chroma helper exposes alpha, auto-key, soft-matte, edge, and despill controls. This proves generation capability and naming are harness-specific; it does not authorize a dependency from this shared skill to Codex config.
- Git/provenance evidence — `git log --follow` and the full creation diff show local introduction in commit `337b6379501751998f018b2db723e27139c08abe`; `THIRD_PARTY_NOTICES.md` contains no entry for this locally authored skill and requires no change.
- Direct support evidence — `shared/skills/gameplay-asset-imagegen/` contains only `SKILL.md`; there are no support files, scripts, examples, or assets to relocate or edit.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-003-gameplay-asset-imagegen.md` — item-local authorization, behavior ledger, scope review, and verification record.
- `shared/skills/gameplay-asset-imagegen/SKILL.md` — the only authorized production file; normalize its body and repair generation routing.

No production support file is authorized because none exists. The two paths above are the complete allowed file set for revision 1.

## Proposed changes

### Add

1. Add `Language Definitions` with exactly the five WF-008-confirmed definitions: generated source, runtime asset, chroma-key background, matte spill, and gameplay scale.
2. Add a generation-capability route at the beginning of `Workflow`: use a raster image-generation tool or skill available in the active harness (including `imagegen`/`image_gen` when actually available). If none is available, stop and ask the user to provide generated bitmap source or continue in a capable environment. Never replace requested bitmap generation with procedural, SVG, HTML/CSS, or other code-native placeholders.
3. Add observable completion criteria to each workflow stage: loaded asset contract, generated-source traceability, transformation checks, synchronized consumers, and in-context validation.
4. Add `Activities` containing the existing chroma-key prompt as an independently selectable recipe, including key-color conflict handling and single-asset-versus-sheet guidance.

### Change or move

1. Change the description and opening route from a nonexistent cross-agent `imagegen` owner to an available raster image-generation capability with an explicit unavailable-capability stop. This redefines transport/tool selection only; actual bitmap generation remains mandatory.
2. Consolidate `Quick Workflow`, `Integration Checklist`, and `Common Gotchas` into one routed `Workflow`.
3. Move source/runtime separation and traceability beside generation and output placement.
4. Colocate every transformation with its governing validation/failure rule:
   - crop/slice only under a clear slicing plan and produce named files;
   - chroma-key removal must verify alpha, transparent corners, nonblank subject coverage, key-color fringe, and matte spill;
   - resize must satisfy expected dimensions and collision/placement/UI/animation contracts;
   - transparent padding must survive when placement depends on it;
   - detect shrink/recentering and reuse-scale mismatches before integration.
5. Colocate stable naming, project-local runtime loading, and manifest/loader/docs/test synchronization in one integration step. Tests continue to guard dimensions, paths, source provenance, and manifest completeness.
6. Keep gameplay-background and gameplay-camera readability validation in the final step, then route browser/video evidence to the project visual validation or `visual-qa` when available.
7. Move the concept-art prohibition beside reference-image intake: concept/reference art is a target, not a sprite sheet, unless the project explicitly authorizes cropping it into runtime assets.

### Remove

1. Remove the false claim that an existing shared `imagegen` skill is always available; replace it with the capability route and hard failure above rather than deleting bitmap-generation behavior.
2. Remove the `Quick Workflow`, `Integration Checklist`, and `Common Gotchas` headings after each live rule is relocated once beside its governing step.
3. Remove duplicate statements of source/runtime separation, transformation checks, synchronization, and in-context validation; remove no trigger, transformation, validation, guardrail, output contract, ownership rule, or completion condition.
4. Add no Reference or support file: the compact workflow and reusable prompt remain executable inline.

## Proposed skill shape

1. `Language Definitions` — present and mandatory; the five human-confirmed gameplay-asset terms.
2. `Workflow` — present; one route from project contract and generation capability through source retention, runtime transformation, synchronized integration, and gameplay validation.
3. `Activities` — present; the reusable chroma-key runtime-asset prompt and its key/sheet selection rules.
4. `Reference` — omitted; there is no support file and no detail-heavy branch that earns one.

## Behavior-preservation checklist

- [x] Frontmatter still triggers sprites, tiles, props, pickups, effects, decal sheets, replacement bitmap assets, chroma-key extraction, traceability, synchronization, and gameplay-scale readability.
- [x] Required bitmap generation remains explicit; unavailable capability stops instead of silently substituting a procedural or code-native placeholder.
- [x] Project manifest/loader, docs, tests, and visual references load before production decisions.
- [x] Concept/reference art remains prohibited as runtime crop input unless explicitly authorized.
- [x] Generated sources remain traceable, project-local, and separate from runtime assets.
- [x] Runtime outputs remain project-local and are never loaded from sibling repos, temporary paths, or generator defaults.
- [x] Crop/slice, chroma-key removal, resize, and transparent-padding preservation all remain.
- [x] Stable names remain unless the consuming manifest changes.
- [x] Manifest, loader, docs, and tests remain synchronized; tests cover dimensions, paths, provenance, and completeness.
- [x] Alpha channel, transparent corners, subject coverage, visible fringe, matte spill, dimensions, collision/placement/UI/animation contracts, shrink/recentering, and scale-reuse mismatch checks remain.
- [x] Real-background appearance and held-item/pickup/effect/decal readability remain validated at gameplay scale.
- [x] Browser/video review still routes to project visual validation or `visual-qa` when available, without transferring caller acceptance.
- [x] The chroma-key prompt remains intact as an Activity, with non-conflicting key selection and clear sheet-selection criteria.
- [x] No Reference, support file, script, asset, new skill, or new generation owner is implied.

## Dependencies, contradiction repairs, provenance, and risks

- SK-001 is verified and supplies the body-authoring rules used here.
- The missing-delegation contradiction is repaired by capability detection plus an explicit stop. The shared skill does not depend on Codex's private system skill, Pi config, a PATH executable, an API key, or an invented one-off generator.
- Generation ownership remains with whichever raster generator the active harness actually exposes. This skill owns game-specific prompting, source/runtime transformation, integration, and validation. The caller retains acceptance.
- `visual-qa` remains a conditional downstream QA route; this item neither rewrites that owner nor claims its final migrated interface.
- Local Git evidence identifies the skill as repository-authored at commit `337b6379501751998f018b2db723e27139c08abe`; no imported source, license text, or notice edit is required.
- Risk: capability-neutral wording cannot guarantee that every supported harness has image generation. Mitigation: make absence a visible blocking condition and preserve a user-provided-source continuation path rather than fabricating art.
- Risk: colocation could accidentally weaken checks previously repeated in two sections. Mitigation: compare the final body line by line against this checklist and WF-003.

## Verification

- `git diff --check` — no whitespace errors.
- Parse frontmatter and assert `name`, `description`, `metadata.short-description`, and `allowed-tools`; assert description includes `Use when` and is at most 1024 characters.
- Inspect level-two headings and assert they are exactly `Language Definitions`, `Workflow`, and `Activities`, in that order, with no `Reference`.
- Assert all five WF-008 terms and the unavailable-generation stop are present.
- Search the resulting body for every transformation, validation, synchronization target, concept-art guard, visual-QA route, and chroma prompt contract in the behavior checklist.
- Confirm `shared/skills/gameplay-asset-imagegen/` contains only `SKILL.md`; validate there are no relative links to resolve and no support scripts/assets to check.
- Run the repository's executable union-frontmatter audit over all shared skills, using the current `audit-shared-skills` contract; expect no new finding for this target.
- Verify `pi/skills/gameplay-asset-imagegen` remains a symlink resolving to the canonical shared skill, without editing it.
- `git diff --name-only 6db8fd6e811af4009ac3b7ce63be43eefe16ddc3` and `git status --short` — only the proposal and target skill may differ; `pi/settings.json`, specs, notices, deployment, visibility, other skills, and `MIGRATION.md` remain untouched.
- Reread the complete final skill and compare the actual diff with revision 1 before marking `ready-to-integrate`.

Acceptance requires every checklist item to pass, exact scope equality, valid union frontmatter, canonical body shape, and no unresolved authority conflict.

## Implementation record

Focused verification completed: `2026-07-14T16:06:04+00:00`

- Actual production diff: `shared/skills/gameplay-asset-imagegen/SKILL.md` only, with 61 insertions and 38 removals; the proposal is the only additional item-local file.
- Resulting skill SHA-256: `c61ffa3a02e6ed0becc537926e96156bacf983bdc08de5e3f07aff7afec4fa70`.
- Complete final-file reread and revision 1 diff comparison: PASS.
- Existing union-frontmatter audit: 33 skills, 0 errors, 0 warnings; target description is 348 characters and includes `Use when`.
- Canonical level-two shape (`Language Definitions`, `Workflow`, `Activities`, with no `Reference`): PASS.
- Five WF-008 terms, exact retained chroma-key prompt, capability-unavailable stop, all transformation/validation markers, concept-art guard, synchronized consumers, and `visual-qa` route: PASS.
- Support-file absence and relative-link check: PASS; the skill directory contains only `SKILL.md` and the body has no Markdown links.
- Pi visibility remains the tracked `../../shared/skills/gameplay-asset-imagegen` symlink and resolves to this canonical directory: PASS.
- Local creation provenance and unchanged central notice scope: PASS.
- `git diff --check`: PASS.
- `bash tests/run.sh`: PASS (2 shell test files; 12 tests).
- Exact changed-path scope from baseline, combining tracked and untracked files: PASS; only this proposal and the target skill differ.
- Forbidden-scope diff for `pi/settings.json`, specs, notices, AGENTS.md, deployment, visibility, other skills, and `MIGRATION.md`: empty.
- Residual risk: raster generation capability and naming still vary by harness. The implemented stop makes that limitation explicit and requires a real generated source before integration; it does not add a portable generator.

## Explicit exclusions

- No edit to `.skill-migration/shared-skill-yagni/MIGRATION.md` or any other migration proposal.
- No edit to `pi/settings.json`, any spec, `THIRD_PARTY_NOTICES.md`, AGENTS.md, installer/deployment file, visibility symlink, or unrelated skill.
- No new shared `imagegen` skill, Codex/Pi configuration, command wrapper, API integration, dependency, helper script, Reference, generated bitmap, manifest, loader, game docs, or game tests.
- No redesign of cross-agent frontmatter or harness-specific grants.
- No change to `visual-qa`, image diffing, image judgment, Playwright, or video conversion ownership.
- No claim on any migration item other than SK-003.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization effect: the standing directive removes the per-item approval wait but authorizes only the two exact paths and changes enumerated in revision 1.
- Scope check: `PASS` — ledger-order authorities, exact two-file scope, complete behavior ledger, missing-delegation repair, local provenance, support-file absence, and verification plan were reviewed against revision 1; production editing may proceed without a per-item approval wait.

---
id: SK-026
target: video-to-contact-sheet
status: verified
revision: 1
blocked-by: [SK-001]
source-verdict: simplify inline
baseline: 0fe451fc40e94420d9f2aa17c684043479866051
---

# Video To Contact Sheet: preserve conversion recipes and make evidence handoff explicit

## Why this item is next

SK-001 is verified and owns the canonical shared-skill body contract. WF-007 places `video-to-contact-sheet` in D4 direct normalization with a **simplify inline** verdict: keep selection in one Workflow, retain the four reusable ffmpeg recipes as Activities, and add a compact path/purpose handoff to `visual-qa` or the caller. No unfinished owner blocks the target, and the claim baseline changes only coordinator-owned migration state outside this item's authorized scope.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes the preserve-before-prune destination and excludes frontmatter redesign, deployment, and Pi visibility changes.
- WF-007 assigns `video-to-contact-sheet` the **simplify inline** verdict and requires source evidence plus returned limitations to `visual-qa`.
- The complete WF-005 target record requires source/bundle discovery, nearby structured-evidence inspection, duration/size/stream/audio probing, overview-first selection, trim when startup obscures action, higher-frequency or crop escalation for brief/small behavior, four independently reusable recipes, raw-source preservation, meaningful-behavior review, fighter-scale escalation, missing-audio disclosure, machine/visual mismatch reporting, and a compact handoff naming every output path and purpose.
- WF-008 confirms the exact meanings of Source evidence, Contact sheet, Overview contact sheet, and Focused evidence.
- WF-006 keeps recording conversion and ffmpeg/ffprobe activities in this owner. Capture remains with the browser/tool owner; consumers retain the source path, intended moment, audio expectation, and returned artifact paths/limitations. Visual work remains a pipeline ending in caller/human acceptance, which this conversion skill must not claim.
- `specs/ai-agent-config.md` 2.3.0 and `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 require canonical section order, semantic YAGNI, behavior preservation, local guards/output/completion rules, caller-owned acceptance, existing union frontmatter, provenance review, and Pi visibility. `specs/README.md` and `specs/SPEC-OF-SPECS.md` establish their authority and reading conventions.
- Verified `shared/skills/write-a-skill/SKILL.md` requires a complete behavior-preservation ledger, one routed Workflow, independently reusable Activities, local failures and completion criteria, semantic YAGNI without a line target, and provenance review. Verified `shared/skills/audit-shared-skills/SKILL.md` owns only YAML-aware validation of the existing union-frontmatter schema.
- The complete current target contains the required selection path and recipes but uses noncanonical `Inputs` and `Review Rules` headings, lacks confirmed definitions, and underspecifies handoff fields. The complete `visual-qa` consumer already routes recordings here, gathers structured runtime context, requires motion escalation and machine/visual mismatch reporting, and reports artifact limitations; it needs no edit.
- Complete target history shows the conversion behavior was authored locally in `playwright-visual-qa` at commit `2c5a46cd810c58345e0218d9550a9c1fbda5a5b8`, split into this target at `26119dbf3ed18cd7c6b05ae20acfb2b6f9f0d677`, and had its overview resolution raised at `4d8767df5261ce148804a74a722365586ff17ff8`. `THIRD_PARTY_NOTICES.md` has no target entry and history gives no evidence of imported target material, so no notice change is required.
- Installed Ubuntu `ffmpeg`/`ffprobe` 6.1.1-3ubuntu5 help confirms `-y`, `-ss`, `-t`, `-i`, `-c`, `-frames`, `-vf`, `-show_entries`, and `-show_streams`, plus the `fps`, `scale`, `tile`, and `crop` filter forms used here. Installed package metadata identifies the upstream source as `https://ffmpeg.org`; no tool material is copied into the repository.
- `pi/skills/video-to-contact-sheet` resolves through `../../shared/skills/video-to-contact-sheet` to the canonical target.

No authority conflict, consumer contradiction, support-file need, provenance gap, or material file-set uncertainty remains.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-026-video-to-contact-sheet.md` — item-local authorization, behavior ledger, implementation evidence, and worker state.
- `shared/skills/video-to-contact-sheet/SKILL.md` — canonical body normalization, retained recipes with local guards, and compact evidence handoff.

These two paths are the complete revision 1 allowed file set. `shared/skills/visual-qa/SKILL.md` is a read-only consumer for this item.

## Proposed changes

### Add

- Add `Language Definitions` with the exact WF-008 meanings of Source evidence, Contact sheet, Overview contact sheet, and Focused evidence.
- Add observable completion/failure gates to source discovery, probing, transformation selection, artifact review, each recipe, and handoff.
- Add the compact return contract: report the raw source and every generated artifact path, each path's purpose, and its limitations; include missing-audio and structured-evidence/visible-result mismatch limitations; return to `visual-qa` or the caller without claiming final acceptance.

### Change or move

- Preserve frontmatter byte-for-byte, including all recording triggers, current union-schema fields, and ffmpeg/ffprobe/evidence-inspection tool grants.
- Move the three current input forms into Workflow routing: direct path, newest runner artifact bundle, or browser/Playwright recording. Preserve newest-bundle preference and inspection of nearby JSON, NDJSON, and console logs before transformation.
- Fold all ordered behavior into one Workflow: discover and preserve source evidence; probe duration, file size, streams/dimensions/codecs, and audio; create an overview first; select trim, higher-frequency sampling, or crop from visible evidence; verify meaningful behavior and preserve machine/visual mismatch; hand off paths/purposes/limitations.
- Move the four current recipe families into `Activities`: overview contact sheet; trimmed clip plus rebuilt sheet; high-frequency sheet; cropped sheet. Retain the current high-resolution overview and focused settings as defaults/examples while making overview sampling cover the probed timeline and keeping parameter/output guards beside each recipe.
- Keep raw inputs unchanged. Generated outputs use a separate output directory, commands must succeed, outputs must be non-empty, and the reviewer must inspect them rather than treating existence as proof.
- Preserve trim/rebuild behavior for black, blank, setup-only, or startup-obscured frames. Preserve higher-frequency and higher-resolution crop escalation for brief, small, attachment, occlusion, directional-read, fighter-scale, motion, and readability questions.

### Remove

- Remove only the redundant unheaded invocation sentence and noncanonical `Inputs` and `Review Rules` level-two headings after all unique behavior is colocated in `Language Definitions`, one `Workflow`, and four `Activities`.
- Remove no trigger, source form, discovery rule, structured-evidence check, probe field, audio limitation, recipe family, parameter-adjustment guard, raw-source rule, meaningful-behavior gate, trim/rebuild branch, focused escalation, mismatch report, output path, caller ownership, or completion condition.
- Add no Reference, support file, helper script, capture behavior, image comparison, PASS/FAIL verdict, or universal report schema.

## Proposed skill shape

1. `Language Definitions` — present; exactly the four WF-008-confirmed evidence terms.
2. `Workflow` — present; one overview-first conversion and handoff process with input/evidence routing first and transformation selection based on visible behavior.
3. `Activities` — present; exactly four independently selectable ffmpeg recipe families, each with its own parameter, source-preservation, output, failure, and inspection guards.
4. `Reference` — omitted; the compact commands are legitimate inline Activities and no support file is needed.

## Behavior-preservation checklist

- [x] Frontmatter remains byte-identical and retains direct video, artifact bundle, browser demo, gameplay, Playwright WebM, screen-recording, and local-app triggers plus existing tool grants.
- [x] Source evidence, Contact sheet, Overview contact sheet, and Focused evidence retain their exact confirmed definitions without competing meanings.
- [x] Routing accepts a direct video path, newest runner artifact directory, or browser-generated recording and resolves one readable source before conversion.
- [x] Raw recording plus nearby structured evidence remain unchanged; JSON, NDJSON, console logs, and other nearby evidence are inspected before trimming or selecting the interesting window.
- [x] Probe records duration, file size, stream inventory, video dimensions/codecs, and audio presence; probe failure blocks conversion rather than producing an unsupported report.
- [x] Missing audio is disclosed as an artifact limitation and is not called a product bug unless independent capture evidence establishes expected audio.
- [x] An overview contact sheet is produced first and samples the full probed timeline at high readable resolution.
- [x] Black, blank, setup-only, or startup-obscured overview evidence routes to a trimmed clip and rebuilt trimmed sheet; trim timing comes from observed frames.
- [x] Brief/transient behavior routes to a higher-frequency sheet with start/window/rate chosen from overview evidence.
- [x] Small, attachment, occlusion, directional-read, fighter-scale, motion, or readability behavior routes to a higher-resolution crop whose bounds come from probed dimensions and visible evidence.
- [x] Exactly four reusable recipe families remain: overview; trimmed clip/sheet; high-frequency sheet; cropped sheet.
- [x] Every Activity keeps the source path distinct from outputs, creates a separate output directory, uses installed-valid ffmpeg/ffprobe syntax, fails on command or empty output, and requires visual inspection.
- [x] Artifact existence never substitutes for meaningful behavior; blank or misleading outputs loop back to trim, frequency, or crop selection.
- [x] Raw video remains source evidence, while a trimmed clip may be identified as the more truthful review surface without replacing the raw path.
- [x] Structured machine evidence and sampled visuals are both retained when they disagree; neither silently overrides the other.
- [x] Handoff reports the raw source and every generated artifact path with purpose and limitations, including sampling/crop/trim and missing-audio limitations plus any machine/visual mismatch.
- [x] Artifacts return to `visual-qa` or the active caller for judgment; conversion does not claim specialist or final human acceptance.
- [x] No capture, neutral-diff, criteria judgment, browser automation, visual-qa workflow, provenance, deployment, or visibility ownership moves into this skill.

## Dependencies, provenance, and risks

- SK-001 is verified at the claim baseline and supplies the final authoring contract. The `visual-qa` consumer already has compatible routing and limitation/mismatch semantics, so it remains unchanged.
- The target is repository-local based on complete history and absence from `THIRD_PARTY_NOTICES.md`. Runtime use of installed FFmpeg does not import FFmpeg documentation or source into this skill; no notice edit is authorized.
- Stream-copy trimming can begin on a nearby keyframe rather than the exact requested instant and a copied stream must remain in a compatible container. The local trim guard will preserve the source extension, require inspection of the actual first meaningful frame, and direct the operator to adjust or use an explicitly chosen compatible/re-encoded output when exact cutting is required.
- A fixed `fps=1/2,tile=3x3` only covers roughly the first 18 seconds of a long recording, which conflicts with the confirmed full-timeline overview meaning. The overview Activity will derive its sampling rate from the probed duration for at most nine chronological samples while retaining `scale=640:-1,tile=3x3`; focused Activities retain their current 12 FPS/6x4 defaults.
- Crop coordinates can exceed small source dimensions. The crop Activity will require `x + width <= video width` and `y + height <= video height` from probe evidence before execution.
- The result may not be shorter because exact definitions, local guards, and output contracts make existing behavior executable. Semantic YAGNI, not line count, governs.

## Verification

1. Reread the complete resulting target and map every checked ledger item above to one location.
2. Parse the opening YAML with a YAML-aware parser and compare it byte-for-byte with baseline `0fe451f:shared/skills/video-to-contact-sheet/SKILL.md`; validate the existing union schema and exact `Use when` trigger.
3. Parse level-two headings; expect exactly `Language Definitions`, `Workflow`, and `Activities`, in that order, with no `Inputs`, `Review Rules`, or `Reference`.
4. Compare all four definitions to WF-008; expect exact semantic identity and no duplicate definition.
5. Inspect Workflow for route-first source/bundle discovery, nearby structured evidence, raw preservation, complete probe fields/audio limitation, overview-first selection, all trim/high-frequency/crop branches, meaningful-behavior/readability escalation, mismatch preservation, and compact per-path purpose/limitation handoff to `visual-qa` or caller.
6. Inspect Activities; expect exactly four recipe families with local input/output, parameter, command-failure, non-empty-output, and visual-inspection guards. Confirm overview uses full-timeline duration-aware sampling, trim preserves a compatible extension and rebuilds a sheet, focused sampling uses the selected window, and crop bounds are verified.
7. Generate temporary synthetic recordings with installed `ffmpeg` 6.1.1-3ubuntu5, including one video-only WebM and one source with audio. Run the four recipes with representative substitutions; require successful commands, non-empty outputs, valid ffprobe results, expected image dimensions/frame counts where applicable, unchanged source hashes, and explicit no-audio detection for the video-only source.
8. Check every fixed option/filter against installed `ffmpeg -h full`, `ffprobe -h full`, and `ffmpeg -h filter={fps,scale,tile,crop}`; require valid syntax and no copied tool documentation in the repository.
9. Run the complete YAML-aware `audit-shared-skills` workflow against baseline and result, account for all skills, require no new finding, and manually confirm target grants remain used. Do not edit unrelated findings.
10. Run `test -L pi/skills/video-to-contact-sheet && test "$(readlink pi/skills/video-to-contact-sheet)" = '../../shared/skills/video-to-contact-sheet' && test -e pi/skills/video-to-contact-sheet/SKILL.md`.
11. Recheck complete history and `THIRD_PARTY_NOTICES.md`; require local target provenance, no imported-source evidence, and no notice diff.
12. Run `git diff --check -- .skill-migration/shared-skill-yagni/proposals/SK-026-video-to-contact-sheet.md shared/skills/video-to-contact-sheet/SKILL.md` and `bash tests/run.sh`.
13. Compare baseline-aware tracked and untracked paths. Acceptance: exactly this proposal and target; no diff in `MIGRATION.md`, `pi/settings.json`, `.wayfinder`, specs/glossary, notices, `visual-qa`, deployment, visibility links, tests, unrelated skills, or unrelated proposals.

Acceptance requires exact two-file scope, canonical three-section body, exact confirmed definitions, byte-identical frontmatter, complete discovery/probe/audio/source-preservation behavior, all four executable locally guarded recipes, overview/trim/frequency/crop selection, meaningful/readable evidence gates, mismatch preservation, per-path purpose/limitation handoff, clean union audit, resolving Pi visibility, local provenance, clean diff checks, and passing repository tests.

## Implementation and verification record

Worker verification completed at `2026-07-14T18:21:55+00:00`.

- Proposal-before-edit control: revision 1 reached committed `proposal-ready` state at `fdb29a0` with the exact proposal/target file set before production editing. Synthetic preflight exposed leading-zero duration syntax and stream-copy keyframe limitations before the edit; both were already captured in the passing scope check, so no material scope, ownership, behavior, removal, provenance, or file-set revision was needed.
- Actual production diff: `shared/skills/video-to-contact-sheet/SKILL.md` has 91 insertions and 42 removals relative to claim baseline `0fe451fc40e94420d9f2aa17c684043479866051`; its resulting SHA-256 is `6f91087947cb9e641b97c6a31a292290d3a2b52724920ea5ed4a3c867c88b897`. This proposal is the only additional item-local file.
- Complete-file and behavior-ledger review: PASS. All triggers, three source forms, newest-bundle routing, nearby JSON/NDJSON/console evidence, intended moment/audio expectation, unchanged raw evidence, duration/file-size/stream/dimension/codec/audio probe, missing-audio limitation, overview-first selection, trim/frequency/crop branches, meaningful/readable behavior, fighter-scale escalation, machine/visual mismatch, and path/purpose/limitation handoff remain inline.
- Canonical body and confirmed language: PASS. Level-two headings are exactly `Language Definitions`, `Workflow`, then `Activities`; no `Reference` is invented. All four WF-008 definitions are exact and unique. One Workflow contains four ordered stages, and Activities contains exactly four recipe families.
- Recipes and local guards: PASS. Installed `ffmpeg`/`ffprobe` 6.1.1-3ubuntu5 help exposes every fixed option and the fps/scale/tile/crop filters. Synthetic audio and video-only WebM sources exercised all four recipe families (five generated outputs because trim also rebuilds a sheet). Outputs were non-empty at expected dimensions, the trim retained video and audio streams, video-only audio detection returned none, and both source hashes remained unchanged. Duration-aware overview sampling replaced the misleading fixed first-18-second coverage; focused defaults retain 12 FPS/6x4; crop bounds, 24-frame capacity, separate outputs, command failures, emptiness, inspection, and escalation are guarded locally.
- Trim limitation: PASS as an explicit artifact limitation. The synthetic stream-copy trim sought to an earlier keyframe and retained an approximately six-second duration rather than an exact 4.5-second cut. The Activity therefore requires inspection of actual first frame/duration and an adjusted seek or explicitly compatible re-encode when exact cutting is required; it cannot report the trim as truthful merely because the file exists.
- Frontmatter and grants: PASS. The opening YAML is byte-identical to baseline. PyYAML parsed the target, the description retains exact `Use when`, and each unchanged grant is concretely used by discovery, structured-evidence inspection, probing, generation, output setup, or size checks.
- Baseline-aware union audit: PASS. PyYAML accounted for all 33 baseline and all 33 result skill frontmatters with zero errors and zero warnings for required fields, description length, and exact `Use when`; manual target tool review found no unused grant.
- Consumer, provenance, and visibility: PASS. `visual-qa` remains byte-identical and already routes recordings here while owning runtime context, limitation reporting, and downstream interpretation. Complete history confirms local authoring at `2c5a46c`, extraction at `26119db`, and resolution update at `4d8767d`; `THIRD_PARTY_NOTICES.md` has no target entry and remains unchanged. Pi visibility still resolves through `../../shared/skills/video-to-contact-sheet`.
- Repository and exact-scope verification: PASS. `bash tests/run.sh` passed both shell files and all 12 tests; scoped `git diff --check` passed. Baseline-aware inspection contains exactly this proposal and target. `MIGRATION.md`, `.wayfinder`, `pi/settings.json`, specs/glossary, notices, `visual-qa`, tests, deployment, visibility links, and unrelated items have no diff, and no live Herdr ID is persisted.
- Residual risks: stream-copy seeks remain keyframe- and container-dependent, so exact trims may require an explicitly chosen re-encode and must report that limitation. A nine-frame overview samples the full timeline sparsely and can miss sub-interval behavior; the workflow therefore reports sampling limitations and escalates to the observed high-frequency window. Crop coordinates and resolution remain source-specific but are bounded by probe dimensions and mandatory visual inspection.

The worker result is `ready-to-integrate`; this record does not claim coordinator integration, coordinator verification, or catalog-wide VG-001 completion.

Coordinator integration verification completed at `2026-07-14T18:25:42+00:00` against integrated commits `20a13c9` and `6664572`: the complete target and proposal were reread; exact definitions, input/evidence routing, probe/audio gates, overview-first selection, all escalation branches, four Activities and local guards, source preservation, meaningful-evidence checks, mismatch handling, path/purpose/limitation handoff, caller acceptance, frontmatter identity, Pi visibility, repo-local provenance, and exact scope passed independent checks. An independent synthetic three-second audio WebM exercised overview, trim/rebuilt sheet, high-frequency, and crop recipes; all outputs were nonempty, the source hash was unchanged, and trim retained audio. The YAML-aware audit accounted for all 33 skills with zero errors and warnings, `git diff --check` passed, and `bash tests/run.sh` passed all 12 tests. The protected `pi/settings.json` content and diff hashes remained `7d3f4713d7239e8cda3f75597a55f1767fecdf7964324630e4e74dc686d12e05` and `8298a9063e3ebf2988000d176057a41c31cf20c10bbabe92fb57d47f9f2738d5`. Residual risks remain keyframe/container-dependent stream-copy trims, sparse overview sampling, and source-specific crop/readability choices, all explicitly surfaced as limitations.

## Explicit exclusions

- No edit to `.skill-migration/shared-skill-yagni/MIGRATION.md`, `.wayfinder/`, `pi/settings.json`, `shared/skills/visual-qa/SKILL.md`, another skill/proposal, specs/glossary, `THIRD_PARTY_NOTICES.md`, AGENTS, tests, scripts, installer/deployment files, agent configs, or Pi visibility symlinks.
- No fixed line/word target, frontmatter/schema/tool-grant redesign, support file, helper script, capture/browser command manual, audio diagnosis, image diff, criteria-based verdict, PASS/FAIL, final human acceptance, broad catalog cleanup, or persistence of live Herdr IDs.
- No coordinator-only `integrating` or `verified` state and no claim that the coordinator verified this item.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization effect: after the scope check passes, the standing directive authorizes only the exact two paths and changes enumerated in revision 1 without a per-item approval wait.
- Scope check: `PASS — revision 1 reread MAP → WF-007 → complete WF-005 target record → WF-008 → WF-006 → current specs/glossary → verified write-a-skill and audit-shared-skills → complete target and visual-qa consumer → provenance/notices/complete target history → installed ffmpeg/ffprobe 6.1.1 help, filters, package source metadata, and synthetic recipe preflight in the mandated order. Exact scope is only this proposal and the target. Frontmatter, four exact definitions, source/bundle discovery, nearby structured evidence, duration/size/streams/audio probing, missing-audio limitation, raw-source preservation, overview/trim/high-frequency/crop selection, all four recipe families with local guards, meaningful/readable evidence, escalation, machine/visual mismatch, compact per-path purpose/limitation handoff, consumer ownership, provenance, Pi visibility, exclusions, and verification are fixed. The preflight confirmed duration-aware fps/scale/tile/crop syntax and exposed that decimal offsets require a leading zero and stream-copy trims may seek to an earlier keyframe; both are bounded locally without changing scope. Production editing may continue autonomously without a per-item approval wait.`

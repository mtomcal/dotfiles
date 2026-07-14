---
id: SK-005
target: playwright
status: verified
revision: 1
blocked-by: [SK-001, MG-002]
source-verdict: move detail to Reference
---

# Playwright: keep one browser Activity and disclose specialized command families

## Why this item is next

SK-001 and MG-002 are verified. WF-007 places `playwright` in the correctness-before-movement tranche: stale command syntax must be repaired before the overloaded body can become a minimal browser Activity with tested topic References. The coordinator claimed SK-005 from baseline `ad18f56862ace4681bac3f85e11992a4c67f5523`; its exact file set does not overlap the concurrently claimed SK-004 scope.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` and WF-007 — verdict `move detail to Reference`; retain routing, one minimal browser Activity, recovery, cleanup, and security inline; repair commands and preserve provenance before movement.
- WF-004 `playwright` record — complete behavior ledger; 369-line overloaded body plus nine linked References; stale `network` and `run-code --file`; version-skew risk under `@latest`; recommendation to make installed command help authoritative.
- WF-008 — human-confirmed definitions for browser session, snapshot, element ref, persistent profile, and storage state.
- WF-006 — Playwright owns browser command syntax/capture; callers retain scenario, viewport/state, evidence, cleanup, sensitive-state constraints, and acceptance. Specialized mechanics belong in Playwright-owned References.
- `specs/UBIQUITOUS_LANGUAGE.md` version `0.7.0` and `specs/ai-agent-config.md` version `2.3.0` — canonical body order, semantic YAGNI, behavior-preservation, imported-fork provenance, ownership, and conditional Reference contracts.
- `specs/tool-provisioning.md` version `1.2.1` and `specs/install-orchestrator.md` version `1.3.2` — the `playwright` module installs `@playwright/cli@latest` through npm and therefore makes dynamic command verification necessary.
- Verified `shared/skills/write-a-skill/SKILL.md` — requires a behavior-preservation ledger, earned Activities/References, local guardrails and failures, exact provenance, and command/link verification.
- Current `shared/skills/playwright/SKILL.md` and all nine files under `shared/skills/playwright/references/` — current command families, routing, examples, recovery, cleanup, security, artifacts, and support corpus.
- `THIRD_PARTY_NOTICES.md` — exact Apache-2.0 provenance covers the main skill and all nine References as a local adaptation of `microsoft/playwright-cli/skills/playwright-cli` at `fac6ebbe68167aa95078d5b8196817c533d9dfb7`; local introduction is `236096bd22f2da9b5d999bbb3bb02ed1a615ec3d` and later rename/rerouting is `26119dbf3ed18cd7c6b05ae20acfb2b6f9f0d677`; the exact upstream revision has no `NOTICE` file.
- Installed executable evidence — `/run/user/1000/fnm_multishells/2284799_1784045610857/bin/playwright-cli` resolves to installed `@playwright/cli` `0.1.14`, npm git revision `9b118a1a737662fa118d591b5687340b86005d5c`. Its authoritative help exposes `requests`/`request`, `run-code --filename`, `open --browser|--config|--headed|--persistent|--profile`, `attach --extension`, session cleanup, route, trace, video, storage, snapshot, and interaction commands. `playwright-cli network` returns top-level help rather than network results.
- Exact current-upstream corroboration — `microsoft/playwright-cli` commit `793cfb32572733cbcb401e6f28d05a7a914ce408` (npm `0.1.17`) retains the same main-plus-nine support corpus and independently uses `requests`, `request 5`, and `run-code --filename=script.js`. Installed `0.1.14` help, not latest prose, remains the command authority for this implementation.
- Privileged recovery authority — `npx playwright install-deps --help` from exact npm `playwright` `1.61.1`, Git revision `39e3553a4f283a41134d75d7e404484bd9e6865a`, confirms the command and explicitly says it asks for sudo permissions. This evidence supports retaining the command only behind user approval; it does not authorize dependency installation.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-005-playwright.md` — item-local authorization, behavior ledger, scope review, and verification record.
- `shared/skills/playwright/SKILL.md` — replace the overloaded manual with confirmed language, routing, one minimal browser Activity, inline recovery/cleanup/security, and nine conditional pointers.
- `shared/skills/playwright/references/request-mocking.md` — become the earned request-inspection and mocking topic by adding the installed `requests`/`request` replacement for stale `network` while retaining route behavior.
- `shared/skills/playwright/references/running-code.md` — add the tested file-loading form `run-code --filename=script.js` beside inline code execution.
- `shared/skills/playwright/references/session-management.md` — receive browser selection, configuration, persistent-profile, and extension-attachment details removed from the main manual.
- `shared/skills/playwright/references/video-recording.md` — repair the stale `run-code --file` hero-script invocation to installed `--filename` syntax.

These six paths are the complete allowed file set for revision 1. The other five provenance-covered References remain present and unchanged: `element-attributes.md`, `playwright-tests.md`, `storage-state.md`, `test-generation.md`, and `tracing.md`. No support file is retired or renamed.

## Proposed changes

### Add

1. Add `Language Definitions` containing exactly the five WF-008-confirmed concepts: browser session, snapshot, element ref, persistent profile, and storage state. Clarify that refs are ephemeral and session-specific so a fresh snapshot is required after material page changes.
2. Add routing at the opening of `Activities`:
   - pass/fail visual review routes to `visual-qa`;
   - recording conversion or frame sampling routes to `video-to-contact-sheet` after Playwright capture;
   - existing Playwright test execution/debugging must load `playwright-tests.md`;
   - specialized work must load only its matching topic Reference and check installed `playwright-cli --help <command>` before relying on syntax.
3. Add one independently executable minimal browser Activity: confirm global or local CLI availability; open a URL; use the current snapshot and its refs; interact; re-snapshot to verify; optionally capture a screenshot; and close the browser.
4. Add inline failure recovery beside that Activity: prefer an installed system-browser channel before dependency installation; keep explicit executable-path/container fallback for raw Node scripts; require user approval before any privileged `npx playwright install-deps` path.
5. Add inline output and targeting rules beside the Activity: snapshots are the normal inspection surface; refs come from the current session snapshot; `--raw` is for result-only piping; use installed help instead of a static command catalog.
6. Add inline cleanup/security completion: close every browser session started by the task, stop background debug runs, reserve `kill-all` for stale agent-owned sessions, remove unneeded captures/profiles, keep traces/videos only when they are outputs, never commit storage state, delete sensitive state after use, and use environment variables rather than literals for secrets.
7. Add explicit load-when/load-why wording for all nine Reference pointers.
8. Add request inspection examples using installed `playwright-cli requests` and `playwright-cli request 1` to `request-mocking.md`.
9. Add installed `playwright-cli run-code --filename=script.js` syntax to `running-code.md` and the relocated open/config/browser/profile/attach forms to `session-management.md`.

### Change or move

1. Replace `Quick start`, the exhaustive command tables, three repeated examples, snapshot/targeting prose, session/open parameters, installation prose, and `Specific tasks` with the canonical `Language Definitions`, `Activities`, and `Reference` body.
2. Keep the quick-start sequence once as the minimal Activity. Navigation/input/capture variants no longer have a copied static index; agents discover non-minimal forms from installed per-command help.
3. Keep CLI availability and launch recovery inline. The global `playwright-cli` path remains preferred; `npx --no-install playwright-cli` remains the local fallback; `npm install -g @playwright/cli@latest` remains the installation recovery when neither exists.
4. Move request inspection and route/mocking ownership to `request-mocking.md`, correcting stale `network` to `requests` plus indexed `request` detail before relocation.
5. Move custom code/file execution ownership to `running-code.md`, using installed `--filename` syntax.
6. Move named sessions, parallel isolation, browser/channel selection, config, headed mode, persistent profiles, custom profile paths, extension attachment, close/close-all/kill-all, and delete-data details to `session-management.md`.
7. Keep storage commands/security in `storage-state.md`, generated-code/manual-assertion behavior in `test-generation.md`, trace behavior/overhead/cleanup in `tracing.md`, recording behavior/overhead/cleanup in `video-recording.md`, element inspection in `element-attributes.md`, and test/debug/background cleanup in `playwright-tests.md`. The main body points to each only when its branch is selected.
8. Correct the hero-script instruction in `video-recording.md` from `run-code --file your-script.js` to `run-code --filename=your-script.js`; also correct the adjacent non-behavioral `thier` typo while touching that instruction.

### Remove

1. Remove stale `playwright-cli network`; its corrected replacement lives in `request-mocking.md`.
2. Remove the stale standalone `run-code --file <path>` spelling; file execution uses installed `run-code --filename=<path>` only.
3. Remove duplicated storage, route, custom-code, session, test-generation, trace, video, and attribute command examples from the main body after their existing topic owners and conditional pointers are confirmed.
4. Remove the exhaustive static navigation, keyboard, mouse, save-as, tabs, and command-index examples from the invoked body. Their live syntax remains discoverable from authoritative installed help; the minimal Activity retains the common executable path.
5. Remove repeated form, multi-tab, console/network, and tracing examples. Their behavior remains in the minimal Activity, installed help, or the matching topic Reference rather than as additional Activities.
6. Remove no trigger, route, failure recovery, security rule, cleanup condition, specialized capability, output type, Reference, provenance, or license coverage. Retire no support file.

## Proposed skill shape

1. `Language Definitions` — present and mandatory; the five human-confirmed Playwright state/targeting terms.
2. `Workflow` — omitted; this skill is an Activity catalog with no required end-to-end workflow.
3. `Activities` — present; routing followed by exactly one minimal open → snapshot/ref → interact → verify/capture → close browser Activity, with availability, recovery, cleanup, output, and security rules local to it.
4. `Reference` — present; exactly nine pointers, each stating when and why its retained topic file must be loaded.

## Behavior-preservation checklist

- [x] Frontmatter triggers remain unchanged for explicit Playwright requests, deterministic browser automation, recordings, and existing Playwright test setups; `allowed-tools`/grants are not redesigned.
- [x] `visual-qa` owns pass/fail visual review; `video-to-contact-sheet` owns recording conversion; Playwright remains capture/command owner and the caller retains scenario and acceptance.
- [x] Browser session, snapshot, element ref, persistent profile, and storage state use the exact WF-008 meanings.
- [x] Global CLI, local `npx --no-install` fallback, global npm installation recovery, system-browser preference, raw Node executable-path/container fallback, and privileged dependency-install approval remain.
- [x] One minimal browser Activity can open/navigate, snapshot, target by current ref, interact, verify/capture, and close without loading optional support.
- [x] Snapshots remain the normal inspection surface; refs remain snapshot-derived, ephemeral, and session-specific; CSS/locator or less-common interaction syntax remains reachable through installed help.
- [x] `--raw` result piping and no-output behavior remain inline; snapshots, screenshots, PDFs, storage JSON, traces, WebM, generated TypeScript, raw values, and test results remain produced by the minimal path, installed command surface, or named Reference owner.
- [x] Existing test execution/debugging, background-run requirement, attach behavior, generated TypeScript, manual assertion requirement, rerun, and background cleanup remain in `playwright-tests.md`/`test-generation.md` and are explicitly routed.
- [x] Request inspection uses `requests`/`request`; route mocking, listing, unroute, advanced conditional responses, response modification, delay, and failure simulation remain in `request-mocking.md`.
- [x] Arbitrary code, permissions, media, waits, frames, downloads, clipboard, page info, JavaScript, error handling, and complex workflows remain in `running-code.md`; file execution uses `--filename`.
- [x] Named/default sessions, isolation, environment-selected session, parallel patterns, browser/channel/config/headed selection, extension attach, persistent profiles, cleanup, close-all, kill-all, and delete-data remain in `session-management.md`.
- [x] State save/load, cookies, localStorage, sessionStorage, IndexedDB, authentication reuse, sensitive-file deletion, environment-secret handling, and never-commit security remain in `storage-state.md` plus inline security.
- [x] Trace and video capture, their output/overhead/cleanup rules, hero scripts/overlays, and recording review route remain; video file execution uses `--filename`.
- [x] Element attributes/properties remain inspectable through `eval` in `element-attributes.md`.
- [x] All nine References remain present, linked exactly once from the main Reference section, covered by the existing Microsoft/Apache provenance, and conditionally loaded.
- [x] No Reference, support file, notice, skill, deployment surface, visibility link, spec, or migration item is retired or added.

## Dependencies, contradiction repairs, provenance, and risks

- SK-001 and MG-002 are verified and supply the authoring/provenance gates.
- Correctness precedes movement: installed `0.1.14` help replaces stale `network` with `requests`/`request` and stale `run-code --file` with `run-code --filename`. Exact current upstream revision `793cfb32572733cbcb401e6f28d05a7a914ce408` corroborates both forms but does not override installed help.
- `THIRD_PARTY_NOTICES.md` already preserves Microsoft Corporation attribution, exact source revision `fac6ebbe68167aa95078d5b8196817c533d9dfb7`, local adaptation history, Apache-2.0 text, and the absence of upstream NOTICE content. All nine adapted support files remain, so no provenance or notice edit is authorized.
- Risk: `@latest` can change syntax after this migration. Mitigation: the invoked body makes installed per-command help authoritative and the edited examples are checked against installed `0.1.14` help.
- Risk: removing the exhaustive main catalog could hide a capability. Mitigation: retain one executable common path, route every specialized family to its existing topic owner, retain dynamic command discovery, and check the behavior ledger rather than line count.
- Risk: `npx --no-install playwright-cli` availability depends on the active project. Mitigation: treat it only as a detected fallback and preserve global installation recovery; do not change provisioning.
- Risk: browser launch/live-page behavior is environment- and site-dependent. Mitigation: verify syntax through installed help and use a controlled local page for one open/snapshot/interaction/close smoke test if browser libraries permit; report a blocked smoke test rather than installing privileged dependencies without approval.

## Verification

- `git diff --check` — no whitespace errors.
- Parse frontmatter and assert unchanged `name`, `description`, `metadata.short-description`, and `allowed-tools`; description still includes concrete triggers and remains under 1024 characters.
- Inspect level-two headings and assert exactly `Language Definitions`, `Activities`, and `Reference`, in that order, with no `Workflow` and exactly one Activity subheading.
- Assert all five WF-008 definitions, initial owner routing, CLI/local/install recovery, system-browser/raw-Node/privileged-install recovery, snapshot/ref rules, `--raw`, cleanup, and sensitive-state security remain inline.
- Extract Markdown links from the resulting main body; require exactly the same nine existing files, each resolving under `shared/skills/playwright/references/`, each with explicit load-when/load-why wording.
- Search the complete target corpus for `playwright-cli network` and the boundary-aware regex `run-code --file([ =]|$)`; expect no matches. Search for `playwright-cli requests`, `playwright-cli request 1`, and `run-code --filename`; expect the corrected forms in the authorized References.
- Re-run installed authoritative help/version checks for every added or changed command: `playwright-cli --version`; `playwright-cli --help requests`; `playwright-cli --help request`; `playwright-cli --help run-code`; `playwright-cli --help open`; `playwright-cli --help attach`; `playwright-cli --help snapshot`; `playwright-cli --help click`; `playwright-cli --help screenshot`; `playwright-cli --help close`; `playwright-cli --help list`; `playwright-cli --help close-all`; `playwright-cli --help kill-all`; and `playwright-cli --help delete-data`. Inspect arguments/options, not only exit status.
- Verify the unchanged specialized examples remain within installed top-level command families; use exact upstream `793cfb32572733cbcb401e6f28d05a7a914ce408` only to corroborate package-specific APIs not exposed by command help.
- Run a controlled local open → snapshot → click/ref → snapshot → close smoke test when browser launch succeeds without privileged installation; always close the created session. If environment libraries block it, record the failure and confirm recovery language rather than changing system dependencies.
- Run the repository executable union-frontmatter audit under the existing schema; expect no new target finding.
- Count `shared/skills/playwright/references/*.md`; expect exactly nine. Compare notice wording to the retained main-plus-nine corpus without editing the notice.
- Verify `pi/skills/playwright` remains a symlink resolving to the canonical shared skill without editing it.
- `git diff --name-only ad18f56862ace4681bac3f85e11992a4c67f5523` plus untracked-file inspection — only the six authorized paths may differ. Forbidden-scope diffs for `pi/settings.json`, specs, `THIRD_PARTY_NOTICES.md`, AGENTS.md, deployment, visibility, unrelated skills/proposals, and `MIGRATION.md` must be empty.
- Reread the complete final skill and every changed Reference; compare the actual diff with revision 1 before marking `ready-to-integrate`.

Acceptance requires every preservation item to pass, exact six-file scope equality, canonical body shape, nine resolving conditional pointers, corrected commands matching installed authoritative help, retained Apache provenance, valid union frontmatter, cleanup of any smoke-test session/artifacts, and no unresolved authority conflict.

## Implementation record

Focused verification completed: `2026-07-14T16:25:31+00:00`

Integrated verification completed: `2026-07-14T16:28:32+00:00`

- Actual production diff: five authorized Playwright files with 74 insertions and 338 removals; this proposal is the only additional item-local file. No authorized support file was added, renamed, or retired.
- Complete final-file reread and revision 1 diff comparison: PASS for the main skill and all four changed References.
- Existing union-frontmatter audit: 33 skills, 0 errors, 0 warnings; target frontmatter values are unchanged and the description is 242 characters with `Use when` triggers.
- Canonical body shape: exactly `Language Definitions`, `Activities`, and `Reference`, in order; no `Workflow`; exactly one Activity subheading.
- WF-008 language, owner routing, CLI/local/install recovery, system-browser and raw-Node fallback, privileged-install approval, snapshot/ref targeting, raw output, cleanup, sensitive-state security, and observable completion: PASS inline.
- Reference disclosure: exactly nine unique resolving links with load-when/load-why wording; all nine provenance-covered files remain present and no new support file exists.
- Correctness-before-movement: no `playwright-cli network` or boundary-matched `run-code --file` remains. `requests`, indexed `request`, and `run-code --filename` are present in their earned References.
- Installed command authority: `playwright-cli` `0.1.14`; focused help passed for `requests`, `request`, `run-code`, `open`, `attach`, `snapshot`, `click`, `screenshot`, `close`, `list`, `close-all`, `kill-all`, and `delete-data`, with expected arguments/options inspected. Exact upstream CLI revision `793cfb32572733cbcb401e6f28d05a7a914ce408` corroborated the corrected forms. Exact Playwright `1.61.1` revision `39e3553a4f283a41134d75d7e404484bd9e6865a` confirmed `install-deps` and its sudo warning; no dependency installation ran.
- Browser smoke: controlled local data page and the exact main example both completed open → snapshot → ref click → changed-state snapshot → screenshot → close. Generated artifacts were confined to temporary directories and removed. Final `playwright-cli list` reported no browsers.
- Apache provenance: the existing notice still names the main skill plus all nine References, source revision `fac6ebbe68167aa95078d5b8196817c533d9dfb7`, Microsoft Corporation, Apache-2.0, and no upstream NOTICE; the notice is unchanged.
- Pi visibility remains the tracked `../../shared/skills/playwright` symlink and resolves to the canonical shared skill: PASS.
- `git diff --check`: PASS.
- `bash tests/run.sh`: PASS (2 shell test files; 12 tests).
- Exact changed-path scope from baseline, combining tracked and untracked files: PASS; only the six revision-1 paths differ.
- Forbidden-scope diff for `pi/settings.json`, specs, notices, AGENTS.md, installer/deployment, visibility, unrelated skills/proposals, and `MIGRATION.md`: empty.
- Residual risk: installation tracks `@latest`, so future command drift remains possible. The implemented dynamic-help gate and tested topic ownership make that risk visible but cannot freeze future package behavior.
- Residual risk: live element refs and external-page content are ephemeral. The Activity requires selecting a current interactive ref and re-snapshotting after material state changes rather than treating the example ref as durable identity.

## Explicit exclusions

- No edit to `.skill-migration/shared-skill-yagni/MIGRATION.md` or any other proposal.
- No edit to `pi/settings.json`, any spec, `THIRD_PARTY_NOTICES.md`, AGENTS.md, installer/deployment file, package version, browser dependency, or Pi visibility symlink.
- No frontmatter, `allowed-tools`, grant, explicit-invocation, or harness-portability redesign.
- No new/renamed/retired Reference, helper script, test fixture, recording, trace, screenshot, profile, storage-state file, browser, npm package, or shared skill.
- No change to `visual-qa`, `video-to-contact-sheet`, visual-diff/judgment ownership, or caller acceptance.
- No command-family expansion from current/latest upstream; exact current upstream is corroboration only, not scope for adopting new features.
- No claim on any migration item other than SK-005.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization effect: the standing directive removes the per-item approval wait but authorizes only the six exact paths and changes enumerated in revision 1.
- Scope review timestamp: `2026-07-14T16:23:20+00:00`
- Scope check: `PASS` — ledger-order authorities, exact six-file scope, complete behavior ledger, stale-command repairs before movement, retained main-plus-nine Apache provenance, installed/exact-source command authority, explicit exclusions, and verification criteria were reviewed against revision 1; production editing may proceed without a per-item approval wait.

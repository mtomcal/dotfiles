---
id: SK-017
target: design-md
status: verified
blocked-by: [SK-001]
source-verdict: simplify inline
---

# Design MD: route artifact modes before evidence-grounded production

## Why this item is next

SK-001 is verified and owns the canonical skill-body contract, so SK-017 is unblocked in the D4 direct-normalization sequence. This worker is assigned the item from baseline `70170563090a52f91adc4cc6b11048f75b16b287`; its exact scope is disjoint from the concurrently claimed SK-016 item.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes the destination and excludes production changes outside the assigned skill migration.
- WF-007 assigns `design-md` the **simplify inline** verdict: route create, update, audit, and validate first while keeping the compact artifact schema and gates inline.
- The complete WF-005 target record supplies the behavior ledger: inspect durable visual evidence; extract rather than invent; retain the exact YAML token names and canonical Markdown section order; preserve established naming and design-direction intent on update; audit against rendered evidence; run official lint and version diff commands when applicable; reject generic, copied, contradictory, or ungrounded guidance.
- WF-008 confirms the skill-local definitions of Design contract, Design token, Token reference, and Orphaned token.
- WF-006 keeps artifact schemas, output contracts, checklists, and acceptance gates with their domain producer. No other skill replaces this skill's DESIGN.md contract, and no Reference extraction is warranted.
- `specs/ai-agent-config.md` 2.3.0 requires the canonical skill-body shape, routing first, local gates and completion criteria, and behavior-preservation review. `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 keeps project terms in the project glossary. `specs/DESIGN_LANGUAGE.md` is repository interface vocabulary, not the Google DESIGN.md artifact schema; the two contracts must not be conflated. `specs/SPEC-OF-SPECS.md` confirms that repository design-language preambles are distinct from behavior specs.
- Verified `shared/skills/write-a-skill/SKILL.md` requires one routed Workflow, checkable behavior, semantic YAGNI, and no optional section without earned behavior.
- The complete current `shared/skills/design-md/SKILL.md` is self-contained and has no supporting files. Git history traces it to the repo-local commit `482309f3b15b0127f7eb10a1bb03c21250f7a546`; it is not identified as imported material, and `THIRD_PARTY_NOTICES.md` assigns it no third-party provenance or license obligation.
- Installed `@google/design.md` v0.3.0 help confirms `lint [OPTIONS] <FILE>` and `diff [OPTIONS] <BEFORE> <AFTER>`, including the current two-path diff order. The package's `spec` command currently fails because its published bundle omits `dist/spec.md`; this migration therefore preserves the current artifact token and section contract rather than inventing schema changes from unavailable help.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-017-design-md.md` — item-local authorization, behavior ledger, verification plan, and worker result.
- `shared/skills/design-md/SKILL.md` — add confirmed definitions and normalize existing behavior into one mode-routed Workflow.

There are no target support files. No migration ledger, spec, notice, test, deployment, visibility, settings, unrelated skill, or frontmatter file is authorized.

## Proposed changes

### Add

- Add `Language Definitions` with the four exact WF-008 definitions: Design contract, Design token, Token reference, and Orphaned token.
- Begin one `Workflow` by selecting create, update, audit, or validate mode and requiring the target path plus applicable evidence or before/after paths.
- Make audit-only and validate-only behavior explicit: audit compares the artifact to durable and rendered evidence without silently rewriting it; validate runs the official linter and reports unavailable tooling rather than claiming lint-clean completion.
- Add observable completion evidence for each mode: artifact path and evidence basis, update intent and version diff when applicable, audit findings, and lint outcome.

### Change or move

- Move the existing Quick Start artifact description into the Workflow opening.
- Keep extraction-before-invention immediately after routing and apply it to create, update, and audit modes.
- Colocate the exact YAML token names, token-reference syntax, token form rules, reusable-component focus, and exact eight-section order with create/update artifact production.
- Move existing-update rules beside the update branch: preserve established naming unless misleading, explain design-direction changes, run `npx @google/design.md diff <before> <after>` when comparing versions, and update repository discovery guidance only when agents need it.
- Colocate the audit gate with rendered evidence and the existing quality rejection rules.
- Colocate official `npx @google/design.md lint <file>` validation with all artifact-producing or validating modes when package/network access is available.
- Preserve frontmatter byte-for-byte; invocation triggers and tool grants remain unchanged.

### Remove

- Remove the standalone `Quick Start`, `Token Rules`, `Updating Existing DESIGN.md`, and `Quality Bar` level-two sections only after retaining every unique contract at its governing Workflow step or branch.
- Remove only duplicated summary wording created by routing and colocation.
- Remove no trigger, mode, evidence source, token name, token form, token reference, canonical artifact heading, update rule, audit criterion, lint/diff command, repository-guidance condition, quality rejection, provenance duty, or completion condition.

## Proposed skill shape

1. `Language Definitions` — the four exact confirmed DESIGN.md artifact terms.
2. `Workflow` — present; one create/update/audit/validate router followed by evidence extraction, exact artifact production rules, mode-specific gates, and completion evidence.
3. `Activities` — omitted; lint and diff remain gates inside the routed modes rather than independently selected recipes.
4. `Reference` — omitted; the compact artifact schema and required gates remain inline, and no support file exists or is warranted.

## Behavior-preservation checklist

- [x] Invocation still covers creating, updating, auditing, and validating Google-style `DESIGN.md` files from UI, CSS, assets, screenshots, or explicit design direction.
- [x] All four WF-008 definitions are present without transferring project-domain vocabulary from repository glossaries.
- [x] Create/update/audit/validate routing occurs before inspection or production, with audit-only and validate-only paths not silently becoming edit modes.
- [x] Existing durable context remains inspected first: `AGENTS.md`, README files, specs, visual QA docs, CSS/theme files, components, assets, screenshots, and product references.
- [x] Existing decisions, CSS variables, theme tokens, component classes, rendered screenshots, and repeated patterns remain preferred over invented style.
- [x] YAML front matter retains exact `version`, `name`, optional `description`, `colors`, `typography`, `rounded`, `spacing`, and `components` token names.
- [x] Typography retains exact `fontFamily`, `fontSize`, `fontWeight`, `lineHeight`, and `letterSpacing` fields.
- [x] Colors remain hex sRGB; opacity remains a base token plus prose; dimensions retain units; zero letter spacing remains `0px`, not `"0"`.
- [x] Component token references retain `{colors.primary}` and `{typography.button}` syntax.
- [x] Contrast warnings still require correcting the model rather than masking a warning, including colored text on dark surfaces rather than falsely modeling a filled badge.
- [x] Orphaned tokens remain rejected unless prose explains future use; component tokens remain focused on reusable buttons, panels, cards, nav, progress, forms, status, and major repeated surfaces.
- [x] Markdown rationale retains the exact order `Overview`, `Colors`, `Typography`, `Layout`, `Elevation & Depth`, `Shapes`, `Components`, and `Do's and Don'ts`.
- [x] Prose still explains use, avoidance, and preservation of visual identity.
- [x] Updates preserve established naming unless clearly misleading, explain intent rather than only value changes, and update repository discovery guidance only when needed.
- [x] Version comparison retains the official before/after diff command and does not reverse its argument meaning.
- [x] Audit remains grounded in actual implementation and rendered evidence rather than only schema validity.
- [x] Official lint remains a create/update/audit/validate gate when tooling is available; unavailable tooling is disclosed and never reported as lint-clean.
- [x] Broad generic guidance, one-off trivia, copied CSS dumps, conflicts with rendered UI or project instructions, invented style, and ungrounded tokens remain rejection conditions.
- [x] The resulting design contract remains compact, specific, grounded, and lint-clean when lint can run.
- [x] Frontmatter, provenance status, relative-link absence, and Pi visibility remain unchanged.

## Dependencies, provenance, and risks

- SK-001 is verified at the baseline. No unfinished owner decision blocks this direct normalization.
- Current source, WF-005, WF-008, WF-006, and the specs agree. There is no behavioral contradiction requiring repair before movement.
- The published CLI's broken `spec` command is an external packaging limitation, not authority to alter or weaken the current exact artifact contract. The target will retain its token names and section order without speculative additions.
- The main risk is over-interpreting implicit audit/validate modes. The proposal limits clarification to existing frontmatter promises and WF-005's accepted rendered-evidence/lint behavior; it adds no new schema or remediation workflow.
- The target is repo-local according to Git history and absent from third-party notices. No notice or license edit is authorized.

## Verification

- Reread the complete resulting `SKILL.md` against the complete WF-005 target ledger and exact WF-008 definitions — every checklist item has a retained inline location.
- Inspect level-two headings — exactly `Language Definitions` then `Workflow`; no Activities, Reference, or unapproved section exists.
- Check the literal artifact tokens, typography fields, token-reference examples, and eight canonical headings against the baseline — all remain present exactly and in the same order.
- Run `npx --yes @google/design.md --help`, `lint --help`, and `diff --help` — installed help continues to support the unchanged lint and before/after diff syntax; record the known broken `spec` command without changing scope.
- Run the complete YAML-aware `audit-shared-skills` union-frontmatter audit over every discovered shared skill — all files accounted for, zero errors, zero warnings, and no target regression.
- `test -L pi/skills/design-md && test "$(readlink pi/skills/design-md)" = '../../shared/skills/design-md' && test -f pi/skills/design-md/SKILL.md` — unchanged Pi visibility still resolves.
- Inspect target Git history and `THIRD_PARTY_NOTICES.md` — repo-local provenance remains consistent and no notice change is required.
- `git diff --name-status 70170563090a52f91adc4cc6b11048f75b16b287 --` plus scoped diff inspection — only this proposal and target differ; protected and unrelated paths do not change.
- `git diff --check` — no whitespace errors.
- `bash tests/run.sh` — repository tests pass.
- After commit, `git status --short` — worktree is clean.

## Implementation and verification record

- Worker verification timestamp: `2026-07-14T17:36:03+00:00`.
- Exact scope: PASS. Relative to baseline `70170563090a52f91adc4cc6b11048f75b16b287`, the result contains only this proposal and `shared/skills/design-md/SKILL.md`. The migration ledger, Wayfinder state, specs/glossaries, notices, tests, deployment/discovery/visibility paths, every Pi file including `pi/settings.json`, frontmatter, unrelated skills, and unrelated proposals remain unchanged.
- Complete-file and behavior-ledger review: PASS. Create/update/audit/validate triggers and routing, durable evidence inspection, extraction-before-invention, explicit-direction labeling, exact YAML token names and typography fields, token-reference syntax, color/dimension/contrast/orphan/reusable-component rules, exact eight-section order, rationale, update naming/intent/discovery rules, rendered-evidence audit, lint/diff gates, rejection rules, and per-mode reporting all remain inline.
- Canonical shape: PASS. Level-two headings are exactly `Language Definitions` then `Workflow`; Activities and Reference remain omitted. All four exact WF-008 definitions are present. The target is 64 lines versus 67 at baseline; its 604 words versus 467 reflect only confirmed definitions, first-class mode routing, and checkable local gates, not added artifact-schema commentary or scope.
- Artifact contract: PASS. A literal baseline comparison found all exact top-level token names, typography fields, both token-reference examples, `#`/`0px` forms, lint/diff commands, and all eight canonical Markdown section tokens present in order. Frontmatter is byte-for-byte unchanged.
- Mode and rejection gates: PASS. Audit-only and validate-only modes do not silently edit; lint is not treated as rendered fidelity; unavailable lint cannot yield a lint-clean claim; broad generic guidance, one-off trivia, copied CSS, invented style, ungrounded tokens, and rendered/project conflicts remain rejected.
- Command help: PASS with one disclosed upstream limitation. Installed `@google/design.md` v0.3.0 confirms `lint [OPTIONS] <FILE>` and `diff [OPTIONS] <BEFORE> <AFTER>`. Its published `spec` command exits 1 because `dist/spec.md` is absent, so no speculative schema change was made.
- Union audit: PASS. PyYAML parsed all 33 discovered shared-skill frontmatters and checked required fields, description limits, exact `Use when`, and unchanged least-tool grants: 33 parsed, zero errors, zero warnings.
- Provenance and visibility: PASS. Git history identifies the repo-local source commit `482309f3b15b0127f7eb10a1bb03c21250f7a546`; no `design-md` third-party notice exists or is required by current evidence. The unchanged `pi/skills/design-md` symlink resolves to `../../shared/skills/design-md`.
- Repository checks: PASS. `git diff --check` is clean and `bash tests/run.sh` passes both shell test files and all 12 tests.
- Resulting target SHA-256: `b13d060132e3d63993e68c7810d1007f67401c84dd10004476730c102bd32ccb`.
- Residual risk: the upstream package's broken `spec` command prevents an additional live spec dump, but installed lint/diff help, baseline literal comparison, and the no-invention rule preserve the authorized contract without expanding scope.

## Integrated verification

- Coordinator verification `2026-07-14T17:37:18+00:00`: exact scope, complete skill, routes, definitions, artifact/token/section gates, lint/diff help, tests 12/12, diff, visibility/settings passed. Upstream spec-command defect remains disclosed.

## Explicit exclusions

- No edits to `.skill-migration/shared-skill-yagni/MIGRATION.md`, `.wayfinder/`, specs/glossaries, `THIRD_PARTY_NOTICES.md`, `AGENTS.md`, tests, help/package files, install/deployment files, agent config/discovery, Pi visibility links, `pi/settings.json`, unrelated skills, unrelated proposals, or frontmatter.
- No new supporting file, artifact schema, token category, canonical artifact section, external source claim, command option, remediation workflow, or fixed line-count target.
- No frontmatter/schema/grant redesign and no claim that the repository `DESIGN_LANGUAGE.md` is a Google `DESIGN.md` artifact.
- No coordinator-only ledger update, integration state, deployment/visibility verification beyond read-only checks, or final catalog verification claim.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization revision: standing directive applied to proposal revision 1 and only the exact two-file set above.
- Scope check: `PASS — MAP → WF-007 → complete WF-005 target record → WF-008 → WF-006 → current specs/glossaries → verified write-a-skill and audit-shared-skills → complete target → provenance/notices/history → installed command help were read in order; exact files, complete behavior ledger, mode boundaries, contradiction review, provenance/license status, exclusions, and verification criteria were checked. Production editing may continue autonomously under the standing directive.`

---
id: SK-007
target: create-explainer
status: ready-to-integrate
blocked-by: [SK-001]
source-verdict: simplify inline
---

# create-explainer: one source-grounded producer/reviewer/serve/validate workflow

## Why this item is next

SK-001 is verified, so the confirmed shared-skill body contract and authoring owner are available. SK-007 is claimed on the current frontier. It repairs Create Explainer's contradictions before deduplicating its main path and Reference, and it establishes the corrected explainer contract needed by later `teach` and `em-train` composition work.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes the destination, preserve-before-prune rule, and out-of-scope frontmatter/deployment boundaries.
- WF-007 assigns `create-explainer` the **simplify inline** verdict: one routed producer/reviewer/serve/validate workflow, with source/screenshot locations, tier requirements, and serve/validate order reconciled first.
- The WF-005 Create Explainer record supplies the behavior-preservation ledger and requires persona intake, scope approval, source discovery, tier artifact shapes, mandatory factual review, reviewer-delegation approval, free-port identity checks, responsive checks, temporary screenshots, and conditional support.
- WF-008 confirms `Output tier`, `Condensed`, `Guided`, `Full Lab`, `Source-grounded reviewer pass`, `Claim checklist`, and `Lab template`.
- WF-006 assigns explainer production and factual review to `create-explainer`, keeps caller-specific location/gates with composing skills, assigns browser command syntax to `playwright`, assigns template/examples to their domain owner, and explicitly authorizes retirement of duplicated `create-explainer/EXAMPLES.md`.
- `specs/ai-agent-config.md` 2.3.0 and `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 require the canonical body shape, behavior ledger, conditional pointers, local completion criteria, composition-without-ownership-transfer, editable isolation, and source/revision/license identification. `specs/SPEC-OF-SPECS.md` and `specs/README.md` confirm those specs' authority and reading order.
- Verified `shared/skills/write-a-skill/SKILL.md` owns the four-section shape, progressive disclosure, checkable behavior, and semantic YAGNI test used here.
- Current `SKILL.md`, `REFERENCE.md`, `EXAMPLES.md`, `lab/README.md`, and all 13 linked lab templates were read completely. The current main and Reference disagree over durable source location, browser-artifact location, tier requirements, and validate-before-serve versus serve-before-validate. Tier, reviewer, serving, validation, and lab guidance is duplicated across files.
- Git history identifies the skill and templates as repository-authored material introduced at `e5d8b9bbc391c6481c2f4d46c1c979c0162a7f30` and extended at `091392d777a7f20018c64fc0c648be2547f54679`; no imported upstream source or license obligation was found, and `THIRD_PARTY_NOTICES.md` has no Create Explainer entry.
- Executable evidence: Python 3.12.3 supports `python3 -m http.server <port> --bind <address>`; installed `playwright-cli` exposes `open`, `resize`, `screenshot --filename`, `eval`, and `close`; Node 24.18.0 parses all 13 extracted inline scripts. Runtime inspection also found a valid-but-wrong packet-loss string expression in `lab/network-simulator.html`, which can render a boolean instead of the loss label and therefore needs a focused template repair.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-007-create-explainer.md` — item-local authorization, behavior ledger, verification record, and state.
- `shared/skills/create-explainer/SKILL.md` — replace the duplicated headings with the confirmed definitions and one executable routed workflow plus deduplicated conditional Reference pointers.
- `shared/skills/create-explainer/REFERENCE.md` — retain detail-heavy intake/persona, tier planning, delegation, reviewer checklist, HTML patterns, and browser-validation support under anchors selected by the main workflow; remove duplicate main-path summaries and contradictory ownership/order text.
- `shared/skills/create-explainer/EXAMPLES.md` — delete the audited duplicated examples after confirming all behavior is retained in `SKILL.md`, `REFERENCE.md`, or `lab/README.md`.
- `shared/skills/create-explainer/lab/network-simulator.html` — repair the packet-loss timeline expression so the routed template is executable when packet loss is nonzero.

No other lab template or `lab/README.md` change is authorized. They are verification inputs only.

## Proposed changes

### Add

- Add the exact WF-008 Language Definitions to `SKILL.md`.
- Add an inline output contract distinguishing durable explainer source from transient browser evidence: default source lives in `./explainer/` or a caller/user-selected destination; Condensed writes `index.html`; Guided and Full Lab write `index.html` plus `main.js`; screenshots, snapshots, and incidental validation files live under an OS temporary directory and are not written into the project root or explainer source directory.
- Add one explicit ordered route: intake/persona inference → tier selection and one scope checkpoint → independent source mapping → tier/template drafting → self-check → mandatory source-grounded reviewer pass → correction gate → free-port serve and identity check → browser validation of the served URL → completion report.
- Add a completion report requiring tier/persona assumptions, durable artifact paths, source map/claim-review result and whether a separate reviewer was used, served URL/port, browser checks/evidence location, limitations, and task-owned process cleanup state.
- Add a focused correction to the network simulator's nonzero packet-loss label.

### Change or move

- Make tier routing immediate after intake and reconcile the minimum contracts:
  - **Condensed**: static `index.html`, no lab, with a summary, source-grounded diagrams/examples, and file/ownership map.
  - **Guided**: Condensed content plus exactly one concept-shaped lab and the lab README's minimum active-recall/source-visual/action-before-reveal/feedback requirements; `index.html` plus `main.js`.
  - **Full Lab**: comprehensive 10+ section explainer with multiple concept-shaped labs, the retained architecture/quiz/graph/quick-reference practice set, and cross-language syntax cards when applicable; `index.html` plus `main.js`.
  The detailed structure remains in `REFERENCE.md` and is loaded during planning for the selected tier; `lab/README.md` remains the sole selection matrix/template integration owner.
- Preserve the persona interview. If concept, audience/experience/specialty, and depth are already clear, state assumptions and ask only missing or risky questions; otherwise ask the ordered intake. Always present exactly one scope checkpoint before source/draft work.
- Preserve source-first mapping: independently find entry points, trace relevant cross-boundary flow, read specs/schemas, record every source path and owning symbol/line, and omit unsupported claims rather than invent them.
- Preserve optional Full Lab drafting delegation only for large work, with the producer retaining shell/CSS/navigation, integration, editable-isolation choice, failed-delegation fallback, and final review ownership. Ask before delegating any sub-agent work.
- Make the reviewer contract mandatory and source-grounded. Build a claim checklist covering routes/methods, gate order, fields and optionality, symbols/signatures, constants, file paths, query patterns, diagrams, lab behavior, and answer keys. A delegated reviewer must independently rediscover source rather than trust the draft's file map. If delegation is declined/unavailable, perform the same independent rediscovery locally and explicitly report that there was no separate reviewer. Fix every CRITICAL finding, fix persona-confusing MINOR findings, and run a second pass when any reviewer reports at least three CRITICAL findings.
- Resolve serve/validate order in favor of executable causality: reviewer corrections finish first; then select a free port, start Python's server from the durable explainer directory, and verify page identity with `curl`; only then open that exact served URL for browser validation. All tiers get desktop and 700px responsive/overflow/console checks; interactive tiers additionally exercise controls and expand all hidden states. Close the task-owned browser after validation. Keep the verified explainer server running for the final URL unless the user asks otherwise, and report its PID/port ownership so later cleanup is unambiguous.
- Consolidate the current repeated `REFERENCE.md` and `lab/README.md` links into one `Reference` section. Each pointer states when and why to load its target, and each support concern has one pointer.
- Retain reference-only persona matrices, cross-language mappings, detailed tier structure, large-draft delegation recipe/fallback, reviewer prompt/findings schema, HTML/CSS/JS implementation patterns, node-graph pitfall, and executable Playwright validation recipe.

### Remove

- Remove `Quick start`, repeated output-tier/core-principle summaries, separate reviewer and serving top-level sections, and duplicate inline links from `SKILL.md`; their behavior moves into the one Workflow or the deduplicated Reference pointers.
- Remove from `REFERENCE.md` the duplicate nine-step workflow wrapper, duplicate server/file-convention contract, duplicate lab template catalog, and any statement that validation is optional/recommended or occurs before serving. Retain the detail that changes execution under the conditional anchors.
- Delete `EXAMPLES.md`. Its three tier/scope examples duplicate the retained intake, persona, tier, and scope-template behavior; its reviewer example duplicates the retained claim checklist, finding schema, correction gate, and second-pass rule. It contains no unique trigger, branch, guardrail, output, ownership rule, or completion condition.

## Proposed skill shape

1. `Language Definitions` — present; exact confirmed terms for output tiers, reviewer pass, claim checklist, and lab template.
2. `Workflow` — present; one routed producer/reviewer/serve/validate process with local gates, failures, ownership, outputs, and completion criteria.
3. `Activities` — omitted; template selection and browser validation serve the required artifact workflow rather than independent selection outside it.
4. `Reference` — present; one conditional pointer each for intake/persona, tier planning/drafting, reviewer detail, browser validation, and lab selection/integration.

## Behavior-preservation checklist

- [x] Trigger remains codebase-accurate explainers, onboarding material, cross-code-boundary teaching, and interactive learning material.
- [x] Concept, experience level, specialty, time/depth, and optional prior knowledge remain collected or explicitly inferred without redundant questioning.
- [x] Condensed, Guided, and Full Lab routing remains time/depth driven, with Full Lab the default when no lesser depth is requested.
- [x] Exactly one pre-production human scope checkpoint remains mandatory, with adjust/cancel handling.
- [x] Source discovery still maps entry points, cross-boundary flow, specs, schemas, file paths, and truth ownership before drafting.
- [x] Unsupported claims are omitted or visibly marked for verification; gate logic, fields, constants, symbols, and paths are never invented.
- [x] Persona adaptation, specialty emphasis, code density, analogies, server/state authority, and cross-language comparison/syntax cards remain.
- [x] Condensed's static contract, Guided's one-simulation contract, Full Lab's comprehensive practice contract, and static versus interactive file counts remain explicit.
- [x] Lab templates remain preferred over hand-built interactivity and are selected by concept shape from `lab/README.md`.
- [x] Large Full Lab drafting delegation remains optional, approval-gated, isolated when editable, producer-integrated, and recoverable through retry or local drafting.
- [x] Self-check still verifies real paths, language syntax, HTML/JS IDs, placeholders/TODOs, and output completeness before review.
- [x] The reviewer pass remains mandatory after a complete draft; source rediscovery is independent of the draft's map and uses a claim checklist.
- [x] Reviewer delegation requires user approval; unavailable/declined delegation has an honest local source-grounded fallback.
- [x] Reviewer findings retain wrong claim, corrected fact, source path/symbol/line, and CRITICAL/MINOR severity; corrections and the ≥3-CRITICAL second-pass gate remain.
- [x] Durable explainer source remains in the caller/user-selected explainer destination while screenshots and transient validation artifacts remain temporary.
- [x] Self-contained/no-build/no-external-dependency output, full-width code layout, mobile collapse, and overflow-safe code blocks remain.
- [x] Port availability, old-artifact detection, next-free-port selection, consistent URL, and post-start explainer identity check remain.
- [x] Browser validation now follows serving and retains desktop/mobile, overflow, interaction, expanded-state, and console checks.
- [x] Final reporting retains the served URL and adds checkable artifact, review, evidence, limitation, and cleanup status.
- [x] Caller composition ownership remains intact: `teach`/`em-train` may invoke the process but retain their destination, mission/no-spoiler constraints, user gates, and return criteria.
- [x] Every authorized support file is accounted for; unchanged templates and `lab/README.md` remain valid routing dependencies.

## Dependencies, provenance, and risks

- Dependency SK-001 is verified at the recorded baseline. No owner/consumer dependency is unresolved for this item.
- The source-versus-screenshot and serve-versus-validate contradictions are resolved before prose is moved. The tier contract uses the strongest current mandatory behavior plus the lab README's existing minimum viable lab, rather than preserving contradictory optional wording.
- Browser syntax remains owned by `playwright`; this skill keeps only the scenario, viewports/states, evidence location, acceptance checks, and cleanup/report contract. Verification checks the installed CLI before retaining commands.
- `lab/README.md` remains the template selection/integration owner. The network simulator fix is a narrow executable correction discovered while validating that owned catalog; no template redesign is authorized.
- Repository history indicates local authorship and no third-party attribution requirement. `THIRD_PARTY_NOTICES.md` is intentionally unchanged.
- Risk: a source-grounded local fallback is methodologically independent from the draft's source map but is not a separate agent. The completion report must disclose this limitation and never imply separate-review independence.
- Risk: browser availability varies by runtime. The workflow must try the available browser owner, report inability as an incomplete validation limitation, and must not claim checks it could not execute.

## Verification

- `git diff --name-status db1281b1833aeb46cc4b491a6ecddd2caafbe67e -- <authorized paths>` — only the proposal, `SKILL.md`, `REFERENCE.md`, deleted `EXAMPLES.md`, and repaired network template appear.
- Frontmatter/parser audit command from `audit-shared-skills` — all shared skills remain valid under the existing union schema; no redesign.
- A Markdown link/anchor checker over `SKILL.md`, `REFERENCE.md`, and `lab/README.md` — every relative target and fragment resolves one level deep; deleted `EXAMPLES.md` has no inbound reference.
- A section-order check — `SKILL.md` contains exactly `Language Definitions`, `Workflow`, and `Reference` as level-two semantic sections, in canonical order, with no `Activities` section.
- Extract every inline `<script>` from all 13 lab templates and run `node --check` — all scripts parse.
- Serve every lab template and a generated static/interactive fixture with `python3 -m http.server` on a verified free temporary port; use `curl` to confirm unique page identity — server command and identity contract are executable.
- Use installed `playwright-cli` against the served network simulator at nonzero packet loss and against representative static/interactive fixtures — page opens, screenshots save under `/tmp`, packet-loss text includes the percentage rather than a boolean, responsive/expanded-state checks return no overflow, no unexpected console/page error is observed, and the browser closes.
- Reread final `SKILL.md`, changed `REFERENCE.md`, and repaired template against WF-005/WF-008; confirm every checked ledger entry has a retained location or approved owner.
- `git diff --check` and `git status --short` — no whitespace errors or undisclosed changes.

## Explicit exclusions

- No edits to `MIGRATION.md`, specs, notices/licenses, `pi/settings.json`, deployment, Pi visibility symlinks, agent discovery, frontmatter schema, unrelated skills/proposals, `teach`, or `em-train`.
- No new skill, script, dependency, build step, CDN, generalized visual-review process, or lab-template redesign.
- No changes to the other 12 lab HTML files or `lab/README.md`; they are read and verified only.
- No claim that this worker integrates or verifies another ledger item.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization revision: standing directive applied to proposal revision 1 and only the exact file set above.
- Scope check: PASS — MAP → WF-007 → WF-005 Create Explainer record → WF-008 → WF-006 → current specs/source/support/history/executable evidence were read in order; the exact file set, preservation ledger, three contradiction repairs, EXAMPLES retirement, local provenance, and focused verification were reviewed against standing authorization before production edits.

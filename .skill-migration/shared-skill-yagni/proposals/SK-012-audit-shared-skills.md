---
id: SK-012
target: audit-shared-skills
status: verified
blocked-by: [SK-001]
source-verdict: simplify inline
---

# Audit Shared Skills: simplify the complete union-schema audit

## Why this item is next

SK-001 is verified and owns the body-authoring contract, so SK-012 is unblocked for direct normalization. WF-007 places this item in D4 and requires the complete union-schema audit to remain inline. Its exact target is disjoint from concurrently claimed SK-010.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes the preserve-before-prune destination and excludes frontmatter redesign, deployment, and Pi visibility changes.
- WF-007 assigns `audit-shared-skills` the **simplify inline** verdict: retain the complete union-schema audit, remove unused Info severity, and continue to own frontmatter validation rather than semantic/YAGNI review.
- The complete WF-005 target record supplies the preservation ledger: discover every `shared/skills/*/SKILL.md`; parse YAML frontmatter; check all required fields, description constraints, trigger wording, and least-tool grants; report by skill; propose fixes; obtain approval before writing; and rerun the complete audit to a clean result. The schema must remain inline.
- WF-008 confirms the exact definitions of `Union schema`, `Error`, and `Warning` and rejects `Info` unless a concrete informational finding is introduced. No such finding exists.
- WF-006 keeps executable union-frontmatter validation with this skill and explicitly excludes semantic/YAGNI review. Its cross-agent frontmatter redesign and grant-portability lane remains separate.
- `specs/ai-agent-config.md` 2.3.0 requires `name`, `description`, `metadata.short-description`, and `allowed-tools`; descriptions must contain concrete `Use when` triggers and be at most 1024 characters. It also requires canonical skill-body sections and confirms this skill's narrow ownership. `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 leaves skill-local definitions in the owning body. `specs/SPEC-OF-SPECS.md` and `specs/README.md` confirm authority and reading order.
- Verified `shared/skills/write-a-skill/SKILL.md` requires the canonical section shape, checkable steps, local approval/failure/output contracts, semantic YAGNI, provenance review, and this audit as the existing-union-schema verifier only.
- The complete current target has no support files or links. Its checklist is compact and coherent, but its four noncanonical headings separate schema, report, and fixes from the steps they govern. It names `info` in reporting although no condition emits it, and its sample incorrectly renders missing `metadata.short-description` as a warning despite the authoritative checklist classifying it as an error.
- Git history shows repository-local creation at `4fcd8db204888b46ef857ea16732bcb2e4ab201b`, followed by locally maintained harness-name and schema updates. No imported source/revision/license or target entry exists in `THIRD_PARTY_NOTICES.md`; no notice change is warranted.
- Installed Python 3.12.3 with PyYAML 6.0.1 successfully parses the catalog frontmatter, and GNU `find` supplies deterministic catalog discovery. A fresh baseline-aware parse at `46bcd68c334f7820ceba36f780689ca8e43f37be` corrects stale evidence from an earlier item baseline: the current baseline contains 33 skills and has zero required-field or description findings. The complete least-tool pass is verified separately because tool use is semantic rather than a YAML-only check.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-012-audit-shared-skills.md` — item-local authorization, behavior ledger, checks, and final state.
- `shared/skills/audit-shared-skills/SKILL.md` — add confirmed definitions and normalize the complete executable audit into one inline Workflow.

No support file, script, spec, notice, test, deployment file, or visibility link is authorized.

## Proposed changes

### Add

- Add the exact WF-008 definitions of `Union schema`, `Error`, and `Warning` under mandatory `Language Definitions`.
- Add a deterministic discovery command and require YAML-aware parsing of each opening frontmatter block. Missing, empty, unterminated, or unparseable frontmatter is reported as an error rather than silently dropping a skill.
- Add a per-step completion condition: account for the discovered catalog count; apply every listed schema check to every parseable skill; report every skill and finding; obtain explicit approval before each fix or explicitly enumerated fix batch; and do not claim clean until a complete rerun has zero errors and warnings.
- Make the narrow ownership boundary explicit: audit existing union frontmatter only, not body structure, semantics, or YAGNI quality.

### Change or move

- Restructure `Union Schema`, `Process`, `Report Format`, and `Fixing` into canonical `Language Definitions` followed by one `Workflow`; omit `Activities` and `Reference` because the audit has one required sequence and no support files.
- Keep the full four-field schema table inline beside validation and preserve agent-specific-field tolerance.
- Keep all existing severity conditions exactly: absent/empty required fields are errors; overlong descriptions, missing `Use when`, and unused tool grants are warnings. Correct the report sample so missing `metadata.short-description` is `[error]`, matching the authoritative checklist.
- Keep report grouping and `[ok]`, `[error]`, and `[warn]` labels beside the reporting step.
- Keep all existing fix derivations beside the approval/apply step, while making every emitted issue actionable: malformed YAML and missing `name` receive proposed corrections; unnecessary grants receive an exact least-privilege removal proposal.

### Remove

- Remove the unused `Info` severity from prose and report routing. No finding is reclassified or deleted.
- Remove separate report/fixing headings after relocating their complete contracts beside the governing Workflow steps.
- Remove only repeated opening/schema summary prose that is fully represented by the exact definitions, inline table, and validation step.

## Proposed skill shape

1. `Language Definitions` — the exact WF-008 definitions of Union schema, Error, and Warning; no Info term.
2. `Workflow` — present; one discover → parse → validate → report → approve/fix → clean-rerun path containing the complete schema, severity conditions, report shape, fix mappings, ownership limit, and observable completion criteria.
3. `Activities` — omitted; discovery, parsing, reporting, and fixing are required parts of the end-to-end audit rather than independently selected recipes.
4. `Reference` — omitted; the required schema and complete audit must remain inline, and no support file exists.

## Behavior-preservation checklist

- [x] Frontmatter triggers remain unchanged for shared skills added manually or via `npx` and cross-agent compatibility checking across Claude Code, Codex, Pi, and Copilot CLI.
- [x] Every direct `shared/skills/*/SKILL.md` is deterministically discovered and accounted for; parse failures cannot disappear from coverage.
- [x] YAML frontmatter is parsed between opening delimiters rather than inferred only from grep text.
- [x] `name`, `description`, `metadata.short-description`, and `allowed-tools` remain required under the existing repository union schema.
- [x] Missing or empty required fields remain errors; missing nested metadata is handled as missing `metadata.short-description`.
- [x] Description length over 1024 characters and absence of the exact `Use when` trigger phrase remain warnings.
- [x] Tool grants unused by the workflow remain a warning and are evaluated for least privilege without redesigning grant syntax or portability.
- [x] Agent-specific fields such as `compatibility` and `disable-model-invocation` remain tolerated.
- [x] Every skill is reported in a grouped format with field-level `[ok]` and exact `[error]`/`[warn]` findings.
- [x] Every emitted error or warning receives a concrete proposed fix; a missing description still requires user-provided intent, short descriptions remain at most six words, and tool grants remain the smallest workflow-needed set.
- [x] No file is changed before explicit user approval for that issue or enumerated batch; declined fixes remain unresolved and visible.
- [x] After approved fixes, the entire catalog is rerun; clean means zero errors and zero warnings, never merely “edits applied.”
- [x] The rejected Info severity is removed because no informational condition exists.
- [x] The skill remains the executable union-frontmatter validator and does not absorb semantic body, body-structure, or YAGNI review from `write-a-skill`.
- [x] Repository-local provenance remains unchanged; no source/license attribution is lost.

## Dependencies, provenance, and risks

- SK-001 is verified at baseline `46bcd68c334f7820ceba36f780689ca8e43f37be`; no unfinished owner interface blocks this item.
- Correcting the report sample from warning to error repairs a live internal contradiction and does not redesign severity: the current Process, specs, and WF-008 already define missing required fields as errors.
- Explicit parse-failure handling makes exhaustive coverage observable without adding a new schema field or severity. YAML parser availability is checked during execution; failure to obtain a YAML-aware parse is reported rather than replaced with an unsafe regex parser.
- Least-tool evaluation remains semantic because grant syntaxes differ across existing skills. This item preserves the warning and does not define a new cross-harness grant grammar.
- Earlier migration records described four missing-tool errors at their older baselines, but those findings are absent from this item's actual baseline. Focused verification therefore requires all 33 current skills, including SK-012, to remain clean under the full schema and least-tool checks. The clean-rerun contract still governs future audits when findings exist.
- Git history indicates local authorship. `THIRD_PARTY_NOTICES.md` remains verification-only and unchanged.

## Verification

- Reread the complete resulting `SKILL.md` against the WF-005 ledger and exact WF-008 definitions — every branch, gate, guardrail, report/fix contract, ownership rule, and completion condition has an inline retained location.
- Inspect level-two headings — exactly `Language Definitions` then `Workflow`; no unapproved section, link, support file, or script exists.
- Execute a PyYAML-based parser over every deterministically discovered `shared/skills/*/SKILL.md`, applying the resulting skill's exact checks and comparing results with baseline `46bcd68c334f7820ceba36f780689ca8e43f37be` — all 33 skills are covered, the target has no finding, and no catalog finding changes because of SK-012.
- Exercise parser failure handling with temporary malformed/missing-field fixtures outside the repository — malformed YAML and each missing required field produce errors; overlong/missing-trigger descriptions produce warnings; no Info result is possible.
- Check installed `python3 --help`, PyYAML import/version, and `find --help`/execution — the verification command surfaces used for parsing and discovery are available and behave as recorded.
- `test -L pi/skills/audit-shared-skills && test "$(readlink pi/skills/audit-shared-skills)" = '../../shared/skills/audit-shared-skills' && test -f pi/skills/audit-shared-skills/SKILL.md` — Pi visibility remains the unchanged resolving symlink.
- Inspect Git history and `THIRD_PARTY_NOTICES.md` — repository-local provenance remains consistent and no attribution edit is needed.
- `git diff --name-status 46bcd68c334f7820ceba36f780689ca8e43f37be --` plus scoped diff inspection — only this proposal and target skill differ; protected and unrelated paths do not change.
- `git diff --check` — no whitespace errors.
- `bash tests/run.sh` — repository shell tests pass.
- `git status --short` after commit — worktree is clean.

## Implementation and verification record

- Final production diff matches proposal revision 2 exactly: only `shared/skills/audit-shared-skills/SKILL.md` changes in production, with the item proposal as the sole additional file.
- Complete-file reread: PASS. The resulting skill retains exhaustive discovery, YAML parsing, every original schema/severity condition, grouped reporting, concrete fix proposals, approval before writes, and complete clean rerun. Parser-unavailable and declined-fix paths cannot claim clean completion.
- Canonical body and exact language: PASS. Level-two headings are exactly `Language Definitions` then `Workflow`; `Activities` and `Reference` are correctly omitted. Union schema, Error, and Warning match WF-008 exactly, and the rejected severity no longer appears in the production body.
- Ownership and behavior: PASS. The full schema remains inline and the Workflow explicitly excludes skill-body structure, semantic, and YAGNI review. The old report contradiction is repaired: missing `metadata.short-description` is consistently an error.
- Frontmatter: PASS and byte-identical to baseline. The description is 264 characters, contains `Use when`, and all four union fields remain present. The target's `read`, `edit`, and `bash` grants are exercised by catalog inspection/parsing, approved fixes, and deterministic discovery.
- Real baseline-aware catalog audit: PASS. PyYAML parsed all 33 baseline files and all 33 current files; required fields, description length, and trigger findings are identical at zero errors and zero warnings. A complete semantic review of each skill's tool grants against its Workflow and applicable support commands found no unused grant. The generated grouped report accounts for every skill and ends `discovered: 33`, `parsed: 33`, `errors: 0`, `warnings: 0`.
- Parser behavior: PASS. Temporary fixtures independently produced errors for missing, empty, unterminated, and unparseable frontmatter and for each missing required field; overlong and missing-trigger descriptions produced warnings. Every emitted severity was Error or Warning.
- Executable help: PASS. Installed Python 3.12.3, PyYAML 6.0.1, GNU `find` discovery, `python3 --help`, and `find --help` support the exercised verification surfaces. No helper script or runtime dependency was added to the repository.
- Pi visibility: PASS. The tracked mode remains `120000`, the target remains `../../shared/skills/audit-shared-skills`, and the linked `SKILL.md` resolves.
- Provenance/history: PASS. History retains local creation commit `4fcd8db204888b46ef857ea16732bcb2e4ab201b` and subsequent local updates; no target notice or imported source exists, and `THIRD_PARTY_NOTICES.md` is unchanged.
- Exact baseline scope and protected paths: PASS. Only this proposal and target differ from `46bcd68c334f7820ceba36f780689ca8e43f37be`; `.wayfinder/`, specs, notices, AGENTS, tests, install/deployment, all Pi files including `pi/settings.json`, `MIGRATION.md`, other skills, and other proposals are unchanged.
- `git diff --check`: PASS. `bash tests/run.sh`: PASS (2 shell files, 12 tests).
- Resulting target SHA-256: `87559d8879345a2e152f800a463c48b6fed44ea33b4cba7f98749b2b7ab2c52f`.
- Residual risk: a host without a YAML-aware parser cannot complete the audit. The skill now reports that condition as blocked rather than using an unsafe regex or claiming a result; it does not impose a new cross-agent parser dependency.

## Integrated verification

- Coordinator verification timestamp: `2026-07-14T17:13:42+00:00`.
- Exact two-file scope, complete skill review, canonical shape, confirmed severities, rejected Info removal, exhaustive YAML-aware discovery/parser gates, schema checks, approval-before-fix, clean-rerun contract, and narrow frontmatter-only ownership passed independent review.
- The current 33-skill catalog parsed with zero schema/description findings; repository shell tests passed 12/12; `git diff --check` and Pi visibility passed.
- `pi/settings.json` retained its recorded content and diff hashes and remained unstaged. YAML-parser availability remains the documented blocked-host risk.

## Explicit exclusions

- No edits to `MIGRATION.md`, `.wayfinder/`, specs, `THIRD_PARTY_NOTICES.md`, `AGENTS.md`, tests, scripts, deployment/install files, Pi visibility symlinks, `pi/settings.json`, unrelated skills, or unrelated proposals.
- No frontmatter redesign, new field, new severity, harness-specific grant grammar, portability policy, discovery/deployment change, semantic body audit, canonical-section audit, YAGNI review, supporting Reference, or executable helper script.
- No catalog frontmatter fixes and no fixed line-count target.
- No claim that this worker performs coordinator integration or central verification.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `2`
- Authorization revision: standing directive applied to proposal revision 2 and only the exact two-file set above. Revision 2 returns the item through scope review to correct stale four-error evidence after a real parse of baseline `46bcd68c334f7820ceba36f780689ca8e43f37be`; it changes no production scope, ownership, behavior, or removal.
- Scope check: `PASS — MAP → WF-007 → complete WF-005 target record → WF-008 → WF-006 → current specs → verified write-a-skill → complete target → provenance/history → executable parsing/help were read in order; exact two-file scope, complete behavior ledger, contradiction repair, corrected baseline evidence, provenance/license ownership, exclusions, and verification criteria were reviewed. Production editing may continue autonomously under the standing directive.`

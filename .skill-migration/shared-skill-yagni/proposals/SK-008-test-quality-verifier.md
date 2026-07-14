---
id: SK-008
target: test-quality-verifier
status: ready-to-integrate
blocked-by: [SK-001]
source-verdict: retain
---

# test-quality-verifier: explicit audit/improve and delegated/solo routing

## Why this item is next

SK-001 is verified, so the confirmed body-authoring contract is available. SK-008 is claimed on the current frontier and has no unresolved owner dependency. This item retains the compact test-quality audit while repairing its implicit edit authorization and harness-specific delegation route before normalizing the body.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes the preserve-before-prune destination and excludes frontmatter redesign, deployment, and Pi visibility changes.
- WF-007 assigns `test-quality-verifier` the **retain** verdict: preserve the compact audit contract while making delegated/solo and audit-only/improve routing explicit; resolve edit authorization and non-portable role assumptions without growing a testing handbook.
- The complete WF-005 target record supplies the behavior ledger: identify runner/conventions, enumerate tests, identify language-specific weak assertions, run tests/coverage, improve assertions and branch coverage when authorized, rerun, and report scanned files, findings/fixes, added tests, sourced coverage, and a reasoned verdict.
- WF-008 confirms the exact `Vague assertion` definition used below.
- WF-006 keeps test-quality auditing separate from TDD, requires the requested mode and audit scope/thresholds locally, and identifies the current always-editing route and `@test_quality_verifier` role name as contradictions. Its catalog isolation contract requires editable delegates to use an isolated checkout while read-only delegates may share.
- `specs/ai-agent-config.md` 2.3.0 and `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 require the canonical body shape, routing first, local failures/output/completion criteria, behavior preservation, cross-agent composition without ownership transfer, and isolation before transport. `specs/SPEC-OF-SPECS.md` and `specs/README.md` confirm spec authority and reading order.
- Verified `shared/skills/write-a-skill/SKILL.md` owns the four-section structure, checkable behavior, provenance gate, and semantic YAGNI test applied here.
- The current target has no support files. It always reaches editing after either a hard-coded `@test_quality_verifier` route or solo fallback, despite its audit-only trigger. Its runner discovery, language examples, rerun gate, and compact report are otherwise coherent.
- Git history shows repository-local introduction at `dfd67d2db28e59cc86463f54592cf5c1a4ed04c2`, consolidation at `4fcd8db204888b46ef857ea16732bcb2e4ab201b`, and union-frontmatter normalization at `f191c773cc74fd65b53606d13eb24c0f26d593fe`. The parallel Claude/Codex role files were introduced in the same local commit; no imported source, revision, license, or Test Quality Verifier entry in `THIRD_PARTY_NOTICES.md` was found.
- Installed help confirms the retained executable surfaces: ripgrep 14.1.0 accepts recursive regex search, `go help test` documents `go test`, pytest exposes test-path/options invocation, and npm 11.16.0 documents `npm test`. No fixed framework command is added; repository-configured commands remain authoritative.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-008-test-quality-verifier.md` — item-local authorization, behavior ledger, verification record, and state.
- `shared/skills/test-quality-verifier/SKILL.md` — repair routing, add the confirmed definition, and normalize the compact body.

No support file, agent role, test, script, spec, or notice change is authorized.

## Proposed changes

### Add

- Add the exact WF-008 definition of `Vague assertion`.
- Put mode selection first: explicit audit/validate requests are audit-only; explicit fix/improve/add-test requests authorize improve mode; ambiguous requests remain audit-only until edit authorization is obtained.
- Add a portable execution route: use a suitable verifier delegation when the harness provides one, otherwise execute the same workflow in-process. The brief carries mode, scope, configured commands/thresholds, and report contract; read-only delegation may share a checkout, while editable delegation requires an isolated checkout and exact file scope. Failed or unavailable delegation falls back in-process and is disclosed.
- Add local completion and failure rules: account for every discovered in-scope test file, record exact commands and results, never invent unavailable coverage, rerun after authorized edits, and issue PASS only when no unresolved vague assertions remain in scope, executed tests pass, and configured/requested coverage requirements are met.

### Change or move

- Remove the hard-coded role sentence from the frontmatter description while preserving all audit, coverage-improvement, and test-quality triggers.
- Fold the introductory purpose, `Quick Use`, six-step workflow, and `Output` contract into one routed `Workflow`.
- Retain runner/config discovery (`package.json`, `pyproject.toml`, `go.mod`, `Makefile`, CI), test enumeration, the `rg` quick-start pattern, and all JS/TS, Python, and Go weak-assertion examples.
- Keep actual-value, shape, error-path, uncovered-branch, test/coverage rerun, sourced coverage, and concrete verdict requirements beside the steps they govern.
- In audit-only mode, report proposed fixes without changing files. In improve mode, follow repository conventions, make only authorized test changes, and report unresolved findings rather than weakening the verdict.

### Remove

- Remove the non-portable `@test_quality_verifier` identifier and the assumption that generic multi-agent availability implies that named role exists.
- Remove separate `Quick Use` and `Output` level-two sections after their unique behavior is retained in `Workflow`.
- Remove the duplicate unheaded trigger summary because the frontmatter description and routed workflow already carry it.

## Proposed skill shape

1. `Language Definitions` — present; the exact confirmed `Vague assertion` definition.
2. `Workflow` — present; one audit/improve process with mode and delegated/solo routing first, followed by discovery, audit, execution, optional edits, rerun, and report.
3. `Activities` — omitted; scanning and test commands are required workflow steps, not independently selected recipes.
4. `Reference` — omitted; the compact language examples and report contract are needed on every invocation and no support file exists.

## Behavior-preservation checklist

- [x] Invocation still covers auditing vague assertions, improving coverage, and validating test quality/meaningfulness.
- [x] Delegated execution remains available when supported, with a complete portable brief; solo/in-process execution remains the fallback.
- [x] Project language, runner, conventions, config, Makefile, and CI discovery remain first-class evidence.
- [x] Test enumeration remains exhaustive for the requested scope and retains the cross-language `rg` quick start.
- [x] JS/TS truthy/defined/literal checks, Python true/bare-result/pass checks, and Go error-only checks remain named candidates.
- [x] The audit still requires assertions on actual caller-visible values, shapes, and errors rather than broad success.
- [x] Existing repository test and coverage commands remain preferred; framework defaults remain the fallback.
- [x] Audit-only mode preserves findings without edits; improve mode preserves replacement of weak assertions and addition of uncovered-branch tests after authorization.
- [x] Tests and coverage are rerun after changes, with command failures and unavailable coverage reported honestly.
- [x] The report still contains files scanned, vague assertions found/fixed, tests added, sourced coverage when available, and PASS/FAIL with concrete reasons.
- [x] Caller ownership of mode, edit authorization, scope/thresholds, and acceptance remains intact across delegation.
- [x] Completion now accounts for all in-scope tests and unresolved findings without expanding into general testing pedagogy.

## Dependencies, provenance, and risks

- SK-001 is verified at baseline `0f5faddbea96056375c6d1374a33c7b9d07902f7`; no consumer depends on an unfinished owner decision for this item.
- The edit-authorization contradiction is repaired before headings move: audit/validate defaults to no edits, improve/fix requires explicit authorization, and ambiguity cannot silently authorize writes.
- The role contradiction is repaired before `Quick Use` is removed: capability-based delegation replaces one harness-specific identifier and retains an honest in-process fallback.
- Repository history indicates local authorship. `THIRD_PARTY_NOTICES.md` is verification-only and intentionally unchanged.
- Existing `allowed-tools` is preserved exactly because frontmatter grant portability/redesign is a separate lane. This may not express editing consistently in every harness; the body still states authorization and isolation requirements, and the residual portability issue is reported rather than silently broadened.
- Coverage can be unavailable or have no configured threshold. The workflow reports that limitation and does not invent a metric or advisory gate.

## Verification

- Reread the complete resulting `SKILL.md` against the WF-005 ledger and WF-008 definition — every checked behavior has an inline retained location and both contradictions are repaired.
- Inspect level-two headings — exactly `Language Definitions` then `Workflow`; no unapproved section or support pointer exists.
- Run a union-frontmatter catalog parser implementing `audit-shared-skills` checks — the target has `name`, a `Use when` description within 1024 characters, `metadata.short-description`, and workflow-used Bash grants. Compare catalog findings to baseline; unrelated pre-existing errors are reported rather than fixed under this item.
- Run the retained `rg -n` quick-start expression against temporary JS, Python, and Go fixture names — all three language forms are discoverable and the command exits successfully.
- Inspect `pi/skills/test-quality-verifier` with `readlink`/`test -e` — it remains a resolving symlink to the canonical target.
- `git diff --name-status 0f5faddbea96056375c6d1374a33c7b9d07902f7 --` and scoped diff inspection — only the proposal and target skill change; no role, notice, spec, deployment, settings, visibility, or unrelated skill changes.
- `git diff --check` — no whitespace errors.
- `bash tests/run.sh` — repository shell tests pass.
- `git status --short` after commit — worktree is clean.

Worker verification at `2026-07-14T16:55:29+00:00`:

- The complete resulting skill matches every WF-005 ledger entry and uses the exact WF-008 definition; audit/improve authorization and capability-based delegation are explicit before execution.
- The only level-two headings are `Language Definitions` and `Workflow` in canonical order; there are no links, support files, scripts, or changed fixed framework commands to validate.
- The baseline-aware union audit covered all 33 skills: the target is clean and no finding changed from baseline. Four unrelated baseline errors remain (`create-agents-md`, `curator`, `design-md`, and `update-specs` lack `allowed-tools`) and are outside this proposal.
- The retained `rg` expression discovered temporary JavaScript, Python, and Go fixtures. Installed ripgrep, npm, pytest, and Go help had already confirmed the applicable command surfaces.
- Pi visibility resolves exactly through `../../shared/skills/test-quality-verifier`; provenance remains repository-local and `THIRD_PARTY_NOTICES.md` is unchanged.
- Exact worktree scope is the proposal plus target skill; `pi/settings.json` and notices have no baseline diff. `git diff --check` passed.
- `bash tests/run.sh` passed both shell test files and all 12 test cases.

## Explicit exclusions

- No edits to `MIGRATION.md`, specs, `THIRD_PARTY_NOTICES.md`, `pi/settings.json`, tests, scripts, deployment, Pi visibility symlinks, agent discovery/config/role files, frontmatter schema, or unrelated skills/proposals.
- No new role, sub-agent, support document, testing framework, coverage threshold, testing handbook, or generic TDD behavior.
- No claim that this worker centrally integrates/verifies SK-008 or changes any other ledger item.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `2`
- Authorization revision: standing directive applied to proposal revision 2 and only the exact two-file set above. Revision 2 makes the catalog audit acceptance baseline-aware after execution found four unrelated pre-existing missing-`allowed-tools` errors; it does not change production scope or behavior.
- Scope check: PASS — MAP → WF-007 → complete WF-005 target record → WF-008 → WF-006 → current specs → verified write-a-skill → current target/support → provenance/history → executable help were read in order; exact files, preservation ledger, contradiction repairs, ownership, provenance, exclusions, and revised verification were checked before further production work.

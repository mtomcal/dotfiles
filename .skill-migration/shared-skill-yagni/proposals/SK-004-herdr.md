---
id: SK-004
target: herdr
status: ready-to-integrate
revision: 1
blocked-by: [SK-001, MG-002]
source-verdict: simplify inline
---

# Herdr: replace the repeated manual with safe current-context activities

## Why this item is next

SK-001 and MG-002 are verified. WF-007 places `herdr` in the correctness-before-movement tranche: repeated recipes may be consolidated only after caller-versus-focused semantics, public-ID semantics, unsafe static selectors, destructive ownership, live command syntax, and provenance are accounted for. The coordinator claimed SK-004 from baseline `0df25fafc4bb6ed284bdc1d2ba5fe1c037286c5a`; this target does not overlap the concurrently claimed SK-002 scope.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` and WF-007 — verdict `simplify inline`; preserve command behavior while repairing current-context, identifier, destructive-operation, live-help, and AGPL obligations before consolidation.
- WF-004 `herdr` record — complete behavior ledger: environment gate; workspace/tab/pane discovery and management; all three installed read sources and ANSI; right/down split, parse, run, send, close; output and agent-status waits; server/test/agent/coordination recipes; JSON/text/silent return contracts; timeout status; focus preservation; and conditional protocol loading.
- WF-008 — human-confirmed caller pane, focused pane, public Herdr ID, legacy display selector, agent status, `done`, and `idle` definitions. Workspace, tab, and pane remain owned by `specs/UBIQUITOUS_LANGUAGE.md`.
- WF-006 — Herdr owns terminal mechanics, not caller task/state/acceptance; callers retain live-ID refresh and in-process fallback; checkout isolation precedes transport; static-ID recipes and missing destructive ownership must be repaired before text moves.
- `specs/ai-agent-config.md` version `2.3.0`, `specs/herdr-config.md` version `0.1.0`, and `specs/UBIQUITOUS_LANGUAGE.md` version `0.7.0` — canonical section order, Herdr ownership/composition rules, public-ID refresh and non-persistence, current-context definitions, runtime-state boundaries, distribution, and body/provenance contracts.
- Current `shared/skills/herdr/SKILL.md` — one production file, no local support files, repeated static numeric selectors, two split recipes that assume the next display position, the false statement that the focused pane is the caller, and no destructive-resource ownership rule.
- Verified `shared/skills/write-a-skill/SKILL.md` — requires a behavior-preservation ledger, only earned semantic sections, independently reusable Activities, colocated guardrails/outputs/completion rules, conditional Reference load reasons, semantic YAGNI, and exact scope verification.
- `THIRD_PARTY_NOTICES.md` — records the local adaptation from `ogulcancelik/herdr` commit `6cbdba434fd15fc3818302a5843593da47db2eb4`, local introduction commit `1007795a0e3608f271797dfc6f6c1ab2b72d5284`, AGPL-3.0-or-later declaration, and full AGPL text. The notice is exact and requires no edit.
- Installed Herdr `0.7.1` evidence — `herdr --help` and the `workspace`, `tab`, `pane`, and `wait` group help confirm every retained command family and option. Read-only redacted smoke checks confirm `workspace list`, `tab list`, `pane current --current`, and `pane list` JSON result shapes; `pane current --current` returns the environment-identified caller without recording a live ID.
- Current upstream/protocol evidence inspected on 2026-07-14 at revision `b0d46fb9bc2a3e7fb58864939e2580b8a9a2f1bc` — current guidance requires installed-help discovery, `HERDR_*_ID`/`--current`, opaque IDs, parsed mutation responses, non-owner close guards, and CLI-first protocol use. The official socket API says omitted optional pane targets use server/UI focus and raw protocol is for direct request/response or event subscribers.

No unresolved consequential authority conflict remains. Current upstream calls public IDs stable and says closed IDs are not reused, while the repository glossary and normative agent spec still require refreshing public IDs after topology changes and never persisting them. Revision 1 follows the repository contract and the safer refresh rule; it does not claim numeric legacy selectors are public IDs. Current upstream documents capabilities newer than installed `0.7.1`; revision 1 makes installed group help authoritative and does not present uninstalled syntax as executable.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-004-herdr.md` — item-local authorization, scope review, behavior ledger, and verification record.
- `shared/skills/herdr/SKILL.md` — the only authorized production file; replace its repeated manual with canonical current-context Activities and earned References.

No support file is authorized because `shared/skills/herdr/` contains only `SKILL.md`. The two paths above are the complete allowed file set for revision 1.

## Proposed changes

### Add

1. Add `Language Definitions` with the WF-008-confirmed operational distinctions: caller pane versus focused pane; opaque refreshable public Herdr ID versus unstable legacy display selector; all five agent statuses; and `done` versus `idle`. Refer to the repository glossary rather than redefining Herdr workspace, tab, or pane.
2. Add a reusable environment-and-discovery Activity that:
   - requires `HERDR_ENV=1` before every Herdr operating session and stops with the existing outside-Herdr message when absent;
   - uses `HERDR_WORKSPACE_ID`, `HERDR_TAB_ID`, `HERDR_PANE_ID`, and `pane current --current` for caller context;
   - states that `focused` list state is UI focus, not caller identity;
   - uses `herdr --help` plus command-group help as installed syntax authority and warns not to probe valid mutators by omitting arguments.
3. Add one canonical split → parse → run → wait → read Activity using `--current`, `--no-focus`, and `result.pane.pane_id`. Parameterize right/down, ordinary commands, tests, servers, and agent launches without any literal public ID or legacy selector.
4. Add explicit operation ownership beside topology changes: transport never transfers caller task/state/acceptance; a separate pane is not checkout isolation; focus/rename/topology changes happen only for the explicitly requested task; close only resources created for the task or resources the user explicitly asks or approves closing; never stop the active server unless explicitly requested.
5. Add explicit wait diagnosis: inspect current state/output before future waits; timeout exits `1`; inspect `pane get` and pane output after timeout; treat `idle` or `done` as completed according to seen state, `blocked` as needing input, and `unknown` as a signal to fall back to output inspection for a plain shell or undetected agent.
6. Add earned Reference pointers with load conditions:
   - repository provenance notice and exact imported upstream revision when auditing or changing adapted AGPL material;
   - exact current upstream skill revision only when reconciling installed-version behavior or updating this adaptation;
   - official socket API only for raw protocol, custom clients, or long-lived subscriptions.

### Change or move

1. Preserve frontmatter and its inside-Herdr trigger; change only body structure and corrected operating semantics.
2. Replace `concepts` with the confirmed definitions and a pointer to project-owned workspace/tab/pane terms.
3. Consolidate discovery, tab/workspace management, pane reading/splitting/input/closing, both wait sections, recipes, and notes into five independently reusable Activities:
   - verify/discover current context and installed syntax;
   - inspect/read pane output;
   - split/run/send and spawn agents;
   - wait/diagnose/coordinate;
   - explicitly requested workspace/tab/resource management.
4. Replace every static numeric example with caller environment variables, `--current`, or a variable parsed directly from a live JSON response. Legacy numeric forms remain named only as selectors that must not be guessed, persisted, or used in recipes.
5. Keep all workspace and tab capabilities: list, create with cwd/label/environment/default naming, keep focus with `--no-focus`, get, focus, rename, and close. Keep pane list/get/read/split/run/send/close, right/down direction, labels where supported, all three installed read sources, ANSI output, literal/regex output waits, and agent-status waits.
6. Keep the input distinction: `send-text` does not press Enter, `send-keys` sends keys, and `pane run` sends text plus a real Enter in one request.
7. Keep return contracts beside execution: the named list/create/get/focus/rename/close/split/wait controls return JSON on success under the existing contract; `pane read` returns text (optionally ANSI); `pane send-text`, `pane send-keys`, and `pane run` are silent on success. Keep create response locations for workspace/tab/root pane and `result.pane.pane_id` for split.
8. Keep read/wait semantics: `visible` is the viewport, `recent` is rendered recent scrollback, `recent-unwrapped` joins soft wraps, recent matching is unwrapped, and matching transcript inspection uses `recent-unwrapped`.
9. Keep `--no-focus` behavior for background workspace/tab/pane creation and default naming behavior when labels are omitted.
10. Keep agent launching and coordination but route detected agents through status inspection and plain/unknown panes through output waits and reads. The caller still chooses the agent executable, task, expected readiness/output, timeout, and acceptance evidence.

### Remove

1. Remove the false claim “the focused pane is yours” and all language equating current caller context with UI focus.
2. Remove examples that define public IDs as compact numeric positions or predict compaction. Replace them with opaque public-ID and legacy-display-selector semantics from WF-008/current specs.
3. Remove every literal numeric workspace/tab/pane recipe and both unsafe split-then-assume-next-selector sequences. No live ID or selector will be persisted in the proposal, skill, commit message, or handoff.
4. Remove repeated server, test, watch, spawn, and coordinate recipes only after their command substitutions, wait modes, output inspection, and completion/failure behavior are retained once in the canonical Activities.
5. Remove repeated read/wait/parse/focus/default-label notes after each contract is colocated with its governing Activity.
6. Remove no trigger, supported command family, status, read source, input mode, return shape, timeout behavior, focus-preservation rule, fallback, guardrail, output contract, coordination path, provenance duty, or license attribution.

## Proposed skill shape

1. `Language Definitions` — present and mandatory; only caller/focus, public/legacy identifier, and agent-status distinctions, with project Herdr entities left to the repository glossary.
2. `Workflow` — omitted; Herdr exposes independently selected terminal operations rather than one required end-to-end process.
3. `Activities` — present; current-context discovery, inspect/read, split/run/send, wait/diagnose/coordinate, and explicitly requested resource management.
4. `Reference` — present; conditional pointers for AGPL provenance/upstream comparison and raw socket protocol work.

## Behavior-preservation checklist

- [x] Frontmatter name, description, trigger, short description, and allowed tools remain unchanged.
- [x] Outside-Herdr gate still checks `HERDR_ENV=1`, reports that the agent is not in a Herdr-managed pane, and stops without inspecting or controlling UI focus.
- [x] Caller pane and focused pane are distinct; environment/current-pane discovery identifies the caller.
- [x] Public IDs are opaque, refreshed after topology changes, parsed from live responses, and never persisted; legacy display selectors are never guessed, persisted, or used in recipes.
- [x] Workspace/tab/pane definitions remain owned by the repository glossary rather than duplicated.
- [x] Agent status retains `idle`, `working`, `blocked`, `done`, and `unknown`; `done` and `idle` preserve the confirmed seen/unseen distinction.
- [x] Workspace discovery plus list/create/default naming/cwd/label/env/no-focus/get/focus/rename/close remain.
- [x] Tab list/create/default naming/cwd/label/env/no-focus/get/focus/rename/close remain.
- [x] Pane list/get/read/split right or down/run/send-text/send-keys/close remain.
- [x] `visible`, `recent`, and `recent-unwrapped` read sources, text/ANSI output, rendered/unwrapped distinction, and recent-wait matching behavior remain.
- [x] Literal and regex output waits, agent-status waits, timeout `1`, and inspect-before-wait behavior remain.
- [x] `send-text` without Enter, `send-keys`, and `run` with Enter remain distinct.
- [x] Server/test/ordinary-command/agent-launch/agent-coordination uses remain reachable through one parameterized split/run/wait/read Activity.
- [x] Detected-agent status handling and plain-shell/unknown-agent output fallback remain executable.
- [x] `--no-focus` preserves caller context for background creation; explicit focus capability remains but is user-requested.
- [x] Split, tab-create, and workspace-create response parsing remains; no mutation response is discarded before its IDs/state are captured.
- [x] JSON, text/ANSI, and silent-success return contracts remain beside their commands.
- [x] Resource ownership and explicit close/server-stop approval are local to destructive operations.
- [x] Herdr remains terminal transport only; caller brief/state/acceptance and checkout-isolation decisions do not transfer to a pane.
- [x] Installed CLI help remains authoritative; current upstream and raw protocol are conditional References rather than copied manuals.
- [x] Exact imported revision, local introduction, AGPL-3.0-or-later provenance, and full license remain in `THIRD_PARTY_NOTICES.md` and are linked conditionally without editing the notice.
- [x] No support file, spec, notice, deployment path, visibility link, unrelated skill/proposal, or migration ledger is changed.

## Dependencies, contradiction repairs, provenance, and risks

- SK-001 and MG-002 are verified blockers. SK-001 supplies the canonical authoring contract; MG-002 already repaired the Herdr notice, so this item must preserve rather than rewrite it.
- Caller/focus contradiction: repaired by treating environment IDs and `pane current --current` as caller context and list `focused` state as UI context. Omitted optional pane targets are not used for caller-sensitive operations.
- Identifier contradiction: repaired by treating public IDs as opaque runtime handles, refreshing after topology changes, and naming numeric forms only as legacy display selectors. Static selector recipes are removed.
- Destructive ownership contradiction: repaired with explicit requested-topology, owner-created cleanup, non-owner approval, context-changing focus, and active-server stop guards.
- Command drift: repaired by requiring installed group help first and limiting executable examples to syntax confirmed in Herdr `0.7.1`. Current upstream behavior is advisory when versions differ.
- Provenance: the exact source/revision/local introduction/AGPL license is already complete in `THIRD_PARTY_NOTICES.md`; revision 1 adds a conditional pointer but authorizes no notice edit and no automatic upstream sync.
- Risk: current upstream says opaque public IDs are not reused, while the repository contract still requires refresh after topology changes. The stricter refresh rule is safe, authoritative for this repo, and avoids durable identity assumptions.
- Risk: a status wait can observe `idle` instead of `done` when completion has already been seen. The Activity requires `pane get` inspection and treats both as completion according to attention state rather than waiting blindly for only one.
- Risk: group help exits vary by installed version. The skill uses explicit group `--help` discovery supported by installed `0.7.1` and tells agents to follow the installed output rather than assume copied syntax.
- Risk: consolidation could omit a command or output nuance repeated in the old notes. Mitigation: compare the final complete file with every checked ledger item and run textual markers plus installed-help verification before `ready-to-integrate`.

## Verification

- `herdr --version; herdr --help; herdr workspace --help; herdr tab --help; herdr pane --help; herdr wait --help` — installed `0.7.1` exposes every command family and option used by the revised Activities. Do not execute mutating commands for verification.
- Run redacted read-only checks of `workspace list`, `tab list --workspace "$HERDR_WORKSPACE_ID"`, `pane current --current`, and `pane list --workspace "$HERDR_WORKSPACE_ID"` — JSON result types/keys are present and current-pane output matches `HERDR_PANE_ID` without printing or persisting a live ID.
- Parse frontmatter and assert `name`, `description`, `metadata.short-description`, and `allowed-tools` are unchanged; assert the description includes `Use when` and is at most 1024 characters.
- Inspect level-two headings and assert they are exactly `Language Definitions`, `Activities`, and `Reference`, in that order, with no `Workflow`.
- Assert every WF-008 term/status, environment gate, caller/focus rule, opaque/legacy rule, ownership guard, timeout behavior, read source, input mode, return contract, and response path in the behavior checklist is present.
- Search all shell fences and body text for literal numeric workspace/tab/pane selectors; acceptance requires none. Search for `HERDR_*_ID`, `--current`, `--no-focus`, and parsed `result.pane.pane_id` in the canonical recipe.
- Validate all Markdown links resolve or return successful HTTP responses. Confirm each Reference pointer says when and why to load its target.
- Confirm `shared/skills/herdr/` contains only `SKILL.md`; there is no support script or local Reference file to validate.
- Run the repository's executable `audit-shared-skills` workflow under the existing union schema; expect no new target finding.
- Verify `pi/skills/herdr` remains the existing symlink resolving to `../../shared/skills/herdr`, without editing it.
- Inspect `THIRD_PARTY_NOTICES.md` for the exact Herdr source revision, local commit, AGPL-3.0-or-later declaration, and complete license; verify the notice has no diff.
- `git diff --check` — no whitespace errors.
- `git diff --name-only 0df25fafc4bb6ed284bdc1d2ba5fe1c037286c5a` plus untracked-file inspection — only this proposal and `shared/skills/herdr/SKILL.md` may differ.
- Run `bash tests/run.sh` as a repository regression check.
- Reread the complete final skill, compare the actual diff with revision 1, and record focused results before marking `ready-to-integrate`.

Acceptance requires every checklist item to pass, exact two-file scope, unchanged union frontmatter, canonical body shape, installed-help compatibility, no static selector recipe, valid conditional References, preserved AGPL notice, and no unresolved authority conflict.

## Implementation record

Focused verification completed: `2026-07-14T16:20:03+00:00`

- Actual production diff: `shared/skills/herdr/SKILL.md` only, with 95 insertions and 219 removals; this proposal is the only additional item-local file.
- Resulting skill SHA-256: `6cb65cb77195973c78062591cb8f5c01d536f170d4e2198d3df060f5d256b7bd`.
- Complete final-file reread and revision 1 diff/behavior-ledger comparison: PASS.
- Existing union-frontmatter audit: 33 skills, 0 errors, 0 warnings; target frontmatter is byte-identical to baseline and its existing Herdr-only grant is exercised.
- Canonical level-two shape (`Language Definitions`, `Activities`, `Reference`, with no `Workflow`): PASS.
- WF-008 definitions, all five statuses, caller/focus distinction, opaque/legacy identifier distinction, ownership guards, wait fallbacks, return contracts, and all retained command-family markers: PASS.
- Installed Herdr `0.7.1` version plus workspace/tab/pane/wait group help: PASS. Redacted read-only workspace/tab/pane list and `pane current --current` JSON checks: PASS; no live ID was recorded.
- Static public-ID/legacy-selector scan and all 11 Bash-fence syntax checks: PASS.
- Four Markdown links resolve: local provenance notice plus exact imported upstream, current inspected upstream, and official socket API references. Every Reference bullet states when and why to load it.
- Herdr skill support scope and Pi visibility symlink: PASS and unchanged.
- Exact Herdr source/local-introduction/AGPL notice checks: PASS; `THIRD_PARTY_NOTICES.md` remains byte-identical to baseline.
- `git diff --check`: PASS.
- `bash tests/run.sh`: PASS (2 shell test files; 12 tests).
- Exact changed-path scope from baseline, including untracked files: PASS; only this proposal and the target skill differ.
- Forbidden-scope diff for `pi/settings.json`, specs/glossary, notices, AGENTS.md, deployment, Herdr config/integrations, visibility, other skills/proposals, and `MIGRATION.md`: empty.
- Residual risk: current upstream considers opaque public IDs stable/non-reused while repository authority requires refresh after topology changes. The implemented stricter refresh rule is deliberate, safe, and recorded; executable syntax remains pinned to installed help rather than newer upstream-only surfaces.
- Residual risk: observed agent completion can be `idle` instead of `done`. The implemented status contract requires live `pane get` inspection and accepts either according to attention state, with output inspection for `unknown`.

## Explicit exclusions

- No edit to `.skill-migration/shared-skill-yagni/MIGRATION.md` or any other migration proposal.
- No edit to `pi/settings.json`, any spec/glossary, `THIRD_PARTY_NOTICES.md`, AGENTS.md, installer/deployment file, Herdr config/integration, or visibility symlink.
- No new support Markdown, script, command wrapper, API client, test fixture, skill, or dependency.
- No execution of close, rename, focus, split, create, run, send, server-stop, session, integration, worktree, or other mutating Herdr commands during verification.
- No redesign of frontmatter, `allowed-tools`, harness grants, discovery, or the repository's composed-use trigger.
- No adoption of newer upstream-only command families as if installed `0.7.1` supported them, and no automatic upstream synchronization.
- No ownership of caller briefs, workflow state, acceptance, checkout isolation, or in-process fallbacks outside this transport skill.
- No claim on any migration item other than SK-004.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization effect: the standing directive removes the per-item approval wait but authorizes only the two exact paths and changes enumerated in revision 1.
- Scope check: `PASS` — ledger-order authorities, exact two-file scope, complete behavior ledger, caller/focus and identifier repairs, static-selector removal, destructive ownership, installed-help verification, current upstream/protocol evidence, exact AGPL provenance, and exclusions were reviewed against revision 1; production editing may proceed without a per-item approval wait.

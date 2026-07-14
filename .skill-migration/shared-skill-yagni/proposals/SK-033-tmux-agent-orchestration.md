---
id: SK-033
target: tmux-agent-orchestration
status: verified
revision: 1
blocked-by: [SK-001, NEW-001]
source-verdict: consolidate/delegate
baseline: e7b8eec2f13506aca747dd7cb4df46c193fe3dd6
---

# Tmux Agent Orchestration: retain terminal control and compose Git delivery

## Why this item is next

SK-001 and NEW-001 are verified at claim baseline `e7b8eec2f13506aca747dd7cb4df46c193fe3dd6`. WF-007 places `tmux-agent-orchestration` after the generic Git-delivery owner exists: tmux keeps isolated worker launch, verified TUI steering, pane-plus-Git monitoring, and scoped cleanup, while generic pull-request creation/update, CI-to-green, stale-head refresh, pushed-head proof, fixed-point review, and conflict intent move to `git-delivery` and its composed owners.

The claim commit changes only coordinator-owned `.skill-migration/shared-skill-yagni/MIGRATION.md`; that file is protected and will not be edited. Tmux remains an explicitly supported fallback even though Herdr is the repository default.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes preserve-before-prune behavior, current frontmatter/provenance, and unchanged deployment/Pi visibility.
- WF-007 assigns this item a **consolidate/delegate** verdict: retain tmux launch, verified steering, monitoring, and scoped cleanup; delete generic delivery only after D6 exists.
- The complete WF-005 target record preserves CLI selection, exact command-shape inspection, one isolated checkout per editable worker, deterministic session/windows, full prompts, pane-plus-Git monitoring, Enter/C-m submission verification, mergeability/CI completion through a replacement owner, and exact session/clone cleanup. It identifies launch, steer, monitor, delivery follow-through, drift recovery, and cleanup as independently reusable operations.
- WF-008 confirms the definitions **Worker clone**, **Orchestration session**, **TUI steering**, and **Prompt submission** exactly. Revision 1 will reproduce those definitions without drift.
- WF-006 keeps terminal/TUI mechanics with this skill, requires isolation before transport, and requires callers to retain task briefs, workflow state, acceptance, returned evidence, editing authority, and an in-process fallback. Its independently invocable split assigns PR/CI/stale-head/pushed-head work to a generic Git-delivery owner.
- `specs/ai-agent-config.md` 2.3.0 requires canonical section order, semantic YAGNI, complete behavior preservation, caller-owned composition, isolated editable delegates, and an in-process fallback. `AGENTS.md`, `specs/tmux-config.md`, `specs/shell-config.md`, and `specs/install-orchestrator.md` retain tmux as an installed/configured explicit fallback while Herdr is the default.
- Verified `write-a-skill` requires one routed Workflow, independently reusable Activities, conditional Reference pointers, local failures/completion evidence, and semantic rather than line-count YAGNI. Verified `git-delivery` now owns a complete transport-independent in-process workflow for PR publication/update, OID proof, CI, and stale refresh; it composes verified `code-review` and `resolving-merge-conflicts`. Verified `audit-shared-skills` owns only YAML-aware union-frontmatter validation.
- The complete current `SKILL.md` and `REFERENCE.md` provide the source ledger. Their tmux-specific commands cover CLI probing, isolated clones, named sessions/windows, prompt files, buffer paste, Enter/C-m, capture-pane, list-panes/list-windows, Git status/log/remote checks, and exact session/clone cleanup. Their generic delivery sections hard-code `origin/main`, PR branch construction, `gh` check/log loops, merge-state interpretation, rebase/merge, semantic conflict review, pushed-head checks, and delivery checklist items; those are now obsolete copies of the verified owner contract.
- Local history introduces the skill at `14d5c80cc86c440d45e84cd636aeaef310c2683d`, moves it to shared skills at `4fcd8db204888b46ef857ea16732bcb2e4ab201b`, expands it locally at `cae720bce55e19c30c916aef320f0104c2926d59`, and adds plan/task wording at `353218e620f7261e0eedde9c62b8f9814c141830`. The material is repository-authored (with recorded Claude Sonnet 4.6 co-authorship), not imported third-party text. `THIRD_PARTY_NOTICES.md` correctly has no target entry.
- Installed command evidence: tmux 3.4 exposes `new-session`, `new-window`, `set-buffer`, `paste-buffer`, `send-keys`, `capture-pane`, `list-panes`, `list-windows`, `list-sessions`, and `kill-session` with the used flags. Installed Codex 0.144.1, Claude Code 2.1.206, Pi 0.80.6, and Copilot CLI 1.0.70 all support interactive and non-interactive entry but differ in working-directory, prompt, approval, and permission flags. Therefore the skill must run `command -v`, `--version`, and `--help` for the selected CLI at invocation rather than prescribe one launch string.

No authority conflict remains. Herdr-default policy does not retire explicitly selected tmux, and the verified Git-delivery owner permits deletion of the copied delivery manual while preserving a local trigger, minimum handoff context, caller ownership, and direct in-process fallback.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-033-tmux-agent-orchestration.md` — item-local authorization, behavior ledger, exact scope, evidence, verification, and worker state.
- `shared/skills/tmux-agent-orchestration/SKILL.md` — canonical body retaining the tmux lifecycle and composing `git-delivery`.
- `shared/skills/tmux-agent-orchestration/REFERENCE.md` — tmux-only command recipes, monitoring patterns, and failure/cleanup handling after generic delivery prose is removed.

These are the exact three regular Markdown files authorized by revision 1, all mode `100644`. No new support file, script, agent, pane, live runtime identifier, or visibility link is authorized.

## Proposed changes

### Add

- Add the four exact WF-008 definitions: **Worker clone**, **Orchestration session**, **TUI steering**, and **Prompt submission**.
- Add route-first scope capture: selected CLI (ask only when absent from the request), one task/branch/isolated clone per editable worker, exact editing authority and prohibited paths, acceptance/return evidence, named bounded session/windows, worker-count and monitoring/deadline bounds, cleanup disposition, and caller ownership.
- Add explicit no-delegation fallback: when tmux/the selected CLI is absent, launch or steering cannot be verified, or a worker fails, the caller retains state and performs the authorized task in the current process. For delivery, the caller invokes `git-delivery` directly rather than recreating its manual.
- Add an explicit delivery composition gate. When PR creation/update, CI-to-green, stale-head refresh, or pushed-head verification is requested, provide `git-delivery` only its required local context (delivery goal/scope, base/head or PR identity, permitted mutations/rewrite/fix authority, checks, and bound). A worker may invoke it, but the caller retains task state, acceptance, and returned-evidence review; if the worker path is unavailable, the caller invokes it in-process.
- Add exact cleanup guards: inventory sessions before launch; never reuse/kill a colliding or unrelated session; refuse clone deletion with unretained changes; target only the named orchestration session and exact owned clone bundle; verify that exact session/path are absent and that the unrelated-session inventory remains present.

### Change or move

- Preserve frontmatter byte-for-byte and normalize the body to `Language Definitions`, one routed `Workflow`, reusable `Activities`, then `Reference`.
- Replace Quick Start, First Question, and Core Rules summaries with one route-first Workflow. The main path will scope, isolate, inspect CLI help, launch named bounded workers with full prompts, monitor pane plus Git state, verify steering submission/activity, compose delivery when requested, collect evidence, and clean exactly owned resources.
- Make full worker prompts explicit: exact clone path/branch/task, editing authority and forbidden paths, whether further delegation is authorized, required checks/commit/return evidence, and instruction not to edit the original checkout.
- Retain launch, steer, monitor, and cleanup as independently reusable Activities with action, failure handling, and observable completion. Workflow references these Activities rather than duplicating their command recipes.
- Keep tmux-specific commands and failures in `REFERENCE.md`: current installed command discovery; clone/branch verification; session/window launch; prompt buffer handling; Enter then C-m retry; capture/list polling; pane/Git state correlation; same-checkout, vanished-window, blocked-agent, unsubmitted-prompt, session-collision, dirty-clone, and exact-cleanup failures.
- Replace anecdotal fixed paths, numeric window loops, hard-coded Codex-only launch, and broad all-session listing with runtime variables and exact named targets. Examples remain illustrative and require current `--help` inspection before use.
- Replace the current single generic Reference sentence with conditional pointers stating when and why to load `REFERENCE.md` and invoke `git-delivery`.

### Remove

- Remove duplicated PR kickoff, clean PR branch, remote-repointing, `origin/main`, `gh pr create`, CI log/check loop, merge-state interpretation, rebase/merge, semantic conflict/drift review, pushed-head, and stale-PR instructions from both target files. Their complete replacement owner is verified `git-delivery`, which composes `code-review` and `resolving-merge-conflicts`.
- Remove obsolete delivery-centric monitoring/checklist entries such as PR created, CI green, clean PR branches, merge-drift status, and pushed refresh. Tmux monitoring ends at pane state, clone path/branch/remote/status/log, worker result, and any composed workflow evidence returned to the caller.
- Remove repeated claims that pasted text is not submission after preserving the rule once beside the verified steering Activity and its detailed failure evidence in Reference.
- Remove the anecdotal false-negative cleanup explanation while retaining exact direct rechecks and fail-closed cleanup evidence.
- Do not copy, summarize, or maintain a second `git-delivery` command manual. Do not add a reciprocal edit to `git-delivery`; this item's authorized composition pointer is local to tmux.

## Proposed skill shape

1. `Language Definitions` — present; the four exact human-confirmed definitions only.
2. `Workflow` — present; one route-first end-to-end lifecycle for scope/ownership, isolation, command inspection, launch, monitoring/steering, optional delivery composition, evidence collection, and exact cleanup.
3. `Activities` — present; independently reusable launch, verified steering, pane-plus-Git monitoring, and exact cleanup operations selected for an already scoped orchestration run.
4. `Reference` — present; conditional pointer to `REFERENCE.md` when exact tmux/CLI recipes or tmux-specific failure recovery are needed, plus the inline composition route to `git-delivery` when generic delivery is requested.

## Behavior-preservation checklist

- [x] Frontmatter remains byte-identical, valid under the union schema, under the description limit, and uses the existing `read,write,bash` grants.
- [x] The exact four WF-008 definitions are present without additions or wording drift.
- [x] Tmux remains invocable for parallel Codex, Claude, Pi, Copilot, or mixed CLI workers when explicitly selected; Herdr's default role does not disable it.
- [x] If the request omits the CLI, ask which installed agent CLI to use before launching; if supplied, do not ask redundantly.
- [x] Run `command -v`, `--version`, and current `--help` for the selected CLI; inspect working-directory, interactive/non-interactive prompt, approval/sandbox/permission, and initial-prompt shape instead of assuming flags.
- [x] Record caller-owned task brief, exact edit authority/forbidden paths, acceptance checks, returned evidence, worker/timeout/poll bounds, and cleanup disposition before transport actions.
- [x] Select checkout isolation before transport; every editable worker gets exactly one task, one isolated clone, and one task branch, and a separate pane never counts as isolation.
- [x] Verify each clone's canonical path, expected branch, remote, and uniqueness; workers may not edit the original checkout or another worker clone.
- [x] Use one deterministic named orchestration session with one deterministic named window per bounded worker; detect collisions and preserve all unrelated sessions.
- [x] Give every worker a full initial prompt containing clone/branch/task, editing authority, forbidden paths, delegation authority, checks, commit/return evidence, and original-checkout prohibition.
- [x] Launch only the authorized worker set; no speculative worker, pane, window, or subagent is added.
- [x] TUI steering uses named targets and buffer paste, sends Enter, inspects the pane, retries with C-m only when still unsubmitted, and verifies a processing transition through a working indicator, assistant/tool output, changed capture, or corresponding Git activity.
- [x] Visible composer text alone is explicitly insufficient; failed transition is reported as unsubmitted and is not treated as worker progress.
- [x] Monitoring correlates pane capture/current command/path with clone branch/remote/status/log and uses the recorded cadence/deadline; completion is never inferred from a vanished window or idle-looking pane alone.
- [x] Worker blocks, permission prompts, exited panes, same-checkout collisions, branch/path/remote mismatches, and unsubmitted prompts have tmux-specific stop/retry/relaunch or in-process fallback handling.
- [x] The caller remains sole owner of workflow state, brief changes, editing authority, acceptance, and cleanup decision; workers return evidence rather than silently expanding scope.
- [x] If tmux/the CLI is unavailable or delegation cannot continue safely, the caller performs the authorized task in-process and preserves the same checks/return contract.
- [x] PR creation/update, CI-to-green, stale-head refresh, pushed-head proof, generic review, and semantic conflict handling route explicitly to verified `git-delivery`, not copied commands.
- [x] Delivery handoff retains minimum local context: goal/scope, base/head or PR identity, permitted remote/metadata/rewrite/fix state changes, checks, and bound.
- [x] A worker may execute the composed delivery process, but the caller retains delivery state/acceptance and invokes `git-delivery` directly in-process if worker transport is unavailable.
- [x] No hard-coded `origin`, `main`, GitHub repository, branch, PR command, check command, merge/rebase method, or semantic-conflict procedure remains in tmux-owned guidance.
- [x] Before cleanup, worker results and Git state are collected and every uncommitted/unretained change blocks clone deletion until explicitly retained or abandoned.
- [x] Cleanup targets only the exact named orchestration session and exact owned clone bundle; it never uses `kill-server`, wildcard session deletion, or broad clone removal.
- [x] Cleanup verifies the exact session no longer exists, the exact clone bundle no longer exists, and every unrelated pre-existing tmux session remains present; failures are reported without widening deletion.
- [x] `REFERENCE.md` retains executable tmux launch/steer/monitor/cleanup commands and tmux-specific failure modes without becoming a second Workflow or delivery manual.
- [x] Every Workflow stage and Activity has an observable completion criterion, and required main-path ownership/fallback rules remain inline.
- [x] Relative Markdown pointers resolve one level deep; Reference commands are consistent with installed tmux 3.4 and the command-probed CLI approach.
- [x] Local repository provenance remains accurate; no unsupported third-party attribution/license is added and `THIRD_PARTY_NOTICES.md` remains unchanged.
- [x] `pi/skills/tmux-agent-orchestration` remains tracked mode `120000`, resolves to `../../shared/skills/tmux-agent-orchestration`, and exposes both target files.
- [x] Semantic YAGNI governs the resulting text; no fixed line target or size gate applies.

## Dependencies, provenance, and risks

- SK-001 and NEW-001 are verified at the claim baseline. This item consumes their final interfaces and does not edit either owner. `git-delivery` is available to Codex/Claude/Copilot through the shared catalog even though its Pi visibility remains deferred to VG-001; when the current harness cannot discover it, tmux must report the unavailable composed owner rather than recreate its manual. The caller still retains the in-process task fallback, but cannot truthfully claim Git delivery without the verified owner contract available.
- The selected agent CLIs have materially different current flags. Reference examples therefore show discovery and tmux mechanics, not a universal launch command. Invocation must inspect current help and form the exact command before launch.
- Tmux target names can collide or resolve ambiguously. The workflow requires deterministic unique names, preflight inventory, and exact named targets; it never kills/reuses a collision merely because the name looks expected.
- TUI rendering differs by CLI/version. Submission proof accepts multiple activity signals but requires an observed transition; visible text alone never passes.
- Removing generic delivery detail is safe only because `git-delivery` is verified and named inline with minimum context plus caller ownership/fallback. A reciprocal production edit to that owner is neither needed nor authorized.
- Local history and notices evidence repository-local provenance. No source, revision, license, or central notice changes.

## Verification

1. Reread both complete resulting target files and map every checklist entry above to one inline location, one tmux-specific Reference location, or the verified `git-delivery` owner.
2. Parse `SKILL.md` headings; expect exactly `Language Definitions`, `Workflow`, `Activities`, `Reference` in canonical order and no Quick Start, First Question, Core Rules, checklist, or other level-two section.
3. Parse frontmatter with PyYAML; compare its complete YAML object and raw frontmatter bytes to baseline. Confirm description length, exact `Use when`, used `read,write,bash` grants, and lowercase hyphenated directory.
4. Confirm the exact four definitions against WF-008 with no wording drift.
5. Inspect routing and ownership: absent CLI asks before launch; supplied CLI proceeds to `command -v`/version/help; scope captures one task/branch/isolated clone per editable worker, editing authority, bounds, return evidence, caller ownership, and in-process fallback before transport.
6. Inspect launch and steering against installed tmux 3.4 `list-commands` output and installed Codex/Claude/Pi/Copilot help. Confirm named bounded session/windows, full prompt fields, runtime-formed CLI command, named buffer cleanup, Enter then conditional C-m, and observed activity transition.
7. Inspect monitoring and cleanup: pane plus Git evidence, cadence/deadline, vanished-pane handling, dirty-clone guard, exact session/path absence checks, unrelated-session preservation, and no `kill-server`/wildcard deletion.
8. Search both target files for delivery sediment: `origin/main`, `gh pr`, PR branch recipes, CI log/check commands, merge-state interpretations, rebase/merge directions, force-push/pushed-head commands, semantic conflict/drift procedure, and delivery checklist entries must be absent except compact owner-routing terminology.
9. Confirm `git-delivery` is explicitly invoked for PR/CI/stale/pushed-head work with minimum handoff context, caller state/acceptance ownership, worker option, and direct in-process caller invocation when worker transport is unavailable. Confirm no copied Git-delivery manual and no reciprocal owner edit.
10. Resolve every relative Markdown link from the target directory one level deep; expect only local `REFERENCE.md` to resolve and no missing nested support.
11. Run the complete YAML-aware `audit-shared-skills` workflow and account for all discovered skills. Acceptance is zero errors; any unchanged pre-existing warning is reported baseline-aware rather than silently repaired outside scope.
12. Run `git diff --check -- .skill-migration/shared-skill-yagni/proposals/SK-033-tmux-agent-orchestration.md shared/skills/tmux-agent-orchestration/SKILL.md shared/skills/tmux-agent-orchestration/REFERENCE.md` and `bash tests/run.sh`.
13. Recheck `git log --follow` for both targets and absence from `THIRD_PARTY_NOTICES.md`; expect the recorded local provenance and no notice diff.
14. Compare baseline-aware paths and modes. Acceptance: only the proposal plus the two mode-`100644` target files differ from `e7b8eec2f13506aca747dd7cb4df46c193fe3dd6`; `.skill-migration/shared-skill-yagni/MIGRATION.md`, `.wayfinder`, specs, AGENTS, notices, tests, deployment/discovery, other skills/proposals, every Pi file including `pi/settings.json`, and visibility symlinks are unchanged.
15. Verify `pi/skills/tmux-agent-orchestration` remains mode `120000`, has exact target `../../shared/skills/tmux-agent-orchestration`, and resolves both `SKILL.md` and `REFERENCE.md`.
16. Perform two separate in-process `code-review` passes against the immutable claim baseline: Standards against repository guidance and Spec against the user directive/proposal. Do not create agents or panes; preserve separate findings/totals.

Acceptance requires proposal-before-edit evidence, exact three-file scope, byte-identical frontmatter, exact definitions, canonical four-section shape, one isolated worker clone/task/branch, command-probed CLI launch, named bounded session/windows/full prompts/edit authority, verified Enter/C-m activity transition, pane-plus-Git monitoring, exact unrelated-session-preserving cleanup, complete caller ownership/in-process fallback, explicit composition to verified `git-delivery`, no copied generic delivery manual or obsolete delivery checklist, retained tmux-specific Activities/Reference commands/failures, local provenance, Pi visibility, clean checks, and no fixed line target.

## Explicit exclusions

- No edit to `.skill-migration/shared-skill-yagni/MIGRATION.md`, `.wayfinder/`, any spec/glossary, `AGENTS.md`, `THIRD_PARTY_NOTICES.md`, tests, installer/deployment/discovery, agent configs, any Pi file including `pi/settings.json`, or any visibility symlink.
- No edit to `git-delivery`, `code-review`, `resolving-merge-conflicts`, `write-a-skill`, `audit-shared-skills`, another skill/support file, or another proposal.
- No new support file, script, symlink, fixed line target, frontmatter redesign, CLI-specific universal command, hard-coded remote/base/PR/check, generic Git-delivery manual, or claim that tmux is the repository default.
- No live worker launch, tmux session/window/pane creation, TUI steering, PR mutation, remote mutation, clone deletion, or persisted live session/window/pane/agent ID during migration verification.
- No central integration, coordinator verification, `verified` status, VG-001 completion, merge, auto-merge, branch deletion, or human-acceptance claim.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization effect: after a passing scope check, the standing directive authorizes only the exact three mode-`100644` Markdown files and changes enumerated in revision 1, without a per-item approval wait.
- Scope check: `PASS — MAP → WF-007 → complete WF-005 tmux-agent-orchestration record → WF-008 → WF-006 → current specs/AGENTS tmux fallback → verified write-a-skill/git-delivery/resolving-merge-conflicts/code-review/audit-shared-skills → complete SKILL.md and REFERENCE.md → provenance/notices/history → installed tmux 3.4 and Codex 0.144.1/Claude 2.1.206/Pi 0.80.6/Copilot 1.0.70 help were read in strict authority order. Exact three-file mode-100644 scope, byte-identical frontmatter, exact definitions, complete behavior ledger, one isolated worker clone/task/branch, named bounded launch/full prompts/edit authority, Enter/C-m activity proof, pane-plus-Git monitoring, exact unrelated-session-preserving cleanup, caller ownership/in-process fallback, explicit verified git-delivery composition, generic delivery removal, retained tmux Activities/Reference/failures, local provenance, Pi visibility, protected paths, and observable verification criteria pass. Production editing may continue autonomously under standing directive 2026-07-14T15:55:39+00:00 for proposal revision 1.`

## Worker implementation and verification record

- Timestamp: `2026-07-14T19:29:57Z`.
- Worker state: `ready-to-integrate`. This is worker evidence only; it is not coordinator verification, integration, or acceptance.
- Proposal-before-edit control: revision 1 was created in `drafting`, reached `proposal-ready` with the standing directive, exact three-file scope, complete behavior ledger, ownership/composition review, provenance, installed-help evidence, and a passing scope check while both production targets remained byte-identical to baseline. No material scope revision followed.
- Fixed review scope: claim baseline `e7b8eec2f13506aca747dd7cb4df46c193fe3dd6`, immutable candidate `8931f5c515ae086de922eb679f5bfb8edfc7e70c`, and stable range `e7b8eec2f13506aca747dd7cb4df46c193fe3dd6...8931f5c515ae086de922eb679f5bfb8edfc7e70c`. The candidate has one commit and exactly the proposal plus both target files. Resulting target SHA-256 values are `17221cf087fd67ebce765ba00bd61909f5188c65e87a6417cf55d46be9e8f9c9` for `SKILL.md` and `e4017a1ce91009934d9e4a09a7257fe51e13110771087c19f7776eb1ceddeba2` for `REFERENCE.md`.
- Standards axis: `PASS`, 0 findings, worst issue none. All three changed files were reviewed against `AGENTS.md`, `specs/ai-agent-config.md`, verified `write-a-skill`, union-frontmatter guidance, exact scope/mode rules, canonical section semantics, local completion/failure contracts, composition ownership, provenance, links, and protected paths.
- Spec axis: `PASS`, 0 findings, worst issue none. All three changed files were independently reviewed against the user directive, MAP, WF-007, complete WF-005 target ledger, WF-008 definitions, WF-006 ownership/split boundaries, and verified `git-delivery`, `code-review`, and `resolving-merge-conflicts`. The pass separately confirmed one isolated worker clone/task/branch, selected-or-asked CLI routing, current-help command formation, named bounded sessions/windows/full prompts/edit authority, Enter/C-m transition proof, pane-plus-Git monitoring, exact unrelated-session-preserving cleanup, caller ownership/direct in-process fallback, and removal of copied generic delivery behavior.
- Behavior and structure: frontmatter is byte-identical to baseline; PyYAML parses the exact union fields and a 339-character `Use when` description; headings are exactly `Language Definitions`, `Workflow`, `Activities`, `Reference`; all four definitions match WF-008; every Workflow stage and Activity has observable completion evidence; both relative links resolve; all 12 fenced Bash recipes pass `bash -n`; and searches find no hard-coded `origin/main`, `gh pr`/`gh run`, merge-state/OID, branch-rebuild, rebase/merge, force-lease, or semantic-drift delivery procedure.
- Runtime/help evidence: installed tmux 3.4 exposes every retained launch/steer/monitor/cleanup command and flag family. Installed Codex 0.144.1, Claude Code 2.1.206, Pi 0.80.6, and Copilot CLI 1.0.70 all resolve and return successful `--help`; their differing command shapes justify invocation-time probing. No live session, window, pane, agent, clone, PR, or remote mutation was created for verification.
- Catalog/repository verification: the YAML-aware audit deterministically discovered and parsed all 34 shared skills with 0 errors and 0 automated description warnings. Target `read,write,bash` grants are all used. The one known unchanged deferred warning remains `visual-qa`'s unused command grants; it is outside this item and no clean-catalog claim is made. `git diff --check` passed; `bash tests/run.sh` passed both shell files and all 12 tests.
- Scope/provenance/visibility: only the three authorized mode-`100644` Markdown files differ from baseline. `MIGRATION.md`, `.wayfinder`, specs, AGENTS, notices, tests, deployment/discovery, other skills/proposals, all Pi files including `pi/settings.json`, and symlinks are unchanged. History confirms local target ancestry at `14d5c80c`, `4fcd8db2`, `cae720bc`, and `353218e6`; the target remains correctly absent from `THIRD_PARTY_NOTICES.md`. `pi/skills/tmux-agent-orchestration` remains tracked mode `120000`, targets `../../shared/skills/tmux-agent-orchestration`, and resolves both files.
- Residual risks: TUI activity markers and CLI flags vary by version, so every real invocation must probe help and prove transitions. Tmux names can collide and cleanup is destructive, so the runtime preflight and exact guards remain mandatory. Git-delivery's Pi visibility is still deferred to VG-001; the direct repository link and caller in-process invocation preserve composition here, but catalog-wide visibility remains a coordinator/final-verification concern.

Coordinator integration verification completed at `2026-07-14T19:34:41+00:00` against integrated commits `fb20052` and `17c91ce`: the complete target, tmux-only Reference, proposal, source ledger, confirmed definitions, current command surfaces, and composed Git Delivery interface were reread. Exact three-file scope; byte-preserved frontmatter; canonical section order; selected-or-asked CLI routing and live help inspection; one isolated worker clone/task/branch; named bounded session/windows; complete prompts/edit authority; Enter then conditional C-m activity proof; pane-plus-Git monitoring; caller ownership and direct in-process fallback; minimum-context Git Delivery composition; exact unrelated-session-preserving cleanup; 12 syntax-valid Bash recipes; Pi visibility; local provenance; and removal of generic delivery sediment passed independent checks. Installed tmux 3.4 and current Codex, Claude, Pi, and Copilot help were available. The YAML-aware audit parsed/accounted for all 34 skills with zero errors and the one deferred SK-027 grant warning, `git diff --check` passed, and `bash tests/run.sh` passed all 12 tests. The protected `pi/settings.json` content and diff hashes remained `7d3f4713d7239e8cda3f75597a55f1767fecdf7964324630e4e74dc686d12e05` and `8298a9063e3ebf2988000d176057a41c31cf20c10bbabe92fb57d47f9f2738d5`. Residual risks remain runtime-varying TUI indicators/CLI flags, destructive name/path collision hazards guarded by preflight, and Git Delivery's intentionally deferred Pi visibility pending VG-001.

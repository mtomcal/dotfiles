---
id: SK-015
target: create-plan
status: verified
blocked-by: [SK-001]
source-verdict: simplify inline
---

# Create Plan: colocate lifecycle guardrails without weakening recovery

## Why this item is next

SK-001 is verified and owns the canonical skill-body contract, so SK-015 is unblocked in the D4 direct-normalization sequence. This worker is assigned the item from baseline `bf52d94c632c2b2288a4efa2d0429cb95ef82644`; its target and support scope is disjoint from concurrently claimed SK-014.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes the decision-ready destination and excludes frontmatter redesign, deployment, and Pi visibility changes.
- WF-007 assigns `create-plan` the **simplify inline** verdict: deduplicate ownership, isolation, and review guardrails at governing transitions while retaining every state and recovery rule. It keeps plan-workspace lifecycle separate from Wayfinder decision tickets, Bootstrap spec-extraction plans, Ralph job plans, teaching state, and other artifacts.
- The complete WF-003 target record supplies the behavior ledger: resolve or safely create `.plan`; classify context and route unresolved uncertainty to Wayfinder; create a parent-owned orchestration index; write vertical fresh-context TDD slices with an expand–migrate–contract exception; derive independent reviews from risk; execute only the integrated-blocker frontier in isolated editable worktrees; retain append-only review/fix history; parent-cherry-pick only verified commits; run final integration, acceptance, repository, and recovery gates. It authorizes removal only of duplicate parent ownership, checkout isolation, non-durable pane-id, and independent Standards/Spec restatements.
- WF-008 confirms the exact skill-local definitions of Plan workspace, Active-plan pointer, Orchestration index, Slice, Frontier, Fixed point, Verification artifact, Integration baseline, and Parent owner. The repository glossary remains authoritative where wording overlaps.
- WF-006 keeps `create-plan` as owner of the plan-specific lifecycle. Universal state/isolation policy remains in specs, while the skill retains each concrete gate at its governing transition. Transport does not own orchestration; read-only reviewers may share a checkout, editors require isolation, generic fixed-point Standards/Spec semantics remain owned by `code-review`, and composition does not transfer parent state or acceptance authority.
- `specs/ai-agent-config.md` 2.3.0 requires the canonical body shape and the full Plan Workspace Contract: temporary workspace and pointer, stale-pointer stop, complete `PLAN.md`, sole parent writer, isolated fresh-context editable slices, integration-gated blockers, independent Standards/Spec reviews, risk-selected additional passes, append-only failed attempts on the original branch, and final reviews. `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 defines overlapping shared terms and qualified artifact boundaries.
- Verified `shared/skills/write-a-skill/SKILL.md` requires this behavior ledger, one routed Workflow, local failures/gates/completion criteria, conditional Reference pointers, and semantic rather than line-count YAGNI. Verified `audit-shared-skills` remains only the union-frontmatter validator.
- The complete current `SKILL.md`, `PLAN-FORMAT.md`, `SLICE-FORMAT.md`, and `VERIFICATION-FORMAT.md` are coherent. The support files own literal schemas and invariants; no support correction or relocation is justified.
- Git history shows the current target/support design arrived at `353218e620f7261e0eedde9c62b8f9814c141830`, building on the original local skill history. `THIRD_PARTY_NOTICES.md` records `create-plan` as a locally maintained adaptation of `mattpocock/skills` revision `66898f60e8c744e269f8ce06c2b2b99ce7660d5f` and reproduces the MIT license. Attribution is complete and unchanged.
- Installed help confirms the unchanged command surfaces: `git worktree --help` is available; `git cherry-pick -h` exposes continuation/conflict operations; `pi --help` supports explicit `--model` and `--thinking`; `pis` reports its wrapper usage; and Herdr mechanics remain delegated to the verified shared `herdr` skill rather than copied here.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-015-create-plan.md` — item-local authorization, behavior ledger, checks, and final worker state.
- `shared/skills/create-plan/SKILL.md` — add confirmed definitions and normalize the six lifecycle phases into the canonical body while removing only duplicate guardrail restatements.

`shared/skills/create-plan/PLAN-FORMAT.md`, `shared/skills/create-plan/SLICE-FORMAT.md`, and `shared/skills/create-plan/VERIFICATION-FORMAT.md` are complete verification-only support files and remain unchanged. No spec, notice, history, help, test, deployment, visibility, settings, or unrelated file is authorized.

## Proposed changes

### Add

- Add `Language Definitions` with all nine exact WF-008 definitions and repository-glossary precedence.
- Begin one `Workflow` by routing existing active-plan, new-plan, stale-pointer, and unresolved-uncertainty cases before authoring state.
- State the parent-owner alias once and retain sole writer, delegate return, and acceptance authority at state-creation and state-changing transitions.
- Add a compact final `Reference` section with mandatory load conditions explaining when and why each of the three unchanged schema files is loaded.

### Change or move

- Preserve the existing six phases as level-three Workflow steps: open/create, orchestration index, fresh-context slices, risk-derived verification, dependency-frontier execution, and finish/recover.
- Move the introduction’s unique artifact relationship into definitions and the opening route; remove its duplicate summary wording.
- Colocate sole-parent ownership with orchestration state creation and reviewer-result recording; keep worker/reviewer return-only behavior at the delegation transitions.
- Colocate editable-checkout isolation with editable worker launch and read-only sharing with reviewer launch.
- Colocate live/non-durable Herdr IDs with transport selection and recovery; retain durable session-purpose recording in the referenced `PLAN.md` schema.
- Colocate independent Standards/Spec requirements with risk selection and fixed-point review execution.
- Colocate integration-gated dependencies, original-branch fixes, verified-only parent cherry-pick, conflict-by-intent, and no merge/deletion authorization with the transitions they govern.
- Preserve frontmatter byte-for-byte; all invocation triggers and current tool grants remain unchanged.

### Remove

- Remove the standalone `Guardrails` section only after placing each unique rule at its governing Workflow transition.
- Remove repeated statements of parent ownership, editable isolation, non-durable pane IDs, and mandatory independent Standards/Spec review where another governing transition retains the same executable rule.
- Remove no `.plan` branch, path rule, context source/classification, objective/DAG/frontier invariant, slice/TDD contract, risk pass, state transition, worktree/branch/commit requirement, review attempt, integration/final gate, recovery rule, schema, authorization boundary, provenance, or support link.

## Proposed skill shape

1. `Language Definitions` — all nine confirmed plan-workspace terms with repository-glossary precedence.
2. `Workflow` — present; one routed, six-phase lifecycle retaining all opening, authoring, execution, verification, integration, completion, and recovery transitions.
3. `Activities` — omitted; all actions are state-ordered parts of the plan lifecycle rather than independently selected recipes.
4. `Reference` — present; mandatory conditional pointers to the unchanged orchestration-index, slice-packet, and verification-artifact schemas.

## Behavior-preservation checklist

- [x] Invocation still covers feature, bug-fix, migration, and refactor planning across fresh contexts or parallel worktrees and still produces a recoverable control plane rather than a prose-only answer.
- [x] All nine WF-008 definitions are present; shared glossary wording wins on overlap, and qualified plan artifacts remain non-interchangeable with Wayfinder tickets, spec-extraction plans, Ralph job plans, teaching state, and Herdr workspaces.
- [x] Existing `.plan` handling retains repository-root discovery, one absolute path, stale target or missing `PLAN.md` stop, no guessing or `/tmp` search, explicit user direction before replacement, and safe new-workspace creation.
- [x] New workspaces retain stable repo id, descriptive plan id, exact `/tmp/agent-plans/<repo-id>/<plan-id>/` tree, newline-terminated pointer, exact local Git exclude entry, no required tracked ignore change, and no implementation secrets.
- [x] Context intake retains specs, ubiquitous language, user decisions, research, current code, four-way context classification, named source evidence, and Wayfinder routing when consequential implementation uncertainty remains.
- [x] `PLAN.md` retains immutable objective/amendment authorization, fixed context sources, full baseline, dedicated integration branch/worktree, explicit Pi/Pis model and thinking defaults, DAG, derived frontier, state/Git/Herdr records, verification matrix, global acceptance, interruption/recovery, and decision/attempt log.
- [x] Parent owner remains the sole writer of `PLAN.md`, slice state, verification artifacts, review verdicts, and integration state; workers/reviewers return commits or findings only and never inherit acceptance authority.
- [x] Every slice retains a DAG node, existing blocker, acyclic graph, and frontier membership only when ready and every blocker is integrated.
- [x] Slice packets retain one-fresh-context scope, vertical behavior, acceptance/failure criteria, blockers, public refactor-resilient test seam, ordered RED/GREEN/REFACTOR cycles, focused commands, likely files, constraints, authorization, and required completion evidence.
- [x] TDD remains one observed intended failure followed by minimum green before the next cycle; horizontal packets remain disallowed; expand–migrate in bounded green batches–contract remains the wide-mechanical exception with all migrations integrated before contraction.
- [x] User presentation/authorization remains required when slice granularity or scope was not already approved, and oversized fresh-context packets block execution.
- [x] Standards and Spec remain mandatory independent passes for every slice; Tests, Premortem, Security, and Visual remain risk-selected with written rationale for any disabled pass.
- [x] Verification placeholders remain flat, enabled-pass-only per slice, with reserved final integration and final acceptance artifacts.
- [x] The complete state machine remains `ready -> implementing -> implemented -> verifying`, `verifying -> needs-fix -> implementing`, and `verifying -> verified -> integrated`; only integrated blockers unlock the frontier.
- [x] Each editable slice retains one isolated worktree/branch from the recorded integration baseline, exact slice-only commit authorization, returned full commit/evidence contract, and prohibition on shared editable checkouts.
- [x] Herdr routing retains the `HERDR_ENV=1` trigger, mandatory shared-herdr-skill loading, exact command from `PLAN.md`, economical explicit model/thinking where appropriate, refreshed live IDs, and no durable pane-ID identity; outside Herdr retains sequential in-process or fresh-context parity.
- [x] Returned worker claims still move only to implemented and can never establish verification.
- [x] Review starts only after commit pinning as an immutable fixed point; read-only checkout sharing, separate Herdr reviewers where appropriate, and explicitly separate in-process axis checklists remain available.
- [x] Parent-recorded `PASS`, `NEEDS-FIX`, and `BLOCKED` behavior remains; failed attempts remain append-only in one artifact, fixes return to the original branch, and the new fixed point is independently reviewed again.
- [x] Parent cherry-picks only after all enabled passes succeed, runs focused integration checks, records the integration commit, and resolves conflicts by both intents without allowing cross-slice convenience edits.
- [x] Every integrated slice still requires isolated implementation commit(s), passing enabled verification attempts, parent checks, and recorded integration evidence.
- [x] Final repository-wide gates, cross-slice integration review, immutable-objective/global-criteria acceptance review, and evidence requirements remain mandatory.
- [x] Remaining worktrees, branches, and integration branch are reported; merge, worktree deletion, and branch deletion remain prohibited without authorization.
- [x] Recovery retains pointer validation, Git reconciliation of baseline/branches/commits/worktrees, mismatch recording, frontier recomputation from integrated blockers, live Herdr rediscovery, and refusal to infer success from idle or missing panes.
- [x] Removed Pi profile, preset reviewer/subagent role, profile runtime, and subagent-tool surfaces remain prohibited.
- [x] All three complete support schemas, relative links, ownership rules, state fields, review axes, attempts, final-review formats, and provenance/license coverage remain unchanged and reachable.

## Dependencies, provenance, and risks

- SK-001 is verified at the baseline. No unfinished owner decision or live contradiction blocks this direct normalization.
- The current target, complete support files, specs, WF-008 language, and WF-006 ownership agree. There is no correctness conflict to resolve before movement.
- The principal risk is unsafe over-compression. The proposal therefore changes only target organization and duplicate placement, leaving support schemas untouched and requiring complete-file/ledger verification.
- Generic Standards/Spec semantics remain owned by `code-review`, but create-plan retains when they run, their fixed point, independent execution, artifact recorder, and state-changing verdict because these are plan-lifecycle gates.
- Herdr owns terminal mechanics; create-plan retains branch/worktree topology, briefs, state, evidence, acceptance, and in-process fallback.
- Provenance is already complete in `THIRD_PARTY_NOTICES.md`; no notice or license edit is authorized.
- Installed help reveals no contradiction with current commands. No executable syntax or helper is added or changed.

## Verification

- Reread the complete resulting `SKILL.md`, `PLAN-FORMAT.md`, `SLICE-FORMAT.md`, and `VERIFICATION-FORMAT.md` against the complete WF-003 ledger and exact WF-008 definitions — every checklist item has a retained inline or support-owned location.
- Inspect level-two headings — exactly `Language Definitions`, `Workflow`, then `Reference`; no Activity or unapproved section exists.
- Resolve every relative Markdown link one level deep — all three references exist inside `shared/skills/create-plan/` and their mandatory load conditions state when and why.
- Run a PyYAML-based complete union-frontmatter audit over every `shared/skills/*/SKILL.md`, accounting for every discovered file and all required checks — zero target errors/warnings and no catalog regression from baseline.
- `git worktree --help`, `git cherry-pick -h`, `pi --help`, `pis --help`/usage, and `herdr --help` — unchanged command assumptions remain supported or delegated; no copied stale syntax is introduced.
- `test -L pi/skills/create-plan && test "$(readlink pi/skills/create-plan)" = '../../shared/skills/create-plan' && test -f pi/skills/create-plan/SKILL.md` — unchanged Pi visibility remains resolving.
- Inspect target/support Git history and `THIRD_PARTY_NOTICES.md` — source revision and reproduced MIT attribution remain complete without a notice edit.
- `git diff --name-status bf52d94c632c2b2288a4efa2d0429cb95ef82644 --` and scoped diff inspection — only this proposal and target differ; protected and unrelated paths do not change.
- `git diff --check` — no whitespace errors.
- `bash tests/run.sh` — repository tests pass.
- After commit, `git status --short` — worktree is clean.

## Implementation and verification record

- Worker verification timestamp: `2026-07-14T17:27:20+00:00`.
- Exact scope: PASS. Relative to baseline `bf52d94c632c2b2288a4efa2d0429cb95ef82644`, only this proposal and `shared/skills/create-plan/SKILL.md` are included in the result. The migration ledger, all Wayfinder files, specs/glossaries, notices, three support schemas, tests, deployment/discovery/visibility paths, all Pi files including `pi/settings.json`, and unrelated skills/proposals remain unchanged.
- Complete-file and preservation review: PASS. The resulting target and all three complete unchanged support files preserve every WF-003 trigger, pointer branch, path rule, context route, state, parent-owner boundary, DAG/frontier invariant, fresh-context TDD slice rule, review pass/attempt, worktree/branch/commit contract, cherry-pick/integration gate, final review, recovery failure, schema, and authorization boundary.
- Canonical shape and language: PASS. Level-two headings are exactly `Language Definitions`, `Workflow`, and `Reference`; no Activity or unapproved section exists. All nine exact WF-008 definitions are present with project-glossary precedence and qualified artifact boundaries.
- Governing transitions: PASS. Sole parent state/verification/integration ownership is stated at orchestration and verdict transitions; editable isolation precedes Herdr transport; read-only sharing remains reviewer-only; live pane IDs remain non-durable; Standards and Spec remain independent; fixes return to the original branch with append-only attempts; only verified commits are parent-cherry-picked; and blockers gate on integration.
- Opening and recovery: PASS. Existing-pointer, missing-pointer, stale-target, new-workspace, local-exclude, secret-safety, context-classification, Wayfinder-routing, Git reconciliation, mismatch-recording, frontier recomputation, and missing/idle-pane failure behavior remain executable.
- Slice and verification schemas: PASS. Vertical RED/GREEN/REFACTOR cycles, intended red signal, minimum green, expand–migrate–contract exception, unapproved-granularity user gate, complete risk matrix, flat enabled artifacts, fixed points, PASS/NEEDS-FIX/BLOCKED, and final integration/acceptance formats remain inline or in their unchanged mandatory support owner.
- Links and visibility: PASS. All three relative links resolve one level deep, state when and why to load their file, and `pi/skills/create-plan` remains the unchanged resolving `../../shared/skills/create-plan` symlink.
- Union audit: PASS. PyYAML parsed all 33 discovered shared-skill frontmatters and applied every required field, 1024-character, exact `Use when`, and workflow tool-use check: 33 parsed, zero errors, zero warnings. The target frontmatter is byte-for-byte unchanged from baseline.
- Provenance/history/help: PASS. Target/support history retains the current design commit `353218e620f7261e0eedde9c62b8f9814c141830`; `THIRD_PARTY_NOTICES.md` still records upstream revision `66898f60e8c744e269f8ce06c2b2b99ce7660d5f` and the MIT license. Installed `git worktree`, `git cherry-pick`, `pi`, `pis`, and `herdr` help supports the unchanged assumptions; no command syntax is copied or changed.
- Repository checks: PASS. `git diff --check` is clean and `bash tests/run.sh` passes both shell test files and all 12 tests.
- Resulting SHA-256 values: target `aa7a305f9b7862da054d064e320c06c6ba930954a55e3c50b8dbf0ffba94403a`; PLAN format `536948a9e6f090a42308aa53b7f82ab169f4301885554cd6499174661d555e5e`; slice format `397457bb0ae14c5cdc2a2403a885043f01a068bbdd8d26897551ab6f02401f3b`; verification format `92f199834f9d7774a9a521ad3a2268b455b9e80edefe0dd7b42cb5a52b488505`.
- Residual risk: none beyond the deliberate dependency on the three unchanged local schema files; complete-file, link, and contract checks passed.

## Integrated verification

- Coordinator verification timestamp: `2026-07-14T17:29:01+00:00`. Exact scope, complete target/support review, canonical shape, nine definitions, lifecycle/state/recovery gates, links, provenance, and settings preservation passed. Repository tests passed 12/12 and diff check passed.

## Explicit exclusions

- No edits to `.skill-migration/shared-skill-yagni/MIGRATION.md`, `.wayfinder/`, any spec or glossary, `THIRD_PARTY_NOTICES.md`, `AGENTS.md`, tests, scripts, help surfaces, install/deployment files, agent config/discovery, Pi visibility links, `pi/settings.json`, support format files, unrelated skills, or unrelated proposals.
- No frontmatter/schema/grant redesign, new plan artifact, changed state, changed review semantics, new transport command, support extraction, executable helper, or fixed line-count target.
- No weakening of plan-specific state ownership, isolation, fixed-point review, review-attempt history, cherry-pick/integration gates, recovery, or authorization.
- No claim that this worker performs coordinator integration, central ledger editing, or final migration verification.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization revision: standing directive applied to proposal revision 1 and only the exact two-file set above.
- Scope check: `PASS — MAP → WF-007 → complete WF-003 target record → WF-008 → WF-006 → current specs/glossary → verified write-a-skill and audit-shared-skills → complete target and all three support files → provenance/notices/history → executable help were read in order; exact files, complete behavior ledger, ownership/composition, contradiction review, provenance/license coverage, exclusions, and verification criteria were checked. Production editing may continue autonomously under the standing directive.`

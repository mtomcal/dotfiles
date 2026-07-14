---
id: NEW-001
target: git-delivery
status: verified
revision: 1
blocked-by: [SK-001, SK-014, SK-024]
source-verdict: independently invocable new-skill split
baseline: c27ceed555233d037cc143321fcfc728475fdadd
---

# Git Delivery: independently own pull-request delivery through green CI

## Why this item is next

SK-001, SK-014, and SK-024 are verified, and NEW-001 is claimed at baseline `c27ceed555233d037cc143321fcfc728475fdadd`. WF-006 found that pull-request creation/update, CI follow-through, stale-branch refresh, and pushed-head verification are useful independently of tmux and have no current owner. WF-007 therefore routes a new owner through D6 before downstream SK-033 removes copied delivery material from `tmux-agent-orchestration`.

The evidence-supported lowercase hyphenated name is `git-delivery`: “Git delivery” is the durable route used by MAP, WF-006, WF-007, and the migration ledger; `git` keeps the skill discoverable outside tmux, while “delivery” covers the complete PR/CI/refresh outcome rather than only PR creation. The proposed description is: “Deliver Git changes through pull requests, CI, and stale-branch refresh with remote-head verification. Use when opening or updating a pull request, following checks to green, refreshing a stale branch, or verifying a pushed PR head.”

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` fixes a decision-ready, preserve-before-prune route and excludes frontmatter redesign, deployment, agent discovery, and Pi visibility changes.
- WF-007 D6 requires a new independently invocable owner for PR creation/update, CI-to-green, stale-branch refresh, and pushed-head verification. It must compose `resolving-merge-conflicts` and `code-review`; tmux material may be removed only after this owner exists.
- WF-006’s ownership matrix keeps terminal/TUI transport with tmux but splits generic delivery. Its composition boundaries keep caller goals, state, authorization, acceptance, and return criteria with the caller; composing another skill imports process rather than ownership. The current contradiction is ownership/location, not a Git command conflict: delivery is useful without tmux but lives only in tmux’s Reference.
- WF-008 confirms `code-review`’s Standards axis, Spec axis, fixed point, and review scope and confirms `resolving-merge-conflicts`’s Source intent, Authoritative source, Combined result, and Remaining operation. NEW-001 will use those owners rather than redefine their language.
- `specs/ai-agent-config.md` 2.3.0 requires canonical body shape, semantic YAGNI, local failures/guardrails/output/completion rules, behavior preservation, caller-owned composition, and no transfer of workflow ownership through transport. It assigns generic fixed-point review to `code-review` and conflict intent/continuation authorization to `resolving-merge-conflicts`.
- `specs/UBIQUITOUS_LANGUAGE.md` 0.7.0 keeps skill-local terms in the owning body; `specs/SPEC-OF-SPECS.md` and `specs/README.md` establish spec authority and reading order.
- Verified `shared/skills/write-a-skill/SKILL.md` permits a split only for an independently useful invocation or reusable workflow and requires one routed, checkable Workflow with semantic YAGNI. Verified `code-review` supplies the fixed-point Standards/Spec review seam and separate results. Verified `resolving-merge-conflicts` supplies in-progress dual-intent conflict resolution, selective staging, and exact-action authorization.
- Verified `audit-shared-skills` owns YAML-aware union-frontmatter checks only. The new skill will preserve the union fields `name`, `description`, `metadata.short-description`, and least-privilege `allowed-tools` without redesigning the schema.
- The complete current `tmux-agent-orchestration/SKILL.md` and `REFERENCE.md` supply the delivery behavior ledger: verify implementation commit and remote; start a clean PR branch from the runtime base rather than carrying unrelated commits; push and create the PR; do not stop at PR creation or “fix pushed”; monitor CI through all required checks green; inspect failed logs, reproduce, fix, push, and recheck; inspect mergeability before stale refresh; fetch and reconcile the latest base; review conflicts semantically and inspect silent auto-merge drift; rerun targeted and broader verification; push before claiming refreshed; and verify GitHub’s head rather than trusting local ahead/behind state. Tmux-only worker steering, panes, sessions, clone launch, and cleanup are not imported.
- Complete local history shows the tmux skill was introduced at `14d5c80cc86c440d45e84cd636aeaef310c2683d`, moved at `4fcd8db204888b46ef857ea16732bcb2e4ab201b`, and expanded at `cae720bce55e19c30c916aef320f0104c2926d59` with merge-drift, semantic-drift, pushed-head, and cleanup guidance; commit `353218e620f7261e0eedde9c62b8f9814c141830` later added plan/task wording only. The delivery source is repository-authored local material (the expansion is co-authored by Claude Sonnet 4.6), not an imported third-party corpus. `THIRD_PARTY_NOTICES.md` contains no tmux entry and needs no change; the new wording is locally synthesized from the durable route and command evidence.
- Installed Git 2.43.0 confirms named-remote fetch, immutable commit resolution, merge-base ancestry checks, explicit refspec pushes, upstream configuration, `git ls-remote --heads`, rebase/merge operation forms, and `--force-with-lease` support. Installed GitHub CLI 2.45.0 confirms `gh auth status`, explicit repository selection, `gh repo view --json nameWithOwner,defaultBranchRef`, `gh pr create --base --head`, `gh pr edit`, `gh pr view --json` including base/head names, `headRefOid`, `mergeable`, `mergeStateStatus`, `reviewDecision`, `state`, `statusCheckRollup`, and URL, `gh pr checks --required/--watch/--fail-fast`, `gh run view --log-failed`, and `gh api` REST access. This installed version does **not** support `gh pr checks --json`; the workflow will not prescribe it.
- Live probes establish failure semantics needed inline: `gh pr checks` exits 1 both when no PR exists and when a PR reports no checks, so absence must be interpreted only after successful PR discovery and runtime protection/rules inspection. General `gh` exit codes are 0 success, 1 failure, 2 cancellation, and 4 authentication failure. A classic branch-protection request may return 404 for an unprotected branch, while `GET /repos/{owner}/{repo}/rules/branches/{branch}` independently returns active applicable rules. GitHub’s primary REST documentation confirms classic `required_status_checks.strict` means the branch must be current and the branch-rules endpoint returns active repository/organization rules, including required status checks and strict-latest-code policy.

No authority conflict exists. The full workflow must discover rather than assume `origin`, `main`, head branch, base repository, protection, or checks. Because installed execution depends on GitHub CLI and GitHub PR/check APIs, a non-GitHub remote or missing/unusable `gh` is an explicit unsupported-host failure, not permission to fake delivery with `git push` alone.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/NEW-001-generic-git-delivery.md` — item-local authorization, exact new-file set, behavior ledger, evidence, verification, and worker state.
- `shared/skills/git-delivery/SKILL.md` — new independently invocable delivery owner with a complete in-process executable workflow.

These are the exact two new files authorized by revision 1. Both will be regular Markdown files with mode `100644`. No existing file is authorized to change.

## Proposed changes

### Add

- Add `shared/skills/git-delivery/SKILL.md` with union frontmatter:
  - `name: git-delivery`;
  - the evidence-supported description quoted above;
  - `metadata.short-description: Deliver pull requests through green CI`;
  - `allowed-tools: read,write,edit,bash`, used to inspect repository/requirements, make caller-authorized CI or refresh fixes, and execute Git/`gh` checks.
- Add skill-local definitions for **Delivery scope** (caller-authorized goal, commits/files, base/head, permitted state changes, and acceptance checks), **Pushed head** (one commit OID agreed by local `HEAD`, remote head, and PR `headRefOid`), **Check requirements** (repository/caller-required local checks plus active branch-protection/ruleset checks), and **Stale head** (latest fetched base is not an ancestor when freshness is required). Do not redefine composed-owner terms.
- Add one complete in-process Workflow with routing first:
  1. establish caller goal and authorization, detect new-versus-existing PR, require clean local/index state, and stop on unresolved Git operations or ambiguous/unapproved branch rewriting;
  2. discover repository host, `gh`/authentication, GitHub repository, default or explicit base, current or explicit head, exact base/head repositories and remotes, push target, active classic protection and branch rules, repository instructions, local checks, and required hosted checks without assuming `origin`/`main`;
  3. fetch named refs, pin the base OID, capture intended commit/diff scope, reject empty/unrelated/dirty scope, and compose `code-review` against that fixed point before publication;
  4. create or update the exact head branch and PR under authorization, use explicit push remote/refspec, update PR metadata only when requested, and prevent duplicate PR creation;
  5. verify local/remote/PR head OIDs after every push with bounded retries for host propagation, then inspect mergeability rather than trusting local status;
  6. monitor hosted checks to green, interpret “no checks reported” only from discovered requirements, inspect failed run logs, reproduce locally, make only delivery-scope fixes, rerun local checks and `code-review`, push, and repeat until requirements are green or an external blocker is reported;
  7. when freshness is requested or required, fetch the latest base, choose merge/rebase from repository policy and caller rewrite authorization, compose `resolving-merge-conflicts` for any in-progress conflicts, inspect silent semantic drift even after clean auto-integration, rerun checks/review, push (using an exact observed lease for rewritten history), and reverify OIDs/mergeability/checks;
  8. report exact repository/PR/base/head/OIDs, review results, checks, protection/freshness evidence, mergeability/review blockers, state changes, and residual risks. Never invoke merge/auto-merge or claim human acceptance.
- Add a hard unsupported-host/tool branch: if remotes are non-GitHub, `gh` is absent, authentication fails, repository mapping is ambiguous, or protection/check APIs cannot be inspected, stop before remote mutation and report local state, attempted discovery, exact missing capability, and safe next action. A classic-protection 404 is accepted as “no classic protection” only when repository/branch discovery succeeded; active branch rules are still queried.

### Change or move

- Relocate ownership, not existing text: use the current tmux delivery material as a behavior ledger and express it in a transport-independent, runtime-discovered workflow. No tmux file changes in NEW-001; SK-033 remains responsible for later removal and reciprocal composition.
- Generalize hard-coded `origin/main`, local clone, worker, and pane assumptions into explicit runtime base/head/push/base-fetch roles. Preserve the preference for a clean PR scope by verifying intended commits/diff and rebuilding or rewriting only with caller authorization.
- Replace “original worker stays on PR” with caller-owned editing authority and an in-process fallback: this skill itself can inspect/fix within Delivery scope; a caller may choose a worker/transport without transferring state or acceptance ownership.
- Strengthen “push completed” into three-way OID equality and “branch refreshed” into fetched-base ancestry plus remote/PR OID verification.
- Strengthen generic CI wording into discovered local, classic-protection, active-ruleset, and caller requirements; report reviews/conversation/deployment/merge-queue requirements that delivery cannot satisfy autonomously.
- Compose `code-review` after the fixed base is fetched and again whenever the delivered diff changes materially. Preserve separate Standards/Spec outputs and stop on unresolved findings outside authorized fix scope.
- Compose `resolving-merge-conflicts` only when Git reports an in-progress conflict. Preserve its intent tracing and exact commit/continue/abort authorization: stale-refresh authorization does not silently authorize a particular conflict decision or operation continuation.

### Remove

- Remove nothing from current production files. In particular, do not edit `tmux-agent-orchestration` until SK-033.
- Add no copied tmux launch/steering/monitoring/session/clone-cleanup mechanics, no hard-coded GitHub repository, remote, base, branch, check name, reviewer, or CI timeout, and no `gh pr checks --json` command unsupported by installed `gh`.
- Add no automatic merge, auto-merge enablement, branch deletion, remote mutation/repointing, stash/reset/clean, raw force push, protection bypass, unrelated cleanup, or claim of final human acceptance.

## Proposed skill shape

1. `Language Definitions` — present; four delivery-local execution terms only. Composed-owner language remains with `code-review` and `resolving-merge-conflicts`.
2. `Workflow` — present; one eight-stage GitHub delivery process with mode/authorization and unsupported-host routing first, runtime discovery, fixed-point review, publication, OID verification, CI loop, stale refresh, and final report.
3. `Activities` — omitted; every Git/`gh` operation belongs to the required delivery sequence rather than being an independently selected recipe.
4. `Reference` — omitted; the user requires a full in-process executable workflow, and the command set is compact enough to remain inline. Runtime `--help`/API discovery supplies version-specific detail without a copied manual.

## Behavior-preservation checklist

- [x] The new description independently triggers opening/updating PRs, CI-to-green, stale refresh, and pushed-head verification without mentioning tmux.
- [x] Caller goal, authorized commit/file scope, base/head intent, permitted push/PR/rewrite/fix state changes, deadline, and acceptance checks are recorded before mutation; missing consequential authorization stops for clarification.
- [x] Existing PR versus new PR is discovered successfully; command/auth/network failure is not misclassified as “no PR,” and duplicate PR creation is prevented.
- [x] Local branch/index/worktree and active Git operation are inspected; dirty state, uncommitted delivery changes, or unrelated changes stop without stash/reset/clean.
- [x] Repository host, GitHub repository, explicit/default base, head, base/head repositories, fetch/push remotes, branch upstream, remote URLs, and exact OIDs are runtime-discovered without assuming `origin` or `main`.
- [x] Missing/unusable `gh`, auth failure, non-GitHub remotes, ambiguous repository/remote mapping, or inaccessible protection/check evidence stops before remote mutation with exact failure reporting.
- [x] Repository guidance, caller checks, classic branch protection, and active branch rules are inspected; classic 404 is not treated as proof that no ruleset applies.
- [x] Check requirements and strict freshness are recorded before publication; human review, conversation, deployment, queue, or permission requirements remain reported external gates rather than silently bypassed.
- [x] Base and head are fetched and pinned; intended commits and resulting diff are non-empty, clean, and free of unrelated history/files before publication.
- [x] `code-review` runs against the immutable fetched base OID with independent Standards/Spec outputs before first publication and after material diff changes.
- [x] Review findings are resolved only within authorized scope; out-of-scope findings stop and return to the caller rather than being waived by delivery.
- [x] Push uses the explicitly selected GitHub remote and exact `HEAD:refs/heads/<head>` refspec; a new upstream is set only when appropriate and authorized.
- [x] PR creation uses explicit repository/base/head/title/body inputs, while existing PR metadata changes occur only when requested; the resulting PR identity and URL are captured.
- [x] After every push, local `HEAD`, `git ls-remote --heads` result, and `gh pr view ... headRefOid` converge before any pushed/refreshed claim.
- [x] Mergeability and merge-state evidence are inspected after OID convergence; unknown/temporarily stale host state is retried within the caller’s bound and otherwise reported.
- [x] CI does not stop at PR creation or “fix pushed”; discovered checks are watched, failures are traced to logs/details, reproduced locally where possible, fixed within Delivery scope, locally verified/reviewed, pushed, and rechecked.
- [x] “No checks reported” is success only when successful protection/rules/repository discovery proves no check requirement and no caller-required hosted check is expected; otherwise it is a blocker.
- [x] Every CI fix preserves the intended goal and excludes unrelated cleanup; external/flaky/permission/secret/infrastructure failures are evidenced and reported rather than guessed around.
- [x] Staleness is checked against the latest fetched base and host mergeability evidence; refresh occurs when caller/repository/protection policy requires it, not merely from a hard-coded assumption.
- [x] Refresh method follows repository history policy and caller rewrite authorization; raw `--force` is forbidden and rewritten history uses `--force-with-lease=<ref>:<observed-remote-oid>`.
- [x] Any in-progress conflict composes `resolving-merge-conflicts`; dual intent and exact continuation authorization remain with that owner. No delivery instruction chooses ours/theirs or silently continues/aborts.
- [x] Clean auto-integration is still inspected for semantic drift across the complete fixed-point diff and relevant neighboring behavior.
- [x] A refreshed branch reruns applicable local checks, fixed-point `code-review`, OID convergence, mergeability inspection, and hosted checks before completion.
- [x] Final reporting contains repository and PR URL/number, base/head names and repositories, fixed base/local/remote/PR OIDs, commit/diff scope, Standards/Spec outcomes, local/hosted checks, protection/freshness evidence, mergeability/review state, changes pushed, failures/limitations, and next owner.
- [x] The skill never merges, enables auto-merge, deletes branches, claims human acceptance, or changes caller ownership.
- [x] Tmux remains untouched; transport can compose this process later but does not own its state, authorization, acceptance, or fallback.
- [x] No third-party notice is invented; local source history and absence of imported material are recorded.
- [x] Existing union frontmatter is valid, the body has canonical sections only, and all grants are used.
- [x] VG-001 visibility exclusion is explicit: NEW-001 does not add `pi/skills/git-delivery`, edit deployment/discovery, or claim Pi visibility; final visibility is deferred to VG-001.

## Dependencies, provenance, and risks

- SK-001, SK-014, and SK-024 are verified at the claim baseline. NEW-001 consumes their final interfaces and does not alter them. SK-033 is downstream and remains the only item authorized to edit tmux delivery duplication after this owner integrates.
- The workflow is intentionally GitHub-backed because the only installed PR/CI client evidenced here is `gh`, and its commands operate on GitHub repositories. “Generic” means transport-independent and repository-runtime-discovered, not host-provider-independent. Non-GitHub delivery reports an unsupported capability rather than partially pushing and falsely claiming PR/CI completion.
- Classic protection and rulesets can coexist. A 404 from classic protection means only that the classic endpoint did not return protection; the active-rules endpoint and repository guidance still determine requirements. API permission/network failure is not equivalent to no requirements.
- GitHub state is eventually consistent. OID and mergeability checks use bounded retries controlled by the caller’s deadline; failure to converge is reported, not hidden by indefinite polling.
- Existing material says “clean branch from origin/main plus cherry-pick.” The durable intent is a clean, unrelated-commit-free PR scope. This proposal preserves it by proving commit/diff scope against a runtime base and permitting branch reconstruction/cherry-pick only when caller-authorized, rather than hard-coding `origin/main` or rewriting an existing PR unexpectedly.
- A rebase rewrites published history and a merge may violate linear-history rules. The workflow discovers policy and caller authorization before choosing. Exact leases prevent overwriting a concurrently changed remote head; lease failure returns to discovery rather than escalating to raw force.
- `gh pr checks` 2.45.0 has no JSON output and exits 1 for both no checks and other failures. The workflow pairs it with `gh pr view --json statusCheckRollup`, successful protection/rules discovery, and captured stderr rather than relying on one exit code.
- Protection may require reviews, deployments, resolved conversations, signed commits, or merge queues. Delivery reports these states but does not fabricate approval or merge authority. CI-to-green is complete only for discovered check requirements; external non-check merge gates remain explicit.
- Source material is locally authored in this repository and no external license applies to the new synthesis. Existing notices remain unchanged. No provenance, license, or attribution is moved or removed.
- Semantic YAGNI governs. The inline workflow is necessarily substantial because premature completion can mutate remote state or falsely report green delivery; it adds no host abstraction, helper script, reference manual, or merge feature without evidence.

## Verification

1. Reread complete `shared/skills/git-delivery/SKILL.md` and map every checked behavior above to one inline location or named composed owner.
2. Parse headings; expect exactly `Language Definitions` then `Workflow`, in that order, with no `Activities`, `Reference`, Quick Start, checklist, or unapproved level-two section.
3. Parse frontmatter with a YAML-aware parser; expect exact `name`, evidence-supported description containing `Use when`, short description, and `read,write,edit,bash`. Confirm the directory is lowercase hyphenated and description is under 1024 characters.
4. Inspect routing: caller authorization and new/update mode precede mutation; missing `gh`, failed auth, non-GitHub remote, ambiguous remote/repository, dirty state, unresolved operation, and unavailable protection/check evidence each have a before-mutation stop and report contract.
5. Inspect discovery: no `origin`/`main` assumption; explicit base/head repositories, branches, remotes, upstreams, OIDs, classic protection, active branch rules, repo/caller checks, freshness, and external gates are recorded.
6. Inspect scope/review: fetched immutable base, non-empty intended commits/diff, unrelated-change rejection, and composed `code-review` before publication and after material changes. Confirm Standards/Spec remain separate.
7. Inspect publication/OID verification: explicit remote/refspec, duplicate-PR prevention, requested-only metadata edits, three-way local/remote/PR OID convergence, bounded propagation handling, and mergeability evidence.
8. Inspect CI loop against installed `gh` 2.45.0 help: no unsupported `gh pr checks --json`; `--watch`, `--fail-fast`, `--required`, `gh pr view --json statusCheckRollup`, and `gh run view --log-failed` are used with correct qualification. Confirm no-check exit 1 is disambiguated by prior discovery.
9. Inspect stale refresh against installed Git 2.43.0 help: named fetch, latest base OID, ancestry check, policy/authorization-selected merge or rebase, exact lease on rewritten history, no raw force, and post-refresh review/check/OID repetition.
10. Inspect composition: `resolving-merge-conflicts` is invoked only for in-progress conflicts and retains dual-intent plus continuation authorization; `code-review` retains fixed-point axis ownership; caller retains goal, state, authorization, and acceptance; no tmux mechanics are copied.
11. Exercise read-only command discovery in this checkout: verify GitHub repository/default branch, named remotes, branch and OIDs, active rules/classic protection behavior, existing-PR lookup result, `gh pr view` JSON fields, and `gh pr checks` no-PR/no-check behavior. Do not push, create/edit/merge a PR, or mutate remotes during migration verification.
12. Run a temporary bare-remote probe for explicit `HEAD:refs/heads/<head>`, `git ls-remote --heads`, ancestry detection, concurrent remote update, and exact `--force-with-lease=<ref>:<oid>` rejection/acceptance. Acceptance: OIDs converge after normal push, stale ancestry is detected, stale lease rejects, current lease accepts. No live repository mutation.
13. Run the complete YAML-aware `audit-shared-skills` workflow. Acceptance: all 34 result skills are parsed/accounted for with zero errors and warnings, including least-privilege grant review.
14. Resolve every Markdown link from the new skill directory; expect none. Confirm the directory contains only `SKILL.md` and no script/reference/asset.
15. Recheck tmux history and `THIRD_PARTY_NOTICES.md`; expect local source commits recorded above, no imported tmux corpus, and no notice diff.
16. Run `git diff --check -- .skill-migration/shared-skill-yagni/proposals/NEW-001-generic-git-delivery.md shared/skills/git-delivery/SKILL.md` and `bash tests/run.sh`.
17. Compare baseline-aware tracked/untracked paths and modes. Acceptance: exactly the proposal and new `SKILL.md`, both mode `100644`; no edit in `MIGRATION.md`, `.wayfinder`, `pi/settings.json`, specs, notices, AGENTS, tests, deployment, discovery, agent configs, visibility symlinks, tmux skill/support, composed owner skills, or unrelated proposals.
18. Confirm `pi/skills/git-delivery` does not exist and record that this is the standing NEW-001 visibility exclusion, not a missing NEW-001 production file. VG-001 owns final catalog visibility verification.

Acceptance requires exact two-new-file scope, canonical two-section shape, valid union frontmatter, a full transport-independent in-process workflow, runtime-discovered host/base/head/remote/protection/check requirements, caller authorization and clean scope, fixed-point Standards/Spec review, conflict-intent composition, explicit push and three-way OID verification, CI-to-green loop, safe stale refresh, mergeability/check reporting, unsupported-host/tool failure reporting, no automatic merge, no tmux edit, no Pi visibility change, clean catalog audit, clean diff, and passing repository tests.

## Explicit exclusions

- No edit to `.skill-migration/shared-skill-yagni/MIGRATION.md`, `.wayfinder/`, `pi/settings.json`, any spec/glossary, `THIRD_PARTY_NOTICES.md`, AGENTS, tests, install/deployment/discovery files, agent configs, any Pi visibility symlink, another skill/support file, or another proposal.
- No edit to `shared/skills/tmux-agent-orchestration/SKILL.md` or `REFERENCE.md`; SK-033 owns downstream consolidation after NEW-001 exists.
- No edit to `code-review` or `resolving-merge-conflicts`; composition uses their verified interfaces without transferring ownership.
- No `pi/skills/git-delivery` symlink. This standing visibility exclusion is deliberate for NEW-001 and remains a VG-001 responsibility.
- No frontmatter redesign, host-provider abstraction, GitLab/Bitbucket client, helper script, Reference file, fixed branch/remote/check names, or fixed line target.
- No automatic merge, `gh pr merge`, auto-merge enablement, branch deletion, remote URL mutation, protection bypass, raw force push, stash/reset/clean, unrelated cleanup, or claim of human acceptance.
- No live PR creation/update/push during migration verification, no persisted live Herdr/workspace/tab/pane ID, no central integration, coordinator verification, SK-033 completion, or VG-001 completion claim.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization effect: the standing directive removes the per-item approval wait but authorizes only the exact two new regular files and changes enumerated in revision 1.
- Scope check: `PASS — revision 1 reread MAP → WF-007 NEW/D6 row and durable route → WF-006 independently invocable split, ownership matrix, composition boundaries, and contradictions → WF-008 relevant code-review/resolving-merge-conflicts definitions → current specs → verified write-a-skill/code-review/resolving-merge-conflicts/audit-shared-skills → complete tmux delivery source and history → provenance/notices → installed Git 2.43.0 and gh 2.45.0 help, live read-only probes, and primary command/API source semantics in the mandated order. The exact file set is two new mode-100644 Markdown files. Name/description, full behavior ledger, caller authorization, clean scope, runtime discovery, protection/rules/check handling, fixed-point review, conflict composition, publication/OID proof, CI loop, stale refresh, unsupported-host failures, no-merge guard, provenance, exclusions, visibility deferral, and verification are fixed. No authority conflict or material scope gap remains; production editing may continue without a per-item approval wait.`

## Worker implementation and verification record

- Timestamp: `2026-07-14T18:38:35Z`.
- Worker state: `ready-to-integrate`. This is worker evidence only; it is not coordinator verification, integration, or acceptance.
- Fixed review scope: baseline `c27ceed555233d037cc143321fcfc728475fdadd`, immutable candidate `ff765d73827f73dc454097408d368bc9ef45cdfc`, and stable range `c27ceed555233d037cc143321fcfc728475fdadd...ff765d73827f73dc454097408d368bc9ef45cdfc`. The candidate has one commit, exactly the proposal and `shared/skills/git-delivery/SKILL.md`, and 320 insertions. The reviewed skill content is unchanged after review and has SHA-256 `14da63e191e2b128d7e42845739039a249cb09bb1029f48098450dfdf53639ef`; only this proposal's lifecycle/checklist/verification record was added afterward.
- Review transport correction: the initial Herdr-backed attempt to create parallel read-only review panes conflicted with the coordinator's topology contract permitting only the coordinator and two labelled worker Pi agents. The coordinator closed those extra panes and directed that no more agents or panes be created, split, or moved. No live Herdr ID was persisted. The required reviews were then completed as two explicitly separate in-process passes over the fixed candidate.
- Standards axis: `PASS`, 0 findings, worst issue none. Both changed files were considered against `AGENTS.md`, `specs/ai-agent-config.md`, `specs/UBIQUITOUS_LANGUAGE.md`, verified `write-a-skill`, and revision-1 scope/body/verification rules.
- Spec axis: `PASS`, 0 findings, worst issue none. Both changed files were independently considered against the user directive, WF-007 D6, WF-006 ownership/composition boundaries, WF-008 owner definitions, revision 1, and the verified `code-review` and `resolving-merge-conflicts` contracts. Neither axis waived or reranked the other.
- Behavior and structure: all 29 preservation entries map to inline stages 1–8 or the named composed owner; exact headings are `Language Definitions` then `Workflow`; all eight stages have observable completion criteria; frontmatter is YAML-parseable with all union fields, a 232-character `Use when` description, and used `read,write,edit,bash` grants; the skill has no links and its directory contains only `SKILL.md`.
- Verification: complete catalog audit discovered and parsed 34 skills with 0 errors and 0 warnings; `git diff --check` passed; `bash tests/run.sh` passed both shell files and all 12 tests; exact scope and tree modes were the two authorized additions at `100644`; protected paths remained unchanged; and `pi/skills/git-delivery` remained absent under the VG-001 exclusion.
- Probes: installed Git 2.43.0 and GitHub CLI 2.45.0 help and read-only GitHub discovery matched the workflow; no live remote mutation occurred. The removed temporary bare-remote probe proved explicit refspec/OID convergence, stale ancestry detection, stale exact-lease rejection, and current exact-lease acceptance.
- Residual risks: GitHub API permissions, eventual consistency, host policy, and installed-client variation can still block a real invocation, so the skill requires runtime discovery and evidenced safe failure. Live PR creation/update and hosted CI mutation were deliberately not exercised. Pi visibility remains deferred to VG-001 and tmux consolidation remains deferred to SK-033.

Coordinator integration verification completed at `2026-07-14T18:44:35+00:00` against integrated commit `cf0c7d7`: the complete new skill and proposal were reread; exact two-file/mode scope, union frontmatter, definitions, eight completion-gated stages, caller authorization, clean-state and unsupported-host stops, runtime topology/protection/rules/check discovery, fixed-point review composition, duplicate-safe explicit publication, three-way OID proof, CI-to-green loop, stale refresh/exact lease/conflict composition, no-merge report, local provenance, and exclusions passed independent checks. Installed Git 2.43.0 and GitHub CLI 2.45.0 command surfaces matched the workflow; a separate temporary bare-remote probe proved explicit-ref OID convergence, stale exact-lease rejection, and current exact-lease acceptance without live remote mutation. The YAML-aware audit parsed/accounted for all 34 skills with zero errors and one unrelated deferred SK-027 grant warning, `git diff --check` passed, and `bash tests/run.sh` passed all 12 tests. The protected `pi/settings.json` content and diff hashes remained `7d3f4713d7239e8cda3f75597a55f1767fecdf7964324630e4e74dc686d12e05` and `8298a9063e3ebf2988000d176057a41c31cf20c10bbabe92fb57d47f9f2738d5`. Residual risks remain unexercised live PR/hosted-CI mutation, host/API/client variability, and the standing absence of Pi visibility pending final reconciliation.

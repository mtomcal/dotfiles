---
id: SK-006
target: ralph
status: ready-to-integrate
revision: 1
blocked-by: [SK-001]
source-verdict: simplify inline
baseline: 45e284f478615f3e772982774e06218de891a1c1
---

# Ralph: make the bounded fresh-agent loop executable and failure-aware

## Why this item is next

SK-001 is verified and the coordinator claimed SK-006 from baseline `45e284f478615f3e772982774e06218de891a1c1`. WF-007 places Ralph in correctness-before-movement: its compact body may be normalized only after the runner and instructions agree on the 25-iteration default, exact done sentinel, failure stop, per-iteration commit evidence, dangerous-sandbox approval, executable setup, and optional orchestrator behavior. Its files do not overlap the concurrently claimed SK-005 scope.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` and WF-007 — verdict `simplify inline`; preserve the Ralph artifacts and course-correction model while repairing the runner before simplification.
- WF-004 `ralph` record — complete behavior ledger covering the three-artifact concept, one-item fresh iterations, repeated prompt reads, Ralph job plan updates, logs, sandbox selection, test-quality routing, course corrections, commit intent, and `/done` completion; it identifies the current runner contradictions.
- WF-008 — human-confirmed Ralph job, worker iteration, Ralph job plan, orchestrator, course correction, and done sentinel definitions. A Ralph job plan is not a repository plan workspace.
- WF-006 — Ralph owns its job plan and must remain separate from `create-plan`; the runner's unlimited default, substring sentinel, continued failures, unenforced commits, unsafe dangerous sandbox, and missing executable setup must be repaired before text moves.
- `specs/parameters.md` version `1.6.0` — authoritative `RALPH_DEFAULT_ITERATIONS=25` and `RALPH_DONE_PATTERN=/done`.
- `specs/ai-agent-config.md` version `2.3.0` and `specs/UBIQUITOUS_LANGUAGE.md` version `0.7.0` — canonical body sections, colocated failure/approval/output/completion rules, behavior preservation, and non-interchangeable Ralph job plan ownership.
- Verified `shared/skills/write-a-skill/SKILL.md` — requires one earned Workflow, semantic YAGNI, a behavior-preservation ledger, executable main-path support, and exact scope verification.
- Current `shared/skills/ralph/SKILL.md` and `references/loop.sh` — advertise `PROMPT.md`, `IMPLEMENTATION_PLAN.md`, and `ORCHESTRATOR.md`; the support script is mode `100644`, defaults to unlimited iterations, accepts non-numeric/unbounded input, matches `/done` as a substring anywhere in combined output, continues after Codex failure, and records no commit evidence.
- Installed `codex-cli 0.144.1` — `codex exec --help` confirms stdin prompts (`-`), `--sandbox` values `read-only`, `workspace-write`, and `danger-full-access`, `-C/--cd`, and `-o/--output-last-message`; the installed parser also accepts the existing `--full-auto` compatibility flag. The revised runner uses `-o` so only the worker's final response can satisfy the exact sentinel.
- Git provenance — Ralph and its runner were introduced locally by `dfd67d2db28e59cc86463f54592cf5c1a4ed04c2` and moved to shared skills by `4fcd8db204888b46ef857ea16732bcb2e4ab201b`; blame attributes the runner entirely to the local introduction. No repository evidence identifies imported material or a third-party license. `THIRD_PARTY_NOTICES.md` has no Ralph entry and requires no change.
- `shared/skills/test-quality-verifier/SKILL.md` — remains the named owner for the test-quality audit routed after test changes; Ralph will use a portable skill name rather than claim that audit behavior.

No consequential authority conflict remains. WF-004 suggested removing `ORCHESTRATOR.md` from the required default set unless a concrete contract is retained; WF-008 subsequently confirmed the orchestrator as optional, and the user requires honest optional behavior. Revision 1 therefore keeps `ORCHESTRATOR.md` only as an optional playbook for a separately started monitor and states that neither this skill nor `loop.sh` supplies or launches that monitor.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-006-ralph.md` — item-local authorization, scope review, behavior ledger, and verification record.
- `shared/skills/ralph/SKILL.md` — replace the three ad hoc body headings with confirmed definitions and one bounded job Workflow; clarify the optional orchestrator and runner setup.
- `shared/skills/ralph/references/loop.sh` — repair defaults, validation, failure behavior, exact completion detection, commit evidence, logging, and executable mode.

These three paths are the complete revision 1 allowed file set. The runner is required because body-only prose cannot correct executable behavior.

## Proposed changes

### Add

1. Add `Language Definitions` containing the six WF-008-confirmed terms and explicitly distinguish the Ralph job plan from the repository plan workspace.
2. Add one ordered `Workflow` covering applicability, artifact setup, executable runner installation, bounded launch, monitoring/course correction, failure recovery, completion evidence, and cleanup.
3. Make `PROMPT.md` require one checklist item per worker iteration, rereading and updating the Ralph job plan, relevant tests, the `test-quality-verifier` workflow after test changes, at least one descendant commit, and exact `/done` only after the complete plan and evidence are current.
4. Keep `ORCHESTRATOR.md` as an optional monitoring playbook. If created, it must direct a separately launched monitor to inspect `.loop-logs` and Git, prepend `IMPORTANT:` course corrections to `PROMPT.md`, avoid doing the worker item, and stop when the runner exits. State explicitly that the runner does not read this file and no orchestrator executable/template is supplied.
5. Add executable setup using the invoking agent's resolved Ralph skill directory: `install -m 0755 "$RALPH_SKILL_DIR/references/loop.sh" ./loop.sh`; require inspection/approval before replacing an existing project runner.
6. Default omitted iteration count to `25`; accept only a positive decimal bound and no more than two positional arguments. Validate the prompt file, Codex, Git repository/HEAD, and one of the three installed sandbox modes before creating logs or running Codex.
7. Gate `SANDBOX_MODE=danger-full-access` on explicit human approval represented by `RALPH_DANGER_FULL_ACCESS_APPROVED=1`; the skill must tell the human what access is requested before that variable is set. `workspace-write` remains the default and `read-only` remains selectable.
8. Capture each iteration's combined output in `.loop-logs/iteration-N.log` and its final worker response in `.loop-logs/iteration-N.last-message.md` through installed `codex exec -o` support.
9. Stop immediately and non-zero on Codex or logging failure. Preserve the failing log and require diagnosis/course correction before an explicit rerun; never advance automatically after failure.
10. Capture `HEAD` before and after every successful Codex execution. Require the old head to be an ancestor of a changed head, record commit count/hash/subject in the iteration log, and stop non-zero if no descendant commit exists. This is enforceable commit evidence, not proof of commit quality.
11. Treat completion as exact final-response equality with `/done` (allowing only trailing newlines removed by shell command substitution), after successful execution and commit evidence. Substrings, explanatory text, and `/done` elsewhere in combined logs cannot complete the job.
12. Exit non-zero when all bounded iterations finish without the exact sentinel. Final human/agent review must inspect the Ralph job plan, every iteration log and commit range, test/test-quality evidence, and final Git state before accepting completion.
13. Retain `.loop-logs` on success, bound exhaustion, or failure. Stop any separately launched monitor when the runner exits; remove logs or the copied runner only as an explicit cleanup action.

### Change or move

1. Change the frontmatter description only to say `ORCHESTRATOR.md` monitoring is optional; preserve the setup/launch triggers, name, short description, and existing union-schema fields/tools.
2. Move `PROMPT.md`, `IMPLEMENTATION_PLAN.md`, and `ORCHESTRATOR.md` descriptions into artifact setup. Keep the prompt concise (about 20 lines), require its opening to route to `IMPLEMENTATION_PLAN.md`, and keep `IMPORTANT:` course corrections at the top where every fresh iteration reads them.
3. Replace the current launch sentence with the resolved-path install command and `./loop.sh [max_iterations] [prompt_file]`; omitted values are exactly `25` and `PROMPT.md`.
4. Keep one fresh `codex exec` process per iteration, stdin prompt rereading, current working directory, `--full-auto`, selectable sandbox, `.loop-logs`, and `tee`; strengthen their validation and evidence contracts.
5. Route test-quality review to the shared `test-quality-verifier` skill after test changes without importing its workflow or assuming a harness-specific role invocation.
6. Keep course corrections as prompt input for the next fresh iteration or an explicit rerun after failure. The Ralph job plan remains the worker-owned mutable checklist/discovery state; the optional monitor may observe it but does not become its writer.

### Remove

1. Remove the three noncanonical level-two headings (`Files`, `Launch`, and `PROMPT.md Rules of Thumb`) only after all behavior is retained under the single Workflow.
2. Remove unlimited iteration behavior and the `0` sentinel for no bound. Every run is bounded; the default is 25.
3. Remove substring matching against combined logs. Only the complete final-message file may equal `/done`.
4. Remove automatic continuation after non-zero Codex exit, logging failure, missing commit evidence, rewritten/non-descendant history, invalid arguments, or bound exhaustion.
5. Remove the implication that `ORCHESTRATOR.md` is a required artifact or that Ralph supplies/launches an orchestrator process.
6. Remove no setup/launch trigger, artifact, one-item rule, fresh-agent boundary, prompt reread, plan update, discovery record, log, sandbox choice, test-quality route, course correction, commit requirement, completion sentinel, failure evidence, or cleanup contract.

## Proposed skill shape

1. `Language Definitions` — present and mandatory; Ralph job, worker iteration, Ralph job plan, orchestrator, course correction, and exact done sentinel.
2. `Workflow` — present; one bounded fresh-agent job process with setup, launch, monitoring/recovery, completion, and cleanup.
3. `Activities` — omitted; launch and course correction are governing steps of the one job Workflow, not independently selected recipes.
4. `Reference` — omitted; `references/loop.sh` is required executable support linked beside setup, not conditionally loaded Markdown.

## Behavior-preservation checklist

- [x] Frontmatter retains the configure/launch triggers, name, short description, and existing union-schema/tools; only the required-versus-optional orchestrator wording changes.
- [x] `PROMPT.md`, the Ralph job plan at `IMPLEMENTATION_PLAN.md`, and optional `ORCHESTRATOR.md` all remain named with their distinct roles.
- [x] Ralph job plan ownership remains separate from the repository plan workspace and `create-plan` lifecycle.
- [x] Every worker iteration is a fresh Codex execution that rereads the prompt, performs one checklist item, updates progress/discoveries, commits, and exits.
- [x] The prompt stays concise, routes to the plan first, and places `IMPORTANT:` course corrections at the top for every iteration.
- [x] Relevant tests and the shared test-quality workflow after test changes remain required and become part of recorded completion evidence.
- [x] The generic runner remains directly linked beside executable setup and is copied with executable permission.
- [x] The authoritative default is exactly 25 iterations; custom runs remain positively bounded.
- [x] `workspace-write`, `read-only`, and `danger-full-access` remain selectable; dangerous full access now requires explicit human approval.
- [x] Per-iteration combined logs remain under `.loop-logs`; final worker messages and commit ranges add stronger evidence.
- [x] Non-zero Codex/logging status, invalid input/environment, absent or non-descendant commit, and exhausted bounds all stop non-zero without advancing.
- [x] At least one descendant commit is enforced and recorded for every successful worker iteration, including the iteration emitting completion.
- [x] Only a final response exactly equal to `/done` completes the job; substring and mixed-text matches do not.
- [x] Optional monitoring, log/Git inspection, course corrections, and the rule that the monitor does not perform the worker item remain honest and reachable.
- [x] Final plan/Git/test/log review and explicit monitor/log/runner cleanup contracts remain inline.
- [x] Local Git provenance remains accurately recorded in this proposal; no unsupported third-party provenance or license is invented.
- [x] No spec, notice, deployment, visibility link, README/catalog entry, unrelated skill/proposal, or migration ledger changes.

## Dependencies, contradiction repairs, provenance, and risks

- SK-001 is verified and supplies the authoring contract. Ralph retains ownership of its job plan; no `create-plan` state or transition is imported.
- The parameter contradiction is repaired in executable code: omitted bounds become 25 and unlimited/zero bounds are rejected.
- The sentinel contradiction is repaired using Codex's supported last-message output rather than grepping the mixed transcript. Sentinel checking occurs only after process and commit checks pass.
- The failure contradiction is repaired by immediate non-zero exits with retained logs and explicit rerun after diagnosis/correction.
- The commit contradiction is repaired by descendant-HEAD evidence in every iteration plus prompt and final-review requirements. Risk: a HEAD change proves commits occurred, not that the correct actor authored them or that they contain exactly one checklist item; log/plan/diff review remains required.
- Dangerous sandbox selection is capability gating, not a security boundary: an automated caller could forge the approval variable. The inline contract requires a human decision for the current job before setting it and defaults to `workspace-write`.
- The optional orchestrator claim is honest but intentionally does not create a monitor implementation. `ORCHESTRATOR.md` is useful only when a human separately starts a process to consume it; without one, the runner and operator inspect logs/Git directly.
- Course corrections made during an active iteration affect only a later prompt read; after any stopped failure they affect an explicit rerun. Concurrent prompt/Git mutation can race with a worker, so the monitor is constrained to corrections and final evidence requires commit/diff inspection.
- Local history identifies no imported Ralph text or runner and no required third-party license. `THIRD_PARTY_NOTICES.md` remains unchanged.
- `--full-auto` is retained for behavior compatibility and accepted by installed Codex even though current `codex exec --help` omits the compatibility alias. Installed help directly confirms every other runner option used. This alias is a residual version-skew risk to recheck at catalog verification.

## Verification

- `bash -n shared/skills/ralph/references/loop.sh` — runner syntax passes.
- Run an isolated temporary Git-repository harness with a fake `codex` executable and copied runner. Assert: omitted bound is reported as 25; malformed/zero/extra arguments fail before Codex; missing prompt/Git/Codex fail; invalid sandbox fails; dangerous sandbox fails without approval and reaches Codex only with approval; a non-zero Codex status invokes it once and returns non-zero; no-commit and non-descendant-history iterations fail; substring/mixed `/done` responses do not complete; exact final `/done` completes only after descendant commit evidence; and exhausting the bound returns non-zero after exactly the bound.
- Confirm the harness's successful two-iteration case creates two combined logs, two last-message files, and commit evidence for each iteration. Confirm failure logs remain available and no later iteration starts.
- `codex --version; codex exec --help` plus parser-only `codex exec --full-auto --help` — installed CLI supports stdin, sandbox values, `-C`, `-o`, and the retained compatibility flag without launching an agent.
- Parse frontmatter: existing union fields remain; only `description` changes, still includes `Use when` and remains under 1024 characters.
- Inspect level-two headings and assert they are exactly `Language Definitions` then `Workflow`; `Activities` and `Reference` are absent.
- Validate the local `references/loop.sh` Markdown link, executable mode `100755`, and resolved-path `install -m 0755` setup.
- Compare the complete resulting skill and runner against the WF-004 ledger and every checked behavior above. Search for stale unlimited defaults, substring `grep`, failure continuation, required-orchestrator claims, and unapproved dangerous mode; acceptance requires none.
- Run the repository `audit-shared-skills` workflow under the existing union schema; expect no target error or warning.
- Verify `pi/skills/ralph` remains the existing symlink to `../../shared/skills/ralph` without editing it.
- Recheck Git history/blame and `THIRD_PARTY_NOTICES.md`; acceptance: local provenance remains supported and the notice has no diff.
- `git diff --check -- .skill-migration/shared-skill-yagni/proposals/SK-006-ralph.md shared/skills/ralph/SKILL.md shared/skills/ralph/references/loop.sh` — no whitespace errors.
- `bash tests/run.sh` — repository regression checks pass.
- Compare changed paths from baseline plus untracked files; only the exact three authorized paths may differ. Confirm no diff in `pi/settings.json`, specs/glossary, notices, README/AGENTS, deployment, visibility, unrelated skills/proposals, or `MIGRATION.md`.

Acceptance requires exact three-file scope, canonical two-section body, all behavior-ledger checks, syntax and isolated runner cases passing, mode `100755`, installed Codex option compatibility, existing union frontmatter validity, unchanged provenance/visibility/forbidden scope, and no unresolved authority conflict.

## Implementation record

Focused verification completed: `2026-07-14T16:32:46+00:00`

- Actual production diff: `shared/skills/ralph/SKILL.md` has 60 insertions and 15 removals; `shared/skills/ralph/references/loop.sh` has 82 insertions and 25 removals plus mode `100644 => 100755`. This proposal is the only additional item-local file.
- Resulting SHA-256: skill `ac99490cdce24b87c4377521bc91ec892504d49fedffda1efbf0970f3eb4ff05`; runner `8c1f39a4239af264a64a151b6b8862d7aa0e5022f35b8a9bbbd6a993e8cfce72`.
- Pre-edit RED evidence: the baseline continued through two Codex failures and returned zero, and accepted a `/done` substring after one iteration; both focused expectations failed for the intended reasons.
- Isolated fake-Codex runner harness: PASS, 15 cases. It covered default 25, zero/text/extra arguments, invalid sandbox, dangerous mode with and without approval, immediate Codex failure stop, missing commit, rewritten history, substring versus exact sentinel over two committed iterations, bound exhaustion, missing prompt, missing Codex, and missing Git. The successful two-iteration case retained both log/final-message pairs and per-iteration commit evidence.
- Runner syntax and executable support: `bash -n` PASS; mode `100755` PASS; `shellcheck` was unavailable and is recorded as a residual tool gap rather than silently claimed.
- Installed `codex-cli 0.144.1` help/parser checks: stdin, all three sandbox values, `-C`, `--output-last-message`, and retained `--full-auto` parser compatibility PASS without launching an agent.
- Complete-file reread and WF-004/WF-008 behavior-ledger comparison: PASS. The exact 25 default, exact final-message sentinel, immediate failure stop, descendant commit evidence, human dangerous-mode gate, executable install, bounded fresh workers, all three named artifacts, course corrections, test-quality routing, completion review, and cleanup contracts remain inline.
- Optional orchestrator honesty: PASS. The body keeps `ORCHESTRATOR.md` as an optional playbook, requires a separately started monitor, denies it worker/job-plan ownership, and states that neither the skill nor runner launches or reads it.
- Read-only semantics: PASS with explicit limitation. The selectable mode is retained for diagnostic execution and is documented as unable to satisfy the mandatory update/commit gate.
- Canonical body shape: exactly `Language Definitions` then one `Workflow`; no unearned `Activities` or `Reference`. The required shell support remains linked beside executable setup.
- Existing union-frontmatter audit: 33 skills, 0 findings; the changed 194-character description retains `Use when`, and the other fields remain unchanged.
- `bash tests/run.sh`: PASS (2 shell test files; 12 tests).
- Pi visibility, local Git provenance, absent Ralph third-party notice, relative runner link, stale-contract scans, `git diff --check`, exact changed-path scope, and forbidden-scope diff: PASS.
- Residual risk: `--full-auto` remains an installed accepted compatibility alias but is omitted from current `codex exec --help`; a later CLI may remove it. Catalog verification should recheck this option before changing the runner.
- Residual risk: descendant `HEAD` proves commits occurred, not actor identity, single-item scope, or commit quality. The Workflow therefore requires plan/log/diff/test review before accepting `/done`.
- Residual risk: the dangerous-mode environment variable records approval but is not a security boundary; the Workflow requires an explicit current-job human decision before setting it.

## Explicit exclusions

- No edit to `.skill-migration/shared-skill-yagni/MIGRATION.md` or any other migration proposal.
- No edit to `pi/settings.json`, specs/glossary, `THIRD_PARTY_NOTICES.md`, README, AGENTS.md, installer/deployment files, agent configs, or visibility symlinks.
- No edit to `test-quality-verifier`, `create-plan`, another skill, or another skill's support files.
- No new `ORCHESTRATOR.md` template, monitor executable, daemon, test fixture, dependency, skill, provenance entry, or license text.
- No frontmatter schema, `allowed-tools`, harness-grant, discovery, or portability redesign.
- No unbounded mode, automatic retry/continuation, sandbox bypass, acceptance of dirty commit quality, or claim that runner evidence replaces final human/agent review.
- No claim on any migration item other than SK-006.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization effect: the standing directive removes the per-item approval wait but authorizes only the three exact paths and changes enumerated in revision 1.
- Scope check: `PASS` — ledger-order authorities, exact three-file scope, complete behavior ledger, 25-iteration default, exact sentinel, failure stop, descendant commit evidence, dangerous-sandbox approval, executable setup, optional orchestrator contract, installed Codex help/source, local provenance, verification plan, and exclusions were reviewed against revision 1; production editing may proceed without a per-item approval wait.

---
id: SK-006
target: ralph
status: verified
revision: 2
blocked-by: [SK-001]
source-verdict: simplify inline
baseline: 45e284f478615f3e772982774e06218de891a1c1
---

# Ralph: make the bounded fresh-agent loop executable and failure-aware

## Why this item is next

SK-001 is verified and the coordinator claimed SK-006 from baseline `45e284f478615f3e772982774e06218de891a1c1`. WF-007 places Ralph in correctness-before-movement: its compact body may be normalized only after the runner and instructions agree on the 25-iteration default, exact done sentinel, failure stop, per-iteration commit evidence, dangerous-sandbox approval, executable setup, and optional orchestrator behavior. Its files do not overlap the concurrently claimed SK-005 scope.

Coordinator review rejected revision 1's `ready-to-integrate` state: every explicit runner invocation restarted at iteration 1, removed the prior final-message path, and opened the prior combined log through truncating `tee`. An explicit rerun therefore destroyed the failing evidence that revision 1 promised to retain. Revision 2 invalidates revision 1's focused acceptance, returns the item to drafting before production changes, and adds a durable non-overwriting evidence allocation contract.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` and WF-007 — verdict `simplify inline`; preserve the Ralph artifacts and course-correction model while repairing the runner before simplification.
- WF-004 `ralph` record — complete behavior ledger covering the three-artifact concept, one-item fresh iterations, repeated prompt reads, Ralph job plan updates, logs, sandbox selection, test-quality routing, course corrections, commit intent, and `/done` completion; it identifies the current runner contradictions.
- WF-008 — human-confirmed Ralph job, worker iteration, Ralph job plan, orchestrator, course correction, and done sentinel definitions. A Ralph job plan is not a repository plan workspace.
- WF-006 — Ralph owns its job plan and must remain separate from `create-plan`; the runner's unlimited default, substring sentinel, continued failures, unenforced commits, unsafe dangerous sandbox, and missing executable setup must be repaired before text moves.
- `specs/parameters.md` version `1.6.0` — authoritative `RALPH_DEFAULT_ITERATIONS=25` and `RALPH_DONE_PATTERN=/done`.
- `specs/ai-agent-config.md` version `2.3.0` and `specs/UBIQUITOUS_LANGUAGE.md` version `0.7.0` — canonical body sections, colocated failure/approval/output/completion rules, behavior preservation, and non-interchangeable Ralph job plan ownership.
- Verified `shared/skills/write-a-skill/SKILL.md` — requires one earned Workflow, semantic YAGNI, a behavior-preservation ledger, executable main-path support, and exact scope verification.
- Pre-SK-006 baseline `shared/skills/ralph/SKILL.md` and `references/loop.sh` — advertised `PROMPT.md`, `IMPLEMENTATION_PLAN.md`, and `ORCHESTRATOR.md`; the support script was mode `100644`, defaulted to unlimited iterations, accepted non-numeric/unbounded input, matched `/done` as a substring anywhere in combined output, continued after Codex failure, and recorded no commit evidence. Revision 1 repaired those defects but introduced the cross-invocation overwrite contradiction addressed here.
- Installed `codex-cli 0.144.1` — `codex exec --help` confirms stdin prompts (`-`), `--sandbox` values `read-only`, `workspace-write`, and `danger-full-access`, `-C/--cd`, and `-o/--output-last-message`; the installed parser also accepts the existing `--full-auto` compatibility flag. The revised runner uses `-o` so only the worker's final response can satisfy the exact sentinel.
- Coordinator rerun evidence against commit `2bf29f062825bca46ea0dade4c04cf4a6bc35252` — each process invocation starts its loop counter at 1, `rm -f` deletes `.loop-logs/iteration-1.last-message.md`, and non-appending `tee` truncates `.loop-logs/iteration-1.log`. This directly contradicts failure diagnosis and explicit-rerun retention wording in both the revision 1 proposal and skill.
- Git provenance — Ralph and its runner were introduced locally by `dfd67d2db28e59cc86463f54592cf5c1a4ed04c2` and moved to shared skills by `4fcd8db204888b46ef857ea16732bcb2e4ab201b`; blame attributes the runner entirely to the local introduction. No repository evidence identifies imported material or a third-party license. `THIRD_PARTY_NOTICES.md` has no Ralph entry and requires no change.
- `shared/skills/test-quality-verifier/SKILL.md` — remains the named owner for the test-quality audit routed after test changes; Ralph will use a portable skill name rather than claim that audit behavior.

No consequential authority conflict remains. WF-004 suggested removing `ORCHESTRATOR.md` from the required default set unless a concrete contract is retained; WF-008 subsequently confirmed the orchestrator as optional, and the user requires honest optional behavior. Revision 2 retains revision 1's `ORCHESTRATOR.md` decision: it is only an optional playbook for a separately started monitor, and neither this skill nor `loop.sh` supplies or launches that monitor.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-006-ralph.md` — item-local authorization, scope review, behavior ledger, and verification record.
- `shared/skills/ralph/SKILL.md` — replace the three ad hoc body headings with confirmed definitions and one bounded job Workflow; clarify the optional orchestrator and runner setup.
- `shared/skills/ralph/references/loop.sh` — repair defaults, validation, failure behavior, exact completion detection, commit evidence, logging, and executable mode.

These three paths are the complete revision 2 allowed file set, unchanged from revision 1. The runner is required because body-only prose cannot correct executable behavior. The temporary fake-Codex harness remains outside the repository and is not an additional affected file.

## Proposed changes

### Add

1. Add `Language Definitions` containing the six WF-008-confirmed terms and explicitly distinguish the Ralph job plan from the repository plan workspace.
2. Add one ordered `Workflow` covering applicability, artifact setup, executable runner installation, bounded launch, monitoring/course correction, failure recovery, completion evidence, and cleanup.
3. Make `PROMPT.md` require one checklist item per worker iteration, rereading and updating the Ralph job plan, relevant tests, the `test-quality-verifier` workflow after test changes, at least one descendant commit, and exact `/done` only after the complete plan and evidence are current.
4. Keep `ORCHESTRATOR.md` as an optional monitoring playbook. If created, it must direct a separately launched monitor to inspect `.loop-logs` and Git, prepend `IMPORTANT:` course corrections to `PROMPT.md`, avoid doing the worker item, and stop when the runner exits. State explicitly that the runner does not read this file and no orchestrator executable/template is supplied.
5. Add executable setup using the invoking agent's resolved Ralph skill directory: `install -m 0755 "$RALPH_SKILL_DIR/references/loop.sh" ./loop.sh`; require inspection/approval before replacing an existing project runner.
6. Default omitted iteration count to `25`; accept only a positive decimal bound and no more than two positional arguments. Validate the prompt file, Codex, Git repository/HEAD, and one of the three installed sandbox modes before creating logs or running Codex.
7. Gate `SANDBOX_MODE=danger-full-access` on explicit human approval represented by `RALPH_DANGER_FULL_ACCESS_APPROVED=1`; the skill must tell the human what access is requested before that variable is set. `workspace-write` remains the default and `read-only` remains selectable.
8. Capture each iteration's combined output in `.loop-logs/iteration-N.log` and its final worker response in `.loop-logs/iteration-N.last-message.md` through installed `codex exec -o` support. On startup, scan both public evidence forms and durable `.iteration-N.claim` allocation markers, then choose an evidence sequence strictly greater than every existing valid positive sequence. Keep this persistent evidence sequence separate from the per-invocation worker count, so `max_iterations` still limits workers launched by the current invocation.
9. Allocate every sequence with an atomic, durable `.loop-logs/.iteration-N.claim` directory before writing evidence. Stop non-zero if that supposedly fresh claim, public log, or public final-message path already exists. Create the log without clobbering and append thereafter; have Codex write its final response inside the fresh claim and publish it to the public path without replacement. Never `rm`, truncate, append to, or otherwise replace evidence from an earlier invocation.
10. Stop immediately and non-zero on Codex or logging failure. Preserve both evidence forms when produced, require diagnosis/course correction before an explicit rerun, and allocate a new evidence sequence on that rerun; never advance automatically after failure.
11. Capture `HEAD` before and after every successful Codex execution. Require the old head to be an ancestor of a changed head, record commit count/hash/subject in the iteration log, and stop non-zero if no descendant commit exists. This is enforceable commit evidence, not proof of commit quality.
12. Treat completion as exact final-response equality with `/done` (allowing only trailing newlines removed by shell command substitution), after successful execution and commit evidence. Substrings, explanatory text, and `/done` elsewhere in combined logs cannot complete the job.
13. Exit non-zero when the current invocation launches its bounded number of workers without the exact sentinel, regardless of how many evidence sequences existed before launch. Final human/agent review must inspect the Ralph job plan, every iteration log and commit range, test/test-quality evidence, and final Git state before accepting completion.
14. Retain `.loop-logs`, including allocation markers, on success, bound exhaustion, or failure. Stop any separately launched monitor when the runner exits; remove logs or the copied runner only as an explicit cleanup action after evidence is no longer needed.

### Change or move

1. Change the frontmatter description only to say `ORCHESTRATOR.md` monitoring is optional; preserve the setup/launch triggers, name, short description, and existing union-schema fields/tools.
2. Move `PROMPT.md`, `IMPLEMENTATION_PLAN.md`, and `ORCHESTRATOR.md` descriptions into artifact setup. Keep the prompt concise (about 20 lines), require its opening to route to `IMPLEMENTATION_PLAN.md`, and keep `IMPORTANT:` course corrections at the top where every fresh iteration reads them.
3. Replace the current launch sentence with the resolved-path install command and `./loop.sh [max_iterations] [prompt_file]`; omitted values are exactly `25` and `PROMPT.md`.
4. Keep one fresh `codex exec` process per worker iteration, stdin prompt rereading, current working directory, `--full-auto`, selectable sandbox, `.loop-logs`, and `tee`; separate the current invocation's worker count from the monotonic durable evidence sequence and strengthen validation/evidence contracts.
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
- [x] Explicit reruns preserve every prior log/final-message byte and allocate sequences above all existing log, final-message, and allocation-marker sequences.
- [x] The iteration bound remains per invocation: pre-existing evidence changes names, never the number of workers this launch may run.
- [x] Fresh-path collisions stop non-zero without removing, truncating, appending to, or replacing either path.
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
- The failure contradiction is repaired by immediate non-zero exits with retained logs and explicit rerun after diagnosis/correction. Revision 2 additionally repairs the cross-invocation contradiction by allocating monotonic evidence sequences through durable atomic claim directories; old evidence is never selected as an output target.
- Durable claim directories deliberately remain in `.loop-logs` as allocation evidence. Concurrent runner startups may compute the same candidate sequence, but atomic `mkdir` gives it to at most one process; the other stops rather than silently retrying or overwriting. Valid evidence sequences are positive decimal numbers represented by either public artifact or a claim marker. Public logs are created with noclobber semantics, final messages are first written under the owned claim and linked into place without replacement, and any unexpected collision is a hard non-zero stop.
- The commit contradiction is repaired by descendant-HEAD evidence in every iteration plus prompt and final-review requirements. Risk: a HEAD change proves commits occurred, not that the correct actor authored them or that they contain exactly one checklist item; log/plan/diff review remains required.
- Dangerous sandbox selection is capability gating, not a security boundary: an automated caller could forge the approval variable. The inline contract requires a human decision for the current job before setting it and defaults to `workspace-write`.
- The optional orchestrator claim is honest but intentionally does not create a monitor implementation. `ORCHESTRATOR.md` is useful only when a human separately starts a process to consume it; without one, the runner and operator inspect logs/Git directly.
- Course corrections made during an active iteration affect only a later prompt read; after any stopped failure they affect an explicit rerun. Concurrent prompt/Git mutation can race with a worker, so the monitor is constrained to corrections and final evidence requires commit/diff inspection.
- Local history identifies no imported Ralph text or runner and no required third-party license. `THIRD_PARTY_NOTICES.md` remains unchanged.
- `--full-auto` is retained for behavior compatibility and accepted by installed Codex even though current `codex exec --help` omits the compatibility alias. Installed help directly confirms every other runner option used. This alias is a residual version-skew risk to recheck at catalog verification.

## Verification

- `bash -n shared/skills/ralph/references/loop.sh` — runner syntax passes.
- Run an isolated temporary Git-repository harness with a fake `codex` executable and copied runner. Assert: omitted bound is reported as 25; malformed/zero/extra arguments fail before Codex; missing prompt/Git/Codex fail; invalid sandbox fails; dangerous sandbox fails without approval and reaches Codex only with approval; a non-zero Codex status invokes it once and returns non-zero; no-commit and non-descendant-history iterations fail; substring/mixed `/done` responses do not complete; exact final `/done` completes only after descendant commit evidence; and exhausting the bound returns non-zero after exactly the bound.
- Add a focused RED/GREEN rerun-preservation case around the public `loop.sh` interface. First run must write both iteration-1 evidence files and fail after the final message exists; record exact hashes/contents. The explicit successful rerun must leave both originals byte-identical, create iteration-2 evidence, and record commit evidence there. Observe it fail against `2bf29f0` for overwrite/removal before editing the runner, then pass after the revision 2 implementation.
- Add focused allocation checks: with prior evidence through sequence N, `max_iterations=2` still launches exactly two workers and uses N+1/N+2 before bound exhaustion; the maximum is taken across logs, final messages, and claim markers; an induced fresh claim/public-path collision stops without modifying existing evidence.
- Confirm the harness's successful two-worker case creates two combined logs, two last-message files, durable claims, and commit evidence for each worker. Confirm failure evidence remains available, no later worker starts in that invocation, and a later explicit invocation uses new sequence names.
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

Acceptance requires exact three-file scope, canonical two-section body, all behavior-ledger checks including cross-invocation preservation and per-invocation bounds, syntax and expanded isolated runner cases passing, mode `100755`, installed Codex option compatibility, existing union frontmatter validity, unchanged provenance/visibility/forbidden scope, and no unresolved authority conflict.

## Implementation record

### Revision 1 (invalidated by coordinator rerun review)

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
- Invalidated acceptance gap: the 15 cases exercised only one invocation per repository and therefore missed destructive reuse of iteration-1 evidence on explicit rerun. Revision 2 must replace this focused result with a RED/GREEN cross-invocation case and expanded allocation checks before returning to `ready-to-integrate`.

### Revision 2

Focused verification completed: `2026-07-14T16:43:36+00:00`

- Proposal-before-edit control: revision 2 returned to `drafting`, preserved the exact three-file scope, recorded the coordinator contradiction, specified monotonic public evidence names plus durable atomic `.iteration-N.claim` allocation, repeated authority/behavior/contradiction/provenance/verification review, and reached `proposal-ready` before the skill or runner changed.
- Focused RED evidence against `2bf29f062825bca46ea0dade4c04cf4a6bc35252`: the first no-commit invocation produced both iteration-1 evidence files; an explicit successful rerun returned zero but changed the iteration-1 log hash and failed the new preservation assertion. The failure was the intended truncation/removal defect, not fixture or environment failure.
- Focused GREEN and expanded fake-Codex harness: PASS, 20 cases. The rerun case preserves exact iteration-1 log/final-message hashes, creates iteration-2 evidence, and records its commit range. Prior evidence through N still permits exactly two workers for `max_iterations=2` at N+1/N+2. The maximum is selected across mixed log, last-message, and claim forms. Induced public-path and claim collisions each stop before a second Codex call without changing collision evidence. The original 15 revision 1 behaviors also remain green.
- Runner implementation: every process computes a first evidence sequence above all existing valid forms, while `RUN_ITERATION` independently enforces the invocation bound. Atomic durable claim directories reserve sequences; logs use noclobber creation and append only after ownership; Codex writes its final response under the owned claim and `ln` publishes it without replacement. No prior final-message removal or truncating log open remains.
- Skill contract: failure recovery now guarantees an explicit rerun uses a new evidence sequence and retains prior bytes; launch wording separates per-invocation bounds from persistent evidence numbering; collision failure and allocation-marker cleanup/retention are colocated with their governing steps.
- Follow-up production diff from `2bf29f0`: skill `6` insertions/`6` removals; runner `56` insertions/`12` removals. The proposal record has `49` insertions/`17` removals. Exact changed paths remain the three authorized files.
- Resulting SHA-256: skill `fc57e7f97267374d36c320a30008384e19f04df77925bc1cc694597736bf385f`; runner `33a7e8fcae2b86734e0aa044f270c898519535659fd151205bfa738dfdd3f742`.
- Runner syntax/executable support: `bash -n` PASS; mode `100755` PASS. `shellcheck` remains unavailable and is reported rather than claimed.
- Installed `codex-cli 0.144.1`: version, stdin route, all three sandbox values, `-C`, `--output-last-message`, and parser-only retained `--full-auto` compatibility PASS without launching an agent.
- Canonical body and behavior ledger: complete skill/runner reread PASS; headings are exactly `Language Definitions` then `Workflow`; the 25 default, exact final-message sentinel, immediate failure stop, descendant commit evidence, explicit dangerous-mode gate, executable install, named artifacts, job-plan ownership, optional orchestrator honesty, course corrections, test-quality route, completion review, and explicit cleanup remain inline.
- Repository verification: `bash tests/run.sh` PASS (2 shell files, 12 tests); union-frontmatter audit PASS (33 skills, 0 findings); relative link, Pi symlink target, local provenance, absent Ralph notice diff, stale-contract scans, `git diff --check`, exact scope, and forbidden-scope diff PASS.
- Residual risk: `--full-auto` is still an installed parser-compatible alias omitted from current help and may disappear in a later Codex release; catalog verification should recheck it.
- Residual risk: descendant `HEAD` still proves commits occurred, not actor identity, one-item scope, or quality; final plan/log/diff/test review remains mandatory.
- Residual risk: the dangerous-mode environment variable records but cannot enforce human approval. Durable claim directories and their staging final-message file intentionally consume disk until explicit evidence cleanup; concurrent launches choose safety by stopping one claimant rather than retrying automatically.

## Integrated verification

- Coordinator verification timestamp: `2026-07-14T16:49:58+00:00`.
- The complete two-commit worker range changed exactly the proposal, `SKILL.md`, and executable runner; proposal revision 2 and mode `100755` are preserved.
- Independent fake-Codex verification passed 20/20 cases, including byte-preserving explicit reruns, monotonic mixed-form sequence selection, per-invocation bounds, fresh public-path/claim collisions, exact `/done`, immediate failure stop, descendant commit evidence, and dangerous-mode approval.
- `bash -n`, installed Codex 0.144.1 option/parser checks, canonical body/link/frontmatter checks, union-frontmatter audit, `git diff --check`, Pi visibility, and repository shell tests (12/12) passed.
- `pi/settings.json` retained its recorded content and diff hashes and remained unstaged. Residual `--full-auto`, commit-quality, approval-variable, and retained-evidence disk risks remain as documented above.

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
- Proposal revision: `2`
- Authorization effect: the standing directive removes the per-item approval wait but authorizes only the same three exact paths and changes enumerated in revision 2.
- Scope check: `PASS` — MAP/WF-007, WF-004, WF-008, WF-006, current specs, the complete target skill/runner, revision 1 diff, coordinator finding, local provenance, and installed command contract were reread in authority order. Revision 2 keeps the exact three-file scope, adds only non-overwriting durable evidence allocation and corresponding skill/proposal wording, preserves the complete behavior ledger and per-invocation bound, resolves the rerun contradiction without changing ownership or provenance, and defines focused plus repository verification. Production editing may resume without a per-item approval wait.

# Lightweight Direct Execution

Use this branch only for an explicit root whose approved execution mode is lightweight.

## 1. Claim direct execution in the current checkout

A direct executor may implement, verify, commit, mutate the molecule's current Beads state, and close verified work. It does not act as an independent reviewer. Herdr, worker-attempt beads, exact advance model assignments, isolated worktrees, review fan-out, and write-ahead records for self-directed actions are not required.

Validate the approved source fixed point, branch plan, and dirty-work disposition. Stop rather than mixing unrelated changes. Exploratory work should use a clearly named branch unless the approved scope names another safe location. Record actual agent, provider, model, and thinking provenance; mark the first ready work bead active with its current state and one next action.

Completion criterion: the direct executor, checkout, starting commit, branch, first work bead, and unrelated-change handling are explicit in Beads and Git.

## 2. Work serially and checkpoint meaningful state

Take one ready implementation work bead at a time.

For **shippable** delivery, obey repository-required TDD, implement only the approved behavior, run focused checks and applicable repository gates, and refactor only while green. For **exploratory** delivery, optimize for the approved learning question: maintain one exact run command, expose the relevant behavior, and avoid invented tests or production polish.

Update the work bead at recovery-relevant boundaries with current state, next action, branch, full base/candidate commit when available, and evidence completeness. Do not create a worker-attempt graph for the already-running direct executor. If interrupted, resume from the active work bead and Git rather than conversation history.

Completion criterion: each return either advances the active bead with durable evidence or records one exact blocker/next action; no status-only return leaves the next action unknown.

## 3. Self-verify and commit

Before closing a shippable work bead, check its approved completion and failure conditions, run its focused commands and applicable mechanical gates, inspect the diff for unintended scope, and commit the result. Record the full commit, changed files, commands and results, completion evidence, known risks, actual model provenance, and explicit statement that the check was not independent review.

Before finishing exploratory implementation, run the exact demonstration, record observations, unknowns discovered, limitations, and the full exploratory commit. Demonstration success proves the learning surface runs; it does not claim production fitness.

Close each serial work bead only after its own evidence and commit are complete, then recompute the frontier.

Completion criterion: every closed implementation bead points to a full commit and complete verification or demonstration evidence.

## 4. Resolve exploratory disposition

Exploratory delivery waits for one human-approved exploration disposition:

- **Discard:** preserve the question, findings, evidence, and implications in Beads; remove the exploratory code and commit the cleanup before closure.
- **Retain as-is:** preserve a clearly named exploratory branch and commit with recorded limitations. Main-line inclusion requires explicit human acceptance of those limitations and passing minimum repository safety checks.
- **Rebuild:** preserve the exploratory branch, commit, findings, limitations, and implications; close the exploration, then route to `create-engineering-plan` for a new linked shippable molecule from a clean production base. Prototype code is evidence and is reused only through normal shippable verification.

Do not silently infer a disposition from terminal inactivity or a successful demo.

Completion criterion: exploratory code has an approved owner/location or is removed, durable learning is recorded, and `rebuild` names the linked planning next action.

## 5. Promote when direct execution no longer fits

When policy changes, concurrent actors become necessary, independent review becomes required, or complexity exceeds bounded serial execution, stop before adding coordination topology. Commit a passing fixed point or explicitly documented partial fixed point, record the reason and proposed coordinated needs, and obtain human approval.

After approval, expand the same molecule through the coordinated branch of `create-engineering-plan`, preserving prior scope and evidence through a linked decision. A fresh coordinator resumes the expanded graph. The direct executor never silently relabels itself as coordinator. Coordinated mode does not downgrade after worker execution begins.

Completion criterion: execution either remains legitimately lightweight or stops at a committed, approved promotion boundary.

## 6. Complete locally and synchronize opportunistically

Close a shippable molecule when all work beads and approved checks pass. Close an exploratory molecule only after its disposition requirements pass. Record the final full commit, evidence, retained branch, and local semantic checkpoint.

Attempt the authorized remote Beads checkpoint. If it fails, the lightweight molecule may remain locally complete with `sync_state: pending`; report that state prominently and require the next Beads operation to reconcile it. Never claim remote durability without evidence.

Completion criterion: the molecule is locally complete at one evidenced commit or remains explicitly active/blocked, and synchronization is either verified or visibly pending.

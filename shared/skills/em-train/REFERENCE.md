# EM Train Reference

This file contains only training-owned schemas, setup, guidance, educational review, reporting, and cleanup. The main Workflow owns when each section must load. `create-explainer` owns explainer production, factual review, serving, and browser validation; `code-review` owns generic fixed-point Standards/Spec review.

## Ticket and setup

### Ticket schema

Write `ticket.md` with this contract:

```markdown
# [Ticket title]

## Story
[Why this real repository change matters to its users or maintainers.]

## What you need to do
[Clear implementation task without an implementation recipe.]

## Acceptance criteria
- [ ] [Specific, observable behavior]
- [ ] [Specific test or failure behavior]
- [ ] [Relevant compatibility or documentation behavior]

## Files you'll likely touch
- `path/to/source` — responsibility, not the answer
- `path/to/test` — behavior surface to verify

## Tips
- [Convention and an existing fixed-point file where the learner can study it]
- [Gotcha phrased as a question or investigation route]
```

Tips and file notes must satisfy the no-spoiler rule. They may point to analogous code that existed at the fixed point, but must not reveal the ticket's exact method call, input schema names/types, return keys/shape, async strategy, registry entry, or copy-ready implementation. Acceptance criteria state behavior rather than prescribing internals unless the repository contract requires them.

### Joint scope checkpoint

After negotiating the ticket and routing the explainer persona/tier, present one checkpoint that satisfies both EM Train and Create Explainer:

```text
Training mission: [goal and role]
Learner: [level, specialty, prior knowledge]
Ticket: [real project task and why it matters]
Acceptance: [testable criteria summary]
Likely files: [paths/responsibilities]
Out of scope: [boundaries and forbidden solution detail]
Time fit: [learner budget and rationale]
Explainer: [tier, concept, planned sections, reading time]
No-spoiler boundary: examples come only from fixed-point code and do not solve the ticket.

Proceed, adjust, or cancel?
```

Treat `proceed` as approval for this exact ticket and explainer scope. Revise this same checkpoint after `adjust`; stop on `cancel`. Do not create branch/runtime artifacts or begin Create Explainer source mapping before approval, and do not ask for a second scope approval afterward.

### Branch setup

Require a suitable starting tree. If unrelated tracked or untracked work could enter the training branch, ask the user to resolve it or explicitly identify what remains outside session ownership; never stash, discard, or absorb it silently.

Generate the branch slug with installed shell tools rather than assuming a `slugify` command:

```bash
TRAINING_FIXED_POINT="$(git rev-parse --verify HEAD^{commit})"
TICKET_SLUG="$(printf '%s' "$TICKET_TITLE" \
  | tr '[:upper:]' '[:lower:]' \
  | tr -cs '[:alnum:]' '-' \
  | sed 's/^-//; s/-$//')"
BRANCH_NAME="train/em-$(date +%Y%m%d)-${TICKET_SLUG}"

test -n "$TICKET_SLUG"
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
  printf 'Training branch already exists: %s\n' "$BRANCH_NAME" >&2
  exit 1
fi
git switch -c "$BRANCH_NAME"
```

Verify the checked-out branch and record the fixed point, branch name, creation result, and session ownership in temporary session state. The fixed point remains the review baseline even as the user commits.

### Temporary-guide assembly

Choose a project-local skill directory supported by the active harness. Verify that the harness discovers its `SKILL.md`; if it has no project discovery location, explicitly load the temporary skill by path. Record the selected path for this session rather than hardcoding another agent's config. The directory is temporary and must not be committed.

Assemble:

```text
<temporary-guide>/
├── SKILL.md            # rendered from scripts/em-guide-template.md
├── ticket.md           # approved ticket
├── struggles.md        # temporary learning observations
└── explainer/
    ├── index.html      # create-explainer-owned output
    └── main.js         # only when required by its selected tier
```

Render the template placeholders `TICKET_TITLE`, `TICKET_SUMMARY`, `LEVEL`, `LANGUAGE`, `PROJECT`, `TRAINING_FIXED_POINT`, `SOURCE_FILES`, and `TEST_FILES`. Source/test paths must exist at the fixed point. Add the exact temporary path to local Git exclusion when needed, with an identifiable session marker, and verify it is absent from `git status` and the review diff. Remove that local exclusion during cleanup.

Continue the already-approved `create-explainer` workflow with `<temporary-guide>/explainer/` as its caller-owned destination. Do not copy its intake, source mapping, tier, reviewer, server, or browser procedures here. Record its returned artifact/evidence paths, URL, server ownership, and limitations in temporary session state for later cleanup and report evidence.

Tell the learner:

```text
You are on [branch]. The ticket is [ticket path]. The reviewed explainer is
[URL and durable temporary path]. Invoke [guidance skill/path] for language,
API, convention, or debugging questions. It will not write the solution.
When your implementation is ready, return with “ready for review.”
```

## Guidance behavior

`scripts/em-guide-template.md` is the sole guidance-body template. Do not paste a second copy into this Reference. Its rendered skill must:

- identify the learner level, language/ecosystem, project, ticket, and fixed point;
- answer conceptual language/API questions, explain project conventions, interpret errors, and show analogous code that existed at the fixed point;
- refuse implementation bodies, ticket-specific answer shapes, exact core calls, registry entries, and copy-ready solutions;
- ask what the learner tried and which concept blocks them before offering another explanation;
- route deeper conceptual blockage through `create-explainer` under the same persona, no-spoiler, temporary-destination, factual-review, serve, and browser-validation contract;
- never edit production implementation files for the learner; and
- record concise struggle patterns in temporary `struggles.md` for the EM's final report.

Before handing over, test one allowed question and one prohibited “write it for me” question against the rendered instructions. The allowed route must teach from fixed-point evidence; the prohibited route must ask for the learner's attempt and refuse the answer.

## Educational review

### Evidence collection

At each `ready for review`, rediscover the repository's actual CI commands from `AGENTS.md`, contributor guidance, CI workflow configuration, package scripts, or equivalent authority. Run those entry points without masking status. Record command, exit code, failed check/test names, and material output. If credentials, network, runner, or infrastructure prevent a check, label it unavailable or infrastructure-failed; do not convert it to a pass.

Run `code-review` over the immutable training fixed point and current branch/worktree. Supply the approved ticket as the Spec authority. Retain its separate Standards and Spec results, but do not interpret either as educational approval and do not ask generic reviewers to calibrate pedagogy.

The EM then reviews the acceptance criteria, tests, diff, CI evidence, generic findings, and learner decisions. Select two or three findings using this schema:

```markdown
### [Finding title] — [blocking | non-blocking]
- Evidence: [command result, path/symbol, diff hunk, criterion, or observed choice]
- Why it matters: [language/ecosystem or codebase lesson calibrated to the learner]
- Investigation: [question, existing fixed-point example, test to write/read, or concept to examine]
- Done when: [observable revision evidence]
```

Prefer the findings with the highest learning value that the learner can act on now. Do not overwhelm them with every review note. Do not provide the implementation in `Investigation`.

### Round rules

- A review round is the learner's submission, real CI, generic review, EM educational findings, and learner revision.
- Run at most two rounds total.
- Round 1 always includes two or three findings and at least one concrete improvement. If there is no correctness defect, choose an evidence-backed test-quality, clarity, convention, or design-tradeoff improvement; never fabricate a failure.
- Round 2 again reports two or three educational findings or takeaways with blocking status. Approval requires all acceptance criteria and required real CI to pass and no unresolved blocking finding.
- When Round 2 requests a final revision, run real CI and targeted checks for those findings afterward. This is final verification, not a third feedback round. Report pass or unresolved failure and stop.

A learner can finish with valuable learning and an unsuccessful implementation. Keep those outcomes distinct and honest.

## Report and cleanup

### Session report

Write the report to a user-approved durable repository location or the repository's existing report convention. Do not silently invent a tracked root artifact when the repository has another convention. Use:

```markdown
# EM Train — Session Report

## Session
- Date: [date]
- Goal / role / level: [intake summary]
- Ticket: [title and acceptance summary]
- Branch: `[branch]`
- Fixed point: `[full commit]`

## What you built
[Implemented behavior and final acceptance status.]

## CI and review evidence
### Round 1
- CI: [commands, status, material failures]
- Generic review: [separate Standards and Spec summary]
- Educational findings: [2–3 titles and disposition]

### Round 2
[Same fields, or “not needed” with reason.]

### Final verification
[Commands/status after a Round-2 revision, or not applicable.]

## What you learned
- [Key lesson 1]
- [Key lesson 2]
- [Key lesson 3, when material]

## Things to remember
- [Language/ecosystem pattern]
- [Codebase convention]
- [Struggle pattern and retrieval cue]

## Unresolved failures or limitations
- [Failed/unavailable checks, blocking findings, or “None”]

## Suggested next ticket
[One real next slice tied to the learner's current hardest useful edge.]

## Cleanup and branch choice
- Temporary guide/explainer runtime: [removed/stopped status]
- Branch choice: [merge | leave as learning artifact | awaiting user]
```

Use the temporary `struggles.md` only as evidence for generalized learning patterns; do not copy sensitive prompts or session history into the report.

### Cleanup checklist

1. Confirm the report contains all evidence needed before deleting temporary files.
2. Close the task-owned browser and stop the exact Create Explainer server using temporary session state. Do not persist its PID or port in the report or another committed file.
3. Remove the temporary guide directory, explainer, ticket copy, struggles file, screenshots, snapshots, and incidental validation artifacts owned by this session.
4. Remove the exact temporary `.git/info/exclude` marker/entry if one was added; preserve unrelated local exclusions.
5. Verify no temporary guide path appears in `git status`, the branch diff, active harness discovery, or a live task-owned process.
6. Ask the user to choose:
   - **merge** — integrate through the repository's normal verified delivery path; or
   - **leave** — keep the training branch as a learning artifact.

The session does not merge on the learner's behalf without that explicit choice. If the branch was not created by this session, report that ownership mismatch and do not claim disposition authority.

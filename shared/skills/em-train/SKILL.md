---
name: em-train
description: Acts as an engineering manager to help you build fluency in a codebase's language and ecosystem. Use when you want to learn a new language/framework by doing real work on a real codebase, prepare for interviews, or build hands-on fluency through structured TDD tasks.
metadata:
  short-description: Train through real tickets
allowed-tools: read,write,edit,bash
---

# EM Train — Engineering Manager Training Skill

## Language Definitions

- **Training ticket** — real repository task sized to learner role, fluency, and time.
- **Temporary guidance skill** — short-lived training constraints removed afterward.
- **No-spoiler rule** — guidance may teach conventions, examples, and debugging but not provide the ticket's answer.
- **Review round** — implementation submission followed by real CI, educational feedback, and revision.

## Workflow

Run one learner-owned implementation session from intake through branch disposition. Right-size the next meaningful slice of real project work; do not use fixed difficulty ladders.

### 1. Interview the learner

Ask for and confirm all five inputs:

1. session goal;
2. experience with the codebase's language and ecosystem (`beginner`, `intermediate`, or `advanced`);
3. specialty or target role;
4. available time; and
5. prior domain or language knowledge to skip.

Use the answers to calibrate scope, analogies, explainer depth, and review feedback. Completion: goal, level, role, time, and prior knowledge are explicit in the session state.

### 2. Find and negotiate one real ticket

Inspect applicable project guidance, plans or roadmaps, specs and architecture, recent Git history, open issue/TODO evidence, existing tests, and real CI entry points. Present a small set of evidenced project needs, explain why each matters, and negotiate one training ticket the learner is excited about and can finish in the available time. The ticket must have a story, a clear task, testable acceptance criteria, likely files, and non-spoiling tips.

Select the explainer concept and use `create-explainer`'s persona/tier routing to present exactly one joint scope checkpoint. Include the training mission, ticket scope and exclusions, acceptance criteria, likely files, time fit, explainer tier/sections, and no-spoiler boundary. This is also Create Explainer's required checkpoint; do not add a second one. Continue on `proceed`, revise on `adjust`, and stop on `cancel`.

Write `ticket.md` with this contract:

```md
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

Completion: the user has approved one real, right-sized ticket and one explainer scope without approving any implementation answer.

### 3. Create the training branch and temporary guide

Load the approved ticket and setup details to safely create `train/em-<date>-<ticket-slug>`, record its immutable start commit as the review fixed point, and record that the session owns the branch. Stop rather than overwrite an existing branch or hide an unsuitable working tree.

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

Render the template placeholders `TICKET_TITLE`, `TICKET_SUMMARY`, `LEVEL`, `LANGUAGE`, `PROJECT`, `TRAINING_FIXED_POINT`, `SOURCE_FILES`, and `TEST_FILES`. Source/test paths must exist at the fixed point. Verify the rendered `SKILL.md` from the temporary-guide directory so its destination-relative paths resolve there: `ticket.md`, `explainer/index.html`, and `struggles.md`. Add the exact temporary path to local Git exclusion when needed, with an identifiable session marker, and verify it is absent from `git status` and the review diff. Remove that local exclusion during cleanup.

Continue the already-approved `create-explainer` workflow with `<temporary-guide>/explainer/` as its caller-owned destination. Pass the learner persona, training mission, no-spoiler constraint, and temporary explainer destination owned by this session. All teaching examples and factual claims must come from code that existed at the training fixed point—not the requested implementation or the learner's new code. Retain Create Explainer's source mapping, tier contract, self-check, mandatory source-grounded reviewer pass, correction gates, identity-checked serving, browser validation, and honest fallback disclosure. EM Train retains the destination, mission, no-spoiler boundary, learner gate, and eventual cleanup.

Tell the learner:

```text
You are on [branch]. The ticket is [ticket path]. The reviewed explainer is
[URL and durable temporary path]. Invoke [guidance skill/path] for language,
API, convention, or debugging questions. It will not write the solution.
When your implementation is ready, return with “ready for review.”
```

Completion: the temporary guide points to a source-grounded, reviewed, served, and browser-validated explainer that teaches prerequisites without revealing the ticket solution.

### 4. Give implementation ownership to the learner

The guide may explain language/API behavior, project conventions, debugging evidence, and analogous fixed-point code. It must ask what the learner tried and must never write production implementation, provide a copy-ready answer, or derive examples from the ticket solution.

Wait for the learner to implement and say `ready for review`. During this phase, do not edit ticket production files on the learner's behalf. Completion: the submitted implementation is the user's work and the temporary guide has retained any observed struggle patterns for the report.

### 5. Run at most two educational review rounds

For each submitted round:

1. Run the repository's real CI/test entry points discovered from its guidance or CI configuration. Preserve exit statuses; distinguish code failures, infrastructure failures, and unavailable checks. Never mask failure with `|| true`, substitute a toy check, or claim an unexecuted pass.
2. Run `code-review` against the recorded fixed point and current branch/worktree only for its generic Standards and Spec axes. The approved training ticket is the Spec source. A generic review result cannot replace CI or approve the learning session.
3. Perform the EM-owned educational review. Combine CI evidence, acceptance criteria, tests, generic findings, the diff, and the learner's choices into two or three evidence-backed, actionable findings calibrated to their level. Explain why each matters and how to investigate; do not supply the implementation.
4. Ask the learner to revise. Round 1 must never be a rubber stamp: include at least one concrete improvement even when correctness is clean, but do not invent a defect. Use an evidenced test, clarity, convention, or tradeoff improvement instead.

After the second round, do not open a third feedback round. If the second-round feedback requires a revision, let the user make it and run one final real-CI check plus targeted verification of those findings. Record success only if the required checks pass; otherwise end with an honest unresolved result.

Completion: no more than two review rounds occurred, each produced two or three educational findings, and final CI/review status is recorded without hiding failures.

### 6. Report, clean temporary state, and honor branch ownership

Write the report to a user-approved durable repository location or the repository's existing report convention. Do not silently invent a tracked root artifact when the repository has another convention. Use:

```md
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

Cleanup checklist:
1. Confirm the report contains all evidence needed before deleting temporary files.
2. Close the task-owned browser and stop the exact Create Explainer server using temporary session state. Do not persist its PID or port in the report or another committed file.
3. Remove the temporary guide directory, explainer, ticket copy, struggles file, screenshots, snapshots, and incidental validation artifacts owned by this session.
4. Remove the exact temporary `.git/info/exclude` marker/entry if one was added; preserve unrelated local exclusions.
5. Verify no temporary guide path appears in `git status`, the branch diff, active harness discovery, or a live task-owned process.
6. Ask the user to choose:
   - **merge** — integrate through the repository's normal verified delivery path; or
   - **leave** — keep the training branch as a learning artifact.

The session does not merge on the learner's behalf without that explicit choice. If the branch was not created by this session, report that ownership mismatch and do not claim disposition authority.

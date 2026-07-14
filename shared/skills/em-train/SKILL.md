---
name: em-train
description: Acts as an engineering manager to help you build fluency in a codebase's language and ecosystem. Interviews you about what the project needs, right-sizes a ticket to your skill level, generates a brief, creates a training branch, reviews your work via real CI, and produces a summary report. Use when you want to learn a new language/framework by doing real work on a real codebase, prepare for interviews, or build hands-on fluency through structured TDD tasks.
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

Completion: the user has approved one real, right-sized ticket and one explainer scope without approving any implementation answer.

### 3. Create the training branch and temporary guide

Load [ticket and setup details](REFERENCE.md#ticket-and-setup) to write the approved ticket, safely create `train/em-<date>-<ticket-slug>`, record its immutable start commit as the review fixed point, and record that the session owns the branch. Stop rather than overwrite an existing branch or hide an unsuitable working tree.

Choose a project skill location actually discovered by the active harness, verify discovery (or arrange explicit loading), and assemble the temporary guidance skill from `scripts/em-guide-template.md`. Keep the temporary guide and explainer out of the training diff and record their exact paths only as temporary session state. Completion: the user is on the owned training branch with an accessible ticket and guidance skill, and the fixed point is recorded.

### 4. Compose the complete Create Explainer workflow

Load and execute `create-explainer`, continuing from the approved joint checkpoint. Pass it the learner persona, training mission, no-spoiler constraint, and temporary explainer destination owned by this session. All teaching examples and factual claims must come from code that existed at the training fixed point—not the requested implementation or the learner's new code.

Do not copy, bypass, or weaken Create Explainer's source mapping, tier contract, self-check, mandatory source-grounded reviewer pass, correction gates, identity-checked serving, browser validation, or honest fallback disclosure. Accept the explainer only with that workflow's reviewed artifact paths, served URL/process ownership, browser evidence, and limitations. EM Train retains the destination, mission, no-spoiler boundary, learner gate, and eventual cleanup.

Completion: the temporary guide points to a source-grounded, reviewed, served, and browser-validated explainer that teaches prerequisites without revealing the ticket solution.

### 5. Give implementation ownership to the learner

Tell the user the branch, ticket path, explainer URL/path, and how to invoke the temporary guide. The guide may explain language/API behavior, project conventions, debugging evidence, and analogous fixed-point code. It must ask what the learner tried and must never write production implementation, provide a copy-ready answer, or derive examples from the ticket solution.

Wait for the learner to implement and say `ready for review`. During this phase, do not edit ticket production files on the learner's behalf. Completion: the submitted implementation is the user's work and the temporary guide has retained any observed struggle patterns for the report.

### 6. Run at most two educational review rounds

For each submitted round:

1. Run the repository's real CI/test entry points discovered from its guidance or CI configuration. Preserve exit statuses; distinguish code failures, infrastructure failures, and unavailable checks. Never mask failure with `|| true`, substitute a toy check, or claim an unexecuted pass.
2. Load and run `code-review` against the recorded fixed point and current branch/worktree only for its generic Standards and Spec axes. The approved training ticket is the Spec source. A generic review result cannot replace CI or approve the learning session.
3. Perform the EM-owned educational review. Combine CI evidence, acceptance criteria, tests, generic findings, the diff, and the learner's choices into two or three evidence-backed, actionable findings calibrated to their level. Explain why each matters and how to investigate; do not supply the implementation.
4. Ask the learner to revise. Round 1 must never be a rubber stamp: include at least one concrete improvement even when correctness is clean, but do not invent a defect. Use an evidenced test, clarity, convention, or tradeoff improvement instead.

After the second round, do not open a third feedback round. If the second-round feedback requires a revision, let the user make it and run one final real-CI check plus targeted verification of those findings. Record success only if the required checks pass; otherwise end with an honest unresolved result.

Completion: no more than two review rounds occurred, each produced two or three educational findings, and final CI/review status is recorded without hiding failures.

### 7. Report, clean temporary state, and honor branch ownership

Load [report and cleanup details](REFERENCE.md#report-and-cleanup) to write the durable session report before deleting temporary evidence. Include the ticket/result, branch and fixed point, CI and review evidence by round, two or three key lessons, patterns to remember, next suggested ticket, and unresolved failures.

Stop the task-owned explainer server/browser, remove the temporary guidance directory and incidental artifacts, and remove any temporary local exclusion created for them. Do not persist process IDs, ports, pane IDs, or other live identities in committed files.

Offer the user the preserved choice: merge the session-owned branch or leave it as a learning artifact. Do not merge without their choice. Completion: the report is locatable, temporary runtime state is gone, and branch disposition matches the user's decision.

## Reference

- Load [Ticket and setup](REFERENCE.md#ticket-and-setup) during steps 2–3 to apply the training-only ticket schema, joint checkpoint, safe branch setup, and temporary-guide assembly contract.
- Load [Guidance behavior](REFERENCE.md#guidance-behavior) when assembling or explaining the temporary skill so its placeholders, allowed help, no-spoiler boundary, and struggle handoff remain complete.
- Load [Educational review](REFERENCE.md#educational-review) during step 6 to apply the two-round evidence and feedback schema without importing nonexistent reviewer roles.
- Load [Report and cleanup](REFERENCE.md#report-and-cleanup) during step 7 to produce the durable report and verify temporary cleanup plus the user's branch choice.

# Shared Skill YAGNI Migration Ledger

## Objective
Implement the decision-ready recommendations in the completed [Shared Skill YAGNI Audit Wayfinder map](../../.wayfinder/shared-skill-yagni-audit/MAP.md) through proposal-before-edit scope control and coordinator verification.

The human directive recorded at `2026-07-14T15:55:39+00:00` authorizes the coordinator and workers to execute every remaining ledger item without per-item human approval. Exact item proposals remain mandatory execution records, not approval gates.

This ledger is the execution control surface. The Wayfinder map and tickets remain the decision trail and are not implementation state. A timestamped handoff may point here, but MUST NOT replace or contradict this ledger.

## Authorities
Read these in order when preparing a proposal:

1. `.wayfinder/shared-skill-yagni-audit/MAP.md` for destination, scope, and low-resolution decisions.
2. Ticket `007-synthesize-audit-and-route-follow-up.md` for the final recommendation and dependency sequence.
3. The target skill's family-audit record in WF-003, WF-004, or WF-005.
4. WF-008 for human-confirmed Language Definitions.
5. WF-006 for ownership, composition boundaries, contradictions, and migration order.
6. Current specs, target skill, directly linked support files, provenance notices, and executable command help where applicable.

If current evidence conflicts with the audit, stop that item's production edit, record the conflict in a proposal revision, and return it to the coordinator. The coordinator MUST resolve it from the authority order or ask the human only when consequential intent remains unknowable; workers never silently choose between conflicting authorities.

## Standing constraints

- Do not edit a production skill or its supporting files before its exact proposal reaches `proposal-ready` after authority and scope review.
- The standing human authorization covers only the files and changes enumerated in the current proposal revision. Material scope growth returns the item to `drafting` for proposal revision and renewed coordinator scope review; it does not require a new human approval.
- MG-001, MG-002, and SK-001 are verified. At most two worker items may now be active in parallel under the three-agent Herdr protocol below.
- Preserve triggers, branches, gates, failures, guardrails, output contracts, ownership rules, completion criteria, provenance, licenses, relative links, and repository-required behavior unless the proposal names the replacement owner.
- Keep `Language Definitions`, optional single `Workflow`, optional `Activities`, and optional `Reference` in that order. Do not invent optional sections.
- Apply YAGNI semantically; there is no line-count target.
- Correct contradictions before moving or deleting text.
- Keep cross-agent frontmatter redesign and harness-specific portability outside this migration. Validate the existing union schema without redesigning it.
- Do not change deployment, Pi visibility symlinks, or agent discovery.
- The pre-existing `pi/settings.json` modification is unrelated. Never edit, stage, normalize, or restore it.
- A control artifact authorizes production work only when it records the standing directive, exact current revision, allowed file set, and `proposal-ready` state.

## Execution protocol

Every remaining item uses one of these states:

```text
queued -> claimed -> drafting -> proposal-ready -> editing -> ready-to-integrate -> integrating -> verified
                         ^              |
                         |              `-> material scope or authority conflict -> drafting
                         `------------------ integration conflict or invalidated dependency
```

`proposal-ready` means the worker has completed the exact proposal, checked it against the authority order and standing authorization, and may edit only the disclosed files. It is not a human wait state. `ready-to-integrate` means worker verification passed, not that the coordinator has accepted the result.

The human may pause, redirect, revise, or cancel the migration at any time. Absent such a directive, workers continue from proposal through implementation without asking for `APPROVE`, `DECLINE`, or `REVISE` responses. If implementation diverges materially from the current proposal, the worker returns to `drafting`, revises the proposal, and rechecks scope before continuing.

## Proposal requirements

A proposal MUST state:

1. Current verdict and evidence source.
2. Exact affected files.
3. Exact additions, removals, relocations, and ownership changes.
4. Proposed four-section shape.
5. Behavior-preservation checklist.
6. Dependencies, contradiction repairs, provenance, and licensing.
7. Verification commands and observable acceptance criteria.
8. Explicit exclusions.
9. A standing-authorization record containing the directive timestamp and current proposal revision.

Create proposal files lazily when their blockers are satisfied. Do not pre-author 33 stale rewrites before current source and dependencies can be reread.

## Three-agent Herdr operation

### Activation and roles

Parallel mode is active because MG-001, MG-002, and SK-001 are integrated and verified. The coordinator remains in the main checkout while two workers use isolated worktrees.

Use exactly three Pi agents in three clearly labelled Herdr tabs:

1. **Coordinator/integrator** — owns the main checkout, `MIGRATION.md`, frontier derivation, claims, worker prompts, integration, and final status. It does not edit a production skill assigned to a worker.
2. **Worker A** — owns at most one claimed migration item and its isolated worktree.
3. **Worker B** — owns at most one claimed migration item and its isolated worktree.

Workers do not wait for per-item human approval. Each worker records the standing authorization in its proposal, performs proposal-before-edit scope review, and returns one committed result to the coordinator.

Herdr is transport, not durable identity or checkout isolation. Load the current Herdr skill before controlling tabs, discover live context, parse create responses, and never persist workspace, tab, or pane ids in this ledger, proposals, branches, commits, or handoffs. Use descriptive tab labels for humans, but rediscover the live ids before every control operation.

### Claiming and isolation

The coordinator MUST:

1. derive the frontier from `verified` blockers rather than table order alone
2. select no more than two items whose exact file sets do not overlap and whose ownership decisions cannot invalidate each other
3. mark each selected item `claimed` before launching its worker
4. create one isolated worktree and branch per worker item from the current integration baseline
5. start or reuse one labelled Herdr worker tab per lane and provide the worktree path, item id, authority paths, scope boundary, and required return contract
6. verify that the Pi prompt was submitted and processing, not merely pasted visibly

Workers MUST NOT share an editable checkout. A separate Herdr tab or pane is not isolation. Read-only authority files may be read from the main checkout when they are not yet present in the worker baseline, but all proposed production edits and item-local records stay in the assigned worktree.

Do not claim together:

- an owner skill and a consumer whose proposal depends on the owner's final interface
- two items that edit the same skill, Reference, script, spec, notice, or generated artifact
- a correctness repair and a relocation that assumes the repair's outcome
- any item whose blocker is merely `ready-to-integrate` rather than `verified`

### Worker proposal and implementation loop

Each worker independently:

1. rereads the target's live source and all authorities listed by this ledger
2. writes only its item proposal while in `drafting`
3. records the standing authorization timestamp and current proposal revision
4. changes the proposal to `proposal-ready` only after exact file, behavior-ledger, contradiction, provenance, and verification scope checks pass
5. edits only the disclosed files, verifies them, and compares the actual diff with the current proposal
6. returns to `drafting` for any material proposal revision before continuing
7. marks the result `ready-to-integrate` only after focused verification passes
8. commits the proposal record and production changes on the item branch, then reports the branch, commit, baseline, files, checks, residual risks, and concise diff summary

Standing authorization is item-local through each proposal's exact scope. One worker's proposal does not expand another worker's allowed files or ownership decisions.

### Coordinator integration

The coordinator alone:

1. inspects the worker commit against its recorded baseline, current proposal revision, behavior ledger, standing-authorization record, and allowed file set
2. rejects undisclosed changes, missing authorization records, weak verification, stale dependencies, or edits to `pi/settings.json`
3. marks an accepted worker result `ready-to-integrate`, then integrates one worker commit at a time
4. stops on conflicts or semantic overlap; it never resolves a conflict by guessing the recorded intent
5. reruns focused verification after integration and updates `MIGRATION.md` to `verified`
6. recomputes the frontier before assigning either worker again

Do not treat a worker's success claim as integration evidence. The coordinator may request fixes on the original item branch; fixes that materially exceed the current proposal return to `drafting`. Worker tabs and worktrees remain until integration is verified or cleanup is safe.

### Human interaction contract

Workers continue autonomously under the standing directive and leave concise visible status containing the item id, proposal path, branch, and state. The human may pause, redirect, revise, or cancel work in any tab at any time; such a later directive supersedes standing authorization for affected items.

If the human wants to pause, create a timestamped handoff that records tab labels, item ids, branches, worktree paths, and states, but no live Herdr ids. The ledger and item proposals remain authoritative after resume.

## Sequence

The sequence follows WF-007: durable decisions, authoring owner, correctness repairs, direct normalization, progressive disclosure/composition, generic Git delivery, then catalog verification.

| ID | Kind | Target | Verdict or purpose | Blocked by | Status |
|---|---|---|---|---|---|
| `MG-001` | prerequisite | Durable terminology and body contract | Route WF-008/WF-006 decisions into specs | — | verified |
| `MG-002` | prerequisite | Provenance notices | Repair known Grill Me, Herdr, and Playwright notice gaps | MG-001 | verified |
| `SK-001` | skill | `write-a-skill` | simplify inline; become body-authoring owner | MG-001, MG-002 | verified |
| `SK-002` | skill | `bootstrap-specs` | simplify inline | SK-001 | verified |
| `SK-003` | skill | `gameplay-asset-imagegen` | simplify inline | SK-001 | verified |
| `SK-004` | skill | `herdr` | simplify inline | SK-001, MG-002 | verified |
| `SK-005` | skill | `playwright` | move detail to Reference | SK-001, MG-002 | verified |
| `SK-006` | skill | `ralph` | simplify inline | SK-001 | verified |
| `SK-007` | skill | `create-explainer` | simplify inline | SK-001 | verified |
| `SK-008` | skill | `test-quality-verifier` | retain substance; clarify routing | SK-001 | verified |
| `SK-009` | skill | `ubiquitous-language` | simplify inline | SK-001, MG-001 | verified |
| `SK-010` | skill | `update-specs` | retain substance; repair executable/ownership contract | SK-001, MG-001 | verified |
| `SK-011` | skill | `prototype` | simplify inline | SK-001 | verified |
| `SK-012` | skill | `audit-shared-skills` | simplify inline; remove unused Info severity | SK-001 | verified |
| `SK-013` | skill | `codebase-design` | retain substance | SK-001 | verified |
| `SK-014` | skill | `code-review` | retain substance | SK-001 | claimed |
| `SK-015` | skill | `create-plan` | simplify inline | SK-001 | queued |
| `SK-016` | skill | `diagnosing-bugs` | retain substance | SK-001 | queued |
| `SK-017` | skill | `design-md` | simplify inline | SK-001 | queued |
| `SK-018` | skill | `grill-me` | retain substance | SK-001, MG-002 | queued |
| `SK-019` | skill | `handoff` | retain substance | SK-001 | queued |
| `SK-020` | skill | `image-comparison-judge` | simplify inline | SK-001 | queued |
| `SK-021` | skill | `image-diff-describer` | retain substance | SK-001 | queued |
| `SK-022` | skill | `improve-codebase-architecture` | simplify inline | SK-001, SK-013 | queued |
| `SK-023` | skill | `research` | retain substance | SK-001 | queued |
| `SK-024` | skill | `resolving-merge-conflicts` | retain substance | SK-001 | queued |
| `SK-025` | skill | `tdd` | simplify inline | SK-001, SK-013 | queued |
| `SK-026` | skill | `video-to-contact-sheet` | simplify inline | SK-001 | queued |
| `SK-027` | skill | `visual-qa` | simplify inline | SK-001, SK-005, SK-021, SK-026 | queued |
| `SK-028` | skill | `wayfinder` | retain substance | SK-001 | queued |
| `SK-029` | skill | `teach` | move detail to Reference | SK-001, SK-007, SK-023 | queued |
| `SK-030` | skill | `create-agents-md` | move detail to Reference | SK-001 | queued |
| `SK-031` | skill | `curator` | move detail to Reference | SK-001 | queued |
| `SK-032` | skill | `em-train` | consolidate/delegate | SK-001, SK-007, SK-014 | queued |
| `NEW-001` | new skill | Generic Git delivery | independently invocable PR/CI/stale-branch owner | SK-001, SK-014, SK-024 | queued |
| `SK-033` | skill | `tmux-agent-orchestration` | consolidate/delegate | SK-001, NEW-001 | queued |
| `VG-001` | verification | Entire shared catalog | links, commands, support, provenance, behavior ledgers, frontmatter, visibility | MG-002, SK-001–SK-033, NEW-001 | queued |

A cancelled or invalidated item does not satisfy blockers automatically. The coordinator must derive and record a valid replacement route from the authority order or ask the human when the destination itself must change.

## Verification policy

For each implemented skill:

- Reread the resulting complete skill and every changed support file.
- Compare the result against its family-audit behavior ledger and WF-008 definitions.
- Confirm the four-section shape and conditional load wording.
- Validate relative Markdown links and supporting script syntax where applicable.
- Check executable commands against installed help or another authoritative source when command behavior changed.
- Run the shared-skill frontmatter audit under the existing union schema.
- Inspect `git diff -- <proposal-authorized files>` and confirm no undisclosed file changed.
- Report unresolved risks; do not call the item verified solely because Markdown parses.

The final catalog gate additionally checks all 33 original skills, the proposal-authorized Git-delivery addition if created, provenance/license notices, composition fallbacks, and Pi visibility. Repository specs and the migration ledger must agree on completed decisions.

## Current frontier

`MG-001` revision 2, `MG-002` revision 1, and SK-001 through SK-005 are verified. Parallel mode is active.

`MG-001` revision 2, `MG-002` revision 1, and SK-001 through SK-013 are verified. SK-014 remains claimed. SK-022 and SK-025 are now blocker-ready but remain queued until a disjoint lane is selected. No later production file is authorized without its item-specific exact proposal in `proposal-ready` state.

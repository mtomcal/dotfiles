# Migration Proposal Format

```markdown
---
id: <MG-001 | SK-001 | NEW-001 | VG-001>
target: <artifact or skill>
status: claimed | drafting | proposal-ready | editing | ready-to-integrate | integrating | verified
blocked-by: []
source-verdict: <verdict or prerequisite purpose>
---

# <Target>: <proposed change>

## Why this item is next
<Resolved blockers and sequence reason.>

## Evidence
<Wayfinder tickets, specs, current source, references, provenance, command help.>

## Exact files in scope
- `<path>` — <why it changes>

## Proposed changes
### Add
- ...

### Change or move
- ...

### Remove
- ...

## Proposed skill shape
1. `Language Definitions` — ...
2. `Workflow` — present/omitted; ...
3. `Activities` — present/omitted; ...
4. `Reference` — present/omitted; ...

Use “Not a skill body change” for prerequisite or verification items.

## Behavior-preservation checklist
- [ ] ...

## Dependencies, provenance, and risks
- ...

## Verification
- `<command>` — <expected evidence>

## Explicit exclusions
- ...

## Standing authorization
- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `<n>`
- Scope check: `<PASS only after authority, exact files, behavior ledger, contradiction, provenance, and verification review>`

After the scope check passes, mark the proposal `proposal-ready` and continue without a per-item human approval wait.
```

## Proposal rules

- State exact intended behavior, not merely “clean up” or “align with audit.”
- Name every file that the current proposal revision authorizes.
- Quote or summarize removals precisely enough to distinguish deletion from relocation.
- Keep required main-path rules inline even when literal templates move to Reference.
- `proposal-ready` is invalid if subsequent evidence materially changes the file set, ownership, behavior, or removals.
- Return to `drafting`, update the proposal, and repeat scope review after any material revision.
- Record the standing directive timestamp, exact proposal revision, and passing scope check before changing production files.
- In parallel mode, one proposal belongs to one worker worktree; its allowed scope never transfers between Herdr tabs or item branches.
- A worker may mark `ready-to-integrate`; only the coordinator may mark `integrating` or `verified` in central state.

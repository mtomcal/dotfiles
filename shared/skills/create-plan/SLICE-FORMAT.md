# Slice Packet Format

Load this reference when writing any `slices/NNN-<vertical-slice>.md`. One packet must fit one fresh agent context.

```markdown
# Slice NNN — <End-to-end behavior>

## Control data
- State: ready
- Blocked by: <slice ids or none>
- Branch: <assigned by parent>
- Worktree: <assigned by parent>
- Authorized scope: implement and commit only this slice

## Behavior
<What becomes observably true when this slice is complete.>

## Acceptance criteria
1. <Specific machine- or human-verifiable outcome>
2. <Boundary or failure behavior>

## Context and constraints
- Sources: <spec sections, decisions, research, existing code>
- Must preserve: <working behavior and compatibility constraints>
- Must not do: <adjacent work or speculative abstraction>

## Agreed test seam
- Public seam: <interface or workflow exercised>
- Test location: <likely path>
- Why this seam survives refactoring: <reason>

## Tracer-bullet cycles

### Cycle A — <first behavior>
#### RED
- Write one test proving: ...
- Run: `<focused command>`
- Required failure signal: ...

#### GREEN
- Minimum behavior change: ...
- Likely files: ...
- Run: `<focused command>`
- Required pass signal: ...

#### REFACTOR
- Cleanup after green, or `none`.
- Re-run: `<focused command>`

### Cycle B — <next behavior, only after A is green>
<Repeat RED, GREEN, REFACTOR.>

## Focused completion commands
1. `<targeted test>`
2. `<broader slice gate>`
3. `<lint/typecheck as applicable>`

## Required completion evidence
- commit hash on the assigned branch
- concise changed-file list
- every red command and observed failure signal
- every green/refactor command and observed pass signal
- acceptance-criteria evidence
- known risks or `none`
```

## Slicing rules

- Cut through all layers needed for one usable behavior; do not create schema-only, service-only, or UI-only packets unless that layer is itself the observable deliverable.
- Put only genuinely gating slices in `Blocked by`.
- One cycle means one failing behavior test followed by its minimum passing change.
- If the packet cannot fit one fresh context, split it before execution.
- Wide mechanical refactors may use expand–migrate–contract packets. Expansion preserves both forms, each bounded migration stays green, and contraction is blocked by every migration.

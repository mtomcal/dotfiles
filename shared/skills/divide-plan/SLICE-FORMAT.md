# Execution Slice Format

Directly apply this operational format to every `slices/NNN-<vertical-behavior>.md`. One packet must fit one fresh implementation-agent context.

```markdown
# Slice NNN — <Vertical behavior>

## Control data
- Ledger: <absolute execution-ledger path>
- Source plan: <absolute implementation-plan path>
- Source SHA-256: <digest>
- State: ready
- Blocked by: <slice ids or none>
- Assigned branch: <coordinator fills before launch>
- Assigned worktree: <coordinator fills before launch>
- Authorized scope: implement and commit only this slice; never edit ledger state

## Behavior
<One caller-visible or operational outcome delivered through all required layers.>

## Source traceability
- Implementation-plan steps/gaps: ...
- Spec requirements: ...
- Must preserve: ...
- Excluded adjacent work: ...

## Retained proposed execution trace(s)
<Every relevant source proposed execution trace, verbatim. Retain all traces that touch this slice's frames.>

## Slice-scope frame mapping
- Owned frames: <frames this slice implements or changes>
- Dependency frames: <frames this slice calls but does not own>
- Required ordering: <binding observable/safety-critical order this slice must honor>
- Proposed frames allowed to vary: <internal frames whose structure may change, with rationale>

## Acceptance and failure criteria
1. Acceptance: <specific machine- or human-verifiable outcome>
2. Failure: <boundary or incorrect behavior that must be distinguished>

## Public test seam
- Seam: <public interface or workflow>
- Test location: <likely path>
- Refactor resilience: <why this checks behavior rather than implementation shape>

## Tracer-bullet cycles

### Cycle A — <first observable increment>
#### RED
- Test to write: ...
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

### Cycle B — <next increment, only after A passes>
<Repeat RED, GREEN, and REFACTOR only when another cycle is required.>

## Focused completion commands
1. `<targeted behavior test>`
2. `<broader slice gate>`
3. `<lint, typecheck, or other applicable mechanical gate>`

## Required return evidence
- full commit hash on the assigned branch
- concise changed-file list within authorized scope
- every RED command and observed intended failure signal
- every GREEN/REFACTOR command and observed pass signal
- acceptance and failure-criteria evidence
- known risks or `none`
```

## Packet invariants

- Cut through every layer needed for one usable behavior; do not create horizontal packets unless the layer itself is the specified outcome.
- Put only genuinely gating integrated slices in `Blocked by`.
- One cycle is one intended failing behavior test followed by its minimum passing change and optional cleanup while green.
- If the packet cannot fit one fresh context, divide it before launch.
- For wide changes, expansion preserves old and new forms, bounded migration packets stay green, and contraction is blocked by every migration.
- The coordinator owns packet state. The implementer edits only the assigned checkout and returns evidence.
- Retain every relevant source proposed execution trace verbatim; never rewrite or summarize it. The slice-scope frame mapping is added separately and must not alter the retained trace.
- Every binding frame and required order in a retained trace maps to at least one slice; permitted deviations from proposed internal frames appear in returned evidence.

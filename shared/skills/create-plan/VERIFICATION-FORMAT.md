# Verification Artifact Format

Load this reference when selecting review passes or writing `verifications/*.md`. Review artifacts are flat files owned by the parent agent.

## Risk matrix

Standards and Spec are always enabled and independently executed.

| Pass | Enable when | Typical evidence |
|---|---|---|
| Tests | Behavior, tests, public seams, regressions, or migrations changed | focused/full test output; assertion review |
| Premortem | Failure can emerge only in integration, operation, concurrency, migration, recovery, or human use | ranked failure modes and mitigations |
| Security | Trust boundaries, credentials, permissions, untrusted input, dependencies, network, or sensitive data changed | threat paths and control checks |
| Visual | Layout, rendering, responsive behavior, motion, screenshots, video, or design fidelity changed | captures, console/network checks, visual criteria |

A pass may be disabled only with a written rationale in `PLAN.md`.

## Per-slice naming

Use `<slice-number>-<pass>.md`, for example:

- `001-standards.md`
- `001-spec.md`
- `001-tests.md`
- `001-premortem.md`
- `001-security.md`
- `001-visual.md`

## Artifact template

```markdown
# Slice NNN — <Pass> Verification

## Scope
- Slice: <packet path>
- Branch: <slice branch>
- Fixed point: <full worker/fix commit hash>
- Diff: <stable command or range>

## Reviewer
- Agent: Pi | in-process fallback
- Model: <explicit model>
- Thinking: <explicit level>
- Independence: <what context/axis was intentionally isolated>

## Criteria
1. ...
2. ...

## Attempt 1 — <timestamp>
- Verdict: PASS | NEEDS-FIX | BLOCKED
- Evidence: ...
- Commands: ...
- Findings/remediation: ...

## Attempt 2 — <timestamp, append after a fix>
- Fixed point: <new full hash>
- Verdict: ...
- Evidence: ...
- Commands: ...
- Findings/remediation: ...
```

Do not overwrite failed history. A new attempt records the new fixed point and verdict in the same file.

## Axis boundaries

- **Standards** reads repository guidance and reports conformance violations or clearly labelled judgement calls.
- **Spec** reads the originating requirement and reports fidelity, omissions, and unrequested behavior.
- Neither pass may waive the other.
- Reviewers return findings only. The parent records the artifact and state transition.

## Final reviews

`final-integration.md` uses the same shape but reviews the integrated branch for cross-slice interactions, conflicts, migration ordering, and complete repository gates.

`final-acceptance.md` reviews the integrated result against the immutable objective, every global acceptance criterion, and required human/visual evidence. Both must pass before the plan is complete.

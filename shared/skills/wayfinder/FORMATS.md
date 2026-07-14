# Wayfinder Markdown Formats

Load this reference whenever creating or changing a Wayfinder map or ticket.

## `MAP.md`

```markdown
# <Effort title> Wayfinder Map

## Destination
<One or two lines defining the planning-ready, spec-ready, or decision-ready endpoint.>

## Context and notes
- Relevant specs: ...
- Relevant code/research: ...
- Standing constraints: ...

## Decisions so far
- <Ticket title as a relative Markdown link> — <one-line gist; detail stays in the ticket>

## Not yet specified
- <In-scope uncertainty that cannot yet be phrased as a precise question>

## Out of scope
- <Ruled-out work and why; link a ticket if one was closed as out-of-scope>
```

Keep all four sections. Use `None` for empty sections so absence is explicit.

## Decision ticket

```markdown
---
id: WF-001
type: research | prototype | grilling | task
status: open | in-progress | resolved | out-of-scope
blocked-by: []
---

# <Descriptive decision title>

## Question
<One precise uncertainty this ticket resolves.>

## Why it matters
<Which destination choice waits on this answer.>

## Completion evidence
<What facts, user decision, or prototype reaction are sufficient to resolve it.>

## Resolution
<Empty while open. On completion: answer, evidence/source pointers, implications, and newly surfaced uncertainty.>
```

## State and dependency rules

- `id` is stable within the effort; filenames begin with the same numeric sequence.
- `blocked-by` contains ticket ids from the same effort.
- `open -> in-progress -> resolved` is the normal flow.
- Any non-final ticket may become `out-of-scope` when the destination excludes it; record why.
- The Frontier is derived from `open` tickets with every blocker `resolved`.
- A `resolved` ticket's answer remains in its Resolution section. The map links and gists it without copying detail.
- Never store Herdr pane ids, transient process ids, or conversation-only claims as durable evidence.

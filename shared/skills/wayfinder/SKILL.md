---
name: wayfinder
description: Resolve a large effort's uncertainty through a specs-first map of decision tickets, dependency frontiers, fog of war, and explicit scope boundaries. Use when the destination is too uncertain or broad for one planning context and implementation must wait until the route is clear.
metadata:
  short-description: Map and resolve decision uncertainty
allowed-tools: read,write,edit,bash
---

# Wayfinder

Wayfinder finds the route to a **destination**; it does not implement the destination. Its durable state is plain Markdown under `.wayfinder/`, with no required issue tracker or database.

## Core model

- **Destination**: the observable decision, spec-ready outcome, or planning-ready change this effort is finding a route toward. It fixes scope.
- **Decision ticket**: one session-sized uncertainty whose resolution advances the route. It is not an implementation slice.
- **Fog of war**: in-scope uncertainty that is visible but not yet precise enough to state as a ticket.
- **Frontier**: open tickets whose blockers are resolved and which may be worked now.
- **Out of scope**: work consciously beyond the destination. It never graduates from fog unless the destination is explicitly redrawn.

Use canonical domain terms from `specs/UBIQUITOUS_LANGUAGE.md` or a root `UBIQUITOUS_LANGUAGE.md`. Cross-check the destination and known constraints against relevant specs and code before asking the user questions that evidence can answer.

## 1. Open or chart an effort

Store one effort at:

```text
.wayfinder/<effort-slug>/
├── MAP.md
└── tickets/
    ├── 001-<decision>.md
    └── 002-<decision>.md
```

If the effort exists, load `MAP.md` and only the frontier tickets needed for the current decision. If it does not exist:

1. Use `grill-me` to name a concrete destination and scope boundary.
2. Explore breadth-first across the decision space. Separate sharp questions from fog.
3. If the route is already clear and fits one planning context, do not create a map; route directly to `create-plan`.
4. Ask before creating `.wayfinder/<effort-slug>/`.
5. Read [FORMATS.md](FORMATS.md), write the map and currently specifiable tickets, then add blocking edges in a second pass.

The parent agent is the sole writer of `MAP.md` and ticket state. Completion criterion: the destination is stable, every live ticket is a decision or uncertainty-unblocking task, and the derived frontier is non-contradictory.

## 2. Choose one frontier ticket

Derive the frontier: tickets with `status: open` whose `blocked-by` tickets are all `resolved`. Never treat `out-of-scope` as satisfying a blocker without first revising the dependent ticket or its edge.

If the user named a valid frontier ticket, use it; otherwise take the first frontier ticket in numeric order. The parent changes its status to `in-progress` before work. Work one decision ticket per session unless independent research tickets can safely run in parallel.

Completion criterion: exactly one non-research decision is claimed, and no unresolved blocker is bypassed.

## 3. Resolve uncertainty, not implementation

Use the ticket type to choose the workflow:

- `research`: compose the `research` skill for primary-source or code evidence.
- `prototype`: compose `prototype` to create a cheap reaction surface; preserve the conclusion, then remove or isolate throwaway code.
- `grilling`: compose `grill-me`; the human supplies their side of human-in-the-loop decisions.
- `task`: perform only the prerequisite work needed to expose facts for a later decision. Do not deliver the destination.

### Herdr delegation

When `HERDR_ENV=1`, load the shared `herdr` skill and use sibling panes for independent read-only investigations where useful. Delegates return findings through their pane output; they MUST NOT edit `.wayfinder/` state. Re-read live pane ids whenever controlling panes and never persist pane ids in the map or tickets because ids compact.

Read-only delegates may share the checkout. Any delegate that must edit a prototype or other artifact needs an isolated worktree or clone. Outside Herdr, perform the same investigation in-process, preserving source notes before synthesis.

If resolution starts turning into production implementation, stop: that pull marks the edge of the map. Capture the decision and defer execution to `create-plan`.

Completion criterion: the ticket has evidence sufficient for one explicit answer, and no production behavior was opportunistically implemented.

## 4. Record the resolution and clear new fog

The parent writes the resolution in the ticket, then:

1. set `status: resolved`, or `out-of-scope` if evidence places it beyond the destination
2. append one linked gist under `MAP.md`'s Decisions so far only for resolved route decisions
3. add newly sharp decision tickets and wire their blockers
4. graduate newly specifiable fog into tickets and remove that fog text from the map
5. revise invalidated tickets or edges rather than preserving a known-wrong route
6. list ruled-out work under Out of scope with a reason and ticket link when applicable

A decision lives in detail in one ticket; the map is only a low-resolution index. Refer to tickets by descriptive title in human-facing prose, with the relative link carrying the id.

Completion criterion: each fact has one durable home, map sections are mutually exclusive, and the frontier can be recomputed from ticket files alone.

## 5. Complete the effort

The effort is complete when the destination is clear, no open or in-progress tickets remain, and no in-scope fog remains. Then:

- route durable behavioral, design, and terminology decisions through `update-specs` (and `ubiquitous-language` when terms changed)
- route implementation work through `create-plan`
- keep `.wayfinder/` as the decision trail unless the repository's documented artifact policy says otherwise

Do not call the effort complete merely because the current frontier is empty; an empty frontier with unresolved tickets means blocked or inconsistent state.

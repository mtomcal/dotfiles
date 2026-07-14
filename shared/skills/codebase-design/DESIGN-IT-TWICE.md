# Design It Twice

Use this branch for consequential interfaces or when the user asks for alternatives. Read [SKILL.md](SKILL.md) and, when dependencies matter, [DEEPENING.md](DEEPENING.md).

## Frame the design

State the domain capability, constraints, dependency categories, invariants, errors, ordering, and current friction. A small code sketch may illustrate constraints, but it is not the first proposal.

## Produce independent alternatives

Create at least three genuinely different interfaces:

1. **Minimal surface** — maximize leverage through one to three entry points.
2. **Flexible surface** — support the justified variation without speculative hooks.
3. **Common-path surface** — make the dominant caller trivial while preserving invariants.
4. **Adapter-led surface** — add when a real remote or external seam dominates the design.

When `HERDR_ENV=1`, load the `herdr` skill and prefer parallel read-only agents for these alternatives. They may share the checkout. Otherwise, produce the alternatives directly in-process, completing one independent design brief before comparing them. Any future delegated agent that edits must use an isolated clone or worktree.

Each alternative must include:

- the complete interface, including invariants and error modes
- one representative caller example
- what the implementation hides
- seam and adapter placement
- testing strategy
- trade-offs in depth, leverage, and locality

## Compare and recommend

Present each design before synthesis. Compare depth, locality, leverage, seam placement, common-path ergonomics, and migration cost. Recommend one design or a precise hybrid; explain which constraints make it strongest.

Completion criterion: at least three complete alternatives were considered independently and the recommendation is falsifiable against the stated constraints.

# 0012 — Right-sized agent engineering

**Status:** Superseded by [0014](0014-model-native-agent-environment.md)

**Created:** 2026-08-08

## What shipped

The solo developer can choose an engineering workflow proportionate to the work while keeping one durable execution model. A bounded change or exploratory build uses lightweight mode: one direct executor turns a concise approved scope into a small execution molecule, performs the work in the current checkout, verifies or demonstrates the result, commits it, and records the evidence in Beads. It does not create a coordinator, worker fleet, independent review topology, or terminal orchestration merely to complete a small task.

Larger or policy-sensitive work uses coordinated mode. It retains recoverable multi-agent execution, isolated integration, independent review, exact role assignments, and explicit remediation. Planning recommends a mode from the work's shape and risks, explains that recommendation, and lets the developer override it unless repository or approved-scope policy requires independent actors or incompatible isolation.

Both modes use an execution molecule, so work can grow without abandoning its approved scope or history. If lightweight execution exposes more complexity than expected, the direct executor records a committed fixed point and the reason for stopping. With developer approval, the same molecule gains the coordinated policy and work needed for a fresh coordinator to resume it. Coordinated execution does not silently downgrade after workers begin.

Exploratory work is a first-class delivery intent rather than shippable work with invented tests. The direct executor produces a runnable learning surface, records what was learned and its limitations, and finishes with an explicit disposition: discard it, retain it as-is, or rebuild it properly. A rebuild starts a linked shippable molecule from a clean production base; exploratory code remains evidence rather than becoming the presumed implementation. Retained exploratory code may enter the main line only when the developer explicitly accepts its known debt and minimum repository safety checks pass.

After activation, the developer receives a temporary visual map of the molecule's work, dependencies, frontier, execution mode, and gates. The map is disposable and read-only; Beads remains authoritative. It can be refreshed on demand until a dedicated dashboard replaces it.

## Why it exists

The recoverable engineering workflow was designed for long-running multi-agent features. Applying its coordinator, worktree, review, assignment, ingestion, and synchronization machinery to a trivial change costs more attention than the change itself. That pressure encourages either avoiding durable planning or pretending small work needs a parallel orchestration graph.

Exploration has a different failure mode. Quick, deliberately rough code is useful for finding unknown constraints, but forcing it through production TDD obscures its purpose, while casually promoting it loses the distinction between evidence and maintained implementation. Two explicit execution modes and two delivery intents preserve that distinction without creating separate planning systems.

## Out of scope

- Building or selecting the future web-based Beads dashboard.
- Weakening coordinated mode's recovery, isolation, assignment, integration, or independent-review guarantees.
- Treating a temporary molecule map as editable or authoritative workflow state.
- Automatically promoting exploratory code into maintained production code.
- Supporting multiple concurrent coordinators or distributed execution authority.

## FAQ

**Why do both modes use an execution molecule?**

One durable artifact preserves scope, history, evidence, and links when a small task grows. Separate lightweight plans and plain standalone beads were rejected because promotion would require reconstructing intent or creating a second authority.

**Revisit if:** Beads provides a smaller artifact that can be promoted transactionally without changing identity, losing history, or duplicating authority.

**Why does lightweight mode use a direct executor?**

The invoking agent may implement, verify, commit, and record its own work because no separate worker side effect needs coordination. Requiring a non-implementing coordinator or independent reviewer was rejected for bounded work because it recreates the overhead this mode removes. The self-check never claims reviewer independence.

**Revisit if:** Measured lightweight failures show that separating execution authority materially improves outcomes enough to justify the routine cost.

**When is coordinated mode mandatory?**

It is mandatory when repository or approved-scope policy requires independent actors, concurrent agents, or isolation incompatible with direct execution. Making every risk or size heuristic mandatory was rejected because the developer remains the final authority over advisory tradeoffs.

**Revisit if:** Repeated overrides produce preventable failures, or repository policy adopts additional non-overridable execution requirements.

**Why can lightweight work use the current checkout?**

A single direct executor does not need worktree isolation from parallel workers. A final commit remains required so Beads can identify the completed result. Mandatory worktrees were rejected as coordination overhead without a concurrent actor.

**Revisit if:** Current-checkout execution repeatedly contaminates unrelated work despite explicit handling of pre-existing changes.

**Why may lightweight completion remain locally synchronized only?**

A remote Beads outage should not hold a bounded task open after its local evidence and commit are complete. The molecule remains visibly pending synchronization and is reconciled by later Beads activity. Coordinated completion keeps its stricter remote checkpoint.

**Revisit if:** Pending lightweight checkpoints are routinely lost or remain unreconciled.

**Why are exploratory and shippable work different delivery intents?**

Exploration optimizes for learning through a runnable demonstration; shippable work optimizes for maintained behavior through repository verification. Inventing RED/GREEN cycles for disposable code and treating rough code as production-ready were both rejected because they erase the reason for exploring.

**Revisit if:** Repository tooling can preserve exploratory speed while proving production fitness without a separate intent boundary.

**Why does rebuilding create a linked shippable molecule?**

The exploration's question and learning criteria differ from production acceptance. Mutating the exploratory scope was rejected because it would hide the transition from evidence gathering to maintained implementation and encourage building directly on disposable structure.

**Revisit if:** A proven promotion process can preserve both scopes and demonstrate that reused code receives normal production verification without historical ambiguity.

**Why is the molecule map temporary and non-authoritative?**

The developer needs immediate visibility into graph shape without creating another state store. An editable or durable duplicate was rejected because it could drift from Beads.

**Revisit if:** A web-based Beads dashboard provides equivalent graph, frontier, mode, and gate visibility.

## Open questions

None

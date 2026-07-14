---
name: codebase-design
description: Design deep modules and their interfaces using shared architecture vocabulary. Use when designing or improving an interface, choosing a seam, comparing module shapes, improving testability, or when another skill needs deep-module guidance.
metadata:
  short-description: Design deep modules and interfaces
allowed-tools: read,bash
---

# Codebase Design

## Language Definitions

Prefer the project's domain terms from `specs/`, especially `specs/UBIQUITOUS_LANGUAGE.md`, when they overlap with this skill's operational vocabulary.

- **Module** — anything with an interface and hidden implementation.
- **Interface** — everything callers must know, including operations, types, invariants, ordering, errors, configuration, and relevant performance constraints.
- **Implementation** — behavior hidden behind the interface.
- **Depth** — leverage relative to interface complexity. A **deep module** exposes much behavior through a small interface; a **shallow module** makes callers learn nearly as much as its implementation contains.
- **Seam** — place where behavior can vary without changing the caller, distinct from a DDD boundary.
- **Adapter** — concrete implementation satisfying an interface at a seam.
- **Leverage** — capability gained per unit of interface learned.
- **Locality** — concentration of related change, knowledge, bugs, and verification.

Use narrower terms such as HTTP API or type signature only when that narrower meaning is intended.

## Workflow

1. Select the route before designing:
   - For a consequential interface or requested alternatives, use Design It Twice.
   - If consolidation or dependency classification also applies, load DEEPENING.md directly from this skill's Reference section and use it with the selected route.
   - Otherwise, use Deepening for module consolidation or dependency classification.
   - Use direct design when neither specialized route applies.

   Load every selected support file from `Reference` before continuing.
2. Read the relevant specs, glossary, requirements, and nearby code. State the domain capability, constraints, and invariants the module must own. Design for caller leverage, maintainer locality, and behavior tests that survive implementation changes.
3. Place the seam, identify dependencies, and apply every design test:
   - **Depth belongs to the interface.** Keep private implementation seams hidden from callers.
   - **Deletion test.** If deleting the module makes complexity disappear, it was pass-through; if complexity spreads back into callers, the module earned its place.
   - **The interface is the test surface.** Callers and behavior tests cross the same seam; do not expose an internal seam merely for testing.
   - **Two adapters justify a seam.** One adapter usually means hypothetical indirection; production plus a justified test adapter is real variation.
   - **Design it twice.** Compare meaningfully different interfaces before committing to a consequential one.
4. Compare interface alternatives by depth, locality, leverage, errors, and test surface. Follow every additional comparison and completion gate in the selected support branch.
5. Recommend one design and record each durable invariant in the spec or plan that owns it.

Completion criterion: the recommendation names the interface callers learn, what the implementation hides, where each seam sits, which adapters are justified, and how behavior is verified.

## Reference

- When consolidating modules or classifying dependencies, load [DEEPENING.md](DEEPENING.md) to apply the dependency categories, consolidation path, and deepening completion test.
- When the interface is consequential or alternatives are requested, load [DESIGN-IT-TWICE.md](DESIGN-IT-TWICE.md) to produce independent complete alternatives and a falsifiable recommendation.

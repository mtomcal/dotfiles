---
name: codebase-design
description: Design deep modules and their interfaces using shared architecture vocabulary. Use when designing or improving an interface, choosing a seam, comparing module shapes, improving testability, or when another skill needs deep-module guidance.
metadata:
  short-description: Design deep modules and interfaces
allowed-tools: read,bash
---

# Codebase Design

Design **deep modules**: substantial behavior behind a small interface at a deliberate seam. The goals are leverage for callers, locality for maintainers, and tests that survive implementation changes.

## Vocabulary

Use these terms consistently while this skill is active. Prefer the project's domain terms from `specs/`, especially `specs/UBIQUITOUS_LANGUAGE.md`, for what modules are called.

- **Module** — anything with an interface and an implementation: a function, class, package, or cross-tier slice.
- **Interface** — everything callers must know: operations, types, invariants, ordering, errors, configuration, and relevant performance constraints.
- **Implementation** — behavior hidden inside a module.
- **Depth** — leverage at the interface. A **deep** module exposes much behavior through a small interface; a **shallow** module makes callers learn nearly as much as its implementation contains.
- **Seam** — the place where behavior can vary without editing the caller; the location of an interface.
- **Adapter** — a concrete implementation that satisfies an interface at a seam.
- **Leverage** — capability callers gain per unit of interface they learn.
- **Locality** — concentration of change, bugs, knowledge, and verification in one module.

Use `seam` rather than the overloaded DDD term `boundary`. Use narrower terms such as HTTP API or type signature only when that narrower meaning is intended.

## Principles

- **Depth belongs to the interface.** Internals may contain private seams without exposing them to callers.
- **Deletion test.** Imagine deleting the module. If complexity disappears, it was pass-through; if complexity spreads back into callers, the module was earning its place.
- **The interface is the test surface.** Callers and behavior tests should cross the same seam.
- **Two adapters justify a seam.** One adapter usually means hypothetical indirection; production plus a justified test adapter is a real variation.
- **Design it twice.** Compare meaningfully different interfaces before committing to a consequential one.

## Design pass

1. Read the relevant specs, glossary, requirements, and nearby code.
2. State the domain capability and constraints the module must own.
3. Place the seam and classify dependencies.
4. Compare interface alternatives by depth, locality, leverage, errors, and test surface.
5. Recommend one design and record any durable invariant in the spec or plan that owns it.

Completion criterion: the recommendation names the interface callers learn, what the implementation hides, where each seam sits, which adapters are justified, and how behavior is verified.

## Context pointers

- When consolidating modules or classifying dependencies, read [DEEPENING.md](DEEPENING.md).
- When the interface is consequential or alternatives are requested, read [DESIGN-IT-TWICE.md](DESIGN-IT-TWICE.md).

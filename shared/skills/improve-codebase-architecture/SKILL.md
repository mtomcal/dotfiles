---
name: improve-codebase-architecture
description: Find deepening opportunities in a codebase, informed by project specs in specs/. Use when the user wants to improve architecture, find refactoring opportunities, consolidate tightly-coupled modules, or make a codebase more testable and AI-navigable.
metadata:
  short-description: Find and fix architectural friction
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability.

## Glossary

Use these terms exactly in every suggestion. Consistent language is the point — don't drift into "component," "service," "API," or "boundary." Full definitions in [LANGUAGE.md](LANGUAGE.md).

- **Module** — anything with an interface and an implementation (function, class, package, slice).
- **Interface** — everything a caller must know to use the module: types, invariants, error modes, ordering, config. Not just the type signature.
- **Implementation** — the code inside.
- **Depth** — leverage at the interface: a lot of behaviour behind a small interface. **Deep** = high leverage. **Shallow** = interface nearly as complex as the implementation.
- **Seam** — where an interface lives; a place behaviour can be altered without editing in place. (Use this, not "boundary.")
- **Adapter** — a concrete thing satisfying an interface at a seam.
- **Leverage** — what callers get from depth.
- **Locality** — what maintainers get from depth: change, bugs, knowledge concentrated in one place.

Key principles (see [LANGUAGE.md](LANGUAGE.md) for the full list):

- **Deletion test**: imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep.
- **The interface is the test surface.**
- **One adapter = hypothetical seam. Two adapters = real seam.**

This skill is _informed_ by the project's specs. The `specs/` folder is the first place to look for domain language, architectural intent, product constraints, test expectations, and known trade-offs. Let those specs supply the names for good seams and the constraints a deepened module must preserve.

## Process

### 1. Explore

Read existing documentation first:

- `specs/README.md`, `specs/SPEC-OF-SPECS.md`, or any equivalent spec index if present
- Specs that match the area under review, such as domain specs, architecture specs, deployment specs, and test indexes
- Any nearby design notes the repo already uses, when linked from the specs

If these files don't exist, proceed silently — don't flag their absence or suggest creating them upfront. If `specs/` exists but lacks an obvious index, skim filenames and read only the specs relevant to the architectural area being reviewed.

Then use the Agent tool with `subagent_type=Explore` to walk the codebase. Don't follow rigid heuristics — explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow** — interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it concentrate complexity, or just move it? A "yes, concentrates" is the signal you want.

### 2. Present candidates

Present a numbered list of deepening opportunities. For each candidate:

- **Files** — which files/modules are involved
- **Problem** — why the current architecture is causing friction
- **Solution** — plain English description of what would change
- **Benefits** — explained in terms of locality and leverage, and also in how tests would improve

**Use specs vocabulary for the domain, and [LANGUAGE.md](LANGUAGE.md) vocabulary for the architecture.** If a spec defines "Match," talk about "the Match flow module" — not "the FooBarHandler," and not "the Match service."

**Spec tension**: if a candidate appears to contradict a spec, only surface it when the friction is real enough to warrant changing either the code or the spec. Mark it clearly (e.g. _"tension with `specs/match.md` — worth revisiting because..."_). Don't list every theoretical refactor a spec might constrain.

Do NOT propose interfaces yet. Ask the user: "Which of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, drop into a grilling conversation. Walk the design tree with them — constraints, dependencies, the shape of the deepened module, what sits behind the seam, what tests survive.

Side effects happen inline as decisions crystallize:

- **Naming a deepened module after a concept not covered by the specs?** Update the most relevant spec, or create a small focused spec under `specs/` if no existing spec owns that concept.
- **Sharpening a fuzzy term during the conversation?** Update the relevant spec right there so future architecture work uses the same name and invariant.
- **User rejects the candidate with a load-bearing reason?** Offer to record that reason in the relevant spec so future architecture reviews don't re-suggest it. Only offer when the reason would actually be needed by a future explorer — skip ephemeral reasons ("not worth it right now") and self-evident ones.
- **Want to explore alternative interfaces for the deepened module?** See [INTERFACE-DESIGN.md](INTERFACE-DESIGN.md).

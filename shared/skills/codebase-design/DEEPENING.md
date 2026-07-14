# Deepening Modules

Use the vocabulary and principles in [SKILL.md](SKILL.md).

## Classify dependencies

The dependency category determines how the deepened module is verified across its seams.

1. **In-process** — pure computation or in-memory state. Consolidate and test directly through the module interface; no adapter is needed.
2. **Local-substitutable** — filesystem, database, or similar dependency with a faithful local stand-in. Keep that seam inside the implementation and test with the stand-in.
3. **Remote but owned** — another system the project controls. Put an interface at the transport seam; use a production transport adapter and a faithful in-memory or local adapter for tests.
4. **True external** — a third-party system. Inject a narrow interface owned by this codebase and use a controlled test adapter at that external seam.

Do not expose an internal seam merely because a test uses it. An adapter should vary something real, not provide indirection by default.

## Deepening pass

1. Name the behavior and invariants currently spread across modules.
2. Apply the deletion test to each shallow candidate.
3. Choose the seam that gives callers the smallest coherent interface.
4. Move orchestration and invariants behind that interface.
5. Replace tests of obsolete shallow interfaces with behavior tests at the agreed interface.
6. Delete superseded pass-through modules and tests once the replacement is green.

Completion criterion: complexity has locality in the deepened module, callers gain leverage through a smaller interface, and tests observe behavior without reaching through the seam.

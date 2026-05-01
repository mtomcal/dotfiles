# Context Engines — Worked Patterns

Concrete examples showing how different context engines shape real plan sections.

## Spec-Driven Example (Stick-Rumble)

### Title & Context Basis
```markdown
# Live Player Footprint Implementation Plan
## Flush Blocker Contact + Stable Dodge Roll Body

**Based on spec commit:** `18f0a76` - `fix(specs): define flush blocker contact for live player body`
```

### Spec Delta
```markdown
## Spec Delta To Implement

1. The live player's collision-carrying visible body must derive directly from PLAYER.WIDTH and PLAYER.HEIGHT.
2. The visible body's outer extents must match the authoritative hitbox within 1 rendered pixel per side.
3. The live body must stay axis-aligned in idle, movement, aim, and dodge roll states.
4. Dodge roll may add flair, but it may not rotate, hide, shrink, stretch, or otherwise distort the live collision-reading body.
5. Obstacle rendering must support the obstacle rectangle boundary as the real readable blocking edge.
6. Shipped map coverage must include representative blocker-contact checks for solid obstacle families.
```

### Current Code State
```markdown
### What is already correct
- Server collision clamps against obstacles with PlayerWidth/2 and PlayerHeight/2 in physics.go.
- Client prediction mirrors that same obstacle resolution in PredictionEngine.ts.
- Shared constants already define PLAYER.WIDTH = 32 and PLAYER.HEIGHT = 64.

### What is currently out of spec
- ProceduralPlayerGraphics.ts draws a small rotated stick figure whose main visible mass is a head circle, not a stable 32x64 live-body footprint.
- PlayerManager.ts rotates the live body 360 degrees during roll and flickers it invisible during i-frames.
- GameScene.ts draws obstacle outlines not explicitly locked to the authoritative blocker edge contract.

### Important implementation constraint
Do not change movement or server-authoritative collision rules unless a red test proves a true geometry mismatch. The spec change is about visible contact readability, not about inventing a new physics shape.
```

### Red/Green Slice

```markdown
### Slice 2: Preserve the live-body footprint through dodge roll

#### Red

Tests to write **before** touching implementation code:

- Test file: `stick-rumble-client/src/game/entities/PlayerManager.test.ts`
- What the test proves: live body must not rotate or flicker during dodge roll
- Assertion strategy: check rotation and visibility state on roll enter/during/exit
- Existing tests to rewrite: tests that endorse 360-degree rotation or body flicker

Run the test suite. You must see the test fail (rotation/flicker still happening, test catches it) before touching PlayerManager.ts.

#### Green

Implementation changes to make the red test pass (only after observing the red failure):

- Source file: `stick-rumble-client/src/game/entities/PlayerManager.ts`
- What to change: stop calling live-body `setRotation(...)` and `setVisible(...)` for roll presentation
- Constraint: minimal change — do not add new flair systems, just remove the wrong behavior
- Decisions/spec delta this satisfies: spec item 4 ("dodge roll may not rotate, hide, shrink, stretch, or otherwise distort the live collision-reading body")

#### Refactor

- If a secondary flair hook is introduced, keep it off the collision-reading body
- Test flair separately from the body contract
```

### Verification Pass
```markdown
#### Test verifier pass 2

Use `test-quality-verifier` on:
- stick-rumble-client/src/game/entities/PlayerManager.test.ts

Prompt focus:

`Review the recent dodge-roll presentation test changes. Identify vague assertions,
any hidden dependency on old rotation/flicker behavior, and missing checks that
the live body remains visible and axis-aligned during roll.`
```

---

## Decision-Driven Example (Pi Subagent Extension)

### Title & Context Basis
```markdown
# Ad-Hoc Subagent Extension — Implementation Plan

> **Status: PLANNING** — 18 design decisions resolved. Ready for TDD implementation.
```

### Decisions Table
```markdown
## Design Decisions (Resolved)

| # | Decision | Choice |
|---|----------|--------|
| 1 | Mental model | Tasks with config (not agents) |
| 2 | systemPrompt priority | Replace agent preset. Consistent overrides for all fields |
| 3 | Minimum required | Just task (bare-task = isolated context pattern) |
| 4 | LLM guidance | Frame primary path, bare task documented as specific use case |
| 5 | Model shorthand | Allowed but not advertised in descriptions |
| 6 | Default tools | All tools, description nudges toward scoping |
| 7 | Per-item config | Full config on each tasks[]/chain[] item |
| 8 | Naming | agent → name, label-only, no lookup |
| 9 | Agent files | Dead. Skills teach. Pure LLM instructions |
| 10 | agents.ts | → subagent-config.ts (keep parseModelField, normalizeOptional, new SubagentConfig) |
```

### Current Code State (decision-driven variant)
```markdown
### What is already correct
- JobManager handles async job lifecycle correctly.
- Notification system via pi.sendMessage() works.
- Tool registration pattern is established.

### What is currently out of alignment with decisions
- agents.ts discovers agent .md files — decision 9 says agent files are dead.
- AgentScope and discoverAgents must be removed.
- `agent` parameter must be renamed to `name` (decision 8).
- subagent-config.ts does not exist yet (decision 10).
```

### Red/Green Slice (decision-tracing variant)

```markdown
### Cycle 1: subagent-config.ts — Config Types and Resolution

#### Red

Tests to write **before** touching implementation code:

- Test file: `tests/subagent-config.test.ts`
- What the test proves: config resolution matches all 10 resolved decisions
- Assertion strategy: direct assertion on resolved config fields
- Existing tests to rewrite: none (new module)
- Specific test cases that must fail on current code:
  - bare task returns defaults with identity injection (decision 3)
  - systemPrompt replaces injected identity (decision 2)
  - name defaults to auto-derived from task (decision 8)
  - model shorthand parses provider and thinking (decision 5)
  - per-item values override top-level (decision 7)

All tests must fail — `subagent-config.ts` does not exist yet. Run the test suite to confirm every new test fails before writing implementation.

#### Green

Implementation changes to make the red test pass (only after observing the red failure):

- Source file: `subagent-config.ts` (new file)
- What to create: `resolveConfig`, `deriveName`, `parseModelField`, `parseTools` per decisions 1-10
- Constraint: no Pi extension imports — pure TypeScript, no framework dependency
- Decisions this satisfies: 1, 2, 3, 5, 7, 8, 10

#### Refactor

- Extract `BARE_TASK_INJECTION` constant
- Ensure `deriveName` edge cases (leading non-alpha, short words) are solid
```

### Reviewer Findings (from pre-implementation review)
```markdown
## Reviewer Findings (Addressed)

| Finding | Severity | Fix |
|---------|----------|-----|
| SubagentDetails retains agentScope/projectAgentsDir | Critical | Cycle 4+8: explicitly remove from interface |
| No backward-compat deserialization for agent → name | Critical | Cycle 2: d.name ?? (d as any).agent ?? "unknown" guard |
| Shorthand provider lost when per-item model replaces top-level | Critical | Cycle 1: fallback parse of topLevel.model shorthand |
| deriveName can produce leading-hyphen names | Critical | Cycle 1: sanitize leading non-alpha, add test |
```

---

## Hybrid Example (Hypothetical)

A plan that uses specs for the rendering contract but decisions for the data persistence approach.

### Title & Context Basis
```markdown
# Player Profile Overlay — Implementation Plan
## In-Game Profile + Leaderboard Integration

**Based on spec commit:** `a1b2c3d` - `feat(specs): add player profile overlay spec v1.0.0`

> **Status:** Rendering behavior is spec-driven (specs/ui.md v2.1.0). Data caching
> and offline behavior are decision-driven (3 decisions from design session 2025-04-28).
```

### Mixed Context Input
```markdown
## Spec Delta (rendering)

1. Profile overlay must render within 200ms of trigger.
2. Overlay must show player name, level, stats, and recent match history.

## Decisions (data access)

| # | Question | Decision | Source |
|---|----------|----------|--------|
| Q1 | Cache strategy? | Read-through cache with 5-min TTL | Design session: 3 cache strategies evaluated |
| Q2 | Offline behavior? | Show last cached profile with stale badge | Spike: full offline would double scope |
| Q3 | Real-time updates? | Poll every 30s while overlay open, not WebSocket | WebSocket would require new server event type |
```

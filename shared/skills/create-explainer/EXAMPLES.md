# Examples: create-explainer in practice

## Example 1: Game shoot flow → Full Lab

**Intake:**
- Q1: "What happens when I shoot my weapon?"
- Q2: `intermediate`
- Q3: `frontend engineer`
- Q4: `> 15 minutes`
- Q5: "I understand WebSocket basics but not game loops"

**Proposed scope:**
```
I'll build a Full Lab explainer for "shooting flow" targeting an intermediate frontend engineer.

Planned sections:
1. Mental model (intent vs authority)
2. Happy path sequence diagram (click → projectile → hit)
3. State diffs + compression theory
4. Interactive Shoot Lab (toggle conditions, fire, watch flow)
5. Validation Gate Playground (5 server gates, toggle to see blocks)
6. "Be The Server" decision game
7. Network Delay Simulator (latency/jitter sliders)
8. Knowledge Check Quiz (10 questions)
9. Code Architecture Map (clickable ownership table)
10. Connect the Concepts graph builder (4 rounds)

Skip: WebSocket basics (you know these). Extra depth on: tick loop, delta compression, client-side prediction.

Time estimate: ~25 minutes of interactive exploration.
Proceed? (yes / adjust / cancel)
```

**Persona config applied:**
- Analogy: "WebSocket messages are like Redux actions — the client dispatches an intent, the server is the only reducer."
- Code density: Real TS/Go snippets with inline comments. No pseudocode.
- Emphasis: Input capture, message flow, rendering feedback. De-emphasize: Go mutex internals, memory layout.

**Reviewer finding (example):**
> **CRITICAL**: Explainer says "Server checks IsAlive before validating a ranged shot." Actual `gameserver.go:PlayerShoot` does NOT check `IsAlive`. Dead players are rejected by `world.GetPlayer` returning false (which maps to `no_player`), not by an explicit alive gate. Remove the alive gate from the diagram.

**Fix:** Removed `IsAlive` gate. Added note: "Dead players fail at Gate 1 (player exists) because `GetPlayer` returns false, not via a separate alive check."

---

## Example 2: API auth flow → Condensed

**Intake:**
- Q1: "How does JWT authentication work across our services?"
- Q2: `advanced`
- Q3: `backend engineer`
- Q4: `≤ 5 minutes`
- Q5: "I wrote the middleware, just need to onboard a junior"

**Proposed scope:**
```
I'll build a Condensed explainer for "JWT auth flow" targeting an advanced backend engineer (for junior onboarding).

Planned sections:
1. One-sentence summary
2. Sequence diagram (login → token issue → validation → refresh)
3. Message examples (request/response payloads)
4. Cheat sheet: "Question → Look here"

Time estimate: ~3 minutes reading.
Proceed? (yes / adjust / cancel)
```

**Persona config applied:**
- Analogy: None needed (advanced audience). Use precise terminology.
- Code density: Minimal — function signatures and key constants only.
- Emphasis: Token lifecycle, validation order, refresh semantics.

**Output:** Single `index.html`, no `main.js`. Served at `localhost:3456`.

---

## Example 3: Database migration system → Guided

**Intake:**
- Q1: "How do migrations run in CI vs locally?"
- Q2: `beginner`
- Q3: `SRE`
- Q4: `5–15 minutes`
- Q5: "Never worked with this ORM before"

**Proposed scope:**
```
I'll build a Guided explainer for "migration execution flow" targeting a beginner SRE.

Planned sections:
1. Mental model (why migrations are scary)
2. Sequence diagram (CI trigger → schema check → lock → apply → verify)
3. Interactive state machine: toggle "concurrent index?", "transaction?", "rollback?" → see path
4. Cheat sheet: "If migration fails at X, check Y"

Skip: ORM internals, SQL dialect differences.
Extra depth on: locking, rollback safety, monitoring hooks.

Time estimate: ~10 minutes.
Proceed? (yes / adjust / cancel)
```

**Persona config applied:**
- Analogy: "A migration is like deploying code, but the database is stateful — you can't just roll back a binary. You need a backward-compatible plan."
- Code density: Pseudocode for migration runner. Real SQL for lock statements.
- Emphasis: Safety, failure modes, observability. De-emphasize: ORM abstractions.

---

## Example reviewer prompt in action

After drafting, the skill forks a subagent with:

```
You are a fact-checker. Your job is to find factual errors...
```

**Sample findings from a real run:**

| # | Finding | Severity | Source evidence |
|---|---------|----------|-----------------|
| 1 | "`projectile:spawn` includes `weaponType`" — server omits it | CRITICAL | `broadcast_helper.go` builds inline map with only `id`, `ownerId`, `position`, `velocity` |
| 2 | "Lag compensation applies to all weapons" — only hitscan | CRITICAL | `position_history.go` only called in `processHitscanShot`, never in projectile path |
| 3 | "Server has 5 validation gates" — actually 6 (weapon state exists was missing) | CRITICAL | `gameserver.go:PlayerShoot` checks `ws == nil` after `world.GetPlayer` |
| 4 | "Barrier blocked shots are rejected before ammo check" — no pre-spawn barrier gate exists | CRITICAL | `PlayerShoot` never checks barrel obstruction; barriers are checked during projectile movement |
| 5 | "Shotgun fires 6 pellets" — spec says 8 | CRITICAL | `ranged_attack.go:ShotgunPelletCount = 8` |
| 6 | Quiz Q9 says barriers stop projectiles before spawning — they stop during movement | CRITICAL | `projectile.go:Update` + `firstProjectileObstacleContact` |
| 7 | "Pistol uses hitscan" — not in current code; all weapons create projectiles | MINOR | `gameserver.go` branches on `ws.Weapon.IsHitscan` but no weapon config sets it true |

After fixes, the explainer is accurate. A second reviewer pass is not needed (only 1 new CRITICAL finding post-fix, and it was a typo in a comment).

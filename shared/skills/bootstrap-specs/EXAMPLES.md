# Bootstrap Specs Examples

Worked examples showing the interview and output for different project types.

---

## Example 1: Multiplayer Game (Greenfield)

### Interview

**Q1: What is this project?**
A browser-based real-time strategy game where 2-4 players compete to control territory on a hex grid. Matches last 5-10 minutes. Think simplified Civ combat meets Advance Wars.

**Q2: What languages and frameworks?**
TypeScript 5.x client with PixiJS 8.x for rendering. Go 1.24 server with WebSocket. Vitest for client tests.

**Q3: Greenfield or brownfield?**
Greenfield — no code yet.

**Q4: What are the major systems?**
Hex map, territory, units, combat, matchmaking, turns, scoring.

*Skill proposes additions: networking (real-time WebSocket), game loop (tick-based), player state. User confirms all.*

**Q5: Where are the boundaries?**
Hex map doesn't need to know about matchmaking. Territory doesn't need to know about unit types — it just tracks who owns each hex. Combat needs both units and the map. Matchmaking is fully isolated from gameplay.

**Q6: Are there terms that mean different things in different contexts?**
"Turn" — in matchmaking it means "player's turn to find a game," but in gameplay it means "a time slice where players act." These are separate concepts.

"Unit" — in combat it's a game piece, but in the networking code it could mean "a message unit." We'll call the networking concept a "packet" or "frame."

**Q7: Does this project have user-facing surfaces?**
Yes — a browser game UI with hex grid, player panels, and a match end screen.

**Q8: What depends on what?**
- Hex map: foundation (no deps)
- Territory: depends on hex map
- Units: depends on hex map, parameters
- Combat: depends on units, territory, hex map
- Game loop: depends on combat, territory, turns
- Turns: depends on parameters
- Scoring: depends on territory, parameters
- Networking: depends on game loop, player state
- Matchmaking: depends on networking, parameters
- Player state: depends on parameters

**Q9: Reading order?**
1. Ubiquitous language, design language, parameters
2. Hex map
3. Territory, units, turns
4. Combat, scoring
5. Game loop, player state
6. Networking, matchmaking

### Generated files

```
specs/
├── SPEC-OF-SPECS.md
├── README.md
├── UBIQUITOUS_LANGUAGE.md
├── DESIGN_LANGUAGE.md
├── parameters.md
├── hex-map.md
├── territory.md
├── units.md
├── combat.md
├── turns.md
├── scoring.md
├── game-loop.md
├── player-state.md
├── networking.md
├── matchmaking.md
├── SPEC-OF-SPECS-PLAN.md
└── reference/          (empty, for screenshots/diagrams later)
```

### Ubiquitous language excerpt

```markdown
## Match Lifecycle

| Term | Definition | Aliases to avoid | Context notes |
|------|-----------|-------------------|---------------|
| **Turn** | A discrete time slice in which players submit actions simultaneously | Round, cycle | In gameplay context only. See **Matchmaking Session** for lobby sense |
| **Matchmaking Session** | The process of finding and connecting players before a match begins | Lobby, queue | Distinct from **Turn** |
| **Hex** | A single tile on the game board with a position and terrain type | Tile, cell | |
| **Territory** | A connected group of hexes owned by the same player | Zone, region | |

## Players and Units

| Term | Definition | Aliases to avoid | Context notes |
|------|-----------|-------------------|---------------|
| **Unit** | A game piece on the board with type, health, and owner | Piece, character | Not to be confused with "unit of measurement" |
| **Player** | A participant in an active match | User, client | Distinct from **Player Account** (persistent identity) |
```

### Design language excerpt (game UI)

```markdown
## Interface Vocabulary: Game Board

| Element | Definition | When to use | When NOT to use |
|---------|-----------|-------------|-----------------|
| **Hex cell** | An interactive tile on the game board showing terrain and ownership | Selecting units, targeting attacks, claiming territory | Displaying non-interactive status info |
| **Action panel** | A slide-out panel showing available actions for selected unit | When a unit is selected and it's the player's turn | During opponent's turn |

## Visual Tokens

### Colors

| Token | Value | Usage |
|-------|-------|-------|
| color-primary | #4A90D9 | Player 1 hexes, selected unit highlight |
| color-danger | #D94A4A | Attack actions, damage indicators |
| color-neutral | #8B8B8B | Unclaimed hexes, disabled states |
```

---

## Example 2: SaaS API (Brownfield)

### Interview

**Q1: What is this project?**
A B2B invoicing API. Companies create invoices, send them to clients, track payment status, and generate reports. It's a REST API with JWT auth — no UI, the frontend is a separate project.

**Q2: What languages and frameworks?**
Python 3.12, FastAPI 0.110, PostgreSQL 16, SQLAlchemy 2.0.

**Q3: Greenfield or brownfield?**
Brownfield — there's an existing codebase at `./app/` with about 15k lines.

**Q4: What are the major systems?**
Auth, invoices, payments, clients, reports, notifications.

*Skill proposes additions: audit logging (financial system), rate limiting. User confirms audit logging but says rate limiting is handled by an API gateway.*

**Q5: Where are the boundaries?**
Auth is fully isolated — it only issues and validates tokens. Invoices depends on clients (who you're billing) but NOT on payments (unpaid invoices are valid). Payments depends on invoices and a payment gateway. Notifications depends on events from multiple systems but doesn't affect business logic.

**Q6: Terms that mean different things in different contexts?**
"Client" — in the auth system it means "the application making the API request," but in the business domain it means "the company being invoiced." We'll call the auth concept "API Consumer" and keep "Client" for the business concept.

"Payment" — could mean the payment record in our system or the actual money transfer. We'll call the record a "Payment Transaction" and the money transfer a "Settlement."

**Q7: User-facing surfaces?**
Yes — a REST API. No UI in this project, but the API IS the user-facing surface. Need naming conventions for endpoints, response shapes, error formats.

**Q8: What depends on what?**
- Auth: no deps (foundation)
- Clients: depends on auth, parameters
- Invoices: depends on clients, parameters
- Payments: depends on invoices, parameters
- Notifications: depends on invoices, payments, clients
- Reports: depends on invoices, payments, clients, parameters
- Audit logging: depends on all systems (observer pattern)

**Q9: Reading order?**
1. Ubiquitous language, design language, parameters
2. Auth
3. Clients
4. Invoices
5. Payments
6. Notifications, reports
7. Audit logging

### Generated output

Instead of skeleton specs, the skill produces a PLAN.md:

```
specs/
├── SPEC-OF-SPECS.md
├── README.md
├── UBIQUITOUS_LANGUAGE.md
├── DESIGN_LANGUAGE.md
├── PARAMETERS.md
├── PLAN.md       (extraction plan, not skeleton specs)
└── reference/    (empty)
```

### PLAN.md excerpt (Code Mapping section)

```markdown
## Code Mapping

### Auth

**Known paths**: `app/auth/`, `app/middleware/jwt.py`
**Discovery strategy**: Search for JWT, token, authentication, and authorization imports
**Extraction focus**:
  - Token lifecycle (creation, validation, expiry, refresh)
  - Role/permission model
  - Rate limiting (documented as API gateway responsibility)

### Invoices

**Known paths**: `app/invoices/`, `app/models/invoice.py`
**Discovery strategy**: Search for Invoice model, invoice routes, and invoice-related SQLAlchemy queries
**Extraction focus**:
  - Invoice state machine (draft → sent → viewed → paid/overdue/cancelled)
  - Line item structure
  - Calculation rules (taxes, discounts, totals)
  - Error cases (duplicate invoice numbers, invalid amounts)
```

---

## Example 3: CLI Tool (Greenfield)

### Interview

**Q1: What is this project?**
A command-line tool for managing dotfiles across multiple machines. It symlinks config files from a central repo, detects conflicts, and supports profiles (work, personal, minimal).

**Q2: What languages and frameworks?**
Rust 1.78, clap 4.x for CLI parsing, serde for config.

**Q3: Greenfield or brownfield?**
Greenfield.

**Q4: What are the major systems?**
Config, symlinks, profiles, conflict detection, sync.

*Skill proposes additions: file watching. User declines — out of scope for v1.*

**Q5: Boundaries?**
Config knows about file paths but not symlinks. Symlinks knows about the filesystem but not profiles. Profiles is just a named subset of config entries. Conflict detection reads symlinks and config but doesn't modify either. Sync orchestrates config, symlinks, and conflict detection.

**Q6: Term collisions?**
"Profile" is unambiguous in this context. "Conflict" means "two things trying to write to the same path" — no collision. "Config" could mean the tool's own config or the dotfile being managed — we'll call the tool's config "Manifest" and keep "Config" for dotfiles.

**Q7: User-facing surfaces?**
Yes — a CLI. Need naming conventions for flags, subcommands, and output formats.

**Q8: Dependencies?**
- Manifest: foundation (no deps)
- Profiles: depends on manifest
- Symlinks: depends on manifest
- Conflict detection: depends on symlinks, manifest
- Sync: depends on manifest, symlinks, conflict detection, profiles

**Q9: Reading order?**
1. Ubiquitous language, design language, parameters
2. Manifest
3. Profiles, symlinks
4. Conflict detection
5. Sync

### Design language excerpt (CLI)

```markdown
## Interface Vocabulary: CLI

| Element | Definition | When to use | When NOT to use |
|---------|-----------|-------------|-----------------|
| **Flag** | A boolean option prefixed with `--` that modifies behavior | `--dry-run`, `--verbose`, `--force` | When the option takes a value (use **Option**) |
| **Option** | A key-value argument prefixed with `--` that takes a parameter | `--profile work`, `--target ~/.config` | For boolean toggles (use **Flag**) |
| **Subcommand** | A named action following the main binary | `sync`, `link`, `check`, `profile` | For flags or options |
| **Positional** | A required argument without a prefix | Source directory in `dot link ./vim` | When the argument is optional (use **Option**) |

## Naming Conventions

| Context | Convention | Example |
|---------|-----------|---------|
| Subcommands | Single lowercase verb | `sync`, `link`, `check` |
| Flags | kebab-case, `--` prefix | `--dry-run`, `--show-conflicts` |
| Options | kebab-case, `--` prefix, `=` separator | `--profile=work` |
| Output format | Structured text, `key: value` pairs | `Linked: ~/.vimrc → repo/vim/vimrc` |
```

Notice how different the design language is for a CLI vs a game UI — the skill adapts the tokens and vocabulary to the project's interface type.
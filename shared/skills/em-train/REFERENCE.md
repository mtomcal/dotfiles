# EM Train Reference

## Intake interview

Run this at the start of every session. Borrowed from `create-explainer` — do not re-invent.

### Q1: Goal
**"What do you want to get out of this session?"**
- Examples: interview prep, building fluency in Python/TypeScript, understanding agent patterns, learning FastAPI, just exploring
- This sets the EM's framing for the entire session

### Q2: Experience level
**"What's your experience level with this codebase's tech stack?"**
- `beginner` — unfamiliar with the primary language or framework
- `intermediate` — comfortable reading code, can make simple changes
- `advanced` — could modify most features independently

### Q3: Specialty / role
**"What's your primary role or specialty?"**
- Examples: backend, frontend, full-stack, SRE, product, student
- Used to choose analogies and which systems to emphasize in the explainer

### Q4: Time budget
**"How much time do you have for this session?"**
- `< 30 min` — micro ticket (single function, one test)
- `30–90 min` — medium ticket (new tool with tests)
- `> 90 min` or "as long as it takes" — full feature slice

### Q5: Prior knowledge
**"Any domain concepts you already understand that I should skip?"**
- Useful for avoiding redundant explainer sections

### Cross-language mapping

If the user knows language A but the codebase is in B, note this. The `create-explainer` brief will include split-code blocks and syntax reference cards. See the [create-explainer persona mapping](<skill:create-explainer>) for details.

---

## Ticket generation

### Step 1: Explore the codebase

Find planning artifacts. Do not hardcode paths — explore:

```bash
# Find roadmap, specs, plans
fd -t f -g '*roadmap*' -g '*plan*' -g '*spec*' -g '*prd*' -g '*ARCHITECTURE*' -g '*AGENTS*'

# Check recent work
git log --oneline -15

# Check for issues, TODOs
rg -l 'TODO|FIXME|HACK|XXX' --type-add 'code:*.{py,ts,tsx}' -t code | head -20

# Understand project structure
ls docs/ 2>/dev/null
ls specs/ 2>/dev/null
```

### Step 2: Read relevant artifacts

Read the artifacts found above. Build a mental model of:
- What the project is building overall
- What phase/phase of development it's in
- What's recently been done (git log)
- What's explicitly planned next (roadmap, spec gaps)

### Step 3: Have the conversation

Present your findings to the user:

> "Here's what I see the project needs next. There's [big feature] planned, but that's pretty involved. There's also [medium slice] and [small slice]. Given you're at [level] in [language], I'd suggest [small slice]. Here's why it matters for the project..."

Negotiate scope until the user agrees on a ticket they're excited about and can realistically finish.

### Step 4: Generate the ticket

The ticket includes:

```markdown
## Story
[A narrative framing — why this matters in the game world / product]

## What you need to do
[Clear description of the implementation task]

## Acceptance criteria
- [ ] Criterion 1 (testable, specific)
- [ ] Criterion 2
- [ ] Criterion 3

## Files you'll likely touch
- `path/to/file.py` — what it does
- `path/to/test_file.py` — what to test

## Tips
- [Key conventions to follow]
- [Gotchas to watch for]

⚠️ **No spoilers in Tips.** Do not give away exact method names, async patterns, or specific API calls the user needs to discover. Point to patterns in existing code instead.
```

### Step 5: Generate the explainer brief

Build a self-contained HTML explainer following the `create-explainer` skill's workflow. This goes into the temp skill directory alongside the guidance skill.

#### 5a. Discover source files

Read the actual source files the user will need. Build a factual model:
- Entry points: the tools, models, and patterns they'll need
- Trace the flow: how existing tools work end-to-end
- Read specs: pull from `specs/` for authoritative behavior
- Record the path: note every file, key function, and what truth it owns

#### 5b. Propose scope (human checkpoint)

Present a concise summary to the user:

```
I'll build a [Condensed | Guided | Full Lab] explainer for "[concept]" targeting a [level] [specialty].

Planned sections:
1. [section name]
2. [section name]
...

Time estimate: [X] minutes of your reading time.
Proceed? (yes / adjust / cancel)
```

Wait for user confirmation.

#### 5c. Build the HTML explainer

Use the lab templates from `create-explainer/lab/` for interactive components:

| Context | Template to use |
|---------|----------------|
| Cross-language (user knows language A, codebase is B) | [`syntax-reference-cards.html`](../create-explainer/lab/syntax-reference-cards.html) — 8-12 collapsible side-by-side cards |
| User needs to understand codebase patterns | [`architecture-map.html`](../create-explainer/lab/architecture-map.html) |
| Need to verify understanding | [`quiz.html`](../create-explainer/lab/quiz.html) — 5-10 questions |
| Need to explain a flow | [`toggleable-state-machine.html`](../create-explainer/lab/toggleable-state-machine.html) |
| Interactive decision training | [`decision-game.html`](../create-explainer/lab/decision-game.html) |

Key patterns from create-explainer:
- **Self-contained**: Single `index.html` (Condensed) or `index.html` + `main.js` (Guided/Full Lab)
- **Theme**: Dark theme with `--bg: #0b1020`, `--panel: #111a33`, `--accent: #6ee7ff`
- **Split-code blocks**: Side-by-side Python ↔ JS with `.split-code` CSS grid, collapses at 700px
- **No external deps**: All CSS inline, all JS in `main.js`, no CDN
- **Syntax coloring**: Use `.token-kw`, `.token-fn`, `.token-str`, `.token-cmt`, etc. classes
- **Cross-language mapping**: Heavy side-by-side code blocks. Python ↔ JS syntax reference cards. Annotate each Python concept with JS analogy.

**No-spoiler rule**: The explainer teaches patterns from EXISTING code — never from the user's ticket. Every code example must come from a file that already exists in the codebase, not from the tool/feature the user is tasked to build. The "Your Ticket" section may show class skeletons (field declarations, method signatures up to `pass`) but must avoid:
  - Exact return dict structures with key names
  - Exact parameter names and types for input schemas
  - The specific method call that solves the core problem
  - Copy-paste-ready code blocks for the registry

Refer to the `create-explainer` lab README for guidance on specific patterns: `../create-explainer/lab/README.md`

#### 5d. Write the files

Write the explainer to `.pi/skills/em-train-guide/explainer.html` (and optionally `explainer.js` for interactivity).

For the `index.html` (Condensed/Guided) or as `explainer.html`:
- Hero: one-sentence summary + three-pillar overview
- TOC with links to sections
- Section cards with numbered headings
- Split-code blocks for cross-language patterns
- Code blocks from actual source files (verified paths exist)
- Callouts for key differences

For `explainer.js` (Guided/Full Lab):
- Syntax card toggle logic
- Quiz logic
- Interactive components from lab templates

#### 5e. Self-fix

Read through the full explainer. Check:
- File paths in code blocks actually exist
- Syntax coloring is applied correctly
- Interactive element IDs match between HTML and JS
- Split-code collapses at 700px
- No placeholder text or TODO markers

**Spoiler checklist** — flag any of these:
  - The "Your Ticket" section contains code the user could copy-paste directly into their implementation
  - A code block shows the exact return shape or parameter names the user's ticket needs
  - The explainer shows the specific method call on `event_bus`, `game_state`, or other injected dependency that solves the core logic
  - The ticket's Tips section (in `ticket.md`) gives away exact method names, async patterns, or implementation strategies
  - If you find spoilers, replace them with `pass` + a comment like `# ← implement this` or a hint that points to the ticket AC

#### 5f. Serve (optional — for Full Lab only)

```bash
cd .pi/skills/em-train-guide && python3 -m http.server 3456 --bind 0.0.0.0
```

#### 5g. Reviewer pass (optional — for Guided/Full Lab with interactivity)

Delegate a reviewer sub-agent to verify factual claims in the explainer match the source code. Fix all CRITICAL findings.

---

## Setup phase

### Branch creation

```bash
# Create and switch to training branch
BRANCH_NAME="train/em-$(date +%Y%m%d)-$(echo '$TICKET_TITLE' | slugify)"
git checkout -b "$BRANCH_NAME"
```

### Assemble the temp skill directory

Create `.pi/skills/em-train-guide/` (or `.em-train-guide/` for non-Pi projects) with:

1. **`SKILL.md`** — the guidance skill (see [template below](#temp-guidance-skill-template))
2. **`ticket.md`** — the ticket (story, acceptance criteria, files, tips from Step 4)
3. **`explainer.html`** (and optionally `explainer.js`) — the self-contained HTML explainer from Step 5

The content for SKILL.md comes from the [template below](#temp-guidance-skill-template), with `$TICKET`, `$LANGUAGE`, `$LEVEL`, and `$PROJECT` filled in.

### Guidance for invoking

Tell the user:

> "You're now on branch `$BRANCH_NAME`. I've left a guidance skill and an interactive explainer in `.pi/skills/em-train-guide/`. Open `explainer.html` in your browser for a cross-language reference. Use the guidance skill for API/language questions — it will NOT write the code for you. If you get truly stuck, ask it for an explainer on the blocking concept. When you're done, come back to me and say 'ready for review.'"

---

## Review phase

### Step 1: Run CI

```bash
# Run the appropriate test suite
make test 2>&1 || true
# Or for specific component
cd backend && uv run pytest tests/test_tools/ -v 2>&1 | tail -30
```

Report results honestly. If tests fail, list them.

### Step 2: Delegate to review subagents

Send the diff and ticket to review subagents. Use the project's available reviewers:

- `test-reviewer` — verifies test assertions pass and coverage meets thresholds
- `quality-reviewer` — checks code structure, conventions, naming
- `security-reviewer` — checks for new attack surfaces

Provide each with:
- The ticket (story + AC)
- The diff / files changed
- The user's experience level (so they calibrate feedback depth)

### Step 3: Curate feedback

Read all review output. Select **2-3 items** that:
1. Would teach the user the most about the language/codebase
2. Are actionable and concrete
3. Won't overwhelm someone at their level

Present to the user:

> "Nice work! Tests [pass/fail]. Here are the 2-3 things I'd focus on improving:
>
> 1. ****[specific issue]** — here's why it matters and how to think about it
> 2. ****[specific issue]**
> 3. ****[specific issue]**
>
> Fix these and come back for Round 2."

**The EM never says "looks good" on Round 1.** Always find at least one improvement.

### Step 4: Round 2

User comes back. Re-run CI + re-review. If fixes are good:

> "Approved! Here's what I'd keep an eye on going forward: [1-2 parting observations]."

If fixes introduced issues, give one more targeted round. Max 3 rounds total.

---

## Cleanup phase

### Generate the summary report

Write a markdown report to the project root:

```markdown
# EM Train — Session Report

## Date
[date]

## Ticket
[Ticket title and AC summary]

## What you built
[Brief description of what was implemented]

## What you learned
- [Key takeaway 1]
- [Key takeaway 2]
- [Key takeaway 3]

## Things to remember
- [Gotcha or pattern to recall next time]
- [Language quirk you encountered]
- [Convention you learned]

## Next steps
Given what you worked on and where you struggled, here's a good next ticket:

> [Suggested next ticket, mapped to what's hardest right now]

## Branch
`[branch name]` — still on your machine. Merge to main if you want to make it real.
```

### Clean up the temp skill

Remove the temporary guidance skill file:

```bash
rm -rf .pi/skills/em-train-guide .em-train-guide.md
```

### Offer merge

> "Your training branch is still there if you want to keep the work. Want me to merge it to main, or leave it as a learning artifact?"

---

## Temp guidance skill template

This is the content written to `.pi/skills/em-train-guide/SKILL.md` (or `.em-train-guide.md` for non-Pi projects).

Fill in placeholders:
- `$TICKET_TITLE`, `$TICKET_SUMMARY`, `$LEVEL`, `$LANGUAGE`, `$PROJECT` — from the intake interview and ticket
- `$SOURCE_FILES` — actual file paths from the codebase the user needs to read (e.g. `backend/src/agentic_rpg/tools/character.py`)
- `$TEST_FILES` — actual test file paths (e.g. `backend/tests/test_tools/test_character.py`)

```markdown
---
name: em-train-guide
description: Temporary guidance skill for [TICKET_TITLE]. Answers API/language questions only. Does NOT provide implementation solutions. Use when working on this training ticket and you need to understand a library, API, language syntax, or codebase convention.
---

# EM Train Guide — [TICKET_TITLE]

You are a senior engineer guiding a [LEVEL] [LANGUAGE] developer through a training ticket.

## The ticket
[TICKET_TITLE]
[1-2 line summary of what they're building]

## Your rules

1. **Never write the implementation code for the ticket.** Not a single line. The user must write it themselves.
2. **Do answer:**
   - "What methods does this class have?"
   - "How does async/await work in Python?"
   - "What's the signature of this function?"
   - "What's the convention for naming tools in this project?"
   - "Can you show me an example of a similar tool that already exists?" (show existing code from elsewhere in the codebase, NOT their ticket)
   - "What's the idiomatic way to do X in this language?"
3. **Do NOT answer:**
   - "How do I implement the ticket?"
   - "What should my function body look like?"
   - "Can you write this for me?"
4. **When the user asks for something you shouldn't answer:**
   - First ask: "What part are you stuck on? What have you tried?"
   - Second ask: "Open the interactive explainer at `explainer.html` — it covers all the patterns."
   - Third ask: "Let me generate an explainer for the concept blocking you."
5. **Keep a list of language patterns the user struggles with.** At the end, report to the EM for the summary report.

## Reference files (in this directory)

- [ticket.md](ticket.md) — the ticket with story, AC, files, tips
- [explainer.html](explainer.html) — interactive cross-language reference with syntax cards and quiz

## Reference files (codebase)

- `$SOURCE_FILES` — key implementation patterns
- `$TEST_FILES` — test patterns to follow
```

---

## Session lifecycle

```
┌─────────────────────────────────────────────────────┐
│ 1. INTAKE ──── Interview (level, goal, budget)      │
│ 2. EXPLORE ─── Read codebase, roadmap, specs         │
│ 3. SCOPE ───── Conversation → ticket negotiation     │
│ 4. TICKET ──── Story + AC + files + tips             │
│ 5. EXPLAINER ── HTML explainer (create-explainer)   │
│    ├─ 5a. Discover source files                      │
│    ├─ 5b. Propose scope (human checkpoint)           │
│    ├─ 5c. Build HTML with lab templates              │
│    ├─ 5d. Write explainer.html + explainer.js        │
│    ├─ 5e. Self-fix                                   │
│    ├─ 5f. Serve (Full Lab only)                      │
│    └─ 5g. Reviewer pass (Guided/Full Lab)            │
│ 6. SETUP ──── Branch + skill dir (SKILL.md,          │
│               ticket.md, explainer.html)             │
│ 7. DOING ──── User works (guidance skill active)     │
│ 8. REVIEW ─── CI + subagents → curated feedback      │
│ 9. ITERATE ── Fix (max 2 rounds)                    │
│ 10. REPORT ── Summary + next steps                   │
│ 11. CLEANUP ─ Remove skill dir, offer merge          │
└─────────────────────────────────────────────────────┘
```

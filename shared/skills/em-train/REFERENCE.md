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
```

### Step 5: Generate the explainer brief

Run the `create-explainer` skill to produce a briefing tailored to the user's persona and the specific ticket. This covers:
- What they're building and why the architecture works that way
- Key code patterns they'll need to understand
- Cross-language syntax reference (if applicable)

---

## Setup phase

### Branch creation

```bash
# Create and switch to training branch
BRANCH_NAME="train/em-$(date +%Y%m%d)-$(echo '$TICKET_TITLE' | slugify)"
git checkout -b "$BRANCH_NAME"
```

### Drop the temp guidance skill

Write a temporary skill file at a project-appropriate location. For Pi projects, use `.pi/skills/em-train-guide.md`. For non-Pi projects, use `.em-train-guide.md` in the project root.

The content comes from the [template below](#temp-guidance-skill-template), with `$TICKET`, `$LANGUAGE`, `$LEVEL`, and `$PROJECT` filled in.

### Guidance for invoking

Tell the user:

> "You're now on branch `$BRANCH_NAME`. I've left a guidance skill you can invoke for help. It will answer API/language questions and explain concepts — but it will NOT write the code for you. If you get truly stuck, ask it for an explainer on the blocking concept. When you're done, come back to me and say 'ready for review.'"

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
rm -f .pi/skills/em-train-guide.md .em-train-guide.md
```

### Offer merge

> "Your training branch is still there if you want to keep the work. Want me to merge it to main, or leave it as a learning artifact?"

---

## Temp guidance skill template

This is the content written to `.pi/skills/em-train-guide.md` (or `.em-train-guide.md` for non-Pi projects):

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
   - Second ask: "Let me generate an explainer for the concept blocking you."
   - Third ask: Generate a `create-explainer` brief for the blocking concept. The user studies it and comes back.
5. **Keep a list of language patterns the user struggles with.** At the end, report to the EM for the summary report.
```

---

## Session lifecycle

```
┌─────────────────────────────────────────────────┐
│ 1. INTAKE ──── Interview (level, goal, budget)  │
│ 2. EXPLORE ─── Read codebase, roadmap, specs     │
│ 3. SCOPE ───── Conversation → ticket negotiation │
│ 4. BRIEF ───── Create-explainer for the ticket   │
│ 5. SETUP ───── Branch + temp skill               │
│ 6. DOING ────  User works (guidance skill active)│
│ 7. REVIEW ──── CI + subagents → curated feedback │
│ 8. ITERATE ─── Fix (max 2 rounds)                │
│ 9. REPORT ──── Summary + next steps              │
│ 10. CLEANUP ── Remove temp skill, offer merge    │
└─────────────────────────────────────────────────┘
```

# Reference: create-explainer internals

## Intake interview

Ask these questions in order. Do not skip any.

### Q1: Concept
**"What concept or flow should the explainer cover?"**
- Accept a feature name ("shooting"), a message type ("what happens on player:shoot"), an architecture question ("how does delta compression work"), or a debugging scenario ("why does my shot sometimes not register").
- If vague, ask one follow-up: "Is this about the input path, the network protocol, the server logic, the rendering, or the full end-to-end flow?"

### Q2: Experience level
**"What's your experience level with this codebase's tech stack?"**
- Options: `beginner` (unfamiliar with framework/language), `intermediate` (comfortable reading code), `advanced` (could modify this feature).
- Use this to set code snippet density and analogy depth.

### Q3: Specialty / role
**"What's your primary role or specialty?"**
- Examples: frontend engineer, backend engineer, SRE, product manager, new hire onboarding.
- Use this to choose analogies and which systems to emphasize.

### Q4: Time budget
**"How much time do you want to spend with this explainer?"**
- `≤ 5 minutes` → Condensed tier
- `5–15 minutes` → Guided tier
- `> 15 minutes` or `"as long as it takes"` → Full Lab (default)

### Q5: Prior knowledge (optional)
**"Any domain concepts you already understand that I should skip?"**
- Useful for avoiding sections the user doesn't need.

## Persona mapping

Use the answers from Q2–Q4 to configure the explainer's voice and content.

### Experience level → content depth

| Level | Code style | Analogy style | Assumed knowledge |
|-------|-----------|---------------|-------------------|
| `beginner` | Pseudocode + one real snippet | Web app / everyday analogies | None |
| `intermediate` | Real code with inline comments | Framework-to-framework analogies | Language syntax |
| `advanced` | Full real code blocks | Architecture pattern analogies | Patterns, concurrency |

### Specialty → emphasis

| Specialty | Emphasize | De-emphasize |
|-----------|-----------|--------------|
| `frontend` | Client input, rendering, state sync, UI feedback | Server tick internals, Go mutex patterns |
| `backend` | Validation gates, game loop, physics, broadcast | Phaser scene lifecycle, CSS effects |
| `SRE` | Message rates, tick timing, delta compression, network failure modes | Visual rendering, gameplay balance |
| `product` | User-visible outcomes, error states, UX flow | Code implementation details |

### Cross-mapping examples

- **Frontend engineer, beginner, 20 min** → Heavy use of React/analogies. Explain WebSocket as "a persistent fetch that the server can push to." Show Phaser input → DOM event parallels. Include interactive lab with toggleable conditions.
- **Backend engineer, advanced, 10 min** → Skip rendering entirely. Focus on validation order, mutex rules, tick loop scheduling, and broadcast semantics. Condensed tier with sequence diagrams.
- **New hire, intermediate, full time** → Full Lab. Assume they can read TS/Go but don't know the architecture. Explain *why* each validation gate exists in anti-cheat terms.

### Cross-language mapping

When the user knows language A but the codebase is in language B, use this special persona:

| Known language | Codebase language | Approach |
|----------------|-------------------|----------|
| `javascript` → `python` | Heavy side-by-side split-code blocks. Python ↔ JS syntax reference cards. "Translate this JS to Python" exercise lab. Annotate each Python concept with JS analogy (decorators → HOF wrappers, Pydantic → Zod, Context managers → try/finally). |
| `typescript` → `go` | Type system comparison (structs vs interfaces). Error handling (if err != nil vs try/catch). Goroutine patterns vs async/await. |
| `python` → `javascript` | Show JS equivalents of Python idioms. Decorators → HOF, list comprehensions → .map()/.filter(), generators → iterators. |
| Any → any other | Generate a syntax quick-reference as the first substantive section. Include 8-12 collapsible cards, each with side-by-side code for the same logical operation in both languages.

## Workflow

### Step 1: Intake interview
Ask Q1–Q5. Record answers.

If the user already gave a concrete concept, target audience, and time/depth signal, do not force redundant intake. State assumptions briefly, for example: "I will treat this as a Guided explainer for a JS-familiar engineer learning Python tooling." Ask only for missing or risky details.

### Step 2: Propose scope (human checkpoint)
Present a concise summary:

```
I'll build a [tier] explainer for "[concept]" targeting a [level] [specialty].

Planned sections:
1. [section name]
2. [section name]
...

Time estimate: [X] minutes of your reading time.
Proceed? (yes / adjust / cancel)
```

Wait for user confirmation. Do not proceed without it.

### Step 3: Discovery
Read source files to build a factual model. Strategy:

1. **Find entry points**: Search for the concept name in file names and message types.
2. **Trace the flow**: Follow call chains from user input → network → server handler → business logic → broadcast → client handler → rendering.
3. **Read specs**: Check `specs/`, `docs/`, or equivalent for authoritative behavior definitions.
4. **Read schemas**: Check shared schema files for exact message shapes.
5. **Record the path**: Note every file visited, the key function/line, and what truth it owns.

**Rule**: If you can't find a source for a claim, do not include it. Mark it as `// TODO: verify` if it's structurally necessary.

### Step 4: Draft
Build the explainer as self-contained HTML. Structure depends on tier.

#### Condensed tier structure
- Hero: one-sentence summary + three-pillar overview
- 2–4 sections with SVG sequence diagrams
- Concrete message examples (JSON)
- Cheat sheet table: "Question → Look here"
- Single file: `index.html`

#### Guided tier structure
- Everything in Condensed
- Plus ONE interactive element chosen by concept shape from the [lab selection matrix](lab/README.md#lab-selection-matrix):
  - Toggleable state machine for validation gates
  - Step-through timeline for message flow
  - Network delay simulator for timing behavior
  - Prediction lab for commit-before-reveal scenarios
  - Compare/contrast lab for similar APIs or bug/fix pairs
- Two files: `index.html` + `main.js`

#### Full Lab structure
- Everything in Guided
- Interactive shoot/play lab with toggleable conditions
- Multi-step animated timeline
- Validation gate playground
- "Be the Server" decision game
- Network delay simulator
- Knowledge check quiz (5–10 questions)
- Code architecture map (clickable table)
- Connect-the-concepts graph builder (node-based, rounds with synonym disguises)
- Compare/contrast lab for near-miss concepts, bug/fix pairs, and subtle API differences
- Prediction lab where the learner commits before revealing output, next state, or blocking gate
- Parsons sequencer for ordering code lines, validation gates, or lifecycle steps
- Worked example fader for full example → partial support → independent attempt
- Self-explanation cards for important code lines or architecture decisions
- Confidence checks after quiz/prediction answers to detect false confidence
- Quick reference with collapsible message payloads
- **Syntax reference cards** — 8-12 collapsible cards with side-by-side code (for cross-language explainers)
- Two files: `index.html` + `main.js`

#### Delegating drafting to sub-agents (Full Lab only, optional)

For large explainers (10+ sections, multiple interactive labs), you can parallelize by delegating sections to sub-agents instead of writing everything yourself.

**When to delegate**:
- Explainer has 6+ static content sections → delegate section drafting
- Explainer has 3+ interactive labs → delegate lab implementation
- Explainer is cross-language (syntax cards) → delegate the syntax reference to one sub-agent

**Delegation strategy**:

1. **You write the shell**: Create `index.html` with the full layout, CSS, navigation, and container divs for each section. Leave section content as empty placeholder divs with IDs. Write `main.js` with the shared interactive framework.

2. **Delegate section content** — For each section, delegate to a sub-agent with:
   - The section's topic, target persona, and which source files to read
   - The HTML/CSS patterns to follow (documented above)
   - The intended section structure (heading level, callouts, code blocks, diagrams)

3. **Delegate labs** — For each interactive lab, delegate to a sub-agent with:
   - The lab template to start from (from `lab/` folder)
   - The concept-specific data (quiz questions, game scenarios)
   - The integration instructions (how to wire into `main.js`)

4. **Merge results**: Collect each sub-agent's output and assemble into the final `index.html` + `main.js`. Verify no ID conflicts or broken cross-references.

5. **Self-draft simple sections**: Write sections 1-3 yourself (syntax reference, architecture overview, request journey) since they anchor the explainer's voice and require the most cross-referencing. Delegate only self-contained sections and labs.

**Handling failed delegation**: If a sub-agent returns unusable output (empty, corrupted, or wrong concept), narrow the task and retry, or write that section yourself.

**Use lab templates**: Instead of writing interactivity from scratch, copy from the [`lab/`](lab/README.md) folder. Each template is a self-contained HTML file with `/* ADAPT: ... */` comments marking customization points. Pick templates from the lab selection matrix before drafting; do not choose flashy interactions that do not match the learning objective.

**Cross-language explainers**: If the user knows a different language than the codebase, add:
1. A "Python ↔ JS Quick Reference" section (or equivalent language pair) with 8-12 collapsible syntax cards as the first section after the TOC
2. Split-code blocks (side-by-side) throughout every section instead of single-language code

### Step 5: Self-fix
After drafting, read through the full explainer and fix obvious issues yourself before sending to reviewers:
- Check that all file paths referenced in code blocks actually exist
- Verify code blocks use the correct syntax for the language shown
- Ensure interactive element IDs match between `index.html` and `main.js`
- Fix any placeholder text or TODO markers left during drafting

### Step 6: Reviewer pass (mandatory — never skip)

The reviewer pass happens **after** the full explainer is drafted. One or more reviewer sub-agents independently read the source files and verify every factual claim.

Before delegating reviewer work, ask the user whether sub-agents are approved for this workflow. If the user declines, does not approve delegation, or the runtime does not allow sub-agents, do a local source-grounded reviewer pass instead and report that no delegated reviewer was used.

#### Single reviewer (compact explainers, ≤4 sections)

Delegate to one reviewer sub-agent. Provide the full explainer content plus this checklist prompt. Adapt the task format to whatever mechanism your environment uses for delegating to sub-agents:

```
You are a fact-checker. Your job is to find factual errors, invented claims, and mismatches between the explainer and the actual source code.

EXPLAINER TO REVIEW:
[ Paste full explainer content OR a condensed claim checklist ]

TASK:
1. Read the actual source files independently. Search for files related to the concept being explained. Do not trust the explainer's file references — verify them.
2. For every claim in the explainer, check if it matches reality:
   - Route paths and HTTP methods
   - Validation gate order and conditions
   - Message/Model field names and required/optional status
   - Function names and signatures
   - Numeric constants (timings, rates, sizes)
   - File paths
   - SQL query patterns (column names, ? placeholders, WHERE clauses)
3. Flag any claim that is:
   - Made up (no source supports it)
   - Partially wrong (right idea, wrong detail)
   - Out of date (code has changed since the spec was written)
4. For each finding, provide:
   - The explainer text that is wrong
   - What the source code actually says
   - The file path and line/function that confirms the correct version
   - Severity: CRITICAL (would mislead) or MINOR (imprecise)

Be ruthless. Assume the explainer author may have hallucinated gates, fields, or behaviors.
```

#### Parallel reviewers (large explainers, 5+ sections)

For large explainers, split review across multiple sub-agents running in parallel. Each receives only the sections they're checking plus a condensed claim checklist:

| Sub-agent | Covers |
|-----------|--------|
| Syntax reviewer | Syntax reference cards, static code examples, language comparisons |
| Architecture reviewer | Architecture diagrams, file ownership table, request flow |
| Code accuracy reviewer | All code blocks, SQL queries, API call patterns, validation logic |
| Interactive lab reviewer | Lab logic, quiz answers, game rules |

Each reviewer reads source files independently and returns a list of findings. Address all CRITICAL findings from any reviewer. If any reviewer found ≥3 CRITICAL errors, do a second reviewer pass before serving.

### Step 7: Fix based on reviewer feedback

Address every CRITICAL finding. Address MINOR findings if they would confuse the target persona. Re-read affected source files to confirm fixes are correct. Do not move to the next step until all CRITICAL findings are resolved.

### Step 8: Serve
Create `explainer/` directory in the project root (or wherever the user prefers). Write `index.html` and optionally `main.js`. Start server:

First check whether the preferred port is already serving something else. A port can be open but pointed at an older explainer or unrelated tool artifact.

```bash
ss -tlnp | rg ':3456' || true
curl -fsS http://127.0.0.1:3456/ | head -20 || true
```

If `3456` is occupied, choose the next free port (`3457`, `3458`, ...). After starting the server, verify page identity by grepping for a unique headline or section title from the explainer.

```bash
cd /path/to/explainer && python3 -m http.server 3456 --bind 0.0.0.0
curl -fsS http://127.0.0.1:3456/ | rg "Expected headline or section title"
```

### Step 9: Validate visually (recommended for Full Lab)
Use playwright-cli to take screenshots and verify layout. Store all screenshots and generated files in a temporary directory (not the project root) to avoid cluttering the repo:

```bash
mkdir -p /tmp/explainer-screenshots
cd /tmp/explainer-screenshots
playwright-cli open http://localhost:3456
playwright-cli resize 1440 900
playwright-cli screenshot --filename=desktop.png
playwright-cli resize 700 900
playwright-cli screenshot --filename=mobile.png
playwright-cli close
```

Check that:
- Code blocks don't overflow horizontally
- Split-code blocks collapse to single column at 700px
- Interactive elements (cards, quiz buttons, game controls) are clickable
- No JavaScript console errors beyond expected favicon.ico 404

For any explainer with hidden or expandable content, also run an expanded-state pass. Toggle every accordion, tab, syntax card, quiz reveal, or collapsible group before taking screenshots and scanning for overflow. A practical Playwright check is:

```javascript
const issues = await page.evaluate(() => {
  const out = [];
  document.querySelectorAll('.syntax-card, details, [data-expandable], pre, .split-code').forEach((el) => {
    if (el.tagName === 'DETAILS') el.open = true;
    el.classList.add('open');
  });
  document.querySelectorAll('pre, .split-code, .syntax-card, details, [data-expandable]').forEach((el) => {
    const rect = el.getBoundingClientRect();
    if (el.scrollWidth > el.clientWidth + 1) out.push({ type: 'horizontal-overflow', text: el.textContent.slice(0, 80) });
    if (rect.right > window.innerWidth + 1 || rect.left < -1) out.push({ type: 'viewport-cutoff', text: el.textContent.slice(0, 80) });
  });
  return out;
});
if (issues.length) throw new Error(JSON.stringify(issues, null, 2));
```

If issues found, fix and re-serve. Skipping visual validation is acceptable for Condensed and Guided tiers.

## HTML/JS patterns

### Static doc layout

Use a single HTML file with embedded CSS. Key visual elements:
- **Hero section**: eyebrow tag, big headline, three-pillar summary cards, TOC
- **Section cards**: numbered sections with `.section-title` (number badge + h2 + subtitle)
- **Flow diagrams**: CSS grid `.flow` with 3–5 `.flow-step` cards connected by arrows
- **Sequence diagrams**: Inline SVG swimlanes (`<rect class="lane">` for columns, `<rect class="box">` for events, `<path class="arrow">` for messages)
- **Code blocks**: `<pre>` with syntax-colored spans (`.token-kw`, `.token-fn`, `.token-str`, `.token-cmt`, etc.). Set `overflow-x: auto; white-space: pre; max-width: 100%;` to prevent horizontal overflow.
- **Split-code blocks**: Side-by-side code for cross-language explainers. See [split-code pattern](#split-code-pattern).
- **Tables**: Ownership tables ("Thing → Who owns truth? → Frontend uses → Backend uses")
- **Callouts**: `.callout` for cross-references and important connections

#### Split-code pattern
For side-by-side language comparisons:
```css
.split-code {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin: 12px 0;
  width: 100%;
}
.split-code pre {
  max-width: none;
  overflow-x: auto;
  margin: 0;
}
.split-code .side-label {
  font-size: 11px; font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin-bottom: 6px;
}
@media (max-width: 700px) {
  .split-code { grid-template-columns: 1fr; }
}
```

Color palette (dark theme, accessible):
```css
--bg: #0b1020; --panel: #111a33; --ink: #eef4ff; --muted: #aab7d4;
--accent: #6ee7ff; --accent-2: #ffd166; --good: #55d68b; --bad: #ff6b6b;
```

### Interactive lab layout

Add `main.js` for interactivity. **Use the [`lab/`](lab/README.md) templates** as starting points instead of writing from scratch.

Key components available as templates:
- **Toggle rows / Gate visual**: [`toggleable-state-machine.html`](lab/toggleable-state-machine.html)
- **"Be The Server" decision game**: [`decision-game.html`](lab/decision-game.html)
- **Network simulator**: [`network-simulator.html`](lab/network-simulator.html)
- **Quiz**: [`quiz.html`](lab/quiz.html)
- **Architecture map**: [`architecture-map.html`](lab/architecture-map.html)
- **Node connector graph** (most complex): [`node-graph-builder.html`](lab/node-graph-builder.html)
- **Syntax reference cards**: [`syntax-reference-cards.html`](lab/syntax-reference-cards.html)

If you need to hand-build a component, here are the CSS/JS patterns:
- **Toggle rows**: `<label class="toggle-row">` with checkbox + switch slider + label + status text
- **Timeline**: `.timeline` with `.timeline-step` elements that activate sequentially via JS
- **Gate visual**: `.gate-visual` with `.gate-node` elements that highlight pass/block states
- **Lab canvas**: `.lab-canvas` with absolutely-positioned divs animated via CSS transitions
- **Message packets**: `.msg-packet` divs with CSS keyframe animations for flying across the canvas
- **Quiz**: `.quiz-opt` buttons with `.correct`/`.wrong` classes, explanation panel below
- **Score board**: `.score-board` with `.score-num` + `.score-label`
- **JSON inspector**: `.json-inspector` with syntax-colored spans for keys, strings, numbers, booleans
- **Node connector graph**: SVG-based with `.nc-node` (draggable divs) + `.nc-port` (connection points) + `.nc-edge` (SVG bezier paths) + delete handles at midpoint
- **Syntax reference cards**: Collapsible cards with `.syntax-card` class. Toggle `.open` on click to reveal `.card-body`. Header shows `.card-title` + toggle arrow.

### Critical JS patterns

**Timeline animation**: Activate steps sequentially with `setTimeout` delays. Show/hide `.step-payload` on activation.

**Gate playground**: On toggle change, re-evaluate gate chain top-to-bottom. First failing gate gets `.block`; prior gates get `.pass`; remaining gates stay neutral.

**Node graph builder**:
- Draggable nodes: `mousedown` on node → `mousemove` on document → `mouseup` on document. Update `left/top` styles.
- Edge drawing: `mousedown` on `.nc-port.output` → `mousemove` draws temporary SVG path → `mouseup` on `.nc-port.input` creates permanent edge.
- SVG path: Cubic bezier from output port center to input port center with control points at `x + dx/2`.
- Edge styling: `setAttribute('class', ...)` not `classList.baseVal` for SVG paths. Explicit `stroke` colors.
- Port-agnostic validation: `sameEdge(a,b)` checks `a.from === b.from && a.to === b.to` only.
- Delete handles: Midpoint via bezier formula at `t=0.5`, not `getPointAtLength()`.
- Z-index fix: `#connect-nodes` container gets `pointer-events: none`; each `.nc-node` gets `pointer-events: auto`.

### Common adaptation pitfalls (node graph builder)

When adapting the [`node-graph-builder.html`](lab/node-graph-builder.html) template, avoid merging `updateUI()` into `renderNodes()`:

**Wrong** — renders calls `renderNodes()` after setting button state, but `renderNodes()` resets it:
```javascript
function checkGraph() {
  // ... sets nextBtn display: inline-flex
  renderNodes();  // OOPS: renderNodes() hides nextBtn again
}
```

**Right** — keep `updateUI()` (init/reset) separate from `renderNodes()` (DOM only):
```javascript
function buildNodes() {
  updateUI();    // sets button visibility, scores
  renderNodes(); // pure DOM — no button/side-effect code
}
```

The template already does this correctly. Do not inline `updateUI`'s contents into `renderNodes` during adaptation.

## File conventions

- Directory: `./explainer/` (or user-specified)
- Static: `index.html` only
- Interactive: `index.html` + `main.js`
- Server: `python3 -m http.server 3456 --bind 0.0.0.0`
- Do not use `npx serve` — it is less reliable than Python's built-in server.
- No external CDN dependencies. All CSS and JS are inline or in the local `main.js`.

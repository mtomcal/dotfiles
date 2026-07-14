# Reference: Create Explainer

## Intake and persona

Use the ordered intake only when the concept, audience, and depth are not already clear. If the request supplies those facts, state the inferred answers and ask only about missing or risky details.

### Ordered intake

1. **Concept:** “What concept or flow should the explainer cover?” Accept a feature, message type, architecture question, or debugging scenario. If vague, ask whether the scope is input, protocol, backend logic, rendering, or the full end-to-end flow.
2. **Experience:** “What's your experience level with this codebase's tech stack?” Offer `beginner`, `intermediate`, or `advanced`.
3. **Specialty:** “What's your primary role or specialty?” Examples include frontend, backend, SRE, product, and new-hire onboarding.
4. **Time:** “How much time do you want to spend with this explainer?” Route `≤ 5 minutes` to Condensed, `5–15 minutes` to Guided, and `> 15 minutes` or “as long as it takes” to Full Lab.
5. **Prior knowledge, optional:** “Any domain concepts you already understand that I should skip?”

### Experience matrix

| Level | Code style | Analogy style | Assumed knowledge |
|-------|------------|---------------|-------------------|
| `beginner` | Pseudocode plus one real snippet | Everyday or familiar-application analogies | None |
| `intermediate` | Real code with inline comments | Framework-to-framework analogies | Language syntax |
| `advanced` | Full real code blocks | Architecture-pattern analogies | Patterns and concurrency |

### Specialty matrix

| Specialty | Emphasize | De-emphasize |
|-----------|-----------|--------------|
| `frontend` | Client input, rendering, state synchronization, UI feedback | Backend tick internals and language-specific locking details |
| `backend` | Validation gates, processing loops, business logic, broadcast | Scene lifecycle and visual effects |
| `SRE` | Message rates, timing, compression, network failure modes | Rendering and product aesthetics |
| `product` | User-visible outcomes, error states, UX flow | Implementation detail |

Cross-map the matrices rather than applying either mechanically. A frontend beginner benefits from familiar UI/state analogies and toggleable conditions. An advanced backend learner may need validation order, locking, scheduling, and broadcast semantics while skipping rendering. An intermediate new hire needs architectural reasons and ownership boundaries even when syntax is familiar.

### Cross-language matrix

| Known language → codebase language | Adaptation |
|------------------------------------|------------|
| JavaScript → Python | Compare decorators with higher-order wrappers, Pydantic with Zod, and context managers with `try/finally`; include a translation exercise. |
| TypeScript → Go | Compare structs/interfaces, explicit error returns/try-catch, and goroutines/async-await. |
| Python → JavaScript | Compare decorators/higher-order functions, comprehensions/`map` and `filter`, and generators/iterators. |
| Any → another | Put an 8–12-card side-by-side syntax quick reference before the main flow and use split-code comparisons throughout. |

### Scope checkpoint template

Present exactly one checkpoint before source mapping or drafting:

```text
I'll build a [tier] explainer for “[concept]” targeting a [level] [specialty].

Planned sections:
1. [section]
2. [section]
...

Skip: [known material or out-of-scope boundaries]
Extra depth: [persona-specific emphasis]
Reading time: [estimate]
Proceed, adjust, or cancel?
```

Apply requested adjustments and present the revised checkpoint; stop on cancellation. Approval covers the concept boundary, persona, tier, section list, omissions, and reading-time expectation.

## Tier planning and drafting

Plan the selected tier from these structures. The main skill owns durable file counts and minimum tier contracts. Use the [lab selection matrix and integration guide](lab/README.md#lab-selection-matrix) for template choice and adaptation rather than maintaining a second template catalog here.

### Condensed

- Hero with a one-sentence summary, three-pillar overview, and table of contents.
- Two to four source-grounded sections with sequence or flow diagrams.
- Concrete messages or examples when the source supports them.
- File/ownership map, optionally phrased as “Question → Look here.”
- No lab or interactive runtime.

### Guided

Include the Condensed structure plus exactly one lab selected by concept shape. The lab must provide active recall, a source-grounded visual, learner action before reveal, and feedback. Typical shapes include a state machine for gates, a step-through timeline for procedural flow, a delay simulator for timing, prediction for unknown outcomes, or compare/contrast for near-miss behavior; the lab README remains authoritative for the actual template and integration method.

### Full Lab

Build at least ten sections and multiple concept-shaped labs. Include:

- the Condensed explanatory foundation and source/ownership map;
- a multi-step architecture or request-flow view;
- an architecture map;
- a five-to-ten-question knowledge check;
- a connect-the-concepts graph;
- a collapsible quick reference for important messages, fields, or rules; and
- for cross-language learners, 8–12 syntax cards and side-by-side comparisons throughout.

Choose additional practice by learning objective rather than visual novelty:

- a toggleable state machine or decision game for validation and authority;
- an animated timeline or Parsons sequencer for ordering and lifecycle;
- a network simulator for latency, jitter, and packet-loss behavior;
- compare/contrast for similar APIs, near misses, or bug/fix pairs;
- prediction where the learner commits before output, next state, or blocking gate is revealed;
- a worked-example fader for full support through independent attempt;
- self-explanation cards for important code lines and architecture decisions; and
- confidence checks after quiz or prediction answers to expose false confidence.

Every selected practice component must use source-backed data, answers, transitions, and feedback. Do not add a generic game whose mechanic does not teach the concept.

### Large Full Lab delegation

Delegation is optional and always approval-gated. It becomes useful when there are at least six static sections, at least three labs, or a cross-language syntax-card set. Before transport, choose read-only work or editable isolation; editable delegates must not share a mutable checkout or destination.

The producer first owns the complete shell: layout, CSS, navigation, section containers and IDs, shared JavaScript, source map, and integration contract. The producer also drafts the first anchoring sections—normally syntax reference when applicable, architecture overview, and request journey—because they set voice and cross-references.

Delegate only self-contained sections or labs. Give each delegate the topic, persona, source-discovery expectation, intended structure, relevant HTML/CSS contract, concept data, selected lab template, and `main.js` integration seam. Returned work is input to the producer, not an independently accepted artifact. The producer merges it, resolves ID and cross-reference conflicts, and retains destination, reviewer, and final-acceptance ownership. If output is empty, corrupted, ungrounded, or about the wrong concept, narrow and retry once when useful; otherwise draft it locally.

### HTML and CSS patterns

A static document can embed its CSS in `index.html`. Useful structures include:

- a hero with eyebrow, headline, summary cards, and table of contents;
- numbered section cards;
- CSS-grid flow diagrams and inline SVG sequence diagrams;
- ownership tables and cross-reference callouts; and
- syntax-colored `<pre>` blocks with `overflow-x: auto`, `white-space: pre`, and `max-width: 100%`.

Use an accessible dark palette such as:

```css
:root {
  --bg: #0b1020;
  --panel: #111a33;
  --ink: #eef4ff;
  --muted: #aab7d4;
  --accent: #6ee7ff;
  --accent-2: #ffd166;
  --good: #55d68b;
  --bad: #ff6b6b;
}
```

For cross-language code, use a two-column grid that collapses at 700px:

```css
.split-code {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: 16px;
  margin: 12px 0;
  width: 100%;
}
.split-code pre {
  max-width: 100%;
  overflow-x: auto;
  margin: 0;
}
.split-code .side-label {
  margin-bottom: 6px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}
@media (max-width: 700px) {
  .split-code { grid-template-columns: minmax(0, 1fr); }
}
```

### Critical JavaScript patterns

- **Timeline:** activate steps sequentially and reveal each payload with its step.
- **Gate playground:** evaluate gates top-to-bottom; mark prior gates passed, the first failure blocked, and later gates neutral.
- **Node graph:** drag with document-level move/up listeners; draw output-to-input SVG cubic Bézier paths; set SVG classes with `setAttribute`; validate an edge by node endpoints rather than ports; calculate delete handles at Bézier `t = 0.5`; keep the graph container `pointer-events: none` and nodes `pointer-events: auto`.

Keep graph state/UI setup separate from DOM rendering. `updateUI()` owns reset, score, and button visibility; `renderNodes()` renders nodes and must not reset those values:

```javascript
function buildNodes() {
  updateUI();
  renderNodes();
}
```

Calling `renderNodes()` after showing a next button is safe only when rendering has no hidden UI-reset side effects. Do not merge `updateUI()` into `renderNodes()` while adapting the graph template.

## Reviewer checklist

The reviewer receives the explainer or condensed claim checklist and the target persona, but independently searches the repository. They must not treat the producer's source map, file references, diagrams, examples, lab answers, or quiz keys as evidence.

Use this review prompt as the minimum contract:

```text
Act as a factual reviewer. Independently rediscover the source for this concept.
Do not trust paths or claims supplied by the explainer.

For every claim, verify routes and methods; gate order and conditions; fields and
required/optional status; symbols and signatures; constants; file paths; query
patterns; diagrams; examples; lab transitions and feedback; quiz answers; and
cross-language syntax.

Flag unsupported, partially wrong, or stale claims. For each finding return:
1. the incorrect explainer claim;
2. the source-backed correction;
3. the confirming path and symbol or line; and
4. CRITICAL or MINOR severity.
```

For an explainer with at most four sections, one reviewer may cover the whole artifact. For five or more sections, focused reviewers may separately cover:

| Review role | Surface |
|-------------|---------|
| Syntax | Syntax cards, code examples, language comparisons |
| Architecture | Diagrams, ownership map, request/message flow |
| Code accuracy | Code blocks, queries, API patterns, gate logic |
| Interactive lab | State transitions, scenarios, answers, feedback |

Each focused reviewer gets only its review surface and associated claims, but still rediscovers the relevant source independently. A local fallback follows the same checklist with a fresh source search and must be reported as local review, not separate-agent review.

Classify a finding as `CRITICAL` when it would materially mislead the learner or make an interaction/answer false; use `MINOR` for supported but imprecise wording. Fix every CRITICAL and every MINOR that would confuse the target persona, then reread the confirming source and affected explainer section. If any one reviewer reports at least three CRITICAL findings, repeat a source-grounded pass after corrections. Review is complete only when no CRITICAL finding remains and the review mode, corrections, and residual MINOR findings are recorded.

## Browser validation

Run this only after the workflow has started the server and verified the exact page identity with `curl`. Confirm installed command forms first with `playwright-cli --help`, and keep all screenshots or incidental snapshots in a temporary directory.

```bash
URL=http://127.0.0.1:3456/
EVIDENCE_DIR="$(mktemp -d /tmp/create-explainer-browser.XXXXXX)"
trap 'playwright-cli close >/dev/null 2>&1 || true' EXIT

playwright-cli open "$URL"
playwright-cli resize 1440 900
playwright-cli eval "() => ({ title: document.title, heading: document.querySelector('h1')?.textContent?.trim() })"
playwright-cli screenshot --filename="$EVIDENCE_DIR/desktop.png"
```

The title or heading must identify the reviewed explainer. Check layout at desktop and again at 700px with this expression; the result must be an empty array:

```bash
playwright-cli eval "() => {
  const issues = [];
  const root = document.documentElement;
  if (root.scrollWidth > window.innerWidth + 1) {
    issues.push({ type: 'page-horizontal-overflow', width: root.scrollWidth, viewport: window.innerWidth });
  }
  document.querySelectorAll('pre, .split-code, .syntax-card, details, [data-expandable]').forEach((el) => {
    const rect = el.getBoundingClientRect();
    if (rect.left < -1 || rect.right > window.innerWidth + 1) {
      issues.push({ type: 'viewport-cutoff', element: el.tagName, text: el.textContent.slice(0, 80) });
    }
    if (el.tagName === 'PRE' && el.scrollWidth > el.clientWidth + 1) {
      const overflow = getComputedStyle(el).overflowX;
      if (!['auto', 'scroll'].includes(overflow)) {
        issues.push({ type: 'unsafe-code-overflow', text: el.textContent.slice(0, 80) });
      }
    }
  });
  return issues;
}"

playwright-cli resize 700 900
playwright-cli eval "() => ({ pageWidth: document.documentElement.scrollWidth, viewport: window.innerWidth, splitColumns: [...document.querySelectorAll('.split-code')].map((el) => getComputedStyle(el).gridTemplateColumns) })"
# Repeat the issue expression above; its result must still be [].
playwright-cli screenshot --filename="$EVIDENCE_DIR/mobile-700.png"
```

For Guided and Full Lab output, take a fresh snapshot, exercise each concept-specific control from that snapshot, and refresh the snapshot after every material state change:

```bash
playwright-cli snapshot --filename="$EVIDENCE_DIR/before-interactions.md"
# playwright-cli click <fresh-element-ref>
# Repeat snapshot/click for toggles, sliders, quiz choices, games, and graph controls.
```

Expand hidden states before the final layout pass:

```bash
playwright-cli eval "() => {
  document.querySelectorAll('details').forEach((el) => { el.open = true; });
  document.querySelectorAll('.syntax-card:not(.open), [data-expandable]:not(.open)').forEach((el) => el.click());
  return {
    details: document.querySelectorAll('details[open]').length,
    syntaxCards: document.querySelectorAll('.syntax-card.open').length,
    expandables: document.querySelectorAll('[data-expandable].open').length
  };
}"
# Repeat the issue expression and require [].
playwright-cli screenshot --filename="$EVIDENCE_DIR/expanded-700.png"
playwright-cli console error
playwright-cli close
trap - EXIT
printf 'Browser evidence: %s\n' "$EVIDENCE_DIR"
```

Tabs, accordions that do not use the selectors above, quiz reveals, and collapsible groups must each be activated through their current snapshot refs before the expanded-state check. Treat unexpected console or page errors as failures; an expected favicon request alone is not an explainer defect. Fix durable source, reconfirm page identity, and repeat affected checks. Close the task-owned browser on success and failure, retain requested evidence, and report its temporary path.

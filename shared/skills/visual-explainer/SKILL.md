---
name: visual-explainer
description: Generate a self-contained HTML explainer page that conveys a system, code change, plan, dataset, or technical concept to a reader. Use when producing a diagram, architecture overview, comparison or audit table, project recap, data dashboard, or slide deck, or when another skill needs an explainer page rendered.
metadata:
  short-description: Render self-contained HTML explainer pages
allowed-tools: read,write,edit,bash
---

# Visual Explainer

## Language Definitions

- **Explainer page** — a self-contained HTML artifact that conveys a system, change, plan, or dataset to a reader. It carries no interactive assessment; learner-response artifacts belong to `teach`.
- **Representation** — the chosen visual form for the content: Mermaid diagram, CSS cards, semantic table, timeline, dashboard, or slides.
- **Diagram shell** — the canonical Mermaid container providing zoom, pan, and expand controls.
- **Aesthetic direction** — the committed visual identity of a page, chosen before any CSS is written.

## Workflow

### 1. Confirm the page and its destination

Establish what the reader must understand after one pass, and confirm the output location. Write to the caller's location when one is supplied. Otherwise default to `${TMPDIR:-/tmp}/explainer-<slug>-<timestamp>.html`, which keeps pages out of the repository. A caller composing this skill retains its own artifact location and acceptance authority.

Prefer an explainer page over terminal output when the content is inherently visual. When a table would carry 4+ rows or 3+ columns, render the page and give only a short chat summary.

Completion criterion: the reader's takeaway is stated, and the absolute output path is fixed.

### 2. Choose the representation

Select from content shape before writing markup:

| Content | Representation |
|---|---|
| Flowchart, pipeline, state machine, decision tree | Mermaid |
| Sequence, ER/schema, class, C4, topology | Mermaid |
| Text-heavy architecture, module internals, plans | CSS grid cards, optionally with a Mermaid overview |
| 15+ element architecture | Hybrid: small Mermaid overview plus CSS detail cards |
| Comparison, audit, status matrix | Semantic HTML `<table>` |
| Timeline, roadmap | CSS timeline |
| Dashboard, metrics | CSS grid with KPI cards or charts |
| Slide deck | Slides, only when explicitly requested |

Start from the template matching the representation and adapt it: `templates/architecture.html` for cards, `templates/mermaid-flowchart.html` for diagrams, `templates/data-table.html` for tables, `templates/slide-deck.html` for slides. Each template is a starting document to copy and modify, not a file to link.

Completion criterion: one representation is chosen with a reason, and its template is loaded.

### 3. Commit to an aesthetic direction

Choose a direction before writing CSS: blueprint, editorial, paper/ink, terminal, IDE-inspired, or data-dense. Define the palette as custom properties — `--bg`, `--surface`, `--border`, `--text`, `--text-dim`, and 3–5 accents.

Avoid generic defaults. Do not use a body font that is only Inter, Roboto, Arial, Helvetica, or system-ui. Do not build the main palette on Tailwind-default violets (`#8b5cf6`, `#7c3aed`, `#a78bfa`, `#d946ef`), a cyan+magenta+purple neon scheme, or gradient-mesh blobs.

Workable pairings: DM Sans + Fira Code; Instrument Serif + JetBrains Mono; IBM Plex Sans + IBM Plex Mono; Bricolage Grotesque + Fragment Mono; Plus Jakarta Sans + Azeret Mono. Workable accents: terracotta+sage, teal+slate, rose+cranberry, amber+emerald, deep blue+gold.

Completion criterion: the page would remain recognizable if compared against a generic dark/violet template.

### 4. Render the page

Produce one complete self-contained HTML document with embedded CSS and any needed JavaScript. No external build step, no separate asset files.

Never invoke an external binary or network service to build the page. Embed a raster image only when the harness can generate one natively, as a base64 data URI; otherwise build the visual from CSS and SVG. Do not probe for image-generation tooling.

**Mermaid invariants**, when the page contains a diagram:

- Use `theme: 'base'` with `themeVariables` matching the page palette.
- Wrap every diagram in the Diagram shell from `templates/mermaid-flowchart.html`: `.diagram-shell` > `.mermaid-wrap` > `.zoom-controls` + `.mermaid-viewport` > `.mermaid-canvas`. Never use a bare `<pre class="mermaid">`.
- Every diagram needs zoom in/out/reset/expand, Ctrl/Cmd+scroll zoom, drag panning, and click-to-expand.
- Prefer `flowchart TD`. Use `LR` only for simple 3–4 node linear flows.
- Use `<br/>` inside quoted labels; never escaped `\n`.
- Never define a page-level `.node` class — Mermaid uses it internally. Namespace page classes, for example `.ve-card`.

**Layout invariants:**

- Use semantic HTML where it aids accessibility and copy/paste: `<table>`, headings, lists, `<details>`, captions.
- Prevent overflow with `min-width: 0` on grid and flex children, `overflow-wrap: break-word` on long text, and scroll containers for wide tables and code.
- Do not set `display: flex` on `<li>` when list markers matter.
- Reserve elevated depth for primary sections; keep reference material flat.
- Use animation only where it clarifies hierarchy. Respect `prefers-reduced-motion`. No continuous glow, pulse, or breathing effects on static content.

Completion criterion: a complete HTML document exists at the fixed path.

### 5. Verify and report

Confirm before reporting completion:

- complete self-contained document written to the agreed path;
- no console errors when opened;
- no horizontal overflow at normal desktop width;
- fonts load with fallbacks;
- tables preserve rows and columns and wrap long text;
- every Mermaid diagram uses the Diagram shell with working zoom, pan, and expand;
- the main idea is obvious within the first viewport.

Attempt to open the page with the platform opener when available. Always report the absolute path, even when opening fails.

Completion criterion: the checks above pass and the absolute path is reported.

## Activities

### Slide deck mode

Selected only when the caller explicitly requests slides. Slides are a distinct medium, not a paginated article.

Before writing markup, inventory the source and map every item to a slide. Never drop content to hit a fixed slide count — add slides instead. Each slide occupies one viewport (`100dvh`) with no page-level scrolling. Use larger type, fewer objects per slide, and varied composition. Include the navigation chrome from `templates/slide-deck.html`: previous/next controls, slide count, keyboard navigation, and carousel indicators.

Completion criterion: every source item appears on a slide, each slide fits one viewport, and navigation chrome works.

## Reference

- `references/css-patterns.md` — load when the page needs overflow protection, depth treatments, collapsible sections, SVG connectors, KPI or before/after panels, directory trees, or prose-page typography beyond the invariants in step 4.
- `references/libraries.md` — load when the page embeds Mermaid configuration beyond the Diagram shell, Chart.js visualizations, anime.js sequences, or Google Fonts loading.
- `references/responsive-nav.md` — load when the page has 4 or more major sections and needs in-page navigation with scroll spy.
- `references/slide-patterns.md` — load when Slide deck mode is selected, for the slide engine, typography scale, transitions, the 10 slide-type layouts, and density limits.

A single-diagram page, a comparison table, or a short architecture overview completes without loading any of these.

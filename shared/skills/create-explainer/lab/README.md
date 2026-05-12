# Lab Templates

Self-contained, copy-pasteable interactive components for explainers. Each is a single HTML file with embedded CSS and JS. No build step. No external dependencies.

## Templates

| Template | Purpose | Complexity | Lines |
|----------|---------|-----------|-------|
| [`node-graph-builder.html`](node-graph-builder.html) | n8n-style directed graph builder. Drag nodes, draw bezier edges between ports, multi-round validation with synonym disguises. | High | ~500 |
| [`toggleable-state-machine.html`](toggleable-state-machine.html) | Toggle rows that control a gate-by-gate validation flow. Watch gates turn green (pass) or red (block) in order. | Low | ~200 |
| [`decision-game.html`](decision-game.html) | "Be The Server" accept/reject game. Random scenarios, score tracking, streak counter. | Low | ~150 |
| [`network-simulator.html`](network-simulator.html) | Range sliders for latency/jitter/packet loss. Live timeline visualization with color-coded events. | Low | ~150 |
| [`quiz.html`](quiz.html) | Multiple-choice quiz with correct/wrong styling, explanations, progress tracking, end screen. | Low | ~200 |
| [`architecture-map.html`](architecture-map.html) | Clickable table rows that expand to show file ownership and responsibilities per business rule. | Low | ~180 |
| [`syntax-reference-cards.html`](syntax-reference-cards.html) | 8-12 collapsible cards with side-by-side code for cross-language syntax comparison. Toggle cards open/closed. Each card has JS and Python (or any language pair) code blocks. | Low | ~200 |

## How to use

1. Copy the template file(s) you need into your explainer directory.
2. Search for `/* ADAPT: ... */` comments — these mark every place that needs customization for your concept.
3. Replace sample data (nodes, gates, scenarios, questions, rules) with your concept's actual logic.
4. Tweak colors in the `:root` CSS variables to match your explainer's theme.
5. For a multi-section explainer, copy each template's `<style>` and `<script>` blocks into your main `index.html` or `main.js`.

## Integration patterns

### Single-file explainer (index.html only)
Copy the `<style>` block and `<script>` block from the template into your `index.html`. Rename IDs to avoid collisions if using multiple templates.

### Split explainer (index.html + main.js)
Copy the `<style>` block into `index.html`. Copy the `<script>` content (minus the `<script>` tags) into `main.js`.

### Theme consistency
All templates share the same dark-theme CSS variable names:
```css
--bg, --bg-elev, --bg-card, --border, --text, --text-dim, --accent, --client, --server, --network, --fx, --danger, --warn
```
Keep these consistent across all templates in your explainer for a unified look.

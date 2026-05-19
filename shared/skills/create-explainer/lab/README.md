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
| [`compare-contrast.html`](compare-contrast.html) | Side-by-side examples where the learner identifies the behavior-changing difference. Useful for bug/fix pairs and near-miss APIs. | Low | ~160 |
| [`prediction-lab.html`](prediction-lab.html) | Commit-before-reveal scenarios. Learner predicts output, next state, or blocking gate, then reveals an animated timeline. | Low | ~80 |
| [`parsons-sequencer.html`](parsons-sequencer.html) | Drag shuffled code lines or flow steps into the correct order. Useful for request lifecycles and algorithm ordering. | Medium | ~60 |
| [`worked-example-fader.html`](worked-example-fader.html) | Full solution → partial solution → self-explanation → independent attempt. Fades support as understanding grows. | Low | ~45 |
| [`self-explanation-card.html`](self-explanation-card.html) | Focus one line of code and ask why it exists before showing a model explanation and answer checklist. | Low | ~55 |
| [`confidence-check.html`](confidence-check.html) | Quiz micro-component that records confidence after an answer to surface false confidence and shaky knowledge. | Low | ~45 |

## Lab selection matrix

Choose the lab from the shape of the concept:

| Concept shape | Use |
|---------------|-----|
| Relational topic | `node-graph-builder.html` or `architecture-map.html` |
| Procedural topic | `parsons-sequencer.html`, timeline, or `worked-example-fader.html` |
| Similar concepts or near-misses | `compare-contrast.html` |
| Unknown outcome | `prediction-lab.html` |
| Validation / authority topic | `toggleable-state-machine.html` or `decision-game.html` |
| Cross-language learner | `syntax-reference-cards.html` plus split-code blocks |
| Beginner topic | `worked-example-fader.html` |
| Retention goal | `quiz.html` plus delayed re-ask |
| Timing / network topic | `network-simulator.html` |
| Debugging topic | combine `compare-contrast.html`, `prediction-lab.html`, and `self-explanation-card.html` |

## Minimum viable lab

For Guided and Full Lab explainers, include at least:

- one active recall moment
- one source-grounded visual
- one learner action before reveal
- one feedback mechanism

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

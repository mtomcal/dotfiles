# Architecture HTML Report

Create one static HTML file outside the repository. Tailwind and Mermaid may load from CDNs; all report content, custom styles, and non-Mermaid visuals stay in the file.

## Required structure

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Architecture review — {{repo}}</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script type="module">
    import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
    mermaid.initialize({ startOnLoad: true, theme: "neutral", securityLevel: "loose" });
  </script>
  <style>
    .seam { stroke-dasharray: 5 5; }
    .leak { stroke: #dc2626; stroke-width: 2; }
    .deep { background: linear-gradient(135deg, #0f172a, #1e293b); color: white; }
  </style>
</head>
<body class="bg-stone-50 text-slate-900">
  <main class="mx-auto max-w-6xl space-y-12 px-6 py-12">
    <header><!-- repo, date, scope, legend, hotspot evidence --></header>
    <section id="comparison"><!-- compact candidate comparison --></section>
    <section id="candidates" class="space-y-10"><!-- candidate cards --></section>
    <section id="top-recommendation"><!-- recommendation --></section>
  </main>
</body>
</html>
```

## Candidate card contract

Each candidate card contains:

- short deepening title and anchor
- recommendation badge: `Strong`, `Worth exploring`, or `Speculative`
- dependency category from `codebase-design`
- monospaced file list
- side-by-side Before and After diagrams
- one-sentence problem and one-sentence direction
- concise wins explicitly tied to depth, leverage, locality, seams, or testing
- spec tension callout when applicable

The comparison section contrasts candidates by evidence strength, expected depth, locality gain, migration risk, test impact, and spec tension. The top recommendation links to its card and explains why it ranks first.

## Diagram patterns

Choose the clearest pattern per candidate rather than repeating one layout:

- Mermaid call/dependency graph for scattered call flow
- sequence diagram for excess round trips
- stacked bands for shallow pass-through modules
- mass diagram comparing interface size with hidden implementation
- call-graph collapse showing behavior moving behind one interface
- hand-built boxes and inline SVG when Mermaid cannot show depth clearly

Diagrams carry the argument. Label modules, interfaces, seams, adapters, and leakage. Keep each diagram readable without surrounding prose and visually emphasize the smaller interface and deeper implementation in the After state.

## Style and tone

Use generous whitespace, restrained color, red only for leakage, and amber for spec tension. Keep prose sparse and evidence-specific. Use the `codebase-design` vocabulary precisely; domain names come from project specs. Avoid generic claims such as “cleaner” or “easier to maintain”—name the locality, leverage, depth, seam, or test gain.

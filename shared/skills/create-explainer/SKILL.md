---
name: create-explainer
description: Creates interactive, codebase-accurate HTML explainers for any concept in a software project. Asks the engineer about experience level and specialty to tailor analogies, depth, and code density. Includes a mandatory reviewer pass that independently discovers source files to verify factual claims. Use when the user wants to understand how a system or feature works across code boundaries, create onboarding docs, build interactive learning materials, or explain a complex flow to a teammate.
metadata:
  short-description: Create codebase explainers
allowed-tools: read,write,edit,bash
---

# Create Explainer

## Language Definitions

- **Output tier** — agreed scope controlling time, interactivity, and complexity.
- **Condensed** — static reference with diagrams, messages, and file map.
- **Guided** — static explanation plus one simulation.
- **Full Lab** — comprehensive interactive explainer.
- **Source-grounded reviewer pass** — mandatory independent source rediscovery and claim verification.
- **Claim checklist** — factual assertions a reviewer verifies.
- **Lab template** — reusable interactive component selected by concept shape.

## Workflow

Build a self-contained HTML explainer from actual code and specs, tailored to the learner, then review and validate it before reporting the durable files and served URL.

### 1. Route the learner and tier

If the concept, audience, and desired depth are already clear, state the inferred persona and tier and ask only about missing or risky details. Otherwise ask, in order, for:

1. the concept or end-to-end flow;
2. experience with the codebase's stack (`beginner`, `intermediate`, or `advanced`);
3. role or specialty;
4. time/depth; and
5. optional prior knowledge to skip.

Route `≤ 5 minutes` to Condensed, `5–15 minutes` to Guided, and `> 15 minutes` or “as long as it takes” to Full Lab. Default to Full Lab when the user does not request less. Match analogies, terminology, code density, and subsystem emphasis to the persona. For a learner crossing languages, plan side-by-side comparisons throughout and an 8–12-card syntax reference.

Present one concise checkpoint naming the tier, persona, concept, planned sections, omissions, and reading time. Wait for `proceed`, `adjust`, or `cancel`; do not inspect and draft the artifact before approval. Completion: the persona, tier, concept boundary, and approved section list are explicit.

### 2. Map source truth

Find the concept's entry points, trace its relevant cross-boundary call/message flow, and read authoritative specs, schemas, and implementations. Record each visited path, owning symbol or line, and the truth it establishes. Include state ownership: explain who owns the authoritative value and why.

Start a claim checklist covering every route/method, validation order, field and optionality, symbol/signature, constant, file path, query pattern, diagram edge, lab behavior, answer key, and other factual assertion planned for the explainer. Omit unsupported claims; use a visible `TODO: verify` only when the structure requires a placeholder that will be resolved before review. Completion: every planned factual claim has source evidence or is excluded.

### 3. Draft the selected output

Write durable source to the user/caller-selected destination, defaulting to `./explainer/`. Validation screenshots, snapshots, and incidental browser artifacts instead go under an OS temporary directory, never the project root or explainer source directory.

| Tier | Required artifact |
|------|-------------------|
| Condensed | `index.html` only: summary, 2–4 source-grounded sections with diagrams/examples, and a file/ownership map. No lab. |
| Guided | `index.html` + `main.js`: Condensed content plus exactly one concept-shaped lab with active recall, a source-grounded visual, learner action before reveal, and feedback. |
| Full Lab | `index.html` + `main.js`: 10+ sections, multiple concept-shaped labs, architecture map, 5–10-question quiz, concept graph, quick reference, and the applicable practice components listed below. |

Keep the output self-contained: no build step or external dependency. Use lab templates rather than rebuilding their mechanics, and choose by concept shape rather than visual novelty. For Guided and Full Lab, choose the template from `lab/README.md#lab-selection-matrix` by concept shape; keep the selected lab's mechanics beside this step instead of maintaining a second catalog. For code-heavy or cross-language explainers, use a 1400px content width, overflow-safe code blocks, side-by-side comparisons, and a mobile single-column layout.

For a large Full Lab, drafting may be delegated only after the user approves sub-agent use. Select read-only versus editable isolation before transport. The producer retains the shell, CSS, navigation, source map, integration, IDs, review, destination, and final acceptance. Delegate only self-contained sections or labs; retry narrowly or draft locally when returned work is unusable. Completion: the tier contract is present at the durable destination and every template adaptation is grounded in the mapped source.

### 4. Self-check the complete draft

Before review, verify referenced paths exist, snippets use the claimed language and source behavior, HTML IDs match JavaScript consumers, the claim checklist covers diagrams and interactions, and no placeholder or unverified TODO remains. Check that files are self-contained and match the selected tier. Fix failures before requesting review. Completion: the artifact is internally complete and the claim checklist is ready for independent checking.

### 5. Run the mandatory source-grounded reviewer pass

Ask whether a separate reviewer sub-agent is approved if the user has not already approved delegation. When approved and available, give the reviewer the explainer or claim checklist and persona, but require independent source rediscovery rather than trusting the producer's source map or file references. Use multiple focused reviewers for a large explainer when useful; each receives only its review surface and claims.

If separate review is declined or unavailable, perform the same source-grounded pass locally by rediscovering sources independently from the draft's map. Explicitly report that no separate reviewer was used; never imply agent independence.

For every finding, record the incorrect claim, source-backed correction, confirming path and symbol/line, and `CRITICAL` or `MINOR` severity. Fix every CRITICAL finding and any MINOR finding that would confuse the persona. Re-read the affected source after each fix. If any reviewer reports at least three CRITICAL findings, run another reviewer pass after correction. Never skip review or serve known CRITICAL errors. Completion: no CRITICAL finding remains and the review mode and results are recorded.

### 6. Serve the reviewed source

Check whether port `3456` is free and whether any responder is an older artifact. If occupied, choose the next free port. Start Python's server from the durable explainer directory, then fetch the exact URL and grep for an explainer-specific headline before browser checks:

```bash
cd /path/to/explainer
python3 -m http.server 3456 --bind 0.0.0.0
curl -fsS http://127.0.0.1:3456/ | rg "Expected unique headline"
```

Use one verified URL consistently. A listening port without the expected page identity is a failure, not completion. Keep the verified server running for the final URL unless the user asks otherwise, and retain its PID/port as task-owned state.

### 7. Validate the served artifact in a browser

Open the identity-checked URL with the available browser automation owner. Validate every tier at its designed desktop viewport and at 700px width: page identity, horizontal overflow, viewport cutoffs, responsive layout, and unexpected console errors. For Guided and Full Lab, exercise controls and expand every accordion, tab, syntax card, quiz reveal, and collapsible group before rechecking layout. Save requested screenshots and transient evidence under the temporary directory, and close the task-owned browser even on failure.

Fix failures in the durable source, recheck page identity, and repeat the affected browser checks. If no browser tool can run, report browser validation as incomplete and do not claim it passed. Completion: the served revision—not an older artifact—passes the applicable desktop, mobile, expanded-state, interaction, and console checks.

### 8. Report completion

Return:

- concept, persona assumptions, and selected tier;
- absolute durable source paths;
- source-map scope and reviewer mode/findings outcome;
- verified URL, port, and server ownership;
- browser checks and temporary evidence paths;
- limitations or incomplete checks; and
- cleanup state for task-owned browser and incidental artifacts.

Completion: the user can locate the source, open the live reviewed artifact, understand what was verified, and later identify or stop the retained server.

## Reference

- Load [Intake and persona](REFERENCE.md#intake-and-persona) only when the concept, audience, or depth still needs calibration.

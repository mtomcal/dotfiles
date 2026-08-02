---
name: create-plan
description: Create one execution-ready Beads molecule from a human-approved scope snapshot, with context-sized TDD slices, genuine dependencies, execution traces, and exact model and review policy. Use when a feature, fix, migration, or refactor needs a durable implementation graph before execution begins.
metadata:
  short-description: Create an execution-ready Beads molecule
allowed-tools: read,bash
---

# Create Plan

## Language Definitions

- **Scope snapshot** — human-approved objective, acceptance criteria, failure criteria, and exclusions, frozen once approved.
- **Execution molecule** — one root epic plus its work-bead graph; the only durable result of this skill.
- **Current-state gap** — desired behavior that code or tests at the source fixed point do not yet satisfy.
- **Proposed execution trace** — evidence-grounded call tree of intended runtime order and depth for one slice, distinguishing binding order from permitted internal variance.
- **Exact model assignment** — command, provider, model id, and thinking level bound to a role.

Repository glossary wording is authoritative where it overlaps. An execution molecule is not a spec-extraction plan, teaching workspace, or `bd mol` template proto.

This skill creates no durable Markdown. It MUST NOT write `PLAN.md`, `.plan`, slice files, verification files, or any `.beads/` state into a source repository.

## Workflow

Load the shared [`beads`](../beads/SKILL.md) skill before any `bd` operation; it owns routing verification, durable-write serialization, graph mechanics, and checkpointing.

### 1. Pin source identity and fixed point

Verify command-repo routing through the `beads` skill first. Then resolve the canonical source checkout, its normalized repository identity, and one full source fixed point:

```bash
git rev-parse --show-toplevel
git remote get-url origin    # SSH and HTTPS spellings normalize to one identity
git rev-parse HEAD           # full hash, never abbreviated
```

If remote aliases cannot normalize, or the repository has no remote and no explicit key, stop and require an explicit repository key. A spec diff is **not** required; changed specs are evidence when they exist, not a precondition.

Record the caller's current exact model configuration as planner provenance.

Completion criterion: canonical root, normalized repository identity, full source fixed point, and planner provenance are fixed, and `BEADS_DIR` routing is verified.

### 2. Gather evidence and approve the scope snapshot

Inspect relevant code, tests, documentation, available specifications, and risks at the fixed point. Account for each desired behavior as already satisfied with concrete evidence, a current-state gap with evidence of what is absent, or ambiguous with the conflicting sources quoted.

Then obtain **explicit human approval** of the scope snapshot: objective, acceptance criteria, failure criteria, and exclusions. Ambiguity that prevents a safe technical sequence stops planning; report the exact decision needed rather than inferring it.

The snapshot freezes on approval. Any later mutation requires a linked decision bead and fresh human approval.

Completion criterion: every desired behavior has an evidenced disposition, only current-state gaps remain in scope, and the human has explicitly approved all four snapshot fields.

### 3. Design slices, traces, and dependencies

Design context-sized vertical slices that each fit one fresh agent context and deliver observable behavior through the applicable layers. Give every slice explicit RED/GREEN/REFACTOR cycles, because implementation agents may run an economical model.

Encode only genuine blocking dependencies. For a wide migration or mechanical refactor, use expand → migrate in bounded passing batches → contract, placing contraction after every migration.

Give each slice at least one proposed execution trace where runtime or operational order is material: a nested call tree with sequence numbers, `path:symbol` where known, and markers distinguishing existing, changed, new, and uncertain frames plus binding required order versus proposed internal structure. Existing frames need fixed-point evidence. Distinct entry points and async roots get separate traces; concurrent branches are marked unordered unless order is guaranteed. Observable or safety-critical ordering is binding; internal proposed frames may vary with rationale. A trace is an intended call tree, not captured runtime evidence or an exhaustive graph. Non-runtime work may substitute an explicitly justified ordered operational flow.

Each slice carries: behavior, dependencies, acceptance and failure criteria, a public test seam that survives refactoring, tracer cycles, focused commands, likely files, and risks.

Completion criterion: every gap maps to at least one context-sized slice, every slice has a public test seam and applicable trace, and dependency edges reflect genuine blockers only.

### 4. Approve review topology and exact assignments

Propose one review preset and obtain human approval for the complete policy:

| Preset | Required final gates | Depth |
|---|---|---|
| Lean | Repository mechanical gates; Scope fidelity | One independent Scope pass |
| Standard | Lean plus integrated Test Quality, Standards, Premortem, Security | One independent pass per non-mechanical gate |
| High assurance | Standard plus risk-triggered gates | Standard depth plus approved second passes for selected risk-bearing gates |

Independent per-slice Test Quality is mandatory before integration under **every** preset.

In the same approval, settle exact role defaults and per-bead overrides, reviewer independence rules, the exact coordinator assignment, escalation ladders, correction allowances (default 2), and critical-invariant triggers. Every executable bead receives a materialized exact assignment. An unavailable assignment blocks pending human-approved reassignment; it is never silently substituted and is not an escalation trigger.

Completion criterion: the human has approved one preset with any overrides, and every executable bead has a resolved exact model assignment, escalation ladder, and correction allowance.

### 5. Create the graph and validate before activation

Create the root molecule in **draft**, then its complete work graph, then validate. Serialize every durable write per the `beads` skill and retry contention rather than skipping it.

Validate before exposing any ready work:

- complete scope coverage — every acceptance criterion maps to at least one slice;
- acyclicity — `bd dep cycles` reports none;
- every executable bead carries its exact assignment;
- every applicable slice carries its trace; and
- review and remediation topology matches the approved policy.

A partial or failing graph stays draft/blocked and MUST NOT expose slices as ready. Reconcile it or explicitly discard the draft. Only after validation passes, mark the molecule ready and push the initial semantic checkpoint.

Report the root molecule id so execution can reference it explicitly.

Completion criterion: one ready molecule exists with a validated acyclic graph, the initial checkpoint is pushed, the root id is reported, and no durable Markdown or source-repository `.beads/` state was created.

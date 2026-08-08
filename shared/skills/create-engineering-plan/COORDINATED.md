# Coordinated Planning

Use this branch only after coordinated execution mode and shippable delivery intent are human-approved. Coordinated mode remains limited to testable engineering work; exploratory delivery must use lightweight mode.

## 1. Pin source identity and fixed point

Verify command-repo routing through the `beads` skill first. Then resolve the canonical source checkout, its normalized repository identity, and one full source fixed point:

```bash
git rev-parse --show-toplevel
git remote get-url origin    # SSH and HTTPS spellings normalize to one identity
git rev-parse HEAD           # full hash, never abbreviated
```

If remote aliases cannot normalize, or the repository has no remote and no explicit key, stop and require an explicit repository key. A spec diff is **not** required; changed specs are evidence when they exist, not a precondition.

Record the caller's current exact model configuration as planner provenance.

Completion criterion: canonical root, normalized repository identity, full source fixed point, and planner provenance are fixed, and `BEADS_DIR` routing is verified.

## 2. Validate the coordinated scope snapshot

Confirm the parent workflow's evidence against relevant code, tests, documentation, available specifications, and risks at the fixed point. The approved coordinated snapshot must explicitly contain objective, acceptance criteria, failure criteria, and exclusions. Ambiguity that prevents a safe technical sequence stops planning; report the exact decision needed rather than inferring it.

Any authoring portion identified by the planning boundary MUST appear in the exclusions with its owning skill named. The snapshot is frozen; any later mutation requires a linked decision bead and fresh human approval.

Completion criterion: every desired behavior has an evidenced disposition, only current-state gaps remain in scope, excluded authoring work names its owner, and all four coordinated snapshot fields are explicitly approved.

## 3. Design slices, traces, and dependencies

Design context-sized vertical slices that each fit one fresh agent context and deliver observable behavior through the applicable layers. Give every slice explicit RED/GREEN/REFACTOR cycles, because implementation agents may run an economical model.

Encode only genuine blocking dependencies. A false edge idles a worker for no reason; chain slices only where one truly cannot start until another closes. For a wide migration or mechanical refactor, use expand → migrate in bounded passing batches → contract, placing contraction after every migration.

When the dependency shape is not obvious, use the `WORKFLOW-SHAPES.md` support selected by the parent skill for parallel slices, review fan-out, expand/migrate/contract, and regression-locked bugfixes. A straightforward linear feature does not load it.

Give each slice at least one proposed execution trace where runtime or operational order is material: a nested call tree with sequence numbers, `path:symbol` where known, and markers distinguishing existing, changed, new, and uncertain frames plus binding required order versus proposed internal structure. Existing frames need fixed-point evidence. Distinct entry points and async roots get separate traces; concurrent branches are marked unordered unless order is guaranteed. Observable or safety-critical ordering is binding; internal proposed frames may vary with rationale. A trace is an intended call tree, not captured runtime evidence or an exhaustive graph. Non-runtime work may substitute an explicitly justified ordered operational flow.

Each slice carries: behavior, dependencies, acceptance and failure criteria, a public test seam that survives refactoring, tracer cycles, focused commands, likely files, and risks.

Completion criterion: every gap maps to at least one context-sized slice, every slice has a public test seam and applicable trace, and dependency edges reflect genuine blockers only.

## 4. Approve review topology and exact assignments

Propose one review preset and obtain human approval for the complete policy:

| Preset | Required final gates | Depth |
|---|---|---|
| Lean | Repository mechanical gates; Scope fidelity | One independent Scope pass |
| Standard | Lean plus integrated Test Quality, Standards, Premortem, Security | One independent pass per non-mechanical gate |
| High assurance | Standard plus risk-triggered gates | Standard depth plus approved second passes for selected risk-bearing gates |

Independent per-slice Test Quality is mandatory before integration under **every** preset.

In the same approval, settle exact role defaults and per-bead overrides, reviewer independence rules, the exact coordinator assignment, escalation ladders, correction allowances (default 2), and critical-invariant triggers. Also settle worker context-rotation policy: checkpoint and hard-rotation thresholds from 1–100 with hard rotation no lower than checkpoint. The coordinator writes ahead checkpoint and wind-down instructions; context comes only from native usage or explicit worker reports and is never estimated. No independent liveness-monitor, heartbeat, or worker-pane-termination policy is created. Every executable bead receives a materialized exact assignment and applicable rotation policy. An unavailable assignment blocks pending human-approved reassignment; it is never silently substituted and is not an escalation trigger.

Completion criterion: the human has approved one preset with any overrides, and every executable bead has a resolved exact model assignment, escalation ladder, correction allowance, and context-rotation policy.

## 5. Ingest atomically and validate before activation

Select the Beads graph-ingestion branch and load its [`GRAPH-INGESTION.md`](../beads/GRAPH-INGESTION.md) Reference file. Probe the installed `bd` graph schema with a disposable dry run before compiling the reviewed plan; unknown-field warnings or silently dropped values are failures. Materialize the complete molecule through the proven graph surface in one atomic apply, with one planner-owned activation gate blocking every initial implementation frontier. Required fields unsupported by that release are materialized after creation while the gate remains open.

Read the graph back from Beads and validate before exposing any ready implementation work:

- complete scope coverage — every acceptance criterion maps to at least one slice;
- exact node and edge counts and directions match the compiled plan;
- acyclicity — `bd dep cycles` reports none;
- every executable bead carries its exact assignment and lifecycle policy;
- every applicable slice carries its trace;
- review and remediation topology matches the approved policy; and
- only expected planner/control work is ready before gate closure.

A partial, lossy, or failing graph remains blocked by the activation gate. Reconcile it or explicitly discard the draft; never fall back to a partially runnable sequential graph. Only after readback validation passes, record the evidence, transition the root to its executable state, close the activation gate, confirm the expected first frontier, and create the initial semantic checkpoint. Push once at this activation boundary when remote durability is configured and authorized; do not push after each node, edge, or field write.

Report the root molecule id, installed Beads version, graph counts, validation evidence, activated frontier, and local/remote checkpoint state so execution can reference it explicitly.

Completion criterion: one ready molecule exists with a read-back, validated, acyclic graph; activation exposed exactly the expected frontier; checkpoint state is explicit; the root id is reported; and no durable Markdown or source-repository `.beads/` state was created.

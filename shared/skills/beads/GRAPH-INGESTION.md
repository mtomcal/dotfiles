# Version-aware graph ingestion

Use this workflow when a caller needs to materialize a non-trivial Beads graph from one reviewed plan. [`SKILL.md`](SKILL.md) remains the canonical command-repo and execution-authority contract; this Reference file owns only portable graph ingestion and activation.

## 1. Establish the installed contract

Run from the command repository and record `bd --version`, `bd create --help`, and `bd dep --help`. Treat installed help and a dry run as authoritative; `--graph` is an option on `bd create`, not a separate help command. Do not assume that a schema accepted by another Beads release is accepted here.

Build a tiny disposable graph fixture that exercises every intended node, edge, metadata, and root field, then run:

```bash
bd create --graph /tmp/beads-capability-probe.json --dry-run --json
```

A zero exit is insufficient when stderr reports unknown or dropped fields. Reject any field that errors, warns, or disappears on readback. Never probe by mutating the real graph.

For Beads 1.1.2, the proven portable shape uses symbolic node keys, edges whose `from` node depends on their `to` blocker, and string-valued metadata. Fields such as acceptance criteria or status may be dropped by this release and therefore require post-create materialization. This is evidence for that release, not a timeless schema.

## 2. Compile the reviewed plan

Generate the graph document outside the source repository. Keep a deterministic symbolic key for every node and edge so returned issue IDs can be reconciled with the plan.

The document MUST include:

- one molecule root;
- every implementation, review, gate, and remediation bead;
- genuine blocking edges only;
- model, thinking, fixed-point, execution-trace, and policy metadata encoded in fields proven by the capability probe; and
- one planner-owned activation gate that blocks every otherwise-runnable implementation frontier.

Keep unsupported but required fields in a separate deterministic materialization manifest keyed by symbolic node. Do not silently omit them or stringify structured metadata unless the chosen encoding is documented and validated on readback.

## 3. Create atomically while inactive

Run the complete graph through `--dry-run` first. Fail on parser errors, unknown-field warnings, unexpected counts, unresolved symbolic keys, or edge-direction ambiguity.

Apply the graph in one `bd create --graph` operation and capture its machine-readable key-to-ID result. The activation gate MUST remain open while unsupported fields are materialized with ordinary `bd` updates. Until validation succeeds, no implementation slice may become runnable.

If the installed release cannot create the required graph atomically, stop and report the capability gap. Do not fall back to a long, partially runnable sequence of node and edge writes.

## 4. Read back and validate

Read the created issues and dependencies from Beads rather than trusting generated input. Verify all of the following:

1. symbolic keys map one-to-one to issue IDs;
2. titles, types, descriptions, acceptance criteria, labels, assignments, model policy, and execution traces match the reviewed plan;
3. every expected edge exists in the correct dependent-to-blocker direction and no extra edge exists;
4. all initial implementation frontiers remain blocked by the activation gate;
5. `bd dep cycles` reports no cycle;
6. molecule lint reports no errors; and
7. the ready frontier contains only planner/control work expected before activation.

Use machine-readable installed commands for the audit, expanding the created IDs rather than trusting only the root summary:

```bash
bd show <created-id> --long --json
bd dep list <created-id> --json
bd dep cycles
bd lint <created-id>...
bd ready --mol <root-id> --json
```

Any mismatch leaves the activation gate open. Correct the graph, repeat readback, and record the validation evidence on the gate.

## 5. Activate at one semantic checkpoint

After all checks pass, transition the root to its planned executable state, close the activation gate with validation evidence, and confirm that the expected first implementation frontier is now ready. Group these correlated local writes into one recoverable checkpoint under the sync policy in [`SKILL.md`](SKILL.md).

Push the Beads command repository once at this activation boundary when a configured remote and the caller's authority require remote durability. Do not push after each field or edge write. Report the Beads version, graph counts, validation commands, activated frontier, local commit state, and remote push state.

## Failure rule

A graph that is incomplete, cyclic, lossy, unexpectedly ready, or not read back is not activated. Leave the gate open, preserve the evidence, and stop for repair or reconciliation.

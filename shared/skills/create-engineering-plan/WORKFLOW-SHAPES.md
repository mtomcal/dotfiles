# Workflow Shapes

Reference for the Beads execution model: what kinds of beads exist, how a molecule is executed, what shapes real engineering work takes, and how states transition.

Diagrams here are **illustrative models, not templates**. Real bead ids come from `bd`; real graphs encode only genuine blockers. `specs/execution-coordination.md` is authoritative wherever this file and it disagree.

## Bead taxonomy

A molecule is a root epic plus everything hanging off it. Two edge kinds do very different jobs:

- **Blocking edges** connect work beads and determine readiness. `bd ready --mol <root>` walks these.
- **Operational edges** connect attempts to the work they track. They never block anything, so retries and lost attempts cannot pollute the frontier.

```mermaid
graph TD
    ROOT["root · molecule<br/>scope snapshot, review policy,<br/>coordinator assignment"]

    ROOT --- S["slice<br/>one vertical behavior<br/>RED/GREEN/REFACTOR"]
    ROOT --- RV["review<br/>one independent axis<br/>reports, never edits"]
    ROOT --- RM["remediation<br/>consolidated findings<br/>isolated worker"]
    ROOT --- D["decision<br/>approved scope or<br/>policy change"]
    ROOT --- MG["mechanical gate<br/>tests, lint, type, build"]
    ROOT --- CS["coordinator-session<br/>one per boot<br/>holds the lease"]

    S -.tracks.-> A1["attempt<br/>one agent launch"]
    RV -.validates.-> A2["attempt<br/>one review pass"]

    classDef work fill:#2d4a3e,stroke:#5a8f73,color:#e8f5ee
    classDef op fill:#3d3a2d,stroke:#8f8259,color:#f5f0e8
    classDef root fill:#2d3a4a,stroke:#5a7a9f,color:#e8f0f5
    class ROOT,CS root
    class S,RV,RM,D,MG work
    class A1,A2 op
```

Solid lines are containment; dotted lines are the non-blocking operational edges. Only `slice`, `review`, `remediation`, `decision`, and `mechanical gate` are work beads. Attempts and coordinator sessions are permanent records, never frontier candidates.

## Execution lifecycle

What `execute-engineering-molecule` actually does per slice. The ordering constraint that matters most: **the durable attempt record is written before the agent is launched**, so a coordinator that dies mid-launch can reconcile rather than blindly relaunch.

```mermaid
sequenceDiagram
    participant C as Coordinator
    participant B as Beads
    participant H as Herdr
    participant W as Worker
    participant V as Verifier

    C->>B: pull, validate molecule, acquire lease
    B-->>C: lease held (non-expiring)
    C->>B: bd ready --mol root
    B-->>C: frontier slices

    Note over C,B: write-ahead: record before side effect
    C->>B: create attempt (planned) + instruction
    C->>B: checkpoint
    C->>H: launch worker with attempt token
    H->>W: packet (slice scope only)
    W->>W: RED, GREEN, REFACTOR in isolated worktree
    W->>B: write evidence (commit, files, results)
    W->>H: report completion
    H-->>C: notification only

    C->>B: read attempt evidence
    alt evidence missing
        C->>C: attempt stays nonterminal, no progress
    else evidence complete
        C->>V: audit slice at fixed point
        V->>B: findings
        alt findings
            C->>B: new attempt id + consolidated batch
            Note over C,W: correction loop, then escalate<br/>up the approved ladder
        else clean
            C->>C: run focused + mechanical gates
            C->>C: cherry-pick into integration branch
            C->>B: close slice, checkpoint
            C->>B: recompute frontier
        end
    end
```

Herdr completion is a notification, never evidence. A slice closes only after implementation evidence, an independent test-quality pass, mechanical gates, integration, and post-integration checks — which is why only closed blockers release dependent work.

## Worked workflow shapes

### Linear feature

Each slice genuinely depends on the last. Reviews fan out from the final integrated point, not from individual slices.

```mermaid
graph LR
    S1["slice<br/>parse config"] --> S2["slice<br/>validate remote"]
    S2 --> S3["slice<br/>write runtime config"]
    S3 --> R1["review<br/>Scope"]
    S3 --> R2["review<br/>Security"]
    S3 --> R3["review<br/>Test Quality"]
```

### Independent slices with review fan-out

The common mistake is chaining slices that have no real dependency. If two behaviors touch different seams, they are parallel — the graph should say so, because a false edge idles a worker for no reason.

```mermaid
graph LR
    S1["slice<br/>add --json flag"]
    S2["slice<br/>add --quiet flag"]
    S3["slice<br/>shared output formatter"]
    S3 --> S1
    S3 --> S2
    S1 --> G["mechanical gate<br/>repo tests"]
    S2 --> G
    G --> R1["review<br/>Standards"]
    G --> R2["review<br/>Premortem"]
```

Only the shared formatter is a genuine blocker. The two flags are independent and can run concurrently.

### Wide migration — expand, migrate, contract

Contraction must come after every migration batch, or the old form disappears while callers still use it. Batches are parallel; the contract step joins them.

```mermaid
graph LR
    E["slice<br/>expand: add new API<br/>old path still works"]
    E --> M1["slice<br/>migrate callers A"]
    E --> M2["slice<br/>migrate callers B"]
    E --> M3["slice<br/>migrate callers C"]
    M1 --> K["slice<br/>contract: remove old API"]
    M2 --> K
    M3 --> K
    K --> R["review<br/>Migration + Compatibility"]
```

### Bugfix with regression lock

The failing test comes first and is the whole point — it must fail before the fix and pass after, which is exactly the property authoring work cannot provide.

```mermaid
graph LR
    S1["slice<br/>failing regression test<br/>RED reproduces the bug"] --> S2["slice<br/>fix + GREEN"]
    S2 --> G["mechanical gate<br/>full suite"]
    G --> R["review<br/>Scope fidelity"]
```

## State machines

### Work bead

```mermaid
stateDiagram-v2
    [*] --> open
    open --> in_progress: worker claims
    in_progress --> awaiting_review: evidence returned
    awaiting_review --> needs_correction: findings
    needs_correction --> in_progress: new attempt
    awaiting_review --> integrating: audit + gates pass
    integrating --> closed: post-integration checks pass
    in_progress --> blocked: ladder exhausted
    needs_correction --> blocked: allowance exhausted
    blocked --> in_progress: approved decision
    closed --> [*]
```

Only `closed` releases dependents into the frontier. `blocked` needs an approved decision bead to move — never a silent retry.

### Attempt

```mermaid
stateDiagram-v2
    [*] --> planned: write-ahead record
    planned --> launched: Herdr launch
    launched --> submitted: instruction delivered
    submitted --> working
    working --> evidence_returned: durable evidence written
    evidence_returned --> verified: coordinator accepts
    evidence_returned --> rejected: findings
    planned --> lost: launch unobserved
    launched --> lost: Herdr state gone
    working --> lost: reconciliation fails
    submitted --> cancelled
    working --> cancelled
    verified --> [*]
    rejected --> [*]
    cancelled --> [*]
    lost --> [*]
```

`lost` is terminal by design. A lost attempt is never resumed under its old id — resumed work always gets a new attempt, so uncertain identity can never be mistaken for confirmed progress.

### Molecule and sync

```mermaid
stateDiagram-v2
    direction LR
    [*] --> draft
    draft --> ready: validation passes
    ready --> executing: lease acquired
    executing --> blocked: gate or ladder exhausted
    blocked --> executing: approved decision
    executing --> complete: all gates + checkpoint
    complete --> [*]
```

Sync state is orthogonal: `clean` normally, `pending` when the remote is unreachable. Under `pending` only the leased host may continue working, and both lease transfer and completion stay blocked until pull and push succeed.

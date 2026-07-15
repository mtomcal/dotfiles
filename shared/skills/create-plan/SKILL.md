---
name: create-plan
description: Create one immutable, single-agent technical implementation plan from a fixed spec diff, limited to behavior still missing at the fixed head. Use when a feature, fix, migration, or refactor has approved spec changes and needs a sequential implementation plan before execution is divided or orchestrated.
metadata:
  short-description: Create an immutable implementation plan
allowed-tools: read,write,bash
---

# Create Plan

## Language Definitions

- **Implementation plan** — immutable `PLAN.md` describing the remaining technical work that one agent can execute sequentially, including binding final review gates.
- **Fixed spec diff** — one two-endpoint Git comparison whose full commit hashes establish planning scope.
- **Current-state gap** — desired behavior in changed specs that code or tests at the fixed head do not yet satisfy.
- **Proposed execution trace** — evidence-grounded, debugger-style call tree of intended runtime order and depth for one ordered step; see the repository glossary for the authoritative definition.
- **Review gate** — binding final quality check defined by order, criteria, blocking behavior, and evidence, with no reviewer or model configuration; see the repository glossary.

Repository glossary wording is authoritative where it overlaps. An implementation plan is not a spec-extraction plan, execution ledger, slice packet, or repository-local `.plan` state. It defines review gates but never records review results, reviewer/model configuration, or execution state.

## Workflow

### 1. Pin the fixed spec diff

Find the canonical repository root. Require either one explicit `<base>..<head>` comparison or a request for the last positive integer `X` commits. Interpret “last X commits” exactly as `HEAD~X..HEAD`. Reject missing endpoints, three-dot notation, multiple comparisons, invalid commits, or an empty comparison.

Resolve both endpoints to full commit hashes and use only that pinned comparison thereafter. Enumerate every changed path under the repository's authoritative spec suite; those changed specs establish scope. If no authoritative spec changed, stop and report that there is no fixed spec scope rather than planning from adjacent code changes.

Choose a stable repository id from the repository basename plus a short hash of its canonical root, and a descriptive plan id. The only allowed artifact path is `/tmp/agent-plans/<repo-id>/plans/<plan-id>/PLAN.md`. If that file already exists, stop; never overwrite or amend an implementation plan. Do not read or write `.plan`.

Completion criterion: the canonical root, repository id, full base and head hashes, exact comparison, changed specs, and unused artifact path are fixed.

### 2. Establish desired and current behavior

Read the changed specs as they exist at the fixed head; they are authoritative for desired behavior within the diff's scope. Read applicable glossary and repository guidance, then inspect relevant code and tests at that same fixed head. Account for every changed requirement as one of:

- already satisfied, with concrete code/test evidence;
- a current-state gap, with evidence of what is absent or contradictory; or
- ambiguous/contradictory, with the conflicting sources quoted.

Already-satisfied behavior is evidence, not implementation work. If any ambiguity or contradiction prevents a safe technical sequence, stop before writing the artifact and report the exact decision needed. Do not infer desired behavior from code when it conflicts with the fixed specs.

Completion criterion: every changed requirement has an evidenced disposition, and only current-state gaps remain in implementation scope.

### 3. Design one sequential technical plan

Design ordered vertical steps that one agent can execute from the fixed head. Each step must deliver observable behavior through the applicable layers rather than a horizontal schema-, service-, or UI-only task unless that layer is itself the specified outcome. State dependencies explicitly and order each step after its prerequisites.

For a wide migration or mechanical refactor, use expand → migrate in bounded passing batches → contract. Preserve the old form until every migration step is complete, and place contraction after all migrations.

Give every ordered step at least one proposed execution trace: a nested pyramid/call tree with sequence numbers, `path:symbol` where known, and markers distinguishing existing, changed, new, and uncertain frames plus binding required order versus proposed internal structure. Existing frames need fixed-head evidence; new or changed frames name their proposed paths and symbols. Give distinct entry points or asynchronous roots separate traces; shared success and error branches may stay together. An async boundary terminates one stack and starts a linked stack; concurrent branches are marked unordered unless order is guaranteed. Observable or safety-critical ordering is binding, while internal proposed frames may vary with documented rationale. State inconsequential uncertainty explicitly; consequential architectural or observable-order uncertainty stops planning (see step 2). A trace is not an actual captured runtime stack trace or an exhaustive control-flow diagram. Non-runtime work may substitute an explicitly justified ordered operational flow.

After the ordered steps, define the plan's final review gates. Every non-empty plan requires these mandatory gates in order: repository-defined tests/lint/type/build; Test Quality via `test-quality-verifier`; Standards and Spec via `code-review`; Premortem; and Security. Concrete plan risks may add gates such as Visual, Performance, Migration, or Compatibility, each justified by the specific risk. Define only each gate's order, criteria, blocking behavior, and required evidence, and the candidate-preparation and remediation policy below. Reviews are mode-neutral: the executing agent may review in-process or delegate. Do not name reviewers, models, Herdr commands, worktrees, branches, or verification artifacts, and never record review results or mutable state in the plan.

The plan must contain this compact structure:

```markdown
# <Objective> — Implementation Plan

## Identity
- Plan path: <absolute path>
- Repository root: <canonical absolute path>
- Repository id: <stable id>
- Base commit: <full hash>
- Head commit: <full hash>
- Spec comparison: <full-base>..<full-head>
- Created: <timestamp>
- Immutability: never amend or overwrite this file

## Objective
<Desired behavioral outcome within the changed-spec scope.>

## Sources
| Source | Fixed point | Authority and relevance |
|---|---|---|

## Current-state gaps
| Requirement | Desired behavior | Current evidence | Disposition / gap |
|---|---|---|---|

## Ordered implementation steps
### Step N — <vertical behavior>
- Delivers: ...
- Depends on: <earlier steps or none>
- Acceptance criteria: ...
- Failure criteria: ...
- Public test seam: ...
- Why the seam survives refactoring: ...
- Likely files: ...
- Focused commands: ...
- Risks: ...
- Proposed execution trace(s): one indented call tree per distinct entry point or async root, e.g.
  - `1. <path:symbol>  [existing|changed|new|uncertain] [required-order|proposed]`
    - `2. <path:symbol>  [marker] [order]`
      - `3. <path:symbol>  [marker] [order]`  — async boundary → linked stack, or `[unordered]` concurrent branch
  - Note binding order, permitted internal variance, and any inconsequential uncertainty.

## Final review gates
Applies to every non-empty plan; the executing agent may review in-process or delegate.

### Candidate preparation
- Run repository gates, then hold one unchanged implementation candidate for every review.

### Mandatory gates
| Gate | Order | Criteria | Blocking | Evidence |
|---|---|---|---|---|
| Repository tests/lint/type/build | 1 | ... | yes | ... |
| Test Quality (`test-quality-verifier`) | ... | ... | yes | ... |
| Standards (`code-review`) | ... | ... | yes | ... |
| Spec (`code-review`) | ... | ... | yes | ... |
| Premortem | ... | ... | yes | ... |
| Security | ... | ... | yes | ... |

### Risk-triggered gates
| Gate | Triggering risk | Criteria | Blocking | Evidence |
|---|---|---|---|---|
| <Visual / Performance / Migration / Compatibility / other> | ... | ... | ... | ... |

### Remediation policy
- Reviewers report findings and do not edit during passes; consolidate findings before remediation.
- Allow at most two remediation batches. After any remediation rerun repository gates, rerun failed reviews and passing reviews the change invalidates, and record rationale for reviews not rerun.
- Stop with unresolved findings after the second batch.

## Global acceptance
1. ...

## Assumptions
- ... or `none`

## Exclusions
- ...
```

Include every required source, current-state disposition, remaining gap, dependency, acceptance and failure criterion, public test seam, likely file, focused command, risk, assumption, exclusion, and per-step proposed execution trace. If all requirements are already satisfied, write `none` under ordered implementation steps, omit the final review gates, and preserve the evidence explaining why no implementation remains.

The plan defines review gates but must not include RED/GREEN/REFACTOR instructions, `.plan`, execution state, review results, reviewer or model configuration, Herdr commands, worktrees, branches, slices, verification artifacts, or orchestration instructions. Those belong to execution, not the implementation plan.

Completion criterion: every remaining gap is covered by at least one ordered step, every ordered step has at least one evidence-grounded proposed execution trace, the mandatory final review gates plus any risk-triggered gates are defined for every non-empty plan, every step traces to changed-spec evidence, and one agent can execute the sequence without making an unstated design decision.

### 4. Write once and verify

Create only the plan directory and `PLAN.md`; never create auxiliary files. Write the complete candidate once, then reread it without changing it. Verify the path is under the fixed repository id, identity hashes match the pinned commits, every changed requirement is accounted for, every gap maps to ordered work and global acceptance, every ordered step carries at least one proposed execution trace, a non-empty plan defines the mandatory final review gates plus any risk-triggered gates, and every excluded execution concern — including review results, reviewer/model configuration, and mutable state — is absent. Compute and report the file's SHA-256 so downstream execution can pin the exact source.

If verification fails before the write, fix the in-memory candidate. If the written file does not verify, report the invalid immutable artifact and create a new plan id only with user approval; never repair it in place.

Completion criterion: exactly one immutable `PLAN.md` exists at the reported absolute path, its SHA-256 is reported, and no execution ledger or `.plan` state was created.

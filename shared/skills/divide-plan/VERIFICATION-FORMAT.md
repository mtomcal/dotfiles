# Execution Verification Format

Directly apply these operational formats when the coordinator records independent test-quality attempts, final review passes, mechanical evidence gates, or remediation batches under `verifications/`.

## Per-slice test-quality artifact

Name the file `<slice-number>-test-quality.md`.

```markdown
# Slice NNN — Test-Quality Verification

## Scope
- Slice packet: <absolute path>
- Branch: <slice branch>
- Initial implementation fixed point: <full hash>
- Authorized audit mode: read-only

## Verifier
- Composed skill: test-quality-verifier
- Exact model id: <oversight model>
- Thinking level: <oversight thinking>
- Independence: separate from implementation

## Attempt 1 — <timestamp>
- Fixed point: <full hash>
- Verdict: PASS | NEEDS-CORRECTION | BLOCKED
- Files and tests scanned: ...
- Commands/results: ...
- Coverage evidence or limitation: ...
- Findings: ...
- Missing evidence: ...

## Attempt N — <timestamp>
- Fixed point: <new full hash>
- Correction number: <1 or 2>
- Verdict: ...
- Files and tests scanned: ...
- Commands/results: ...
- Coverage evidence or limitation: ...
- Findings: ...
- Missing evidence: ...
```

Append every attempt; never overwrite a failed or blocked attempt. `PASS` requires the composed verifier's complete structured report at that fixed point.

## Coordinator mechanical evidence artifact

Name the file `<slice-number>-evidence-gates.md` and append a section for each fixed point tested.

```markdown
## Fixed point <full hash> — <timestamp>
- Packet commands: <exact commands and results>
- Applicable repository gates: <exact commands and results>
- Returned evidence reconciled: yes | no — <reason>
- Verdict: PASS | NEEDS-CORRECTION | BLOCKED
```

A changed fixed point invalidates the prior mechanical pass and requires a new appended section.

## Final pass artifact

Use `final-test-quality.md`, `final-standards.md`, `final-spec.md`, `final-premortem.md`, `final-security.md`, and one `final-<risk-triggered-or-approved-exception>.md` per risk-triggered or approved exceptional gate. `final-test-quality.md` records the integrated Test Quality pass and is separate from the per-slice `<slice-number>-test-quality.md` artifacts.

```markdown
# Final <Axis> Verification

## Authority and criteria
- Source implementation plan: <path>
- Source SHA-256: <digest>
- Axis owner / composed skill: <code-review for Standards or Spec; named criteria owner otherwise>
- Criteria: ...

## Attempt N — <timestamp>
- Integrated fixed point: <full hash>
- Exact model id: <oversight model>
- Thinking level: <oversight thinking>
- Independence: <separate axis context and checkout authority>
- Verdict: PASS | NEEDS-REMEDIATION | BLOCKED
- Evidence and commands: ...
- Findings with location, impact, and remedy: ...
- Limitations: ...
```

Standards and Spec remain separate axes even when one composed `code-review` invocation coordinates them. The mandatory integrated passes are Test Quality, Standards, Spec, Premortem, and Security; each risk-triggered or approved exceptional gate records its own artifact. Every mandatory pass records every reviewed integrated fixed point; no pass can waive another.

## Final findings and remediation artifact

Use `final-findings.md`.

```markdown
## Fixed point <full hash> — aggregated findings
| Finding id | Source axis/gate | Evidence | Impact | Deduplicated remedy | Status |
|---|---|---|---|---|---|

## Remediation batch N — <timestamp>
- Starting fixed point: <full hash>
- Oversight model/thinking: <exact configuration>
- Isolated branch/worktree: <values>
- Authorized findings: <ids>
- Returned commit: <full hash>
- Integrated fixed point: <full hash>
- Evidence: ...
- Repository gates rerun: <result>
- Reviews rerun: <failed reviews plus passing reviews the impact invalidated>
- Reviews not rerun: <review — rationale it was unaffected>
```

Append each fixed-point finding set and remediation batch. Do not erase resolved findings. After any remediation always rerun repository gates, rerun failed and invalidated passing reviews, and record why any not-rerun review was unaffected. A maximum of two remediation batches is allowed.

## Verdict invariants

- Reviewers return findings and evidence; only the coordinator records state and acceptance.
- Every verdict names one full fixed-point hash.
- Missing required evidence is not a pass.
- A correction or remediation commit creates a new fixed point and invalidates prior passing evidence where the scope changed.
- Attempts and history are append-only; summary/index state in ledger `PLAN.md` may be updated.

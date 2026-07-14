---
id: SK-019
target: handoff
status: ready-to-integrate
revision: 1
blocked-by: [SK-001]
source-verdict: retain substance
baseline: e8136ac629ff546d4364ea1d522ae9d5a5ce617d
---

# Handoff: retain the compact redacted continuation artifact

## Why this item is next

SK-001 is verified and SK-019 is claimed at the stated baseline. WF-007 places this coherent compact skill in direct normalization with no unresolved owner or correctness dependency.

## Evidence

- WF-005 gives `handoff` a retain verdict and a complete behavior ledger: an outside-repository temporary artifact, seven ordered production steps, enumerated redaction, references instead of duplicated artifacts, the specified content sections, saved-file self-check, fresh-agent next action, and absolute path as the final response line.
- WF-008 requires the exact Language Definitions content `No skill-specific terms.`
- WF-007 preserves the compact producer and final absolute-path contract without adding branches or padding.
- `specs/ai-agent-config.md` requires redacted timestamped Markdown under the OS temporary handoff directory, an absolute-path report, canonical body structure, and behavior preservation.
- The current 33-line `shared/skills/handoff/SKILL.md` is self-contained, has no links or support files, and needs only canonical heading normalization and compaction.
- `THIRD_PARTY_NOTICES.md` identifies `handoff` as a locally maintained adaptation of `mattpocock/skills` revision `66898f60e8c744e269f8ce06c2b2b99ce7660d5f` and reproduces Matt Pocock's MIT license.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-019-handoff.md` — this item-local proposal and worker verification record.
- `shared/skills/handoff/SKILL.md` — the sole production target.

## Proposed changes

### Add

- Add `Language Definitions` containing exactly `No skill-specific terms.`
- Add the canonical `Workflow` heading.

### Change or move

- Rename the noncanonical `Process` section to `Workflow` and keep exactly seven ordered steps.
- Fold the opening outside-repository rule into the temporary-directory step.
- Keep the eight artifact sections in the write step, compacted onto one line without changing their names or order.
- Keep the saved-file self-check, completion criterion, and absolute-path final-line contract inline.

### Remove

- Remove only the redundant standalone opening sentence and list formatting made unnecessary by the compact Workflow.
- Remove no trigger, step, redaction class, artifact section, guardrail, output contract, or completion condition.

## Proposed skill shape

1. `Language Definitions` — present; exact statement `No skill-specific terms.`
2. `Workflow` — present; one compact seven-step producer path plus its completion and final-line contracts.
3. `Activities` — omitted; no independently selected action exists.
4. `Reference` — omitted; the workflow is self-contained and has no support file.

## Behavior-preservation checklist

- [x] Frontmatter and pause/switch/compaction/explicit-request triggers remain byte-identical.
- [x] The artifact remains compact Markdown outside the repository under `${TMPDIR:-/tmp}/agent-handoffs/`.
- [x] The workflow retains exactly seven ordered steps: directory, slug/timestamp, state review, redaction, artifact references, write, and reread self-check.
- [x] Credentials, tokens, private keys, personal data, sensitive URLs, and unnecessary machine-specific details remain redacted with descriptive placeholders.
- [x] Specs, plans, issues, commits, diffs, logs, screenshots, and generated artifacts remain referenced rather than duplicated.
- [x] The write step retains exactly these sections in order: objective and requested next-session focus; constraints and decisions; completed work; current repository/Git state; verification already run; remaining steps and blockers; relevant artifact references; suggested skills and why they apply.
- [x] The saved file is reread once for self-containment, redaction, and useful references.
- [x] Completion still requires a file in the temporary handoff directory, no known secrets, and a next concrete action discoverable without the original conversation.
- [x] The absolute path remains the final response line.
- [x] Existing Matt Pocock provenance and MIT license coverage remain unchanged and accurate.
- [x] The resulting target is at most 30 lines; if it exceeds 30 lines, stop without committing.

## Dependencies, provenance, and risks

- SK-001 is verified; no concurrent owner decision affects this self-contained artifact workflow.
- No contradiction, support file, link, script, executable command correction, relocation, or ownership transfer exists.
- MIT provenance is complete in `THIRD_PARTY_NOTICES.md`; that notice is not changed.
- The only material risk is accidental loss through compaction. Exact step count, section names/order, redaction classes, self-check, completion criterion, final-line rule, and line count are explicit acceptance checks.

## Verification

- Reread the complete target and map every checked behavior above to resulting text.
- `test "$(grep -cE '^[0-9]+\\.' shared/skills/handoff/SKILL.md)" -eq 7` — exactly seven Workflow steps.
- `test "$(wc -l < shared/skills/handoff/SKILL.md)" -le 30` — compact target; stop before commit on failure.
- Parse level-two headings — exactly `Language Definitions` then `Workflow`.
- Compare frontmatter to baseline — byte-identical.
- Check the exact no-terms sentence, all sensitive classes, all artifact section names in order, self-check, completion criterion, and absolute-path final-line rule.
- Run the complete YAML-aware `audit-shared-skills` workflow — all 33 skills accounted for with zero errors and zero warnings.
- `test -L pi/skills/handoff && test "$(readlink pi/skills/handoff)" = '../../shared/skills/handoff' && test -e pi/skills/handoff/SKILL.md` — unchanged visibility resolves.
- Inspect target history and `THIRD_PARTY_NOTICES.md` — source revision and full MIT coverage remain present with no notice diff.
- `git diff --check -- .skill-migration/shared-skill-yagni/proposals/SK-019-handoff.md shared/skills/handoff/SKILL.md` — no whitespace errors.
- `bash tests/run.sh` — repository tests pass.
- Baseline-aware status/diff inspection — exactly this proposal and target differ; no ledger, settings, specs, notices, symlinks, tests, support files, or unrelated skills change.

Acceptance requires exact two-file scope, unchanged frontmatter, canonical two-section body, exact no-terms statement, exactly seven preserved steps, exact artifact sections and redaction contracts, saved-file self-check, absolute-path final line, at most 30 target lines, clean audit and tests, and preserved MIT provenance.

## Implementation and verification record

Worker verification completed at `2026-07-14T17:39:49+00:00`.

- Proposal revision 1 reached `proposal-ready` before the target edit; no scope or authority revision was needed.
- The target is 27 lines with exactly `Language Definitions` then `Workflow`, the exact no-terms sentence, seven ordered steps, eight ordered artifact sections, the redaction contract, saved-file self-check, completion criterion, and absolute-path final line. Frontmatter is byte-identical to baseline.
- The complete YAML-aware union audit parsed and accounted for all 33 skills with 0 errors and 0 warnings; the target's read/write/bash grants remain used.
- `bash tests/run.sh` passed both shell files and all 12 tests. Pi visibility, Markdown/link/support checks, scoped `git diff --check`, and Matt Pocock revision/full MIT provenance checks passed.
- Baseline-aware scope inspection found exactly this proposal and target. The target diff is 8 insertions and 14 deletions; SHA-256 is `c03177653e3ad6f9d6f66073aed253b220031f8336ef90e6657ad125f5ac8af9`.
- Two initial ad hoc assertions were corrected: section ordering first searched the whole file and collided with `completed work` in the review step, and exact scope first assumed locale-independent sort order. Step-6-scoped and set-membership checks passed; both were verification-harness errors, not target failures.
- Residual risk: none identified. The worker result is `ready-to-integrate` and does not claim coordinator integration or another item.

## Explicit exclusions

- No edit to the migration ledger, settings, specs/glossaries, notices, AGENTS, tests, deployment, visibility symlinks, support files, other skills, or other proposals.
- No frontmatter redesign, new terminology, Activity, Reference, helper, template, route, approval gate, owner transfer, or fixed schema beyond the retained artifact sections.
- No per-item approval wait and no claim of coordinator integration or catalog-wide verification.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `1`
- Authorization effect: the standing no-approval directive authorizes only the exact proposal and target paths and changes enumerated above.
- Scope check: `PASS — MAP, WF-007, WF-005, WF-008, specs, verified write-a-skill, complete target, provenance notice/history, exact file scope, behavior preservation, contradiction review, and verification were checked in authority order. Production editing may continue without a per-item approval wait.`

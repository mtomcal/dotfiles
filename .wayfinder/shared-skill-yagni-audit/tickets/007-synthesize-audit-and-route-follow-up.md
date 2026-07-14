---
id: WF-007
type: task
status: resolved
blocked-by: [WF-006]
---

# Synthesize the audit and route follow-up

## Question
What final recommendation set and dependency order make the confirmed skill-body contract ready for durable specification and implementation planning?

## Why it matters
The destination requires one coherent route, not disconnected per-skill observations or opportunistic rewrites.

## Completion evidence
All 33 skills have exactly one current recommendation with evidence; cross-skill changes have explicit ownership and dependencies; accepted terminology and body-structure rules are identified for `ubiquitous-language` and `update-specs`; implementation candidates are grouped for `create-plan`; out-of-scope frontmatter concerns remain separate; and no production skill behavior has been changed during Wayfinder.

## Resolution
The 33 family-audit records in WF-003, WF-004, and WF-005 are the behavior-preservation ledger. WF-008 supplies the accepted skill-local language, and WF-006 supplies catalog ownership and migration constraints. Together they support one current primary recommendation per skill: **11 retain, 16 simplify inline, 4 move detail to Reference, 2 consolidate/delegate, 0 split, and 0 retire**. The separately justified Git-delivery skill is a new catalog candidate, not a changed verdict for one of the 33.

A verdict of **retain** preserves substance, not the current headings: every implementation still adds the confirmed `Language Definitions` section (using “No skill-specific terms” for `handoff`) and may reorder routing without changing behavior. No recommendation authorizes deleting a trigger, branch, gate, failure state, guardrail, output contract, ownership rule, completion condition, provenance, or required repository behavior unless its ledger names the replacement owner.

### Dependency keys and implementation sequence

All production-skill work waits on **D1** and uses **D2**:

1. **D1 — durable decisions:** route all WF-008 terminology and authority boundaries through `ubiquitous-language`; route the four-section/YAGNI contract, ownership matrix, artifact qualifications, composition boundaries, provenance duties, and required behavior corrections through `update-specs`. Repository glossaries remain authoritative where terms overlap.
2. **D2 — authoring owner:** update `write-a-skill` from the durable contract before using it to restructure other skills.
3. **D3 — correctness before movement:** repair evidenced command, behavior, runner, location, and provenance contradictions before relocating or deleting their prose. A body move never silently chooses between conflicting rules.
4. **D4 — direct normalization:** apply retain/simplify recommendations whose behavior is already coherent, rechecking each affected ledger.
5. **D5 — progressive disclosure and composition:** create or revise owner-local References and replace copied behavior with explicit composition pointers only after the owner contract is correct and independently executable.
6. **D6 — generic Git delivery:** plan a new independently invocable owner for PR creation/update, CI-to-green, stale-branch refresh, and pushed-head verification; it composes `resolving-merge-conflicts` and `code-review`. Remove that material from tmux orchestration only after the new owner exists.
7. **D7 — catalog verification:** validate all 33 ledgers, links, supporting scripts, command help, provenance/licenses, in-process fallbacks, frontmatter under the existing repository contract, and Pi visibility. Run `audit-shared-skills` after implementation.

### Final recommendation set

`D1` and `D2` are global dependencies unless a row says it is the D2 owner. The final column records additional ordering constraints; these are implementation dependencies, not new Wayfinder uncertainty.

| Skill | Primary recommendation | Planning-ready action | Additional dependency |
|---|---|---|---|
| `write-a-skill` | simplify inline | Become the four-section, progressive-disclosure, split-test, and YAGNI owner. | D1; implement as D2 before other bodies. |
| `bootstrap-specs` | simplify inline | Keep one routed interview/generation workflow; remove repeated summaries; conditionally link or retire orphaned examples. | D3: resolve pre/post-generation approval, qualify brownfield extraction plan, and protect glossary/rerun ownership. |
| `gameplay-asset-imagegen` | simplify inline | Colocate transformation checks and keep the chroma-key recipe as an Activity. | D3: supply or redefine the missing `imagegen` delegation before changing the main path. |
| `herdr` | simplify inline | Replace the repeated manual with current-context Activities and conditional upstream/protocol references. | D3: caller/focus and opaque/legacy ID semantics, destructive ownership, live command checks, AGPL provenance. |
| `playwright` | move detail to Reference | Keep routing, one minimal browser Activity, recovery, cleanup, and security inline; move specialized command families to tested topic references. | D3: correct stale commands and record Apache-2.0 provenance; command/grant portability remains in the separate frontmatter lane. |
| `ralph` | simplify inline | Make one bounded, failure-aware job workflow with executable runner setup and exact completion evidence. | D3: align the 25-iteration default, exact sentinel, failure stop, commit evidence, sandbox approval, and orchestrator claim. |
| `create-explainer` | simplify inline | Keep one routed producer/reviewer/serve/validate workflow and deduplicate conditional references. | D3: reconcile source/screenshot locations, tier requirements, and serve/validate order before moving text. |
| `test-quality-verifier` | retain | Preserve the compact audit contract while making delegated/solo and audit-only/improve routing explicit. | D3: resolve edit authorization and remove non-portable role assumptions without expanding into a testing handbook. |
| `ubiquitous-language` | simplify inline | Route create/update and canonical glossary location first; keep one output schema. | D1 owner for accepted terms; D3: follow repository authority instead of forcing a root file. |
| `update-specs` | retain | Preserve the gated discrepancy/review workflow and one authoritative discrepancy definition set. | D1 owner for durable behavior; D3: use a real ref/range contract, route terminology to its owner, and state editor isolation/writer authority. |
| `prototype` | simplify inline | Preserve the compact logic/UI router and align both branch references on throwaway-by-default behavior. | D3: code is absorbed only deliberately through normal production implementation and verification. |
| `audit-shared-skills` | simplify inline | Keep the complete union-schema audit inline and remove the unused Info severity. | D4 after D2; continue to own frontmatter validation, not semantic/YAGNI review. |
| `codebase-design` | retain | Preserve vocabulary, design tests, and both conditional references; move route selection to the Workflow opening. | D4; repository glossary wins on overlap. |
| `code-review` | retain | Preserve independent Standards/Spec axes, fixed-point scope, and separate outputs. | D4; generic review owner used later by D6. |
| `create-plan` | simplify inline | Deduplicate ownership/isolation/review guardrails at their governing transitions while retaining all state and recovery rules. | D4; plan-specific lifecycle remains distinct from other plan artifacts. |
| `diagnosing-bugs` | retain | Preserve the six evidence gates and TDD handoff as one ordered workflow. | D4; no architecture work may replace the requested fix. |
| `design-md` | simplify inline | Route create/update/audit/validate first and keep the compact artifact schema and gates inline. | D4. |
| `grill-me` | retain | Preserve evidence-first, one-question-at-a-time grilling and confirmed downstream routing. | D3 provenance notice, then D4 body normalization. |
| `handoff` | retain | Preserve the compact redacted artifact producer and final absolute-path contract. | D4; Language Definitions says “No skill-specific terms.” |
| `image-comparison-judge` | simplify inline | Put role/delegation routing first and retain strict scoped PASS/FAIL beside the judging step. | D4; consume neutral diff from `image-diff-describer` without claiming human acceptance. |
| `image-diff-describer` | retain | Preserve the no-verdict neutral diff contract and colocate its output schema with production. | D4; owns `neutral diff artifact`. |
| `improve-codebase-architecture` | simplify inline | Remove repeated design-skill loading while retaining the temporary HTML decision surface and selection gate. | D4 after `codebase-design` ownership is durable. |
| `research` | retain | Preserve source authority, freshness, citation, conflict, and durable artifact gates. | D4. |
| `resolving-merge-conflicts` | retain | Preserve dual-intent tracing, verification, selective staging, and continuation authorization. | D4; specialist conflict owner composed by D6. |
| `tdd` | simplify inline | Route normal versus discovered-bug mode first, colocate guardrails, and retire only duplicate reference content. | D4 after seam ownership is aligned with `codebase-design`; test-quality audit remains separately routed. |
| `video-to-contact-sheet` | simplify inline | Keep selection in Workflow, four reusable ffmpeg recipes in Activities, and add a compact path/purpose handoff. | D4; preserve source evidence and return limitations to `visual-qa`. |
| `visual-qa` | simplify inline | Route orchestrated versus ad hoc first, then select available evidence tooling and preserve mismatch reporting. | D4 after capture/conversion/verdict ownership pointers are durable. |
| `wayfinder` | retain | Rename the core model to Language Definitions and preserve the complete state lifecycle and format reference. | D4; repository glossary wins on overlap. |
| `teach` | move detail to Reference | Keep approvals, teaching-workspace state, lesson requirements, and evidence gates inline; move detailed pedagogy to a mandatory source-backed reference. | D5 after primary-source pedagogy research and `create-explainer` composition boundaries are correct. |
| `create-agents-md` | move detail to Reference | Keep one routed generation/update workflow and move the deep grill briefing behind a conditional pointer. | D5; preserve hill-climbing meaning, tree-hash limits, human content, and detection script. |
| `curator` | move detail to Reference | Keep the intake/scan/rank/approval/apply path inline; extract detailed scan, ranking, triage, template, and stuck-point material. | D5 after reference load conditions preserve privacy, runtime, and final-approval gates. |
| `em-train` | consolidate/delegate | Retain the training lifecycle and training-only reference material; compose `create-explainer` rather than copying or weakening it. | D5 after corrected `create-explainer`; preserve real CI, no spoilers, review-round cap, cleanup, and merge choice. |
| `tmux-agent-orchestration` | consolidate/delegate | Retain tmux launch, verified steering, monitoring, and scoped cleanup; remove generic delivery only when delegated. | D5 for tmux-specific references, then D6 before deleting PR/CI/stale-branch behavior. |

### Durable routes

- **`ubiquitous-language`:** persist the complete human-confirmed WF-008 term set, the explicit no-terms case, and ownership boundaries for project glossary terms, architecture vocabulary, Herdr entities, and neutral diff evidence. Reconcile overlapping wording rather than creating a second authority.
- **`update-specs`:** record the canonical section order/optionality, semantic YAGNI test, colocated guardrails/output/completion rule, one-workflow limit, activity distinction, conditional Reference contract, behavior-ledger preservation gate, composition/transport/isolation boundaries, plan-artifact qualifications, provenance obligations, and migration ordering. Record body-affecting correctness decisions where they are durable behavior.
- **`create-plan`:** create dependency-ordered vertical slices matching D2–D7. Every slice must name affected ledgers, supporting references/scripts, source and license checks, focused verification, and rollback/recovery. Keep contradiction repair before relocation and retain the 33-skill catalog pass as final acceptance.

### Separate frontmatter lane

Cross-agent frontmatter redesign, harness-specific explicit-invocation metadata, `allowed-tools` portability, and grant-schema changes remain outside this body audit. Preserve the current union schema. Existing command/grant mismatches may be reported by `audit-shared-skills`, but any schema or grant redesign needs a separate destination and plan; it neither expands nor invalidates the 33 body recommendations.

### Closure evidence

Every one of the 33 skills appears exactly once above with its WF-003/004/005 verdict, accepted WF-008 terminology, and WF-006 ownership/dependency constraints. The sequence has one authoring owner, correctness-before-movement gates, explicit composition dependencies, a separately scoped new Git-delivery candidate, and catalog-wide verification. No production skill, specification, installer, provenance file, deployment link, or Pi visibility file was changed during Wayfinder; the unrelated `pi/settings.json` modification remains untouched. No new in-scope uncertainty surfaced.

---
id: MG-001
target: Durable terminology and shared-skill body contract
status: verified
revision: 2
blocked-by: []
source-verdict: Route accepted Wayfinder decisions into durable specifications before production-skill rewrites
---

# Durable terminology and shared-skill body contract

## Why this item is next
WF-007 requires durable language and behavior contracts before `write-a-skill` becomes the implementation owner. The completed Wayfinder map has no remaining fog, but its decision trail is not itself the repository's normative specification.

This proposal authorizes specification edits only. It does not authorize editing any shared skill.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md`
- WF-001: canonical four-section/YAGNI contract
- WF-002: behavior-preservation ledger and disclosure rules
- WF-006: ownership matrix, composition boundaries, contradictions, and migration order
- WF-007: final recommendation set and durable routes
- WF-008: human-confirmed skill-local definitions and ownership boundaries
- `specs/SPEC-OF-SPECS.md`: glossary authority and spec versioning rules
- `specs/UBIQUITOUS_LANGUAGE.md` version 0.6.0
- `specs/ai-agent-config.md` version 2.2.0

## Exact files in scope

- `specs/UBIQUITOUS_LANGUAGE.md` — add shared cross-skill vocabulary and clarify ownership/collisions exposed by the audit.
- `specs/ai-agent-config.md` — make the accepted shared-skill body, YAGNI, preservation, composition, and artifact-qualification decisions normative; add tests and changelog entries.
- `specs/README.md` — update only the AI Agent Config version in the Quick Reference so the suite index does not retain the superseded `2.2.0` version.

No other file is authorized by this proposal.

## Proposed changes

### `specs/UBIQUITOUS_LANGUAGE.md`

1. Bump the version from `0.6.0` to `0.7.0`, retain the 2026-07-14 date, and add a changelog section if needed to record the new vocabulary contract.
2. Add cross-skill body terms under the Agent Domain or Agent Workflow Domain:
   - **skill body** — invoked Markdown instructions after frontmatter.
   - **Language Definitions section** — mandatory skill-local operational vocabulary, or an explicit no-terms statement.
   - **Workflow section** — at most one primary end-to-end process whose routing occurs first.
   - **Activity** — independently reusable command, action, or recipe rather than a renamed Workflow step.
   - **Reference section** — conditional pointers explaining when and why supporting Markdown must be loaded.
   - **progressive disclosure** — catalog description, invoked skill body, then conditionally loaded support.
   - **behavior-preservation ledger** — audit record mapping behavior to its retained location or replacement owner.
3. Add qualified workflow artifacts where collision with the existing **plan workspace** is consequential:
   - **spec-extraction plan** — brownfield Bootstrap Specs artifact, not a plan workspace or slice graph.
   - **Ralph job plan** — mutable `IMPLEMENTATION_PLAN.md` used by a Ralph job, not a plan workspace.
   - **teaching workspace** — dedicated learner state, distinct from plan and Herdr workspaces.
4. Add Herdr context/identity terms that belong to the repository's Herdr domain rather than only the skill:
   - **caller pane** and **focused pane** as distinct concepts.
   - **public Herdr ID** as opaque refreshable runtime identity.
   - **legacy display selector** as unstable numeric position that must not be guessed or persisted.
5. Add **neutral diff artifact** to the Agent Workflow Domain, owned by `image-diff-describer` and explicitly distinct from acceptance judgment.
6. Extend relationships and flagged ambiguities to state:
   - skill-local definitions remain in the owning skill; the project glossary owns terms shared by specs or multiple workflows.
   - plan workspace, spec-extraction plan, Ralph job plan, teaching workspace, and Herdr workspace are qualified and non-interchangeable.
   - caller pane is not inferred from UI focus.
   - neutral description does not imply visual acceptance.
7. Do **not** copy all WF-008 definitions into the project glossary. Terms used only by one skill remain authoritative in that skill's future `Language Definitions`; WF-008 is their approved migration source until that skill is implemented.

### `specs/README.md`

1. Change only the AI Agent Config Quick Reference version from `2.2.0` to `2.3.0`. The reading order, dependency graph, and implementation checklist remain unchanged.

### `specs/ai-agent-config.md`

1. Bump the version from `2.2.0` to `2.3.0` and add a dated changelog entry.
2. Expand `Shared Skill Contract` with a normative body contract:
   - canonical order is `Language Definitions`, optional `Workflow`, optional `Activities`, optional `Reference`.
   - `Language Definitions` is mandatory and contains only execution-relevant skill-local terms or “No skill-specific terms.”
   - `Workflow` contains at most one primary end-to-end process and begins with routing/mode selection.
   - `Activities` contains independently reusable operations and does not restate Workflow steps.
   - `Reference` contains conditional Markdown pointers with explicit load conditions.
   - required main-path behavior cannot be hidden behind optional wording.
3. Add the semantic YAGNI retention rule: retain content only when it changes invocation/routing, correctness, reusable activity execution, guardrails/failures, output/artifact contracts, or required repository behavior. Explicitly reject fixed line limits as the standard.
4. Require guardrails, failures, approvals, output contracts, and completion criteria beside the Workflow step or Activity they govern. Permit literal/detail-heavy schemas and templates in Reference while retaining compact main-path contracts inline.
5. Require a behavior-preservation ledger before material restructuring. Every trigger, branch, gate, failure, guardrail, output, ownership rule, and completion condition must remain or name a replacement owner.
6. Add catalog ownership/composition rules from WF-006 at durable resolution:
   - `write-a-skill` owns body authoring, progressive disclosure, split tests, and YAGNI pruning.
   - `audit-shared-skills` owns executable union-frontmatter validation, not semantic/YAGNI review.
   - transport skills own terminal mechanics; callers retain briefs, state, acceptance, and fallback.
   - checkout isolation is chosen before transport; editable delegates require isolation.
   - composition imports process, not caller ownership.
   - generic Standards/Spec review remains with `code-review`; specialist verdicts retain narrow authority.
   - visual work follows capture → optional recording conversion → optional neutral diff → general QA or scoped judgment → caller/human acceptance.
   - templates, output contracts, ranking models, and checklists remain with their domain producer rather than a universal schema.
7. Qualify state artifacts explicitly:
   - Wayfinder decision tickets, plan-workspace slices, spec-extraction plans, Ralph job plans, teaching state, and generated artifacts are not interchangeable.
   - reciprocal routing may compose workflows without transferring state ownership.
8. Preserve provenance/licensing as a central `THIRD_PARTY_NOTICES.md` obligation and require source/revision/license identification before imported material is moved or rewritten. Actual notice repairs remain MG-002.
9. Add test scenarios covering:
   - canonical shared-skill body structure and conditional Reference loading.
   - behavior-preservation and ownership boundaries during restructuring.
   - qualification of plan-like artifacts and transport-versus-isolation behavior.
10. Leave existing frontmatter requirements unchanged. Do not add harness-specific explicit-invocation metadata or redesign `allowed-tools`.

## Proposed skill shape
Not a skill body change.

## Behavior-preservation checklist

- [x] Existing project glossary definitions remain unchanged unless a collision requires an additive clarification.
- [x] Repository glossary remains authoritative for overlapping project-domain terms.
- [x] WF-008 skill-local definitions are not flattened into a global glossary.
- [x] Existing union-frontmatter requirements remain unchanged.
- [x] The spec-suite Quick Reference agrees with the new AI Agent Config version; no other README content changes.
- [x] Required provenance and licensing duties remain repository-level.
- [x] Existing Wayfinder, plan workspace, and teaching workspace contracts remain intact while artifact boundaries become explicit.
- [x] No shared skill or support file changes.
- [x] No deployment, discovery, or Pi visibility changes.
- [x] `pi/settings.json` remains untouched.

## Dependencies, provenance, and risks

- Revision 1 omitted `specs/README.md`, whose Quick Reference records the AI Agent Config version. Changing the spec to `2.3.0` without updating that row would create immediate cross-spec drift; revision 2 adds only that mechanical version update.
- This proposal must precede `SK-001 write-a-skill`.
- MG-002 will separately propose exact `THIRD_PARTY_NOTICES.md` repairs; this proposal only preserves the obligation.
- Risk: overloading the project glossary with skill-private vocabulary. Mitigation: add only terms shared across specs/workflows and leave one-skill terms in their owning skill.
- Risk: making optional sections appear mandatory. Mitigation: only `Language Definitions` is mandatory; the other three sections remain semantic and optional.
- Risk: turning the ownership matrix into brittle copied implementation detail. Mitigation: specify durable boundaries and owners, while exact per-skill moves remain in approved skill proposals.
- Risk: frontmatter scope creep. Mitigation: explicitly preserve the current union schema and separate portability concerns.

## Verification

- Reread both complete edited specs and compare every new normative clause with WF-001, WF-006, WF-007, and WF-008.
- Verify both spec version headers and changelog entries agree.
- Verify every new glossary term is used by multiple specs/workflows or resolves a documented collision.
- Verify every new test scenario has a unique `TS-AIAGT-*` identifier and language-agnostic expected output.
- Run `rg -n 'Language Definitions|Workflow section|Activity|Reference section|behavior-preservation ledger|spec-extraction plan|Ralph job plan|caller pane|neutral diff artifact' specs/UBIQUITOUS_LANGUAGE.md specs/ai-agent-config.md` and inspect each match in context.
- Verify `specs/README.md` lists AI Agent Config version `2.3.0` and has no other changes.
- Run `git diff --check -- specs/UBIQUITOUS_LANGUAGE.md specs/ai-agent-config.md specs/README.md`.
- Run `git diff -- specs/UBIQUITOUS_LANGUAGE.md specs/ai-agent-config.md specs/README.md` and confirm no undisclosed file is included.
- Run `git status --short` and confirm `pi/settings.json` remains the only unrelated pre-existing tracked modification.

## Explicit exclusions

- No shared skill or supporting reference edits.
- No provenance-notice edits yet; those belong to MG-002.
- No frontmatter, `allowed-tools`, deployment, discovery, installer, or Pi visibility changes.
- No generic Git-delivery skill creation.
- No implementation of any of the 33 audit recommendations.

## Decision

Revision 1 recorded decision: `APPROVE MG-001`

Revision 1 decision timestamp: `2026-07-14T15:16:08+00:00`

Revision 1 authorization was invalidated before any production edit when complete spec-suite review exposed the omitted `specs/README.md` version index.

Revision 2 requested timestamp: `2026-07-14T15:17:52+00:00`

Revision 2 recorded decision: `APPROVE MG-001`

Revision 2 decision timestamp: `2026-07-14T15:19:31+00:00`

Approved proposal revision: `2`.

Reply with exactly one:

- `APPROVE MG-001`
- `DECLINE MG-001: <reason>`
- `REVISE MG-001: <instruction>`

No production file is authorized until that decision is recorded.

## Implementation record

Verified timestamp: `2026-07-14T15:22:40+00:00`

Actual production diff:

- `specs/UBIQUITOUS_LANGUAGE.md` — version `0.7.0`; added the approved shared-skill body vocabulary, artifact qualifications, Herdr distinctions, neutral-diff ownership, relationships, ambiguities, and changelog.
- `specs/ai-agent-config.md` — version `2.3.0`; added the approved body/YAGNI/preservation/ownership/composition/provenance contracts, three unique test scenarios, and changelog.
- `specs/README.md` — changed only the AI Agent Config Quick Reference version from `2.2.0` to `2.3.0`.

Verification results:

- Complete reread and contract comparison against WF-001, WF-006, WF-007, and WF-008: PASS.
- Approved terminology search with contextual inspection: PASS.
- Version, changelog, and nine unique `TS-AIAGT-*` identifier checks: PASS.
- Relative Markdown link check across all approved files: PASS.
- `git diff --check` across all approved files: PASS.
- Actual diff matches revision 2's exact three-file production scope: PASS.
- Shared skills, support files, provenance notices, deployment, discovery, and Pi visibility remain unchanged: PASS.
- The unrelated pre-existing `pi/settings.json` modification remains untouched: PASS.

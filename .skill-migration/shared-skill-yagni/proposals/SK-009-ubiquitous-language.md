---
id: SK-009
target: ubiquitous-language
status: ready-to-integrate
revision: 2
blocked-by: [SK-001, MG-001]
source-verdict: simplify inline
baseline: 0f5faddbea96056375c6d1374a33c7b9d07902f7
---

# Ubiquitous Language: route canonical glossary ownership before extraction

## Why this item is next

MG-001 and SK-001 are verified, so SK-009 is unblocked and was claimed from baseline `0f5faddbea96056375c6d1374a33c7b9d07902f7`. WF-007 places this skill in the correctness-before-movement tranche: its root-file promise must first be repaired to follow repository glossary authority, after which its create/update paths and duplicate dialogue guidance can be normalized into one compact artifact workflow. Its only production target is disjoint from the concurrently claimed SK-008 scope.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md` and WF-007 — final verdict `simplify inline`; route create versus update and canonical glossary location first, keep one output schema, and follow repository authority rather than force a root file.
- WF-005 `ubiquitous-language` record — complete behavior ledger covering create/update routing, evidence scan, ambiguity/synonym/overload detection, opinionated canonical proposals, grouped term tables, relationships/cardinality, a 3–5-exchange dialogue, explicit ambiguities, summary, and rerun merging. It identifies the duplicate dialogue example and unconditional root output as the only YAGNI/correctness findings.
- WF-008 — human-confirmed definitions for ubiquitous language, bounded context, canonical term, alias to avoid, and flagged ambiguity.
- WF-006 — the applicable project glossary owns project language; `ubiquitous-language` owns ongoing terminology workflow, must preserve authority location/conflict handling, and must not overwrite a repository convention with a root duplicate.
- `specs/UBIQUITOUS_LANGUAGE.md` version `0.7.0`, `specs/SPEC-OF-SPECS.md` version `1.1.0`, `specs/README.md` version `0.5.0`, and `specs/ai-agent-config.md` version `2.3.0` — this repository's live glossary is the preamble file `specs/UBIQUITOUS_LANGUAGE.md`; project-domain terms remain there, while skill-local terms live in the skill body; canonical body order, semantic YAGNI, behavior preservation, and workflow ownership are normative.
- Verified `shared/skills/write-a-skill/SKILL.md` — requires exact behavior-preservation mapping, only earned sections, routing first in one Workflow, colocated artifact/completion contracts, and no fixed line target.
- Current `shared/skills/ubiquitous-language/SKILL.md` — has the complete artifact schema and rules, but splits one process across `Process`, `Output Format`, `Rules`, and `Re-running`; promises `UBIQUITOUS_LANGUAGE.md` in the working directory in both frontmatter and body; and illustrates dialogue twice.
- Git history — the file was introduced locally at commit `14d5c80cc86c440d45e84cd636aeaef310c2683d`, then moved and locally maintained. The audit and history identify no imported source or third-party license; `THIRD_PARTY_NOTICES.md` contains no target entry and requires no change.
- There are no target support files, scripts, or executable command contracts, so no executable-help check applies.

Revision 2 returns to `drafting` before production editing because the revision 1 scope review overgeneralized the new-artifact three-column table schema to updates. WF-006 assigns project language **and spec form** to the applicable project glossary and target `SPEC-OF-SPECS`; this repository's canonical glossary legitimately includes preamble metadata and a fourth `Context notes` column. Forcing every existing term table to the skill's three-column creation schema would violate that authority and risk destructive format drift.

No consequential conflict remains after repair. Path selection uses a deterministic authority order: use a repository-declared glossary path first, otherwise the sole applicable existing glossary, otherwise an established documentation/spec convention, and only default a new glossary to root `UBIQUITOUS_LANGUAGE.md` when no repository authority or convention exists. If multiple locations remain plausibly authoritative, the workflow pauses for clarification instead of creating a competing glossary. New artifacts use the skill's one compact output schema. Updates preserve the canonical artifact's established preamble, table shape, and required fields while retaining the same semantic contract for terms, definitions, aliases, relationships, dialogue, and ambiguities.

## Exact files in scope

- `.skill-migration/shared-skill-yagni/proposals/SK-009-ubiquitous-language.md` — item-local authorization, behavior ledger, scope review, and verification record.
- `shared/skills/ubiquitous-language/SKILL.md` — repair canonical-location behavior and restructure the compact create/update artifact process.

These two paths are the complete revision 2 allowed file set, unchanged from revision 1. No support file, notice, spec, deployment file, or visibility link is required.

## Proposed changes

### Add

1. Add `Language Definitions` containing exactly the five WF-008-confirmed concepts: ubiquitous language, bounded context, canonical term, alias to avoid, and flagged ambiguity.
2. Add one routed `Workflow` whose opening selects create versus update and resolves the applicable canonical glossary path before evidence is gathered or files are written.
3. Add explicit path precedence: repository guidance/spec authority; then an applicable existing glossary; then an established repository documentation convention; finally root `UBIQUITOUS_LANGUAGE.md` only as the no-convention creation fallback. Pause for user clarification when multiple plausible authorities cannot be resolved from evidence.
4. For update mode, require reading the complete canonical glossary and merging new evidence without dropping unrelated accepted terms or groups. Revise definitions and the example dialogue only where understanding evolved, and re-flag new or still-unresolved ambiguities.
5. Add checkable completion criteria beside route selection, evidence extraction, canonical proposal, artifact writing, and final report.

### Change or move

1. Change only the frontmatter description's unconditional save-location claim to say the workflow writes the repository's canonical glossary; preserve its DDD/glossary/refinement/brownfield triggers, `name`, `metadata.short-description`, `allowed-tools`, and union-schema structure.
2. Consolidate `Process`, `Output Format`, `Rules`, and `Re-running` into one ordered Workflow: route mode/location; gather evidence; resolve terms; write or merge one artifact; reread and report.
3. Keep the current new-artifact output contract beside the write step as one compact schema: title, naturally grouped term tables with `Term`, `Definition`, and `Aliases to avoid`; `Relationships`; `Example dialogue`; and `Flagged ambiguities`. In update mode, preserve the canonical artifact's established metadata and table shape (including project-owned extra fields such as `Context notes`) while maintaining equivalent term, definition, and alias semantics.
4. Keep every content rule local to extraction or writing: domain-relevant terms only; implementation names only when domain-significant; generic programming concepts excluded unless domain-specific; canonical choices are opinionated; definitions are one sentence and state what a concept is; aliases are explicit; groups are natural rather than forced; relationships use bold canonical terms and cardinality where evident; dialogue has 3–5 exchanges and demonstrates boundaries; unresolved conflicts remain explicit rather than being presented as settled.
5. Keep the final conversational summary, now including the exact artifact path, mode, principal canonical choices, and unresolved ambiguities.

### Remove

1. Remove unconditional wording that always creates `UBIQUITOUS_LANGUAGE.md` in the working directory; retain that path only as the creation fallback when no applicable authority, existing glossary, or convention exists.
2. Remove the second standalone `<example>` dialogue because the sole output schema already demonstrates and requires the dialogue section.
3. Remove the four noncanonical level-two headings only after all create/update, artifact, rerun, and reporting behavior is retained in the single Workflow.
4. Remove no trigger, mode, evidence source, ambiguity/synonym/overload check, canonical-choice rule, domain filter, one-sentence definition rule, grouping rule, relationship/cardinality rule, dialogue requirement, output section, summary, or rerun behavior.

## Proposed skill shape

1. `Language Definitions` — present and mandatory; exactly the five human-confirmed operational terms.
2. `Workflow` — present; one create/update glossary workflow with authority/path routing first and the compact output contract beside its producing step.
3. `Activities` — omitted; extraction, canonicalization, writing, and rerun merging are required steps of the end-to-end workflow, not independently selected recipes.
4. `Reference` — omitted; the skill is self-contained and has no support Markdown warranting conditional loading.

## Behavior-preservation checklist

- [x] Frontmatter keeps all concrete invocation triggers, union fields, short description, and tool grants; only the false unconditional path promise changes.
- [x] Create versus update mode is explicit and occurs before evidence gathering or writes.
- [x] Repository authority wins; an existing applicable glossary is updated instead of silently creating a root duplicate.
- [x] Root `UBIQUITOUS_LANGUAGE.md` remains the creation fallback when no repository authority or convention exists.
- [x] Conversation, specs, plans, and brownfield code/system evidence remain valid extraction sources.
- [x] Domain-relevant nouns, verbs, and concepts are scanned; ambiguity, synonyms, vagueness, and overload remain detected.
- [x] Canonical choices remain opinionated, alternatives remain aliases to avoid, and unresolved conflicts remain explicitly flagged.
- [x] Only domain terms are included; implementation names and generic programming concepts remain excluded unless they carry domain meaning.
- [x] Definitions remain one sentence and define what the concept is.
- [x] Natural grouping remains optional rather than forced; a new artifact uses the three-column schema, while an update preserves the authoritative artifact's established metadata, table shape, and any project-owned extra fields.
- [x] Relationships retain bold canonical terms and evident cardinality.
- [x] The 3–5-exchange developer/domain-expert dialogue remains required and demonstrates interactions and boundaries.
- [x] The artifact retains title, grouped terms, Relationships, Example dialogue, and Flagged ambiguities.
- [x] Update/rerun reads the canonical artifact, merges new evidence, preserves unrelated accepted content, updates evolved definitions/dialogue, and re-flags ambiguities.
- [x] Final output still summarizes the result in conversation and now reports the exact canonical path.
- [x] Every branch, guardrail, artifact requirement, and completion condition stays inline; no replacement owner is needed beyond the already-authoritative project glossary location.
- [x] Local provenance remains accurately recorded; no unsupported attribution or license is invented.
- [x] No spec, notice, support file, deployment surface, Pi visibility link, unrelated skill/proposal, or migration ledger changes.

## Dependencies, provenance, and risks

- MG-001 already made project glossary and skill-local language ownership durable; SK-001 already supplies the verified body-authoring contract. This item consumes those decisions and does not reopen or edit them.
- The key contradiction is repaired before simplification: repository-declared glossary authority takes precedence over the historical working-directory default. Existing canonical content is merged, not wholesale replaced.
- A repository may contain multiple bounded-context glossaries. The path route therefore selects the glossary applicable to the requested context and pauses when evidence cannot identify one authority. Risk: a repository with no explicit convention still needs a default; retaining root `UBIQUITOUS_LANGUAGE.md` preserves the prior creation behavior without overriding established suites.
- Compacting the concrete sample risks making the artifact schema abstract. The resulting inline creation schema will retain every required section, its three exact table columns, the dialogue requirement, and a flagged-ambiguity form while deleting only the second redundant dialogue illustration. Update mode explicitly preserves project-owned form instead of normalizing an established glossary to this seed schema.
- The source is repo-local according to Git history and the completed audit. No imported material is moved into a new file, no license applies, and `THIRD_PARTY_NOTICES.md` remains unchanged.
- Frontmatter schema and tool grants remain outside this migration. `bash` is retained rather than least-privilege-redesigned because the standing constraints prohibit harness/frontmatter redesign.

## Verification

- Reread complete `shared/skills/ubiquitous-language/SKILL.md` and compare it line by line with the WF-005 ledger and all five WF-008 definitions — every checked behavior above must have an inline resulting location.
- Parse level-two headings and assert exactly `Language Definitions` then `Workflow`; assert `Activities` and `Reference` are absent.
- Inspect the Workflow opening — create/update and canonical-location routing must precede extraction and writing; repository authority must outrank the root fallback; unresolved competing authorities must stop for clarification.
- Inspect the single new-artifact output schema and resulting prose — its exact term-table columns, Relationships, one Example dialogue requirement, Flagged ambiguities, natural grouping, cardinality, one-sentence definitions, domain filters, and 3–5 exchanges must remain; update mode must preserve an authoritative artifact's existing metadata/table shape; the standalone duplicate `<example>` block must be absent.
- Parse all `shared/skills/*/SKILL.md` frontmatter with YAML and apply the `audit-shared-skills` union checks — expect every skill to have `name`, `description`, `metadata.short-description`, and `allowed-tools`; descriptions are at most 1024 characters and contain `Use when`; the target has no finding.
- Verify `pi/skills/ubiquitous-language` remains a symlink to `../../shared/skills/ubiquitous-language` without editing it.
- Recheck `git log --follow -- shared/skills/ubiquitous-language/SKILL.md` and target absence from `THIRD_PARTY_NOTICES.md`; expect local provenance and no notice diff.
- `git diff --check -- .skill-migration/shared-skill-yagni/proposals/SK-009-ubiquitous-language.md shared/skills/ubiquitous-language/SKILL.md` — no whitespace errors.
- `bash tests/run.sh` — repository regression checks pass.
- Compare changed paths from baseline plus untracked files — exactly the proposal and target may differ. Confirm no diff in `.skill-migration/shared-skill-yagni/MIGRATION.md`, `pi/settings.json`, specs, notices, deployment, visibility, support files, or unrelated skills/proposals.

Acceptance requires exact two-file scope, canonical two-section body, complete behavior-ledger preservation, all five confirmed definitions, authority-first path routing, one compact creation schema without duplicate dialogue, project-form-preserving update merges, valid union frontmatter, unchanged Pi visibility/provenance/forbidden scope, clean diff checks, and passing repository tests.

## Implementation record

Focused verification completed: `2026-07-14T16:57:25+00:00`.

- Proposal-before-edit control: revision 1 reached `proposal-ready` without a production edit, then returned to `drafting` when renewed spec-form review found that its three-column requirement would overwrite project-owned glossary form. Revision 2 retained the same exact two-file scope, repaired update semantics, repeated the scope review, and reached `proposal-ready` before `SKILL.md` changed.
- Actual production diff: `shared/skills/ubiquitous-language/SKILL.md` has 60 insertions and 60 removals. This proposal is the only additional item-local file. Resulting skill SHA-256 is `f1ebb2333338824b56e4c17a7be6e555c3ccf2150252b0fbd3c1c23011c2e944`.
- Complete-file reread and WF-005/WF-008 comparison: PASS. All five confirmed definitions, create/update route, conversation/spec/plan/brownfield evidence, synonym/ambiguity/overload detection, opinionated canonical choices, domain filters, one-sentence definitions, natural groups, relationships/cardinality, 3–5-exchange dialogue, explicit ambiguity status, update merging, and final summary remain inline.
- Contradiction repair: PASS. Repository-declared authority outranks the historical root default; unresolved competing authorities pause for clarification; root `UBIQUITOUS_LANGUAGE.md` remains only the no-convention creation fallback. Updates preserve established preamble/table shape/project fields and unrelated accepted content rather than imposing the seed schema.
- Canonical body: PASS. Semantic level-two headings are exactly `Language Definitions` then `Workflow`; `Activities` and `Reference` are absent. Each of the five Workflow steps has an observable completion criterion.
- Semantic YAGNI: PASS. The second standalone `<example>` dialogue and fragmented `Process`/`Output Format`/`Rules`/`Re-running` ownership are removed. One compact creation schema retains all required fields and sections; there is no fixed line target.
- Union-frontmatter audit: PASS for all 33 shared skills with 0 findings. The target description is 464 characters, retains `Use when` and every concrete trigger, and the existing name, short description, and tool grants remain valid.
- Support/link/command verification: PASS. The target has no support files, Markdown links, scripts, or changed executable commands, so no executable-help validation applies.
- Repository checks: `bash tests/run.sh` PASS (2 shell files, 12 tests); `git diff --check` PASS; Pi symlink remains `../../shared/skills/ubiquitous-language`; local introduction at `14d5c80cc86c440d45e84cd636aeaef310c2683d` remains supported; the target has no notice entry and no notice diff.
- Exact scope and forbidden scope: PASS. Baseline plus untracked comparison contains only this proposal and target; `MIGRATION.md`, `pi/settings.json`, specs/glossary, notices, deployment, visibility, support files, and unrelated skills/proposals have no diff.
- Residual risk: a repository with several plausible glossary authorities or bounded contexts requires user clarification and therefore cannot complete unattended; this is the deliberate guard against a competing canonical artifact. A new repository still receives the historical root filename only when no authority or convention exists.

## Explicit exclusions

- No edit to `.skill-migration/shared-skill-yagni/MIGRATION.md`, `pi/settings.json`, any spec or glossary, `THIRD_PARTY_NOTICES.md`, README, AGENTS.md, installer/deployment files, agent configs, or Pi visibility symlinks.
- No edit to another shared skill, migration proposal, or support file; no new Reference, example, template, script, command, or executable dependency.
- No frontmatter schema, `allowed-tools`, harness grant, explicit-invocation, discovery, deployment, or portability redesign.
- No ownership of project-domain definitions is transferred into the skill body; no universal output schema is imposed on another producer.
- No claim on central verification, integration, VG-001, or any migration item other than SK-009.

## Standing authorization

- Human directive timestamp: `2026-07-14T15:55:39+00:00`
- Proposal revision: `2`
- Authorization effect: the standing directive removes the per-item approval wait but authorizes only the two exact paths and changes enumerated in revision 2.
- Scope check: `PASS` — MAP/WF-007, the complete WF-005 target record, WF-008, WF-006, current specs including project-owned glossary form, verified `write-a-skill`, the complete target, provenance/history, and lack of executable support were reviewed in authority order. Revision 2 retains the exact two-file scope, preserves every ledger entry, repairs canonical path and project-form authority before simplification, retains local provenance and union frontmatter, and defines focused plus repository verification. Production editing may continue without a per-item approval wait.

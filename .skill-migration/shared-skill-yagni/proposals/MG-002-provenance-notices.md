---
id: MG-002
target: Provenance notices for Grill Me, Herdr, and Playwright
status: verified
revision: 1
blocked-by: [MG-001]
source-verdict: Repair the three provenance and license gaps identified by WF-003, WF-004, and WF-006 before imported skill bodies are rewritten
---

# Provenance notices for Grill Me, Herdr, and Playwright

## Why this item is next

MG-001 is verified and makes source, revision, license identification a normative gate before imported skill material is moved or rewritten. WF-006 identified three existing notice gaps. MG-002 repairs only those gaps so `write-a-skill` and the later Herdr and Playwright body proposals do not restructure imported material without durable provenance.

This proposal authorizes a repository-level notice edit only. It does not authorize editing any shared skill.

## Evidence

- `.wayfinder/shared-skill-yagni-audit/MAP.md`
- WF-003 `grill-me` record: imported from `mattpocock/skills` and absent from `THIRD_PARTY_NOTICES.md`.
- WF-004 `herdr` record: local body matches upstream Herdr `SKILL.md` at commit `6cbdba434fd15fc3818302a5843593da47db2eb4` except repository frontmatter; upstream package declares `AGPL-3.0-or-later`.
- WF-004 `playwright` record: the skill and nine references were substantially adapted from Microsoft `playwright-cli` around commit `fac6ebbe68167aa95078d5b8196817c533d9dfb7`; upstream package declares `Apache-2.0` and has no `NOTICE` file at that revision.
- WF-006 provenance contradiction and migration order.
- `specs/ai-agent-config.md` version `2.3.0`: imported material requires source, revision, license, and repository-level notice coverage before movement or rewriting.
- Current `THIRD_PARTY_NOTICES.md`: contains the Matt Pocock MIT notice but omits `grill-me`, Herdr, and Playwright.
- Local Git provenance:
  - `80eafee1882c0f2fccc0c066ac3a5e3572f25f02` imported `grill-me` from Matt Pocock's skill with an exact source-body match.
  - `1007795a0e3608f271797dfc6f6c1ab2b72d5284` introduced the Herdr skill.
  - `236096bd22f2da9b5d999bbb3bb02ed1a615ec3d` introduced the Playwright skill corpus; `26119dbf3ed18cd7c6b05ae20acfb2b6f9f0d677` later renamed and rerouted it.
- Exact upstream primary sources, checked 2026-07-14:
  - `mattpocock/skills`, `skills/productivity/grill-me/SKILL.md` at `62f43a18177be6ec82da242e59ffbc490a4c22ea`, and the repository MIT `LICENSE`.
  - `ogulcancelik/herdr`, root `SKILL.md`, `Cargo.toml`, and `LICENSE` at `6cbdba434fd15fc3818302a5843593da47db2eb4`.
  - `microsoft/playwright-cli`, `skills/playwright-cli/`, `package.json`, and `LICENSE` at `fac6ebbe68167aa95078d5b8196817c533d9dfb7`.

## Exact files in scope

- `THIRD_PARTY_NOTICES.md` — repair the three approved provenance gaps and carry the required license copies.

No other file is authorized by this proposal.

## Proposed changes

### Change the existing Matt Pocock section

1. Preserve every currently listed Matt Pocock skill and the existing MIT license text unchanged.
2. Separate the existing July 2026 cohort, sourced from commit `66898f60e8c744e269f8ce06c2b2b99ce7660d5f`, from `grill-me` so the notice does not falsely claim the later cohort revision as Grill Me's original source.
3. Add `grill-me` as a separately qualified Matt Pocock lineage:
   - stable source link to `skills/productivity/grill-me/SKILL.md` at full commit `62f43a18177be6ec82da242e59ffbc490a4c22ea`;
   - state that it was imported locally at commit `80eafee1882c0f2fccc0c066ac3a5e3572f25f02` and subsequently expanded for repository glossary, evidence, and routing behavior;
   - state that it remains covered by the Matt Pocock MIT license already reproduced in the section.
4. Keep the locally maintained, no-automatic-upstream-sync statement applicable to both the existing cohort and `grill-me`.

### Add a Herdr section

1. Identify `shared/skills/herdr/SKILL.md` as adapted from the root Herdr `SKILL.md` in [`ogulcancelik/herdr`](https://github.com/ogulcancelik/herdr) at full commit `6cbdba434fd15fc3818302a5843593da47db2eb4`.
2. Record local introduction at commit `1007795a0e3608f271797dfc6f6c1ab2b72d5284`, repository frontmatter adaptation, and locally maintained/no-automatic-sync status.
3. Record the upstream license identifier `AGPL-3.0-or-later` and stable links to the exact source and license revision.
4. Reproduce the complete upstream `LICENSE` text from that exact revision verbatim under `GNU Affero General Public License v3.0 or later`. The license copy is required legal material and is not subject to semantic YAGNI pruning.

### Add a Microsoft Playwright CLI section

1. Identify `shared/skills/playwright/SKILL.md` and all nine files under `shared/skills/playwright/references/` as substantially adapted from [`microsoft/playwright-cli/skills/playwright-cli`](https://github.com/microsoft/playwright-cli/tree/fac6ebbe68167aa95078d5b8196817c533d9dfb7/skills/playwright-cli) at full commit `fac6ebbe68167aa95078d5b8196817c533d9dfb7`.
2. Record Microsoft Corporation as the upstream package author, local introduction at commit `236096bd22f2da9b5d999bbb3bb02ed1a615ec3d`, later rename/rerouting, and locally maintained/no-automatic-sync status.
3. Record the upstream license identifier `Apache-2.0`, stable links to the exact source and license revision, and the evidence that no upstream `NOTICE` file exists at that revision.
4. Reproduce the complete upstream Apache License 2.0 `LICENSE` text from that exact revision verbatim. No extra NOTICE content will be invented.

### Remove or relocate

- Remove no existing attribution, license text, or skill entry.
- Relocate no legal text to a skill body or supporting file.
- Change no provenance owner: `THIRD_PARTY_NOTICES.md` remains the central repository authority.

## Proposed skill shape

Not a skill body change.

## Behavior-preservation checklist

- [x] Every existing Matt Pocock skill entry remains present.
- [x] Existing Matt Pocock MIT text remains unchanged.
- [x] Grill Me uses its exact original source revision rather than the later common cohort revision.
- [x] Herdr identifies source, full revision, local adaptation, and `AGPL-3.0-or-later`.
- [x] Playwright identifies the main skill plus all nine references, full revision, local adaptation, and `Apache-2.0`.
- [x] Complete AGPL and Apache license texts match the exact upstream revisions.
- [x] No unsupported Playwright NOTICE attribution is invented.
- [x] No shared skill, support file, spec, deployment, discovery, installer, or Pi visibility file changes.
- [x] `pi/settings.json` remains untouched.

## Dependencies, provenance, and risks

- MG-001 is verified and supplies the durable provenance gate this item satisfies.
- MG-002 must be verified before `SK-001 write-a-skill`; later Herdr and Playwright proposals also depend on this repair.
- Risk: adding `grill-me` to the existing common Matt revision would record a source that does not match its original import. Mitigation: preserve a separate exact `62f43a...` lineage under the same MIT license.
- Risk: abbreviated license identifiers or links alone may not carry the required license copy with the adapted material. Mitigation: reproduce the complete exact-revision AGPL and Apache license texts in the central notice.
- Risk: inventing a Microsoft NOTICE obligation that the source revision does not provide. Mitigation: record that the exact upstream tree contains no `NOTICE` file and copy only the Apache license and evidenced package authorship.
- Risk: the legal text substantially increases notice length. Mitigation: treat required license copies as legal obligations rather than skill-body context subject to YAGNI pruning.
- This proposal records repository provenance; it is not legal advice and does not change the licenses of unrelated repository content.

## Verification

- Reread the complete resulting `THIRD_PARTY_NOTICES.md` and compare each section with the exact upstream source, package manifest, and license revision.
- Fetch the three source revisions through the GitHub API and confirm the full commit hashes resolve.
- Confirm the local import commits resolve and their file histories match the stated lineage.
- Extract the reproduced AGPL and Apache license bodies and compare them byte-for-byte after CRLF normalization with:
  - `https://raw.githubusercontent.com/ogulcancelik/herdr/6cbdba434fd15fc3818302a5843593da47db2eb4/LICENSE`
  - `https://raw.githubusercontent.com/microsoft/playwright-cli/fac6ebbe68167aa95078d5b8196817c533d9dfb7/LICENSE`
- Run `rg -n 'grill-me|62f43a18177be6ec82da242e59ffbc490a4c22ea|herdr|6cbdba434fd15fc3818302a5843593da47db2eb4|AGPL-3.0-or-later|playwright|fac6ebbe68167aa95078d5b8196817c533d9dfb7|Apache-2.0|Microsoft Corporation' THIRD_PARTY_NOTICES.md` and inspect every match in context.
- Count the Playwright reference files and confirm the notice scope remains nine.
- Run `git diff --check -- THIRD_PARTY_NOTICES.md`.
- Run `git diff -- THIRD_PARTY_NOTICES.md` and confirm the actual production diff contains only the disclosed notice repairs.
- Run `git status --short` and confirm `pi/settings.json` remains the only unrelated pre-existing tracked modification outside the already verified MG-001 spec changes.

## Implementation record

Verified timestamp: `2026-07-14T15:37:51+00:00`

- Actual production diff: `THIRD_PARTY_NOTICES.md` only, with 882 insertions and no removals.
- All three exact upstream commit hashes resolved through the GitHub API.
- The Grill Me and Herdr introduction bodies matched their stated upstream revisions; the Playwright introduction matched the upstream main-plus-nine corpus as an exact or substantial adaptation.
- Fresh exact-revision manifest checks confirmed `AGPL-3.0-or-later`, Microsoft Corporation, `Apache-2.0`, and no Playwright `NOTICE` file.
- The reproduced AGPL and Apache bodies matched freshly fetched exact-revision licenses byte-for-byte after CRLF normalization.
- The 13 existing Matt Pocock entries and existing MIT text remained unchanged; nine local Playwright reference files remain present.
- `git diff --check -- THIRD_PARTY_NOTICES.md` passed, and focused diff inspection found only the approved notice file.
- Pre/post hashes confirmed `pi/settings.json` and the three verified MG-001 spec diffs remained untouched.

## Explicit exclusions

- No shared skill or supporting reference edits.
- No changes to the MG-001 specifications.
- No command corrections, body restructuring, or implementation of the Grill Me, Herdr, or Playwright audit recommendations.
- No frontmatter, `allowed-tools`, deployment, discovery, installer, or Pi visibility changes.
- No new license files outside `THIRD_PARTY_NOTICES.md`.

## Decision

Proposal revision: `1`

Presented timestamp: `2026-07-14T15:28:57+00:00`

Recorded human response: `APPROVE MG-002 and handoff to a new herdr pi tab`

Approval decision: `APPROVE MG-002`

Decision timestamp: `2026-07-14T15:31:48+00:00`

Approved proposal revision: `1`.

Reply with exactly one:

- `APPROVE MG-002`
- `DECLINE MG-002: <reason>`
- `REVISE MG-002: <instruction>`

No production file is authorized until that decision is recorded.

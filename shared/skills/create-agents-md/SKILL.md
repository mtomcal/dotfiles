---
name: create-agents-md
description: Generate and maintain an AGENTS.md codebase map that prevents hill climbing by surfacing module boundaries, dependency rules, anti-patterns, and coding principles. Use when creating an AGENTS.md for a new project or updating an existing one as the codebase evolves.
metadata:
  short-description: Generate and maintain AGENTS.md codebase maps
allowed-tools:
  - read
  - write
  - edit
  - bash
  - grep
  - ls
  - find
---

# Create AGENTS.md

## Language Definitions

- **Codebase map** — agent-facing overview of structure, ownership, dependencies, entry points, rules, and anti-patterns.
- **Hill climbing** — repeatedly loading additional files into context while discovering a task, increasing context cost and diluting relevant information when the map could have directed the agent to a smaller authoritative set; necessary reading for genuinely cross-cutting work is excluded.
- **Tree hash** — SHA-256 directory-tree fingerprint for structural-change detection, not content accuracy.
- **Confidence marker** — inferred, convention-backed, or human-confirmed status, not probability.
- **Codebase area** — directory or subsystem represented by one AGENTS.md ownership section, avoiding collision with `codebase-design`’s module.

## Workflow

### 1. Route creation versus update

Find the project root and check for root `AGENTS.md` before doing anything else:

- If it does not exist, select **full generation**.
- If it exists, select **incremental update**.

The parent running this workflow owns the draft, user gates, acceptance, and every `AGENTS.md` write. Completion: exactly one mode is selected from root-file evidence.

### 2. Detect current structure

Resolve and execute `scripts/detect-structure.sh` from this skill directory with `--json` and the project root. If `tree` is unavailable, stop and help the user install it with `brew install tree` on macOS or `sudo apt install tree` on Ubuntu/Debian, then retry; do not fabricate detector output.

Parse and retain:

- `tree` and `tree_hash` for the delimited map and structural comparison;
- `ecosystems` and their detected entry-point evidence;
- `modules`, where every record includes name, path, convention match, confidence, dominant language, README presence/description, detected dependencies, and entry points; and
- `warnings`, which must be surfaced and resolved or recorded as limitations.

The detector calls candidates `modules`; represent each accepted ownership section as a Codebase area. The Tree hash says only whether the emitted directory tree changed, not whether file content or the existing map is accurate.

Completion: detection succeeds, all required fields are accounted for, and warnings are not silently discarded.

### 3. Execute the selected mode

#### Full generation

Draft from `TEMPLATE.md` without writing the final root file yet:

1. Embed the exact detected tree between `<!-- TREE-START -->` and `<!-- TREE-END -->`, with `<!-- TREE-HASH: <sha256> -->`.
2. Create one Modules subsection for each accepted detected Codebase area:
   - **Purpose**: README evidence when available; otherwise `[LOW-CONFIDENCE: auto-detected — <convention>]`.
   - **Owns**: detected subdirectories.
   - **Depends on**: detected manifest relationships or `[LOW-CONFIDENCE: none detected]`.
   - **Rules**: `[LOW-CONFIDENCE: pending interview]`.
   - **Entry points**: detected build/manifest evidence or `[LOW-CONFIDENCE: none detected]`.
3. Pre-populate convention-backed dependency rules with a matching Confidence marker, such as `[MEDIUM-CONFIDENCE: internal/ packages are unexported outside this module per Go convention]`; mark unsupported rules pending interview.
4. Mark Anti-patterns and Coding Principles `[LOW-CONFIDENCE: pending interview]`.

Present the parent-owned draft section by section. For every Codebase area, ask whether its purpose and ownership are accurate, whether dependencies contain omissions or false positives, and whether entry points are missing. Correct the draft and replace a Confidence marker with `[CONFIRMED]` or confirmed text only when the user or authoritative evidence supports it.

Completion: every drafted area has been shown and its purpose/ownership, dependencies, and entry points have been confirmed or remain explicitly unresolved; no inference is presented as human-confirmed.

#### Incremental update

Extract the stored Tree hash and old tree from the existing marker blocks, then compare them with current detection:

1. If hashes are identical, report that the structural map is up to date and make no edit. State that this is a structural no-op, not a content-accuracy audit, then stop.
2. If hashes differ, compare old and new trees. Add genuinely new areas with `[LOW-CONFIDENCE: new directory]`, update moved or renamed paths, and ask the user before removing any area or human-authored content associated with a removed directory.
3. Rescan manifests and update detected `Depends on` evidence for affected areas. Never overwrite human-authored Rules, Anti-patterns, or Coding Principles with detector output.
4. For every genuinely new area, run the same purpose/ownership, dependency, and entry-point confirmation used in full generation.

Completion: structural additions, removals, and moves are accounted for; every removal is approved; dependency evidence is rescanned; new areas are confirmed; and preserved human-authored content remains intact.

### 4. Conduct the mandatory `grill-me` deep pass

When full-generation confirmation or a structural update is complete, load `PRINCIPLES_CATALOG.md` and `GRILL_BRIEFING.md`, then use `grill-me` to conduct the detailed one-question-at-a-time interview. Cover every area for full generation and only affected areas plus impacted cross-area rules for an update. An identical-hash update already stopped and does not run this pass.

When `HERDR_ENV=1`, load the shared `herdr` skill before considering terminal transport. A read-only sibling pane may conduct the interview only when the user can interact with that pane. Otherwise, it may only critique the briefing while the parent conducts the human interview. The sibling returns findings through pane output, never edits `AGENTS.md`, and supplies no durable pane ID or selector. The parent independently checks returned findings against the user's answers before writing.

Outside Herdr, or whenever a sibling cannot interact with the user, load `grill-me` and conduct the complete interview directly in-process. This is the full fallback, not a reduced review.

Merge confirmed area rules, dependency boundaries, anti-patterns, and coding principles into the parent-owned draft. Replace pending-interview markers only with supported content; retain and report an explicit Confidence marker for unresolved uncertainty rather than inventing certainty.

Completion: the mandatory in-scope deep pass is complete, findings have been checked against user answers, unresolved items are explicit, and only the parent has modified the draft.

### 5. Finalize and report

Refresh the detected tree immediately before writing if structure changed during the interview. Write the final parent-owned `AGENTS.md` with the current Tree hash and tree block. Count Codebase area/Modules subsections, dependency rules, anti-patterns, and coding-principle entries.

Report: `AGENTS.md created/updated at tree hash <sha256> with X modules, Y dependency rules, Z anti-patterns, and W coding principles.` For an incremental no-op, report that no edit was made, then include the current Tree hash and the same four counts from the existing artifact.

Completion: the stored hash matches the written tree, or the no-op hash matches the existing tree; the four counts are derived from the final artifact; and no unconfirmed content is described as confirmed.

## Reference

- When the mandatory deep pass is reached, load [the coding-principles catalog](PRINCIPLES_CATALOG.md) because it owns the seven-category question inventory, and load [the deep-pass briefing](GRILL_BRIEFING.md) because it owns the structured interview brief and returned-findings schema.

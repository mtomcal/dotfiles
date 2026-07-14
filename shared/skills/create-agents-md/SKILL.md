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

Generates and maintains an AGENTS.md — a living codebase map that prevents hill climbing (locally optimal, globally wrong decisions) by giving AI agents a topographic view of module boundaries, architectural rules, anti-patterns, and coding principles.

## Workflow

### Step 0: Detect Mode

Check if `AGENTS.md` exists in the project root:

- **No AGENTS.md** → full generation (go to Step 1)
- **AGENTS.md exists** → incremental update (go to Step 4)

---

## Full Generation (No Existing AGENTS.md)

### Step 1: Auto-Detect Structure

Run the detection script:

```bash
bash /path/to/shared/skills/create-agents-md/scripts/detect-structure.sh --json
```

If `tree` is not installed, help the user install it:

- **macOS**: `brew install tree`
- **Ubuntu/Debian**: `sudo apt install tree`

Parse the JSON output. You now have:
- `tree` — directory map (dirs only, `--dirsfirst`)
- `tree_hash` — sha256 of tree output (for future diff)
- `ecosystems` — detected language ecosystems and their entry points
- `modules` — per-directory: name, path, convention match, confidence, dominant language, has_readme, readme_description, depends_on (from manifests), entry_points
- `warnings` — anything unusual (multiple package managers, missing README, etc.)

### Step 2: Generate Draft

Produce a draft `AGENTS.md` from [TEMPLATE.md](TEMPLATE.md). Apply these rules:

1. **Map section**: Embed the tree output inside `<!-- TREE-START -->` / `<!-- TREE-END -->` HTML comments. Include `<!-- TREE-HASH: <sha256> -->` for future diffing.

2. **Modules section**: One subsection per auto-detected module. Populate:
   - **Purpose**: From README if available, otherwise `[LOW-CONFIDENCE: auto-detected — <convention>]`
   - **Owns**: Subdirectories within the module
   - **Depends on**: From manifest parsing, or `[LOW-CONFIDENCE: none detected]`
   - **Rules**: `[LOW-CONFIDENCE: pending interview]`
   - **Entry points**: From build manifests, or `[LOW-CONFIDENCE: none detected]`

3. **Dependency Rules section**: Pre-populate with auto-detected rules (e.g., `internal/` in Go → `[MEDIUM-CONFIDENCE: internal/ packages are unexported outside this module per Go convention]`). Flag remaining as `[LOW-CONFIDENCE: pending interview]`.

4. **Anti-patterns section**: Leave as `[LOW-CONFIDENCE: pending interview]`.

5. **Coding Principles section**: Leave as `[LOW-CONFIDENCE: pending interview]`.

### Step 3: Inline Confirmation (Modules)

Present the draft to the user section by section. For each module, ask:

- "Is the purpose accurate? What does this module actually own?"
- "Any missing dependencies or false positives?"
- "Any entry points I missed?"

Update the draft as you go. Replace `[LOW-CONFIDENCE]` / `[MEDIUM-CONFIDENCE]` markers with `[CONFIRMED]` or corrected values.

When all modules are confirmed, go to Step 5 (grill-me deep pass).

---

## Incremental Update (Existing AGENTS.md)

### Step 4: Diff and Update

1. Re-run `detect-structure.sh --json` to get the current tree.
2. Extract the stored `<!-- TREE-HASH: ... -->` from the existing AGENTS.md.
3. Compare hashes. If identical → "AGENTS.md is up to date. No changes needed." Exit.
4. If different → compare the old tree (from `<!-- TREE-START/END -->`) with the new tree:
   - **New directories**: Add as new modules with `[LOW-CONFIDENCE: new directory]`
   - **Removed directories**: Flag modules for removal, ask user to confirm
   - **Renamed/moved directories**: Update module paths
5. Re-scan build manifests for updated dependencies. Update `Depends on` fields for changed modules.
6. **Preserve all human-authored content** — Rules, Anti-patterns, and Coding Principles sections are never overwritten by auto-detection.
7. For genuinely new modules, ask the inline confirmation questions (Step 3). Optionally offer a grill-me pass on the new module alone.

---

### Step 5: Grill-Me Deep Pass

Once inline confirmation is complete, use the `grill-me` skill for adversarial interviewing. Load [PRINCIPLES_CATALOG.md](PRINCIPLES_CATALOG.md) for the question inventory and prepare the structured briefing below.

When `HERDR_ENV=1`, load the shared `herdr` skill. A read-only sibling Pi pane may conduct the grilling only when the user can interact with that pane; otherwise use the pane to critique the briefing and conduct the human interview in the parent pane. The sibling returns findings through pane output and never edits `AGENTS.md`. Do not persist compact Herdr pane ids.

Outside Herdr, or when a sibling cannot interact with the user, load `grill-me` and conduct the same one-question-at-a-time interview directly in-process. This fallback is the complete workflow, not a reduced review.

**Structured briefing format:**

```
## AGENTS.md Draft Review

Below is an auto-generated AGENTS.md draft for <project-name>. Sections marked [LOW-CONFIDENCE] need human confirmation. For each, interview the user relentlessly until the section is complete.

### Section 1: Module Rules

For each module listed below, ask:
- "What rules govern work in <module>?"
- "What has broken when these rules were violated?"
- "What should every developer know before touching this module?"

<list module names from the draft>

### Section 2: Dependency Rules

Ask:
- "What architectural boundaries exist in this codebase?"
- "What imports or cross-module calls are forbidden?"
- "Are there layering rules (e.g., handlers never call DB directly)?"

### Section 3: Anti-patterns

Ask:
- "What mistakes have been made more than once in this codebase?"
- "What patterns keep causing bugs or rework?"
- "What should a new developer be warned about?"

For each anti-pattern, capture: the pattern, why it was wrong, and the right approach.

### Section 4: Coding Principles

Walk through the categories in PRINCIPLES_CATALOG.md. For each category:
- Confirm whether the team follows it
- If yes: capture the specific practices
- If no: note "not practiced" (don't argue)

The catalog categories are: [paste PRINCIPLES_CATALOG.md summary]

### Output Format

Return your findings as:

## Interview Results

### Module Rules
- **<module>**: <rules from interview>

### Dependency Rules
- <rule>: <rationale>

### Anti-patterns
- **Pattern**: <description>
  **Why wrong**: <explanation>
  **Right way**: <guidance>

### Coding Principles
- **<category>**: <confirmed practices or "not practiced">

## Unresolved
[List any areas the user was uncertain about]
```

After the grill-me pass completes, collect its results and merge them into the draft `AGENTS.md`. Replace all remaining `[LOW-CONFIDENCE: pending interview]` markers with confirmed content. If a sibling pane was used, independently check its findings against the user's answers before writing.

### Step 6: Finalize

1. Update `<!-- TREE-HASH -->` with the current hash.
2. Write the final `AGENTS.md` to the project root.
3. Report: "AGENTS.md created/updated with X modules, Y dependency rules, Z anti-patterns, and W coding principles."

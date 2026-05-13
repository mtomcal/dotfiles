---
name: update-specs
description: Analyze recent code changes against the spec suite, detect coverage gaps, violations, and checklist drift, then delegate spec updates to a sub-agent and verify through review passes. Use when specs need syncing after code changes, or when user mentions 'update specs', 'sync specs', or 'specs are stale'.
---

# Update Specs

You are an orchestrator — you do not edit specs yourself. You analyze, delegate, and verify.

## Quick start

Invoke with a git scope boundary:
```
update-specs --since <ref>
```
Examples: `--since HEAD~5`, `--since main..feature-branch`.

## Workflows

### Step 1 — Pre-flight

**Hard gate: working tree must be clean.** Verify with `git status --porcelain`. If dirty, abort and report.

**Hard gate: `--since <ref>` is required.** No default. Verify the ref resolves and the diff is non-empty.

### Step 2 — Detect discrepancies

Read these in order:

1. **AGENTS.md** module boundaries — maps code paths to spec files
2. **specs/README.md** dependency graph + implementation checklist
3. **All spec files** in `specs/` — extract every "MUST" clause, every checklist item, every declared scope
4. **`git diff --stat <ref>..HEAD`** — changed files and magnitude
5. **`git diff <ref>..HEAD`** — changed content

Classify each changed file against the spec suite:

| Discrepancy | Signal |
|-------------|--------|
| **Coverage gap** | File changed but no spec covers it (new module, new tool, new agent) |
| **Violation** | Code contradicts a "MUST" clause in a spec |
| **Checklist drift** | Implementation checklist claims something is done but code disagrees |
| **In-spec change** | Code change is within what the spec already requires — no update needed |

Build an inline discrepancy table in context:

```
| # | Spec File | Type | What Changed | What Spec Says | Action |
|---|-----------|------|-------------|----------------|--------|
| 1 | ai-agent-config.md | violation | [detail] | [MUST clause] | Update MUST clause |
| 2 | new-needs-spec.md | coverage gap | [new module] | — | Create new spec |
```

### Step 3 — Present inline plan

Show the user the discrepancy table and the proposed execution plan. **Wait for confirmation before proceeding.**

```markdown
## Spec Update Plan — <ref>

[N] discrepancies found: [n1] violations, [n2] coverage gaps, [n3] checklist drift.

**Execution**: Single sub-agent reads full git diff + all specs, applies all updates.
**Review**: 3 passes — contract consistency, cross-spec integrity, mechanical quality.
**Escalation**: <3 fix issues → per-file fixers. ≥3 or hallucination → sage.
**Guardrail fallback**: Rollback specs/, report to user.
```

### Step 4 — Delegate updates

Fork a single sub-agent with a system prompt tailored to spec authoring:

```
subagent_fork {
  task: "Update spec files to reflect recent code changes.

Git scope: <ref>
Changed files (diff stat):
<git diff --stat <ref>..HEAD>

Discrepancy table:
<inline discrepancy table>

Instructions:
1. Read ALL spec files in specs/.
2. Read the full git diff (<ref>..HEAD).
3. Apply the fixes from the discrepancy table.
4. For each spec change:

   - Prescriptive tone: 'The system MUST…' — never descriptive.
   - No code in specs. Use schema tables, decision tables, or pseudocode.
   - Every parameter change goes in parameters.md with a WHY column.
   - Bump version per SPEC-OF-SPECS convention (patch/minor/major).
   - Add changelog entry with date and summary.
   - Update cross-references if file names change.
   - Update UBIQUITOUS_LANGUAGE.md if new terms are introduced.

5. For coverage gaps: create a new spec file following SPEC-OF-SPECS template.
   Add it to specs/README.md dependency graph and reading order.
   Register an appropriate prefix (2-6 chars).

6. Do NOT change any file outside specs/.

Return: list of all files created/modified, version bumps applied, and any concerns.",
  systemPrompt: "You are a spec authoring agent. Specs are language-agnostic, prescriptive behavior contracts. Never embed code — use pseudocode, schema tables, and decision tables. Every clause uses 'MUST' language. Specs define what the system SHOULD do, not what it currently does. References use markdown cross-links. Every version bump must include a changelog entry.",
  tools: "read,write,edit,bash",
  maxTurns: 30,
  maxCost: 0.50,
  maxTokens: 200000,
  maxTime: 300
}
```

### Step 5 — Review passes (sequential)

After the update sub-agent completes, run these three reviews in order. Each review must pass before proceeding to the next. Use `subagent_run` for sequential gate checking.

#### Pass 1 — Contract consistency

Verify every spec change has a corresponding code change in the git diff.

```
subagent_run {
  agent: "quality-reviewer",
  task: "Contract consistency check for spec updates.

Git scope: <ref>
Full git diff: <git diff <ref>..HEAD>
Spec changes: <git diff -- specs/>

For each added/changed/removed 'MUST' clause in the spec changes:
- Does a corresponding code change exist in the git diff?
- If no, flag as HALLUCINATED REQUIREMENT.
- If yes, state which code change supports it.

Return: structured table of every MUST clause with code match or HALLUCINATION flag.",
  maxTurns: 15,
  maxCost: 0.15,
  maxTokens: 100000,
  maxTime: 120
}
```

#### Pass 2 — Cross-spec integrity

All specs must form a coherent suite — no broken references, no term drift, no dependency orphans.

```
subagent_run {
  agent: "quality-reviewer",
  task: "Cross-spec integrity check.

Read ALL files in specs/. Check:
1. Every internal cross-reference resolves to an existing section anchor.
2. Every spec prefix appears in SPEC-OF-SPECS prefix table or is new with proper registration.
3. Terminology in UBIQUITOUS_LANGUAGE.md is consistent across all specs.
4. Dependency graph in specs/README.md is still coherent — new specs are properly placed.
5. Every new spec file follows the SPEC-OF-SPECS required section order.

Return: structured report with issues found per check.",
  maxTurns: 20,
  maxCost: 0.20,
  maxTokens: 150000,
  maxTime: 180
}
```

#### Pass 3 — Mechanical quality

Formatting, versioning, and changelog compliance.

```
subagent_run {
  agent: "quality-reviewer",
  task: "Mechanical quality gate for spec changes.

Check:
1. Every modified spec has a version bump (patch/minor/major per SPEC-OF-SPECS).
2. Every modification has a changelog entry with date and summary.
3. No broken markdown links (internal or external).
4. SPEC-OF-SPECS required sections are present in order.
5. No code in specs — pseudocode, schema tables, or decision tables only.

Return: structured report with pass/fail per check.",
  maxTurns: 10,
  maxCost: 0.10,
  maxTokens: 50000,
  maxTime: 120
}
```

### Step 6 — Process review results

- **All 3 passes ✅ PASS** → write milestone: `✅ Specs updated and verified for <ref>.`
- **Pass 1 finds hallucinated requirements** → escalate immediately to sage agent with full context. This is a critical failure — the update sub-agent invented behavior.
- **Other reviewers ❌ NEEDS-FIX**:
  - **<3 issues** → fork one fixer sub-agent per affected spec file with specific instructions.
  - **≥3 issues** → escalate to sage agent with reviewer verdicts and full context.

**Re-review after fixes**: re-run only the failed review passes, not all three.

### Step 7 — Guardrail fallback

If the update sub-agent is killed by guardrail mid-edit:
1. `git checkout -- specs/` — rollback all partial changes.
2. Report to user: `⚠️ Guardrail hit mid-edit. All spec changes rolled back. Recommend increasing maxTurns/maxCost or narrowing --since scope.`

Partial updates create false synchronicity — always prefer a clean rollback.

## Guardrail defaults

Spec updates involve reading the full git diff and multiple spec files — double the standard guardrails to account for the heavyweight I/O. The first execution of this skill confirmed both maxTurns(30) and quality-reviewer maxTime(120s) were insufficient.

| Role | maxTurns | maxCost | maxTokens | maxTime |
|------|----------|---------|-----------|---------|
| **Update sub-agent** (spec authoring) | 60 | 1.00 | 300000 | 300 |
| **quality-reviewer** (any pass) | 30 | 0.40 | 200000 | 600 |
| **sage** (escalation) | 50 | 1.50 | 200000 | 300 |

⚠️ **Recorded lesson (2026-05-13)**: First run hit maxTurns(30) on the update sub-agent and maxTime(120s/300s) on quality-reviewer. Initial defaults were too tight for full-spec-read workloads. Double the standard defaults going forward.

## Agent references

- `quality-reviewer` — contract consistency, cross-spec integrity, mechanical quality
- `sage` — escalation when ≥3 issues, hallucinated requirements, or guardrail fallback
- Default subagent with `systemPrompt` — spec authoring (no dedicated agent exists)

## Anti-patterns

1. **🔴 Auto-editing specs yourself.** You are an orchestrator. Delegate all edits.
2. **🔴 Descriptive tone in specs.** Specs are prescriptive — "MUST", not "currently does".
3. **🔴 Embedding code.** Pseudocode, schema tables, decision tables only.
4. **🔴 Skipping review passes.** All three passes are mandatory before marking complete.
5. **🔴 Partial updates after guardrail.** Always rollback — half-updated specs are worse than no updates.
6. **🔴 Missing `--since`.** The ref is required. No default. No heuristic guessing.

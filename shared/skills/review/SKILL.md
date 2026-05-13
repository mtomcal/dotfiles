---
name: review
description: Multi-dimension code review with auto-detection — fires the right reviewers based on code changes, produces a consolidated report
metadata:
  short-description: Auto-detecting multi-dimension code review
allowed-tools: read,write,bash,edit
---

# Review

Run a comprehensive review on code changes. Auto-detects which reviewers to fire based on heuristics and file analysis. Always produces a consolidated report.

## Usage

```
/review                     # Reviews git diff against merge-base
/review path/to/file.ts     # Reviews specific files
/review --full              # Reviews entire working tree
/review --gate              # Report mode with exit-code behavior for CI
/review --skip-visual       # Skip visual QA (UI review but no browser)
/review --skip-security     # Skip security review
```

When reviewing a slice from /orchestrate, include the slice context (risk tier, files changed, acceptance criteria).

---

## Reviewers Pipeline

### Always fire (cheap, high-signal)

| Reviewer | What it checks |
|---|---|
| test-reviewer | Test assertions pass, no vague/weak tests |
| quality-reviewer | Code structure, naming, consistency, spec adherence |
| premortem-reviewer | Operational failure modes, edge cases, deployment risks |

### File-signal-gated (expensive, fire only when relevant)

| Reviewer | Trigger | What it checks |
|---|---|---|
| security-reviewer | Auth/session/input/env files | Attack surfaces, validation, data exposure |
| design-reviewer | UI framework detected | Visual consistency, responsiveness |
| visual-qa | UI + interactive keywords | Browser-based functional walkthrough |

---

## Auto-Detection Heuristics

### Step 1 — Determine scope

If no explicit scope is given:
- Run `git merge-base HEAD main` (or `master`) to find the merge base
- Run `git diff --name-only <merge-base>` to get changed files
- If the diff is empty but there are unstaged/staged changes, include those
- If `--full` flag is set, review the entire repo

### Step 2 — Classify changed files

Scan the list of changed files and classify them:

```yaml
always_fire:
  - "*"  # test, quality, and premortem always run

security_triggers:
  pattern: "(auth|session|token|password|api.+\\.env|credentials|sanitize|validate|permission|rbac|oauth|jwt|csrf|xss|sql|injection)"
  packages: ["passport", "bcrypt", "jsonwebtoken", "helmet", "cors"]

design_triggers:
  extensions: [".tsx", ".jsx", ".vue", ".svelte", ".css", ".scss", ".less", ".tailwind"]
  dirs: ["components/", "ui/", "pages/", "screens/", "layouts/", "styles/"]
  packages: ["react", "vue", "svelte", "next", "nuxt", "remix", "gatsby"]

visual_qa_triggers:
  same as design_triggers, plus:
  interactive_keywords: ["click", "submit", "navigate", "form", "modal", "flow", "toggle", "drag", "select", "type", "fill", "upload"]

premortem_triggers:
  # Always fires, but these files amplify the scrutiny
  amplify:
    - "migration"
    - "schema"
    - "queue"
    - "worker"
    - "cron"
    - "webhook"
    - "payment"
    - "transaction"
```

### Step 3 — Build reviewer list

1. Start with the always-fire set: test + quality + premortem
2. Check each gated trigger against the file list and `package.json`/`pyproject.toml`/equivalent
3. If any trigger matches, add that reviewer
4. If `--skip-*` flags are present, remove the corresponding reviewer
5. If `--only-*` flags are present, restrict to only those

---

## Execution

For each selected reviewer, fork a subagent:

```
subagent_fork {
  agent: "<reviewer-agent-name>"
  task: "Review [scope context]. Scope files: [file list]. Write ✅ PASS or ❌ NEEDS-FIX."
  maxTurns: [from guardrail table below]
  maxCost: [from guardrail table]
  maxTokens: [from guardrail table]
  maxTime: [from guardrail table]
}
```

### Guardrail table by reviewer

| Reviewer | maxTurns | maxCost | maxTokens | maxTime |
|---|---|---|---|---|
| test-reviewer | 10 | $0.10 | 50K | 120s |
| quality-reviewer | 10 | $0.10 | 50K | 120s |
| premortem-reviewer | 10 | $0.10 | 50K | 120s |
| security-reviewer | 10 | $0.10 | 50K | 120s |
| design-reviewer | 30 | $0.50 | 150K | 360s |
| visual-qa | 40 | $0.75 | 200K | 480s |

Design-reviewer and visual-qa have higher guardrails because they use playwright-cli (browser rendering, screenshots, multiple viewports).

---

## Output Format

### Summary Card

At the top of the response, produce a summary card:

```
## 📋 Review Summary

**Scope**: [git diff vs specific path vs full]
**Files reviewed**: [N changed]
**Reviewers fired**: test, quality, premortem [+ gated reviewers]

| Reviewer | Verdict |
|---|---|
| test | ✅ PASS |
| quality | ✅ PASS |
| premortem | ✅ PASS |
| [gated] | ✅ PASS / ❌ NEEDS-FIX |

**Blockers**: [N] — ❌ NEEDS-FIX (list reviewer names)
**Advisories**: [N]

**Overall**: ✅ PASS / ❌ BLOCKERS FOUND
```

### Per-Reviewer Reports

After the summary card, include each reviewer's full verdict in a collapsible section:

<details>
<summary><b>test review</b> — ✅ PASS</summary>

[full reviewer output]
</details>

<details>
<summary><b>premortem review</b> — ✅ PASS</summary>

[full reviewer output]
</details>

### `--gate` Flag

When `--gate` is set, append a machine-parseable exit line at the very end:

```
[EXIT: 0]   # all pass
[EXIT: 1]   # at least one blocker
```

---

## Edge Cases

| Situation | Behavior |
|---|---|
| Empty diff (no changes) | Print "Nothing to review." Exit clean. |
| No reviewers match gated triggers | Only fire always-set (test + quality + premortem) |
| --flag conflicts | Explicit flags win over auto-detection |
| Merge-base not found | Fall back to `HEAD~1` |
| No test framework detected | Run quality + premortem, skip test-reviewer |
| No UI framework detected | Skip design-reviewer and visual-qa entirely |
| premortem on migration files | Amplify scrutiny — flag deployment order, rollback, data loss risks |
| Reviewing from /orchestrate slice | Include slice context (risk tier, acceptance criteria) in the task text for each reviewer |

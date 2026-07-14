---
name: test-quality-verifier
description: Audit tests for vague assertions, improve coverage, and produce a structured report. Use when auditing tests for vague assertions, improving coverage, or validating test quality.
allowed-tools: read,write,edit,bash
metadata:
  short-description: Verify and improve test quality
---

# Test Quality Verifier

## Language Definitions

- **Vague assertion** — checks only broad success, existence, truthiness, or absence of failure without distinguishing intended caller-visible behavior from materially wrong alternatives.

## Workflow

1. **Route mode and execution.** Treat requests to audit or validate as audit-only; do not change files. Treat explicit requests to fix, improve, or add tests as improve mode. If edit authorization is ambiguous, remain audit-only and ask before changing files.

   If the harness provides a suitable verifier, delegate with the mode, test scope, configured commands and thresholds, and report contract. A read-only delegate may share the checkout; an editable delegate requires an isolated checkout and exact file scope. Verify returned evidence yourself. If delegation is unavailable or fails, run the same workflow in-process and disclose the fallback.

   Completion criterion: mode, scope, edit authority, and execution route are explicit before the audit begins.

2. **Discover and enumerate.** Identify the test runner and repository conventions from sources such as `package.json`, `pyproject.toml`, `go.mod`, `Makefile`, and CI workflows. Record configured test and coverage commands and thresholds. Enumerate every test in scope; `rg -n "describe\\(|it\\(|test\\(|def test_|func Test" .` is a cross-language starting point, not a substitute for framework-specific discovery.

   Completion criterion: every discovered in-scope test file is accounted for and the command/threshold sources are recorded.

3. **Audit assertions.** Inspect candidate patterns in context rather than treating search matches as automatic findings:
   - JS/TS: lone `.toBeTruthy()`, `.toBeDefined()` without value or shape checks, and literal-equals-literal assertions.
   - Python: `assert True`, bare `assert result` without comparison, and `pass` in tests.
   - Go: tests that only check `err != nil` and never validate returned values.

   A meaningful assertion checks actual values, shapes, error behavior, or another caller-visible outcome that distinguishes the intended behavior from materially wrong alternatives. Completion criterion: each candidate is classified with a concrete reason, and uncovered important branches or error paths are listed.

4. **Establish the baseline.** Run the repository's configured test and coverage commands when present; otherwise use applicable framework defaults such as npm, pytest, or Go test commands. Record the exact commands, results, and coverage source. If coverage cannot be produced, report it as unavailable rather than inventing a number.

   Completion criterion: every runnable in-scope suite has a recorded result, and any skipped or failed command has a stated reason.

5. **Apply the selected mode and verify.** In audit-only mode, make no edits; describe the specific assertion replacements and branch tests needed. In improve mode, change only authorized test files, follow nearby conventions, replace vague assertions with checks on actual values, shapes, and error paths, and add tests for uncovered important branches. Report any finding that cannot be fixed rather than weakening the verdict.

   After improve-mode edits, rerun the affected tests and coverage command. Completion criterion: all authorized edits are accounted for and the post-change command results are recorded; any unresolved finding remains explicit.

6. **Report.** Produce a structured report containing:
   - mode, scope, execution route, and files scanned;
   - vague assertions found and fixed, unresolved findings, and tests added;
   - exact test/coverage commands and results;
   - coverage values when available, their source, and configured or requested thresholds; and
   - `PASS` or `FAIL` with concrete reasons and limitations.

   Return `PASS` only when no vague assertions remain unresolved in scope, all executed tests pass, and every configured or requested coverage requirement is met. A required command that could not run is a `FAIL`; unavailable optional coverage is a reported limitation, not an invented gate.


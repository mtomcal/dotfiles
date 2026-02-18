---
name: test-quality-verifier
description: Audit tests for vague assertions, improve coverage, and produce a structured report. Pairs well with @test-quality-verifier.
compatibility: opencode
metadata:
  short-description: Verify and improve test quality
---

# Test Quality Verifier

Use this skill when you need to validate that tests are meaningful (not just truthy checks), cover important behaviors, and actually fail when the implementation is wrong.

## Quick Use

- If multi-agent is enabled, invoke `@test-quality-verifier` and ask it to audit the current repo's tests and improve them as needed.
- If working solo, follow the workflow below.

## Workflow

1. Identify the test runner and conventions (look for `package.json`, `pyproject.toml`, `go.mod`, `Makefile`, CI workflows).
2. Enumerate tests (`rg -n "describe\(|it\(|test\(|def test_|func Test" .` is a quick start).
3. Find vague assertions:
   - JS/TS: lone `.toBeTruthy()`, `.toBeDefined()` with no value/shape checks; literal==literal asserts.
   - Python: `assert True`, `assert result` with no comparison; `pass` in tests.
   - Go: tests that only check `err != nil` and never validate returned values.
4. Run the repo's existing test/coverage commands if present; otherwise use framework defaults.
5. Replace vague asserts with checks on actual values, shapes, and error paths. Add tests for uncovered branches.
6. Re-run tests/coverage and ensure the report reflects reality.

## Output

Produce a report with:
- Files scanned, vague assertions found/fixed, tests added
- Coverage numbers if available (and where they came from)
- PASS/FAIL with concrete reasons

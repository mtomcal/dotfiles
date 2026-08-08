---
name: python-tracing
description: Trace Python runtime execution to inspect real calls, returns, exceptions, state transitions, and side-effect ordering during correctness review or debugging. Use when static inspection and green tests hide a bug, when you need to prove which call, exception, or write happened first, or to verify a runtime invariant; not for CPU/memory optimization.
metadata:
  short-description: Trace Python runtime for correctness
allowed-tools: read,write,bash
---

# Python Tracing

## Language Definitions

- **Invariant** — the expected call sequence, state transition, or side-effect ordering the trace is run to confirm or falsify.
- **Flow trace** — Hunter record of synchronous Python `call`, `return`, and `exception` events for a narrow target.
- **I/O trace** — `strace` record of kernel file syscalls for a narrow target, used only when write/open ordering evidence is required.
- **Observer effect** — any difference in exit code, stdout/stderr, persisted state, or call count between the untraced baseline and the traced run.
- **Narrow target** — one deterministic script or one selected pytest node, not a whole suite or long-running service.

## Workflow

Gather runtime evidence before theorizing. This skill observes execution; it does not optimize CPU time. Route CPU/memory questions to a sampling profiler instead.

1. **Frame the invariant and the falsifier.** State the expected calls, the state boundary, the allowed transition, and the side effects. State what runtime evidence would falsify it. Read relevant project guidance, proposals, and `UBIQUITOUS-LANGUAGE.md` when present so the invariant uses project terms.

   Completion criterion: the invariant and its falsifier are explicit, and the target is one narrow deterministic script or pytest node.

2. **Check prerequisites and refuse unsafe work.** Confirm Python 3.9+ and `uv`. Obtain user approval before rerunning destructive, production, paid, networked, or irreversible work. Replace real credentials and sensitive data with test fixtures before tracing; Hunter captures argument, return, and exception `repr` strings and cannot redact them before they are written. Capture `git status --short` as a baseline; do not edit source merely to add decorators or logging.

   Refuse and stop when: the target is not narrow or not safely rerunnable; secrets cannot be replaced; or the bug is timing/concurrency-sensitive and tracer overhead may mask or create it (state this rather than guessing).

   Completion criterion: prerequisites confirmed, approval recorded for any non-trivial rerun, secrets replaced or disclosure risk accepted, and repository baseline captured.

3. **Run a baseline.** Run the narrow target once without tracing. Capture exit code, stdout, stderr, and the relevant before/after persisted state (file contents, row counts, directory listings). This is the comparison point for observer effect.

   Completion criterion: baseline exit code, stdout, stderr, and persisted state are recorded.

4. **Trace narrowly with Hunter.** Create a private artifact directory outside every repository, then run Hunter with absolute project path filters, line events excluded, and hard caps. Default to `CodePrinter`, which prints call source, return values, and exception values but not call arguments:

   ```bash
   ART="$TMPDIR/python-runtime-trace/$(basename "$PWD")/$(date -u +%Y%m%dT%H%M%SZ)-flow"
   mkdir -p "$ART" && chmod 700 "$ART" && umask 077
   rm -f "$ART/trace.txt" "$ART/traced.stdout" "$ART/traced.stderr"

   PYTHONHUNTER='Q(filename_startswith="/absolute/path/to/project/"),Q(depth_lt=30),~Q(kind="line"),action=CodePrinter(stream=open("'"$ART"'/trace.txt","a"),force_colors=False,repr_limit=160)' \
     timeout 30s uv run --quiet --with hunter==3.9.0 -- \
     python -m pytest -q -s tests/test_case.py::test_name \
     >"$ART/traced.stdout" 2>"$ART/traced.stderr"
   ```

   Substitute the project target after `--` (`python script.py args` or `python -m pytest ...`). Use an absolute project path in `filename_startswith`. For a single file, use `Q(filename="/absolute/path/to/file.py")`. Never pass a path string directly as `stream=`; Hunter 3.9.0 opens it unbuffered and fails — always use `stream=open(...)`.

   Do **not** add `Q(calls_lt=N)` to bound volume. Hunter's `calls` counter increments for every call event in the process, including calls excluded by your filename filter, so combined with a file filter it stops tracing after the first matching event once the global counter passes `N`. Bound volume with the filename/`depth_lt` filters, the external `timeout`, and by narrowing to one pytest node — not with `calls_lt`.

   To opt into call **arguments** with `CallPrinter` (higher disclosure and volume), replace `action=CodePrinter(...)` with `action=CallPrinter(...)` using the same `stream=` form. Warn the user that arguments may contain secrets before using it.

   Completion criterion: the trace ran once, produced a non-empty `trace.txt` containing the target function or test, and the command and versions are recorded.

5. **Validate observer effect before trusting the trace.** Compare the traced run against the baseline: exit code, stdout, stderr, persisted state, and approximate call count. If anything differs, label the trace invalid and do not reason from it; narrow scope and rerun, or report that tracing perturbs this target.

   Completion criterion: baseline and traced exit/output/state match, or the difference is reported as a trace-invalid finding.

6. **Narrow and rerun, not widen.** If output is too large, filter by function or module (`Q(function="name")` or a tighter `filename_startswith`) and reduce `depth_lt` before raising it. Rely on the external `timeout` as the hard bound. Do not raise limits to silence volume, and never introduce `calls_lt` (see step 4).

   Completion criterion: the trace is small enough to read, or the scope cannot be narrowed further and the limitation is explicitly reported.

7. **Branch: I/O evidence.** Load [I/O Tracing](references/io-tracing.md) when the invariant concerns file or write ordering, atomicity, or which side effect persisted first. It defines the Linux-only `strace` pass, syscall filters, payload suppression, durability caveats, and macOS unavailability. Do not run it for ordinary flow questions.

8. **Branch: concurrency timeline.** Load [Concurrency Fallback](references/concurrency-fallback.md) when the invariant concerns async task scheduling, multi-process merged ordering, or you need machine-queryable JSON rather than text. It defines VizTracer as a secondary view and the `--log_exception` defect that forbids it as a default.

9. **Summarize the invariant from evidence.** Answer the framed invariant using exact trace lines or events, separating observation from inference. State subprocess, thread, async, C-extension, or greenlet coverage limits. State explicitly when evidence is insufficient rather than guessing. Write a short `summary.md` in the artifact directory and report its absolute path. Keep raw artifacts private (mode `0700`); redact known secret patterns only in derived summaries, never claim raw Hunter output is safely redacted.

   Completion criterion: the invariant is answered with cited trace evidence or an explicit insufficient-evidence statement, coverage limits are stated, artifact paths are reported, and `git status --short` matches the baseline.

## Guardrails

- **No source modification to add tracing.** Activate Hunter through `PYTHONHUNTER` with `uv run --with`; do not edit project files to import snoop, add decorators, or insert prints. `snoop` provides no console executable and needs source changes, so do not use it as the primary tracer.
- **Secrets.** Hunter `repr` of arguments, returns, and exceptions can contain tokens, passwords, and PII. `repr_limit` truncates but does not redact. Default to `CodePrinter`; use `CallPrinter` only with explicit user acknowledgement. Redact only in derived summaries.
- **Overhead.** Hunter instruments every Python call and can perturb timing-sensitive or concurrent behavior. Always validate observer effect (step 5) before trusting a trace for a concurrency or timing claim.
- **VizTracer exception mode.** Do not use VizTracer `--log_exception` for correctness: in 1.1.1 it can evaluate a `raise` expression twice. See the Concurrency Fallback reference before using VizTracer at all.
- **I/O durability.** A successful `write` syscall observed under `strace` is not proof of crash durability; only an observed `fsync`/`fdatasync` plus the relevant filesystem/storage guarantees address that. See the I/O Tracing reference.
- **Artifacts.** Write traces and manifests only to a private temporary directory outside every repository unless the user explicitly approves a durable path. Never commit raw traces.

## Reference

- Load [I/O Tracing](references/io-tracing.md) when the invariant concerns file or write ordering, atomicity, or which side effect persisted first; it defines the Linux-only `strace` pass, syscall filters, payload suppression, durability caveats, and macOS unavailability.
- Load [Concurrency Fallback](references/concurrency-fallback.md) when the invariant concerns async task scheduling, multi-process merged ordering, or a machine-queryable JSON timeline is needed; it defines VizTracer as a secondary view and the `--log_exception` defect that forbids it as a default.
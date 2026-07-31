# Concurrency Fallback

Load this reference only when the invariant concerns async task scheduling, multi-process merged ordering, or a machine-queryable JSON timeline is needed. For ordinary synchronous call/return/exception flow, stay on the Hunter flow trace in the main Workflow. VizTracer is a **secondary view**, not the default.

## Why Hunter is not the default here

Hunter uses raw `sys.settrace` semantics. For `asyncio`, a coroutine emits repeated `call`/`return` events at suspension and resumption plus `StopIteration` exceptions, with no task identifier. This is faithful low-level evidence but not a coherent domain-level task-transition model. For async task scheduling or a queryable timeline, VizTracer's structured Chrome Trace Event JSON and `--log_async` task lanes are better.

## VizTracer command

```bash
ART="$TMPDIR/python-runtime-trace/$(basename "$PWD")/$(date -u +%Y%m%dT%H%M%SZ)-viz"
mkdir -p "$ART" && chmod 700 "$ART" && umask 077

uvx --quiet --from viztracer==1.1.1 viztracer --quiet \
  -o "$ART/trace.json" \
  --tracer_entries 100000 \
  --ignore_c_function \
  --log_async \
  -- /absolute/path/to/script.py args
```

Query the JSON:

```bash
python3 -c "import json;d=json.load(open('$ART/trace.json'));print(len(d['traceEvents']))"
rg '"name":.*target_func' "$ART/trace.json"
```

## Forbidden: `--log_exception`

Do not use `--log_exception` for correctness work. In VizTracer 1.1.1 the AST transformer inserts a logging expression before a `raise` and then retains the original `raise`, so `raise Factory(side_effect())` evaluates the exception expression **twice**. In a program ending with `raise SystemExit(main())`, enabling `--log_exception` ran `main()` twice and appended two audit records in the empirical probe. A simple `raise ValueError("once")` shows no visible duplicate side effect, which is why basic tests miss it.

Until an upstream release includes a regression test proving `raise ExceptionFactory(side_effect())` evaluates exactly once, treat `--log_exception` as unsafe for correctness review.

## `--log_audit` caveat

`--log_audit` is advertised to log Python audit events, but in 1.1.1 it records the event name with VizTracer launcher arguments rather than the audit event's own argument tuple. An `open` audit event therefore lacks path and mode evidence. Do not treat `--log_audit` as file-I/O evidence; use the `strace` I/O pass instead.

## Secrets and overhead

- `--log_func_args` and `--log_func_retval` store `repr` strings in `traceEvents[].args` and can leak secrets; docs warn args add very large overhead. Use them only with user acknowledgement.
- The default `tracer_entries` is 1,000,000 (~150 MiB, preallocating ~100 B/entry). Lower it for narrow targets. One tiny pytest node unfiltered produced 22.4 MB / 82,327 events in the probe.
- VizTracer conflicts with other tools using `sys.setprofile` (pre-3.12) or `sys.monitoring` (3.12+).

## Coverage

- asyncio (with `--log_async`), Python threads, `multiprocessing`/`concurrent.futures`, `os.fork`, and `loky>=3.0.0` are supported.
- subprocess support is constrained: VizTracer patches `subprocess.Popen` only when args are a list whose first element starts with `python`.
- On Windows, `multiprocessing.Pool` is not supported.
- `-m pytest` works; `--include_files` can drop events in module mode, so verify the target function appears in `traceEvents` before trusting a filtered run.

## Completion criterion

The concurrency/timeline question is answered from VizTracer JSON with cited events, `--log_exception` was not used, secret-bearing options were acknowledged, and the async/multiprocess coverage limits are stated. If the invariant still needs synchronous call/return/exception values Hunter provides, run both and correlate, noting that VizTracer does not replace Hunter for caught-exception evidence.
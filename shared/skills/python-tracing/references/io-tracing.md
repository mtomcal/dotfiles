# I/O Tracing

Load this reference only when the invariant concerns file or write ordering, atomicity, or which side effect persisted first. It defines the Linux-only `strace` pass. For ordinary call/return/exception flow, stay on the Hunter flow trace in the main Workflow.

## When to use this branch

- Prove a successful write or open happened before a later failed one (false atomicity).
- Prove a directory was or was not created.
- Prove a file was opened with a specific mode or flags.
- Check whether `fsync`/`fdatasync` was called before a crash point.

## Prerequisites and refusal

- **Linux only.** `strace` is Linux-specific. On macOS, report I/O mode unavailable rather than substituting a weaker observer; `dtruss`/DTrace generally have privilege and platform-policy friction.
- The target must be safely rerunnable. This is a second execution; do not run it against destructive, production, paid, networked, or irreversible work without approval.
- Run it as a **separate pass** from the Hunter trace. Tracing Hunter's own output under `strace` creates many irrelevant writes and corrupts the I/O evidence.

## Command

```bash
ART="$TMPDIR/python-runtime-trace/$(basename "$PWD")/$(date -u +%Y%m%dT%H%M%SZ)-io"
mkdir -p "$ART" && chmod 700 "$ART" && umask 077

strace -f -qq -ttt -yy -s 0 \
  -e trace=%file,write,close,fsync,fdatasync \
  -o "$ART/io.strace" \
  python /absolute/path/to/script.py args \
  >"$ART/io.stdout" 2>"$ART/io.stderr"
```

Inspect with `rg` or `grep`:

```bash
rg '/path/to/artifact-dir|ENOENT|EACCES|write\(' "$ART/io.strace"
```

## Reading the output

Each line is a syscall with decoded file descriptor paths, flags, byte counts, and errno. A representative shape:

```text
openat(..., "/tmp/run/audit.jsonl", O_WRONLY|O_CREAT|O_APPEND|..., 0666) = 3</tmp/run/audit.jsonl>
write(3</tmp/run/audit.jsonl>, ""..., 43) = 43
openat(..., "/tmp/run/missing/item-7.json", O_WRONLY|O_CREAT|O_TRUNC|..., 0666) = -1 ENOENT (No such file or directory)
```

This establishes a successful 43-byte write before the failed second open. Correlate open/write/close ordering with the Hunter call sequence from the flow trace.

## Volume and disclosure controls

- **`-s 0` suppresses string-buffer contents** while preserving path arguments, byte counts, descriptors, timestamps, and errno. This is the default; never use `-e read=` or `-e write=` payload dumps for correctness review.
- `-s 0` does **not** make output safe: file paths, sizes, and flags can themselves be sensitive. Keep artifacts private (mode `0700`) and redact only in derived summaries.
- `-f` follows child processes created by `fork`/`vfork`/`clone`. Use it when the target spawns subprocesses.
- `-e trace=%file,write,close,fsync,fdatasync` limits noise. Add `rename`, `unlink`, `mkdir`, `rmdir` if the invariant concerns those operations. Use `--trace=%file` as a shorthand for all filename-taking syscalls.
- `-P /path` traces only syscalls accessing a specific path, but in the probe it filtered out `write` to that path because `-P` matches path arguments, not fd targets; prefer the syscall-set filter plus `rg` for reliability.

## Durability caveat

A successful `write` returning a byte count means the kernel accepted the data, not that it reached stable storage. Only an observed `fsync`/`fdatasync` (and knowledge of the filesystem/storage guarantees) supports a crash-durability claim. Do not assert atomicity or durability from a `write` alone.

## Limitations

- `strace` records kernel syscalls, not logical Python operations. It will not name the Python function that issued a write; correlate with the Hunter flow trace for that.
- It does not observe in-memory state changes or pure computation.
- Version: the empirical host had strace 6.8; the command above uses options present there. `strace` 6.16 (2025-08-05) is current as of 2026-07-24.

## Completion criterion

The I/O ordering question is answered with cited `strace` lines, the durability caveat is stated when relevant, artifacts are private, and the separate-pass constraint was observed.
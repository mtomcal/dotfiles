---
name: playwright
description: Automate browser interactions, scripted capture, and Playwright test workflows. Use when the task specifically calls for Playwright, deterministic browser automation, Playwright recordings, or working inside an existing Playwright test setup.
allowed-tools: Bash(playwright-cli:*) Bash(npx:*) Bash(npm:*)
metadata:
  short-description: Playwright usage and browser automation
---

# Playwright

## Language Definitions

- **Browser session** — CLI-managed browser instance and state addressed by a session name until closed.
- **Snapshot** — structured page representation used for inspection and element discovery.
- **Element ref** — ephemeral, session-specific target derived from a snapshot.
- **Persistent profile** — on-disk browser state that survives restarts, unlike the default in-memory state.
- **Storage state** — serialized authentication and application state that may contain credentials and is sensitive.

## Workflow

1. **Route the task before acting.** Use `visual-qa` when the task is pass/fail visual review. Playwright owns browser interaction and capture; the caller retains the scenario and acceptance decision. Use `video-to-contact-sheet` after capture when a Playwright recording needs trimming or frame-sampled evidence. For an existing Playwright test setup, load the test Reference below before running or debugging tests. For a specialized command family, load only its matching Reference below. Check `playwright-cli --help <command>` against the installed executable before relying on static syntax.

2. **Run one minimal browser scenario.** First confirm the CLI. Prefer the global executable; if it is unavailable, try the project-local package. Stop after the first successful version check and use that invocation consistently:

```bash
playwright-cli --version
npx --no-install playwright-cli --version
```

If neither exists and installation is within scope, recover with:

```bash
npm install -g @playwright/cli@latest
```

Examples below use `playwright-cli`; substitute `npx --no-install playwright-cli` when that was the successful check.

Run one minimal open → snapshot → interact → verify/capture → close sequence:

```bash
playwright-cli open https://example.com
playwright-cli snapshot
# Choose an interactive element ref from this session's current snapshot.
playwright-cli click e6
# Refresh the snapshot after navigation or a material page-state change.
playwright-cli snapshot --filename=after-click.md
# Capture pixels only when the task needs them.
playwright-cli screenshot --filename=evidence.png
playwright-cli close
```

Snapshots are the normal inspection surface. Use a ref only with the browser session and page state that produced it; take a fresh snapshot before targeting after navigation or material state changes. For another interaction, navigation, tab, PDF, console, or capture form, inspect installed per-command help rather than guessing. Put the global `--raw` option before a command only when piping its result without page status, generated code, or snapshot sections; commands with no result still return nothing.

If browser launch fails because native shared libraries are missing, try an installed system-browser channel before installing dependencies, for example `playwright-cli open https://example.com --browser=chrome`. For a raw Node Playwright script, use the installed browser's explicit `executablePath`; in a container, add conservative `--no-sandbox` and `--disable-dev-shm-usage` launch flags only when the environment requires them. Use `npx playwright install-deps` only if no system browser works, and obtain user approval before running it because it may request sudo privileges.

Always close every browser session started by the task, including on failure. Stop background test runs after debugging. Use `close-all` only when every affected session is task-owned, and reserve `kill-all` for stale or zombie task-owned processes. Delete task-created persistent profile data when it is no longer needed. Keep requested snapshots, screenshots, PDFs, traces, WebM recordings, generated TypeScript, raw values, storage JSON, and test results; report their paths and remove incidental captures.

Treat persistent profiles and storage-state files as sensitive. Never commit storage state or other authentication artifacts, delete them after use unless the user requested retention, and pass secrets through environment variables rather than embedding them in commands or generated code.

Completion criterion: the requested browser behavior is verified from a fresh snapshot, test result, or requested capture; output paths are reported; all task-owned browser/debug processes are stopped; and no unapproved privileged install or sensitive state remains.

## Reference

- Load [Running Playwright Tests](references/playwright-tests.md) when running or debugging an existing Playwright suite; it defines noninteractive reporting, background debug attachment, generated-code use, rerun, and cleanup.
- Load [Request Inspection and Mocking](references/request-mocking.md) when inspecting, mocking, modifying, delaying, or blocking requests; it owns the tested `requests`/`request` and route command families.
- Load [Running Custom Playwright Code](references/running-code.md) when CLI commands cannot express the scenario or code must run from a file; it defines `run-code`, permissions, waits, frames, downloads, and error handling.
- Load [Browser Session Management](references/session-management.md) when using named, parallel, configured, attached, headed, or persistent browser sessions; it defines isolation, profile selection, and scoped cleanup.
- Load [Storage Management](references/storage-state.md) when saving/loading authentication state or manipulating cookies, localStorage, sessionStorage, or IndexedDB; it defines the detailed commands and sensitive-file handling.
- Load [Test Generation](references/test-generation.md) when transferring CLI-generated TypeScript into a test; it explains locator choice and the required manual assertions.
- Load [Tracing](references/tracing.md) when a trace is required for debugging or evidence; it defines capture contents, overhead, limitations, and cleanup.
- Load [Video Recording](references/video-recording.md) when producing a Playwright WebM or annotated hero script; it defines recording, chapters, overlays, file execution, overhead, and cleanup.
- Load [Inspecting Element Attributes](references/element-attributes.md) when a snapshot omits an element property needed for targeting or verification; it defines scoped `eval` inspection.

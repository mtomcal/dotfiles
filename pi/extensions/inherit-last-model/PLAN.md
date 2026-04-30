# Inherit Last Model Extension — Plan

## Problem

When a user runs `/new` inside pi, the new session falls back to `settings.defaultProvider` / `settings.defaultModel` instead of carrying over the model from the previous session. This is jarring when you've been working with a different model (e.g., deepseek) and `/new` reverts to your configured default (e.g., kimi).

**Source — model resolution chain on `/new`:**

1. `handleClearCommand()` → `runtimeHost.newSession()` — no options passed
   - `/Users/mtomcal/Code/pi-mono/packages/coding-agent/src/modes/interactive/interactive-mode.ts:5262-5264`
2. `AgentSessionRuntime.newSession()` creates fresh `SessionManager`, then calls `createRuntime()`
   - `/Users/mtomcal/Code/pi-mono/packages/coding-agent/src/core/agent-session-runtime.ts:224-239`
3. `buildSessionOptions()` attempts to resolve model from CLI args, scoped models, or settings defaults
   - `/Users/mtomcal/Code/pi-mono/packages/coding-agent/src/main.ts:287-366`
   - Key guard: `if (!options.model && scopedModels.length > 0 && !hasExistingSession)` at line 317
4. `createAgentSession()` falls to `findInitialModel()` which reads `settingsManager.getDefaultProvider()` / `getDefaultModel()`
   - `/Users/mtomcal/Code/pi-mono/packages/coding-agent/src/core/sdk.ts:221-228`
   - `/Users/mtomcal/Code/pi-mono/packages/coding-agent/src/core/model-resolver.ts:256-262` — step 3 in the priority chain
5. `setModel()` calls `settingsManager.setDefaultModelAndProvider()` to persist
   - `/Users/mtomcal/Code/pi-mono/packages/coding-agent/src/core/agent-session.ts:1400`
   - `/Users/mtomcal/Code/pi-mono/packages/coding-agent/src/core/settings-manager.ts:605-612` — writes async via `enqueueWrite`

## Approach

A temp-file bridge that survives extension reloads across session boundaries. The extension uses two hooks on the old instance (write) and one hook on the new instance (read).

**Source — lifecycle docs:**
- `/Users/mtomcal/Code/pi-mono/packages/coding-agent/docs/extensions.md:303-310` — the exact `/new` lifecycle diagram
- `/Users/mtomcal/Code/pi-mono/packages/coding-agent/docs/extensions.md:367-384` — `session_start` / `session_before_switch` docs
- `/Users/mtomcal/Code/pi-mono/packages/coding-agent/docs/extensions.md:617-626` — `model_select` event docs
- `/Users/mtomcal/Code/pi-mono/packages/coding-agent/src/core/extensions/types.ts:369-374` — `ReplacedSessionContext` extends `ExtensionCommandContext`

## Hooks & Lifecycle

```
Previous session           │  New session
                           │
model_select ──► write     │  (every model change = always current)
                           │
/before_switch (new) ──► write │  (safety net, ctx.model available)
                           │
      session_shutdown     │
      extensions reload    │
                           │  session_start (new) ──► read → pi.setModel()
```

**Source — why old instance is torn down:**
- `/Users/mtomcal/Code/pi-mono/packages/coding-agent/docs/extensions.md:382-384`:
  > "After a successful switch... pi emits `session_shutdown` for the old extension instance, reloads and rebinds extensions for the new session, then emits `session_start`."

**Source — why we need a temp file (not in-memory):**
- Old extension instance is disposed → all in-memory state lost
- New extension instance starts fresh → must read persisted state
- `/Users/mtomcal/Code/pi-mono/packages/coding-agent/docs/extensions.md:1087-1097` — the footguns section about stale closures after session replacement

## Decisions (grill outcomes)

| # | Question | Decision | Source |
|---|----------|----------|--------|
| Q1 | Which hook? | `session_before_switch` for write, `session_start` for read | Lifecycle diagram + footgun docs (see above) |
| Q2 | Persistence across reload? | Temp file bridge (Approach B) | Extensions are torn down and reloaded between sessions — memory doesn't survive |
| Q3 | No model selected? | Skip write, fall through to pi defaults | `ctx.model` can be undefined if pi started without a valid model (`/Users/mtomcal/Code/pi-mono/packages/coding-agent/src/core/extensions/types.ts:173`) |
| Q4 | Robustness? | Also write on `model_select` so file is always current | Covers crashes before `/new` — any model change records immediately |
| Q5 | Resume/fork too? | No — pi already restores model from session context | `/Users/mtomcal/Code/pi-mono/packages/coding-agent/src/core/sdk.ts:205-216` — `existingSession.model` is read from session entries |
| Q6 | Temp file location? | `~/.pi/agent/.last-model.json` (via `getAgentDir()`) | `/Users/mtomcal/Code/pi-mono/packages/coding-agent/src/config.ts:327-335` — `getAgentDir()` returns `~/.pi/agent` |
| Q7 | Silent on failure? | Yes — no notifications, let pi handle fallback | `pi.setModel()` signature: `Promise<boolean>` (`/Users/mtomcal/Code/pi-mono/packages/coding-agent/src/core/extensions/types.ts:1212`). Returns `false` if no auth (`/Users/mtomcal/Code/pi-mono/packages/coding-agent/src/core/agent-session.ts:2184`). |

## File Format

```json
{ "provider": "deepseek", "modelId": "deepseek-v4-pro" }
```

Matches `modelRegistry.find(provider, modelId)` signature:
- `/Users/mtomcal/Code/pi-mono/packages/coding-agent/src/core/model-registry.ts:614-615` — `find(provider, modelId): Model<Api> | undefined`

## Extension API Surface Used

| API | Signature | Source |
|-----|-----------|--------|
| `pi.on("model_select", ...)` | `event: { model, previousModel, source }` | `/Users/mtomcal/Code/pi-mono/packages/coding-agent/docs/extensions.md:617-626` |
| `pi.on("session_before_switch", ...)` | `event: { reason: "new" \| "resume" }, ctx: ExtensionContext` | `/Users/mtomcal/Code/pi-mono/packages/coding-agent/docs/extensions.md:367-380`, `types.ts:339-342` |
| `pi.on("session_start", ...)` | `event: { reason, previousSessionFile? }, ctx: ExtensionContext` | `/Users/mtomcal/Code/pi-mono/packages/coding-agent/docs/extensions.md:355-362`, `types.ts:332-337` |
| `pi.setModel(model)` | `Promise<boolean>` | `types.ts:1212`, `agent-session.ts:2183-2187` |
| `ctx.model` | `Model<Api> \| undefined` | `types.ts:173` |
| `ctx.modelRegistry.find(provider, modelId)` | `Model<Api> \| undefined` | `model-registry.ts:614-615` |
| `getAgentDir()` | `string` | `config.ts:327-335`, re-exported from SDK `index.ts:4` |

*(Unprefixed paths are relative to `/Users/mtomcal/Code/pi-mono/packages/coding-agent/src/core/extensions/`)*

## Edge Cases Handled

- **No model yet** (`ctx.model` undefined): skip write → pi defaults apply
- **Model removed from models.json**: `ctx.modelRegistry.find()` returns undefined → skip restore
- **Auth lost for the model**: `pi.setModel()` returns `false` → skip silently
- **File missing**: First run, no prior session → skip restore
- **Corrupt temp file**: JSON parse failure → skip restore
- **Crash before `/new`**: `model_select` hook wrote the temp file → still works
- **Model changed then `/new` immediately**: `session_before_switch` fires synchronously during user action handler — write completes before extension reload begins

## Implementation

Single file: `~/.pi/agent/extensions/inherit-last-model/index.ts`

Three small functions:
1. `getLastModelPath()` — `join(getAgentDir(), "last-model.json")`
2. `writeLastModel(model)` — `writeFileSync(path, JSON.stringify({ provider, modelId }))`
3. `readLastModel()` — `existsSync` guard, `JSON.parse(readFileSync(...))`

Three hook registrations inside `export default function(pi)`:
- `pi.on("model_select", (event) => writeLastModel(event.model))`
- `pi.on("session_before_switch", (event, ctx) => { if (reason === "new" && ctx.model) writeLastModel(ctx.model) })`
- `pi.on("session_start", async (event, ctx) => { if (reason === "new") { read → find → await pi.setModel(model) } })`

**Reference — pattern established by existing extensions:**
- `/Users/mtomcal/Code/pi-mono/packages/coding-agent/examples/extensions/preset.ts` — saves/restores model state across sessions using `appendEntry` + `session_start`
- `/Users/mtomcal/Code/pi-mono/packages/coding-agent/examples/extensions/handoff.ts` — uses `session_start` + `withSession` pattern for post-replacement work

## Installation

```bash
# No npm install needed — pure SDK APIs only, no external dependencies
mkdir -p ~/.pi/agent/extensions/inherit-last-model
# copy index.ts there — pi picks it up on next start
# (no config change needed, extension directory is auto-discovered)
```

Source — extension auto-discovery:
- `/Users/mtomcal/Code/pi-mono/packages/coding-agent/docs/extensions.md` — extensions in `~/.pi/agent/extensions/` are auto-loaded

Since the user's dotfiles already symlink `~/.pi/agent/extensions/` → `~/dotfiles/pi/extensions/`:

```bash
# Just create the file in dotfiles — symlink is already in place
~/dotfiles/pi/extensions/inherit-last-model/index.ts
# pi picks it up on next start
```

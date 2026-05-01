# Ad-Hoc Subagent Extension — Implementation Plan

> **Status: PLANNING** — 18 design decisions resolved. Ready for TDD implementation.

Red/green TDD. Write the test first (red), make it pass (green), then refactor. Each section is a TDD cycle. Run tests after every green step to ensure nothing regresses.

## Design Decisions (Resolved)

| # | Decision | Choice |
|---|----------|--------|
| 1 | Mental model | Tasks with config (not agents) |
| 2 | systemPrompt priority | Replace agent preset. Consistent overrides for all fields |
| 3 | Minimum required | Just task (bare-task = isolated context pattern) |
| 4 | LLM guidance | Frame primary path, bare task documented as specific use case |
| 5 | Model shorthand | Allowed but not advertised in descriptions |
| 6 | Default tools | All tools, description nudges toward scoping |
| 7 | Per-item config | Full config on each tasks[]/chain[] item |
| 8 | Naming | `agent` → `name`, label-only, no lookup |
| 9 | Agent files | Dead. Skills teach. Pure LLM instructions |
| 10 | agents.ts | → `subagent-config.ts` (keep parseModelField, normalizeOptional, new SubagentConfig) |
| 11 | Bare-task identity | Full injection with judgment clause |
| 12 | Default name | Auto-derive from task text, fallback "task" |
| 13 | Context files | New `contextFiles` param, default true |
| 14 | Skill creation | `create-subagent-skill` skill, specializes `write-a-skill` |
| 15 | Extensions | New `extensions` param, default false |
| 16 | Skills in subagents | Strip by default (`--no-skills`) |
| 17 | Session persistence | Keep `--no-session` fixed |
| 18 | agentSource | Kill from SingleResult and rendering |

## Reviewer Findings (Addressed)

A pre-implementation review identified 6 critical, 9 warning, and 7 minor findings.
All critical and warning items are addressed inline below. Key fixes:

| Finding | Severity | Fix |
|---------|----------|-----|
| `SubagentDetails` retains `agentScope`/`projectAgentsDir` | Critical | Cycle 4+8: explicitly remove from interface |
| No backward-compat deserialization for `agent` → `name` | Critical | Cycle 2: `d.name ?? (d as any).agent ?? "unknown"` guard |
| Shorthand provider lost when per-item model replaces top-level | Critical | Cycle 1: fallback parse of topLevel.model shorthand |
| `--thinking medium` suppression logic untested | Critical | Cycle 3: add test for medium → no flag emitted |
| `deriveName` can produce leading-hyphen names | Critical | Cycle 1: sanitize leading non-alpha, add test |
| Restored "running" jobs must stay cancelled in deserialize | Critical | Cycle 2: explicit test + guard preserved |
| Fork schema not defined | Warning | Added ForkParams schema below |
| `parseTools` has no tests | Warning | Cycle 1: added parseTools tests |
| `cwd` not tested in spawn | Warning | Cycle 3: added cwd spawn test |
| Empty tasks array not tested | Warning | Cycle 4: added empty-array test |
| Chain {previous} with empty output untested | Warning | Cycle 4: added empty-chain-output test |
| `Task:` prefix may conflict | Warning | Cycle 3: noted, verified Pi parses it correctly |
| Cycle 9 tests are structural not behavioral | Warning | Added post-Cycle-9 integration re-run step |
| No real subprocess e2e test | Warning | Added manual QA step after Cycle 12 |

---

## Architecture Overview

**Six tools** — same names, new internals:

| Tool | Purpose | Returns |
|------|---------|---------|
| `subagent_run` | Blocking — single, parallel, chain | Full result |
| `subagent_fork` | Async — start background job(s) | Job ID + summary |
| `subagent_status` | Check job status / list all | Lightweight summaries |
| `subagent_results` | Get full output of a job | All messages + usage |
| `subagent_wait` | Block until job completes | Full result |
| `subagent_cancel` | Cancel one or all jobs | Confirmation |

**What changed from previous version:**
- ❌ No agent `.md` file discovery (`discoverAgents`, `AgentScope`, `confirmProjectAgents`)
- ❌ No `agent` parameter (renamed to `name`, label-only)
- ❌ No `agentSource` on results
- ❌ No `agentScope` or `projectAgentsDir` on `SubagentDetails`
- ❌ No `agents.ts` module
- ✅ New ad-hoc parameters: `systemPrompt`, `tools`, `model`, `name`
- ✅ New runtime params: `contextFiles`, `extensions`
- ✅ New `subagent-config.ts` module (stripped-down config resolution)
- ✅ Bare-task pattern with identity injection
- ✅ Auto-derived names from task text
- ✅ Child processes get `--no-skills` by default

**Key invariants (unchanged):**
- Max 8 concurrent async jobs
- Job ID format: `{name}-{6hex}`
- Fork always returns immediately
- Completion notifications via `pi.sendMessage()` with `deliverAs: "steer"`
- Running jobs killed on `session_shutdown`

**CLI flags for child processes:**
```
pi --mode json -p --no-session --no-skills
   [--provider <p>] [--model <m>] [--thinking <t>] [--tools <t1,t2>]
   [--no-context-files]           # when contextFiles=false
   [--no-extensions]              # when extensions=false (default)
   [--append-system-prompt <file>] # when systemPrompt provided
   Task: <task>
```

**Bare-task injection (when no systemPrompt):**
> "You are a subagent operating in an isolated context. Complete your task autonomously. Return a clear, self-contained result. Your output will be read by another agent — be concise and structured. If you encounter ambiguity, make your best judgment rather than asking questions."

---

## New Schema Definitions

### Per-Item Config (tasks[], chain[], fork items)

```ts
const ItemConfig = {
  name: Type.Optional(Type.String({ description: "Display label for this subagent. Auto-derived from task text if omitted." })),
  task: Type.String({ description: "Task to delegate to the subagent" }),
  systemPrompt: Type.Optional(Type.String({ description: "System prompt — defines the subagent's role and behavior" })),
  tools: Type.Optional(Type.String({ description: "Comma-separated tool allowlist (e.g. 'read,write,bash'). Omit for all default tools." })),
  model: Type.Optional(Type.String({ description: "Model ID or pattern (e.g. 'claude-sonnet-4-5', 'anthropic/claude-sonnet-4-5')" })),
  provider: Type.Optional(Type.String({ description: "Provider override" })),
  thinking: Type.Optional(StringEnum(["off","minimal","low","medium","high","xhigh"])),
  cwd: Type.Optional(Type.String({ description: "Working directory for the subagent process" })),
  contextFiles: Type.Optional(Type.Boolean({ description: "Load project context files (AGENTS.md etc). Default: true." })),
  extensions: Type.Optional(Type.Boolean({ description: "Load extensions in subagent. Default: false." })),
};
```

### Top-Level Config — subagent_run

```ts
const RunParams = {
  name: Type.Optional(Type.String({ description: "Display label. Auto-derived from task text if omitted." })),
  task: Type.Optional(Type.String({ description: "Task to delegate (single mode)" })),
  systemPrompt: Type.Optional(Type.String({ description: "System prompt — defines the subagent's role and behavior" })),
  tools: Type.Optional(Type.String({ description: "Comma-separated tool allowlist. Omit for all default tools." })),
  model: Type.Optional(Type.String({ description: "Model ID or pattern" })),
  provider: Type.Optional(Type.String({ description: "Provider override" })),
  thinking: Type.Optional(StringEnum(["off","minimal","low","medium","high","xhigh"])),
  cwd: Type.Optional(Type.String({ description: "Working directory for the subagent process" })),
  contextFiles: Type.Optional(Type.Boolean({ description: "Load project context files (AGENTS.md etc). Default: true.", default: true })),
  extensions: Type.Optional(Type.Boolean({ description: "Load extensions in subagent. Default: false.", default: false })),
  // Mode-specific:
  tasks: Type.Optional(Type.Array(ItemConfig, { description: "Array of items for parallel execution" })),
  chain: Type.Optional(Type.Array(ItemConfig, { description: "Array of items for sequential execution with {previous}" })),
};
```

### Top-Level Config — subagent_fork

```ts
const ForkParams = {
  name: Type.Optional(Type.String({ description: "Display label. Auto-derived from task text if omitted." })),
  task: Type.Optional(Type.String({ description: "Task to delegate (single mode)" })),
  systemPrompt: Type.Optional(Type.String({ description: "System prompt — defines the subagent's role and behavior" })),
  tools: Type.Optional(Type.String({ description: "Comma-separated tool allowlist. Omit for all default tools." })),
  model: Type.Optional(Type.String({ description: "Model ID or pattern" })),
  provider: Type.Optional(Type.String({ description: "Provider override" })),
  thinking: Type.Optional(StringEnum(["off","minimal","low","medium","high","xhigh"])),
  cwd: Type.Optional(Type.String({ description: "Working directory for the subagent process" })),
  contextFiles: Type.Optional(Type.Boolean({ description: "Load project context files. Default: true.", default: true })),
  extensions: Type.Optional(Type.Boolean({ description: "Load extensions in subagent. Default: false.", default: false })),
  // Fork mode — parallel only (no chain):
  tasks: Type.Optional(Type.Array(ItemConfig, { description: "Array of items for parallel fork" })),
};
```

> **Note**: `subagent_fork` has `tasks[]` but no `chain[]`. `subagent_run` has both.

### Config Resolution Order

For every configurable field, resolution is:

```
per-item value > top-level value > default
```

No agent preset layer — it's gone. The chain is simple.

**Shorthand provider fallback**: When a per-item `model` field lacks a shorthand
provider (e.g. bare `"claude-sonnet-4-5"`) but the top-level `model` has one
(e.g. `"anthropic/claude-sonnet-4-5"`), the top-level model's shorthand provider
is *not* automatically inherited. This is a deliberate restriction: per-item model
fully replaces the top-level model string. If you want the provider, specify it
explicitly via `provider` on the item or inherit from a top-level `provider` param.
This avoids ambiguous composition of shorthand components across priority levels.

For `model` with shorthand `provider/model:thinking`:
- Parse shorthand components from `model` string
- Explicit `provider` param overrides shorthand provider
- Explicit `thinking` param overrides shorthand thinking
- Shorthand is allowed but not advertised

---

## File Structure

```
pi/extensions/subagent/
├── PLAN.md                # This file
├── index.ts               # Extension entry point, registers all 6 tools
├── subagent-config.ts     # Config types, resolution, parseModelField, normalizeOptional, deriveName
├── job-manager.ts         # AsyncJob state management (mostly unchanged)
├── renderers.ts           # Shared rendering helpers (updated: remove agentSource, agentScope, projectAgentsDir)
├── tests/
│   ├── helpers.ts          # Shared test utilities
│   ├── extension-helpers.ts # Extension setup/test harness
│   ├── subagent-config.test.ts    # NEW: config resolution, deriveName
│   ├── job-manager.test.ts        # Mostly unchanged
│   ├── subagent-run.test.ts       # Updated: ad-hoc params
│   ├── subagent-fork.test.ts      # Updated: ad-hoc params
│   ├── subagent-fork-parallel.test.ts
│   ├── subagent-status.test.ts
│   ├── subagent-results.test.ts
│   ├── subagent-wait.test.ts
│   ├── subagent-cancel.test.ts
│   ├── notification.test.ts
│   ├── notification-renderer.test.ts
│   ├── rendering.test.ts
│   ├── lifecycle.test.ts
│   ├── integration.test.ts
│   ├── tool-registration.test.ts
│   └── cleanup.test.ts
└── package.json
```

**Deleted files:**
- `agents.ts` — replaced by `subagent-config.ts`

---

## Cycle 1: subagent-config.ts — Config Types and Resolution

The new module. Pure TypeScript, no Pi extension dependency.

### Red: Write failing tests

```typescript
// tests/subagent-config.test.ts

describe("subagent-config", () => {
  describe("resolveConfig", () => {
    test("bare task returns defaults with identity injection", () => {
      const config = resolveConfig({ task: "Review the auth module" });
      expect(config.name).toBe("review"); // auto-derived
      expect(config.systemPrompt).toContain("subagent");
      expect(config.systemPrompt).toContain("best judgment");
      expect(config.tools).toBeUndefined(); // all tools = no --tools flag
      expect(config.model).toBeUndefined();
      expect(config.provider).toBeUndefined();
      expect(config.thinking).toBe("medium");
      expect(config.contextFiles).toBe(true);
      expect(config.extensions).toBe(false);
    });

    test("systemPrompt replaces injected identity", () => {
      const config = resolveConfig({
        task: "Review auth",
        systemPrompt: "You are a security auditor.",
      });
      expect(config.systemPrompt).toBe("You are a security auditor.");
      expect(config.systemPrompt).not.toContain("subagent operating");
    });

    test("name defaults to auto-derived from task", () => {
      expect(resolveConfig({ task: "Fix the login bug" }).name).toBe("fix");
      expect(resolveConfig({ task: "Implement the feature" }).name).toBe("implement");
    });

    test("explicit name overrides auto-derive", () => {
      const config = resolveConfig({ task: "Fix bug", name: "bugfixer" });
      expect(config.name).toBe("bugfixer");
    });

    test("short task word falls back to 'task'", () => {
      expect(resolveConfig({ task: "Do the thing" }).name).toBe("task");
      expect(resolveConfig({ task: "" }).name).toBe("task");
    });

    test("model shorthand parses provider and thinking", () => {
      const config = resolveConfig({
        task: "Plan",
        model: "anthropic/claude-sonnet-4-5:high",
      });
      expect(config.model).toBe("claude-sonnet-4-5");
      expect(config.provider).toBe("anthropic");
      expect(config.thinking).toBe("high");
    });

    test("explicit provider overrides shorthand provider", () => {
      const config = resolveConfig({
        task: "Plan",
        model: "anthropic/claude-sonnet-4-5",
        provider: "openai",
      });
      expect(config.provider).toBe("openai");
      expect(config.model).toBe("claude-sonnet-4-5");
    });

    test("explicit thinking overrides shorthand thinking", () => {
      const config = resolveConfig({
        task: "Plan",
        model: "anthropic/claude-sonnet-4-5:high",
        thinking: "low",
      });
      expect(config.thinking).toBe("low");
    });

    test("per-item values override top-level", () => {
      const config = resolveConfig(
        { task: "Plan", provider: "google", thinking: "high", model: "gemini-2.5-pro" },
        { provider: "anthropic", thinking: "low", model: "claude-sonnet-4-5" },
      );
      expect(config.provider).toBe("google");
      expect(config.thinking).toBe("high");
      expect(config.model).toBe("gemini-2.5-pro");
    });

    test("top-level values fill in when per-item omitted", () => {
      const config = resolveConfig(
        { task: "Plan" },
        { provider: "anthropic", thinking: "high" },
      );
      expect(config.provider).toBe("anthropic");
      expect(config.thinking).toBe("high");
    });

    test("tools string parses to array", () => {
      const config = resolveConfig({ task: "Look", tools: "read, grep, bash" });
      expect(config.tools).toEqual(["read", "grep", "bash"]);
    });

    test("tools omitted = undefined (all tools)", () => {
      const config = resolveConfig({ task: "Look" });
      expect(config.tools).toBeUndefined();
    });

    test("contextFiles defaults to true", () => {
      expect(resolveConfig({ task: "Do it" }).contextFiles).toBe(true);
    });

    test("extensions defaults to false", () => {
      expect(resolveConfig({ task: "Do it" }).extensions).toBe(false);
    });
  });

  describe("deriveName", () => {
    test("extracts first significant word from task", () => {
      expect(deriveName("Review the auth module")).toBe("review");
      expect(deriveName("Fix the login bug")).toBe("fix");
    });

    test("lowercases", () => {
      expect(deriveName("IMPLEMENT the feature")).toBe("implement");
    });

    test("preserves hyphens within words", () => {
      expect(deriveName("auto-fix the bug")).toBe("auto-fix");
    });

    test("strips leading non-alpha chars to avoid hyphen-prefixed job IDs", () => {
      // "-fix" → "fix" (strip leading hyphen)
      expect(deriveName("-fix the bug")).toBe("fix");
      // "#review" → "review" (strip leading #)
      expect(deriveName("#review the code")).toBe("review");
    });

    test("returns 'task' for empty input", () => {
      expect(deriveName("")).toBe("task");
      expect(deriveName("   ")).toBe("task");
    });

    test("returns 'task' for short words", () => {
      expect(deriveName("Do the thing")).toBe("task");
      expect(deriveName("Go fix it")).toBe("task");
    });

    test("returns 'task' when first word becomes empty after stripping", () => {
      expect(deriveName("--- the task")).toBe("task");
    });

    test("truncates long derived names", () => {
      expect(deriveName("comprehensive-architectural-review of the system").length).toBeLessThanOrEqual(20);
    });
  });

  describe("parseTools", () => {
    test("parses comma-separated tools", () => {
      expect(parseTools("read, grep, bash")).toEqual(["read", "grep", "bash"]);
    });

    test("single tool", () => {
      expect(parseTools("read")).toEqual(["read"]);
    });

    test("empty string returns empty array", () => {
      expect(parseTools("")).toEqual([]);
    });

    test("handles extra whitespace and empty elements", () => {
      expect(parseTools("read, , grep")).toEqual(["read", "grep"]);
    });
  });

  describe("parseModelField", () => {
    test("parses provider/model:thinking", () => {
      const result = parseModelField("anthropic/claude-sonnet-4-5:high");
      expect(result.provider).toBe("anthropic");
      expect(result.model).toBe("claude-sonnet-4-5");
      expect(result.thinking).toBe("high");
    });

    test("parses model:thinking without provider", () => {
      const result = parseModelField("claude-sonnet-4-5:high");
      expect(result.provider).toBeUndefined();
      expect(result.model).toBe("claude-sonnet-4-5");
      expect(result.thinking).toBe("high");
    });

    test("parses provider/model without thinking", () => {
      const result = parseModelField("anthropic/claude-sonnet-4-5");
      expect(result.provider).toBe("anthropic");
      expect(result.model).toBe("claude-sonnet-4-5");
      expect(result.thinking).toBeUndefined();
    });

    test("bare model id", () => {
      const result = parseModelField("claude-sonnet-4-5");
      expect(result.provider).toBeUndefined();
      expect(result.model).toBe("claude-sonnet-4-5");
      expect(result.thinking).toBeUndefined();
    });

    test("invalid thinking suffix is not parsed", () => {
      const result = parseModelField("my-model:speed");
      expect(result.model).toBe("my-model");
      expect(result.thinking).toBeUndefined();
    });
  });
});
```

### Green: Implement subagent-config.ts

```typescript
// subagent-config.ts

import type { ThinkingLevel } from "@mariozechner/pi-agent-core";

export interface SubagentConfig {
  name: string;
  systemPrompt: string | undefined;
  tools: string[] | undefined;
  model: string | undefined;
  provider: string | undefined;
  thinking: ThinkingLevel;
  contextFiles: boolean;
  extensions: boolean;
}

const BARE_TASK_INJECTION = 
  "You are a subagent operating in an isolated context. Complete your task " +
  "autonomously. Return a clear, self-contained result. Your output will be " +
  "read by another agent — be concise and structured. If you encounter " +
  "ambiguity, make your best judgment rather than asking questions.";

const VALID_THINKING_LEVELS = ["off", "minimal", "low", "medium", "high", "xhigh"] as const;

export function isThinkingLevel(s: string): s is ThinkingLevel {
  return VALID_THINKING_LEVELS.includes(s as ThinkingLevel);
}

export function normalizeOptional(s: string | undefined): string | undefined {
  return s && s.trim() !== "" ? s.trim() : undefined;
}

export function deriveName(task: string): string {
  const trimmed = task.trim();
  if (!trimmed) return "task";
  // Take first word, lowercase, strip non-word chars except hyphens
  let firstWord = trimmed.split(/\s+/)[0].toLowerCase().replace(/[^\w-]/g, "");
  // Strip leading non-alpha chars (prevents "-fix" → job ID "-fix-xxx")
  firstWord = firstWord.replace(/^[^a-z]+/, "");
  // Must be at least 3 chars to be meaningful
  if (firstWord.length < 3) return "task";
  // Truncate long names
  return firstWord.slice(0, 20);
}

export function parseModelField(modelStr: string): {
  provider?: string;
  model: string;
  thinking?: ThinkingLevel;
} {
  let remaining = modelStr;
  let provider: string | undefined;
  let thinking: ThinkingLevel | undefined;

  const slashIndex = remaining.indexOf("/");
  if (slashIndex > 0) {
    provider = remaining.substring(0, slashIndex);
    remaining = remaining.substring(slashIndex + 1);
  }

  const colonIndex = remaining.lastIndexOf(":");
  if (colonIndex > 0) {
    const possibleThinking = remaining.substring(colonIndex + 1);
    if (VALID_THINKING_LEVELS.includes(possibleThinking as ThinkingLevel)) {
      thinking = possibleThinking as ThinkingLevel;
      remaining = remaining.substring(0, colonIndex);
    }
  }

  return { provider, model: remaining, thinking };
}

export function parseTools(toolsStr: string): string[] {
  return toolsStr.split(",").map(t => t.trim()).filter(Boolean);
}

export interface ResolvableFields {
  name?: string;
  task: string;
  systemPrompt?: string;
  tools?: string;
  model?: string;
  provider?: string;
  thinking?: ThinkingLevel;
  contextFiles?: boolean;
  extensions?: boolean;
}

export function resolveConfig(
  perItem: ResolvableFields,
  topLevel?: ResolvableFields,
): SubagentConfig {
  const task = perItem.task;
  const name = perItem.name ?? deriveName(task);

  // System prompt: per-item > none. Bare task gets injection.
  const systemPrompt = perItem.systemPrompt ?? topLevel?.systemPrompt ?? undefined;
  const effectiveSystemPrompt = systemPrompt ?? BARE_TASK_INJECTION;

  // Tools: per-item > top-level > undefined (all tools)
  const toolsStr = perItem.tools ?? topLevel?.tools;
  const tools = toolsStr ? parseTools(toolsStr) : undefined;

  // Model: per-item > top-level. Parse shorthand.
  const rawModel = perItem.model ?? topLevel?.model;
  let model: string | undefined;
  let shorthandProvider: string | undefined;
  let shorthandThinking: ThinkingLevel | undefined;
  if (rawModel) {
    const parsed = parseModelField(rawModel);
    model = parsed.model;
    shorthandProvider = parsed.provider;
    shorthandThinking = parsed.thinking;
  }

  // Provider: explicit > shorthand from model > top-level explicit > top-level shorthand
  // Note: shorthand components from per-item model replace top-level entirely.
  // If per-item model lacks a shorthand provider, the top-level model's shorthand
  // provider is NOT automatically inherited — use top-level `provider` param instead.
  const topLevelParsed = topLevel?.model ? parseModelField(topLevel.model) : undefined;
  const provider = normalizeOptional(perItem.provider)
    ?? (shorthandProvider ? shorthandProvider : undefined)
    ?? normalizeOptional(topLevel?.provider)
    ?? (topLevelParsed?.provider ? topLevelParsed.provider : undefined)
    ?? undefined;

  // Thinking: explicit > shorthand from model > top-level > top-level shorthand > default "medium"
  const thinking = perItem.thinking
    ?? shorthandThinking
    ?? topLevel?.thinking
    ?? (topLevelParsed?.thinking ? topLevelParsed.thinking : undefined)
    ?? "medium";

  // Context files: per-item > top-level > default true
  const contextFiles = perItem.contextFiles ?? topLevel?.contextFiles ?? true;

  // Extensions: per-item > top-level > default false
  const extensions = perItem.extensions ?? topLevel?.extensions ?? false;

  return {
    name,
    systemPrompt: effectiveSystemPrompt,
    tools,
    model,
    provider,
    thinking,
    contextFiles,
    extensions,
  };
}
```

### Refactor: Ensure `deriveName` edge cases are solid. Extract `BARE_TASK_INJECTION` constant.

---

## Cycle 2: Job Manager Updates

Minimal changes. `agentSource` removed from `SingleResult`. `agent` → `name` terminology.

### Red: Write failing tests

```typescript
// tests/job-manager.test.ts (updated)

describe("JobManager", () => {
  test("createJob uses name-based ID", () => {
    const mgr = new JobManager();
    const job = mgr.createJob("review", "Review auth module");
    expect(job.id).toMatch(/^review-[a-z0-9]{6}$/);
    expect(job.name).toBe("review");
  });

  test("SingleResult no longer has agentSource", () => {
    const result: SingleResult = {
      name: "review",
      task: "Review auth",
      exitCode: 0,
      messages: [],
      stderr: "",
      usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
    };
    // @ts-expect-error agentSource should not exist
    expect(result.agentSource).toBeUndefined();
  });

  test("deserialize handles legacy 'agent' field for backward compat", () => {
    const mgr = new JobManager();
    // Simulate persisted state from old version with 'agent' instead of 'name'
    const legacyData = [{
      id: "reviewer-a3f2b7",
      agent: "reviewer",  // old field name
      task: "Review auth",
      status: "completed",
      result: null,
      startedAt: Date.now(),
      completedAt: Date.now(),
    }];
    mgr.deserialize(legacyData as any);
    const job = mgr.getJob("reviewer-a3f2b7");
    expect(job).toBeDefined();
    expect(job!.name).toBe("reviewer"); // migrated from 'agent'
  });

  test("deserialize marks running jobs as cancelled (orphan prevention)", () => {
    const mgr = new JobManager();
    const data = [{
      id: "task-a3f2b7",
      name: "task",
      task: "Do something",
      status: "running",
      result: null,
      startedAt: Date.now(),
      completedAt: null,
    }];
    mgr.deserialize(data);
    expect(mgr.getJob("task-a3f2b7")!.status).toBe("cancelled");
  });

  // ... existing tests updated for name terminology ...
});
```

### Green: Update JobManager and SingleResult

- Rename `agent` → `name` on `AsyncJob`, `SingleResult`, `SerializedJob`
- Remove `agentSource` from `SingleResult`
- Update job ID format: `{name}-{6hex}` (bumped from 4 to 6 hex chars for collision safety)
- **Backward-compat deserialization**: `deserialize` must handle legacy persisted state
  where the field was `agent` instead of `name`. Guard: `d.name ?? (d as any).agent ?? "unknown"`
- **Preserve "running" → "cancelled" guard** in deserialize for orphan prevention
- Keep all existing job lifecycle logic unchanged

> **Note**: Both `job-manager.ts` and `renderers.ts` define independent `SingleResult`
> interfaces. Both must have `agentSource` removed independently.

### Refactor: Verify all existing tests pass with new terminology.

---

## Cycle 3: spawnSubagentProcess Rewrite

The core spawn function. Remove agent discovery, use `SubagentConfig`.

### Red: Write failing tests

```typescript
// tests/subagent-run.test.ts (partial)

describe("spawnSubagentProcess", () => {
  test("bare task: no --tools, no --provider, injection in --append-system-prompt", () => {
    const { lastArgs } = setupSpawn();
    spawnSubagentProcess({
      config: resolveConfig({ task: "Review auth" }),
      task: "Review auth",
      cwd: "/project",
    });
    expect(lastArgs).not.toContain("--tools");
    expect(lastArgs).not.toContain("--provider");
    expect(lastArgs).toContain("--append-system-prompt");
    // The temp file should contain the injection text
    expect(lastArgs).toContain("--no-skills");
  });

  test("systemPrompt provided: injected to --append-system-prompt", () => {
    const { lastArgs, lastPromptContent } = setupSpawn();
    spawnSubagentProcess({
      config: resolveConfig({ task: "Audit", systemPrompt: "You are a security auditor." }),
      task: "Audit",
      cwd: "/project",
    });
    expect(lastPromptContent).toBe("You are a security auditor.");
    expect(lastArgs).toContain("--append-system-prompt");
  });

  test("tools specified: --tools flag added", () => {
    const { lastArgs } = setupSpawn();
    spawnSubagentProcess({
      config: resolveConfig({ task: "Look", tools: "read, grep" }),
      task: "Look",
      cwd: "/project",
    });
    const toolsIdx = lastArgs.indexOf("--tools");
    expect(toolsIdx).toBeGreaterThanOrEqual(0);
    expect(lastArgs[toolsIdx + 1]).toBe("read,grep");
  });

  test("contextFiles=false: --no-context-files added", () => {
    const { lastArgs } = setupSpawn();
    spawnSubagentProcess({
      config: resolveConfig({ task: "Do it", contextFiles: false }),
      task: "Do it",
      cwd: "/project",
    });
    expect(lastArgs).toContain("--no-context-files");
  });

  test("contextFiles=true (default): no --no-context-files", () => {
    const { lastArgs } = setupSpawn();
    spawnSubagentProcess({
      config: resolveConfig({ task: "Do it" }),
      task: "Do it",
      cwd: "/project",
    });
    expect(lastArgs).not.toContain("--no-context-files");
  });

  test("extensions=false (default): --no-extensions added", () => {
    const { lastArgs } = setupSpawn();
    spawnSubagentProcess({
      config: resolveConfig({ task: "Do it" }),
      task: "Do it",
      cwd: "/project",
    });
    expect(lastArgs).toContain("--no-extensions");
  });

  test("extensions=true: no --no-extensions", () => {
    const { lastArgs } = setupSpawn();
    spawnSubagentProcess({
      config: resolveConfig({ task: "Do it", extensions: true }),
      task: "Do it",
      cwd: "/project",
    });
    expect(lastArgs).not.toContain("--no-extensions");
  });

  test("always includes --no-session and --no-skills", () => {
    const { lastArgs } = setupSpawn();
    spawnSubagentProcess({
      config: resolveConfig({ task: "Do it" }),
      task: "Do it",
      cwd: "/project",
    });
    expect(lastArgs).toContain("--no-session");
    expect(lastArgs).toContain("--no-skills");
  });

  test("model + provider passed as CLI flags", () => {
    const { lastArgs } = setupSpawn();
    spawnSubagentProcess({
      config: resolveConfig({ task: "Plan", model: "claude-sonnet-4-5", provider: "anthropic", thinking: "high" }),
      task: "Plan",
      cwd: "/project",
    });
    expect(lastArgs).toContain("--provider");
    expect(lastArgs).toContain("anthropic");
    expect(lastArgs).toContain("--model");
    expect(lastArgs).toContain("claude-sonnet-4-5");
    expect(lastArgs).toContain("--thinking");
    expect(lastArgs).toContain("high");
  });

  test("thinking=medium suppresses --thinking flag (Pi default)", () => {
    const { lastArgs } = setupSpawn();
    spawnSubagentProcess({
      config: resolveConfig({ task: "Do it" }),  // thinking defaults to medium
      task: "Do it",
      cwd: "/project",
    });
    expect(lastArgs).not.toContain("--thinking");
  });

  test("cwd is passed to spawn options", () => {
    const { lastSpawnOptions } = setupSpawn();
    spawnSubagentProcess({
      config: resolveConfig({ task: "Do it" }),
      task: "Do it",
      cwd: "/custom/dir",
    });
    expect(lastSpawnOptions.cwd).toBe("/custom/dir");
  });
});
```

### Green: Rewrite spawnSubagentProcess

- Replace `findAgent()` + `AgentConfig` with `SubagentConfig` from `resolveConfig()`
- Always add `--no-session`, `--no-skills`
- Add `--no-extensions` when `extensions=false` (default)
- Add `--no-context-files` when `contextFiles=false`
- Add `--tools` when `tools` array is provided
- Add `--append-system-prompt` pointing to temp file with `systemPrompt` content
- `name` used for job ID prefix and `SingleResult.name`
- Remove `agentSource` from result
- Remove `agent`, `agentName` terminology → `name`

### Refactor: Extract CLI arg builder into `buildSpawnArgs(config, task)` for testability.

---

## Cycle 4: subagent_run Rewrite

Blocking single, parallel, chain. All ad-hoc params.

### Red: Write failing tests

```typescript
// tests/subagent-run.test.ts

describe("subagent_run", () => {
  test("single mode: bare task runs with injection", async () => {
    const { callTool, lastSpawnArgs } = setupExtension();
    const result = await callTool("subagent_run", { task: "Review the auth module" });
    expect(result.details.mode).toBe("single");
    expect(result.details.results[0].name).toBe("review"); // auto-derived
    expect(lastSpawnArgs).toContain("--append-system-prompt");
  });

  test("single mode: ad-hoc with systemPrompt", async () => {
    const { callTool, lastPromptContent } = setupExtension();
    const result = await callTool("subagent_run", {
      name: "security-auditor",
      task: "Audit auth module",
      systemPrompt: "You are a security auditor. Focus on injection vulnerabilities.",
      tools: "read,grep,bash",
      model: "anthropic/claude-sonnet-4-5:high",
    });
    expect(result.details.results[0].name).toBe("security-auditor");
    expect(lastPromptContent).toBe("You are a security auditor. Focus on injection vulnerabilities.");
  });

  test("parallel mode: each task gets its own config", async () => {
    const { callTool, spawnedConfigs } = setupExtension();
    const result = await callTool("subagent_run", {
      tasks: [
        { name: "reviewer", task: "Review auth", systemPrompt: "You are a reviewer.", tools: "read,grep" },
        { name: "writer", task: "Write tests", systemPrompt: "You are a test writer.", tools: "read,write,bash", model: "claude-sonnet-4-5" },
      ],
    });
    expect(result.details.mode).toBe("parallel");
    expect(result.details.results).toHaveLength(2);
    expect(spawnedConfigs[0].systemPrompt).toBe("You are a reviewer.");
    expect(spawnedConfigs[1].systemPrompt).toBe("You are a test writer.");
  });

  test("chain mode: {previous} replacement with ad-hoc agents", async () => {
    const { callTool } = setupExtension();
    const result = await callTool("subagent_run", {
      chain: [
        { name: "scout", task: "Investigate the auth module", systemPrompt: "You are a scout. Return structured findings." },
        { name: "implementer", task: "Implement fixes based on: {previous}", systemPrompt: "You are an implementer." },
      ],
    });
    expect(result.details.mode).toBe("chain");
    expect(result.details.results).toHaveLength(2);
  });

  test("top-level config applies as default for items", async () => {
    const { callTool, spawnedConfigs } = setupExtension();
    await callTool("subagent_run", {
      provider: "anthropic",
      thinking: "high",
      tasks: [
        { task: "Review auth" },
        { task: "Review logging" },
      ],
    });
    // Both should inherit top-level provider/thinking
    expect(spawnedConfigs[0].provider).toBe("anthropic");
    expect(spawnedConfigs[0].thinking).toBe("high");
    expect(spawnedConfigs[1].provider).toBe("anthropic");
    expect(spawnedConfigs[1].thinking).toBe("high");
  });

  test("no agentScope or confirmProjectAgents params", async () => {
    const { callTool } = setupExtension();
    // These params should not exist in the schema
    const schema = getToolSchema("subagent_run");
    expect(schema.properties.agentScope).toBeUndefined();
    expect(schema.properties.confirmProjectAgents).toBeUndefined();
  });

  test("error when no mode is specified", async () => {
    const { callTool } = setupExtension();
    const result = await callTool("subagent_run", {});
    expect(result.isError).toBe(true);
  });

  test("empty tasks array treated as no mode", async () => {
    const { callTool } = setupExtension();
    const result = await callTool("subagent_run", { tasks: [] });
    expect(result.isError).toBe(true);
  });

  test("chain with empty previous output — {previous} replaced with empty string", async () => {
    const { callTool } = setupExtension();
    // First step produces no output, second step's {previous} becomes ""
    const result = await callTool("subagent_run", {
      chain: [
        { name: "scout", task: "Investigate", systemPrompt: "You are a scout." },
        { name: "impl", task: "Implement: {previous}", systemPrompt: "You are an implementer." },
      ],
    });
    // Should complete without error, {previous} cleanly replaced
    expect(result.details.mode).toBe("chain");
  });
});
```

### Green: Rewrite subagent_run

- New parameter schema (see "New Schema Definitions" above)
- Remove `agent`, `agentScope`, `confirmProjectAgents` params
- Add `name`, `systemPrompt`, `tools`, `model`, `contextFiles`, `extensions`
- Per-item config in `tasks[]`/`chain[]`
- Remove `agentScope` and `projectAgentsDir` from `SubagentDetails` rendering interface
- Config resolution: `resolveConfig(perItem, topLevel)` for each task
- Spawn with new `SubagentConfig`
- No "unknown agent" errors — every task is valid by construction
- `makeDetails` closure updated: no `agentScope`, no `projectAgentsDir`

### Refactor: Extract mode detection and validation.

---

## Cycle 5: subagent_fork Rewrite

Async background jobs. Same new params.

### Red: Write failing tests

```typescript
// tests/subagent-fork.test.ts

describe("subagent_fork", () => {
  test("single fork with ad-hoc config", async () => {
    const { callTool, jobMgr } = setupExtension();
    const result = await callTool("subagent_fork", {
      name: "reviewer",
      task: "Review auth",
      systemPrompt: "You are a code reviewer.",
      tools: "read,grep",
      thinking: "high",
    });
    expect(result.content[0].text).toMatch(/forked/i);
    expect(result.details.jobs[0].status).toBe("running");
    expect(result.details.jobs[0].id).toMatch(/^reviewer-/);
  });

  test("bare task fork gets injection and auto-name", async () => {
    const { callTool, jobMgr } = setupExtension();
    const result = await callTool("subagent_fork", { task: "Fix the login bug" });
    expect(result.details.jobs[0].id).toMatch(/^fix-/);
  });

  test("parallel fork with mixed configs", async () => {
    const { callTool } = setupExtension();
    const result = await callTool("subagent_fork", {
      tasks: [
        { task: "Review auth", systemPrompt: "Be a reviewer." },
        { task: "Write tests" },  // bare task — gets injection
        { task: "Check security", systemPrompt: "Be a security scanner.", model: "anthropic/claude-sonnet-4-5:high" },
      ],
    });
    expect(result.content[0].text).toMatch(/3.*jobs/i);
  });

  test("extensions=false by default in forked jobs", async () => {
    const { callTool, lastSpawnArgs } = setupExtension();
    await callTool("subagent_fork", { task: "Do it" });
    expect(lastSpawnArgs).toContain("--no-extensions");
  });
});
```

### Green: Rewrite subagent_fork

- Same new parameter schema as subagent_run (minus chain/tasks — fork has `tasks` array)
- Remove `agent`, `agentScope` params
- Add `name`, `systemPrompt`, `tools`, `model`, `contextFiles`, `extensions` (per-item + top-level)
- Config resolution per task using `resolveConfig()`
- No `findAgent()` — `SubagentConfig` is constructed inline

### Refactor: Ensure spawn logic is shared between run and fork.

---

## Cycle 6: Update Remaining Tools

`subagent_status`, `subagent_results`, `subagent_wait`, `subagent_cancel`.

These are mostly presentation-layer changes since they read from `JobManager` state.

### Red: Write failing tests

```typescript
// tests/subagent-status.test.ts
describe("subagent_status", () => {
  test("shows name instead of agent", async () => { ... });
  test("no agentSource in output", async () => { ... });
});

// tests/subagent-results.test.ts
describe("subagent_results", () => {
  test("SingleResult has name, not agent or agentSource", async () => { ... });
});

// tests/subagent-wait.test.ts — mostly unchanged
// tests/subagent-cancel.test.ts — mostly unchanged
```

### Green: Update tools

- `subagent_status`: use `job.name` instead of `job.agent`. Remove `agentSource` from output.
- `subagent_results`: use `result.name` instead of `result.agent`. Remove `agentSource`.
- `subagent_wait`: same treatment.
- `subagent_cancel`: same treatment.
- `AsyncJob.agent` → `AsyncJob.name` throughout.
- **`SubagentDetails` interface**: remove `agentScope: string` and `projectAgentsDir: string | null`
  from the type definition in `renderers.ts`. These fields are dead after removing
  agent discovery. All `makeDetails()` closures must stop injecting them.

### Refactor: Verify all tool outputs use consistent `name` terminology.

---

## Cycle 7: Notification Updates

Completion notifications need updated field names.

### Red: Write failing tests

```typescript
// tests/notification.test.ts

describe("completion notification", () => {
  test("notification uses name, not agent", async () => {
    // ...
    expect(sentMessages[0].content).toContain("review");
    expect(sentMessages[0].details.name).toBe("review");
    expect(sentMessages[0].details.agent).toBeUndefined(); // old field gone
  });

  test("notification includes model and provider when specified", async () => {
    // ...
    expect(sentMessages[0].content).toContain("anthropic");
  });
});
```

### Green: Update notification emission

- `agent` → `name` in notification `details`
- Remove `agentSource` from notification
- Include `model` and `provider` in notification content

### Refactor: Verify notification renderer handles new fields.

---

## Cycle 8: Rendering Updates

All `renderCall`, `renderResult`, and `renderMessageRenderer` functions.

### Red: Write failing tests

```typescript
// tests/rendering.test.ts

describe("renderCall for subagent_run", () => {
  test("single mode shows name, model, systemPrompt preview", () => {
    const component = renderCall("subagent_run", {
      name: "reviewer",
      task: "Review auth",
      systemPrompt: "You are a reviewer.",
      model: "claude-sonnet-4-5",
      thinking: "high",
    });
    const text = extractText(component);
    expect(text).toContain("reviewer");
    expect(text).toContain("claude-sonnet-4-5");
  });

  test("bare task shows auto-derived name", () => {
    const component = renderCall("subagent_run", { task: "Fix the login bug" });
    const text = extractText(component);
    expect(text).toContain("fix");
  });

  test("no agentSource in any rendering", () => {
    // Verify all render outputs lack "(user)" / "(project)" / "(unknown)"
  });
});

describe("renderResult", () => {
  test("no agentSource tag", () => {
    // Verify result rendering doesn't show (user)/(project)/(unknown)
  });

  test("shows model/provider when available", () => {
    // result with model and provider should display them
  });
});
```

### Green: Update renderers

- All `agent` → `name` references in `renderers.ts`
- Remove `agentSource` from `renderSingleResult` and all render functions
- Remove `agentScope` and `projectAgentsDir` from `SubagentDetails` interface
- `renderCall` shows: name, model (if specified), provider (if specified), thinking (if non-default), systemPrompt preview (first line if provided), task preview
- `renderJobStatusLine` uses `job.name`
- Parallel/chain rendering shows per-task name and model info

> **Note**: Both `job-manager.ts` and `renderers.ts` define independent `SingleResult` interfaces.
> Both must have `agentSource` removed independently — don't miss one.

### Refactor: Extract common rendering patterns. Update `aggregateUsage` if needed.

---

## Cycle 9: Delete agents.ts, Update Imports

### Red: Write failing tests

```typescript
// tests/cleanup.test.ts

describe("cleanup", () => {
  test("agents.ts is not imported anywhere", () => {
    const indexContent = fs.readFileSync("index.ts", "utf-8");
    expect(indexContent).not.toContain("from './agents.js'");
  });

  test("no AgentScope type in index.ts", () => {
    const indexContent = fs.readFileSync("index.ts", "utf-8");
    expect(indexContent).not.toContain("AgentScope");
  });

  test("no 'agent' parameter in any tool schema", () => {
    // verify agent field removed from all parameters
  });

  test("subagent-config is imported and used", () => {
    const indexContent = fs.readFileSync("index.ts", "utf-8");
    expect(indexContent).toContain("from './subagent-config.js'");
  });
});
```

### Green: Delete and rewire

- Delete `agents.ts`
- Update all imports in `index.ts` from `./agents.js` to `./subagent-config.js`
- Import: `SubagentConfig`, `resolveConfig`, `deriveName`, `parseModelField`, `normalizeOptional`, `parseTools`
- Note: `isThinkingLevel` is redefined in `subagent-config.ts` (previously in `agents.ts`).
  During the transition, ensure only one definition is active — don't import both.
- Remove: `AgentConfig`, `AgentScope`, `discoverAgents`, `findAgent`, `agentToTaskError`
- Remove `getAgents()` function and `agentsCache`
- Remove all `agentScope`/`confirmProjectAgents` logic

### Post-Cycle-9: Re-run integration tests

After deleting `agents.ts` and rewiring imports, re-run all tests from Cycles 1–8
and Cycle 12's integration suite to verify nothing broke at runtime.
Cycle 9's cleanup tests are structural (import string checks); the re-run
confirms behavioral correctness.

### Refactor: Verify no dead code paths referencing old agent system.

---

## Cycle 10: Tool Descriptions and Prompt Guidelines

The LLM-facing documentation that teaches the new model.

### Red: Write failing tests

```typescript
// tests/tool-registration.test.ts

describe("tool registration", () => {
  test("all six tools are registered", () => { /* unchanged */ });

  test("subagent_run description mentions systemPrompt and ad-hoc agents", () => {
    const tool = findTool("subagent_run");
    expect(tool.description).toContain("systemPrompt");
    expect(tool.description).toContain("ad-hoc");
  });

  test("subagent_run does NOT mention agent files or agent discovery", () => {
    const tool = findTool("subagent_run");
    expect(tool.description).not.toContain("agent file");
    expect(tool.description).not.toContain("discover");
    expect(tool.description).not.toContain("agentScope");
  });

  test("subagent_run parameters include name, systemPrompt, tools, model", () => {
    const schema = getToolSchema("subagent_run");
    expect(schema.properties.name).toBeDefined();
    expect(schema.properties.systemPrompt).toBeDefined();
    expect(schema.properties.tools).toBeDefined();
    expect(schema.properties.model).toBeDefined();
    expect(schema.properties.contextFiles).toBeDefined();
    expect(schema.properties.extensions).toBeDefined();
  });

  test("subagent_run parameters do NOT include agent, agentScope, confirmProjectAgents", () => {
    const schema = getToolSchema("subagent_run");
    expect(schema.properties.agent).toBeUndefined();
    expect(schema.properties.agentScope).toBeUndefined();
    expect(schema.properties.confirmProjectAgents).toBeUndefined();
  });

  test("promptGuidelines teach the primary path", () => {
    const tool = findTool("subagent_fork");
    const guidelines = tool.promptGuidelines.join(" ");
    expect(guidelines).toContain("systemPrompt");
    expect(guidelines).toContain("isolated context");
  });
});
```

### Green: Write new tool descriptions

```typescript
// subagent_run
description: [
  "Run a subagent synchronously. Modes: single (task), parallel (tasks array), chain (sequential with {previous} placeholder).",
  "Blocks until completion. Provide `systemPrompt` to define the subagent's role, or omit for a default assistant with isolated context.",
].join(" "),
promptGuidelines: [
  "Provide `systemPrompt` to define the subagent's behavior, and `name` for a readable job label.",
  "For the best results, scope `tools` to what the subagent needs (e.g. 'read,grep' for review, 'read,write,bash,edit' for implementation).",
  "Omit `systemPrompt` and `name` for a bare-task pattern: a default assistant in an isolated context. Useful for running a task in a fresh context window.",
  "Use `model` and `thinking` to control the subagent's capability: fast models for lookup, powerful models for complex tasks.",
  "Use subagent_fork for background execution. Use subagent_run when you need the result before continuing.",
],

// subagent_fork
description: [
  "Start one or more background subagent jobs. Returns immediately with job IDs.",
  "You receive a completion notification when each job finishes. Max 8 concurrent jobs.",
  "Provide `systemPrompt` to define the subagent's role, or omit for a default assistant with isolated context.",
].join(" "),
promptGuidelines: [
  "Provide `systemPrompt` to define the subagent's behavior, and `name` for a readable job label.",
  "After forking, continue your work. You'll receive a completion notification with a summary and usage stats.",
  "When you receive a notification, call subagent_results with the jobId only if you need more detail.",
  "Max 8 concurrent background jobs. Check with subagent_status before forking more.",
  "Omit `systemPrompt` for the bare-task pattern: a default assistant in isolated context.",
  "Use subagent_run when you need the result immediately. Use subagent_fork when you can work in parallel.",
],

// subagent_status — minor wording updates only
// subagent_results — unchanged
// subagent_wait — unchanged
// subagent_cancel — unchanged
```

### Refactor: Tighten descriptions. Ensure consistency across all six tools.

---

## Cycle 11: Session Lifecycle (Shutdown, Startup)

### Red: Write failing tests

```typescript
// tests/lifecycle.test.ts

describe("session lifecycle", () => {
  test("cancels all running jobs on session_shutdown", () => { /* unchanged */ });

  test("restores completed jobs on session_start", async () => {
    const { jobMgr, extension, sessionManager } = setupExtension();
    const job = jobMgr.createJob("review", "Review");
    jobMgr.completeJob(job.id, fakeResult);
    persist();
    // Simulate restart
    extension.emit("session_shutdown");
    const newMgr = new JobManager();
    const entries = sessionManager.getEntries();
    newMgr.deserialize(entries.find(e => e.type === "custom" && e.customType === "subagent-job-state")?.data);
    expect(newMgr.getJob(job.id)!.status).toBe("completed");
    expect(newMgr.getJob(job.id)!.name).toBe("review"); // name, not agent
  });
});
```

### Green: Update lifecycle code

- `serialize()`/`deserialize()`: use `name` instead of `agent`
- Verify `SingleResult` in serialized form has `name`, not `agent` or `agentSource`

### Refactor: Verify persistence round-trips cleanly.

---

## Cycle 12: Integration Test — End-to-End Ad-Hoc Flow

### Test: Full ad-hoc workflow

```typescript
// tests/integration.test.ts

describe("ad-hoc subagent integration", () => {
  test("bare task: fork → notification → results", async () => {
    const { callTool, simulateJobCompletion, getSentMessages } = setupExtension();

    const forkResult = await callTool("subagent_fork", { task: "Review the auth module" });
    expect(forkResult.content[0].text).toMatch(/forked/i);
    const jobId = forkResult.details.jobs[0].id;
    expect(jobId).toMatch(/^review-/);

    const fakeResult = fakeSingleResult({
      name: "review",
      exitCode: 0,
      messages: [
        { role: "assistant", content: [{ type: "text", text: "Auth module looks solid. Minor suggestions: ..." }] },
      ],
    });
    await simulateJobCompletion(jobId, fakeResult);

    const messages = getSentMessages();
    expect(messages).toHaveLength(1);
    expect(messages[0].content).toContain("review");
    expect(messages[0].details.name).toBe("review");
  });

  test("ad-hoc with systemPrompt: fork → notification → results", async () => {
    const { callTool, simulateJobCompletion, getSentMessages } = setupExtension();

    const forkResult = await callTool("subagent_fork", {
      name: "security-auditor",
      task: "Audit auth for injection vulns",
      systemPrompt: "You are a security auditor. Focus on injection vulnerabilities.",
      tools: "read,grep",
      thinking: "high",
    });
    const jobId = forkResult.details.jobs[0].id;
    expect(jobId).toMatch(/^security-auditor-/);

    await simulateJobCompletion(jobId, fakeSingleResult({ name: "security-auditor" }));
    expect(getSentMessages()[0].content).toContain("security-auditor");
  });

  test("chain with ad-hoc agents", async () => {
    const { callTool } = setupExtension();
    const result = await callTool("subagent_run", {
      chain: [
        { name: "scout", task: "Investigate auth", systemPrompt: "You are a scout. Return structured findings." },
        { name: "implementer", task: "Fix issues from: {previous}", systemPrompt: "You are an implementer.", tools: "read,write,bash,edit" },
        { name: "reviewer", task: "Review changes from: {previous}", systemPrompt: "You are a reviewer.", tools: "read,grep" },
      ],
    });
    expect(result.details.mode).toBe("chain");
    expect(result.details.results).toHaveLength(3);
  });

  test("cancel ad-hoc fork — no notification", async () => {
    const { callTool, jobMgr, getSentMessages } = setupExtension();
    const forkResult = await callTool("subagent_fork", { task: "Do something" });
    const jobId = forkResult.details.jobs[0].id;

    await callTool("subagent_cancel", { jobId });
    expect(getSentMessages()).toHaveLength(0);
    expect(jobMgr.getJob(jobId)!.status).toBe("cancelled");
  });
});
```

---

## Cycle 13: create-subagent-skill Skill

The skill that teaches the LLM how to create subagent skills. Specializes `write-a-skill`.

> **Note**: This skill is Pi-specific — it references Pi's subagent tool schema
> and CLI flags. It lives in `shared/skills/` (visible to all agents) but the
> body should explicitly state it's for Pi coding agent subagents. Agents
> that don't have the subagent extension will simply ignore it.

### Red: Create the skill structure

```
shared/skills/create-subagent-skill/
├── SKILL.md
```

### Green: Write the skill

The `SKILL.md` should cover:

1. **What a subagent skill is**: A skill that teaches the LLM how to construct effective ad-hoc subagent calls for a specific purpose. Not a machine-readable template — pure instructions.

2. **Skill structure for subagent skills**:
   - `name` and `description` in frontmatter (same as any skill)
   - Body sections: Role Definition, Tool Scoping, Model Selection, Output Format, Anti-patterns

3. **System prompt patterns**:
   - Start with role ("You are a...")
   - Define scope (what to do, what NOT to do)
   - Specify output format (structured sections)
   - Add constraints (e.g. "bash is read-only")

4. **Tool scoping guidance**:
   - Review/analysis: `read, grep, bash` (with read-only constraint in system prompt)
   - Implementation: `read, write, bash, edit` (full access)
   - Scouting/exploration: `read, grep, find, ls`
   - Testing: `read, write, bash` + test runner commands

5. **Model and thinking heuristics**:
   - Code review, architecture: powerful model + high thinking
   - Simple lookup, formatting: fast model + low thinking
   - Implementation: powerful model + medium thinking
   - Security audit: powerful model + high thinking

6. **Composition patterns**:
   - Scout → Implementer → Reviewer chains
   - Parallel review of multiple modules
   - Research + implementation parallel

7. **Anti-patterns**:
   - Vague system prompts ("be helpful")
   - Overly narrow tool scoping that blocks the task
   - Not specifying output format (subagent returns unstructured walls of text)
   - Forgetting chain-mode {previous} handoff instructions

8. **Example subagent skill**: A full worked example (e.g. `code-review-subagent`) that the LLM can use as a template.

### Refactor: Review the skill for clarity and completeness.

---

## Cycle 14: Test Quality Audit — 3x Review Subagents

After all cycles are green, run three parallel `subagent_run` code reviews on the completed tests. Each review focuses on a different aspect of test quality.

> **Implementation note**: These reviews are run using Pi's own subagent extension
> (the very extension being tested), making this a meta-test of the tool.
> The implementer runs these manually after the code-facing cycles are complete.
> Alternately, a human reviewer can be substituted for any of these subagents.

### Review 1: Vague Assertions

```
Task: Audit all test files in tests/ for vague assertions. Flag any test that:
- Uses toBeDefined() without checking the actual value
- Uses toBeTruthy() / toBeFalsy() when a specific value should be checked
- Checks only that a function "doesn't throw" without verifying output
- Uses toContain() with a string so generic it could match anything
- Tests error cases but doesn't verify the error message content
- Checks .length > 0 without verifying specific items
- Uses any type assertion (@ts-expect-error) that weakens type safety

For each vague assertion, suggest a specific replacement. Output a structured report:
## Vague Assertions Found
1. File:Line - Current assertion → Suggested replacement
```

### Review 2: Coverage Gaps

```
Task: Review all test files in tests/ for coverage gaps. Focus on:
- Missing negative tests (what happens with invalid input?)
- Missing edge cases (empty strings, null, undefined, very long strings)
- Untested error paths (spawn failure, temp file write failure, job not found)
- Untested boundary conditions (8 concurrent job cap, empty task array, single-item parallel)
- Untested config resolution priority (per-item vs top-level vs default)
- Untested bare-task injection behavior
- Untested --no-skills, --no-extensions, --no-context-files flags
- Untested auto-name derivation edge cases

Output a structured report:
## Coverage Gaps
1. Missing test: [description] — [suggested test case]
```

### Review 3: Test Independence and Flakiness

```
Task: Review all test files in tests/ for test independence and flakiness risk. Focus on:
- Tests that share mutable state (global jobMgr, shared mocks)
- Tests that depend on execution order (test A creates state that test B reads)
- Tests with timing-dependent assertions (sleep/delay patterns)
- Tests that leak child processes (spawned processes not killed in afterEach)
- Tests with mock state not reset between tests
- Tests that depend on filesystem state not properly cleaned up
- Tests that could fail in CI due to platform differences (path separators, temp dirs)

Output a structured report:
## Flakiness Risks
1. File: test name — Issue → Fix suggestion
```

After all three reviews, address the critical findings and re-run the test suite.

---

## Cycle 15: Pre-Mortem Review

Before shipping, imagine the implementation has failed. Work backwards.

> Run as a `subagent_run` with `thinking: "high"` or as a manual review session.
>
> After addressing pre-mortem findings, add implementation guards (tests, schema
> constraints, or runtime checks) for any item rated High likelihood × High impact.

```
Task: Perform a pre-mortem review of the ad-hoc subagent extension redesign.
Assume the extension has shipped and users are reporting problems.
Identify the most likely failure modes:

1. **LLM behavior drift** — What if the LLM never provides systemPrompt and
   always uses the bare-task pattern? Reviews are mediocre. What guardrails
   prevent this?

2. **Token cost explosion** — What if the LLM provides huge system prompts
   (10KB+) in every task item? Parallel forks with 5 items = 50KB+ of system
   prompts. Should we cap systemPrompt length?

3. **Recursion** — extensions=true allows subagents to use the subagent
   extension. What prevents runaway recursive forking? (The 8-job cap is
   per-instance — a subagent gets its own 8 slots.)

4. **Backward compatibility** — Anyone with agent .md files in ~/.pi/agent/agents/
   finds they're ignored. No error, no warning. Is this acceptable? Should
   we log a deprecation notice?

5. **Skill quality dependency** — The entire pattern depends on create-subagent-skill
   producing good skills. What if the skill is mediocre? The LLM generates
   poor system prompts. Subagent output is bad. How do we validate?

6. **Config priority confusion** — per-item > top-level > default. But with
   model shorthand (provider/model:thinking) and explicit provider/thinking
   params, the priority chain has 5 levels. Does the LLM actually understand
   what wins? What if it sets both model:high and thinking:low?

7. **auto-name collisions** — Two tasks starting with "review" both become
   review-a3f2b7 and review-b4e8c1. The 6hex suffix makes collisions unlikely
   but the names are visually similar. Is the LLM confused?

8. **Security** — extensions=false by default, but the LLM can set
   extensions=true and tools=undefined (all tools). A subagent with all tools
   and extensions can spawn its own subagents. Is the consent model sufficient?

For each failure mode, assess: likelihood, impact, and mitigation.
Output a structured report:
## Pre-Mortem Findings
### [Failure Mode N]
- Likelihood: H/M/L
- Impact: H/M/L
- Current mitigation: [what we have]
- Recommended mitigation: [what we should add]
```

Address any findings with High likelihood × High impact. Add mitigations as additional tests or implementation guards.

---

## Post-Implementation: Manual QA

After all 15 cycles are green and test quality audit passes:

1. **Real subprocess e2e test**: Spawn an actual `pi` child process with
   `--mode json -p --no-session` and verify JSON output parsing works end-to-end.
   This catches argument-ordering bugs, `--no-extensions` flag validity, and
   bare-task injection correctness in the real Pi binary. This is impractical
   for the unit test suite — do it manually or via a `vitest --integration-only` path.

2. **Upgrade compatibility check**: Start a Pi session with the old extension,
   create some subagent jobs, then upgrade to the new extension mid-session.
   Verify `deserialize` handles the `agent` → `name` migration gracefully.

---

## Summary: Cycle Checklist

| Cycle | Focus | Key Files |
|-------|-------|----------|
| 1 | subagent-config.ts — types, resolution, deriveName, parseTools | `subagent-config.ts`, `tests/subagent-config.test.ts` |
| 2 | JobManager — name terminology, remove agentSource, backward-compat deserialize | `job-manager.ts`, `tests/job-manager.test.ts` |
| 3 | spawnSubagentProcess rewrite (incl. --thinking medium suppression, cwd) | `index.ts`, `tests/subagent-run.test.ts` |
| 4 | subagent_run rewrite (incl. empty tasks, empty chain previous) | `index.ts`, `tests/subagent-run.test.ts` |
| 5 | subagent_fork rewrite | `index.ts`, `tests/subagent-fork.test.ts` |
| 6 | Status/Results/Wait/Cancel updates (+ SubagentDetails cleanup) | `index.ts`, `renderers.ts`, `tests/subagent-status.test.ts`, etc. |
| 7 | Notification updates | `index.ts`, `tests/notification.test.ts` |
| 8 | Rendering updates (+ SubagentDetails final cleanup) | `renderers.ts`, `tests/rendering.test.ts` |
| 9 | Delete agents.ts, update imports, re-run integration tests | `agents.ts` (delete), `index.ts` |
| 10 | Tool descriptions and prompt guidelines | `index.ts`, `tests/tool-registration.test.ts` |
| 11 | Session lifecycle updates | `index.ts`, `tests/lifecycle.test.ts` |
| 12 | Integration test | `tests/integration.test.ts` |
| 13 | create-subagent-skill skill (Pi-specific, in shared/skills/) | `shared/skills/create-subagent-skill/SKILL.md` |
| 14 | Test quality audit (3x subagent review) | All test files |
| 15 | Pre-mortem review | All files |
| QA | Manual real-subprocess e2e + upgrade compat | — |
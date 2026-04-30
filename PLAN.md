# PLAN: Per-Subagent Provider, Model, and Thinking Level Control

## Problem

The subagent extension (`packages/coding-agent/examples/extensions/subagent/`) currently supports:

1. **Agent definition frontmatter**: `model: claude-sonnet-4-5` (maps to `--model` CLI arg)
2. **CLI shorthand**: `--model sonnet:high` (model + thinking level in one string)
3. **Standalone flag**: `--thinking high` (separate thinking level arg)
4. **Provider via model**: `--model anthropic/opus` (provider prefix in model pattern)

But the subagent tool's `AgentConfig` and invocation parameters **lack three things**:

- **No `provider` field** — you can't explicitly pin a subagent to a specific provider (e.g., always use Anthropic for reviews to avoid accidentally routing to an expensive provider like OpenAI)
- **No `thinking` field** — agent definitions and invocations can't specify reasoning effort, so review agents always inherit the default thinking level
- **No per-invocation overrides** — you can't say "run the reviewer at xhigh thinking on Anthropic this time" without editing the agent definition

This is critical for cost control: without a `provider` field, a model pattern like `opus` could resolve to any provider that has an "opus" model, potentially an expensive one. And without `thinking`, review quality depends on the default rather than being explicitly tuned per-agent.

## Design Principles

1. **Provider pinning is a cost-control measure** — explicit `provider` prevents accidental routing to expensive providers
2. **Thinking level is a quality/cost knob** — reviewers need `high`/`xhigh`, scouts can use `low`
3. **Resolution priority is explicit and predictable** — per-task > top-level invocation > agent definition > default
4. **The `model:provider/id:thinking` shorthand still works** — but separate fields take precedence for clarity

## Proposed Changes

### 1. Add `provider` and `thinking` to agent frontmatter (`agents.ts`)

**File**: `packages/coding-agent/examples/extensions/subagent/agents.ts`

```typescript
import type { ThinkingLevel } from "@mariozechner/pi-agent-core";

export interface AgentConfig {
  name: string;
  description: string;
  tools?: string[];
  provider?: string;     // NEW — pin to specific provider
  model?: string;
  thinking?: ThinkingLevel;  // NEW — explicit thinking level
  systemPrompt: string;
  source: "user" | "project";
  filePath: string;
}
```

Parse both from frontmatter, and extract `provider` and `thinking` from the `model` field's `provider/id:thinking` shorthand:

```typescript
const VALID_THINKING_LEVELS = ["off", "minimal", "low", "medium", "high", "xhigh"] as const;

function parseModelField(modelStr: string): {
  provider?: string;
  model: string;
  thinking?: ThinkingLevel;
} {
  let remaining = modelStr;
  let provider: string | undefined;
  let thinking: ThinkingLevel | undefined;

  // Extract provider prefix: "provider/model" -> provider="provider", model="model"
  const slashIndex = remaining.indexOf("/");
  if (slashIndex > 0) {
    provider = remaining.substring(0, slashIndex);
    remaining = remaining.substring(slashIndex + 1);
  }

  // Extract thinking suffix: "model:high" -> thinking="high", model="model"
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
```

In `loadAgentsFromDir`:

```typescript
const { frontmatter, body } = parseFrontmatter<Record<string, string>>(content);

// Parse model field (handles "provider/id:thinking" shorthand)
let provider = frontmatter.provider;
let model = frontmatter.model;
let thinking: ThinkingLevel | undefined;

if (model) {
  const parsed = parseModelField(model);
  // Shorthand components only apply if explicit fields aren't set
  if (!provider && parsed.provider) provider = parsed.provider;
  if (!frontmatter.thinking && parsed.thinking) thinking = parsed.thinking;
  model = parsed.model;
}

// Explicit thinking field overrides shorthand
if (frontmatter.thinking) {
  if (VALID_THINKING_LEVELS.includes(frontmatter.thinking as ThinkingLevel)) {
    thinking = frontmatter.thinking as ThinkingLevel;
  } else {
    // Skip agent with invalid thinking level
    continue;
  }
}

agents.push({
  name: frontmatter.name,
  description: frontmatter.description,
  tools: /* ... */,
  provider,
  model,
  thinking,
  systemPrompt: body,
  source,
  filePath,
});
```

This supports all these frontmatter styles:

```yaml
# Style 1: Separate fields (most explicit)
provider: anthropic
model: claude-opus-4-7
thinking: high

# Style 2: Shorthand in model field
model: anthropic/claude-opus-4-7:high

# Style 3: Mixed (explicit overrides shorthand)
model: anthropic/claude-opus-4-7:medium  # shorthand says medium
thinking: high                             # but explicit field wins

# Style 4: Provider + model, no thinking
provider: google
model: gemini-3.1-flash
```

### 2. Add `provider` and `thinking` to subagent invocation parameters (`index.ts`)

**File**: `packages/coding-agent/examples/extensions/subagent/index.ts`

Add fields at every level:

```typescript
// Shared options for per-task/per-chain overrides
const ProviderSchema = Type.Optional(Type.String({
  description: "Provider override. Prevents accidental routing to expensive providers.",
}));

const ThinkingSchema = Type.Optional(StringEnum(
  ["off", "minimal", "low", "medium", "high", "xhigh"] as const,
  { description: "Thinking level override. Overrides agent definition default." },
));

const TaskItem = Type.Object({
  agent: Type.String({ description: "Name of the agent to invoke" }),
  task: Type.String({ description: "Task to delegate to the agent" }),
  cwd: Type.Optional(Type.String({ description: "Working directory for the agent process" })),
  provider: ProviderSchema,   // NEW
  thinking: ThinkingSchema,    // NEW
});

const ChainItem = Type.Object({
  agent: Type.String({ description: "Name of the agent to invoke" }),
  task: Type.String({ description: "Task with optional {previous} placeholder for prior output" }),
  cwd: Type.Optional(Type.String({ description: "Working directory for the agent process" })),
  provider: ProviderSchema,   // NEW
  thinking: ThinkingSchema,    // NEW
});

const SubagentParams = Type.Object({
  agent: Type.Optional(Type.String({ description: "Name of the agent to invoke (for single mode)" })),
  task: Type.Optional(Type.String({ description: "Task to delegate (for single mode)" })),
  tasks: Type.Optional(Type.Array(TaskItem, { description: "Array of {agent, task} for parallel execution" })),
  chain: Type.Optional(Type.Array(ChainItem, { description: "Array of {agent, task} for sequential execution" })),
  agentScope: Type.Optional(AgentScopeSchema),
  confirmProjectAgents: Type.Optional(Type.Boolean({ ... })),
  cwd: Type.Optional(Type.String({ description: "Working directory for the agent process (single mode)" })),
  provider: ProviderSchema,    // NEW — top-level default for all agents
  thinking: ThinkingSchema,    // NEW — top-level default for all agents
});
```

**Resolution order** (highest priority wins):

| Priority | Provider | Thinking |
|----------|----------|----------|
| 1 (highest) | Per-task/per-chain-step `provider` | Per-task/per-chain-step `thinking` |
| 2 | Top-level `provider` param | Top-level `thinking` param |
| 3 | Agent definition `provider` | Agent definition `thinking` |
| 4 (lowest) | Derived from `--model` resolution | `"medium"` |

### 3. Pass `--provider` and `--thinking` to spawned `pi` process (`index.ts`)

**File**: `packages/coding-agent/examples/extensions/subagent/index.ts`

Update `runSingleAgent` signature and CLI arg construction:

```typescript
interface EffectiveModelConfig {
  provider?: string;
  model?: string;
  thinking: ThinkingLevel;
}

function resolveEffectiveConfig(options: {
  agent: AgentConfig | undefined;
  topLevelProvider?: string;
  topLevelThinking?: ThinkingLevel;
  perTaskProvider?: string;
  perTaskThinking?: ThinkingLevel;
}): EffectiveModelConfig {
  return {
    provider: options.perTaskProvider ?? options.topLevelProvider ?? options.agent?.provider,
    model: options.agent?.model,
    thinking: options.perTaskThinking ?? options.topLevelThinking ?? options.agent?.thinking ?? "medium",
  };
}

async function runSingleAgent(
  defaultCwd: string,
  agents: AgentConfig[],
  agentName: string,
  task: string,
  cwd: string | undefined,
  providerOverride: string | undefined,      // NEW
  thinkingOverride: ThinkingLevel | undefined, // NEW
  step: number | undefined,
  signal: AbortSignal | undefined,
  onUpdate: OnUpdateCallback | undefined,
  makeDetails: (results: SingleResult[]) => SubagentDetails,
): Promise<SingleResult> {
  const agent = agents.find((a) => a.name === agentName);
  // ...

  const effective = resolveEffectiveConfig({
    agent,
    topLevelProvider: /* top-level provider param */,
    topLevelThinking: /* top-level thinking param */,
    perTaskProvider: providerOverride,
    perTaskThinking: thinkingOverride,
  });

  const args: string[] = ["--mode", "json", "-p", "--no-session"];
  if (effective.provider) args.push("--provider", effective.provider);
  if (effective.model) args.push("--model", effective.model);
  if (effective.thinking !== "medium") args.push("--thinking", effective.thinking);
  if (agent.tools && agent.tools.length > 0) args.push("--tools", agent.tools.join(","));

  // ...
}
```

### 4. Update `SingleResult` and display (`index.ts`)

```typescript
interface SingleResult {
  agent: string;
  agentSource: "user" | "project" | "unknown";
  task: string;
  exitCode: number;
  messages: Message[];
  stderr: string;
  usage: UsageStats;
  provider?: string;     // NEW
  model?: string;
  thinking?: ThinkingLevel;  // NEW
  stopReason?: string;
  errorMessage?: string;
  step?: number;
}
```

After spawn, capture `provider` from messages if available. Update `formatUsageStats`:

```typescript
function formatUsageStats(usage: UsageStats, model?: string, provider?: string, thinking?: ThinkingLevel): string {
  const parts: string[] = [];
  if (usage.turns) parts.push(`${usage.turns} turn${usage.turns > 1 ? "s" : ""}`);
  if (usage.input) parts.push(`↑${formatTokens(usage.input)}`);
  if (usage.output) parts.push(`↓${formatTokens(usage.output)}`);
  if (usage.cacheRead) parts.push(`R${formatTokens(usage.cacheRead)}`);
  if (usage.cacheWrite) parts.push(`W${formatTokens(usage.cacheWrite)}`);
  if (usage.cost) parts.push(`$${usage.cost.toFixed(4)}`);
  if (usage.contextTokens && usage.contextTokens > 0) parts.push(`ctx:${formatTokens(usage.contextTokens)}`);
  if (provider && model) parts.push(`${provider}/${model}`);
  else if (model) parts.push(model);
  if (thinking && thinking !== "medium") parts.push(`think:${thinking}`);
  return parts.join(" ");
}
```

### 5. Update agent `.md` files

**`agents/reviewer.md`** — quality review wants strong reasoning on a pinned provider:

```yaml
---
name: reviewer
description: Code review specialist for quality and security analysis
tools: read, grep, find, ls, bash
provider: anthropic
model: claude-opus-4-7
thinking: high
---
```

**`agents/scout.md`** — fast recon, cheap provider, low thinking:

```yaml
---
name: scout
description: Fast codebase recon that returns compressed context
tools: read, grep, find, ls, bash
provider: google
model: gemini-3.1-flash
thinking: low
---
```

**`agents/planner.md`** — medium effort, pinned provider:

```yaml
---
name: planner
description: Creates implementation plans from context and requirements
tools: read, grep, find, ls
provider: anthropic
model: claude-sonnet-4-5
---
```

**`agents/worker.md`** — full capabilities, default thinking:

```yaml
---
name: worker
description: General-purpose subagent with full capabilities, isolated context
provider: anthropic
model: claude-sonnet-4-5
---
```

### 6. Update `renderCall` to show provider and thinking

```typescript
// In renderCall — show provider and thinking in the subagent call display
const agentConfig = agents.find(a => a.name === agentName);
const effectiveProvider = /* resolved provider */;
const effectiveThinking = /* resolved thinking */;

let meta = `[${scope}]`;
if (effectiveProvider) meta += ` ${effectiveProvider}`;
if (effectiveThinking && effectiveThinking !== "medium") meta += ` think:${effectiveThinking}`;
text += theme.fg("muted", meta);
```

### 7. Update README

Document the new frontmatter fields and invocation parameters:

```markdown
### Agent Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Agent identifier |
| `description` | Yes | Short description |
| `tools` | No | Comma-separated tool allowlist |
| `provider` | No | Pin agent to a specific provider (cost control) |
| `model` | No | Model ID or `provider/id:thinking` shorthand |
| `thinking` | No | Thinking level: off, minimal, low, medium, high, xhigh |

### Invocation Parameters

| Parameter | Level | Description |
|-----------|-------|-------------|
| `provider` | top-level, per-task | Override agent provider (cost control) |
| `thinking` | top-level, per-task | Override agent thinking level (quality/cost) |

### Resolution Priority (highest wins)

1. Per-task/per-chain-step parameter
2. Top-level invocation parameter
3. Agent definition frontmatter
4. Default (thinking: "medium", provider: resolved from model)

### Cost Control

Pin providers on agent definitions to prevent accidental routing:
\`\`\`yaml
provider: anthropic  # Always use Anthropic, never accidentally route to OpenAI
model: claude-opus-4-7
thinking: high
\`\`\`
```

## Files to Modify

| File | Change |
|------|--------|
| `packages/coding-agent/examples/extensions/subagent/agents.ts` | Add `provider`, `thinking` to `AgentConfig`; add `parseModelField()` for shorthand parsing; update `loadAgentsFromDir` |
| `packages/coding-agent/examples/extensions/subagent/index.ts` | Add `provider`/`thinking` to `SubagentParams`, `TaskItem`, `ChainItem`; add `resolveEffectiveConfig()`; update `runSingleAgent` signature and CLI args; add `provider`/`thinking` to `SingleResult`; update `formatUsageStats`, `renderCall`, `renderResult` |
| `packages/coding-agent/examples/extensions/subagent/agents/reviewer.md` | Add `provider: anthropic`, `model: claude-opus-4-7`, `thinking: high` |
| `packages/coding-agent/examples/extensions/subagent/agents/scout.md` | Add `provider: google`, `model: gemini-3.1-flash`, `thinking: low` |
| `packages/coding-agent/examples/extensions/subagent/agents/planner.md` | Add `provider: anthropic`, `model: claude-sonnet-4-5` |
| `packages/coding-agent/examples/extensions/subagent/agents/worker.md` | Add `provider: anthropic`, `model: claude-sonnet-4-5` |
| `packages/coding-agent/examples/extensions/subagent/README.md` | Document `provider`, `thinking` fields and resolution priority |

## Invocation Examples

```javascript
// Single: reviewer on opus with high thinking, pinned to anthropic (from agent def)
subagent({ agent: "reviewer", task: "Review the auth module" })

// Override thinking for deeper review
subagent({ agent: "reviewer", task: "Review the auth module", thinking: "xhigh" })

// Override provider — force cheap provider for a quick pass
subagent({ agent: "reviewer", task: "Quick lint check", provider: "google", thinking: "low" })

// Top-level defaults for all tasks in this call
subagent({ provider: "anthropic", thinking: "high", tasks: [
  { agent: "reviewer", task: "Review security" },
  { agent: "reviewer", task: "Review performance", thinking: "medium" },  // override thinking
]})

// Chain with per-step control
subagent({ chain: [
  { agent: "scout", task: "Find auth code" },                          // google/flash/low (from def)
  { agent: "planner", task: "Plan improvements using {previous}" },    // anthropic/sonnet/medium (from def)
  { agent: "reviewer", task: "Review plan from {previous}", thinking: "xhigh" },  // anthropic/opus/xhigh
]})
```

## Testing Plan

1. **Frontmatter parsing**: Test `parseModelField` with all styles:
   - `"anthropic/claude-opus-4-7:high"` → `{ provider: "anthropic", model: "claude-opus-4-7", thinking: "high" }`
   - `"claude-opus-4-7:high"` → `{ model: "claude-opus-4-7", thinking: "high" }`
   - `"anthropic/claude-opus-4-7"` → `{ provider: "anthropic", model: "claude-opus-4-7" }`
   - `"claude-opus-4-7"` → `{ model: "claude-opus-4-7" }`
   - `"openrouter/google/gemma-3:high"` → `{ provider: "openrouter", model: "google/gemma-3", thinking: "high" }`

2. **Priority resolution**: Test `resolveEffectiveConfig` with combinations:
   - Agent def has `provider: anthropic`, task override has `provider: google` → google wins
   - Agent def has `thinking: high`, top-level has `thinking: medium`, per-task has nothing → medium wins
   - Agent def has `thinking: high`, top-level has nothing, per-task has `thinking: xhigh` → xhigh wins

3. **CLI arg generation**: Verify spawned args:
   - `provider=anthropic, model=opus, thinking=high` → `["--provider", "anthropic", "--model", "opus", "--thinking", "high"]`
   - `thinking=medium` → no `--thinking` flag (default, omitted)
   - No provider → no `--provider` flag (model resolver handles it via `provider/id` in `--model`)

4. **Invalid values**: Invalid thinking level in frontmatter → agent skipped. Invalid thinking level in invocation → clear error returned.

## Open Questions

1. **Should `--provider` always be passed, even when `--model` already has a `provider/` prefix?**
   - Recommendation: Yes. `--provider` is more reliable than the model resolver's prefix inference. When both are set, `--provider` wins per the existing CLI behavior. This makes pinning explicit.

2. **Should we add a `provider` check that validates the provider name exists in the model registry?**
   - Recommendation: Not in the subagent extension — that's pi's job. If the provider is invalid, pi exits with an error and `runSingleAgent` captures it in `exitCode`/`stderr`.

3. **Should `thinking: "medium"` still pass `--thinking medium` to pi?**
   - Recommendation: Omit it. Medium is the default. Only pass `--thinking` when the level differs.

4. **Should the `provider` field also support being set from the `model` field's `provider/id` shorthand?**
   - Recommendation: Yes, with lower priority. If `model: "anthropic/opus:high"` is set and no explicit `provider` field exists, extract `provider: "anthropic"` from the shorthand. If an explicit `provider: "google"` exists, that wins.
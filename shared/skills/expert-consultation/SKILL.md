---
name: expert-consultation
description: Escalate hard problems to an expert subagent via delegate mode, or get unstuck via consult mode when you detect a loop. Uses a 3-tier consultation chain with structured triggers and directive (not advisory) pivots.
metadata:
  short-description: Delegate hard problems or consult when stuck — 3-tier expert escalation with loop detection
allowed-tools:
  - read
  - write
  - edit
  - bash
  - grep
  - ls
  - find
---

# Expert Consultation

This skill teaches you when and how to escalate to an expert subagent. You have two modes:

- **Delegate** — hand off a hard problem from the start (you know upfront this needs deep reasoning)
- **Consult** — get unstuck when you're caught in a loop (a trigger fires)

## Two Modes

| Mode | When | Input | Output |
|------|------|-------|--------|
| **Delegate** | Task is hard from the start — you know upfront this needs deep reasoning | Full problem description | Completed work |
| **Consult** | You hit a loop trigger after trying to solve something | Trigger ID + files + error + summary of attempts | MISCONCEPTION / PIVOT / EVIDENCE |

## Routing Table

Three expert tiers, used in order. Each consultation on the same issue moves to the next tier. Never consult the same model twice on the same issue.

| Category | Description | Model | Provider | Thinking |
|----------|-------------|-------|----------|----------|
| `expert (1st)` | Deep domain reasoning — delegate hard problems or consult when stuck. Primary expert. | deepseek-v4-pro | ollama-cloud | high |
| `expert (2nd)` | Expert consultation fallback — same issue, different perspective. Second consultation. | glm-5.1 | ollama-cloud | high |
| `expert (3rd)` | Expert consultation fallback — same issue, third architecture. Final consultation before user escalation. | kimi-k2.6 | opencode-go | high |

---

## Loop Triggers

Triggers are **file-scoped**: same file + same error class = same issue. A different file or different error class starts a *new* issue and resets the consultation counter.

| Trigger | ID | Threshold | Detection method |
|---------|-----|-----------|-----------------|
| Repeat edit | TR-REPEAT | 3 edits to overlapping area (±20 lines) in same file, partially reverting or re-attempting | Review edit history |
| Same error | TR-ERROR | 2 occurrences of the same error class after attempted fixes | Compare last 2 error outputs |
| Tool call plateau | TR-PLATEAU | 6+ consecutive tool calls without substantive text response to user | Count tool calls since last response |
| Approach recycling | TR-RECYCLE | Tried approach A, then B, then returned to A or near-variant | Review approach history |
| Turn budget | TR-TURNS | 8+ turns on a single file-scoped issue without resolution | Count turns since issue started |

### How to Detect Triggers

You must monitor yourself for these patterns. After every tool call, briefly check:

1. **TR-REPEAT**: Have I edited the same region of this file 3 times, with some edits partially reverting others?
2. **TR-ERROR**: Is this the second time I'm seeing the same error class after I tried to fix it?
3. **TR-PLATEAU**: Have I made 6+ consecutive tool calls without giving the user a substantive text response?
4. **TR-RECYCLE**: Did I abandon approach A for B, then come back to A or something very similar?
5. **TR-TURNS**: Have I spent 8+ turns on this same file and error without resolving it?

**Any single trigger fires** → halt your current approach and initiate a consultation.

---

## Consultation Protocol

### Step-by-step escalation

1. **Any trigger fires** → halt current approach immediately
2. **First consultation** → call `expert (1st)` via `subagent_run`, consult mode
3. **Specialist returns** → structured response: MISCONCEPTION / PIVOT / EVIDENCE
4. **Main model acts on pivot** — the pivot is **directive, not advisory** — you must follow it
5. **If still stuck on same file + same error** → call `expert (2nd)` with glm-5.1
6. **If still stuck** → call `expert (3rd)` with kimi-k2.6
7. **If still stuck after 3 consultations** → **escalate to user**, explain what was tried and all three pivots

### Issue Tracking

An **issue** is file-scoped: `same file + same error class = same issue`. A different file or a different error class = a **new issue**, which resets the consultation counter back to `expert (1st)`.

**Examples:**
- Stuck on `auth.py` with `ImportError` → issue #1, starts at `expert (1st)`
- Still stuck on `auth.py` with `ImportError` → same issue, escalate to `expert (2nd)`
- Now stuck on `auth.py` with `TypeError` → **new issue** (different error class), reset to `expert (1st)`
- Stuck on `utils.py` with `ImportError` → **new issue** (different file), reset to `expert (1st)`

---

## Consultation Payload

### Consult mode (when stuck)

Send this concise payload to the expert:

```
Trigger: [TR-REPEAT | TR-ERROR | TR-PLATEAU | TR-RECYCLE | TR-TURNS]
File: [path to the file you're stuck on]
Error: [the error output or failure signal]
Attempted approaches:
  - [approach 1 and result]
  - [approach 2 and result]
  - [approach 3 and result]
```

**Keep it short** — 3-5 lines max for the attempted approaches. The expert gets the trigger, file, error, and a summary. Not your entire conversation history.

### Delegate mode (hard problem from the start)

Send the full problem description:

```
Task: [complete description of what needs to be done]
Files: [relevant file paths]
Expected outcome: [what success looks like]
```

---

## Expert Output (consult mode)

The expert returns a structured response with three fields. **You must follow the PIVOT — it is a directive, not a suggestion.**

```
MISCONCEPTION: What you're getting wrong
PIVOT: The new direction to try
EVIDENCE: Why this is right (1-3 lines, with file:line if possible)
```

After receiving this response:
1. **Stop** your current approach entirely
2. **Adopt** the PIVOT direction as your new approach
3. **Do not** second-guess or partially apply the pivot — follow it fully
4. If the pivot resolves the issue, continue normally
5. If the same file + same error persists, escalate to the next expert tier

---

## Example: Consult Mode

```
subagent_run({
  name: "expert-consult-1",
  task: "I'm stuck on a bug in src/auth/session.py. Error: RuntimeError: Cannot refresh expired token after refresh attempt. I've tried: (1) Extending token TTL — still expired, (2) Forcing token refresh on 401 — infinite loop, (3) Bypassing refresh for expired tokens — auth failures. Trigger: TR-REPEAT (3 edits to same area with partial reverts). What am I missing?",
  systemPrompt: "You are an expert consultant. Diagnose the problem and return ONLY a structured response with MISCONCEPTION, PIVOT, and EVIDENCE fields. Be concise. Do not implement changes — only diagnose and redirect.",
  model: "deepseek-v4-pro",
  provider: "ollama-cloud",
  thinking: "high"
})
```

Second consultation (same issue, still stuck):

```
subagent_run({
  name: "expert-consult-2",
  task: "Still stuck on src/auth/session.py. Error: RuntimeError: Cannot refresh expired token after refresh attempt. First expert said: MISCONCEPTION: treating refresh as a recovery path instead of preemptive. PIVOT: refresh tokens proactively before expiry using a background scheduler. EVIDENCE: token_refresh() at line 47 only runs after 401. I implemented that but still hit the error when the scheduler misses a cycle. Trigger: TR-ERROR (same error class recurring). What now?",
  systemPrompt: "You are an expert consultant. Diagnose the problem and return ONLY a structured response with MISCONCEPTION, PIVOT, and EVIDENCE fields. Be concise. Do not implement changes — only diagnose and redirect.",
  model: "glm-5.1",
  provider: "ollama-cloud",
  thinking: "high"
})
```

Third consultation (same issue, still stuck):

```
subagent_run({
  name: "expert-consult-3",
  task: "Still stuck on src/auth/session.py. Error: RuntimeError: Cannot refresh expired token after refresh attempt. Two prior pivots failed: (1) proactive refresh via scheduler, (2) fallback to re-authentication on missed cycles. Both still trigger the RuntimeError under high load. Trigger: TR-RECYCLE (returned to refresh-based approach after trying re-auth). Third perspective needed.",
  systemPrompt: "You are an expert consultant. Diagnose the problem and return ONLY a structured response with MISCONCEPTION, PIVOT, and EVIDENCE fields. Be concise. Do not implement changes — only diagnose and redirect.",
  model: "kimi-k2.6",
  provider: "opencode-go",
  thinking: "high"
})
```

If still stuck after all three → escalate to user:

> I've consulted three expert models on the `src/auth/session.py` RuntimeError and tried the following pivots without success:
> 1. Proactive token refresh via background scheduler
> 2. Fallback re-authentication on missed refresh cycles
> 3. [third pivot from kimi-k2.6]
>
> This may require architectural changes beyond the current scope. How would you like to proceed?

---

## Example: Delegate Mode

When you know upfront a task requires deep expertise:

```
subagent_run({
  name: "expert-delegate",
  task: "Implement a lock-free concurrent queue for the event processing pipeline in src/queue/. Requirements: (1) Multi-producer, single-consumer, (2) Batch dequeue support, (3) Wait-free on the producer side, (4) Must compile under Go 1.24. Existing codebase uses sync.Mutex in src/queue/mutex_queue.go — the new implementation should be a drop-in replacement implementing the Queue interface defined there.",
  systemPrompt: "You are an expert implementer. Complete the assigned task autonomously. Read existing code for context, then implement the solution. Write production-quality code with edge-case handling.",
  model: "deepseek-v4-pro",
  provider: "ollama-cloud",
  thinking: "high",
  tools: "read,write,bash,edit"
})
```

---

## Key Rules

1. **Directive escalation** — Once you've escalated, you've conceded you need help. Act on the pivot. Do not second-guess the expert's advice.
2. **One consultation per model per issue** — Never consult the same model twice on the same issue. Move to the next model in the chain.
3. **File-scoped issue tracking** — Same file + same error class = same issue. Different file or different error = new issue, counter resets.
4. **Maximum 3 consultations per issue** — After 3 unsuccessful consultations, escalate to the user.
5. **Bite-sized consultations** — Keep the payload short. The expert gets trigger, file, error, and a summary. Not your entire conversation history.
6. **Structural triggers only** — Use observable patterns (edit counts, error repetition, tool counts) to detect loops. Do not rely on vague feelings of being stuck.
7. **Halt immediately on trigger** — When a trigger fires, stop your current approach. Don't finish the current attempt "just in case" — the trigger means your approach isn't working.
8. **Carry forward prior pivots** — When escalating to the 2nd or 3rd expert, include what prior experts recommended and why it didn't work. This avoids repeating the same dead ends.
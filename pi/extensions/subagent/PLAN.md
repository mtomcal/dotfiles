# Async Subagent Extension — Implementation Plan

Red/green TDD. Write the test first (red), make it pass (green), then refactor. Each section is a TDD cycle. Run tests after every green step to ensure nothing regresses.

## Architecture Overview

**Six tools** replace the current `subagent` tool:

| Tool | Purpose | Returns |
|------|---------|---------|
| `subagent_run` | Blocking — single, parallel, chain | Full result |
| `subagent_fork` | Async — start background job(s) | Job ID + summary |
| `subagent_status` | Check job status / list all | Lightweight summaries |
| `subagent_results` | Get full output of a job | All messages + usage |
| `subagent_wait` | Block until job completes | Full result |
| `subagent_cancel` | Cancel one or all jobs | Confirmation |

**Key invariants:**
- Max 8 concurrent async jobs
- Job ID format: `{agentName}-{shortRandom}` (e.g. `code-reviewer-a3f2`)
- Blocking mode on `subagent_run` (current behavior, unchanged)
- Fork always returns immediately
- Completion notifications via `pi.sendMessage({ deliverAs: "steer", triggerTurn: true })`
- Notification content: final assistant message + full usage stats (smart hybrid)
- `confirmProjectAgents` skipped for `subagent_fork`
- Running jobs killed on `session_shutdown`, completed persisted via `appendEntry`

---

## Cycle 1: Job Manager Core

The in-memory job tracker. No Pi extension yet — pure TypeScript state management.

### Red: Write failing tests

```typescript
// tests/job-manager.test.ts

describe("JobManager", () => {
  test("createJob assigns agent-prefixed ID and status running", () => {
    const mgr = new JobManager();
    const job = mgr.createJob("code-reviewer", "Review auth module");
    expect(job.id).toMatch(/^code-reviewer-[a-z0-9]{4}$/);
    expect(job.agent).toBe("code-reviewer");
    expect(job.task).toBe("Review auth module");
    expect(job.status).toBe("running");
  });

  test("createJob throws if 8 jobs already running", () => {
    const mgr = new JobManager();
    for (let i = 0; i < 8; i++) {
      mgr.createJob("agent", `Task ${i}`);
    }
    expect(() => mgr.createJob("agent", "Task 9")).toThrow(/maximum/i);
  });

  test("completeJob transitions running to completed", () => {
    const mgr = new JobManager();
    const job = mgr.createJob("reviewer", "Review");
    const fakeResult = { exitCode: 0, messages: [], usage: { ... } };
    mgr.completeJob(job.id, fakeResult);
    expect(mgr.getJob(job.id)!.status).toBe("completed");
    expect(mgr.getJob(job.id)!.result).toBe(fakeResult);
  });

  test("failJob transitions running to failed", () => {
    const mgr = new JobManager();
    const job = mgr.createJob("reviewer", "Review");
    mgr.failJob(job.id, "Process exited with code 1");
    expect(mgr.getJob(job.id)!.status).toBe("failed");
  });

  test("cancelJob sends SIGTERM and marks cancelled", () => {
    const mgr = new JobManager();
    const mockProc = { kill: vi.fn(), killed: false } as any;
    const job = mgr.createJob("reviewer", "Review");
    mgr.setProcess(job.id, mockProc);
    mgr.cancelJob(job.id);
    expect(mockProc.kill).toHaveBeenCalledWith("SIGTERM");
    expect(mgr.getJob(job.id)!.status).toBe("cancelled");
  });

  test("cancelAll cancels all running jobs", () => {
    const mgr = new JobManager();
    const job1 = mgr.createJob("a", "task1");
    const job2 = mgr.createJob("b", "task2");
    mgr.completeJob(job1.id, fakeResult);
    const job3 = mgr.createJob("c", "task3");
    mgr.cancelAll();
    expect(mgr.getJob(job2.id)!.status).toBe("cancelled");
    expect(mgr.getJob(job3.id)!.status).toBe("cancelled");
    expect(mgr.getJob(job1.id)!.status).toBe("completed"); // untouched
  });

  test("listJobs returns all jobs", () => {
    const mgr = new JobManager();
    mgr.createJob("a", "task1");
    mgr.createJob("b", "task2");
    expect(mgr.listJobs()).toHaveLength(2);
  });

  test("listRunning returns only running jobs", () => {
    const mgr = new JobManager();
    const j1 = mgr.createJob("a", "task1");
    const j2 = mgr.createJob("b", "task2");
    mgr.completeJob(j1.id, fakeResult);
    expect(mgr.listRunning()).toHaveLength(1);
    expect(mgr.listRunning()[0].id).toBe(j2.id);
  });

  test("serialize/deserialize roundtrips for appendEntry", () => {
    const mgr = new JobManager();
    const job = mgr.createJob("reviewer", "Review");
    mgr.completeJob(job.id, fakeResult);
    const data = mgr.serialize();
    const mgr2 = new JobManager();
    mgr2.deserialize(data);
    expect(mgr2.getJob(job.id)!.status).toBe("completed");
  });
});
```

### Green: Implement JobManager

```typescript
// src/job-manager.ts

import { randomBytes } from "node:crypto";
import type { ChildProcess } from "node:child_process";

export interface AsyncJob {
  id: string;
  agent: string;
  task: string;
  status: "running" | "completed" | "failed" | "cancelled";
  process: ChildProcess | null;
  result: SingleResult | null;
  startedAt: number;
  completedAt: number | null;
}

export class JobManager {
  private jobs = new Map<string, AsyncJob>();
  private static MAX_RUNNING = 8;

  createJob(agentName: string, task: string): AsyncJob {
    const running = this.listRunning();
    if (running.length >= JobManager.MAX_RUNNING) {
      throw new Error(`Maximum ${JobManager.MAX_RUNNING} concurrent async jobs. Cancel a job or wait for one to complete.`);
    }
    const id = `${agentName}-${randomBytes(2).toString("hex")}`;
    const job: AsyncJob = {
      id,
      agent: agentName,
      task,
      status: "running",
      process: null,
      result: null,
      startedAt: Date.now(),
      completedAt: null,
    };
    this.jobs.set(id, job);
    return job;
  }

  setProcess(jobId: string, proc: ChildProcess): void {
    const job = this.jobs.get(jobId);
    if (job) job.process = proc;
  }

  completeJob(jobId: string, result: SingleResult): void {
    const job = this.jobs.get(jobId);
    if (job && job.status === "running") {
      job.status = "completed";
      job.result = result;
      job.completedAt = Date.now();
      job.process = null;
    }
  }

  failJob(jobId: string, error: string): void {
    const job = this.jobs.get(jobId);
    if (job && job.status === "running") {
      job.status = "failed";
      job.result = job.result ?? {
        agent: job.agent,
        agentSource: "unknown",
        task: job.task,
        exitCode: 1,
        messages: [],
        stderr: error,
        usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
        errorMessage: error,
      };
      job.completedAt = Date.now();
      job.process = null;
    }
  }

  cancelJob(jobId: string): void {
    const job = this.jobs.get(jobId);
    if (job && job.status === "running") {
      job.process?.kill("SIGTERM");
      job.status = "cancelled";
      job.completedAt = Date.now();
      job.process = null;
    }
  }

  cancelAll(): void {
    for (const job of this.jobs.values()) {
      if (job.status === "running") {
        job.process?.kill("SIGTERM");
        job.status = "cancelled";
        job.completedAt = Date.now();
        job.process = null;
      }
    }
  }

  getJob(id: string): AsyncJob | undefined {
    return this.jobs.get(id);
  }

  listJobs(): AsyncJob[] {
    return Array.from(this.jobs.values());
  }

  listRunning(): AsyncJob[] {
    return Array.from(this.jobs.values()).filter((j) => j.status === "running");
  }

  serialize(): SerializedJob[] {
    return Array.from(this.jobs.values()).map((j) => ({
      id: j.id,
      agent: j.agent,
      task: j.task,
      status: j.status,
      result: j.result,
      startedAt: j.startedAt,
      completedAt: j.completedAt,
    }));
  }

  deserialize(data: SerializedJob[]): void {
    this.jobs.clear();
    for (const d of data) {
      const job: AsyncJob = {
        ...d,
        process: null, // processes don't survive restart
      };
      this.jobs.set(d.id, job);
    }
  }
}
```

### Refactor: Clean up, extract constants, ensure test coverage is complete.

---

## Cycle 2: Fork — Spawn Background Jobs

The `subagent_fork` tool that starts child `pi` processes and returns immediately.

### Red: Write failing tests

```typescript
// tests/subagent-fork.test.ts

describe("subagent_fork", () => {
  test("spawns single background job and returns job ID", async () => {
    const { callTool } = setupExtension();
    const result = await callTool("subagent_fork", {
      agent: "code-reviewer",
      task: "Review the auth module",
    });
    expect(result.content[0].text).toMatch(/forked/i);
    expect(result.content[0].text).toMatch(/code-reviewer-[a-z0-9]{4}/);
    expect(result.details.jobs).toHaveLength(1);
    expect(result.details.jobs[0].status).toBe("running");
  });

  test("spawns multiple jobs with tasks array", async () => {
    const { callTool } = setupExtension();
    const result = await callTool("subagent_fork", {
      tasks: [
        { agent: "code-reviewer", task: "Review auth" },
        { agent: "test-writer", task: "Write tests" },
      ],
    });
    expect(result.content[0].text).toMatch(/2 jobs/);
    expect(result.details.jobs).toHaveLength(2);
  });

  test("rejects when 8 jobs already running", async () => {
    const { callTool } = setupExtension();
    // Fill up 8 jobs
    for (let i = 0; i < 8; i++) {
      await callTool("subagent_fork", { agent: "agent", task: `Task ${i}` });
    }
    const result = await callTool("subagent_fork", { agent: "agent", task: "Task 9" });
    expect(result.content[0].text).toMatch(/maximum/i);
    expect(result.isError).toBe(true);
  });

  test("skips project agent confirmation for fork", async () => {
    const { callTool, ui } = setupExtension({ projectAgents: true });
    const result = await callTool("subagent_fork", {
      agent: "project-agent",
      task: "Do something",
      confirmProjectAgents: true,
    });
    expect(ui.confirm).not.toHaveBeenCalled();
    expect(result.content[0].text).toMatch(/forked/i);
  });

  test("returns running count in response", async () => {
    const { callTool } = setupExtension();
    await callTool("subagent_fork", { agent: "a", task: "task1" });
    const result = await callTool("subagent_fork", { agent: "b", task: "task2" });
    expect(result.content[0].text).toMatch(/2\/8/);
  });
});
```

### Green: Implement subagent_fork

- Register the `subagent_fork` tool in the extension
- On execute: create job entries via `JobManager.createJob()`
- Spawn child `pi --mode json -p --no-session` processes (reuse `runSingleAgent` process spawning, but don't await the exit code)
- Parse stdout JSON stream as it arrives, update job state on `message_end` and `tool_result_end` events
- On job completion: call `jobMgr.completeJob()` or `jobMgr.failJob()`, then `pi.sendMessage()` with notification
- Return immediately with job ID, agent name, task summary, running count
- No `confirmProjectAgents` dialog (skip for async)

### Refactor: Extract shared process spawning logic between `subagent_run` and `subagent_fork`.

---

## Cycle 3: Completion Notification

The background job completes and the model finds out.

### Red: Write failing tests

```typescript
// tests/notification.test.ts

describe("completion notification", () => {
  test("sends steer message when background job completes", async () => {
    const { jobMgr, sentMessages } = setupExtension();
    const job = jobMgr.createJob("reviewer", "Review auth");
    // Simulate completion
    const result = fakeSingleResult({ agent: "reviewer", exitCode: 0 });
    jobMgr.completeJob(job.id, result);
    emitCompletionNotification(job.id);

    expect(sentMessages).toHaveLength(1);
    expect(sentMessages[0].customType).toBe("subagent-result");
    expect(sentMessages[0].content).toContain("reviewer");
    expect(sentMessages[0].content).toContain("completed");
    expect(sentMessages[0].details.jobId).toBe(job.id);
    expect(sentMessages[0].details.mode).toBe("single");
  });

  test("notification includes final assistant message, not raw tool calls", async () => {
    const { jobMgr, sentMessages } = setupExtension();
    const job = jobMgr.createJob("reviewer", "Review");
    const result = fakeSingleResult({
      agent: "reviewer",
      messages: [
        { role: "assistant", content: [{ type: "toolCall", name: "bash", arguments: { command: "ls" } }] },
        { role: "assistant", content: [{ type: "text", text: "Here is my review: looks good." }] },
      ],
    });
    jobMgr.completeJob(job.id, result);
    emitCompletionNotification(job.id);

    expect(sentMessages[0].content).toContain("Here is my review: looks good.");
    expect(sentMessages[0].content).not.toContain("toolCall");
  });

  test("notification includes full usage stats", async () => {
    const { jobMgr, sentMessages } = setupExtension();
    const job = jobMgr.createJob("reviewer", "Review");
    const result = fakeSingleResult({
      usage: { input: 5000, output: 1200, cacheRead: 3000, cacheWrite: 800, cost: 0.0342, contextTokens: 0, turns: 3 },
    });
    jobMgr.completeJob(job.id, result);
    emitCompletionNotification(job.id);

    expect(sentMessages[0].content).toContain("3 turns");
    expect(sentMessages[0].content).toContain("$0.0342");
  });

  test("failed job notification includes error message", async () => {
    const { jobMgr, sentMessages } = setupExtension();
    const job = jobMgr.createJob("reviewer", "Review");
    jobMgr.failJob(job.id, "Process exited with code 1");
    emitCompletionNotification(job.id);

    expect(sentMessages[0].content).toContain("failed");
    expect(sentMessages[0].content).toContain("Process exited with code 1");
  });

  test("triggerTurn is true and deliverAs is steer", async () => {
    const { jobMgr, sendMessageOptions } = setupExtension();
    const job = jobMgr.createJob("reviewer", "Review");
    jobMgr.completeJob(job.id, fakeResult);
    emitCompletionNotification(job.id);

    expect(sendMessageOptions[0].triggerTurn).toBe(true);
    expect(sendMessageOptions[0].deliverAs).toBe("steer");
  });
});
```

### Green: Implement notification emission

- In the child process exit handler: call `jobMgr.completeJob()` or `jobMgr.failJob()`, then call `pi.sendMessage()`
- Build notification content: final assistant message (smart hybrid — extract last assistant text, skip intermediate tool calls), full usage stats, job ID, status
- Set `customType: "subagent-result"`, `display: true`
- Set `triggerTurn: true`, `deliverAs: "steer"`

### Refactor: Extract notification formatting into a reusable function.

---

## Cycle 4: Status and Results Tools

The model checks on its jobs.

### Red: Write failing tests

```typescript
// tests/subagent-status.test.ts

describe("subagent_status", () => {
  test("lists all jobs when no jobId provided", async () => {
    const { callTool, jobMgr } = setupExtension();
    jobMgr.createJob("reviewer", "Review auth");
    jobMgr.createJob("writer", "Write tests");
    const result = await callTool("subagent_status", {});
    expect(result.content[0].text).toContain("2 jobs");
    expect(result.content[0].text).toContain("reviewer");
    expect(result.content[0].text).toContain("writer");
  });

  test("shows specific job status with jobId", async () => {
    const { callTool, jobMgr } = setupExtension();
    const job = jobMgr.createJob("reviewer", "Review auth");
    const result = await callTool("subagent_status", { jobId: job.id });
    expect(result.content[0].text).toContain("running");
    expect(result.content[0].text).toContain("Review auth");
  });

  test("includes elapsed time for running jobs", async () => {
    const { callTool, jobMgr } = setupExtension();
    const job = jobMgr.createJob("reviewer", "Review");
    // Simulate some elapsed time
    job.startedAt = Date.now() - 45000;
    const result = await callTool("subagent_status", { jobId: job.id });
    expect(result.content[0].text).toContain("45s");
  });

  test("includes summary for completed jobs", async () => {
    const { callTool, jobMgr } = setupExtension();
    const job = jobMgr.createJob("reviewer", "Review auth");
    jobMgr.completeJob(job.id, fakeSingleResult({
      messages: [{ role: "assistant", content: [{ type: "text", text: "Looks good." }] }],
    }));
    const result = await callTool("subagent_status", { jobId: job.id });
    expect(result.content[0].text).toContain("completed");
    expect(result.content[0].text).toContain("Looks good");
  });
});

describe("subagent_results", () => {
  test("returns full messages for completed job", async () => {
    const { callTool, jobMgr } = setupExtension();
    const job = jobMgr.createJob("reviewer", "Review auth");
    const result = fakeSingleResult({
      messages: [
        { role: "assistant", content: [{ type: "toolCall", name: "bash", arguments: { command: "ls" } }] },
        { role: "assistant", content: [{ type: "text", text: "Here is my review: looks good." }] },
      ],
    });
    jobMgr.completeJob(job.id, result);
    const status = await callTool("subagent_results", { jobId: job.id });
    expect(status.content[0].text).toContain("Here is my review: looks good.");
    expect(status.content[0].text).toContain("bash");
    expect(status.details).toBeDefined();
  });

  test("returns error for still-running job", async () => {
    const { callTool, jobMgr } = setupExtension();
    const job = jobMgr.createJob("reviewer", "Review");
    const result = await callTool("subagent_results", { jobId: job.id });
    expect(result.isError).toBe(true);
    expect(result.content[0].text).toMatch(/still running/i);
  });

  test("returns error for unknown jobId", async () => {
    const { callTool } = setupExtension();
    const result = await callTool("subagent_results", { jobId: "nonexistent-xxxx" });
    expect(result.isError).toBe(true);
    expect(result.content[0].text).toMatch(/not found/i);
  });
});
```

### Green: Implement subagent_status and subagent_results

- `subagent_status`: if no `jobId`, format a listing of all jobs with status, agent, task (truncated), elapsed time for running, summary for completed. If `jobId` provided, detailed status of that job.
- `subagent_results`: look up job by ID, return error if running or not found, return full `SingleResult` (messages, usage, etc.) if completed.
- Both use the `JobManager` instance from the extension's shared state.

### Refactor: Extract shared job-lookup error handling. Ensure status rendering is consistent.

---

## Cycle 5: Wait and Cancel Tools

### Red: Write failing tests

```typescript
// tests/subagent-wait.test.ts

describe("subagent_wait", () => {
  test("returns immediately if job already completed", async () => {
    const { callTool, jobMgr } = setupExtension();
    const job = jobMgr.createJob("reviewer", "Review");
    jobMgr.completeJob(job.id, fakeSingleResult({ exitCode: 0 }));
    const result = await callTool("subagent_wait", { jobId: job.id });
    expect(result.content[0].text).toContain("completed");
    expect(result.details.results[0].exitCode).toBe(0);
  });

  test("waits for running job to complete, then returns result", async () => {
    const { callTool, jobMgr } = setupExtension();
    const job = jobMgr.createJob("reviewer", "Review");
    // Simulate completion after a delay
    setTimeout(() => {
      jobMgr.completeJob(job.id, fakeSingleResult({ exitCode: 0 }));
    }, 100);
    const result = await callTool("subagent_wait", { jobId: job.id, timeout: 5 });
    expect(result.content[0].text).toContain("completed");
  });

  test("times out if job doesn't complete within timeout", async () => {
    const { callTool, jobMgr } = setupExtension();
    const job = jobMgr.createJob("reviewer", "Review");
    const result = await callTool("subagent_wait", { jobId: job.id, timeout: 1 });
    expect(result.content[0].text).toMatch(/still running|timed out/i);
  });

  test("returns error for unknown jobId", async () => {
    const { callTool } = setupExtension();
    const result = await callTool("subagent_wait", { jobId: "nonexistent-xxxx" });
    expect(result.isError).toBe(true);
    expect(result.content[0].text).toMatch(/not found/i);
  });
});

// tests/subagent-cancel.test.ts

describe("subagent_cancel", () => {
  test("cancels a specific running job", async () => {
    const { callTool, jobMgr } = setupExtension();
    const job = jobMgr.createJob("reviewer", "Review");
    const mockProc = { kill: vi.fn() } as any;
    jobMgr.setProcess(job.id, mockProc);
    const result = await callTool("subagent_cancel", { jobId: job.id });
    expect(result.content[0].text).toMatch(/cancelled/i);
    expect(mockProc.kill).toHaveBeenCalledWith("SIGTERM");
    expect(jobMgr.getJob(job.id)!.status).toBe("cancelled");
  });

  test("cancels all running jobs with all: true", async () => {
    const { callTool, jobMgr } = setupExtension();
    const j1 = jobMgr.createJob("a", "task1");
    const j2 = jobMgr.createJob("b", "task2");
    const result = await callTool("subagent_cancel", { all: true });
    expect(result.content[0].text).toMatch(/2.*cancelled/i);
    expect(jobMgr.getJob(j1.id)!.status).toBe("cancelled");
    expect(jobMgr.getJob(j2.id)!.status).toBe("cancelled");
  });

  test("returns error for cancelled or completed job", async () => {
    const { callTool, jobMgr } = setupExtension();
    const job = jobMgr.createJob("reviewer", "Review");
    jobMgr.completeJob(job.id, fakeSingleResult({ exitCode: 0 }));
    const result = await callTool("subagent_cancel", { jobId: job.id });
    expect(result.isError).toBe(true);
    expect(result.content[0].text).toMatch(/not running/i);
  });
});
```

### Green: Implement subagent_wait and subagent_cancel

- `subagent_wait`: look up job, if completed return immediately. If running, poll `JobManager` with a sleep loop until complete or timeout (default 300s). Use `AbortSignal` from `ctx.signal` for cancellation.
- `subagent_cancel`: look up job(s), send SIGTERM to child process, mark as cancelled. `all: true` cancels all running.

### Refactor: Extract SIGTERM+SIGKILL timeout logic (reuse from current `runSingleAgent` abort handling).

---

## Cycle 6: subagent_run (Blocking Replacement)

Replacing the old `subagent` tool with `subagent_run`, preserving all three modes.

### Red: Write failing tests

```typescript
// tests/subagent-run.test.ts

describe("subagent_run", () => {
  test("single mode: runs agent and returns result", async () => {
    const { callTool } = setupExtension();
    const result = await callTool("subagent_run", {
      agent: "code-reviewer",
      task: "Review the auth module",
    });
    expect(result.content[0].text).toContain("review");
    expect(result.details.mode).toBe("single");
  });

  test("parallel mode: runs multiple agents concurrently", async () => {
    const { callTool } = setupExtension();
    const result = await callTool("subagent_run", {
      tasks: [
        { agent: "code-reviewer", task: "Review auth" },
        { agent: "test-writer", task: "Write tests" },
      ],
    });
    expect(result.details.mode).toBe("parallel");
    expect(result.details.results).toHaveLength(2);
  });

  test("chain mode: runs agents sequentially with {previous}", async () => {
    const { callTool } = setupExtension();
    const result = await callTool("subagent_run", {
      chain: [
        { agent: "planner", task: "Plan the feature" },
        { agent: "coder", task: "Implement based on: {previous}" },
      ],
    });
    expect(result.details.mode).toBe("chain");
    expect(result.details.results).toHaveLength(2);
  });

  test("confirms project agents when confirmProjectAgents is true", async () => {
    const { callTool, ui } = setupExtension({ projectAgents: true });
    vi.spyOn(ui, "confirm").mockResolvedValue(true);
    await callTool("subagent_run", {
      agent: "project-agent",
      task: "Do something",
      confirmProjectAgents: true,
    });
    expect(ui.confirm).toHaveBeenCalled();
  });

  test("provider and thinking overrides are passed through", async () => {
    const { callTool, lastSpawnArgs } = setupExtension();
    await callTool("subagent_run", {
      agent: "reviewer",
      task: "Review",
      provider: "anthropic",
      thinking: "high",
    });
    expect(lastSpawnArgs).toContain("--provider");
    expect(lastSpawnArgs).toContain("anthropic");
    expect(lastSpawnArgs).toContain("--thinking");
    expect(lastSpawnArgs).toContain("high");
  });
});
```

### Green: Implement subagent_run

- Port the current `subagent` tool's execute logic to `subagent_run`
- Reuse `runSingleAgent`, `mapWithConcurrencyLimit`, chain logic, project agent confirmation
- Support `provider` and `thinking` per-task and top-level overrides (already in current code)
- Render `renderCall` and `renderResult` adapted from current tool

### Refactor: Remove old `subagent` tool registration. Delete dead code.

---

## Cycle 7: Fork Parallel Support

Multiple jobs in one `subagent_fork` call.

### Red: Write failing tests

```typescript
// tests/subagent-fork-parallel.test.ts

describe("subagent_fork parallel", () => {
  test("spawns multiple jobs with tasks array", async () => {
    const { callTool, jobMgr } = setupExtension();
    const result = await callTool("subagent_fork", {
      tasks: [
        { agent: "code-reviewer", task: "Review auth" },
        { agent: "test-writer", task: "Write tests" },
        { agent: "security", task: "Check vulnerabilities" },
      ],
    });
    expect(result.content[0].text).toMatch(/3.*jobs/);
    expect(result.details.jobs).toHaveLength(3);
    expect(result.details.jobs[0].status).toBe("running");
    expect(result.details.jobs[1].status).toBe("running");
    expect(result.details.jobs[2].status).toBe("running");
  });

  test("enforces 8-job cap across fork calls", async () => {
    const { callTool, jobMgr } = setupExtension();
    // Spawn 6 in one call
    await callTool("subagent_fork", {
      tasks: Array.from({ length: 6 }, (_, i) => ({ agent: "agent", task: `Task ${i}` })),
    });
    // Spawn 2 more in another call
    const result = await callTool("subagent_fork", {
      tasks: [
        { agent: "agent", task: "Task X" },
        { agent: "agent", task: "Task Y" },
      ],
    });
    expect(result.details.jobs).toHaveLength(2);
    // Now try to spawn 1 more — should fail
    const fail = await callTool("subagent_fork", { agent: "agent", task: "Task Z" });
    expect(fail.isError).toBe(true);
    expect(fail.content[0].text).toMatch(/maximum/i);
  });

  test("per-task provider/thinking overrides", async () => {
    const { callTool } = setupExtension();
    const result = await callTool("subagent_fork", {
      tasks: [
        { agent: "reviewer", task: "Review", provider: "anthropic" },
        { agent: "writer", task: "Write", thinking: "high" },
      ],
    });
    expect(result.content[0].text).toMatch(/forked/i);
  });
});
```

### Green: Implement parallel fork spawning

- Accept `tasks` array in `subagent_fork` parameters
- Loop through tasks, create job for each, spawn child process
- Enforce combined 8-job cap (check `jobMgr.listRunning().length` before each spawn)
- Return summary: `{count} jobs forked`, listing each job ID, agent, task (truncated), running count

### Refactor: Ensure provider/thinking resolution logic is shared between `subagent_run` and `subagent_fork`.

---

## Cycle 8: Message Renderer for Completion Notifications

Custom TUI rendering for `subagent-result` messages so they look nice instead of raw JSON.

### Red: Write failing tests (visual / snapshot)

```typescript
// tests/notification-renderer.test.ts

describe("subagent-result message renderer", () => {
  test("renders completion card with agent name, status, task, and usage", () => {
    const renderer = getRenderer("subagent-result");
    const message = {
      customType: "subagent-result",
      content: "...",
      details: {
        jobId: "code-reviewer-a3f2",
        status: "completed",
        agent: "code-reviewer",
        task: "Review the auth module",
        summary: "The auth module looks good overall...",
        usage: { input: 5000, output: 1200, turns: 3, cost: 0.0342 },
      },
    };
    const component = renderer(message, { expanded: false }, theme);
    // Verify it renders as a Container or Text with expected content
    expect(component).toBeDefined();
    expect(extractText(component)).toContain("code-reviewer");
    expect(extractText(component)).toContain("completed");
  });
});
```

### Green: Implement message renderer

- Register via `pi.registerMessageRenderer("subagent-result", ...)`
- Render a compact card: `✓ code-reviewer-a3f2 (completed) — 3 turns, $0.0342`
- Expanded view: full task, summary, usage breakdown
- Use theme colors for status icons: ✓ green, ✗ red, ⏳ yellow (for running if renderer is ever called mid-stream)
- Running status unlikely in renderer (notifications only fire on completion) but handle gracefully

### Refactor: Reuse `formatUsageStats` from the current subagent extension.

---

## Cycle 9: Session Lifecycle (Shutdown, Startup, Persistence)

### Red: Write failing tests

```typescript
// tests/lifecycle.test.ts

describe("session lifecycle", () => {
  test("cancels all running jobs on session_shutdown", () => {
    const { jobMgr, extension } = setupExtension();
    jobMgr.createJob("a", "Task 1");
    jobMgr.createJob("b", "Task 2");
    extension.emit("session_shutdown", { reason: "quit" });
    expect(jobMgr.listRunning()).toHaveLength(0);
    expect(jobMgr.listJobs().every((j) => j.status === "cancelled")).toBe(true);
  });

  test("restores completed jobs on session_start", () => {
    const { jobMgr, extension, appendEntries } = setupExtension();
    const job = jobMgr.createJob("reviewer", "Review");
    jobMgr.completeJob(job.id, fakeResult);
    // Simulate restart
    extension.emit("session_shutdown", { reason: "reload" });
    const newMgr = new JobManager();
    newMgr.deserialize(appendEntries.lastSaved);
    extension.emit("session_start", { reason: "reload" });
    expect(newMgr.getJob(job.id)!.status).toBe("completed");
    expect(newMgr.getJob(job.id)!.result).toBeDefined();
  });

  test("running jobs are marked cancelled after restart (no orphan processes)", () => {
    const { jobMgr, appendEntries } = setupExtension();
    jobMgr.createJob("a", "Running task"); // running, no result
    const restored = appendEntries.lastSaved.filter((e) => e.status !== "running");
    // After restore, running jobs have no process — they're cancelled
    for (const j of restored) {
      if (j.status === "running") expect(j.status).toBe("cancelled");
    }
  });
});
```

### Green: Implement lifecycle events

- `session_shutdown`: call `jobMgr.cancelAll()`, SIGTERM all child processes
- `session_start`: restore completed/failed jobs from `appendEntry` entries. Mark any "running" entries as "cancelled" (orphaned from previous session).
- On `appendEntry`: serialize `jobMgr.serialize()` after each state change (create, complete, fail, cancel)

### Refactor: Ensure serialization doesn't include `ChildProcess` objects. Clean up partial state on error.

---

## Cycle 10: Tool Descriptions and Prompt Guidelines

The system prompt content that teaches the model how to use the tools.

### Red: Write the descriptions (they exist as strings, test by checking they're registered)

```typescript
// tests/tool-registration.test.ts

describe("tool registration", () => {
  test("all six tools are registered", () => {
    const { tools } = setupExtension();
    const names = tools.map((t) => t.name);
    expect(names).toContain("subagent_run");
    expect(names).toContain("subagent_fork");
    expect(names).toContain("subagent_status");
    expect(names).toContain("subagent_results");
    expect(names).toContain("subagent_wait");
    expect(names).toContain("subagent_cancel");
  });

  test("subagent_fork has workflow-oriented promptGuidelines", () => {
    const { tools } = setupExtension();
    const fork = tools.find((t) => t.name === "subagent_fork");
    expect(fork.promptGuidelines).toBeDefined();
    expect(fork.promptGuidelines.join(" ")).toContain("continue");
    expect(fork.promptGuidelines.join(" ")).toContain("notification");
  });

  test("subagent_run has no async references in description", () => {
    const { tools } = setupExtension();
    const run = tools.find((t) => t.name === "subagent_run");
    expect(run.description).not.toContain("fork");
    expect(run.description).not.toContain("background");
  });
});
```

### Green: Write the descriptions

```typescript
// subagent_run
description: "Run a subagent synchronously. Modes: single (agent + task), parallel (tasks array), chain (sequential with {previous} placeholder). Blocks until completion.",
promptSnippet: "Run subagent tasks and get results immediately",
promptGuidelines: [
  "Use subagent_run for blocking tasks where you need the result before continuing.",
  "Use subagent_fork instead when you want to start background work and continue your turn.",
],

// subagent_fork
description: "Start one or more background subagent jobs. Returns immediately with job IDs. You receive a completion notification when each job finishes. Max 8 concurrent jobs.",
promptSnippet: "Fork background subagent jobs, continue working while they run",
promptGuidelines: [
  "Use subagent_fork when you want to start work and continue your turn without waiting.",
  "After forking, continue your work. You will receive a completion notification for each job with a summary and usage stats.",
  "When you receive a notification, call subagent_results with the jobId only if you need the full detail beyond the summary.",
  "You may have up to 8 background jobs running at once. Check with subagent_status before forking more.",
  "Use subagent_run when you need the result immediately. Use subagent_fork when you can work on other things in parallel.",
],

// subagent_status
description: "Check the status of background subagent jobs. With no arguments, lists all jobs. With a jobId, shows details for that specific job.",
promptSnippet: "Check subagent job status",
promptGuidelines: [
  "Use subagent_status to check on your background jobs.",
  "Call without arguments to see an overview of all jobs (running, completed, failed).",
  "You don't need to poll — you will be notified when each job completes.",
],

// subagent_results
description: "Retrieve the full output of a completed subagent job, including all messages and tool calls. The job must be completed (not running).",
promptSnippet: "Get full subagent job results",
promptGuidelines: [
  "Use subagent_results when you need the complete output of a job, including intermediate tool calls and full messages.",
  "The completion notification already includes a summary. Only call subagent_results if you need more detail.",
  "subagent_results returns an error if the job is still running. Use subagent_wait to block until completion.",
],

// subagent_wait
description: "Block until a specific background job completes. Default timeout is 300 seconds (5 minutes). Returns the full result when done.",
promptSnippet: "Wait for a subagent job to complete",
promptGuidelines: [
  "Use subagent_wait when you need the result of a background job and can't continue without it.",
  "Prefer waiting for the completion notification instead of calling subagent_wait — only use it when you explicitly need to block.",
  "The timeout defaults to 300 seconds. Specify a longer timeout for heavy tasks.",
],

// subagent_cancel
description: "Cancel a running background job by ID, or cancel all running jobs with all: true.",
promptSnippet: "Cancel subagent jobs",
promptGuidelines: [
  "Use subagent_cancel to stop a background job you no longer need.",
  "Use all: true to cancel all running jobs at once.",
  "Completed and failed jobs cannot be cancelled.",
],
```

### Refactor: Tighten descriptions to be concise. Ensure no overlap between tool descriptions.

---

## Cycle 11: Rendering Consistency

Adapt `renderCall` and `renderResult` from the old `subagent` tool for `subagent_run`. Add minimal rendering for the new tools.

### Red: Write snapshot/regression tests for render output

```typescript
// tests/rendering.test.ts

describe("renderCall for subagent_run", () => {
  test("single mode renders agent name and task", () => {
    const { renderCall } = setupExtension();
    const component = renderCall("subagent_run", { agent: "reviewer", task: "Review auth" });
    expect(extractText(component)).toContain("reviewer");
    expect(extractText(component)).toContain("Review auth");
  });

  test("parallel mode renders count", () => {
    const { renderCall } = setupExtension();
    const component = renderCall("subagent_run", {
      tasks: [
        { agent: "a", task: "t1" },
        { agent: "b", task: "t2" },
      ],
    });
    expect(extractText(component)).toContain("2 tasks");
  });

  test("chain mode renders steps", () => {
    const { renderCall } = setupExtension();
    const component = renderCall("subagent_run", {
      chain: [
        { agent: "planner", task: "Plan" },
        { agent: "coder", task: "Implement {previous}" },
      ],
    });
    expect(extractText(component)).toContain("2 steps");
  });
});

describe("renderCall for subagent_fork", () => {
  test("renders fork icon and job info", () => {
    const { renderCall } = setupExtension();
    const component = renderCall("subagent_fork", { agent: "reviewer", task: "Review auth" });
    expect(extractText(component)).toContain("fork");
    expect(extractText(component)).toContain("reviewer");
  });
});

describe("renderResult for subagent_status", () => {
  test("renders job table with status indicators", () => {
    // ...
  });
});
```

### Green: Port and adapt renderers

- `subagent_run`: reuse existing `renderCall`/`renderResult` from old `subagent` tool, updated for `subagent_run` name
- `subagent_fork`: simple renderCall showing fork icon + agent/task, renderResult showing job ID + summary + running count
- `subagent_status`: render a compact job table with status icons (⏳ running, ✓ completed, ✗ failed, ⊘ cancelled)
- `subagent_results`: render same as `subagent_run` result (full messages, usage, etc.)
- `subagent_wait`: render similar to `subagent_run` result (blocking result)
- `subagent_cancel`: simple confirmation text

### Refactor: Extract shared rendering helpers (formatUsageStats, formatToolCall, etc.) into a shared module.

---

## Cycle 12: Integration Test — End-to-End Fork Flow

Not a TDD cycle — this is a holistic integration test that exercises the full path.

### Test: Full async workflow

```typescript
// tests/integration.test.ts

describe("async subagent integration", () => {
  test("complete fork → work → notification → results flow", async () => {
    const { callTool, jobMgr, simulateJobCompletion, getSentMessages } = setupExtension();

    // 1. Fork a background job
    const forkResult = await callTool("subagent_fork", {
      agent: "code-reviewer",
      task: "Review the auth module",
    });
    expect(forkResult.content[0].text).toMatch(/forked/i);
    const jobId = forkResult.details.jobs[0].id;

    // 2. Model continues working (other tool calls would happen here)
    // The model doesn't need to call subagent_status — it just keeps working

    // 3. Background job completes
    const fakeResult = fakeSingleResult({
      agent: "code-reviewer",
      exitCode: 0,
      messages: [
        { role: "assistant", content: [{ type: "text", text: "The auth module looks solid. Minor suggestions: ..." }] },
      ],
      usage: { input: 5000, output: 1200, turns: 3, cost: 0.03 },
    });
    await simulateJobCompletion(jobId, fakeResult);

    // 4. Notification was sent
    const messages = getSentMessages();
    expect(messages).toHaveLength(1);
    expect(messages[0].customType).toBe("subagent-result");
    expect(messages[0].content).toContain("code-reviewer");
    expect(messages[0].content).toContain("completed");
    expect(messages[0].content).toContain("3 turns");
    expect(messages[0].details.jobId).toBe(jobId);

    // 5. Model calls subagent_results for full detail
    const results = await callTool("subagent_results", { jobId });
    expect(results.content[0].text).toContain("The auth module looks solid");
    expect(results.details.results[0].usage.cost).toBeCloseTo(0.03);
  });

  test("fork multiple → notifications arrive as each completes", async () => {
    const { callTool, simulateJobCompletion, getSentMessages } = setupExtension();

    const forkResult = await callTool("subagent_fork", {
      tasks: [
        { agent: "reviewer", task: "Review auth" },
        { agent: "writer", task: "Write tests" },
      ],
    });
    const jobIds = forkResult.details.jobs.map((j: any) => j.id);

    // Complete first job
    await simulateJobCompletion(jobIds[0], fakeSingleResult({ agent: "reviewer" }));
    expect(getSentMessages()).toHaveLength(1);
    expect(getSentMessages()[0].details.jobId).toBe(jobIds[0]);

    // Complete second job
    await simulateJobCompletion(jobIds[1], fakeSingleResult({ agent: "writer" }));
    expect(getSentMessages()).toHaveLength(2);
    expect(getSentMessages()[1].details.jobId).toBe(jobIds[1]);
  });

  test("cancel running job stops process and sends no notification", async () => {
    const { callTool, jobMgr, getSentMessages } = setupExtension();

    const forkResult = await callTool("subagent_fork", {
      agent: "reviewer",
      task: "Review auth",
    });
    const jobId = forkResult.details.jobs[0].id;

    // Cancel it
    const cancelResult = await callTool("subagent_cancel", { jobId });
    expect(cancelResult.content[0].text).toMatch(/cancelled/i);

    // No completion notification should be sent
    expect(getSentMessages()).toHaveLength(0);
    expect(jobMgr.getJob(jobId)!.status).toBe("cancelled");
  });
});
```

---

## Cycle 13: Remove Old `subagent`, Update `agents.ts`

### Red: Verify old tool is gone

```typescript
// tests/cleanup.test.ts

describe("old subagent removal", () => {
  test("subagent tool is not registered", () => {
    const { tools } = setupExtension();
    const names = tools.map((t) => t.name);
    expect(names).not.toContain("subagent");
  });

  test("agents.ts is unchanged (still used by subagent_run)", () => {
    // Verify discoverAgents, parseModelField, etc. still export correctly
    const { discoverAgents } = require("./agents");
    expect(typeof discoverAgents).toBe("function");
  });
});
```

### Green: Remove old registration, keep shared code

- Delete the old `subagent` tool registration from `index.ts`
- Keep `agents.ts` — it's still used by `subagent_run` and `subagent_fork`
- Keep `runSingleAgent` — it's still used by `subagent_run` (blocking) and `subagent_fork` (spawns the process, doesn't await)
- Export `JobManager` and `AsyncJob` types for test access

### Refactor: Clean up imports. Ensure no dead code paths.

---

## Code Review — 3 Subagent Reviews

After implementation is green, I'll run three parallel `subagent_run` code reviews using the `code-reviewer` agent (or whichever review agent is available). Each review focuses on a different aspect.

### Review 1: Correctness & Edge Cases

```
Agent: code-reviewer
Task: Review the async subagent extension for correctness and edge cases.

Focus areas:
- Race conditions between job creation and completion
- Error handling: child process crash, stdout parse failure, temp file cleanup
- Signal handling: SIGTERM → SIGKILL escalation after 5s
- Job cap enforcement: what happens if 2 forks arrive in the same turn and both check 7 running?
- AbortSignal propagation: when parent tool call is cancelled, do children get killed?
- Notification delivery: what if pi.sendMessage is called during session shutdown?
- Off-by-one in the 8-job cap: is it <8 or <=8?
- Empty task string, missing agent name, invalid agent scope
- Chain mode with {previous} when previous output is empty
```

### Review 2: Security & Resource Management

```
Agent: code-reviewer
Task: Review the async subagent extension for security and resource management.

Focus areas:
- Temp file cleanup: are prompt files always deleted, even on crash?
- Child process zombie prevention: SIGTERM + SIGKILL fallback
- Orphan process detection on session restart
- Memory leaks: are Map entries cleaned up when jobs are cancelled/completed?
- DoS vectors: can a user (or model) spawn 8 jobs that each spawn 8 more?
- confirmProjectAgents skip for fork: is this safe? Should we at least log which project agents were used?
- Process argument injection: are agent names and tasks properly escaped in CLI args?
- Resource limits: what if a subagent writes 10MB of stdout?
- File descriptor leaks: are child.stdio streams properly drained and closed?
```

### Review 3: API Design & Documentation

```
Agent: code-reviewer
Task: Review the async subagent extension for API design, documentation, and developer experience.

Focus areas:
- Tool descriptions: are they clear enough for an LLM that has never used async subagents?
- Schema consistency: do fork/run/status/results/wait/cancel use consistent parameter naming?
- Error messages: when a tool returns isError, is the message actionable?
- RenderCall/renderResult: do they give enough context in collapsed mode? Are expanded views useful?
- Job ID collision: is {agentName}-{4hex} enough entropy? What's the collision probability?
- Notification format: is the customType message format extensible? Future-proof?
- Backward compatibility: are there any scenarios where removing the old subagent tool could break saved sessions?
- Does the extension load correctly? Are all imports resolved with .js extensions for ESM?
- Install script: does the symlink for the subagent extension still work after the refactor?
```

After all three reviews, address the critical findings and re-run the review cycle on the fixes.

---

## File Structure

```
pi/extensions/subagent/
├── PLAN.md              # This file
├── index.ts             # Extension entry point, registers all 6 tools
├── job-manager.ts       # AsyncJob state management, persistence, lifecycle
├── process-runner.ts    # Shared child process spawning (from runSingleAgent)
├── agents.ts            # Agent discovery (unchanged)
├── renderers.ts         # Shared rendering helpers (formatUsageStats, etc.)
├── notifications.ts     # Completion notification formatting & emission
├── tests/
│   ├── job-manager.test.ts
│   ├── subagent-fork.test.ts
│   ├── subagent-status.test.ts
│   ├── subagent-results.test.ts
│   ├── subagent-wait.test.ts
│   ├── subagent-cancel.test.ts
│   ├── subagent-run.test.ts
│   ├── notification.test.ts
│   ├── notification-renderer.test.ts
│   ├── rendering.test.ts
│   ├── lifecycle.test.ts
│   ├── tool-registration.test.ts
│   ├── integration.test.ts
│   └── helpers.ts        # Shared test utilities (fakeSingleResult, setupExtension, etc.)
└── package.json          # Dependencies (if any beyond pi-coding-agent)
```

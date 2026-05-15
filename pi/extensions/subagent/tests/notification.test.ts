/**
 * Completion Notification — Background job completion notifications.
 * Uses name (not agent).
 */

import { describe, test, expect, vi, beforeAll, afterEach } from "vitest";
import { createMockExtension } from "./extension-helpers.js";

let registeredTools: Map<string, any>;
let mockPi: any;
let jobMgr: any;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
	jobMgr = ctx.jobMgr;
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(mockPi);
});

afterEach(() => {
	mockPi.sentMessages.length = 0;
	jobMgr.cancelAll();
	for (const job of jobMgr.listJobs()) {
		(jobMgr as any).jobs.delete(job.id);
	}
});

describe("completion notification", () => {
	test("subagent-result message renderer is registered", () => {
		expect(mockPi.messageRenderers.has("subagent-result")).toBe(true);
		expect(registeredTools.has("subagent_fork")).toBe(true);
		expect(registeredTools.has("subagent_status")).toBe(true);
		expect(registeredTools.has("subagent_results")).toBe(true);
		expect(registeredTools.has("subagent_wait")).toBe(true);
		expect(registeredTools.has("subagent_cancel")).toBe(true);
		expect(registeredTools.has("subagent_run")).toBe(true);
	});

	test("fork tool creates job entries with name field", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const mockCtx = {
			cwd: "/test",
			hasUI: false,
			signal: undefined,
			ui: { confirm: vi.fn() },
		} as any;

		const result = await forkTool.execute("cf1", { task: "Test task" }, undefined, undefined, mockCtx);
		expect(result.details.jobs).toHaveLength(1);
		expect(result.details.jobs[0].name).toBeDefined();
		expect(result.details.jobs[0].status).toBeDefined();
	});

	test("session handlers registered", async () => {
		expect(mockPi.eventHandlers.has("session_shutdown")).toBe(true);
		expect(mockPi.eventHandlers.has("session_start")).toBe(true);
	});
});

describe("guardrail notification — resumable info", () => {
	/**
	 * Helper: create a guardrail-failed job by manipulating job state directly.
	 * This simulates what happens when a subagent process is killed by guardrails.
	 */
	function makeGuardrailJob(): any {
		const job = jobMgr.createJob("test-job", "Do something dangerous");
		const completedAt = Date.now() - 1000;
		const origJob = jobMgr.getJob(job.id)!;
		Object.assign(origJob, {
			status: "failed",
			result: {
				name: "test-job",
				task: "Do something dangerous",
				exitCode: 1,
				messages: [],
				stderr: "",
				usage: { input: 100, output: 50, cacheRead: 0, cacheWrite: 0, cost: 0.01, contextTokens: 500, turns: 26 },
				stopReason: "guardrail",
				errorMessage: "Subagent killed: exceeded maxTurns (25)",
			},
			completedAt,
			original: {
				config: { name: "subagent" },
				task: "Do something dangerous",
				guardrails: { maxTurns: 25 },
			},
		});
		return origJob;
	}

	function makeNonGuardrailFailedJob(): any {
		const job = jobMgr.createJob("fail-job", "Something broke");
		const completedAt = Date.now() - 1000;
		const origJob = jobMgr.getJob(job.id)!;
		Object.assign(origJob, {
			status: "failed",
			result: {
				name: "fail-job",
				task: "Something broke",
				exitCode: 1,
				messages: [],
				stderr: "Process crashed",
				usage: { input: 50, output: 10, cacheRead: 0, cacheWrite: 0, cost: 0.002, contextTokens: 100, turns: 2 },
				stopReason: "error",
				errorMessage: "Process crashed",
			},
			completedAt,
			original: {
				config: { name: "subagent" },
				task: "Something broke",
				guardrails: { maxTurns: 25 },
			},
		});
		return origJob;
	}

	test("guardrail notification contains 'Resumable' label", async () => {
		const job = makeGuardrailJob();
		const mod: any = await import("../index.js");
		mod.emitCompletionNotification(mockPi, job);

		const msgs = mockPi.sentMessages.filter((m: any) => m.customType === "subagent-result");
		expect(msgs.length).toBeGreaterThanOrEqual(1);
		const msg = msgs[msgs.length - 1];
		expect(msg.content).toContain("Resumable");
	});

	test("notification contains pasteable subagent_run({ resumeFrom: ... }) suggest", async () => {
		const job = makeGuardrailJob();
		const mod: any = await import("../index.js");
		mod.emitCompletionNotification(mockPi, job);

		const msgs = mockPi.sentMessages.filter((m: any) => m.customType === "subagent-result");
		expect(msgs.length).toBeGreaterThanOrEqual(1);
		const msg = msgs[msgs.length - 1];
		expect(msg.content).toContain("resumeFrom");
		expect(msg.content).toContain("subagent_run");
	});

	test("notification contains retry-fresh command with original config", async () => {
		const job = makeGuardrailJob();
		const mod: any = await import("../index.js");
		mod.emitCompletionNotification(mockPi, job);

		const msgs = mockPi.sentMessages.filter((m: any) => m.customType === "subagent-result");
		expect(msgs.length).toBeGreaterThanOrEqual(1);
		const msg = msgs[msgs.length - 1];
		expect(msg.content).toContain("retry fresh");
		expect(msg.content).toContain("Do something dangerous");
	});

	test("non-guardrail failure has no resumable info", async () => {
		const job = makeNonGuardrailFailedJob();
		const mod: any = await import("../index.js");
		mod.emitCompletionNotification(mockPi, job);

		const msgs = mockPi.sentMessages.filter((m: any) => m.customType === "subagent-result");
		expect(msgs.length).toBeGreaterThanOrEqual(1);
		const msg = msgs[msgs.length - 1];
		expect(msg.content).not.toContain("Resumable");
		expect(msg.content).not.toContain("resumeFrom");
	});

	test("notification details has resumable: true", async () => {
		const job = makeGuardrailJob();
		const mod: any = await import("../index.js");
		mod.emitCompletionNotification(mockPi, job);

		const msgs = mockPi.sentMessages.filter((m: any) => m.customType === "subagent-result");
		expect(msgs.length).toBeGreaterThanOrEqual(1);
		const msg = msgs[msgs.length - 1];
		expect(msg.details.resumable).toBe(true);
	});
});

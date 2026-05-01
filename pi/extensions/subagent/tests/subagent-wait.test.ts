/**
 * Wait and Cancel — Block until completion and cancel jobs.
 */

import { describe, test, expect, vi, beforeAll, afterEach } from "vitest";
import { createMockExtension } from "./extension-helpers.js";

let registeredTools: Map<string, any>;
let mockPi: any;
let jobMgr: any;
let waitTool: any;
let cancelTool: any;
let forkTool: any;
let mockCtx: any;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
	jobMgr = ctx.jobMgr;
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(mockPi);

	waitTool = registeredTools.get("subagent_wait");
	cancelTool = registeredTools.get("subagent_cancel");
	forkTool = registeredTools.get("subagent_fork");

	mockCtx = {
		cwd: "/test",
		hasUI: false,
		signal: undefined,
		ui: { confirm: vi.fn() },
	} as any;
});

afterEach(() => {
	jobMgr.cancelAll();
	for (const job of jobMgr.listJobs()) {
		(jobMgr as any).jobs.delete(job.id);
	}
});

describe("subagent_wait", () => {
	test("waitTool is registered as subagent_wait", () => {
		expect(waitTool).toBeDefined();
		expect(waitTool.name).toBe("subagent_wait");
	});

	test("returns error for unknown jobId", async () => {
		const result = await waitTool.execute("w1", { jobId: "nonexistent-xxxx" }, undefined, undefined, mockCtx);
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toMatch(/not found/i);
	});

	test("returns immediately if job already completed/failed", async () => {
		const forkResult = await forkTool.execute("fw1", { task: "Fail fast" }, undefined, undefined, mockCtx);
		const jobId = forkResult.details.jobs[0].id;

		const result = await waitTool.execute("w2", { jobId, timeout: 5 }, undefined, undefined, mockCtx);
		expect(result.content[0].text).not.toMatch(/still running/i);
		expect(result.content[0].text).toMatch(/fail|complet|cancel/i);
	});

	test("timeout returns isError: true so LLM knows to poll or extend", async () => {
		const freshCtx = createMockExtension();
		const freshMod = await import("../index.js");
		freshMod.default(freshCtx.pi);
		const freshWaitTool = freshCtx.registeredTools.get("subagent_wait");
		const freshCtxMock = { cwd: "/test", hasUI: false, signal: undefined, ui: { confirm: vi.fn() } };

		const runningJob = freshCtx.jobMgr.createJob("slow-name", "Slow task");
		const result = await freshWaitTool.execute("w3", { jobId: runningJob.id, timeout: 1 }, undefined, undefined, freshCtxMock);
		expect(result.content[0].text).toMatch(/still running|timed out/i);
		expect(result.isError).toBe(true);
	});
});

describe("subagent_cancel", () => {
	test("cancelTool is registered as subagent_cancel", () => {
		expect(cancelTool).toBeDefined();
		expect(cancelTool.name).toBe("subagent_cancel");
	});

	test("cancels a specific job by ID", async () => {
		const forkResult = await forkTool.execute("fc1", { task: "Will be cancelled" }, undefined, undefined, mockCtx);
		const jobId = forkResult.details.jobs[0].id;

		const result = await cancelTool.execute("c1", { jobId }, undefined, undefined, mockCtx);
		expect(result.content[0].text).toMatch(/cancel|already|fail/i);
	});

	test("cancel all: handles empty case gracefully", async () => {
		const result = await cancelTool.execute("c2", { all: true }, undefined, undefined, mockCtx);
		expect(result.content[0].text).toMatch(/no running|0|cancelled/i);
	});

	test("returns error for completed/cancelled job", async () => {
		const forkResult = await forkTool.execute("fc4", { task: "Done" }, undefined, undefined, mockCtx);
		const jobId = forkResult.details.jobs[0].id;

		await cancelTool.execute("c3", { jobId }, undefined, undefined, mockCtx);

		const result = await cancelTool.execute("c4", { jobId }, undefined, undefined, mockCtx);
		expect(result.isError).toBe(true);
	});

	test("returns error for unknown jobId", async () => {
		const result = await cancelTool.execute("c5", { jobId: "nonexistent-xxxx" }, undefined, undefined, mockCtx);
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toMatch(/not found/i);
	});
});
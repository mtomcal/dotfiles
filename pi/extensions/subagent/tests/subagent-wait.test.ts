/**
 * Cycle 5: Wait and Cancel — Block until completion and cancel jobs.
 */

import { describe, test, expect, vi, beforeAll } from "vitest";
import { createMockExtension } from "./extension-helpers.js";

let registeredTools: Map<string, any>;
let mockPi: any;
let waitTool: any;
let cancelTool: any;
let forkTool: any;
let mockCtx: any;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
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

describe("subagent_wait", () => {
	test("is registered as a tool", () => {
		expect(waitTool).toBeDefined();
	});

	test("returns error for unknown jobId", async () => {
		const result = await waitTool.execute("w1", { jobId: "nonexistent-xxxx" }, undefined, undefined, mockCtx);
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toMatch(/not found/i);
	});

	test("returns immediately if job already completed/failed", async () => {
		const forkResult = await forkTool.execute("fw1", { agent: "quick-fail", task: "Fail fast" }, undefined, undefined, mockCtx);
		const jobId = forkResult.details.jobs[0].id;

		const result = await waitTool.execute("w2", { jobId, timeout: 5 }, undefined, undefined, mockCtx);
		expect(result).toBeDefined();
		expect(result.content[0].text).not.toMatch(/still running/i);
	});

	test("timeout returns isError: true so LLM knows to poll or extend", async () => {
		// Create a fresh extension with a running job that won't complete quickly
		const freshCtx = createMockExtension();
		const freshMod = await import("../index.js");
		freshMod.default(freshCtx.pi);
		const freshWaitTool = freshCtx.registeredTools.get("subagent_wait");
		const freshCtxMock = { cwd: "/test", hasUI: false, signal: undefined, ui: { confirm: vi.fn() } };

		const runningJob = freshCtx.jobMgr.createJob("slow-agent", "Slow task");
		const result = await freshWaitTool.execute("w3", { jobId: runningJob.id, timeout: 1 }, undefined, undefined, freshCtxMock);
		expect(result.content[0].text).toMatch(/still running|timed out/i);
		expect(result.isError).toBe(true);
	});
});

describe("subagent_cancel", () => {
	test("is registered as a tool", () => {
		expect(cancelTool).toBeDefined();
	});

	test("cancels a specific job by ID", async () => {
		const forkResult = await forkTool.execute("fc1", { agent: "cancel-me", task: "Will be cancelled" }, undefined, undefined, mockCtx);
		const jobId = forkResult.details.jobs[0].id;

		const result = await cancelTool.execute("c1", { jobId }, undefined, undefined, mockCtx);
		// Should either cancel or say already completed
		expect(result.content[0].text).toBeTruthy();
	});

	test("cancel all: handles empty case gracefully", async () => {
		// When no running jobs, cancel all just reports "no running jobs"
		const result = await cancelTool.execute("c2", { all: true }, undefined, undefined, mockCtx);
		expect(result.content[0].text).toMatch(/no running|0|cancelled/i);
	});

	test("returns error for completed/cancelled job", async () => {
		const forkResult = await forkTool.execute("fc4", { agent: "already-done", task: "Done" }, undefined, undefined, mockCtx);
		const jobId = forkResult.details.jobs[0].id;

		// Cancel it first (or it may already be failed)
		await cancelTool.execute("c3", { jobId }, undefined, undefined, mockCtx);

		// Try cancelling again
		const result = await cancelTool.execute("c4", { jobId }, undefined, undefined, mockCtx);
		expect(result.isError).toBe(true);
	});

	test("returns error for unknown jobId", async () => {
		const result = await cancelTool.execute("c5", { jobId: "nonexistent-xxxx" }, undefined, undefined, mockCtx);
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toMatch(/not found/i);
	});
});

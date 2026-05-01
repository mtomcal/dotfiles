/**
 * Integration Test — End-to-end ad-hoc config workflow.
 */

import { describe, test, expect, vi, beforeAll, afterEach } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import { fakeSingleResult } from "./helpers.js";

let mockPi: any;
let registeredTools: Map<string, any>;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(mockPi);
});

afterEach(() => {
	mockPi.sentMessages.length = 0;
	mockPi.appendEntries.length = 0;
	mockPi.jobMgr.cancelAll();
	for (const job of mockPi.jobMgr.listJobs()) {
		(mockPi.jobMgr as any).jobs.delete(job.id);
	}
});

describe("integration: full async workflow", () => {
	test("fork with bare task sends job and returns ID", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const mockCtx = { cwd: "/test", hasUI: false, signal: undefined, ui: { confirm: vi.fn() } } as any;

		const result = await forkTool.execute("int-fork-1", { task: "Review the auth module" }, undefined, undefined, mockCtx);

		expect(result.content[0].text).toMatch(/forked/i);
		expect(result.details.jobs).toHaveLength(1);
		expect(result.details.jobs[0].name).toBe("review"); // auto-derived
		expect(result.details.jobs[0].id).toMatch(/^review-/);
		expect(mockPi.sentMessages).toHaveLength(0); // no notification yet
	});

	test("fork with name and systemPrompt", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const mockCtx = { cwd: "/test", hasUI: false, signal: undefined, ui: { confirm: vi.fn() } } as any;

		const result = await forkTool.execute("int-fork-2", {
			name: "security-auditor",
			task: "Audit auth module",
			systemPrompt: "You are a security auditor.",
		}, undefined, undefined, mockCtx);

		expect(result.details.jobs[0].name).toBe("security-auditor");
		expect(result.details.jobs[0].id).toMatch(/^security-auditor-/);
	});

	test("fork with tasks array creates multiple jobs", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const mockCtx = { cwd: "/test", hasUI: false, signal: undefined, ui: { confirm: vi.fn() } } as any;

		const result = await forkTool.execute("int-fork-3", {
			tasks: [
				{ task: "Review auth" },
				{ task: "Write tests" },
				{ task: "Check security", systemPrompt: "Be a security scanner.", model: "anthropic/claude-sonnet-4-5:high" },
			],
		}, undefined, undefined, mockCtx);

		expect(result.details.jobs).toHaveLength(3);
		const ids = result.details.jobs.map((j: any) => j.id);
		expect(new Set(ids).size).toBe(3);
	});

	test("status tool sees the forked job", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const statusTool = registeredTools.get("subagent_status");
		const mockCtx = { cwd: "/test", hasUI: false, signal: undefined, ui: { confirm: vi.fn() } } as any;

		const forkResult = await forkTool.execute("int-fork-4", { task: "Status test task" }, undefined, undefined, mockCtx);
		const jobId = forkResult.details.jobs[0].id;

		const statusResult = await statusTool.execute("int-status-1", { jobId }, undefined, undefined, mockCtx);
		expect(statusResult.content[0].text).toContain(jobId);
	});

	test("cancel clears job", async () => {
		const cancelTool = registeredTools.get("subagent_cancel");
		const mockCtx = { cwd: "/test", hasUI: false, signal: undefined, ui: { confirm: vi.fn() } } as any;

		const result = await cancelTool.execute("int-cancel-all", { all: true }, undefined, undefined, mockCtx);
		expect(result.content[0].text).toMatch(/cancel|no running/i);
	});

	test("appendEntry is called after fork", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const mockCtx = { cwd: "/test", hasUI: false, signal: undefined, ui: { confirm: vi.fn() } } as any;

		await forkTool.execute("int-fork-persist", { task: "Persist test" }, undefined, undefined, mockCtx);

		const stateEntries = mockPi.appendEntries.filter((e: any) => e.customType === "subagent-job-state");
		expect(stateEntries.length).toBeGreaterThan(0);
	});

	test("results tool handles unknown job gracefully", async () => {
		const resultsTool = registeredTools.get("subagent_results");
		const mockCtx = { cwd: "/test", hasUI: false, signal: undefined, ui: { confirm: vi.fn() } } as any;

		const result = await resultsTool.execute("int-results-1", { jobId: "nonexistent-job-xxxx" }, undefined, undefined, mockCtx);
		expect(result.isError).toBe(true);
	});

	test("wait tool handles unknown job gracefully", async () => {
		const waitTool = registeredTools.get("subagent_wait");
		const mockCtx = { cwd: "/test", hasUI: false, signal: undefined, ui: { confirm: vi.fn() } } as any;

		const result = await waitTool.execute("int-wait-1", { jobId: "nonexistent-job-xxxx" }, undefined, undefined, mockCtx);
		expect(result.isError).toBe(true);
	});
});
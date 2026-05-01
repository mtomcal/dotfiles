/**
 * Cycle 4: Status and Results — Check job status and retrieve full results.
 *
 * RED: Tests for subagent_status and subagent_results tools.
 */

import { describe, test, expect, vi, beforeAll } from "vitest";
import { createMockExtension } from "./extension-helpers.js";

let registeredTools: Map<string, any>;
let mockPi: any;
let statusTool: any;
let resultsTool: any;
let mockCtx: any;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(mockPi);

	statusTool = registeredTools.get("subagent_status");
	resultsTool = registeredTools.get("subagent_results");

	mockCtx = {
		cwd: "/test",
		hasUI: false,
		signal: undefined,
		ui: { confirm: vi.fn() },
	} as any;
});

describe("subagent_status", () => {
	test("statusTool is registered as subagent_status", () => {
		expect(statusTool).toBeDefined();
		expect(statusTool.name).toBe("subagent_status");
	});

	test("lists all jobs when no jobId provided (even if empty)", async () => {
		const result = await statusTool.execute("s1", {}, undefined, undefined, mockCtx);
		expect(result.content[0].text).toContain("No subagent jobs");
		expect(result.details.total).toBe(0);
	});

	test("shows specific job status with jobId", async () => {
		// Fork a job first
		const forkTool = registeredTools.get("subagent_fork");
		await forkTool.execute("f1", { agent: "test-agent", task: "Test task" }, undefined, undefined, mockCtx);

		// Fork returns jobs list - get the ID from the details
		const forkResult = await forkTool.execute("f2", { agent: "another-agent", task: "Another task" }, undefined, undefined, mockCtx);
		const jobId = forkResult.details.jobs[0].id;

		const result = await statusTool.execute("s2", { jobId }, undefined, undefined, mockCtx);
		expect(result.content[0].text).toContain(jobId);
		expect(result.content[0].text).toContain("another-agent");
	});

	test("returns error for unknown jobId", async () => {
		const result = await statusTool.execute("s3", { jobId: "nonexistent-xxxx" }, undefined, undefined, mockCtx);
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toMatch(/not found/i);
	});
});

describe("subagent_results", () => {
	test("resultsTool is registered as subagent_results", () => {
		expect(resultsTool).toBeDefined();
		expect(resultsTool.name).toBe("subagent_results");
	});

	test("returns error for still-running job", async () => {
		// Create a running job directly so we control its state
		const job = mockPi.jobMgr.createJob("test-running", "Running task");
		const jobId = job.id;

		const result = await resultsTool.execute("r1", { jobId }, undefined, undefined, mockCtx);
		// Job is running with no result yet — should error
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toMatch(/running|no result|not complet/i);
	});

	test("returns error for unknown jobId", async () => {
		const result = await resultsTool.execute("r2", { jobId: "nonexistent-xxxx" }, undefined, undefined, mockCtx);
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toMatch(/not found/i);
	});
});

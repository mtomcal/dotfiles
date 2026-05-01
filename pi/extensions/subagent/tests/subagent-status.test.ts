/**
 * Status and Results — Check job status and retrieve full results.
 * Uses ad-hoc config (name instead of agent).
 */

import { describe, test, expect, vi, beforeAll, beforeEach, afterEach } from "vitest";
import { createMockExtension } from "./extension-helpers.js";

let registeredTools: Map<string, any>;
let mockPi: any;
let statusTool: any;
let resultsTool: any;
let mockCtx: any;
let jobMgr: any;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
	jobMgr = ctx.jobMgr;
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

afterEach(() => {
	jobMgr.cancelAll();
	for (const job of jobMgr.listJobs()) {
		(jobMgr as any).jobs.delete(job.id);
	}
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

	test("shows specific job status with jobId — uses name, not agent", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const forkResult = await forkTool.execute("f2", { task: "Another task" }, undefined, undefined, mockCtx);
		const jobId = forkResult.details.jobs[0].id;

		const result = await statusTool.execute("s2", { jobId }, undefined, undefined, mockCtx);
		expect(result.content[0].text).toContain(jobId);
		// The auto-derived name from "Another task" is "anoth" (truncated to 5 chars? No, "another" is 7 chars)
		// Actually deriveName("Another task") = "another"
		expect(result.content[0].text).toContain("another");
	});

	test("returns error for unknown jobId", async () => {
		const result = await statusTool.execute("s3", { jobId: "nonexistent-xxxx" }, undefined, undefined, mockCtx);
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toMatch(/not found/i);
	});

	test("list-all output contains job names", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		await forkTool.execute("f3", { task: "Check mock theme" }, undefined, undefined, mockCtx);

		const result = await statusTool.execute("s4", {}, undefined, undefined, mockCtx);
		const text = result.content[0].text;
		expect(text).not.toContain("() =>");
		expect(text).toContain("check");
	});
});

describe("subagent_status formatting", () => {
	beforeEach(() => {
		jobMgr.cancelAll();
		for (const job of jobMgr.listJobs()) {
			(jobMgr as any).jobs.delete(job.id);
		}
	});

	test("renders running job with correct icon and name", async () => {
		const job = jobMgr.createJob("running-name", "Do something");

		const result = await statusTool.execute("s10", {}, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).toContain("⏳");
		expect(text).toContain("running-name");
		expect(text).toContain("1 running");
		expect(result.details.running).toBe(1);
	});

	test("renders completed job with correct icon", async () => {
		const job = jobMgr.createJob("completed-name", "Finished work");
		jobMgr.completeJob(job.id, {
			name: "completed-name",
			task: "Finished work",
			exitCode: 0,
			messages: [{ role: "assistant", content: [{ type: "text", text: "Done successfully" }] }],
			stderr: "",
			usage: { input: 100, output: 50, cacheRead: 0, cacheWrite: 0, cost: 0.01, contextTokens: 500, turns: 1 },
		});

		const result = await statusTool.execute("s11", {}, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).toContain("✓");
		expect(text).toContain("completed-name");
		expect(text).toContain("1 completed");
	});

	test("renders failed job with correct icon", async () => {
		const job = jobMgr.createJob("failed-name", "Bad task");
		jobMgr.failJob(job.id, "Process exited with code 1");

		const result = await statusTool.execute("s12", {}, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).toContain("✗");
		expect(text).toContain("failed-name");
	});
});

describe("subagent_results", () => {
	test("returns error for still-running job", async () => {
		const job = mockPi.jobMgr.createJob("test-running", "Running task");

		const result = await resultsTool.execute("r1", { jobId: job.id }, undefined, undefined, mockCtx);
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toMatch(/running|not complet/i);
	});

	test("returns error for unknown jobId", async () => {
		const result = await resultsTool.execute("r2", { jobId: "nonexistent-xxxx" }, undefined, undefined, mockCtx);
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toMatch(/not found/i);
	});
});
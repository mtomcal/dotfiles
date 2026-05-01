/**
 * Cycle 4: Status and Results — Check job status and retrieve full results.
 *
 * Tests for subagent_status and subagent_results tools.
 * Includes regression test for mock theme fg signature bug
 * (old: { fg: () => (s) => s } -> new: { fg: (_color, s) => s }).
 */

import { describe, test, expect, vi, beforeAll, beforeEach } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import type { AsyncJob } from "../job-manager.js";

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

	test("list-all output contains no arrow function syntax from mock theme", async () => {
		// Fork a job so the list is non-empty
		const forkTool = registeredTools.get("subagent_fork");
		await forkTool.execute("f3", { agent: "status-mock-test", task: "Check mock theme" }, undefined, undefined, mockCtx);

		const result = await statusTool.execute("s4", {}, undefined, undefined, mockCtx);
		const text = result.content[0].text;
		// The old mock { fg: () => (s) => s } caused "() =>" to appear in output
		expect(text).not.toContain("() =>");
		expect(text).toContain("status-mock-test");
	});
});

describe("subagent_status list-all formatting", () => {
	beforeEach(() => {
		// Clear jobs between tests for isolated assertions
		jobMgr.cancelAll();
		// Manually reset the job map since cancelled jobs still show up
		for (const job of jobMgr.listJobs()) {
			(jobMgr as any).jobs.delete(job.id);
		}
	});

	test("renders running job with correct icon and agent name", async () => {
		// Create a running job directly via jobMgr so we control its status
		const job = jobMgr.createJob("running-agent", "Do something");
		// Job is still "running" — no process attached, no completion

		const result = await statusTool.execute("s10", {}, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		// With the mock theme (identity fg), running icon string should be "⏳"
		expect(text).toContain("⏳");
		expect(text).toContain("running-agent");
		expect(text).toContain("Do something");
		// Counter should show 1 running
		expect(text).toContain("1 running");
		expect(result.details.running).toBe(1);
	});

	test("renders completed job with correct icon and summary", async () => {
		const job = jobMgr.createJob("completed-agent", "Finished work");
		jobMgr.completeJob(job.id, {
			agent: "completed-agent",
			agentSource: "user",
			task: "Finished work",
			exitCode: 0,
			messages: [{ role: "assistant", content: [{ type: "text", text: "Done successfully" }] }],
			stderr: "",
			usage: { input: 100, output: 50, cacheRead: 0, cacheWrite: 0, cost: 0.01, contextTokens: 500, turns: 1 },
		});

		const result = await statusTool.execute("s11", {}, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).toContain("✓");
		expect(text).toContain("completed-agent");
		expect(text).toContain("Finished work");
		expect(text).toContain("1 completed");
	});

	test("renders failed job with correct icon", async () => {
		const job = jobMgr.createJob("failed-agent", "Bad task");
		jobMgr.failJob(job.id, "Process exited with code 1");

		const result = await statusTool.execute("s12", {}, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).toContain("✗");
		expect(text).toContain("failed-agent");
		expect(text).toContain("1 failed");
	});

	test("renders cancelled job with correct icon", async () => {
		const job = jobMgr.createJob("cancelled-agent", "Cancelled task");
		jobMgr.cancelJob(job.id);

		const result = await statusTool.execute("s13", {}, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).toContain("⊘");
		expect(text).toContain("cancelled-agent");
		expect(text).toContain("1 cancelled");
	});

	test("renders multiple jobs with correct counts", async () => {
		const j1 = jobMgr.createJob("a-running", "Running");
		// j1 stays running

		const j2 = jobMgr.createJob("a-completed", "Completed");
		jobMgr.completeJob(j2.id, {
			agent: "a-completed",
			agentSource: "user",
			task: "Completed",
			exitCode: 0,
			messages: [{ role: "assistant", content: [{ type: "text", text: "OK" }] }],
			stderr: "",
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
		});

		const j3 = jobMgr.createJob("a-failed", "Failed");
		jobMgr.failJob(j3.id, "error");

		const result = await statusTool.execute("s14", {}, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).toContain("3 jobs");
		expect(text).toContain("1 running");
		expect(text).toContain("1 completed");
		expect(text).toContain("1 failed");

		// Each agent name should appear
		expect(text).toContain("a-running");
		expect(text).toContain("a-completed");
		expect(text).toContain("a-failed");
	});

	test("completed job line includes summary text from result", async () => {
		const job = jobMgr.createJob("summary-agent", "Summary task");
		jobMgr.completeJob(job.id, {
			agent: "summary-agent",
			agentSource: "user",
			task: "Summary task",
			exitCode: 0,
			messages: [{ role: "assistant", content: [{ type: "text", text: "Here is the summary output" }] }],
			stderr: "",
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
		});

		const result = await statusTool.execute("s15", {}, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		// renderJobStatusLine appends " — {summary}" for completed jobs with output
		expect(text).toContain("Here is the summary output");
	});

	test("failed job line includes error message", async () => {
		const job = jobMgr.createJob("err-agent", "Error task");
		jobMgr.failJob(job.id, "Something went terribly wrong");

		const result = await statusTool.execute("s16", {}, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).toContain("Something went terribly wrong");
	});
});

describe("subagent_status specific-job formatting", () => {
	beforeEach(() => {
		for (const job of jobMgr.listJobs()) {
			(jobMgr as any).jobs.delete(job.id);
		}
	});

	test("specific job with jobId shows elapsed time", async () => {
		const job = jobMgr.createJob("elapsed-agent", "Time check");
		jobMgr.completeJob(job.id, {
			agent: "elapsed-agent",
			agentSource: "user",
			task: "Time check",
			exitCode: 0,
			messages: [{ role: "assistant", content: [{ type: "text", text: "Done" }] }],
			stderr: "",
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
		});

		const result = await statusTool.execute("s20", { jobId: job.id }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).toContain("elapsed-agent");
		expect(text).toContain("completed");
		// Should contain an elapsed time value (e.g. "0ms" or similar)
		expect(text).toMatch(/\d+(ms|s|m)/);
	});

	test("specific running job shows running status", async () => {
		const job = jobMgr.createJob("still-running", "In progress");

		const result = await statusTool.execute("s21", { jobId: job.id }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).toContain("running");
		expect(text).toContain("still-running");
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
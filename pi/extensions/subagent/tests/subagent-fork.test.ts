/**
 * Cycle 5+: subagent_fork — ad-hoc config tests.
 */

import { describe, test, expect, vi, beforeAll, afterEach } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import { MAX_RUNNING_JOBS } from "../job-manager.js";

let registeredTools: Map<string, any>;
let mockPi: any;
let forkTool: any;
let mockCtx: any;
let jobMgr: any;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
	jobMgr = ctx.jobMgr;
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(mockPi);

	forkTool = registeredTools.get("subagent_fork");

	mockCtx = {
		cwd: "/test",
		hasUI: false,
		signal: undefined,
		ui: { confirm: vi.fn().mockResolvedValue(true) },
	} as any;
});

afterEach(() => {
	jobMgr.cancelAll();
	for (const job of jobMgr.listJobs()) {
		(jobMgr as any).jobs.delete(job.id);
	}
});

describe("subagent_fork", () => {
	test("is registered as subagent_fork", () => {
		expect(forkTool).toBeDefined();
		expect(forkTool.name).toBe("subagent_fork");
	});

	test("bare task fork gets auto-name", async () => {
		const result = await forkTool.execute("call-1", { task: "Fix the login bug" }, undefined, undefined, mockCtx);

		expect(result.content[0].text).toMatch(/forked/i);
		expect(result.details.jobs).toHaveLength(1);
		expect(result.details.jobs[0].name).toBe("fix");
		expect(result.details.jobs[0].id).toMatch(/^fix-/);
	});

	test("explicit name overrides auto-derive", async () => {
		const result = await forkTool.execute("call-1b", { name: "security-auditor", task: "Audit auth module" }, undefined, undefined, mockCtx);

		expect(result.details.jobs[0].name).toBe("security-auditor");
		expect(result.details.jobs[0].id).toMatch(/^security-auditor-/);
	});

	test("spawns multiple jobs with tasks array", async () => {
		const result = await forkTool.execute(
			"call-2",
			{
				tasks: [
					{ task: "Review auth" },
					{ task: "Write tests" },
				],
			},
			undefined, undefined, mockCtx,
		);

		expect(result.content[0].text).toMatch(/2 jobs/);
		expect(result.details.jobs).toHaveLength(2);
	});

	test("returns job count and running count in response", async () => {
		const result = await forkTool.execute(
			"call-3",
			{ task: "some task" },
			undefined, undefined, mockCtx,
		);

		expect(result.content[0].text).toMatch(/Forked 1 job/);
		expect(result.content[0].text).toMatch(/\d+\/8/);
	});

	test("per-task config overrides", async () => {
		const result = await forkTool.execute(
			"call-4",
			{
				tasks: [
					{ task: "Review", provider: "anthropic" },
					{ task: "Write", thinking: "high" as any },
				],
			},
			undefined, undefined, mockCtx,
		);

		expect(result.content[0].text).toMatch(/forked/i);
		expect(result.details.jobs).toHaveLength(2);
	});

	test("returns error for invalid params (no task or tasks)", async () => {
		const result = await forkTool.execute("call-5", {}, undefined, undefined, mockCtx);
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toMatch(/task|provide/i);
	});

	test("each spawned job has id, name, task, and status fields", async () => {
		const result = await forkTool.execute(
			"call-6",
			{
				tasks: [
					{ task: "task a" },
					{ task: "task b" },
				],
			},
			undefined, undefined, mockCtx,
		);

		for (const job of result.details.jobs) {
			expect(job).toHaveProperty("id");
			expect(job).toHaveProperty("name");
			expect(job).toHaveProperty("task");
			expect(job).toHaveProperty("status");
		}
	});

	test("fork with systemPrompt", async () => {
		const result = await forkTool.execute("call-7", {
			name: "auditor",
			task: "Audit auth module",
			systemPrompt: "You are a security auditor.",
		}, undefined, undefined, mockCtx);

		expect(result.details.jobs[0].name).toBe("auditor");
	});
});
/**
 * Fork Parallel Support — tests for tasks array and cap enforcement.
 */

import { describe, test, expect, vi, beforeAll, beforeEach } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import { MAX_RUNNING_JOBS } from "../job-manager.js";

let registeredTools: Map<string, any>;
let mockPi: any;
let jobMgr: any;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
	registeredTools = ctx.registeredTools;
	jobMgr = ctx.jobMgr;

	const mod = await import("../index.js");
	mod.default(ctx.pi);
});

beforeEach(() => {
	// Clean up jobs between tests
	jobMgr.cancelAll();
	for (const job of jobMgr.listJobs()) {
		(jobMgr as any).jobs.delete(job.id);
	}
});

function mockCtxFunc() {
	return {
		cwd: "/test",
		hasUI: false,
		signal: undefined,
		ui: { confirm: vi.fn() },
	} as any;
}

describe("subagent_fork parallel (tasks array)", () => {
	test("spawns multiple jobs with tasks array", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const result = await forkTool.execute(
			"fp-1",
			{
				tasks: [
					{ task: "Review auth" },
					{ task: "Write tests" },
					{ task: "Check vulnerabilities" },
				],
			},
			undefined, undefined, mockCtxFunc(),
		);

		expect(result.content[0].text).toMatch(/3 jobs|3.*fork/i);
		expect(result.details.jobs).toHaveLength(3);
		for (const job of result.details.jobs) {
			expect(job).toHaveProperty("id");
			expect(job).toHaveProperty("name");
			expect(job).toHaveProperty("task");
			expect(job).toHaveProperty("status");
		}
	});

	test("each job in tasks array gets a unique ID", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const result = await forkTool.execute(
			"fp-2",
			{
				tasks: [
					{ task: "t1" },
					{ task: "t2" },
					{ task: "t3" },
					{ task: "t4" },
				],
			},
			undefined, undefined, mockCtxFunc(),
		);

		const ids = result.details.jobs.map((j: any) => j.id);
		const uniqueIds = new Set(ids);
		expect(uniqueIds.size).toBe(4);
	});

	test("enforces 8-job cap — excess fork is rejected", async () => {
		const freshCtx = createMockExtension();
		const freshMod = await import("../index.js");
		freshMod.default(freshCtx.pi);
		const freshForkTool = freshCtx.registeredTools.get("subagent_fork");
		const freshJobMgr = freshCtx.pi.jobMgr;
		const freshMockCtx = () => ({ cwd: "/test", hasUI: false, signal: undefined, ui: { confirm: vi.fn() } });

		for (let i = 0; i < MAX_RUNNING_JOBS; i++) {
			freshJobMgr.createJob(`agent-${i}`, `Task ${i}`);
		}

		const result = await freshForkTool.execute(
			"fp-cap-attempt",
			{ task: "Over cap" },
			undefined, undefined, freshMockCtx(),
		);
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toMatch(/8|maximum|concurrent/i);
	});

	test("9 tasks in single call triggers cap check", async () => {
		const freshCtx = createMockExtension();
		const freshMod = await import("../index.js");
		freshMod.default(freshCtx.pi);
		const freshForkTool = freshCtx.registeredTools.get("subagent_fork");
		const freshJobMgr = freshCtx.pi.jobMgr;
		const freshMockCtx = () => ({ cwd: "/test", hasUI: false, signal: undefined, ui: { confirm: vi.fn() } });

		for (let i = 0; i < MAX_RUNNING_JOBS; i++) {
			freshJobMgr.createJob(`fill-${i}`, `Fill task ${i}`);
		}

		const result = await freshForkTool.execute(
			"fp9-attempt",
			{
				tasks: Array.from({ length: 9 }, (_, i) => ({
					task: `Task ${i}`,
				})),
			},
			undefined, undefined, freshMockCtx(),
		);
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toMatch(/8|maximum|concurrent/i);
	});

	test("single task mode still works alongside tasks array", async () => {
		const forkTool = registeredTools.get("subagent_fork");

		const result = await forkTool.execute(
			"fp-single",
			{ task: "Single task" },
			undefined, undefined, mockCtxFunc(),
		);

		expect(result.details.jobs).toHaveLength(1);
		expect(result.details.jobs[0].name).toBe("single");
	});
});

describe("subagent_fork per-task overrides", () => {
	test("per-task provider override in spawned config", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const result = await forkTool.execute(
			"fp-override-1",
			{
				tasks: [
					{ task: "Review something", provider: "anthropic" },
					{ task: "Write something", provider: "openai" },
				],
			},
			undefined, undefined, mockCtxFunc(),
		);

		expect(result.details.jobs).toHaveLength(2);
		// Verify provider overrides were applied to each spawned job
		expect(result.details.jobs[0].provider).toBe("anthropic");
		expect(result.details.jobs[1].provider).toBe("openai");
	});

	test("top-level provider/thinking applies to single task", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const result = await forkTool.execute(
			"fp-toplevel-single",
			{
				task: "Top level task",
				provider: "anthropic",
			},
			undefined, undefined, mockCtxFunc(),
		);

		expect(result.details.jobs).toHaveLength(1);
		expect(result.details.jobs[0].provider).toBe("anthropic");
	});
});
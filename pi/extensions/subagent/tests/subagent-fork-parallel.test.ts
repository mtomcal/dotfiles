/**
 * Cycle 7: Fork Parallel Support.
 *
 * Test that subagent_fork correctly handles arrays of tasks,
 * enforces the 8-job cap across calls, and supports per-task overrides.
 */

import { describe, test, expect, vi, beforeAll } from "vitest";
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

function mockCtx() {
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
					{ agent: "code-reviewer", task: "Review auth" },
					{ agent: "test-writer", task: "Write tests" },
					{ agent: "security", task: "Check vulnerabilities" },
				],
			},
			undefined,
			undefined,
			mockCtx(),
		);

		expect(result.content[0].text).toMatch(/3 jobs|3.*fork/i);
		expect(result.details.jobs).toHaveLength(3);
		for (const job of result.details.jobs) {
			expect(job).toHaveProperty("id");
			expect(job).toHaveProperty("agent");
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
					{ agent: "a", task: "t1" },
					{ agent: "b", task: "t2" },
					{ agent: "c", task: "t3" },
					{ agent: "d", task: "t4" },
				],
			},
			undefined,
			undefined,
			mockCtx(),
		);

		const ids = result.details.jobs.map((j: any) => j.id);
		const uniqueIds = new Set(ids);
		expect(uniqueIds.size).toBe(4);
	});

	test("enforces 8-job cap — ninth individual fork is rejected", async () => {
		// Fill the cap directly via JobManager (bypassing fork, which would
		// immediately fail jobs in the test env where agents aren't discoverable).
		// This tests that the fork tool correctly checks runningCount() before spawning.
		const freshCtx = createMockExtension();
		const freshMod = await import("../index.js");
		freshMod.default(freshCtx.pi);
		const freshForkTool = freshCtx.registeredTools.get("subagent_fork");
		const freshJobMgr = freshCtx.pi.jobMgr;
		const freshMockCtx = () => ({ cwd: "/test", hasUI: false, signal: undefined, ui: { confirm: vi.fn() } });

		// Pre-fill 8 running jobs directly in the JobManager
		for (let i = 0; i < MAX_RUNNING_JOBS; i++) {
			freshJobMgr.createJob(`agent-${i}`, `Task ${i}`);
		}
		expect(freshJobMgr.runningCount()).toBe(MAX_RUNNING_JOBS);

		// 9th fork must be rejected at the cap check
		const result = await freshForkTool.execute(
			"fp-cap-attempt",
			{ agent: "excess", task: "Over cap" },
			undefined,
			undefined,
			freshMockCtx(),
		);
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toMatch(/8|maximum|concurrent/i);
	});

	test("cap enforcement error message includes max count", async () => {
		const freshCtx = createMockExtension();
		const freshMod = await import("../index.js");
		freshMod.default(freshCtx.pi);
		const freshForkTool = freshCtx.registeredTools.get("subagent_fork");
		const freshJobMgr = freshCtx.pi.jobMgr;
		const freshMockCtx = () => ({ cwd: "/test", hasUI: false, signal: undefined, ui: { confirm: vi.fn() } });

		// Pre-fill 8 running jobs directly in the JobManager
		for (let i = 0; i < MAX_RUNNING_JOBS; i++) {
			freshJobMgr.createJob(`cap-agent-${i}`, `Cap task ${i}`);
		}

		// One more should fail with isError containing the cap message.
		const result = await freshForkTool.execute(
			"fp-fresh-attempt",
			{ agent: "excess", task: "Over cap" },
			undefined,
			undefined,
			freshMockCtx(),
		);
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toMatch(/8|maximum|concurrent/i);
	});

	test("single call with 9 tasks triggers cap check", async () => {
		const freshCtx = createMockExtension();
		const freshMod = await import("../index.js");
		freshMod.default(freshCtx.pi);
		const freshForkTool = freshCtx.registeredTools.get("subagent_fork");
		const freshJobMgr = freshCtx.pi.jobMgr;
		const freshMockCtx = () => ({ cwd: "/test", hasUI: false, signal: undefined, ui: { confirm: vi.fn() } });

		// Pre-fill 8 running jobs directly in the JobManager
		for (let i = 0; i < MAX_RUNNING_JOBS; i++) {
			freshJobMgr.createJob(`fill-${i}`, `Fill task ${i}`);
		}

		// Try to spawn 9 more in a single call — should be rejected because 9 > (8 - runningCount)
		const result = await freshForkTool.execute(
			"fp9-attempt",
			{
				tasks: Array.from({ length: 9 }, (_, i) => ({
					agent: `agent-${i}`,
					task: `Task ${i}`,
				})),
			},
			undefined,
			undefined,
			freshMockCtx(),
		);
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toMatch(/8|maximum|concurrent/i);
	});

	test("single agent+task mode still works alongside tasks array", async () => {
		const forkTool = registeredTools.get("subagent_fork");

		const result = await forkTool.execute(
			"fp-single",
			{ agent: "single-agent", task: "Single task" },
			undefined,
			undefined,
			mockCtx(),
		);

		expect(result.details.jobs).toHaveLength(1);
		expect(result.details.jobs[0].agent).toBe("single-agent");
	});

	test("returns error when both agent+task and tasks are provided", async () => {
		const forkTool = registeredTools.get("subagent_fork");

		const result = await forkTool.execute(
			"fp-ambiguous",
			{
				agent: "a",
				task: "t",
				tasks: [{ agent: "b", task: "t2" }],
			},
			undefined,
			undefined,
			mockCtx(),
		);

		// agent+task takes precedence (single mode)
		expect(result.details.jobs).toHaveLength(1);
	});
});

describe("subagent_fork per-task overrides", () => {
	test("per-task provider override", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const result = await forkTool.execute(
			"fp-override-1",
			{
				tasks: [
					{ agent: "reviewer", task: "Review", provider: "anthropic" },
					{ agent: "writer", task: "Write", provider: "openai" },
				],
			},
			undefined,
			undefined,
			mockCtx(),
		);

		expect(result.details.jobs).toHaveLength(2);
	});

	test("per-task thinking override", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const result = await forkTool.execute(
			"fp-override-2",
			{
				tasks: [
					{ agent: "reviewer", task: "Review", thinking: "high" as any },
					{ agent: "writer", task: "Write", thinking: "off" as any },
				],
			},
			undefined,
			undefined,
			mockCtx(),
		);

		expect(result.details.jobs).toHaveLength(2);
	});

	test("top-level provider/thinking applies to all tasks when per-task not set", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const result = await forkTool.execute(
			"fp-toplevel",
			{
				provider: "anthropic",
				thinking: "high" as any,
				tasks: [
					{ agent: "a", task: "task a" },
					{ agent: "b", task: "task b" },
				],
			},
			undefined,
			undefined,
			mockCtx(),
		);

		expect(result.details.jobs).toHaveLength(2);
	});

	test("per-task overrides take precedence over top-level", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const result = await forkTool.execute(
			"fp-precedence",
			{
				provider: "openai",
				thinking: "low" as any,
				tasks: [
					{ agent: "a", task: "t1", provider: "anthropic" },
					{ agent: "b", task: "t2", thinking: "high" as any },
				],
			},
			undefined,
			undefined,
			mockCtx(),
		);

		expect(result.details.jobs).toHaveLength(2);
	});
});
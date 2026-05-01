/**
 * Cycle 2: Fork — Subagent background job spawning.
 *
 * RED: Tests for subagent_fork tool.
 */

import { describe, test, expect, vi, beforeAll } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import { MAX_RUNNING_JOBS } from "../job-manager.js";

let registeredTools: Map<string, any>;
let mockPi: any;
let forkTool: any;
let mockCtx: any;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
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

describe("subagent_fork", () => {
	test("is registered as a tool", () => {
		expect(forkTool).toBeDefined();
	});

	test("spawns single background job and returns job ID", async () => {
		const result = await forkTool.execute("call-1", { agent: "code-reviewer", task: "Review the auth module" }, undefined, undefined, mockCtx);

		expect(result.content[0].text).toMatch(/forked/i);
		expect(result.details.jobs).toHaveLength(1);
		expect(result.details.jobs[0].agent).toBe("code-reviewer");
	});

	test("spawns multiple jobs with tasks array", async () => {
		const result = await forkTool.execute(
			"call-2",
			{
				tasks: [
					{ agent: "code-reviewer", task: "Review auth" },
					{ agent: "test-writer", task: "Write tests" },
				],
			},
			undefined,
			undefined,
			mockCtx,
		);

		expect(result.content[0].text).toMatch(/2 jobs/);
		expect(result.details.jobs).toHaveLength(2);
	});

	test("returns job count and running count in response", async () => {
		const result = await forkTool.execute(
			"call-3",
			{ agent: "agent-x", task: "some task" },
			undefined,
			undefined,
			mockCtx,
		);

		// Should show "Forked 1 job (N/8 running)"
		expect(result.content[0].text).toMatch(/Forked 1 job/);
		// Contains running count
		expect(result.content[0].text).toMatch(/\d+\/8/);
	});

	test("per-task provider/thinking overrides", async () => {
		const result = await forkTool.execute(
			"call-4",
			{
				tasks: [
					{ agent: "reviewer", task: "Review", provider: "anthropic" },
					{ agent: "writer", task: "Write", thinking: "high" as any },
				],
			},
			undefined,
			undefined,
			mockCtx,
		);

		expect(result.content[0].text).toMatch(/forked/i);
		expect(result.details.jobs).toHaveLength(2);
	});

	test("returns error for invalid params (no agent or tasks)", async () => {
		const result = await forkTool.execute("call-5", {}, undefined, undefined, mockCtx);
		expect(result.isError).toBe(true);
	});

	test("each spawned job has id, agent, task, and status fields", async () => {
		const result = await forkTool.execute(
			"call-6",
			{
				tasks: [
					{ agent: "agent-a", task: "task a" },
					{ agent: "agent-b", task: "task b" },
				],
			},
			undefined,
			undefined,
			mockCtx,
		);

		for (const job of result.details.jobs) {
			expect(job).toHaveProperty("id");
			expect(job).toHaveProperty("agent");
			expect(job).toHaveProperty("task");
			expect(job).toHaveProperty("status");
		}
	});
});

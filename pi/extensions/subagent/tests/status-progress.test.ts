/**
 * Slice 5: Enhanced subagent_status — Progress Section
 *
 * RED tests — the Progress section in subagent_status output does NOT exist yet.
 * These tests define the expected contract for showing progress info on running jobs.
 */

import { describe, test, expect, vi, beforeAll, beforeEach, afterEach } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import type { SingleResult } from "../job-manager.js";
import type { Message } from "@earendil-works/pi-ai";

let registeredTools: Map<string, any>;
let mockPi: any;
let statusTool: any;
let jobMgr: any;
let mockCtx: any;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
	jobMgr = ctx.jobMgr;
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(mockPi);

	statusTool = registeredTools.get("subagent_status");

	mockCtx = {
		cwd: "/test",
		hasUI: false,
		signal: undefined,
		ui: { confirm: vi.fn() },
	} as any;
});

beforeEach(() => {
	jobMgr.cancelAll();
	for (const job of jobMgr.listJobs()) {
		(jobMgr as any).jobs.delete(job.id);
	}
});

afterEach(() => {
	jobMgr.cancelAll();
	for (const job of jobMgr.listJobs()) {
		(jobMgr as any).jobs.delete(job.id);
	}
});

// ── Helpers ────────────────────────────────────────────────────────────────

/** Build a partial result that represents a still-running job's progress. */
function makePartialResult(overrides: Partial<SingleResult> = {}): SingleResult {
	return {
		name: "progress-test",
		task: "Running task with progress",
		exitCode: -1, // still running
		messages: [
   // @ts-expect-error -- test fixture with incomplete Message type
			{
				role: "assistant",
				content: [{ type: "text", text: "This is a sufficiently long text block that exceeds the fifty character threshold for summary extraction." }],
			},
			{
				role: "assistant",
    // @ts-expect-error -- test fixture with incomplete Message type
				content: [{ type: "toolCall", name: "bash", arguments: { command: "npm test" } }],
			},
		],
		stderr: "",
		usage: {
			input: 5000,
			output: 1200,
			cacheRead: 3000,
			cacheWrite: 800,
			cost: 0.034,
			contextTokens: 6000,
			turns: 3,
		},
		provider: "ollama-cloud",
		model: "deepseek-v4-flash",
		...overrides,
	};
}

/** Create a running job with an optional partial result and return its ID. */
function createRunningJob(name: string = "progress-test", task: string = "Running task with progress", partialResult?: SingleResult | null): string {
	const job = jobMgr.createJob(name, task);
	if (partialResult !== undefined && partialResult !== null) {
		// Directly set partial result on the running job
		(jobMgr.getJob(job.id) as any).result = partialResult;
	} else if (partialResult === null) {
		// Explicitly null — no partial result yet
		(jobMgr.getJob(job.id) as any).result = null;
	}
	return job.id;
}

// ── Tests ──────────────────────────────────────────────────────────────────

describe("subagent_status Progress section for running jobs", () => {
	test("running job with partial result includes a **Progress:** section", async () => {
		const jobId = createRunningJob("progress-test", "Running task with progress", makePartialResult());

		const result = await statusTool.execute("sp1", { jobId }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).toContain("**Progress:**");
	});

	test("Progress section shows turns so far from the partial result", async () => {
		const partial = makePartialResult();
		expect(partial.usage.turns).toBe(3);

		const jobId = createRunningJob("progress-test", "Running task with progress", partial);

		const result = await statusTool.execute("sp2", { jobId }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).toContain("3 turn");
	});

	test("Progress section shows usage stats from the partial result", async () => {
		const partial = makePartialResult();

		const jobId = createRunningJob("progress-test", "Running task with progress", partial);

		const result = await statusTool.execute("sp3", { jobId }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		// Should include formatted usage from formatUsageStats
		expect(text).toContain("5.0k"); // input tokens ↑5.0k
		expect(text).toContain("1.2k"); // output tokens ↓1.2k
	});

	test("Progress section shows last text snippet using extractSummary (skipping blocks under 50 chars)", async () => {
		const partial = makePartialResult({
			messages: [
				{ role: "assistant", content: [{ type: "text", text: "Short." }] } as Message, // < 50 chars, should be skipped
				{ role: "assistant", content: [{ type: "text", text: "Here is a substantive progress update that clearly exceeds the fifty character minimum threshold." }] } as Message, // ≥ 50 chars
			],
		});
		const jobId = createRunningJob("progress-test", "Running task with progress", partial);

		const result = await statusTool.execute("sp4", { jobId }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		// Should include the long text block, not "Short."
		expect(text).toContain("Here is a substantive progress update");
		expect(text).not.toContain("Short.");
	});

	test("Progress section shows last tool call from completed messages", async () => {
		const partial = makePartialResult({
			messages: [
				{ role: "assistant", content: [{ type: "text", text: "This is a long enough text block to pass the fifty character threshold for display." }] } as Message,
    // @ts-expect-error -- test fixture with incomplete Message type
				{ role: "assistant", content: [{ type: "toolCall", name: "bash", arguments: { command: "npm test" } }] } as Message,
			],
		});
		const jobId = createRunningJob("progress-test", "Running task with progress", partial);

		const result = await statusTool.execute("sp5", { jobId }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		// Should show the last tool call
		expect(text).toContain("npm test");
	});

	test("Progress section only shows completed messages (not mid-stream data)", async () => {
		// The partial result should only contain full/complete messages,
		// not partial tool_result messages that are still streaming.
		// This test ensures the Progress section reads from job.result.messages
		// (which only contains completed messages), not from any live stream.
		const partial = makePartialResult({
			messages: [
				{ role: "assistant", content: [{ type: "text", text: "Completed analysis of the codebase, found several issues worth addressing." }] } as Message,
    // @ts-expect-error -- test fixture with incomplete Message type
				{ role: "assistant", content: [{ type: "toolCall", name: "bash", arguments: { command: "npm test" } }] } as Message,
				// No mid-stream tool_result messages — only completed message entries
			],
		});
		const jobId = createRunningJob("progress-test", "Running task with progress", partial);

		const result = await statusTool.execute("sp6", { jobId }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		// Should have the completed text and tool call, no partial/streaming artifacts
		expect(text).toContain("Completed analysis");
		expect(text).toContain("npm test");
		// Should NOT contain any "tool_result" or streaming markers
		expect(text).not.toContain("tool_result");
	});

	test("when running job has no result yet (null), show 'No progress data available yet'", async () => {
		const jobId = createRunningJob("progress-test", "Running task with progress", null);

		const result = await statusTool.execute("sp7", { jobId }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).toContain("No progress data available yet");
	});

	test("Progress section appears AFTER the existing elapsed time info", async () => {
		const partial = makePartialResult();
		const jobId = createRunningJob("progress-test", "Running task with progress", partial);

		const result = await statusTool.execute("sp8", { jobId }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		const elapsedIndex = text.indexOf("**Elapsed:**");
		const progressIndex = text.indexOf("**Progress:**");

		expect(elapsedIndex).toBeGreaterThan(-1);
		expect(progressIndex).toBeGreaterThan(-1);
		expect(progressIndex).toBeGreaterThan(elapsedIndex);
	});
});

describe("subagent_status Progress section — completed jobs should NOT have it", () => {
	test("completed job does not include a Progress section", async () => {
		const job = jobMgr.createJob("completed-name", "Finished work");
		jobMgr.completeJob(job.id, {
			name: "completed-name",
			task: "Finished work",
			exitCode: 0,
			messages: [{ role: "assistant", content: [{ type: "text", text: "Done successfully" }] } as Message],
			stderr: "",
			usage: { input: 100, output: 50, cacheRead: 0, cacheWrite: 0, cost: 0.01, contextTokens: 500, turns: 1 },
		});

		const result = await statusTool.execute("sp10", { jobId: job.id }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		// Completed jobs show Summary, not Progress
		expect(text).not.toContain("**Progress:**");
		expect(text).toContain("**Summary:**");
	});

	test("failed job does not include a Progress section", async () => {
		const job = jobMgr.createJob("failed-name", "Bad task");
		jobMgr.failJob(job.id, "Process exited with code 1");

		const result = await statusTool.execute("sp11", { jobId: job.id }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).not.toContain("**Progress:**");
		expect(text).toContain("**Error:**");
	});

	test("cancelled job does not include a Progress section", async () => {
		const job = jobMgr.createJob("cancelled-name", "Aborted task");
		jobMgr.cancelJob(job.id);

		const result = await statusTool.execute("sp12", { jobId: job.id }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).not.toContain("**Progress:**");
	});
});
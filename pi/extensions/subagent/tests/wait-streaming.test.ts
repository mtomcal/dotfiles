/**
 * Slice 6: Enhanced subagent_wait — Streaming Progress
 *
 * RED tests — `updatePartialResult` does not yet exist on JobManager,
 * and `subagent_wait` does not yet call `onUpdate` during polling.
 * These tests define the expected contract for streaming progress updates.
 */

import { describe, test, expect, vi } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import { fakeSingleResult } from "./helpers.js";
import type { SingleResult } from "../job-manager.js";

/**
 * Create a partial result with text and tool call messages
 * for testing progress trace formatting.
 */
function makePartialResult(overrides: Partial<SingleResult> = {}): SingleResult {
	return fakeSingleResult({
		name: "streaming-test",
		task: "Stream test task",
		messages: [
			{
				role: "assistant",
				content: [{ type: "text", text: "Working on the code..." }],
			},
			{
				role: "assistant",
				content: [
					{ type: "toolCall", name: "bash", arguments: { command: "npm test" } },
				],
			},
			{
				role: "assistant",
				content: [{ type: "text", text: "Tests passed, now formatting..." }],
			},
		],
		usage: {
			input: 1000,
			output: 300,
			cacheRead: 500,
			cacheWrite: 200,
			cost: 0.01,
			contextTokens: 2000,
			turns: 2,
		},
		...overrides,
	});
}

function makeCompletedResult(overrides: Partial<SingleResult> = {}): SingleResult {
	return fakeSingleResult({
		name: "streaming-test",
		task: "Stream test task",
		exitCode: 0,
		messages: [
			{
				role: "assistant",
				content: [{ type: "text", text: "All done! Changes applied." }],
			},
		],
		usage: {
			input: 3000,
			output: 800,
			cacheRead: 1000,
			cacheWrite: 400,
			cost: 0.05,
			contextTokens: 5000,
			turns: 4,
		},
		...overrides,
	});
}

describe("subagent_wait — streaming progress", () => {
	test("onUpdate is called with progress content on each poll iteration when job has partial result", async () => {
		const freshCtx = createMockExtension();
		const freshMod = await import("../index.js");
		freshMod.default(freshCtx.pi);
		const waitTool = freshCtx.registeredTools.get("subagent_wait");
		const mockCtx = {
			cwd: "/test",
			hasUI: false,
			signal: undefined,
			ui: { confirm: vi.fn() },
		} as any;
		const onUpdate = vi.fn();

		const job = freshCtx.jobMgr.createJob("streaming-test", "Stream test task");

		// Set partial result on the running job — updatePartialResult doesn't exist yet (RED)
		const partial = makePartialResult();
		freshCtx.jobMgr.updatePartialResult(job.id, partial);

		// Start wait with short timeout; we'll complete the job before timeout
		const waitPromise = waitTool.execute(
			"w1",
			{ jobId: job.id, timeout: 10 },
			undefined,
			onUpdate,
			mockCtx,
		);

		// Let at least one poll iteration happen (500ms), then complete the job
		await new Promise((resolve) => setTimeout(resolve, 600));
		const completed = makeCompletedResult();
		freshCtx.jobMgr.completeJob(job.id, completed);

		const result = await waitPromise;

		// onUpdate should have been called at least once during polling
		expect(onUpdate).toHaveBeenCalled();
		const callCount = onUpdate.mock.calls.length;
		expect(callCount).toBeGreaterThanOrEqual(1);
	});

	test("progress update format includes two-line trace (last text snippet + last tool call)", async () => {
		const freshCtx = createMockExtension();
		const freshMod = await import("../index.js");
		freshMod.default(freshCtx.pi);
		const waitTool = freshCtx.registeredTools.get("subagent_wait");
		const mockCtx = {
			cwd: "/test",
			hasUI: false,
			signal: undefined,
			ui: { confirm: vi.fn() },
		} as any;
		const onUpdate = vi.fn();

		const job = freshCtx.jobMgr.createJob("streaming-test", "Stream test task");

		// Partial result with specific text and tool call for trace verification
		const partial = makePartialResult({
			messages: [
				{
					role: "assistant",
					content: [{ type: "text", text: "Analyzing the auth module..." }],
				},
				{
					role: "assistant",
					content: [
						{ type: "toolCall", name: "read", arguments: { file_path: "src/auth.ts" } },
					],
				},
				{
					role: "assistant",
					content: [{ type: "text", text: "Found the issue in the auth logic." }],
				},
				{
					role: "assistant",
					content: [
						{ type: "toolCall", name: "edit", arguments: { path: "src/auth.ts" } },
					],
				},
			],
		});
		freshCtx.jobMgr.updatePartialResult(job.id, partial);

		const waitPromise = waitTool.execute(
			"w2",
			{ jobId: job.id, timeout: 10 },
			undefined,
			onUpdate,
			mockCtx,
		);

		await new Promise((resolve) => setTimeout(resolve, 600));
		freshCtx.jobMgr.completeJob(job.id, makeCompletedResult());

		await waitPromise;

		expect(onUpdate).toHaveBeenCalled();

		// The progress content should include the last text snippet and last tool call
		const updateCalls = onUpdate.mock.calls;
		const lastUpdateCall = updateCalls[updateCalls.length - 1];
		const updateArg = lastUpdateCall?.[0];

		if (updateArg?.content?.[0]?.text) {
			const progressText = updateArg.content[0].text;
			// Should contain the last text snippet from messages
			expect(progressText).toContain("Found the issue in the auth logic.");
			// Should contain the last tool call info
			expect(progressText).toContain("edit");
			expect(progressText).toContain("src/auth.ts");
		}
	});

	test("subagent_wait still returns final result when job completes", async () => {
		const freshCtx = createMockExtension();
		const freshMod = await import("../index.js");
		freshMod.default(freshCtx.pi);
		const waitTool = freshCtx.registeredTools.get("subagent_wait");
		const mockCtx = {
			cwd: "/test",
			hasUI: false,
			signal: undefined,
			ui: { confirm: vi.fn() },
		} as any;
		const onUpdate = vi.fn();

		const job = freshCtx.jobMgr.createJob("streaming-test", "Stream test task");
		freshCtx.jobMgr.updatePartialResult(job.id, makePartialResult());

		const completed = makeCompletedResult();

		const waitPromise = waitTool.execute(
			"w3",
			{ jobId: job.id, timeout: 10 },
			undefined,
			onUpdate,
			mockCtx,
		);

		await new Promise((resolve) => setTimeout(resolve, 600));
		freshCtx.jobMgr.completeJob(job.id, completed);

		const result = await waitPromise;

		// Final result should contain the completed result content, not the partial
		expect(result.content[0].text).toContain("All done! Changes applied.");
		expect(result.isError).toBeFalsy();
		expect(result.details.results).toBeDefined();
	});

	test("subagent_wait respects timeout even with streaming updates", async () => {
		const freshCtx = createMockExtension();
		const freshMod = await import("../index.js");
		freshMod.default(freshCtx.pi);
		const waitTool = freshCtx.registeredTools.get("subagent_wait");
		const mockCtx = {
			cwd: "/test",
			hasUI: false,
			signal: undefined,
			ui: { confirm: vi.fn() },
		} as any;
		const onUpdate = vi.fn();

		const job = freshCtx.jobMgr.createJob("slow-name", "Slow task that won't complete");
		// Set partial result so progress updates would be emitted
		freshCtx.jobMgr.updatePartialResult(job.id, makePartialResult());

		// Very short timeout — job won't complete in time
		const result = await waitTool.execute(
			"w4",
			{ jobId: job.id, timeout: 1 },
			undefined,
			onUpdate,
			mockCtx,
		);

		expect(result.content[0].text).toMatch(/still running|timed out/i);
		expect(result.isError).toBe(true);
	});

	test("onUpdate is called with text showing the job name and progress info", async () => {
		const freshCtx = createMockExtension();
		const freshMod = await import("../index.js");
		freshMod.default(freshCtx.pi);
		const waitTool = freshCtx.registeredTools.get("subagent_wait");
		const mockCtx = {
			cwd: "/test",
			hasUI: false,
			signal: undefined,
			ui: { confirm: vi.fn() },
		} as any;
		const onUpdate = vi.fn();

		const job = freshCtx.jobMgr.createJob("my-reviewer", "Review the auth module");
		freshCtx.jobMgr.updatePartialResult(
			job.id,
			makePartialResult({
				name: "my-reviewer",
				task: "Review the auth module",
				messages: [
					{
						role: "assistant",
						content: [{ type: "text", text: "Checking auth module structure..." }],
					},
				],
				usage: {
					input: 500,
					output: 100,
					cacheRead: 200,
					cacheWrite: 50,
					cost: 0.005,
					contextTokens: 1000,
					turns: 1,
				},
			}),
		);

		const waitPromise = waitTool.execute(
			"w5",
			{ jobId: job.id, timeout: 10 },
			undefined,
			onUpdate,
			mockCtx,
		);

		await new Promise((resolve) => setTimeout(resolve, 600));
		freshCtx.jobMgr.completeJob(job.id, makeCompletedResult({ name: "my-reviewer" }));

		await waitPromise;

		expect(onUpdate).toHaveBeenCalled();

		// At least one onUpdate call should mention the job name
		const allUpdateTexts = onUpdate.mock.calls
			.map((call: any[]) => call[0]?.content?.[0]?.text ?? "")
			.filter(Boolean);
		const hasJobNameInUpdate = allUpdateTexts.some((text: string) =>
			text.includes("my-reviewer"),
		);
		expect(hasJobNameInUpdate).toBe(true);
	});

	test("no progress update sent when job has null result (not yet started)", async () => {
		const freshCtx = createMockExtension();
		const freshMod = await import("../index.js");
		freshMod.default(freshCtx.pi);
		const waitTool = freshCtx.registeredTools.get("subagent_wait");
		const mockCtx = {
			cwd: "/test",
			hasUI: false,
			signal: undefined,
			ui: { confirm: vi.fn() },
		} as any;
		const onUpdate = vi.fn();

		// Create job but do NOT set any partial result — result is null
		const job = freshCtx.jobMgr.createJob("null-result-job", "Nothing happening yet");

		const waitPromise = waitTool.execute(
			"w6",
			{ jobId: job.id, timeout: 2 },
			undefined,
			onUpdate,
			mockCtx,
		);

		// Complete the job quickly without any partial result
		await new Promise((resolve) => setTimeout(resolve, 200));
		freshCtx.jobMgr.completeJob(job.id, makeCompletedResult({ name: "null-result-job" }));

		const result = await waitPromise;

		// With null result (no partial), onUpdate should NOT have been called with progress
		// It should only be called if there's actual partial content to display
		const progressCalls = onUpdate.mock.calls.filter((call: any[]) => {
			const text = call[0]?.content?.[0]?.text ?? "";
			// Progress updates show partial content; completion is handled by return value
			return text.length > 0 && !text.includes("already");
		});

		// No progress updates should have been emitted since result was null the entire time
		// The job completed almost immediately, so there was no poll iteration with partial data
		expect(progressCalls.length).toBe(0);
	});
});
/**
 * Slice 3: Cancellation Notifications
 *
 * Tests that cancelling a job (or all jobs) sends a steer notification
 * via pi.sendMessage with the ⊘ icon, job name, elapsed time,
 * partial usage stats, and last completed assistant text / tool call.
 *
 * RED tests — emitCancellationNotification is not yet implemented.
 * These tests should FAIL until the cancel tool calls it.
 */

import { describe, test, expect, vi, beforeAll, afterEach } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import { fakeSingleResult, fakeUsageStats, fakeMessage, fakeMessageWith, fakeToolCall } from "./helpers.js";
import type { SingleResult } from "../job-manager.js";
import type { Message } from "@mariozechner/pi-ai";

let registeredTools: Map<string, any>;
let mockPi: any;
let jobMgr: any;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
	jobMgr = ctx.jobMgr;
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(mockPi);
});

afterEach(() => {
	// Clean up all jobs between tests
	mockPi.sentMessages.length = 0;
	for (const job of jobMgr.listJobs()) {
		(jobMgr as any).jobs.delete(job.id);
	}
});

/**
 * Helper: set a partial result on a running job to simulate mid-stream data.
 * This mimics what happens when a job is cancelled while the subagent process
 * has already emitted some messages.
 */
function setPartialResult(jobId: string, result: SingleResult): void {
	const job = jobMgr.getJob(jobId);
	if (job) {
		job.result = result;
	}
}

/**
 * Helper: build a SingleResult with assistant text and a tool call.
 */
function makePartialResult(overrides: Partial<SingleResult> = {}): SingleResult {
	return fakeSingleResult({
		name: "reviewer",
		task: "Review the auth module",
		exitCode: 0,
		messages: [
			fakeMessageWith([
				{ type: "text", text: "I've reviewed the auth module. The login function looks correct but the token refresh logic has a race condition." },
			]) as Message,
			fakeMessageWith([
				fakeToolCall("read", { file_path: "/src/auth.ts", offset: 1, limit: 50 }),
			]) as Message,
			fakeMessageWith([
				{ type: "text", text: "The token refresh at line 42 needs a mutex to prevent concurrent refresh attempts." },
			]) as Message,
		],
		usage: fakeUsageStats(),
		...overrides,
	});
}

function findCancellationMessages(): any[] {
	return mockPi.sentMessages.filter(
		(m: any) =>
			m.customType === "subagent-result" &&
			m.details?.status === "cancelled",
	);
}

// ─── Cancel a single job ────────────────────────────────────────────

describe("cancellation notification — single job", () => {
	test("cancel sends a steer notification with ⊘ or 'cancelled' status", async () => {
		const cancelTool = registeredTools.get("subagent_cancel");
		const job = jobMgr.createJob("reviewer", "Review the auth module");
		setPartialResult(job.id, makePartialResult());
		jobMgr.cancelJob(job.id);

		const cancelMessages = findCancellationMessages();
		expect(cancelMessages.length).toBeGreaterThanOrEqual(1);

		const msg = cancelMessages[0];
		// Notification content should contain the cancellation icon or status
		expect(msg.content ?? msg.details?.status).toMatch(/⊘|cancelled/i);
	});

	test("notification includes job name", async () => {
		const job = jobMgr.createJob("code-reviewer", "Review auth module");
		setPartialResult(job.id, makePartialResult({ name: "code-reviewer" }));
		jobMgr.cancelJob(job.id);

		const cancelMessages = findCancellationMessages();
		expect(cancelMessages.length).toBeGreaterThanOrEqual(1);

		const msg = cancelMessages[0];
		expect(msg.details?.name ?? msg.content).toMatch(/code-reviewer/);
	});

	test("notification includes elapsed time", async () => {
		const job = jobMgr.createJob("linter", "Lint the codebase");
		// Simulate some elapsed time
		job.startedAt = Date.now() - 15000;
		setPartialResult(job.id, makePartialResult({ name: "linter" }));
		jobMgr.cancelJob(job.id);

		const cancelMessages = findCancellationMessages();
		expect(cancelMessages.length).toBeGreaterThanOrEqual(1);

		const msg = cancelMessages[0];
		// Content or details should include some form of elapsed time (e.g. "15s", "0m 15s")
		const text = msg.content ?? "";
		expect(text).toMatch(/\d+s|\d+ms|\d+m/);
	});

	test("notification includes partial usage stats", async () => {
		const job = jobMgr.createJob("reviewer", "Review the auth module");
		const usage = fakeUsageStats();
		setPartialResult(job.id, makePartialResult({ usage }));
		jobMgr.cancelJob(job.id);

		const cancelMessages = findCancellationMessages();
		expect(cancelMessages.length).toBeGreaterThanOrEqual(1);

		const msg = cancelMessages[0];
		// Usage should be present in details or content
		expect(msg.details?.usage ?? msg.content).toBeDefined();
		if (msg.details?.usage) {
			expect(msg.details.usage.input).toBe(usage.input);
			expect(msg.details.usage.output).toBe(usage.output);
		}
	});

	test("notification includes last completed assistant text", async () => {
		const job = jobMgr.createJob("reviewer", "Review the auth module");
		setPartialResult(job.id, makePartialResult());
		jobMgr.cancelJob(job.id);

		const cancelMessages = findCancellationMessages();
		expect(cancelMessages.length).toBeGreaterThanOrEqual(1);

		const msg = cancelMessages[0];
		const content = msg.content ?? "";
		const summary = msg.details?.summary ?? "";
		// Should contain the last assistant text (the token refresh observation)
		expect(content + summary).toContain("token refresh");
	});

	test("notification includes last completed tool call", async () => {
		const job = jobMgr.createJob("reviewer", "Review the auth module");
		setPartialResult(job.id, makePartialResult());
		jobMgr.cancelJob(job.id);

		const cancelMessages = findCancellationMessages();
		expect(cancelMessages.length).toBeGreaterThanOrEqual(1);

		const msg = cancelMessages[0];
		const content = msg.content ?? "";
		const details = msg.details ?? {};
		// The notification should reference at least the last tool call somewhere
		// (either in content, summary, or details.result.messages)
		const resultMessages = details.result?.messages ?? [];
		const hasToolCall = content.includes("read") ||
			content.includes("tool") ||
			resultMessages.some((m: any) =>
				m.content?.some?.((c: any) => c.type === "toolCall"),
			);
		expect(hasToolCall).toBe(true);
	});

	test("notification excludes partial/mid-stream data — only completed messages", async () => {
		const job = jobMgr.createJob("reviewer", "Review the auth module");
		// Create a result where the last message is a partial tool call
		// (simulating mid-stream cancellation)
		const partialResult = makePartialResult();
		// Add a partial tool_result message that wouldn't be "completed"
		partialResult.messages.push({
			role: "tool",
			content: [{ type: "toolResult", toolCallId: "tc_partial", result: "INCOMPLETE..." }],
		} as any);
		setPartialResult(job.id, partialResult);
		jobMgr.cancelJob(job.id);

		const cancelMessages = findCancellationMessages();
		expect(cancelMessages.length).toBeGreaterThanOrEqual(1);

		const msg = cancelMessages[0];
		const content = msg.content ?? "";
		// Should NOT include "INCOMPLETE..." — partial data excluded
		expect(content).not.toContain("INCOMPLETE...");
	});
});

// ─── sendMessage options ─────────────────────────────────────────────

describe("cancellation notification — delivery options", () => {
	test("notification sent with deliverAs: 'steer'", async () => {
		const job = jobMgr.createJob("reviewer", "Review the code");
		setPartialResult(job.id, makePartialResult());
		jobMgr.cancelJob(job.id);

		const cancelMessages = findCancellationMessages();
		expect(cancelMessages.length).toBeGreaterThanOrEqual(1);

		const msg = cancelMessages[0];
		expect(msg.options?.deliverAs).toBe("steer");
	});

	test("notification sent with triggerTurn: true", async () => {
		const job = jobMgr.createJob("reviewer", "Review the code");
		setPartialResult(job.id, makePartialResult());
		jobMgr.cancelJob(job.id);

		const cancelMessages = findCancellationMessages();
		expect(cancelMessages.length).toBeGreaterThanOrEqual(1);

		const msg = cancelMessages[0];
		expect(msg.options?.triggerTurn).toBe(true);
	});
});

// ─── Cancel all jobs ─────────────────────────────────────────────────

describe("cancellation notification — cancel all", () => {
	test("cancel all sends notifications for each running job", async () => {
		const job1 = jobMgr.createJob("reviewer", "Review auth");
		const job2 = jobMgr.createJob("linter", "Lint codebase");
		const job3 = jobMgr.createJob("tester", "Run tests");
		setPartialResult(job1.id, makePartialResult({ name: "reviewer" }));
		setPartialResult(job2.id, makePartialResult({ name: "linter" }));
		setPartialResult(job3.id, makePartialResult({ name: "tester" }));
		jobMgr.cancelAll();

		const cancelMessages = findCancellationMessages();
		// Each cancelled job should produce a notification
		expect(cancelMessages.length).toBe(3);

		const names = cancelMessages.map((m: any) => m.details?.name);
		expect(names).toContain("reviewer");
		expect(names).toContain("linter");
		expect(names).toContain("tester");
	});

	test("cancel all only notifies for running jobs (not completed)", async () => {
		const job1 = jobMgr.createJob("reviewer", "Review auth");
		const job2 = jobMgr.createJob("linter", "Lint codebase");
		jobMgr.completeJob(job1.id, fakeSingleResult());
		setPartialResult(job2.id, makePartialResult({ name: "linter" }));
		jobMgr.cancelAll();

		const cancelMessages = findCancellationMessages();
		// Only the running job (linter) should get a cancellation notification
		expect(cancelMessages.length).toBe(1);
		expect(cancelMessages[0].details?.name).toBe("linter");
	});
});

// ─── Graceful handling — no result ───────────────────────────────────

describe("cancellation notification — edge cases", () => {
	test("cancel job with no result does not crash (graceful handling)", async () => {
		const job = jobMgr.createJob("reviewer", "Review immediately-cancelled job");
		// Don't set any result — job was cancelled before any messages arrived
		expect(() => jobMgr.cancelJob(job.id)).not.toThrow();

		// If a notification is sent, it should be valid; if not, that's also fine
		// The key invariant: no crash
		const cancelMessages = findCancellationMessages();
		if (cancelMessages.length > 0) {
			const msg = cancelMessages[0];
			expect(msg.details?.status).toBe("cancelled");
		}
	});

	test("cancel job with null result sends minimal notification", async () => {
		const job = jobMgr.createJob("reviewer", "Review quick-cancelled");
		// Explicitly set result to null
		job.result = null;
		expect(() => jobMgr.cancelJob(job.id)).not.toThrow();

		const cancelMessages = findCancellationMessages();
		if (cancelMessages.length > 0) {
			const msg = cancelMessages[0];
			// Should still have basic fields
			expect(msg.details?.name ?? msg.content).toBeDefined();
			expect(msg.options?.deliverAs).toBe("steer");
			expect(msg.options?.triggerTurn).toBe(true);
		}
	});

	test("cancel job with empty messages array handles gracefully", async () => {
		const job = jobMgr.createJob("reviewer", "Review empty job");
		setPartialResult(job.id, fakeSingleResult({
			name: "reviewer",
			messages: [],
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
		}));
		expect(() => jobMgr.cancelJob(job.id)).not.toThrow();

		const cancelMessages = findCancellationMessages();
		if (cancelMessages.length > 0) {
			const msg = cancelMessages[0];
			expect(msg.details?.status).toBe("cancelled");
		}
	});
});

// ─── extractSummary integration ──────────────────────────────────────

describe("cancellation notification — content selection", () => {
	test("uses extractSummary to select content (≥ 50 chars for meaningful text)", async () => {
		const job = jobMgr.createJob("reviewer", "Review the auth module");
		// Set a result with a very short assistant text and a longer one
		// extractSummary should prefer the longer, more informative text
		const result: SingleResult = {
			name: "reviewer",
			task: "Review the auth module",
			exitCode: 0,
			messages: [
    // @ts-expect-error -- test fixture with incomplete Message type
				{
					role: "assistant",
					content: [{ type: "text", text: "ok" }], // too short — < 50 chars
				},
    // @ts-expect-error -- test fixture with incomplete Message type
				{
					role: "assistant",
					content: [
						{
							type: "text",
							text: "The authentication module has a critical vulnerability in the token refresh logic that could allow concurrent refresh attempts to create duplicate sessions.",
						},
					],
				},
			],
			stderr: "",
			usage: fakeUsageStats(),
		};
		setPartialResult(job.id, result);
		jobMgr.cancelJob(job.id);

		const cancelMessages = findCancellationMessages();
		expect(cancelMessages.length).toBeGreaterThanOrEqual(1);

		const msg = cancelMessages[0];
		const content = msg.content ?? "";
		const summary = msg.details?.summary ?? "";
		// The longer text should be selected as the summary, not "ok"
		expect(content + summary).toContain("critical vulnerability");
	});

	test("falls back to short text when no ≥ 50 char text exists", async () => {
		const job = jobMgr.createJob("reviewer", "Quick review");
		const result: SingleResult = {
			name: "reviewer",
			task: "Quick review",
			exitCode: 0,
			messages: [
    // @ts-expect-error -- test fixture with incomplete Message type
				{
					role: "assistant",
					content: [{ type: "text", text: "Looks fine, approved." }],
				},
			],
			stderr: "",
			usage: fakeUsageStats(),
		};
		setPartialResult(job.id, result);
		jobMgr.cancelJob(job.id);

		const cancelMessages = findCancellationMessages();
		if (cancelMessages.length > 0) {
			const msg = cancelMessages[0];
			const content = msg.content ?? "";
			const summary = msg.details?.summary ?? "";
			// Even short text should be used as fallback
			expect(content + summary).toContain("approved");
		}
	});
});
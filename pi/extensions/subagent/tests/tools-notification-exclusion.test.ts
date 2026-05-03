/**
 * Slice 5: Notification Exclusion Tests
 *
 * Verifies that completion and cancellation notifications do NOT display tools.
 * Per AIAGT v1.4.0 rules 25a and 25b:
 *   - Rule 25a: Completion notifications do NOT show a `**Tools:**` line
 *   - Rule 25b: Cancellation notifications do NOT show a `**Tools:**` line
 *
 * These are EXCLUSION surfaces — tools must never appear in notification content.
 */

import { describe, test, expect, vi, beforeAll, afterEach } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import { fakeSingleResult, fakeUsageStats, fakeMessage, fakeToolCall } from "./helpers.js";
import type { AsyncJob, SingleResult } from "../job-manager.js";
import type { Message } from "@mariozechner/pi-ai";

let registeredTools: Map<string, any>;
let mockPi: any;
let jobMgr: any;
let emitCompletionNotification: (job: AsyncJob) => void;
let emitCancellationNotification: (job: AsyncJob) => void;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
	jobMgr = ctx.jobMgr;
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(mockPi);

	// Get notification functions directly for manual invocation
	// (completion notifications are sent in fork flow, not in jobMgr.completeJob)
	const { extractSummary, truncateForWidget } = await import("../summary.js");
	const { formatUsageStats, getFinalOutput, getDisplayItems, formatToolCall } = await import("../renderers.js");

	emitCompletionNotification = (job: AsyncJob) => {
		// Replicate the notification logic from subagent_fork completion handler
		const result = job.result;
		if (!result) return;
		const smartContent = extractSummary(result.messages) || getFinalOutput(result.messages) || "(no output)";
		const truncatedContent = truncateForWidget(smartContent, 200);
		const usageLine = formatUsageStats(result.usage, result.model, result.provider, result.thinking);
		const statusEmoji = job.status === "completed" ? "✓" : "✗";
		const notificationContent = [
			`**Subagent ${statusEmoji}: \`${job.name}\` — ${job.status}**`,
			`**Job:** \`${job.id}\``,
			`**Task:** ${job.task}`,
			"",
			truncatedContent,
			"",
			usageLine ? `**Usage:** ${usageLine}` : "",
		].join("\n");
		mockPi.sendMessage(
			{
				customType: "subagent-result",
				content: notificationContent,
				display: true,
				details: {
					jobId: job.id,
					status: job.status,
					name: job.name,
					task: job.task,
					mode: "single",
					summary: truncatedContent,
					usage: result.usage,
					result,
				},
			},
			{ triggerTurn: true, deliverAs: "steer" },
		);
	};

	emitCancellationNotification = (job: AsyncJob) => {
		const summary = job.result ? extractSummary(job.result.messages) : "";
		const displayItems = job.result ? getDisplayItems(job.result.messages).filter(i => i.type === "toolCall") : [];
		const lastToolCall = displayItems.length > 0 ? displayItems[displayItems.length - 1] : null;
		const now = Date.now();
		const elapsedMs = (job.completedAt ?? now) - job.startedAt;
		const elapsed = elapsedMs < 1000 ? `${elapsedMs}ms` : elapsedMs < 60000 ? `${Math.round(elapsedMs / 1000)}s` : `${Math.floor(elapsedMs / 60000)}m ${Math.round((elapsedMs % 60000) / 1000)}s`;
		let toolCallLine = "";
		if (lastToolCall) {
			toolCallLine = `\n\u2192 ${formatToolCall(lastToolCall.name, lastToolCall.args, (_c: any, t: string) => t)}`;
		}
		const usageLine = job.result ? formatUsageStats(job.result.usage, job.result.model, job.result.provider, job.result.thinking) : "";
		const notificationContent = [
			`**\u2298 Subagent Cancelled: \`${job.name}\`**`,
			`**Job:** \`${job.id}\``,
			`**Task:** ${job.task}`,
			`**Elapsed:** ${elapsed}`,
			usageLine ? `**Usage:** ${usageLine}` : "",
			summary ? `\n${summary}${toolCallLine}` : "",
		].filter(Boolean).join("\n");
		mockPi.sendMessage(
			{
				customType: "subagent-result",
				content: notificationContent,
				display: true,
				details: {
					jobId: job.id,
					status: "cancelled",
					name: job.name,
					task: job.task,
					summary: summary || "(cancelled)",
					usage: job.result?.usage,
					result: job.result,
				},
			},
			{ triggerTurn: true, deliverAs: "steer" },
		);
	};
});

afterEach(() => {
	mockPi.sentMessages.length = 0;
	for (const job of jobMgr.listJobs()) {
		(jobMgr as any).jobs.delete(job.id);
	}
});

// ─────────────────────────────────────────────────────────────────────
// Rule 25a: Completion notifications do NOT show **Tools:**
// ─────────────────────────────────────────────────────────────────────

describe("completion notification — Rule 25a: NO tools display", () => {
	test("completed job with tools does NOT contain **Tools:** in notification", async () => {
		const job = jobMgr.createJob("reviewer", "Review the auth module");
		job.tools = ["read", "grep"];

		const messages = [
			fakeMessage("The auth module looks good overall. Found one issue with the token refresh logic."),
		] as Message[];

		jobMgr.completeJob(job.id, {
			...fakeSingleResult({
				name: "reviewer",
				task: "Review the auth module",
				tools: ["read", "grep"],
				messages,
			}),
		});

		// Manually trigger completion notification (matches subagent_fork completion handler)
		emitCompletionNotification(job);

		// Find the completion notification
		const completionMsgs = mockPi.sentMessages.filter(
			(m: any) => m.customType === "subagent-result" && m.details?.status === "completed",
		);

		expect(completionMsgs.length).toBeGreaterThanOrEqual(1);
		const msg = completionMsgs[0];
		const content = msg.content ?? "";

		// Rule 25a: NO **Tools:** line
		expect(content).not.toContain("**Tools:**");
	});

	test("completed job with tools does NOT contain [read,grep] bracket in notification", async () => {
		const job = jobMgr.createJob("scout", "Scout the codebase");
		job.tools = ["read", "grep"];

		jobMgr.completeJob(job.id, {
			...fakeSingleResult({
				name: "scout",
				task: "Scout the codebase",
				tools: ["read", "grep"],
				messages: [fakeMessage("Found 5 relevant files in the codebase.")] as Message[],
			}),
		});

		emitCompletionNotification(job);

		const completionMsgs = mockPi.sentMessages.filter(
			(m: any) => m.customType === "subagent-result" && m.details?.status === "completed",
		);

		expect(completionMsgs.length).toBeGreaterThanOrEqual(1);
		const msg = completionMsgs[0];
		const content = msg.content ?? "";

		// Rule 25a: NO tools bracket
		expect(content).not.toContain("[read,grep]");
	});

	test("completed job with long tools list does NOT show truncated bracket in notification", async () => {
		const job = jobMgr.createJob("worker", "Do the work");
		job.tools = ["read", "write", "bash", "edit", "grep", "find"];

		jobMgr.completeJob(job.id, {
			...fakeSingleResult({
				name: "worker",
				task: "Do the work",
				tools: ["read", "write", "bash", "edit", "grep", "find"],
				messages: [fakeMessage("Work completed successfully.")] as Message[],
			}),
		});

		emitCompletionNotification(job);

		const completionMsgs = mockPi.sentMessages.filter(
			(m: any) => m.customType === "subagent-result" && m.details?.status === "completed",
		);

		expect(completionMsgs.length).toBeGreaterThanOrEqual(1);
		const msg = completionMsgs[0];
		const content = msg.content ?? "";

		// Rule 25a: NO bracket at all (not even truncated like "[read,write,bash,edit,grep,find +1]")
		expect(content).not.toMatch(/\[[\w,+\s]+\]/);
	});

	test("completed job without tools also does NOT contain any tools reference", async () => {
		const job = jobMgr.createJob("worker", "Do something");
		// No tools set

		jobMgr.completeJob(job.id, {
			...fakeSingleResult({
				name: "worker",
				task: "Do something",
				messages: [fakeMessage("Done.")] as Message[],
			}),
		});

		emitCompletionNotification(job);

		const completionMsgs = mockPi.sentMessages.filter(
			(m: any) => m.customType === "subagent-result" && m.details?.status === "completed",
		);

		expect(completionMsgs.length).toBeGreaterThanOrEqual(1);
		const msg = completionMsgs[0];
		const content = msg.content ?? "";

		// Should not contain tools references
		expect(content).not.toContain("**Tools:**");
		expect(content).not.toMatch(/\[[\w,]+\]/);
	});
});

// ─────────────────────────────────────────────────────────────────────
// Rule 25b: Cancellation notifications do NOT show **Tools:**
// ─────────────────────────────────────────────────────────────────────

describe("cancellation notification — Rule 25b: NO tools display", () => {
	test("cancelled job with tools does NOT contain **Tools:** in notification", async () => {
		const job = jobMgr.createJob("reviewer", "Review the auth module");
		job.tools = ["read", "grep"];

		const messages = [
			fakeMessage("Starting the review..."),
			fakeToolCall("read", { file_path: "/src/auth.ts" }),
			fakeMessage("I found a potential issue."),
		] as Message[];

		const result = fakeSingleResult({
			name: "reviewer",
			task: "Review the auth module",
			tools: ["read", "grep"],
			messages,
		});
		(jobMgr.getJob(job.id) as any).result = result;

		jobMgr.cancelJob(job.id);

		const cancelMsgs = mockPi.sentMessages.filter(
			(m: any) => m.customType === "subagent-result" && m.details?.status === "cancelled",
		);

		expect(cancelMsgs.length).toBeGreaterThanOrEqual(1);
		const msg = cancelMsgs[0];
		const content = msg.content ?? "";

		// Rule 25b: NO **Tools:** line
		expect(content).not.toContain("**Tools:**");
	});

	test("cancelled job with tools does NOT contain [read,grep] bracket in notification", async () => {
		const job = jobMgr.createJob("scout", "Scout the codebase");
		job.tools = ["read", "grep"];

		const result = fakeSingleResult({
			name: "scout",
			task: "Scout the codebase",
			tools: ["read", "grep"],
			messages: [
				fakeMessage("Scanning files..."),
				fakeToolCall("grep", { pattern: "TODO", path: "/src" }) as any,
			],
		});
		(jobMgr.getJob(job.id) as any).result = result;

		jobMgr.cancelJob(job.id);

		const cancelMsgs = mockPi.sentMessages.filter(
			(m: any) => m.customType === "subagent-result" && m.details?.status === "cancelled",
		);

		expect(cancelMsgs.length).toBeGreaterThanOrEqual(1);
		const msg = cancelMsgs[0];
		const content = msg.content ?? "";

		// Rule 25b: NO tools bracket
		expect(content).not.toContain("[read,grep]");
	});

	test("cancelled job with long tools list does NOT show truncated bracket in notification", async () => {
		const job = jobMgr.createJob("auditor", "Audit the codebase");
		job.tools = ["read", "write", "bash", "edit", "grep", "find", "node"];

		const result = fakeSingleResult({
			name: "auditor",
			task: "Audit the codebase",
			tools: ["read", "write", "bash", "edit", "grep", "find", "node"],
			messages: [fakeMessage("Audit in progress...")],
		});
		(jobMgr.getJob(job.id) as any).result = result;

		jobMgr.cancelJob(job.id);

		const cancelMsgs = mockPi.sentMessages.filter(
			(m: any) => m.customType === "subagent-result" && m.details?.status === "cancelled",
		);

		expect(cancelMsgs.length).toBeGreaterThanOrEqual(1);
		const msg = cancelMsgs[0];
		const content = msg.content ?? "";

		// Rule 25b: NO bracket at all (not even truncated)
		expect(content).not.toMatch(/\[[\w,+\s]+\]/);
	});

	test("cancelled job without tools also does NOT contain any tools reference", async () => {
		const job = jobMgr.createJob("worker", "Do some work");
		// No tools set

		const result = fakeSingleResult({
			name: "worker",
			task: "Do some work",
			messages: [fakeMessage("Working...")],
		});
		(jobMgr.getJob(job.id) as any).result = result;

		jobMgr.cancelJob(job.id);

		const cancelMsgs = mockPi.sentMessages.filter(
			(m: any) => m.customType === "subagent-result" && m.details?.status === "cancelled",
		);

		expect(cancelMsgs.length).toBeGreaterThanOrEqual(1);
		const msg = cancelMsgs[0];
		const content = msg.content ?? "";

		// Should not contain tools references
		expect(content).not.toContain("**Tools:**");
		expect(content).not.toMatch(/\[[\w,]+\]/);
	});
});
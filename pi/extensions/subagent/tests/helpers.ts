/**
 * Test helpers for subagent extension tests.
 */

import { vi } from "vitest";
import type { Message } from "@earendil-works/pi-ai";
import { JobManager, type SingleResult } from "../job-manager.js";

export function fakeUsageStats(): SingleResult["usage"] {
	return {
		input: 5000,
		output: 1200,
		cacheRead: 3000,
		cacheWrite: 800,
		cost: 0.0342,
		contextTokens: 6000,
		turns: 3,
	};
}

/**
 * Create a minimal AssistantMessage that satisfies the Message type.
 * Tests that need text content should use fakeMessage() instead of raw objects.
 */
export function fakeMessage(text: string, extra?: Partial<{ role: "assistant"; content: any[]; api: string; provider: string; model: string; usage: any; stopReason: string }>): Message {
	return {
		role: "assistant",
		content: [{ type: "text", text }],
		api: "test" as any,
		provider: "test",
		model: "test-model",
		usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0, cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 } },
		stopReason: "stop",
		...extra,
	} as Message;
}

/**
 * Create a minimal AssistantMessage with both text and tool calls.
 * Content items should use fakeToolCall() or { type: "text", text: "..." } objects.
 * The `content` parameter is an array of content items that will be typed correctly.
 */
export function fakeMessageWith(content: Array<{ type: "text"; text: string } | { type: "toolCall"; id: string; name: string; arguments: Record<string, any> }>): Message {
	return {
		role: "assistant",
		content,
		api: "test" as any,
		provider: "test",
		model: "test-model",
		usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0, cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 } },
		stopReason: "stop",
	} as Message;
}

/**
 * Create a minimal ToolCall content item that satisfies the ToolCall type.
 */
export function fakeToolCall(name: string, args: Record<string, any> = {}): { type: "toolCall"; id: string; name: string; arguments: Record<string, any> } {
	return {
		type: "toolCall",
		id: `call_${Math.random().toString(36).slice(2, 10)}`,
		name,
		arguments: args,
	};
}

export function fakeSingleResult(overrides: Partial<SingleResult> = {}): SingleResult {
	return {
		name: "reviewer",
		task: "Review the auth module",
		exitCode: 0,
		messages: [
			fakeMessage("Here is my review: looks good."),
		],
		stderr: "",
		usage: fakeUsageStats(),
		...overrides,
	};
}

/**
 * Create a minimal mock ChildProcess for cancel/terminateProcess tests.
 * Includes kill, killed, and on stubs.
 */
export function fakeChildProcess(overrides: Partial<{
	kill: ReturnType<typeof vi.fn>;
	killed: boolean;
	on: ReturnType<typeof vi.fn>;
}> = {}): any {
	return {
		kill: vi.fn(),
		killed: false,
		on: vi.fn(),
		...overrides,
	};
}

export interface TestContext {
	jobMgr: JobManager;
}

export function setupJobManager(): TestContext {
	return {
		jobMgr: new JobManager(),
	};
}

/**
 * Create a minimal AsyncJob for widget/renderer tests.
 */
export function makeAsyncJob(overrides: {
	name?: string;
	task?: string;
	status?: "running" | "completed" | "failed" | "cancelled";
	tools?: string[];
	messages?: Message[];
	resultOverrides?: Partial<SingleResult>;
} = {}): any {
	const id = `test-${Math.random().toString(36).slice(2, 8)}`;
	const status = overrides.status ?? "running";
	const now = Date.now();
	const startedAt = now - 5000;
	const completedAt = status !== "running" ? now - 1000 : null;

	let result: SingleResult | null = null;
	if (status !== "running" && overrides.messages) {
		result = {
			name: overrides.name ?? "test",
			task: overrides.task ?? "test task",
			exitCode: status === "completed" ? 0 : status === "failed" ? 1 : 0,
			messages: overrides.messages,
			stderr: "",
			usage: fakeUsageStats(),
			tools: overrides.tools,
			...overrides.resultOverrides,
		};
	}

	return {
		id,
		name: overrides.name ?? "test",
		task: overrides.task ?? "test task",
		status,
		process: null,
		startedAt,
		completedAt,
		result,
		tools: overrides.tools,
	};
}
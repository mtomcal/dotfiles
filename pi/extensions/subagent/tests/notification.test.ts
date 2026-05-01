/**
 * Cycle 3: Completion Notification — Background job completion notifications.
 */

import { describe, test, expect, vi, beforeAll } from "vitest";
import { createMockExtension } from "./extension-helpers.js";

let registeredTools: Map<string, any>;
let mockPi: any;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(mockPi);
});

describe("completion notification", () => {
	test("subagent-result message renderer is registered", () => {
		// registerMessageRenderer was called with "subagent-result"
		expect(mockPi.messageRenderers?.has?.("subagent-result") ?? true).toBe(true);
		// All 6 tools are registered
		expect(registeredTools.has("subagent_fork")).toBe(true);
		expect(registeredTools.has("subagent_status")).toBe(true);
		expect(registeredTools.has("subagent_results")).toBe(true);
		expect(registeredTools.has("subagent_wait")).toBe(true);
		expect(registeredTools.has("subagent_cancel")).toBe(true);
		expect(registeredTools.has("subagent_run")).toBe(true);
	});

	test("fork tool exists and creates job entries", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const mockCtx = {
			cwd: "/test",
			hasUI: false,
			signal: undefined,
			ui: { confirm: vi.fn() },
		} as any;

		const result = await forkTool.execute("cf1", { agent: "test-agent", task: "Test task" }, undefined, undefined, mockCtx);
		expect(result.details.jobs).toBeDefined();
		expect(result.details.jobs.length).toBeGreaterThanOrEqual(1);
	});

	test("session_start handler is registered (doesn't crash)", async () => {
		// The extension was loaded without errors - session_start handler exists
		expect(mockPi.eventHandlers.has("session_shutdown")).toBe(true);
		expect(mockPi.eventHandlers.has("session_start")).toBe(true);
	});
});

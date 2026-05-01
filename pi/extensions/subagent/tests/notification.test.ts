/**
 * Completion Notification — Background job completion notifications.
 * Uses name (not agent).
 */

import { describe, test, expect, vi, beforeAll, afterEach } from "vitest";
import { createMockExtension } from "./extension-helpers.js";

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
	jobMgr.cancelAll();
	for (const job of jobMgr.listJobs()) {
		(jobMgr as any).jobs.delete(job.id);
	}
});

describe("completion notification", () => {
	test("subagent-result message renderer is registered", () => {
		expect(mockPi.messageRenderers.has("subagent-result")).toBe(true);
		expect(registeredTools.has("subagent_fork")).toBe(true);
		expect(registeredTools.has("subagent_status")).toBe(true);
		expect(registeredTools.has("subagent_results")).toBe(true);
		expect(registeredTools.has("subagent_wait")).toBe(true);
		expect(registeredTools.has("subagent_cancel")).toBe(true);
		expect(registeredTools.has("subagent_run")).toBe(true);
	});

	test("fork tool creates job entries with name field", async () => {
		const forkTool = registeredTools.get("subagent_fork");
		const mockCtx = {
			cwd: "/test",
			hasUI: false,
			signal: undefined,
			ui: { confirm: vi.fn() },
		} as any;

		const result = await forkTool.execute("cf1", { task: "Test task" }, undefined, undefined, mockCtx);
		expect(result.details.jobs).toHaveLength(1);
		expect(result.details.jobs[0].name).toBeDefined();
		expect(result.details.jobs[0].status).toBeDefined();
	});

	test("session handlers registered", async () => {
		expect(mockPi.eventHandlers.has("session_shutdown")).toBe(true);
		expect(mockPi.eventHandlers.has("session_start")).toBe(true);
	});
});
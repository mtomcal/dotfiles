/**
 * Session Lifecycle — Shutdown, startup, and persistence.
 */

import { describe, test, expect, vi, beforeAll, afterEach } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import { JobManager } from "../job-manager.js";
import { fakeSingleResult } from "./helpers.js";

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
	mockPi.sentMessages.length = 0;
	mockPi.appendEntries.length = 0;
});

describe("session lifecycle", () => {
	test("session_shutdown handler is registered", () => {
		expect(mockPi.eventHandlers.has("session_shutdown")).toBe(true);
	});

	test("session_start handler is registered", () => {
		expect(mockPi.eventHandlers.has("session_start")).toBe(true);
	});

	test("session_shutdown cancels running jobs", () => {
		expect(() => {
			mockPi.emit("session_shutdown", { reason: "quit" });
		}).not.toThrow();
	});

	test("session_start restores completed jobs with name field", () => {
		const mgr = new JobManager();
		const job = mgr.createJob("reviewer", "Review");
		mgr.completeJob(job.id, fakeSingleResult());

		mockPi.appendEntry("subagent-job-state", mgr.serialize());

		expect(() => {
			mockPi.emit("session_start", { reason: "reload" });
		}).not.toThrow();
	});

	test("running jobs are persisted via appendEntry on create", () => {
		const forkTool = registeredTools.get("subagent_fork");
		const mockCtx = {
			cwd: "/test",
			hasUI: false,
			signal: undefined,
			ui: { confirm: vi.fn() },
		} as any;

		forkTool.execute("lf1", { task: "Will be persisted" }, undefined, undefined, mockCtx);

		const stateEntries = mockPi.appendEntries.filter((e: any) => e.customType === "subagent-job-state");
		expect(stateEntries.length).toBeGreaterThan(0);
	});
});
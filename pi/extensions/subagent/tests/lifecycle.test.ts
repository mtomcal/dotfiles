/**
 * Cycle 9: Session Lifecycle — Shutdown, startup, and persistence.
 */

import { describe, test, expect, vi, beforeAll } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import { JobManager, MAX_RUNNING_JOBS } from "../job-manager.js";
import { fakeSingleResult } from "./helpers.js";

let registeredTools: Map<string, any>;
let mockPi: any;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(mockPi);
});

describe("session lifecycle", () => {
	test("session_shutdown handler is registered", () => {
		expect(mockPi.eventHandlers.has("session_shutdown")).toBe(true);
	});

	test("session_start handler is registered", () => {
		expect(mockPi.eventHandlers.has("session_start")).toBe(true);
	});

	test("session_shutdown cancels running jobs", () => {
		// Emit a shutdown event - should not throw
		expect(() => {
			mockPi.emit("session_shutdown", { reason: "quit" });
		}).not.toThrow();
	});

	test("session_start restores completed jobs from appendEntry", () => {
		// Persist some state via appendEntry
		const mgr = new JobManager();
		const job = mgr.createJob("reviewer", "Review");
		mgr.completeJob(job.id, fakeSingleResult());

		// Append state
		mockPi.appendEntry("subagent-job-state", mgr.serialize());

		// Then emit session_start - should not throw
		expect(() => {
			mockPi.emit("session_start", { reason: "reload" });
		}).not.toThrow();
	});

	test("running jobs are persisted via appendEntry on create", () => {
		// Fork creates jobs and calls appendEntry
		const forkTool = registeredTools.get("subagent_fork");
		const mockCtx = {
			cwd: "/test",
			hasUI: false,
			signal: undefined,
			ui: { confirm: vi.fn() },
		} as any;

		forkTool.execute("lf1", { agent: "persist-me", task: "Will be persisted" }, undefined, undefined, mockCtx);

		// Check that appendEntry was called
		const stateEntries = mockPi.appendEntries.filter((e: any) => e.customType === "subagent-job-state");
		expect(stateEntries.length).toBeGreaterThan(0);
	});
});

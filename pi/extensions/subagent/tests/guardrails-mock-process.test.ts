/**
 * Mock Process Pipeline Integration Tests — Validates the full enforcement
 * pipeline (processLine → checkGuardrails → terminateProcess → close handler)
 * using a mocked NDJSON-emitting child process.
 *
 * Spec: specs/subagent-guardrails.md (Slice 3), Course Corrections Round 2
 */

import { describe, test, expect, vi, beforeEach, afterEach } from "vitest";
import { EventEmitter } from "node:events";

// ─── Mock setup ───────────────────────────────────────────────────────
// Mock node:child_process BEFORE the extension module is loaded.
// The mock spawn returns a fake EventEmitter-based process that we control
// during tests. This validates the full enforcement pipeline end-to-end.

const mockSpawn = vi.fn();
vi.mock("node:child_process", () => ({
	spawn: mockSpawn,
}));

// We import dynamically after the mock is in place
// so that index.ts gets the mocked spawn.

let registeredTools: Map<string, any>;
let mockPi: any;
let runTool: any;
let forkTool: any;
let jobMgr: any;

async function setupTools() {
	if (registeredTools) return;

	const { createMockExtension } = await import("./extension-helpers.js");

	const ctx = createMockExtension();
	mockPi = ctx.pi;
	jobMgr = ctx.jobMgr;
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(mockPi);

	runTool = registeredTools.get("subagent_run");
	forkTool = registeredTools.get("subagent_fork");
}

// ─── Helper: build a synthetic NDJSON message_end event ──────────────

function makeMessageEndEvent(overrides: {
	turns?: number;
	cost?: number;
	contextTokens?: number;
	stopReason?: string;
} = {}): string {
	const msg = {
		type: "message_end",
		message: {
			role: "assistant",
			content: [{ type: "text", text: `Turn ${overrides.turns ?? 1}` }],
			usage: {
				input: 1000,
				output: 500,
				cacheRead: 0,
				cacheWrite: 0,
				cost: { total: overrides.cost ?? 0.01 },
				totalTokens: overrides.contextTokens ?? 5000,
			},
			stopReason: overrides.stopReason ?? undefined,
		},
	};
	return JSON.stringify(msg);
}

// ─── Helper: build a mock child process ──────────────────────────────

function createMockProcess() {
	const stdout = new EventEmitter();
	const stderr = new EventEmitter();

	const mockProc = Object.assign(new EventEmitter(), {
		stdout,
		stderr,
		killed: false,
		kill: vi.fn(function (this: any, _signal?: string) {
			this.killed = true;
			return true;
		}),
	});

	return mockProc;
}

// ─── Test context ─────────────────────────────────────────────────────

function makeCtx(overrides: Record<string, any> = {}) {
	return {
		cwd: "/test",
		ui: { confirm: vi.fn(), setWidget: vi.fn() },
		sessionManager: { getEntries: () => [] },
		...overrides,
	};
}

// ─── Helper: sleep ────────────────────────────────────────────────────

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

// ─── Tests ────────────────────────────────────────────────────────────

describe("mock process pipeline: guardrail enforcement integration", () => {
	beforeEach(async () => {
		await setupTools();
		mockSpawn.mockReset();
		mockPi.sentMessages = [];
		mockPi.appendEntries = [];
	});

	afterEach(() => {
		try { jobMgr.cancelAll(); } catch { /* ok */ }
		for (const j of jobMgr.listJobs()) {
			(jobMgr as any).jobs.delete(j.id);
		}
	});

	test("maxTurns guardrail: subagent_run kills process with stopReason='guardrail' and exitCode=1", async () => {
		const mockProc = createMockProcess();
		mockSpawn.mockReturnValue(mockProc);

		// Start the subagent_run with maxTurns=2
		const resultPromise = runTool.execute(
			"call-1",
			{ task: "test task", maxTurns: 2 },
			undefined,
			undefined,
			makeCtx(),
		);

		// Wait for the spawn to happen and async setup to complete
		await sleep(50);

		// Verify spawn was called
		expect(mockSpawn).toHaveBeenCalled();

		// Emit turn 1 — within limit
		mockProc.stdout.emit("data", Buffer.from(makeMessageEndEvent({ turns: 1, cost: 0.01 }) + "\n"));

		// Emit turn 2 — at limit (2 ≤ 2), still OK
		mockProc.stdout.emit("data", Buffer.from(makeMessageEndEvent({ turns: 2, cost: 0.02 }) + "\n"));

		// Emit turn 3 — exceeds maxTurns=2, guardrail should fire
		mockProc.stdout.emit("data", Buffer.from(makeMessageEndEvent({ turns: 3, cost: 0.03 }) + "\n"));

		// Give time for the guardrail check to synchronously execute
		await sleep(0);

		// The guardrail kill calls terminateProcess which calls mockProc.kill
		expect(mockProc.kill).toHaveBeenCalled();

		// Now emit close to resolve the result promise
		mockProc.emit("close", null);
		await sleep(0);

		const result = await resultPromise;
		expect(result.details.results).toBeDefined();
		expect(result.details.results.length).toBeGreaterThan(0);
		const singleResult = result.details.results[0];
		expect(singleResult.stopReason).toBe("guardrail");
		expect(singleResult.exitCode).toBe(1);
		expect(singleResult.errorMessage).toContain("exceeded maxTurns");
	}, 10000);

	test("maxTime guardrail: setTimeout kills process and sets stopReason='guardrail' with exitCode=1", async () => {
		const mockProc = createMockProcess();
		mockSpawn.mockReturnValue(mockProc);

		// maxTime: 0.1 seconds (100ms)
		const resultPromise = runTool.execute(
			"call-2",
			{ task: "timeout test", maxTime: 0.1 },
			undefined,
			undefined,
			makeCtx(),
		);

		// Let the spawn happen
		await sleep(20);

		// Verify spawn was called
		expect(mockSpawn).toHaveBeenCalled();

		// Wait for the maxTime timer to fire (> 100ms total)
		await sleep(150);

		// The setTimeout should have fired, called terminateProcess → kill
		expect(mockProc.kill).toHaveBeenCalled();

		// Emit close to resolve
		mockProc.emit("close", null);
		await sleep(0);

		const result = await resultPromise;
		const singleResult = result.details.results[0];
		expect(singleResult.stopReason).toBe("guardrail");
		expect(singleResult.exitCode).toBe(1);
		expect(singleResult.errorMessage).toContain("exceeded maxTime");
	}, 10000);

	test("usage guardrail beats maxTime when both could fire: usage checkpoint runs synchronously", async () => {
		const mockProc = createMockProcess();
		mockSpawn.mockReturnValue(mockProc);

		// Set both maxTurns=1 and maxTime=0.5 (500ms)
		const resultPromise = runTool.execute(
			"call-3",
			{ task: "race test", maxTurns: 1, maxTime: 0.5 },
			undefined,
			undefined,
			makeCtx(),
		);

		// Let the spawn happen
		await sleep(50);
		expect(mockSpawn).toHaveBeenCalled();

		// Emit turn 1 — at limit (1 ≤ 1), still OK
		mockProc.stdout.emit("data", Buffer.from(makeMessageEndEvent({ turns: 1, cost: 0.01 }) + "\n"));

		// Emit turn 2 — exceeds maxTurns=1, guardrail fires synchronously
		mockProc.stdout.emit("data", Buffer.from(makeMessageEndEvent({ turns: 2, cost: 0.02 }) + "\n"));
		await sleep(0);

		// Guardrail fired — timer should have been cleared, kill called
		expect(mockProc.kill).toHaveBeenCalled();

		// Emit close
		mockProc.emit("close", null);
		await sleep(0);

		const result = await resultPromise;
		const singleResult = result.details.results[0];
		expect(singleResult.stopReason).toBe("guardrail");
		expect(singleResult.exitCode).toBe(1);
		// Usage guardrail (maxTurns) should win, not maxTime
		expect(singleResult.errorMessage).toContain("maxTurns");
	}, 10000);

	test("mock process pipeline: multiple turns without guardrail breach completes normally", async () => {
		const mockProc = createMockProcess();
		mockSpawn.mockReturnValue(mockProc);

		const resultPromise = runTool.execute(
			"call-4",
			{ task: "normal task", maxTurns: 5 },
			undefined,
			undefined,
			makeCtx(),
		);

		// Let the spawn happen
		await sleep(50);
		expect(mockSpawn).toHaveBeenCalled();

		// Emit 2 turns (within maxTurns=5)
		mockProc.stdout.emit("data", Buffer.from(makeMessageEndEvent({ turns: 1, cost: 0.01, stopReason: "end_turn" }) + "\n"));
		mockProc.stdout.emit("data", Buffer.from(makeMessageEndEvent({ turns: 2, cost: 0.02, stopReason: "end_turn" }) + "\n"));

		// Normal close without guardrail kill
		mockProc.emit("close", 0);
		await sleep(0);

		const result = await resultPromise;
		const singleResult = result.details.results[0];
		expect(singleResult.stopReason).toBe("end_turn");
		expect(singleResult.exitCode).toBe(0);
		expect(singleResult.errorMessage).toBeUndefined();
	}, 10000);
});

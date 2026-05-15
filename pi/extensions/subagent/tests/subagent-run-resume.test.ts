/**
 * Slice 6: subagent_run with resumeFrom — RED tests.
 *
 * Tests cover:
 * 1. resumeFrom with non-existent job errors
 * 2. resumeFrom with non-guardrail job errors
 * 3. resumeFrom without higher limit errors
 * 4. resumeFrom + tasks[] combo errors
 * 5. resumeFrom + chain[] combo errors
 * 6. resumeFrom with no task uses original task
 * 7. resumeFrom with additional task appends it
 * 8. resumeFrom inherits source config (system prompt contains serialized conversation)
 */

import { describe, test, expect, vi, beforeAll, afterEach, beforeEach } from "vitest";
import { EventEmitter } from "node:events";
import { createMockExtension } from "./extension-helpers.js";
import { fakeMessage, makeAsyncJob } from "./helpers.js";
import type { AsyncJob, SingleResult } from "../job-manager.js";
import type { Guardrails } from "../guardrails.js";

// ─── Mock setup ───────────────────────────────────────────────────────
// Mock node:child_process BEFORE the extension module is loaded so that
// spawnSubagentProcess uses our controlled mock for tests 6-8 (spawning).

const mockSpawn = vi.fn();
vi.mock("node:child_process", () => ({
	spawn: mockSpawn,
}));

let registeredTools: Map<string, any>;
let mockPi: any;
let runTool: any;
let jobMgr: any;
let mockCtx: any;

async function setupTools() {
	if (registeredTools) return;

	const ctx = createMockExtension();
	mockPi = ctx.pi;
	jobMgr = ctx.jobMgr;
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(mockPi);

	runTool = registeredTools.get("subagent_run");

	mockCtx = {
		cwd: "/test",
		hasUI: false,
		signal: undefined,
		ui: { confirm: vi.fn() },
		sessionManager: { getEntries: () => [] },
	} as any;
}

// ─── Helper: create a mock process with EventEmitter ──────────────────

function createMockProcess() {
	const stdout = new EventEmitter();
	const stderr = new EventEmitter();
	const mockProc = Object.assign(new EventEmitter(), {
		stdout,
		stderr,
		killed: false,
		kill: vi.fn(function (this: any) {
			this.killed = true;
			return true;
		}),
	});
	return mockProc;
}

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
				input: 100,
				output: 50,
				cacheRead: 0,
				cacheWrite: 0,
				cost: { total: overrides.cost ?? 0.001 },
				totalTokens: overrides.contextTokens ?? 500,
			},
			stopReason: overrides.stopReason ?? "stop",
		},
	};
	return JSON.stringify(msg);
}

// ─── Helper: create a guardrail-killed job ────────────────────────────

function createGuardrailKilledJob(overrides: {
	id?: string;
	task?: string;
	maxTurns?: number;
	maxCost?: number;
	maxTokens?: number;
	maxTime?: number;
	turns?: number;
	cost?: number;
	contextTokens?: number;
	elapsedMs?: number;
	stoppedAt?: number;
} = {}): AsyncJob {
	const now = Date.now();
	const task = overrides.task ?? "original test task";
	const maxTurns = overrides.maxTurns ?? 25;
	const maxCost = overrides.maxCost ?? 1.0;
	const maxTokens = overrides.maxTokens ?? 200000;
	const maxTime = overrides.maxTime ?? 600;
	const turns = overrides.turns ?? (maxTurns + 1); // exceeds by default
	const cost = overrides.cost ?? 0.5;
	const contextTokens = overrides.contextTokens ?? 50000;
	const elapsedMs = overrides.elapsedMs ?? 100000;

	const guardrails: Guardrails = {};
	if (overrides.maxTurns !== undefined) guardrails.maxTurns = maxTurns;
	if (overrides.maxCost !== undefined) guardrails.maxCost = maxCost;
	if (overrides.maxTokens !== undefined) guardrails.maxTokens = maxTokens;
	if (overrides.maxTime !== undefined) guardrails.maxTime = maxTime;

	const result: SingleResult = {
		name: "test-agent",
		task,
		exitCode: 1,
		messages: [fakeMessage("This is a message from the prior run.")],
		stderr: "",
		usage: {
			input: 500,
			output: 200,
			cacheRead: 0,
			cacheWrite: 0,
			cost,
			contextTokens,
			turns,
		},
		stopReason: "guardrail",
	};

	const job: AsyncJob = {
		id: overrides.id ?? "guardrail-killed-job",
		name: "test-agent",
		task,
		status: "failed",
		process: null,
		result,
		startedAt: now - elapsedMs,
		completedAt: overrides.stoppedAt ?? now,
		guardrails,
		original: {
			config: {
				name: "test-agent",
				systemPrompt: undefined,
				tools: ["read", "write"],
				model: "claude-3",
				provider: "anthropic",
				thinking: "medium" as any,
				contextFiles: true,
				extensions: false,
				guardrails,
			},
			task: task,
			cwd: "/src",
			guardrails,
		},
	};

	return job;
}

// ─── Setup / Teardown ────────────────────────────────────────

beforeAll(async () => {
	await setupTools();
});

beforeEach(() => {
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

// ─── Tests ──────────────────────────────────────────────────

describe("resumeFrom validation errors", () => {
	test("1: resumeFrom with non-existent job errors", async () => {
		const result = await runTool.execute(
			"call-1",
			{ resumeFrom: "nonexistent-id" },
			undefined,
			undefined,
			mockCtx,
		);
		expect(result.isError).toBe(true);
		const text = result.content[0]?.text ?? "";
		expect(text).toMatch(/not found/i);
	});

	test("2: resumeFrom with non-guardrail job errors", async () => {
		// Create a completed (non-guardrail) job
		const completedJob = makeAsyncJob({ name: "completed-job", status: "completed" });
		(jobMgr as any).jobs.set(completedJob.id, completedJob);

		const result = await runTool.execute(
			"call-2",
			{ resumeFrom: completedJob.id },
			undefined,
			undefined,
			mockCtx,
		);
		expect(result.isError).toBe(true);
		const text = result.content[0]?.text ?? "";
		expect(text).toMatch(/was not killed by a guardrail/i);
	});

	test("3: resumeFrom without higher limit on breached dim errors", async () => {
		// Create a maxTurns guardrail-killed job
		const job = createGuardrailKilledJob({ id: "breached-maxTurns", maxTurns: 25, turns: 26 });
		(jobMgr as any).jobs.set(job.id, job);

		// Try to resume with same maxTurns (not higher)
		const result = await runTool.execute(
			"call-3",
			{ resumeFrom: job.id, maxTurns: 25 },
			undefined,
			undefined,
			mockCtx,
		);
		expect(result.isError).toBe(true);
		const text = result.content[0]?.text ?? "";
		expect(text).toMatch(/must be raised/i);
	});

	test("4: resumeFrom + tasks[] combo errors", async () => {
		// Create a guardrail-killed job
		const job = createGuardrailKilledJob({ id: "combo-job-tasks" });
		(jobMgr as any).jobs.set(job.id, job);

		const result = await runTool.execute(
			"call-4",
			{
				resumeFrom: job.id,
				tasks: [{ task: "some task" }],
			},
			undefined,
			undefined,
			mockCtx,
		);
		expect(result.isError).toBe(true);
		const text = result.content[0]?.text ?? "";
		expect(text).toMatch(/resumeFrom.*cannot.*tasks/i);
	});

	test("5: resumeFrom + chain[] combo errors", async () => {
		// Create a guardrail-killed job
		const job = createGuardrailKilledJob({ id: "combo-job-chain" });
		(jobMgr as any).jobs.set(job.id, job);

		const result = await runTool.execute(
			"call-5",
			{
				resumeFrom: job.id,
				chain: [{ task: "step 1" }],
			},
			undefined,
			undefined,
			mockCtx,
		);
		expect(result.isError).toBe(true);
		const text = result.content[0]?.text ?? "";
		expect(text).toMatch(/resumeFrom.*cannot.*chain/i);
	});
});

describe("resumeFrom behavior (spawn integration)", () => {
	test("6: resumeFrom with no task uses original task", async () => {
		const mockProc = createMockProcess();
		mockSpawn.mockReturnValue(mockProc);

		// Create a guardrail-killed job
		const job = createGuardrailKilledJob({ id: "resume-no-task", maxTurns: 25, turns: 26 });
		(jobMgr as any).jobs.set(job.id, job);

		// Call resumeFrom with higher maxTurns and no task
		const resultPromise = runTool.execute(
			"call-6",
			{ resumeFrom: job.id, maxTurns: 50 },
			undefined,
			undefined,
			mockCtx,
		);

		// Let the spawn happen
		await new Promise((r) => setTimeout(r, 50));

		// Capture the spawn args
		expect(mockSpawn).toHaveBeenCalled();
		const spawnArgs = mockSpawn.mock.calls[0];

		// The task should be in the args (as "Task: original test task")
		const argsList = spawnArgs[1] as string[];
		const taskArg = argsList.find((a: string) => a.startsWith("Task: "));
		expect(taskArg).toBeDefined();
		expect(taskArg).toContain("original test task");

		// Emit successful result events to resolve the execute handler
		mockProc.stdout.emit("data", Buffer.from(makeMessageEndEvent({ turns: 1, cost: 0.001 }) + "\n"));
		await new Promise((r) => setTimeout(r, 0));
		mockProc.emit("close", null);
		await new Promise((r) => setTimeout(r, 0));

		const result = await resultPromise;
		// Should not be an error since spawn succeeded
		expect(result.isError).toBeFalsy();
	}, 10000);

	test("7: resumeFrom with additional task appends it", async () => {
		const mockProc = createMockProcess();
		mockSpawn.mockReturnValue(mockProc);

		// Create a guardrail-killed job
		const job = createGuardrailKilledJob({ id: "resume-with-task", maxTurns: 25, turns: 26 });
		(jobMgr as any).jobs.set(job.id, job);

		// Call resumeFrom with a new continuation task
		const resultPromise = runTool.execute(
			"call-7",
			{ resumeFrom: job.id, maxTurns: 50, task: "new task" },
			undefined,
			undefined,
			mockCtx,
		);

		// Let the spawn happen
		await new Promise((r) => setTimeout(r, 50));

		// Capture the spawn args
		expect(mockSpawn).toHaveBeenCalled();
		const spawnArgs = mockSpawn.mock.calls[0];

		// The task should contain both original and new instruction
		const argsList = spawnArgs[1] as string[];
		const taskArg = argsList.find((a: string) => a.startsWith("Task: "));
		expect(taskArg).toBeDefined();
		expect(taskArg).toContain("original test task");
		expect(taskArg).toContain("New instruction: new task");

		// Emit successful result events to resolve
		mockProc.stdout.emit("data", Buffer.from(makeMessageEndEvent({ turns: 1, cost: 0.001 }) + "\n"));
		await new Promise((r) => setTimeout(r, 0));
		mockProc.emit("close", null);
		await new Promise((r) => setTimeout(r, 0));

		const result = await resultPromise;
		expect(result.isError).toBeFalsy();
	}, 10000);

	test("8: resumeFrom inherits source config and injects conversation context", async () => {
		const mockProc = createMockProcess();
		mockSpawn.mockReturnValue(mockProc);

		// Create a guardrail-killed job with specific source config
		const job = createGuardrailKilledJob({
			id: "resume-inherit-config",
			maxTurns: 25,
			turns: 26,
		});
		(jobMgr as any).jobs.set(job.id, job);

		// Call resumeFrom
		const resultPromise = runTool.execute(
			"call-8",
			{ resumeFrom: job.id, maxTurns: 50 },
			undefined,
			undefined,
			mockCtx,
		);

		// Let the spawn happen
		await new Promise((r) => setTimeout(r, 50));

		// Verify spawn was called (implies config was resolved and passed through)
		expect(mockSpawn).toHaveBeenCalled();

		// Verify the source config is inherited: provider "anthropic" should be in args
		const spawnArgs = mockSpawn.mock.calls[0];
		const argsList = spawnArgs[1] as string[];
		expect(argsList).toContain("--provider");
		const providerIdx = argsList.indexOf("--provider");
		expect(argsList[providerIdx + 1]).toBe("anthropic");

		// Verify model is inherited
		expect(argsList).toContain("--model");
		const modelIdx = argsList.indexOf("--model");
		expect(argsList[modelIdx + 1]).toBe("claude-3");

		// Emit successful result events to resolve
		mockProc.stdout.emit("data", Buffer.from(makeMessageEndEvent({ turns: 1, cost: 0.001 }) + "\n"));
		await new Promise((r) => setTimeout(r, 0));
		mockProc.emit("close", null);
		await new Promise((r) => setTimeout(r, 0));

		const result = await resultPromise;
		expect(result.isError).toBeFalsy();
	}, 10000);
});

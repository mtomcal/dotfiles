/**
 * Slice 7: subagent_fork with resumeFrom.
 *
 * Tests cover:
 * 1. Valid resumeFrom creates job with injected context (single mode)
 * 2. Invalid job ID → error, no job created
 * 3. resumeFrom + tasks[] top-level → error
 * 4. tasks[] with per-task resumeFrom → one resumes, another fresh
 * 5. Preserves original config on new job (resumedFrom in OriginalInvocation)
 * 6. Non-guardrail job → error
 */

import { describe, test, expect, vi, beforeAll, afterEach, beforeEach } from "vitest";
import { EventEmitter } from "node:events";
import { createMockExtension } from "./extension-helpers.js";
import { fakeMessage, makeAsyncJob } from "./helpers.js";
import type { AsyncJob, SingleResult } from "../job-manager.js";
import type { Guardrails } from "../guardrails.js";

// ─── Mock setup ───────────────────────────────────────────────────────
// Mock node:child_process BEFORE the extension module is loaded so that
// spawnSubagentProcess uses our controlled mock for tests that spawn.

const mockSpawn = vi.fn();
vi.mock("node:child_process", () => ({
	spawn: mockSpawn,
}));

let registeredTools: Map<string, any>;
let mockPi: any;
let forkTool: any;
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

	forkTool = registeredTools.get("subagent_fork");

	mockCtx = {
		cwd: "/test",
		hasUI: false,
		signal: undefined,
		ui: { confirm: vi.fn().mockResolvedValue(true) },
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
	const turns = overrides.turns ?? (maxTurns + 1);
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

describe("subagent_fork resumeFrom validation errors", () => {
	test("1: invalid job ID returns error, no job created", async () => {
		const result = await forkTool.execute(
			"call-1",
			{ resumeFrom: "nonexistent-job" },
			undefined,
			undefined,
			mockCtx,
		);
		expect(result.isError).toBe(true);
		const text = result.content[0]?.text ?? "";
		expect(text).toMatch(/not found/i);
	});

	test("2: non-guardrail job returns error", async () => {
		const completedJob = makeAsyncJob({ name: "completed-job", status: "completed" });
		(jobMgr as any).jobs.set(completedJob.id, completedJob);

		const result = await forkTool.execute(
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

	test("3: resumeFrom + tasks[] top-level returns error", async () => {
		const job = createGuardrailKilledJob({ id: "fork-combo-top" });
		(jobMgr as any).jobs.set(job.id, job);

		const result = await forkTool.execute(
			"call-3",
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

	test("4: resumeFrom without higher limit on breached dim errors", async () => {
		const job = createGuardrailKilledJob({ id: "fork-no-limit-raise", maxTurns: 25, turns: 26 });
		(jobMgr as any).jobs.set(job.id, job);

		const result = await forkTool.execute(
			"call-4",
			{ resumeFrom: job.id, maxTurns: 25 },
			undefined,
			undefined,
			mockCtx,
		);
		expect(result.isError).toBe(true);
		const text = result.content[0]?.text ?? "";
		expect(text).toMatch(/must be raised/i);
	});
});

describe("subagent_fork resumeFrom behavior (spawn integration)", () => {
	test("5: valid resumeFrom creates job with injected context", async () => {
		const mockProc = createMockProcess();
		mockSpawn.mockReturnValue(mockProc);

		const job = createGuardrailKilledJob({
			id: "fork-valid-resume",
			maxTurns: 25,
			turns: 26,
		});
		(jobMgr as any).jobs.set(job.id, job);

		const resultPromise = forkTool.execute(
			"call-5",
			{ resumeFrom: job.id, maxTurns: 50 },
			undefined,
			undefined,
			mockCtx,
		);

		// Let the spawn happen
		await new Promise((r) => setTimeout(r, 50));

		// Verify spawn was called — implies valid config was resolved
		expect(mockSpawn).toHaveBeenCalled();

		const spawnArgs = mockSpawn.mock.calls[0];
		const argsList = spawnArgs[1] as string[];

		// Verify source config is inherited: provider and model from original
		expect(argsList).toContain("--provider");
		const providerIdx = argsList.indexOf("--provider");
		expect(argsList[providerIdx + 1]).toBe("anthropic");

		expect(argsList).toContain("--model");
		const modelIdx = argsList.indexOf("--model");
		expect(argsList[modelIdx + 1]).toBe("claude-3");

		// Verify task from original is present
		const taskArg = argsList.find((a: string) => a.startsWith("Task: "));
		expect(taskArg).toBeDefined();
		expect(taskArg).toContain("original test task");

		// Emit successful result to resolve the handler
		mockProc.stdout.emit("data", Buffer.from(makeMessageEndEvent({ turns: 1, cost: 0.001 }) + "\n"));
		await new Promise((r) => setTimeout(r, 0));
		mockProc.emit("close", null);
		await new Promise((r) => setTimeout(r, 0));

		const result = await resultPromise;
		expect(result.isError).toBeFalsy();
		expect(result.content[0]?.text).toMatch(/forked/i);
		expect(result.details.jobs).toHaveLength(1);
	}, 10000);

	test("6: preserves original config on new job (resumedFrom in OriginalInvocation)", async () => {
		const mockProc = createMockProcess();
		mockSpawn.mockReturnValue(mockProc);

		const job = createGuardrailKilledJob({
			id: "fork-preserve-original",
			maxTurns: 25,
			turns: 26,
		});
		(jobMgr as any).jobs.set(job.id, job);

		const resultPromise = forkTool.execute(
			"call-6",
			{ resumeFrom: job.id, maxTurns: 50 },
			undefined,
			undefined,
			mockCtx,
		);

		// Let the spawn happen
		await new Promise((r) => setTimeout(r, 50));

		// Emit successful result to resolve
		mockProc.stdout.emit("data", Buffer.from(makeMessageEndEvent({ turns: 1, cost: 0.001 }) + "\n"));
		await new Promise((r) => setTimeout(r, 0));
		mockProc.emit("close", null);
		await new Promise((r) => setTimeout(r, 0));

		await resultPromise;

		// Find the newly created job (there should be 2: source + new)
		const allJobs = jobMgr.listJobs();
		const newJob = allJobs.find((j: any) => j.id !== job.id);
		expect(newJob).toBeDefined();
		expect(newJob!.original).toBeDefined();
		expect(newJob!.original!.resumedFrom).toBe(job.id);
		// Original config should be preserved (provider from source)
		expect(newJob!.original!.config.provider).toBe("anthropic");
	}, 10000);

	test("7: tasks[] with per-task resumeFrom — one resumes, another fresh", async () => {
		const mockProc1 = createMockProcess();
		const mockProc2 = createMockProcess();
		mockSpawn.mockReturnValueOnce(mockProc1).mockReturnValueOnce(mockProc2);

		const sourceJob = createGuardrailKilledJob({
			id: "fork-per-task-source",
			maxTurns: 25,
			turns: 26,
		});
		(jobMgr as any).jobs.set(sourceJob.id, sourceJob);

		const resultPromise = forkTool.execute(
			"call-7",
			{
				tasks: [
					{ task: "Fresh task", name: "fresh-task" },
					{ task: "Continue from source", name: "resume-task", resumeFrom: sourceJob.id, maxTurns: 50 },
				],
			},
			undefined,
			undefined,
			mockCtx,
		);

		// Let the spawns happen
		await new Promise((r) => setTimeout(r, 50));

		// Verify spawn was called twice
		expect(mockSpawn).toHaveBeenCalledTimes(2);

		// First spawn should be the fresh task
		const firstSpawnArgs = mockSpawn.mock.calls[0][1] as string[];
		const firstTaskArg = firstSpawnArgs.find((a: string) => a.startsWith("Task: "));
		expect(firstTaskArg).toBeDefined();
		expect(firstTaskArg).toContain("Fresh task");

		// Second spawn should be the resume task
		const secondSpawnArgs = mockSpawn.mock.calls[1][1] as string[];
		const secondTaskArg = secondSpawnArgs.find((a: string) => a.startsWith("Task: "));
		expect(secondTaskArg).toBeDefined();
		expect(secondTaskArg).toContain("original test task");
		expect(secondTaskArg).toContain("Continue from source");

		// Verify the resume spawn has provider from source
		expect(secondSpawnArgs).toContain("--provider");
		const providerIdx = secondSpawnArgs.indexOf("--provider");
		expect(secondSpawnArgs[providerIdx + 1]).toBe("anthropic");

		// Emit successful results to resolve
		mockProc1.stdout.emit("data", Buffer.from(makeMessageEndEvent({ turns: 1, cost: 0.001 }) + "\n"));
		await new Promise((r) => setTimeout(r, 0));
		mockProc1.emit("close", null);
		await new Promise((r) => setTimeout(r, 0));

		mockProc2.stdout.emit("data", Buffer.from(makeMessageEndEvent({ turns: 1, cost: 0.001 }) + "\n"));
		await new Promise((r) => setTimeout(r, 0));
		mockProc2.emit("close", null);
		await new Promise((r) => setTimeout(r, 0));

		const result = await resultPromise;
		expect(result.isError).toBeFalsy();
		expect(result.content[0]?.text).toMatch(/forked/i);
		expect(result.details.jobs).toHaveLength(2);

		// Verify the resumed job has original.resumedFrom set
		const allJobs = jobMgr.listJobs();
		const resumedJob = allJobs.find((j: any) => j.id !== sourceJob.id && j.original?.resumedFrom === sourceJob.id);
		expect(resumedJob).toBeDefined();
	}, 10000);

	test("8: resumeFrom with additional task appends it", async () => {
		const mockProc = createMockProcess();
		mockSpawn.mockReturnValue(mockProc);

		const job = createGuardrailKilledJob({
			id: "fork-with-new-task",
			maxTurns: 25,
			turns: 26,
		});
		(jobMgr as any).jobs.set(job.id, job);

		const resultPromise = forkTool.execute(
			"call-8",
			{ resumeFrom: job.id, maxTurns: 50, task: "new continuation task" },
			undefined,
			undefined,
			mockCtx,
		);

		// Let the spawn happen
		await new Promise((r) => setTimeout(r, 50));

		expect(mockSpawn).toHaveBeenCalled();
		const spawnArgs = mockSpawn.mock.calls[0];
		const argsList = spawnArgs[1] as string[];
		const taskArg = argsList.find((a: string) => a.startsWith("Task: "));
		expect(taskArg).toBeDefined();
		expect(taskArg).toContain("original test task");
		expect(taskArg).toContain("New instruction: new continuation task");

		// Emit successful result to resolve
		mockProc.stdout.emit("data", Buffer.from(makeMessageEndEvent({ turns: 1, cost: 0.001 }) + "\n"));
		await new Promise((r) => setTimeout(r, 0));
		mockProc.emit("close", null);
		await new Promise((r) => setTimeout(r, 0));

		const result = await resultPromise;
		expect(result.isError).toBeFalsy();
		expect(result.content[0]?.text).toMatch(/forked/i);
	}, 10000);
});
